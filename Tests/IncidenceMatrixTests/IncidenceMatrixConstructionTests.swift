// Construction and reads (catalog IM-001 – IM-018, IM-064): columns in input order, a repeated member
// one bit, repeated and empty columns kept; from a graph one column per edge in edges order, a
// self-loop one bit (NetworkX: a zero column), both ends from a digraph; cells, columns, rows and
// degrees; the same matrix through an incidence-list copy and by appending one column at a time;
// the checked: reads, which throw VertexNotFound out of range.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Hypergraphs
import IncidenceMatrixModule
import Multigraphs
import Testing

@Suite("IncidenceMatrix construction and reads")
struct IncidenceMatrixConstructionTests {
    @Test("IM-001 empty")
    func im001() {
        // IM n 0; E []
        let matrix = IncidenceMatrix(vertexCount: 0, hyperedges: [] as [[Int]])
        // Final state.
        #expect(matrix.vertexCount == 0 && matrix.hyperedgeCount == 0)
        #expect((0 ..< 0).map { v in String((0 ..< 0).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == [])
        #expect(matrix.hyperedges.map { Array($0) } == [])
        #expect(matrix.vertices == 0 ..< 0 && matrix.vertexIndexBound == 0 && matrix.hyperedgeIndexBound == 0)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [])
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            let built = IncidenceMatrix(vertexCount: 0)
            #expect(built == matrix)
        }
    }

    @Test("IM-002 vertices, no hyperedges")
    func im002() {
        // IM n 3; E []
        let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [] as [[Int]])
        // Final state.
        #expect(matrix.vertexCount == 3 && matrix.hyperedgeCount == 0)
        #expect((0 ..< 3).map { v in String((0 ..< 0).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["", "", ""])
        #expect(matrix.hyperedges.map { Array($0) } == [])
        #expect(matrix.vertices == 0 ..< 3 && matrix.vertexIndexBound == 3 && matrix.hyperedgeIndexBound == 0)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [])
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [])
        #expect(matrix.degree(of: 0) == 0 && matrix.degree(ofIndex: 0) == 0 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [])
        #expect(matrix.degree(of: 1) == 0 && matrix.degree(ofIndex: 1) == 0 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [])
        #expect(matrix.degree(of: 2) == 0 && matrix.degree(ofIndex: 2) == 0 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            let built = IncidenceMatrix(vertexCount: 3)
            #expect(built == matrix)
        }
    }

    @Test("IM-003 columns in input order; a repeated member is one bit")
    func im003() {
        // IM n 4; E [{2, 0}, {1, 1, 3}]
        let matrix = IncidenceMatrix(vertexCount: 4, hyperedges: [[2, 0], [1, 1, 3]] as [[Int]])
        // Final state.
        #expect(matrix.vertexCount == 4 && matrix.hyperedgeCount == 2)
        #expect((0 ..< 4).map { v in String((0 ..< 2).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10", "01", "10", "01"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 2], [1, 3]])
        #expect(matrix.vertices == 0 ..< 4 && matrix.vertexIndexBound == 4 && matrix.hyperedgeIndexBound == 2)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 2] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [2, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [1, 3] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [1, 3] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [3, 1] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [1])
        #expect(matrix.degree(of: 1) == 1 && matrix.degree(ofIndex: 1) == 1 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [0])
        #expect(matrix.degree(of: 2) == 1 && matrix.degree(ofIndex: 2) == 1 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        #expect(Array(matrix.incidentHyperedges(of: 3)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 3)) == [1])
        #expect(matrix.degree(of: 3) == 1 && matrix.degree(ofIndex: 3) == 1 && matrix.vertexIndex(of: 3) == 3 && matrix.vertex(atIndex: 3) == 3)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 4)
            #expect(built.insert(hyperedge: [0, 2] as [Int]) == 0)
            #expect(built.insert(hyperedge: [1, 3] as [Int]) == 1)
            #expect(built == matrix)
        }
    }

    @Test("IM-004 repeated and empty columns are kept")
    func im004() {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}]
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        // Final state.
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
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 5)
            #expect(built.insert(hyperedge: [0, 1, 2] as [Int]) == 0)
            #expect(built.insert(hyperedge: [2, 3] as [Int]) == 1)
            #expect(built.insert(hyperedge: [0, 1, 2] as [Int]) == 2)
            #expect(built.insert(hyperedge: [4] as [Int]) == 3)
            #expect(built.insert(hyperedge: [] as [Int]) == 4)
            #expect(built == matrix)
        }
    }

    @Test("IM-007 triangle (NetworkX)")
    func im007() {
        // IncidenceMatrix(Pseudograph(n 3; [0–1, 1–2, 0–2]))
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)]))
        // Final state.
        #expect(matrix.vertexCount == 3 && matrix.hyperedgeCount == 3)
        #expect((0 ..< 3).map { v in String((0 ..< 3).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["101", "110", "011"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1], [1, 2], [0, 2]])
        #expect(matrix.vertices == 0 ..< 3 && matrix.vertexIndexBound == 3 && matrix.hyperedgeIndexBound == 3)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [1, 2] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [2, 1] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 2)) == [0, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 2)) == [0, 2] && matrix.size(ofHyperedgeAt: 2) == 2)
        #expect(matrix.contains(hyperedge: [2, 0] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0, 2] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0, 2])
        #expect(matrix.degree(of: 0) == 2 && matrix.degree(ofIndex: 0) == 2 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [1, 2] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [1, 2])
        #expect(matrix.degree(of: 2) == 2 && matrix.degree(ofIndex: 2) == 2 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 3)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built.insert(hyperedge: [1, 2] as [Int]) == 1)
            #expect(built.insert(hyperedge: [0, 2] as [Int]) == 2)
            #expect(built == matrix)
        }
    }

    @Test("IM-008 parallel edges keep their own columns")
    func im008() {
        // IncidenceMatrix(Pseudograph(n 2; [0–1, 1–0]))
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]))
        // Final state.
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 2)
        #expect((0 ..< 2).map { v in String((0 ..< 2).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["11", "11"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1], [0, 1]])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 2)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [0, 1] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0, 1])
        #expect(matrix.degree(of: 0) == 2 && matrix.degree(ofIndex: 0) == 2 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 2)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 1)
            #expect(built == matrix)
        }
    }

    @Test("IM-009 a self-loop sets one bit (NetworkX: a zero column)")
    func im009() {
        // IncidenceMatrix(Pseudograph(n 2; [0–1, 1–1]))
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)]))
        // Final state.
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 2)
        #expect((0 ..< 2).map { v in String((0 ..< 2).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10", "11"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1], [1]])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 2)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [1] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [1] && matrix.size(ofHyperedgeAt: 1) == 1)
        #expect(matrix.contains(hyperedge: [1] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 2)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built.insert(hyperedge: [1] as [Int]) == 1)
            #expect(built == matrix)
        }
    }

    @Test("IM-010 isolated vertex: a zero row")
    func im010() {
        // IncidenceMatrix(Pseudograph(n 3; [0–1]))
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]))
        // Final state.
        #expect(matrix.vertexCount == 3 && matrix.hyperedgeCount == 1)
        #expect((0 ..< 3).map { v in String((0 ..< 1).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["1", "1", "0"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1]])
        #expect(matrix.vertices == 0 ..< 3 && matrix.vertexIndexBound == 3 && matrix.hyperedgeIndexBound == 1)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(matrix.degree(of: 1) == 1 && matrix.degree(ofIndex: 1) == 1 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [])
        #expect(matrix.degree(of: 2) == 0 && matrix.degree(ofIndex: 2) == 0 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 3)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built == matrix)
        }
    }

    @Test("IM-011 unoriented, from a digraph: both ends (NetworkX oriented=False)")
    func im011() {
        // IncidenceMatrix(DirectedPseudograph(n 3; [0→1, 2→1]))
        let matrix = IncidenceMatrix(DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)]))
        // Final state.
        #expect(matrix.vertexCount == 3 && matrix.hyperedgeCount == 2)
        #expect((0 ..< 3).map { v in String((0 ..< 2).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10", "11", "01"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1], [1, 2]])
        #expect(matrix.vertices == 0 ..< 3 && matrix.vertexIndexBound == 3 && matrix.hyperedgeIndexBound == 2)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [1, 2] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [2, 1] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [1] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [1])
        #expect(matrix.degree(of: 2) == 1 && matrix.degree(ofIndex: 2) == 1 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 3)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built.insert(hyperedge: [1, 2] as [Int]) == 1)
            #expect(built == matrix)
        }
    }

    @Test("IM-012 unoriented, a directed self-loop sets one bit (NetworkX: zero)")
    func im012() {
        // IncidenceMatrix(DirectedPseudograph(n 2; [0→1, 1→1]))
        let matrix = IncidenceMatrix(DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)]))
        // Final state.
        #expect(matrix.vertexCount == 2 && matrix.hyperedgeCount == 2)
        #expect((0 ..< 2).map { v in String((0 ..< 2).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10", "11"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1], [1]])
        #expect(matrix.vertices == 0 ..< 2 && matrix.vertexIndexBound == 2 && matrix.hyperedgeIndexBound == 2)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [1] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [1] && matrix.size(ofHyperedgeAt: 1) == 1)
        #expect(matrix.contains(hyperedge: [1] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 2)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built.insert(hyperedge: [1] as [Int]) == 1)
            #expect(built == matrix)
        }
    }

    @Test("IM-013 path P4: B·Bᵀ = D + A and Bᵀ·B = 2I + A(L(G))")
    func im013() {
        // IncidenceMatrix(Pseudograph(n 4; [0–1, 1–2, 2–3]))
        let matrix = IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]))
        // Final state.
        #expect(matrix.vertexCount == 4 && matrix.hyperedgeCount == 3)
        #expect((0 ..< 4).map { v in String((0 ..< 3).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["100", "110", "011", "001"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1], [1, 2], [2, 3]])
        #expect(matrix.vertices == 0 ..< 4 && matrix.vertexIndexBound == 4 && matrix.hyperedgeIndexBound == 3)
        #expect(matrix.hyperedges.indices.map { matrix.hyperedgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1] && Array(matrix.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && matrix.size(ofHyperedgeAt: 0) == 2)
        #expect(matrix.contains(hyperedge: [1, 0] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 1)) == [1, 2] && Array(matrix.memberIndices(ofHyperedgeAt: 1)) == [1, 2] && matrix.size(ofHyperedgeAt: 1) == 2)
        #expect(matrix.contains(hyperedge: [2, 1] as [Int]))
        #expect(Array(matrix.members(ofHyperedgeAt: 2)) == [2, 3] && Array(matrix.memberIndices(ofHyperedgeAt: 2)) == [2, 3] && matrix.size(ofHyperedgeAt: 2) == 2)
        #expect(matrix.contains(hyperedge: [3, 2] as [Int]))
        #expect(Array(matrix.incidentHyperedges(of: 0)) == [0] && Array(matrix.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(matrix.degree(of: 0) == 1 && matrix.degree(ofIndex: 0) == 1 && matrix.vertexIndex(of: 0) == 0 && matrix.vertex(atIndex: 0) == 0)
        #expect(Array(matrix.incidentHyperedges(of: 1)) == [0, 1] && Array(matrix.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(matrix.degree(of: 1) == 2 && matrix.degree(ofIndex: 1) == 2 && matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 1) == 1)
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [1, 2] && Array(matrix.incidentHyperedges(ofIndex: 2)) == [1, 2])
        #expect(matrix.degree(of: 2) == 2 && matrix.degree(ofIndex: 2) == 2 && matrix.vertexIndex(of: 2) == 2 && matrix.vertex(atIndex: 2) == 2)
        #expect(Array(matrix.incidentHyperedges(of: 3)) == [2] && Array(matrix.incidentHyperedges(ofIndex: 3)) == [2])
        #expect(matrix.degree(of: 3) == 1 && matrix.degree(ofIndex: 3) == 1 && matrix.vertexIndex(of: 3) == 3 && matrix.vertex(atIndex: 3) == 3)
        // The same matrix from an incidence-list copy, and by appending one column at a time.
        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)
        do {
            var built = IncidenceMatrix(vertexCount: 4)
            #expect(built.insert(hyperedge: [0, 1] as [Int]) == 0)
            #expect(built.insert(hyperedge: [1, 2] as [Int]) == 1)
            #expect(built.insert(hyperedge: [2, 3] as [Int]) == 2)
            #expect(built == matrix)
        }
    }

    @Test("IM-014 cells")
    func im014() {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / [vertex: 2, hyperedge: 0] / [vertex: 3, hyperedge: 0] / [vertex: 4, hyperedge: 3]
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(matrix[vertex: 2, hyperedge: 0])
        #expect(!matrix[vertex: 3, hyperedge: 0])
        #expect(matrix[vertex: 4, hyperedge: 3])
        // Final state.
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

    @Test("IM-015 members and sizes, ascending")
    func im015() {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / members(ofHyperedgeAt: 0) / size(ofHyperedgeAt: 0) / members(ofHyperedgeAt: 4) / size(ofHyperedgeAt: 4)
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(Array(matrix.members(ofHyperedgeAt: 0)) == [0, 1, 2])
        #expect(matrix.size(ofHyperedgeAt: 0) == 3)
        #expect(Array(matrix.members(ofHyperedgeAt: 4)) == [])
        #expect(matrix.size(ofHyperedgeAt: 4) == 0)
        // Final state.
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

    @Test("IM-016 incident hyperedges and degrees, ascending")
    func im016() {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(of: 2) / degree(of: 2) / incidentHyperedges(of: 4) / degree(of: 4)
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(Array(matrix.incidentHyperedges(of: 2)) == [0, 1, 2])
        #expect(matrix.degree(of: 2) == 3)
        #expect(Array(matrix.incidentHyperedges(of: 4)) == [3])
        #expect(matrix.degree(of: 4) == 1)
        // Final state.
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

    @Test("IM-017 counts")
    func im017() {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / vertexCount/hyperedgeCount
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(matrix.vertexCount == 5 && matrix.hyperedgeCount == 5)
        // Final state.
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

    @Test("IM-018 a zero row: degree 0")
    func im018() {
        // IM n 6; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(of: 5) / degree(of: 5)
        let matrix = IncidenceMatrix(vertexCount: 6, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(Array(matrix.incidentHyperedges(of: 5)) == [])
        #expect(matrix.degree(of: 5) == 0)
        // Final state.
        #expect(matrix.vertexCount == 6 && matrix.hyperedgeCount == 5)
        #expect((0 ..< 6).map { v in String((0 ..< 5).map { p -> Character in matrix[vertex: v, hyperedge: p] ? "1" : "0" }) } == ["10100", "10100", "11100", "01000", "00010", "00000"])
        #expect(matrix.hyperedges.map { Array($0) } == [[0, 1, 2], [2, 3], [0, 1, 2], [4], []])
        #expect(matrix.vertices == 0 ..< 6 && matrix.vertexIndexBound == 6 && matrix.hyperedgeIndexBound == 5)
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
        #expect(Array(matrix.incidentHyperedges(of: 5)) == [] && Array(matrix.incidentHyperedges(ofIndex: 5)) == [])
        #expect(matrix.degree(of: 5) == 0 && matrix.degree(ofIndex: 5) == 0 && matrix.vertexIndex(of: 5) == 5 && matrix.vertex(atIndex: 5) == 5)
    }

    @Test("IM-064 checked: spellings answer a vertex as the plain ones do and throw out of range")
    func im064() throws {
        // IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(checked: 2) / degree(checked: 2) / vertexIndex(checked: 4) / incidentHyperedges(checked: 5) / degree(checked: -1) / vertexIndex(checked: 5)
        let matrix = IncidenceMatrix(vertexCount: 5, hyperedges: [[0, 1, 2], [2, 3], [0, 1, 2], [4], []] as [[Int]])
        #expect(try Array(matrix.incidentHyperedges(checked: 2)) == [0, 1, 2])
        #expect(try matrix.degree(checked: 2) == 3)
        #expect(try matrix.vertexIndex(checked: 4) == 4)
        #expect(throws: VertexNotFound.self) { try matrix.incidentHyperedges(checked: 5) }
        #expect((try? matrix.incidentHyperedges(checked: 5)) == nil)
        #expect(throws: VertexNotFound.self) { try matrix.degree(checked: -1) }
        #expect((try? matrix.degree(checked: -1)) == nil)
        #expect(throws: VertexNotFound.self) { try matrix.vertexIndex(checked: 5) }
        #expect((try? matrix.vertexIndex(checked: 5)) == nil)
        // Final state.
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
}
