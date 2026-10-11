// Equality (catalog LG-082 – LG-086): equal label sets and equal labeled edge sets, whatever the
// index assignment.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import Testing

@Suite("LabeledGraphs equality")
struct LabeledGraphEqualityTests {
    @Test("LG-082 same labels, same order", .tags(.conformance))
    func lg082() {
        // CSR V []; E [a→b] == CSR V [a, b]; E [a→b] → true
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs == lhs)
    }

    @Test("LG-083 same labeled graph, different index assignment", .tags(.conformance))
    func lg083() {
        // CSR V [b, a]; E [a→b] == CSR V [a, b]; E [a→b] → true
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["b", "a"] && Array(rhs.vertices) == ["a", "b"])
        #expect(lhs == lhs)
    }

    @Test("LG-084 different label sets", .tags(.conformance))
    func lg084() {
        // CSR V [a, b]; E [] == CSR V [a, c]; E [] → false
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [] as [DirectedEdge<String>])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "c"], edges: [] as [DirectedEdge<String>])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("LG-085 different edges", .tags(.conformance))
    func lg085() {
        // CSR V []; E [a→b] == CSR V []; E [b→a] → false
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "b", to: "a")])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("LG-086 matrix, different index assignment", .tags(.conformance))
    func lg086() {
        // M V [c]; E [a→c, c→a] == M V [a]; E [c→a, a→c] → true
        let lhs = LabeledGraph<String, AdjacencyMatrix>(vertices: ["c"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "a")])
        let rhs = LabeledGraph<String, AdjacencyMatrix>(vertices: ["a"], edges: [DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "c")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["c", "a"] && Array(rhs.vertices) == ["a", "c"])
        #expect(lhs == lhs)
    }
}
