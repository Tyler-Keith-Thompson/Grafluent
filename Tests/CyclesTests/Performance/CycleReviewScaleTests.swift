// Review cases at scale (CycleReviewTests.swift has the rest): shapes on which a round or girth
// used to cost the whole graph (a windmill whose hub is the last vertex, a large grid with a bound,
// forests and DAGs for girth), each with a one-minute limit. Case IDs (CY-nnn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import Cycles
import GraphProtocols
import Testing
import Traversal
import Walks

@Suite("Cycle review cases at scale")
struct CycleReviewScaleTests {
    @Test("CY-1004 a windmill of 20 000 triangles whose hub is the last vertex: each round costs its triangle", .timeLimit(.minutes(1)))
    func windmillHubLast() async {
        await Task {
            let k = 20_000
            let hub = 2 * k
            var edges: [UndirectedEdge<Int>] = []
            for t in 0 ..< k {
                edges.append(UndirectedEdge(2 * t, 2 * t + 1))
                edges.append(UndirectedEdge(2 * t + 1, hub))
                edges.append(UndirectedEdge(hub, 2 * t))
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ... hub, edges: edges)
            var count = 0
            for cycle in graph.simpleCycles() {
                #expect(cycle.vertices == [2 * count, 2 * count + 1, hub])
                count += 1
            }
            #expect(count == k)
            let bounded = graph.simpleCycles(maxLength: 3).reduce(0) { n, _ in n + 1 }
            #expect(bounded == k)
            #expect(graph.girth() == 3)
        }.value
    }

    @Test("CY-1005 a 100 × 100 grid with a bound of 4 and 6: its squares and dominoes", .timeLimit(.minutes(1)))
    func boundedGrid() async {
        await Task {
            let side = 100
            var edges: [UndirectedEdge<Int>] = []
            for v in 0 ..< side * side {
                if v % side + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                if v + side < side * side { edges.append(UndirectedEdge(v, v + side)) }
            }
            let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
            // 99² unit squares; 2 · 99 · 98 dominoes (NetworkX on a 7 × 9 grid: 48 and 82).
            let squares = 99 * 99, dominoes = 2 * 99 * 98
            let upToFour = grid.simpleCycles(maxLength: 4).reduce(0) { n, _ in n + 1 }
            let upToSix = grid.simpleCycles(maxLength: 6).reduce(0) { n, _ in n + 1 }
            #expect(upToFour == squares)
            #expect(upToSix == squares + dominoes)
            #expect(grid.girth() == 4)
        }.value
    }

    @Test("CY-1006 girth of forests and DAGs of 100 000 vertices is nil without a search from every vertex", .timeLimit(.minutes(1)))
    func girthWithoutCycles() async {
        await Task {
            let n = 100_000
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(path.girth() == nil)
            let tree = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge($0, ($0 - 1) / 2) })
            #expect(tree.girth() == nil)
            let tail = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) } + [UndirectedEdge(n - 1, n - 3)])
            #expect(tail.girth() == 3)
            let dag = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).flatMap { [DirectedEdge(from: $0, to: $0 + 1), DirectedEdge(from: $0, to: min($0 + 7, n - 1))] })
            #expect(dag.girth() == nil)
            let back = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) } + [DirectedEdge(from: n - 1, to: n - 4)])
            #expect(back.girth() == 4)
        }.value
    }
}
