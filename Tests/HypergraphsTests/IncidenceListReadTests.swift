// Reads (catalog DH-008 – DH-012): the forward and backward stars in ascending position, degrees as
// in + out, contains(sources:targets:), the safe: lookups and the hash law.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Hypergraphs
import Testing

@Suite("IncidenceList reads")
struct IncidenceListReadTests {
    @Test("DH-008 out- and in-hyperedges ascend by position (Gallo's forward and backward stars)")
    func dh008() {
        // D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(of: a) / inHyperedges(of: c) / outHyperedges(of: c) / inHyperedges(of: a)
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d", "e"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["d", "e"]), (sources: ["c"], targets: ["c", "e"]), (sources: [], targets: []), (sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 4])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0, 2, 4])
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [])
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]])
        #expect(hypergraph.vertexCount == 5 && hypergraph.hyperedgeCount == 5 && hypergraph.hyperedges.count == 5)
        #expect(hypergraph.vertexIndexBound == 5 && hypergraph.hyperedgeIndexBound == 5)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["b", "c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [1, 2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["d", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [3, 4])
        #expect(hypergraph.contains(sources: ["c", "b"] as [String], targets: ["e", "d"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 2)) == ["c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 2)) == [2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 2)) == ["c", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 2)) == [2, 4])
        #expect(hypergraph.contains(sources: ["c"] as [String], targets: ["e", "c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 3)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 3)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 3)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 3)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 4)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 4)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 4)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 4)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 4] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0, 4])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [1] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [1])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 4] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 4])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 3)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0, 2, 4] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0, 2, 4])
        #expect(hypergraph.outDegree(of: "c") == 2 && hypergraph.outDegree(ofIndex: 2) == 2 && hypergraph.inDegree(of: "c") == 3 && hypergraph.inDegree(ofIndex: 2) == 3)
        #expect(hypergraph.degree(of: "c") == 5)
        #expect(hypergraph.contains("d"))
        #expect(Array(hypergraph.outHyperedges(of: "d")) == [] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "d")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [1])
        #expect(hypergraph.outDegree(of: "d") == 0 && hypergraph.outDegree(ofIndex: 3) == 0 && hypergraph.inDegree(of: "d") == 1 && hypergraph.inDegree(ofIndex: 3) == 1)
        #expect(hypergraph.degree(of: "d") == 1)
        #expect(hypergraph.contains("e"))
        #expect(Array(hypergraph.outHyperedges(of: "e")) == [] && Array(hypergraph.outHyperedges(ofIndex: 4)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "e")) == [1, 2] && Array(hypergraph.inHyperedges(ofIndex: 4)) == [1, 2])
        #expect(hypergraph.outDegree(of: "e") == 0 && hypergraph.outDegree(ofIndex: 4) == 0 && hypergraph.inDegree(of: "e") == 2 && hypergraph.inDegree(ofIndex: 4) == 2)
        #expect(hypergraph.degree(of: "e") == 2)
    }

    @Test("DH-009 degrees: in + out, so a vertex on both sides of one hyperedge counts it twice (XGI's degree: once)")
    func dh009() {
        // D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outDegree(of: c) / inDegree(of: c) / degree(of: c) / degree(of: e)
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d", "e"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["d", "e"]), (sources: ["c"], targets: ["c", "e"]), (sources: [], targets: []), (sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        #expect(hypergraph.outDegree(of: "c") == 2)
        #expect(hypergraph.inDegree(of: "c") == 3)
        #expect(hypergraph.degree(of: "c") == 5)
        #expect(hypergraph.degree(of: "e") == 2)
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]])
        #expect(hypergraph.vertexCount == 5 && hypergraph.hyperedgeCount == 5 && hypergraph.hyperedges.count == 5)
        #expect(hypergraph.vertexIndexBound == 5 && hypergraph.hyperedgeIndexBound == 5)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["b", "c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [1, 2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["d", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [3, 4])
        #expect(hypergraph.contains(sources: ["c", "b"] as [String], targets: ["e", "d"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 2)) == ["c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 2)) == [2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 2)) == ["c", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 2)) == [2, 4])
        #expect(hypergraph.contains(sources: ["c"] as [String], targets: ["e", "c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 3)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 3)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 3)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 3)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 4)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 4)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 4)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 4)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 4] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0, 4])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [1] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [1])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 4] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 4])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 3)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0, 2, 4] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0, 2, 4])
        #expect(hypergraph.outDegree(of: "c") == 2 && hypergraph.outDegree(ofIndex: 2) == 2 && hypergraph.inDegree(of: "c") == 3 && hypergraph.inDegree(ofIndex: 2) == 3)
        #expect(hypergraph.degree(of: "c") == 5)
        #expect(hypergraph.contains("d"))
        #expect(Array(hypergraph.outHyperedges(of: "d")) == [] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "d")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [1])
        #expect(hypergraph.outDegree(of: "d") == 0 && hypergraph.outDegree(ofIndex: 3) == 0 && hypergraph.inDegree(of: "d") == 1 && hypergraph.inDegree(ofIndex: 3) == 1)
        #expect(hypergraph.degree(of: "d") == 1)
        #expect(hypergraph.contains("e"))
        #expect(Array(hypergraph.outHyperedges(of: "e")) == [] && Array(hypergraph.outHyperedges(ofIndex: 4)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "e")) == [1, 2] && Array(hypergraph.inHyperedges(ofIndex: 4)) == [1, 2])
        #expect(hypergraph.outDegree(of: "e") == 0 && hypergraph.outDegree(ofIndex: 4) == 0 && hypergraph.inDegree(of: "e") == 2 && hypergraph.inDegree(ofIndex: 4) == 2)
        #expect(hypergraph.degree(of: "e") == 2)
    }

    @Test("DH-010 contains(sources:targets:) compares both sides as sets")
    func dh010() {
        // D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / contains(sources: [c, b], targets: [e, d]) / contains(sources: [d, e], targets: [b, c]) / contains(sources: [], targets: []) / contains(sources: [a], targets: [z])
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d", "e"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["d", "e"]), (sources: ["c"], targets: ["c", "e"]), (sources: [], targets: []), (sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        #expect(hypergraph.contains(sources: ["c", "b"] as [String], targets: ["e", "d"] as [String]))
        #expect(!hypergraph.contains(sources: ["d", "e"] as [String], targets: ["b", "c"] as [String]))
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(!hypergraph.contains(sources: ["a"] as [String], targets: ["z"] as [String]))
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]])
        #expect(hypergraph.vertexCount == 5 && hypergraph.hyperedgeCount == 5 && hypergraph.hyperedges.count == 5)
        #expect(hypergraph.vertexIndexBound == 5 && hypergraph.hyperedgeIndexBound == 5)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["b", "c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [1, 2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["d", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [3, 4])
        #expect(hypergraph.contains(sources: ["c", "b"] as [String], targets: ["e", "d"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 2)) == ["c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 2)) == [2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 2)) == ["c", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 2)) == [2, 4])
        #expect(hypergraph.contains(sources: ["c"] as [String], targets: ["e", "c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 3)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 3)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 3)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 3)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 4)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 4)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 4)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 4)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 4] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0, 4])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [1] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [1])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 4] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 4])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 3)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0, 2, 4] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0, 2, 4])
        #expect(hypergraph.outDegree(of: "c") == 2 && hypergraph.outDegree(ofIndex: 2) == 2 && hypergraph.inDegree(of: "c") == 3 && hypergraph.inDegree(ofIndex: 2) == 3)
        #expect(hypergraph.degree(of: "c") == 5)
        #expect(hypergraph.contains("d"))
        #expect(Array(hypergraph.outHyperedges(of: "d")) == [] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "d")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [1])
        #expect(hypergraph.outDegree(of: "d") == 0 && hypergraph.outDegree(ofIndex: 3) == 0 && hypergraph.inDegree(of: "d") == 1 && hypergraph.inDegree(ofIndex: 3) == 1)
        #expect(hypergraph.degree(of: "d") == 1)
        #expect(hypergraph.contains("e"))
        #expect(Array(hypergraph.outHyperedges(of: "e")) == [] && Array(hypergraph.outHyperedges(ofIndex: 4)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "e")) == [1, 2] && Array(hypergraph.inHyperedges(ofIndex: 4)) == [1, 2])
        #expect(hypergraph.outDegree(of: "e") == 0 && hypergraph.outDegree(ofIndex: 4) == 0 && hypergraph.inDegree(of: "e") == 2 && hypergraph.inDegree(ofIndex: 4) == 2)
        #expect(hypergraph.degree(of: "e") == 2)
    }

    @Test("DH-011 index-space reads hash nothing; a vertex-space read hashes once")
    func dh011() {
        // D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(ofIndex: 2) / inHyperedges(ofIndex: 2) / sourceIndices(ofHyperedgeAt: 1) / hashes() / outHyperedges(of: c) / hashes()
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d", "e"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["d", "e"]), (sources: ["c"], targets: ["c", "e"]), (sources: [], targets: []), (sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        #expect(Array(hypergraph.outHyperedges(ofIndex: 2)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(ofIndex: 2)) == [0, 2, 4])
        #expect(Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [1, 2])
        // hashes() is 0 here: see the counted copy below.
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2])
        // hashes() is 1 here: see the counted copy below.
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]])
        #expect(hypergraph.vertexCount == 5 && hypergraph.hyperedgeCount == 5 && hypergraph.hyperedges.count == 5)
        #expect(hypergraph.vertexIndexBound == 5 && hypergraph.hyperedgeIndexBound == 5)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["b", "c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [1, 2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["d", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [3, 4])
        #expect(hypergraph.contains(sources: ["c", "b"] as [String], targets: ["e", "d"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 2)) == ["c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 2)) == [2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 2)) == ["c", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 2)) == [2, 4])
        #expect(hypergraph.contains(sources: ["c"] as [String], targets: ["e", "c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 3)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 3)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 3)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 3)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 4)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 4)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 4)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 4)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 4] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0, 4])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [1] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [1])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 4] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 4])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 3)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0, 2, 4] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0, 2, 4])
        #expect(hypergraph.outDegree(of: "c") == 2 && hypergraph.outDegree(ofIndex: 2) == 2 && hypergraph.inDegree(of: "c") == 3 && hypergraph.inDegree(ofIndex: 2) == 3)
        #expect(hypergraph.degree(of: "c") == 5)
        #expect(hypergraph.contains("d"))
        #expect(Array(hypergraph.outHyperedges(of: "d")) == [] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "d")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [1])
        #expect(hypergraph.outDegree(of: "d") == 0 && hypergraph.outDegree(ofIndex: 3) == 0 && hypergraph.inDegree(of: "d") == 1 && hypergraph.inDegree(ofIndex: 3) == 1)
        #expect(hypergraph.degree(of: "d") == 1)
        #expect(hypergraph.contains("e"))
        #expect(Array(hypergraph.outHyperedges(of: "e")) == [] && Array(hypergraph.outHyperedges(ofIndex: 4)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "e")) == [1, 2] && Array(hypergraph.inHyperedges(ofIndex: 4)) == [1, 2])
        #expect(hypergraph.outDegree(of: "e") == 0 && hypergraph.outDegree(ofIndex: 4) == 0 && hypergraph.inDegree(of: "e") == 2 && hypergraph.inDegree(ofIndex: 4) == 2)
        #expect(hypergraph.degree(of: "e") == 2)
        // Vertex hashes, counted by a vertex whose hash(into:) counts. OrderedSet hashes only from 16
        // elements (up to 15 it scans), so 16 isolated vertices follow the catalog's; they come after
        // every index above and change none of them.
        final class Tally {
            var hashes = 0
            var comparisons = 0
        }
        struct Counted: Hashable {
            let name: String
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool {
                lhs.tally.comparisons += 1
                return lhs.name == rhs.name
            }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        func label(_ name: String) -> Counted { Counted(name: name, tally: tally) }
        let pads = (0 ..< 16).map { "pad\($0)" }
        let counted = IncidenceList<Counted>(vertices: (["a", "b", "c", "d", "e"] + pads).map(label), hyperedges: [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]].map { (sources: $0[0].map(label), targets: $0[1].map(label)) })
        tally.hashes = 0
        tally.comparisons = 0
        let r1 = Array(counted.outHyperedges(ofIndex: 2))
        let r2 = Array(counted.inHyperedges(ofIndex: 2))
        let r3 = Array(counted.sourceIndices(ofHyperedgeAt: 1))
        #expect(tally.hashes == 0)
        #expect(tally.comparisons == 0)
        let r5 = Array(counted.outHyperedges(of: label("c")))
        #expect(tally.hashes == 1)
        #expect(r1 == [1, 2])
        #expect(r2 == [0, 2, 4])
        #expect(r3 == [1, 2])
        #expect(r5 == [1, 2])
    }

    @Test("DH-012 safe: spellings return nil for a non-vertex")
    func dh012() {
        // D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(safe: z) / vertexIndex(safe: z) / outHyperedges(safe: a) / hashes()
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c", "d", "e"] as [String], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["d", "e"]), (sources: ["c"], targets: ["c", "e"]), (sources: [], targets: []), (sources: ["a"], targets: ["b", "c"])] as [(sources: [String], targets: [String])])
        #expect(hypergraph.outHyperedges(safe: "z").map { Array($0) } == nil)
        #expect(hypergraph.vertexIndex(safe: "z") == nil)
        #expect(hypergraph.outHyperedges(safe: "a").map { Array($0) } == [0, 4])
        // hashes() is 3 here: see the counted copy below.
        // Final state.
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]])
        #expect(hypergraph.vertexCount == 5 && hypergraph.hyperedgeCount == 5 && hypergraph.hyperedges.count == 5)
        #expect(hypergraph.vertexIndexBound == 5 && hypergraph.hyperedgeIndexBound == 5)
        #expect(hypergraph.vertices.map { hypergraph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { hypergraph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(hypergraph.hyperedges.indices.map { hypergraph.hyperedgeIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 0)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 0)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 0)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 0)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 1)) == ["b", "c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 1)) == [1, 2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 1)) == ["d", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 1)) == [3, 4])
        #expect(hypergraph.contains(sources: ["c", "b"] as [String], targets: ["e", "d"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 2)) == ["c"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 2)) == [2])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 2)) == ["c", "e"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 2)) == [2, 4])
        #expect(hypergraph.contains(sources: ["c"] as [String], targets: ["e", "c"] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 3)) == [] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 3)) == [])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 3)) == [] && Array(hypergraph.targetIndices(ofHyperedgeAt: 3)) == [])
        #expect(hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(Array(hypergraph.sources(ofHyperedgeAt: 4)) == ["a"] && Array(hypergraph.sourceIndices(ofHyperedgeAt: 4)) == [0])
        #expect(Array(hypergraph.targets(ofHyperedgeAt: 4)) == ["b", "c"] && Array(hypergraph.targetIndices(ofHyperedgeAt: 4)) == [1, 2])
        #expect(hypergraph.contains(sources: ["a"] as [String], targets: ["c", "b"] as [String]))
        #expect(hypergraph.contains("a"))
        #expect(Array(hypergraph.outHyperedges(of: "a")) == [0, 4] && Array(hypergraph.outHyperedges(ofIndex: 0)) == [0, 4])
        #expect(Array(hypergraph.inHyperedges(of: "a")) == [] && Array(hypergraph.inHyperedges(ofIndex: 0)) == [])
        #expect(hypergraph.outDegree(of: "a") == 2 && hypergraph.outDegree(ofIndex: 0) == 2 && hypergraph.inDegree(of: "a") == 0 && hypergraph.inDegree(ofIndex: 0) == 0)
        #expect(hypergraph.degree(of: "a") == 2)
        #expect(hypergraph.contains("b"))
        #expect(Array(hypergraph.outHyperedges(of: "b")) == [1] && Array(hypergraph.outHyperedges(ofIndex: 1)) == [1])
        #expect(Array(hypergraph.inHyperedges(of: "b")) == [0, 4] && Array(hypergraph.inHyperedges(ofIndex: 1)) == [0, 4])
        #expect(hypergraph.outDegree(of: "b") == 1 && hypergraph.outDegree(ofIndex: 1) == 1 && hypergraph.inDegree(of: "b") == 2 && hypergraph.inDegree(ofIndex: 1) == 2)
        #expect(hypergraph.degree(of: "b") == 3)
        #expect(hypergraph.contains("c"))
        #expect(Array(hypergraph.outHyperedges(of: "c")) == [1, 2] && Array(hypergraph.outHyperedges(ofIndex: 2)) == [1, 2])
        #expect(Array(hypergraph.inHyperedges(of: "c")) == [0, 2, 4] && Array(hypergraph.inHyperedges(ofIndex: 2)) == [0, 2, 4])
        #expect(hypergraph.outDegree(of: "c") == 2 && hypergraph.outDegree(ofIndex: 2) == 2 && hypergraph.inDegree(of: "c") == 3 && hypergraph.inDegree(ofIndex: 2) == 3)
        #expect(hypergraph.degree(of: "c") == 5)
        #expect(hypergraph.contains("d"))
        #expect(Array(hypergraph.outHyperedges(of: "d")) == [] && Array(hypergraph.outHyperedges(ofIndex: 3)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "d")) == [1] && Array(hypergraph.inHyperedges(ofIndex: 3)) == [1])
        #expect(hypergraph.outDegree(of: "d") == 0 && hypergraph.outDegree(ofIndex: 3) == 0 && hypergraph.inDegree(of: "d") == 1 && hypergraph.inDegree(ofIndex: 3) == 1)
        #expect(hypergraph.degree(of: "d") == 1)
        #expect(hypergraph.contains("e"))
        #expect(Array(hypergraph.outHyperedges(of: "e")) == [] && Array(hypergraph.outHyperedges(ofIndex: 4)) == [])
        #expect(Array(hypergraph.inHyperedges(of: "e")) == [1, 2] && Array(hypergraph.inHyperedges(ofIndex: 4)) == [1, 2])
        #expect(hypergraph.outDegree(of: "e") == 0 && hypergraph.outDegree(ofIndex: 4) == 0 && hypergraph.inDegree(of: "e") == 2 && hypergraph.inDegree(ofIndex: 4) == 2)
        #expect(hypergraph.degree(of: "e") == 2)
        // Vertex hashes, counted by a vertex whose hash(into:) counts. OrderedSet hashes only from 16
        // elements (up to 15 it scans), so 16 isolated vertices follow the catalog's; they come after
        // every index above and change none of them.
        final class Tally {
            var hashes = 0
            var comparisons = 0
        }
        struct Counted: Hashable {
            let name: String
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool {
                lhs.tally.comparisons += 1
                return lhs.name == rhs.name
            }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        func label(_ name: String) -> Counted { Counted(name: name, tally: tally) }
        let pads = (0 ..< 16).map { "pad\($0)" }
        let counted = IncidenceList<Counted>(vertices: (["a", "b", "c", "d", "e"] + pads).map(label), hyperedges: [[["a"], ["b", "c"]], [["b", "c"], ["d", "e"]], [["c"], ["c", "e"]], [[], []], [["a"], ["b", "c"]]].map { (sources: $0[0].map(label), targets: $0[1].map(label)) })
        tally.hashes = 0
        tally.comparisons = 0
        let r1 = counted.outHyperedges(safe: label("z")).map { Array($0) }
        let r2 = counted.vertexIndex(safe: label("z"))
        let r3 = counted.outHyperedges(safe: label("a")).map { Array($0) }
        #expect(tally.hashes == 3)
        #expect(r1 == nil)
        #expect(r2 == nil)
        #expect(r3 == [0, 4])
    }
}
