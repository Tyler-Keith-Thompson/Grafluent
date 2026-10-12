// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the fault, so the trap is the fault's and not the
// setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory preconditions", .tags(.precondition))
struct SpectralPreconditionTests {
    @Test("SGT-032 Laplacian: negative weight")
    func sgt032() async {
        // U: P(0,1,2) · laplacianMatrix(weight:) [-1, 2] → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weights: [Int] = [-1, 2]
            _ = graph.laplacianMatrix(weight: { weights[$0] })
        }
        // Without the fault: the same graph with valid weights.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2]
        #expect(graph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)
    }

    @Test("SGT-033 Laplacian: NaN weight")
    func sgt033() async {
        // U: P(0,1,2) · laplacianMatrix(weight:) [nan, 2] → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weights: [Double] = [.nan, 2]
            _ = graph.laplacianMatrix(weight: { weights[$0] })
        }
        // Without the fault: the same graph with valid weights.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [1, 2]
        #expect(graph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)
    }

    @Test("SGT-034 Laplacian: infinite weight")
    func sgt034() async {
        // U: P(0,1,2) · laplacianMatrix(weight:) [inf, 2] → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weights: [Double] = [.infinity, 2]
            _ = graph.laplacianMatrix(weight: { weights[$0] })
        }
        // Without the fault: the same graph with valid weights.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [1, 2]
        #expect(graph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)
    }

    @Test("SGT-035 adjacency: NaN weight")
    func sgt035() async {
        // U: P(0,1,2) · adjacencyMatrix(weight:) [nan, 2] → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weights: [Double] = [.nan, 2]
            _ = graph.adjacencyMatrix(weight: { weights[$0] })
        }
        // Without the fault: the same graph with valid weights.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [1, 2]
        #expect(graph.adjacencyMatrix(weight: { weights[$0] }).nonzeroCount == 4)
    }

    @Test("SGT-084 negative weight")
    func sgt084() async throws {
        // U: P(0,1,2) · laplacianSpectrum(weight:) [-1, 1] → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weights: [Int] = [-1, 1]
            _ = try graph.laplacianSpectrum(weight: { weights[$0] })
        }
        // Without the fault: the same graph with valid weights.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 1]
        #expect(try graph.laplacianSpectrum(weight: { weights[$0] }).count == 3)
    }

    @Test("SGT-106 one vertex")
    func sgt106() async throws {
        // U: [0] · algebraicConnectivity() → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = []
            let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = try graph.algebraicConnectivity()
        }
        // Without the fault: the same call on two vertices joined by an edge.
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(abs(try graph.algebraicConnectivity() - 2) <= 1e-6 * 2)
    }

    @Test("SGT-107 empty graph")
    func sgt107() async throws {
        // U: · algebraicConnectivity() → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = []
            let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = try graph.algebraicConnectivity()
        }
        // Without the fault: the same call on two vertices joined by an edge.
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(abs(try graph.algebraicConnectivity() - 2) <= 1e-6 * 2)
    }

    @Test("SGT-126 one vertex")
    func sgt126() async throws {
        // U: [0] · fiedlerVector() → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = []
            let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = try graph.fiedlerVector()
        }
        // Without the fault: the same call on two vertices joined by an edge.
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.fiedlerVector()?.values.count == 2)
    }

    @Test("SGT-183 not a vertex")
    func sgt183() async throws {
        // U: P(0..2) · resistanceDistance(from: 0, to: 9) → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = try graph.resistanceDistance(from: 0, to: 9)
        }
        // Without the fault: the same graph and a vertex.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.resistanceDistance(from: 0, to: 2).map { abs($0 - 2) <= 1e-6 * 2 } == true)
    }

    @Test("SGT-184 negative weight")
    func sgt184() async throws {
        // U: P(0..2) · resistanceDistance(from: 0, to: 2) weight: [1, -1] → **trap**
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weights: [Int] = [1, -1]
            _ = try graph.resistanceDistance(from: 0, to: 2, weight: { weights[$0] })
        }
        // Without the fault: the same graph with valid weights.
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 1]
        #expect(try graph.resistanceDistance(from: 0, to: 2, weight: { weights[$0] }).map { abs($0 - 2) <= 1e-6 * 2 } == true)
    }

    @Test("A negative weight traps every Laplacian-family entry point, Int and Double weights")
    func negativeWeightsEverywhere() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Int] = [1, -1]
            _ = graph.normalizedLaplacianMatrix(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, -0.5]
            _ = graph.randomWalkLaplacianMatrix(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Int] = [-2, 1]
            _ = graph.signlessLaplacianMatrix(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, -1]
            _ = try graph.normalizedLaplacianSpectrum(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Int] = [1, -1]
            _ = try graph.algebraicConnectivity(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, -1]
            _ = try graph.fiedlerVector(weight: { weights[$0] }, normalized: true)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Int] = [1, -1]
            _ = try graph.spectralOrdering(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, -1]
            _ = graph.numberOfSpanningTrees(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Int] = [1, -1]
            _ = graph.effectiveGraphResistance(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, -1]
            _ = graph.kemenyConstant(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let weights: [Int] = [1, -1]
            _ = graph.laplacianMatrix(weight: { weights[$0] })
        }
        // Without the fault: the same calls answer with weights 1 and 2.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weights: [Int] = [1, 2]
        #expect(graph.normalizedLaplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)
        #expect(graph.randomWalkLaplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)
        #expect(graph.signlessLaplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)
        #expect(try graph.normalizedLaplacianSpectrum(weight: { weights[$0] }).count == 3)
        #expect(try graph.algebraicConnectivity(weight: { weights[$0] }) > 0)
        #expect(try graph.fiedlerVector(weight: { weights[$0] }, normalized: true) != nil)
        #expect(try graph.spectralOrdering(weight: { weights[$0] }).count == 3)
        #expect(graph.numberOfSpanningTrees(weight: { weights[$0] }) == 2)
        #expect(graph.effectiveGraphResistance(weight: { weights[$0] }).map { abs($0 - 3) <= 1e-9 * 3 } == true)
        #expect(graph.kemenyConstant(weight: { weights[$0] }) != nil)
        let digraph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(digraph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 4)
    }

    @Test("NaN and infinite weights trap everywhere, the adjacency matrix and spectrum included")
    func nonFiniteWeightsEverywhere() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, .infinity]
            _ = graph.adjacencyMatrix(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [.nan, 1]
            _ = try graph.adjacencySpectrum(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, -.infinity]
            _ = try graph.adjacencySpectrum(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, .nan]
            _ = try graph.spectralRadius(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [1, .infinity]
            _ = try graph.resistanceDistance(from: 0, to: 2, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Float] = [1, .nan]
            _ = try graph.laplacianSpectrum(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let weights: [Double] = [.nan, 1]
            _ = graph.adjacencyMatrix(weight: { weights[$0] })
        }
        // Without the fault: finite weights answer, negative ones included for A.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weights: [Double] = [1, -2]
        #expect(graph.adjacencyMatrix(weight: { weights[$0] }).nonzeroCount == 4)
        #expect(try graph.adjacencySpectrum(weight: { weights[$0] }).count == 3)
        let positive: [Float] = [1, 2]
        #expect(try graph.laplacianSpectrum(weight: { positive[$0] }).count == 3)
        #expect(try graph.resistanceDistance(from: 0, to: 2, weight: { positive[$0] }).map { abs($0 - 1.5) <= 1e-6 * 1.5 } == true)
        #expect(abs(try graph.spectralRadius(weight: { positive[$0] }) - 5.0.squareRoot()) <= 1e-6 * 5.0.squareRoot())
        let digraph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(digraph.adjacencyMatrix(weight: { weights[$0] }).nonzeroCount == 2)
    }

    @Test("A negative weight traps even on an edge outside the component a call reads")
    func negativeWeightOutsideTheComponent() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            let weights: [Double] = [1, -1]
            _ = try graph.resistanceDistance(from: 0, to: 1, weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            let weights: [Double] = [1, -1]
            _ = try graph.algebraicConnectivity(weight: { weights[$0] })
        }
        // Without the fault: R(0, 1) = 1, and λ₂ = 0 (two components).
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let weights: [Double] = [1, 1]
        #expect(try graph.resistanceDistance(from: 0, to: 1, weight: { weights[$0] }).map { abs($0 - 1) <= 1e-6 } == true)
        #expect(try graph.algebraicConnectivity(weight: { weights[$0] }) == 0)
    }

    @Test("Fewer than two vertices trap the Fiedler vector and normalized λ₂, not the ordering")
    func fewerThanTwoVertices() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: [] as [Int], edges: [])
            _ = try graph.fiedlerVector()
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
            _ = try graph.fiedlerVector(normalized: true)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: [0], edges: [])
            _ = try graph.algebraicConnectivity(normalized: true)
        }
        // Without the fault: two vertices answer; one vertex has an ordering.
        let two = ReferencePseudograph(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        #expect(try two.fiedlerVector()?.values.count == 2)
        #expect(abs(try two.algebraicConnectivity(normalized: true) - 2) <= 1e-6 * 2)
        #expect(try ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)]).spectralOrdering() == [0])
    }

    @Test("resistanceDistance traps when the source is not a vertex")
    func resistanceFromNonVertex() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.resistanceDistance(from: 7, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.resistanceDistance(from: 7, to: 7)
        }
        // Without the fault: R(1, 0) = 1.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(try graph.resistanceDistance(from: 1, to: 0).map { abs($0 - 1) <= 1e-6 } == true)
    }

    @Test("FiedlerVector.value(of:) traps on a non-vertex, value(ofIndex:) out of range")
    func fiedlerVectorLookups() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.fiedlerVector()?.value(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.fiedlerVector()?.value(ofIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.fiedlerVector()?.value(ofIndex: -1)
        }
        // Without the fault: P₃'s Fiedler vector is (1, 0, −1)/√2.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let fiedler = try graph.fiedlerVector()
        #expect(fiedler.map { abs($0.value(of: 2) + 0.5.squareRoot()) <= 1e-5 } == true)
        #expect(fiedler.map { abs($0.value(ofIndex: 0) - 0.5.squareRoot()) <= 1e-5 } == true)
    }

    @Test("SparseMatrix traps on an entry outside the matrix and on a vector of the wrong length")
    func sparseMatrixBounds() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.laplacianMatrix()[3, 0]
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.laplacianMatrix()[0, -1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.laplacianMatrix() * [1, 2]
        }
        // Without the fault: the corner entry and L · (1, 2, 3).
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.laplacianMatrix()[2, 0] == 0)
        #expect(graph.laplacianMatrix() * [1, 2, 3] == [-1, 0, 1])
    }
}
