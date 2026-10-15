// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in a
// debug build; the benchmarks take timings. A 400 × 400 grid with walls given by a lazy-filter
// closure, against a CompressedSparseRow of the materialized grid (layers, components, Dijkstra with
// the weight from the position's target), with one call per discovered vertex; a hashed closure on
// 10⁵ vertices against a DirectedPseudograph; and 200 unbounded weighted searches by D19's
// Dijkstra and A*, which must agree with each other and with the path they return. See README.md.

import CompressedSparseRowModule
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import ImplicitGraphs
import Multigraphs
import ShortestPaths
import Testing
import Traversal

@Suite("ImplicitGraphs at scale")
struct ImplicitGraphStressTests {
    @Test("A 400 × 400 grid with walls equals the CSR of its materialized edges", .timeLimit(.minutes(1)))
    func grid() async {
        await Task {
            let side = 400
            let n = side * side
            // A wall where (r · 31 + c · 17) mod 11 == 0: about one cell in eleven.
            let isWall = { (v: Int) -> Bool in ((v / side) * 31 + (v % side) * 17) % 11 == 0 }
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: n, successors: { (v: Int) -> LazyFilterSequence<[Int]> in
                calls += 1
                let (r, c) = (v / side, v % side)
                let blocked = isWall(v)
                // Up, left, right, down: ascending, as a CSR row is.
                return [r > 0 ? v - side : -1, c > 0 ? v - 1 : -1, c < side - 1 ? v + 1 : -1, r < side - 1 ? v + side : -1]
                    .lazy.filter { $0 >= 0 && !blocked && !isWall($0) }
            })
            var edges: [DirectedEdge<Int>] = []
            for edge in graph.edges { edges.append(edge) }
            let csr = CompressedSparseRow(vertexCount: n, edges: edges)
            #expect(csr.edgeCount == edges.count && graph.edgeCount == edges.count)
            let source = (0 ..< n).first { !isWall($0) }!
            calls = 0
            let layers = graph.breadthFirstLayers(from: source)
            #expect(calls == layers.joined().count)
            #expect(layers == csr.breadthFirstLayers(from: source))
            #expect(graph.weaklyConnectedComponents().count == csr.weaklyConnectedComponents().count)
            #expect(graph.stronglyConnectedComponents().count == csr.stronglyConnectedComponents().count)
            calls = 0
            let tree = graph.dijkstraShortestPaths(from: source) { $0.target % 7 + 1 }
            let reached = (0 ..< n).filter { tree.distance(to: $0) != nil }.count
            #expect(reached == layers.joined().count && calls <= 2 * reached)
            let csrTree = csr.dijkstraShortestPaths(from: source) { csr.target(ofEdgeAt: $0) % 7 + 1 }
            var mismatches = 0
            for v in stride(from: 0, to: n, by: 13) where tree.distance(to: v) != csrTree.distance(to: v) { mismatches += 1 }
            #expect(mismatches == 0)
        }.value
    }

    @Test("A hashed closure on 10⁵ vertices equals the pseudograph of its rows", .timeLimit(.minutes(1)))
    func hashedClosure() async {
        await Task {
            let n = 100_000
            // Two or three successors per vertex, repeats and self-loops allowed.
            let row = { (v: Int) -> [Int] in
                let a = Int((Int64(v) * 7_919 + 13) % Int64(n)), b = Int((Int64(v) * 104_729 + 7) % Int64(n))
                return v % 5 == 0 ? [a, b, a] : (v % 7 == 0 ? [v, b] : [a, b])
            }
            let graph = ImplicitDirectedGraph(vertexCount: n, successors: row)
            let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).flatMap { v in row(v).map { DirectedEdge(from: v, to: $0) } })
            #expect(graph.edgeCount == pseudograph.edgeCount)
            #expect(graph.breadthFirstLayers(from: 1) == pseudograph.breadthFirstLayers(from: 1))
            #expect(graph.stronglyConnectedComponents().map { Array($0) } == pseudograph.stronglyConnectedComponents().map { Array($0) })
            #expect(graph.weaklyConnectedComponents().count == pseudograph.weaklyConnectedComponents().count)
            let hops = graph.shortestPaths(from: 3), pseudoHops = pseudograph.shortestPaths(from: 3)
            var mismatches = 0
            for v in stride(from: 0, to: n, by: 17) where hops.distance(to: v) != pseudoHops.distance(to: v) { mismatches += 1 }
            #expect(mismatches == 0)
        }.value
    }

    @Test("200 unbounded weighted searches: Dijkstra and A* agree, and their paths cost what they say", .timeLimit(.minutes(1)))
    func unboundedSearches() async {
        await Task {
            struct P: Hashable {
                var x, y: Int
            }
            var rng = SeededRandomNumberGenerator(seed: 21)
            for _ in 0 ..< 200 {
                let m = Int.random(in: 2 ... 9, using: &rng)
                let goal = P(x: Int.random(in: -12 ... 12, using: &rng), y: Int.random(in: -12 ... 12, using: &rng))
                // A step's cost depends on both ends.
                let cost = { (p: P, q: P) -> Int in 1 + ((p.x * 7 + q.y * 13 + p.y * q.x * 3) % m + m) % m }
                let neighbors = { (p: P) -> [(P, Int)] in
                    [P(x: p.x + 1, y: p.y), P(x: p.x - 1, y: p.y), P(x: p.x, y: p.y + 1), P(x: p.x, y: p.y - 1)].map { ($0, cost(p, $0)) }
                }
                let dijkstra = dijkstraShortestPath(from: P(x: 0, y: 0), successors: neighbors, success: { $0 == goal })
                let aStar = aStarShortestPath(from: P(x: 0, y: 0), successors: neighbors, heuristic: { abs(goal.x - $0.x) + abs(goal.y - $0.y) }, success: { $0 == goal })
                #expect(dijkstra != nil && dijkstra?.distance == aStar?.distance, "m \(m), goal \(goal)")
                for result in [dijkstra, aStar] {
                    guard let result else { continue }
                    #expect(result.path.first == P(x: 0, y: 0) && result.path.last == goal)
                    #expect(zip(result.path, result.path.dropFirst()).allSatisfy { abs($0.x - $1.x) + abs($0.y - $1.y) == 1 })
                    #expect(zip(result.path, result.path.dropFirst()).reduce(0) { $0 + cost($1.0, $1.1) } == result.distance)
                    #expect(result.distance >= abs(goal.x) + abs(goal.y) && result.distance <= m * (abs(goal.x) + abs(goal.y)))
                }
            }
        }.value
    }
}
