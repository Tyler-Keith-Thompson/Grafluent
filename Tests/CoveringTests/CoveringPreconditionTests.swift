// Preconditions, as exit tests (catalog CV-213 – CV-220): a negative or NaN weight, a seed or a
// checked vertex that is not a vertex, a position outside `edges`, a matching or a bipartition of
// another graph. Then the preconditions the catalog does not list: a non-vertex given to
// `isIndependentSet` and `isDominatingSet`, a NaN and a negative `Double` weight to the
// dominating-set approximation, a negative `Int` weight to the vertex-cover approximation and to the
// unindexed path, a seed that is not a vertex next to valid ones, a bipartition of a graph with the
// same vertex count but other vertices. Each exit test builds its inputs inside the closure.
// Generated from cases.md by swiftgen.py, the tests after CV-220 written by hand; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Testing

@Suite("Covering preconditions", .tags(.precondition))
struct CoveringPreconditionTests {
    @Test("CV-213 negative vertex weight (weights >= 0 (the 2-approximation needs it)) traps")
    func cv213() async {
        // V [0, 1]; E [0-1]; w [-1, 2]; approximateMinimumVertexCover(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [-1, 2]
            _ = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        }
    }

    @Test("CV-214 NaN weight (no weight is NaN) traps")
    func cv214() async {
        // V [0, 1]; E [0-1]; w [nan, 1]; approximateMinimumVertexCover(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [Double.nan, 1]
            _ = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        }
    }

    @Test("CV-215 negative weight, dominating (weights >= 0) traps")
    func cv215() async {
        // V [0]; E []; w [-1]; approximateMinimumDominatingSet(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0], edges: [])
            _ = graph.approximateMinimumDominatingSet(weight: { (_: Int) -> Int in -1 })
        }
    }

    @Test("CV-216 seed not a vertex (every seed is a vertex) traps")
    func cv216() async {
        // P(3); maximalIndependentSet(containing: [9])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.maximalIndependentSet(containing: [9])
        }
    }

    @Test("CV-217 check with a non-vertex (every element is a vertex) traps")
    func cv217() async {
        // P(3); isVertexCover([9])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isVertexCover([9])
        }
    }

    @Test("CV-218 check with a non-position (every element is a position of edges) traps")
    func cv218() async {
        // P(3); isEdgeCover([7])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isEdgeCover([7])
        }
    }

    @Test("CV-219 matching from another graph (matching.edges are positions of this graph (vertex count checked)) traps")
    func cv219() async {
        // P(3); minimumEdgeCover(matching: P(5).maximumMatching())
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            // P5's maximum matching: positions [0, 2], on five vertices.
            let other = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
            _ = graph.minimumEdgeCover(matching: other.maximumMatching())
        }
    }

    @Test("CV-220 bipartition of another graph (the bipartition's vertex count is this graph's) traps")
    func cv220() async {
        // P(4); minimumVertexCover(bipartition: P(5).bipartition()!)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let other = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
            _ = graph.minimumVertexCover(bipartition: other.bipartition()!)
        }
    }

    @Test("isIndependentSet with a non-vertex traps")
    func independentSetNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isIndependentSet([0, 9])
        }
    }

    @Test("isDominatingSet with a non-vertex traps")
    func dominatingSetNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isDominatingSet([1, 9])
        }
    }

    @Test("isEdgeCover with a negative position traps")
    func edgeCoverNegativePosition() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isEdgeCover([0, -1])
        }
    }

    @Test("maximalIndependentSet(containing:) with a non-vertex after a valid seed traps")
    func seedNonVertexAfterValid() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.maximalIndependentSet(containing: [0, 9])
        }
    }

    @Test("approximateMinimumDominatingSet(weight:) with a NaN Double weight traps")
    func dominatingNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [1.0, Double.nan]
            _ = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        }
    }

    @Test("approximateMinimumDominatingSet(weight:) with a negative Double weight traps")
    func dominatingNegativeDoubleWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [1.0, -0.5]
            _ = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        }
    }

    @Test("approximateMinimumVertexCover(weight:) with a negative Double weight traps")
    func vertexCoverNegativeDoubleWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [1.0, -0.5]
            _ = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        }
    }

    @Test("approximateMinimumVertexCover(weight:) with a negative weight on a vertex no edge reaches traps (every weight is read)")
    func vertexCoverNegativeWeightIsolated() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
            let weights = [1, 1, -3]
            _ = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        }
    }

    @Test("minimumVertexCover(bipartition:) with sides of another graph that put an edge inside a side traps")
    func bipartitionEdgeInsideSide() async {
        await #expect(processExitsWith: .failure) {
            // P4 0–1–2–3; the sides of 0–2, 1–3 are left [0, 1], right [2, 3], so 0–1 is inside the left side.
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let other = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3)])
            _ = graph.minimumVertexCover(bipartition: other.bipartition()!)
        }
    }
}
