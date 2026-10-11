// Equality and hashing (catalog LG-089 – LG-096): equal label sets and equal labeled edge sets,
// whatever the index assignment, and equal values hash alike.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import Testing

@Suite("LabeledGraphs equality")
struct LabeledGraphEqualityTests {
    @Test("LG-089 same labels, same order", .tags(.conformance))
    func lg089() {
        // CSR V []; E [a→b] == CSR V [a, b]; E [a→b] → true
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs == lhs)
    }

    @Test("LG-090 same labeled graph, different index assignment", .tags(.conformance))
    func lg090() {
        // CSR V [b, a]; E [a→b] == CSR V [a, b]; E [a→b] → true
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["b", "a"] && Array(rhs.vertices) == ["a", "b"])
        #expect(lhs == lhs)
    }

    @Test("LG-091 different label sets", .tags(.conformance))
    func lg091() {
        // CSR V [a, b]; E [] == CSR V [a, c]; E [] → false
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [] as [DirectedEdge<String>])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "c"], edges: [] as [DirectedEdge<String>])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("LG-092 different edges", .tags(.conformance))
    func lg092() {
        // CSR V []; E [a→b] == CSR V []; E [b→a] → false
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "b", to: "a")])
        #expect(lhs != rhs)
        #expect(rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("LG-093 matrix, different index assignment", .tags(.conformance))
    func lg093() {
        // M V [c]; E [a→c, c→a] == M V [a]; E [c→a, a→c] → true
        let lhs = LabeledGraph<String, AdjacencyMatrix>(vertices: ["c"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "a")])
        let rhs = LabeledGraph<String, AdjacencyMatrix>(vertices: ["a"], edges: [DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "c")])
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["c", "a"] && Array(rhs.vertices) == ["a", "c"])
        #expect(lhs == lhs)
    }

    @Test("LG-094 same labeled graph, different index assignment", .tags(.conformance))
    func lg094() {
        // Set([CSR V [c, b, a]; E [a→b, b→c], CSR V [b]; E [b→c, a→b]]).count → 1
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["c", "b", "a"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["b"], edges: [DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "b")])
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == rhs)
        #expect(lhs.hashValue == rhs.hashValue)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["c", "b", "a"] && Array(rhs.vertices) == ["b", "c", "a"])
        #expect(lhs.hashValue == lhs.hashValue)
    }

    @Test("LG-095 matrix, opposite arcs, different index assignment", .tags(.conformance))
    func lg095() {
        // Set([M V [b]; E [a→b, b→a, a→a], M V [a]; E [b→a, a→b, a→a]]).count → 1
        let lhs = LabeledGraph<String, AdjacencyMatrix>(vertices: ["b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "a")])
        let rhs = LabeledGraph<String, AdjacencyMatrix>(vertices: ["a"], edges: [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "a")])
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == rhs)
        #expect(lhs.hashValue == rhs.hashValue)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["b", "a"] && Array(rhs.vertices) == ["a", "b"])
        #expect(lhs.hashValue == lhs.hashValue)
    }

    @Test("LG-096 different edges", .tags(.conformance))
    func lg096() {
        // Set([CSR V [a, b]; E [a→b], CSR V [a, b]; E [b→a]]).count → 2
        let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b"], edges: [DirectedEdge(from: "b", to: "a")])
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs != rhs)
        #expect(lhs.hashValue == lhs.hashValue)
    }
}
