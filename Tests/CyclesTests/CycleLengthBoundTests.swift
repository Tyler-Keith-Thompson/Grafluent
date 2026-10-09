// §F: `simpleCycles(maxLength:)`, directed and undirected. The bound counts edges: 0 gives
// nothing, 1 the loops, 2 adds 2-cycles; the result is the unbounded sequence filtered to
// `length <= maxLength`, in the same order. Cases from NetworkX, igraph, Boost (`max_length`) and
// JGraphT (`setPathLimit`), plus the planted bounded-search mistake CY-491. Graphs written as the
// catalog writes them, so positions are exact. Expected values come from the catalog's reference
// (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md.

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

@Suite("Simple cycles with a length bound")
struct CycleLengthBoundTests {
    @Test("CY-450 simpleCycles(maxLength: 0) emits 0: NetworkX test_simple_cycles_bound_corner_cases")
    func boundedCount450() {
        // C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 0)).count == 0)
    }

    @Test("CY-451 simpleCycles(maxLength: 0) emits 0: NetworkX corner cases")
    func boundedCount451() {
        // D: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 0)).count == 0)
    }

    @Test("CY-452 simpleCycles(maxLength: 1): 2 cycles in order: NetworkX example, bound 1")
    func boundedSimpleCycles452() {
        // D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 1))
        let expectedVertices: [[Int]] = [[0], [2]]
        let expectedEdges: [[Int]] = [[0], [6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-453 simpleCycles(maxLength: 2): 4 cycles in order: NetworkX example, bound 2")
    func boundedSimpleCycles453() {
        // D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 2))
        let expectedVertices: [[Int]] = [[0], [0, 2], [1, 2], [2]]
        let expectedEdges: [[Int]] = [[0], [2, 4], [3, 5], [6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-454 simpleCycles(maxLength: 0) emits 0: NetworkX test_simple_cycles_bounded nested directed cycles, bound 0")
    func boundedCount454() {
        // One cycle of every length 1 … 9
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 0)).count == 0)
    }

    @Test("CY-455 simpleCycles(maxLength: 1) emits 1: bound 1")
    func boundedCount455() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 1)).count == 1)
    }

    @Test("CY-456 simpleCycles(maxLength: 2) emits 2: bound 2")
    func boundedCount456() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).count == 2)
    }

    @Test("CY-457 simpleCycles(maxLength: 5): 5 cycles in order: bound 5")
    func boundedSimpleCycles457() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 5))
        let expectedVertices: [[Int]] = [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4]]
        let expectedEdges: [[Int]] = [[0], [1, 2], [1, 3, 4], [1, 3, 5, 6], [1, 3, 5, 7, 8]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-458 simpleCycles(maxLength: 8) emits 8: bound 8")
    func boundedCount458() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 8)).count == 8)
    }

    @Test("CY-459 simpleCycles(maxLength: 9) emits 9: bound 9")
    func boundedCount459() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 9)).count == 9)
    }

    @Test("CY-460 simpleCycles(maxLength: 1) emits 1: NetworkX disjoint undirected cycles, bound 1")
    func boundedCount460() {
        // "one cycle of every length except 2"
        // 0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42
        let pairs: [(Int, Int)] = [
            (0, 0), (1, 2), (1, 3), (2, 3), (4, 5), (4, 7), (5, 6), (6, 7), (8, 9), (8, 12), (9, 10),
            (10, 11), (11, 12), (13, 14), (13, 18), (14, 15), (15, 16), (16, 17), (17, 18), (19, 20),
            (19, 25), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (26, 27), (26, 33), (27, 28),
            (28, 29), (29, 30), (30, 31), (31, 32), (32, 33), (34, 35), (34, 42), (35, 36), (36, 37),
            (37, 38), (38, 39), (39, 40), (40, 41), (41, 42)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 1)).count == 1)
    }

    @Test("CY-461 simpleCycles(maxLength: 2) emits 1: bound 2")
    func boundedCount461() {
        // 0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42
        let pairs: [(Int, Int)] = [
            (0, 0), (1, 2), (1, 3), (2, 3), (4, 5), (4, 7), (5, 6), (6, 7), (8, 9), (8, 12), (9, 10),
            (10, 11), (11, 12), (13, 14), (13, 18), (14, 15), (15, 16), (16, 17), (17, 18), (19, 20),
            (19, 25), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (26, 27), (26, 33), (27, 28),
            (28, 29), (29, 30), (30, 31), (31, 32), (32, 33), (34, 35), (34, 42), (35, 36), (36, 37),
            (37, 38), (38, 39), (39, 40), (40, 41), (41, 42)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).count == 1)
    }

    @Test("CY-462 simpleCycles(maxLength: 3) emits 2: bound 3")
    func boundedCount462() {
        // 0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42
        let pairs: [(Int, Int)] = [
            (0, 0), (1, 2), (1, 3), (2, 3), (4, 5), (4, 7), (5, 6), (6, 7), (8, 9), (8, 12), (9, 10),
            (10, 11), (11, 12), (13, 14), (13, 18), (14, 15), (15, 16), (16, 17), (17, 18), (19, 20),
            (19, 25), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (26, 27), (26, 33), (27, 28),
            (28, 29), (29, 30), (30, 31), (31, 32), (32, 33), (34, 35), (34, 42), (35, 36), (36, 37),
            (37, 38), (38, 39), (39, 40), (40, 41), (41, 42)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 2)
    }

    @Test("CY-463 simpleCycles(maxLength: 9) emits 8: bound 9")
    func boundedCount463() {
        // 0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42
        let pairs: [(Int, Int)] = [
            (0, 0), (1, 2), (1, 3), (2, 3), (4, 5), (4, 7), (5, 6), (6, 7), (8, 9), (8, 12), (9, 10),
            (10, 11), (11, 12), (13, 14), (13, 18), (14, 15), (15, 16), (16, 17), (17, 18), (19, 20),
            (19, 25), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (26, 27), (26, 33), (27, 28),
            (28, 29), (29, 30), (30, 31), (31, 32), (32, 33), (34, 35), (34, 42), (35, 36), (36, 37),
            (37, 38), (38, 39), (39, 40), (40, 41), (41, 42)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 9)).count == 8)
    }

    @Test("CY-464 simpleCycles(maxLength: 3) emits 9: igraph wheel of 10, bound 3 (ig#9)")
    func boundedCount464() {
        // W(0;1..9)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 2), (2, 3),
            (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 1)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 9)
    }

    @Test("CY-465 simpleCycles(maxLength: 4) emits 18: igraph wheel of 10, bound 4 (ig#18)")
    func boundedCount465() {
        // W(0;1..9)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 2), (2, 3),
            (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 1)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 18)
    }

    @Test("CY-466 simpleCycles(maxLength: 4) emits 2: igraph cycle of 4 with a multi-edge, directed, bound 4 (ig#2)")
    func boundedCount466() {
        // D: [0..4] 1>2 2>3 2>3 3>4 4>1
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (2, 3), (3, 4), (4, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 2)
    }

    @Test("CY-467 simpleCycles(maxLength: 4) emits 3: igraph the same, undirected, bound 4 (ig#3)")
    func boundedCount467() {
        // [0..4] 1-2 2-3 2-3 3-4 4-1
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (2, 3), (3, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: 0 ... 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 3)
    }

    @Test("CY-468 simpleCycles(maxLength: 3) emits 0: igraph PR 2181, bound 3 (ig#0)")
    func boundedCount468() {
        // D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 0)
    }

    @Test("CY-469 simpleCycles(maxLength: 4) is [0,1,2,3]/[0,1,2,3]: bound 4 (ig#1)")
    func boundedSimpleCycles469() {
        // D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 4))
        let expectedVertices: [[Int]] = [[0, 1, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-470 simpleCycles(maxLength: 5) emits 2: bound 5 (ig#2)")
    func boundedCount470() {
        // D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 5)).count == 2)
    }

    @Test("CY-471 simpleCycles(maxLength: 2) emits 1: igraph stable boat, bound 2 (ig#1)")
    func boundedCount471() {
        // D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 0), (2, 3), (3, 4), (4, 1), (4, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).count == 1)
    }

    @Test("CY-472 simpleCycles(maxLength: 3) emits 2: bound 3 (ig#2)")
    func boundedCount472() {
        // D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 0), (2, 3), (3, 4), (4, 1), (4, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 2)
    }

    @Test("CY-473 simpleCycles(maxLength: 4) emits 3: bound 4 (ig#3)")
    func boundedCount473() {
        // D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 0), (2, 3), (3, 4), (4, 1), (4, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 3)
    }

    @Test("CY-474 simpleCycles(maxLength: 1) emits 0: igraph stable letter, bound 1 (ig#0)")
    func boundedCount474() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 1)).count == 0)
    }

    @Test("CY-475 simpleCycles(maxLength: 2) emits 1: bound 2 (ig#1)")
    func boundedCount475() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).count == 1)
    }

    @Test("CY-476 simpleCycles(maxLength: 3) emits 3: bound 3 (ig#3)")
    func boundedCount476() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 3)
    }

    @Test("CY-477 simpleCycles(maxLength: 4) emits 5: bound 4 (ig#5)")
    func boundedCount477() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 5)
    }

    @Test("CY-478 simpleCycles(maxLength: 5) emits 7: bound 5 (ig#7)")
    func boundedCount478() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 5)).count == 7)
    }

    @Test("CY-479 simpleCycles(maxLength: 3) emits 0: igraph double square, bound 3 (ig#0)")
    func boundedCount479() {
        // D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (2, 5), (3, 0), (4, 1), (5, 4)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 0)
    }

    @Test("CY-480 simpleCycles(maxLength: 4) emits 1: bound 4 (ig#1)")
    func boundedCount480() {
        // D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (2, 5), (3, 0), (4, 1), (5, 4)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 1)
    }

    @Test("CY-481 simpleCycles(maxLength: 6) emits 2: bound 6 (ig#2)")
    func boundedCount481() {
        // D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (2, 5), (3, 0), (4, 1), (5, 4)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 6)).count == 2)
    }

    @Test("CY-482 simpleCycles(maxLength: 2) emits 3: Boost directed ER, max_length 2 (bh#3 bhu#3)")
    func boundedCount482() {
        // Boost's max_length counts vertices, the same number for a cycle
        // D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1), (12, 8), (11, 16), (9, 15), (1, 3), (4, 15), (1, 3), (12, 11), (14, 6),
            (8, 18), (19, 11), (3, 13), (6, 9), (1, 2), (3, 8), (0, 10), (9, 11), (13, 1), (1, 16),
            (7, 3), (3, 19)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).count == 3)
    }

    @Test("CY-483 simpleCycles(maxLength: 4) emits 13: max_length 4 (bh#13 bhu#10)")
    func boundedCount483() {
        // D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1), (12, 8), (11, 16), (9, 15), (1, 3), (4, 15), (1, 3), (12, 11), (14, 6),
            (8, 18), (19, 11), (3, 13), (6, 9), (1, 2), (3, 8), (0, 10), (9, 11), (13, 1), (1, 16),
            (7, 3), (3, 19)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 13)
    }

    @Test("CY-484 simpleCycles(maxLength: 7) emits 24: max_length 7 (bh#24 bhu#19)")
    func boundedCount484() {
        // D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1), (12, 8), (11, 16), (9, 15), (1, 3), (4, 15), (1, 3), (12, 11), (14, 6),
            (8, 18), (19, 11), (3, 13), (6, 9), (1, 2), (3, 8), (0, 10), (9, 11), (13, 1), (1, 16),
            (7, 3), (3, 19)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 7)).count == 24)
    }

    @Test("CY-485 simpleCycles(maxLength: 9) emits 30: max_length 9 (bh#30 bhu#23)")
    func boundedCount485() {
        // D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1), (12, 8), (11, 16), (9, 15), (1, 3), (4, 15), (1, 3), (12, 11), (14, 6),
            (8, 18), (19, 11), (3, 13), (6, 9), (1, 2), (3, 8), (0, 10), (9, 11), (13, 1), (1, 16),
            (7, 3), (3, 19)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 9)).count == 30)
    }

    @Test("CY-486 directed.simpleCycles(maxLength: 3) emits 26: Boost undirected ER, max_length 3 (bh#26 bhu#23)")
    func directedViewCount486() {
        // [0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.directed.simpleCycles(maxLength: 3)).count == 26)
    }

    @Test("CY-487 simpleCycles(maxLength: 3): 3 cycles in order: the same graph, our undirected count, bound 3")
    func boundedSimpleCycles487() {
        // [0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 3))
        let expectedVertices: [[Int]] = [[1, 11], [3, 19, 17], [5, 8, 18]]
        let expectedEdges: [[Int]] = [[5, 19], [2, 8, 13], [10, 15, 14]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-488 simpleCycles(maxLength: 1) is empty: JGraphT limitPaths1")
    func boundedSimpleCycles488() {
        // D: A>B B>A
        let pairs: [(String, String)] = [("A", "B"), ("B", "A")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 1)).isEmpty)
    }

    @Test("CY-489 simpleCycles(maxLength: 2) is empty: JGraphT limitPaths2")
    func boundedSimpleCycles489() {
        // D: A>B B>C C>A
        let pairs: [(String, String)] = [("A", "B"), ("B", "C"), ("C", "A")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).isEmpty)
    }

    @Test("CY-490 simpleCycles(maxLength: 2): 2 cycles in order: JGraphT limitPathsTwoCycles (jg#2)")
    func boundedSimpleCycles490() {
        // D: A>B B>A C>D D>C
        let pairs: [(String, String)] = [("A", "B"), ("B", "A"), ("C", "D"), ("D", "C")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 2))
        let expectedVertices: [[String]] = [["A", "B"], ["C", "D"]]
        let expectedEdges: [[Int]] = [[0, 1], [2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-491 simpleCycles(maxLength: 4): 3 cycles in order: the bounded search must count other-orientation closures as found")
    func boundedSimpleCycles491() {
        // Planted P2 emits two of these three; unbounded Johnson is immune
        // [0..3] 1-3 2-0 3-0 0-1 2-1 ~rot
        let pairs: [(Int, Int)] = [(1, 3), (2, 0), (3, 0), (0, 1), (2, 1)]
        let graph = ReorderedPseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .rotated)
        let cycles = Array(graph.simpleCycles(maxLength: 4))
        let expectedVertices: [[Int]] = [[0, 3, 1], [0, 2, 1], [0, 2, 1, 3]]
        let expectedEdges: [[Int]] = [[2, 0, 3], [1, 4, 3], [1, 4, 0, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-492 simpleCycles(maxLength: 3) emits 20: NetworkX A000292 triangles, K₆")
    func boundedCount492() {
        // K(6): every pair u < v, lexicographic
        let n = 6
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 20)
    }

    @Test("CY-493 simpleCycles(maxLength: 4) emits 65: triangles and 4-cycles of K₆ (A050534: 45)")
    func boundedCount493() {
        // K(6): every pair u < v, lexicographic
        let n = 6
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 4)).count == 65)
    }

    @Test("CY-494 simpleCycles(maxLength: 3) emits 165: NetworkX A000292, K₁₁")
    func boundedCount494() {
        // K(11): every pair u < v, lexicographic
        let n = 11
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 165)
    }

    @Test("CY-495 simpleCycles(maxLength: 2) emits 36: NetworkX test_directed_chordless_cycle_diclique, bound 2")
    func boundedCount495() {
        // n(n − 1)/2 digons
        // DK(9): every arc a>b, a != b, row-major
        let n = 9
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n where a != b { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 2)).count == 36)
    }

    @Test("CY-496 simpleCycles(maxLength: 100) emits 1: bound above n")
    func boundedCount496() {
        // C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles(maxLength: 100)).count == 1)
    }

    @Test("CY-497 simpleCycles(maxLength: 1): 10 cycles in order: NetworkX test_directed_chordless_loop_blockade, bound 1")
    func boundedSimpleCycles497() {
        // D: [0..9] 0>0 1>1 2>2 3>3 4>4 5>5 6>6 7>7 8>8 9>9 C(0..9)
        let pairs: [(Int, Int)] = [
            (0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8), (9, 9), (0, 1),
            (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 1))
        let expectedVertices: [[Int]] = [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]]
        let expectedEdges: [[Int]] = [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-498 simpleCycles(maxLength: 2): 2 cycles in order: undirected bound 2: loops and 2-cycles only")
    func boundedSimpleCycles498() {
        // 0-1 0-1 1-2 2-0 2-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 2))
        let expectedVertices: [[Int]] = [[0, 1], [2]]
        let expectedEdges: [[Int]] = [[0, 1], [4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }
}
