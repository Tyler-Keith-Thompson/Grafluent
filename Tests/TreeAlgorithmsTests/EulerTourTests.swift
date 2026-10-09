// §C: `RootedTree.eulerTour`, the closed walk from the root that goes down each child edge, in
// `children(of:)` order (the edge-position order of the child edges), and back up it after that
// subtree: 2n − 1 vertices and 2n − 2 edge positions, each edge twice. K₁ gives the trivial walk.
// It follows the rooting, so it differs between F1 and F1b (TA-204, TA-205) and after rerooting
// (TA-206). On an `Arborescence` the walk would go back up arcs, so it is reached through
// `RootedTree(arborescence)` (TA-210). F1 is `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8`,
// F1b the same edges in the position order `4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5`. Expected
// walks are the catalog's, computed by `ref.py` three ways (a climb over preorder, recursion over
// rows, NetworkX's `dfs_labeled_edges`). Case IDs (TA-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees
import Walks

@Suite("Euler tour")
struct EulerTourTests {
    @Test("TA-201 RootedTree(K₁, root: 0).eulerTour is the trivial walk [0]")
    func singleVertex() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [0])
        #expect(tour.edges == [])
        #expect(tour.isTrivial)
        #expect(tour.isClosed)
    }

    @Test("TA-202 RootedTree(K₂, root: 0).eulerTour is [0, 1, 0] / [0, 0]")
    func edgeFromZero() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [0, 1, 0])
        #expect(tour.edges == [0, 0])
    }

    @Test("TA-203 RootedTree(K₂, root: 1).eulerTour is [1, 0, 1] / [0, 0]")
    func edgeFromOne() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let rooted = try #require(RootedTree(graph, root: 1))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [1, 0, 1])
        #expect(tour.edges == [0, 0])
    }

    @Test("TA-204 RootedTree(F1, root: 0).eulerTour")
    func f1() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [0, 1, 3, 1, 4, 6, 4, 7, 4, 1, 0, 2, 5, 8, 5, 2, 0])
        #expect(tour.edges == [0, 2, 2, 3, 5, 5, 6, 6, 3, 0, 1, 4, 7, 7, 4, 1])
        // A walk in the tree: each step crosses the edge at that position.
        #expect(Walk(vertices: tour.vertices, edges: tour.edges, in: rooted) != nil)
    }

    @Test("TA-205 RootedTree(F1b, root: 0).eulerTour: children by edge position")
    func f1b() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [0, 2, 5, 8, 5, 2, 0, 1, 4, 7, 4, 6, 4, 1, 3, 1, 0])
        #expect(tour.edges == [1, 7, 3, 3, 7, 1, 4, 2, 0, 0, 5, 5, 2, 6, 6, 4])
    }

    @Test("TA-206 RootedTree(F1, root: 4).eulerTour: rerooted, the old parent where its edge sits in the row")
    func f1Rerooted() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [4, 1, 0, 2, 5, 8, 5, 2, 0, 1, 3, 1, 4, 6, 4, 7, 4])
        #expect(tour.edges == [3, 0, 1, 4, 7, 7, 4, 1, 0, 2, 2, 3, 5, 5, 6, 6])
    }

    @Test("TA-207 RootedTree(P(0..3), root: 2).eulerTour is [2, 1, 0, 1, 2, 3, 2] / [1, 0, 0, 1, 2, 2]")
    func pathFromInside() throws {
        // U: [] P(0..3)
        let pairs = (0 ..< 3).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 2))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [2, 1, 0, 1, 2, 3, 2])
        #expect(tour.edges == [1, 0, 0, 1, 2, 2])
    }

    @Test("TA-208 RootedTree(S(0; 1..3), root: 0).eulerTour: a star from its center")
    func starFromCenter() throws {
        // U: [] S(0;1..3)
        let pairs = (1 ... 3).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [0, 1, 0, 2, 0, 3, 0])
        #expect(tour.edges == [0, 0, 1, 1, 2, 2])
    }

    @Test("TA-209 RootedTree(S(0; 1..3), root: 2).eulerTour: a star from a leaf")
    func starFromLeaf() throws {
        // U: [] S(0;1..3)
        let pairs = (1 ... 3).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 2))
        let tour = rooted.eulerTour
        #expect(tour.vertices == [2, 0, 1, 0, 3, 0, 2])
        #expect(tour.edges == [1, 0, 0, 2, 2, 1])
    }

    @Test("TA-210 RootedTree(Arborescence(NX)).eulerTour: through the O(1) conversion")
    func arborescence() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let tour = RootedTree(arborescence).eulerTour
        #expect(tour.vertices == [0, 1, 3, 1, 4, 1, 0, 2, 5, 2, 6, 2, 0])
        #expect(tour.edges == [0, 2, 2, 3, 3, 0, 1, 4, 4, 5, 5, 1])
    }

    @Test("TA-211 RootedTree(a-b, b-c, b-d, d-e; root: d).eulerTour: String vertices")
    func stringVertices() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "d"))
        let tour = rooted.eulerTour
        #expect(tour.vertices == ["d", "b", "a", "b", "c", "b", "d", "e", "d"])
        #expect(tour.edges == [2, 0, 0, 1, 1, 2, 3, 3])
    }

    @Test("TA-212 RootedTree(F1, root: 0).eulerTour.length is 16: 2(n − 1), each edge twice")
    func f1Length() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let tour = rooted.eulerTour
        #expect(tour.length == 16)
        #expect(tour.vertices.count == 17)
        #expect(tour.isClosed)
        #expect(tour.source == 0)
        for e in 0 ..< 8 { #expect(tour.edges.count { $0 == e } == 2, "edge \(e)") }
    }
}
