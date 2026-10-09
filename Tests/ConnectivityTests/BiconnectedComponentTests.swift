// §C: articulation points, blocks and the block–cut tree, ported from NetworkX, JGraphT, petgraph,
// Boost, igraph, rustworkx and LEMON.
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

@Suite("Articulation points and blocks")
struct BiconnectedComponentTests {
    @Test("CN-235 NetworkX test_biconnected_components1: points 4, 6, 7, 8, 9 and 7 blocks")
    func networkxTestBiconnectedComponents1Points4() {
        // 0-1 0-5 0-6 0-14 1-5 1-6 1-14 2-4 2-10 3-4 3-15 4-6 4-7 4-10 5-14 6-14 7-9 8-9 8-12 8-13 10-15 11-12 11-13 12-13
        let edges = [(0, 1), (0, 5), (0, 6), (0, 14), (1, 5), (1, 6), (1, 14), (2, 4), (2, 10), (3, 4), (3, 15), (4, 6), (4, 7), (4, 10), (5, 14), (6, 14), (7, 9), (8, 9), (8, 12), (8, 13), (10, 15), (11, 12), (11, 13), (12, 13)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 5, 6, 14, 2, 4, 10, 3, 15, 7, 9, 8, 12, 13, 11]])
            #expect(g.isConnected)
            #expect(g.bridges() == [11, 12, 16, 17])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [6, 4, 7, 9, 8])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 7)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4, 5, 6, 14, 15], [7, 8, 9, 10, 13, 20], [11], [12], [16], [17], [18, 19, 21, 22, 23]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 5, 6, 14], [2, 4, 10, 3, 15], [6, 4], [4, 7], [7, 9], [9, 8], [8, 12, 13, 11]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 5, 6, 14], [2, 4, 10, 3, 15], [7], [9], [8, 12, 13, 11]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [6, 4, 7, 9, 8])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[6], [4], [6, 4], [4, 7], [7, 9], [9, 8], [8]])
            #expect(tree.edgeCount == 11)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 3, 1, 0, 0, 4, 5, 6, 6, 1, 6, 6, 6])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0, 2], [0], [1], [1, 2, 3], [1], [1], [1], [3, 4], [4, 5], [5, 6], [6], [6], [6]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .articulationPoint(0), .block(0), .block(1), .articulationPoint(1), .block(1), .block(1), .block(1), .articulationPoint(2), .articulationPoint(3), .articulationPoint(4), .block(6), .block(6), .block(6)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 2], [1, 2, 3], [3, 4], [4, 5], [5, 6]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-236 NetworkX test_biconnected_components2: points C, E, G")
    func networkxTestBiconnectedComponents2PointsC() {
        // C(A,B,C) C(C,D,E) C(F,I,J,H,G) G-I J-G E-G
        let edges = [("A", "B"), ("B", "C"), ("C", "A"), ("C", "D"), ("D", "E"), ("E", "C"), ("F", "I"), ("I", "J"), ("J", "H"), ("H", "G"), ("G", "F"), ("G", "I"), ("J", "G"), ("E", "G")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C", "D", "E", "F", "I", "J", "H", "G"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [13])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["C", "E", "G"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            let expected7: [[Int]] = [[0, 1, 2], [3, 4, 5], Array(6 ... 12), [13]]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B", "C"], ["C", "D", "E"], ["F", "I", "J", "H", "G"], ["E", "G"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A", "B", "C", "D", "E"], ["F", "I", "J", "H", "G"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["C", "E", "G"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["C"], ["C", "E"], ["G"], ["E", "G"]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1], [1, 3], [2], [2], [2], [2], [2, 3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .block(1), .articulationPoint(1), .block(2), .block(2), .block(2), .block(2), .articulationPoint(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 3], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-237 NetworkX test_biconnected_components2 with I–J written twice: the copy joins the big block")
    func networkxTestBiconnectedComponents2WithI() {
        // C(A,B,C) C(C,D,E) C(F,I,J,H,G) C(G,I,J) E-G
        let edges = [("A", "B"), ("B", "C"), ("C", "A"), ("C", "D"), ("D", "E"), ("E", "C"), ("F", "I"), ("I", "J"), ("J", "H"), ("H", "G"), ("G", "F"), ("G", "I"), ("I", "J"), ("J", "G"), ("E", "G")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C", "D", "E", "F", "I", "J", "H", "G"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [14])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["C", "E", "G"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            let expected7: [[Int]] = [[0, 1, 2], [3, 4, 5], Array(6 ... 13), [14]]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B", "C"], ["C", "D", "E"], ["F", "I", "J", "H", "G"], ["E", "G"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A", "B", "C", "D", "E"], ["F", "I", "J", "H", "G"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["C", "E", "G"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["C"], ["C", "E"], ["G"], ["E", "G"]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [1], [1, 3], [2], [2], [2], [2], [2, 3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .block(1), .articulationPoint(1), .block(2), .block(2), .block(2), .block(2), .articulationPoint(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 3], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-238 NetworkX test_barbell: barbell_graph(8, 4) with a tail and a cycle, 11 blocks")
    func networkxTestBarbellBarbellGraph8() {
        // K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25)
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 7 { for v in u + 1 ... 7 { pairs.append((u, v)) } }
        for i in 7 ..< 12 { pairs.append((i, i + 1)) }
        for u in 12 ..< 19 { for v in u + 1 ... 19 { pairs.append((u, v)) } }
        pairs += [(7, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 22)]
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 25)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [28, 29, 30, 31, 32, 61, 62, 63])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [7, 8, 9, 10, 11, 12, 20, 21, 22])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 11)
            let expected8: [[Int]] = [Array(0 ... 27), [28], [29], [30], [31], [32], Array(33 ... 60), [61], [62], [63], [64, 65, 66, 67]]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 7), [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], Array(12 ... 19), [7, 20], [20, 21], [21, 22], [22, 23, 24, 25]]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(!g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 7), [8], [9], [10], [11], Array(12 ... 19), [20], [21], [22, 23, 24, 25]]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [7, 8, 9, 10, 11, 12, 20, 21, 22])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[7], [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], [12], [7, 20], [20, 21], [21, 22], [22]])
            #expect(tree.edgeCount == 19)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-239 NetworkX test_barbell with 2–17: points 7, 20, 21, 22")
    func networkxTestBarbellWith217() {
        // K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25) 2-17
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 7 { for v in u + 1 ... 7 { pairs.append((u, v)) } }
        for i in 7 ..< 12 { pairs.append((i, i + 1)) }
        for u in 12 ..< 19 { for v in u + 1 ... 19 { pairs.append((u, v)) } }
        pairs += [(7, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 22), (2, 17)]
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 25)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [61, 62, 63])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [7, 20, 21, 22])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 5)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 68], [61], [62], [63], [64, 65, 66, 67]])
            let expected9: [[Int]] = [Array(0 ... 19), [7, 20], [20, 21], [21, 22], [22, 23, 24, 25]]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected9)
            #expect(!g.isBiconnected)
            let expected12: [[Int]] = [Array(0 ... 19), [20], [21], [22, 23, 24, 25]]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected12)
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [7, 20, 21, 22])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[7], [7, 20], [20, 21], [21, 22], [22]])
            #expect(tree.edgeCount == 8)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-240 NetworkX test_biconnected_karate: point 0, three blocks", .tags(.fixture))
    func networkxTestBiconnectedKaratePoint0() {
        let fixture = UndirectedFixture<Int>.karate
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 17, 19, 21, 31, 30, 9, 27, 28, 32, 16, 33, 14, 15, 18, 20, 22, 23, 25, 29, 24, 26]])
            #expect(g.isConnected)
            #expect(g.bridges() == [9])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 6, 7, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77], [3, 4, 5, 8, 35, 36, 37, 38, 39, 40], [9]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3, 7, 8, 12, 13, 17, 19, 21, 31, 30, 9, 27, 28, 32, 33, 14, 15, 18, 20, 22, 23, 25, 29, 24, 26], [0, 4, 5, 6, 10, 16], [0, 11]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 17, 19, 21, 31, 30, 9, 27, 28, 32, 16, 33, 14, 15, 18, 20, 22, 23, 25, 29, 24, 26], [11]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0], [0]])
            #expect(tree.edgeCount == 3)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-241 NetworkX test_biconnected_eppstein G1: biconnected")
    func networkxTestBiconnectedEppsteinG1Biconnected() {
        // 0-1 0-2 0-5 1-5 2-3 2-4 3-4 3-5 3-6 4-5 4-6
        let edges = [(0, 1), (0, 2), (0, 5), (1, 5), (2, 3), (2, 4), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 5, 3, 4, 6]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 10)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 5, 3, 4, 6]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 5, 3, 4, 6]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-242 NetworkX test_biconnected_eppstein G2: four blocks")
    func networkxTestBiconnectedEppsteinG2Four() {
        // [0..8] 0-2 0-5 1-3 1-8 2-3 2-5 3-6 3-8 4-7 6-8
        let edges = [(0, 2), (0, 5), (1, 3), (1, 8), (2, 3), (2, 5), (3, 6), (3, 8), (4, 7), (6, 8)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 5, 6, 8], [4, 7]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [4, 8])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 5], [2, 3, 6, 7, 9], [4], [8]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 2, 5], [1, 3, 6, 8], [2, 3], [4, 7]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 2, 5], [1, 3, 6, 8], [4], [7]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [3], [2, 3], []])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 1, 1, 2, 0, 1, 1, 3, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [1], [0, 2], [1, 2], [3], [0], [1], [3], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(1), .articulationPoint(0), .articulationPoint(1), .block(3), .block(0), .block(1), .block(3), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 2], [1, 2]])
        }
        check(ReferencePseudograph(vertices: 0 ... 8, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 8, edges: edges))
    }

    @Test("CN-243 JGraphT testWikiGraph: points 4, 5, 6, 7, 9 and five bridges")
    func jgraphtTestWikiGraphPoints456() {
        // [1..14] 1-3 1-2 2-4 3-4 4-5 5-6 6-7 7-8 7-9 9-10 9-11 11-12 12-13 13-14 12-14 7-14
        let edges = [(1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(1 ... 14)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [4, 5, 6, 7, 9])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [4, 5, 6, 7, 9])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 7)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3], [4], [5], [6], [7], [8, 10, 11, 12, 13, 14, 15], [9]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [7, 9, 11, 12, 13, 14], [9, 10]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1, 2, 3, 4], [5], [6], [7, 9, 11, 12, 13, 14], [8], [10]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [4, 5, 6, 7, 9])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[4], [4, 5], [5, 6], [6, 7], [7], [7, 9], [9]])
            #expect(tree.edgeCount == 11)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 5, 5, 5, 5, 5, 5])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0, 1], [1, 2], [2, 3], [3, 4, 5], [4], [5, 6], [6], [5], [5], [5], [5]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .articulationPoint(3), .block(4), .articulationPoint(4), .block(6), .block(5), .block(5), .block(5), .block(5)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3], [3, 4, 5], [5, 6]])
        }
        check(ReferencePseudograph(vertices: 1 ... 14, edges: edges))
        check(UndirectedAdjacencyList(vertices: 1 ... 14, edges: edges))
    }

    @Test("CN-244 JGraphT testMultiGraph: a loop and a parallel pair", .tags(.selfLoops))
    func jgraphtTestMultiGraphLoopParallelPair() {
        // [0..2] 0-1 1-1 1-2 1-2
        let edges = [(0, 1), (1, 1), (1, 2), (1, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0], [2, 3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1, 2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, nil, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-245 JGraphT testMultiGraph2: every edge twice, same points and blocks, no bridges")
    func jgraphtTestMultiGraph2EveryEdgeTwiceSame() {
        // [1..14] 1-3 1-2 2-4 3-4 4-5 5-6 6-7 7-8 7-9 9-10 9-11 11-12 12-13 13-14 12-14 7-14 1-3 1-2 2-4 3-4 4-5 5-6 6-7 7-8 7-9 9-10 9-11 11-12 12-13 13-14 12-14 7-14
        let edges = [(1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14), (1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(1 ... 14)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [4, 5, 6, 7, 9])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 7)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 16, 17, 18, 19], [4, 20], [5, 21], [6, 22], [7, 23], [8, 10, 11, 12, 13, 14, 15, 24, 26, 27, 28, 29, 30, 31], [9, 25]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2, 3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [7, 9, 11, 12, 13, 14], [9, 10]])
            #expect(!g.isBiconnected)
            let expected11: [[Int]] = [Array(1 ... 14)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected11)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [4, 5, 6, 7, 9])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[4], [4, 5], [5, 6], [6, 7], [7], [7, 9], [9]])
            #expect(tree.edgeCount == 11)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 5, 5, 5, 5, 5, 5])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0, 1], [1, 2], [2, 3], [3, 4, 5], [4], [5, 6], [6], [5], [5], [5], [5]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .articulationPoint(3), .block(4), .articulationPoint(4), .block(6), .block(5), .block(5), .block(5), .block(5)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2], [2, 3], [3, 4, 5], [5, 6]])
        }
        check(ReferencePseudograph(vertices: 1 ... 14, edges: edges))
    }

    @Test("CN-246 JGraphT testLinearGraph: n − 2 points on a path")
    func jgraphtTestLinearGraphN2PointsOn() {
        // P(0..4)
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

    @Test("CN-247 JGraphT testBiconnected: the 6-cycle")
    func jgraphtTestBiconnected6Cycle() {
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

    @Test("CN-248 JGraphT testNotBiconnected: two points")
    func jgraphtTestNotBiconnectedTwoPoints() {
        // [0..5] 0-2 0-3 3-1 1-4 4-5 5-3
        let edges = [(0, 2), (0, 3), (3, 1), (1, 4), (4, 5), (5, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2, 3, 4, 5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 2], [0, 3], [1, 3, 4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1, 3, 4, 5], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0, 3], [3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 2, 2, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [2], [0], [1, 2], [2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(2), .block(0), .articulationPoint(1), .block(2), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(vertices: 0 ... 5, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 5, edges: edges))
    }

    @Test("CN-249 JGraphT testConnectedComponents1: two components")
    func jgraphtTestConnectedComponents1TwoComponents() {
        // [1..5] 1-2 2-3 4-5
        let edges = [(1, 2), (2, 3), (4, 5)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[1, 2, 3], [4, 5]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[1, 2], [2, 3], [4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1], [2], [3], [4], [5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2], []])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-250 JGraphT ConnectivityInspectorTest pseudograph: not connected", .tags(.selfLoops))
    func jgraphtConnectivityInspectorTestPseudographNotConnected() {
        // [v1,v2,v3,v4] v1-v2 v2-v3 v3-v1 v3-v1 v1-v1 v1-v1
        let edges = [("v1", "v2"), ("v2", "v3"), ("v3", "v1"), ("v3", "v1"), ("v1", "v1"), ("v1", "v1")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["v1", "v2", "v3"], ["v4"]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["v1", "v2", "v3"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["v1", "v2", "v3"], ["v4"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, nil, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: ["v1", "v2", "v3", "v4"], edges: edges))
    }

    @Test("CN-251 JGraphT testIsGraphConnected: connected", .tags(.selfLoops))
    func jgraphtTestIsGraphConnectedConnected() {
        // v1-v2 v2-v3 v3-v1 v3-v1 v1-v1 v1-v1
        let edges = [("v1", "v2"), ("v2", "v3"), ("v3", "v1"), ("v3", "v1"), ("v1", "v1"), ("v1", "v1")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["v1", "v2", "v3"]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["v1", "v2", "v3"]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["v1", "v2", "v3"]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, nil, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-252 petgraph art_two_connected_components: B and E")
    func petgraphArtTwoConnectedComponentsB() {
        // A-B B-C D-E E-F
        let edges = [("A", "B"), ("B", "C"), ("D", "E"), ("E", "F")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C"], ["D", "E", "F"]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["B", "E"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B"], ["B", "C"], ["D", "E"], ["E", "F"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A"], ["B"], ["C"], ["D"], ["E"], ["F"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["B", "E"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["B"], ["B"], ["E"], ["E"]])
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

    @Test("CN-253 petgraph art_linear_chain: B and C")
    func petgraphArtLinearChainBC() {
        // A-B B-C C-D
        let edges = [("A", "B"), ("B", "C"), ("C", "D")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C", "D"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["B", "C"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B"], ["B", "C"], ["C", "D"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A"], ["B"], ["C"], ["D"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["B", "C"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["B"], ["B", "C"], ["C"]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-254 petgraph art_star_graph: the center")
    func petgraphArtStarGraphCenter() {
        // S(Center;A,B,C,D)
        let edges = [("Center", "A"), ("Center", "B"), ("Center", "C"), ("Center", "D")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["Center", "A", "B", "C", "D"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["Center"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["Center", "A"], ["Center", "B"], ["Center", "C"], ["Center", "D"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["Center"], ["A"], ["B"], ["C"], ["D"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["Center"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["Center"], ["Center"], ["Center"], ["Center"]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1, 2, 3], [0], [1], [2], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(1), .block(2), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-255 petgraph art_clique: none")
    func petgraphArtCliqueNone() {
        // A-B B-C C-A
        let edges = [("A", "B"), ("B", "C"), ("C", "A")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C"]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B", "C"]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A", "B", "C"]])
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

    @Test("CN-256 petgraph art_simple1: B")
    func petgraphArtSimple1B() {
        // A-B B-C B-D
        let edges = [("A", "B"), ("B", "C"), ("B", "D")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C", "D"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["B"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B"], ["B", "C"], ["B", "D"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A"], ["B"], ["C"], ["D"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["B"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["B"], ["B"], ["B"]])
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

    @Test("CN-257 petgraph art_disconnected_graph: B")
    func petgraphArtDisconnectedGraphB() {
        // A-B B-C D-E
        let edges = [("A", "B"), ("B", "C"), ("D", "E")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C"], ["D", "E"]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [0, 1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["B"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B"], ["B", "C"], ["D", "E"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A"], ["B"], ["C"], ["D"], ["E"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["B"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["B"], ["B"], []])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1], [2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-258 petgraph art_3x3_grid: none")
    func petgraphArt3x3GridNone() {
        // A-B B-C A-D B-E C-F D-E E-F D-G E-H F-I G-H H-I
        let edges = [("A", "B"), ("B", "C"), ("A", "D"), ("B", "E"), ("C", "F"), ("D", "E"), ("E", "F"), ("D", "G"), ("E", "H"), ("F", "I"), ("G", "H"), ("H", "I")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C", "D", "E", "F", "G", "H", "I"]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 11)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B", "C", "D", "E", "F", "G", "H", "I"]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A", "B", "C", "D", "E", "F", "G", "H", "I"]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-259 petgraph art_simple2: B and D")
    func petgraphArtSimple2BD() {
        // A-B B-C B-D D-E
        let edges = [("A", "B"), ("B", "C"), ("B", "D"), ("D", "E")].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["A", "B", "C", "D", "E"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 1, 2, 3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["B", "D"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0], [1], [2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["A", "B"], ["B", "C"], ["B", "D"], ["D", "E"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["A"], ["B"], ["C"], ["D"], ["E"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["B", "D"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["B"], ["B"], ["B", "D"], ["D"]])
            #expect(tree.edgeCount == 5)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1, 2], [1], [2, 3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .articulationPoint(1), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-260 Boost biconnected_components.cpp: 4 blocks, 3 articulation points")
    func boostBiconnectedComponentsCpp4Blocks() {
        // [0..8] 0-5 0-1 0-6 1-2 1-3 1-4 2-3 4-5 6-8 6-7 7-8
        let edges = [(0, 5), (0, 1), (0, 6), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5), (6, 8), (6, 7), (7, 8)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 8)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges() == [2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0, 1, 6])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 5, 7], [2], [3, 4, 6], [8, 9, 10]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 4, 5], [0, 6], [1, 2, 3], [6, 7, 8]])
            #expect(!g.isBiconnected)
            let expected11: [[Int]] = [Array(0 ... 5), [6, 7, 8]]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected11)
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0, 1, 6])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0, 1], [0, 6], [1], [6]])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 1, 2, 2, 0, 2, 0, 3, 3, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0, 2], [2], [2], [0], [0], [1, 3], [3], [3]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .articulationPoint(1), .block(2), .block(2), .block(0), .block(0), .articulationPoint(2), .block(3), .block(3)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [0, 2], [1, 3]])
        }
        check(ReferencePseudograph(vertices: 0 ... 8, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 8, edges: edges))
    }

    @Test("CN-261 Boost biconnected_components_test.cpp: the 4-vertex graph")
    func boostBiconnectedComponentsTestCpp4() {
        // [0..3] 2-3 0-3 0-2 1-0
        let edges = [(2, 3), (0, 3), (0, 2), (1, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 2, 3], [0, 1]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 2, 3], [1]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [1], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(1), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: 0 ... 3, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 3, edges: edges))
    }

    @Test("CN-262 igraph igraph_biconnected_components: points 2 and 5, an isolated vertex")
    func igraphIgraphBiconnectedComponentsPoints2() {
        // [0..9] 0-1 1-2 2-3 3-0 2-4 4-5 5-2 5-6 7-8
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 5), (5, 2), (5, 6), (7, 8)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 6), [7, 8], [9]]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(!g.isConnected)
            #expect(g.bridges() == [7, 8])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3], [4, 5, 6], [7], [8]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3], [2, 4, 5], [5, 6], [7, 8]])
            #expect(!g.isBiconnected)
            let expected11: [[Int]] = [Array(0 ... 5), [6], [7], [8], [9]]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected11)
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 5], [5], []])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 1, 1, 2, 3])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [0], [1], [1, 2], [2], [3], [3], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .block(0), .block(1), .articulationPoint(1), .block(2), .block(3), .block(3), nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(vertices: 0 ... 9, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 9, edges: edges))
    }

    @Test("CN-263 igraph igraph_is_biconnected: two cycles sharing a vertex")
    func igraphIgraphBiconnectedTwoCyclesSharing() {
        // [0..5] 0-1 1-2 2-3 3-0 2-4 4-5 5-2
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 5), (5, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3], [4, 5, 6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 3], [2, 4, 5]])
            #expect(!g.isBiconnected)
            let expected11: [[Int]] = [Array(0 ... 5)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected11)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 1], [0], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .block(0), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-264 igraph igraph_is_biconnected: a 10-ring")
    func igraphIgraphBiconnected10Ring() {
        // C(0..9)
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 9)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected8: [[Int]] = [Array(0 ... 9)]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 9)]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 9)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-265 igraph igraph_is_biconnected: a triangle, a pendant and isolated vertices")
    func igraphIgraphBiconnectedTrianglePendantIsolated() {
        // [0..6] 0-1 1-2 2-0 1-3
        let edges = [(0, 1), (1, 2), (2, 0), (1, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3], [4], [5], [6]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [1, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3], [4], [5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [0], [1], [], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(0), .block(1), nil, nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: 0 ... 6, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 6, edges: edges))
    }

    @Test("CN-266 igraph igraph_is_biconnected: a triangle with an ear")
    func igraphIgraphBiconnectedTriangleWithEar() {
        // [0..4] 0-1 1-2 2-0 1-3 3-4 4-2
        let edges = [(0, 1), (1, 2), (2, 0), (1, 3), (3, 4), (4, 2)].map { UndirectedEdge($0.0, $0.1) }
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

    @Test("CN-267 igraph igraph_is_biconnected: a triangle and a 2-path")
    func igraphIgraphBiconnectedTriangle2Path() {
        // [0..6] 0-1 1-2 2-0 1-3 3-4
        let edges = [(0, 1), (1, 2), (2, 0), (1, 3), (3, 4)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4], [5], [6]])
            #expect(!g.isConnected)
            #expect(g.bridges() == [3, 4])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 3])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3], [4]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [1, 3], [3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3], [4], [5], [6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 3])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 3], [3]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [0], [1, 2], [2], [], []])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(0), .articulationPoint(1), .block(2), nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(vertices: 0 ... 6, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 6, edges: edges))
    }

    @Test("CN-268 igraph igraph_is_biconnected: two disjoint cycles")
    func igraphIgraphBiconnectedTwoDisjointCycles() {
        // [0..5] C(0,1,2) C(3,4,5)
        let edges = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [3, 4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], []])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [1], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(1), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-269 igraph igraph_is_biconnected: a cycle and an isolated vertex is not biconnected")
    func igraphIgraphBiconnectedCycleIsolatedVertex() {
        // [0..3] C(0,1,2)
        let edges = [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2], [3]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3]])
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
        check(ReferencePseudograph(vertices: 0 ... 3, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 3, edges: edges))
    }

    @Test("CN-270 igraph igraph_is_biconnected: the first vertex is the articulation point")
    func igraphIgraphBiconnectedFirstVertexArticulation() {
        // C(0,1,2) C(0,3,4)
        let edges = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [0, 3, 4]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0], [0], [1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .block(1), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-271 rustworkx TestBiconnected.test_graph: points 4 and 5, 4 blocks")
    func rustworkxTestBiconnectedTestGraphPoints4() {
        // 0-2 0-3 1-4 4-9 5-7 0-1 1-2 2-3 2-4 4-5 4-8 5-6 6-7 8-9
        let edges = [(0, 2), (0, 3), (1, 4), (4, 9), (5, 7), (0, 1), (1, 2), (2, 3), (2, 4), (4, 5), (4, 8), (5, 6), (6, 7), (8, 9)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 2, 3, 1, 4, 9, 5, 7, 8, 6]])
            #expect(g.isConnected)
            #expect(g.bridges() == [9])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [4, 5])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 4)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 5, 6, 7, 8], [3, 10, 13], [4, 11, 12], [9]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 2, 3, 1, 4], [4, 9, 8], [5, 7, 6], [4, 5]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 2, 3, 1, 4, 9, 8], [5, 7, 6]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [4, 5])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[4], [4], [5], [4, 5]])
            #expect(tree.edgeCount == 5)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 2, 0, 0, 0, 0, 3, 1, 2, 2, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0, 1, 3], [1], [2, 3], [2], [1], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .articulationPoint(0), .block(1), .articulationPoint(1), .block(2), .block(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 3], [2, 3]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-272 rustworkx test_barbell_graph: points 2 and 3")
    func rustworkxTestBarbellGraphPoints2() {
        // 0-1 0-2 1-2 3-4 3-5 4-5 2-3
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

    @Test("CN-273 rustworkx test_disconnected_graph: two barbells")
    func rustworkxTestDisconnectedGraphTwoBarbells() {
        // 0-1 0-2 1-2 3-4 3-5 4-5 2-3 6-7 6-8 7-8 9-10 9-11 10-11 8-9
        let edges = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (6, 7), (6, 8), (7, 8), (9, 10), (9, 11), (10, 11), (8, 9)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 5), Array(6 ... 11)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(!g.isConnected)
            #expect(g.bridges() == [6, 13])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [2, 3, 8, 9])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 6)
            #expect(blocks.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6], [7, 8, 9], [10, 11, 12], [13]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [3, 4, 5], [2, 3], [6, 7, 8], [9, 10, 11], [8, 9]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [2, 3, 8, 9])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [3], [2, 3], [8], [9], [8, 9]])
            #expect(tree.edgeCount == 8)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 1, 1, 1, 2, 3, 3, 3, 4, 4, 4, 5])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0, 2], [1, 2], [1], [1], [3], [3], [3, 5], [4, 5], [4], [4]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .articulationPoint(0), .articulationPoint(1), .block(1), .block(1), .block(3), .block(3), .articulationPoint(2), .articulationPoint(3), .block(4), .block(4)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 2], [1, 2], [3, 5], [4, 5]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-274 rustworkx test_biconnected_graph: one block of 11 edges")
    func rustworkxTestBiconnectedGraphOneBlock() {
        // 0-1 0-2 0-5 1-5 2-3 2-4 3-4 3-5 3-6 4-5 4-6
        let edges = [(0, 1), (0, 2), (0, 5), (1, 5), (2, 3), (2, 4), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 5, 3, 4, 6]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected7: [[Int]] = [Array(0 ... 10)]
            #expect(blocks.map(Array.init) == expected7)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2, 5, 3, 4, 6]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2, 5, 3, 4, 6]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-275 NetworkX TestConnected: a grid, a lollipop and a house")
    func networkxTestConnectedGridLollipopHouse() {
        // 0-2 0-1 1-3 2-3 4-5 4-6 5-6 6-7 7-8 8-9 10-11 10-12 11-13 12-13 12-14 13-14
        let edges = [(0, 2), (0, 1), (1, 3), (2, 3), (4, 5), (4, 6), (5, 6), (6, 7), (7, 8), (8, 9), (10, 11), (10, 12), (11, 13), (12, 13), (12, 14), (13, 14)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [[0, 2, 1, 3], Array(4 ... 9), [10, 11, 12, 13, 14]]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(!g.isConnected)
            #expect(g.bridges() == [7, 8, 9])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [6, 7, 8])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 6)
            let expected8: [[Int]] = [[0, 1, 2, 3], [4, 5, 6], [7], [8], [9], Array(10 ... 15)]
            #expect(blocks.map(Array.init) == expected8)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 2, 1, 3], [4, 5, 6], [6, 7], [7, 8], [8, 9], [10, 11, 12, 13, 14]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 2, 1, 3], [4, 5, 6], [7], [8], [9], [10, 11, 12, 13, 14]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [6, 7, 8])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[], [6], [6, 7], [7, 8], [8], []])
            #expect(tree.edgeCount == 6)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 1, 1, 1, 2, 3, 4, 5, 5, 5, 5, 5, 5])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [1], [1], [1, 2], [2, 3], [3, 4], [4], [5], [5], [5], [5], [5]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(1), .block(1), .articulationPoint(0), .articulationPoint(1), .articulationPoint(2), .block(4), .block(5), .block(5), .block(5), .block(5), .block(5)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[1, 2], [2, 3], [3, 4]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-276 NetworkX test_is_connected: a 4 × 4 grid")
    func networkxTestConnected44Grid() {
        // grid(4,4)
        let edges = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 15)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            let expected8: [[Int]] = [Array(0 ... 23)]
            #expect(blocks.map(Array.init) == expected8)
            let expected10: [[Int]] = [Array(0 ... 15)]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected10)
            #expect(g.isBiconnected)
            let expected13: [[Int]] = [Array(0 ... 15)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected13)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: 0 ... 15, edges: edges))
        check(UndirectedAdjacencyList(vertices: 0 ... 15, edges: edges))
    }

    @Test("CN-277 NetworkX test_is_connected: two vertices, no edge")
    func networkxTestConnectedTwoVerticesNo() {
        // [1,2]
        let edges: [UndirectedEdge<Int>] = []
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[1], [2]])
            #expect(!g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.isEmpty)
            #expect(blocks.isEmpty)
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }.isEmpty)
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(tree.edgeCount == 0)
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], []])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: [1, 2], edges: edges))
        check(UndirectedAdjacencyList(vertices: [1, 2], edges: edges))
    }

    @Test("CN-278 LEMON connectivity_test, 8 nodes as bi-node and bi-edge components: no bridge")
    func lemonConnectivityTest8NodesAs() {
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

    @Test("CN-279 LEMON connectivity_test, 6 nodes: no articulation point")
    func lemonConnectivityTest6NodesNo() {
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
}
