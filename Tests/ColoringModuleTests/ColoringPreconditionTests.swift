// Preconditions, as exit tests (catalog CO-215, CO-216, CO-248 – CO-252): `edgeColoring()` on a
// graph with a self-loop or parallel edges; an order that misses, repeats or adds a vertex; a colour
// asked for a non-vertex or an index out of range. Then the preconditions the catalog does not list:
// an order with the right length that repeats one vertex and misses another, or swaps one for a
// non-vertex; a negative index; a non-vertex on a graph without vertex indices, to `color(of:)` and
// in an order; `minimumColoring().color(of:)`; `edgeColoring()` on parallel arcs through
// `AdjacencyList.undirected`, on `graph.directed.undirected`, and on a self-loop away from the first
// vertex; `color(ofEdgeAt:)` with a position the graph does not have, with and without edge indices;
// a negative preset colour and two adjacent vertices preset alike. Each exit test builds its inputs
// inside the closure. Generated from cases.md by swiftgen.py, the tests after CO-252 written by hand
// (extra_traps.swift); see README.md.

import AdjacencyListModule
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
/// Rows are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Coloring preconditions", .tags(.precondition))
struct ColoringPreconditionTests {
    @Test("CO-215 self-loop (simple graph) traps")
    func co215() async {
        // V [0]; E [0-0]; edgeColoring()
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0], edges: [UndirectedEdge(0, 0)])
            _ = graph.edgeColoring()
        }
    }

    @Test("CO-216 parallel edges (simple graph) traps")
    func co216() async {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; edgeColoring()
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2)])
            _ = graph.edgeColoring()
        }
    }

    @Test("CO-248 order misses a vertex (every vertex exactly once) traps")
    func co248() async {
        // P(3); greedyColoring(order: [0, 1])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 1])
        }
    }

    @Test("CO-249 order repeats a vertex traps")
    func co249() async {
        // P(3); greedyColoring(order: [0, 1, 1, 2])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 1, 1, 2])
        }
    }

    @Test("CO-250 order names a non-vertex traps")
    func co250() async {
        // P(3); greedyColoring(order: [0, 1, 2, 3])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 1, 2, 3])
        }
    }

    @Test("CO-251 color(of:) a non-vertex traps")
    func co251() async {
        // P(3); greedyColoring().color(of: 9)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring().color(of: 9)
        }
    }

    @Test("CO-252 color(ofIndex:) out of range (index in 0..<vertexCount) traps")
    func co252() async {
        // P(3); greedyColoring().color(ofIndex: 3)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring().color(ofIndex: 3)
        }
    }

    @Test("An order of the right length that repeats one vertex and misses another traps")
    func orderRepeatsAndMisses() async {
        // P3; greedyColoring(order: [0, 0, 2]): three entries, as many as vertices, but 1 is missing.
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 0, 2])
        }
    }

    @Test("An order of the right length with a non-vertex in place of a vertex traps")
    func orderSwapsInNonVertex() async {
        // P3; greedyColoring(order: [0, 9, 2]).
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(order: [0, 9, 2])
        }
    }

    @Test("color(ofIndex:) with a negative index traps")
    func negativeIndex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring().color(ofIndex: -1)
        }
    }

    @Test("color(of:) a non-vertex on a graph without vertex indices traps")
    func unindexedNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
            _ = graph.greedyColoring(strategy: .saturationLargestFirst).color(of: "z")
        }
    }

    @Test("An order with a non-vertex on a graph without vertex indices traps")
    func unindexedOrderNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
            _ = graph.greedyColoring(order: ["a", "b", "z"])
        }
    }

    @Test("minimumColoring().color(of:) a non-vertex traps")
    func minimumColoringNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
            _ = graph.minimumColoring().color(of: 5)
        }
    }

    @Test("edgeColoring() on AdjacencyList.undirected with arcs 0→1 and 1→0 (parallel edges) traps")
    func parallelArcs() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 0)]).undirected
            _ = graph.edgeColoring()
        }
    }

    @Test("edgeColoring() on graph.directed.undirected (every edge a parallel pair) traps")
    func directedUndirected() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.directed.undirected.edgeColoring()
        }
    }

    @Test("edgeColoring() with a self-loop at the last vertex, after simple edges, traps")
    func selfLoopLater() async {
        // C4 with a loop at 3, listed last.
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 3)])
            _ = graph.edgeColoring()
        }
    }

    @Test("edgeColoring() on a ReferencePseudograph whose parallel pair comes last traps")
    func parallelLater() async {
        // P4 then a second copy of 2–3.
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 2)])
            _ = graph.edgeColoring()
        }
    }

    @Test("color(ofEdgeAt:) with a position the graph does not have traps (edge indices)")
    func foreignEdgePosition() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeColoring().color(ofEdgeAt: 7)
        }
    }

    @Test("color(ofEdgeAt:) with a position the graph does not have traps (no edge indices: the binary search misses)")
    func foreignEdgePositionUnindexed() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyEdgeColoring().color(ofEdgeAt: 2)
        }
    }

    @Test("greedyColoring(strategy:presetColor:) with a negative preset colour traps")
    func negativePreset() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.greedyColoring { $0 == 2 ? -1 : nil }
        }
    }

    @Test("greedyColoring(strategy:presetColor:) with two adjacent vertices preset alike traps")
    func adjacentPresets() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.greedyColoring(strategy: .saturationLargestFirst) { $0 == 0 || $0 == 1 ? 3 : nil }
        }
    }
}
