// BidirectionalCompressedSparseRow: the row form with its column form. Hand cases with a self-loop
// (predecessors ascending, in-edge positions naming edges that enter the vertex, degrees),
// degenerate graphs, every initializer, the forwarded reads equal to the base's, transposed(),
// attached maps written through the wrapper and read through in-edge positions, equality, hashing,
// Codable, the checked spellings, exit tests for a vertex out of range, and a property test against
// a brute force over random edge lists, with shrinking.

import AdjacencyListModule
import CompressedSparseRowModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

@Suite("BidirectionalCompressedSparseRow")
struct BidirectionalCompressedSparseRowTests {
    @Test("A small digraph with a self-loop: predecessors ascending, in-edges at the edges' positions, degrees")
    func handComputed() {
        // 0→1, 0→2, 1→2, 2→2, 3→1, 2→0: positions in row-major order are 0:0→1, 1:0→2, 2:1→2, 3:2→0, 4:2→2, 5:3→1.
        let graph = BidirectionalCompressedSparseRow(vertexCount: 4, edges: [
            DirectedEdge(from: 2, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 2, to: 0),
        ])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 2], [2, 0], [2, 2], [3, 1]])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.predecessors(of: 1)) == [0, 3])
        #expect(Array(graph.predecessors(of: 2)) == [0, 1, 2])
        #expect(Array(graph.predecessors(of: 3)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [0, 5])
        #expect(Array(graph.inEdges(of: 2)) == [1, 2, 4])
        #expect(Array(graph.inEdges(of: 0)) == [3])
        for v in 0 ..< 4 {
            for p in graph.inEdges(of: v) { #expect(graph.target(ofEdgeAt: p) == v, "position \(p) enters \(v)") }
            #expect(Array(graph.inEdges(of: v).map { graph.source(ofEdgeAt: $0) }) == Array(graph.predecessors(of: v)))
            #expect(graph.inDegree(of: v) == graph.predecessors(of: v).count)
            #expect(graph.degree(of: v) == graph.outDegree(of: v) + graph.inDegree(of: v))
            #expect(graph.inDegree(ofIndex: v) == graph.inDegree(of: v))
            #expect(Array(graph.predecessorIndices(ofIndex: v)) == Array(graph.predecessors(of: v)))
            #expect(Array(graph.inEdges(ofIndex: v)) == Array(graph.inEdges(of: v)))
        }
        // Vertex 2 has two out-edges and three in-edges; its self-loop is in both counts.
        #expect(graph.degree(of: 2) == 5)
        #expect(Array(graph.successors(of: 2)) == [0, 2])
        var visited: [Int] = []
        graph._forEachPredecessorIndex(ofIndex: 2) { visited.append($0) }
        #expect(visited == [0, 1, 2])
    }

    @Test("Degenerate graphs: no vertices, vertices without edges, one vertex with a loop")
    func degenerate() {
        let empty = BidirectionalCompressedSparseRow()
        #expect(empty.vertexCount == 0 && empty.edgeCount == 0)
        #expect(empty == BidirectionalCompressedSparseRow(vertexCount: 0))
        let bare = BidirectionalCompressedSparseRow(vertexCount: 3)
        #expect(bare.edgeCount == 0)
        for v in 0 ..< 3 { #expect(bare.inDegree(of: v) == 0 && bare.predecessors(of: v).isEmpty && bare.inEdges(of: v).isEmpty) }
        let loop = BidirectionalCompressedSparseRow(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)])
        #expect(Array(loop.predecessors(of: 0)) == [0] && Array(loop.inEdges(of: 0)) == [0] && loop.degree(of: 0) == 2)
    }

    @Test("Every initializer agrees with wrapping the CompressedSparseRow it builds; transposed() is the base's")
    func initializers() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)]
        let rows = CompressedSparseRow(vertexCount: 3, edges: edges)
        let wrapped = BidirectionalCompressedSparseRow(rows)
        #expect(BidirectionalCompressedSparseRow(vertexCount: 3, edges: edges) == wrapped)
        #expect(BidirectionalCompressedSparseRow(vertexCount: 3, edges: AnySequence(edges)) == wrapped)
        let list = AdjacencyList(vertices: 0 ..< 3, edges: edges)
        #expect(BidirectionalCompressedSparseRow(list) == wrapped)
        #expect(wrapped.base == rows)
        #expect(wrapped.transposed() == rows.transposed())
        #expect(wrapped.transposed().edges.map { [$0.source, $0.target] } == [[0, 2], [1, 0], [2, 1]])
        // The forwarded reads are the base's.
        #expect(Array(wrapped.vertices) == Array(rows.vertices))
        #expect(wrapped.edges.map { [$0.source, $0.target] } == rows.edges.map { [$0.source, $0.target] })
        for v in 0 ..< 3 {
            #expect(Array(wrapped.successors(of: v)) == Array(rows.successors(of: v)))
            #expect(Array(wrapped.outEdges(of: v)) == Array(rows.outEdges(of: v)))
            #expect(wrapped.outDegree(of: v) == rows.outDegree(of: v))
        }
        #expect(wrapped.contains(edge: DirectedEdge(from: 2, to: 0)) && !wrapped.contains(edge: DirectedEdge(from: 0, to: 2)))
        #expect(wrapped.vertexIndexBound == 3 && wrapped.edgeIndexBound == 3 && wrapped.edgeIndex(of: 2) == 2)
        #expect(wrapped.generation == rows.generation)
    }

    @Test("Attached maps: written through the wrapper, read through the base and through in-edge positions")
    func maps() {
        var graph = BidirectionalCompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 2)])
        let weight = graph.addEdgeMap(default: 1.0)
        let label = graph.addVertexMap(default: "")
        graph[weight, ofEdgeAt: 2] = 5
        graph[label, of: 1] = "hub"
        graph[label, ofVertexAt: 2] = "spoke"
        #expect(graph[weight, ofEdgeAt: 2] == 5 && graph[weight, ofEdgeAt: 0] == 1)
        #expect(graph.base[weight, ofEdgeAt: 2] == 5)
        #expect(graph[label, of: 1] == "hub" && graph[label, ofVertexAt: 2] == "spoke" && graph[label, of: 0] == "")
        // Positions are row-major: 0:0→1, 1:1→2, 2:2→1. The in-edges are positions, so the map
        // reads through them: 1 enters 2 through position 1, and 0 and 2 enter 1 through 0 and 2.
        #expect(graph.inEdges(of: 2).map { graph[weight, ofEdgeAt: $0] } == [1])
        #expect(graph.inEdges(of: 1).map { graph[weight, ofEdgeAt: $0] } == [1, 5])
        #expect(graph.values(of: weight)[2] == 5)
        graph.removeEdgeMap(weight)
        graph.removeVertexMap(label)
        #expect(graph.edgeCount == 3)
    }

    @Test("Equality and hashing follow the row form; Codable round-trips through the row form's arrays")
    func conformances() throws {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)]
        let a = BidirectionalCompressedSparseRow(vertexCount: 3, edges: edges)
        let b = BidirectionalCompressedSparseRow(vertexCount: 3, edges: edges.reversed())
        let c = BidirectionalCompressedSparseRow(vertexCount: 4, edges: edges)
        let d = BidirectionalCompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1)])
        #expect(a == b && a.hashValue == b.hashValue && a != c && a != d)
        #expect(a.description == a.base.description)
        let data = try JSONEncoder().encode(a)
        #expect(try JSONDecoder().decode(CompressedSparseRow.self, from: data) == a.base)
        let decoded = try JSONDecoder().decode(BidirectionalCompressedSparseRow.self, from: data)
        #expect(decoded == a)
        #expect(Array(decoded.predecessors(of: 0)) == [1] && Array(decoded.inEdges(of: 2)) == [2])
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(BidirectionalCompressedSparseRow.self, from: Data(#"{"offsets": [0, 2, 2], "targets": [1, 1]}"#.utf8)) }
    }

    @Test("The checked spellings answer as the trapping ones and throw for a vertex out of range")
    func checked() throws {
        let graph = BidirectionalCompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        #expect(try Array(graph.predecessors(checked: 1)) == [0, 2])
        #expect(try Array(graph.inEdges(checked: 1)) == [0, 1])
        #expect(try graph.inDegree(checked: 1) == 2)
        #expect(try Array(graph.successors(checked: 0)) == [1])
        for v in [-1, 3] {
            #expect(throws: VertexNotFound.self) { try graph.predecessors(checked: v) }
            #expect(throws: VertexNotFound.self) { try graph.inEdges(checked: v) }
            #expect(throws: VertexNotFound.self) { try graph.inDegree(checked: v) }
        }
    }

    @Test("Against a brute force over random edge lists: predecessors, in-edges and degrees", .tags(.randomized))
    func bruteForce() async {
        let pairs = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 1 ... 7)) { raw, n in
            let edges = raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) }
            let graph = BidirectionalCompressedSparseRow(vertexCount: n, edges: edges)
            let distinct = Set(edges.map { [$0.source, $0.target] })
            #expect(graph.edgeCount == distinct.count, "\(edges)")
            var total = 0
            for v in 0 ..< n {
                let sources = distinct.filter { $0[1] == v }.map { $0[0] }.sorted()
                #expect(Array(graph.predecessors(of: v)) == sources, "predecessors of \(v); \(edges)")
                #expect(graph.inDegree(of: v) == sources.count, "\(edges)")
                let positions = Array(graph.inEdges(of: v))
                #expect(positions.map { graph.source(ofEdgeAt: $0) } == sources, "in-edge positions of \(v); \(edges)")
                #expect(positions.allSatisfy { graph.target(ofEdgeAt: $0) == v }, "\(edges)")
                #expect(graph.degree(of: v) == graph.outDegree(of: v) + sources.count, "\(edges)")
                total += graph.inDegree(of: v)
            }
            #expect(total == graph.edgeCount, "\(edges)")
            #expect(graph.transposed() == graph.base.transposed(), "\(edges)")
            #expect(BidirectionalCompressedSparseRow(graph.transposed()).transposed() == graph.base, "\(edges)")
        }
    }
}

@Suite("BidirectionalCompressedSparseRow preconditions", .tags(.precondition))
struct BidirectionalCompressedSparseRowPreconditionTests {
    @Test("predecessors(of:) traps on a vertex out of range")
    func predecessorsOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = BidirectionalCompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.predecessors(of: 2)
        }
    }

    @Test("inEdges(of:) traps on a negative vertex")
    func inEdgesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = BidirectionalCompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.inEdges(of: -1)
        }
    }

    @Test("inDegree(of:) traps on a vertex out of range")
    func inDegreeOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = BidirectionalCompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.inDegree(of: 5)
        }
    }
}
