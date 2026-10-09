// §C: construction. From a graph, a tree has the graph's `vertices` order and its edges at their
// positions; from `vertices:edges:`, the listed vertices with duplicates dropped, then endpoints by
// first appearance, edges in the order given (`UndirectedAdjacencyList(vertices:edges:)`'s rule);
// incidence rows are in position order. A root that is not a vertex is a precondition (TS-109, in
// TreePreconditionTests.swift); a graph that is not a tree is nil (TS-110). Conversions keep
// vertices and positions (TS-112). Sources are written on the `ReferencePseudograph` as the catalog
// writes them, and again through the `vertices:edges:` initializers, single-pass sequences
// included. Expected values come from the catalog's reference (`ref.py`). Case IDs (TS-nnn) refer
// to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Tree construction: vertex order, positions, duplicates")
struct TreeConstructionTests {
    @Test("TS-100 Tree(g).vertices is [2, 0, 1]: listed vertices first, in the order given")
    func listedVerticesFirst() throws {
        // U: [2,0,1] 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: [2, 0, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [2, 0, 1])
        let direct = try #require(Tree(vertices: [2, 0, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(direct.vertices) == [2, 0, 1])
    }

    @Test("TS-101 Tree(vertices: [2, 2, 0], …).vertices is [2, 0, 1]: a duplicate listed vertex is dropped")
    func duplicateListedVertexDropped() throws {
        // U: [2,2,0] 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: [2, 2, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [2, 0, 1])
        let direct = try #require(Tree(vertices: [2, 2, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(direct.vertices) == [2, 0, 1])
        #expect(direct.vertexCount == 3)
        let forest = try #require(Forest(vertices: [2, 2, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(forest.vertices) == [2, 0, 1])
    }

    @Test("TS-102 Tree(vertices: [0], …).vertices is [0, 1, 2]: missing endpoints added by first appearance")
    func missingEndpointsAdded() throws {
        // U: [0] 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: [0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [0, 1, 2])
        let direct = try #require(Tree(vertices: [0], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(direct.vertices) == [0, 1, 2])
    }

    @Test("TS-103 Tree(edges: 2-1, 1-0).vertices is [2, 1, 0]")
    func verticesByFirstAppearance() throws {
        // U: 2-1, 1-0
        let pairs: [(Int, Int)] = [(2, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [2, 1, 0])
        let direct = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(direct.vertices) == [2, 1, 0])
    }

    @Test("TS-104 Tree(edges: 2-1, 1-0).edges is [2-1, 1-0]")
    func edgesInOrderGiven() throws {
        // U: 2-1, 1-0
        let pairs: [(Int, Int)] = [(2, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let expected: [(Int, Int)] = [(2, 1), (1, 0)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
        let direct = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(direct.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-105 Tree(g).incidentEdges(of: a) is [0, 1, 2]: rows in position order")
    func rowsInPositionOrder() throws {
        // U: b-a, c-a, a-d
        let pairs: [(String, String)] = [("b", "a"), ("c", "a"), ("a", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.incidentEdges(of: "a")) == [0, 1, 2])
    }

    @Test("TS-106 Tree(g).neighbors(of: a) is [b, c, d]")
    func neighborsInRowOrder() throws {
        // U: b-a, c-a, a-d
        let pairs: [(String, String)] = [("b", "a"), ("c", "a"), ("a", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.neighbors(of: "a")) == ["b", "c", "d"])
    }

    @Test("TS-107 Tree(g).vertices is [x]: one String vertex, no edges")
    func singleStringVertex() throws {
        // U: [x]
        let graph = ReferencePseudograph<String>(vertices: ["x"], edges: [])
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == ["x"])
        #expect(tree.edges.isEmpty)
        let direct = try #require(Tree<String>(vertices: ["x"], edges: []))
        #expect(Array(direct.vertices) == ["x"])
    }

    @Test("TS-108 RootedTree(g, root: x).height is 0: one vertex")
    func singleVertexHeight() throws {
        // U: [x]
        let graph = ReferencePseudograph<String>(vertices: ["x"], edges: [])
        let rooted = try #require(RootedTree(graph, root: "x"))
        #expect(rooted.height == 0)
        #expect(rooted.root == "x")
        #expect(rooted.depth(of: "x") == 0)
    }

    @Test("TS-110 RootedTree(g, root: 0) is nil: a triangle is not a tree")
    func rootedTreeOfACycleIsNil() {
        // U: 0-1, 1-2, 2-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(RootedTree(graph, root: 0) == nil)
    }

    @Test("TS-112 Tree > RootedTree(root: 2) > Tree keeps positions: [0-1, 1-2]")
    func forgettingTheRootKeepsPositions() throws {
        // U: 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let rooted = RootedTree(tree, root: 2)
        let back = Tree(rooted)
        let expected: [(Int, Int)] = [(0, 1), (1, 2)]
        #expect(Array(back.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(rooted.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(back.vertices) == [0, 1, 2])
        #expect(back == tree)
    }

    @Test("Initializers take single-pass sequences: vertices and edges are each read once")
    func singlePassSequences() throws {
        // The TS-100 source and TS-063's arcs, through MinimalSequence.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let tree = try #require(Tree(vertices: MinimalSequence(elements: [2, 0, 1]), edges: MinimalSequence(elements: pairs.map { UndirectedEdge($0.0, $0.1) })))
        #expect(Array(tree.vertices) == [2, 0, 1])
        #expect(tree.edgeCount == 2)
        let fromEdges = try #require(Tree(edges: MinimalSequence(elements: pairs.map { UndirectedEdge($0.0, $0.1) }, underestimatedCount: .precise)))
        #expect(Array(fromEdges.vertices) == [0, 1, 2])
        let forest = try #require(Forest(vertices: MinimalSequence(elements: [5]), edges: MinimalSequence(elements: pairs.map { UndirectedEdge($0.0, $0.1) }, underestimatedCount: .half)))
        #expect(Array(forest.vertices) == [5, 0, 1, 2])
        let forestFromEdges = try #require(Forest(edges: MinimalSequence(elements: pairs.map { UndirectedEdge($0.0, $0.1) })))
        #expect(forestFromEdges.edgeCount == 2)
        let arcs: [(Int, Int)] = [(1, 2), (0, 1)]
        let arborescence = try #require(Arborescence(edges: MinimalSequence(elements: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })))
        #expect(Array(arborescence.vertices) == [1, 2, 0])
        #expect(arborescence.root == 0)
        let listed = try #require(Arborescence(vertices: MinimalSequence(elements: [0]), edges: MinimalSequence(elements: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })))
        #expect(Array(listed.vertices) == [0, 1, 2])
        let parents: [String: String] = ["b": "a"]
        let fromParents = try #require(Arborescence(vertices: MinimalSequence(elements: ["a", "b"]), parent: { parents[$0] }))
        #expect(Array(fromParents.vertices) == ["a", "b"])
        let rootedFromParents = try #require(RootedTree(vertices: MinimalSequence(elements: ["a", "b"]), parent: { parents[$0] }))
        #expect(rootedFromParents.root == "a")
    }

    @Test("From vertices:edges:, the same edge written twice is a parallel pair, and a loop is a cycle")
    func directInitializersRejectRepeatsAndLoops() {
        // TS-010, TS-011 and TS-007 through the edge initializers.
        #expect(Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]) == nil)
        #expect(Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]) == nil)
        #expect(Tree(edges: [UndirectedEdge(0, 0)]) == nil)
        #expect(Tree(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)]) == nil)
        #expect(Forest(edges: [UndirectedEdge(0, 0)]) == nil)
        #expect(Forest(vertices: [9], edges: [UndirectedEdge(2, 3), UndirectedEdge(2, 3)]) == nil)
        #expect(Arborescence(edges: [DirectedEdge(from: 0, to: 0)]) == nil)
        #expect(Arborescence(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]) == nil)
    }

    @Test("Collider vertices: every hash equal, values still told apart")
    func colliderVertices() throws {
        // TS-200's tree E1 on Collider vertices whose hashes all collide.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) }))
        #expect(Array(tree.vertices).map(\.value) == [0, 1, 2, 3, 4, 5, 6])
        let rooted = RootedTree(tree, root: Collider(0))
        #expect(Array(rooted.preorder).map(\.value) == [0, 1, 3, 4, 6, 2, 5])
        #expect(rooted.postorder.map(\.value) == [3, 6, 4, 1, 5, 2, 0])
        let path = tree.path(from: Collider(6), to: Collider(5))
        #expect(path.vertices.map(\.value) == [6, 4, 1, 0, 2, 5])
        #expect(path.edges == [5, 3, 0, 1, 4])
        #expect(Tree(edges: [UndirectedEdge(Collider(0), Collider(1)), UndirectedEdge(Collider(1), Collider(0))]) == nil)
    }

    @Test("HashableBox vertices: the instance stored is the first one given")
    func firstInstanceKept() throws {
        // TS-101's rule: a repeated vertex is dropped, so the first instance is the one kept.
        let first = HashableBox(0, label: "first")
        let second = HashableBox(0, label: "second")
        let one = HashableBox(1)
        let tree = try #require(Tree(vertices: [first, second], edges: [UndirectedEdge(second, one)]))
        #expect(tree.vertexCount == 2)
        let stored = try #require(tree.vertices.first)
        #expect(stored === first)
    }
}
