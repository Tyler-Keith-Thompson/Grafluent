// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the call, so the trap is the call's and not the
// setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import IncidenceMatrixModule
import Multigraphs
import Testing

@Suite("IncidenceMatrix preconditions", .tags(.precondition))
struct IncidenceMatrixPreconditionTests {
    @Test("IM-005 a member out of range")
    func im005() async {
        // IM n 2; E [{0, 2}] → **trap** (vertex out of range)
        await #expect(processExitsWith: .failure) {
            _ = IncidenceMatrix(vertexCount: 2, hyperedges: [[0, 2]] as [[Int]])
        }
        // Without the fault: accepted.
        let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]] as [[Int]])
        #expect(matrix.vertexCount == 3 && matrix.hyperedgeCount == 1)
        #expect((0 ..< 3).map { v in String((0 ..< 1).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["1", "0", "1"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 2]])
        #expect(matrix.vertices == 0 ..< 3 && matrix.vertexIndexBound == 3 && matrix.hyperedgeIndexBound == 1)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 2] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [2, 0] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [])
        #expect(matrix.degree(of: 1) == 0 && matrix.degree(ofIndex: 1) == 0 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0])
        #expect(matrix.degree(of: 2) == 1 && matrix.degree(ofIndex: 2) == 1 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
    }

    @Test("IM-006 negative vertexCount")
    func im006() async {
        // IM n -1; E [] → **trap** (vertexCount must not be negative)
        await #expect(processExitsWith: .failure) {
            _ = IncidenceMatrix(vertexCount: -1, hyperedges: [] as [[Int]])
        }
        // Without the fault: accepted.
        let matrix = IncidenceMatrix(vertexCount: 0, hyperedges: [] as [[Int]])
        #expect(matrix.vertexCount == 0 && matrix.hyperedgeCount == 0)
        #expect((0 ..< 0).map { v in String((0 ..< 0).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == [])
        #expect(matrix.hyperedges.map { Array($0) } == [])
        #expect(matrix.vertices == 0 ..< 0 && matrix.vertexIndexBound == 0 && matrix.hyperedgeIndexBound == 0)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [])
    }

    @Test("IM-019 cell with a vertex out of range")
    func im019() async {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / [vertex: 5, hyperedge: 0] → **trap** (vertex out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
            _ = matrix[vertex: 5, hyperedge: 0]
        }
        // Without the call: the state the call would apply to.
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(matrix.vertexCount == 5 && matrix.hyperedgeCount == 5)
        #expect((0 ..< 5).map { v in String((0 ..< 5).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10100", "10100", "11100", "01000", "00010"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1, 2], [2, 3], [0, 1, 2], [4], []])
        #expect(matrix.vertices == 0 ..< 5 && matrix.vertexIndexBound == 5 && matrix.hyperedgeIndexBound == 5)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 0) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [2, 3] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [2, 3] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [3, 2] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 2)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 2)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 2) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 3)) == [4] && Array(matrix.memberIndices(ofHyperedgeAt: 3)) == [4] && matrix.size(ofHyperedgeAt: 3) == 1)
        #expect(matrix.contains(hyperedge: [4] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 4)) == [] && Array(matrix.memberIndices(ofHyperedgeAt: 4)) == [] && matrix.size(ofHyperedgeAt: 4) == 0)
        #expect(matrix.contains(hyperedge: [] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0, 2])
        #expect(matrix.degree(of: 0) == 2 && matrix.degree(ofIndex: 0) == 2 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0, 1, 2] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0, 1, 2])
        #expect(matrix.degree(of: 2) == 3 && matrix.degree(ofIndex: 2) == 3 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        #expect(Array(matrix.incidentHyperedges(of: 3)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 3)) == [1])
        #expect(matrix.degree(of: 3) == 1 && matrix.degree(ofIndex: 3) == 1 && matrix.vertexIndex(of: 3) == 3 && matrix.vertex(atIndex: 3) == 3)
        #expect(Array(matrix.incidentHyperedges(of: 4)) == [3] && Array(matrix.incidentHyperedges(ofIndex: 4)) == [3])
        #expect(matrix.degree(of: 4) == 1 && matrix.degree(ofIndex: 4) == 1 && matrix.vertexIndex(of: 4) == 4 && matrix.vertex(atIndex: 4) == 4)
    }

    @Test("IM-020 cell with a column out of range")
    func im020() async {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / [vertex: 0, hyperedge: 5] → **trap** (hyperedge position out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
            _ = matrix[vertex: 0, hyperedge: 5]
        }
        // Without the call: the state the call would apply to.
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(matrix.vertexCount == 5 && matrix.hyperedgeCount == 5)
        #expect((0 ..< 5).map { v in String((0 ..< 5).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10100", "10100", "11100", "01000", "00010"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1, 2], [2, 3], [0, 1, 2], [4], []])
        #expect(matrix.vertices == 0 ..< 5 && matrix.vertexIndexBound == 5 && matrix.hyperedgeIndexBound == 5)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 0) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [2, 3] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [2, 3] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [3, 2] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 2)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 2)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 2) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 3)) == [4] && Array(matrix.memberIndices(ofHyperedgeAt: 3)) == [4] && matrix.size(ofHyperedgeAt: 3) == 1)
        #expect(matrix.contains(hyperedge: [4] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 4)) == [] && Array(matrix.memberIndices(ofHyperedgeAt: 4)) == [] && matrix.size(ofHyperedgeAt: 4) == 0)
        #expect(matrix.contains(hyperedge: [] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0, 2])
        #expect(matrix.degree(of: 0) == 2 && matrix.degree(ofIndex: 0) == 2 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0, 1, 2] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0, 1, 2])
        #expect(matrix.degree(of: 2) == 3 && matrix.degree(ofIndex: 2) == 3 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        #expect(Array(matrix.incidentHyperedges(of: 3)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 3)) == [1])
        #expect(matrix.degree(of: 3) == 1 && matrix.degree(ofIndex: 3) == 1 && matrix.vertexIndex(of: 3) == 3 && matrix.vertex(atIndex: 3) == 3)
        #expect(Array(matrix.incidentHyperedges(of: 4)) == [3] && Array(matrix.incidentHyperedges(ofIndex: 4)) == [3])
        #expect(matrix.degree(of: 4) == 1 && matrix.degree(ofIndex: 4) == 1 && matrix.vertexIndex(of: 4) == 4 && matrix.vertex(atIndex: 4) == 4)
    }

    @Test("IM-021 members(ofHyperedgeAt:) out of range")
    func im021() async {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / members(ofHyperedgeAt: 5) → **trap** (hyperedge position out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
            _ = matrix.members(ofHyperedgeAt: 5)
        }
        // Without the call: the state the call would apply to.
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(matrix.vertexCount == 5 && matrix.hyperedgeCount == 5)
        #expect((0 ..< 5).map { v in String((0 ..< 5).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10100", "10100", "11100", "01000", "00010"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1, 2], [2, 3], [0, 1, 2], [4], []])
        #expect(matrix.vertices == 0 ..< 5 && matrix.vertexIndexBound == 5 && matrix.hyperedgeIndexBound == 5)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 0) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [2, 3] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [2, 3] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [3, 2] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 2)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 2)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 2) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 3)) == [4] && Array(matrix.memberIndices(ofHyperedgeAt: 3)) == [4] && matrix.size(ofHyperedgeAt: 3) == 1)
        #expect(matrix.contains(hyperedge: [4] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 4)) == [] && Array(matrix.memberIndices(ofHyperedgeAt: 4)) == [] && matrix.size(ofHyperedgeAt: 4) == 0)
        #expect(matrix.contains(hyperedge: [] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0, 2])
        #expect(matrix.degree(of: 0) == 2 && matrix.degree(ofIndex: 0) == 2 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0, 1, 2] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0, 1, 2])
        #expect(matrix.degree(of: 2) == 3 && matrix.degree(ofIndex: 2) == 3 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        #expect(Array(matrix.incidentHyperedges(of: 3)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 3)) == [1])
        #expect(matrix.degree(of: 3) == 1 && matrix.degree(ofIndex: 3) == 1 && matrix.vertexIndex(of: 3) == 3 && matrix.vertex(atIndex: 3) == 3)
        #expect(Array(matrix.incidentHyperedges(of: 4)) == [3] && Array(matrix.incidentHyperedges(ofIndex: 4)) == [3])
        #expect(matrix.degree(of: 4) == 1 && matrix.degree(ofIndex: 4) == 1 && matrix.vertexIndex(of: 4) == 4 && matrix.vertex(atIndex: 4) == 4)
    }

    @Test("IM-022 incidentHyperedges(of:) out of range")
    func im022() async {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(of: -1) → **trap** (vertex out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
            _ = matrix.incidentHyperedges(of: -1)
        }
        // Without the call: the state the call would apply to.
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(matrix.vertexCount == 5 && matrix.hyperedgeCount == 5)
        #expect((0 ..< 5).map { v in String((0 ..< 5).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10100", "10100", "11100", "01000", "00010"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1, 2], [2, 3], [0, 1, 2], [4], []])
        #expect(matrix.vertices == 0 ..< 5 && matrix.vertexIndexBound == 5 && matrix.hyperedgeIndexBound == 5)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 0) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [2, 3] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [2, 3] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [3, 2] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 2)) == [0, 1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 2)) == [0, 1, 2] && matrix.size(ofHyperedgeAt: 2) == 3)
        #expect(matrix.contains(hyperedge: [2, 1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 3)) == [4] && Array(matrix.memberIndices(ofHyperedgeAt: 3)) == [4] && matrix.size(ofHyperedgeAt: 3) == 1)
        #expect(matrix.contains(hyperedge: [4] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 4)) == [] && Array(matrix.memberIndices(ofHyperedgeAt: 4)) == [] && matrix.size(ofHyperedgeAt: 4) == 0)
        #expect(matrix.contains(hyperedge: [] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0, 2])
        #expect(matrix.degree(of: 0) == 2 && matrix.degree(ofIndex: 0) == 2 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0, 1, 2] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0, 1, 2])
        #expect(matrix.degree(of: 2) == 3 && matrix.degree(ofIndex: 2) == 3 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        #expect(Array(matrix.incidentHyperedges(of: 3)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 3)) == [1])
        #expect(matrix.degree(of: 3) == 1 && matrix.degree(ofIndex: 3) == 1 && matrix.vertexIndex(of: 3) == 3 && matrix.vertex(atIndex: 3) == 3)
        #expect(Array(matrix.incidentHyperedges(of: 4)) == [3] && Array(matrix.incidentHyperedges(ofIndex: 4)) == [3])
        #expect(matrix.degree(of: 4) == 1 && matrix.degree(ofIndex: 4) == 1 && matrix.vertexIndex(of: 4) == 4 && matrix.vertex(atIndex: 4) == 4)
    }

    @Test("IM-026 insert(hyperedge:) with a member out of range")
    func im026() async {
        // IM n 2; E [] / insert(hyperedge: [0, 2]) → **trap** (vertex out of range)
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [] as [[Int]])
            matrix.insert(hyperedge: [0, 2] as [Int])
        }
        // Without the call: the state the call would apply to.
        let matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [] as [[Int]])
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 0)
        #expect((0 ..< 2).map { v in String((0 ..< 0).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["", ""])
        #expect(matrix.hyperedges.map { Array($0) } == [])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 0)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [])
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [])
        #expect(matrix.degree(of: 0) == 0 && matrix.degree(ofIndex: 0) == 0 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [])
        #expect(matrix.degree(of: 1) == 0 && matrix.degree(ofIndex: 1) == 0 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
    }

    @Test("IM-029 remove(_:fromHyperedgeAt:) out of range")
    func im029() async {
        // IM n 3; E [{0, 2}] / remove(0, fromHyperedgeAt: 1) → **trap** (hyperedge position out of range)
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]] as [[Int]])
            matrix.remove(0, fromHyperedgeAt: 1)
        }
        // Without the call: the state the call would apply to.
        let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]] as [[Int]])
        #expect(matrix.vertexCount == 3 && matrix.hyperedgeCount == 1)
        #expect((0 ..< 3).map { v in String((0 ..< 1).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["1", "0", "1"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 2]])
        #expect(matrix.vertices == 0 ..< 3 && matrix.vertexIndexBound == 3 && matrix.hyperedgeIndexBound == 1)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 2] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [2, 0] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [])
        #expect(matrix.degree(of: 1) == 0 && matrix.degree(ofIndex: 1) == 0 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0])
        #expect(matrix.degree(of: 2) == 1 && matrix.degree(ofIndex: 2) == 1 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
    }

    @Test("IM-056 insert(sources:targets:) with a vertex out of range")
    func im056() async {
        // OIM n 2; E [] / insert(sources: [0], targets: [2]) → **trap** (vertex out of range)
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [] as [(sources: [Int], targets: [Int])])
            matrix.insert(sources: [0] as [Int], targets: [2] as [Int])
        }
        // Without the call: the state the call would apply to.
        let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [] as [(sources: [Int], targets: [Int])])
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 0)
        #expect((0 ..< 2).map { v in String((0 ..< 0).map { p -> Character in ["-", "0", "+"][matrix[vertex: v, hyperedge: p] + 1] }) } == ["", ""])
        #expect(matrix.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 0)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [])
        #expect(Array(matrix.outHyperedges(of: 0)) == [] && Array(matrix.outHyperedges(ofIndex: 0)) == [])
        #expect(Array(matrix.inHyperedges(of: 0)) == [] && Array(matrix.inHyperedges(ofIndex: 0)) == [])
        #expect(matrix.outDegree(of: 0) == 0 && matrix.inDegree(of: 0) == 0 && matrix.outDegree(ofIndex: 0) == 0 && matrix.inDegree(ofIndex: 0) == 0 && matrix.degree(of: 0) == 0)
        #expect(Array(matrix.outHyperedges(of: 1)) == [] && Array(matrix.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(matrix.inHyperedges(of: 1)) == [] && Array(matrix.inHyperedges(ofIndex: 1)) == [])
        #expect(matrix.outDegree(of: 1) == 0 && matrix.inDegree(of: 1) == 0 && matrix.outDegree(ofIndex: 1) == 0 && matrix.inDegree(ofIndex: 1) == 0 && matrix.degree(of: 1) == 0)
    }

    @Test("IM-057 entry with a column out of range")
    func im057() async {
        // OIM n 2; E [{0}→{1}] / [vertex: 0, hyperedge: 1] → **trap** (hyperedge position out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [1])] as [(sources: [Int], targets: [Int])])
            _ = matrix[vertex: 0, hyperedge: 1]
        }
        // Without the call: the state the call would apply to.
        let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [1])] as [(sources: [Int], targets: [Int])])
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 1)
        #expect((0 ..< 2).map { v in String((0 ..< 1).map { p -> Character in ["-", "0", "+"][matrix[vertex: v, hyperedge: p] + 1] }) } == ["-", "+"])
        #expect(matrix.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[0], [1]]])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 1)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(matrix.sources(ofHyperedgeAt: 0)) == [0] && Array(matrix.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(matrix.targets(ofHyperedgeAt: 0)) == [1] && Array(matrix.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(matrix.contains(sources: [0] as [Int], targets: [1] as [Int]))
        #expect(Array(matrix.outHyperedges(of: 0)) == [0] && Array(matrix.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(matrix.inHyperedges(of: 0)) == [] && Array(matrix.inHyperedges(ofIndex: 0)) == [])
        #expect(matrix.outDegree(of: 0) == 1 && matrix.inDegree(of: 0) == 0 && matrix.outDegree(ofIndex: 0) == 1 && matrix.inDegree(ofIndex: 0) == 0 && matrix.degree(of: 0) == 1)
        #expect(Array(matrix.outHyperedges(of: 1)) == [] && Array(matrix.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(matrix.inHyperedges(of: 1)) == [0] && Array(matrix.inHyperedges(ofIndex: 1)) == [0])
        #expect(matrix.outDegree(of: 1) == 0 && matrix.inDegree(of: 1) == 1 && matrix.outDegree(ofIndex: 1) == 0 && matrix.inDegree(ofIndex: 1) == 1 && matrix.degree(of: 1) == 1)
    }

    @Test("IM-058 targets(ofHyperedgeAt:) out of range")
    func im058() async {
        // OIM n 2; E [{0}→{1}] / targets(ofHyperedgeAt: -1) → **trap** (hyperedge position out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [1])] as [(sources: [Int], targets: [Int])])
            _ = matrix.targets(ofHyperedgeAt: -1)
        }
        // Without the call: the state the call would apply to.
        let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [1])] as [(sources: [Int], targets: [Int])])
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 1)
        #expect((0 ..< 2).map { v in String((0 ..< 1).map { p -> Character in ["-", "0", "+"][matrix[vertex: v, hyperedge: p] + 1] }) } == ["-", "+"])
        #expect(matrix.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[0], [1]]])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 1)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(matrix.sources(ofHyperedgeAt: 0)) == [0] && Array(matrix.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(matrix.targets(ofHyperedgeAt: 0)) == [1] && Array(matrix.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(matrix.contains(sources: [0] as [Int], targets: [1] as [Int]))
        #expect(Array(matrix.outHyperedges(of: 0)) == [0] && Array(matrix.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(matrix.inHyperedges(of: 0)) == [] && Array(matrix.inHyperedges(ofIndex: 0)) == [])
        #expect(matrix.outDegree(of: 0) == 1 && matrix.inDegree(of: 0) == 0 && matrix.outDegree(ofIndex: 0) == 1 && matrix.inDegree(ofIndex: 0) == 0 && matrix.degree(of: 0) == 1)
        #expect(Array(matrix.outHyperedges(of: 1)) == [] && Array(matrix.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(matrix.inHyperedges(of: 1)) == [0] && Array(matrix.inHyperedges(ofIndex: 1)) == [0])
        #expect(matrix.outDegree(of: 1) == 0 && matrix.inDegree(of: 1) == 1 && matrix.outDegree(ofIndex: 1) == 0 && matrix.inDegree(ofIndex: 1) == 1 && matrix.degree(of: 1) == 1)
    }

    @Test("IM-059 outHyperedges(of:) out of range")
    func im059() async {
        // OIM n 2; E [{0}→{1}] / outHyperedges(of: 2) → **trap** (vertex out of range)
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [1])] as [(sources: [Int], targets: [Int])])
            _ = matrix.outHyperedges(of: 2)
        }
        // Without the call: the state the call would apply to.
        let matrix = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [1])] as [(sources: [Int], targets: [Int])])
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 1)
        #expect((0 ..< 2).map { v in String((0 ..< 1).map { p -> Character in ["-", "0", "+"][matrix[vertex: v, hyperedge: p] + 1] }) } == ["-", "+"])
        #expect(matrix.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[0], [1]]])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 1)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(matrix.sources(ofHyperedgeAt: 0)) == [0] && Array(matrix.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(matrix.targets(ofHyperedgeAt: 0)) == [1] && Array(matrix.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(matrix.contains(sources: [0] as [Int], targets: [1] as [Int]))
        #expect(Array(matrix.outHyperedges(of: 0)) == [0] && Array(matrix.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(matrix.inHyperedges(of: 0)) == [] && Array(matrix.inHyperedges(ofIndex: 0)) == [])
        #expect(matrix.outDegree(of: 0) == 1 && matrix.inDegree(of: 0) == 0 && matrix.outDegree(ofIndex: 0) == 1 && matrix.inDegree(ofIndex: 0) == 0 && matrix.degree(of: 0) == 1)
        #expect(Array(matrix.outHyperedges(of: 1)) == [] && Array(matrix.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(matrix.inHyperedges(of: 1)) == [0] && Array(matrix.inHyperedges(ofIndex: 1)) == [0])
        #expect(matrix.outDegree(of: 1) == 0 && matrix.inDegree(of: 1) == 1 && matrix.outDegree(ofIndex: 1) == 0 && matrix.inDegree(ofIndex: 1) == 1 && matrix.degree(of: 1) == 1)
    }

    @Test("Unoriented: cell edits and reads trap on a vertex or column out of range")
    func unorientedRanges() async {
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            matrix.insert(3, intoHyperedgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            matrix.insert(0, intoHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            matrix.remove(-1, fromHyperedgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            _ = matrix.degree(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
            _ = matrix.size(ofHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = IncidenceMatrix()
            _ = matrix.incidentHyperedges(of: 0)
        }
        // Without the calls: the last vertex and column answer.
        var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2]])
        let inserted = matrix.insert(1, intoHyperedgeAt: 0)
        let removed = matrix.remove(2, fromHyperedgeAt: 0)
        #expect(inserted && removed)
        #expect(matrix.degree(of: 2) == 0 && matrix.size(ofHyperedgeAt: 0) == 2)
    }

    @Test("Converting a graph without vertex indices traps")
    func graphWithoutIndices() async {
        await #expect(processExitsWith: .failure) {
            // A graph with only the required members: vertexIndexBound is nil.
            struct Bare: Graph {
                var vertices: [Int] { [0, 1] }
                var edges: [UndirectedEdge<Int>] { [UndirectedEdge(0, 1)] }
                func neighbors(of vertex: Int) -> [Int] { [1 - vertex] }
                func incidentEdges(of vertex: Int) -> [Int] { [0] }
            }
            _ = IncidenceMatrix(Bare())
        }
        // Without the fault: the same graph with indices converts.
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]))
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1])
    }

    @Test("Oriented: growth, edits and reads trap out of range")
    func orientedRanges() async {
        await #expect(processExitsWith: .failure) {
            _ = OrientedIncidenceMatrix(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2)
            matrix.insert(edge: DirectedEdge(from: 2, to: 0))
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            matrix.insert(2, intoSourcesOfHyperedgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            matrix.remove(0, fromTargetsOfHyperedgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.inHyperedges(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.sources(ofHyperedgeAt: 1)
        }
        // Without the calls: the last vertex and column answer.
        var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(matrix.insert(edge: DirectedEdge(from: 1, to: 0)) == 1)
        let inserted = matrix.insert(1, intoSourcesOfHyperedgeAt: 0)
        let removed = matrix.remove(1, fromTargetsOfHyperedgeAt: 1)
        #expect(inserted && !removed)
        #expect(Array(matrix.inHyperedges(of: 1)) == [0] && Array(matrix.sources(ofHyperedgeAt: 0)) == [0, 1])
    }
}
