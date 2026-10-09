// Conformance: the values and the sequence are Sendable when the graph is and can be used in a
// Task; they hold a copy of the graph, so mutating the original afterwards changes nothing; the
// sequence is lazy (making it or an iterator reads no row) and not a Collection, each iterator
// starts over, and a copied iterator resumes independently; generic code gets the same answers; the
// whole-graph entry points on an indexed adjacency list never hash a vertex (api.md: they run in
// index space). Preconditions are in CliquePreconditionTests.swift. Values are catalog cells of
// CQ-101's graph (K(0..2), 2-3: CQ-101, CQ-301, CQ-303, CQ-401 – CQ-405) and the karate club
// (CQ-121, CQ-123, CQ-211, CQ-212, CQ-319), or were computed with the catalog's reference (`ref.py`)
// where noted. Case IDs (CQ-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

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

/// Counts every row an algorithm asks for.
private final class RowCounter: @unchecked Sendable {
    var rows = 0
}

/// An undirected multigraph on 0..<vertexCount with vertex and edge indices that counts every row
/// it is asked for. Rows are in position order, a self-loop twice.
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

@Suite("Cliques conformance: Sendable, value semantics, laziness, index space", .tags(.conformance))
struct CliqueConformanceTests {
    @Test("CQ-101 CQ-301 CQ-402 the sequence, its iterator and both values are Sendable when the graph is: a Task can use them")
    func sendable() async {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let sequence = requireSendable(graph.maximalCliques())
        let all = await Task { Array(sequence) }.value
        #expect(Set(all) == [[2, 3], [0, 1, 2]])
        let iterator = requireSendable(graph.maximalCliques().makeIterator())
        let viaIterator = await Task {
            var it = iterator
            var found: [[Int]] = []
            while let clique = it.next() { found.append(clique) }
            return found
        }.value
        #expect(Set(viaIterator) == [[2, 3], [0, 1, 2]])
        let cores = requireSendable(graph.coreNumbers())
        let coreNumbers = await Task { [0, 1, 2, 3].map { cores.coreNumber(of: $0) } }.value
        #expect(coreNumbers == [2, 2, 2, 1])
        let values = requireSendable(graph.clusteringCoefficients())
        let triangles = await Task { [0, 1, 2, 3].map { values.triangleCount(of: $0) } }.value
        #expect(triangles == [1, 1, 1, 0])
    }

    @Test("value semantics: mutating the graph after making the sequence, an iterator and both values changes none of them")
    func valueSemantics() {
        // U: K(0..2), 2-3; then 3-0 and 3-1 make it K₄ (`ref.py`: one clique [0, 1, 2, 3], cores
        // [3, 3, 3, 3], 3 triangles per vertex).
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        var graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let sequence = graph.maximalCliques()
        var iterator = sequence.makeIterator()
        let cores = graph.coreNumbers()
        let values = graph.clusteringCoefficients()
        graph.insert(edge: UndirectedEdge(3, 0))
        graph.insert(edge: UndirectedEdge(3, 1))
        #expect(Set(sequence) == [[2, 3], [0, 1, 2]])
        var fromIterator: [[Int]] = []
        while let clique = iterator.next() { fromIterator.append(clique) }
        #expect(Set(fromIterator) == [[2, 3], [0, 1, 2]])
        let coresByIndex = (0 ..< 4).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == [2, 2, 2, 1])
        #expect(cores.degeneracyOrdering == [3, 0, 1, 2])
        let triangles = (0 ..< 4).map { values.triangleCount(ofIndex: $0) }
        #expect(triangles == [1, 1, 1, 0])
        #expect(values.transitivity == 0.6)
        #expect(values.averageClustering == 0.5833333333333334)
        // The mutated graph has its own answers.
        #expect(Array(graph.maximalCliques()) == [[0, 1, 2, 3]])
        let after = graph.coreNumbers()
        let afterByIndex = (0 ..< 4).map { after.coreNumber(ofIndex: $0) }
        #expect(afterByIndex == [3, 3, 3, 3])
        #expect(graph.triangleCount(of: 3) == 3)
    }

    @Test("CQ-121 each iterator starts over, and a copied iterator resumes where the copy was made, independently")
    func iteratorsStartOverAndCopy() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let sequence = graph.maximalCliques()
        let first = Array(sequence)
        let second = Array(sequence)
        #expect(first.count == 36)
        #expect(second == first)
        var iterator = sequence.makeIterator()
        for _ in 0 ..< 10 { _ = iterator.next() }
        var copy = iterator
        var rest: [[Int]] = []
        while let clique = iterator.next() { rest.append(clique) }
        var restOfCopy: [[Int]] = []
        while let clique = copy.next() { restOfCopy.append(clique) }
        #expect(rest == Array(first.dropFirst(10)))
        #expect(restOfCopy == rest)
        #expect(iterator.next() == nil)
        // Stopping early is allowed: the first clique of a fresh iterator is the sequence's first.
        var fresh = sequence.makeIterator()
        #expect(fresh.next() == first.first)
    }

    @Test("laziness: making the sequence or an iterator reads no row; a lazy filter by size is the sequence filtered; not a Collection")
    func laziness() {
        // CQ-122: U: K(0..3), K(3..6), 0-6.
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6), (0, 6)
        ]
        let counter = RowCounter()
        let graph = RowCountingGraph(vertexCount: 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, counter: counter)
        counter.rows = 0
        let sequence = graph.maximalCliques()
        var iterator = sequence.makeIterator()
        #expect(counter.rows == 0, "\(counter.rows) rows read before the first next()")
        let first = iterator.next()
        #expect(first != nil)
        #expect(counter.rows > 0)
        let all = Array(sequence)
        #expect(Set(all) == [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]])
        let large = Array(sequence.lazy.filter { $0.count >= 4 })
        #expect(large == all.filter { $0.count >= 4 })
        #expect(!((sequence as Any) is any Collection))
    }

    @Test("generic code over some Graph gets the same answers as concrete calls")
    func genericCode() {
        func summary<G: Graph>(_ g: G) -> (cliques: [[G.Vertex]], maximum: [G.Vertex], omega: Int, ordering: [G.Vertex], triangles: Int, transitivity: Double, average: Double) {
            (Array(g.maximalCliques()), g.maximumClique(), g.cliqueNumber(), g.coreNumbers().degeneracyOrdering,
             g.triangleCount(), g.transitivity(), g.averageClustering())
        }
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let generic = summary(graph)
        #expect(Set(generic.cliques) == [[2, 3], [0, 1, 2]])
        #expect(generic.cliques == Array(graph.maximalCliques()))
        #expect(generic.maximum == [0, 1, 2])
        #expect(generic.omega == 3)
        #expect(generic.ordering == [3, 0, 1, 2])
        #expect(generic.triangles == 1)
        #expect(generic.transitivity == 0.6)
        #expect(generic.average == 0.5833333333333334)
        // Through an existential, as well.
        let erased: any Graph<Int> = graph
        #expect(erased.cliqueNumber() == 3)
        #expect(erased.triangleCount() == 1)
    }

    @Test("index space: on UndirectedAdjacencyList the whole-graph entry points never hash a vertex")
    func noHashing() {
        let counter = HashCounter()
        func vertex(_ value: Int) -> HashCountingVertex { HashCountingVertex(value: value, counter: counter) }
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge(vertex($0.0), vertex($0.1)) })
        counter.hashes = 0
        let cliques = Array(graph.maximalCliques()).map { $0.map(\.value) }
        #expect(counter.hashes == 0, "maximalCliques() hashed \(counter.hashes) times")
        #expect(Set(cliques) == [[2, 3], [0, 1, 2]])
        counter.hashes = 0
        #expect(graph.maximumClique().map(\.value) == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        #expect(counter.hashes == 0, "maximumClique() or cliqueNumber() hashed \(counter.hashes) times")
        counter.hashes = 0
        let cores = graph.coreNumbers()
        let coresByIndex = (0 ..< 4).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == [2, 2, 2, 1])
        #expect(cores.degeneracyOrdering.map(\.value) == [3, 0, 1, 2])
        #expect(cores.kCore(2).map(\.value) == [0, 1, 2])
        #expect(counter.hashes == 0, "coreNumbers() hashed \(counter.hashes) times")
        counter.hashes = 0
        let values = graph.clusteringCoefficients()
        let triangles = (0 ..< 4).map { values.triangleCount(ofIndex: $0) }
        #expect(triangles == [1, 1, 1, 0])
        #expect(graph.triangleCount() == 1)
        #expect(graph.transitivity() == 0.6)
        #expect(graph.averageClustering() == 0.5833333333333334)
        #expect(counter.hashes == 0, "the triangle pass hashed \(counter.hashes) times")
    }
}
