// Large shapes, each inside a Task (whose stack is much smaller than the main thread's, so a
// recursive search would overflow on the long path and the long cycle) with a one-minute limit,
// meant to finish within a few seconds in a debug build; the benchmarks take timings. A
// 10⁵-vertex path on `UndirectedAdjacencyList` (stored rows) and on `ReferencePseudograph` (rows
// read through the protocol), the odd cycle C₁₀₀₀₀₁ whose only cycle is the whole graph, a 300 × 300
// grid with and without a diagonal, a 10⁵-vertex `BipartiteGraph` built by insertion and then half
// removed, and projections of a star and a long path. Expected values are closed forms (the grid's
// cycle was also computed with ref.py's model, as BP-039 is at 3 × 3). See README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Recognition and BipartiteGraph at 10⁵ vertices")
struct BipartiteStressTests {
    @Test("The 10⁵-vertex path: bipartite, the even vertices left, on both kinds of rows", .timeLimit(.minutes(1)))
    func longPath() async throws {
        try await Task {
            let n = 100_000
            let edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
            let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            #expect(list.isBipartite)
            #expect(list.findOddCycle() == nil)
            let sides = try #require(list.bipartition())
            #expect(sides.left.count == n / 2)
            #expect(Array(sides.left) == Array(stride(from: 0, to: n, by: 2)))
            #expect(sides.side(of: n - 1) == .right)
            let pseudograph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let pseudoSides = try #require(pseudograph.bipartition())
            #expect(pseudoSides.left.count == n / 2)
            #expect(Array(pseudoSides.right) == Array(stride(from: 1, to: n, by: 2)))
            let bipartite = try #require(BipartiteGraph(list))
            #expect(bipartite.edgeCount == n - 1)
            #expect(Array(bipartite.left) == Array(sides.left))
            #expect(bipartite.edges[n - 2].u == n - 2 && bipartite.edges[n - 3].u == n - 2)
        }.value
    }

    @Test("The odd cycle C₁₀₀₀₀₁: findOddCycle() is the whole cycle, in order", .timeLimit(.minutes(1)))
    func longOddCycle() async throws {
        try await Task {
            let n = 100_001
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == Array(0 ..< n))
            #expect(cycle.edges == Array(0 ..< n))
            // One more vertex makes the even cycle C₁₀₀₀₀₂: bipartite.
            let even = UndirectedAdjacencyList(vertices: 0 ..< n + 1, edges: (0 ..< n + 1).map { UndirectedEdge($0, ($0 + 1) % (n + 1)) })
            #expect(even.isBipartite)
            let evenSides = try #require(even.bipartition())
            #expect(evenSides.left.count == (n + 1) / 2)
        }.value
    }

    @Test("The 300 × 300 grid: bipartite by the parity of i + j; with the diagonal 0–301 the triangle 0, 1, 301", .timeLimit(.minutes(1)))
    func grid() async throws {
        try await Task {
            let (rows, columns) = (300, 300)
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< rows {
                for j in 0 ..< columns {
                    let v = i * columns + j
                    if j + 1 < columns { edges.append(UndirectedEdge(v, v + 1)) }
                    if i + 1 < rows { edges.append(UndirectedEdge(v, v + columns)) }
                }
            }
            let grid = UndirectedAdjacencyList(vertices: 0 ..< rows * columns, edges: edges)
            let sides = try #require(grid.bipartition())
            #expect(Array(sides.left) == (0 ..< rows * columns).filter { ($0 / columns + $0 % columns).isMultiple(of: 2) })
            #expect(sides.left.count == rows * columns / 2)
            let bipartite = try #require(BipartiteGraph(grid))
            #expect(bipartite.edgeCount == edges.count)
            // As BP-039 at 3 × 3: edges 0 (0–1) and 3 (1–301), then the diagonal at the last position.
            var diagonal = grid
            diagonal.insert(edge: UndirectedEdge(0, columns + 1))
            let cycle = try #require(diagonal.findOddCycle())
            #expect(cycle.vertices == [0, 1, columns + 1])
            #expect(cycle.edges == [0, 3, edges.count])
            #expect(BipartiteGraph(diagonal) == nil)
        }.value
    }

    @Test("A 10⁵-vertex BipartiteGraph built by insertion (an even cycle), half its left side removed", .timeLimit(.minutes(1)))
    func insertionAndRemoval() async {
        await Task {
            let half = 50_000
            var graph = BipartiteGraph<Int>()
            graph.reserveCapacity(vertexCount: 2 * half, edgeCount: 2 * half)
            for i in 0 ..< half {
                graph.insert(i, on: .left)
                graph.insert(half + i, on: .right)
            }
            for i in 0 ..< half {
                graph.insert(edge: UndirectedEdge(half + i, i))
                graph.insert(edge: UndirectedEdge(i, half + (i + 1) % half))
            }
            #expect(graph.edgeCount == 2 * half)
            #expect(graph.isBipartite)
            #expect(graph.edges.allSatisfy { $0.u < half && $0.v >= half })
            for i in stride(from: 0, to: half, by: 2) { graph.remove(i) }
            #expect(graph.vertexCount == 3 * half / 2)
            #expect(graph.edgeCount == half)
            #expect(Set(graph.left) == Set(stride(from: 1, to: half, by: 2)))
            #expect(graph.right.count == half)
            #expect(graph.edges.allSatisfy { graph.side(of: $0.u) == .left && graph.side(of: $0.v) == .right })
            #expect(graph.vertices.allSatisfy { graph.side(of: $0) == ($0 < half ? .left : .right) })
            let rebuilt = BipartiteGraph(left: stride(from: 1, to: half, by: 2), right: half ..< 2 * half, edges: Array(graph.edges).reversed())
            #expect(rebuilt == graph)
        }.value
    }

    @Test("Projections: a star K₁,₄₀₀ onto its leaves is K₄₀₀; a 10⁵-vertex path onto its even vertices is a path", .timeLimit(.minutes(1)))
    func projections() async throws {
        try await Task {
            let leaves = 400
            let star = try #require(BipartiteGraph(left: [-1], right: 0 ..< leaves, edges: (0 ..< leaves).map { UndirectedEdge(-1, $0) }))
            let complete = star.projectedGraph(onto: .right)
            #expect(complete.vertexCount == leaves)
            #expect(complete.edgeCount == leaves * (leaves - 1) / 2)
            #expect(star.projectedGraph(onto: .left).edgeCount == 0)
            let n = 100_000
            let path = try #require(BipartiteGraph(UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })))
            let evens = path.projectedGraph(onto: .left)
            #expect(Array(evens.vertices) == Array(stride(from: 0, to: n, by: 2)))
            #expect(evens.edgeCount == n / 2 - 1)
            #expect(evens.edges.map { [$0.u, $0.v] } == stride(from: 0, to: n - 2, by: 2).map { [$0, $0 + 2] })
        }.value
    }
}
