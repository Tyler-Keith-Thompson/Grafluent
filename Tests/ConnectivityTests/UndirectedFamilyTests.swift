// §E: graph families — paths, cycles, stars, complete and complete bipartite graphs, grids, wheels,
// chains of blocks — and the canonical block order.
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

@Suite("Forests, paths, cycles and complete graphs")
struct UndirectedFamilyTests {
    @Test("CN-300 the path P₆")
    func pathP6() {
        // P(0..5)
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3, 4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2, 3, 4])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 5)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3], [4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2, 3, 4])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2, 3], [3, 4], [4]])
            #expect(tree.edgeCount == 8)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3, 4])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2, 3], [3, 4], [4]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .articulationPoint(3), .block(4)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3], [3, 4]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-301 the cycle C₆")
    func cycleC6() {
        // C(0..5)
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected8: [[Int]] = [Array(0 ... 5)]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 5)]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 5)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-302 the star K₁,₅")
    func starK15() {
        // S(0;1..5)
        let edges = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3, 4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 5)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3], [4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0], [0], [0], [0]])
            #expect(tree.edgeCount == 5)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3, 4])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1, 2, 3, 4], [0], [1], [2], [3], [4]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(1), .block(2), .block(3), .block(4)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2, 3, 4]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-303 K₅")
    func k5() {
        // K(0..4)
        let edges = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 9)]
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
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-304 K₂,₃")
    func k23() {
        // 0-2 0-3 0-4 1-2 1-3 1-4
        let edges = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 2, 3, 4, 1]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 5)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 2, 3, 4, 1]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 2, 3, 4, 1]])
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
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-305 a bowtie is 2-edge-connected but not biconnected")
    func bowtie2EdgeConnectedButNot() {
        // C(0,1,2) C(2,3,4)
        let edges = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-306 a theta graph")
    func thetaGraph() {
        // P(0,1,2) P(0,3,2) P(0,4,2)
        let edges = [(0, 1), (1, 2), (0, 3), (3, 2), (0, 4), (4, 2)].map { UndirectedEdge($0.0, $0.1) }
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
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-307 the ladder L₄")
    func ladderL4() {
        // ladder(4)
        let edges = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 7)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected8: [[Int]] = [Array(0 ... 9)]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 7)]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 7)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 7, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 7, edges: edges))
    }

    @Test("CN-308 the wheel W₆")
    func wheelW6() {
        // C(1..5) S(0;1..5)
        let edges = [(1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[1, 2, 3, 4, 5, 0]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 9)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 3, 4, 5, 0]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1, 2, 3, 4, 5, 0]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-309 a chain of four triangles")
    func chainFourTriangles() {
        // C(0,1,2) C(2,3,4) C(4,5,6) C(6,7,8)
        let edges = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2), (4, 5), (5, 6), (6, 4), (6, 7), (7, 8), (8, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 8)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [2, 4, 6])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3, 4], [4, 5, 6], [6, 7, 8]])
            #expect(!g.isBiconnected)
            let expected11: [[Int]] = [Array(0 ... 8)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected11)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 4, 6])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 4], [4, 6], [6]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1], [1, 2], [2], [2, 3], [3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .block(1), .articulationPoint(1), .block(2), .articulationPoint(2), .block(3), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-310 a lollipop: K₄ with a 3-edge tail")
    func lollipopK4With3EdgeTail() {
        // K(0..3) P(3,4,5,6)
        let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 6)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [6, 7, 8])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [3, 4, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            let expected8: [[Int]] = [Array(0 ... 5), [6], [7], [8]]
            #expect(blocks.map(Array.init) == expected8)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3], [3, 4], [4, 5], [5, 6]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3], [4], [5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [3, 4, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[3], [3, 4], [4, 5], [5]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 1, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0, 1], [1, 2], [2, 3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-311 a caterpillar")
    func caterpillar() {
        // P(0..4) 1-5 1-6 3-7
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (3, 7)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 7)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3, 4, 5, 6])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 7)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3], [4], [5], [6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3], [3, 4], [1, 5], [1, 6], [3, 7]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6], [7]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2, 3], [3], [1], [1], [3]])
            #expect(tree.edgeCount == 9)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 6])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1, 4, 5], [1, 2], [2, 3, 6], [3], [4], [5], [6]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(3), .block(4), .block(5), .block(6)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 4, 5], [1, 2], [2, 3, 6]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-312 a forest of three trees and an isolated vertex")
    func forestThreeTreesIsolatedVertex() {
        // [0..9] P(0,1,2) S(3;4,5,6) 7-8
        let edges = [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6), (7, 8)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5, 6], [7, 8], [9]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3, 4, 5])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 6)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3], [4], [5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [3, 4], [3, 5], [3, 6], [7, 8]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [3], [3], [3], []])
            #expect(tree.edgeCount == 5)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2, 3, 4], [2], [3], [4], [5], [5], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .articulationPoint(1), .block(2), .block(3), .block(4), .block(5), .block(5), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [2, 3, 4]])
        }
        check(ReferencePseudograph(vertices: 0 ... 9, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 9, edges: edges))
    }

    @Test("CN-313 the 3 × 4 grid")
    func n34Grid() {
        // grid(3,4)
        let edges = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 11)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected8: [[Int]] = [Array(0 ... 16)]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 11)]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 11)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 11, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 11, edges: edges))
    }

    @Test("CN-314 the 1 × 5 grid is a path")
    func n15GridPath() {
        // grid(1,5)
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2, 3], [3]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2, 3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-315 the first vertex is a cut vertex in three blocks")
    func firstVertexCutVertexInThree() {
        // C(0,1,2) C(0,3,4) 0-5
        let edges = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0), (0, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [6])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [0, 3, 4], [0, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0], [0]])
            #expect(tree.edgeCount == 3)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1, 2], [0], [0], [1], [1], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .block(1), .block(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-316 a cycle with a chord and a pendant")
    func cycleWithChordPendant() {
        // C(0..5) 0-3 3-6
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (3, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 6)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [7])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            let expected8: [[Int]] = [Array(0 ... 6), [7]]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 5), [3, 6]]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(!g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 5), [6]]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[3], [3]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0, 1], [0], [0], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .articulationPoint(0), .block(0), .block(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-317 a one-edge block between two cut vertices")
    func oneEdgeBlockBetweenTwoCut() {
        // C(0,1,2) 2-3 C(3,4,5)
        let edges = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3], [4, 5, 6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3], [3, 4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 3], [3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 2, 2, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1, 2], [2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(2), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-318 nested blocks: cut vertices in three blocks")
    func nestedBlocksCutVerticesInThree() {
        // C(0,1,2) C(0,3,4) 0-5 5-6 C(5,7,8)
        let edges = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0), (0, 5), (5, 6), (5, 7), (7, 8), (8, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 8)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [6, 7])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 5)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6], [7], [8, 9, 10]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [0, 3, 4], [0, 5], [5, 6], [5, 7, 8]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4], [5, 7, 8], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0], [0, 5], [5], [5]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2, 3, 4, 4, 4])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1, 2], [0], [0], [1], [1], [2, 3, 4], [3], [4], [4]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .block(1), .block(1), .articulationPoint(1), .block(3), .block(4), .block(4)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2], [2, 3, 4]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-319 blocks are ordered by smallest position, not by search completion")
    func blocksAreOrderedSmallestPositionNot() {
        // 5-6 0-1 1-2 2-0 2-3 3-4 4-2 1-5
        let edges = [(5, 6), (0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2), (1, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[5, 6, 0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 7])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [5, 1, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1, 2, 3], [4, 5, 6], [7]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[5, 6], [0, 1, 2], [2, 3, 4], [5, 1]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[5], [6], [0, 1, 2, 3, 4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [5, 1, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[5], [1, 2], [2], [5, 1]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 1, 1, 2, 2, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 3], [0], [1], [1, 3], [1, 2], [2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(1), .articulationPoint(1), .articulationPoint(2), .block(2), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 3], [1, 3], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }
}
