// §J: deep and wide undirected graphs, and the real-world fixtures read as undirected graphs. Deep
// graphs run inside a Task, whose stack is much smaller than the main thread's, so a recursive
// depth-first search to the depth of a 100 000-vertex path overflows (JGraphT's
// BiconnectivityInspector is recursive and does). Each entry point is called once per graph, on
// one representation, and per-element checks are folded into one expectation each to keep each
// test well under two seconds in a debug build: so the sizes are half the catalog's or less (a
// 50 000-vertex path, cycle and star, a 25 000-vertex doubled path and lasso, a 150 × 150 grid,
// 15 000 triangles), still far deeper than a recursive search survives on a Task's stack; the
// benchmarks run 10⁶. Expected values come from the catalog's reference, scaled. Case IDs (CN-nnn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Undirected connectivity on deep and wide graphs")
struct UndirectedConnectivityDeepGraphTests {
    @Test("CN-370 a 50 000-vertex path: depth 50 000, every edge a bridge, no recursion")
    func deepPath() async {
        await Task {
            let n = 50_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.connectedComponents().count == 1)
            #expect(graph.isConnected)
            #expect(graph.bridges() == Array(0 ..< n - 1))
            #expect(graph.hasBridges)
            #expect(graph.articulationPoints() == Array(1 ..< n - 1))
            #expect(!graph.isBiconnected)
            let twoEdge = graph.biEdgeConnectedComponents()
            #expect(twoEdge.count == n)
            #expect(twoEdge.indices.allSatisfy { Array(twoEdge[$0]) == [$0] })
            #expect(!graph.isBiEdgeConnected)
            // The tree's blocks are biconnectedComponents().
            let tree = graph.blockCutTree()
            let blocks = tree.blocks
            #expect(blocks.count == n - 1)
            #expect(blocks.indices.allSatisfy { Array(blocks[$0]) == [$0] })
            #expect(tree.articulationPoints.count == n - 2)
            #expect(tree.edgeCount == 2 * (n - 2))
            #expect(tree.node(of: n / 2) == .articulationPoint(n / 2 - 1))
        }.value
    }

    @Test("CN-371 a 50 000-vertex cycle: one block, no bridge")
    func deepCycle() async {
        await Task {
            let n = 50_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(graph.connectedComponents().map(Array.init) == [Array(0 ..< n)])
            #expect(graph.isConnected)
            #expect(graph.bridges().isEmpty)
            #expect(!graph.hasBridges)
            #expect(graph.articulationPoints().isEmpty)
            #expect(graph.isBiconnected)
            #expect(graph.biEdgeConnectedComponents().count == 1)
            #expect(graph.isBiEdgeConnected)
            let tree = graph.blockCutTree()
            #expect(tree.blocks.map(Array.init) == [Array(0 ..< n)])
            #expect(tree.edgeCount == 0)
        }.value
    }

    @Test("CN-372 a doubled 25 000-vertex path: depth 25 000, every tree edge with a parallel copy, so no bridge")
    func doubledPath() async {
        await Task {
            let n = 25_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).flatMap { [UndirectedEdge($0, $0 + 1), UndirectedEdge($0, $0 + 1)] })
            #expect(graph.bridges().isEmpty)
            #expect(!graph.hasBridges)
            #expect(graph.articulationPoints() == Array(1 ..< n - 1))
            let tree = graph.blockCutTree()
            #expect(tree.blocks.count == n - 1)
            #expect(tree.blocks.indices.allSatisfy { Array(tree.blocks[$0]) == [2 * $0, 2 * $0 + 1] })
            #expect(graph.biEdgeConnectedComponents().count == 1)
            #expect(graph.isBiEdgeConnected)
        }.value
    }

    @Test("CN-373 a star with 50 000 leaves: every edge a bridge, one articulation point in every block")
    func wideStar() async {
        await Task {
            let leaves = 50_000
            let graph = UndirectedAdjacencyList(edges: (1 ... leaves).map { UndirectedEdge(0, $0) })
            #expect(graph.isConnected)
            #expect(graph.bridges() == Array(0 ..< leaves))
            #expect(graph.articulationPoints() == [0])
            #expect(!graph.isBiconnected)
            #expect(graph.biEdgeConnectedComponents().count == leaves + 1)
            #expect(!graph.isBiEdgeConnected)
            let tree = graph.blockCutTree()
            #expect(tree.blocks.count == leaves)
            #expect(tree.blocks.components(containing: 0).count == leaves)
            #expect(tree.blocks(ofArticulationPoint: 0).count == leaves)
            #expect(tree.edgeCount == leaves)
        }.value
    }

    @Test("CN-374 a 150 × 150 grid: biconnected")
    func grid() async {
        await Task {
            let side = 150
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    if j + 1 < side { edges.append(UndirectedEdge(i * side + j, i * side + j + 1)) }
                    if i + 1 < side { edges.append(UndirectedEdge(i * side + j, (i + 1) * side + j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
            #expect(graph.edgeCount == 2 * side * (side - 1))
            #expect(graph.isConnected)
            #expect(graph.bridges().isEmpty)
            #expect(graph.articulationPoints().isEmpty)
            #expect(graph.biconnectedComponents().map(Array.init) == [Array(0 ..< graph.edgeCount)])
            #expect(graph.isBiconnected)
            #expect(graph.biEdgeConnectedComponents().count == 1)
            #expect(graph.isBiEdgeConnected)
        }.value
    }

    @Test("CN-375 K₃₀₀: dense, one block")
    func dense() async {
        await Task {
            let n = 300
            let graph = UndirectedAdjacencyList(edges: (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } })
            #expect(graph.edgeCount == n * (n - 1) / 2)
            #expect(graph.isConnected)
            #expect(graph.bridges().isEmpty)
            #expect(graph.articulationPoints().isEmpty)
            let blocks = graph.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.vertices(ofComponentAt: 0).count == n)
            #expect(graph.isBiconnected)
            #expect(graph.isBiEdgeConnected)
        }.value
    }

    @Test("CN-376 a lasso: a 25 000-cycle with a 25 000-edge tail")
    func lasso() async {
        await Task {
            let half = 25_000
            // C(0..24999) P(24999..49999).
            let edges = (0 ..< half).map { UndirectedEdge($0, ($0 + 1) % half) } + (half - 1 ..< 2 * half - 1).map { UndirectedEdge($0, $0 + 1) }
            let graph = UndirectedAdjacencyList(edges: edges)
            #expect(graph.vertexCount == 2 * half)
            #expect(graph.isConnected)
            #expect(graph.bridges() == Array(half ..< 2 * half))
            #expect(graph.articulationPoints() == Array(half - 1 ..< 2 * half - 1))
            let blocks = graph.blockCutTree().blocks
            #expect(blocks.count == half + 1)
            #expect(Array(blocks[0]) == Array(0 ..< half))
            #expect(!graph.isBiconnected)
            let twoEdge = graph.biEdgeConnectedComponents()
            #expect(twoEdge.count == half + 1)
            #expect(Array(twoEdge[0]) == Array(0 ..< half))
            #expect(!graph.isBiEdgeConnected)
        }.value
    }

    @Test("CN-377 a chain of 15 000 triangles, each sharing a vertex with the next")
    func triangleChain() async {
        await Task {
            let k = 15_000
            // T(15000): triangles (2i, 2i+1, 2i+2), edges 2i–2i+1, 2i+1–2i+2, 2i+2–2i.
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< k {
                let (a, b, c) = (2 * i, 2 * i + 1, 2 * i + 2)
                edges += [UndirectedEdge(a, b), UndirectedEdge(b, c), UndirectedEdge(c, a)]
            }
            let graph = UndirectedAdjacencyList(edges: edges)
            #expect(graph.isConnected)
            #expect(graph.bridges().isEmpty)
            #expect(graph.articulationPoints() == (1 ..< k).map { 2 * $0 })
            #expect(!graph.isBiconnected)
            #expect(graph.biEdgeConnectedComponents().count == 1)
            #expect(graph.isBiEdgeConnected)
            let tree = graph.blockCutTree()
            #expect(tree.blocks.count == k)
            #expect(tree.blocks.indices.allSatisfy { Array(tree.blocks[$0]) == [3 * $0, 3 * $0 + 1, 3 * $0 + 2] })
            #expect(tree.edgeCount == 2 * (k - 1))
        }.value
    }
}

@Suite("Undirected connectivity on the real-world fixtures", .tags(.fixture))
struct UndirectedConnectivityRealWorldTests {
    @Test("CN-378 gap4 with one edge per unordered pair")
    func gap4Simple() {
        let fixture = DirectedFixture<Int>.gap4
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 14, edges: fixture.edges.map { UndirectedEdge($0.source, $0.target) })
        #expect(graph.connectedComponents().count == 2)
        #expect(!graph.isConnected)
        #expect(graph.bridges().isEmpty)
        #expect(graph.articulationPoints().isEmpty)
        let blocks = graph.biconnectedComponents()
        #expect(blocks.count == 1)
        #expect(Array(blocks.vertices(ofComponentAt: 0)) == [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13])
        #expect(!graph.isBiconnected)
        #expect(graph.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13], [5]])
        #expect(!graph.isBiEdgeConnected)
    }

    @Test("CN-379 CN-380 graph500Scale8, simple and as written: 16 components, 25 bridges, 22 articulation points")
    func graph500() {
        let fixture = DirectedFixture<Int>.graph500Scale8
        let edges = fixture.edges.map { UndirectedEdge($0.source, $0.target) }
        func check<G: Graph<Int>>(_ g: G) {
            #expect(g.connectedComponents().count == 16)
            #expect(!g.isConnected)
            #expect(g.bridges().count == 25)
            #expect(g.hasBridges)
            #expect(g.articulationPoints().count == 22)
            #expect(g.biconnectedComponents().count == 26)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().count == 41)
            #expect(!g.isBiEdgeConnected)
        }
        check(UndirectedAdjacencyList(vertices: 0 ..< 256, edges: edges))
        // As written, repeated arcs collapsed and opposite arcs parallel: the same counts.
        check(AdjacencyList(vertices: 0 ..< 256, edges: fixture.edges).undirected)
        // Every arc, repeats included: bridges are arcs written once, so the count is the same.
        #expect(ReferencePseudograph(vertices: 0 ..< 256, edges: edges).bridges().count == 25)
    }

    @Test("CN-381 ligraRMat with one edge per unordered pair: five bridges")
    func ligraSimple() {
        let fixture = DirectedFixture<Int>.ligraRMat
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 128, edges: fixture.edges.map { UndirectedEdge($0.source, $0.target) })
        #expect(graph.connectedComponents().count == 4)
        #expect(!graph.isConnected)
        #expect(graph.bridges() == [25, 51, 215, 216, 260])
        #expect(graph.articulationPoints() == [4, 72, 79, 80, 97])
        #expect(graph.biconnectedComponents().count == 6)
        #expect(!graph.isBiconnected)
        #expect(graph.biEdgeConnectedComponents().count == 9)
        #expect(!graph.isBiEdgeConnected)
    }

    @Test("CN-382 ligraRMat as written: opposite arcs are parallel edges, so no bridge but the same articulation points")
    func ligraAsWritten() {
        let fixture = DirectedFixture<Int>.ligraRMat
        let graph = ReferencePseudograph(vertices: 0 ..< 128, edges: fixture.edges.map { UndirectedEdge($0.source, $0.target) })
        #expect(graph.connectedComponents().count == 4)
        #expect(graph.bridges().isEmpty)
        #expect(!graph.hasBridges)
        #expect(graph.articulationPoints() == [4, 72, 79, 80, 97])
        #expect(graph.biconnectedComponents().count == 6)
        #expect(graph.biEdgeConnectedComponents().count == 4)
        #expect(!graph.isBiEdgeConnected)
        // The same arcs through AdjacencyList.undirected: the opposite arcs are parallel there too.
        let view = AdjacencyList(vertices: 0 ..< 128, edges: fixture.edges).undirected
        #expect(view.bridges().isEmpty)
        #expect(view.articulationPoints() == [4, 72, 79, 80, 97])
        #expect(view.biEdgeConnectedComponents().count == 4)
    }
}
