// Incidence matrices (oriented and unoriented, undirected and directed: loops, parallel edges,
// column order, B Bᵀ = Q and = L) and modularity matrices (undirected and directed: hand-computed
// entries, row sums 0, loops, weights, no edges), and the rectangular SparseMatrix they need.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import SpectralGraphTheory
import Testing

@Suite("Incidence and modularity matrices")
struct IncidenceModularityTests {
    @Test("P3: the 3 × 2 incidence matrix, unoriented and oriented")
    func pathOfThree() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let b = graph.incidenceMatrix()
        #expect(b.rowCount == 3 && b.columnCount == 2 && b.nonzeroCount == 4)
        #expect(b.offsets == [0, 1, 3, 4] && b.columns == [0, 0, 1, 1] && b.values == [1, 1, 1, 1])
        let oriented = graph.incidenceMatrix(oriented: true)
        #expect(oriented.values == [-1, 1, -1, 1])
        #expect(oriented[0, 0] == -1 && oriented[1, 0] == 1 && oriented[1, 1] == -1 && oriented[2, 1] == 1 && oriented[2, 0] == 0)
        #expect(b * [1, 1] == [1, 2, 1])
        #expect(oriented * [1, 1] == [-1, 0, 1])
        #expect(b.description == "SparseMatrix(3×2, 4 stored: [0: 1.0]; [0: 1.0, 1: 1.0]; [1: 1.0])")
    }

    @Test("A loop has 2 at its vertex unoriented and an empty column oriented; parallel edges are separate columns")
    func loopsAndParallelEdges() {
        let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(1, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
        let b = graph.incidenceMatrix()
        #expect(b.columnCount == 4)
        #expect(b[1, 0] == 2 && b[0, 0] == 0 && b[0, 1] == 1 && b[0, 2] == 1 && b[1, 3] == 1 && b[2, 3] == 1)
        let oriented = graph.incidenceMatrix(oriented: true)
        #expect((0 ..< 3).allSatisfy { oriented[$0, 0] == 0 })
        // The edge 2–1 as stored: −1 at 2, +1 at 1.
        #expect(oriented[2, 3] == -1 && oriented[1, 3] == 1)
        #expect(oriented.nonzeroCount == 6 && b.nonzeroCount == 7)
    }

    @Test("Directed: −1 at the source and +1 at the target; a loop's column is empty oriented, 2 unoriented")
    func directed() {
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1)])
        let oriented = graph.incidenceMatrix(oriented: true)
        #expect(oriented.rowCount == 3 && oriented.columnCount == 4)
        #expect(oriented[2, 0] == -1 && oriented[0, 0] == 1 && oriented[0, 1] == -1 && oriented[1, 1] == 1 && oriented[0, 3] == -1 && oriented[1, 3] == 1)
        #expect((0 ..< 3).allSatisfy { oriented[$0, 2] == 0 })
        let b = graph.incidenceMatrix()
        #expect(b[1, 2] == 2 && b[2, 0] == 1 && b[0, 0] == 1)
        let csr = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(csr.incidenceMatrix(oriented: true).values == [-1, 1, -1, 1])
    }

    @Test("B Bᵀ is Q unoriented and L oriented, on a multigraph with loops")
    func gramIdentities() {
        let graph = Pseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(3, 4), UndirectedEdge(4, 0), UndirectedEdge(3, 3)])
        for (oriented, expected) in [(false, graph.signlessLaplacianMatrix()), (true, graph.laplacianMatrix())] {
            let b = graph.incidenceMatrix(oriented: oriented)
            for i in 0 ..< 5 {
                for j in 0 ..< 5 {
                    var sum = 0.0
                    for e in 0 ..< b.columnCount { sum += b[i, e] * b[j, e] }
                    #expect(sum == expected[i, j], "oriented \(oriented), (\(i), \(j))")
                }
            }
        }
    }

    @Test("Edgeless and empty graphs: no columns, no stored entries")
    func edgeless() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [])
        let b = graph.incidenceMatrix()
        #expect(b.rowCount == 3 && b.columnCount == 0 && b.nonzeroCount == 0 && b * [] == [0, 0, 0])
        let empty = UndirectedAdjacencyList<Int>(vertices: 0 ..< 0, edges: [])
        #expect(empty.incidenceMatrix(oriented: true).rowCount == 0)
        #expect(empty.modularityMatrix().isEmpty)
    }

    @Test("The modularity matrix of P3: A − k kᵀ / 4")
    func modularityOfPath() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let b = graph.modularityMatrix()
        let expected: [[Double]] = [[-0.25, 0.5, -0.25], [0.5, -1, 0.5], [-0.25, 0.5, -0.25]]
        #expect(b == expected)
        // The modularity of {0, 1}, {2}: Σ B over pairs in one community / vol.
        let q = (b[0][0] + b[0][1] + b[1][0] + b[1][1] + b[2][2]) / 4
        #expect(abs(q - (-0.125)) < 1e-15)
    }

    @Test("Modularity matrix rows sum to 0, with loops (A[v][v] = 2w) and weights; no edges gives zeros")
    func modularityProperties() {
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let weights = [3, 1, 2, 5, 4]
        let b = graph.modularityMatrix(weight: { weights[$0] })
        // A[0][0] = 6, k = (7, 8, 11, 4), vol 30.
        #expect(abs(b[0][0] - (6 - 49.0 / 30)) < 1e-12)
        #expect(abs(b[1][2] - (7 - 88.0 / 30)) < 1e-12)
        for row in b { #expect(abs(row.reduce(0, +)) < 1e-12) }
        #expect(b == graph.modularityMatrix(weight: { Double(weights[$0]) }))
        let unweighted = graph.modularityMatrix()
        // k = (3, 3, 3, 1), vol 10.
        #expect(abs(unweighted[1][2] - (2 - 9.0 / 10)) < 1e-12)
        let edgeless = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [])
        #expect(edgeless.modularityMatrix() == [[0, 0], [0, 0]])
        #expect(graph.modularityMatrix(weight: { _ in 0 }) == [[Double]](repeating: [0, 0, 0, 0], count: 4))
    }

    @Test("The directed modularity matrix A − k_out k_inᵀ / m: rows and columns sum to 0")
    func directedModularity() {
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        let b = graph.modularityMatrix()
        // k_out = (2, 1, 1), k_in = (0, 1, 3), m = 4.
        let expected: [[Double]] = [[0, 0.5, -0.5], [0, -0.25, 0.25], [0, -0.25, 0.25]]
        #expect(b == expected)
        let weighted = graph.modularityMatrix(weight: { [1, 1, 1, 0][$0] })
        for i in 0 ..< 3 {
            #expect(abs(weighted[i].reduce(0, +)) < 1e-15)
            #expect(abs((0 ..< 3).map { weighted[$0][i] }.reduce(0, +)) < 1e-15)
        }
        #expect(weighted == graph.modularityMatrix(weight: { [1.0, 1, 1, 0][$0] }))
        #expect(AdjacencyList<Int>(vertices: 0 ..< 2, edges: []).modularityMatrix() == [[0, 0], [0, 0]])
    }
}
