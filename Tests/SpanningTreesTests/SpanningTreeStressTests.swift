// Long, wide and dense graphs inside a Task: a long path, a grid, a star, a complete graph, a
// sparse random graph with every weight equal, and the real-world fixtures through
// AdjacencyList.undirected. Sizes are scaled so each test stays well under a few seconds in a debug
// build; the catalog's larger sizes are benchmarks (ST-B01). Only answers are asserted. Case IDs
// (ST-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

/// An undirected graph on 0..<n stored as rows of edge positions, built in O(n + m) with no hashing
/// so that construction does not dominate in a debug build. Vertex indices are the vertices and
/// edge indices the positions; a self-loop is listed twice in its row.
private struct RowGraph: Graph, Sendable {
    let vertexCount: Int
    let edges: [UndirectedEdge<Int>]
    private let offsets: [Int]
    private let ends: [Int]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>]) {
        var offsets = [Int](repeating: 0, count: vertexCount + 1)
        for edge in edges {
            offsets[edge.u + 1] += 1
            offsets[edge.v + 1] += 1
        }
        for v in 0 ..< vertexCount { offsets[v + 1] += offsets[v] }
        var next = offsets
        var ends = [Int](repeating: 0, count: 2 * edges.count)
        for (position, edge) in edges.enumerated() {
            ends[next[edge.u]] = position
            next[edge.u] += 1
            ends[next[edge.v]] = position
            next[edge.v] += 1
        }
        self.vertexCount = vertexCount
        self.edges = edges
        self.offsets = offsets
        self.ends = ends
    }

    var vertices: Range<Int> { 0 ..< vertexCount }
    func incidentEdges(of vertex: Int) -> ArraySlice<Int> { ends[offsets[vertex] ..< offsets[vertex + 1]] }
    func neighbors(of vertex: Int) -> LazyMapSequence<ArraySlice<Int>, Int> {
        incidentEdges(of: vertex).lazy.map { edges[$0].oppositeVertex(to: vertex) }
    }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertexCount }
    var vertexIndexBound: Int? { vertexCount }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Spanning-tree stress")
struct SpanningTreeStressTests {
    @Test("ST-110 a 100 000-vertex path with weights k % 1000: every edge, in (weight, position) order")
    func longPath() async {
        await Task {
            let n = 100_000
            let path = RowGraph(vertexCount: n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let total = (0 ..< n - 1).reduce(0) { $0 + $1 % 1000 }
            // Kruskal's order: every residue in turn, positions ascending within it.
            let order = (0 ..< 1000).flatMap { Array(stride(from: $0, to: n - 1, by: 1000)) }
            let kruskal = path.kruskalMinimumSpanningTree { $0 % 1000 }
            #expect(kruskal.edges == order)
            #expect(kruskal.weight == total)
            #expect(path.minimumSpanningTree { $0 % 1000 } == kruskal)
            let boruvka = path.boruvkaMinimumSpanningTree { $0 % 1000 }
            #expect(boruvka.edges.count == n - 1)
            #expect(Set(boruvka.edges).count == n - 1)
            #expect(boruvka.weight == total)
            // From vertex 0 Prim has one choice at each step.
            let prim = path.primMinimumSpanningTree { $0 % 1000 }
            #expect(prim.edges == Array(0 ..< n - 1))
            #expect(prim.weight == total)
            let fromMiddle = path.primMinimumSpanningTree(from: n / 2) { $0 % 1000 }
            #expect(fromMiddle.edges.count == n - 1)
            #expect(fromMiddle.weight == total)
            #expect(path.minimumSpanningTree().edges == Array(0 ..< n - 1))
        }.value
    }

    @Test("ST-111 a 200 × 200 grid with random Int weights: equal weights, Kruskal ≡ Borůvka", .tags(.randomized))
    func grid() async {
        await Task {
            let side = 200
            var edges: [UndirectedEdge<Int>] = []
            edges.reserveCapacity(2 * side * side)
            for r in 0 ..< side {
                for c in 0 ..< side {
                    let v = r * side + c
                    if c + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                    if r + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
                }
            }
            let grid = RowGraph(vertexCount: side * side, edges: edges)
            var rng = SeededRandomNumberGenerator(seed: 111)
            let weights = edges.map { _ in Int.random(in: 1 ... 100, using: &rng) }
            let kruskal = grid.kruskalMinimumSpanningTree { weights[$0] }
            #expect(kruskal.edges.count == side * side - 1)
            #expect(grid.minimumSpanningTree { weights[$0] } == kruskal)
            let boruvka = grid.boruvkaMinimumSpanningTree { weights[$0] }
            #expect(Set(boruvka.edges) == Set(kruskal.edges))
            #expect(boruvka.weight == kruskal.weight)
            let prim = grid.primMinimumSpanningTree { weights[$0] }
            #expect(prim.edges.count == side * side - 1)
            #expect(prim.weight == kruskal.weight)
        }.value
    }

    @Test("ST-112 a star with 50 000 leaves: every edge, Prim's queue holds every leaf")
    func star() async {
        await Task {
            let leaves = 50_000
            let star = RowGraph(vertexCount: leaves + 1, edges: (1 ... leaves).map { UndirectedEdge(0, $0) })
            // Edge k weighs k + 1: distinct, so both orders are determined.
            let total = leaves * (leaves + 1) / 2
            let kruskal = star.kruskalMinimumSpanningTree { $0 + 1 }
            #expect(kruskal.edges == Array(0 ..< leaves))
            #expect(kruskal.weight == total)
            let boruvka = star.boruvkaMinimumSpanningTree { $0 + 1 }
            #expect(Set(boruvka.edges) == Set(0 ..< leaves))
            #expect(boruvka.weight == total)
            // From the center every leaf is queued at once and leaves in weight order.
            let prim = star.primMinimumSpanningTree { $0 + 1 }
            #expect(prim.edges == Array(0 ..< leaves))
            #expect(prim.weight == total)
            // From a leaf, the same tree.
            let fromLeaf = star.primMinimumSpanningTree(from: leaves) { $0 + 1 }
            #expect(fromLeaf.edges.count == leaves)
            #expect(fromLeaf.weight == total)
            #expect(star.maximumSpanningTree { $0 + 1 }.edges == Array((0 ..< leaves).reversed()))
        }.value
    }

    @Test("ST-113 K₄₅₀ (101 025 edges) with random weights: the dense case, three-way agreement", .tags(.randomized))
    func completeGraph() async {
        await Task {
            let n = 450
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< n { for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) } }
            let complete = RowGraph(vertexCount: n, edges: edges)
            var rng = SeededRandomNumberGenerator(seed: 113)
            let weights = edges.map { _ in Int.random(in: 1 ... 1_000_000_000, using: &rng) }
            let kruskal = complete.kruskalMinimumSpanningTree { weights[$0] }
            #expect(kruskal.edges.count == n - 1)
            #expect(complete.minimumSpanningTree { weights[$0] } == kruskal)
            let boruvka = complete.boruvkaMinimumSpanningTree { weights[$0] }
            #expect(Set(boruvka.edges) == Set(kruskal.edges))
            #expect(boruvka.weight == kruskal.weight)
            let prim = complete.primMinimumSpanningTree { weights[$0] }
            #expect(prim.weight == kruskal.weight)
            #expect(prim.edges.count == n - 1)
        }.value
    }

    @Test("ST-114 G(5·10⁴, 10⁵) with every weight equal: the canonical forest is the first forest in position order", .tags(.randomized))
    func equalWeights() async {
        await Task {
            let n = 50_000
            var rng = SeededRandomNumberGenerator(seed: 114)
            // Self-loops and parallel edges happen by chance.
            let edges = (0 ..< 100_000).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let graph = RowGraph(vertexCount: n, edges: edges)
            let first = graph.minimumSpanningTree()
            let tree = graph.minimumSpanningTree { _ in 5 }
            #expect(tree.edges == first.edges)
            #expect(tree.weight == 5 * first.edges.count)
            #expect(graph.kruskalMinimumSpanningTree { _ in 5 } == tree)
            #expect(Set(graph.boruvkaMinimumSpanningTree { _ in 5 }.edges) == Set(first.edges))
            #expect(graph.primMinimumSpanningTree { _ in 5 }.edges.count == first.edges.count)
            #expect(graph.maximumSpanningTree { _ in 5 }.edges == first.edges)
            // The first forest, by an in-test union–find.
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x {
                    parent[x] = parent[parent[x]]
                    x = parent[x]
                }
                return x
            }
            var expected: [Int] = []
            for (position, edge) in edges.enumerated() {
                let (ru, rv) = (find(edge.u), find(edge.v))
                if ru != rv {
                    parent[ru] = rv
                    expected.append(position)
                }
            }
            #expect(first.edges == expected)
        }.value
    }

    @Test("ST-115 the real-world fixtures through AdjacencyList.undirected: three-way agreement, n − c edges", .tags(.fixture), arguments: DirectedFixture<Int>.realWorld)
    func realWorld(fixture: DirectedFixture<Int>) async {
        await Task {
            let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).undirected
            // A hash of the position as the weight.
            let weight: (Int) -> Int = { ($0 &* 2_654_435_761) % 1000 }
            let n = graph.vertexCount
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for edge in graph.edges {
                let (ru, rv) = (find(graph.vertexIndex(of: edge.u)), find(graph.vertexIndex(of: edge.v)))
                if ru != rv { parent[ru] = rv }
            }
            let components = (0 ..< n).filter { find($0) == $0 }.count
            let kruskal = graph.kruskalMinimumSpanningTree(weight: weight)
            #expect(kruskal.edges.count == n - components, "\(fixture.name)")
            #expect(graph.minimumSpanningTree(weight: weight) == kruskal, "\(fixture.name)")
            let boruvka = graph.boruvkaMinimumSpanningTree(weight: weight)
            #expect(Set(boruvka.edges) == Set(kruskal.edges), "\(fixture.name)")
            #expect(boruvka.weight == kruskal.weight, "\(fixture.name)")
            let prim = graph.primMinimumSpanningTree(weight: weight)
            #expect(prim.edges.count == n - components, "\(fixture.name)")
            #expect(prim.weight == kruskal.weight, "\(fixture.name)")
            #expect(graph.minimumSpanningTree().edges.count == n - components, "\(fixture.name)")
        }.value
    }

    @Test("ST-116 the grid of ST-111 inside a Task, its forest sent back out", .tags(.randomized))
    func insideATask() async {
        let side = 200
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< side {
            for c in 0 ..< side {
                let v = r * side + c
                if c + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                if r + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
            }
        }
        var rng = SeededRandomNumberGenerator(seed: 111)
        let weights = edges.map { _ in Int.random(in: 1 ... 100, using: &rng) }
        let grid = RowGraph(vertexCount: side * side, edges: edges)
        let forest: SpanningForest<RowGraph, Int> = await Task { grid.kruskalMinimumSpanningTree { weights[$0] } }.value
        let prim: SpanningForest<RowGraph, Int> = await Task { grid.primMinimumSpanningTree { weights[$0] } }.value
        #expect(forest == grid.kruskalMinimumSpanningTree { weights[$0] })
        #expect(forest.edges.count == side * side - 1)
        #expect(prim.weight == forest.weight)
    }
}
