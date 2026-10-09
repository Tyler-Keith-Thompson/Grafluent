// §G: `Forest`. `trees` lists the trees by least vertex (in `vertices` order); each tree has the
// forest's vertices in the forest's order and its edges in the forest's position order, renumbered
// from 0. `component(of:)` is the offset of the vertex's tree in `trees`. `Forest` is a `Graph`
// with the source's positions; `Forest(tree)` is a one-tree forest. Sources are written on the
// `ReferencePseudograph` as the catalog writes them. Expected values come from the catalog's
// reference (`ref.py`, cross-checked against NetworkX's `connected_components` in node order).
// Case IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Forest")
struct ForestTests {
    @Test("TS-400 Forest(g).trees is [0, 1]/[0-1]; [2, 3, 4]/[2-3, 3-4]: edges renumbered from 0")
    func treesByLeastVertex() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let trees = Array(forest.trees)
        #expect(trees.count == 2)
        let first: [(Int, Int)] = [(0, 1)]
        let second: [(Int, Int)] = [(2, 3), (3, 4)]
        #expect(Array(trees[0].vertices) == [0, 1])
        #expect(Array(trees[0].edges) == first.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(trees[1].vertices) == [2, 3, 4])
        #expect(Array(trees[1].edges) == second.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(trees[1].edges.indices) == [0, 1])
        #expect(Array(trees[1].incidentEdges(of: 3)) == [0, 1])
    }

    @Test("TS-401 Forest(g).trees is [5]/[]; [4, 3, 2]/[2-3, 3-4]; [0, 1]/[0-1]: the listed order decides")
    func listedOrderDecides() throws {
        // U: [5,4,3] 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: [5, 4, 3], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let trees = Array(forest.trees)
        #expect(trees.count == 3)
        let second: [(Int, Int)] = [(2, 3), (3, 4)]
        let third: [(Int, Int)] = [(0, 1)]
        #expect(Array(trees[0].vertices) == [5])
        #expect(trees[0].edges.isEmpty)
        #expect(Array(trees[1].vertices) == [4, 3, 2])
        #expect(Array(trees[1].edges) == second.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(trees[2].vertices) == [0, 1])
        #expect(Array(trees[2].edges) == third.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-402 Forest(g).trees is [3, 4, 2]/[3-4, 2-3]; [0, 1]/[0-1]")
    func edgesInForestOrder() throws {
        // U: 3-4, 0-1, 2-3
        let pairs: [(Int, Int)] = [(3, 4), (0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let trees = Array(forest.trees)
        #expect(trees.count == 2)
        let first: [(Int, Int)] = [(3, 4), (2, 3)]
        let second: [(Int, Int)] = [(0, 1)]
        #expect(Array(trees[0].vertices) == [3, 4, 2])
        #expect(Array(trees[0].edges) == first.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(trees[1].vertices) == [0, 1])
        #expect(Array(trees[1].edges) == second.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-403 Forest(g).component(of: 2) is 0")
    func componentOffset() throws {
        // U: 3-4, 0-1, 2-3
        let pairs: [(Int, Int)] = [(3, 4), (0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.component(of: 2) == 0)
        #expect(forest.component(of: 0) == 1)
    }

    @Test("TS-404 Forest(g).trees of four isolated vertices is [0]; [1]; [2]; [3]")
    func everyVertexItsOwnTree() throws {
        // U: [0,1,2,3]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3], edges: [])
        let forest = try #require(Forest(graph))
        let trees = Array(forest.trees)
        #expect(trees.map { Array($0.vertices) } == [[0], [1], [2], [3]])
        #expect(trees.allSatisfy { $0.edges.isEmpty })
    }

    @Test("TS-405 Forest(g).trees of the null graph is empty")
    func noTrees() throws {
        // U: []
        let graph = ReferencePseudograph<Int>(edges: [])
        let forest = try #require(Forest(graph))
        #expect(forest.trees.isEmpty)
        #expect(Forest<Int>() == forest)
    }

    @Test("TS-406 Forest(tree).trees is [0, 1, 2]/[0-1, 1-2]")
    func forestOfATree() throws {
        // U: 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let forest = Forest(tree)
        let trees = Array(forest.trees)
        #expect(trees.count == 1)
        let expected: [(Int, Int)] = [(0, 1), (1, 2)]
        #expect(Array(trees[0].vertices) == [0, 1, 2])
        #expect(Array(trees[0].edges) == expected.map { UndirectedEdge($0.0, $0.1) })
        #expect(trees[0] == tree)
    }

    @Test("TS-407 Forest(g).edges is [0-1, 1-2]: a Graph with the source's positions")
    func forestEdges() throws {
        // U: 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let expected: [(Int, Int)] = [(0, 1), (1, 2)]
        #expect(Array(forest.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-408 Forest(g).trees is [a, b]/[a-b]; [c, d, e]/[c-d, e-c]: String vertices")
    func stringForest() throws {
        // U: a-b, c-d, e-c
        let pairs: [(String, String)] = [("a", "b"), ("c", "d"), ("e", "c")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let trees = Array(forest.trees)
        #expect(trees.count == 2)
        let first: [(String, String)] = [("a", "b")]
        let second: [(String, String)] = [("c", "d"), ("e", "c")]
        #expect(Array(trees[0].vertices) == ["a", "b"])
        #expect(Array(trees[0].edges) == first.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(trees[1].vertices) == ["c", "d", "e"])
        #expect(Array(trees[1].edges) == second.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-409 Forest(g).trees.count is 2")
    func treeCount() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.trees.count == 2)
    }

    @Test("TS-410 Forest(g).component(of: 9) is 0: a listed isolated vertex comes first")
    func isolatedComponent() throws {
        // U: [9] 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: [9], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.component(of: 9) == 0)
    }

    @Test("TS-411 Forest(g) is nil: a triangle in the second tree")
    func cycleInSecondTree() {
        // U: 0-1, 2-3, 3-4, 4-2
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Forest(graph) == nil)
    }

    @Test("TS-412 Forest(g) is nil: parallel edges in a second tree")
    func parallelInSecondTree() {
        // U: 0-1, 2-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Forest(graph) == nil)
    }

    @Test("trees, component(of:) and the forest agree: every vertex once, its tree at its component")
    func treesPartitionTheForest() throws {
        // TS-401's forest: each vertex in exactly the tree at component(of:), edge counts add up.
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let forest = try #require(Forest(vertices: [5, 4, 3], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let trees = forest.trees
        var seen: [Int] = []
        for (offset, tree) in trees.enumerated() {
            for v in tree.vertices {
                seen.append(v)
                #expect(forest.component(of: v) == offset, "\(v)")
            }
            #expect(tree.edgeCount == tree.vertexCount - 1)
        }
        #expect(seen.sorted() == Array(forest.vertices).sorted())
        let edgeTotal = trees.reduce(0) { $0 + $1.edgeCount }
        #expect(edgeTotal == forest.edgeCount)
        #expect(forest.vertexCount - forest.edgeCount == trees.count)
        // Reading a tree twice gives equal values.
        let middle = trees.index(after: trees.startIndex)
        #expect(trees[middle] == trees[middle])
    }
}
