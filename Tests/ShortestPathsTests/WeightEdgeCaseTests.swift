// Weights at the edges of what is allowed: negative weights (trapped on each examined edge),
// sums near the limit and overflow, infinities and NaN, other weight types, and what the weight
// closure is asked. Case IDs (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

/// A weight type of the user's own: only `Comparable` and `AdditiveArithmetic`.
private struct Cost: Comparable, AdditiveArithmetic {
    var cents: Int
    static var zero: Cost { Cost(cents: 0) }
    static func + (lhs: Cost, rhs: Cost) -> Cost { Cost(cents: lhs.cents + rhs.cents) }
    static func - (lhs: Cost, rhs: Cost) -> Cost { Cost(cents: lhs.cents - rhs.cents) }
    static func < (lhs: Cost, rhs: Cost) -> Bool { lhs.cents < rhs.cents }
}

@Suite("Weight edge cases")
struct WeightEdgeCaseTests {
    @Test("SP-35 a negative edge traps, even where the answer could be repaired", .tags(.precondition))
    func negativeEdgeTraps() async {
        // Without the check, b settles first and then lowers a, which is still queued: no
        // accidental trap would fire, and a's distance would be wrong.
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [
                DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "s", to: "b"), DirectedEdge(from: "b", to: "a"),
            ])
            let weights = [2, 1, -5]
            _ = graph.dijkstraShortestPaths(from: "s") { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [
                DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "s", to: "b"), DirectedEdge(from: "b", to: "a"),
            ])
            let weights = [2, 1, -5]
            _ = graph.dijkstraShortestPath(from: "s", to: "a") { weights[$0] }
        }
    }

    @Test("SP-36 a negative edge the search never examines does not trap")
    func unexaminedNegativeEdge() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "b", to: "c")])
        let weights = [1, -1]
        let tree = graph.dijkstraShortestPaths(from: "s") { weights[$0] }
        #expect(tree.distance(to: "s") == 0)
        #expect(tree.distance(to: "a") == 1)
        #expect(tree.distance(to: "b") == nil)
        #expect(tree.distance(to: "c") == nil)
    }

    @Test("SP-36 an examined negative edge traps even beyond the cutoff", .tags(.precondition))
    func examinedNegativeEdgeBeyondCutoff() async {
        // The source's out-edges are examined (and checked) before the cutoff test.
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "s", to: "a")])
            let weights = [-1]
            _ = graph.dijkstraShortestPaths(from: "s", cutoff: 0) { weights[$0] }
        }
    }

    @Test("SP-37 Int sums up to the limit are exact: no sentinel is ever added to")
    func sumsNearTheLimit() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let dijkstra = g.dijkstraShortestPaths(from: 0) { _ in Int.max / 2 }
            #expect(dijkstra.distance(to: 2) == Int.max - 1)
            let bellmanFord = g.bellmanFordShortestPaths(from: 0) { _ in Int.max / 2 }
            #expect(bellmanFord?.distance(to: 2) == Int.max - 1)
            #expect(g.shortestPaths(from: 0).distance(to: 2) == 2)
        }
        check(ReferenceDirectedMultigraph(edges: edges))
        check(CompressedSparseRow(vertexCount: 3, edges: edges))
        check(AdjacencyMatrix(vertexCount: 3, edges: edges))
        check(AdjacencyList(edges: edges))
    }

    @Test("SP-38 overflow traps, in Dijkstra and in Bellman–Ford", .tags(.precondition))
    func overflowTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in Int.max / 2 + 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.bellmanFordShortestPaths(from: 0) { _ in Int.max / 2 + 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPath(from: 0, to: 2) { _ in Int.max / 2 + 1 }
        }
    }

    @Test("SP-39 Double.infinity is an ordinary weight: the target is reached at +∞")
    func infiniteWeights() {
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "s", to: "b"), DirectedEdge(from: "b", to: "a"),
            DirectedEdge(from: "s", to: "c"),
        ])
        let weights: [Double] = [.infinity, 1, 2, .infinity]
        let tree = graph.dijkstraShortestPaths(from: "s") { weights[$0] }
        #expect(tree.distance(to: "a") == 3.0)
        #expect(tree.parent(of: "a") == "b")
        #expect(tree.distance(to: "c") == .infinity)
        #expect(tree.hasPath(to: "c"))
        #expect(tree.path(to: "c") == ["s", "c"])
        let bellmanFord = graph.bellmanFordShortestPaths(from: "s") { weights[$0] }
        #expect(bellmanFord?.distance(to: "a") == 3.0)
        #expect(bellmanFord?.distance(to: "c") == .infinity)
    }

    @Test("SP-40 NaN traps in Dijkstra, A* and Bellman–Ford; −∞ traps in Dijkstra; +∞ meeting −∞ traps in Bellman–Ford", .tags(.precondition))
    func nanAndNegativeInfinity() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in Double.nan }
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.aStarShortestPath(from: 0, to: 1, weight: { _ in Double.nan }, heuristic: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.bellmanFordShortestPaths(from: 0) { _ in Double.nan }
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.findNegativeCycle(from: 0) { _ in Double.nan }
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in -Double.infinity }
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let weights: [Double] = [.infinity, -.infinity]
            _ = graph.bellmanFordShortestPaths(from: 0) { weights[$0] }
        }
    }

    @Test("SP-41 other weight types: Double, Float, UInt8, Duration and a user type")
    func otherWeightTypes() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let order = ["s", "u", "x", "v", "y"]
        let ints = xg.map(\.2)

        let doubles = ints.map(Double.init)
        let doubleTree = graph.dijkstraShortestPaths(from: "s") { doubles[$0] }
        #expect(order.map { doubleTree.distance(to: $0) } == [0, 8, 5, 9, 7])

        let floats = ints.map(Float.init)
        let floatTree = graph.dijkstraShortestPaths(from: "s") { floats[$0] }
        #expect(order.map { floatTree.distance(to: $0) } == [0, 8, 5, 9, 7])

        let bytes = ints.map { UInt8($0) }
        let byteTree = graph.dijkstraShortestPaths(from: "s") { bytes[$0] }
        #expect(order.map { byteTree.distance(to: $0) } == [0, 8, 5, 9, 7])

        let durations = ints.map { Duration.seconds($0) }
        let durationTree = graph.dijkstraShortestPaths(from: "s") { durations[$0] }
        #expect(order.map { durationTree.distance(to: $0) } == [0, 8, 5, 9, 7].map { Duration.seconds($0) })
        #expect(graph.bellmanFordShortestPaths(from: "s") { durations[$0] }?.distance(to: "v") == .seconds(9))

        let costs = ints.map { Cost(cents: $0) }
        let costTree = graph.dijkstraShortestPaths(from: "s") { costs[$0] }
        #expect(order.map { costTree.distance(to: $0)?.cents } == [0, 8, 5, 9, 7])
        #expect(costTree.path(to: "v") == ["s", "x", "u", "v"])
        #expect(graph.bellmanFordShortestPaths(from: "s") { costs[$0] }?.distance(to: "v") == Cost(cents: 9))
        #expect(graph.aStarShortestPath(from: "s", to: "v", weight: { costs[$0] }, heuristic: { _ in .zero })?.distance == Cost(cents: 9))
    }

    @Test("SP-42 the weight closure is asked for positions, each examined edge once, parallel copies separately")
    func weightClosureSeesPositions() {
        // petgraph's spfa_multiple_edges: every vertex is reached, so every edge is examined.
        let petgraph: [(Int, Int, Int)] = [
            (0, 1, 10), (0, 1, 1), (0, 2, 4), (0, 3, 10), (1, 2, 2), (1, 3, 2), (2, 3, 2), (0, 3, 100), (2, 3, 20), (0, 0, 5),
        ]
        let graph = ReferenceDirectedMultigraph(edges: petgraph.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = petgraph.map(\.2)
        var asked: [Int] = []
        let tree = graph.dijkstraShortestPaths(from: 0) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(tree.distance(to: 3) == 3)
        #expect(asked.sorted() == Array(0 ..< graph.edgeCount))
        // The two copies of 0→1 (positions 0 and 1) were each asked once.
        #expect(asked.filter { $0 == 0 || $0 == 1 }.count == 2)

        // From 3 nothing leaves, so nothing is asked.
        var none: [Int] = []
        _ = graph.dijkstraShortestPaths(from: 3) { position in
            none.append(position)
            return weights[position]
        }
        #expect(none.isEmpty)
    }
}
