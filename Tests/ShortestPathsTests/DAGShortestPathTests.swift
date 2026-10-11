// DAG shortest paths (Boost's `dag_shortest_paths`): negative weights, a cycle reachable from the
// source (nil) and one that is not, several sources as one super-source, ties, every
// representation's index space (indexed, compressed rows, a stable graph with holes), the
// DirectedAcyclicGraph overload that relaxes in its maintained order, random DAGs against
// Bellman–Ford, ties by the maintained order, and the preconditions (a non-vertex source, a NaN
// length). See README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import ShortestPaths
import StableGraphs
import Testing

@Suite("DAG shortest paths")
struct DAGShortestPathTests {
    @Test("Negative weights: CLRS figure 24.5, Boost's dag_shortest_paths example, from s")
    func clrs() throws {
        // r s t x y z with r→s 5, r→t 3, s→t 2, s→x 6, t→x 7, t→y 4, t→z 2, x→y −1, x→z 1, y→z −2.
        let arcs: [(String, String, Int)] = [
            ("r", "s", 5), ("r", "t", 3), ("s", "t", 2), ("s", "x", 6), ("t", "x", 7),
            ("t", "y", 4), ("t", "z", 2), ("x", "y", -1), ("x", "z", 1), ("y", "z", -2),
        ]
        let edges = arcs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let weights = arcs.map(\.2)
        let list = AdjacencyList(vertices: ["r", "s", "t", "x", "y", "z"], edges: edges)
        let tree = try #require(list.dagShortestPaths(from: "s") { weights[$0] })
        #expect(["r", "s", "t", "x", "y", "z"].map { tree.distance(to: $0) } == [nil, 0, 2, 6, 5, 3])
        #expect(tree.path(to: "z")?.vertices == ["s", "x", "y", "z"])
        #expect(tree.path(to: "z")?.edges == [3, 7, 9])
        #expect(tree.parent(of: "s") == nil && tree.parent(of: "r") == nil && !tree.hasPath(to: "r"))
        // The same on the wrapper, in its maintained order.
        let dag = try #require(DirectedAcyclicGraph<AdjacencyList<String>>(vertices: ["r", "s", "t", "x", "y", "z"], edges: edges))
        let ordered = dag.dagShortestPaths(from: "s") { weights[$0] }
        #expect(["r", "s", "t", "x", "y", "z"].map { ordered.distance(to: $0) } == [nil, 0, 2, 6, 5, 3])
        #expect(ordered.path(to: "z")?.edges == [3, 7, 9])
    }

    @Test("A cycle reachable from the source gives nil; one it cannot reach does not matter")
    func cycles() throws {
        // 0 → 1 → 2, and a cycle 3 ⇄ 4 that 0 reaches through 2 → 3, or not.
        let base = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3)]
        let unreached = AdjacencyList(vertices: 0 ..< 5, edges: base)
        let tree = try #require(unreached.dagShortestPaths(from: 0) { _ in 1 })
        #expect((0 ..< 5).map { tree.distance(to: $0) } == [0, 1, 2, nil, nil])
        #expect(unreached.dagShortestPaths(from: 3) { _ in 1 } == nil)
        let reached = AdjacencyList(vertices: 0 ..< 5, edges: base + [DirectedEdge(from: 2, to: 3)])
        #expect(reached.dagShortestPaths(from: 0) { _ in 1 } == nil)
        #expect(reached.dagShortestPaths(from: 4) { _ in 1 } == nil)
        // A self-loop is a cycle.
        let loop = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(loop.dagShortestPaths(from: 0) { _ in 1 } == nil)
        #expect(loop.dagShortestPaths(from: 1) { _ in 1 } == nil)
    }

    @Test("Several sources act as one super-source: a negative path from one source improves another")
    func severalSources() throws {
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3),
        ])
        let weights = [-4, 1, 1]
        let tree = try #require(graph.dagShortestPaths(from: [2, 0, 2]) { weights[$0] })
        #expect(tree.sources == [2, 0])
        #expect((0 ..< 4).map { tree.distance(to: $0) } == [0, -4, -3, -2])
        #expect(tree.parent(of: 2) == 1 && tree.parent(of: 0) == nil)
        let dag = try #require(DirectedAcyclicGraph(graph))
        let ordered = dag.dagShortestPaths(from: [2, 0]) { weights[$0] }
        #expect((0 ..< 4).map { ordered.distance(to: $0) } == [0, -4, -3, -2])
    }

    @Test("Parallel copies: the lighter; ties: the first relaxation")
    func copiesAndTies() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2),
        ])
        let weights = [3, 2, 1, 3]
        let tree = try #require(graph.dagShortestPaths(from: 0) { weights[$0] })
        #expect(tree.distance(to: 1) == 2 && tree.parentEdge(of: 1) == 1)
        // 0 → 2 directly and 0 → 1 → 2 both cost 3: the first relaxation, the direct edge (0 is
        // popped first), wins.
        #expect(tree.distance(to: 2) == 3 && tree.parentEdge(of: 2) == 3)
    }

    @Test("Every index space: compressed rows, and a stable graph with holes through numbered rows")
    func representations() throws {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3)]
        let weights = [1, -5, 2, 1]
        // Compressed rows number the edges by source: 0→1, 0→2, 1→3, 2→3.
        let csr = CompressedSparseRow(vertexCount: 4, edges: edges)
        let csrWeights = csr.edges.map { edge in weights[edges.firstIndex(of: edge)!] }
        let byRow = try #require(csr.dagShortestPaths(from: 0) { csrWeights[$0] })
        #expect((0 ..< 4).map { byRow.distance(to: $0) } == [0, 1, 2, -4])
        var stable = StableDirectedGraph(vertices: 0 ..< 6, edges: edges)
        stable.remove(4)
        #expect(stable.vertexIndexBound == nil)
        let tree = try #require(stable.dagShortestPaths(from: 0) { weights[$0] })
        #expect([0, 1, 2, 3, 5].map { tree.distance(to: $0) } == [0, 1, 2, -4, nil])
        #expect(tree.path(to: 3)?.edges == [0, 1])
        let dag = try #require(DirectedAcyclicGraph(stable))
        let ordered = dag.dagShortestPaths(from: 0) { weights[$0] }
        #expect([0, 1, 2, 3, 5].map { ordered.distance(to: $0) } == [0, 1, 2, -4, nil])
        #expect(ordered.path(to: 3)?.edges == [0, 1])
    }

    @Test("Random DAGs: the same distances as Bellman–Ford, on the graph and on its DirectedAcyclicGraph", arguments: [1, 2, 3, 4, 5])
    func againstBellmanFord(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 200
        let rank = Array(0 ..< n).shuffled(using: &rng)
        var edges: [DirectedEdge<Int>] = []
        var weights: [Int] = []
        for _ in 0 ..< 800 {
            let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
            guard u != v else { continue }
            edges.append(rank[u] < rank[v] ? DirectedEdge(from: u, to: v) : DirectedEdge(from: v, to: u))
            weights.append(Int.random(in: -10 ... 10, using: &rng))
        }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: edges)
        var dag = try #require(DirectedAcyclicGraph(graph))
        // Some removals, so the wrapper's order has holes.
        for v in stride(from: 3, to: n, by: 7) { dag.remove(v) }
        let pruned = dag.base
        let survivors = pruned.edges.indices.map { p in weights[edges.firstIndex(of: pruned.edges[p])!] }
        for source in [rank.firstIndex(of: 0)!, 0, 1] where pruned.contains(source) {
            let reference = try #require(pruned.bellmanFordShortestPaths(from: source) { survivors[$0] })
            let sorted = try #require(pruned.dagShortestPaths(from: source) { survivors[$0] })
            let ordered = dag.dagShortestPaths(from: source) { survivors[$0] }
            for v in pruned.vertices {
                #expect(sorted.distance(to: v) == reference.distance(to: v), "seed \(seed) source \(source) vertex \(v)")
                #expect(ordered.distance(to: v) == reference.distance(to: v), "seed \(seed) source \(source) vertex \(v)")
                if let path = ordered.path(to: v) {
                    #expect(path.edges.reduce(0) { $0 + survivors[$1] } == reference.distance(to: v))
                }
            }
        }
    }

    @Test("On a DirectedAcyclicGraph, ties follow its maintained order, not Kahn's over the rows")
    func tiesFollowTheMaintainedOrder() throws {
        // 0 → 1 and 0 → 2 tie at 3. The rows list 1 first, so Kahn's algorithm relaxes 1 first;
        // the graph's own order places 2 first, so 2 relaxes 3 first and keeps it.
        var dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 2, 1, 3])
        for (u, v) in [(0, 1), (0, 2), (1, 3), (2, 3)] { _ = dag.insert(edge: DirectedEdge(from: u, to: v)) }
        #expect(Array(dag.topologicalOrder) == [0, 2, 1, 3])
        let tree = dag.dagShortestPaths(from: 0) { _ in 1 }
        #expect(tree.distance(to: 3) == 2 && tree.parent(of: 3) == 2)
        let kahn = try #require(dag.base.dagShortestPaths(from: 0) { _ in 1 })
        #expect(kahn.distance(to: 3) == 2 && kahn.parent(of: 3) == 1)
    }

    @Test("A NaN path length traps, on either overload", .tags(.precondition))
    func nanTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dagShortestPaths(from: 0) { $0 == 0 ? Double.nan : 1 }
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])!
            _ = dag.dagShortestPaths(from: 0) { $0 == 0 ? Double.nan : 1 }
        }
        // Without NaN, the same graphs answer.
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.dagShortestPaths(from: 0) { _ in 0.5 }?.distance(to: 2) == 1.0)
    }

    @Test("The source must be a vertex", .tags(.precondition))
    func sourceMustBeAVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestPaths(from: 5) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])!
            _ = dag.dagShortestPaths(from: 5) { _ in 1 }
        }
    }
}
