// Equality, hashing, description and Codable (catalog HG-078 – HG-094): equal vertex sets and equal
// multisets of member sets whatever the order; String(reflecting:) lists elided after 16; Codable as
// {vertices, hyperedges} with ascending rows, and the decoder's re-checks as dataCorrupted.
// Generated from cases.md by swiftgen.py; see README.md.

import Foundation
import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import Testing

@Suite("UndirectedIncidenceList equality, description and Codable")
struct UndirectedIncidenceListValueTests {
    @Test("HG-078 same hypergraph", .tags(.conformance))
    func hg078() {
        // U V [a]; E [{a, b}] == U V [a, b]; E [{b, a}] → true
        let lhs = UndirectedIncidenceList<String>(vertices: ["a"] as [String], hyperedges: [["a", "b"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: ["a", "b"] as [String], hyperedges: [["b", "a"]] as [[String]])
        #expect(lhs == rhs && rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(lhs == lhs)
    }

    @Test("HG-079 different vertex order and hyperedge order", .tags(.conformance))
    func hg079() {
        // U V [c, b, a]; E [{a, b}, {c}] == U V [a, b, c]; E [{c}, {b, a}] → true
        let lhs = UndirectedIncidenceList<String>(vertices: ["c", "b", "a"] as [String], hyperedges: [["a", "b"], ["c"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: ["a", "b", "c"] as [String], hyperedges: [["c"], ["b", "a"]] as [[String]])
        #expect(lhs == rhs && rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["c", "b", "a"] && Array(rhs.vertices) == ["a", "b", "c"])
        #expect(lhs == lhs)
    }

    @Test("HG-080 multiplicity matters", .tags(.conformance))
    func hg080() {
        // U V []; E [{a, b}] == U V []; E [{a, b}, {a, b}] → false
        let lhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], ["a", "b"]] as [[String]])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("HG-081 an empty hyperedge matters", .tags(.conformance))
    func hg081() {
        // U V []; E [{a, b}] == U V []; E [{a, b}, {}] → false
        let lhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], []] as [[String]])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("HG-082 an isolated vertex matters", .tags(.conformance))
    func hg082() {
        // U V []; E [{a, b}] == U V [c]; E [{a, b}] → false
        let lhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: ["c"] as [String], hyperedges: [["a", "b"]] as [[String]])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("HG-083 different member sets", .tags(.conformance))
    func hg083() {
        // U V []; E [{a, b}, {c}] == U V []; E [{a}, {b, c}] → false
        let lhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], ["c"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a"], ["b", "c"]] as [[String]])
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("HG-084 equal hypergraphs hash equal", .tags(.conformance))
    func hg084() {
        // Set([U V [c, b, a]; E [{a, b}, {c}], U V [a, b, c]; E [{c}, {b, a}]]).count → 1
        let lhs = UndirectedIncidenceList<String>(vertices: ["c", "b", "a"] as [String], hyperedges: [["a", "b"], ["c"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: ["a", "b", "c"] as [String], hyperedges: [["c"], ["b", "a"]] as [[String]])
        #expect(Set([lhs, rhs]).count == 1)
        #expect(lhs == rhs && rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        // Equal values with different index assignments.
        #expect(Array(lhs.vertices) == ["c", "b", "a"] && Array(rhs.vertices) == ["a", "b", "c"])
        #expect(lhs == lhs)
    }

    @Test("HG-085 different multiplicity", .tags(.conformance))
    func hg085() {
        // Set([U V []; E [{a, b}], U V []; E [{a, b}, {a, b}]]).count → 2
        let lhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"]] as [[String]])
        let rhs = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], ["a", "b"]] as [[String]])
        #expect(Set([lhs, rhs]).count == 2)
        #expect(lhs != rhs && rhs != lhs)
        #expect(lhs == lhs)
    }

    @Test("HG-086 description: String(reflecting:) vertices, then hyperedges by position", .tags(.conformance))
    func hg086() {
        // U V []; E [{a, b}, {}, {b, c}] / description / debugDescription
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], [], ["b", "c"]] as [[String]])
        #expect(hypergraph.description == "[\"a\", \"b\", \"c\"]; [{\"a\", \"b\"}, {}, {\"b\", \"c\"}]")
        #expect(hypergraph.debugDescription == "UndirectedIncidenceList<String>(vertexCount: 3, hyperedgeCount: 3, vertices: [\"a\", \"b\", \"c\"], hyperedges: [{\"a\", \"b\"}, {}, {\"b\", \"c\"}])")
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b"], [], ["b", "c"]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 3 && hypergraph.hyperedges.count == 3)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 3)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == [] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [] && hypergraph.size(ofHyperedgeAt: 1) == 0)
        #expect(hypergraph.contains(hyperedge: [] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 2)) == ["b", "c"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 2)) == [1, 2] && hypergraph.size(ofHyperedgeAt: 2) == 2)
        #expect(hypergraph.contains(hyperedge: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0, 2] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(hypergraph.degree(of: "b") == 2 && hypergraph.degree(ofIndex: 1) == 2)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.incidentHyperedges(of: "c")) == [2] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [2])
        #expect(hypergraph.degree(of: "c") == 1 && hypergraph.degree(ofIndex: 2) == 1)
    }

    @Test("HG-087 empty", .tags(.conformance))
    func hg087() {
        // U V []; E [] / description / debugDescription
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [] as [[String]])
        #expect(hypergraph.description == "[]; []")
        #expect(hypergraph.debugDescription == "UndirectedIncidenceList<String>(vertexCount: 0, hyperedgeCount: 0, vertices: [], hyperedges: [])")
        // Final state.
        #expect(Array(hypergraph.vertices) == [])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 0 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [])
        #expect((0 ..< 0).map { hypergraph.vertex(atIndex: $0) } == [])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
    }

    @Test("HG-088 at most 16 vertices and 16 hyperedges, then …", .tags(.conformance))
    func hg088() {
        // U V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]; E [{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}] / description
        let hypergraph = UndirectedIncidenceList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16] as [Int], hyperedges: [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16]] as [[Int]])
        #expect(hypergraph.description == "[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, …]; [{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, …]")
        // Final state.
        #expect(Array(hypergraph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        #expect(hypergraph.hyperedges.map { Array($0) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16]])
        #expect(hypergraph.vertexCount == 17 && hypergraph.hyperedgeCount == 17 && hypergraph.hyperedges.count == 17)
        #expect(hypergraph.vertexIndexBound == 17 && hypergraph.hyperedgeIndexBound == 17)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        #expect((0 ..< 17).map { hypergraph.vertex(atIndex: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == [0] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0] && hypergraph.size(ofHyperedgeAt: 0) == 1)
        #expect(hypergraph.contains(hyperedge: [0] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == [1] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [1] && hypergraph.size(ofHyperedgeAt: 1) == 1)
        #expect(hypergraph.contains(hyperedge: [1] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 2)) == [2] && Array(hypergraph.memberIndices(ofHyperedgeAt: 2)) == [2] && hypergraph.size(ofHyperedgeAt: 2) == 1)
        #expect(hypergraph.contains(hyperedge: [2] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 3)) == [3] && Array(hypergraph.memberIndices(ofHyperedgeAt: 3)) == [3] && hypergraph.size(ofHyperedgeAt: 3) == 1)
        #expect(hypergraph.contains(hyperedge: [3] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 4)) == [4] && Array(hypergraph.memberIndices(ofHyperedgeAt: 4)) == [4] && hypergraph.size(ofHyperedgeAt: 4) == 1)
        #expect(hypergraph.contains(hyperedge: [4] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 5)) == [5] && Array(hypergraph.memberIndices(ofHyperedgeAt: 5)) == [5] && hypergraph.size(ofHyperedgeAt: 5) == 1)
        #expect(hypergraph.contains(hyperedge: [5] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 6)) == [6] && Array(hypergraph.memberIndices(ofHyperedgeAt: 6)) == [6] && hypergraph.size(ofHyperedgeAt: 6) == 1)
        #expect(hypergraph.contains(hyperedge: [6] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 7)) == [7] && Array(hypergraph.memberIndices(ofHyperedgeAt: 7)) == [7] && hypergraph.size(ofHyperedgeAt: 7) == 1)
        #expect(hypergraph.contains(hyperedge: [7] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 8)) == [8] && Array(hypergraph.memberIndices(ofHyperedgeAt: 8)) == [8] && hypergraph.size(ofHyperedgeAt: 8) == 1)
        #expect(hypergraph.contains(hyperedge: [8] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 9)) == [9] && Array(hypergraph.memberIndices(ofHyperedgeAt: 9)) == [9] && hypergraph.size(ofHyperedgeAt: 9) == 1)
        #expect(hypergraph.contains(hyperedge: [9] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 10)) == [10] && Array(hypergraph.memberIndices(ofHyperedgeAt: 10)) == [10] && hypergraph.size(ofHyperedgeAt: 10) == 1)
        #expect(hypergraph.contains(hyperedge: [10] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 11)) == [11] && Array(hypergraph.memberIndices(ofHyperedgeAt: 11)) == [11] && hypergraph.size(ofHyperedgeAt: 11) == 1)
        #expect(hypergraph.contains(hyperedge: [11] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 12)) == [12] && Array(hypergraph.memberIndices(ofHyperedgeAt: 12)) == [12] && hypergraph.size(ofHyperedgeAt: 12) == 1)
        #expect(hypergraph.contains(hyperedge: [12] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 13)) == [13] && Array(hypergraph.memberIndices(ofHyperedgeAt: 13)) == [13] && hypergraph.size(ofHyperedgeAt: 13) == 1)
        #expect(hypergraph.contains(hyperedge: [13] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 14)) == [14] && Array(hypergraph.memberIndices(ofHyperedgeAt: 14)) == [14] && hypergraph.size(ofHyperedgeAt: 14) == 1)
        #expect(hypergraph.contains(hyperedge: [14] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 15)) == [15] && Array(hypergraph.memberIndices(ofHyperedgeAt: 15)) == [15] && hypergraph.size(ofHyperedgeAt: 15) == 1)
        #expect(hypergraph.contains(hyperedge: [15] as [Int]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 16)) == [16] && Array(hypergraph.memberIndices(ofHyperedgeAt: 16)) == [16] && hypergraph.size(ofHyperedgeAt: 16) == 1)
        #expect(hypergraph.contains(hyperedge: [16] as [Int]))
        #expect(hypergraph.contains(0))
        #expect(Array(hypergraph.incidentHyperedges(of: 0)) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: 0) == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains(1))
        #expect(Array(hypergraph.incidentHyperedges(of: 1)) == [1] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [1])
        #expect(hypergraph.degree(of: 1) == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(hypergraph.contains(2))
        #expect(Array(hypergraph.incidentHyperedges(of: 2)) == [2] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [2])
        #expect(hypergraph.degree(of: 2) == 1 && hypergraph.degree(ofIndex: 2) == 1)
        #expect(hypergraph.contains(3))
        #expect(Array(hypergraph.incidentHyperedges(of: 3)) == [3] && Array(hypergraph.incidentHyperedges(ofIndex: 3)) == [3])
        #expect(hypergraph.degree(of: 3) == 1 && hypergraph.degree(ofIndex: 3) == 1)
        #expect(hypergraph.contains(4))
        #expect(Array(hypergraph.incidentHyperedges(of: 4)) == [4] && Array(hypergraph.incidentHyperedges(ofIndex: 4)) == [4])
        #expect(hypergraph.degree(of: 4) == 1 && hypergraph.degree(ofIndex: 4) == 1)
        #expect(hypergraph.contains(5))
        #expect(Array(hypergraph.incidentHyperedges(of: 5)) == [5] && Array(hypergraph.incidentHyperedges(ofIndex: 5)) == [5])
        #expect(hypergraph.degree(of: 5) == 1 && hypergraph.degree(ofIndex: 5) == 1)
        #expect(hypergraph.contains(6))
        #expect(Array(hypergraph.incidentHyperedges(of: 6)) == [6] && Array(hypergraph.incidentHyperedges(ofIndex: 6)) == [6])
        #expect(hypergraph.degree(of: 6) == 1 && hypergraph.degree(ofIndex: 6) == 1)
        #expect(hypergraph.contains(7))
        #expect(Array(hypergraph.incidentHyperedges(of: 7)) == [7] && Array(hypergraph.incidentHyperedges(ofIndex: 7)) == [7])
        #expect(hypergraph.degree(of: 7) == 1 && hypergraph.degree(ofIndex: 7) == 1)
        #expect(hypergraph.contains(8))
        #expect(Array(hypergraph.incidentHyperedges(of: 8)) == [8] && Array(hypergraph.incidentHyperedges(ofIndex: 8)) == [8])
        #expect(hypergraph.degree(of: 8) == 1 && hypergraph.degree(ofIndex: 8) == 1)
        #expect(hypergraph.contains(9))
        #expect(Array(hypergraph.incidentHyperedges(of: 9)) == [9] && Array(hypergraph.incidentHyperedges(ofIndex: 9)) == [9])
        #expect(hypergraph.degree(of: 9) == 1 && hypergraph.degree(ofIndex: 9) == 1)
        #expect(hypergraph.contains(10))
        #expect(Array(hypergraph.incidentHyperedges(of: 10)) == [10] && Array(hypergraph.incidentHyperedges(ofIndex: 10)) == [10])
        #expect(hypergraph.degree(of: 10) == 1 && hypergraph.degree(ofIndex: 10) == 1)
        #expect(hypergraph.contains(11))
        #expect(Array(hypergraph.incidentHyperedges(of: 11)) == [11] && Array(hypergraph.incidentHyperedges(ofIndex: 11)) == [11])
        #expect(hypergraph.degree(of: 11) == 1 && hypergraph.degree(ofIndex: 11) == 1)
        #expect(hypergraph.contains(12))
        #expect(Array(hypergraph.incidentHyperedges(of: 12)) == [12] && Array(hypergraph.incidentHyperedges(ofIndex: 12)) == [12])
        #expect(hypergraph.degree(of: 12) == 1 && hypergraph.degree(ofIndex: 12) == 1)
        #expect(hypergraph.contains(13))
        #expect(Array(hypergraph.incidentHyperedges(of: 13)) == [13] && Array(hypergraph.incidentHyperedges(ofIndex: 13)) == [13])
        #expect(hypergraph.degree(of: 13) == 1 && hypergraph.degree(ofIndex: 13) == 1)
        #expect(hypergraph.contains(14))
        #expect(Array(hypergraph.incidentHyperedges(of: 14)) == [14] && Array(hypergraph.incidentHyperedges(ofIndex: 14)) == [14])
        #expect(hypergraph.degree(of: 14) == 1 && hypergraph.degree(ofIndex: 14) == 1)
        #expect(hypergraph.contains(15))
        #expect(Array(hypergraph.incidentHyperedges(of: 15)) == [15] && Array(hypergraph.incidentHyperedges(ofIndex: 15)) == [15])
        #expect(hypergraph.degree(of: 15) == 1 && hypergraph.degree(ofIndex: 15) == 1)
        #expect(hypergraph.contains(16))
        #expect(Array(hypergraph.incidentHyperedges(of: 16)) == [16] && Array(hypergraph.incidentHyperedges(ofIndex: 16)) == [16])
        #expect(hypergraph.degree(of: 16) == 1 && hypergraph.degree(ofIndex: 16) == 1)
    }

    @Test("HG-089 encodes vertices in index order and hyperedges as ascending index rows", .tags(.conformance))
    func hg089() throws {
        // U V []; E [{a, b}, {}, {b, c}] / JSONEncoder().encode(self)
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], [], ["b", "c"]] as [[String]])
        do {
            // {"vertices":["a","b","c"],"hyperedges":[[0,1],[],[1,2]]}
            let data = try JSONEncoder().encode(hypergraph)
            struct Payload: Decodable, Equatable { let vertices: [String]; let hyperedges: [[Int]] }
            #expect(try JSONDecoder().decode(Payload.self, from: data) == Payload(vertices: ["a", "b", "c"], hyperedges: [[0, 1], [], [1, 2]]))
            let decoded = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: data)
            #expect(Array(decoded.vertices) == ["a", "b", "c"])
            #expect(decoded.hyperedges.map { Array($0) } == [["a", "b"], [], ["b", "c"]])
            #expect(decoded == hypergraph)
        }
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b"], [], ["b", "c"]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 3 && hypergraph.hyperedges.count == 3)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 3)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == [] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [] && hypergraph.size(ofHyperedgeAt: 1) == 0)
        #expect(hypergraph.contains(hyperedge: [] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 2)) == ["b", "c"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 2)) == [1, 2] && hypergraph.size(ofHyperedgeAt: 2) == 2)
        #expect(hypergraph.contains(hyperedge: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0, 2] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(hypergraph.degree(of: "b") == 2 && hypergraph.degree(ofIndex: 1) == 2)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.incidentHyperedges(of: "c")) == [2] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [2])
        #expect(hypergraph.degree(of: "c") == 1 && hypergraph.degree(ofIndex: 2) == 1)
    }

    @Test("HG-090 decodes, keeping vertex order and positions", .tags(.conformance))
    func hg090() throws {
        // decode {"vertices":["b","a"],"hyperedges":[[0,1],[]]} → V [b#0, a#1]; E [0:{b, a}, 1:{}]
        let payload = Data(#"{"vertices":["b","a"],"hyperedges":[[0,1],[]]}"#.utf8)
        let hypergraph = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: payload)
        #expect(Array(hypergraph.vertices) == ["b", "a"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["b", "a"], []])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["b", "a"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["b", "a"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["a", "b"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == [] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [] && hypergraph.size(ofHyperedgeAt: 1) == 0)
        #expect(hypergraph.contains(hyperedge: [] as [String]))
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "b") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: JSONEncoder().encode(hypergraph)) == hypergraph)
    }

    @Test("HG-091 rejects a repeated vertex", .tags(.conformance))
    func hg091() throws {
        // decode {"vertices":["a","a"],"hyperedges":[]} → throws DecodingError.dataCorrupted (repeated vertex)
        let payload = Data(#"{"vertices":["a","a"],"hyperedges":[]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("HG-092 rejects a member index out of range", .tags(.conformance))
    func hg092() throws {
        // decode {"vertices":["a"],"hyperedges":[[1]]} → throws DecodingError.dataCorrupted (member index out of range)
        let payload = Data(#"{"vertices":["a"],"hyperedges":[[1]]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("HG-093 rejects a repeated member inside one hyperedge", .tags(.conformance))
    func hg093() throws {
        // decode {"vertices":["a","b"],"hyperedges":[[0,0]]} → throws DecodingError.dataCorrupted (members not strictly ascending)
        let payload = Data(#"{"vertices":["a","b"],"hyperedges":[[0,0]]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("HG-094 rejects members out of order (the encoder writes them ascending)", .tags(.conformance))
    func hg094() throws {
        // decode {"vertices":["a","b"],"hyperedges":[[1,0]]} → throws DecodingError.dataCorrupted (members not strictly ascending)
        let payload = Data(#"{"vertices":["a","b"],"hyperedges":[[1,0]]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
