// §B: directed recognition. `isArborescence` (at least one vertex, exactly one vertex of in-degree
// 0, every other of in-degree 1, and every vertex reachable from that root) and `Arborescence(g)`,
// nil exactly when `isArborescence` is false. Every digraph is written as the catalog writes it,
// on the `ReferenceDirectedMultigraph` (listed vertices first, then endpoints by first appearance;
// arcs in written order, repeats and loops kept), so positions are exact. Expected values come
// from the catalog's reference (`ref.py`, cross-checked against NetworkX's `is_arborescence`).
// Case IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Arborescence recognition")
struct ArborescenceRecognitionTests {
    @Test("TS-050 isArborescence is false on the null graph")
    func nullGraph() {
        // NetworkX raises on the null graph.
        // D: []
        let graph = ReferenceDirectedMultigraph<Int>(edges: [])
        #expect(!graph.isArborescence)
        #expect(Arborescence(graph) == nil)
        #expect(Arborescence<Int>(edges: []) == nil)
    }

    @Test("TS-051 Arborescence(g) of one vertex has root 0")
    func singleVertex() throws {
        // D: [0]
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [0], edges: [])
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.root == 0)
        #expect(graph.isArborescence)
    }

    @Test("TS-052 Arborescence(g) of 0>1, 0>2 has root 0")
    func smallOutStar() throws {
        // D: 0>1, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.root == 0)
    }

    @Test("TS-053 isArborescence is false: an in-tree, in-degree 2 at 0")
    func inTree() {
        // D: 1>0, 2>0
        let pairs: [(Int, Int)] = [(1, 0), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
    }

    @Test("TS-054 isArborescence is false: a polytree that is not an arborescence")
    func polytree() {
        // D: 0>1, 2>1
        let pairs: [(Int, Int)] = [(0, 1), (2, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
        #expect(Arborescence(graph) == nil)
    }

    @Test("TS-055 isArborescence is false: a directed triangle has no root")
    func directedTriangle() {
        // D: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
    }

    @Test("TS-056 isArborescence is false: m = n, in-degree 2 at 1")
    func extraArc() {
        // D: 0>1, 1>2, 2>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
    }

    @Test("TS-057 isArborescence is false: parallel arcs")
    func parallelArcs() {
        // D: 0>1, 0>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
        #expect(Arborescence(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }) == nil)
    }

    @Test("TS-058 isArborescence is false: a self-loop")
    func selfLoop() {
        // D: 0>0
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0)])
        #expect(!graph.isArborescence)
        #expect(Arborescence(graph) == nil)
    }

    @Test("TS-059 isArborescence is false: opposite arcs")
    func oppositeArcs() {
        // D: 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
    }

    @Test("TS-060 isArborescence is false: a branching of two arcs")
    func branching() {
        // D: 0>1, 2>3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
    }

    @Test("TS-061 isArborescence is false: two roots")
    func twoRoots() {
        // D: [0,1]
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1], edges: [])
        #expect(!graph.isArborescence)
        #expect(Arborescence(graph) == nil)
    }

    @Test("TS-062 Arborescence(g).root is 3: the root is not the first vertex")
    func rootNotFirst() throws {
        // D: 3>1, 1>0, 1>2
        let pairs: [(Int, Int)] = [(3, 1), (1, 0), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.root == 3)
        #expect(Array(arborescence.vertices) == [3, 1, 0, 2])
    }

    @Test("TS-063 Arborescence(g).edges keeps positions: [1>2, 0>1]")
    func positionsKept() throws {
        // D: 1>2, 0>1
        let pairs: [(Int, Int)] = [(1, 2), (0, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let expected: [(Int, Int)] = [(1, 2), (0, 1)]
        #expect(Array(arborescence.edges) == expected.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(arborescence.root == 0)
    }

    @Test("TS-064 isArborescence is true: NetworkX is_arborescence docstring")
    func networkXDocstring() {
        // D: 0>1, 0>2, 2>3, 3>4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 3), (3, 4)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.isArborescence)
    }

    @Test("TS-065 isArborescence is false: the docstring graph after remove_edge(0, 1); add_edge(1, 2)")
    func networkXDocstringModified() {
        // D: 0>2, 1>2, 2>3, 3>4
        let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 3), (3, 4)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(!graph.isArborescence)
    }

    @Test("TS-066 Arborescence(g).children(of: x) is [y, z]: String vertices")
    func stringVertices() throws {
        // D: x>y, x>z, z>w
        let pairs: [(String, String)] = [("x", "y"), ("x", "z"), ("z", "w")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.children(of: "x")) == ["y", "z"])
        #expect(arborescence.root == "x")
    }

    @Test("TS-067 isArborescence is false: m = n − 1, a loop makes 1's in-degree 2 and leaves 2 a second root")
    func loopAndSecondRoot() {
        // D: [0,1,2] 0>1, 1>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1, 2], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == graph.vertexCount - 1)
        #expect(!graph.isArborescence)
    }

    @Test("TS-068 isArborescence is false: in-degrees ≤ 1, one root, n − 1 arcs, but 2 and 3 are not reached")
    func reachabilityNeeded() {
        // D: [0,1,2,3] 0>1, 2>3, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1, 2, 3], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edgeCount == graph.vertexCount - 1)
        #expect(!graph.isArborescence)
        #expect(Arborescence(graph) == nil)
        #expect(Arborescence(vertices: [0, 1, 2, 3], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }) == nil)
    }

    @Test("TS-050 – TS-068 isArborescence ⇔ Arborescence(g) != nil on every §B source")
    func equivalenceOnEverySource() {
        let sources: [(vertices: [Int], arcs: [(Int, Int)])] = [
            ([], []),
            ([0], []),
            ([], [(0, 1), (0, 2)]),
            ([], [(1, 0), (2, 0)]),
            ([], [(0, 1), (2, 1)]),
            ([], [(0, 1), (1, 2), (2, 0)]),
            ([], [(0, 1), (1, 2), (2, 1)]),
            ([], [(0, 1), (0, 1)]),
            ([], [(0, 0)]),
            ([], [(0, 1), (1, 0)]),
            ([], [(0, 1), (2, 3)]),
            ([0, 1], []),
            ([], [(3, 1), (1, 0), (1, 2)]),
            ([], [(1, 2), (0, 1)]),
            ([], [(0, 1), (0, 2), (2, 3), (3, 4)]),
            ([], [(0, 2), (1, 2), (2, 3), (3, 4)]),
            ([0, 1, 2], [(0, 1), (1, 1)]),
            ([0, 1, 2, 3], [(0, 1), (2, 3), (3, 2)]),
        ]
        for source in sources {
            let graph = ReferenceDirectedMultigraph(vertices: source.vertices, edges: source.arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let isArborescence = graph.isArborescence
            let built = Arborescence(graph) != nil
            #expect(isArborescence == built, "\(source)")
        }
    }
}

