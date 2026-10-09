// §A: undirected recognition. `isTree` (at least one vertex, connected, acyclic; a self-loop and a
// parallel pair are cycles), `Tree(g)` (nil exactly when `isTree` is false) and `Forest(g)` (nil
// exactly when Cycles' `isAcyclic` is false; the empty forest exists). Every graph is written as
// the catalog writes it, on the `ReferencePseudograph` (listed vertices first, then endpoints by
// first appearance; edges in written order, repeats and loops kept), so positions are exact.
// Expected values come from the catalog's reference (`ref.py`). Case IDs (TS-nnn) refer to the
// catalog; see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Tree recognition, undirected")
struct TreeRecognitionTests {
    @Test("TS-001 isTree is false: the null graph is not a tree")
    func nullGraphIsNotATree() {
        // igraph and JGraphT agree; NetworkX raises; LEMON's tree() says true.
        // U: []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(!graph.isTree)
    }

    @Test("TS-002 Tree(g) is nil on the null graph: there is no empty Tree")
    func noEmptyTree() {
        // U: []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(Tree(graph) == nil)
        #expect(Tree<Int>(edges: []) == nil)
        #expect(Tree<Int>(vertices: [], edges: []) == nil)
    }

    @Test("TS-003 Forest(g) of the null graph has 0 trees: the empty forest exists")
    func emptyForest() throws {
        // U: []
        let graph = ReferencePseudograph<Int>(edges: [])
        let forest = try #require(Forest(graph))
        #expect(forest.trees.count == 0)
        #expect(forest.vertexCount == 0)
        #expect(forest.edgeCount == 0)
        #expect(Forest<Int>().trees.isEmpty)
    }

    @Test("TS-004 isAcyclic is true on the null graph, as Forest(g) != nil")
    func nullGraphIsAcyclic() {
        // U: []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(graph.isAcyclic)
        #expect(Forest(graph) != nil)
    }

    @Test("TS-005 isTree is true: K₁")
    func singleVertexIsATree() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.isTree)
    }

    @Test("TS-006 Tree(g) of K₁ has 0 edges")
    func singleVertexTreeHasNoEdges() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        #expect(tree.edgeCount == 0)
        #expect(tree.vertexCount == 1)
        #expect(Array(tree.vertices) == [0])
    }

    @Test("TS-007 isTree is false: one vertex with a self-loop (m = n, not a tree)")
    func selfLoopIsNotATree() {
        // U: 0-0
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 0)])
        #expect(!graph.isTree)
        #expect(Tree(graph) == nil)
    }

    @Test("TS-008 Forest(g) is nil: a self-loop is a cycle")
    func selfLoopIsNotAForest() {
        // U: 0-0
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 0)])
        #expect(Forest(graph) == nil)
        #expect(!graph.isAcyclic)
    }

    @Test("TS-009 isTree is true: K₂")
    func singleEdgeIsATree() {
        // U: 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        #expect(graph.isTree)
    }

    @Test("TS-010 isTree is false: a parallel pair is a 2-cycle")
    func parallelPairIsNotATree() {
        // U: 0-1, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isTree)
        #expect(Tree(graph) == nil)
    }

    @Test("TS-011 Forest(g) is nil: the same edge written both ways is still two edges")
    func sameEdgeBothWaysIsAParallelPair() {
        // U: 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Forest(graph) == nil)
        #expect(Forest(edges: pairs.map { UndirectedEdge($0.0, $0.1) }) == nil)
        #expect(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }) == nil)
    }

    @Test("TS-012 isTree is false: two isolated vertices are acyclic but disconnected")
    func twoIsolatedVerticesAreNotATree() {
        // U: [0,1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(!graph.isTree)
        #expect(graph.isAcyclic)
    }

    @Test("TS-013 Forest(g) of two isolated vertices has 2 trees")
    func twoIsolatedVerticesAreTwoTrees() throws {
        // U: [0,1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let forest = try #require(Forest(graph))
        #expect(forest.trees.count == 2)
    }

    @Test("TS-014 isTree is true: the path P(0..4)")
    func pathIsATree() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isTree)
    }

    @Test("TS-015 isTree is false: the triangle C(0,1,2)")
    func triangleIsNotATree() {
        // U: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isTree)
    }

    @Test("TS-016 isAcyclic is false: the triangle C(0,1,2)")
    func triangleIsCyclic() {
        // U: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isAcyclic)
        #expect(Forest(graph) == nil)
    }

    @Test("TS-017 isTree is true: the star S(0;1..5)")
    func starIsATree() {
        // U: S(0;1..5)
        let graph = ReferencePseudograph(edges: (1 ... 5).map { UndirectedEdge(0, $0) })
        #expect(graph.isTree)
    }

    @Test("TS-018 isTree is false: two disjoint edges (m = n − 2)")
    func twoEdgesAreNotATree() {
        // U: 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isTree)
    }

    @Test("TS-019 Forest(g) of two disjoint edges has 2 trees")
    func twoEdgesAreTwoTrees() throws {
        // U: 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.trees.count == 2)
    }

    @Test("TS-020 isTree is false: m = n − 1 but a triangle and a separate edge")
    func edgeCountAloneIsNotEnough() {
        // U: 0-1, 1-2, 2-0, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == graph.vertexCount - 1)
        #expect(!graph.isTree)
        #expect(Tree(graph) == nil)
    }

    @Test("TS-021 Forest(g) is nil: a triangle and a separate edge")
    func triangleAndEdgeIsNotAForest() {
        // U: 0-1, 1-2, 2-0, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Forest(graph) == nil)
    }

    @Test("TS-022 isTree is false: a tree plus an isolated vertex")
    func treePlusIsolatedVertexIsNotATree() {
        // U: [5] 0-1, 1-2, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: [5], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isTree)
    }

    @Test("TS-023 Forest(g) of a tree plus an isolated vertex has 2 trees")
    func treePlusIsolatedVertexIsTwoTrees() throws {
        // U: [5] 0-1, 1-2, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: [5], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.trees.count == 2)
    }

    @Test("TS-024 isTree is false: a loop on a leaf (m = n)")
    func loopOnALeafIsNotATree() {
        // U: 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isTree)
        #expect(Tree(graph) == nil)
    }

    @Test("TS-025 isTree is false: m = n − 1, but the loop used up the edge that would have reached 2")
    func loopLeavesAVertexUnreached() {
        // U: [0,1,2] 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == graph.vertexCount - 1)
        #expect(!graph.isTree)
        #expect(Tree(graph) == nil)
        #expect(Forest(graph) == nil)
    }

    @Test("TS-026 isTree is true: igraph's binary tree kary(15,2)")
    func binaryTreeIsATree() {
        // U: kary(15,2): vertex i to 2i+1 and 2i+2 below 15, in that order
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 15 {
            for j in 1 ... 2 where 2 * i + j < 15 { pairs.append((i, 2 * i + j)) }
        }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 14)
        #expect(graph.isTree)
    }

    @Test("TS-027 isTree is true: String vertices")
    func stringVerticesTree() {
        // U: a-b, b-c, b-d
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isTree)
    }

    @Test("TS-028 Tree(g) is nil: a String triangle")
    func stringTriangleIsNotATree() {
        // U: a-b, b-c, c-a
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Tree(graph) == nil)
    }

    @Test("TS-029 Forest(g) is nil: the closing edge of a 4-cycle comes last")
    func closingEdgeLast() {
        // U: P(0..3), 3-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Forest(graph) == nil)
    }

    @Test("TS-030 Tree(g).edges keeps the graph's positions, in its order: [0-1, 2-3, 1-2]")
    func edgesKeepPositions() throws {
        // U: 0-1, 2-3, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let expected: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(tree.edges.indices) == [0, 1, 2])
        #expect(Array(tree.vertices) == [0, 1, 2, 3])
    }

    @Test("TS-001 – TS-030 isTree ⇔ Tree(g) != nil and isAcyclic ⇔ Forest(g) != nil on every §A source")
    func equivalencesOnEverySource() {
        // Each source of §A once, with its listed vertices.
        let sources: [(vertices: [Int], edges: [(Int, Int)])] = [
            ([], []),
            ([0], []),
            ([], [(0, 0)]),
            ([], [(0, 1)]),
            ([], [(0, 1), (0, 1)]),
            ([], [(0, 1), (1, 0)]),
            ([0, 1], []),
            ([], [(0, 1), (1, 2), (2, 3), (3, 4)]),
            ([], [(0, 1), (1, 2), (2, 0)]),
            ([], [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]),
            ([], [(0, 1), (2, 3)]),
            ([], [(0, 1), (1, 2), (2, 0), (3, 4)]),
            ([5], [(0, 1), (1, 2), (2, 3)]),
            ([], [(0, 1), (1, 1)]),
            ([0, 1, 2], [(0, 1), (1, 1)]),
            ([], [(0, 1), (1, 2), (2, 3), (3, 0)]),
            ([], [(0, 1), (2, 3), (1, 2)]),
        ]
        for source in sources {
            let graph = ReferencePseudograph(vertices: source.vertices, edges: source.edges.map { UndirectedEdge($0.0, $0.1) })
            let isTree = graph.isTree
            let built = Tree(graph) != nil
            let isAcyclic = graph.isAcyclic
            let forest = Forest(graph) != nil
            #expect(isTree == built, "\(source)")
            #expect(isAcyclic == forest, "\(source)")
            // A tree is a connected forest.
            if isTree { #expect(forest, "\(source)") }
        }
    }
}
