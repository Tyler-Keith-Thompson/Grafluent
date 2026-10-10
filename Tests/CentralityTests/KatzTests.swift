// §F: x = αAᵀx + β1 from x₀ = 0, normalized to Euclidean norm 1 by default; nil when α ≥ 1/ρ(A).
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Katz")
struct KatzTests {
    @Test("CE-160 U(P(0,1,2)).katzCentrality() is [0.559885258415, 0.610783918271, 0.559885258415]: α = 0.1, β = 1, Euclidean norm 1 (NetworkX defaults)")
    func katz160() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5598852584152163, 0.6107839182711452, 0.5598852584152163]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.katzCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-161 U(K(4)).katzCentrality() is [0.5, 0.5, 0.5, 0.5]")
    func katz161() throws {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.katzCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-162 U(nx(karate_club)).katzCentrality() is 34 scores, [0.321324621912, 0.235484274833, …]")
    func katz162() throws {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [
            0.3213246219124112, 0.23548427483304846, 0.26576591973677494, 0.1949132148792719,
            0.12190437880575036, 0.13097224917085232, 0.13097224917085232, 0.1662330569529996,
            0.2007178298475908, 0.12420148853050474, 0.12190437880575036, 0.0966167160080901,
            0.1161080374960173, 0.19937369969297786, 0.12513341330533256, 0.12513341330533256,
            0.09067870365101947, 0.12016514349139495, 0.12513341330533256, 0.15330578623137317,
            0.12513341330533256, 0.12016514349139495, 0.12513341330533256, 0.1667906398392426,
            0.11021103786319625, 0.11156458182124115, 0.11293549927853831, 0.15190165630074862,
            0.14358164876465299, 0.15310602721711067, 0.16875362377339648, 0.1938016023414827,
            0.2750851674850533, 0.33140642739978243
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.katzCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-163 U(nx(karate_club)).katzCentrality(alpha: 0.2) is nil: α > 1/λ_max ≈ 0.149: the series diverges")
    func katz163() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.katzCentrality(alpha: 0.2) == nil)
        #expect(graph.directed.katzCentrality(alpha: 0.2) == nil)
    }

    @Test("CE-164 U(P(0,1,2)).katzCentrality(normalized: false) is [1.12244897959, 1.22448979592, 1.12244897959]: (I − αAᵀ)⁻¹β1")
    func katz164() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality(normalized: false))
        let expected: [Double] = [1.1224489795918366, 1.2244897959183674, 1.1224489795918366]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = try #require(graph.directed.katzCentrality(normalized: false))
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-165 U(P(0,1,2)).katzCentrality(alpha: 0.5, beta: 2.0, normalized: false) is [6, 8, 6]")
    func katz165() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality(alpha: 0.5, beta: 2, normalized: false))
        let expected: [Double] = [5.999999999999998, 7.999999999999997, 5.999999999999998]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = try #require(graph.directed.katzCentrality(alpha: 0.5, beta: 2, normalized: false))
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-166 D(P(0,1,2)).katzCentrality() is [0.538999370961, 0.592899308057, 0.598289301767]: In-edges: β, β + αβ, β + α(β + αβ), normalized")
    func katz166() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5389993709611511, 0.5928993080572663, 0.5982893017668779]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
    }

    @Test("CE-167 D(C(0,1,2)).katzCentrality() is [0.57735026919, 0.57735026919, 0.57735026919]")
    func katz167() throws {
        // D: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5773502691896257, 0.5773502691896257, 0.5773502691896257]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
    }

    @Test("CE-168 U(P(0,1,2), 1-1).katzCentrality() is [0.514495755428, 0.68599434057, 0.514495755428]: Loop twice in A")
    func katz168() throws {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5144957554275265, 0.6859943405700353, 0.5144957554275265]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.katzCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-169 U(0-1, 0-1, 1-2).katzCentrality() is [0.582127834454, 0.625426599, 0.519585174554]: NetworkX refuses multigraphs")
    func katz169() throws {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5821278344542006, 0.6254265990003808, 0.5195851745541625]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.katzCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-170 U(P(0,1,2)).katzCentrality(weight: [1.0, 2.0]) is [0.519585174554, 0.625426599, 0.582127834454]")
    func katz170() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 2]
        let result = try #require(graph.katzCentrality(weight: { w[$0] }))
        let expected: [Double] = [0.5195851745541625, 0.6254265990003808, 0.5821278344542006]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.katzCentrality(weight: { w[$0.position] }))
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-171 U(K(4)).katzCentrality(alpha: 0.4) is nil: α·λ_max = 1.2")
    func katz171() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.katzCentrality(alpha: 0.4) == nil)
        #expect(graph.directed.katzCentrality(alpha: 0.4) == nil)
    }
}
