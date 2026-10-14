// Preconditions of edge betweenness and betweenness from pivots, as exit tests: weights that are
// not > 0 (zero, NaN, a loop's included), a pivot that is not a vertex, a repeated pivot, no pivot
// in a nonempty graph, a pivot count outside 1...n, and `score(ofEdgeAt:)` off the graph. Each exit
// test builds its inputs inside the closure.

import AdjacencyListModule
import AdjacencyMatrixModule
import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Edge betweenness and pivot preconditions", .tags(.precondition))
struct EdgeBetweennessPreconditionTests {
    @Test("edgeBetweennessCentrality(weight:) traps on a zero weight (undirected)")
    func zeroWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [0, 1]
            _ = graph.edgeBetweennessCentrality(weight: { w[$0] })
        }
    }

    @Test("edgeBetweennessCentrality(weight:) traps on NaN (directed)")
    func nanWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w: [Double] = [1, .nan]
            _ = graph.edgeBetweennessCentrality(weight: { w[$0] })
        }
    }

    @Test("edgeBetweennessCentrality(weight:) checks every weight, a self-loop's too")
    func loopWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
            let w = [1, -1]
            _ = graph.edgeBetweennessCentrality(weight: { w[$0] })
        }
    }

    @Test("edgeBetweennessCentrality(weight:pivots:) traps on a zero weight")
    func zeroWeightPivots() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeBetweennessCentrality(weight: { _ in 0.0 }, pivots: [0])
        }
    }

    @Test("betweennessCentrality(weight:pivotCount:using:) traps on a zero weight (directed)")
    func zeroWeightRandom() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.betweennessCentrality(weight: { _ in 0 }, pivotCount: 2, using: &generator)
        }
    }

    @Test("betweennessCentrality(pivots:) traps on a pivot that is not a vertex (undirected)")
    func missingPivot() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.betweennessCentrality(pivots: [0, 3])
        }
    }

    @Test("edgeBetweennessCentrality(pivots:) traps on a pivot that is not a vertex (directed)")
    func missingPivotDirected() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.edgeBetweennessCentrality(pivots: [-1])
        }
    }

    @Test("betweennessCentrality(pivots:) traps on a repeated pivot (directed)")
    func repeatedPivot() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.betweennessCentrality(pivots: [1, 2, 1])
        }
    }

    @Test("edgeBetweennessCentrality(weight:pivots:) traps on a repeated pivot (undirected)")
    func repeatedPivotEdges() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeBetweennessCentrality(weight: { _ in 1 }, pivots: [0, 0])
        }
    }

    @Test("betweennessCentrality(pivots:) traps on no pivot in a nonempty graph")
    func noPivots() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.betweennessCentrality(pivots: [])
        }
    }

    @Test("edgeBetweennessCentrality(pivots:) traps on no pivot in a nonempty graph (directed)")
    func noPivotsEdges() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 1, edges: [])
            _ = graph.edgeBetweennessCentrality(pivots: [])
        }
    }

    @Test("betweennessCentrality(pivotCount: 0) traps on a nonempty graph")
    func zeroPivotCount() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.betweennessCentrality(pivotCount: 0, using: &generator)
        }
    }

    @Test("edgeBetweennessCentrality(pivotCount:) traps above vertexCount (directed)")
    func tooManyPivots() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.edgeBetweennessCentrality(pivotCount: 4, using: &generator)
        }
    }

    @Test("edgeBetweennessCentrality(pivotCount:) traps on a negative count")
    func negativePivotCount() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.edgeBetweennessCentrality(pivotCount: -1, using: &generator)
        }
    }

    @Test("betweennessCentrality(pivotCount: 1) traps on an empty graph")
    func pivotOnEmpty() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>()
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.betweennessCentrality(pivotCount: 1, using: &generator)
        }
    }

    @Test("score(ofEdgeAt:) traps on a position past the edges (integer positions)")
    func scoreOffGraph() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeBetweennessCentrality().score(ofEdgeAt: 2)
        }
    }

    @Test("score(ofEdgeAt:) traps on a cell that is not an edge (AdjacencyMatrix)")
    func scoreOffMatrix() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            let other = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 0)])
            _ = graph.edgeBetweennessCentrality().score(ofEdgeAt: other.edges.indices.first!)
        }
    }
}
