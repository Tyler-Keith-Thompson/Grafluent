// breadthFirstTree(from:depthLimit:) and depthFirstTree(from:depthLimit:): the search trees as
// arborescences, after NetworkX's bfs_tree and dfs_tree. Each tree is checked against the search
// it comes from: vertices in discovery order, edges in tree-edge order, parents and depths.
// Undirected NetworkX graphs are written as both directions. Case IDs (TR-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal
import Trees

@Suite("Search trees")
struct SearchTreeTests {
    @Test("TR-184 NetworkX's test_bfs_tree and test_dfs_tree graph")
    func networkX() {
        // NetworkX test_bfs.py / test_dfs.py: edges (0, 1), (1, 2), (1, 3), (2, 4), (3, 4), undirected.
        var edges: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (1, 2), (1, 3), (2, 4), (3, 4)] {
            edges += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let graph = CompressedSparseRow(vertexCount: 5, edges: edges)
        let bfs = graph.breadthFirstTree(from: 0)
        // bfs_tree(G, 0).edges(): [(0, 1), (1, 2), (1, 3), (2, 4)].
        #expect(Array(bfs.edges) == [(0, 1), (1, 2), (1, 3), (2, 4)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(bfs.vertices) == [0, 1, 2, 3, 4])
        #expect(bfs.root == 0)
        // dfs_tree(G, 0).edges(): [(0, 1), (1, 2), (2, 4), (4, 3)].
        let dfs = graph.depthFirstTree(from: 0)
        #expect(Array(dfs.edges) == [(0, 1), (1, 2), (2, 4), (4, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(dfs.vertices) == [0, 1, 2, 4, 3])
        #expect(dfs.root == 0)
        #expect(dfs.depth(of: 3) == 4)
    }

    @Test("TR-185 breadth-first: vertices in discovery order, edges in tree-edge order, depths are layers", arguments: DirectedFixture<Int>.nonempty)
    func breadthFirstAgainstSearch(fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for source in Array(graph.vertices.prefix(3)) + [graph.vertices.last!] {
            let tree = graph.breadthFirstTree(from: source)
            var discovered: [Int] = []
            var treeEdges: [DirectedEdge<Int>] = []
            for event in graph.breadthFirstSearch(from: source) {
                switch event {
                case .discover(let v): discovered.append(v)
                case .treeEdge(let e): treeEdges.append(e)
                default: break
                }
            }
            #expect(Array(tree.vertices) == discovered, "\(fixture.name) from \(source)")
            #expect(Array(tree.edges) == treeEdges, "\(fixture.name) from \(source)")
            #expect(tree.root == source)
            #expect(tree.parent(of: source) == nil)
            for e in treeEdges { #expect(tree.parent(of: e.target) == e.source) }
            let layers = graph.breadthFirstLayers(from: source)
            for (depth, layer) in layers.enumerated() {
                for v in layer { #expect(tree.depth(of: v) == depth, "\(fixture.name) from \(source): \(v)") }
            }
            // Edge k leads to the vertex at offset k + 1.
            for k in 0 ..< tree.edgeCount { #expect(tree.edges[k].target == tree.vertices[k + 1]) }
        }
    }

    @Test("TR-186 depth-first: vertices in preorder, edges in tree-edge order", arguments: DirectedFixture<Int>.nonempty)
    func depthFirstAgainstSearch(fixture: DirectedFixture<Int>) {
        guard fixture.vertexSet == Set(0 ..< fixture.vertexCount) else { return }
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for source in [0, fixture.vertexCount - 1] {
            let tree = graph.depthFirstTree(from: source)
            var discovered: [Int] = []
            var treeEdges: [DirectedEdge<Int>] = []
            for event in graph.depthFirstSearch(from: source) {
                switch event {
                case .discover(let v): discovered.append(v)
                case .treeEdge(let e): treeEdges.append(e)
                default: break
                }
            }
            #expect(Array(tree.vertices) == discovered, "\(fixture.name) from \(source)")
            #expect(Array(tree.edges) == treeEdges, "\(fixture.name) from \(source)")
            #expect(tree.root == source)
            for e in treeEdges { #expect(tree.parent(of: e.target) == e.source) }
            // The arborescence's own preorder visits children in vertex order, which is the
            // discovery order here, so it matches the search.
            #expect(Array(tree.preorder) == discovered)
            // Exactly the vertices reachable from the source.
            #expect(Set(tree.vertices) == graph.descendants(of: source).union([source]))
        }
    }

    @Test("TR-187 depth limits keep vertices at most that many edges from the source")
    func depthLimits() {
        // The path 0 → 1 → … → 9 with a chord 0 → 5.
        var edges = (0 ..< 9).map { DirectedEdge(from: $0, to: $0 + 1) }
        edges.append(DirectedEdge(from: 0, to: 5))
        let graph = AdjacencyList(vertices: 0 ..< 10, edges: edges)
        #expect(Array(graph.breadthFirstTree(from: 0, depthLimit: 0).vertices) == [0])
        #expect(Array(graph.breadthFirstTree(from: 0, depthLimit: 1).vertices) == [0, 1, 5])
        #expect(Array(graph.breadthFirstTree(from: 0, depthLimit: 2).vertices) == [0, 1, 5, 2, 6])
        #expect(graph.breadthFirstTree(from: 0, depthLimit: 2).depth(of: 6) == 2)
        #expect(Array(graph.depthFirstTree(from: 0, depthLimit: 0).vertices) == [0])
        // Depth-first goes 0 → 1 → 2 first, so 5 is reached through the chord at depth 1.
        #expect(Array(graph.depthFirstTree(from: 0, depthLimit: 2).vertices) == [0, 1, 2, 5, 6])
        #expect(graph.depthFirstTree(from: 0, depthLimit: 2).parent(of: 6) == 5)
        #expect(graph.depthFirstTree(from: 0).vertexCount == 10)
        // Without the limit depth-first takes the path: 5's parent is 4.
        #expect(graph.depthFirstTree(from: 0).parent(of: 5) == 4)
        #expect(graph.breadthFirstTree(from: 0).parent(of: 5) == 0)
    }

    @Test("TR-188 a source with no out-edges, a self-loop, and unreachable vertices")
    func smallCases() {
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 1)])
        for tree in [graph.breadthFirstTree(from: 0), graph.depthFirstTree(from: 0)] {
            #expect(tree.vertexCount == 1)
            #expect(tree.edgeCount == 0)
            #expect(tree.root == 0)
        }
        for tree in [graph.breadthFirstTree(from: 1), graph.depthFirstTree(from: 1)] {
            #expect(Array(tree.vertices) == [1, 2])
            #expect(Array(tree.edges) == [DirectedEdge(from: 1, to: 2)])
        }
        // From 3, every vertex but 0.
        #expect(Array(graph.breadthFirstTree(from: 3).vertices) == [3, 1, 2])
        #expect(Array(graph.depthFirstTree(from: 3).vertices) == [3, 1, 2])
    }

    @Test("TR-189 String vertices, and Int vertices that are not 0..<n in discovery order")
    func vertexTypes() {
        let dag = DirectedFixture<String>.petgraphDAG
        let graph = AdjacencyList(vertices: dag.vertices, edges: dag.edges)
        let source = "a"
        let tree = graph.breadthFirstTree(from: source)
        var discovered: [String] = []
        for case .discover(let v) in graph.breadthFirstSearch(from: source) { discovered.append(v) }
        #expect(Array(tree.vertices) == discovered)
        for v in discovered where v != source { #expect(graph.successors(of: tree.parent(of: v)!).contains(v)) }
        let dfs = graph.depthFirstTree(from: source)
        #expect(Set(dfs.vertices) == Set(discovered))
        // Int vertices discovered as 5, 3, 9: looked up through a table, not by value.
        let ints = AdjacencyList(vertices: [5, 3, 9], edges: [DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 9)])
        let chain = ints.breadthFirstTree(from: 5)
        #expect(Array(chain.vertices) == [5, 3, 9])
        #expect(chain.parent(of: 9) == 3)
        #expect(chain.depth(of: 9) == 2)
        #expect(ints.depthFirstTree(from: 3).parent(of: 9) == 3)
        // Int vertices 0..<n discovered out of order: 0 → 2 → 1.
        let swapped = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1)])
        let path = swapped.breadthFirstTree(from: 0)
        #expect(Array(path.vertices) == [0, 2, 1])
        #expect(path.parent(of: 1) == 2)
        #expect(path.depth(of: 1) == 2)
    }

    @Test("TR-190 the matrix and the adjacency list agree with CSR on the Petersen graph")
    func representations() {
        let fixture = DirectedFixture<Int>.petersen
        let csr = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for source in 0 ..< fixture.vertexCount {
            #expect(Array(matrix.breadthFirstTree(from: source).edges) == Array(csr.breadthFirstTree(from: source).edges))
            #expect(Array(matrix.depthFirstTree(from: source).edges) == Array(csr.depthFirstTree(from: source).edges))
        }
    }

    @Test("TR-191 a source that is not a vertex, or a negative depth limit, traps", .tags(.precondition))
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).breadthFirstTree(from: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).depthFirstTree(from: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).breadthFirstTree(from: 0, depthLimit: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).depthFirstTree(from: 0, depthLimit: -1)
        }
    }
}
