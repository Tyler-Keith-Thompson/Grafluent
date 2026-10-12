// §H: 10⁶-vertex shapes, which no recursive walk survives. Each runs inside a Task, whose stack is
// much smaller than the main thread's, so recursion over the 10⁶-vertex path (depth 10⁶ − 1)
// overflows: the Euler tour, the heavy-first preorder, the subtree sizes, the eccentricity
// passes and the centroid decomposition must all be iterative. The star has one row of
// 10⁶ − 1 entries and 999 999 one-vertex components in its decomposition; kary(10⁶, 2) is the
// binary heap shape (height 19). Trees are built through `Tree(vertices:edges:)`. Each test has a
// one-minute limit and is meant to stay within a few seconds in a debug build; the benchmarks
// take timings. Expected values are the catalog's (closed forms checked by `ref.py`) or were
// computed with `ref.py`'s model on the same shapes. Case IDs (TA-nnn) refer to the catalog; see
// README.md.

import GraphProtocols
import Testing
import TreeAlgorithms
import Trees

@Suite("TreeAlgorithms at 10⁶ vertices, without recursion")
struct TreeAlgorithmStressTests {
    @Test("TA-901 Tree(P(0..999999)).diameter() is 999999", .timeLimit(.minutes(1)))
    func pathDiameter() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            #expect(tree.diameter() == 999_999)
            // Computed with ref.py: the path from the first end to the other.
            let path = tree.diameterPath()
            #expect(path.vertices == Array(0 ..< n))
            #expect(path.edges == Array(0 ..< n - 1))
        }.value
    }

    @Test("TA-902 Tree(P(0..999999)).center() is [499999, 500000]", .timeLimit(.minutes(1)))
    func pathCenter() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            #expect(tree.center() == [499_999, 500_000])
        }.value
    }

    @Test("TA-903 Tree(P(0..999999)).centroid() is [499999, 500000]", .timeLimit(.minutes(1)))
    func pathCentroid() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            #expect(tree.centroid() == [499_999, 500_000])
        }.value
    }

    @Test("TA-904 LowestCommonAncestors(P(0..999999), root: 0).lowestCommonAncestor(of: 999999, 500000) is 500000", .timeLimit(.minutes(1)))
    func pathDeepLCA() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let rooted = RootedTree(tree, root: 0)
            let lca = LowestCommonAncestors(rooted)
            #expect(lca.lowestCommonAncestor(of: 999_999, 500_000) == 500_000)
            // Computed with ref.py: the one-shot climb at depth 10⁶ − 1.
            #expect(rooted.lowestCommonAncestor(of: 999_999, 500_000) == 500_000)
        }.value
    }

    @Test("TA-905 LowestCommonAncestors(P(0..999999), root: 0).distance(from: 3, to: 999999) is 999996", .timeLimit(.minutes(1)))
    func pathDeepDistance() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let lca = LowestCommonAncestors(RootedTree(tree, root: 0))
            #expect(lca.distance(from: 3, to: 999_999) == 999_996)
        }.value
    }

    @Test("TA-906 RootedTree(P(0..999999), root: 0).eulerTour.length is 1999998", .timeLimit(.minutes(1)))
    func pathEulerTour() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let tour = RootedTree(tree, root: 0).eulerTour
            #expect(tour.length == 1_999_998)
            #expect(tour.vertices.count == 1_999_999)
            #expect(tour.vertices[999_999] == 999_999)
            #expect(tour.isClosed)
        }.value
    }

    @Test("TA-907 HeavyLightDecomposition(P(0..999999), root: 0).segments(from: 999999, to: 0) is [0..<1000000 R]: one heavy path", .timeLimit(.minutes(1)))
    func pathOneHeavyPath() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let hld = HeavyLightDecomposition(RootedTree(tree, root: 0))
            let segments = hld.segments(from: 999_999, to: 0)
            #expect(segments.map(\.positions) == [0 ..< 1_000_000])
            #expect(segments.map(\.isReversed) == [true])
            #expect(hld.head(of: 999_999) == 0)
        }.value
    }

    @Test("TA-908 LowestCommonAncestors(P(0..999999), root: 500000).lowestCommonAncestor(of: 0, 999999) is 500000", .timeLimit(.minutes(1)))
    func pathMiddleLCA() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let lca = LowestCommonAncestors(RootedTree(tree, root: 500_000))
            #expect(lca.lowestCommonAncestor(of: 0, 999_999) == 500_000)
        }.value
    }

    @Test("TA-909 HeavyLightDecomposition(P(0..999999), root: 500000).segments(from: 0, to: 999999) is [0..<500001 R, 500001..<1000000]", .timeLimit(.minutes(1)))
    func pathMiddleSegments() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let hld = HeavyLightDecomposition(RootedTree(tree, root: 500_000))
            let segments = hld.segments(from: 0, to: 999_999)
            #expect(segments.map(\.positions) == [0 ..< 500_001, 500_001 ..< 1_000_000])
            #expect(segments.map(\.isReversed) == [true, false])
            // Computed with ref.py: the heavy side is 0 … 499999.
            #expect(hld.heavyChild(of: 500_000) == 499_999)
            #expect(hld.head(of: 999_999) == 500_001)
            #expect(hld.lowestCommonAncestor(of: 0, 999_999) == 500_000)
        }.value
    }

    @Test("TA-910 Tree(S(0; 1..999999)).diameter() is 2", .timeLimit(.minutes(1)))
    func starDiameter() async throws {
        try await Task {
            // U: [] S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            #expect(tree.diameter() == 2)
            // Computed with ref.py.
            #expect(tree.diameter(weight: { _ in 2 }) == 4)
        }.value
    }

    @Test("TA-911 Tree(S(0; 1..999999)).center() is [0]", .timeLimit(.minutes(1)))
    func starCenter() async throws {
        try await Task {
            // U: [] S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            #expect(tree.center() == [0])
        }.value
    }

    @Test("TA-912 Tree(S(0; 1..999999)).centroid() is [0]", .timeLimit(.minutes(1)))
    func starCentroid() async throws {
        try await Task {
            // U: [] S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            #expect(tree.centroid() == [0])
        }.value
    }

    @Test("TA-913 Tree(S(0; 1..999999)).diameterPath() is [1, 0, 2] / [0, 1]", .timeLimit(.minutes(1)))
    func starDiameterPath() async throws {
        try await Task {
            // U: [] S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            let path = tree.diameterPath()
            #expect(path.vertices == [1, 0, 2])
            #expect(path.edges == [0, 1])
        }.value
    }

    @Test("TA-914 Tree(S(0; 1..999999)).centroidDecomposition().height is 1", .timeLimit(.minutes(1)))
    func starDecomposition() async throws {
        try await Task {
            // U: [] S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            let decomposition = tree.centroidDecomposition()
            #expect(decomposition.height == 1)
            #expect(decomposition.root == 0)
            #expect(decomposition.children(of: 0).count == 999_999)
        }.value
    }

    @Test("The 10⁶-leaf star rooted at its center: a 10⁶-entry row for LCA, HLD and the Euler tour", .timeLimit(.minutes(1)))
    func starRootedQueries() async throws {
        try await Task {
            // U: [] S(0;1..999999). Computed with ref.py.
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            let rooted = RootedTree(tree, root: 0)
            #expect(LowestCommonAncestors(rooted).lowestCommonAncestor(of: 999_999, 1) == 0)
            let hld = HeavyLightDecomposition(rooted)
            #expect(hld.heavyChild(of: 0) == 1)
            let segments = hld.segments(from: 999_999, to: 1)
            #expect(segments.map(\.positions) == [999_999 ..< 1_000_000, 0 ..< 2])
            #expect(segments.map(\.isReversed) == [false, false])
            #expect(RootedTree(tree, root: 999_999).eulerTour.length == 1_999_998)
        }.value
    }

    @Test("TA-915 Tree(P(0..131070)).centroidDecomposition().height is 16: 2¹⁷ − 1 vertices", .timeLimit(.minutes(1)))
    func pathDecompositionHeight() async throws {
        try await Task {
            // U: [] P(0..131070)
            let n = 131_071
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let decomposition = tree.centroidDecomposition()
            #expect(decomposition.height == 16)
            #expect(decomposition.vertexCount == n)
        }.value
    }

    @Test("TA-916 Tree(P(0..999999)).diameter(weight: 2) is 1999998", .timeLimit(.minutes(1)))
    func pathWeightedDiameter() async throws {
        try await Task {
            // U: [] P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            #expect(tree.diameter(weight: { _ in 2 }) == 1_999_998)
            #expect(tree.diameter(weight: { _ in 2.0 }) == 1_999_998)
        }.value
    }

    @Test("TA-917 LowestCommonAncestors(kary(10⁶, 2), root: 0).lowestCommonAncestor(of: 999999, 524287) is 0", .timeLimit(.minutes(1)))
    func heapShapeLCA() async throws {
        try await Task {
            // U: [] kary(1000000,2)
            let n = 1_000_000
            let edges = (1 ..< n).map { UndirectedEdge(($0 - 1) / 2, $0) }
            let tree = try #require(Tree(vertices: 0 ..< n, edges: edges))
            let rooted = RootedTree(tree, root: 0)
            let lca = LowestCommonAncestors(rooted)
            #expect(lca.lowestCommonAncestor(of: 999_999, 524_287) == 0)
            // Computed with ref.py.
            #expect(lca.distance(from: 999_999, to: 524_287) == 38)
            let hld = HeavyLightDecomposition(rooted)
            #expect(hld.lowestCommonAncestor(of: 999_999, 524_287) == 0)
            #expect(hld.segments(from: 999_999, to: 524_287).count == 7)
        }.value
    }

    @Test("TA-918 Tree(kary(10⁶, 2)).diameter() is 38", .timeLimit(.minutes(1)))
    func heapShapeDiameter() async throws {
        try await Task {
            // U: [] kary(1000000,2)
            let n = 1_000_000
            let edges = (1 ..< n).map { UndirectedEdge(($0 - 1) / 2, $0) }
            let tree = try #require(Tree(vertices: 0 ..< n, edges: edges))
            #expect(tree.diameter() == 38)
        }.value
    }
}
