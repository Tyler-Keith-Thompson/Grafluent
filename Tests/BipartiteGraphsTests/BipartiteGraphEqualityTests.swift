// Equality (catalog BP-162 – BP-166): vertex sets, edge sets and each vertex's side, not orders
// or orientations; the same graph with its sides swapped is a different value. Equal values
// hash alike. Generated from cases.md by swiftgen.py; see README.md.

import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("BipartiteGraph equality", .tags(.conformance))
struct BipartiteGraphEqualityTests {
    @Test("BP-162 same sides and edges, different insertion order: true")
    func bp162() throws {
        // (left [a, b], right [x], edges [a–x, b–x]) == (left [b, a], right [x], edges [x–b, a–x])
        let a = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String], edges: [("a", "x"), ("b", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let b = try #require(BipartiteGraph<String>(left: ["b", "a"] as [String], right: ["x"] as [String], edges: [("x", "b"), ("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect((a == b) == true)
        #expect((b == a) == true)
        #expect(a == a && b == b)
        #expect(a.hashValue == b.hashValue)
        #expect(Set([a, b]).count == 1)
    }

    @Test("BP-163 same graph, sides swapped: not equal: false")
    func bp163() throws {
        // (left [a], right [x], edges [a–x]) == (left [x], right [a], edges [a–x])
        let a = try #require(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let b = try #require(BipartiteGraph<String>(left: ["x"] as [String], right: ["a"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect((a == b) == false)
        #expect((b == a) == false)
        #expect(a == a && b == b)
        #expect(Set([a, b]).count == 2)
    }

    @Test("BP-164 same sides, different edges: false")
    func bp164() throws {
        // (left [a, b], right [x], edges [a–x]) == (left [a, b], right [x], edges [b–x])
        let a = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let b = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String], edges: [("b", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect((a == b) == false)
        #expect((b == a) == false)
        #expect(a == a && b == b)
        #expect(Set([a, b]).count == 2)
    }

    @Test("BP-165 an extra isolated vertex: false")
    func bp165() throws {
        // (left [a], right [x], edges [a–x]) == (left [a, b], right [x], edges [a–x])
        let a = try #require(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let b = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x"] as [String], edges: [("a", "x")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect((a == b) == false)
        #expect((b == a) == false)
        #expect(a == a && b == b)
        #expect(Set([a, b]).count == 2)
    }

    @Test("BP-166 empty and empty: true")
    func bp166() throws {
        // (left [], right []) == (left [], right [])
        let a = try #require(BipartiteGraph<String>(left: [] as [String], right: [] as [String]))
        let b = try #require(BipartiteGraph<String>(left: [] as [String], right: [] as [String]))
        #expect((a == b) == true)
        #expect((b == a) == true)
        #expect(a == a && b == b)
        #expect(a.hashValue == b.hashValue)
        #expect(Set([a, b]).count == 1)
    }
}
