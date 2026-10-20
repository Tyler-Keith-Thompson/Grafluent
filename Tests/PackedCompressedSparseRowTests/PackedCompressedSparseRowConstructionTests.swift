// Construction, value semantics and the value protocols of PackedCompressedSparseRow: the bulk
// initializers, the builder and the dictionary literal, copying any directed graph, equality and
// hashing by vertex and edge sets, Codable round trips, descriptions, generations, and the sorted
// construction protocol through a named family. Case IDs (C-nn) refer to the AdjacencyList catalog.

import AdjacencyListModule
import CompressedSparseRowModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import PackedCompressedSparseRowModule
import Testing

@Suite("PackedCompressedSparseRow construction and value semantics")
struct PackedCompressedSparseRowConstructionTests {
    @Test("Bulk initializers, the builder and the literal give the same graph; repeats are one each")
    func bulkForms() {
        let edges = [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "c")]
        let fromEdges = PackedCompressedSparseRow(edges: edges)
        let fromBoth = PackedCompressedSparseRow(vertices: ["d", "a"], edges: edges)
        let adjacency = PackedCompressedSparseRow(adjacency: ["a": ["b"], "b": ["c"], "c": ["c"], "d": []])
        let literal: PackedCompressedSparseRow<String> = ["a": ["b"], "b": ["c"], "c": ["c"], "d": []]
        let built = PackedCompressedSparseRow<String> {
            "d"
            DirectedEdge(from: "a", to: "b"); DirectedEdge(from: "b", to: "c"); DirectedEdge(from: "c", to: "c")
        }
        #expect(fromEdges.vertexCount == 3 && fromEdges.edgeCount == 3)
        #expect(Array(fromBoth.vertices) == ["d", "a", "b", "c"] && fromBoth.edgeCount == 3)
        #expect(fromBoth == adjacency && adjacency == literal && literal == built)
        #expect(fromEdges != fromBoth)
        #expect(Array(fromBoth.edges) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "c")])
        verify(fromBoth, ["a", "b", "c", "d"], [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "c")])
    }

    @Test("Any directed graph copies in, including itself without a copy of the storage")
    func fromGraph() {
        let list = AdjacencyList(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 4, to: 0)])
        let packed = PackedCompressedSparseRow(list)
        #expect(Array(packed.vertices) == Array(list.vertices) && Array(packed.edges) == Array(list.edges))
        let csr = CompressedSparseRow(vertexCount: 5, edges: Array(list.edges))
        #expect(PackedCompressedSparseRow(csr) == packed)
        let again = PackedCompressedSparseRow(packed)
        #expect(again == packed && again.generation == packed.generation)
        let reference = ReferenceDirectedMultigraph(vertices: ["x", "y"], edges: [DirectedEdge(from: "x", to: "y")])
        #expect(PackedCompressedSparseRow(reference).contains(edge: DirectedEdge(from: "x", to: "y")))
    }

    @Test("The sorted construction protocol builds it: a complete graph and a cycle through CompressedSparseRow's edges")
    func sortedConstruction() {
        let complete = (0 ..< 6).flatMap { u in (0 ..< 6).filter { $0 != u }.map { DirectedEdge(from: u, to: $0) } }
        let csr = CompressedSparseRow(vertexCount: 6, edges: complete)
        let packed = PackedCompressedSparseRow(_vertexCount: 6, sortedEdges: complete, _ConstructionToken())
        #expect(packed.vertexCount == 6 && packed.edgeCount == 30 && Array(packed.edges) == Array(csr.edges))
        #expect((0 ..< 6).allSatisfy { Array(packed.successorIndices(ofIndex: $0)) == Array(csr.successorIndices(ofIndex: $0)) })
        #expect(Array(packed.outEdges(ofIndex: 5)) == Array(25 ..< 30))
    }

    @Test("Equality and hashing see vertex and edge sets, not slots, positions or spare cells")
    func equalityAndHash() {
        var a = PackedCompressedSparseRow(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3)])
        var b = PackedCompressedSparseRow<Int>()
        b.insert(edge: DirectedEdge(from: 2, to: 3))
        b.insert(1)
        b.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(a == b && a.hashValue == b.hashValue)
        a.insert(edge: DirectedEdge(from: 3, to: 0))
        #expect(a != b)
        b.insert(edge: DirectedEdge(from: 3, to: 0))
        b.insert(edge: DirectedEdge(from: 1, to: 1))
        b.remove(edge: DirectedEdge(from: 1, to: 1))
        #expect(a == b && a.hashValue == b.hashValue)
        #expect(Set([a, b]).count == 1)
        let crossed = PackedCompressedSparseRow(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3)])
        let straight = PackedCompressedSparseRow(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3)])
        #expect(crossed != straight)
        #expect(crossed.hashValue != straight.hashValue)
    }

    @Test("Codable round trips keep vertices, edges and slot order; a corrupt edge list throws")
    func codable() throws {
        var graph = PackedCompressedSparseRow(vertices: ["p", "q", "r"], edges: [DirectedEdge(from: "p", to: "q"), DirectedEdge(from: "q", to: "r")])
        graph.insert(edge: DirectedEdge(from: "r", to: "p"))
        let data = try JSONEncoder().encode(graph)
        let back = try JSONDecoder().decode(PackedCompressedSparseRow<String>.self, from: data)
        #expect(back == graph && Array(back.vertices) == Array(graph.vertices) && Array(back.edges) == Array(graph.edges))
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\"vertices\"") && text.contains("\"edges\""))
        let odd = Data("{\"vertices\":[\"p\"],\"edges\":[0]}".utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PackedCompressedSparseRow<String>.self, from: odd) }
        let outOfRange = Data("{\"vertices\":[\"p\"],\"edges\":[0,1]}".utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PackedCompressedSparseRow<String>.self, from: outOfRange) }
        let repeated = Data("{\"vertices\":[\"p\",\"q\"],\"edges\":[0,1,0,1]}".utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PackedCompressedSparseRow<String>.self, from: repeated) }
        // AdjacencyList's encoding decodes as a packed graph and back.
        let list = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2)])
        let crossed = try JSONDecoder().decode(PackedCompressedSparseRow<Int>.self, from: try JSONEncoder().encode(list))
        #expect(Array(crossed.edges) == Array(list.edges))
    }

    @Test("Descriptions list vertices and edges; the generation moves with every structural change")
    func descriptionsAndGeneration() {
        var graph = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)])
        #expect(graph.description.contains("1") && graph.description.contains("2"))
        #expect(graph.debugDescription.hasPrefix("PackedCompressedSparseRow<Int>(vertexCount: 2, edgeCount: 1"))
        #expect(graph.customMirror.children.count == 2)
        let g0 = graph.generation
        let derived = GraphGeneration.untracked
        #expect(!derived.isCurrent(for: graph))
        graph.insert(3)
        let g1 = graph.generation
        #expect(g1 != g0 && !g0.isCurrent(for: graph) && g1.isCurrent(for: graph))
        graph.insert(edge: DirectedEdge(from: 3, to: 1))
        #expect(graph.generation != g1)
        let weights = graph.addEdgeMap(default: 0.0)
        let g2 = graph.generation
        graph[weights, ofEdgeAt: 0] = 2.5
        #expect(graph.generation == g2, "a map write is not a structural change")
        graph.remove(edge: DirectedEdge(from: 3, to: 1))
        #expect(graph.generation != g2)
    }

    @Test("Value semantics: a copy keeps its vertices, edges and map values while the original changes")
    func valueSemantics() {
        var original = PackedCompressedSparseRow(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        let weights = original.addEdgeMap(default: 1)
        original[weights, ofEdgeAt: 0] = 7
        let copy = original
        for v in 3 ..< 40 { original.insert(edge: DirectedEdge(from: v - 1, to: v)) }
        original.remove(0)
        original[weights, ofEdgeAt: 0] = 9
        #expect(copy.vertexCount == 3 && copy.edgeCount == 1 && copy[weights, ofEdgeAt: 0] == 7)
        #expect(original.vertexCount == 39 && !original.contains(0))
        verify(copy, [0, 1, 2], [DirectedEdge(from: 0, to: 1)])
    }
}
