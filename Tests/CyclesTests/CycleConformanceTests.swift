// §L: conformance. The sequences are Sendable when the graph is and can be iterated in a Task
// (CY-852); they hold a copy of the graph, so mutating the original afterwards changes nothing
// (CY-853); they are lazy, not Collections, with underestimatedCount 0 (CY-854, CY-855); generic
// code gets the same answers (CY-856); on indexed adjacency lists the entry points never hash a
// vertex (CY-857); Graph.isAcyclic and Traversal's DirectedGraph.isAcyclic differ on the views as
// api.md says (CY-858); every returned Cycle survives a Codable round trip and is equal and hashes
// equal under rotation (CY-859). Preconditions are in CyclePreconditionTests.swift. Case IDs
// (CY-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cycles
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal
import Walks

/// Counts the hashes of every `HashCountingVertex` that shares it.
private final class HashCounter: @unchecked Sendable {
    var hashes = 0
}

/// A vertex that counts how often it is hashed, so a test can see whether an algorithm works in
/// index space or looks vertices up in a dictionary.
private struct HashCountingVertex: Hashable {
    let value: Int
    let counter: HashCounter
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.value == rhs.value }
    func hash(into hasher: inout Hasher) {
        counter.hashes += 1
        hasher.combine(value)
    }
}

/// An undirected multigraph with vertex and edge indices that counts every row it is asked for.
private final class RowCounter: @unchecked Sendable {
    var rows = 0
}

private struct RowCountingGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    let incident: [[Int]]
    let counter: RowCounter

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], counter: RowCounter) {
        var incident = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            incident[edge.u].append(k)
            incident[edge.v].append(k)
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.incident = incident
        self.counter = counter
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        counter.rows += 1
        return incident[vertex]
    }
    func neighbors(of vertex: Int) -> [Int] {
        counter.rows += 1
        return incident[vertex].map { edges[$0].oppositeVertex(to: vertex) }
    }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func neighborIndices(ofIndex index: Int) -> [Int] {
        counter.rows += 1
        return incident[index].map { edges[$0].oppositeVertex(to: index) }
    }
    func incidentEdges(ofIndex index: Int) -> [Int] {
        counter.rows += 1
        return incident[index]
    }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
    func incidentEdgeIndices(ofIndex index: Int) -> [Int] {
        counter.rows += 1
        return incident[index]
    }
}

@Suite("Cycles conformance: Sendable, value semantics, laziness, index space", .tags(.conformance))
struct CycleConformanceTests {
    @Test("CY-852 the sequences and their iterators are Sendable when the graph is: a Task can iterate them")
    func sendable() async {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        // CY-330's K₄ and CY-200's digraph.
        let k4: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: k4.map { UndirectedEdge($0.0, $0.1) })
        let undirected = requireSendable(graph.simpleCycles())
        let undirectedEdges = await Task { Array(undirected).map(\.edges) }.value
        #expect(undirectedEdges == [[0, 3, 1], [0, 3, 5, 2], [0, 4, 2], [0, 4, 5, 1], [1, 3, 4, 2], [1, 5, 2], [3, 5, 4]])
        let arcs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let digraph = AdjacencyList(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let directed = requireSendable(digraph.simpleCycles(maxLength: 2))
        let iterator = requireSendable(directed.makeIterator())
        let directedEdges = await Task {
            var it = iterator
            var all: [[Int]] = []
            while let cycle = it.next() { all.append(cycle.edges) }
            return all
        }.value
        #expect(directedEdges == [[0], [2, 4], [3, 5], [6]])
        let cycle = requireSendable(digraph.simpleCycles().first { _ in true })
        #expect(cycle?.edges == [0])
    }

    @Test("CY-853 value semantics: mutating the graph after making the sequence changes nothing")
    func valueSemantics() {
        // A triangle; then a fourth vertex joined to all three, which would add six cycles.
        var graph = UndirectedAdjacencyList(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let before = graph.simpleCycles()
        var iterator = before.makeIterator()
        graph.insert(edge: UndirectedEdge(3, 0))
        graph.insert(edge: UndirectedEdge(3, 1))
        graph.insert(edge: UndirectedEdge(3, 2))
        #expect(Array(before).map(\.vertices) == [[0, 1, 2]])
        #expect(Array(before).map(\.edges) == [[0, 1, 2]])
        #expect(iterator.next()?.edges == [0, 1, 2])
        #expect(iterator.next() == nil)
        #expect(Array(graph.simpleCycles()).count == 7)

        var digraph = AdjacencyList(edges: [(0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let directed = digraph.simpleCycles()
        digraph.remove(edge: DirectedEdge(from: 1, to: 0))
        #expect(Array(directed).map(\.edges) == [[0, 1]])
        #expect(Array(digraph.simpleCycles()).isEmpty)
    }

    @Test("CY-854 the sequences are not Collections and report underestimatedCount 0")
    func notACollection() {
        let graph = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let digraph = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.simpleCycles().underestimatedCount == 0)
        #expect(graph.simpleCycles(maxLength: 3).underestimatedCount == 0)
        #expect(digraph.simpleCycles().underestimatedCount == 0)
        #expect(!((graph.simpleCycles() as Any) is any Collection))
        #expect(!((digraph.simpleCycles() as Any) is any Collection))
        // Array(_:) still gets every element.
        #expect(Array(graph.simpleCycles()).count == 1)
        #expect(Array(digraph.simpleCycles()).count == 1)
    }

    @Test("CY-855 laziness: making the sequence or an iterator reads no row; the first cycle reads each row a bounded number of times")
    func laziness() {
        // A triangle written first, then a 10 000-vertex cycle: the triangle is the first cycle.
        let n = 10_000
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]
            + (0 ..< n).map { UndirectedEdge(3 + $0, 3 + ($0 + 1) % n) }
        let counter = RowCounter()
        let graph = RowCountingGraph(vertexCount: n + 3, edges: edges, counter: counter)
        counter.rows = 0
        let sequence = graph.simpleCycles()
        var iterator = sequence.makeIterator()
        #expect(counter.rows == 0)
        let first = iterator.next()
        #expect(first?.vertices == [0, 1, 2])
        #expect(first?.edges == [0, 1, 2])
        // api.md: the first next() copies the rows once, O(n + m), and searches the copy.
        #expect(counter.rows <= 4 * (n + 3), "\(counter.rows) rows read")
        let afterFirst = counter.rows
        #expect(iterator.next()?.length == n)
        #expect(iterator.next() == nil)
        #expect(counter.rows == afterFirst, "\(counter.rows - afterFirst) more rows read after the copy")
    }

    @Test("CY-856 generic code over some Graph and some DirectedGraph gets the same results as concrete calls")
    func genericCode() {
        func undirectedSummary<G: Graph>(_ g: G) -> (Bool, [[G.Vertex]], [[G.Edges.Index]], Int, Int?, [G.Vertex]?) {
            let cycles = Array(g.simpleCycles())
            return (g.isAcyclic, cycles.map(\.vertices), cycles.map(\.edges), g.cycleBasis().count, g.girth(), g.findCycle()?.vertices)
        }
        func directedSummary<G: DirectedGraph>(_ g: G, maxLength: Int) -> ([[G.Vertex]], [[G.Edges.Index]], Int?) {
            let cycles = Array(g.simpleCycles(maxLength: maxLength))
            return (cycles.map(\.vertices), cycles.map(\.edges), g.girth())
        }
        // CY-119: 0-1 1-2 2-0 0-1 2-2.
        let graph = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)].map { UndirectedEdge($0.0, $0.1) })
        let summary = undirectedSummary(graph)
        #expect(summary.0 == graph.isAcyclic && !summary.0)
        #expect(summary.1 == [[0, 1, 2], [0, 1], [0, 2, 1], [2]])
        #expect(summary.2 == [[0, 1, 2], [0, 3], [2, 1, 3], [4]])
        #expect(summary.3 == 3)
        #expect(summary.4 == 1)
        #expect(summary.5 == [0, 1, 2])
        // CY-453: D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2, bound 2.
        let digraph = ReferenceDirectedMultigraph(edges: [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let directed = directedSummary(digraph, maxLength: 2)
        #expect(directed.0 == [[0], [0, 2], [1, 2], [2]])
        #expect(directed.1 == [[0], [2, 4], [3, 5], [6]])
        #expect(directed.2 == 1)
        #expect(directed.1 == Array(digraph.simpleCycles(maxLength: 2)).map(\.edges))
    }

    @Test("CY-857 index space: on indexed adjacency lists findCycle(), cycleBasis(), simpleCycles() and girth() never hash a vertex")
    func noHashing() {
        let counter = HashCounter()
        func vertex(_ value: Int) -> HashCountingVertex { HashCountingVertex(value: value, counter: counter) }
        // CY-319's envelope: 0-1 0-3 0-4 1-2 1-3 2-3 2-4 3-4.
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 4), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge(vertex($0.0), vertex($0.1)) })
        let digraph = AdjacencyList(edges: pairs.map { DirectedEdge(from: vertex($0.0), to: vertex($0.1)) } + [DirectedEdge(from: vertex(4), to: vertex(0))])
        counter.hashes = 0
        #expect(graph.findCycle()?.vertices.map(\.value) == [0, 1, 2, 3])
        #expect(counter.hashes == 0, "findCycle() hashed \(counter.hashes) times")
        counter.hashes = 0
        #expect(graph.cycleBasis().count == 4)
        #expect(counter.hashes == 0, "cycleBasis() hashed \(counter.hashes) times")
        counter.hashes = 0
        #expect(Array(graph.simpleCycles()).count == 13)
        #expect(counter.hashes == 0, "simpleCycles() hashed \(counter.hashes) times")
        counter.hashes = 0
        #expect(graph.girth() == 3)
        #expect(counter.hashes == 0, "girth() hashed \(counter.hashes) times")
        // The digraph: the envelope's arcs u>v plus 4>0, whose cycles are 0>4>0... closed by 4>0.
        counter.hashes = 0
        let directed = Array(digraph.simpleCycles())
        #expect(directed.allSatisfy { $0.vertices.first?.value == 0 && $0.vertices.last?.value == 4 })
        #expect(counter.hashes == 0, "directed simpleCycles() hashed \(counter.hashes) times")
        counter.hashes = 0
        #expect(digraph.girth() == 2)
        #expect(counter.hashes == 0, "directed girth() hashed \(counter.hashes) times")
    }

    @Test("CY-858 Graph.isAcyclic and DirectedGraph.isAcyclic differ on the views: g.directed is cyclic whenever g has an edge; digraph.undirected is the polytree test")
    func acyclicOnViews() {
        // A tree, a single edge, the empty graph and a lone vertex.
        let tree = ReferencePseudograph(edges: [(0, 1), (1, 2), (1, 3)].map { UndirectedEdge($0.0, $0.1) })
        #expect(tree.isAcyclic)
        #expect(!tree.directed.isAcyclic)
        let edge = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        #expect(edge.isAcyclic && !edge.directed.isAcyclic)
        let empty = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(empty.isAcyclic && empty.directed.isAcyclic)
        // CY-039: D: 0>1 0>2 1>2 is acyclic as a digraph, not as a graph.
        let dag = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 2), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(dag.isAcyclic)
        #expect(!dag.undirected.isAcyclic)
        #expect(dag.undirected.findCycle()?.vertices == [0, 1, 2])
        #expect(dag.undirected.findCycle()?.edges == [0, 2, 1])
        // A directed tree is a polytree: acyclic both ways.
        let polytree = ReferenceDirectedMultigraph(edges: [(1, 0), (1, 2), (3, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(polytree.isAcyclic && polytree.undirected.isAcyclic)
    }

    @Test("CY-859 every returned Cycle survives a Codable round trip and equals and hashes like each of its rotations")
    func codableAndRotation() throws {
        // CY-412: C(0..3) 0-1 2-3; and CY-410: D: 0>1 1>0 1>0 0>1.
        let graph = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1), (2, 3)].map { UndirectedEdge($0.0, $0.1) })
        let digraph = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 0), (1, 0), (0, 1)].map { DirectedEdge(from: $0.0, to: $0.1) })
        var returned = Array(graph.simpleCycles()) + graph.cycleBasis() + Array(digraph.simpleCycles())
        returned.append(try #require(graph.findCycle()))
        #expect(returned.count == 6 + 3 + 4 + 1)
        for cycle in returned {
            let data = try JSONEncoder().encode(cycle)
            let decoded = try JSONDecoder().decode(Cycle<Int, Int>.self, from: data)
            #expect(decoded == cycle)
            #expect(decoded.vertices == cycle.vertices && decoded.edges == cycle.edges)
            for r in 0 ..< cycle.length {
                let rotated = try #require(Cycle(vertices: Array(cycle.vertices[r...] + cycle.vertices[..<r]), edges: Array(cycle.edges[r...] + cycle.edges[..<r])))
                #expect(rotated == cycle)
                #expect(rotated.hashValue == cycle.hashValue)
            }
        }
        // Distinct cycles stay distinct in a Set, though four share their vertices.
        #expect(Set(graph.simpleCycles()).count == 6)
        #expect(Set(digraph.simpleCycles()).count == 4)
    }
}
