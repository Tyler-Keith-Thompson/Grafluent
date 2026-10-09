// §B: bridges and 2-edge-connected components, ported from NetworkX, igraph, rustworkx and JGraphT.
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

@Suite("Bridges and 2-edge-connected components")
struct BridgeTests {
    @Test("CN-220 NetworkX test_single_bridge: only (5, 6)")
    func networkxTestSingleBridgeOnly5() {
        // 1-2 2-3 3-4 3-5 5-6 6-7 7-8 5-9 9-10 1-3 1-4 2-5 5-10 6-8
        let edges = [(1, 2), (2, 3), (3, 4), (3, 5), (5, 6), (6, 7), (7, 8), (5, 9), (9, 10), (1, 3), (1, 4), (2, 5), (5, 10), (6, 8)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(1 ... 10)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [5, 6])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 9, 10, 11], [4], [5, 6, 13], [7, 8, 12]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 3, 4, 5], [5, 6], [6, 7, 8], [5, 9, 10]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1, 2, 3, 4, 5, 9, 10], [6, 7, 8]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [5, 6])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[5], [5, 6], [6], [5]])
            #expect(tree.edgeCount == 5)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 2, 2, 3, 3, 0, 0, 0, 3, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0, 1, 3], [1, 2], [2], [2], [3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(2), .block(2), .block(3), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 3], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-221 NetworkX test_barbell_graph: only (2, 3)")
    func networkxTestBarbellGraphOnly2() {
        // K(0..2) K(3..5) 2-3
        let edges = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [6])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [3, 4, 5], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [3], [2, 3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 2], [1, 2], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 2], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-222 NetworkX test_multiedge_bridge: only (2, 3), a parallel pair is no bridge")
    func networkxTestMultiedgeBridgeOnly2() {
        // 0-1 0-2 1-2 1-2 2-3 3-4 3-4
        let edges = [(0, 1), (0, 2), (1, 2), (1, 2), (2, 3), (3, 4), (3, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges() == [4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3], [4], [5, 6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 3], [3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 2, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-223 NetworkX TestHasBridges.test_multiedge_bridge: no bridges")
    func networkxTestHasBridgesTestMultiedgeBridgeNo() {
        // 0-1 0-2 1-2 1-2 2-3 3-4 3-4 0-1 0-2 2-3
        let edges = [(0, 1), (0, 2), (1, 2), (1, 2), (2, 3), (3, 4), (3, 4), (0, 1), (0, 2), (2, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 7, 8], [4, 9], [5, 6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 3], [3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 2, 2, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-224 NetworkX test_bridges_multiple_components: every edge of two paths")
    func networkxTestBridgesMultipleComponentsEvery() {
        // P(0,1,2) P(4,5,6)
        let edges = [(0, 1), (1, 2), (4, 5), (5, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [4, 5, 6]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [4, 5], [5, 6]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [4], [5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [5], [5]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2], [2, 3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .articulationPoint(1), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-225 igraph igraph_bridges, 7 vertices: edges 3 and 7")
    func igraphIgraphBridges7VerticesEdges() {
        // [0..6] 0-1 1-2 0-2 0-3 3-4 4-5 3-5 4-6
        let edges = [(0, 1), (1, 2), (0, 2), (0, 3), (3, 4), (4, 5), (3, 5), (4, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 6)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [3, 7])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0, 3, 4])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3], [4, 5, 6], [7]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [0, 3], [3, 4, 5], [4, 6]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0, 3, 4])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0, 3], [3, 4], [4]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 2, 2, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0], [0], [1, 2], [2, 3], [2], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .articulationPoint(1), .articulationPoint(2), .block(2), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-226 igraph igraph_bridges, disconnected with an isolated vertex: 0 1 2 13 14")
    func igraphIgraphBridgesDisconnectedWithIsolated() {
        // [0..15] 0-1 1-2 1-3 4-5 5-6 4-6 4-7 7-8 4-8 9-10 10-11 11-12 9-12 9-13 13-14
        let edges = [(0, 1), (1, 2), (1, 3), (4, 5), (5, 6), (4, 6), (4, 7), (7, 8), (4, 8), (9, 10), (10, 11), (11, 12), (9, 12), (9, 13), (13, 14)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7, 8], Array(9 ... 14), [15]]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 13, 14])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 4, 9, 13])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 8)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3, 4, 5], [6, 7, 8], [9, 10, 11, 12], [13], [14]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [1, 3], [4, 5, 6], [4, 7, 8], [9, 10, 11, 12], [9, 13], [13, 14]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4, 5, 6, 7, 8], [9, 10, 11, 12], [13], [14], [15]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 4, 9, 13])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [1], [4], [4], [9], [9, 13], [13]])
            #expect(tree.edgeCount == 9)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 7])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1, 2], [1], [2], [3, 4], [3], [3], [4], [4], [5, 6], [5], [5], [5], [6, 7], [7], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .articulationPoint(1), .block(3), .block(3), .block(4), .block(4), .articulationPoint(2), .block(5), .block(5), .block(5), .articulationPoint(3), .block(7), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2], [3, 4], [5, 6], [6, 7]])
        }
        check(ReferencePseudograph(vertices: 0 ... 15, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 15, edges: edges))
    }

    @Test("CN-227 igraph igraph_bridges with multi-edges and a self-loop: edge 2", .tags(.selfLoops))
    func igraphIgraphBridgesWithMultiEdges() {
        // 0-1 0-1 1-2 2-2
        let edges = [(0, 1), (0, 1), (1, 2), (2, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 1, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-228 rustworkx test_tree: every edge is a bridge")
    func rustworkxTestTreeEveryEdgeBridge() {
        // 0-1 0-2 1-3 1-4 2-5 2-6
        let edges = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 6)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3, 4, 5])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0, 1, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 6)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3], [4], [5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0, 1, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0, 1], [0, 2], [1], [1], [2], [2]])
            #expect(tree.edgeCount == 8)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0, 2, 3], [1, 4, 5], [2], [3], [4], [5]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(2), .block(3), .block(4), .block(5)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [0, 2, 3], [1, 4, 5]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-229 rustworkx test_cycle_no_bridges: a 100-cycle")
    func rustworkxTestCycleNoBridges100() {
        // C(0..99)
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 99 { pairs.append((i, i + 1)) }
        pairs.append((99, 0))
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 99)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected8: [[Int]] = [Array(0 ... 99)]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 99)]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 99)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-230 JGraphT testGithubIssueBug798: cut point 0, bridge 0–3, two blocks")
    func jgraphtTestGithubIssueBug798CutPoint0Bridge() {
        // [0..3] 0-1 1-2 0-2 0-3
        let edges = [(0, 1), (1, 2), (0, 2), (0, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [0, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0], [0], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-231 NetworkX test_tarjan_bridge (Tarjan 1974): bridges (4, 8), (3, 5), (3, 17)")
    func networkxTestTarjanBridgeTarjan1974() {
        // P(1,2,4,3,1,4) P(5,6,7,5) P(8,9,10,8) P(17,18,16,15,17) P(11,12,14,13,11,14) 4-8 3-5 3-17
        let edges = [(1, 2), (2, 4), (4, 3), (3, 1), (1, 4), (5, 6), (6, 7), (7, 5), (8, 9), (9, 10), (10, 8), (17, 18), (18, 16), (16, 15), (15, 17), (11, 12), (12, 14), (14, 13), (13, 11), (11, 14), (4, 8), (3, 5), (3, 17)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[1, 2, 4, 3, 5, 6, 7, 8, 9, 10, 17, 18, 16, 15], [11, 12, 14, 13]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [20, 21, 22])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [4, 3, 5, 8, 17])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 8)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4], [5, 6, 7], [8, 9, 10], [11, 12, 13, 14], [15, 16, 17, 18, 19], [20], [21], [22]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 4, 3], [5, 6, 7], [8, 9, 10], [17, 18, 16, 15], [11, 12, 14, 13], [4, 8], [3, 5], [3, 17]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1, 2, 4, 3], [5, 6, 7], [8, 9, 10], [17, 18, 16, 15], [11, 12, 14, 13]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [4, 3, 5, 8, 17])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[4, 3], [5], [8], [17], [], [4, 8], [3, 5], [3, 17]])
            #expect(tree.edgeCount == 11)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 6, 7])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 5], [0, 6, 7], [1, 6], [1], [1], [2, 5], [2], [2], [3, 7], [3], [3], [3], [4], [4], [4], [4]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(1), .block(1), .articulationPoint(3), .block(2), .block(2), .articulationPoint(4), .block(3), .block(3), .block(3), .block(4), .block(4), .block(4), .block(4)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 5], [0, 6, 7], [1, 6], [2, 5], [3, 7]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-232 NetworkX test_bridge_cc: the 2-edge-connected components")
    func networkxTestBridgeCc2Edge() {
        // P(1,2,4,3,1,4) P(8,9,10,8) P(11,12,13,11) 4-8 3-5 20-21 P(22,23,24)
        let edges = [(1, 2), (2, 4), (4, 3), (3, 1), (1, 4), (8, 9), (9, 10), (10, 8), (11, 12), (12, 13), (13, 11), (4, 8), (3, 5), (20, 21), (22, 23), (23, 24)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[1, 2, 4, 3, 8, 9, 10, 5], [11, 12, 13], [20, 21], [22, 23, 24]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [11, 12, 13, 14, 15])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [4, 3, 8, 23])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 8)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4], [5, 6, 7], [8, 9, 10], [11], [12], [13], [14], [15]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 4, 3], [8, 9, 10], [11, 12, 13], [4, 8], [3, 5], [20, 21], [22, 23], [23, 24]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1, 2, 4, 3], [8, 9, 10], [11, 12, 13], [5], [20], [21], [22], [23], [24]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [4, 3, 8, 23])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[4, 3], [8], [], [4, 8], [3], [], [23], [23]])
            #expect(tree.edgeCount == 8)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 4, 5, 6, 7])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 3], [0, 4], [1, 3], [1], [1], [2], [2], [2], [4], [5], [5], [6], [6, 7], [7]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(1), .block(1), .block(2), .block(2), .block(2), .block(4), .block(5), .block(5), .block(6), .articulationPoint(3), .block(7)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 3], [0, 4], [1, 3], [6, 7]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-233 NetworkX bridge_components doc example: barbell_graph(5, 0)")
    func networkxBridgeComponentsDocExampleBarbell() {
        // K(0..4) K(5..9) 4-5
        let edges = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 9)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [20])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [4, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            let expected8: [[Int]] = [Array(0 ... 9), Array(10 ... 19), [20]]
            #expect(blocks.map(Array.init) == expected8)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [4, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[4], [5], [4, 5]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0, 2], [1, 2], [1], [1], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(1), .block(1), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 2], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-234 NetworkX test_triangles: two triangles joined by 11–21")
    func networkxTestTrianglesTwoTrianglesJoined() {
        // C(11,12,13) C(21,22,23) 11-21
        let edges = [(11, 12), (12, 13), (13, 11), (21, 22), (22, 23), (23, 21), (11, 21)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[11, 12, 13, 21, 22, 23]])
            #expect(g.isConnected)
            #expect(g.bridges() == [6])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [11, 21])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[11, 12, 13], [21, 22, 23], [11, 21]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[11, 12, 13], [21, 22, 23]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [11, 21])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[11], [21], [11, 21]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 2], [0], [0], [1, 2], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .articulationPoint(1), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 2], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }
}
