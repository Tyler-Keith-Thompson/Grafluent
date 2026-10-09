// Conformances and representations. api.md: `LowestCommonAncestors`, `HeavyLightDecomposition`,
// its `Preorder` and `Segment` are value types, `Sendable` when `Vertex` is; `Segment` is
// `Hashable` with mutable `positions` and `isReversed`; `Preorder` is a `RandomAccessCollection`
// of vertices. The structures share the tree's storage, so they keep answering for the tree they
// were built from whatever happens to the variable that held it. Inputs reach the module through
// every Trees type, so catalog rows are repeated on trees built from the package's
// `UndirectedAdjacencyList` and `AdjacencyList` (written in catalog order, which keeps vertex
// order and edge positions), from `Tree(edges:)`, from parent functions, and with `Collider`
// vertices whose hashes all collide; the expected values are the catalog cells of the rows named.
// Case IDs (TA-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees
import Walks

@Suite("TreeAlgorithms conformances and representations", .tags(.conformance))
struct TreeAlgorithmConformanceTests {
    @Test("LowestCommonAncestors, HeavyLightDecomposition, Preorder and Segment are Sendable and cross a Task")
    func sendable() async throws {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let tree = try #require(Tree(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let rooted = RootedTree(tree, root: 0)
        let lca = requireSendable(LowestCommonAncestors(rooted))
        let hld = requireSendable(HeavyLightDecomposition(rooted))
        let preorder = requireSendable(hld.preorder)
        let segments = requireSendable(hld.segments(from: 7, to: 8))
        // TA-104, TA-304, TA-317, read on another task.
        let answer = await Task { lca.lowestCommonAncestor(of: 3, 7) }.value
        #expect(answer == 1)
        let order = await Task { Array(preorder) }.value
        #expect(order == [0, 1, 4, 6, 7, 3, 2, 5, 8])
        let ranges = await Task { segments.map(\.positions) }.value
        #expect(ranges == [4 ..< 5, 0 ..< 3, 6 ..< 9])
        let decomposition = await Task { hld.segments(from: 8, to: 7).map(\.isReversed) }.value
        #expect(decomposition == [true, false, false])
    }

    @Test("The structures are values: copies answer alike, and keep the tree they were built from")
    func valueSemantics() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let tree = try #require(Tree(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        var rooted = RootedTree(tree, root: 0)
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        let lcaCopy = lca
        let hldCopy = hld
        // Rebinding the variable to F1 rooted at 4 does not change the structures (TA-104, TA-304).
        rooted = RootedTree(tree, root: 4)
        #expect(rooted.root == 4)
        #expect(lca.lowestCommonAncestor(of: 3, 7) == 1)
        #expect(lcaCopy.lowestCommonAncestor(of: 3, 7) == 1)
        #expect(Array(hld.preorder) == [0, 1, 4, 6, 7, 3, 2, 5, 8])
        #expect(Array(hldCopy.preorder) == Array(hld.preorder))
        // The structures built at 4 answer for that root (TA-009, TA-328).
        #expect(LowestCommonAncestors(rooted).lowestCommonAncestor(of: 3, 8) == 1)
        #expect(Array(HeavyLightDecomposition(rooted).preorder) == [4, 1, 0, 2, 5, 8, 3, 6, 7])
    }

    @Test("Segment is Hashable with mutable fields; equal segments come from equal queries")
    func segmentHashable() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8 (TA-317, TA-318)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let tree = try #require(Tree(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let hld = HeavyLightDecomposition(RootedTree(tree, root: 0))
        let forward = hld.segments(from: 7, to: 8)
        let backward = hld.segments(from: 8, to: 7)
        #expect(forward == hld.segments(from: 7, to: 8))
        #expect(Set(forward).count == 3)
        // 4..<5 is one position, so it is not reversed either way and is the same segment.
        #expect(Set(forward).intersection(Set(backward)).map(\.positions) == [4 ..< 5])
        #expect(forward[2].hashValue == hld.segments(from: 7, to: 8)[2].hashValue)
        var flipped = forward[1]
        #expect(flipped.isReversed)
        flipped.isReversed = false
        #expect(flipped == backward[1])
        flipped.positions = 0 ..< 2
        #expect(flipped != backward[1])
    }

    @Test("HeavyLightDecomposition.Preorder is a RandomAccessCollection of vertices")
    func preorderCollection() throws {
        func elements<C: RandomAccessCollection>(_ collection: C) -> (first: C.Element?, last: C.Element?, count: Int, reversed: [C.Element]) {
            (collection.first, collection.last, collection.distance(from: collection.startIndex, to: collection.endIndex), Array(collection.reversed()))
        }
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8 (TA-304)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let tree = try #require(Tree(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let hld = HeavyLightDecomposition(RootedTree(tree, root: 0))
        let preorder = hld.preorder
        let summary = elements(preorder)
        #expect(summary.first == 0)
        #expect(summary.last == 8)
        #expect(summary.count == 9)
        #expect(summary.reversed == [8, 5, 2, 3, 7, 6, 4, 1, 0])
        // A heavy path is an interval from its head: 0, 1, 4, 6 (TA-310, TA-320).
        let start = preorder.startIndex
        let heavyPath = preorder[start ..< preorder.index(start, offsetBy: 4)]
        #expect(Array(heavyPath) == [0, 1, 4, 6])
    }

    @Test("Generic code over Vertex: Int and String trees through one function")
    func genericCode() throws {
        func summary<V: Hashable>(_ rooted: RootedTree<V>, _ a: V, _ b: V) -> (one: V, both: V, heavy: V, distance: Int, tour: Int) {
            let lca = LowestCommonAncestors(rooted)
            let hld = HeavyLightDecomposition(rooted)
            return (rooted.lowestCommonAncestor(of: a, b), lca.lowestCommonAncestor(of: a, b), hld.lowestCommonAncestor(of: a, b), lca.distance(from: a, to: b), rooted.eulerTour.length)
        }
        // TA-003, TA-108 on F1; TA-018 on the String tree.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let tree = try #require(Tree(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let ints = summary(RootedTree(tree, root: 0), 3, 7)
        #expect(ints.one == 1)
        #expect(ints.both == 1)
        #expect(ints.heavy == 1)
        #expect(summary(RootedTree(tree, root: 0), 3, 8).distance == 5)
        #expect(ints.tour == 16)
        let names: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let named = try #require(Tree(edges: names.map { UndirectedEdge($0.0, $0.1) }))
        let strings = summary(RootedTree(named, root: "c"), "a", "e")
        #expect(strings.one == "b")
        #expect(strings.both == "b")
        #expect(strings.heavy == "b")
    }

    @Test("TA-204 TA-304 TA-317 TA-410 TA-508 TA-515 TA-609 on F1 from an UndirectedAdjacencyList")
    func undirectedAdjacencyList() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [0, 1, 3, 1, 4, 6, 4, 7, 4, 1, 0, 2, 5, 8, 5, 2, 0])
        #expect(tour.edges == [0, 2, 2, 3, 5, 5, 6, 6, 3, 0, 1, 4, 7, 7, 4, 1])
        let hld = HeavyLightDecomposition(rooted)
        #expect(Array(hld.preorder) == [0, 1, 4, 6, 7, 3, 2, 5, 8])
        let segments = hld.segments(from: 7, to: 8)
        #expect(segments.map(\.positions) == [4 ..< 5, 0 ..< 3, 6 ..< 9])
        #expect(segments.map(\.isReversed) == [false, true, false])
        #expect(tree.center() == [0])
        #expect(tree.centroid() == [1])
        let decomposition = tree.centroidDecomposition()
        #expect(decomposition == RootedTree(parents: [2, nil, 1, 1, 1, 2, 4, 4, 5]))
        let path = tree.diameterPath()
        #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(path.edges == [5, 3, 0, 1, 4, 7])
    }

    @Test("TA-012 – TA-015 TA-114 TA-210 TA-332 on NX from an AdjacencyList")
    func adjacencyList() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = AdjacencyList(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.lowestCommonAncestor(of: 3, 4) == 1)
        #expect(arborescence.lowestCommonAncestor(of: 3, 5) == 0)
        #expect(arborescence.lowestCommonAncestor(of: 5, 6) == 2)
        #expect(arborescence.lowestCommonAncestor(of: 2, 6) == 2)
        let lca = LowestCommonAncestors(arborescence)
        #expect(lca.lowestCommonAncestor(of: 4, 5) == 0)
        let tour = RootedTree(arborescence).eulerTour
        #expect(tour.vertices == [0, 1, 3, 1, 4, 1, 0, 2, 5, 2, 6, 2, 0])
        #expect(tour.edges == [0, 2, 2, 3, 3, 0, 1, 4, 4, 5, 5, 1])
        let segments = HeavyLightDecomposition(arborescence).segments(from: 4, to: 6)
        #expect(segments.map(\.positions) == [3 ..< 4, 0 ..< 2, 4 ..< 5, 6 ..< 7])
        #expect(segments.map(\.isReversed) == [false, true, false, false])
    }

    @Test("TA-016 TA-017 TA-513 TA-517 from parent functions and Tree(edges:)")
    func parentFunctionsAndEdges() throws {
        // parents: [_, 0, 0, 1, 1, 2, 2] (TA-016) and [3, 3, _, 2, 0] (TA-017), as closures.
        let nxParents: [Int?] = [nil, 0, 0, 1, 1, 2, 2]
        let arborescence = try #require(Arborescence(vertices: 0 ..< 7, parent: { nxParents[$0] }))
        #expect(arborescence.lowestCommonAncestor(of: 4, 6) == 0)
        let parents: [Int?] = [3, 3, nil, 2, 0]
        let rooted = try #require(RootedTree(vertices: 0 ..< 5, parent: { parents[$0] }))
        #expect(rooted.lowestCommonAncestor(of: 4, 1) == 3)
        #expect(LowestCommonAncestors(rooted).lowestCommonAncestor(of: 4, 1) == 3)
        // U: [] P(0..6) (TA-513) and a-b, b-c, b-d, d-e (TA-517) through Tree(edges:).
        let path = try #require(Tree(edges: (0 ..< 6).map { UndirectedEdge($0, $0 + 1) }))
        #expect(path.centroidDecomposition() == RootedTree(parents: [1, 3, 1, nil, 5, 3, 5]))
        let names: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let named = try #require(Tree(edges: names.map { UndirectedEdge($0.0, $0.1) }))
        let decomposition = named.centroidDecomposition()
        #expect(decomposition.root == "b")
        #expect(decomposition.parent(of: "e") == "d")
        #expect(named.diameterPath().vertices == ["a", "b", "d", "e"])
    }

    @Test("TA-003 TA-204 TA-304 TA-410 TA-508 TA-609 with Collider vertices whose hashes all collide")
    func collidingVertices() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8, every vertex hashing alike.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let edges = pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) }
        let tree = try #require(Tree(vertices: (0 ... 8).map { Collider($0) }, edges: edges))
        let rooted = RootedTree(tree, root: Collider(0))
        #expect(rooted.lowestCommonAncestor(of: Collider(3), Collider(7)) == Collider(1))
        #expect(LowestCommonAncestors(rooted).lowestCommonAncestor(of: Collider(3), Collider(7)) == Collider(1))
        let tour = rooted.eulerTour
        #expect(tour.vertices.map(\.value) == [0, 1, 3, 1, 4, 6, 4, 7, 4, 1, 0, 2, 5, 8, 5, 2, 0])
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.preorder.map(\.value) == [0, 1, 4, 6, 7, 3, 2, 5, 8])
        #expect(tree.center() == [Collider(0)])
        #expect(tree.centroid() == [Collider(1)])
        #expect(tree.diameterPath().vertices.map(\.value) == [6, 4, 1, 0, 2, 5, 8])
    }
}
