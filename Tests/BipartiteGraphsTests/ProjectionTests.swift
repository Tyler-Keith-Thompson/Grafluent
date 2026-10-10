// `projectedGraph(onto:)` (catalog BP-150 – BP-161): the side's vertices in `left` or `right`
// order, isolated ones included, and an edge between two of them iff they share a neighbour,
// once however many they share, never a self-loop. Positions follow api.md's discovery order
// (for each u in side order, each neighbour w in u's row, each x ≠ u in w's row: {u, x}), and
// edges are compared as [u, v]. ref.py checks every row against NetworkX 3.7's
// `projected_graph`. Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("projectedGraph(onto:)")
struct ProjectionTests {
    @Test("BP-150 K2,3 onto left: one edge")
    func bp150() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [0, 1] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.edgeCount == 1)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-151 K2,3 onto right: a triangle")
    func bp151() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; projectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .right)
        #expect(Array(projection.vertices) == [2, 3, 4] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [[2, 3], [2, 4], [3, 4]] as [[Int]])
        #expect(projection.edgeCount == 3)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-152 star centre left, onto right: K4")
    func bp152() throws {
        // left [0], right [1, 2, 3, 4], edges [0–1, 0–2, 0–3, 0–4]; projectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1, 2, 3, 4] as [Int], edges: [(0, 1), (0, 2), (0, 3), (0, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .right)
        #expect(Array(projection.vertices) == [1, 2, 3, 4] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] as [[Int]])
        #expect(projection.edgeCount == 6)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-153 star centre left, onto left: one isolated vertex")
    func bp153() throws {
        // left [0], right [1, 2, 3, 4], edges [0–1, 0–2, 0–3, 0–4]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1, 2, 3, 4] as [Int], edges: [(0, 1), (0, 2), (0, 3), (0, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [0] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(projection.edgeCount == 0)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-154 path a–x–b–y–c onto left: path a–b–c")
    func bp154() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == ["a", "b", "c"] as [String])
        #expect(projection.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"]] as [[String]])
        #expect(projection.edgeCount == 2)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-155 path onto right: one edge x–y")
    func bp155() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; projectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .right)
        #expect(Array(projection.vertices) == ["x", "y"] as [String])
        #expect(projection.edges.map { [$0.u, $0.v] } == [["x", "y"]] as [[String]])
        #expect(projection.edgeCount == 1)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-156 edgeless: isolated vertices of the side")
    func bp156() throws {
        // left [0, 1], right [2]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2] as [Int], edges: [UndirectedEdge<Int>]()))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [0, 1] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(projection.edgeCount == 0)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-157 empty side")
    func bp157() throws {
        // left [], right [0, 1]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [] as [Int], right: [0, 1] as [Int], edges: [UndirectedEdge<Int>]()))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(projection.edgeCount == 0)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-158 two shared neighbours give one edge (simple projection)")
    func bp158() throws {
        // left [0, 1], right [2, 3], edges [0–2, 0–3, 1–2, 1–3]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3] as [Int], edges: [(0, 2), (0, 3), (1, 2), (1, 3)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [0, 1] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.edgeCount == 1)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-159 isolated left vertex kept")
    func bp159() throws {
        // left [0, 1, 5], right [2], edges [0–2, 1–2]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 5] as [Int], right: [2] as [Int], edges: [(0, 2), (1, 2)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [0, 1, 5] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.edgeCount == 1)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-160 C6 onto one side: a triangle")
    func bp160() throws {
        // left [0, 2, 4], right [1, 3, 5], edges [0–1, 1–2, 2–3, 3–4, 4–5, 5–0]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 2, 4] as [Int], right: [1, 3, 5] as [Int], edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == [0, 2, 4] as [Int])
        #expect(projection.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 4], [2, 4]] as [[Int]])
        #expect(projection.edgeCount == 3)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }

    @Test("BP-161 affiliation network: people onto events they share")
    func bp161() throws {
        // left [p1, p2, p3, p4], right [e1, e2, e3], edges [p1–e1, p2–e1, p2–e2, p3–e2, p4–e3]; projectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["p1", "p2", "p3", "p4"] as [String], right: ["e1", "e2", "e3"] as [String], edges: [("p1", "e1"), ("p2", "e1"), ("p2", "e2"), ("p3", "e2"), ("p4", "e3")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == ["p1", "p2", "p3", "p4"] as [String])
        #expect(projection.edges.map { [$0.u, $0.v] } == [["p1", "p2"], ["p2", "p3"]] as [[String]])
        #expect(projection.edgeCount == 2)
        #expect(projection.edges.allSatisfy { !$0.isSelfLoop })
    }
}
