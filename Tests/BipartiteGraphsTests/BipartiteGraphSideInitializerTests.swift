// `BipartiteGraph(left:right:)` and `BipartiteGraph(left:right:edges:)` (catalog BP-105 – BP-118):
// `left` then `right` in `vertices` order, repeats within a side dropped, edges in order, a
// repeat in either orientation once, each stored left endpoint first; nil when the sides
// overlap, or an edge is inside a side, a self-loop, or has an endpoint on neither side
// (endpoints are never inserted implicitly). Edges are compared as [u, v] to see the stored
// orientation. Generated from cases.md by swiftgen.py; see README.md.

import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("BipartiteGraph(left:right:) and BipartiteGraph(left:right:edges:)")
struct BipartiteGraphSideInitializerTests {
    @Test("BP-105 no vertices: V [], E []")
    func bp105() throws {
        // left [], right []
        let graph = try #require(BipartiteGraph<String>(left: [] as [String], right: [] as [String]))
        #expect(Array(graph.vertices) == [] as [String])
        #expect(Array(graph.left) == [] as [String])
        #expect(Array(graph.right) == [] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("BP-106 sides only: V [a, b, x], E []")
    func bp106() throws {
        // left [a, b], right [x]
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String]))
        #expect(Array(graph.vertices) == ["a", "b", "x"] as [String])
        #expect(Array(graph.left) == ["a", "b"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 0)
    }

    @Test("BP-107 one edge: V [a, x], E [a–x]")
    func bp107() throws {
        // left [a], right [x], edges [a–x]
        let graph = try #require(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(Array(graph.vertices) == ["a", "x"] as [String])
        #expect(Array(graph.left) == ["a"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
    }

    @Test("BP-108 edge written right endpoint first is stored left first: V [a, x], E [a–x]")
    func bp108() throws {
        // left [a], right [x], edges [x–a]
        let graph = try #require(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: [("x", "a")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(Array(graph.vertices) == ["a", "x"] as [String])
        #expect(Array(graph.left) == ["a"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
    }

    @Test("BP-109 duplicate within a side dropped: V [a, b, x], E [a–x]")
    func bp109() throws {
        // left [a, b, a], right [x], edges [a–x]
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "a"] as [String], right: ["x"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(Array(graph.vertices) == ["a", "b", "x"] as [String])
        #expect(Array(graph.left) == ["a", "b"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
    }

    @Test("BP-110 repeated edge, either orientation, once: V [a, b, x], E [a–x, b–x]")
    func bp110() throws {
        // left [a, b], right [x], edges [a–x, x–a, b–x]
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String], edges: [("a", "x"), ("x", "a"), ("b", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(Array(graph.vertices) == ["a", "b", "x"] as [String])
        #expect(Array(graph.left) == ["a", "b"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
    }

    @Test("BP-111 overlapping sides: nil")
    func bp111() throws {
        // left [a, b], right [b, x]
        #expect(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["b", "x"] as [String]) == nil)
    }

    @Test("BP-112 edge inside left: nil")
    func bp112() throws {
        // left [a, b], right [x], edges [a–b]
        #expect(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String], edges: [("a", "b")].map { UndirectedEdge<String>($0.0, $0.1) }) == nil)
    }

    @Test("BP-113 edge inside right: nil")
    func bp113() throws {
        // left [a], right [x, y], edges [x–y]
        #expect(BipartiteGraph<String>(left: ["a"] as [String], right: ["x", "y"] as [String], edges: [("x", "y")].map { UndirectedEdge<String>($0.0, $0.1) }) == nil)
    }

    @Test("BP-114 self-loop: nil")
    func bp114() throws {
        // left [a], right [x], edges [a–a]
        #expect(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: [("a", "a")].map { UndirectedEdge<String>($0.0, $0.1) }) == nil)
    }

    @Test("BP-115 missing endpoint: nil")
    func bp115() throws {
        // left [a], right [x], edges [a–z]
        #expect(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: [("a", "z")].map { UndirectedEdge<String>($0.0, $0.1) }) == nil)
    }

    @Test("BP-116 empty left side: V [x, y], E []")
    func bp116() throws {
        // left [], right [x, y]
        let graph = try #require(BipartiteGraph<String>(left: [] as [String], right: ["x", "y"] as [String]))
        #expect(Array(graph.vertices) == ["x", "y"] as [String])
        #expect(Array(graph.left) == [] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 0)
    }

    @Test("BP-117 K2,3: V [0, 1, 2, 3, 4], E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]")
    func bp117() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4] as [Int])
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(Array(graph.right) == [2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4]] as [[Int]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 6)
    }

    @Test("BP-118 integer sides interleaved: V [0, 2, 4, 1, 3, 5], E [0–1, 2–1, 2–3, 4–5, 0–5]")
    func bp118() throws {
        // left [0, 2, 4], right [1, 3, 5], edges [0–1, 2–1, 2–3, 4–5, 0–5]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 2, 4] as [Int], right: [1, 3, 5] as [Int], edges: [(0, 1), (2, 1), (2, 3), (4, 5), (0, 5)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        #expect(Array(graph.vertices) == [0, 2, 4, 1, 3, 5] as [Int])
        #expect(Array(graph.left) == [0, 2, 4] as [Int])
        #expect(Array(graph.right) == [1, 3, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3], [4, 5], [0, 5]] as [[Int]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
        #expect(graph.vertexCount == 6)
        #expect(graph.edgeCount == 5)
    }
}
