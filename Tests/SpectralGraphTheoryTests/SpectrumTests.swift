// Spectra (catalog SGT-047 – SGT-083): every eigenvalue of A, L and N, ascending, multiplicities
// repeated, on the named families, multigraphs, loops and weights.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory spectra")
struct SpectrumTests {
    @Test("SGT-047 empty graph")
    func sgt047() throws {
        // U: · laplacianSpectrum() → []
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = []
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-048 one vertex")
    func sgt048() throws {
        // U: [0] · laplacianSpectrum() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [0]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-049 three isolated vertices")
    func sgt049() throws {
        // U: E(3) · laplacianSpectrum() → 0 ×3
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [0, 0, 0]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-050 K2")
    func sgt050() throws {
        // U: K(2) · laplacianSpectrum() → 0, 2
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [0, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-051 K5")
    func sgt051() throws {
        // U: K(5) · laplacianSpectrum() → 0, 5 ×4
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [1e-16, 5, 5, 5, 5]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 5
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-052 path P5")
    func sgt052() throws {
        // U: P(0..4) · laplacianSpectrum() → 0, 0.3819660113, 1.381966011, 2.618033989, 3.618033989
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [9e-17, 0.3819660112501, 1.3819660112501, 2.6180339887499, 3.6180339887499]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 3.6180339887499
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-053 cycle C6")
    func sgt053() throws {
        // U: C(0..5) · laplacianSpectrum() → 0, 1 ×2, 3 ×2, 4
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [-7e-16, 1, 1, 3, 3, 4]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 4
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-054 star K1,4")
    func sgt054() throws {
        // U: S(0;1..4) · laplacianSpectrum() → 0, 1 ×3, 5
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [0, 1, 1, 1, 5]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 5
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-055 hypercube Q3")
    func sgt055() throws {
        // U: Q(3) · laplacianSpectrum() → 0, 2 ×3, 4 ×3, 6
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [-2e-16, 2, 2, 2, 4, 4, 4, 6]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 6
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-056 K5")
    func sgt056() throws {
        // U: K(5) · adjacencySpectrum() → -1 ×4, 4
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-1, -1, -1, -1, 4]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 4
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-057 path P5")
    func sgt057() throws {
        // U: P(0..4) · adjacencySpectrum() → -1.732050808, -1, 0, 1, 1.732050808
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-1.73205080756888, -1, -3e-17, 1, 1.73205080756888]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1.73205080756888
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-058 cycle C6")
    func sgt058() throws {
        // U: C(0..5) · adjacencySpectrum() → -2, -1 ×2, 1 ×2, 2
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-2, -1, -1, 1, 1, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-059 star K1,4")
    func sgt059() throws {
        // U: S(0;1..4) · adjacencySpectrum() → -2, 0 ×3, 2
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-2, 0, 0, 0, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-060 hypercube Q3")
    func sgt060() throws {
        // U: Q(3) · adjacencySpectrum() → -3, -1 ×3, 1 ×3, 3
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-3, -1, -1, -1, 1, 1, 1, 3]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 3
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-061 K5")
    func sgt061() throws {
        // U: K(5) · normalizedLaplacianSpectrum() → 0, 1.25 ×4
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [3e-17, 1.25, 1.25, 1.25, 1.25]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1.25
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-062 path P5")
    func sgt062() throws {
        // U: P(0..4) · normalizedLaplacianSpectrum() → 0, 0.2928932188, 1, 1.707106781, 2
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [-2e-16, 0.29289321881345, 1, 1.70710678118655, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-063 cycle C6")
    func sgt063() throws {
        // U: C(0..5) · normalizedLaplacianSpectrum() → 0, 0.5 ×2, 1.5 ×2, 2
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [-1e-16, 0.5, 0.5, 1.5, 1.5, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-064 star K1,4")
    func sgt064() throws {
        // U: S(0;1..4) · normalizedLaplacianSpectrum() → 0, 1 ×3, 2
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [0, 1, 1, 1, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-065 hypercube Q3")
    func sgt065() throws {
        // U: Q(3) · normalizedLaplacianSpectrum() → 0, 0.6666666667 ×3, 1.333333333 ×3, 2
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [3e-16, 0.66666666666667, 0.66666666666667, 0.66666666666667, 1.33333333333333, 1.33333333333333, 1.33333333333333, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-066 K2,3 Laplacian")
    func sgt066() throws {
        // U: KB(0..1;2..4) · laplacianSpectrum() → 0, 2 ×2, 3, 5
        let edges: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = ReferencePseudograph(vertices: [0, 2, 3, 4, 1], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [2e-16, 2, 2, 3, 5]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 5
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-067 K2,3 adjacency")
    func sgt067() throws {
        // U: KB(0..1;2..4) · adjacencySpectrum() → -2.449489743, 0 ×3, 2.449489743
        let edges: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = ReferencePseudograph(vertices: [0, 2, 3, 4, 1], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-2.4494897427832, 0, 2e-16, 3e-16, 2.4494897427832]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2.4494897427832
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-068 Petersen Laplacian")
    func sgt068() throws {
        // U: nx(petersen) · laplacianSpectrum() → 0, 2 ×5, 5 ×4
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [
            2e-16, 2, 2, 2, 2, 2, 5, 5,
            5, 5,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 5
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-069 Petersen adjacency")
    func sgt069() throws {
        // U: nx(petersen) · adjacencySpectrum() → -2 ×4, 1 ×5, 3
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [
            -2, -2, -2, -2, 1, 1, 1, 1,
            1, 3,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 3
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-070 grid 3×4 Laplacian")
    func sgt070() throws {
        // U: grid(3,4) · laplacianSpectrum() → 0, 0.5857864376, 1, 1.585786438, 2, 3 ×2, 3.414213562, 3.585786438, 4.414213562, 5, 6.414213562
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7),
            (6, 10), (7, 11), (8, 9), (9, 10), (10, 11),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 12), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [
            -9e-16, 0.5857864376269, 1, 1.5857864376269, 2, 3, 3, 3.4142135623731,
            3.5857864376269, 4.4142135623731, 5, 6.4142135623731,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 6.4142135623731
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-071 two triangles: 0 twice")
    func sgt071() throws {
        // U: C(0,1,2), C(3,4,5) · laplacianSpectrum() → 0 ×2, 3 ×4
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [-1e-16, -1e-16, 3, 3, 3, 3]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 3
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-072 path and isolated vertex, normalized: 0 per component")
    func sgt072() throws {
        // U: [0,1,2,3] P(0,1,2) · normalizedLaplacianSpectrum() → 0 ×2, 1, 2
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [0, 2e-16, 1, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-073 doubled edge")
    func sgt073() throws {
        // U: 0=1 · laplacianSpectrum() → 0, 4
        let edges: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [0, 4]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 4
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-074 self-loop: adjacency 1 ± √2")
    func sgt074() throws {
        // U: 0-0, 0-1 · adjacencySpectrum() → -0.4142135624, 2.414213562
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [-0.4142135623731, 2.4142135623731]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2.4142135623731
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-075 self-loop: Laplacian unchanged")
    func sgt075() throws {
        // U: 0-0, 0-1 · laplacianSpectrum() → 0, 2
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [0, 2]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 2
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-076 self-loop: normalized")
    func sgt076() throws {
        // U: 0-0, 0-1 · normalizedLaplacianSpectrum() → 0, 1.333333333
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [-2e-17, 1.33333333333333]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1.33333333333333
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-077 weighted triangle")
    func sgt077() throws {
        // U: C(0,1,2) · laplacianSpectrum(weight:) [1, 2, 3] → 0, 4.267949192, 7.732050808
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let spectrum = try graph.laplacianSpectrum(weight: { weights[$0] })
        let expected: [Double] = [4e-16, 4.2679491924311, 7.7320508075689]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 7.7320508075689
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-078 weighted triangle, normalized")
    func sgt078() throws {
        // U: C(0,1,2) · normalizedLaplacianSpectrum(weight:) [1, 2, 3] → 0, 1.276393202, 1.723606798
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let spectrum = try graph.normalizedLaplacianSpectrum(weight: { weights[$0] })
        let expected: [Double] = [1e-16, 1.27639320225002, 1.72360679774998]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1.72360679774998
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-079 grid 20×20 Laplacian (summary)")
    func sgt079() throws {
        // U: grid(20,20) · laplacianSpectrum() → 400 values; smallest 0, 0.02462331881, 0.02462331881, 0.04924663762; largest 7.877489714, 7.950753362; Σ 1520; Σ² 7368
        let edges: [(Int, Int)] = [
            (0, 1), (0, 20), (1, 2), (1, 21), (2, 3), (2, 22), (3, 4), (3, 23), (4, 5), (4, 24), (5, 6), (5, 25),
            (6, 7), (6, 26), (7, 8), (7, 27), (8, 9), (8, 28), (9, 10), (9, 29), (10, 11), (10, 30), (11, 12), (11, 31),
            (12, 13), (12, 32), (13, 14), (13, 33), (14, 15), (14, 34), (15, 16), (15, 35), (16, 17), (16, 36), (17, 18), (17, 37),
            (18, 19), (18, 38), (19, 39), (20, 21), (20, 40), (21, 22), (21, 41), (22, 23), (22, 42), (23, 24), (23, 43), (24, 25),
            (24, 44), (25, 26), (25, 45), (26, 27), (26, 46), (27, 28), (27, 47), (28, 29), (28, 48), (29, 30), (29, 49), (30, 31),
            (30, 50), (31, 32), (31, 51), (32, 33), (32, 52), (33, 34), (33, 53), (34, 35), (34, 54), (35, 36), (35, 55), (36, 37),
            (36, 56), (37, 38), (37, 57), (38, 39), (38, 58), (39, 59), (40, 41), (40, 60), (41, 42), (41, 61), (42, 43), (42, 62),
            (43, 44), (43, 63), (44, 45), (44, 64), (45, 46), (45, 65), (46, 47), (46, 66), (47, 48), (47, 67), (48, 49), (48, 68),
            (49, 50), (49, 69), (50, 51), (50, 70), (51, 52), (51, 71), (52, 53), (52, 72), (53, 54), (53, 73), (54, 55), (54, 74),
            (55, 56), (55, 75), (56, 57), (56, 76), (57, 58), (57, 77), (58, 59), (58, 78), (59, 79), (60, 61), (60, 80), (61, 62),
            (61, 81), (62, 63), (62, 82), (63, 64), (63, 83), (64, 65), (64, 84), (65, 66), (65, 85), (66, 67), (66, 86), (67, 68),
            (67, 87), (68, 69), (68, 88), (69, 70), (69, 89), (70, 71), (70, 90), (71, 72), (71, 91), (72, 73), (72, 92), (73, 74),
            (73, 93), (74, 75), (74, 94), (75, 76), (75, 95), (76, 77), (76, 96), (77, 78), (77, 97), (78, 79), (78, 98), (79, 99),
            (80, 81), (80, 100), (81, 82), (81, 101), (82, 83), (82, 102), (83, 84), (83, 103), (84, 85), (84, 104), (85, 86), (85, 105),
            (86, 87), (86, 106), (87, 88), (87, 107), (88, 89), (88, 108), (89, 90), (89, 109), (90, 91), (90, 110), (91, 92), (91, 111),
            (92, 93), (92, 112), (93, 94), (93, 113), (94, 95), (94, 114), (95, 96), (95, 115), (96, 97), (96, 116), (97, 98), (97, 117),
            (98, 99), (98, 118), (99, 119), (100, 101), (100, 120), (101, 102), (101, 121), (102, 103), (102, 122), (103, 104), (103, 123), (104, 105),
            (104, 124), (105, 106), (105, 125), (106, 107), (106, 126), (107, 108), (107, 127), (108, 109), (108, 128), (109, 110), (109, 129), (110, 111),
            (110, 130), (111, 112), (111, 131), (112, 113), (112, 132), (113, 114), (113, 133), (114, 115), (114, 134), (115, 116), (115, 135), (116, 117),
            (116, 136), (117, 118), (117, 137), (118, 119), (118, 138), (119, 139), (120, 121), (120, 140), (121, 122), (121, 141), (122, 123), (122, 142),
            (123, 124), (123, 143), (124, 125), (124, 144), (125, 126), (125, 145), (126, 127), (126, 146), (127, 128), (127, 147), (128, 129), (128, 148),
            (129, 130), (129, 149), (130, 131), (130, 150), (131, 132), (131, 151), (132, 133), (132, 152), (133, 134), (133, 153), (134, 135), (134, 154),
            (135, 136), (135, 155), (136, 137), (136, 156), (137, 138), (137, 157), (138, 139), (138, 158), (139, 159), (140, 141), (140, 160), (141, 142),
            (141, 161), (142, 143), (142, 162), (143, 144), (143, 163), (144, 145), (144, 164), (145, 146), (145, 165), (146, 147), (146, 166), (147, 148),
            (147, 167), (148, 149), (148, 168), (149, 150), (149, 169), (150, 151), (150, 170), (151, 152), (151, 171), (152, 153), (152, 172), (153, 154),
            (153, 173), (154, 155), (154, 174), (155, 156), (155, 175), (156, 157), (156, 176), (157, 158), (157, 177), (158, 159), (158, 178), (159, 179),
            (160, 161), (160, 180), (161, 162), (161, 181), (162, 163), (162, 182), (163, 164), (163, 183), (164, 165), (164, 184), (165, 166), (165, 185),
            (166, 167), (166, 186), (167, 168), (167, 187), (168, 169), (168, 188), (169, 170), (169, 189), (170, 171), (170, 190), (171, 172), (171, 191),
            (172, 173), (172, 192), (173, 174), (173, 193), (174, 175), (174, 194), (175, 176), (175, 195), (176, 177), (176, 196), (177, 178), (177, 197),
            (178, 179), (178, 198), (179, 199), (180, 181), (180, 200), (181, 182), (181, 201), (182, 183), (182, 202), (183, 184), (183, 203), (184, 185),
            (184, 204), (185, 186), (185, 205), (186, 187), (186, 206), (187, 188), (187, 207), (188, 189), (188, 208), (189, 190), (189, 209), (190, 191),
            (190, 210), (191, 192), (191, 211), (192, 193), (192, 212), (193, 194), (193, 213), (194, 195), (194, 214), (195, 196), (195, 215), (196, 197),
            (196, 216), (197, 198), (197, 217), (198, 199), (198, 218), (199, 219), (200, 201), (200, 220), (201, 202), (201, 221), (202, 203), (202, 222),
            (203, 204), (203, 223), (204, 205), (204, 224), (205, 206), (205, 225), (206, 207), (206, 226), (207, 208), (207, 227), (208, 209), (208, 228),
            (209, 210), (209, 229), (210, 211), (210, 230), (211, 212), (211, 231), (212, 213), (212, 232), (213, 214), (213, 233), (214, 215), (214, 234),
            (215, 216), (215, 235), (216, 217), (216, 236), (217, 218), (217, 237), (218, 219), (218, 238), (219, 239), (220, 221), (220, 240), (221, 222),
            (221, 241), (222, 223), (222, 242), (223, 224), (223, 243), (224, 225), (224, 244), (225, 226), (225, 245), (226, 227), (226, 246), (227, 228),
            (227, 247), (228, 229), (228, 248), (229, 230), (229, 249), (230, 231), (230, 250), (231, 232), (231, 251), (232, 233), (232, 252), (233, 234),
            (233, 253), (234, 235), (234, 254), (235, 236), (235, 255), (236, 237), (236, 256), (237, 238), (237, 257), (238, 239), (238, 258), (239, 259),
            (240, 241), (240, 260), (241, 242), (241, 261), (242, 243), (242, 262), (243, 244), (243, 263), (244, 245), (244, 264), (245, 246), (245, 265),
            (246, 247), (246, 266), (247, 248), (247, 267), (248, 249), (248, 268), (249, 250), (249, 269), (250, 251), (250, 270), (251, 252), (251, 271),
            (252, 253), (252, 272), (253, 254), (253, 273), (254, 255), (254, 274), (255, 256), (255, 275), (256, 257), (256, 276), (257, 258), (257, 277),
            (258, 259), (258, 278), (259, 279), (260, 261), (260, 280), (261, 262), (261, 281), (262, 263), (262, 282), (263, 264), (263, 283), (264, 265),
            (264, 284), (265, 266), (265, 285), (266, 267), (266, 286), (267, 268), (267, 287), (268, 269), (268, 288), (269, 270), (269, 289), (270, 271),
            (270, 290), (271, 272), (271, 291), (272, 273), (272, 292), (273, 274), (273, 293), (274, 275), (274, 294), (275, 276), (275, 295), (276, 277),
            (276, 296), (277, 278), (277, 297), (278, 279), (278, 298), (279, 299), (280, 281), (280, 300), (281, 282), (281, 301), (282, 283), (282, 302),
            (283, 284), (283, 303), (284, 285), (284, 304), (285, 286), (285, 305), (286, 287), (286, 306), (287, 288), (287, 307), (288, 289), (288, 308),
            (289, 290), (289, 309), (290, 291), (290, 310), (291, 292), (291, 311), (292, 293), (292, 312), (293, 294), (293, 313), (294, 295), (294, 314),
            (295, 296), (295, 315), (296, 297), (296, 316), (297, 298), (297, 317), (298, 299), (298, 318), (299, 319), (300, 301), (300, 320), (301, 302),
            (301, 321), (302, 303), (302, 322), (303, 304), (303, 323), (304, 305), (304, 324), (305, 306), (305, 325), (306, 307), (306, 326), (307, 308),
            (307, 327), (308, 309), (308, 328), (309, 310), (309, 329), (310, 311), (310, 330), (311, 312), (311, 331), (312, 313), (312, 332), (313, 314),
            (313, 333), (314, 315), (314, 334), (315, 316), (315, 335), (316, 317), (316, 336), (317, 318), (317, 337), (318, 319), (318, 338), (319, 339),
            (320, 321), (320, 340), (321, 322), (321, 341), (322, 323), (322, 342), (323, 324), (323, 343), (324, 325), (324, 344), (325, 326), (325, 345),
            (326, 327), (326, 346), (327, 328), (327, 347), (328, 329), (328, 348), (329, 330), (329, 349), (330, 331), (330, 350), (331, 332), (331, 351),
            (332, 333), (332, 352), (333, 334), (333, 353), (334, 335), (334, 354), (335, 336), (335, 355), (336, 337), (336, 356), (337, 338), (337, 357),
            (338, 339), (338, 358), (339, 359), (340, 341), (340, 360), (341, 342), (341, 361), (342, 343), (342, 362), (343, 344), (343, 363), (344, 345),
            (344, 364), (345, 346), (345, 365), (346, 347), (346, 366), (347, 348), (347, 367), (348, 349), (348, 368), (349, 350), (349, 369), (350, 351),
            (350, 370), (351, 352), (351, 371), (352, 353), (352, 372), (353, 354), (353, 373), (354, 355), (354, 374), (355, 356), (355, 375), (356, 357),
            (356, 376), (357, 358), (357, 377), (358, 359), (358, 378), (359, 379), (360, 361), (360, 380), (361, 362), (361, 381), (362, 363), (362, 382),
            (363, 364), (363, 383), (364, 365), (364, 384), (365, 366), (365, 385), (366, 367), (366, 386), (367, 368), (367, 387), (368, 369), (368, 388),
            (369, 370), (369, 389), (370, 371), (370, 390), (371, 372), (371, 391), (372, 373), (372, 392), (373, 374), (373, 393), (374, 375), (374, 394),
            (375, 376), (375, 395), (376, 377), (376, 396), (377, 378), (377, 397), (378, 379), (378, 398), (379, 399), (380, 381), (381, 382), (382, 383),
            (383, 384), (384, 385), (385, 386), (386, 387), (387, 388), (388, 389), (389, 390), (390, 391), (391, 392), (392, 393), (393, 394), (394, 395),
            (395, 396), (396, 397), (397, 398), (398, 399),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 400), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [
            4e-15, 0.02462331880972, 0.02462331880973, 0.04924663761945, 0.09788696740969, 0.0978869674097, 0.12251028621941, 0.12251028621942,
            0.1957739348194, 0.21798695162325, 0.21798695162326, 0.24261027043298, 0.242610270433, 0.31587391903296, 0.31587391903296, 0.3819660112501,
            0.3819660112501, 0.40658933005983, 0.40658933005983, 0.43597390324653, 0.4798529786598, 0.4798529786598, 0.5857864376269, 0.5857864376269,
            0.59995296287337, 0.59995296287337, 0.61040975643663, 0.61040975643663, 0.6836734050366, 0.6836734050366, 0.7639320225002, 0.80377338925017,
            0.80377338925017, 0.82442949541505, 0.82442949541505, 0.84905281422478, 0.84905281422478, 0.92231646282475, 0.92231646282475, 0.967752448877,
            0.967752448877, 1.04241644703832, 1.04241644703832, 1.0920190005209, 1.0920190005209, 1.11664231933063, 1.11664231933063, 1.1715728752538,
            1.1899059679306, 1.1899059679306, 1.20639550666516, 1.20639550666516, 1.31000595214417, 1.31000595214417, 1.3819660112501, 1.3819660112501,
            1.40658933005983, 1.40658933005983, 1.41021593304196, 1.41021593304196, 1.473985011771, 1.473985011771, 1.4798529786598, 1.4798529786598,
            1.59995296287337, 1.59995296287337, 1.6488589908301, 1.6778054381478, 1.6778054381478, 1.68713106991954, 1.68713106991954, 1.71175438872926,
            1.71175438872926, 1.7639320225002, 1.7639320225002, 1.78501803732923, 1.78501803732923, 1.9051180215428, 1.9051180215428, 1.91644849593596,
            1.91644849593596, 1.967752448877, 1.967752448877, 2, 2, 2.02462331880972, 2.02462331880973, 2.06909708116964,
            2.06909708116964, 2.0978869674097, 2.0978869674097, 2.1840380010418, 2.20639550666516, 2.20639550666516, 2.21798695162326, 2.21798695162326,
            2.27291750754644, 2.27291750754644, 2.31286893008046, 2.31286893008046, 2.3374922488902, 2.3374922488902, 2.3819660112501, 2.3819660112501,
            2.41075589749015, 2.41075589749015, 2.473985011771, 2.473985011771, 2.5115605653346, 2.5115605653346, 2.53085588170373, 2.53085588170373,
            2.5857864376269, 2.5857864376269, 2.6180339887499, 2.6180339887499, 2.6426573075596, 2.6426573075596, 2.69483494133057, 2.69483494133057,
            2.7159209561596, 2.7159209561596, 2.7639320225002, 2.77915007044044, 2.77915007044045, 2.82442949541505, 2.82442949541505, 2.83602094037316,
            2.83602094037316, 2.89865536770736, 2.89865536770737, 2.9079809994791, 2.9079809994791, 2.9326043182888, 2.9326043182888, 3,
            3, 3.0058679668888, 3.0058679668888, 3.06909708116964, 3.06909708116964, 3.0920190005209, 3.0920190005209, 3.12596795110236,
            3.12596795110236, 3.1372984254955, 3.1372984254955, 3.17557050458494, 3.17557050458495, 3.2001938233947, 3.2001938233947, 3.2038204263768,
            3.2038204263768, 3.27345747199464, 3.27345747199464, 3.2899470107292, 3.2899470107292, 3.3742621398391, 3.3819660112501, 3.3819660112501,
            3.3935574562082, 3.3935574562082, 3.4048879306014, 3.4048879306014, 3.4142135623731, 3.4142135623731, 3.4388368811828, 3.4388368811828,
            3.44246348416495, 3.44246348416495, 3.493767437106, 3.493767437106, 3.5121005297828, 3.5121005297828, 3.55753651583505, 3.55753651583505,
            3.6180339887499, 3.6180339887499, 3.63220051399636, 3.63220051399636, 3.6426573075596, 3.6426573075596, 3.6871310699195, 3.68713106991954,
            3.6948349413306, 3.6948349413306, 3.7100529892708, 3.7100529892708, 3.7159209561596, 3.7159209561596, 3.73241049489415, 3.73241049489415,
            3.76135694221185, 3.76135694221185, 3.7820130483767, 3.7820130483767, 3.7961795736232, 3.7961795736232, 3.80663636718646, 3.80663636718646,
            3.83602094037316, 3.83602094037316, 3.8799000157864, 3.8799000157864, 3.9021130325903, 3.9021130325903, 3.9267363514, 3.9267363514,
            3.9753766811903, 3.9753766811903, 4, 4, 4, 4, 4, 4,
            4, 4, 4, 4, 4, 4, 4, 4,
            4, 4, 4, 4, 4, 4.0732636486, 4.0732636486, 4.1200999842136,
            4.1200999842136, 4.1639790596268, 4.16397905962684, 4.1933636328135, 4.19336363281354, 4.2038204263768, 4.2038204263768, 4.23864305778815,
            4.23864305778815, 4.26758950510585, 4.26758950510585, 4.2840790438404, 4.2840790438404, 4.2899470107292, 4.2899470107292, 4.3051650586694,
            4.3051650586694, 4.3128689300805, 4.3128689300805, 4.3573426924404, 4.3573426924404, 4.3677994860036, 4.3677994860036, 4.44246348416495,
            4.44246348416495, 4.4878994702172, 4.4878994702172, 4.506232562894, 4.506232562894, 4.55753651583505, 4.5575365158351, 4.5611631188172,
            4.5611631188172, 4.5951120693986, 4.5951120693986, 4.6064425437918, 4.6064425437918, 4.6180339887499, 4.6180339887499, 4.6257378601609,
            4.7100529892708, 4.7100529892708, 4.7265425280054, 4.7265425280054, 4.7961795736232, 4.7961795736232, 4.7998061766053, 4.7998061766053,
            4.8627015745045, 4.8627015745045, 4.8740320488976, 4.8740320488976, 4.9079809994791, 4.9079809994791, 4.9309029188304, 4.9309029188304,
            4.9941320331112, 4.9941320331112, 5, 5, 5.0673956817112, 5.0673956817112, 5.1013446322926, 5.1013446322926,
            5.1639790596268, 5.1639790596268, 5.1755705045849, 5.175570504585, 5.2208499295595, 5.2208499295596, 5.2360679774998, 5.2840790438404,
            5.2840790438404, 5.3051650586694, 5.3051650586694, 5.3573426924404, 5.3573426924404, 5.4142135623731, 5.4142135623731, 5.4691441182963,
            5.4691441182963, 5.4884394346654, 5.4884394346654, 5.526014988229, 5.526014988229, 5.5892441025098, 5.5892441025098, 5.6180339887499,
            5.6180339887499, 5.6625077511098, 5.6625077511098, 5.7270824924536, 5.7270824924536, 5.7820130483767, 5.7820130483767, 5.7936044933348,
            5.7936044933348, 5.8159619989582, 5.9021130325903, 5.9021130325903, 5.9309029188304, 5.9309029188304, 5.9753766811903, 5.9753766811903,
            6.032247551123, 6.032247551123, 6.083551504064, 6.083551504064, 6.0948819784572, 6.0948819784572, 6.2149819626708, 6.2149819626708,
            6.2360679774998, 6.2360679774998, 6.2882456112707, 6.2882456112707, 6.3221945618522, 6.3221945618522, 6.3511410091699, 6.4000470371266,
            6.4000470371266, 6.5201470213402, 6.5201470213402, 6.526014988229, 6.526014988229, 6.589784066958, 6.589784066958, 6.5934106699402,
            6.5934106699402, 6.6899940478558, 6.6899940478558, 6.7936044933348, 6.7936044933348, 6.8100940320694, 6.8100940320694, 6.8284271247462,
            6.8833576806694, 6.8833576806694, 6.9575835529617, 6.9575835529617, 7.032247551123, 7.032247551123, 7.0776835371752, 7.0776835371753,
            7.1509471857752, 7.1509471857752, 7.1962266107498, 7.1962266107498, 7.2360679774998, 7.3163265949634, 7.3163265949634, 7.3895902435634,
            7.3895902435634, 7.4000470371266, 7.4000470371266, 7.5201470213402, 7.5201470213402, 7.5640260967535, 7.5934106699402, 7.5934106699402,
            7.684126080967, 7.684126080967, 7.757389729567, 7.757389729567, 7.8042260651806, 7.8774897137806, 7.8774897137806, 7.9507533623805,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 7.9507533623805
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-080 hypercube Q6 Laplacian (summary)")
    func sgt080() throws {
        // U: Q(6) · laplacianSpectrum() → 64 values; smallest 0, 2, 2, 2; largest 10, 12; Σ 384; Σ² 2688
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 4), (0, 8), (0, 16), (0, 32), (1, 3), (1, 5), (1, 9), (1, 17), (1, 33), (2, 3),
            (2, 6), (2, 10), (2, 18), (2, 34), (3, 7), (3, 11), (3, 19), (3, 35), (4, 5), (4, 6), (4, 12), (4, 20),
            (4, 36), (5, 7), (5, 13), (5, 21), (5, 37), (6, 7), (6, 14), (6, 22), (6, 38), (7, 15), (7, 23), (7, 39),
            (8, 9), (8, 10), (8, 12), (8, 24), (8, 40), (9, 11), (9, 13), (9, 25), (9, 41), (10, 11), (10, 14), (10, 26),
            (10, 42), (11, 15), (11, 27), (11, 43), (12, 13), (12, 14), (12, 28), (12, 44), (13, 15), (13, 29), (13, 45), (14, 15),
            (14, 30), (14, 46), (15, 31), (15, 47), (16, 17), (16, 18), (16, 20), (16, 24), (16, 48), (17, 19), (17, 21), (17, 25),
            (17, 49), (18, 19), (18, 22), (18, 26), (18, 50), (19, 23), (19, 27), (19, 51), (20, 21), (20, 22), (20, 28), (20, 52),
            (21, 23), (21, 29), (21, 53), (22, 23), (22, 30), (22, 54), (23, 31), (23, 55), (24, 25), (24, 26), (24, 28), (24, 56),
            (25, 27), (25, 29), (25, 57), (26, 27), (26, 30), (26, 58), (27, 31), (27, 59), (28, 29), (28, 30), (28, 60), (29, 31),
            (29, 61), (30, 31), (30, 62), (31, 63), (32, 33), (32, 34), (32, 36), (32, 40), (32, 48), (33, 35), (33, 37), (33, 41),
            (33, 49), (34, 35), (34, 38), (34, 42), (34, 50), (35, 39), (35, 43), (35, 51), (36, 37), (36, 38), (36, 44), (36, 52),
            (37, 39), (37, 45), (37, 53), (38, 39), (38, 46), (38, 54), (39, 47), (39, 55), (40, 41), (40, 42), (40, 44), (40, 56),
            (41, 43), (41, 45), (41, 57), (42, 43), (42, 46), (42, 58), (43, 47), (43, 59), (44, 45), (44, 46), (44, 60), (45, 47),
            (45, 61), (46, 47), (46, 62), (47, 63), (48, 49), (48, 50), (48, 52), (48, 56), (49, 51), (49, 53), (49, 57), (50, 51),
            (50, 54), (50, 58), (51, 55), (51, 59), (52, 53), (52, 54), (52, 60), (53, 55), (53, 61), (54, 55), (54, 62), (55, 63),
            (56, 57), (56, 58), (56, 60), (57, 59), (57, 61), (58, 59), (58, 62), (59, 63), (60, 61), (60, 62), (61, 63), (62, 63),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 64), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [
            9e-16, 2, 2, 2, 2, 2, 2, 4,
            4, 4, 4, 4, 4, 4, 4, 4,
            4, 4, 4, 4, 4, 4, 6, 6,
            6, 6, 6, 6, 6, 6, 6, 6,
            6, 6, 6, 6, 6, 6, 6, 6,
            6, 6, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8,
            8, 10, 10, 10, 10, 10, 10, 12,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 12
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-081 karate club Laplacian (summary)")
    func sgt081() throws {
        // U: nx(karate_club) · laplacianSpectrum() → 34 values; smallest 0, 0.4685252267, 0.9092476638, 1.125010718; largest 17.05517119, 18.13669597; Σ 156; Σ² 1368
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13),
            (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30),
            (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6),
            (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33),
            (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29),
            (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32),
            (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 34), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.laplacianSpectrum()
        let expected: [Double] = [
            -3e-15, 0.4685252267014, 0.90924766380331, 1.12501071824467, 1.2594041101217, 1.59928307542958, 1.76189862114404, 1.82605520982546,
            1.95505044733737, 2, 2, 2, 2, 2, 2.4870917344645, 2.74915717527666,
            3.0139629662516, 3.24206747742174, 3.3761540928711, 3.3819660112501, 3.47218739972644, 4.2758768201418, 4.48000767103, 4.5807926680295,
            5.3785950776694, 5.6180339887499, 6.3315922236696, 6.5155446280316, 6.9961970331071, 9.7772409528015, 10.9210675301336, 13.3061223127668,
            17.055171190995, 18.1366959730044,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 18.1366959730044
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-082 karate club adjacency (summary)")
    func sgt082() throws {
        // U: nx(karate_club) · adjacencySpectrum() → 34 values; smallest -4.487229194, -3.447934858, -3.110690917, -2.437424427; largest 4.977074233, 6.725697728; Σ 0; Σ² 156
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13),
            (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30),
            (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6),
            (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33),
            (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29),
            (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32),
            (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 34), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.adjacencySpectrum()
        let expected: [Double] = [
            -4.4872291941623, -3.4479348579588, -3.1106909166517, -2.43742442656863, -2.09082295477648, -2, -1.6876894475452, -1.44407373518236,
            -1.19242424583723, -1.04208785499145, -0.79240681501887, -0.4188187483321, -2e-15, -2e-15, -1e-15, -9e-16,
            -5e-16, 1e-16, 6e-16, 9e-16, 1e-15, 2e-15, 0.29941068523014, 0.41972947374533,
            0.61584058898997, 0.834304102161, 1.03145042460775, 1.08328639033577, 1.45305566280225, 1.48615953687838, 2.30908766643383, 2.91650670492065,
            4.9770742332883, 6.7256977276317,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 6.7256977276317
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }

    @Test("SGT-083 random multigraph lcg(60,150,3) normalized (summary)")
    func sgt083() throws {
        // U: lcg(60,150,3) · normalizedLaplacianSpectrum() → 60 values; smallest 0, 0.2002576706, 0.2351635713, 0.2403154366; largest 1.754407671, 1.80528904; Σ 60; Σ² 73.58148369
        let edges: [(Int, Int)] = [
            (59, 43), (35, 58), (24, 23), (55, 5), (29, 9), (43, 42), (56, 9), (58, 5), (39, 19), (7, 56), (5, 46), (11, 6),
            (41, 11), (25, 54), (49, 54), (11, 19), (5, 48), (21, 3), (48, 19), (55, 9), (0, 46), (0, 17), (5, 49), (49, 38),
            (41, 46), (25, 5), (46, 41), (35, 46), (44, 41), (31, 50), (37, 25), (35, 51), (11, 37), (59, 39), (12, 6), (59, 14),
            (33, 0), (7, 39), (48, 15), (9, 49), (45, 15), (24, 36), (45, 43), (19, 31), (10, 16), (49, 45), (59, 45), (38, 47),
            (25, 27), (45, 8), (2, 34), (25, 16), (57, 25), (33, 4), (56, 26), (38, 17), (48, 49), (56, 29), (6, 47), (57, 55),
            (11, 25), (53, 59), (15, 56), (6, 28), (6, 32), (16, 18), (51, 27), (0, 53), (18, 21), (36, 3), (48, 17), (55, 38),
            (22, 45), (58, 28), (23, 44), (51, 40), (43, 49), (20, 17), (36, 48), (12, 17), (41, 24), (23, 6), (52, 0), (15, 46),
            (6, 38), (19, 37), (33, 4), (7, 13), (56, 41), (41, 47), (54, 45), (14, 18), (39, 6), (23, 58), (41, 14), (56, 26),
            (6, 19), (56, 52), (42, 12), (20, 12), (40, 29), (32, 57), (14, 24), (58, 48), (48, 47), (35, 55), (2, 53), (27, 29),
            (50, 6), (27, 35), (38, 29), (19, 26), (13, 16), (16, 58), (47, 29), (32, 6), (5, 33), (50, 42), (24, 18), (32, 37),
            (1, 31), (10, 31), (34, 23), (55, 39), (14, 47), (52, 30), (23, 31), (49, 23), (6, 48), (29, 44), (17, 31), (50, 10),
            (0, 29), (59, 32), (5, 56), (51, 27), (39, 55), (11, 58), (55, 20), (58, 49), (44, 9), (50, 41), (10, 9), (26, 11),
            (7, 11), (32, 5), (13, 26), (44, 55), (49, 20), (12, 53),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 60), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let spectrum = try graph.normalizedLaplacianSpectrum()
        let expected: [Double] = [
            -3e-16, 0.20025767064418, 0.23516357129422, 0.24031543661537, 0.287354652451, 0.30217446629008, 0.33098560343725, 0.37791244601066,
            0.42563046039466, 0.4485055911326, 0.49028833166021, 0.49945890789054, 0.52587882802483, 0.5562080113679, 0.60054585425548, 0.61735646209558,
            0.63113119880613, 0.68540078262632, 0.74249824079296, 0.7709146222409, 0.78960418055532, 0.79744541255144, 0.82352842733544, 0.8791945546374,
            0.90437701294893, 0.9196857329454, 0.94339398659402, 0.96180853779235, 0.98661503851532, 1, 1.00459791343458, 1.03238645441626,
            1.06390296669423, 1.08616980832857, 1.110234664972, 1.1304052842236, 1.15636755997787, 1.18720244760533, 1.19351273675666, 1.22087098541242,
            1.27078207626754, 1.30182091419205, 1.31703196154205, 1.37303891938968, 1.39905051640713, 1.40983370021387, 1.44192372955776, 1.46700006924815,
            1.498280619565, 1.5476458984497, 1.5684402492875, 1.59704418248312, 1.62954480510014, 1.64379073806777, 1.66374612665023, 1.70527111054408,
            1.71581330038162, 1.7309595275079, 1.75440767129598, 1.80528904012075,
        ]
        #expect(spectrum.count == expected.count)
        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })
        let tolerance = 1e-9 * 1.80528904012075
        for (k, value) in zip(spectrum, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= tolerance, "eigenvalue \(k)")
        }
    }
}
