// Map preconditions: a cell with no edge has no value, so reading or writing it traps (the checked
// read throws instead); a vertex out of range traps; a handle traps on another matrix, on a
// complement or transpose, and after its map is removed. Each case runs in a child process (exit
// test). See README.md.

import AdjacencyMatrixModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("AdjacencyMatrix map preconditions", .tags(.precondition))
struct AdjacencyMatrixMapPreconditionTests {
    @Test("Reading or writing a removed edge's value traps")
    func deadCell() async {
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            let p = matrix.edges.startIndex
            matrix.remove(edge: DirectedEdge(from: 0, to: 1))
            _ = matrix[weights, ofEdgeAt: p]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            let p = matrix.edges.startIndex
            matrix.removeEdges(from: 0)
            matrix[weights, ofEdgeAt: p] = 3
        }
        await #expect(processExitsWith: .failure) {
            // Clearing an Optional value of a dead cell traps too: it has none.
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 1, to: 1)])
            let labels = matrix.addEdgeMap(of: String.self)
            let p = matrix.edges.startIndex
            matrix[1, 1] = false
            matrix[labels, ofEdgeAt: p] = nil
        }
        await #expect(processExitsWith: .failure) {
            // A cell outside the matrix after removeAll.
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 1, to: 0)])
            let weights = matrix.addEdgeMap(default: 0)
            let p = matrix.edges.startIndex
            matrix.removeAll()
            _ = matrix[weights, ofEdgeAt: p]
        }
    }

    @Test("A vertex out of range traps to read and to write")
    func vertexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: "")
            _ = matrix[names, of: 2]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: "")
            matrix[names, ofVertexAt: -1] = "x"
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: "")
            matrix[names, of: 5] = "x"
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: "")
            _ = matrix[names, ofVertexAt: 2]
        }
    }

    @Test("A handle traps on another matrix, on a complement or transpose, and after its map is removed")
    func handleMisuse() async {
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            let other = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = other[weights, ofEdgeAt: other.edges.startIndex]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let weights = matrix.addEdgeMap(default: 0)
            let complement = matrix.complement(includingSelfLoops: true)
            _ = complement[weights, ofEdgeAt: complement.edges.startIndex]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let names = matrix.addVertexMap(default: 0)
            _ = matrix.transposed()[names, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let names = matrix.addVertexMap(default: 0)
            _ = matrix.complement()[names, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            matrix.removeEdgeMap(weights)
            _ = matrix[weights, ofEdgeAt: matrix.edges.startIndex]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: 0)
            matrix.removeVertexMap(names)
            _ = matrix.values(of: names)
        }
        await #expect(processExitsWith: .failure) {
            // A checked read still traps for a handle of another matrix: that is a programming error.
            var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            let other = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try? other[weights, checkedEdgeAt: other.edges.startIndex]
        }
        await #expect(processExitsWith: .failure) {
            // Two copies each add a map: one copy's handle does not name the other's map.
            let matrix = AdjacencyMatrix(vertexCount: 2)
            var a = matrix, b = matrix
            _ = b.addVertexMap(default: 0)
            let names = a.addVertexMap(default: 0)
            _ = b[names, of: 0]
        }
    }
}
