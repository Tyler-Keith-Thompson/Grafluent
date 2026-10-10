// Preconditions, as exit tests (catalog trap rows): a start or end that is not a vertex of the
// graph, the empty graph included; a tour heuristic on a graph that is not complete; a tour to
// improve that does not list every vertex once; a NaN weight; more than 31 vertices for Held–Karp.
// Then the preconditions the catalog does not list (extra_traps.swift): each on the other entry
// points and kinds of graph, a vertex not in a graph without indices, a NaN weight in every tour, an
// infinite weight and the matching's bound in Christofides, a missing pair beside parallel edges and
// self-loops. Each exit test builds its inputs inside the closure. Generated from cases.md by
// swiftgen.py; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

/// A directed graph with no vertex or edge indices: only the protocol's vertex-level members. Out-rows
/// are in position order; parallel edges and self-loops are kept.
private struct UnindexedDirectedGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]

    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
}

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members. Rows
/// are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Tours preconditions", .tags(.precondition))
struct ToursPreconditionTests {
    @Test("TO-285 start not a vertex traps (the start is not a vertex of the graph)")
    func to285() async {
        // C(3); eulerianCircuit(from: 7)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.eulerianCircuit(from: 7)
        }
    }

    @Test("TO-286 start not a vertex traps (the start is not a vertex of the graph)")
    func to286() async {
        // P(3); eulerianTrail(from: 7)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.eulerianTrail(from: 7)
        }
    }

    @Test("TO-287 start not a vertex traps (the start is not a vertex of the graph)")
    func to287() async {
        // Cd(3); eulerianCircuit(from: 7)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
            _ = graph.eulerianCircuit(from: 7)
        }
    }

    @Test("TO-288 start not a vertex traps (the start is not a vertex of the graph)")
    func to288() async {
        // Pd(3); eulerianTrail(from: 7)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.eulerianTrail(from: 7)
        }
    }

    @Test("TO-289 start not a vertex of the empty graph traps (the start is not a vertex of the graph)")
    func to289() async {
        // V []; E []; eulerianCircuit(from: 0)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [], edges: [])
            _ = graph.eulerianCircuit(from: 0)
        }
    }

    @Test("TO-397 start not a vertex traps (the start is not a vertex of the graph)")
    func to397() async {
        // P(3); hamiltonianPath(from: 7)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.hamiltonianPath(from: 7)
        }
    }

    @Test("TO-398 end not a vertex traps (the end is not a vertex of the graph)")
    func to398() async {
        // P(3); hamiltonianPath(from: 0, to: 7)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.hamiltonianPath(from: 0, to: 7)
        }
    }

    @Test("TO-399 start not a vertex traps (the start is not a vertex of the graph)")
    func to399() async {
        // Pd(3); hamiltonianPath(from: 7)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.hamiltonianPath(from: 7)
        }
    }

    @Test("TO-492 not complete traps (the graph is not complete (0 and 2 are not adjacent))")
    func to492() async {
        // C(4) weight 1; nearestNeighborTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            _ = graph.nearestNeighborTour(weight: { _ in 1 })
        }
    }

    @Test("TO-493 not complete traps (the graph is not complete)")
    func to493() async {
        // C(4) weight 1; christofidesTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            _ = graph.christofidesTour(weight: { _ in 1 })
        }
    }

    @Test("TO-494 not complete traps (the graph is not complete)")
    func to494() async {
        // C(4) weight 1; twoOptTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            _ = graph.twoOptTour(weight: { _ in 1 })
        }
    }

    @Test("TO-495 tour misses a vertex traps (the tour does not list every vertex once)")
    func to495() async {
        // pts[(0,0),(0,1),(1,1),(1,0)]; twoOptTour(improving: [0, 1, 2], weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
            let weights = [1, 2, 1, 1, 2, 1]  // Manhattan distances of (0,0), (0,1), (1,1), (1,0)
            let tour = Cycle([0, 1, 2], in: graph)!
            _ = graph.twoOptTour(improving: tour, weight: { weights[$0] })
        }
    }

    @Test("TO-496 tour repeats a vertex traps (the tour does not list every vertex once)")
    func to496() async {
        // pts[(0,0),(0,1),(1,1),(1,0)]; twoOptTour(improving: [0, 1, 2, 1], weight:)
        // The tour the row describes is not a `Cycle` at all.
        #expect(Cycle<Int, Int>(vertices: [0, 1, 2, 1], edges: [0, 3, 4, 1]) == nil)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
            let weights = [1, 2, 1, 1, 2, 1]  // Manhattan distances of (0,0), (0,1), (1,1), (1,0)
            // A `Cycle` cannot repeat a vertex (`Cycle(vertices: [0, 1, 2, 1], …)` is nil, checked in the test
            // above), so four vertices with one that is not the graph's stand for a tour that does not list
            // every vertex once.
            let tour = Cycle(vertices: [0, 1, 2, 9], edges: [0, 3, 5, 2])!
            _ = graph.twoOptTour(improving: tour, weight: { weights[$0] })
        }
    }

    @Test("TO-497 start not a vertex traps (the start is not a vertex of the graph)")
    func to497() async {
        // pts[(0,0),(0,1),(1,1),(1,0)]; nearestNeighborTour(from: 7, weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
            let weights = [1, 2, 1, 1, 2, 1]  // Manhattan distances of (0,0), (0,1), (1,1), (1,0)
            _ = graph.nearestNeighborTour(from: 7, weight: { weights[$0] })
        }
    }

    @Test("TO-498 NaN weight traps (a weight is NaN)")
    func to498() async {
        // Double K(3) weights 1.0, nan, 2.0; nearestNeighborTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.nearestNeighborTour(weight: { weights[$0] })
        }
    }

    @Test("TO-499 NaN weight traps (a weight is NaN)")
    func to499() async {
        // Double K(3) weights 1.0, nan, 2.0; christofidesTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
    }

    @Test("TO-500 NaN weight traps (a weight is NaN)")
    func to500() async {
        // Double K(3) weights 1.0, nan, 2.0; shortestTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
    }

    @Test("TO-501 too many vertices traps (more than 31 vertices (JGraphT HeldKarpTSP's limit))")
    func to501() async {
        // K(32) weight 1; shortestTour(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 32, edges: (0 ..< 32).flatMap { i in (i + 1 ..< 32).map { UndirectedEdge(i, $0) } })
            _ = graph.shortestTour(weight: { _ in 1 })
        }
    }

    @Test("A start or end that is not a vertex traps in every entry point that takes one, on both kinds of graph")
    func vertexNotInTheGraph() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [], edges: [])
            _ = graph.eulerianCircuit(from: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.eulerianTrail(from: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.hamiltonianPath(from: 7, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.hamiltonianPath(from: 0, to: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.hamiltonianPath(from: 7, to: 2)
        }
        await #expect(processExitsWith: .failure) {
            // An edgeless graph: the trivial trail would be at the start, but 7 is not a vertex.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [])
            _ = graph.eulerianTrail(from: 7)
        }
    }

    @Test("A vertex that is not the graph's traps on graphs without vertex indices")
    func unindexedVertexNotInTheGraph() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
            _ = graph.eulerianCircuit(from: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
            _ = graph.hamiltonianPath(from: "a", to: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.eulerianTrail(from: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.hamiltonianPath(from: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
            _ = graph.nearestNeighborTour(from: "z", weight: { _ in 1 })
        }
    }

    @Test("The heuristics trap on a missing pair even when parallel edges and self-loops make up the edge count, and from a start")
    func notCompleteBesideParallelEdges() async {
        // K(4) less the pair {0, 2}, with a second copy of {0, 1} and a self-loop at 2: six edges, as many
        // as K(4) has, yet 0 and 2 are not adjacent.
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.nearestNeighborTour(weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.nearestNeighborTour(from: 3, weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.christofidesTour(weight: { _ in 1.0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            _ = graph.twoOptTour(weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            // Only the tour's vertices are read, so its edges need not be the graph's.
            let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 2)])
            let tour = Cycle(vertices: [0, 1, 2, 3], edges: [0, 3, 5, 2])!
            _ = graph.twoOptTour(improving: tour, weight: { _ in 1 })
        }
    }

    @Test("A NaN weight traps in every tour, a heavier parallel copy's included")
    func nanEverywhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.twoOptTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            let tour = Cycle([0, 1, 2], in: graph)!
            _ = graph.twoOptTour(improving: tour, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 2.0]
            _ = graph.nearestNeighborTour(from: 2, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // The NaN is on the second copy of {0, 1}, which the lightest-copy rule would never use.
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .nan, 1.0, 1.0]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Held–Karp needs no completeness, and the NaN still traps.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            let weights: [Float] = [1, 1, .nan, 1]
            _ = graph.shortestTour(weight: { weights[$0] })
        }
    }

    @Test("Christofides traps on an infinite weight and past the matching's bound, n · (2 · |weight| + 1) ≤ W.max / 8")
    func christofidesBounds() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1.0, .infinity, 2.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            // Int8: 3 · (2 · 10 + 1) = 63 > 127 / 8.
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Int8] = [10, 10, 10]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let weights: [Double] = [1e308, 1.0, 1.0]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
    }

    @Test("A tour to improve traps unless it lists every vertex of the graph exactly once: too long, or with a vertex of another graph")
    func improvingTheWrongTour() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let tour = Cycle(vertices: [0, 1, 2, 3], edges: [0, 1, 2, 3])!
            _ = graph.twoOptTour(improving: tour, weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            let tour = Cycle(vertices: [0, 1, 5], edges: [0, 2, 1])!
            _ = graph.twoOptTour(improving: tour, weight: { _ in 1 })
        }
    }

    @Test("Held–Karp traps above 31 vertices whatever the edges, a cycle of 32 vertices and Double weights")
    func heldKarpLimit() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 32, edges: (0 ..< 32).map { UndirectedEdge($0, ($0 + 1) % 32) })
            _ = graph.shortestTour(weight: { _ in 1.5 })
        }
    }
}
