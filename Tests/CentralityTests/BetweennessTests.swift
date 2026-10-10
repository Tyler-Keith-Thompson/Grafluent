// §D: Brandes betweenness with NetworkX's rescaling (normalized, endpoints, directed ordered pairs),
// parallel edges as distinct shortest paths (edge sequences), self-loops on no path, `Int` and
// `Double` weights with ties by exact equality (CE-114).
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Betweenness")
struct BetweennessTests {
    @Test("CE-090 U(P(0..4)).betweennessCentrality() is [0, 0.5, 0.666666666667, 0.5, 0]: Normalized (default): ÷ (n − 1)(n − 2)/2 pairs")
    func betweenness090() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0, 0.5, 0.6666666666666666, 0.5, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-091 U(P(0..4)).betweennessCentrality(normalized: false) is [0, 3, 4, 3, 0]: Unordered pairs (NetworkX halves)")
    func betweenness091() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [0, 3, 4, 3, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-092 U(P(0..4)).betweennessCentrality(endpoints: true) is [0.4, 0.7, 0.8, 0.7, 0.4]")
    func betweenness092() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(endpoints: true)
        let expected: [Double] = [0.4, 0.7000000000000001, 0.8, 0.7000000000000001, 0.4]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(endpoints: true)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-093 U(P(0..4)).betweennessCentrality(normalized: false, endpoints: true) is [4, 7, 8, 7, 4]")
    func betweenness093() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(normalized: false, endpoints: true)
        let expected: [Double] = [4, 7, 8, 7, 4]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(normalized: false, endpoints: true)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-094 U(S(0;1..4)).betweennessCentrality() is [1, 0, 0, 0, 0]: The hub: 1")
    func betweenness094() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [1, 0, 0, 0, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-095 U(C(0..4)).betweennessCentrality(normalized: false) is [1, 1, 1, 1, 1]")
    func betweenness095() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [1, 1, 1, 1, 1]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-096 U(C(0,1,2,3)).betweennessCentrality(normalized: false) is [0.5, 0.5, 0.5, 0.5]: Each opposite pair has two shortest paths: ½ each")
    func betweenness096() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [0.5, 0.5, 0.5, 0.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-097 U(nx(krackhardt_kite)).betweennessCentrality() is 10 scores, [0.0231481481481, 0.0231481481481, …]: NetworkX test values")
    func betweenness097() {
        // U: nx(krackhardt_kite)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5),
            (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [
            0.023148148148148143, 0.023148148148148143, 0, 0.10185185185185183, 0, 0.23148148148148148,
            0.23148148148148148, 0.38888888888888884, 0.2222222222222222, 0
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-098 U(nx(florentine_families)).betweennessCentrality() is 15 scores, [0, 0.521978021978, …]: NetworkX test values")
    func betweenness098() {
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
        let result = graph.betweennessCentrality()
        let expected: [Double] = [
            0, 0.521978021978022, 0.05494505494505495, 0.02197802197802198, 0.10256410256410257,
            0.09340659340659341, 0.11355311355311355, 0.09157509157509157, 0.21245421245421245,
            0.14285714285714288, 0, 0.1043956043956044, 0.2545787545787546, 0, 0
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-099 U(nx(karate_club)).betweennessCentrality() is 34 scores, [0.437635281385, 0.0539366883117, …]")
    func betweenness099() {
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
        let result = graph.betweennessCentrality()
        let expected: [Double] = [
            0.43763528138528146, 0.053936688311688304, 0.14365680615680618, 0.011909271284271283,
            0.0006313131313131313, 0.02998737373737374, 0.029987373737373736, 0, 0.055926827801827804,
            0.0008477633477633477, 0.0006313131313131313, 0, 0, 0.04586339586339586, 0, 0, 0, 0, 0,
            0.03247504810004811, 0, 0, 0, 0.017613636363636363, 0.0022095959595959595,
            0.0038404882154882154, 0, 0.02233345358345358, 0.0017947330447330447, 0.0029220779220779218,
            0.014411976911976914, 0.13827561327561325, 0.14524711399711399, 0.30407497594997596
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-100 U(nx(petersen)).betweennessCentrality() is 10 scores, [0.0833333333333, 0.0833333333333, …]: Vertex-transitive: all equal")
    func betweenness100() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [
            0.08333333333333333, 0.08333333333333333, 0.08333333333333333, 0.08333333333333333,
            0.08333333333333333, 0.08333333333333333, 0.08333333333333333, 0.08333333333333333,
            0.08333333333333333, 0.08333333333333333
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-101 U(P(0,1,2), 3-4).betweennessCentrality() is [0, 0.166666666667, 0, 0, 0]: Unreachable pairs contribute nothing")
    func betweenness101() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0, 0.16666666666666666, 0, 0, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-102 D(P(0,1,2)).betweennessCentrality() is [0, 0.5, 0]: Directed normalized: ÷ (n − 1)(n − 2) ordered pairs")
    func betweenness102() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0, 0.5, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-103 D(P(0,1,2)).betweennessCentrality(normalized: false) is [0, 1, 0]: Ordered pairs, not halved")
    func betweenness103() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [0, 1, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-104 D(C(0,1,2,3)).betweennessCentrality(normalized: false) is [3, 3, 3, 3]")
    func betweenness104() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [3, 3, 3, 3]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-105 D(S(0;1..3), 1>0).betweennessCentrality(normalized: false) is [2, 0, 0, 0]")
    func betweenness105() {
        // D: S(0;1..3), 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [2, 0, 0, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-106 U(P(0,1,2)).directed.betweennessCentrality() is [0, 1, 0]: Normalized values agree with undirected")
    func betweenness106() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.directed.betweennessCentrality()
        let expected: [Double] = [0, 1, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-107 U(P(0,1,2)).directed.betweennessCentrality(normalized: false) is [0, 2, 0]: Unnormalized: twice the undirected value (ordered pairs, not halved)")
    func betweenness107() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.directed.betweennessCentrality(normalized: false)
        let expected: [Double] = [0, 2, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-108 U(0-1, 0-1, 1-2, 0-3, 3-2).betweennessCentrality(normalized: false) is [0.666666666667, 0.666666666667, 0.333333333333, 0.333333333333]")
    func betweenness108() {
        // U: 0-1, 0-1, 1-2, 0-3, 3-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (0, 3), (3, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [
            0.6666666666666666, 0.6666666666666666, 0.3333333333333333, 0.3333333333333333
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-109 U(P(0,1,2), 1-1).betweennessCentrality() is [0, 1, 0]: A self-loop is on no shortest path")
    func betweenness109() {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0, 1, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-110 U(K(5)).betweennessCentrality() is [0, 0, 0, 0, 0]")
    func betweenness110() {
        // U: K(5)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0, 0, 0, 0, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-111 U(KB(0..1;2..4)).betweennessCentrality() is [0.25, 0.0555555555556, 0.0555555555556, 0.0555555555556, 0.25]")
    func betweenness111() {
        // U: KB(0..1;2..4)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = ReferencePseudograph(vertices: [0, 2, 3, 4, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [
            0.25, 0.05555555555555555, 0.05555555555555555, 0.05555555555555555, 0.25
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-112 U(P(0,1,2,3)).betweennessCentrality(weight: [1, 2, 3]) is [0, 0.666666666667, 0.666666666667, 0]")
    func betweenness112() {
        // U: P(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3]
        let result = graph.betweennessCentrality(weight: { w[$0] })
        let expected: [Double] = [0, 0.6666666666666666, 0.6666666666666666, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-113 U(C(0,1,2,3)).betweennessCentrality(normalized: false, weight: [1, 1, 1, 3]) is [0, 1.5, 1.5, 0]: 0 → 3 ties at 3: direct, and through 1, 2")
    func betweenness113() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1, 3]
        let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
        let expected: [Double] = [0, 1.5, 1.5, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] }, normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-114 U(0-1, 1-2, 0-3, 3-2).betweennessCentrality(normalized: false, weight: [0.1, 0.2, 0.15, 0.15]) is [1, 0, 0, 1]")
    func betweenness114() {
        // U: 0-1, 1-2, 0-3, 3-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.1, 0.2, 0.15, 0.15]
        let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
        let expected: [Double] = [1, 0, 0, 1]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] }, normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-118 D(C(0,1,2,3)).betweennessCentrality(normalized: false, weight: [1, 1, 1, 1]) is [3, 3, 3, 3]: Unit weights: CE-104")
    func betweenness118() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 1, 1, 1]
        let result = graph.betweennessCentrality(weight: { w[$0] }, normalized: false)
        let expected: [Double] = [3, 3, 3, 3]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }

    @Test("CE-119 U(nx(karate_club)).betweennessCentrality(weight: e%3+1) is 34 scores, [0.458333333333, 0.0915404040404, …]")
    func betweenness119() {
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
        let w = (0 ..< 78).map { $0 % 3 + 1 }
        let result = graph.betweennessCentrality(weight: { w[$0] })
        let expected: [Double] = [
            0.4583333333333333, 0.09154040404040406, 0.10022095959595959, 0.024936868686868684,
            0.05681818181818182, 0.058712121212121215, 0, 0, 0.0006944444444444445, 0, 0, 0,
            0.005050505050505049, 0.03630050505050505, 0, 0.0006944444444444445, 0, 0, 0,
            0.012626262626262628, 0, 0, 0, 0.05782828282828283, 0.0211489898989899, 0, 0,
            0.010416666666666668, 0.013257575757575758, 0.03188131313131313, 0, 0.32077020202020207,
            0.22885101010101008, 0.25331439393939387
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-120 U(nx(florentine_families)).betweennessCentrality(endpoints: true) is 15 scores, [0.133333333333, 0.585714285714, …]")
    func betweenness120() {
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
        let result = graph.betweennessCentrality(endpoints: true)
        let expected: [Double] = [
            0.13333333333333336, 0.5857142857142857, 0.18095238095238098, 0.1523809523809524,
            0.22222222222222227, 0.2142857142857143, 0.23174603174603178, 0.21269841269841272,
            0.3174603174603175, 0.2571428571428572, 0.13333333333333336, 0.22380952380952382,
            0.353968253968254, 0.13333333333333336, 0.13333333333333336
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.betweennessCentrality(endpoints: true)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-121 D(0>1, 0>2, 1>3, 2>3, 3>4).betweennessCentrality(normalized: false) is [0, 1, 1, 3, 0]: Diamond then tail: σ(0, 3) = 2")
    func betweenness121() {
        // D: 0>1, 0>2, 1>3, 2>3, 3>4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality(normalized: false)
        let expected: [Double] = [0, 1, 1, 3, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
    }
}
