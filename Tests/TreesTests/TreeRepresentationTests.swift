// The initializers and predicates on every representation the module can read: the package's
// `UndirectedAdjacencyList`, `AdjacencyList` and `CompressedSparseRow`, the `.directed` and
// `.undirected` views, a file-private conformer whose rows are reversed (as an adjacency list's are
// after removals), one with no vertex or edge indices, and an `UndirectedAdjacencyList` after real
// removals. Built from a graph, a tree has the graph's `vertices` order and its edges at their
// positions, but its rows are rebuilt in position order whatever the graph's row order (api.md,
// "Vertex order and edge positions"), so `children(of:)` and `preorder` do not depend on how the
// source stores its rows. Catalog rows are repeated exactly; on adjacency lists after removals the
// expected rows and orders are computed inside the test from the graph's own `edges`. Case IDs
// (TS-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

/// An undirected graph whose incidence rows are in reverse position order. Vertex and edge
/// indices are positions.
private struct ReversedRowsGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(edges: [UndirectedEdge<Vertex>]) {
        let inOrder = ReferencePseudograph(edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { Array(inOrder.incidentEdges(of: $0).reversed()) }
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

/// Counts the hashes of every `HashCountingVertex` that shares it.
private final class HashCounter: @unchecked Sendable {
    var hashes = 0
}

/// A vertex that counts how often it is hashed.
private struct HashCountingVertex: Hashable {
    let value: Int
    let counter: HashCounter
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.value == rhs.value }
    func hash(into hasher: inout Hasher) {
        counter.hashes += 1
        hasher.combine(value)
    }
}

@Suite("Trees on every representation")
struct TreeRepresentationTests {
    @Test("TS-030 TS-100 TS-105 on UndirectedAdjacencyList: vertex order and positions kept, rows in position order")
    func undirectedAdjacencyList() throws {
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.edges) == pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isTree)
        let listed = UndirectedAdjacencyList(vertices: [2, 0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(Array(try #require(Tree(listed)).vertices) == [2, 0, 1])
        let star = UndirectedAdjacencyList(edges: [UndirectedEdge("b", "a"), UndirectedEdge("c", "a"), UndirectedEdge("a", "d")])
        let starTree = try #require(Tree(star))
        #expect(Array(starTree.incidentEdges(of: "a")) == [0, 1, 2])
        #expect(Array(starTree.neighbors(of: "a")) == ["b", "c", "d"])
    }

    @Test("TS-200 TS-218 TS-300 on UndirectedAdjacencyList: rooted queries and paths")
    func undirectedAdjacencyListRooted() throws {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0, 1, 3, 4, 6, 2, 5])
        let rerooted = try #require(RootedTree(graph, root: 4))
        #expect(Array(rerooted.preorder) == [4, 1, 0, 2, 5, 3, 6])
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 6, to: 5)
        #expect(path.vertices == [6, 4, 1, 0, 2, 5])
        #expect(path.edges == [5, 3, 0, 1, 4])
        #expect(Forest(graph) != nil)
    }

    @Test("TS-015 TS-020 TS-022 TS-029 on UndirectedAdjacencyList: isTree, Tree, Forest and isAcyclic agree")
    func undirectedAdjacencyListRejections() throws {
        let triangle = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(!triangle.isTree)
        #expect(Tree(triangle) == nil)
        #expect(Forest(triangle) == nil)
        #expect(!triangle.isAcyclic)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
        let mixed = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!mixed.isTree)
        let plusIsolated = UndirectedAdjacencyList(vertices: [5], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(!plusIsolated.isTree)
        #expect(try #require(Forest(plusIsolated)).trees.count == 2)
        #expect(plusIsolated.isAcyclic)
        let square = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(Forest(square) == nil)
        #expect(!UndirectedAdjacencyList<Int>().isTree)
        #expect(try #require(Forest(UndirectedAdjacencyList<Int>())).trees.isEmpty)
    }

    @Test("An UndirectedAdjacencyList after removals: Tree(g) keeps its positions and rebuilds rows in position order")
    func adjacencyListAfterRemovals() throws {
        // E1 with extra edges, then the extras removed: removal moves the last edge into the hole
        // and swaps row entries, so the graph's rows are no longer in position order.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (5, 6), (1, 3), (0, 6), (1, 4), (2, 5), (3, 6), (4, 6)]
        var graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        graph.remove(edge: UndirectedEdge(5, 6))
        graph.remove(edge: UndirectedEdge(0, 6))
        graph.remove(edge: UndirectedEdge(3, 6))
        let edges = Array(graph.edges)
        #expect(edges.count == 6)
        let vertices = Array(graph.vertices)
        func positionRow(_ v: Int) -> [Int] { edges.indices.filter { edges[$0].u == v || edges[$0].v == v } }
        let outOfOrder = vertices.filter { Array(graph.incidentEdges(of: $0)) != positionRow($0) }
        #expect(!outOfOrder.isEmpty, "the removals should leave some row out of position order")

        #expect(graph.isTree)
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == vertices)
        #expect(Array(tree.edges) == edges)
        for v in vertices {
            #expect(Array(tree.incidentEdges(of: v)) == positionRow(v), "row of \(v)")
        }
        // Preorder from the root by an explicit stack over the position-ordered rows.
        let rooted = try #require(RootedTree(graph, root: 0))
        var expectedPreorder: [Int] = []
        var stack: [(vertex: Int, parentEdge: Int?)] = [(0, nil)]
        while let (v, parentEdge) = stack.popLast() {
            expectedPreorder.append(v)
            let childEdges = positionRow(v).filter { $0 != parentEdge }
            for e in childEdges.reversed() { stack.append((edges[e].oppositeVertex(to: v), e)) }
            let children = childEdges.map { edges[$0].oppositeVertex(to: v) }
            #expect(Array(rooted.children(of: v)) == children, "children of \(v)")
            #expect(rooted.parentEdge(of: v) == parentEdge, "parent edge of \(v)")
        }
        #expect(Array(rooted.preorder) == expectedPreorder)
        #expect(Set(expectedPreorder) == Set(0 ... 6))
    }

    @Test("TS-200 TS-219 TS-225 on a graph whose rows are reversed: the tree's rows are in position order regardless")
    func reversedRows() throws {
        let e1: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReversedRowsGraph(edges: e1.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.incidentEdges(of: 1)) == [3, 2, 0])
        #expect(graph.isTree)
        let tree = try #require(Tree(graph))
        #expect(Array(tree.incidentEdges(of: 1)) == [0, 2, 3])
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0, 1, 3, 4, 6, 2, 5])
        #expect(rooted.postorder == [3, 6, 4, 1, 5, 2, 0])
        let rerooted = try #require(RootedTree(graph, root: 4))
        #expect(Array(rerooted.children(of: 4)) == [1, 6])
        let e2: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let other = try #require(RootedTree(ReversedRowsGraph(edges: e2.map { UndirectedEdge($0.0, $0.1) }), root: 0))
        #expect(Array(other.children(of: 2)) == [4, 1])
        #expect(Array(other.preorder) == [0, 2, 4, 1, 3])
        // Rejections do not depend on row order either (TS-020, TS-025).
        let mixed: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
        #expect(!ReversedRowsGraph(edges: mixed.map { UndirectedEdge($0.0, $0.1) }).isTree)
        #expect(Forest(ReversedRowsGraph(edges: mixed.map { UndirectedEdge($0.0, $0.1) })) == nil)
        #expect(!ReversedRowsGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]).isTree)
    }

    @Test("TS-005 TS-020 TS-025 TS-200 TS-400 TS-500 on a graph without vertex or edge indices")
    func unindexedGraph() throws {
        let e1: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = UnindexedGraph(vertices: Array(0 ... 6), edges: e1.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.isTree)
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0, 1, 3, 4, 6, 2, 5])
        let tree = try #require(Tree(graph))
        #expect(tree.vertexIndexBound == 7)
        #expect(tree.edgeIndexBound == 6)
        #expect(UnindexedGraph<Int>(vertices: [0], edges: []).isTree)
        let mixed: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
        #expect(!UnindexedGraph(vertices: Array(0 ... 4), edges: mixed.map { UndirectedEdge($0.0, $0.1) }).isTree)
        #expect(!UnindexedGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)]).isTree)
        let forestPairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let forest = try #require(Forest(UnindexedGraph(vertices: Array(0 ... 4), edges: forestPairs.map { UndirectedEdge($0.0, $0.1) })))
        #expect(forest.trees.map { Array($0.vertices) } == [[0, 1], [2, 3, 4]])
        let pruferPairs: [(Int, Int)] = [(0, 3), (1, 3), (2, 3), (3, 4), (4, 5)]
        let coded = try #require(Tree(UnindexedGraph(vertices: Array(0 ... 5), edges: pruferPairs.map { UndirectedEdge($0.0, $0.1) })))
        #expect(coded.pruferSequence == [3, 3, 3, 4])
    }

    @Test("TS-052 TS-062 TS-063 TS-068 on AdjacencyList")
    func adjacencyList() throws {
        let star = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        #expect(try #require(Arborescence(star)).root == 0)
        let pairs: [(Int, Int)] = [(3, 1), (1, 0), (1, 2)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.isArborescence)
        #expect(try #require(Arborescence(graph)).root == 3)
        let swapped = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)])
        let arborescence = try #require(Arborescence(swapped))
        #expect(Array(arborescence.edges) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)])
        let unreached = AdjacencyList(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        #expect(!unreached.isArborescence)
        #expect(Arborescence(unreached) == nil)
        #expect(!AdjacencyList<Int>().isArborescence)
    }

    @Test("TS-239 TS-307 on CompressedSparseRow; TS-242 with its arcs in CSR's row-major positions")
    func compressedSparseRow() throws {
        // E1's arcs are already row-major, so CSR keeps their positions.
        let e1: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = CompressedSparseRow(vertexCount: 7, edges: e1.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.isArborescence)
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.preorder) == [0, 1, 3, 4, 6, 2, 5])
        let path = try #require(arborescence.path(from: 0, to: 6))
        #expect(path.vertices == [0, 1, 4, 6])
        #expect(path.edges == [0, 3, 5])
        // D: [0,1,2,3] 0>1, 2>0, 2>3 is TS-242's 2>3, 2>0, 0>1 in row-major order.
        let rowMajor = CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)])
        let fromCSR = try #require(Arborescence(rowMajor))
        #expect(Array(fromCSR.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3)])
        #expect(Array(fromCSR.children(of: 2)) == [0, 3])
        #expect(fromCSR.depth(of: 1) == 2)
        #expect(!CompressedSparseRow(vertexCount: 2).isArborescence)
        #expect(CompressedSparseRow(vertexCount: 1).isArborescence)
    }

    @Test("Views: digraph.undirected.isTree is the polytree test; graph.directed is an arborescence only without edges")
    func views() throws {
        // TS-054's polytree, read as undirected, is the tree 0-1, 2-1; TS-059's opposite arcs a parallel pair.
        let polytree = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        #expect(!polytree.isArborescence)
        #expect(polytree.undirected.isTree)
        let undirectedTree = try #require(Tree(polytree.undirected))
        #expect(Array(undirectedTree.edges) == [UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
        let opposite = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(!opposite.undirected.isTree)
        #expect(Forest(opposite.undirected) == nil)
        // An arborescence read as undirected is its tree (TS-239's E1).
        let e1: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let arborescence = try #require(Arborescence(edges: e1.map { DirectedEdge(from: $0.0, to: $0.1) }))
        #expect(arborescence.undirected.isTree)
        #expect(Tree(arborescence.undirected) == Tree(RootedTree(arborescence)))
        // Every edge of g.directed is a digon, so with an edge it is never an arborescence; K₁ is.
        let k2 = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        #expect(!k2.directed.isArborescence)
        #expect(Arborescence(k2.directed) == nil)
        let k1 = UndirectedAdjacencyList(vertices: [0])
        #expect(k1.directed.isArborescence)
        let tree = try #require(Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))
        #expect(!tree.directed.isArborescence)
        #expect(Arborescence(RootedTree(tree, root: 0)).undirected.isTree)
    }

    @Test("isTree on an UndirectedAdjacencyList reads the index rows: it hashes no vertex")
    func isTreeHashesNothing() {
        // TS-014's path and TS-020's triangle-and-edge, on counting vertices.
        let counter = HashCounter()
        let path = UndirectedAdjacencyList(edges: (0 ..< 4).map { UndirectedEdge(HashCountingVertex(value: $0, counter: counter), HashCountingVertex(value: $0 + 1, counter: counter)) })
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
        let mixed = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge(HashCountingVertex(value: $0.0, counter: counter), HashCountingVertex(value: $0.1, counter: counter)) })
        counter.hashes = 0
        #expect(path.isTree)
        #expect(!mixed.isTree)
        #expect(counter.hashes == 0)
    }
}
