// §A: undirected cycle detection. `isAcyclic` (a self-loop and a parallel pair are cycles, one
// edge is not), `findCycle()` (the cycle closed by the first edge of a depth-first search, roots
// in `vertices` order, rows in incidence order, skipping the edge it arrived by, returned in
// canonical form) and `findCycle(from:)` (only the roots' components, roots in order). Every graph
// is written as the catalog writes it, on the `ReferencePseudograph` (listed vertices first, then
// endpoints by first appearance; edges in written order, repeats and loops kept), so positions
// are exact. Expected values come from the catalog's reference (`ref.py`). Case IDs (CY-nnn)
// refer to the catalog; see README.md.

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

@Suite("Undirected cycle detection")
struct UndirectedCycleDetectionTests {
    @Test("CY-001 isAcyclic is true: igraph null graph")
    func isAcyclic001() {
        // The empty graph is acyclic (and a forest)
        // []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(graph.isAcyclic)
    }

    @Test("CY-002 findCycle() is nil: igraph null graph")
    func findCycle002() {
        // []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(graph.findCycle() == nil)
    }

    @Test("CY-003 isAcyclic is true: K₁")
    func isAcyclic003() {
        // [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.isAcyclic)
    }

    @Test("CY-004 findCycle() is nil: igraph several isolated vertices")
    func findCycle004() {
        // [0..4]
        let graph = ReferencePseudograph<Int>(vertices: 0 ... 4, edges: [])
        #expect(graph.findCycle() == nil)
    }

    @Test("CY-005 isAcyclic is true: K₂")
    func isAcyclic005() {
        // One edge is not a 2-cycle: an undirected walk may not reuse it
        // 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isAcyclic)
    }

    @Test("CY-006 isAcyclic is false: petgraph is_cyclic_undirected, NetworkX")
    func isAcyclic006() {
        // A self-loop is a cycle
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isAcyclic)
    }

    @Test("CY-007 findCycle() is [0]/[0]: NetworkX test_simple_cycles_singleton")
    func findCycle007() throws {
        // Listed twice in the row, found once
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0])
        #expect(cycle.edges == [0])
    }

    @Test("CY-008 findCycle() is [0,1]/[0,1]: igraph, JGraphT multigraph")
    func findCycle008() throws {
        // A parallel pair is a 2-cycle
        // 0-1 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1])
        #expect(cycle.edges == [0, 1])
    }

    @Test("CY-009 findCycle() is [1]/[0]: igraph find_cycle isolated vertices with self-loops")
    func findCycle009() throws {
        // igraph: vertices (1), edges (0)
        // [0..2] 1-1 1-1 2-2
        let pairs: [(Int, Int)] = [(1, 1), (1, 1), (2, 2)]
        let graph = ReferencePseudograph(vertices: 0 ... 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [1])
        #expect(cycle.edges == [0])
    }

    @Test("CY-010 findCycle() is [3,4]/[1,2]: igraph find_cycle small undirected multigraph")
    func findCycle010() throws {
        // igraph: vertices (4 3), edges (1 2): the same cycle, other start
        // [0..4] 1-2 3-4 3-4 3-4
        let pairs: [(Int, Int)] = [(1, 2), (3, 4), (3, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ... 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [3, 4])
        #expect(cycle.edges == [1, 2])
    }

    @Test("CY-011 isAcyclic is true: NetworkX TestFindCycle (nx.Graph, repeats collapsed)")
    func isAcyclic011() {
        // test_graph_nocycle
        // -1-0 0-1 2-1 3-1
        let pairs: [(Int, Int)] = [(-1, 0), (0, 1), (2, 1), (3, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isAcyclic)
    }

    @Test("CY-012 findCycle(from:) is nil: NetworkX test_graph_nocycle")
    func findCycleFromRoots012() {
        // -1-0 0-1 2-1 3-1
        let pairs: [(Int, Int)] = [(-1, 0), (0, 1), (2, 1), (3, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.findCycle(from: [0, 1, 2, 3]) == nil)
    }

    @Test("CY-013 findCycle(from:) is [0,1]/[1,2]: NetworkX test_multigraph (nx.MultiGraph)")
    func findCycleFromRoots013() throws {
        // NetworkX: [(0,1,0),(1,0,1)] "or (1,0,2)"; ours is pinned: the second copy
        // -1-0 0-1 1-0 1-0 2-1 3-1
        let pairs: [(Int, Int)] = [(-1, 0), (0, 1), (1, 0), (1, 0), (2, 1), (3, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle(from: [0, 1, 2, 3]))
        #expect(cycle.vertices == [0, 1])
        #expect(cycle.edges == [1, 2])
    }

    @Test("CY-014 findCycle(from:) is [0,1,2]/[1,2,4]: NetworkX test_graph_cycle")
    func findCycleFromRoots014() throws {
        // NetworkX: [(0,1),(1,2),(2,0)]
        // -1-0 0-1 2-1 3-1 2-0
        let pairs: [(Int, Int)] = [(-1, 0), (0, 1), (2, 1), (3, 1), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle(from: [0, 1, 2, 3]))
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [1, 2, 4])
    }

    @Test("CY-015 findCycle() is [0,1,2]/[0,2,1]: NetworkX test_dag with orientation=\"ignore\"")
    func findCycle015() throws {
        // NetworkX: [(0,1,F),(1,2,F),(0,2,R)]; in Grafluent digraph.undirected.findCycle()
        // 0-1 0-2 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 2, 1])
    }

    @Test("CY-016 findCycle(from:) is nil: forest, then a cycle")
    func findCycleFromRoots016() {
        // Only 0's component is searched
        // P(0,1,2) C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.findCycle(from: [0]) == nil)
    }

    @Test("CY-017 findCycle(from:) is [3,4,5]/[2,3,4]")
    func findCycleFromRoots017() throws {
        // P(0,1,2) C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle(from: [0, 3]))
        #expect(cycle.vertices == [3, 4, 5])
        #expect(cycle.edges == [2, 3, 4])
    }

    @Test("CY-018 findCycle() is [3,4,5]/[2,3,4]")
    func findCycle018() throws {
        // P(0,1,2) C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [3, 4, 5])
        #expect(cycle.edges == [2, 3, 4])
    }

    @Test("CY-019 isAcyclic is false")
    func isAcyclic019() {
        // P(0,1,2) C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isAcyclic)
    }

    @Test("CY-020 findCycle() is [3,4,5]/[3,4,5]: lollipop")
    func findCycle020() throws {
        // P(0..3) C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [3, 4, 5])
        #expect(cycle.edges == [3, 4, 5])
    }

    @Test("CY-021 findCycle() is [4]/[4]: loop at a leaf")
    func findCycle021() throws {
        // P(0..4) 4-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [4])
        #expect(cycle.edges == [4])
    }

    @Test("CY-022 findCycle() is [0,1,2]/[0,1,2]: triangle and loop")
    func findCycle022() throws {
        // 1's row reaches 2 before its loop: the triangle closes first
        // 0-1 1-2 2-0 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
    }

    @Test("CY-023 findCycle() is [1]/[0]: loop first")
    func findCycle023() throws {
        // Vertex 1 is first in vertices; its loop is its first edge
        // 1-1 0-1 1-2 2-0
        let pairs: [(Int, Int)] = [(1, 1), (0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [1])
        #expect(cycle.edges == [0])
    }

    @Test("CY-024 findCycle() is [1,2]/[1,2]: parallel copy of the tree edge")
    func findCycle024() throws {
        // Skips the parent EDGE, not the parent vertex
        // 0-1 1-2 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [1, 2])
        #expect(cycle.edges == [1, 2])
    }

    @Test("CY-025 findCycle() is [0,1,2,3]/[0,1,2,3]: C₄ with a chord")
    func findCycle025() throws {
        // The depth-first search walks the rim first
        // C(0..3) 0-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1, 2, 3])
        #expect(cycle.edges == [0, 1, 2, 3])
    }

    @Test("CY-026 findCycle() is [0,3,2]/[3,2,4]: the same, rows reversed")
    func findCycle026() throws {
        // Which cycle depends on incidence order; the form does not
        // C(0..3) 0-2 ~rev
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let graph = ReorderedPseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .reversed)
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 3, 2])
        #expect(cycle.edges == [3, 2, 4])
    }

    @Test("CY-027 findCycle() is [1,2,5,4]/[2,4,7,3]: grid")
    func findCycle027() throws {
        // grid(3,3)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7),
            (7, 8)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [1, 2, 5, 4])
        #expect(cycle.edges == [2, 4, 7, 3])
    }

    @Test("CY-028 isAcyclic is true: star")
    func isAcyclic028() {
        // S(0;1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isAcyclic)
    }

    @Test("CY-029 isAcyclic is true: NetworkX random_labeled_tree(10, seed=42)")
    func isAcyclic029() {
        // [0..9] 0-6 0-4 1-5 1-2 1-8 2-3 3-4 3-7 8-9
        let pairs: [(Int, Int)] = [(0, 6), (0, 4), (1, 5), (1, 2), (1, 8), (2, 3), (3, 4), (3, 7), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isAcyclic)
    }

    @Test("CY-030 isAcyclic is true: NetworkX empty_graph(10)")
    func isAcyclic030() {
        // [0..9]
        let graph = ReferencePseudograph<Int>(vertices: 0 ... 9, edges: [])
        #expect(graph.isAcyclic)
    }

    @Test("CY-031 findCycle() is [A,B,C]/[0,1,2]: String vertices")
    func findCycle031() throws {
        // A-B B-C C-A
        let pairs: [(String, String)] = [("A", "B"), ("B", "C"), ("C", "A")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == ["A", "B", "C"])
        #expect(cycle.edges == [0, 1, 2])
    }

    @Test("CY-032 findCycle() is [0,1,2]/[0,3,1]: K₄")
    func findCycle032() throws {
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 3, 1])
    }

    @Test("CY-033 findCycle() is [0,1]/[0,1]: JGraphT AsUndirectedGraph of D: 0>1 1>0")
    func findCycle033() throws {
        // Opposite arcs read as parallel edges: a 2-cycle
        // 0-1 1-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [0, 1])
        #expect(cycle.edges == [0, 1])
    }

    @Test("CY-034 findCycle(from:) is nil: loop on an isolated vertex")
    func findCycleFromRoots034() {
        // P(0,1,2) [3] 3-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.findCycle(from: [0]) == nil)
    }

    @Test("CY-035 findCycle() is [3]/[2]")
    func findCycle035() throws {
        // P(0,1,2) 3-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle())
        #expect(cycle.vertices == [3])
        #expect(cycle.edges == [2])
    }

    @Test("CY-036 isAcyclic is false: m ≥ n means cyclic")
    func isAcyclic036() {
        // m = 3 < n = 5 and still cyclic: the m ≥ n shortcut only rejects
        // C(0,1,2) [3,4]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: 0 ... 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isAcyclic)
    }

    @Test("CY-037 isAcyclic is false")
    func isAcyclic037() {
        // P(0..5) 5-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isAcyclic)
    }

    @Test("CY-038 findCycle(from:) is [2,3,4]/[1,2,3]: roots repeated and out of order")
    func findCycleFromRoots038() throws {
        // Searches from 4 first
        // P(0,1) C(2,3,4)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycle = try #require(graph.findCycle(from: [4, 0, 4]))
        #expect(cycle.vertices == [2, 3, 4])
        #expect(cycle.edges == [1, 2, 3])
    }

    @Test("CY-039 isAcyclic is false: NetworkX test_dag")
    func isAcyclic039() {
        // D: 0>1 0>2 1>2 is acyclic as a digraph, not as a graph
        // 0-1 0-2 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isAcyclic)
    }
}
