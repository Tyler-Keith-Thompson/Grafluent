// Preconditions, as exit tests (catalog §Preconditions): the source as the sink in every s–t entry
// point; a terminal that is not a vertex; a negative capacity, also off every path; a NaN or
// infinite capacity; the capacities at the source summing past the type's maximum, though the value
// would fit; negative capacities for the global cut, Gomory–Hu and minimum-cost flow; a cost total
// past the cost type. Then the preconditions the catalog does not list (extra_traps.swift): each on
// the other entry points and kinds of graph, a terminal not in a graph without indices,
// `GomoryHuTree.minimumCut(between:and:)` with u = v, a floating sum that overflows to infinity.
// Each exit test builds its inputs inside the closure. Generated from cases.md by swiftgen.py; see
// README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

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

@Suite("Flows preconditions", .tags(.precondition))
struct FlowsPreconditionTests {
    @Test("FL-213 source is the sink traps (source == sink (NetworkX raises))")
    func fl213() async {
        // V [0, 1]; E [0→1 5]; maximumFlow(from: 0, to: 0, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 0, capacity: { _ in 5 })
        }
    }

    @Test("FL-214 source is the sink traps (source == sink (NetworkX raises))")
    func fl214() async {
        // V [0, 1]; E [0→1 5]; edmondsKarpMaximumFlow(from: 0, to: 0, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edmondsKarpMaximumFlow(from: 0, to: 0, capacity: { _ in 5 })
        }
    }

    @Test("FL-215 source is the sink traps (source == sink (NetworkX raises))")
    func fl215() async {
        // V [0, 1]; E [0→1 5]; dinicMaximumFlow(from: 0, to: 0, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dinicMaximumFlow(from: 0, to: 0, capacity: { _ in 5 })
        }
    }

    @Test("FL-216 source is the sink traps (source == sink (NetworkX raises))")
    func fl216() async {
        // V [0, 1]; E [0→1 5]; maximumFlowValue(from: 0, to: 0, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlowValue(from: 0, to: 0, capacity: { _ in 5 })
        }
    }

    @Test("FL-217 source is the sink traps (source == sink (NetworkX raises))")
    func fl217() async {
        // V [0, 1]; E [0→1 5]; minimumCut(from: 0, to: 0, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCut(from: 0, to: 0, capacity: { _ in 5 })
        }
    }

    @Test("FL-218 source not a vertex traps (not a vertex)")
    func fl218() async {
        // V [0, 1]; E [0→1 5]; maximumFlow(from: 7, to: 1, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 7, to: 1, capacity: { _ in 5 })
        }
    }

    @Test("FL-219 sink not a vertex traps (not a vertex)")
    func fl219() async {
        // V [0, 1]; E [0→1 5]; maximumFlow(from: 0, to: 7, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 7, capacity: { _ in 5 })
        }
    }

    @Test("FL-220 negative capacity traps (a capacity is negative)")
    func fl220() async {
        // V [0, 1]; E [0→1 -1]; maximumFlow(from: 0, to: 1, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in -1 })
        }
    }

    @Test("FL-221 negative capacity off every path traps (a capacity is negative (every non-loop edge is checked))")
    func fl221() async {
        // V [0, 1, 2]; E [0→1 1, 2→1 -1]; maximumFlow(from: 0, to: 1, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
    }

    @Test("FL-222 NaN capacity traps (a capacity is NaN)")
    func fl222() async {
        // Double V [0, 1]; E [0→1 nan]; maximumFlow(from: 0, to: 1, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in Double.nan })
        }
    }

    @Test("FL-223 infinite capacity traps (a capacity is infinite (c − c ≠ 0))")
    func fl223() async {
        // Double V [0, 1]; E [0→1 inf]; maximumFlow(from: 0, to: 1, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in Double.infinity })
        }
    }

    @Test("FL-224 source capacities overflow traps (the capacities out of the source sum past Int8.max, though the value 100 fits)")
    func fl224() async {
        // Int8 V [0, 1, 2, 3]; E [0→1 100, 0→2 100, 1→3 50, 2→3 50]; maximumFlow(from: 0, to: 3, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
            let capacities: [Int8] = [100, 100, 50, 50]
            _ = graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
        }
    }

    @Test("FL-225 source capacities overflow, Int traps (Int.max + 1)")
    func fl225() async {
        // V [0, 1]; E [0→1 9223372036854775807, 0→1 1]; maximumFlowValue(from: 0, to: 1, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
            let capacities = [Int.max, 1]
            _ = graph.maximumFlowValue(from: 0, to: 1, capacity: { capacities[$0] })
        }
    }

    @Test("FL-226 undirected: capacities at the source overflow traps (edges at the source sum past Int8.max)")
    func fl226() async {
        // Int8 undirected V [0, 1, 2]; E [1–0 100, 0–2 28]; maximumFlow(from: 0, to: 2, capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 2)])
            let capacities: [Int8] = [100, 28]
            _ = graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        }
    }

    @Test("FL-249 negative weight traps (a capacity is negative)")
    func fl249() async {
        // undirected V [0, 1]; E [0–1 -1]; minimumCut(capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.minimumCut(capacity: { _ in -1 })
        }
    }

    @Test("FL-274 Gomory–Hu: negative capacity traps (a capacity is negative)")
    func fl274() async {
        // undirected V [0, 1]; E [0–1 -2]; gomoryHuTree(capacity:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.gomoryHuTree(capacity: { _ in -2 })
        }
    }

    @Test("FL-306 min-cost: negative capacity traps (a capacity is negative)")
    func fl306() async {
        // V [0, 1]; E [0→1 -1 @1]; supply []; minimumCostFlow(supply:capacity:cost:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in -1 }, cost: { _ in 1 })
        }
    }

    @Test("FL-307 min-cost: cost total overflows traps (capacity × cost magnitude summed past Int8.max (checked before solving))")
    func fl307() async {
        // Int8 V [0, 1]; E [0→1 100 @2]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let supplies: [Int8] = [1, -1]
            let capacities: [Int8] = [100]
            let costs: [Int8] = [2]
            _ = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[$0] }, cost: { costs[$0] })
        }
    }

    @Test("FL-319 min-cost max flow: source is the sink traps (source == sink)")
    func fl319() async {
        // V [0, 1]; E [0→1 1 @1]; minimumCostMaximumFlow(from: 0, to: 0, capacity:cost:)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 0, capacity: { _ in 1 }, cost: { _ in 1 })
        }
    }

    @Test("FL-485 connectivity: source is the target traps (source == target)")
    func fl485() async {
        // P(3); vertexConnectivity(from: 0, to: 0)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.vertexConnectivity(from: 0, to: 0)
        }
    }

    @Test("FL-486 connectivity: source is the target traps (source == target)")
    func fl486() async {
        // P(3); minimumVertexCut(from: 0, to: 0)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.minimumVertexCut(from: 0, to: 0)
        }
    }

    @Test("FL-487 connectivity: source is the target traps (source == target)")
    func fl487() async {
        // P(3); edgeConnectivity(from: 0, to: 0)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeConnectivity(from: 0, to: 0)
        }
    }

    @Test("FL-524 disjoint paths: source is the target traps (source == target)")
    func fl524() async {
        // P(3); edgeDisjointPaths(from: 0, to: 0)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeDisjointPaths(from: 0, to: 0)
        }
    }

    @Test("FL-525 disjoint paths: source is the target traps (source == target)")
    func fl525() async {
        // P(3); vertexDisjointPaths(from: 0, to: 0)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.vertexDisjointPaths(from: 0, to: 0)
        }
    }

    @Test("The source as the sink traps on an undirected graph too, in every s–t entry point")
    func undirectedSourceIsSink() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlow(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.edmondsKarpMaximumFlow(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.dinicMaximumFlow(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlowValue(from: 1, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.minimumCut(from: 1, to: 1, capacity: { _ in 5 })
        }
    }

    @Test("A terminal that is not a vertex traps in every s–t entry point, on both kinds of graph")
    func terminalNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dinicMaximumFlow(from: 7, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlowValue(from: 0, to: 7, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCut(from: 7, to: 1, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumFlow(from: 0, to: 7, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.minimumCut(from: 7, to: 0, capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 7, capacity: { _ in 1 }, cost: { _ in 1 })
        }
    }

    @Test("A terminal that is not a vertex traps on a graph without vertex indices")
    func unindexedTerminalNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.maximumFlow(from: "a", to: "z", capacity: { _ in 5 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedGraph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.edgeConnectivity(from: "z", to: "a")
        }
    }

    @Test("A negative capacity traps in every maximum-flow entry point and in the directed global cut")
    func negativeCapacityEverywhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.maximumFlowValue(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
            let capacities = [1, -1]
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            let capacities = [1, -1]
            _ = graph.minimumCut(capacity: { capacities[$0] })
        }
    }

    @Test("A NaN or infinite capacity traps in the global cut and in Gomory–Hu")
    func nonFiniteCapacityGlobal() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let capacities = [1.0, Double.nan]
            _ = graph.minimumCut(capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let capacities = [Double.infinity, 1.0]
            _ = graph.gomoryHuTree(capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let capacities = [1.0, Double.nan]
            _ = graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
        }
    }

    @Test("Capacities at the source that sum past the type trap: UInt8 200 + 100, and Double 1e308 + 1e308 (infinite)")
    func sourceSumOverflowOtherTypes() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
            let capacities: [UInt8] = [200, 100, 1]
            _ = graph.maximumFlowValue(from: 0, to: 2, capacity: { capacities[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
            let capacities: [Double] = [1e308, 1e308, 1]
            _ = graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        }
    }

    @Test("GomoryHuTree.minimumCut(between:and:) with u = v traps")
    func gomoryHuSameVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let tree = graph.gomoryHuTree(capacity: { _ in 1 })!
            _ = tree.minimumCut(between: 1, and: 1)
        }
    }

    @Test("minimumCostFlow traps on a negative capacity on a self-loop (loops matter there), and minimumCostMaximumFlow on a negative capacity or a cost total past the type")
    func minimumCostMoreTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
            let capacities = [-1, 1]
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { capacities[$0] }, cost: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { _ in -1 }, cost: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { _ in Int8(100) }, cost: { _ in Int8(2) })
        }
    }

    @Test("The connectivity s–t entry points trap on a terminal that is not a vertex, and on a directed graph with source = target")
    func connectivityTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.vertexConnectivity(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.minimumVertexCut(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.edgeConnectivity(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.vertexConnectivity(from: 2, to: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.minimumVertexCut(from: 2, to: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.edgeConnectivity(from: 2, to: 2)
        }
    }

    @Test("Results trap on a position or vertex the graph does not have")
    func foreignLookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 }).flow(ofEdgeAt: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.edmondsKarpMaximumFlow(from: "a", to: "b", capacity: { _ in 5 }).flow(ofEdgeAt: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 1 }, cost: { _ in 1 })!.flow(ofEdgeAt: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 1 }, cost: { _ in 1 })!.potential(of: 9)
        }
    }
}
