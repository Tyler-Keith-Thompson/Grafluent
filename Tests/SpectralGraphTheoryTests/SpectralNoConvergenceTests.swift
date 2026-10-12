// NoConvergence: every iterative entry point throws it when its iteration limit is spent, with the
// iterations spent and a residual still above the tolerance; `maxIterations` replaces the limit
// that throws. A dense spectrum counts QL/QR iterations in all, Lanczos and conjugate gradients
// count matrix–vector products; below 5,000 vertices each throws with exactly the limit. Below 64
// vertices λ₂ and ρ come from the dense solver, which does not read `maxIterations`. See README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory NoConvergence")
struct SpectralNoConvergenceTests {
    @Test("Dense spectra: maxIterations below what the QL/QR iteration needs throws with exactly that count and an off-diagonal entry left")
    func denseSpectra() throws {
        // A path of 10: no eigenvalue deflates without iterating.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: (0 ..< 9).map { UndirectedEdge($0, $0 + 1) })
        let ints = [Int](repeating: 2, count: 9)
        let doubles = [Double](repeating: 0.5, count: 9)
        for limit in [1, 2, 5] {
            let errors = [
                #expect(throws: NoConvergence.self) { try graph.adjacencySpectrum(maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.adjacencySpectrum(weight: { ints[$0] }, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.adjacencySpectrum(weight: { doubles[$0] }, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.laplacianSpectrum(maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.laplacianSpectrum(weight: { ints[$0] }, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.laplacianSpectrum(weight: { doubles[$0] }, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.normalizedLaplacianSpectrum(maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.normalizedLaplacianSpectrum(weight: { ints[$0] }, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.normalizedLaplacianSpectrum(weight: { doubles[$0] }, maxIterations: limit) },
            ]
            for (k, error) in errors.enumerated() {
                #expect(error?.iterations == limit, "entry \(k), limit \(limit)")
                // The off-diagonal entry still being reduced, relative to its block: above rounding.
                let residual = error?.residual ?? 0
                #expect(residual > Double.ulpOfOne && residual.isFinite, "entry \(k), limit \(limit): \(residual)")
            }
        }
        // A heavier first edge: the tridiagonal's top diagonal entry (3) is larger than its bottom
        // one (1), so the root-free iteration runs QR (deflating from the bottom) rather than QL.
        for limit in [1, 2, 5] {
            let error = #expect(throws: NoConvergence.self) { try graph.laplacianSpectrum(weight: { $0 == 0 ? 3 : 1 }, maxIterations: limit) }
            #expect(error?.iterations == limit, "QR, limit \(limit)")
        }
                // The default limit (30 n) and a generous one give the same spectrum, bit for bit.
        #expect(try graph.laplacianSpectrum(maxIterations: 1_000) == graph.laplacianSpectrum())
        #expect(try graph.adjacencySpectrum(maxIterations: 300) == graph.adjacencySpectrum())
    }

    @Test("The residuals are relative: scaling every weight by 2¹⁰ (exact) leaves each residual and count unchanged, bit for bit")
    func relativeResiduals() {
        // Dense: the off-diagonal entry relative to its block.
        let path = ReferencePseudograph(vertices: Array(0 ..< 10), edges: (0 ..< 9).map { UndirectedEdge($0, $0 + 1) })
        for limit in [1, 3, 6] {
            let unit = #expect(throws: NoConvergence.self) { try path.laplacianSpectrum(maxIterations: limit) }
            let scaled = #expect(throws: NoConvergence.self) { try path.laplacianSpectrum(weight: { _ in 1024 }, maxIterations: limit) }
            #expect(unit != nil && unit == scaled, "limit \(limit): \(String(describing: unit)) against \(String(describing: scaled))")
        }
        // Lanczos by shift-invert: the Ritz residual relative to 1/λ₂, which scales by 2⁻¹⁰.
        let long = ReferencePseudograph(vertices: Array(0 ..< 200), edges: (0 ..< 199).map { UndirectedEdge($0, $0 + 1) })
        for limit in [1, 4] {
            let unit = #expect(throws: NoConvergence.self) { try long.algebraicConnectivity(maxIterations: limit) }
            let scaled = #expect(throws: NoConvergence.self) { try long.algebraicConnectivity(weight: { _ in 1024 }, maxIterations: limit) }
            #expect(unit != nil && unit == scaled, "limit \(limit): \(String(describing: unit)) against \(String(describing: scaled))")
        }
        // Lanczos on A: the Ritz residual relative to ρ.
        let n = 100
        var rng = SeededRandomNumberGenerator(seed: 11)
        let edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) } + (0 ..< n).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
        for limit in [1, 7] {
            let unit = #expect(throws: NoConvergence.self) { try graph.spectralRadius(maxIterations: limit) }
            let scaled = #expect(throws: NoConvergence.self) { try graph.spectralRadius(weight: { _ in 1024 }, maxIterations: limit) }
            #expect(unit != nil && unit == scaled, "limit \(limit): \(String(describing: unit)) against \(String(describing: scaled))")
        }
    }

    @Test("Dense spectra: one vertex and the empty graph need no iteration, so maxIterations: 1 answers")
    func denseWithoutIterations() throws {
        let one = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        #expect(try one.adjacencySpectrum(maxIterations: 1) == [2])
        #expect(try one.laplacianSpectrum(maxIterations: 1) == [0])
        let empty = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(try empty.normalizedLaplacianSpectrum(maxIterations: 1) == [])
    }

    @Test("λ₂ by shift-invert (a path of 200): maxIterations: 1 throws after one product with a Ritz residual above the tolerance")
    func algebraicConnectivityShiftInvert() throws {
        let graph = ReferencePseudograph(vertices: Array(0 ..< 200), edges: (0 ..< 199).map { UndirectedEdge($0, $0 + 1) })
        let ints = [Int](repeating: 3, count: 199)
        let doubles = [Double](repeating: 0.25, count: 199)
        let errors = [
            #expect(throws: NoConvergence.self) { try graph.algebraicConnectivity(maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.algebraicConnectivity(weight: { ints[$0] }, maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.algebraicConnectivity(weight: { doubles[$0] }, normalized: true, maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.fiedlerVector(maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.fiedlerVector(weight: { ints[$0] }, normalized: true, maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.fiedlerVector(weight: { doubles[$0] }, maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.spectralOrdering(maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.spectralOrdering(weight: { ints[$0] }, maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.spectralOrdering(weight: { doubles[$0] }, normalized: true, maxIterations: 1) },
        ]
        for (k, error) in errors.enumerated() {
            #expect(error?.iterations == 1, "entry \(k)")
            #expect((error?.residual ?? 0) > 1e-8, "entry \(k)")
        }
        // The default limits converge: λ₂ = 2 − 2cos(π/200) = 4 sin²(π/400).
        let s = 0.007853900888711334
        #expect(abs(try graph.algebraicConnectivity() - 4 * s * s) <= 1e-8 * 4 * s * s)
        #expect(try graph.algebraicConnectivity(maxIterations: 1_000) == graph.algebraicConnectivity())
    }

    @Test("λ₂ on σI − L (a 10 × 10 grid): a limit given cuts the shifted run short, and shift-invert then throws at the same limit")
    func algebraicConnectivityShifted() throws {
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< 10 {
            for j in 0 ..< 10 {
                if j + 1 < 10 { edges.append(UndirectedEdge(10 * i + j, 10 * i + j + 1)) }
                if i + 1 < 10 { edges.append(UndirectedEdge(10 * i + j, 10 * i + j + 10)) }
            }
        }
        let graph = ReferencePseudograph(vertices: Array(0 ..< 100), edges: edges)
        let error = #expect(throws: NoConvergence.self) { try graph.algebraicConnectivity(maxIterations: 2) }
        #expect(error?.iterations == 2)
        #expect((error?.residual ?? 0) > 1e-8)
        // A limit the shifted run does not reach answers as the default does, bit for bit.
        let lambda2 = try graph.algebraicConnectivity()
        #expect(try graph.algebraicConnectivity(maxIterations: 4_200) == lambda2)
        // 2 − 2cos(π/10).
        #expect(abs(lambda2 - 0.09788696740969294) <= 1e-8)
    }

    @Test("Spectral ordering throws only for a component it iterates on: components of at most two vertices and dense ones (below 64) never read maxIterations")
    func spectralOrderingComponents() throws {
        // A path of 70 (iterative) and an edge: the path throws.
        var edges = (0 ..< 69).map { UndirectedEdge($0, $0 + 1) }
        edges.append(UndirectedEdge(70, 71))
        let graph = ReferencePseudograph(vertices: Array(0 ..< 72), edges: edges)
        let error = #expect(throws: NoConvergence.self) { try graph.spectralOrdering(maxIterations: 1) }
        #expect(error?.iterations == 1 && (error?.residual ?? 0) > 1e-8)
        // A path of 60 and an edge: every component dense or small, so maxIterations: 1 answers.
        var small = (0 ..< 59).map { UndirectedEdge($0, $0 + 1) }
        small.append(UndirectedEdge(60, 61))
        let dense = ReferencePseudograph(vertices: Array(0 ..< 62), edges: small)
        #expect(try dense.spectralOrdering(maxIterations: 1) == dense.spectralOrdering())
        #expect(try dense.algebraicConnectivity(maxIterations: 1) == 0)
        #expect(try dense.fiedlerVector(maxIterations: 1) == nil)
        let k5 = ReferencePseudograph(vertices: Array(0 ..< 5), edges: [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)].map { UndirectedEdge($0.0, $0.1) })
        #expect(abs(try k5.algebraicConnectivity(maxIterations: 1) - 5) <= 1e-12)
    }

    @Test("Spectral radius: maxIterations: 1 throws after one product; below 64 vertices it is unused")
    func spectralRadius() throws {
        // A random graph on 100 vertices: no symmetry closes the Krylov space early.
        let n = 100
        var rng = SeededRandomNumberGenerator(seed: 11)
        let edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) } + (0 ..< n).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
        let ints = edges.indices.map { $0 % 3 + 1 }
        let signed = edges.indices.map { $0 % 2 == 0 ? 1.0 : -1.0 }
        let errors = [
            #expect(throws: NoConvergence.self) { try graph.spectralRadius(maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.spectralRadius(weight: { ints[$0] }, maxIterations: 1) },
            #expect(throws: NoConvergence.self) { try graph.spectralRadius(weight: { signed[$0] }, maxIterations: 1) },
        ]
        for (k, error) in errors.enumerated() {
            #expect(error?.iterations == 1, "entry \(k)")
            #expect((error?.residual ?? 0) > 1e-8, "entry \(k)")
        }
        let radius = try graph.spectralRadius()
        let largest = try graph.adjacencySpectrum().map { abs($0) }.max()!
        #expect(abs(radius - largest) <= 1e-8 * largest)
        #expect(try graph.spectralRadius(maxIterations: 20_000) == radius)
        // Signed weights: two runs, on A and on −A, each within the default limit.
        let signedRadius = try graph.spectralRadius(weight: { signed[$0] })
        let signedLargest = try graph.adjacencySpectrum(weight: { signed[$0] }).map { abs($0) }.max()!
        #expect(abs(signedRadius - signedLargest) <= 1e-6 * signedLargest)
        // Dense below 64 vertices: maxIterations is not read.
        let small = ReferencePseudograph(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(abs(try small.spectralRadius(maxIterations: 1) - 2) <= 1e-12)
    }

    @Test("Resistance distance: maxIterations conjugate-gradient iterations exactly, with the residual relative to the right-hand side")
    func resistanceDistance() throws {
        // A path of 200, one end to the other: R = 199, and Jacobi needs about n iterations.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 200), edges: (0 ..< 199).map { UndirectedEdge($0, $0 + 1) })
        let ints = [Int](repeating: 1, count: 199)
        let doubles = [Double](repeating: 2, count: 199)
        for limit in [1, 2, 10] {
            let errors = [
                #expect(throws: NoConvergence.self) { try graph.resistanceDistance(from: 0, to: 199, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.resistanceDistance(from: 0, to: 199, weight: { ints[$0] }, maxIterations: limit) },
                #expect(throws: NoConvergence.self) { try graph.resistanceDistance(from: 0, to: 199, weight: { doubles[$0] }, maxIterations: limit) },
            ]
            for (k, error) in errors.enumerated() {
                #expect(error?.iterations == limit, "entry \(k), limit \(limit)")
                let residual = error?.residual ?? 0
                #expect(residual > 1e-10 && residual <= 1, "entry \(k), limit \(limit): \(residual)")
            }
        }
        #expect(abs(try #require(try graph.resistanceDistance(from: 0, to: 199)) - 199) <= 1e-6 * 199)
        #expect(abs(try #require(try graph.resistanceDistance(from: 0, to: 199, weight: { doubles[$0] }, maxIterations: 20_400)) - 99.5) <= 1e-6 * 99.5)
        // No iteration: the same vertex, and vertices in different components.
        #expect(try graph.resistanceDistance(from: 5, to: 5, maxIterations: 1) == 0)
        let two = ReferencePseudograph(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(try two.resistanceDistance(from: 0, to: 3, maxIterations: 1) == nil)
    }

    @Test("NoConvergence is a value: equal for equal fields, hashable, and described by its fields")
    func errorValue() {
        let error = NoConvergence(iterations: 3, residual: 0.5)
        #expect(error == NoConvergence(iterations: 3, residual: 0.5))
        #expect(error != NoConvergence(iterations: 4, residual: 0.5))
        #expect(error != NoConvergence(iterations: 3, residual: 0.25))
        #expect(Set([error, NoConvergence(iterations: 3, residual: 0.5)]).count == 1)
        #expect(error.description == "NoConvergence(iterations: 3, residual: 0.5)")
        var copy = error
        copy.iterations = 7
        copy.residual = .infinity
        #expect(copy.iterations == 7 && copy.residual == .infinity)
    }

    @Test("maxIterations below 1 traps on every entry point that takes it", .tags(.precondition))
    func maxIterationsPrecondition() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.laplacianSpectrum(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.adjacencySpectrum(weight: { _ in 1.0 }, maxIterations: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.normalizedLaplacianSpectrum(weight: { _ in 1 }, maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.algebraicConnectivity(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.fiedlerVector(weight: { _ in 2 }, maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.spectralOrdering(weight: { _ in 2.0 }, maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.spectralRadius(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.resistanceDistance(from: 0, to: 2, maxIterations: 0)
        }
        // Without the fault: the same graph with a valid limit.
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(try graph.algebraicConnectivity(maxIterations: 1) > 0)
        #expect(try graph.spectralRadius(maxIterations: 1) > 0)
        #expect(try graph.resistanceDistance(from: 0, to: 2, maxIterations: 100) != nil)
    }
}
