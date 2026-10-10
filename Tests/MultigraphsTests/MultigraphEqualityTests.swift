// Equality and hashing (catalog MG-115 – MG-128): equal vertex sets and equal edge multisets (each
// edge with the same number of copies; orientation ignored for the undirected types). Vertex
// order, positions, rows and class order do not matter.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs equality")
struct MultigraphEqualityTests {
    @Test("MG-115 same edges, other order", .tags(.conformance))
    func mg115() {
        // Pseudograph V [] E [0–1, 0–1, 1–2] vs V [] E [1–2, 0–1, 1–0] → == true; equal hashes
        let lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(1, 0)])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-116 copy count differs", .tags(.conformance))
    func mg116() {
        // Pseudograph V [] E [0–1, 0–1] vs V [] E [0–1] → == false
        let lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("MG-117 orientation ignored", .tags(.conformance))
    func mg117() {
        // Pseudograph V [] E [0–1] vs V [] E [1–0] → == true; equal hashes
        let lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1)])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 0)])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-118 isolated vertex differs", .tags(.conformance))
    func mg118() {
        // Pseudograph V [2] E [0–1] vs V [] E [0–1] → == false
        let lhs = Pseudograph<Int>(vertices: [2], edges: [UndirectedEdge(0, 1)])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("MG-119 vertex order ignored", .tags(.conformance))
    func mg119() {
        // Pseudograph V [0, 1, 2] E [] vs V [2, 1, 0] E [] → == true; equal hashes
        let lhs = Pseudograph<Int>(vertices: [0, 1, 2], edges: [] as [UndirectedEdge<Int>])
        let rhs = Pseudograph<Int>(vertices: [2, 1, 0], edges: [] as [UndirectedEdge<Int>])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-120 loop count differs", .tags(.conformance))
    func mg120() {
        // Pseudograph V [] E [0–0] vs V [] E [0–0, 0–0] → == false
        let lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0)])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("MG-121 after removal equal to fresh", .tags(.conformance))
    func mg121() {
        // Pseudograph V [] E [0–1, 1–2, 0–1] then remove(edgeAt: 0) vs V [] E [1–2, 0–1] → == true; equal hashes
        var lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1)])
        lhs.remove(edgeAt: 0)
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1)])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-122 directed orientation matters", .tags(.conformance))
    func mg122() {
        // DirectedPseudograph V [] E [0→1] vs V [] E [1→0] → == false
        let lhs = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1)])
        let rhs = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 1, to: 0)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("MG-123 directed copies", .tags(.conformance))
    func mg123() {
        // DirectedPseudograph V [] E [0→1, 0→1, 1→0] vs V [] E [1→0, 0→1, 0→1] → == true; equal hashes
        let lhs = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let rhs = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-124 directed copy count differs", .tags(.conformance))
    func mg124() {
        // DirectedPseudograph V [] E [0→1, 1→0] vs V [] E [0→1, 0→1] → == false
        let lhs = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let rhs = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("MG-125 empty graphs", .tags(.conformance))
    func mg125() {
        // Pseudograph V [] E [] vs V [] E [] → == true; equal hashes
        let lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-126 multigraph same edges", .tags(.conformance))
    func mg126() throws {
        // Multigraph V [] E [0–1, 1–0] vs V [] E [0–1, 0–1] → == true; equal hashes
        let lhs = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]))
        let rhs = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }

    @Test("MG-127 same edge multiset, different pairs", .tags(.conformance))
    func mg127() {
        // Pseudograph V [] E [0–1, 2–3] vs V [] E [0–2, 1–3] → == false
        let lhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let rhs = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("MG-128 strings", .tags(.conformance))
    func mg128() {
        // Pseudograph V [] E ["a"–"b", "b"–"a"] vs V [] E ["b"–"a", "a"–"b"] → == true; equal hashes
        let lhs = Pseudograph<String>(vertices: [] as [String], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "a")])
        let rhs = Pseudograph<String>(vertices: [] as [String], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "b")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == lhs)
    }
}
