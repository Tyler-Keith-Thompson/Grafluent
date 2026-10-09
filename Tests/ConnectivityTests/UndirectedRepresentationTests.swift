// §H: the same answers on every representation. Every test in §A – §G already runs on the
// ReferencePseudograph (CN-340) and, when no edge repeats, on an UndirectedAdjacencyList built in
// the same order (CN-341); this file adds the rows whose repeats collapse, AdjacencyList and
// AdjacencyMatrix read through `.undirected` (positions are arcs, or cells without edge indices),
// two conformers private to this file (no indices; vertex indices only), an adjacency list after
// removals, and vertices whose hashes all collide. Expected values come from the catalog's
// reference. Case IDs (CN-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

/// An undirected pseudograph with no vertex or edge indices, so the algorithms number the vertices
/// through a dictionary and key blocks by position. A self-loop is listed twice at its vertex.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// Vertex indices (the positions in `vertices`) but no edge indices, so parent edges are compared
/// as positions and blocks are keyed by `Edges.Index`.
private struct VertexIndexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Vertex { vertices[index] }
}

@Suite("Undirected connectivity on every representation")
struct UndirectedRepresentationTests {
    @Test("CN-341 rows with repeated edges collapse on UndirectedAdjacencyList: the values of the collapsed graph")
    func collapsedRows() {
        // Each row: the written edges, then the reference's values for the graph with every repeat
        // (in either orientation, a repeated loop included) dropped after its first copy. Positions
        // are those of the collapsed graph, and the vertices order is unchanged.
        let rows: [(String, [Int], [(Int, Int)], [Int], [Int], [[Int]], [[Int]], Bool, Bool)] = [
            ("CN-217", [0, 1, 2, 3, 4, 5], [(0, 2), (2, 1), (1, 0), (3, 1), (3, 2), (4, 5), (5, 4)], [5], [], [[0, 1, 2, 3, 4], [5]], [[0, 1, 2, 3], [4], [5]], false, false),
            ("CN-218", [0, 1, 2, 3, 4, 5, 6, 7], [(0, 1), (4, 0), (1, 7), (7, 4), (5, 3), (3, 5), (1, 4), (0, 7), (5, 6), (6, 5)], [4, 7], [5], [[0, 1, 2, 3, 5, 6], [4], [7]], [[0, 1, 4, 7], [2], [3], [5], [6]], false, false),
            ("CN-219", [0, 1, 2, 3, 4, 5, 6, 7], [(0, 1), (4, 0), (1, 7), (7, 4), (5, 3), (3, 5), (1, 4), (0, 7), (5, 6), (6, 5), (2, 0), (2, 4), (2, 7), (7, 5), (7, 6)], [4], [5, 7], [[0, 1, 2, 3, 5, 6, 8, 9, 10], [4], [7, 11, 12]], [[0, 1, 2, 4, 5, 6, 7], [3]], false, false),
            ("CN-222", [0, 1, 2, 3, 4], [(0, 1), (0, 2), (1, 2), (1, 2), (2, 3), (3, 4), (3, 4)], [3, 4], [2, 3], [[0, 1, 2], [3], [4]], [[0, 1, 2], [3], [4]], false, false),
            ("CN-223", [0, 1, 2, 3, 4], [(0, 1), (0, 2), (1, 2), (1, 2), (2, 3), (3, 4), (3, 4), (0, 1), (0, 2), (2, 3)], [3, 4], [2, 3], [[0, 1, 2], [3], [4]], [[0, 1, 2], [3], [4]], false, false),
            ("CN-227", [0, 1, 2], [(0, 1), (0, 1), (1, 2), (2, 2)], [0, 1], [1], [[0], [1]], [[0], [1], [2]], false, false),
            ("CN-244", [0, 1, 2], [(0, 1), (1, 1), (1, 2), (1, 2)], [0, 2], [1], [[0], [2]], [[0], [1], [2]], false, false),
            ("CN-245", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], [(1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14), (1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14)], [4, 5, 6, 7, 9], [4, 5, 6, 7, 9], [[0, 1, 2, 3], [4], [5], [6], [7], [8, 10, 11, 12, 13, 14, 15], [9]], [[1, 2, 3, 4], [5], [6], [7, 9, 11, 12, 13, 14], [8], [10]], false, false),
            ("CN-278", [0, 1, 2, 3, 4, 5, 6, 7], [(0, 1), (4, 0), (1, 7), (7, 4), (5, 3), (3, 5), (1, 4), (0, 7), (5, 6), (6, 5)], [4, 7], [5], [[0, 1, 2, 3, 5, 6], [4], [7]], [[0, 1, 4, 7], [2], [3], [5], [6]], false, false),
            ("CN-279", [0, 1, 2, 3, 4, 5], [(0, 2), (2, 1), (1, 0), (3, 1), (3, 2), (4, 5), (5, 4)], [5], [], [[0, 1, 2, 3, 4], [5]], [[0, 1, 2, 3], [4], [5]], false, false),
            ("CN-281", [0, 1], [(0, 1), (0, 1)], [0], [], [[0]], [[0], [1]], true, false),
            ("CN-282", [0, 1], [(0, 1), (0, 1), (0, 1)], [0], [], [[0]], [[0], [1]], true, false),
            ("CN-283", [0, 1, 2], [(0, 1), (1, 2), (1, 2)], [0, 1], [1], [[0], [1]], [[0], [1], [2]], false, false),
            ("CN-288", [0, 1, 2, 3], [(0, 1), (0, 2), (2, 0), (0, 0), (1, 2), (1, 0), (0, 3)], [4], [0], [[0, 1, 3], [4]], [[0, 1, 2], [3]], false, false),
            ("CN-289", [0, 1], [(0, 0), (0, 0), (1, 1)], [], [], [], [[0], [1]], false, false),
            ("CN-290", [0, 1, 2, 3], [(0, 1), (1, 2), (1, 2), (2, 3)], [0, 1, 2], [1, 2], [[0], [1], [2]], [[0], [1], [2], [3]], false, false),
            ("CN-291", [0, 1, 2, 3], [(0, 1), (1, 2), (1, 3), (0, 1)], [0, 1, 2], [1], [[0], [1], [2]], [[0], [1], [2], [3]], false, false),
            ("CN-292", [0, 1, 2, 3], [(0, 1), (0, 2), (2, 3), (1, 0)], [0, 1, 2], [0, 2], [[0], [1], [2]], [[0], [1], [2], [3]], false, false),
            ("CN-295", [0, 1], [(0, 0), (0, 1), (0, 0), (1, 0)], [1], [], [[1]], [[0], [1]], true, false),
            ("CN-296", [0, 1, 2], [(0, 1), (1, 0), (1, 2)], [0, 1], [1], [[0], [1]], [[0], [1], [2]], false, false),
            ("CN-299", [0, 1, 2], [(0, 1), (1, 1), (1, 0), (1, 2)], [0, 2], [1], [[0], [2]], [[0], [1], [2]], false, false),
            ("CN-334", [0, 1, 2, 3], [(0, 1), (0, 1), (2, 3)], [0, 1], [], [[0], [1]], [[0], [1], [2], [3]], false, false),
            ("CN-335", [0, 1, 2, 3, 4, 5], [(0, 3), (1, 4), (2, 5), (3, 0)], [0, 1, 2], [], [[0], [1], [2]], [[0], [1], [2], [3], [4], [5]], false, false),
        ]
        for (id, vertices, pairs, bridges, points, blocks, twoEdge, biconnected, biEdgeConnected) in rows {
            let graph = UndirectedAdjacencyList(vertices: vertices, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(Array(graph.vertices) == vertices, "\(id)")
            #expect(graph.edgeCount == Set(pairs.map { UndirectedEdge($0.0, $0.1) }).count, "\(id)")
            #expect(graph.bridges() == bridges, "\(id)")
            #expect(graph.hasBridges == !bridges.isEmpty, "\(id)")
            #expect(graph.articulationPoints() == points, "\(id)")
            #expect(graph.biconnectedComponents().map(Array.init) == blocks, "\(id)")
            #expect(graph.biEdgeConnectedComponents().map(Array.init) == twoEdge, "\(id)")
            #expect(graph.isBiconnected == biconnected, "\(id)")
            #expect(graph.isBiEdgeConnected == biEdgeConnected, "\(id)")
            #expect(graph.blockCutTree().blocks == graph.biconnectedComponents(), "\(id)")
        }
    }

    @Test("CN-342 UndirectedAdjacencyList of CN-222: the repeats collapse, so 3–4 becomes a bridge")
    func collapsedMultiedgeBridge() {
        let pairs = [(0, 1), (0, 2), (1, 2), (1, 2), (2, 3), (3, 4), (3, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [2, 3], [3, 4]])
        #expect(graph.connectedComponents().map(Array.init) == [[0, 1, 2, 3, 4]])
        #expect(graph.isConnected)
        #expect(graph.bridges() == [3, 4])
        #expect(graph.articulationPoints() == [2, 3])
        let blocks = graph.biconnectedComponents()
        #expect(blocks.map(Array.init) == [[0, 1, 2], [3], [4]])
        #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1, 2], [2, 3], [3, 4]])
        #expect(!graph.isBiconnected)
        #expect(graph.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2], [3], [4]])
        #expect(!graph.isBiEdgeConnected)
        let tree = graph.blockCutTree()
        #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[2], [2, 3], [3]])
        // The pseudograph keeps the copies: 3–4 is doubled, so only 2–3 is a bridge (CN-222).
        let pseudograph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(pseudograph.bridges() == [4])
    }

    @Test("CN-343 AdjacencyList.undirected: one arc per edge is CN-238 exactly, both arcs are CN-297")
    func adjacencyListUndirected() {
        // K(0..7) P(7..12) K(12..19) P(7,20,21,22) C(22,23,24,25), each edge one arc in written order.
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 7 { for v in u + 1 ... 7 { pairs.append((u, v)) } }
        for i in 7 ..< 12 { pairs.append((i, i + 1)) }
        for u in 12 ..< 19 { for v in u + 1 ... 19 { pairs.append((u, v)) } }
        pairs += [(7, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 22)]
        #expect(pairs.count == 68)
        let once = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(once.edgeCount == 68)
        #expect(once.connectedComponents().map(Array.init) == [Array(0 ... 25)])
        #expect(once.bridges() == [28, 29, 30, 31, 32, 61, 62, 63])
        #expect(once.articulationPoints() == [7, 8, 9, 10, 11, 12, 20, 21, 22])
        let onceBlocks = once.biconnectedComponents()
        let expectedOnce: [[Int]] = [Array(0 ... 27), [28], [29], [30], [31], [32], Array(33 ... 60), [61], [62], [63], [64, 65, 66, 67]]
        #expect(onceBlocks.map(Array.init) == expectedOnce)
        let blockVertices: [[Int]] = [Array(0 ... 7), [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], Array(12 ... 19), [7, 20], [20, 21], [21, 22], [22, 23, 24, 25]]
        #expect(onceBlocks.indices.map { Array(onceBlocks.vertices(ofComponentAt: $0)) } == blockVertices)
        let twoEdgeOnce: [[Int]] = [Array(0 ... 7), [8], [9], [10], [11], Array(12 ... 19), [20], [21], [22, 23, 24, 25]]
        #expect(once.biEdgeConnectedComponents().map(Array.init) == twoEdgeOnce)
        #expect(!once.isBiconnected && !once.isBiEdgeConnected)

        // Every forward arc, then every reverse arc: positions 68 ..< 136 repeat 0 ..< 68.
        let both = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) } + pairs.map { DirectedEdge(from: $0.1, to: $0.0) }).undirected
        #expect(both.edgeCount == 136)
        #expect(both.bridges().isEmpty)
        #expect(!both.hasBridges)
        #expect(both.articulationPoints() == [7, 8, 9, 10, 11, 12, 20, 21, 22])
        let bothBlocks = both.biconnectedComponents()
        #expect(bothBlocks.map(Array.init) == expectedOnce.map { $0 + $0.map { $0 + 68 } })
        #expect(bothBlocks.indices.map { Array(bothBlocks.vertices(ofComponentAt: $0)) } == blockVertices)
        #expect(both.biEdgeConnectedComponents().map(Array.init) == [Array(0 ... 25)])
        #expect(!both.isBiconnected)
        #expect(both.isBiEdgeConnected)
        let tree = both.blockCutTree()
        #expect(bothBlocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[7], [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], [12], [7, 20], [20, 21], [21, 22], [22]])
    }

    @Test("CN-344 AdjacencyMatrix.undirected with cells u < v: vertex indices, no edge indices, positions are cells")
    func matrixUpperCells() {
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: [(0, 1), (1, 2), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(matrix.vertexIndexBound == 4 && matrix.edgeIndexBound == nil)
        #expect(matrix.connectedComponents().map(Array.init) == [[0, 1, 2, 3]])
        #expect(matrix.isConnected)
        #expect(matrix.bridges().map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3]])
        #expect(matrix.hasBridges)
        #expect(matrix.articulationPoints() == [1, 2])
        let blocks = matrix.biconnectedComponents()
        #expect(blocks.map { $0.map { [$0.source, $0.target] } } == [[[0, 1]], [[1, 2]], [[2, 3]]])
        #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2], [2, 3]])
        // Keyed by cell.
        #expect(matrix.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 1, 2])
        #expect((0 ..< 4).map { Array(blocks.components(containing: $0)) } == [[0], [0, 1], [1, 2], [2]])
        #expect(!matrix.isBiconnected)
        #expect(matrix.biEdgeConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
        #expect(!matrix.isBiEdgeConnected)
        let tree = matrix.blockCutTree()
        #expect(blocks.indices.map { tree.articulationPoints(ofBlock: $0).map { tree.articulationPoints[$0] } } == [[1], [1, 2], [2]])
        #expect(tree.edgeCount == 4)
    }

    @Test("CN-345 AdjacencyMatrix.undirected of a symmetric matrix: both cells are edges, so no bridges")
    func matrixSymmetricCells() {
        // Cells (0,1) < (1,0) < (1,2) < (2,1): the graph 0-1 1-0 1-2 2-1.
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [(0, 1), (1, 0), (1, 2), (2, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(matrix.edgeCount == 4)
        #expect(matrix.connectedComponents().map(Array.init) == [[0, 1, 2]])
        #expect(matrix.bridges().isEmpty)
        #expect(!matrix.hasBridges)
        #expect(matrix.articulationPoints() == [1])
        let blocks = matrix.biconnectedComponents()
        #expect(blocks.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [1, 0]], [[1, 2], [2, 1]]])
        #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == [[0, 1], [1, 2]])
        #expect(matrix.edges.indices.map { blocks.component(ofEdgeAt: $0) } == [0, 0, 1, 1])
        #expect(!matrix.isBiconnected)
        #expect(matrix.biEdgeConnectedComponents().map(Array.init) == [[0, 1, 2]])
        #expect(matrix.isBiEdgeConnected)
        let tree = matrix.blockCutTree()
        #expect(tree.articulationPoints == [1])
        #expect(Array(tree.blocks(ofArticulationPoint: 0)) == [0, 1])
    }

    @Test("CN-346 a conformer without indices, String vertices: CN-236, CN-252 and CN-294 exactly")
    func plainGraphStrings() {
        // CN-236: C(A,B,C) C(C,D,E) C(F,I,J,H,G) G-I J-G E-G.
        let pairs236 = [("A", "B"), ("B", "C"), ("C", "A"), ("C", "D"), ("D", "E"), ("E", "C"), ("F", "I"), ("I", "J"), ("J", "H"), ("H", "G"), ("G", "F"), ("G", "I"), ("J", "G"), ("E", "G")]
        let reference236 = ReferencePseudograph(edges: pairs236.map { UndirectedEdge($0.0, $0.1) })
        let plain236 = PlainGraph(vertices: reference236.vertices, edges: reference236.edges)
        #expect(plain236.vertexIndexBound == nil && plain236.edgeIndexBound == nil)
        #expect(plain236.connectedComponents().map(Array.init) == [["A", "B", "C", "D", "E", "F", "I", "J", "H", "G"]])
        #expect(plain236.isConnected)
        #expect(plain236.bridges() == [13])
        #expect(plain236.articulationPoints() == ["C", "E", "G"])
        let blocks236 = plain236.biconnectedComponents()
        #expect(blocks236.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6, 7, 8, 9, 10, 11, 12], [13]])
        #expect(blocks236.indices.map { Array(blocks236.vertices(ofComponentAt: $0)) } == [["A", "B", "C"], ["C", "D", "E"], ["F", "I", "J", "H", "G"], ["E", "G"]])
        #expect(Array(blocks236.components(containing: "E")) == [1, 3])
        #expect(blocks236.component(ofEdgeAt: 13) == 3)
        #expect(plain236.biEdgeConnectedComponents().map(Array.init) == [["A", "B", "C", "D", "E"], ["F", "I", "J", "H", "G"]])
        #expect(!plain236.isBiconnected && !plain236.isBiEdgeConnected)
        let tree236 = plain236.blockCutTree()
        #expect(tree236.articulationPoints == ["C", "E", "G"])
        #expect(tree236.node(of: "E") == .articulationPoint(1))
        #expect(tree236.node(of: "A") == .block(0))
        #expect(blocks236.indices.map { tree236.articulationPoints(ofBlock: $0).map { tree236.articulationPoints[$0] } } == [["C"], ["C", "E"], ["G"], ["E", "G"]])

        // CN-252: A-B B-C D-E E-F.
        let pairs252 = [("A", "B"), ("B", "C"), ("D", "E"), ("E", "F")]
        let plain252 = PlainGraph(vertices: ["A", "B", "C", "D", "E", "F"], edges: pairs252.map { UndirectedEdge($0.0, $0.1) })
        #expect(plain252.connectedComponents().map(Array.init) == [["A", "B", "C"], ["D", "E", "F"]])
        #expect(!plain252.isConnected)
        #expect(plain252.bridges() == [0, 1, 2, 3])
        #expect(plain252.articulationPoints() == ["B", "E"])
        #expect(plain252.biconnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
        #expect(plain252.biEdgeConnectedComponents().map(Array.init) == [["A"], ["B"], ["C"], ["D"], ["E"], ["F"]])
        #expect(plain252.blockCutTree().edgeCount == 4)

        // CN-294: petgraph's undirected graph with doubled edges and a loop at a.
        let fixture = UndirectedFixture<String>.petgraphUndirected
        let reference294 = ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)
        let plain294 = PlainGraph(vertices: reference294.vertices, edges: reference294.edges)
        #expect(plain294.vertices == ["a", "b", "c", "d"])
        #expect(plain294.bridges() == [6])
        #expect(plain294.articulationPoints() == ["a"])
        let blocks294 = plain294.biconnectedComponents()
        #expect(blocks294.map(Array.init) == [[0, 1, 2, 4, 5], [6]])
        #expect(blocks294.indices.map { Array(blocks294.vertices(ofComponentAt: $0)) } == [["a", "b", "c"], ["a", "d"]])
        #expect(plain294.edges.indices.map { blocks294.component(ofEdgeAt: $0) } == [0, 0, 0, nil, 0, 0, 1])
        #expect(plain294.biEdgeConnectedComponents().map(Array.init) == [["a", "b", "c"], ["d"]])
        #expect(!plain294.isBiconnected && !plain294.isBiEdgeConnected)
    }

    @Test("CN-346 a conformer without indices agrees with the ReferencePseudograph: CN-244 and CN-288")
    func plainGraphAgrees() {
        // CN-244: [0..2] 0-1 1-1 1-2 1-2; CN-288: the petgraphUndirected fixture.
        let fixture = UndirectedFixture<Int>.petgraphUndirected
        let graphs = [
            ReferencePseudograph(vertices: 0 ... 2, edges: [(0, 1), (1, 1), (1, 2), (1, 2)].map { UndirectedEdge($0.0, $0.1) }),
            ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges),
        ]
        for reference in graphs {
            let plain = PlainGraph(vertices: reference.vertices, edges: reference.edges)
            #expect(plain.connectedComponents().map(Array.init) == reference.connectedComponents().map(Array.init))
            #expect(plain.isConnected == reference.isConnected)
            #expect(plain.bridges() == reference.bridges())
            #expect(plain.hasBridges == reference.hasBridges)
            #expect(plain.articulationPoints() == reference.articulationPoints())
            let blocks = plain.biconnectedComponents()
            let expected = reference.biconnectedComponents()
            #expect(blocks.map(Array.init) == expected.map(Array.init))
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected.indices.map { Array(expected.vertices(ofComponentAt: $0)) })
            #expect(plain.edges.indices.map { blocks.component(ofEdgeAt: $0) } == reference.edges.indices.map { expected.component(ofEdgeAt: $0) })
            #expect(plain.vertices.map { Array(blocks.components(containing: $0)) } == reference.vertices.map { Array(expected.components(containing: $0)) })
            #expect(plain.isBiconnected == reference.isBiconnected)
            #expect(plain.biEdgeConnectedComponents().map(Array.init) == reference.biEdgeConnectedComponents().map(Array.init))
            #expect(plain.isBiEdgeConnected == reference.isBiEdgeConnected)
            let tree = plain.blockCutTree()
            let expectedTree = reference.blockCutTree()
            #expect(tree.articulationPoints == expectedTree.articulationPoints)
            #expect(tree.edgeCount == expectedTree.edgeCount)
            // The two trees' Node types differ (they name the graph), so compare spelled out.
            func spelled<H: Graph>(_ node: BlockCutTree<H>.Node?) -> String {
                switch node {
                case .block(let b)?: "block \(b)"
                case .articulationPoint(let a)?: "point \(a)"
                case nil: "none"
                }
            }
            #expect(plain.vertices.map { spelled(tree.node(of: $0)) } == reference.vertices.map { spelled(expectedTree.node(of: $0)) })
        }
        // The exact values of CN-244.
        let multi = PlainGraph(vertices: [0, 1, 2], edges: [(0, 1), (1, 1), (1, 2), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(multi.bridges() == [0])
        #expect(multi.articulationPoints() == [1])
        #expect(multi.biconnectedComponents().map(Array.init) == [[0], [2, 3]])
        #expect(multi.biEdgeConnectedComponents().map(Array.init) == [[0], [1, 2]])
    }

    @Test("CN-347 a conformer with vertex indices only: CN-243, CN-245, CN-291 and CN-292 exactly")
    func vertexIndexedGraph() {
        // CN-243: JGraphT's testWikiGraph.
        let wiki = [(1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14)]
        let once = VertexIndexedGraph(vertices: Array(1 ... 14), edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        #expect(once.vertexIndexBound == 14 && once.edgeIndexBound == nil)
        #expect(once.connectedComponents().map(Array.init) == [Array(1 ... 14)])
        #expect(once.bridges() == [4, 5, 6, 7, 9])
        #expect(once.articulationPoints() == [4, 5, 6, 7, 9])
        let onceBlocks = once.biconnectedComponents()
        #expect(onceBlocks.map(Array.init) == [[0, 1, 2, 3], [4], [5], [6], [7], [8, 10, 11, 12, 13, 14, 15], [9]])
        #expect(onceBlocks.indices.map { Array(onceBlocks.vertices(ofComponentAt: $0)) } == [[1, 2, 3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [7, 9, 11, 12, 13, 14], [9, 10]])
        // JGraphT's getBlocks(7): three blocks.
        #expect(Array(onceBlocks.components(containing: 7)) == [3, 4, 5])
        #expect(once.biEdgeConnectedComponents().map(Array.init) == [[1, 2, 3, 4], [5], [6], [7, 9, 11, 12, 13, 14], [8], [10]])
        let onceTree = once.blockCutTree()
        #expect(onceBlocks.indices.map { onceTree.articulationPoints(ofBlock: $0).map { onceTree.articulationPoints[$0] } } == [[4], [4, 5], [5, 6], [6, 7], [7], [7, 9], [9]])

        // CN-245: every edge written twice.
        let twice = VertexIndexedGraph(vertices: Array(1 ... 14), edges: (wiki + wiki).map { UndirectedEdge($0.0, $0.1) })
        #expect(twice.bridges().isEmpty)
        #expect(twice.articulationPoints() == [4, 5, 6, 7, 9])
        #expect(twice.biconnectedComponents().map(Array.init) == [[0, 1, 2, 3, 16, 17, 18, 19], [4, 20], [5, 21], [6, 22], [7, 23], [8, 10, 11, 12, 13, 14, 15, 24, 26, 27, 28, 29, 30, 31], [9, 25]])
        #expect(twice.biEdgeConnectedComponents().map(Array.init) == [Array(1 ... 14)])
        #expect(twice.isBiEdgeConnected && !twice.isBiconnected)

        // CN-291 and CN-292: the parallel copy of a tree edge is a back edge to the parent.
        let far = VertexIndexedGraph(vertices: [0, 1, 2, 3], edges: [(0, 1), (1, 2), (1, 3), (0, 1)].map { UndirectedEdge($0.0, $0.1) })
        #expect(far.bridges() == [1, 2])
        #expect(far.articulationPoints() == [1])
        #expect(far.biconnectedComponents().map(Array.init) == [[0, 3], [1], [2]])
        #expect(far.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2], [3]])
        let last = VertexIndexedGraph(vertices: [0, 1, 2, 3], edges: [(0, 1), (0, 2), (2, 3), (1, 0)].map { UndirectedEdge($0.0, $0.1) })
        #expect(last.bridges() == [1, 2])
        #expect(last.articulationPoints() == [0, 2])
        #expect(last.biconnectedComponents().map(Array.init) == [[0, 3], [1], [2]])
        #expect(last.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2], [3]])
        #expect(Array(last.blockCutTree().blocks(ofArticulationPoint: 0)) == [0, 1])
    }

    @Test("CN-348 UndirectedAdjacencyList after removals, exactly, against a pseudograph written in its own order")
    func afterRemovals() {
        // CN-235's graph, then a vertex and two edges removed: slots and positions move.
        let pairs = [(0, 1), (0, 5), (0, 6), (0, 14), (1, 5), (1, 6), (1, 14), (2, 4), (2, 10), (3, 4), (3, 15), (4, 6), (4, 7), (4, 10), (5, 14), (6, 14), (7, 9), (8, 9), (8, 12), (8, 13), (10, 15), (11, 12), (11, 13), (12, 13)]
        var list = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        list.remove(10)
        list.remove(edge: UndirectedEdge(0, 1))
        list.remove(edge: UndirectedEdge(12, 11))
        list.insert(edge: UndirectedEdge(15, 2))
        list.insert(20)
        let reference = ReferencePseudograph(vertices: Array(list.vertices), edges: Array(list.edges))
        #expect(reference.vertices == Array(list.vertices))
        #expect(reference.edges == Array(list.edges))
        #expect(list.connectedComponents().map(Array.init) == reference.connectedComponents().map(Array.init))
        #expect(list.isConnected == reference.isConnected)
        #expect(list.bridges() == reference.bridges())
        #expect(list.articulationPoints() == reference.articulationPoints())
        let blocks = list.biconnectedComponents()
        let expected = reference.biconnectedComponents()
        #expect(blocks.map(Array.init) == expected.map(Array.init))
        #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected.indices.map { Array(expected.vertices(ofComponentAt: $0)) })
        #expect(list.edges.indices.map { blocks.component(ofEdgeAt: $0) } == reference.edges.indices.map { expected.component(ofEdgeAt: $0) })
        #expect(list.vertices.map { Array(blocks.components(containing: $0)) } == reference.vertices.map { Array(expected.components(containing: $0)) })
        #expect(list.isBiconnected == reference.isBiconnected)
        #expect(list.biEdgeConnectedComponents().map(Array.init) == reference.biEdgeConnectedComponents().map(Array.init))
        #expect(list.isBiEdgeConnected == reference.isBiEdgeConnected)
        let tree = list.blockCutTree()
        let expectedTree = reference.blockCutTree()
        #expect(tree.articulationPoints == expectedTree.articulationPoints)
        #expect(tree.edgeCount == expectedTree.edgeCount)
        #expect(tree.blocks.indices.map { Array(tree.articulationPoints(ofBlock: $0)) } == expectedTree.blocks.indices.map { Array(expectedTree.articulationPoints(ofBlock: $0)) })
        // The removals leave something to find: 20 is isolated and some vertex still separates.
        #expect(list.connectedComponents().count >= 2)
        #expect(!list.articulationPoints().isEmpty)
    }

    @Test("CN-349 Collider vertices, every hash equal, on CN-243: the same answers")
    func colliders() {
        let wiki = [(1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14)]
        let edges = wiki.map { UndirectedEdge(Collider($0.0), Collider($0.1)) }
        func check<G: Graph<Collider>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.connectedComponents().map { $0.map(\.value) } == [Array(1 ... 14)])
            #expect(g.bridges() == [4, 5, 6, 7, 9])
            #expect(g.articulationPoints().map(\.value) == [4, 5, 6, 7, 9])
            let blocks = g.biconnectedComponents()
            #expect(blocks.map(Array.init) == [[0, 1, 2, 3], [4], [5], [6], [7], [8, 10, 11, 12, 13, 14, 15], [9]])
            #expect(blocks.indices.map { blocks.vertices(ofComponentAt: $0).map(\.value) } == [[1, 2, 3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [7, 9, 11, 12, 13, 14], [9, 10]])
            #expect(Array(blocks.components(containing: Collider(7))) == [3, 4, 5])
            #expect(g.biEdgeConnectedComponents().map { $0.map(\.value) } == [[1, 2, 3, 4], [5], [6], [7, 9, 11, 12, 13, 14], [8], [10]])
            let tree = g.blockCutTree()
            #expect(tree.node(of: Collider(7)) == .articulationPoint(3))
            #expect(tree.node(of: Collider(1)) == .block(0))
            #expect(Array(tree.blocks(ofArticulationPoint: 3)) == [3, 4, 5])
        }
        check(ReferencePseudograph(vertices: (1 ... 14).map { Collider($0) }, edges: edges))
        check(UndirectedAdjacencyList(vertices: (1 ... 14).map { Collider($0) }, edges: edges))
    }
}
