// Fiedler vector (catalog SGT-108 – SGT-125): every entry where λ₂ is simple, with the canonical
// sign (the first entry of magnitude at least 1e-4 of the largest is positive); only invariants
// where λ₂ is multiple; nil when not connected.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory Fiedler vector")
struct FiedlerVectorTests {
    @Test("SGT-108 path P4")
    func sgt108() throws {
        // U: P(0..3) · fiedlerVector() → λ₂ = 0.5857864376; [0.6532814824, 0.2705980501, -0.2705980501, -0.6532814824]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 3.4142135623731; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.5857864376269) <= 1e-6 * 3.4142135623731)
        let expected: [Double] = [0.65328148243819, 0.2705980500731, -0.2705980500731, -0.65328148243819]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-109 path P5: middle entry 0")
    func sgt109() throws {
        // U: P(0..4) · fiedlerVector() → λ₂ = 0.3819660113; [0.601500955, 0.3717480345, 0, -0.3717480345, -0.601500955]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 3.6180339887499; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.3819660112501) <= 1e-6 * 3.6180339887499)
        let expected: [Double] = [0.60150095500755, 0.37174803446018, 2e-16, -0.37174803446018, -0.60150095500755]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-110 path P4 in another vertex order")
    func sgt110() throws {
        // U: P(2,0,3,1) · fiedlerVector() → λ₂ = 0.5857864376; [0.6532814824, 0.2705980501, -0.2705980501, -0.6532814824]
        let edges: [(Int, Int)] = [(2, 0), (0, 3), (3, 1)]
        let graph = ReferencePseudograph(vertices: [2, 0, 3, 1], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 3.4142135623731; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.5857864376269) <= 1e-6 * 3.4142135623731)
        let expected: [Double] = [0.65328148243819, 0.2705980500731, -0.2705980500731, -0.65328148243819]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-111 canonical sign: the first significant entry is positive")
    func sgt111() throws {
        // U: P(3,2,1,0) · fiedlerVector() → λ₂ = 0.5857864376; [0.6532814824, 0.2705980501, -0.2705980501, -0.6532814824]
        let edges: [(Int, Int)] = [(3, 2), (2, 1), (1, 0)]
        let graph = ReferencePseudograph(vertices: [3, 2, 1, 0], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 3.4142135623731; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.5857864376269) <= 1e-6 * 3.4142135623731)
        let expected: [Double] = [0.65328148243819, 0.2705980500731, -0.2705980500731, -0.65328148243819]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-112 barbell: two K4 joined by an edge")
    func sgt112() throws {
        // U: K(0..3), K(4..7), 3-4 · fiedlerVector() → λ₂ = 0.3542486889; [0.382527662, 0.382527662, 0.382527662, 0.2470177392, -0.2470177392, -0.382527662, -0.382527662, -0.382527662]
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7),
            (3, 4),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 5.6457513110646; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.3542486889354) <= 1e-6 * 5.6457513110646)
        let expected: [Double] = [0.38252766196473, 0.38252766196473, 0.38252766196473, 0.2470177392322, -0.2470177392322, -0.38252766196473, -0.38252766196473, -0.38252766196473]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-113 grid 3×4")
    func sgt113() throws {
        // U: grid(3,4) · fiedlerVector() → λ₂ = 0.5857864376; [0.3771722397, 0.1562298571, -0.1562298571, -0.3771722397, 0.3771722397, 0.1562298571, -0.1562298571, -0.3771722397, 0.3771722397, 0.15622…
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7),
            (6, 10), (7, 11), (8, 9), (9, 10), (10, 11),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 12), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 6.4142135623731; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.5857864376269) <= 1e-6 * 6.4142135623731)
        let expected: [Double] = [
            0.37717223974229, 0.1562298570519, -0.1562298570519, -0.37717223974229, 0.37717223974229, 0.1562298570519, -0.1562298570519, -0.37717223974229,
            0.37717223974229, 0.1562298570519, -0.1562298570519, -0.37717223974229,
        ]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-114 weighted path")
    func sgt114() throws {
        // U: P(0..3) · fiedlerVector(weight:) [1, 2, 3] → λ₂ = 0.9358222275; [0.7931284139, 0.05090121489, -0.3440296287, -0.5]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let fiedler = try #require(graph.fiedlerVector(weight: { weights[$0] }))
        // λ₂ to 1e-6 · max(1, scale), scale = 7.7587704831436; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.93582222752409) <= 1e-6 * 7.7587704831436)
        let expected: [Double] = [0.79312841385727, 0.05090121488871, -0.34402962874599, -0.5]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-115 parallel edge counts twice")
    func sgt115() throws {
        // U: 0=1, P(1,2,3) · fiedlerVector() → λ₂ = 0.6570769172; [0.5605806578, 0.3764083525, -0.2392654978, -0.6977235125]
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 4.8136065026483; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.65707691722283) <= 1e-6 * 4.8136065026483)
        let expected: [Double] = [0.56058065775662, 0.37640835252989, -0.23926549782084, -0.69772351246567]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-116 loop does not change it")
    func sgt116() throws {
        // U: 1-1, P(0..3) · fiedlerVector() → λ₂ = 0.5857864376; [0.2705980501, 0.6532814824, -0.2705980501, -0.6532814824]
        let edges: [(Int, Int)] = [(1, 1), (0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: [1, 0, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 3.4142135623731; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.5857864376269) <= 1e-6 * 3.4142135623731)
        let expected: [Double] = [0.2705980500731, 0.65328148243819, -0.2705980500731, -0.65328148243819]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-117 path P4 normalized")
    func sgt117() throws {
        // U: P(0..3) · fiedlerVector(normalized: true) → λ₂ = 0.5; [0.5773502692, 0.4082482905, -0.4082482905, -0.5773502692]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector(normalized: true))
        // λ₂ to 1e-6 · max(1, scale), scale = 2; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.5) <= 1e-6 * 2)
        let expected: [Double] = [0.57735026918963, 0.40824829046386, -0.40824829046386, -0.57735026918963]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-118 karate club")
    func sgt118() throws {
        // U: nx(karate_club) · fiedlerVector() → λ₂ = 0.4685252267; first 4 [0.1121374323, 0.04128788812, -0.02321895576, 0.05549978091], argmax 16, argmin 26
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
        let fiedler = try #require(graph.fiedlerVector())
        // λ₂ to 1e-6 · max(1, scale), scale = 18.1366959730044; entries to 1e-5, canonical sign.
        #expect(abs(fiedler.algebraicConnectivity - 0.4685252267014) <= 1e-6 * 18.1366959730044)
        let expected: [Double] = [
            0.11213743230966, 0.04128788811914, -0.02321895576433, 0.05549978091414, 0.28460452516293, 0.323727218344, 0.323727218344, 0.05258600372364,
            -0.05160127594533, -0.09280088795114, 0.28460452516293, 0.21099295383989, 0.10946129583494, 0.01474197382708, -0.16275078473568, -0.16275078473568,
            0.42276532919537, 0.10018142192335, -0.16275078473568, 0.0136371326787, -0.16275078473568, 0.10018142192335, -0.16275078473568, -0.15569456736395,
            -0.1530255806008, -0.16096292141292, -0.18710956349329, -0.1276640485189, -0.09515229952361, -0.16765031326034, -0.07349963560436, -0.0987534270285,
            -0.1303454580847, -0.11890326307255,
        ]
        #expect(fiedler.values.count == expected.count)
        for (k, value) in zip(fiedler.values, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-5, "entry \(k)")
        }
        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        for (i, vertex) in graph.vertices.enumerated() {
            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])
        }
    }

    @Test("SGT-119 K4: λ₂ = 4 ×3")
    func sgt119() throws {
        // U: K(4) · fiedlerVector() → degenerate: λ₂ = 4 ×3 (some unit vector of that eigenspace)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // Degenerate: λ₂ = 4 with multiplicity 3. Only invariants are pinned.
        let scale: Double = 4
        #expect(abs(fiedler.algebraicConnectivity - 4) <= 1e-6 * scale)
        #expect(graph.laplacianSpectrum().filter { abs($0 - 4) <= 1e-6 * scale }.count == 3)
        let x = fiedler.values
        #expect(x.count == 4)
        #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        #expect(abs(x.reduce(0, +)) <= 1e-6)
        let mx = graph.laplacianMatrix() * x
        let residual = zip(mx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
        #expect(residual.squareRoot() <= 1e-6 * scale)
        let rayleigh = zip(mx, x).reduce(0) { $0 + $1.0 * $1.1 }
        #expect(abs(rayleigh - 4) <= 1e-6 * scale)
    }

    @Test("SGT-120 cycle C6: λ₂ = 1 ×2")
    func sgt120() throws {
        // U: C(0..5) · fiedlerVector() → degenerate: λ₂ = 1 ×2 (some unit vector of that eigenspace)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // Degenerate: λ₂ = 1 with multiplicity 2. Only invariants are pinned.
        let scale: Double = 4
        #expect(abs(fiedler.algebraicConnectivity - 1) <= 1e-6 * scale)
        #expect(graph.laplacianSpectrum().filter { abs($0 - 1) <= 1e-6 * scale }.count == 2)
        let x = fiedler.values
        #expect(x.count == 6)
        #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        #expect(abs(x.reduce(0, +)) <= 1e-6)
        let mx = graph.laplacianMatrix() * x
        let residual = zip(mx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
        #expect(residual.squareRoot() <= 1e-6 * scale)
        let rayleigh = zip(mx, x).reduce(0) { $0 + $1.0 * $1.1 }
        #expect(abs(rayleigh - 1) <= 1e-6 * scale)
    }

    @Test("SGT-121 star K1,4: λ₂ = 1 ×3")
    func sgt121() throws {
        // U: S(0;1..4) · fiedlerVector() → degenerate: λ₂ = 1 ×3 (some unit vector of that eigenspace)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // Degenerate: λ₂ = 1 with multiplicity 3. Only invariants are pinned.
        let scale: Double = 5
        #expect(abs(fiedler.algebraicConnectivity - 1) <= 1e-6 * scale)
        #expect(graph.laplacianSpectrum().filter { abs($0 - 1) <= 1e-6 * scale }.count == 3)
        let x = fiedler.values
        #expect(x.count == 5)
        #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        #expect(abs(x.reduce(0, +)) <= 1e-6)
        let mx = graph.laplacianMatrix() * x
        let residual = zip(mx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
        #expect(residual.squareRoot() <= 1e-6 * scale)
        let rayleigh = zip(mx, x).reduce(0) { $0 + $1.0 * $1.1 }
        #expect(abs(rayleigh - 1) <= 1e-6 * scale)
    }

    @Test("SGT-122 hypercube Q3")
    func sgt122() throws {
        // U: Q(3) · fiedlerVector() → degenerate: λ₂ = 2 ×3 (some unit vector of that eigenspace)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let fiedler = try #require(graph.fiedlerVector())
        // Degenerate: λ₂ = 2 with multiplicity 3. Only invariants are pinned.
        let scale: Double = 6
        #expect(abs(fiedler.algebraicConnectivity - 2) <= 1e-6 * scale)
        #expect(graph.laplacianSpectrum().filter { abs($0 - 2) <= 1e-6 * scale }.count == 3)
        let x = fiedler.values
        #expect(x.count == 8)
        #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
        #expect(abs(x.reduce(0, +)) <= 1e-6)
        let mx = graph.laplacianMatrix() * x
        let residual = zip(mx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
        #expect(residual.squareRoot() <= 1e-6 * scale)
        let rayleigh = zip(mx, x).reduce(0) { $0 + $1.0 * $1.1 }
        #expect(abs(rayleigh - 2) <= 1e-6 * scale)
    }

    @Test("SGT-123 disconnected")
    func sgt123() {
        // U: C(0,1,2), C(3,4,5) · fiedlerVector() → nil
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.fiedlerVector() == nil)
    }

    @Test("SGT-124 two isolated vertices")
    func sgt124() {
        // U: E(2) · fiedlerVector() → nil
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.fiedlerVector() == nil)
    }

    @Test("SGT-125 weight 0 disconnects")
    func sgt125() {
        // U: P(0..3) · fiedlerVector(weight:) [1, 0, 1] → nil
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 0, 1]
        #expect(graph.fiedlerVector(weight: { weights[$0] }) == nil)
    }
}
