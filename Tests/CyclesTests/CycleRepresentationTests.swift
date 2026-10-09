// §I: the same answers on every representation. Every test in §A – §G already runs on the
// ReferencePseudograph or ReferenceDirectedMultigraph as the catalog writes it (CY-700); this file
// adds UndirectedAdjacencyList and AdjacencyList built in written order (CY-701: rows without
// repeats, so nothing collapses and positions are the written ones), CompressedSparseRow and
// AdjacencyMatrix (CY-702: positions are the representation's own, cells on the matrix), the views
// `.undirected` (arcs as edges, rows out-edges then in-edges) and `.directed` (two arcs per edge),
// conformers private to this file without indices and with vertex indices only (CY-703), rows out
// of position order (CY-704 – CY-706), String and Collider vertices (CY-709), and adjacency lists
// after removals, whose rows are no longer in position order, against a brute force over their own
// rows written inside the test (CY-710). Expected literals come from the catalog's reference
// (`ref.py`), with rows modelled as each representation stores them. Case IDs (CY-nnn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

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

/// A directed multigraph whose out-edge rows are not in position order: each row is built in
/// position order, then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex
/// indices are positions.
private struct ReorderedDirectedMultigraph<Vertex: Hashable>: DirectedGraph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [DirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferenceDirectedMultigraph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.outEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func outEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
}

/// An undirected pseudograph with no vertex or edge indices, rows in position order (a self-loop
/// twice), so the algorithms number vertices through a dictionary.
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

/// Vertex indices (the positions in `vertices`) but no edge indices, rows in position order.
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

/// A directed multigraph with no vertex or edge indices, out-edges in position order.
private struct PlainDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Cycles on every representation")
struct CycleRepresentationTests {
    @Test("CY-701 CY-006 on UndirectedAdjacencyList: isAcyclic is false: petgraph is_cyclic_undirected, NetworkX")
    func undirectedAdjacencyListIsAcyclic006() {
        // A self-loop is a cycle
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0])
        #expect(!graph.isAcyclic)
    }

    @Test("CY-701 CY-014 on UndirectedAdjacencyList: findCycle(from:) is [0,1,2]/[1,2,4]: NetworkX test_graph_cycle")
    func undirectedAdjacencyListFindCycleFromRoots014() throws {
        // NetworkX: [(0,1),(1,2),(2,0)]
        // -1-0 0-1 2-1 3-1 2-0
        let pairs: [(Int, Int)] = [(-1, 0), (0, 1), (2, 1), (3, 1), (2, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [-1, 0, 1, 2, 3])
        let cycle = try #require(graph.findCycle(from: [0, 1, 2, 3]))
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [1, 2, 4])
    }

    @Test("CY-701 CY-022 on UndirectedAdjacencyList: findCycle() is [0,1,2]/[0,1,2]: triangle and loop")
    func undirectedAdjacencyListFindCycle022() throws {
        // 1's row reaches 2 before its loop: the triangle closes first
        // 0-1 1-2 2-0 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 1)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
    }

    @Test("CY-701 CY-027 on UndirectedAdjacencyList: findCycle() is [1,2,5,4]/[2,4,7,3]: grid")
    func undirectedAdjacencyListFindCycle027() throws {
        // grid(3,3)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7),
            (7, 8)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [1, 2, 5, 4])
        #expect(cycle.edges == [2, 4, 7, 3])
    }

    @Test("CY-701 CY-032 on UndirectedAdjacencyList: findCycle() is [0,1,2]/[0,3,1]: K₄")
    func undirectedAdjacencyListFindCycle032() throws {
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 3, 1])
    }

    @Test("CY-701 CY-039 on UndirectedAdjacencyList: isAcyclic is false: NetworkX test_dag")
    func undirectedAdjacencyListIsAcyclic039() {
        // D: 0>1 0>2 1>2 is acyclic as a digraph, not as a graph
        // 0-1 0-2 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(!graph.isAcyclic)
    }

    @Test("CY-701 CY-113 on UndirectedAdjacencyList: cycleBasis() has 3 cycles: K₄")
    func undirectedAdjacencyListCycleBasis113() {
        // Breadth-first from 0: every cycle a triangle through 0
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 1, 3], [0, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 3, 1], [0, 4, 2], [1, 5, 2]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-121 on UndirectedAdjacencyList: cycleBasis() has 6 cycles: wheel")
    func undirectedAdjacencyListCycleBasis121() {
        // W(0;1..6)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6),
            (6, 1)
        ]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 6], [0, 1, 6]]
        let expectedEdges: [[Int]] = [[0, 6, 1], [1, 7, 2], [2, 8, 3], [3, 9, 4], [4, 10, 5], [0, 11, 5]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-122 on UndirectedAdjacencyList: cycleBasis() has 4 cycles: grid")
    func undirectedAdjacencyListCycleBasis122() {
        // grid(3,3)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7),
            (7, 8)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 4, 3], [1, 2, 5, 4], [0, 1, 4, 7, 6, 3], [1, 2, 5, 8, 7, 4]]
        let expectedEdges: [[Int]] = [[0, 3, 5, 1], [2, 4, 7, 3], [0, 3, 8, 10, 6, 1], [2, 4, 9, 11, 8, 3]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-123 on UndirectedAdjacencyList: cycleBasis() has 4 cycles: not every basis is fundamental: NetworkX cycle_basis (Paton) gives [0,3,4], [2,3,4], [0,1,3], [0,2,4], and [0,3,4] has no edge of its own (nxb#4)")
    func undirectedAdjacencyListCycleBasis123() {
        // Ours: each cycle holds exactly one non-tree edge, its own. JGraphT documents Paton's output as "weakly fundamental"
        // [0..4] 0-4 0-3 0-2 0-1 1-3 2-4 2-3 3-4
        let pairs: [(Int, Int)] = [(0, 4), (0, 3), (0, 2), (0, 1), (1, 3), (2, 4), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 3, 1], [0, 4, 2], [0, 3, 2], [0, 4, 3]]
        let expectedEdges: [[Int]] = [[1, 4, 3], [0, 5, 2], [1, 6, 2], [0, 7, 1]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-319 on UndirectedAdjacencyList: simpleCycles(): 13 cycles in order: igraph \"envelope\" (ig#13)")
    func undirectedAdjacencyListSimpleCycles319() {
        // 0-1 0-3 0-4 1-2 1-3 2-3 2-4 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 4), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 3, 4, 2])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3], [0, 1, 2, 3, 4], [0, 1, 2, 4], [0, 1, 2, 4, 3], [0, 1, 3], [0, 1, 3, 2, 4],
            [0, 1, 3, 4], [0, 3, 1, 2, 4], [0, 3, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4, 3], [3, 2, 4]
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 5, 1], [0, 3, 5, 7, 2], [0, 3, 6, 2], [0, 3, 6, 7, 1], [0, 4, 1], [0, 4, 5, 6, 2],
            [0, 4, 7, 2], [1, 4, 3, 6, 2], [1, 5, 6, 2], [1, 7, 2], [3, 5, 4], [3, 6, 7, 4], [5, 6, 7]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-325 on UndirectedAdjacencyList: simpleCycles(): 3 cycles in order: igraph \"Mickey\" (ig#3)")
    func undirectedAdjacencyListSimpleCycles325() {
        // [0..6] 0-1 1-2 2-0 0-0 0-3 3-4 4-5 5-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 0), (0, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [0], [0, 3, 4, 5]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3], [4, 5, 6, 7]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-330 on UndirectedAdjacencyList: simpleCycles(): 7 cycles in order: K₄: the canonical form and order")
    func undirectedAdjacencyListSimpleCycles330() {
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2], [0, 1, 2, 3], [0, 1, 3], [0, 1, 3, 2], [0, 2, 1, 3], [0, 2, 3], [1, 2, 3]
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 1], [0, 3, 5, 2], [0, 4, 2], [0, 4, 5, 1], [1, 3, 4, 2], [1, 5, 2], [3, 5, 4]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-341 on UndirectedAdjacencyList: simpleCycles(): 3 cycles in order: cycles through a cut vertex")
    func undirectedAdjacencyListSimpleCycles341() {
        // C(0,1,2) C(2,3,4) C(4,5,6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2), (4, 5), (5, 6), (6, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [2, 3, 4], [4, 5, 6]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-343 on UndirectedAdjacencyList: simpleCycles(): 6 cycles in order: the same plus 7–3")
    func undirectedAdjacencyListSimpleCycles343() {
        // 0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11 7-3
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (2, 3), (3, 4), (4, 5), (4, 11), (5, 6), (6, 7), (7, 8), (8, 9),
            (9, 10), (10, 11), (7, 3)
        ]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 14)
        #expect(Array(graph.vertices) == [0, 1, 4, 2, 3, 5, 11, 6, 7, 8, 9, 10])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3, 4], [0, 1, 2, 3, 7, 6, 5, 4], [0, 1, 2, 3, 7, 8, 9, 10, 11, 4],
            [4, 3, 7, 6, 5], [4, 3, 7, 8, 9, 10, 11], [4, 5, 6, 7, 8, 9, 10, 11]
        ]
        let expectedEdges: [[Int]] = [
            [0, 2, 3, 4, 1], [0, 2, 3, 13, 8, 7, 5, 1], [0, 2, 3, 13, 9, 10, 11, 12, 6, 1],
            [4, 13, 8, 7, 5], [4, 13, 9, 10, 11, 12, 6], [5, 7, 8, 9, 10, 11, 12, 6]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-418 on UndirectedAdjacencyList: simpleCycles() is [1]/[2]: loop on a vertex in no cycle")
    func undirectedAdjacencyListSimpleCycles418() {
        // P(0,1,2) 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1]]
        let expectedEdges: [[Int]] = [[2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-492 on UndirectedAdjacencyList: simpleCycles(maxLength: 3) emits 20: NetworkX A000292 triangles, K₆")
    func undirectedAdjacencyListBoundedCount492() {
        // K(6): every pair u < v, lexicographic
        let n = 6
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(Array(graph.simpleCycles(maxLength: 3)).count == 20)
    }

    @Test("CY-701 CY-502 on UndirectedAdjacencyList: girth() is 5: NetworkX (nxg=5)")
    func undirectedAdjacencyListGirth502() {
        // nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.girth() == 5)
    }

    @Test("CY-701 CY-503 on UndirectedAdjacencyList: girth() is 6: NetworkX (nxg=6)")
    func undirectedAdjacencyListGirth503() {
        // nx(heawood)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9),
            (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 13, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 21)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
        #expect(graph.girth() == 6)
    }

    @Test("CY-701 CY-200 on AdjacencyList: simpleCycles(): 5 cycles in order: NetworkX test_simple_cycles and docstring; rustworkx (nx#5 rx#5 bh#5 bhu#5 bt#3)")
    func adjacencyListSimpleCycles200() {
        // NetworkX sorted: [0], [0,1,2], [0,2], [1,2], [2]
        // D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 7)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0, 1, 2], [0, 2], [1, 2], [2]]
        let expectedEdges: [[Int]] = [[0], [1, 3, 4], [2, 4], [3, 5], [6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-210 on AdjacencyList: simpleCycles(): 5 cycles in order: JGraphT DirectedSimpleCyclesTest incremental (jg#5)")
    func adjacencyListSimpleCycles210() {
        // D: [0..6] 0>0 1>1 0>1 1>0 1>2 2>3 3>0 6>6
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (0, 1), (1, 0), (1, 2), (2, 3), (3, 0), (6, 6)]
        let graph = AdjacencyList(vertices: 0 ... 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0, 1], [0, 1, 2, 3], [1], [6]]
        let expectedEdges: [[Int]] = [[0], [2, 3], [2, 4, 5, 6], [1], [7]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-215 on AdjacencyList: simpleCycles(): 9 cycles in order: NetworkX / rustworkx Johnson figure 1, k = 3 (nx#9)")
    func adjacencyListSimpleCycles215() {
        // D: johnson(3)
        let pairs: [(Int, Int)] = [
            (1, 2), (2, 5), (1, 3), (3, 5), (1, 4), (4, 5), (7, 1), (5, 8), (5, 6), (6, 8), (6, 7),
            (7, 8), (9, 5), (8, 9), (9, 12), (8, 10), (10, 12), (8, 11), (11, 12), (12, 8)
        ]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [1, 2, 5, 3, 4, 7, 8, 6, 9, 12, 10, 11])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [1, 2, 5, 6, 7], [1, 3, 5, 6, 7], [1, 4, 5, 6, 7], [5, 8, 9], [5, 6, 8, 9],
            [5, 6, 7, 8, 9], [8, 9, 12], [8, 10, 12], [8, 11, 12]
        ]
        let expectedEdges: [[Int]] = [
            [0, 1, 8, 10, 6], [2, 3, 8, 10, 6], [4, 5, 8, 10, 6], [7, 13, 12], [8, 9, 13, 12],
            [8, 10, 11, 13, 12], [13, 14, 19], [15, 16, 19], [17, 18, 19]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-241 on AdjacencyList: simpleCycles(): 7 cycles in order: igraph \"stable letter\" (ig#7)")
    func adjacencyListSimpleCycles241() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 2, 3, 1, 4])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 2, 3, 1, 4], [0, 2, 4], [0, 3, 1, 2, 4], [0, 3, 1, 4], [2, 3, 1], [2, 3, 1, 4], [2, 4]
        ]
        let expectedEdges: [[Int]] = [
            [0, 4, 6, 3, 7], [0, 5, 7], [1, 6, 2, 5, 7], [1, 6, 3, 7], [4, 6, 2], [4, 6, 3, 8], [5, 8]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-247 on AdjacencyList: simpleCycles(): 3 cycles in order: the same plus 7>3")
    func adjacencyListSimpleCycles247() {
        // D: 0>1 1>2 2>3 3>4 4>0 4>5 5>6 6>7 7>8 8>9 9>10 10>11 11>4 7>3
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10),
            (10, 11), (11, 4), (7, 3)
        ]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 14)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4], [3, 4, 5, 6, 7], [4, 5, 6, 7, 8, 9, 10, 11]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3, 4], [3, 5, 6, 7, 13], [5, 6, 7, 8, 9, 10, 11, 12]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-250 on AdjacencyList: simpleCycles() is [2,0,1]/[2,0,1]: start is the least vertex in vertices order, not by value")
    func adjacencyListSimpleCycles250() {
        // D: [2,1,0] 0>1 1>2 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList(vertices: [2, 1, 0], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [2, 1, 0])
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[2, 0, 1]]
        let expectedEdges: [[Int]] = [[2, 0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-457 on AdjacencyList: simpleCycles(maxLength: 5): 5 cycles in order: bound 5")
    func adjacencyListBoundedSimpleCycles457() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 17)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let cycles = Array(graph.simpleCycles(maxLength: 5))
        let expectedVertices: [[Int]] = [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4]]
        let expectedEdges: [[Int]] = [[0], [1, 2], [1, 3, 4], [1, 3, 5, 6], [1, 3, 5, 7, 8]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-701 CY-511 on AdjacencyList: girth() is 4: JGraphT testGraphDirectedCyclic (jgg=4)")
    func adjacencyListGirth511() {
        // D: [0..3] 0>1 1>2 2>3 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.girth() == 4)
    }

    @Test("CY-701 CY-517 on AdjacencyList: girth() is 2: JGraphT testGraphDirected1 (jgg=2)")
    func adjacencyListGirth517() {
        // D: [0..3] 1>0 3>0 1>2 2>3 3>2
        let pairs: [(Int, Int)] = [(1, 0), (3, 0), (1, 2), (2, 3), (3, 2)]
        let graph = AdjacencyList(vertices: 0 ... 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.girth() == 2)
    }

    @Test("CY-701 CY-534 on AdjacencyList: girth() is 3: directed: shortest cycle not through vertex 0")
    func adjacencyListGirth534() {
        // D: C(0..5) 3>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (3, 1)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == 7)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(graph.girth() == 3)
    }

    @Test("CY-702 CY-200 on CompressedSparseRow: positions are the representation's own")
    func compressedSparseRow200() {
        // D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0, 1, 2], [0, 2], [1, 2], [2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedEdges: [[Int]] = [[0], [1, 3, 4], [2, 4], [3, 5], [6]]
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-702 CY-240 on CompressedSparseRow: the catalog's arcs in row-major order, vertices 0..<5")
    func compressedSparseRow240() {
        // D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3, rewritten row-major
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 0), (2, 3), (3, 4), (4, 1), (4, 3)]
        let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 3, 4, 1], [0, 3, 4, 1], [0, 4, 1], [3, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedEdges: [[Int]] = [[0, 4, 5, 6, 3], [1, 5, 6, 3], [2, 6, 3], [5, 7]]
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-702 CY-241 on CompressedSparseRow: the catalog's arcs in row-major order, vertices 0..<5")
    func compressedSparseRow241() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2, rewritten row-major
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 3, 1, 4], [0, 2, 4], [0, 3, 1, 2, 4], [0, 3, 1, 4], [1, 2, 3], [1, 4, 2, 3], [2, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedEdges: [[Int]] = [[0, 4, 6, 3, 7], [0, 5, 7], [1, 6, 2, 5, 7], [1, 6, 3, 7], [2, 4, 6], [3, 8, 4, 6], [5, 8]]
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-702 CY-457 on CompressedSparseRow: positions are the representation's own")
    func compressedSparseRow457() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = CompressedSparseRow(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 5))
        let expectedVertices: [[Int]] = [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedEdges: [[Int]] = [[0], [1, 2], [1, 3, 4], [1, 3, 5, 6], [1, 3, 5, 7, 8]]
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-702 CY-511 on CompressedSparseRow: positions are the representation's own")
    func compressedSparseRow511() {
        // D: [0..3] 0>1 1>2 2>3 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-702 CY-534 on CompressedSparseRow: the catalog's arcs in row-major order, vertices 0..<6")
    func compressedSparseRow534() {
        // D: C(0..5) 3>1, rewritten row-major
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 1), (3, 4), (4, 5), (5, 0)]
        let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 3)
    }

    @Test("CY-702 CY-200 on AdjacencyMatrix: positions are the representation's own")
    func adjacencyMatrix200() {
        // D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0, 1, 2], [0, 2], [1, 2], [2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedCells: [[[Int]]] = [
            [[0, 0]], [[0, 1], [1, 2], [2, 0]], [[0, 2], [2, 0]], [[1, 2], [2, 1]], [[2, 2]]
        ]
        #expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)
    }

    @Test("CY-702 CY-240 on AdjacencyMatrix: the catalog's arcs in row-major order, vertices 0..<5")
    func adjacencyMatrix240() {
        // D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3, rewritten row-major
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 0), (2, 3), (3, 4), (4, 1), (4, 3)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 3, 4, 1], [0, 3, 4, 1], [0, 4, 1], [3, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedCells: [[[Int]]] = [
            [[0, 2], [2, 3], [3, 4], [4, 1], [1, 0]], [[0, 3], [3, 4], [4, 1], [1, 0]],
            [[0, 4], [4, 1], [1, 0]], [[3, 4], [4, 3]]
        ]
        #expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)
    }

    @Test("CY-702 CY-241 on AdjacencyMatrix: the catalog's arcs in row-major order, vertices 0..<5")
    func adjacencyMatrix241() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2, rewritten row-major
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 3, 1, 4], [0, 2, 4], [0, 3, 1, 2, 4], [0, 3, 1, 4], [1, 2, 3], [1, 4, 2, 3], [2, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedCells: [[[Int]]] = [
            [[0, 2], [2, 3], [3, 1], [1, 4], [4, 0]], [[0, 2], [2, 4], [4, 0]],
            [[0, 3], [3, 1], [1, 2], [2, 4], [4, 0]], [[0, 3], [3, 1], [1, 4], [4, 0]],
            [[1, 2], [2, 3], [3, 1]], [[1, 4], [4, 2], [2, 3], [3, 1]], [[2, 4], [4, 2]]
        ]
        #expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)
    }

    @Test("CY-702 CY-457 on AdjacencyMatrix: positions are the representation's own")
    func adjacencyMatrix457() {
        // D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (1, 0), (1, 2), (2, 0), (2, 3), (3, 0), (3, 4), (4, 0), (4, 5), (5, 0),
            (5, 6), (6, 0), (6, 7), (7, 0), (7, 8), (8, 0)
        ]
        let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles(maxLength: 5))
        let expectedVertices: [[Int]] = [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        let expectedCells: [[[Int]]] = [
            [[0, 0]], [[0, 1], [1, 0]], [[0, 1], [1, 2], [2, 0]], [[0, 1], [1, 2], [2, 3], [3, 0]],
            [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]]
        ]
        #expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)
    }

    @Test("CY-702 CY-511 on AdjacencyMatrix: positions are the representation's own")
    func adjacencyMatrix511() {
        // D: [0..3] 0>1 1>2 2>3 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-702 CY-534 on AdjacencyMatrix: the catalog's arcs in row-major order, vertices 0..<6")
    func adjacencyMatrix534() {
        // D: C(0..5) 3>1, rewritten row-major
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 1), (3, 4), (4, 5), (5, 0)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 3)
    }


    @Test("CY-704 simpleCycles(): 7 cycles in order: rows reversed")
    func simpleCycles704() {
        // = CY-331
        // K(4) ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReorderedPseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .reversed)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 2, 3], [0, 2, 1, 3], [0, 1, 3, 2], [0, 1, 3], [0, 1, 2, 3], [0, 1, 2], [1, 2, 3]
        ]
        let expectedEdges: [[Int]] = [
            [1, 5, 2], [1, 3, 4, 2], [0, 4, 5, 1], [0, 4, 2], [0, 3, 5, 2], [0, 3, 1], [3, 5, 4]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-705 simpleCycles(): 7 cycles in order: rows rotated")
    func simpleCycles705() {
        // K(4) ~rot
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReorderedPseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .rotated)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 2, 1, 3], [0, 2, 3], [0, 1, 2, 3], [0, 1, 2], [0, 1, 3, 2], [0, 1, 3], [1, 2, 3]
        ]
        let expectedEdges: [[Int]] = [
            [1, 3, 4, 2], [1, 5, 2], [0, 3, 5, 2], [0, 3, 1], [0, 4, 5, 1], [0, 4, 2], [3, 5, 4]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-706 simpleCycles(): 5 cycles in order: rows rotated, directed")
    func simpleCycles706() {
        // D: DK(3) ~rot
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = ReorderedDirectedMultigraph(vertices: 0 ... 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }, rows: .rotated)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 1], [0, 2], [0, 1, 2], [0, 1], [1, 2]]
        let expectedEdges: [[Int]] = [[1, 5, 2], [1, 4], [0, 3, 4], [0, 2], [3, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-702 AdjacencyMatrix.undirected with cells u < v: K₄ with positions as cells, rows out-edges then in-edges")
    func adjacencyMatrixUndirected() throws {
        // Cells (0,1) < (0,2) < (0,3) < (1,2) < (1,3) < (2,3). Vertex 1's row is (1,2), (1,3), then
        // (0,1), so the order is not K(4)'s (CY-330); the canonical forms are, cell for cell.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.vertexIndexBound == 4 && graph.edgeIndexBound == nil)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2], [0, 1, 3], [0, 1, 3, 2], [0, 2, 3], [0, 2, 1, 3], [1, 2, 3]]
        let expectedCells: [[[Int]]] = [
            [[0, 1], [1, 2], [2, 3], [0, 3]], [[0, 1], [1, 2], [0, 2]], [[0, 1], [1, 3], [0, 3]],
            [[0, 1], [1, 3], [2, 3], [0, 2]], [[0, 2], [2, 3], [0, 3]], [[0, 2], [1, 2], [1, 3], [0, 3]],
            [[1, 2], [2, 3], [1, 3]],
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1, 2, 3])
        #expect(found.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [0, 3]])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3]])
        #expect(basis.map { $0.edges.map { [$0.source, $0.target] } } == [[[0, 1], [1, 2], [0, 2]], [[0, 1], [1, 3], [0, 3]], [[0, 2], [2, 3], [0, 3]]])
        #expect(graph.girth() == 3)
        #expect(!graph.isAcyclic)
    }

    @Test("CY-702 AdjacencyList.undirected, one arc per edge: K₄ with the arcs' positions, rows out-edges then in-edges")
    func adjacencyListUndirected() throws {
        // The same rows as the matrix's above, positions 0..<6 in written order.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.edgeCount == 6)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2], [0, 1, 3], [0, 1, 3, 2], [0, 2, 3], [0, 2, 1, 3], [1, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 3, 5, 2], [0, 3, 1], [0, 4, 2], [0, 4, 5, 1], [1, 5, 2], [1, 3, 4, 2], [3, 5, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1, 2, 3])
        #expect(found.edges == [0, 3, 5, 2])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3]])
        #expect(basis.map(\.edges) == [[0, 3, 1], [0, 4, 2], [1, 5, 2]])
        #expect(graph.girth() == 3)
    }

    @Test("CY-703 conformers without indices and with vertex indices only: CY-119, CY-327 and CY-412 exactly")
    func conformersWithoutIndices() throws {
        // CY-119: 0-1 1-2 2-0 0-1 2-2.
        let pairs119: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let edges119 = pairs119.map { UndirectedEdge($0.0, $0.1) }
        let plain119 = PlainGraph(vertices: [0, 1, 2], edges: edges119)
        let indexed119 = VertexIndexedGraph(vertices: [0, 1, 2], edges: edges119)
        #expect(plain119.vertexIndexBound == nil && plain119.edgeIndexBound == nil)
        #expect(indexed119.vertexIndexBound == 3 && indexed119.edgeIndexBound == nil)
        let cycles119Vertices: [[Int]] = [[0, 1, 2], [0, 1], [0, 2, 1], [2]]
        let cycles119Edges: [[Int]] = [[0, 1, 2], [0, 3], [2, 1, 3], [4]]
        #expect(Array(plain119.simpleCycles()).map(\.vertices) == cycles119Vertices)
        #expect(Array(plain119.simpleCycles()).map(\.edges) == cycles119Edges)
        #expect(Array(indexed119.simpleCycles()).map(\.vertices) == cycles119Vertices)
        #expect(Array(indexed119.simpleCycles()).map(\.edges) == cycles119Edges)
        let basis119Vertices: [[Int]] = [[0, 1, 2], [0, 1], [2]]
        let basis119Edges: [[Int]] = [[0, 1, 2], [0, 3], [4]]
        #expect(plain119.cycleBasis().map(\.vertices) == basis119Vertices)
        #expect(plain119.cycleBasis().map(\.edges) == basis119Edges)
        #expect(indexed119.cycleBasis().map(\.vertices) == basis119Vertices)
        #expect(indexed119.cycleBasis().map(\.edges) == basis119Edges)
        let plainFound = try #require(plain119.findCycle())
        let indexedFound = try #require(indexed119.findCycle())
        #expect(plainFound.vertices == [0, 1, 2] && plainFound.edges == [0, 1, 2])
        #expect(indexedFound.vertices == [0, 1, 2] && indexedFound.edges == [0, 1, 2])
        #expect(plain119.girth() == 1 && indexed119.girth() == 1)
        #expect(!plain119.isAcyclic && !indexed119.isAcyclic)

        // CY-327 (igraph "Mickey3"): [0..6] 0-1 1-2 2-0 0-3 3-4 4-5 5-0 1-1 5-6 6-5 5-5 5-5.
        let pairs327: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 5), (5, 0), (1, 1), (5, 6), (6, 5), (5, 5), (5, 5)]
        let edges327 = pairs327.map { UndirectedEdge($0.0, $0.1) }
        let cycles327Vertices: [[Int]] = [[0, 1, 2], [0, 3, 4, 5], [1], [5, 6], [5], [5]]
        let cycles327Edges: [[Int]] = [[0, 1, 2], [3, 4, 5, 6], [7], [8, 9], [10], [11]]
        let plain327 = PlainGraph(vertices: Array(0 ... 6), edges: edges327)
        let indexed327 = VertexIndexedGraph(vertices: Array(0 ... 6), edges: edges327)
        #expect(Array(plain327.simpleCycles()).map(\.vertices) == cycles327Vertices)
        #expect(Array(plain327.simpleCycles()).map(\.edges) == cycles327Edges)
        #expect(Array(indexed327.simpleCycles()).map(\.vertices) == cycles327Vertices)
        #expect(Array(indexed327.simpleCycles()).map(\.edges) == cycles327Edges)
        // Here the basis is every simple cycle: no two share a non-tree edge.
        #expect(plain327.cycleBasis().map(\.edges) == cycles327Edges)
        #expect(indexed327.cycleBasis().map(\.edges) == cycles327Edges)

        // CY-412: C(0..3) 0-1 2-3, two doubled sides.
        let pairs412: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1), (2, 3)]
        let edges412 = pairs412.map { UndirectedEdge($0.0, $0.1) }
        let cycles412Vertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1], [0, 3, 2, 1], [0, 3, 2, 1], [2, 3]]
        let cycles412Edges: [[Int]] = [[0, 1, 2, 3], [0, 1, 5, 3], [0, 4], [3, 2, 1, 4], [3, 5, 1, 4], [2, 5]]
        let plain412 = PlainGraph(vertices: [0, 1, 2, 3], edges: edges412)
        #expect(Array(plain412.simpleCycles()).map(\.vertices) == cycles412Vertices)
        #expect(Array(plain412.simpleCycles()).map(\.edges) == cycles412Edges)
        #expect(plain412.cycleBasis().map(\.edges) == [[0, 1, 2, 3], [0, 4], [0, 1, 5, 3]])
        #expect(plain412.girth() == 2)
        let indexed412 = VertexIndexedGraph(vertices: [0, 1, 2, 3], edges: edges412)
        #expect(Array(indexed412.simpleCycles()).map(\.vertices) == cycles412Vertices)
        #expect(Array(indexed412.simpleCycles()).map(\.edges) == cycles412Edges)
        #expect(indexed412.cycleBasis().map(\.edges) == [[0, 1, 2, 3], [0, 4], [0, 1, 5, 3]])
        #expect(indexed412.girth() == 2)
    }

    @Test("CY-703 a digraph conformer without indices: CY-200 and CY-410 exactly")
    func digraphWithoutIndices() {
        // CY-200: 0>0 0>1 0>2 1>2 2>0 2>1 2>2.
        let pairs200: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let plain200 = PlainDigraph(vertices: [0, 1, 2], edges: pairs200.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(plain200.vertexIndexBound == nil && plain200.edgeIndexBound == nil)
        let cycles200 = Array(plain200.simpleCycles())
        #expect(cycles200.map(\.vertices) == [[0], [0, 1, 2], [0, 2], [1, 2], [2]])
        #expect(cycles200.map(\.edges) == [[0], [1, 3, 4], [2, 4], [3, 5], [6]])
        #expect(plain200.girth() == 1)
        // CY-410: 0>1 1>0 1>0 0>1, 2 × 2 antiparallel copies.
        let pairs410: [(Int, Int)] = [(0, 1), (1, 0), (1, 0), (0, 1)]
        let plain410 = PlainDigraph(vertices: [0, 1], edges: pairs410.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles410 = Array(plain410.simpleCycles())
        #expect(cycles410.map(\.vertices) == [[0, 1], [0, 1], [0, 1], [0, 1]])
        #expect(cycles410.map(\.edges) == [[0, 1], [0, 2], [3, 1], [3, 2]])
        #expect(plain410.girth() == 2)
    }

    @Test("CY-708 digraph.undirected: antiparallel arcs become a 2-cycle, rows out-edges then in-edges")
    func undirectedViewOfDigraph() throws {
        // D: 0>1 1>0 1>2 2>0. Vertex 1's row is 1, 2 (out) then 0 (in); the catalog's position-order
        // row gives the same order here.
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let digraph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1, 2], [0, 1, 2]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2, 3], [1, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1])
        #expect(found.edges == [0, 1])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1], [0, 1, 2]])
        #expect(basis.map(\.edges) == [[0, 1], [0, 2, 3]])
        #expect(graph.girth() == 2)
        #expect(!graph.isAcyclic)
        // The digraph's own cycles: the digon and 0>1>2>0.
        let directed = Array(digraph.simpleCycles())
        #expect(directed.map(\.vertices) == [[0, 1], [0, 1, 2]])
        #expect(directed.map(\.edges) == [[0, 1], [0, 2, 3]])
        #expect(digraph.girth() == 2)
    }

    @Test("CY-423 CY-708 the .undirected view of D: 0>1 1>0 1>0: three 2-cycles, one per pair of arcs")
    func undirectedViewOfParallelArcs() throws {
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let cycles = Array(graph.simpleCycles())
        #expect(cycles.map(\.vertices) == [[0, 1], [0, 1], [0, 1]])
        #expect(cycles.map(\.edges) == [[0, 1], [0, 2], [1, 2]])
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1] && found.edges == [0, 1])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1], [0, 1]])
        #expect(basis.map(\.edges) == [[0, 1], [0, 2]])
        #expect(graph.girth() == 2)
    }

    @Test("CY-708 the .undirected view of CY-119 written as arcs: loops and parallel arcs keep their positions")
    func undirectedViewWithLoop() throws {
        // D: 0>1 1>2 2>0 0>1 2>2. The view lists the loop at 2 once as an out-edge, once as an in-edge.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let cycles = Array(graph.simpleCycles())
        #expect(cycles.map(\.vertices) == [[0, 1, 2], [0, 1], [0, 2, 1], [2]])
        #expect(cycles.map(\.edges) == [[0, 1, 2], [0, 3], [2, 1, 3], [4]])
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1, 2] && found.edges == [0, 1, 2])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1], [2]])
        #expect(basis.map(\.edges) == [[0, 1, 2], [0, 3], [4]])
        #expect(graph.girth() == 1)
    }

    @Test("CY-707 CY-858 g.directed reads every edge as two arcs: C₄ with a chord has 11 directed cycles and is not acyclic")
    func directedViewOfGraph() {
        // C(0..3) 0-2: 2 × 3 cycles of length ≥ 3 and 5 digons, one per edge.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = Array(graph.directed.simpleCycles())
        #expect(arcs.count == 11)
        #expect(arcs.filter { $0.length == 2 }.count == 5)
        #expect(arcs.filter { $0.length == 3 }.count == 4)
        #expect(arcs.filter { $0.length == 4 }.count == 2)
        // Every digon uses one edge's two arcs.
        #expect(arcs.filter { $0.length == 2 }.allSatisfy { $0.edges[0].position == $0.edges[1].position && $0.edges[0].reversed != $0.edges[1].reversed })
        #expect(graph.directed.girth() == 2)
        #expect(graph.girth() == 3)
    }

    @Test("CY-709 String and Collider vertices (every hash equal): the envelope (CY-319) relabelled, exactly")
    func stringAndColliderVertices() {
        // 0-1 0-3 0-4 1-2 1-3 2-3 2-4 3-4.
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 4), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3], [0, 1, 2, 3, 4], [0, 1, 2, 4], [0, 1, 2, 4, 3], [0, 1, 3], [0, 1, 3, 2, 4],
            [0, 1, 3, 4], [0, 3, 1, 2, 4], [0, 3, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4, 3], [3, 2, 4],
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 5, 1], [0, 3, 5, 7, 2], [0, 3, 6, 2], [0, 3, 6, 7, 1], [0, 4, 1], [0, 4, 5, 6, 2],
            [0, 4, 7, 2], [1, 4, 3, 6, 2], [1, 5, 6, 2], [1, 7, 2], [3, 5, 4], [3, 6, 7, 4], [5, 6, 7],
        ]
        let strings = ReferencePseudograph(edges: pairs.map { UndirectedEdge("v\($0.0)", "v\($0.1)") })
        let stringCycles = Array(strings.simpleCycles())
        #expect(stringCycles.map { $0.vertices.map { Int($0.dropFirst())! } } == expectedVertices)
        #expect(stringCycles.map(\.edges) == expectedEdges)
        #expect(strings.girth() == 3)
        #expect(strings.cycleBasis().count == 4)

        let colliderEdges = pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) }
        let colliders = ReferencePseudograph(edges: colliderEdges)
        let colliderCycles = Array(colliders.simpleCycles())
        #expect(colliderCycles.map { $0.vertices.map(\.value) } == expectedVertices)
        #expect(colliderCycles.map(\.edges) == expectedEdges)
        let list = UndirectedAdjacencyList(edges: colliderEdges)
        let listCycles = Array(list.simpleCycles())
        #expect(listCycles.map { $0.vertices.map(\.value) } == expectedVertices)
        #expect(listCycles.map(\.edges) == expectedEdges)
        #expect(list.findCycle()?.vertices.map(\.value) == [0, 1, 2, 3])
        #expect(list.findCycle()?.edges == [0, 3, 5, 1])
        #expect(list.cycleBasis().map { $0.vertices.map(\.value) } == [[0, 1, 3], [0, 1, 2, 3], [0, 1, 2, 4], [0, 3, 4]])
        #expect(list.cycleBasis().map(\.edges) == [[0, 4, 1], [0, 3, 5, 1], [0, 3, 6, 2], [1, 7, 2]])
        #expect(list.girth() == 3)
        #expect(!list.isAcyclic)
    }

    @Test("CY-710 UndirectedAdjacencyList after removals: rows out of position order, the order its own rows give, the same set as a pseudograph")
    func undirectedAdjacencyListAfterRemovals() throws {
        // K(0..5) and a triangle 5-6-7 with a loop at 7, then removals that move the last edge into
        // each hole and the last slot into a removed vertex's place, so rows leave position order.
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 6 { for v in u + 1 ..< 6 { pairs.append((u, v)) } }
        pairs += [(5, 6), (6, 7), (7, 5), (7, 7)]
        var list = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        list.remove(edge: UndirectedEdge(0, 1))
        list.remove(edge: UndirectedEdge(3, 2))
        list.remove(1)
        list.insert(edge: UndirectedEdge(6, 0))
        list.insert(edge: UndirectedEdge(4, 4))
        let vertices = Array(list.vertices)
        let edges = Array(list.edges)
        let rows = vertices.map { Array(list.incidentEdges(of: $0)) }
        // Only meaningful if some row is out of position order.
        #expect(rows.contains { $0 != $0.sorted() })

        // Brute force over the list's own rows: every closed path from each start s through
        // vertices after s (in `vertices` order), in canonical orientation, sorted by api.md's key.
        let n = vertices.count
        var number: [Int: Int] = [:]
        for (i, v) in vertices.enumerated() { number[v] = i }
        var found: [[Int]: (key: [Int], vertices: [Int], edges: [Int])] = [:]
        for s in 0 ..< n {
            var pathVertices = [s]
            var pathEdges: [Int] = []
            func extend() {
                let v = pathVertices[pathVertices.count - 1]
                for e in rows[v] where !pathEdges.contains(e) {
                    let w = number[edges[e].oppositeVertex(to: vertices[v])]!
                    if w == s {
                        var cv = pathVertices
                        var ce = pathEdges + [e]
                        if ce.count >= 2 && ce[ce.count - 1] < ce[0] {
                            cv = [cv[0]] + cv[1...].reversed()
                            ce.reverse()
                        }
                        let key = [s] + zip(cv, ce).map { rows[$0.0].firstIndex(of: $0.1)! }
                        found[cv + [-1] + ce] = (key, cv, ce)
                    } else if w > s && !pathVertices.contains(w) {
                        pathVertices.append(w)
                        pathEdges.append(e)
                        extend()
                        pathVertices.removeLast()
                        pathEdges.removeLast()
                    }
                }
            }
            extend()
        }
        let expected = found.values.sorted { $0.key.lexicographicallyPrecedes($1.key) }
        #expect(!expected.isEmpty)
        let cycles = Array(list.simpleCycles())
        #expect(cycles.map(\.vertices) == expected.map { $0.vertices.map { vertices[$0] } })
        #expect(cycles.map(\.edges) == expected.map(\.edges))

        // The same set as a pseudograph holding the same vertices and edges with rows in position
        // order; only the order differs.
        let reference = ReferencePseudograph(vertices: vertices, edges: edges)
        let referenceCycles = Array(reference.simpleCycles())
        #expect(Set(cycles) == Set(referenceCycles))
        #expect(cycles.count == referenceCycles.count)
        #expect(list.girth() == reference.girth())
        #expect(list.isAcyclic == reference.isAcyclic)
        #expect(list.cycleBasis().count == reference.cycleBasis().count)
        let cycle = try #require(list.findCycle())
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: list) != nil)
        #expect(list.cycleBasis().allSatisfy { Cycle(vertices: $0.vertices, edges: $0.edges, in: list) != nil })
    }

    @Test("CY-710 AdjacencyList after removals: out-edge rows out of position order, the order its own rows give")
    func adjacencyListAfterRemovals() {
        // DKL(0..4) (every arc, loops included), then removals that repack rows and positions.
        var pairs: [(Int, Int)] = []
        for a in 0 ..< 5 { for b in 0 ..< 5 { pairs.append((a, b)) } }
        var list = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        list.remove(edge: DirectedEdge(from: 0, to: 1))
        list.remove(edge: DirectedEdge(from: 2, to: 2))
        list.remove(edge: DirectedEdge(from: 3, to: 0))
        list.remove(1)
        list.insert(edge: DirectedEdge(from: 4, to: 7))
        list.insert(edge: DirectedEdge(from: 7, to: 0))
        let vertices = Array(list.vertices)
        let edges = Array(list.edges)
        let rows = vertices.map { Array(list.outEdges(of: $0)) }
        #expect(rows.contains { $0 != $0.sorted() })

        // Brute force over the list's own rows, as above but directed: no orientation to choose.
        let n = vertices.count
        var number: [Int: Int] = [:]
        for (i, v) in vertices.enumerated() { number[v] = i }
        var found: [(key: [Int], vertices: [Int], edges: [Int])] = []
        for s in 0 ..< n {
            var pathVertices = [s]
            var pathEdges: [Int] = []
            func extend() {
                let v = pathVertices[pathVertices.count - 1]
                for e in rows[v] {
                    let w = number[edges[e].target]!
                    if w == s {
                        let ce = pathEdges + [e]
                        found.append(([s] + zip(pathVertices, ce).map { rows[$0.0].firstIndex(of: $0.1)! }, pathVertices, ce))
                    } else if w > s && !pathVertices.contains(w) {
                        pathVertices.append(w)
                        pathEdges.append(e)
                        extend()
                        pathVertices.removeLast()
                        pathEdges.removeLast()
                    }
                }
            }
            extend()
        }
        let expected = found.sorted { $0.key.lexicographicallyPrecedes($1.key) }
        #expect(!expected.isEmpty)
        let cycles = Array(list.simpleCycles())
        #expect(cycles.map(\.vertices) == expected.map { $0.vertices.map { vertices[$0] } })
        #expect(cycles.map(\.edges) == expected.map(\.edges))
        let reference = ReferenceDirectedMultigraph(vertices: vertices, edges: edges)
        #expect(Set(cycles) == Set(reference.simpleCycles()))
        #expect(list.girth() == reference.girth())
    }
}
