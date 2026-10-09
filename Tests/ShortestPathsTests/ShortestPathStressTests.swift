// Deep and wide graphs inside a Task: a 10⁶-vertex path (no recursion, iterative path
// reconstruction, Bellman–Ford in one pass), a 1000 × 1000 grid, long negative cycles and a lasso,
// a negative path, an out-star and a complete digraph; and the real-world fixtures against
// Floyd–Warshall. Only answers are asserted; times are benchmarks. Case IDs (SP-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

@Suite("Shortest-path stress")
struct ShortestPathStressTests {
    @Test("SP-115 a 10⁶-vertex path: Dijkstra, Bellman–Ford and unweighted search, iterative paths")
    func millionVertexPath() async {
        await Task {
            let n = 1_000_000
            let path = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            let dijkstra = path.dijkstraShortestPaths(from: 0) { _ in 1 }
            #expect(dijkstra.distance(to: n - 1) == n - 1)
            #expect(dijkstra.path(to: n - 1)?.count == n)
            #expect(dijkstra.parent(of: n - 1) == n - 2)
            // Rounds over the vertices improved last: one out-edge per round on a path, so the
            // weights are read about once each, not once per edge per round.
            var asked = 0
            let bellmanFord = path.bellmanFordShortestPaths(from: 0) { _ in
                asked += 1
                return 1
            }
            #expect(bellmanFord?.distance(to: n - 1) == n - 1)
            #expect(bellmanFord?.path(to: n - 1)?.count == n)
            #expect(asked <= 2 * path.edgeCount)
            let unweighted = path.shortestPaths(from: 0)
            #expect(unweighted.distance(to: n - 1) == n - 1)
            let walk = unweighted.path(to: n - 1)
            #expect(walk?.count == n)
            #expect(walk?.first == 0)
            #expect(walk?.last == n - 1)
            let single = path.dijkstraShortestPath(from: 0, to: n - 1) { _ in 1 }
            #expect(single?.path.count == n)
        }.value
    }

    @Test("SP-116 a 1000 × 1000 grid in both directions: distances r + c, and A* to the far corner")
    func grid() async {
        await Task {
            let side = 1000
            var edges: [DirectedEdge<Int>] = []
            edges.reserveCapacity(4 * side * side)
            for r in 0 ..< side {
                for c in 0 ..< side {
                    let v = r * side + c
                    if c + 1 < side { edges.append(DirectedEdge(from: v, to: v + 1)); edges.append(DirectedEdge(from: v + 1, to: v)) }
                    if r + 1 < side { edges.append(DirectedEdge(from: v, to: v + side)); edges.append(DirectedEdge(from: v + side, to: v)) }
                }
            }
            let grid = CompressedSparseRow(vertexCount: side * side, edges: edges)
            let tree = grid.dijkstraShortestPaths(from: 0) { _ in 1 }
            #expect((0 ..< side * side).allSatisfy { tree.distance(to: $0) == $0 / side + $0 % side })
            let corner = side * side - 1
            let result = grid.aStarShortestPath(from: 0, to: corner, weight: { _ in 1 }, heuristic: { (side - 1 - $0 / side) + (side - 1 - $0 % side) })
            #expect(result?.distance == 2 * (side - 1))
            #expect(result?.path.count == 2 * side - 1)
        }.value
    }

    @Test("SP-117 a negative cycle through 100 000 vertices")
    func longNegativeCycle() async {
        await Task {
            let n = 100_000
            let edges = (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) }
            let graph = CompressedSparseRow(vertexCount: n, edges: edges)
            // Every edge 1 except the last, n − 1 → 0, at −n: total −1.
            let weight: (Int) -> Int = { $0 == n - 1 ? -n : 1 }
            #expect(graph.findNegativeCycle(from: 0, weight: weight)?.vertices == Array(0 ..< n))
            #expect(graph.bellmanFordShortestPaths(from: 0, weight: weight) == nil)
        }.value
    }

    @Test("SP-118 a lasso: the witness leaves out the tail the search started on")
    func lasso() async {
        await Task {
            let n = 100_000
            let edges = (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) } + [DirectedEdge(from: n - 1, to: n / 2)]
            let graph = CompressedSparseRow(vertexCount: n, edges: edges)
            let weight: (Int) -> Int = { $0 == n - 1 ? -n : 1 }
            #expect(graph.findNegativeCycle(from: 0, weight: weight)?.vertices == Array(n / 2 ..< n))
            #expect(graph.findNegativeCycle(weight: weight)?.vertices == Array(n / 2 ..< n))
        }.value
    }

    @Test("SP-119 a 100 000-vertex path of negative edges is a tree")
    func negativePath() async {
        await Task {
            let n = 100_000
            let graph = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            let tree = graph.bellmanFordShortestPaths(from: 0) { _ in -1 }
            #expect(tree != nil)
            #expect((0 ..< n).allSatisfy { tree?.distance(to: $0) == -$0 })
            #expect(graph.findNegativeCycle { _ in -1 } == nil)
        }.value
    }

    @Test("SP-120 wide graphs: a 10⁵-leaf out-star and a complete digraph on 1000 vertices")
    func wideGraphs() async {
        await Task {
            let leaves = 100_000
            let star = CompressedSparseRow(vertexCount: leaves + 1, edges: (1 ... leaves).map { DirectedEdge(from: 0, to: $0) })
            // Edge k goes to leaf k + 1.
            let tree = star.dijkstraShortestPaths(from: 0) { $0 + 1 }
            #expect((1 ... leaves).allSatisfy { tree.distance(to: $0) == $0 && tree.parent(of: $0) == 0 })

            let n = 1000
            var edges: [DirectedEdge<Int>] = []
            for u in 0 ..< n { for v in 0 ..< n where u != v { edges.append(DirectedEdge(from: u, to: v)) } }
            let complete = CompressedSparseRow(vertexCount: n, edges: edges)
            var rng = SeededRandomNumberGenerator(seed: 120)
            let weights = (0 ..< complete.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &rng) }
            let dijkstra = complete.dijkstraShortestPaths(from: 0) { weights[$0] }
            let bellmanFord = complete.bellmanFordShortestPaths(from: 0) { weights[$0] }
            #expect((0 ..< n).allSatisfy { dijkstra.distance(to: $0) == bellmanFord?.distance(to: $0) })
        }.value
    }

    @Test("SP-121 the real-world fixtures: Dijkstra = Bellman–Ford = Floyd–Warshall on AL, AM and CSR", .tags(.fixture), arguments: DirectedFixture<Int>.realWorld)
    func realWorld(fixture: DirectedFixture<Int>) async {
        await Task {
            let n = fixture.vertexCount
            // Floyd–Warshall with the weight a function of the endpoints, so repeated edges agree.
            var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for edge in fixture.edges { d[edge.source][edge.target] = min(d[edge.source][edge.target] ?? .max, 1 + (edge.source * 31 + edge.target) % 17) }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    guard let ik = d[i][k] else { continue }
                    for j in 0 ..< n {
                        guard let kj = d[k][j] else { continue }
                        if d[i][j] == nil || ik + kj < d[i][j]! { d[i][j] = ik + kj }
                    }
                }
            }
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            let listWeights = list.edges.map { 1 + ($0.source * 31 + $0.target) % 17 }
            let sparse = CompressedSparseRow(vertexCount: n, edges: fixture.edges)
            let sparseWeights = sparse.edges.map { 1 + ($0.source * 31 + $0.target) % 17 }
            let matrix = AdjacencyMatrix(vertexCount: n, edges: fixture.edges)
            for s in 0 ..< n {
                let listDijkstra = list.dijkstraShortestPaths(from: s) { listWeights[$0] }
                let listBellmanFord = list.bellmanFordShortestPaths(from: s) { listWeights[$0] }
                let sparseDijkstra = sparse.dijkstraShortestPaths(from: s) { sparseWeights[$0] }
                let sparseBellmanFord = sparse.bellmanFordShortestPaths(from: s) { sparseWeights[$0] }
                let matrixDijkstra = matrix.dijkstraShortestPaths(from: s) { 1 + ($0.source * 31 + $0.target) % 17 }
                let matrixBellmanFord = matrix.bellmanFordShortestPaths(from: s) { 1 + ($0.source * 31 + $0.target) % 17 }
                #expect((0 ..< n).map { listDijkstra.distance(to: $0) } == d[s], "\(fixture.name) from \(s)")
                #expect((0 ..< n).map { listBellmanFord?.distance(to: $0) } == d[s], "\(fixture.name) from \(s)")
                #expect((0 ..< n).map { sparseDijkstra.distance(to: $0) } == d[s], "\(fixture.name) from \(s)")
                #expect((0 ..< n).map { sparseBellmanFord?.distance(to: $0) } == d[s], "\(fixture.name) from \(s)")
                #expect((0 ..< n).map { matrixDijkstra.distance(to: $0) } == d[s], "\(fixture.name) from \(s)")
                #expect((0 ..< n).map { matrixBellmanFord?.distance(to: $0) } == d[s], "\(fixture.name) from \(s)")
            }
        }.value
    }
}
