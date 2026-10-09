// §G: disconnected graphs — isolated vertices, loop-only components, interleaved components.
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

@Suite("Disconnected undirected graphs")
struct UndirectedDisconnectedTests {
    @Test("CN-330 isolated vertices around one block are in no block")
    func isolatedVerticesAroundOneBlockAre() {
        // [0..4] C(1,2,3)
        let edges = [(1, 2), (2, 3), (3, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0], [1, 2, 3], [4]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1, 2, 3], [4]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], [0], [0], [0], []])
            let nodes: [BlockCutTree<G>.Node?] = [nil, .block(0), .block(0), .block(0), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 4, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 4, edges: edges))
    }

    @Test("CN-331 an isolated vertex listed last")
    func isolatedVertexListedLast() {
        // [0,1,2,9] C(0,1,2)
        let edges = [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [9]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [9]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: [0, 1, 2, 9], edges: edges))
        check(UndirectedAdjacencyList(vertices: [0, 1, 2, 9], edges: edges))
    }

    @Test("CN-332 two components, each with a cut vertex")
    func twoComponentsEachWithCutVertex() {
        // P(0,1,2) C(3,4,5) 5-6
        let edges = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3), (5, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5, 6]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 5])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2, 3, 4], [5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [3, 4, 5], [5, 6]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3, 4, 5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [5], [5]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 2, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2], [2], [2, 3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .block(2), .articulationPoint(1), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-333 a loop-only component next to a tree", .tags(.selfLoops))
    func loopOnlyComponentNextTree() {
        // [0] 0-0 P(1,2,3)
        let edges = [(0, 0), (1, 2), (2, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0], [1, 2, 3]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], [0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [nil, .block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-334 a component of parallel edges next to a bridge")
    func componentParallelEdgesNextBridge() {
        // 0-1 0-1 2-3
        let edges = [(0, 1), (0, 1), (2, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1], [2, 3]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], []])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-335 components interleaved in vertices order")
    func componentsInterleavedInVerticesOrder() {
        // [0..5] 0-3 1-4 2-5 3-0
        let edges = [(0, 3), (1, 4), (2, 5), (3, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 3], [1, 4], [2, 5]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 3], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 3], [1, 4], [2, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 3], [1], [2], [4], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], [], []])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [1], [2], [0], [1], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(1), .block(2), .block(0), .block(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 5, edges: edges))
    }

    @Test("CN-336 a tree, a cycle, a bowtie, a loop-only vertex and an isolated vertex", .tags(.selfLoops))
    func treeCycleBowtieLoopOnlyVertex() {
        // [0..13] P(0,1,2) C(3,4,5) C(6,7,8) C(8,9,10) 11-11
        let edges = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3), (6, 7), (7, 8), (8, 6), (8, 9), (9, 10), (10, 8), (11, 11)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5], [6, 7, 8, 9, 10], [11], [12], [13]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 8])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 5)
            #expect(blocks.map(Array.init) == [[0], [1], [2, 3, 4], [5, 6, 7], [8, 9, 10]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [3, 4, 5], [6, 7, 8], [8, 9, 10]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3, 4, 5], [6, 7, 8, 9, 10], [11], [12], [13]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 8])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [], [8], [8]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2], [2], [2], [3], [3], [3, 4], [4], [4], [], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .block(2), .block(2), .block(3), .block(3), .articulationPoint(1), .block(4), .block(4), nil, nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [3, 4]])
        }
        check(ReferencePseudograph(vertices: 0 ... 13, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 13, edges: edges))
    }

    @Test("CN-337 two copies of CN-235")
    func twoCopiesCN235() {
        // 0-1 0-5 0-6 0-14 1-5 1-6 1-14 2-4 2-10 3-4 3-15 4-6 4-7 4-10 5-14 6-14 7-9 8-9 8-12 8-13 10-15 11-12 11-13 12-13 100-101 100-105 100-106 100-114 101-105 101-106 101-114 102-104 102-110 103-104 103-115 104-106 104-107 104-110 105-114 106-114 107-109 108-109 108-112 108-113 110-115 111-112 111-113 112-113
        let edges = [(0, 1), (0, 5), (0, 6), (0, 14), (1, 5), (1, 6), (1, 14), (2, 4), (2, 10), (3, 4), (3, 15), (4, 6), (4, 7), (4, 10), (5, 14), (6, 14), (7, 9), (8, 9), (8, 12), (8, 13), (10, 15), (11, 12), (11, 13), (12, 13), (100, 101), (100, 105), (100, 106), (100, 114), (101, 105), (101, 106), (101, 114), (102, 104), (102, 110), (103, 104), (103, 115), (104, 106), (104, 107), (104, 110), (105, 114), (106, 114), (107, 109), (108, 109), (108, 112), (108, 113), (110, 115), (111, 112), (111, 113), (112, 113)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 5, 6, 14, 2, 4, 10, 3, 15, 7, 9, 8, 12, 13, 11], [100, 101, 105, 106, 114, 102, 104, 110, 103, 115, 107, 109, 108, 112, 113, 111]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [11, 12, 16, 17, 35, 36, 40, 41])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [6, 4, 7, 9, 8, 106, 104, 107, 109, 108])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 14)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4, 5, 6, 14, 15], [7, 8, 9, 10, 13, 20], [11], [12], [16], [17], [18, 19, 21, 22, 23], [24, 25, 26, 27, 28, 29, 30, 38, 39], [31, 32, 33, 34, 37, 44], [35], [36], [40], [41], [42, 43, 45, 46, 47]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 5, 6, 14], [2, 4, 10, 3, 15], [6, 4], [4, 7], [7, 9], [9, 8], [8, 12, 13, 11], [100, 101, 105, 106, 114], [102, 104, 110, 103, 115], [106, 104], [104, 107], [107, 109], [109, 108], [108, 112, 113, 111]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 5, 6, 14], [2, 4, 10, 3, 15], [7], [9], [8, 12, 13, 11], [100, 101, 105, 106, 114], [102, 104, 110, 103, 115], [107], [109], [108, 112, 113, 111]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [6, 4, 7, 9, 8, 106, 104, 107, 109, 108])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[6], [4], [6, 4], [4, 7], [7, 9], [9, 8], [8], [106], [104], [106, 104], [104, 107], [107, 109], [109, 108], [108]])
            #expect(tree.edgeCount == 22)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-338 20 isolated vertices and one edge between the last two")
    func n20IsolatedVerticesOneEdgeBetween() {
        // [0..19] 18-19
        let edges = [(18, 19)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18, 19]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[18, 19]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 19, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 19, edges: edges))
    }

    @Test("CN-339 gap4 read as written: every arc an edge, opposite arcs parallel", .tags(.selfLoops))
    func gap4ReadAsWrittenEveryArc() {
        let fixture = DirectedFixture<Int>.gap4
        let edges = fixture.edges.map { UndirectedEdge($0.source, $0.target) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13], [5]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 4, 6, 8, 9, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 35, 36, 37, 38, 39, 40, 41, 42, 43, 45, 46, 47, 48, 49, 51, 52, 53, 54, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 68, 69, 70, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 86, 87, 89, 90, 91, 93, 94, 95, 96, 97, 99, 101, 102, 103, 104, 105, 106, 107, 108, 109, 111, 112, 113, 114, 115, 116, 118, 119, 120, 121, 122, 124, 125, 126, 127, 128, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 141, 142, 144, 145, 146, 147, 148, 150, 151, 152, 153, 155, 156, 159, 160, 161, 162, 164, 165, 167, 168, 170, 171, 172, 173, 174, 175, 176, 177, 178, 180, 181, 182, 183, 184, 185, 186, 187, 188, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 246, 247, 248, 249, 250, 251, 252, 254, 255]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
        }
        check(ReferencePseudograph(vertices: 0 ..< 14, edges: edges))
    }
}
