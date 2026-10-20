// Traps of PackedCompressedSparseRow, each in a child process: queries on a missing vertex or
// position, a repeated dictionary-literal key, negative reservations, and map subscripts outside the
// graph. Their checked spellings throw instead.

import GraphProtocols
import GrafluentTestSupport
import PackedCompressedSparseRowModule
import Testing

@Suite("PackedCompressedSparseRow preconditions")
struct PackedCompressedSparseRowPreconditionTests {
    @Test("A missing vertex traps in every plain query and throws in every checked one")
    func missingVertex() async {
        await #expect(processExitsWith: .failure) { _ = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)]).successors(of: 9) }
        await #expect(processExitsWith: .failure) { _ = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)]).predecessors(of: 9) }
        await #expect(processExitsWith: .failure) { _ = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)]).outEdges(of: 9) }
        await #expect(processExitsWith: .failure) { _ = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)]).degree(of: 9) }
        await #expect(processExitsWith: .failure) { _ = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)]).vertexIndex(of: 9) }
        await #expect(processExitsWith: .failure) { _ = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)]).source(ofEdgeAt: 5) }
        let graph = PackedCompressedSparseRow(vertices: [1, 2], edges: [DirectedEdge(from: 1, to: 2)])
        #expect(throws: VertexNotFound.self) { try graph.successors(checked: 9) }
        #expect(throws: VertexNotFound.self) { try graph.inDegree(checked: 9) }
        #expect(throws: EdgeNotFound.self) { try graph.target(checkedEdgeAt: 5) }
        #expect(throws: VertexNotFound.self) { var g = graph; try g.insert(checked: DirectedEdge(from: 1, to: 9)) }
        #expect((try? graph.outEdges(checked: 1)) == [0] && (try? graph.degree(checked: 2)) == 1)
    }

    @Test("A repeated literal key, a negative reservation and a map read outside the graph trap")
    func otherTraps() async {
        await #expect(processExitsWith: .failure) {
            let literal: PackedCompressedSparseRow<String> = ["a": ["b"], "a": []]
            _ = literal
        }
        await #expect(processExitsWith: .failure) {
            var graph = PackedCompressedSparseRow<Int>()
            graph.reserveCapacity(vertexCount: -1, edgeCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            var graph = PackedCompressedSparseRow(edges: [DirectedEdge(from: 0, to: 1)])
            let weight = graph.addEdgeMap(default: 0)
            _ = graph[weight, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = PackedCompressedSparseRow(edges: [DirectedEdge(from: 0, to: 1)])
            let label = graph.addVertexMap(default: 0)
            graph[label, ofVertexAt: 2] = 1
        }
    }
}
