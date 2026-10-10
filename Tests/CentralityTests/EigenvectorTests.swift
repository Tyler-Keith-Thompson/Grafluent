// §E: the principal eigenvector of Aᵀ by power iteration on A + I from the uniform start, Euclidean
// norm 1; an undirected loop is 2 in A, parallel copies add; disconnected graphs; nil on a DAG and
// with too few iterations.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Eigenvector")
struct EigenvectorTests {
    @Test("CE-130 U(K(4)).eigenvectorCentrality() is [0.5, 0.5, 0.5, 0.5]: Euclidean norm 1 (NetworkX)")
    func eigenvector130() throws {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-131 U(P(0,1,2)).eigenvectorCentrality() is [0.5, 0.707106781187, 0.5]: Bipartite: plain power iteration oscillates, the A + I shift (NetworkX) converges")
    func eigenvector131() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [0.5, 0.7071067811865474, 0.5]
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-132 U(S(0;1..4)).eigenvectorCentrality() is 5 scores, [0.707106781187, 0.353553390593, …]")
    func eigenvector132() throws {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.7071067811865479, 0.35355339059327356, 0.35355339059327356, 0.35355339059327356,
            0.35355339059327356
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-133 U(P(0,1,2,3)).eigenvectorCentrality() is [0.37174803446, 0.601500955008, 0.601500955008, 0.37174803446]")
    func eigenvector133() throws {
        // U: P(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.3717480344601846, 0.6015009550075456, 0.6015009550075456, 0.3717480344601846
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-134 U(nx(krackhardt_kite)).eigenvectorCentrality() is 10 scores, [0.352209396817, 0.352209396817, …]")
    func eigenvector134() throws {
        // U: nx(krackhardt_kite)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5),
            (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.3522093968166346, 0.3522093968166346, 0.2858349913908715, 0.4810208582728083,
            0.2858349913908715, 0.39769063647017033, 0.39769063647017033, 0.19586058302781284,
            0.048073485026283974, 0.011163255309776575
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-135 U(nx(karate_club)).eigenvectorCentrality() is 34 scores, [0.355491444525, 0.265959919552, …]")
    func eigenvector135() throws {
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
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.35549144452455894, 0.2659599195524863, 0.317192504486429, 0.21117972037788527,
            0.0759688181830663, 0.07948304511709661, 0.07948304511709661, 0.17095974804479222,
            0.2274039071254013, 0.10267425072358718, 0.0759688181830663, 0.05285569749351979,
            0.0842546287167112, 0.22647272014247857, 0.10140326218952737, 0.10140326218952737,
            0.023635628104590228, 0.09239953819569997, 0.10140326218952737, 0.14791251029338634,
            0.10140326218952737, 0.09239953819569997, 0.10140326218952737, 0.15011857186115718,
            0.05705244054116677, 0.059206474916779994, 0.07557941348827443, 0.13347715338024219,
            0.13107782298371218, 0.13496081926233194, 0.17475830231435474, 0.19103384140654575,
            0.30864421979105366, 0.37336347029149053
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-136 U(nx(florentine_families)).eigenvectorCentrality() is 15 scores, [0.132154294729, 0.430308094041, …]")
    func eigenvector136() throws {
        // U: nx(florentine_families)
        let pairs: [(String, String)] = [
            ("Acciaiuoli", "Medici"), ("Medici", "Barbadori"), ("Medici", "Ridolfi"),
            ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"),
            ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"),
            ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"),
            ("Strozzi", "Bischeri"), ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"),
            ("Albizzi", "Ginori"), ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"),
            ("Bischeri", "Guadagni"), ("Guadagni", "Lamberteschi")
        ]
        let graph = ReferencePseudograph(vertices: ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.13215429472871026, 0.43030809404092446, 0.2590261671902524, 0.2757303735808764,
            0.3559804484113811, 0.21170525116052846, 0.3415526440572176, 0.3258423011242119,
            0.24395610915884292, 0.14591719646635043, 0.04481343589592644, 0.2828000865441147,
            0.2891155990122102, 0.0749227076997092, 0.08879188797897287
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-137 U(K(3), 3-4).eigenvectorCentrality() is [0.57735026919, 0.57735026919, 0.57735026919, 0, 0]: Disconnected: the limit puts 0 on K₂ (NetworkX returns 4.5e-6 there, within Tol)")
    func eigenvector137() throws {
        // U: K(3), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.5773502691896258, 0.5773502691896258, 0.5773502691896258, 4.7221377109224855e-15,
            4.7221377109224855e-15
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-138 U(K(3), C(3,4,5)).eigenvectorCentrality() is 6 scores, [0.408248290464, 0.408248290464, …]")
    func eigenvector138() throws {
        // U: K(3), C(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.408248290463863, 0.408248290463863, 0.408248290463863, 0.408248290463863,
            0.408248290463863, 0.408248290463863
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-139 U(P(0,1,2), 1-1).eigenvectorCentrality() is [0.325057583672, 0.888073833977, 0.325057583672]: A_11 = 2 (the loop twice, as degree(of:)): λ = 1 + √3")
    func eigenvector139() throws {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [0.3250575836718682, 0.8880738339771153, 0.3250575836718682]
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-140 U(0-1, 0-1, 1-2, 0-3, 3-2).eigenvectorCentrality() is [0.601500955008, 0.601500955008, 0.37174803446, 0.37174803446]: Parallel edges add: igraph agrees, eigenvector_centrality_numpy agrees")
    func eigenvector140() throws {
        // U: 0-1, 0-1, 1-2, 0-3, 3-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (0, 3), (3, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [
            0.6015009550075454, 0.6015009550075454, 0.37174803446018484, 0.37174803446018484
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-141 D(C(0,1,2)).eigenvectorCentrality() is [0.57735026919, 0.57735026919, 0.57735026919]")
    func eigenvector141() throws {
        // D: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
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

    @Test("CE-142 D(P(0,1,2)).eigenvectorCentrality() is nil")
    func eigenvector142() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.eigenvectorCentrality() == nil)
    }

    @Test("CE-143 D(C(0,1,2), 0>3).eigenvectorCentrality() is [0.5, 0.5, 0.5, 0.5]: In-edges (left eigenvector): 3 inherits 0's score")
    func eigenvector143() throws {
        // D: C(0,1,2), 0>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
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
    }

    @Test("CE-144 U(P(0,1,2)).eigenvectorCentrality(weight: [1.0, 2.0]) is [0.316227766017, 0.707106781187, 0.632455532034]")
    func eigenvector144() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 2]
        let result = try #require(graph.eigenvectorCentrality(weight: { w[$0] }))
        let expected: [Double] = [0.31622776601683783, 0.7071067811865478, 0.6324555320336757]
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
        let arcs = try #require(graph.directed.eigenvectorCentrality(weight: { w[$0.position] }))
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-145 U(nx(karate_club)).eigenvectorCentrality(maxIterations: 5) is nil: NetworkX raises with max_iter=5 too")
    func eigenvector145() {
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
        #expect(graph.eigenvectorCentrality(maxIterations: 5) == nil)
        #expect(graph.directed.eigenvectorCentrality(maxIterations: 5) == nil)
    }

    @Test("CE-146 U(nx(karate_club)).eigenvectorCentrality(tolerance: 1e-10) is 34 scores, [0.355491444525, 0.265959919552, …]")
    func eigenvector146() throws {
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
        let result = try #require(graph.eigenvectorCentrality(tolerance: 1e-10))
        let expected: [Double] = [
            0.35549144452455894, 0.2659599195524863, 0.317192504486429, 0.21117972037788527,
            0.0759688181830663, 0.07948304511709661, 0.07948304511709661, 0.17095974804479222,
            0.2274039071254013, 0.10267425072358718, 0.0759688181830663, 0.05285569749351979,
            0.0842546287167112, 0.22647272014247857, 0.10140326218952737, 0.10140326218952737,
            0.023635628104590228, 0.09239953819569997, 0.10140326218952737, 0.14791251029338634,
            0.10140326218952737, 0.09239953819569997, 0.10140326218952737, 0.15011857186115718,
            0.05705244054116677, 0.059206474916779994, 0.07557941348827443, 0.13347715338024219,
            0.13107782298371218, 0.13496081926233194, 0.17475830231435474, 0.19103384140654575,
            0.30864421979105366, 0.37336347029149053
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-8 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
        let arcs = try #require(graph.directed.eigenvectorCentrality(tolerance: 1e-10))
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-8 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-147 U(P(0,1,2)).directed.eigenvectorCentrality() is [0.5, 0.707106781187, 0.5]: Same as undirected")
    func eigenvector147() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.directed.eigenvectorCentrality())
        let expected: [Double] = [0.5, 0.7071067811865474, 0.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
        #expect(abs(norm - 1) <= 1e-12, "Euclidean norm 1")
    }

    @Test("CE-148 D(C(0,1,2), 2>0).eigenvectorCentrality() is [0.702414383919, 0.557506665976, 0.442493334024]: A parallel arc counts twice")
    func eigenvector148() throws {
        // D: C(0,1,2), 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [0.702414383919315, 0.5575066659755585, 0.44249333402444174]
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
}
