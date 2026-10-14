// The preconditions of the eigenpairs, embedding, random-walk, incidence and
// modularity entry points, each in a child process (an exit test), followed by the same setup
// without the fault, so that the trap comes from the fault.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("Eigenpairs, embedding and random-walk preconditions")
struct EigenpairsTrapTests {
    @Test("Eigenpairs: a count past vertexCount, a negative count, tolerance ≤ 0, maxIterations 0, a negative Laplacian weight")
    func eigenpairs() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.laplacianEigenpairs(smallest: 4)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.adjacencyEigenpairs(largest: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.normalizedLaplacianEigenpairs(smallest: 1, tolerance: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.signlessLaplacianEigenpairs(largest: 1, maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.laplacianEigenpairs(smallest: 1, weight: { _ in -1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.adjacencyEigenpairs(largest: 1, weight: { _ in Double.nan })
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(try graph.laplacianEigenpairs(smallest: 3).count == 3)
        #expect(try graph.adjacencyEigenpairs(largest: 0, weight: { _ in -1 }).count == 0)
        #expect(try graph.normalizedLaplacianEigenpairs(smallest: 1, tolerance: 1e-3).count == 1)
        #expect(try graph.signlessLaplacianEigenpairs(largest: 1, maxIterations: 1).count == 1)
        let pairs = try graph.laplacianEigenpairs(smallest: 2)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.laplacianEigenpairs(smallest: 2).eigenvector(at: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.laplacianEigenpairs(smallest: 2).eigenvectorEntries(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.laplacianEigenpairs(smallest: 2).eigenvectorEntries(ofIndex: 3)
        }
        #expect(pairs.eigenvector(at: 1).count == 3 && pairs.eigenvectorEntries(ofIndex: 2).count == 2)
    }

    @Test("Embedding: dimensions outside 1..<n, a lookup off the graph")
    func embedding() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.spectralEmbedding(dimensions: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.spectralEmbedding(dimensions: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.spectralEmbedding(dimensions: 1).coordinates(of: 7)
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(try graph.spectralEmbedding(dimensions: 2).dimensions == 2)
        #expect(try graph.spectralEmbedding(dimensions: 1).coordinates(of: 2).count == 1)
    }

    @Test("Random walks: a vertex off the graph, tolerance ≤ 0, maxIterations 0, a negative weight")
    func randomWalks() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.hittingTime(from: 0, to: 5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.commuteTime(from: 5, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.hittingTime(from: 0, to: 1, tolerance: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = try graph.commuteTime(from: 0, to: 1, weight: { _ in -1 })
        }
        await #expect(processExitsWith: .failure) {
            let digraph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try digraph.stationaryDistribution(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let digraph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try digraph.stationaryDistribution(weight: { _ in -1.0 })
        }
        await #expect(processExitsWith: .failure) {
            let digraph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = try digraph.stationaryDistribution().probability(of: 2)
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(try graph.hittingTime(from: 0, to: 2) == nil)
        #expect(try graph.commuteTime(from: 1, to: 0, weight: { _ in 1 }) != nil)
        let digraph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(try digraph.stationaryDistribution(maxIterations: 100).probability(of: 1) > 0.5)
    }

    @Test("Matrices: a negative modularity weight; SparseMatrix index and vector length against the rectangular shape")
    func matrices() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.modularityMatrix(weight: { _ in -1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.incidenceMatrix()[0, 1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.incidenceMatrix() * [1, 1, 1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.incidenceMatrix().pattern
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(graph.modularityMatrix(weight: { _ in 1 })[0][1] == 0.5)
        #expect(graph.incidenceMatrix()[2, 0] == 0 && graph.incidenceMatrix() * [1] == [1, 1, 0])
        #expect(graph.laplacianMatrix().pattern.vertexCount == 3)
    }
}
