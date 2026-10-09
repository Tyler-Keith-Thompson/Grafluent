// §D: parallel edges and self-loops. A parallel pair is never a bridge and both copies share a
// block; a self-loop is never a bridge, never makes an articulation point and is in no block.
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

@Suite("Undirected parallel edges and self-loops")
struct UndirectedSelfLoopAndParallelEdgeTests {
    @Test("CN-280 a lone self-loop is in no block and makes no articulation point", .tags(.fixture, .selfLoops))
    func loneSelfLoopInNoBlock() {
        let fixture = UndirectedFixture<Int>.singleSelfLoop
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
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[]])
            let nodes: [BlockCutTree<G>.Node?] = [nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-281 a parallel pair is one block, biconnected and bi-edge-connected, and no bridge")
    func parallelPairOneBlockBiconnectedBi() {
        // 0-1 0-1
        let edges = [(0, 1), (0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-282 three parallel edges are one block")
    func threeParallelEdgesAreOneBlock() {
        // 0-1 0-1 0-1
        let edges = [(0, 1), (0, 1), (0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[0, 1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-283 parallelPath: the doubled edge is no bridge", .tags(.fixture))
    func parallelpathDoubledEdgeNoBridge() {
        let fixture = UndirectedFixture<Int>.parallelPath
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0], [1, 2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1, 2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-284 a self-loop at a cut vertex keeps it one and is in no block", .tags(.selfLoops))
    func selfLoopAtCutVertexKeeps() {
        // 0-1 1-1 1-2
        let edges = [(0, 1), (1, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, nil, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-285 loopAndPath: a loop on the end of a path makes no articulation point", .tags(.fixture, .selfLoops))
    func loopandpathLoopOnEndPathMakes() {
        let fixture = UndirectedFixture<Int>.loopAndPath
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-286 a loop and one edge: still biconnected, the loop makes no cut vertex", .tags(.selfLoops))
    func loopOneEdgeStillBiconnectedLoop() {
        // 0-0 0-1
        let edges = [(0, 0), (0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isConnected)
            #expect(g.bridges() == [1])
            #expect(g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[1]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-287 k3WithLoop: the loop changes nothing", .tags(.fixture, .selfLoops))
    func k3withloopLoopChangesNothing() {
        let fixture = UndirectedFixture<Int>.k3WithLoop
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
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-288 petgraphUndirected: doubled edges and a loop at a", .tags(.fixture, .selfLoops))
    func petgraphundirectedDoubledEdgesLoopAt() {
        let fixture = UndirectedFixture<Int>.petgraphUndirected
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [6])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 4, 5], [6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [0, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, nil, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0], [0], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-289 vertices whose only edges are loops are in no block", .tags(.selfLoops))
    func verticesWhoseOnlyEdgesAreLoops() {
        // [0,1] 0-0 0-0 1-1
        let edges = [(0, 0), (0, 0), (1, 1)].map { UndirectedEdge($0.0, $0.1) }
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
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil, nil, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[], []])
            let nodes: [BlockCutTree<G>.Node?] = [nil, nil]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-290 a doubled middle edge on a path")
    func doubledMiddleEdgeOnPath() {
        // 0-1 1-2 1-2 2-3
        let edges = [(0, 1), (1, 2), (1, 2), (2, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0], [1, 2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1, 2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 1, 2])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-291 the parallel copy of a tree edge written far from it: skip the parent edge, not the parent vertex")
    func parallelCopyTreeEdgeWrittenFar() {
        // 0-1 1-2 1-3 0-1
        let edges = [(0, 1), (1, 2), (1, 3), (0, 1)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 3], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [1, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1], [1]])
            #expect(tree.edgeCount == 3)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1, 2], [1], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-292 the parallel copy of the root's first tree edge, written last")
    func parallelCopyRootFirstTreeEdge() {
        // 0-1 0-2 2-3 1-0
        let edges = [(0, 1), (0, 2), (2, 3), (1, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [1, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [0, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[0, 3], [1], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [0, 2], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [0, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[0], [0, 2], [2]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-293 networkXIJK, String vertices: a loop at K", .tags(.fixture, .selfLoops))
    func networkxijkStringVerticesLoopAtK() {
        let fixture = UndirectedFixture<String>.networkXIJK
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["I", "J", "K"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [0, 2])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["J"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0], [2]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["I", "J"], ["J", "K"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["I"], ["J"], ["K"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["J"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["J"], ["J"]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, nil, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-294 petgraphUndirected, String vertices", .tags(.fixture, .selfLoops))
    func petgraphundirectedStringVertices() {
        let fixture = UndirectedFixture<String>.petgraphUndirected
        func check<G: Graph<String>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [["a", "b", "c", "d"]])
            #expect(g.isConnected)
            #expect(g.bridges() == [6])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == ["a"])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 4, 5], [6]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [["a", "b", "c"], ["a", "d"]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [["a", "b", "c"], ["d"]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == ["a"])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [["a"], ["a"]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 0, nil, 0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0, 1], [0], [0], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.articulationPoint(0), .block(0), .block(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-295 two loops and a parallel pair on two vertices", .tags(.selfLoops))
    func twoLoopsParallelPairOnTwo() {
        // 0-0 0-1 0-0 1-0
        let edges = [(0, 0), (0, 1), (0, 0), (1, 0)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints().isEmpty)
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 1)
            #expect(blocks.map(Array.init) == [[1, 3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1]])
            #expect(g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1]])
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints.isEmpty)
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[]])
            #expect(tree.edgeCount == 0)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil, 0, nil, 0])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .block(0)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-296 a digraph's opposite arcs through .undirected are parallel edges, so not bridges")
    func digraphOppositeArcsThroughUndirectedAre() {
        // 0-1 1-0 1-2
        let edges = [(0, 1), (1, 0), (1, 2)].map { UndirectedEdge($0.0, $0.1) }
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
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
        check(AdjacencyList(edges: [(0, 1), (1, 0), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }).undirected)
    }

    @Test("CN-297 doubling every edge of CN-238: no bridges, the same points, every block doubled")
    func doublingEveryEdgeCN238No() {
        // K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25) K(0..7) P(7,8,9,10,11,12) K(12..19) P(7,20,21,22) C(22,23,24,25)
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 7 { for v in u + 1 ... 7 { pairs.append((u, v)) } }
        for i in 7 ..< 12 { pairs.append((i, i + 1)) }
        for u in 12 ..< 19 { for v in u + 1 ... 19 { pairs.append((u, v)) } }
        pairs += [(7, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 22)]
        for u in 0 ..< 7 { for v in u + 1 ... 7 { pairs.append((u, v)) } }
        for i in 7 ..< 12 { pairs.append((i, i + 1)) }
        for u in 12 ..< 19 { for v in u + 1 ... 19 { pairs.append((u, v)) } }
        pairs += [(7, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 22)]
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            let expected0: [[Int]] = [Array(0 ... 25)]
            #expect(g.connectedComponents().map(Array.init) == expected0)
            #expect(g.isConnected)
            #expect(g.bridges().isEmpty)
            #expect(!g.hasBridges)
            #expect(g.articulationPoints() == [7, 8, 9, 10, 11, 12, 20, 21, 22])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 11)
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95], [28, 96], [29, 97], [30, 98], [31, 99], [32, 100], [33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128], [61, 129], [62, 130], [63, 131], [64, 65, 66, 67, 132, 133, 134, 135]])
            let expected9: [[Int]] = [Array(0 ... 7), [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], Array(12 ... 19), [7, 20], [20, 21], [21, 22], [22, 23, 24, 25]]
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected9)
            #expect(!g.isBiconnected)
            let expected12: [[Int]] = [Array(0 ... 25)]
            #expect(g.biEdgeConnectedComponents().map(Array.init) == expected12)
            #expect(g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [7, 8, 9, 10, 11, 12, 20, 21, 22])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[7], [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], [12], [7, 20], [20, 21], [21, 22], [22]])
            #expect(tree.edgeCount == 19)
        }
        check(ReferencePseudograph(edges: edges))
    }

    @Test("CN-298 a loop at every vertex of a path", .tags(.selfLoops))
    func loopAtEveryVertexPath() {
        // 0-0 0-1 1-1 1-2 2-2 2-3 3-3
        let edges = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2), (2, 3), (3, 3)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
            #expect(g.isConnected)
            #expect(g.bridges() == [1, 3, 5])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1, 2])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 3)
            #expect(blocks.map(Array.init) == [[1], [3], [5]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1, 2])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2]])
            #expect(tree.edgeCount == 4)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [nil, 0, nil, 1, nil, 2, nil])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .articulationPoint(1), .block(2)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1], [1, 2]])
        }
        check(ReferencePseudograph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges))
    }

    @Test("CN-299 the loop written between a tree edge and its parallel copy", .tags(.selfLoops))
    func loopWrittenBetweenTreeEdgeIts() {
        // 0-1 1-1 1-0 1-2
        let edges = [(0, 1), (1, 1), (1, 0), (1, 2)].map { UndirectedEdge($0.0, $0.1) }
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map(Array.init) == [[0, 1, 2]])
            #expect(g.isConnected)
            #expect(g.bridges() == [3])
            #expect(g.hasBridges)
            #expect(g.articulationPoints() == [1])
            let blocks = g.biconnectedComponents()
            #expect(blocks.count == 2)
            #expect(blocks.map(Array.init) == [[0, 2], [3]])
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
            #expect(!g.isBiconnected)
            #expect(g.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2]])
            #expect(!g.isBiEdgeConnected)
            let tree = g.blockCutTree()
            #expect(tree.blocks == blocks)
            #expect(tree.articulationPoints == [1])
            #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1]])
            #expect(tree.edgeCount == 2)
            #expect(g.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, nil, 0, 1])
            #expect(g.vertices.map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1]])
            let nodes: [BlockCutTree<G>.Node?] = [.block(0), .articulationPoint(0), .block(1)]
            #expect(g.vertices.map { tree.node(of: $0) } == nodes)
            #expect(tree.articulationPoints.indices.map { Array(tree.blocks(ofArticulationPoint: $0)) } == [[0, 1]])
        }
        check(ReferencePseudograph(edges: edges))
    }
}
