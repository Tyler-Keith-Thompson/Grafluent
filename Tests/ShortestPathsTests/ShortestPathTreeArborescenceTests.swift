// Arborescence(_: ShortestPathTree): a one-source shortest-path tree as a Trees arborescence.
// Each conversion is checked against the tree it comes from: the reached vertices in index
// order, the root, every parent, and every tree path. Case IDs (SP-nn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import StableGraphs
import Testing
import Trees

@Suite("Shortest-path trees as arborescences")
struct ShortestPathTreeArborescenceTests {
    @Test("SP-138 Dijkstra on a weighted digraph: root, parents, index order, unreached vertices left out")
    func dijkstra() {
        // 0 → 1 (4), 0 → 2 (1), 2 → 1 (2), 1 → 3 (1), 2 → 3 (5), 4 → 0 (1); vertex 4 unreached.
        let arcs = [(0, 1, 4), (0, 2, 1), (2, 1, 2), (1, 3, 1), (2, 3, 5), (4, 0, 1)]
        let graph = CompressedSparseRow(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = graph.edges.map { edge in arcs.first { $0.0 == edge.source && $0.1 == edge.target }!.2 }
        let tree = graph.dijkstraShortestPaths(from: 0) { weights[$0] }
        let arborescence = Arborescence(tree)
        #expect(arborescence.root == 0)
        #expect(Array(arborescence.vertices) == [0, 1, 2, 3])
        #expect(arborescence.parent(of: 1) == 2)
        #expect(arborescence.parent(of: 2) == 0)
        #expect(arborescence.parent(of: 3) == 1)
        #expect(arborescence.parent(of: 0) == nil)
        #expect(arborescence.depth(of: 3) == 3)
        #expect(Array(arborescence.edges) == [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3)])
        // The tree path is the shortest path.
        #expect(arborescence.path(from: 0, to: 3)!.vertices == tree.path(to: 3)!.vertices)
    }

    @Test("SP-139 the source need not come first; edge k leads to the k-th vertex other than the root")
    func sourceInTheMiddle() {
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: [DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 5, to: 4)])
        let tree = graph.shortestPaths(from: 3)
        let arborescence = Arborescence(tree)
        #expect(arborescence.root == 3)
        #expect(arborescence.rootIndex == 2)
        #expect(Array(arborescence.vertices) == [0, 1, 3, 4, 5])
        let others = arborescence.vertices.filter { $0 != 3 }
        for k in 0 ..< arborescence.edgeCount {
            #expect(arborescence.edges[k].target == others[k])
            #expect(arborescence.edges[k].source == tree.parent(of: others[k]))
            #expect(arborescence.parentEdge(of: others[k]) == k)
        }
        // Vertex 2 is not reached.
        #expect(arborescence.vertexCount == 5)
        #expect(!arborescence.vertices.contains(2))
    }

    @Test("SP-140 every search's tree converts, on seeded random digraphs", .tags(.randomized), arguments: 0 ..< 8)
    func everySearch(seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(140 + seed))
        let n = 25
        let arcs = (0 ..< 60).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator)) }
        let graph = AdjacencyList(vertices: 0 ..< n, edges: arcs)
        let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 0 ... 9, using: &generator) }
        let source = Int.random(in: 0 ..< n, using: &generator)
        var trees = [graph.shortestPaths(from: source), graph.dijkstraShortestPaths(from: source) { weights[$0] }]
        if let bellmanFord = graph.bellmanFordShortestPaths(from: source, weight: { weights[$0] }) { trees.append(bellmanFord) }
        for tree in trees {
            let arborescence = Arborescence(tree)
            let reached = (0 ..< n).filter { tree.hasPath(to: $0) }
            #expect(Array(arborescence.vertices) == reached)
            #expect(arborescence.root == source)
            #expect(arborescence.edgeCount == reached.count - 1)
            for v in reached {
                #expect(arborescence.parent(of: v) == tree.parent(of: v))
                // Depth is the number of edges on the tree path.
                #expect(arborescence.depth(of: v) == tree.path(to: v)!.edges.count)
                #expect(arborescence.path(from: source, to: v)!.vertices == tree.path(to: v)!.vertices)
            }
        }
    }

    @Test("SP-141 a DAG, an undirected graph, and a matrix")
    func otherSearches() {
        let dag = AdjacencyList(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4)])
        let dagWeights = [5, 1, 1, 1, 2]
        let dagTree = dag.dagShortestPaths(from: 0) { dagWeights[$0] }!
        let fromDAG = Arborescence(dagTree)
        #expect(fromDAG.parent(of: 3) == 2)
        #expect(fromDAG.parent(of: 4) == 3)

        let undirected = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let ring = Arborescence(undirected.shortestPaths(from: 0))
        #expect(ring.root == 0)
        #expect(Array(ring.vertices) == [0, 1, 2, 3])
        #expect(ring.parent(of: 1) == 0)
        #expect(ring.parent(of: 3) == 0)
        #expect(ring.depth(of: 2) == 2)

        let matrix = AdjacencyMatrix(vertexCount: 4, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 3)])
        let fromMatrix = Arborescence(matrix.shortestPaths(from: 1))
        #expect(Array(fromMatrix.vertices) == [0, 1, 2, 3])
        #expect(fromMatrix.parent(of: 0) == 2)
        #expect(fromMatrix.children(of: 1).map { $0 } == [2, 3])
    }

    @Test("SP-142 String vertices, a graph without vertex indices, and a stable graph with holes")
    func vertexIdentifiers() {
        let named = AdjacencyList(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let fromNamed = Arborescence(named.shortestPaths(from: "a"))
        // Index order: "c" is index 0.
        #expect(Array(fromNamed.vertices) == ["c", "a", "b"])
        #expect(fromNamed.root == "a")
        #expect(fromNamed.parent(of: "c") == "b")
        #expect(fromNamed.depth(of: "c") == 2)

        // Without vertex indices the tree numbers vertices as the search meets them.
        let reference = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 7, to: 3), DirectedEdge(from: 3, to: 9), DirectedEdge(from: 7, to: 9)])
        let fromReference = Arborescence(reference.shortestPaths(from: 7))
        #expect(fromReference.root == 7)
        #expect(Set(fromReference.vertices) == [7, 3, 9])
        #expect(fromReference.parent(of: 9) == 7)
        #expect(fromReference.parent(of: 3) == 7)

        var stable = StableDirectedGraph(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 3)])
        stable.remove(1)
        let fromStable = Arborescence(stable.shortestPaths(from: 0))
        #expect(Set(fromStable.vertices) == [0, 2, 3, 4])
        #expect(fromStable.parent(of: 3) == 4)
        #expect(fromStable.depth(of: 3) == 3)
    }

    @Test("SP-143 a one-vertex search is a one-vertex arborescence")
    func single() {
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 2)])
        let arborescence = Arborescence(graph.shortestPaths(from: 0))
        #expect(arborescence.vertexCount == 1)
        #expect(arborescence.edgeCount == 0)
        #expect(arborescence.root == 0)
    }

    @Test("SP-144 a tree from several sources traps: Trees has no rooted-forest type", .tags(.precondition))
    func severalSources() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
            _ = Arborescence(graph.shortestPaths(from: [0, 2]))
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = Arborescence(graph.dijkstraShortestPaths(from: [0, 2]) { _ in 1 })
        }
        // Bellman–Ford gives the second source a parent, so the parents alone form one tree; the
        // tree still came from two sources.
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = Arborescence(graph.bellmanFordShortestPaths(from: [0, 1]) { _ in -1 }!)
        }
    }

    @Test("SP-145 a repeated source is one source")
    func repeatedSource() {
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let arborescence = Arborescence(graph.shortestPaths(from: [0, 0]))
        #expect(arborescence.root == 0)
        #expect(arborescence.vertexCount == 3)
    }
}
