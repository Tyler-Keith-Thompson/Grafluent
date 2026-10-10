// Large inputs, each inside a Task (whose stack is much smaller than the main thread's, so a
// recursive search would overflow on the long paths and cycles) with a one-minute limit, meant to
// finish within seconds in a debug build; the benchmarks take timings. Expected values are known by
// construction: the even vertices of a long path and an even cycle; disjoint copies of catalog rows
// (each component's answer is the catalog's, shifted, since the lexicographic optimum of a union is
// the union of the components' optima); a planted perfect matching (the edge cover is the matching,
// the König covers as large); a star forest (the greedy dominating set is the hubs); and, for the
// dense branch and bound, a planted independent set larger than any other. Random instances use the
// package's seeded generator. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("Covering on large inputs")
struct CoveringStressTests {
    @Test("maximumIndependentSet() on the path P₁₀₀₀₀₁ and the even cycle C₁₀₀₀₀₀: the even vertices; the maximal set and the approximations on them", .timeLimit(.minutes(1)))
    func longPathAndCycle() async {
        await Task {
            let n = 100_000
            let path = UndirectedAdjacencyList(vertices: 0 ... n, edges: (0 ..< n).map { UndirectedEdge($0, $0 + 1) })
            let evens = Array(stride(from: 0, through: n, by: 2))
            #expect(path.maximumIndependentSet() == evens)
            #expect(path.independenceNumber() == n / 2 + 1)
            #expect(path.minimumVertexCover() == Array(stride(from: 1, to: n, by: 2)))
            #expect(path.maximalIndependentSet() == evens)
            // Bar-Yehuda–Even on the path in order (CV-093 at scale): each edge {i, i + 1} finds i with
            // the lesser remaining cost (0 after the previous subtraction, or a tie), so every vertex but
            // the last: twice τ = 50,000, the bound met exactly.
            #expect(path.approximateMinimumVertexCover() == Array(0 ..< n))
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(cycle.maximumIndependentSet() == Array(stride(from: 0, to: n, by: 2)))
            #expect(cycle.minimumVertexCover().count == n / 2)
            #expect(cycle.maximalIndependentSet(containing: [1]) == Array(stride(from: 1, to: n, by: 2)))
            // The cycle's edges taken alternately cover it exactly: ν = n / 2, so ρ = n / 2.
            #expect(cycle.minimumEdgeCover()?.count == n / 2)
        }.value
    }

    @Test("A random tree on 10⁵ vertices: α = n − ν (König), an independent and maximal set; the vertex cover as large as the matching", .timeLimit(.minutes(1)))
    func randomTree() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 21)
            // Vertex v > 0 hangs from a random earlier vertex.
            let edges = (1 ..< n).map { UndirectedEdge(Int.random(in: 0 ..< $0, using: &rng), $0) }
            let tree = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let nu = tree.maximumMatching().edges.count
            let independent = tree.maximumIndependentSet()
            #expect(independent.count == n - nu)
            #expect(tree.independenceNumber() == n - nu)
            #expect(tree.isIndependentSet(independent))
            #expect(independent == independent.sorted())
            let cover = tree.minimumVertexCover()
            #expect(cover.count == nu && tree.isVertexCover(cover))
            let sides = tree.bipartition()!
            #expect(tree.minimumVertexCover(bipartition: sides).count == nu)
            #expect(tree.minimumEdgeCover()?.count == n - nu)
        }.value
    }

    @Test("20,000 copies of CV-064's bipartite gadget (120,000 vertices): minimumVertexCover() is each copy's right side, König's cover each copy's left side", .timeLimit(.minutes(1)))
    func bipartiteGadgets() async throws {
        try await Task {
            let copies = 20_000
            // Copy c: left 6c, 6c + 1, 6c + 2, right 6c + 3, 6c + 4, 6c + 5, edges 0-3, 1-3, 1-4, 2-4, 2-5.
            let shape = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            var pairs: [(Int, Int)] = []
            for c in 0 ..< copies { pairs += shape.map { (6 * c + $0.0, 6 * c + $0.1) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 6 * copies, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let right = (0 ..< copies).flatMap { [6 * $0 + 3, 6 * $0 + 4, 6 * $0 + 5] }
            let left = (0 ..< copies).flatMap { [6 * $0, 6 * $0 + 1, 6 * $0 + 2] }
            #expect(graph.minimumVertexCover() == right)
            #expect(graph.maximumIndependentSet() == left)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == left)
            #expect(graph.minimumVertexCover(bipartition: sides) == left)
            #expect(graph.maximumBipartiteMatching(bipartition: sides).edges.count == 3 * copies)
        }.value
    }

    @Test("A random bipartite graph on 10⁵ vertices with a planted perfect matching: both minimum covers 50,000 vertices, the edge cover the matching", .timeLimit(.minutes(1)))
    func plantedBipartite() async throws {
        try await Task {
            let half = 50_000
            var rng = SeededRandomNumberGenerator(seed: 22)
            let planted = Array(0 ..< half).shuffled(using: &rng)
            var pairs: [(Int, Int)] = (0 ..< half).map { ($0, half + planted[$0]) }
            for _ in 0 ..< 100_000 { pairs.append((Int.random(in: 0 ..< half, using: &rng), half + Int.random(in: 0 ..< half, using: &rng))) }
            pairs.shuffle(using: &rng)
            let graph = try #require(BipartiteGraph(left: 0 ..< half, right: half ..< 2 * half, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
            let cover = graph.minimumVertexCover()
            #expect(cover.count == half)
            #expect(graph.isVertexCover(cover))
            #expect(graph.independenceNumber() == half)
            let sides = try #require(graph.bipartition())
            let koenig = graph.minimumVertexCover(bipartition: sides)
            #expect(koenig.count == half && graph.isVertexCover(koenig))
            let matching = graph.maximumBipartiteMatching()
            #expect(graph.minimumEdgeCover(matching: matching) == matching.edges)
            let approximate = graph.approximateMinimumVertexCover()
            #expect(graph.isVertexCover(approximate) && approximate.count <= 2 * half)
        }.value
    }

    @Test("1,000 copies of the Petersen graph and of P₇: minimumDominatingSet() is each copy's catalog set (CV-141, CV-137) shifted; the greedy approximation on 2,000 stars of ten leaves is the hubs", .timeLimit(.minutes(1)))
    func dominatingComponents() async {
        await Task {
            // Petersen as NetworkX numbers it: outer cycle 0–4, spokes i–(i + 5), inner pentagram.
            let petersen = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            var pairs: [(Int, Int)] = []
            let copies = 1_000
            for c in 0 ..< copies { pairs += petersen.map { (10 * c + $0.0, 10 * c + $0.1) } }
            let base = 10 * copies
            for c in 0 ..< copies { pairs += (0 ..< 6).map { (base + 7 * c + $0, base + 7 * c + $0 + 1) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< base + 7 * copies, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let inPetersens: [Int] = (0 ..< copies).flatMap { (c: Int) -> [Int] in [10 * c, 10 * c + 2, 10 * c + 6] }
            let inPaths: [Int] = (0 ..< copies).flatMap { (c: Int) -> [Int] in [base + 7 * c, base + 7 * c + 2, base + 7 * c + 5] }
            let expected = inPetersens + inPaths
            let dominating = graph.minimumDominatingSet()
            #expect(dominating == expected)
            #expect(graph.isDominatingSet(dominating))
            // Petersen's α is 4 per copy (CV-045) and P₇'s is 4.
            #expect(graph.independenceNumber() == 8 * copies)
            let stars = 2_000
            let forest = UndirectedAdjacencyList(vertices: 0 ..< 11 * stars, edges: (0 ..< stars).flatMap { s in (1 ... 10).map { UndirectedEdge(11 * s, 11 * s + $0) } })
            let hubs = (0 ..< stars).map { 11 * $0 }
            #expect(forest.approximateMinimumDominatingSet() == hubs)
            #expect(forest.approximateMinimumDominatingSet(weight: { (_: Int) -> Int in 3 }) == hubs)
            #expect(forest.minimumDominatingSet() == hubs)
            #expect(forest.approximateMinimumVertexCover() == hubs)
            #expect(forest.maximalIndependentSet() == hubs)
        }.value
    }

    @Test("Branch and bound on a dense random graph: 60 vertices, edge probability ½ outside a planted independent set of 16, which is the maximum one", .timeLimit(.minutes(1)))
    func denseBranchAndBound() async {
        await Task {
            let n = 60
            var rng = SeededRandomNumberGenerator(seed: 23)
            let planted = Set(Array(0 ..< n).shuffled(using: &rng).prefix(16))
            var edges: [UndirectedEdge<Int>] = []
            for a in 0 ..< n {
                for b in a + 1 ..< n where !(planted.contains(a) && planted.contains(b)) && Bool.random(using: &rng) { edges.append(UndirectedEdge(a, b)) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let independent = graph.maximumIndependentSet()
            #expect(independent.count >= 16)
            #expect(graph.isIndependentSet(independent))
            // The planted set: G(60, ½) alone has α near 10, so no other set of 16 is independent.
            #expect(independent == planted.sorted())
            #expect(graph.independenceNumber() == independent.count)
            #expect(graph.minimumVertexCover() == (0 ..< n).filter { !planted.contains($0) })
            // Maximal: every other vertex has a neighbour in it.
            let inside = Set(independent)
            #expect((0 ..< n).allSatisfy { v in inside.contains(v) || graph.neighbors(of: v).contains { inside.contains($0) } })
        }.value
    }

    @Test("The greedy and checking entry points on a random graph of 10⁵ vertices and 3 · 10⁵ edges: valid, and the approximation inside the ends of maximalMatching()", .timeLimit(.minutes(1)))
    func linearEntryPoints() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 24)
            let edges = (0 ..< 3 * n).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let maximal = graph.maximalIndependentSet()
            #expect(graph.isIndependentSet(maximal))
            #expect(graph.isDominatingSet(maximal) || edges.contains { $0.u == $0.v })
            let cover = graph.approximateMinimumVertexCover()
            #expect(graph.isVertexCover(cover))
            let weighted = graph.approximateMinimumVertexCover(weight: { Double($0 % 7) })
            #expect(graph.isVertexCover(weighted))
            let dominating = graph.approximateMinimumDominatingSet()
            #expect(graph.isDominatingSet(dominating))
            let loopFree = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.filter { $0.u != $0.v })
            let matched = Set(loopFree.maximalMatching().edges.flatMap { [loopFree.edges[$0].u, loopFree.edges[$0].v] })
            #expect(loopFree.approximateMinimumVertexCover().allSatisfy { matched.contains($0) })
        }.value
    }
}
