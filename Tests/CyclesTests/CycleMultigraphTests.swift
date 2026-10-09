// §E: parallel edges and self-loops. A loop is one 1-cycle per loop edge (though an undirected row
// lists it twice), k parallel undirected edges give C(k, 2) 2-cycles, one undirected edge is no
// cycle, opposite arcs are one 2-cycle, and parallel arcs give one cycle per copy; `g.directed`
// reads every edge as two arcs (Boost's undirected count). Graphs written as the catalog writes
// them on the reference conformers, so positions are exact. Expected values come from the
// catalog's reference (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

/// An undirected pseudograph whose incidence rows are not in position order, as on an
/// `UndirectedAdjacencyList` after removals: each row is built in position order (a self-loop
/// twice), then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex and edge
/// indices are positions.
private struct ReorderedPseudograph<Vertex: Hashable>: Graph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.incidentEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Cycles of multigraphs and self-loops")
struct CycleMultigraphTests {
    @Test("CY-400 simpleCycles() is [0]/[0]: NetworkX test_simple_cycles_singleton (nx#1 ig#1)")
    func simpleCycles400() {
        // Once, though the row lists it twice. Boost's undirected Hawick emits it twice (CY-414)
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0]]
        let expectedEdges: [[Int]] = [[0]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-401 simpleCycles(): 2 cycles in order: two loops (nx#1)")
    func simpleCycles401() {
        // Edge identity: two cycles
        // 0-0 0-0
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0]]
        let expectedEdges: [[Int]] = [[0], [1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-402 simpleCycles() is [0,1]/[0,1]: igraph single length-2 loop (ig#1 nx#1)")
    func simpleCycles402() {
        // Canonical: the lesser position leaves 0
        // 0-1 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1]]
        let expectedEdges: [[Int]] = [[0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-403 simpleCycles(): 3 cycles in order: igraph three length-2 loops (ig#3 nx#1)")
    func simpleCycles403() {
        // One per pair of copies: C(3, 2)
        // 0-1 0-1 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1], [0, 1]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2], [1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-404 simpleCycles(): 2 cycles in order: igraph length-2 loop and a self-loop (ig#2)")
    func simpleCycles404() {
        // 0-1 0-1 0-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0]]
        let expectedEdges: [[Int]] = [[0, 1], [2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-405 simpleCycles(): 3 cycles in order: triangle with a doubled side (nx#2)")
    func simpleCycles405() {
        // Each copy gives its own triangle
        // 0-1 0-1 1-2 2-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1, 2], [0, 1, 2]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2, 3], [1, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-406 simpleCycles(): 2 cycles in order: triangle with a loop")
    func simpleCycles406() {
        // C(0,1,2) 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [1]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-407 simpleCycles() is [1,0]/[0,1]: canonical start is by vertices, orientation by position")
    func simpleCycles407() {
        // 1-0 0-1
        let pairs: [(Int, Int)] = [(1, 0), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 0]]
        let expectedEdges: [[Int]] = [[0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-408 simpleCycles(): 2 cycles in order: Boost probe \"doubled 2-cycle\" (bh#2 bhu#1 bt#1 nx#1)")
    func simpleCycles408() {
        // D: 0>1 0>1 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1]]
        let expectedEdges: [[Int]] = [[0, 2], [1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-409 simpleCycles(): 2 cycles in order: two directed loops (nx#1)")
    func simpleCycles409() {
        // D: 0>0 0>0
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0]]
        let expectedEdges: [[Int]] = [[0], [1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-410 simpleCycles(): 4 cycles in order: 2 × 2 antiparallel copies")
    func simpleCycles410() {
        // D: 0>1 1>0 1>0 0>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1], [0, 1], [0, 1]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2], [3, 1], [3, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-411 simpleCycles(): 3 cycles in order: igraph cycle of 4 with a multi-edge, undirected (ig#3 nx#2)")
    func simpleCycles411() {
        // [0..4] 1-2 2-3 2-3 3-4 4-1
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (2, 3), (3, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: 0 ... 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 2, 3, 4], [1, 2, 3, 4], [2, 3]]
        let expectedEdges: [[Int]] = [[0, 1, 3, 4], [0, 2, 3, 4], [1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-412 simpleCycles(): 6 cycles in order: two doubled sides of C₄")
    func simpleCycles412() {
        // 2 × 2 four-cycles and two 2-cycles
        // C(0..3) 0-1 2-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3], [0, 1, 2, 3], [0, 1], [0, 3, 2, 1], [0, 3, 2, 1], [2, 3]
        ]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3], [0, 1, 5, 3], [0, 4], [3, 2, 1, 4], [3, 5, 1, 4], [2, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-413 directed.simpleCycles() emits 1: Boost probe \"U K2\" (bh#1)")
    func directedViewCount413() {
        // In g.directed an edge is two arcs: a 2-cycle
        // 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.directed.simpleCycles()).count == 1)
    }

    @Test("CY-414 directed.simpleCycles() emits 2: Boost probe \"U self-loop\" (bh#2)")
    func directedViewCount414() {
        // g.directed lists a loop's two ends as two arcs
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.directed.simpleCycles()).count == 2)
    }

    @Test("CY-415 directed.simpleCycles() emits 4: Boost probe \"U doubled K2\" (bh#4)")
    func directedViewCount415() {
        // 0-1 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.directed.simpleCycles()).count == 4)
    }

    @Test("CY-416 directed.simpleCycles() emits 5: Boost probe \"U triangle\" (bh#5)")
    func directedViewCount416() {
        // Three digons and both orientations
        // C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.directed.simpleCycles()).count == 5)
    }

    @Test("CY-417 directed.simpleCycles() emits 30: Boost undirected ER(20, 0.1) (bh#30)")
    func directedViewCount417() {
        // Boost's undirected count is our g.directed count
        // [0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.directed.simpleCycles()).count == 30)
    }

    @Test("CY-418 simpleCycles() is [1]/[2]: loop on a vertex in no cycle")
    func simpleCycles418() {
        // P(0,1,2) 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1]]
        let expectedEdges: [[Int]] = [[2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-419 simpleCycles(): 2 cycles in order: bridge with loops at both ends")
    func simpleCycles419() {
        // 0-0 0-1 1-1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [1]]
        let expectedEdges: [[Int]] = [[0], [2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-420 simpleCycles(): 3 cycles in order: NetworkX test_chordless_cycles_multigraph_self_loops graph (nx#3)")
    func simpleCycles420() {
        // 1-1 2-2 1-2 1-2
        let pairs: [(Int, Int)] = [(1, 1), (2, 2), (1, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1], [1, 2], [2]]
        let expectedEdges: [[Int]] = [[0], [2, 3], [1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-421 simpleCycles(): 6 cycles in order: the same plus a doubled pendant")
    func simpleCycles421() {
        // 1-1 2-2 1-2 1-2 2-3 3-4 3-4 1-3
        let pairs: [(Int, Int)] = [(1, 1), (2, 2), (1, 2), (1, 2), (2, 3), (3, 4), (3, 4), (1, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1], [1, 2], [1, 2, 3], [1, 2, 3], [2], [3, 4]]
        let expectedEdges: [[Int]] = [[0], [2, 3], [2, 4, 7], [3, 4, 7], [1], [5, 6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-422 simpleCycles(): 3 cycles in order: rows reversed: orientation still by position")
    func simpleCycles422() {
        // 0-1 0-1 1-2 2-0 ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0)]
        let graph = ReorderedPseudograph(vertices: 0 ... 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .reversed)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 1, 2], [0, 1]]
        let expectedEdges: [[Int]] = [[1, 2, 3], [0, 2, 3], [0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-423 simpleCycles(): 3 cycles in order: .undirected of D: 0>1 1>0 1>0")
    func simpleCycles423() {
        // 0-1 1-0 1-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1], [0, 1]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2], [1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }
}
