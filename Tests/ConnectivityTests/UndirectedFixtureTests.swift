// §F: the named UndirectedFixture graphs.
// Each case runs on the ReferencePseudograph in written order, and on an UndirectedAdjacencyList
// built in the same order when no edge repeats, so positions and vertices order are the written
// ones and every value is exact. Expected values come from the catalog's reference (brute force
// from the definitions, an iterative Hopcroft–Tarjan and NetworkX 3.7). Case IDs (CN-nnn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Undirected connectivity on the named fixtures")
struct UndirectedFixtureTests {
    @Test("CN-320 k3", .tags(.fixture))
    func k3() {
        let fixture = UndirectedFixture<Int>.k3
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-321 path4", .tags(.fixture))
    func path4() {
        let fixture = UndirectedFixture<Int>.path4
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-322 cycle5", .tags(.fixture))
    func cycle5() {
        let fixture = UndirectedFixture<Int>.cycle5
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3, 4]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-323 k4", .tags(.fixture))
    func k4() {
        let fixture = UndirectedFixture<Int>.k4
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 5)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-324 house", .tags(.fixture))
    func house() {
        let fixture = UndirectedFixture<Int>.house
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 5)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3, 4]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-325 petersen: 3-connected", .tags(.fixture))
    func petersen3Connected() {
        let fixture = UndirectedFixture<Int>.petersen
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 4, 5, 2, 6, 3, 7, 8, 9]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 14)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 4, 5, 2, 6, 3, 7, 8, 9]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 4, 5, 2, 6, 3, 7, 8, 9]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-326 cube: 3-connected", .tags(.fixture))
    func cube3Connected() {
        let fixture = UndirectedFixture<Int>.cube
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 4, 3, 5, 6, 7]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 11)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 4, 3, 5, 6, 7]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 4, 3, 5, 6, 7]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-327 components7", .tags(.fixture))
    func components7() {
        let fixture = UndirectedFixture<Int>.components7
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [3, 4], [5], [6]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], []])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2], [2], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .block(2), nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-328 isolatedVertices", .tags(.fixture))
    func isolatedvertices() {
        let fixture = UndirectedFixture<Int>.isolatedVertices
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.isEmpty)
            #expect(blocks.isEmpty)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }.isEmpty)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(tree.edgeCount == 0)
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], [], [], [], [], [], [], [], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-329 networkXABCD, String vertices: the isolated G, J, K come first", .tags(.fixture))
    func networkxabcdStringVerticesIsolatedGJ() {
        let fixture = UndirectedFixture<String>.networkXABCD
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["G"], ["J"], ["K"], ["A", "B", "C", "D"]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B", "C", "D"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["G"], ["J"], ["K"], ["A", "B", "C", "D"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], [], [], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil, nil, .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }
}
