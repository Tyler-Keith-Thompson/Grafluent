// Boundary (catalog LG-054 – LG-060): algorithms see the base through the index-space members, so
// index-space reads hash no label and a label-space read hashes one; topologicalSort and
// descendants are the base's results through the labels.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import LabeledGraphs
import Testing
import Traversal

@Suite("LabeledGraphs boundary")
struct LabeledGraphBoundaryTests {
    @Test("LG-054 index-space reads do not hash")
    func lg054() {
        // CSR V []; E [a→b, b→c, c→d, d→e] / successorIndices(ofIndex: 0) / vertex(atIndex: 4) / edges[3] / hashes()
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(graph.vertex(atIndex: 4) == "e")
        #expect(graph.edges[3] == DirectedEdge(from: "d", to: "e"))
        // hashes() is 0 here: see the counted copy below.
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4)
        #expect(graph.vertexIndexBound == 5)
        #expect(graph.edgeIndexBound == 4)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { graph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(graph.base.vertexCount == 5)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == ["b"])
        #expect(Array(graph.outEdges(of: "a")) == [0])
        #expect(graph.outDegree(of: "a") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 0)) == [0])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["c"])
        #expect(Array(graph.outEdges(of: "b")) == [1])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [2])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [1])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == ["d"])
        #expect(Array(graph.outEdges(of: "c")) == [2])
        #expect(graph.outDegree(of: "c") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [3])
        #expect(Array(graph.outEdges(ofIndex: 2)) == [2])
        #expect(graph.contains("d"))
        #expect(Array(graph.successors(of: "d")) == ["e"])
        #expect(Array(graph.outEdges(of: "d")) == [3])
        #expect(graph.outDegree(of: "d") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 3)) == [4])
        #expect(Array(graph.outEdges(ofIndex: 3)) == [3])
        #expect(graph.contains("e"))
        #expect(Array(graph.successors(of: "e")) == [] as [String])
        #expect(Array(graph.outEdges(of: "e")) == [] as [Int])
        #expect(graph.outDegree(of: "e") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 4)) == [] as [Int])
        #expect(Array(graph.outEdges(ofIndex: 4)) == [] as [Int])
        #expect(graph.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "c")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "d")))
        #expect(graph.contains(edge: DirectedEdge(from: "d", to: "e")))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2, 3])
        // Label hashes, counted by a label whose hash(into:) counts. OrderedSet hashes only from 16
        // elements (up to 15 it scans), so 16 isolated labels follow the catalog's; they come after
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
        let counted = LabeledGraph<Counted, CompressedSparseRow>(vertices: (["a", "b", "c", "d", "e"] + pads).map(label), edges: [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]].map { DirectedEdge(from: label($0[0]), to: label($0[1])) })
        tally.hashes = 0
        tally.comparisons = 0
        let r1 = Array(counted.successorIndices(ofIndex: 0))
        let r2 = counted.vertex(atIndex: 4).name
        let r3 = counted.edges[3]
        #expect(tally.hashes == 0)
        #expect(tally.comparisons == 0)
        #expect(r1 == [1])
        #expect(r2 == "e")
        #expect([r3.source.name, r3.target.name] == ["d", "e"])
    }

    @Test("LG-055 a label-space read hashes once, not per successor")
    func lg055() {
        // CSR V []; E [a→b, b→c, c→d, d→e] / successors(a) / hashes()
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(Array(graph.successors(of: "a")) == ["b"])
        // hashes() is 1 here: see the counted copy below.
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4)
        #expect(graph.vertexIndexBound == 5)
        #expect(graph.edgeIndexBound == 4)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { graph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(graph.base.vertexCount == 5)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == ["b"])
        #expect(Array(graph.outEdges(of: "a")) == [0])
        #expect(graph.outDegree(of: "a") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 0)) == [0])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["c"])
        #expect(Array(graph.outEdges(of: "b")) == [1])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [2])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [1])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == ["d"])
        #expect(Array(graph.outEdges(of: "c")) == [2])
        #expect(graph.outDegree(of: "c") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [3])
        #expect(Array(graph.outEdges(ofIndex: 2)) == [2])
        #expect(graph.contains("d"))
        #expect(Array(graph.successors(of: "d")) == ["e"])
        #expect(Array(graph.outEdges(of: "d")) == [3])
        #expect(graph.outDegree(of: "d") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 3)) == [4])
        #expect(Array(graph.outEdges(ofIndex: 3)) == [3])
        #expect(graph.contains("e"))
        #expect(Array(graph.successors(of: "e")) == [] as [String])
        #expect(Array(graph.outEdges(of: "e")) == [] as [Int])
        #expect(graph.outDegree(of: "e") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 4)) == [] as [Int])
        #expect(Array(graph.outEdges(ofIndex: 4)) == [] as [Int])
        #expect(graph.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "c")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "d")))
        #expect(graph.contains(edge: DirectedEdge(from: "d", to: "e")))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2, 3])
        // Label hashes, counted by a label whose hash(into:) counts. OrderedSet hashes only from 16
        // elements (up to 15 it scans), so 16 isolated labels follow the catalog's; they come after
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
        let counted = LabeledGraph<Counted, CompressedSparseRow>(vertices: (["a", "b", "c", "d", "e"] + pads).map(label), edges: [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]].map { DirectedEdge(from: label($0[0]), to: label($0[1])) })
        tally.hashes = 0
        tally.comparisons = 0
        let r1 = Array(counted.successors(of: label("a"))).map(\.name)
        #expect(tally.hashes == 1)
        #expect(r1 == ["b"])
    }

    @Test("LG-056 descendants: one lookup, plus one hash per vertex inserted into the returned Set")
    func lg056() {
        // CSR V []; E [a→b, b→c, c→d, d→e] / descendants(a) / hashes()
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(graph.descendants(of: "a") == Set(["b", "c", "d", "e"]))
        // hashes() is 1 here: see the counted copy below.
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4)
        #expect(graph.vertexIndexBound == 5)
        #expect(graph.edgeIndexBound == 4)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { graph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(graph.base.vertexCount == 5)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == ["b"])
        #expect(Array(graph.outEdges(of: "a")) == [0])
        #expect(graph.outDegree(of: "a") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 0)) == [0])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["c"])
        #expect(Array(graph.outEdges(of: "b")) == [1])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [2])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [1])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == ["d"])
        #expect(Array(graph.outEdges(of: "c")) == [2])
        #expect(graph.outDegree(of: "c") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [3])
        #expect(Array(graph.outEdges(ofIndex: 2)) == [2])
        #expect(graph.contains("d"))
        #expect(Array(graph.successors(of: "d")) == ["e"])
        #expect(Array(graph.outEdges(of: "d")) == [3])
        #expect(graph.outDegree(of: "d") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 3)) == [4])
        #expect(Array(graph.outEdges(ofIndex: 3)) == [3])
        #expect(graph.contains("e"))
        #expect(Array(graph.successors(of: "e")) == [] as [String])
        #expect(Array(graph.outEdges(of: "e")) == [] as [Int])
        #expect(graph.outDegree(of: "e") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 4)) == [] as [Int])
        #expect(Array(graph.outEdges(ofIndex: 4)) == [] as [Int])
        #expect(graph.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "c")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "d")))
        #expect(graph.contains(edge: DirectedEdge(from: "d", to: "e")))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2, 3])
        // Label hashes, counted by a label whose hash(into:) counts. OrderedSet hashes only from 16
        // elements (up to 15 it scans), so 16 isolated labels follow the catalog's; they come after
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
        let counted = LabeledGraph<Counted, CompressedSparseRow>(vertices: (["a", "b", "c", "d", "e"] + pads).map(label), edges: [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]].map { DirectedEdge(from: label($0[0]), to: label($0[1])) })
        tally.hashes = 0
        tally.comparisons = 0
        let r1 = counted.descendants(of: label("a"))
        // descendants(of:) looks its source up once (vertexIndex(of:), which also checks it is a
        // vertex) and hashes each vertex it reaches into its Set result, which a fresh Set built
        // in the same order hashes the same number of times. Nothing is hashed per edge.
        let hashes2 = tally.hashes
        tally.hashes = 0
        var rebuilt = Set<Counted>()
        for name in ["b", "c", "d", "e"] { rebuilt.insert(label(name)) }
        #expect(hashes2 == 1 + tally.hashes)
        #expect(Set(r1.map(\.name)) == Set(["b", "c", "d", "e"]))
    }

    @Test("LG-057 topologicalSort hashes nothing")
    func lg057() {
        // CSR V []; E [a→b, b→c, c→d, d→e] / topologicalSort() / hashes()
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(graph.topologicalSort() == ["a", "b", "c", "d", "e"])
        // hashes() is 0 here: see the counted copy below.
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4)
        #expect(graph.vertexIndexBound == 5)
        #expect(graph.edgeIndexBound == 4)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2, 3, 4])
        #expect((0 ..< 5).map { graph.vertex(atIndex: $0) } == ["a", "b", "c", "d", "e"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e")])
        #expect(graph.base.vertexCount == 5)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == ["b"])
        #expect(Array(graph.outEdges(of: "a")) == [0])
        #expect(graph.outDegree(of: "a") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 0)) == [0])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["c"])
        #expect(Array(graph.outEdges(of: "b")) == [1])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [2])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [1])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == ["d"])
        #expect(Array(graph.outEdges(of: "c")) == [2])
        #expect(graph.outDegree(of: "c") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [3])
        #expect(Array(graph.outEdges(ofIndex: 2)) == [2])
        #expect(graph.contains("d"))
        #expect(Array(graph.successors(of: "d")) == ["e"])
        #expect(Array(graph.outEdges(of: "d")) == [3])
        #expect(graph.outDegree(of: "d") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 3)) == [4])
        #expect(Array(graph.outEdges(ofIndex: 3)) == [3])
        #expect(graph.contains("e"))
        #expect(Array(graph.successors(of: "e")) == [] as [String])
        #expect(Array(graph.outEdges(of: "e")) == [] as [Int])
        #expect(graph.outDegree(of: "e") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 4)) == [] as [Int])
        #expect(Array(graph.outEdges(ofIndex: 4)) == [] as [Int])
        #expect(graph.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "c")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "d")))
        #expect(graph.contains(edge: DirectedEdge(from: "d", to: "e")))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2, 3])
        // Label hashes, counted by a label whose hash(into:) counts. OrderedSet hashes only from 16
        // elements (up to 15 it scans), so 16 isolated labels follow the catalog's; they come after
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
        let counted = LabeledGraph<Counted, CompressedSparseRow>(vertices: (["a", "b", "c", "d", "e"] + pads).map(label), edges: [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"]].map { DirectedEdge(from: label($0[0]), to: label($0[1])) })
        tally.hashes = 0
        tally.comparisons = 0
        let r1 = counted.topologicalSort()
        #expect(tally.hashes == 0)
        #expect(tally.comparisons == 0)
        // The padding is isolated; without it the order is the catalog's.
        #expect(r1?.map(\.name).filter { !$0.hasPrefix("pad") } == ["a", "b", "c", "d", "e"])
    }

    @Test("LG-058 topologicalSort is the base's, mapped through labels")
    func lg058() {
        // CSR V []; E [b→a, c→a, c→b] / topologicalSort()
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "c", to: "b")])
        #expect(graph.topologicalSort() == ["c", "b", "a"])
        // Final state.
        #expect(Array(graph.vertices) == ["b", "a", "c"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["b", "a"], ["c", "b"], ["c", "a"]])
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3)
        #expect(graph.vertexIndexBound == 3)
        #expect(graph.edgeIndexBound == 3)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { graph.vertex(atIndex: $0) } == ["b", "a", "c"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["b", "a"], ["c", "b"], ["c", "a"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "c", to: "a")])
        #expect(graph.base.vertexCount == 3)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1)])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["a"])
        #expect(Array(graph.outEdges(of: "b")) == [0])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 0)) == [0])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == [] as [String])
        #expect(Array(graph.outEdges(of: "a")) == [] as [Int])
        #expect(graph.outDegree(of: "a") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [] as [Int])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == ["b", "a"])
        #expect(Array(graph.outEdges(of: "c")) == [1, 2])
        #expect(graph.outDegree(of: "c") == 2)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [0, 1])
        #expect(Array(graph.outEdges(ofIndex: 2)) == [1, 2])
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "a")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "a")))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2])
    }

    @Test("LG-059 topologicalSort of a cyclic graph")
    func lg059() {
        // CSR V []; E [a→b, b→a, c→a] / topologicalSort() / descendants(c)
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: [] as [String], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a")])
        #expect(graph.topologicalSort() == nil)
        #expect(graph.descendants(of: "c") == Set(["a", "b"]))
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "a"], ["c", "a"]])
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3)
        #expect(graph.vertexIndexBound == 3)
        #expect(graph.edgeIndexBound == 3)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { graph.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "a"], ["c", "a"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a")])
        #expect(graph.base.vertexCount == 3)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 0)])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == ["b"])
        #expect(Array(graph.outEdges(of: "a")) == [0])
        #expect(graph.outDegree(of: "a") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 0)) == [0])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["a"])
        #expect(Array(graph.outEdges(of: "b")) == [1])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [0])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [1])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == ["a"])
        #expect(Array(graph.outEdges(of: "c")) == [2])
        #expect(graph.outDegree(of: "c") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [0])
        #expect(Array(graph.outEdges(ofIndex: 2)) == [2])
        #expect(graph.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "a")))
        #expect(graph.contains(edge: DirectedEdge(from: "c", to: "a")))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2])
    }

    @Test("LG-060 descendants of an isolated vertex")
    func lg060() {
        // M V [s]; E [a→b, b→c] / descendants(s) / descendants(a)
        let graph = LabeledGraph<String, AdjacencyMatrix>(vertices: ["s"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        #expect(graph.descendants(of: "s") == Set<String>())
        #expect(graph.descendants(of: "a") == Set(["b", "c"]))
        // Final state.
        #expect(Array(graph.vertices) == ["s", "a", "b", "c"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"]])
        #expect(graph.edges.indices.map { [$0.source, $0.target] } == [[1, 2], [2, 3]])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 2 && graph.edges.count == 2)
        #expect(graph.vertexIndexBound == 4)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2, 3])
        #expect((0 ..< 4).map { graph.vertex(atIndex: $0) } == ["s", "a", "b", "c"])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        #expect(graph.base.vertexCount == 4)
        #expect(Array(graph.base.edges) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        #expect(graph.contains("s"))
        #expect(Array(graph.successors(of: "s")) == [] as [String])
        #expect(graph.outEdges(of: "s").map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.outDegree(of: "s") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(graph.outEdges(ofIndex: 0).map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.predecessors(of: "s")) == [] as [String])
        #expect(graph.inEdges(of: "s").map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.inDegree(of: "s") == 0 && graph.degree(of: "s") == 0)
        #expect(Array(graph.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(graph.inEdges(ofIndex: 0).map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.contains("a"))
        #expect(Array(graph.successors(of: "a")) == ["b"])
        #expect(graph.outEdges(of: "a").map { [$0.source, $0.target] } == [[1, 2]])
        #expect(graph.outDegree(of: "a") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [2])
        #expect(graph.outEdges(ofIndex: 1).map { [$0.source, $0.target] } == [[1, 2]])
        #expect(Array(graph.predecessors(of: "a")) == [] as [String])
        #expect(graph.inEdges(of: "a").map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.inDegree(of: "a") == 0 && graph.degree(of: "a") == 1)
        #expect(Array(graph.predecessorIndices(ofIndex: 1)) == [] as [Int])
        #expect(graph.inEdges(ofIndex: 1).map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.contains("b"))
        #expect(Array(graph.successors(of: "b")) == ["c"])
        #expect(graph.outEdges(of: "b").map { [$0.source, $0.target] } == [[2, 3]])
        #expect(graph.outDegree(of: "b") == 1)
        #expect(Array(graph.successorIndices(ofIndex: 2)) == [3])
        #expect(graph.outEdges(ofIndex: 2).map { [$0.source, $0.target] } == [[2, 3]])
        #expect(Array(graph.predecessors(of: "b")) == ["a"])
        #expect(graph.inEdges(of: "b").map { [$0.source, $0.target] } == [[1, 2]])
        #expect(graph.inDegree(of: "b") == 1 && graph.degree(of: "b") == 2)
        #expect(Array(graph.predecessorIndices(ofIndex: 2)) == [1])
        #expect(graph.inEdges(ofIndex: 2).map { [$0.source, $0.target] } == [[1, 2]])
        #expect(graph.contains("c"))
        #expect(Array(graph.successors(of: "c")) == [] as [String])
        #expect(graph.outEdges(of: "c").map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.outDegree(of: "c") == 0)
        #expect(Array(graph.successorIndices(ofIndex: 3)) == [] as [Int])
        #expect(graph.outEdges(ofIndex: 3).map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.predecessors(of: "c")) == ["b"])
        #expect(graph.inEdges(of: "c").map { [$0.source, $0.target] } == [[2, 3]])
        #expect(graph.inDegree(of: "c") == 1 && graph.degree(of: "c") == 1)
        #expect(Array(graph.predecessorIndices(ofIndex: 3)) == [2])
        #expect(graph.inEdges(ofIndex: 3).map { [$0.source, $0.target] } == [[2, 3]])
        #expect(graph.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(graph.contains(edge: DirectedEdge(from: "b", to: "c")))
    }
}
