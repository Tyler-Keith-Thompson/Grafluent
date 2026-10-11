// Construction and mutation (catalog DH-001 – DH-007, DH-018 – DH-021): listed vertices, then each new
// hyperedge's sources, then its targets, by first appearance; each side stored once in index order;
// empty sides, the empty hyperedge, a vertex on both sides and repeats are kept.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Hypergraphs
import Testing

@Suite("IncidenceList construction and mutation")
struct IncidenceListConstructionTests {
    @Test("DH-001 empty")
    func dh001() {
        // D V []; E []
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [] as [(sources: [String], targets: [String])])
        // Final state.
        #expect(Array(hypergraph.vertices) == [])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 0 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [])
        #expect((0 ..< 0).map { hypergraph.vertex(atIndex: $0) } == [])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>()
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(vertices: [] as [String])
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(hyperedges: [] as [(sources: [String], targets: [String])])
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == [])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-002 listed vertices first, then sources then targets of each hyperedge by first appearance")
    func dh002() {
        // D V [z]; E [{x, z}→{y}, {w}→{x}]
        let hypergraph = IncidenceList<String>(vertices: ["z"] as [String], hyperedges: [(sources: ["x", "z"], targets: ["y"]), (sources: ["w"], targets: ["x"])] as [(sources: [String], targets: [String])])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["z", "x", "y", "w"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["z", "x"], ["y"]], [["w"], ["x"]]])
        #expect(hypergraph.vertexCount == 4 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 4 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3])
        #expect((0 ..< 4).map { hypergraph.vertex(atIndex: $0) } == ["z", "x", "y", "w"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["z", "x"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 1])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["y"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [2])
        #expect(hypergraph.contains(sources: ["x", "z"] as [String], targets: ["y"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["w"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [3])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["x"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [1])
        #expect(hypergraph.contains(sources: ["w"] as [String], targets: ["x"] as [String]))
        #expect(hypergraph.contains("z"))
        #expect(Array(hypergraph.outHyperedges(of: "z")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "z")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "z") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "z") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "z") == 1)
        #expect(hypergraph.contains("x"))
        #expect(Array(hypergraph.outHyperedges(of: "x")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "x")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [1])
        #expect(hypergraph.outDegree(of: "x") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "x") == 1 && hypergraph.inDegree(ofIndex: 1) == 1)
        #expect(hypergraph.degree(of: "x") == 2)
        #expect(hypergraph.contains("y"))
        #expect(Array(hypergraph.outHyperedges(of: "y")) == [] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "y")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0])
        #expect(hypergraph.outDegree(of: "y") == 0 && hypergraph.outDegree(ofIndex: 2) == 0 && hypergraph.inDegree(of: "y") == 1 && hypergraph.inDegree(ofIndex: 2) == 1)
        #expect(hypergraph.degree(of: "y") == 1)
        #expect(hypergraph.contains("w"))
        #expect(Array(hypergraph.outHyperedges(of: "w")) == [1] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [1])
        #expect(Array(hypergraph.inHyperedges(of: "w")) == [] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [])
        #expect(hypergraph.outDegree(of: "w") == 1 && hypergraph.outDegree(ofIndex: 3) == 1 && hypergraph.inDegree(of: "w") == 0 && hypergraph.inDegree(ofIndex: 3) == 0)
        #expect(hypergraph.degree(of: "w") == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["z", "x", "y", "w"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["z", "x"], ["y"]], [["w"], ["x"]]])
            #expect(built == hypergraph)
        }
        do {
            var built = IncidenceList<String>()
            built.insert("z")
            built.insert(sources: ["x", "z"] as [String], targets: ["y"] as [String])
            built.insert(sources: ["w"] as [String], targets: ["x"] as [String])
            #expect(Array(built.vertices) == ["z", "x", "y", "w"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["z", "x"], ["y"]], [["w"], ["x"]]])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-003 each side stored in vertex-index order")
    func dh003() {
        // D V [a, b, c, d]; E [{c, a}→{d, b}] / sources(ofHyperedgeAt: 0) / targets(ofHyperedgeAt: 0) / sourceIndices(ofHyperedgeAt: 0) / targetIndices(ofHyperedgeAt: 0)
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d"] as [String], hyperedges: [(sources: ["c", "a"], targets: ["d", "b"])] as [(sources: [String], targets: [String])])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a", "c"])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "d"])
        #expect(Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 2])
        #expect(Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 3])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "d"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "c"], ["b", "d"]]])
        #expect(hypergraph.vertexCount == 4 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 4 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3])
        #expect((0 ..< 4).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c", "d"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a", "c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "d"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 3])
        #expect(hypergraph.contains(sources: ["c", "a"] as [String], targets: ["d", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 1 && hypergraph.inDegree(ofIndex: 1) == 1)
        #expect(hypergraph.degree(of: "b") == 1)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [])
        #expect(hypergraph.outDegree(of: "c") == 1 && hypergraph.outDegree(ofIndex: 2) == 1 && hypergraph.inDegree(of: "c") == 0 && hypergraph.inDegree(ofIndex: 2) == 0)
        #expect(hypergraph.degree(of: "c") == 1)
        #expect(hypergraph.contains("d"))
        #expect(Array(hypergraph.outHyperedges(of: "d")) == [] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "d")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [0])
        #expect(hypergraph.outDegree(of: "d") == 0 && hypergraph.outDegree(ofIndex: 3) == 0 && hypergraph.inDegree(of: "d") == 1 && hypergraph.inDegree(ofIndex: 3) == 1)
        #expect(hypergraph.degree(of: "d") == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b", "c", "d"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "c"], ["b", "d"]]])
            #expect(built == hypergraph)
        }
        do {
            var built = IncidenceList<String>()
            built.insert("a")
            built.insert("b")
            built.insert("c")
            built.insert("d")
            built.insert(sources: ["c", "a"] as [String], targets: ["d", "b"] as [String])
            #expect(Array(built.vertices) == ["a", "b", "c", "d"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "c"], ["b", "d"]]])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-004 a repeated member within a side is stored once")
    func dh004() {
        // D V []; E [{a, a}→{b, b}]
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a", "a"], targets: ["b", "b"])] as [(sources: [String], targets: [String])])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 1 && hypergraph.inDegree(ofIndex: 1) == 1)
        #expect(hypergraph.degree(of: "b") == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>(hyperedges: [(sources: ["a", "a"], targets: ["b", "b"])] as [(sources: [String], targets: [String])])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]]])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]]])
            #expect(built == hypergraph)
        }
        do {
            var built = IncidenceList<String>()
            built.insert(sources: ["a", "a"] as [String], targets: ["b", "b"] as [String])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]]])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-005 a vertex may be a source and a target of the same hyperedge (XGI allows it; Gallo et al. require disjoint sides)")
    func dh005() {
        // D V []; E [{a, b}→{b, c}] / outHyperedges(of: b) / inHyperedges(of: b) / degree(of: b)
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a", "b"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0])
        #expect(hypergraph.degree(of: "b") == 2)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["b", "c"]]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 1])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 2])
        #expect(hypergraph.contains(sources: ["b", "a"] as [String], targets: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 1 && hypergraph.inDegree(ofIndex: 1) == 1)
        #expect(hypergraph.degree(of: "b") == 2)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0])
        #expect(hypergraph.outDegree(of: "c") == 0 && hypergraph.outDegree(ofIndex: 2) == 0 && hypergraph.inDegree(of: "c") == 1 && hypergraph.inDegree(ofIndex: 2) == 1)
        #expect(hypergraph.degree(of: "c") == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>(hyperedges: [(sources: ["a", "b"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["b", "c"]]])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["b", "c"]]])
            #expect(built == hypergraph)
        }
        do {
            var built = IncidenceList<String>()
            built.insert(sources: ["a", "b"] as [String], targets: ["b", "c"] as [String])
            #expect(Array(built.vertices) == ["a", "b", "c"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["b", "c"]]])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-006 empty sides and the empty hyperedge are kept")
    func dh006() {
        // D V []; E [{}→{a}, {a}→{}, {a}→{b}, {}→{}] / vertexCount/hyperedgeCount
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: [], targets: ["a"]), (sources: ["a"], targets: []), (sources: ["a"], targets: ["b"]), (sources: [], targets: [])] as [(sources: [String], targets: [String])])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 4)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[], ["a"]], [["a"], []], [["a"], ["b"]], [[], []]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 4 && hypergraph.hyperedges.count == 4)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 4)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [0])
        #expect(hypergraph.contains(sources: [] as [String], targets: ["a"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: [] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 2)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 2)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 2)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 2)) == [1])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 3)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 3)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 3)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 3)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [1, 2] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [0])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 1 && hypergraph.inDegree(ofIndex: 0) == 1)
        #expect(hypergraph.degree(of: "a") == 3)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [2] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [2])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 1 && hypergraph.inDegree(ofIndex: 1) == 1)
        #expect(hypergraph.degree(of: "b") == 1)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>(hyperedges: [(sources: [], targets: ["a"]), (sources: ["a"], targets: []), (sources: ["a"], targets: ["b"]), (sources: [], targets: [])] as [(sources: [String], targets: [String])])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[], ["a"]], [["a"], []], [["a"], ["b"]], [[], []]])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[], ["a"]], [["a"], []], [["a"], ["b"]], [[], []]])
            #expect(built == hypergraph)
        }
        do {
            var built = IncidenceList<String>()
            built.insert(sources: [] as [String], targets: ["a"] as [String])
            built.insert(sources: ["a"] as [String], targets: [] as [String])
            built.insert(sources: ["a"] as [String], targets: ["b"] as [String])
            built.insert(sources: [] as [String], targets: [] as [String])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[[], ["a"]], [["a"], []], [["a"], ["b"]], [[], []]])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-007 a repeated hyperedge is kept, each its own position")
    func dh007() {
        // D V []; E [{a}→{b}, {a}→{b}] / outHyperedges(of: a) / inHyperedges(of: b)
        let hypergraph = IncidenceList<String>(vertices: [] as [String], hyperedges: [(sources: ["a"], targets: ["b"]), (sources: ["a"], targets: ["b"])] as [(sources: [String], targets: [String])])
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 1])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 1])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]], [["a"], ["b"]]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 2 && hypergraph.hyperedges.count == 2)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 2)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [1])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 1] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0, 1])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 1] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 1])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 2)
        // The other initializers, and inserting one at a time, give the same state.
        do {
            let built = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"]), (sources: ["a"], targets: ["b"])] as [(sources: [String], targets: [String])])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]], [["a"], ["b"]]])
            #expect(built == hypergraph)
        }
        do {
            let built = IncidenceList<String>(hypergraph)
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]], [["a"], ["b"]]])
            #expect(built == hypergraph)
        }
        do {
            var built = IncidenceList<String>()
            built.insert(sources: ["a"] as [String], targets: ["b"] as [String])
            built.insert(sources: ["a"] as [String], targets: ["b"] as [String])
            #expect(Array(built.vertices) == ["a", "b"])
            #expect(built.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]], [["a"], ["b"]]])
            #expect(built == hypergraph)
        }
    }

    @Test("DH-018 insert(sources:targets:) appends, inserting missing vertices")
    func dh018() {
        // D V [a]; E [] / insert(sources: [b, a], targets: [c]) / outHyperedges(of: a)
        var hypergraph = IncidenceList<String>(vertices: ["a"] as [String], hyperedges: [] as [(sources: [String], targets: [String])])
        #expect(hypergraph.insert(sources: ["b", "a"] as [String], targets: ["c"] as [String]) == 0)
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a", "b"], ["c"]]])
        #expect(hypergraph.vertexCount == 3 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 3 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a", "b"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0, 1])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [2])
        #expect(hypergraph.contains(sources: ["b", "a"] as [String], targets: ["c"] as [String]))
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

    @Test("DH-019 insert(safe:targets:) with every vertex present")
    func dh019() {
        // D V [a, b]; E [] / insert(safe: [a], targets: [b])
        var hypergraph = IncidenceList<String>(vertices: ["a", "b"] as [String], hyperedges: [] as [(sources: [String], targets: [String])])
        #expect(hypergraph.insert(safe: ["a"] as [String], targets: ["b"] as [String]) == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b"]]])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 1 && hypergraph.hyperedges.count == 1)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 1)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 1 && hypergraph.outDegree(ofIndex: 0) == 1 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 1)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 1 && hypergraph.inDegree(ofIndex: 1) == 1)
        #expect(hypergraph.degree(of: "b") == 1)
    }

    @Test("DH-020 insert(safe:targets:) with a missing vertex: nil, nothing changes")
    func dh020() {
        // D V [a, b]; E [] / insert(safe: [a], targets: [z]) / vertexCount/hyperedgeCount
        var hypergraph = IncidenceList<String>(vertices: ["a", "b"] as [String], hyperedges: [] as [(sources: [String], targets: [String])])
        #expect(hypergraph.insert(safe: ["a"] as [String], targets: ["z"] as [String]) == nil)
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
        #expect(hypergraph.vertexCount == 2 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 2 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { hypergraph.vertex(atIndex: $0) } == ["a", "b"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 0 && hypergraph.outDegree(ofIndex: 0) == 0 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 0)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [])
        #expect(hypergraph.outDegree(of: "b") == 0 && hypergraph.outDegree(ofIndex: 1) == 0 && hypergraph.inDegree(of: "b") == 0 && hypergraph.inDegree(ofIndex: 1) == 0)
        #expect(hypergraph.degree(of: "b") == 0)
    }

    @Test("DH-021 removeAll")
    func dh021() {
        // D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / removeAll() / vertexCount/hyperedgeCount
        var hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d", "e"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["d", "e"]), (sources: ["c"], targets: ["c", "e"]), (sources: [], targets: []), (sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        hypergraph.removeAll()
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0)
        // Final state.
        #expect(Array(hypergraph.vertices) == [])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [])
        #expect(hypergraph.vertexCount == 0 && hypergraph.hyperedgeCount == 0 && hypergraph.hyperedges.count == 0)
        #expect(hypergraph.vertexIndexBound == 0 && hypergraph.hyperedgeIndexBound == 0)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [])
        #expect((0 ..< 0).map { hypergraph.vertex(atIndex: $0) } == [])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [])
    }
}
