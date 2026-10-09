// §A: the basic cases every entry point agrees on — the empty graph, K₁, K₂, a few vertices, and
// small graphs ported from NetworkX, petgraph, rustworkx, Boost and LEMON.
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

@Suite("Undirected connectivity basics")
struct UndirectedComponentsTests {
    @Test("CN-200 the empty graph: not connected, nothing found (NetworkX, rustworkx, igraph, JGraphT)", .tags(.fixture))
    func emptyGraphNotConnectedNothingFound() {
        let fixture = UndirectedFixture<Int>.empty
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().isEmpty)
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.isEmpty)
            #expect(blocks.isEmpty)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }.isEmpty)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().isEmpty)
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(tree.edgeCount == 0)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-201 K₁: connected, not biconnected, no block, one 2-edge-connected component", .tags(.fixture))
    func k1ConnectedNotBiconnectedNoBlock() {
        let fixture = UndirectedFixture<Int>.trivial
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.isEmpty)
            #expect(blocks.isEmpty)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }.isEmpty)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(tree.edgeCount == 0)
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[]])
            let nodes: [BlockCutTree<G>.Node?] = [nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-202 two isolated vertices (JGraphT, igraph, LEMON)")
    func twoIsolatedVerticesJGraphTIgraphLEMON() {
        // [0,1]
        let edges: [UndirectedEdge<Int>] = []
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0], [1]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.isEmpty)
            #expect(blocks.isEmpty)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }.isEmpty)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(tree.edgeCount == 0)
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], []])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: [0, 1], edges: edges))
        check(UndirectedAdjacencyList(vertices: [0, 1], edges: edges))
    }

    @Test("CN-203 K₂ is biconnected and its edge is a bridge (JGraphT, igraph, NetworkX, petgraph, rustworkx)")
    func k2BiconnectedItsEdgeBridgeJGraphT() {
        // 0-1
        let edges = [(0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-204 K₂ and a third vertex is not biconnected (LEMON)")
    func k2ThirdVertexNotBiconnectedLEMON() {
        // [0,1,2] 0-1
        let edges = [(0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1], [2]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 2, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 2, edges: edges))
    }

    @Test("CN-205 rustworkx test_another_trivial_graph")
    func rustworkxTestAnotherTrivialGraph() {
        // 0-1 1-2
        let edges = [(0, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0], [1]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-206 petgraph test_bridges, step 1")
    func petgraphTestBridgesStep1() {
        // 0-1 2-1
        let edges = [(0, 1), (2, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0], [1]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-207 petgraph test_bridges, step 2: a triangle")
    func petgraphTestBridgesStep2Triangle() {
        // 0-1 2-1 0-2
        let edges = [(0, 1), (2, 1), (0, 2)].map { UndirectedEdge($0.0, $0.1) }
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
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-208 petgraph test_bridges, step 3: a triangle and a 2-path")
    func petgraphTestBridgesStep3Triangle() {
        // 0-1 2-1 0-2 2-3 3-4
        let edges = [(0, 1), (2, 1), (0, 2), (2, 3), (3, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges() == [3, 4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3], [4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3], [4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 3], [3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-209 petgraph test_bridges, step 4: the path closes a cycle")
    func petgraphTestBridgesStep4Path() {
        // 0-1 2-1 0-2 2-3 3-4 3-0
        let edges = [(0, 1), (2, 1), (0, 2), (2, 3), (3, 4), (3, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges() == [4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 5], [4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3], [4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[3], [3]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-210 petgraph's bridges doc example: e0, e1, e5")
    func petgraphBridgesDocExampleE0E1() {
        // 0-1 1-2 2-3 3-4 2-4 5-2
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (2, 4), (5, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 5])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2, 3, 4], [5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3, 4], [2, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2, 3, 4], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2], [2]])
            #expect(tree.edgeCount == 5)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 2, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2, 3], [2], [2], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .block(2), .block(2), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-211 NetworkX test_articulation_points_repetitions: 1 listed once")
    func networkxTestArticulationPointsRepetitions1() {
        // 0-1 1-2 1-3
        let edges = [(0, 1), (1, 2), (1, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [1, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [1]])
            #expect(tree.edgeCount == 3)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1, 2], [1], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-212 NetworkX test_articulation_points_cycle and test_biconnected_components_cycle")
    func networkxTestArticulationPointsCycleTest() {
        // C(0,1,2) C(1,3,4)
        let edges = [(0, 1), (1, 2), (2, 0), (1, 3), (3, 4), (4, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [1, 3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [0], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(0), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-213 NetworkX test_is_biconnected: a triangle")
    func networkxTestBiconnectedTriangle() {
        // C(0,1,2)
        let edges = [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) }
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
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-214 NetworkX test_empty_is_biconnected: five isolated vertices")
    func networkxTestEmptyBiconnectedFiveIsolated() {
        // [0..4]
        let edges: [UndirectedEdge<Int>] = []
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0], [1], [2], [3], [4]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.isEmpty)
            #expect(blocks.isEmpty)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }.isEmpty)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(tree.edgeCount == 0)
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], [], [], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil, nil, nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 4, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 4, edges: edges))
    }

    @Test("CN-215 NetworkX test_empty_is_biconnected with one edge")
    func networkxTestEmptyBiconnectedWithOne() {
        // [0..4] 0-1
        let edges = [(0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1], [2], [3], [4]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), nil, nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 4, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 4, edges: edges))
    }

    @Test("CN-216 Boost connected_components.cpp (CLR p. 87): three components")
    func boostConnectedComponentsCppCLRP() {
        // [0..5] 0-1 1-4 4-0 2-5
        let edges = [(0, 1), (1, 4), (4, 0), (2, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 4], [2, 5], [3]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 4], [2, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 4], [2], [3], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], []])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [1], [], [0], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(1), nil, .block(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 5, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 5, edges: edges))
    }

    @Test("CN-217 LEMON connectivity_test, 6 nodes: two components")
    func lemonConnectivityTest6NodesTwo() {
        // [0..5] 0-2 2-1 1-0 3-1 3-2 4-5 5-4
        let edges = [(0, 2), (2, 1), (1, 0), (3, 1), (3, 2), (4, 5), (5, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3], [4, 5]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4], [5, 6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3], [4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3], [4, 5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], []])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 5, edges: edges))
    }

    @Test("CN-218 LEMON connectivity_test, 8 nodes: three components")
    func lemonConnectivityTest8NodesThree() {
        // [0..7] 0-1 4-0 1-7 7-4 5-3 3-5 1-4 0-7 5-6 6-5
        let edges = [(0, 1), (4, 0), (1, 7), (7, 4), (5, 3), (3, 5), (1, 4), (0, 7), (5, 6), (6, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 4, 7], [2], [3, 5, 6]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 6, 7], [4, 5], [8, 9]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 4, 7], [3, 5], [5, 6]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 4, 7], [2], [3, 5, 6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], [5], [5]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 1, 0, 0, 2, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [], [1], [0], [1, 2], [2], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), nil, .block(1), .block(0), .articulationPoint(0), .block(2), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[1, 2]])
        }
        check(ReferencePseudograph(vertices: 0 ... 7, edges: edges))
    }

    @Test("CN-219 LEMON connectivity_test, 8 nodes with the five cut arcs")
    func lemonConnectivityTest8NodesWith() {
        // [0..7] 0-1 4-0 1-7 7-4 5-3 3-5 1-4 0-7 5-6 6-5 2-0 2-4 2-7 7-5 7-6
        let edges = [(0, 1), (4, 0), (1, 7), (7, 4), (5, 3), (3, 5), (1, 4), (0, 7), (5, 6), (6, 5), (2, 0), (2, 4), (2, 7), (7, 5), (7, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 7)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [5, 7])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 6, 7, 10, 11, 12], [4, 5], [8, 9, 13, 14]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 4, 7], [3, 5], [5, 6, 7]])
            #expect(!g.isBiconnected)
            let expected11: [[Int]] = [Array(0 ... 7)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected11)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [5, 7])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[7], [5], [5, 7]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 1, 0, 0, 2, 2, 0, 0, 0, 2, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [1], [0], [1, 2], [2], [0, 2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(1), .block(0), .articulationPoint(0), .block(2), .articulationPoint(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[1, 2], [0, 2]])
        }
        check(ReferencePseudograph(vertices: 0 ... 7, edges: edges))
    }
}
