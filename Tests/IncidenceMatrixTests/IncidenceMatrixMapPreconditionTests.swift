// Map preconditions of both matrices: a column or vertex out of range traps to read and to write
// (the checked reads throw instead), and a handle traps on another matrix, on a derived matrix and
// after its map is removed. Each case runs in a child process (exit test). See README.md.

import GrafluentTestSupport
import GraphProtocols
import IncidenceMatrixModule
import Testing

@Suite("IncidenceMatrix map preconditions", .tags(.precondition))
struct IncidenceMatrixMapPreconditionTests {
    @Test("A column or vertex out of range traps to read and to write")
    func outOfRange() async {
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            let weights = matrix.addEdgeMap(default: 0)
            _ = matrix[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            let weights = matrix.addEdgeMap(default: 0)
            matrix[weights, ofEdgeAt: -1] = 2
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: "")
            _ = matrix[names, of: 2]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: "")
            matrix[names, ofVertexAt: 2] = "x"
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            let weights = matrix.addEdgeMap(default: 0)
            matrix.removeAll()
            _ = matrix[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            _ = matrix[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(of: String.self)
            matrix[weights, ofEdgeAt: 3] = nil
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: 0)
            matrix[names, of: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: 0)
            _ = matrix[names, ofVertexAt: 2]
        }
    }

    @Test("A handle traps on another matrix, on a derived matrix and after its map is removed")
    func handleMisuse() async {
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            let weights = matrix.addEdgeMap(default: 0)
            let other = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            _ = other[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            let names = matrix.addVertexMap(default: 0)
            _ = matrix.transposed()[names, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
            let weights = matrix.addEdgeMap(default: 0)
            matrix.removeEdgeMap(weights)
            _ = matrix.values(of: weights)
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            _ = matrix.reversed[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = matrix.addEdgeMap(default: 0)
            _ = IncidenceMatrix(matrix)[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var matrix = OrientedIncidenceMatrix(vertexCount: 2)
            let names = matrix.addVertexMap(default: 0)
            matrix.removeVertexMap(names)
            _ = try? matrix[names, checked: 0]
        }
    }
}
