// Equality and hashing (catalog SG-078 – SG-081): equal vertex sets and equal edge multisets;
// positions and holes do not matter.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs equality")
struct StableGraphEqualityTests {
    @Test("SG-078 positions do not matter", .tags(.conformance))
    func sg078() {
        // V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0)  ==  V [0, 1]; E [0→1] → true; equal hashes
        var lhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        _ = lhs.remove(edgeAt: 0)
        let rhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        // Equal values can still differ in positions.
        #expect(Array(lhs.edges.indices) != Array(rhs.edges.indices) || Array(lhs.vertices.indices) != Array(rhs.vertices.indices))
        #expect(lhs == lhs)
    }

    @Test("SG-079 vertex holes do not matter", .tags(.conformance))
    func sg079() {
        // V [9, 0]; E [] / remove(9) / insert(1)  ==  V [0, 1]; E [] → true
        var lhs = StableDirectedGraph<Int>(vertices: [9, 0], edges: [] as [DirectedEdge<Int>])
        _ = lhs.remove(9)
        _ = lhs.insert(1)
        let rhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        // Equal values can still differ in positions.
        #expect(Array(lhs.edges.indices) != Array(rhs.edges.indices) || Array(lhs.vertices.indices) != Array(rhs.vertices.indices))
        #expect(lhs == lhs)
    }

    @Test("SG-080 copies count", .tags(.conformance))
    func sg080() {
        // V [0, 1]; E [0→1, 0→1]  ==  V [0, 1]; E [0→1] → false
        let lhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let rhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }

    @Test("SG-081 orientation counts", .tags(.conformance))
    func sg081() {
        // V [0, 1]; E [0→1]  ==  V [0, 1]; E [1→0] → false
        let lhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let rhs = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0)])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs == lhs)
    }
}
