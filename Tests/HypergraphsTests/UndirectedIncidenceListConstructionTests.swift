// Construction and mutation (catalog HG-001 – HG-011, HG-035 – HG-042): listed vertices first (a repeat
// once), then new members by first appearance; members stored once and in vertex-index order;
// repeated and empty hyperedges kept at their own positions; every initializer that fits, and
// inserting one at a time, give the same state; insert(checked:) throws and changes nothing for a
// non-vertex.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Hypergraphs
import Testing

@Suite("UndirectedIncidenceList construction and mutation")
struct UndirectedIncidenceListConstructionTests {
    @Test("HG-001 empty")
    func hg001() {
        // U V []; E []
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [] as [[String]])
        // Final state.
        #expect(Array(hypergraph.vertices) == [])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 0 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [])
        #expect((0 ..< 0).map { hypergraph.vertex(atIndex: $0) } == [])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>()
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(vertices: [] as [String])
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hyperedges: [] as [[String]])
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-002 isolated vertices in listed order")
    func hg002() {
        // U V [a, b, c]; E []
        let hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "b", "c"] as [String], hyperedges: [] as [[String]])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.degree(of: "a") == 0 && hypergraph.degree(ofIndex: 0) == 0)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.degree(of: "b") == 0 && hypergraph.degree(ofIndex: 1) == 0)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.incidentHyperedges(of: "c")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [])
        #expect(hypergraph.degree(of: "c") == 0 && hypergraph.degree(ofIndex: 2) == 0)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(vertices: ["a", "b", "c"] as [String])
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert("a")
            built.insert("b")
            built.insert("c")
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-003 vertices by first appearance in the hyperedges")
    func hg003() {
        // U V []; E [{c, a}, {b, c}]
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["c", "a"], ["b", "c"]] as [[String]])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["c", "a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["c", "a"], ["c", "b"]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["c", "a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["c", "a"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["a", "c"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == ["c", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [0, 2] && hypergraph.size(ofHyperedgeAt: 1) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "c"] as [String]))
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.incidentHyperedges(of: "c")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0, 1])
        #expect(hypergraph.degree(of: "c") == 2 && hypergraph.degree(ofIndex: 0) == 2)
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [1] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [1])
        #expect(hypergraph.degree(of: "b") == 1 && hypergraph.degree(ofIndex: 2) == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hyperedges: [["c", "a"], ["b", "c"]] as [[String]])
            #expect(Array(built.vertices) == ["c", "a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["c", "a"], ["c", "b"]])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["c", "a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["c", "a"], ["c", "b"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert(hyperedge: ["c", "a"] as [String])
            built.insert(hyperedge: ["b", "c"] as [String])
            #expect(Array(built.vertices) == ["c", "a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["c", "a"], ["c", "b"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-004 listed vertices first, then new members")
    func hg004() {
        // U V [z]; E [{x, z}, {z, y}]
        let hypergraph = UndirectedIncidenceList<String>(vertices: ["z"] as [String], hyperedges: [["x", "z"], ["z", "y"]] as [[String]])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["z", "x", "y"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["z", "x"], ["z", "y"]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["z", "x", "y"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["z", "x"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["x", "z"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == ["z", "y"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [0, 2] && hypergraph.size(ofHyperedgeAt: 1) == 2)
        #expect(hypergraph.contains(hyperedge: ["y", "z"] as [String]))
        #expect(hypergraph.contains("z"))
        #expect(Array(hypergraph.incidentHyperedges(of: "z")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0, 1])
        #expect(hypergraph.degree(of: "z") == 2 && hypergraph.degree(ofIndex: 0) == 2)
        #expect(hypergraph.contains("x"))
        #expect(Array(hypergraph.incidentHyperedges(of: "x")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: "x") == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(hypergraph.contains("y"))
        #expect(Array(hypergraph.incidentHyperedges(of: "y")) == [1] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [1])
        #expect(hypergraph.degree(of: "y") == 1 && hypergraph.degree(ofIndex: 2) == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["z", "x", "y"])
            #expect(built.hyperedges.map { Array($0) } == [["z", "x"], ["z", "y"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert("z")
            built.insert(hyperedge: ["x", "z"] as [String])
            built.insert(hyperedge: ["z", "y"] as [String])
            #expect(Array(built.vertices) == ["z", "x", "y"])
            #expect(built.hyperedges.map { Array($0) } == [["z", "x"], ["z", "y"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-005 members stored in vertex-index order, not input order")
    func hg005() {
        // U V [a, b, c]; E [{c, a, b}] / members(ofHyperedgeAt: 0) / memberIndices(ofHyperedgeAt: 0)
        let hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "b", "c"] as [String], hyperedges: [["c", "a", "b"]] as [[String]])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b", "c"])
        #expect(Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1, 2])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b", "c"]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b", "c"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1, 2] && hypergraph.size(ofHyperedgeAt: 0) == 3)
        #expect(hypergraph.contains(hyperedge: ["c", "b", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: "b") == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.incidentHyperedges(of: "c")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [0])
        #expect(hypergraph.degree(of: "c") == 1 && hypergraph.degree(ofIndex: 2) == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b", "c"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert("a")
            built.insert("b")
            built.insert("c")
            built.insert(hyperedge: ["c", "a", "b"] as [String])
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b", "c"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-006 a repeated member is stored once")
    func hg006() {
        // U V []; E [{a, b, a}] / size(ofHyperedgeAt: 0)
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b", "a"]] as [[String]])
        #expect(hypergraph.size(ofHyperedgeAt: 0) == 2)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b"]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: "b") == 1 && hypergraph.degree(ofIndex: 1) == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hyperedges: [["a", "b", "a"]] as [[String]])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"]])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert(hyperedge: ["a", "b", "a"] as [String])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-007 a repeated hyperedge is kept (multi-hyperedge), each its own position")
    func hg007() {
        // U V []; E [{a, b}, {b, a}] / incidentHyperedges(of: a) / degree(of: a)
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], ["b", "a"]] as [[String]])
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0, 1])
        #expect(hypergraph.degree(of: "a") == 2)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b"], ["a", "b"]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 1) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0, 1])
        #expect(hypergraph.degree(of: "a") == 2 && hypergraph.degree(ofIndex: 0) == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(hypergraph.degree(of: "b") == 2 && hypergraph.degree(ofIndex: 1) == 2)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], ["b", "a"]] as [[String]])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"], ["a", "b"]])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"], ["a", "b"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert(hyperedge: ["a", "b"] as [String])
            built.insert(hyperedge: ["b", "a"] as [String])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"], ["a", "b"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-008 an empty hyperedge is kept")
    func hg008() {
        // U V []; E [{a, b}, {}, {b, c}] / size(ofHyperedgeAt: 1) / vertexCount/hyperedgeCount
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"], [], ["b", "c"]] as [[String]])
        #expect(hypergraph.size(ofHyperedgeAt: 1) == 0)
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 3)
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
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], [], ["b", "c"]] as [[String]])
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"], [], ["b", "c"]])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"], [], ["b", "c"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert(hyperedge: ["a", "b"] as [String])
            built.insert(hyperedge: [] as [String])
            built.insert(hyperedge: ["b", "c"] as [String])
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { Array($0) } == [["a", "b"], [], ["b", "c"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-009 a singleton hyperedge")
    func hg009() {
        // U V []; E [{a}] / degree(of: a) / neighbors(of: a)
        let hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a"]] as [[String]])
        #expect(hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.neighbors(of: "a") == [])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a"]])
        #expect(hypergraph.vertexCount == 1 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 1 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { hypergraph.vertex(atIndex: $0) } == ["a"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0] && hypergraph.size(ofHyperedgeAt: 0) == 1)
        #expect(hypergraph.contains(hyperedge: ["a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(hyperedges: [["a"]] as [[String]])
            #expect(Array(built.vertices) == ["a"])
            #expect(built.hyperedges.map { Array($0) } == [["a"]])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a"])
            #expect(built.hyperedges.map { Array($0) } == [["a"]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert(hyperedge: ["a"] as [String])
            #expect(Array(built.vertices) == ["a"])
            #expect(built.hyperedges.map { Array($0) } == [["a"]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-010 a repeated vertex in the vertex list is inserted once")
    func hg010() {
        // U V [a, a, b]; E [] / vertexCount/hyperedgeCount
        let hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "a", "b"] as [String], hyperedges: [] as [[String]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.degree(of: "a") == 0 && hypergraph.degree(ofIndex: 0) == 0)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.degree(of: "b") == 0 && hypergraph.degree(ofIndex: 1) == 0)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<String>(vertices: ["a", "a", "b"] as [String])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = UndirectedIncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<String>()
            built.insert("a")
            built.insert("a")
            built.insert("b")
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { Array($0) } == [])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-011 Int vertices are labels, not indices")
    func hg011() {
        // U V [5, 3]; E [{3, 7}] / vertexIndex(of: 3) / vertex(atIndex: 2) / members(ofHyperedgeAt: 0)
        let hypergraph = UndirectedIncidenceList<Int>(vertices: [5, 3] as [Int], hyperedges: [[3, 7]] as [[Int]])
        #expect(hypergraph.vertexIndex(of: 3) == 1)
        #expect(hypergraph.vertex(atIndex: 2) == 7)
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == [3, 7])
        // Final state.
        #expect(Array(hypergraph.vertices) == [5, 3, 7])
        #expect(hypergraph.hyperedges.map { Array($0) } == [[3, 7]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == [5, 3, 7])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == [3, 7] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [1, 2] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: [7, 3] as [Int]))
        #expect(hypergraph.contains(5))
        #expect(Array(hypergraph.incidentHyperedges(of: 5)) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.degree(of: 5) == 0 && hypergraph.degree(ofIndex: 0) == 0)
        #expect(hypergraph.contains(3))
        #expect(Array(hypergraph.incidentHyperedges(of: 3)) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: 3) == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(hypergraph.contains(7))
        #expect(Array(hypergraph.incidentHyperedges(of: 7)) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [0])
        #expect(hypergraph.degree(of: 7) == 1 && hypergraph.degree(ofIndex: 2) == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = UndirectedIncidenceList<Int>(hypergraph)
            #expect(Array(built.vertices) == [5, 3, 7])
            #expect(built.hyperedges.map { Array($0) } == [[3, 7]])
            #expect(built == hypergraph)
        }
        do {
            var built = UndirectedIncidenceList<Int>()
            built.insert(5)
            built.insert(3)
            built.insert(hyperedge: [3, 7] as [Int])
            #expect(Array(built.vertices) == [5, 3, 7])
            #expect(built.hyperedges.map { Array($0) } == [[3, 7]])
            #expect(built == hypergraph)
        }
    }

    @Test("HG-035 insert a new vertex, then an existing one")
    func hg035() {
        // U V [a]; E [] / insert(b) / insert(a)
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a"] as [String], hyperedges: [] as [[String]])
        do {
            let result = hypergraph.insert("b")
            #expect(result.inserted && result.memberAfterInsert == "b")
        }
        // After insert(b).
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        do {
            let result = hypergraph.insert("a")
            #expect(!result.inserted && result.memberAfterInsert == "a")
        }
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.degree(of: "a") == 0 && hypergraph.degree(ofIndex: 0) == 0)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.degree(of: "b") == 0 && hypergraph.degree(ofIndex: 1) == 0)
    }

    @Test("HG-036 insert(hyperedge:) returns the new position and inserts missing members")
    func hg036() {
        // U V [a]; E [{a}] / insert(hyperedge: [c, a, b]) / incidentHyperedges(of: a)
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a"] as [String], hyperedges: [["a"]] as [[String]])
        #expect(hypergraph.insert(hyperedge: ["c", "a", "b"] as [String]) == 1)
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0, 1])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "c", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a"], ["a", "c", "b"]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "c", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0] && hypergraph.size(ofHyperedgeAt: 0) == 1)
        #expect(hypergraph.contains(hyperedge: ["a"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == ["a", "c", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [0, 1, 2] && hypergraph.size(ofHyperedgeAt: 1) == 3)
        #expect(hypergraph.contains(hyperedge: ["b", "c", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0, 1])
        #expect(hypergraph.degree(of: "a") == 2 && hypergraph.degree(ofIndex: 0) == 2)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.incidentHyperedges(of: "c")) == [1] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [1])
        #expect(hypergraph.degree(of: "c") == 1 && hypergraph.degree(ofIndex: 1) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [1] && Array(hypergraph.incidentHyperedges(ofIndex: 2)) == [1])
        #expect(hypergraph.degree(of: "b") == 1 && hypergraph.degree(ofIndex: 2) == 1)
    }

    @Test("HG-037 insert(hyperedge:) of an existing member set adds a copy")
    func hg037() {
        // U V []; E [{a, b}] / insert(hyperedge: [b, a]) / vertexCount/hyperedgeCount
        var hypergraph = UndirectedIncidenceList<String>(vertices: [] as [String], hyperedges: [["a", "b"]] as [[String]])
        #expect(hypergraph.insert(hyperedge: ["b", "a"] as [String]) == 1)
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 2)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b"], ["a", "b"]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 1) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0, 1])
        #expect(hypergraph.degree(of: "a") == 2 && hypergraph.degree(ofIndex: 0) == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0, 1] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0, 1])
        #expect(hypergraph.degree(of: "b") == 2 && hypergraph.degree(ofIndex: 1) == 2)
    }

    @Test("HG-038 insert(hyperedge:) of the empty set")
    func hg038() {
        // U V [a]; E [] / insert(hyperedge: []) / size(ofHyperedgeAt: 0)
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a"] as [String], hyperedges: [] as [[String]])
        #expect(hypergraph.insert(hyperedge: [] as [String]) == 0)
        #expect(hypergraph.size(ofHyperedgeAt: 0) == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [[]])
        #expect(hypergraph.vertexCount == 1 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 1 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { hypergraph.vertex(atIndex: $0) } == ["a"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == [] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [] && hypergraph.size(ofHyperedgeAt: 0) == 0)
        #expect(hypergraph.contains(hyperedge: [] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.degree(of: "a") == 0 && hypergraph.degree(ofIndex: 0) == 0)
    }

    @Test("HG-039 insert(checked:) with every member present")
    func hg039() throws {
        // U V [a, b]; E [] / insert(checked: [a, b])
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "b"] as [String], hyperedges: [] as [[String]])
        #expect(try hypergraph.insert(checked: ["a", "b"] as [String]) == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["a", "b"]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 0) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.degree(of: "a") == 1 && hypergraph.degree(ofIndex: 0) == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.degree(of: "b") == 1 && hypergraph.degree(ofIndex: 1) == 1)
    }

    @Test("HG-040 insert(checked:) with a missing member: throws, nothing changes")
    func hg040() throws {
        // U V [a, b]; E [] / insert(checked: [a, z]) / vertexCount/hyperedgeCount
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "b"] as [String], hyperedges: [] as [[String]])
        #expect(throws: VertexNotFound.self) { try hypergraph.insert(checked: ["a", "z"] as [String]) }
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.degree(of: "a") == 0 && hypergraph.degree(ofIndex: 0) == 0)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.degree(of: "b") == 0 && hypergraph.degree(ofIndex: 1) == 0)
    }

    @Test("HG-041 removeAll")
    func hg041() {
        // U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / removeAll() / vertexCount/hyperedgeCount
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "b", "c", "d", "e", "f"] as [String], hyperedges: [["a", "b", "c"], ["c", "d"], ["a", "b", "c"], ["e"]] as [[String]])
        hypergraph.removeAll()
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == [])
        #expect(hypergraph.hyperedges.map { Array($0) } == [])
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 0 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [])
        #expect((0 ..< 0).map { hypergraph.vertex(atIndex: $0) } == [])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
    }

    @Test("HG-042 incidence rows stay ascending under appends")
    func hg042() {
        // U V [a, b]; E [{b}] / insert(hyperedge: [a]) / insert(hyperedge: [b, a]) / incidentHyperedges(of: b) / incidentHyperedges(of: a)
        var hypergraph = UndirectedIncidenceList<String>(vertices: ["a", "b"] as [String], hyperedges: [["b"]] as [[String]])
        #expect(hypergraph.insert(hyperedge: ["a"] as [String]) == 1)
        // After insert(hyperedge: [a]).
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["b"], ["a"]])
        #expect(hypergraph.insert(hyperedge: ["b", "a"] as [String]) == 2)
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0, 2])
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [1, 2])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { Array($0) } == [["b"], ["a"], ["a", "b"]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 3 && hypergraph.hyperedges.count == 3)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 3)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(hypergraph.members(ofHyperedgeAt: 0)) == ["b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 0)) == [1] && hypergraph.size(ofHyperedgeAt: 0) == 1)
        #expect(hypergraph.contains(hyperedge: ["b"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 1)) == ["a"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 1)) == [0] && hypergraph.size(ofHyperedgeAt: 1) == 1)
        #expect(hypergraph.contains(hyperedge: ["a"] as [String]))
        #expect(Array(hypergraph.members(ofHyperedgeAt: 2)) == ["a", "b"] && Array(hypergraph.memberIndices(ofHyperedgeAt: 2)) == [0, 1] && hypergraph.size(ofHyperedgeAt: 2) == 2)
        #expect(hypergraph.contains(hyperedge: ["b", "a"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.incidentHyperedges(of: "a")) == [1, 2] && Array(hypergraph.incidentHyperedges(ofIndex: 0)) == [1, 2])
        #expect(hypergraph.degree(of: "a") == 2 && hypergraph.degree(ofIndex: 0) == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.incidentHyperedges(of: "b")) == [0, 2] && Array(hypergraph.incidentHyperedges(ofIndex: 1)) == [0, 2])
        #expect(hypergraph.degree(of: "b") == 2 && hypergraph.degree(ofIndex: 1) == 2)
    }
}
