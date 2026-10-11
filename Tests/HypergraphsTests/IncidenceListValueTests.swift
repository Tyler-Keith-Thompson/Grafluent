// Equality, hashing, description and Codable (catalog DH-046 – DH-056): equal vertex sets and equal
// multisets of (source set, target set) pairs; Codable as {vertices, sources, targets}, and the
// decoder's re-checks as dataCorrupted.
// Generated from cases.md by swiftgen.py; see README.md.

import Foundation
import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import Testing

@Suite("IncidenceList equality, description and Codable")
struct IncidenceListValueTests {
    @Test("DH-046 same hypergraph, any vertex and hyperedge order", .tags(.conformance))
    func dh046() {
        // D V [c]; E [{a}→{b, c}, {c}→{}] == D V []; E [{c}→{}, {a}→{c, b}] → true
        let lhs = IncidenceList<String>(vertices: ["c"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["c"], targets: [])] as [(sources: [String], targets: [String])])
        let rhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["c"], targets: []), (sources: ["a"], targets: ["c", "b"])] as [(sources: [String], targets: [String])])
        #expect(lhs == rhs && rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(lhs == lhs)
    }

    @Test("DH-047 direction matters", .tags(.conformance))
    func dh047() {
        // D V []; E [{a}→{b}] == D V []; E [{b}→{a}] → false
        let lhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["b"])] as [(sources: [String], targets: [String])])
        let rhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["b"], targets: ["a"])] as [(sources: [String], targets: [String])])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("DH-048 a vertex on both sides differs from it on one", .tags(.conformance))
    func dh048() {
        // D V []; E [{a}→{a, b}] == D V []; E [{a}→{b}] → false
        let lhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["a", "b"])] as [(sources: [String], targets: [String])])
        let rhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["b"])] as [(sources: [String], targets: [String])])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("DH-049 multiplicity matters", .tags(.conformance))
    func dh049() {
        // D V []; E [{a}→{b}] == D V []; E [{a}→{b}, {a}→{b}] → false
        let lhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["b"])] as [(sources: [String], targets: [String])])
        let rhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["b"]), (sources: ["a"], targets: ["b"])] as [(sources: [String], targets: [String])])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("DH-050 equal hypergraphs hash equal", .tags(.conformance))
    func dh050() {
        // Set([D V [c]; E [{a}→{b, c}], D V []; E [{a}→{c, b}]]).count → 1
        let lhs = IncidenceList<String>(vertices: ["c"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        let rhs = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["c", "b"])] as [(sources: [String], targets: [String])])
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == rhs && rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["c", "a", "b"] && Array(rhs.vertices) == ["a", "c", "b"])
        #expect(lhs == lhs)
    }

    @Test("DH-051 description: vertices, then sources→targets by position", .tags(.conformance))
    func dh051() {
        // D V []; E [{a, b}→{c}, {}→{}] / description / debugDescription
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a", "b"], targets: ["c"]), (sources: [], targets: [])] as [(sources: [String], targets: [String])])
        #expect(hypergraph.description == "[\"a\", \"b\", \"c\"]; [{\"a\", \"b\"}→{\"c\"}, {}→{}]")
        #expect(hypergraph.debugDescription == "IncidenceList<String>(vertexCount: 3, hyperedgeCount: 2, vertices: [\"a\", \"b\", \"c\"], hyperedges: [{\"a\", \"b\"}→{\"c\"}, {}→{}])")
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["c"]], [[], []]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 1])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [2])
        #expect(hypergraph.contains(sources: ["b", "a"] as [String], targets: ["c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 0 && hypergraph.inDegree(ofIndex: 1) == 0)
        #expect(hypergraph.degree(of: "b") == 1)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0])
        #expect(hypergraph.outDegree(of: "c") == 0 && hypergraph.outDegree(ofIndex: 2) == 0 && hypergraph.inDegree(of: "c") == 1 && hypergraph.inDegree(ofIndex: 2) == 1)
        #expect(hypergraph.degree(of: "c") == 1)
    }

    @Test("DH-052 encodes vertices, then parallel source and target rows", .tags(.conformance))
    func dh052() throws {
        // D V []; E [{a, b}→{c}, {}→{a}] / JSONEncoder().encode(self)
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a", "b"], targets: ["c"]), (sources: [], targets: ["a"])] as [(sources: [String], targets: [String])])
        do {
            // {"vertices":["a","b","c"],"sources":[[0,1],[]],"targets":[[2],[0]]}
            let data = try JSONEncoder().encode(hypergraph)
            struct Payload: Decodable, Equatable { let vertices: [String]; let sources: [[Int]]; let targets: [[Int]] }
            #expect(try JSONDecoder().decode(Payload.self, from: data) == Payload(vertices: ["a", "b", "c"], sources: [[0, 1], []], targets: [[2], [0]]))
            let decoded = try JSONDecoder().decode(IncidenceList<String>.self, from: data)
            #expect(Array(decoded.vertices) == ["a", "b", "c"])
            #expect(decoded.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["c"]], [[], ["a"]]])
            #expect(decoded == hypergraph)
        }
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["c"]], [[], ["a"]]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 1])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [2])
        #expect(hypergraph.contains(sources: ["b", "a"] as [String], targets: ["c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["a"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [0])
        #expect(hypergraph.contains(sources: [] as [String], targets: ["a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [1])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 1 && hypergraph.inDegree(ofIndex: 0) == 1)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 0 && hypergraph.inDegree(ofIndex: 1) == 0)
        #expect(hypergraph.degree(of: "b") == 1)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0])
        #expect(hypergraph.outDegree(of: "c") == 0 && hypergraph.outDegree(ofIndex: 2) == 0 && hypergraph.inDegree(of: "c") == 1 && hypergraph.inDegree(ofIndex: 2) == 1)
        #expect(hypergraph.degree(of: "c") == 1)
    }

    @Test("DH-053 decodes", .tags(.conformance))
    func dh053() throws {
        // decode {"vertices":["a","b"],"sources":[[0],[]],"targets":[[0,1],[1]]} → V [a#0, b#1]; E [0:{a}→{a, b}, 1:{}→{b}]
        let payload = Data(#"{"vertices":["a","b"],"sources":[[0],[]],"targets":[[0,1],[1]]}"#.utf8)
        let hypergraph = try JSONDecoder().decode(IncidenceList<String>.self, from: payload)
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["a", "b"]], [[], ["b"]]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [0, 1])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["b", "a"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [1])
        #expect(hypergraph.contains(sources: [] as [String], targets: ["b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 1 && hypergraph.inDegree(ofIndex: 0) == 1)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 1] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 1])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 2)
        #expect(try JSONDecoder().decode(IncidenceList<String>.self, from: JSONEncoder().encode(hypergraph)) == hypergraph)
    }

    @Test("DH-054 rejects source and target lists of different lengths", .tags(.conformance))
    func dh054() throws {
        // decode {"vertices":["a"],"sources":[[0]],"targets":[]} → throws DecodingError.dataCorrupted (sources and targets differ in length)
        let payload = Data(#"{"vertices":["a"],"sources":[[0]],"targets":[]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(IncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("DH-055 rejects a repeated member inside one side", .tags(.conformance))
    func dh055() throws {
        // decode {"vertices":["a","b"],"sources":[[1,1]],"targets":[[]]} → throws DecodingError.dataCorrupted (members not strictly ascending)
        let payload = Data(#"{"vertices":["a","b"],"sources":[[1,1]],"targets":[[]]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(IncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("DH-056 rejects an index out of range", .tags(.conformance))
    func dh056() throws {
        // decode {"vertices":["a"],"sources":[[]],"targets":[[3]]} → throws DecodingError.dataCorrupted (member index out of range)
        let payload = Data(#"{"vertices":["a"],"sources":[[]],"targets":[[3]]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(IncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
