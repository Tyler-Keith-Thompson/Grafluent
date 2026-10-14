// Hitting and commute times, stationary distributions, incidence and modularity matrices (catalog
// SGT-256 – SGT-297): exact rationals, nil across components; the lazy walk's limit from the
// uniform distribution; every entry of the matrices.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory random walks, incidence and modularity")
struct RandomWalkCatalogTests {
    @Test("SGT-256 P3: h(0 → 2) = 4")
    func sgt256() throws {
        // U: P(0..2) · hittingTime(from: 0, to: 2) → 4
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 0, to: 2)
        let time = try #require(value)
        // 4
        #expect(abs(time - 4) <= 1e-9 * 4)
    }

    @Test("SGT-257 P3: h(1 → 0) = 3")
    func sgt257() throws {
        // U: P(0..2) · hittingTime(from: 1, to: 0) → 3
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 1, to: 0)
        let time = try #require(value)
        // 3
        #expect(abs(time - 3) <= 1e-9 * 3)
    }

    @Test("SGT-258 the same vertex: 0")
    func sgt258() throws {
        // U: P(0..2) · hittingTime(from: 1, to: 1) → 0
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 1, to: 1)
        #expect(value == 0)
    }

    @Test("SGT-259 across components: nil")
    func sgt259() throws {
        // U: P(0..1), P(2..3) · hittingTime(from: 0, to: 3) → nil
        let edges: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 0, to: 3)
        #expect(value == nil)
    }

    @Test("SGT-260 P6: (n − 1)²")
    func sgt260() throws {
        // U: P(0..5) · hittingTime(from: 0, to: 5) → 25
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 0, to: 5)
        let time = try #require(value)
        // 25
        #expect(abs(time - 25) <= 1e-9 * 25)
    }

    @Test("SGT-261 K5: n − 1")
    func sgt261() throws {
        // U: K(5) · hittingTime(from: 0, to: 3) → 4
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 0, to: 3)
        let time = try #require(value)
        // 4
        #expect(abs(time - 4) <= 1e-9 * 4)
    }

    @Test("SGT-262 star: leaf to centre 1, centre to leaf 2n − 1")
    func sgt262() throws {
        // U: S(0;1..4) · hittingTime(from: 0, to: 2) → 7
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 0, to: 2)
        let time = try #require(value)
        // 7
        #expect(abs(time - 7) <= 1e-9 * 7)
    }

    @Test("SGT-263 a loop slows the walk")
    func sgt263() throws {
        // U: 0-0, 0-1 · hittingTime(from: 0, to: 1) → 3
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 0, to: 1)
        let time = try #require(value)
        // 3
        #expect(abs(time - 3) <= 1e-9 * 3)
    }

    @Test("SGT-264 weighted")
    func sgt264() throws {
        // U: C(0,1,2,3) · hittingTime(from: 0, to: 2) weight: [1, 2, 3, 4] → 21/5 (4.2)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3, 4]
        let value = try graph.hittingTime(from: 0, to: 2, weight: { weights[$0] })
        let time = try #require(value)
        // 21/5 (4.2)
        #expect(abs(time - 4.2) <= 1e-9 * 4.2)
    }

    @Test("SGT-265 parallel edges")
    func sgt265() throws {
        // U: 0=1, 1-2 · hittingTime(from: 2, to: 0) → 3
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.hittingTime(from: 2, to: 0)
        let time = try #require(value)
        // 3
        #expect(abs(time - 3) <= 1e-9 * 3)
    }

    @Test("SGT-266 P3: commute 0 ↔ 2 = 2m · R = 8")
    func sgt266() throws {
        // U: P(0..2) · commuteTime(from: 0, to: 2) → 8
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.commuteTime(from: 0, to: 2)
        let time = try #require(value)
        // 8
        #expect(abs(time - 8) <= 1e-9 * 8)
    }

    @Test("SGT-267 commute across components: nil")
    func sgt267() throws {
        // U: P(0..1), P(2..3) · commuteTime(from: 0, to: 2) → nil
        let edges: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.commuteTime(from: 0, to: 2)
        #expect(value == nil)
    }

    @Test("SGT-268 commute: the component's volume")
    func sgt268() throws {
        // U: P(0..2), C(3,4,5) · commuteTime(from: 3, to: 5) → 4
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.commuteTime(from: 3, to: 5)
        let time = try #require(value)
        // 4
        #expect(abs(time - 4) <= 1e-9 * 4)
    }

    @Test("SGT-269 commute: a loop counts twice in the volume")
    func sgt269() throws {
        // U: 0-0, 0-1 · commuteTime(from: 0, to: 1) → 4
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.commuteTime(from: 0, to: 1)
        let time = try #require(value)
        // 4
        #expect(abs(time - 4) <= 1e-9 * 4)
    }

    @Test("SGT-270 commute: weighted")
    func sgt270() throws {
        // U: C(0,1,2,3) · commuteTime(from: 0, to: 2) weight: [1, 2, 3, 4] → 42/5 (8.4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3, 4]
        let value = try graph.commuteTime(from: 0, to: 2, weight: { weights[$0] })
        let time = try #require(value)
        // 42/5 (8.4)
        #expect(abs(time - 8.4) <= 1e-9 * 8.4)
    }

    @Test("SGT-271 commute: Petersen")
    func sgt271() throws {
        // U: nx(petersen) · commuteTime(from: 0, to: 1) → 18
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = try graph.commuteTime(from: 0, to: 1)
        let time = try #require(value)
        // 18
        #expect(abs(time - 18) <= 1e-9 * 18)
    }

    @Test("SGT-272 empty")
    func sgt272() throws {
        // D: · stationaryDistribution() → []
        let edges: [(Int, Int)] = []
        let graph = ReferenceDirectedMultigraph(vertices: [] as [Int], edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = []
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
    }

    @Test("SGT-273 one vertex")
    func sgt273() throws {
        // D: [0] · stationaryDistribution() → [1]
        let edges: [(Int, Int)] = []
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 1), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [1]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-274 directed cycle: uniform")
    func sgt274() throws {
        // D: C(0..4) · stationaryDistribution() → [1/5 (0.2), 1/5 (0.2), 1/5 (0.2), 1/5 (0.2), 1/5 (0.2)]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 5), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.2, 0.2, 0.2, 0.2, 0.2]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-275 both arcs of P4: d / vol")
    func sgt275() throws {
        // D: 0>1, 1>0, 1>2, 2>1, 2>3, 3>2 · stationaryDistribution() → [1/6 (0.1666666667), 1/3 (0.3333333333), 1/3 (0.3333333333), 1/6 (0.1666666667)]
        let edges: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 4), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.16666666666667, 0.33333333333333, 0.33333333333333, 0.16666666666667]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-276 a dangling vertex jumps uniformly")
    func sgt276() throws {
        // D: 0>1 · stationaryDistribution() → [1/3 (0.3333333333), 2/3 (0.6666666667)]
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 2), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.33333333333333, 0.66666666666667]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-277 no arcs: uniform")
    func sgt277() throws {
        // D: E(3) · stationaryDistribution() → [1/3 (0.3333333333), 1/3 (0.3333333333), 1/3 (0.3333333333)]
        let edges: [(Int, Int)] = []
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.33333333333333, 0.33333333333333, 0.33333333333333]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-278 periodic: the star both ways")
    func sgt278() throws {
        // D: 0>1, 1>0, 0>2, 2>0, 0>3, 3>0 · stationaryDistribution() → [1/2 (0.5), 1/6 (0.1666666667), 1/6 (0.1666666667), 1/6 (0.1666666667)]
        let edges: [(Int, Int)] = [(0, 1), (1, 0), (0, 2), (2, 0), (0, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 4), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.5, 0.16666666666667, 0.16666666666667, 0.16666666666667]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-279 weights and a loop")
    func sgt279() throws {
        // D: 0>0, 0>1, 1>0 · stationaryDistribution() weight: [1, 3, 5] → [4/7 (0.5714285714), 3/7 (0.4285714286)]
        let edges: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 2), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights: [Int] = [1, 3, 5]
        let distribution = try graph.stationaryDistribution(weight: { weights[$0] })
        let expected: [Double] = [0.57142857142857, 0.42857142857143]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-280 parallel arcs add up")
    func sgt280() throws {
        // D: 0>0, 0>1, 0>1, 0>1, 1>0 · stationaryDistribution() → [4/7 (0.5714285714), 3/7 (0.4285714286)]
        let edges: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 2), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.57142857142857, 0.42857142857143]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-281 two closed classes fed equally")
    func sgt281() throws {
        // D: 0>1, 1>0, 2>3, 3>2, 4>0, 4>2 · stationaryDistribution() → [1/4 (0.25), 1/4 (0.25), 1/4 (0.25), 1/4 (0.25), 0]
        let edges: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 5), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.25, 0.25, 0.25, 0.25, 0]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-282 two closed classes, unequally")
    func sgt282() throws {
        // D: 0>1, 1>0, 2>2, 3>0, 3>1, 3>2 · stationaryDistribution() → [1/3 (0.3333333333), 1/3 (0.3333333333), 1/3 (0.3333333333), 0]
        let edges: [(Int, Int)] = [(0, 1), (1, 0), (2, 2), (3, 0), (3, 1), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 4), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.33333333333333, 0.33333333333333, 0.33333333333333, 0]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-283 a weight-0 arc is no arc")
    func sgt283() throws {
        // D: 0>1, 1>2, 2>0, 2>1 · stationaryDistribution() weight: [1, 1, 0, 1] → [0, 1/2 (0.5), 1/2 (0.5)]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights: [Int] = [1, 1, 0, 1]
        let distribution = try graph.stationaryDistribution(weight: { weights[$0] })
        let expected: [Double] = [0, 0.5, 0.5]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-284 a 3-cycle with a chord")
    func sgt284() throws {
        // D: C(0,1,2), 0>2 · stationaryDistribution() → [2/5 (0.4), 1/5 (0.2), 2/5 (0.4)]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let distribution = try graph.stationaryDistribution()
        let expected: [Double] = [0.4, 0.2, 0.4]
        #expect(distribution.probabilities.count == expected.count)
        for (k, value) in zip(distribution.probabilities, expected).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "probability \(k)")
        }
        #expect(distribution.probability(of: 0) == distribution.probabilities[0])
    }

    @Test("SGT-285 P3 unoriented")
    func sgt285() {
        // U: P(0..2) · incidenceMatrix() → 3×2: [[1, 0], [1, 1], [0, 1]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.incidenceMatrix()
        #expect(matrix.rowCount == 3 && matrix.columnCount == 2)
        #expect(matrix.nonzeroCount == 4 && !matrix.values.contains(0))
        let rows: [[Double]] = [
            [1, 0],
            [1, 1],
            [0, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 2 { #expect(matrix[i, j] == rows[i][j], "entry (\(i), \(j))") }
        }
    }

    @Test("SGT-286 P3 oriented")
    func sgt286() {
        // U: P(0..2) · incidenceMatrix(oriented: true) → 3×2: [[-1, 0], [1, -1], [0, 1]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.incidenceMatrix(oriented: true)
        #expect(matrix.rowCount == 3 && matrix.columnCount == 2)
        #expect(matrix.nonzeroCount == 4 && !matrix.values.contains(0))
        let rows: [[Double]] = [
            [-1, 0],
            [1, -1],
            [0, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 2 { #expect(matrix[i, j] == rows[i][j], "entry (\(i), \(j))") }
        }
    }

    @Test("SGT-287 loop: 2 unoriented")
    func sgt287() {
        // U: 1-1, 0-1, 0-1, 2-1 · incidenceMatrix() → 3×4: [[2, 1, 1, 1], [0, 1, 1, 0], [0, 0, 0, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(1, 1), (0, 1), (0, 1), (2, 1)]
        let graph = ReferencePseudograph(vertices: [1, 0, 2], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.incidenceMatrix()
        #expect(matrix.rowCount == 3 && matrix.columnCount == 4)
        #expect(matrix.nonzeroCount == 7 && !matrix.values.contains(0))
        let rows: [[Double]] = [
            [2, 1, 1, 1],
            [0, 1, 1, 0],
            [0, 0, 0, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 4 { #expect(matrix[i, j] == rows[i][j], "entry (\(i), \(j))") }
        }
    }

    @Test("SGT-288 loop: empty oriented")
    func sgt288() {
        // U: 1-1, 0-1, 0-1, 2-1 · incidenceMatrix(oriented: true) → 3×4: [[0, 1, 1, 1], [0, -1, -1, 0], [0, 0, 0, -1]] (nnz 6)
        let edges: [(Int, Int)] = [(1, 1), (0, 1), (0, 1), (2, 1)]
        let graph = ReferencePseudograph(vertices: [1, 0, 2], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.incidenceMatrix(oriented: true)
        #expect(matrix.rowCount == 3 && matrix.columnCount == 4)
        #expect(matrix.nonzeroCount == 6 && !matrix.values.contains(0))
        let rows: [[Double]] = [
            [0, 1, 1, 1],
            [0, -1, -1, 0],
            [0, 0, 0, -1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 4 { #expect(matrix[i, j] == rows[i][j], "entry (\(i), \(j))") }
        }
    }

    @Test("SGT-289 directed oriented")
    func sgt289() {
        // D: 2>0, 0>1, 1>1, 0>1 · incidenceMatrix(oriented: true) → 3×4: [[-1, 0, 0, 0], [1, -1, 0, -1], [0, 1, 0, 1]] (nnz 6)
        let edges: [(Int, Int)] = [(2, 0), (0, 1), (1, 1), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: [2, 0, 1], edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.incidenceMatrix(oriented: true)
        #expect(matrix.rowCount == 3 && matrix.columnCount == 4)
        #expect(matrix.nonzeroCount == 6 && !matrix.values.contains(0))
        let rows: [[Double]] = [
            [-1, 0, 0, 0],
            [1, -1, 0, -1],
            [0, 1, 0, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 4 { #expect(matrix[i, j] == rows[i][j], "entry (\(i), \(j))") }
        }
    }

    @Test("SGT-290 directed unoriented")
    func sgt290() {
        // D: 2>0, 0>1, 1>1, 0>1 · incidenceMatrix() → 3×4: [[1, 0, 0, 0], [1, 1, 0, 1], [0, 1, 2, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(2, 0), (0, 1), (1, 1), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: [2, 0, 1], edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.incidenceMatrix()
        #expect(matrix.rowCount == 3 && matrix.columnCount == 4)
        #expect(matrix.nonzeroCount == 7 && !matrix.values.contains(0))
        let rows: [[Double]] = [
            [1, 0, 0, 0],
            [1, 1, 0, 1],
            [0, 1, 2, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 4 { #expect(matrix[i, j] == rows[i][j], "entry (\(i), \(j))") }
        }
    }

    @Test("SGT-291 no edges")
    func sgt291() {
        // U: E(3) · incidenceMatrix() → 3×0: [[], [], []] (nnz 0)
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.incidenceMatrix()
        #expect(matrix.rowCount == 3 && matrix.columnCount == 0)
        #expect(matrix.nonzeroCount == 0 && !matrix.values.contains(0))
    }

    @Test("SGT-292 modularity of P3")
    func sgt292() {
        // U: P(0..2) · modularityMatrix() → [[-1/4 (-0.25), 1/2 (0.5), -1/4 (-0.25)], [1/2 (0.5), -1, 1/2 (0.5)], [-1/4 (-0.25), 1/2 (0.5), -1/4 (-0.25)]]
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.modularityMatrix()
        let expected: [[Double]] = [
            [-0.25, 0.5, -0.25],
            [0.5, -1, 0.5],
            [-0.25, 0.5, -0.25],
        ]
        #expect(matrix.count == expected.count)
        for (i, row) in zip(matrix, expected).enumerated() {
            #expect(row.0.count == row.1.count)
            for (j, entry) in zip(row.0, row.1).enumerated() {
                #expect(abs(entry.0 - entry.1) <= 1e-12 * max(1, abs(entry.1)), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-293 modularity of K4")
    func sgt293() {
        // U: K(4) · modularityMatrix() → [[-3/4 (-0.75), 1/4 (0.25), 1/4 (0.25), 1/4 (0.25)], [1/4 (0.25), -3/4 (-0.75), 1/4 (0.25), 1/4 (0.25)], [1/4 (0.25), 1/4 (0.25), -3/4 (-0.75), 1/4 (0.25)], …
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.modularityMatrix()
        let expected: [[Double]] = [
            [-0.75, 0.25, 0.25, 0.25],
            [0.25, -0.75, 0.25, 0.25],
            [0.25, 0.25, -0.75, 0.25],
            [0.25, 0.25, 0.25, -0.75],
        ]
        #expect(matrix.count == expected.count)
        for (i, row) in zip(matrix, expected).enumerated() {
            #expect(row.0.count == row.1.count)
            for (j, entry) in zip(row.0, row.1).enumerated() {
                #expect(abs(entry.0 - entry.1) <= 1e-12 * max(1, abs(entry.1)), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-294 modularity with a loop (A[v][v] = 2w) and weights")
    func sgt294() {
        // U: 0-0, 0-1, 1-2, 1-2, 2-3 · modularityMatrix() weight: [3, 1, 2, 5, 4] → [[131/30 (4.366666667), -13/15 (-0.8666666667), -77/30 (-2.566666667), -14/15 (-0.9333333333)], [-13/15 (-0.8666666667), -32/15 (-2.133333333), 61/15 (4.0666…
        let edges: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [3, 1, 2, 5, 4]
        let matrix = graph.modularityMatrix(weight: { weights[$0] })
        let expected: [[Double]] = [
            [4.3666666666667, -0.86666666666667, -2.56666666666667, -0.93333333333333],
            [-0.86666666666667, -2.13333333333333, 4.0666666666667, -1.06666666666667],
            [-2.56666666666667, 4.0666666666667, -4.0333333333333, 2.53333333333333],
            [-0.93333333333333, -1.06666666666667, 2.53333333333333, -0.53333333333333],
        ]
        #expect(matrix.count == expected.count)
        for (i, row) in zip(matrix, expected).enumerated() {
            #expect(row.0.count == row.1.count)
            for (j, entry) in zip(row.0, row.1).enumerated() {
                #expect(abs(entry.0 - entry.1) <= 1e-12 * max(1, abs(entry.1)), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-295 modularity without edges: zeros")
    func sgt295() {
        // U: E(2) · modularityMatrix() → [[0, 0], [0, 0]]
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.modularityMatrix()
        let expected: [[Double]] = [
            [0, 0],
            [0, 0],
        ]
        #expect(matrix.count == expected.count)
        for (i, row) in zip(matrix, expected).enumerated() {
            #expect(row.0.count == row.1.count)
            for (j, entry) in zip(row.0, row.1).enumerated() {
                #expect(abs(entry.0 - entry.1) <= 1e-12 * max(1, abs(entry.1)), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-296 directed modularity")
    func sgt296() {
        // D: 0>1, 0>2, 1>2, 2>2 · modularityMatrix() → [[0, 1/2 (0.5), -1/2 (-0.5)], [0, -1/4 (-0.25), 1/4 (0.25)], [0, -1/4 (-0.25), 1/4 (0.25)]]
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.modularityMatrix()
        let expected: [[Double]] = [
            [0, 0.5, -0.5],
            [0, -0.25, 0.25],
            [0, -0.25, 0.25],
        ]
        #expect(matrix.count == expected.count)
        for (i, row) in zip(matrix, expected).enumerated() {
            #expect(row.0.count == row.1.count)
            for (j, entry) in zip(row.0, row.1).enumerated() {
                #expect(abs(entry.0 - entry.1) <= 1e-12 * max(1, abs(entry.1)), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-297 directed modularity, weighted")
    func sgt297() {
        // D: C(0,1,2), 0>2 · modularityMatrix() weight: [1, 2, 3, 4] → [[-3/2 (-1.5), 1/2 (0.5), 1], [-3/5 (-0.6), -1/5 (-0.2), 4/5 (0.8)], [21/10 (2.1), -3/10 (-0.3), -9/5 (-1.8)]]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights: [Int] = [1, 2, 3, 4]
        let matrix = graph.modularityMatrix(weight: { weights[$0] })
        let expected: [[Double]] = [
            [-1.5, 0.5, 1],
            [-0.6, -0.2, 0.8],
            [2.1, -0.3, -1.8],
        ]
        #expect(matrix.count == expected.count)
        for (i, row) in zip(matrix, expected).enumerated() {
            #expect(row.0.count == row.1.count)
            for (j, entry) in zip(row.0, row.1).enumerated() {
                #expect(abs(entry.0 - entry.1) <= 1e-12 * max(1, abs(entry.1)), "entry (\(i), \(j))")
            }
        }
    }
}
