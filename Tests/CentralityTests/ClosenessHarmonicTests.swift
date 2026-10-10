// §C: closeness with and without the Wasserman–Faust factor, harmonic (not normalized), incoming
// distances d(v, u) on directed graphs, `Int` and `Double` weights (zeros allowed), isolated
// vertices, loops and parallel copies changing no distance, and the one-vertex forms. Every vector
// row also checks each `closenessCentrality(of:)` / `harmonicCentrality(of:)` against the vector.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Closeness and harmonic")
struct ClosenessHarmonicTests {
    @Test("CE-050 U(P(0..4)).closenessCentrality() is [0.4, 0.571428571429, 0.666666666667, 0.571428571429, 0.4]: (n − 1)/Σd")
    func closeness050() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [0.4, 0.5714285714285714, 0.6666666666666666, 0.5714285714285714, 0.4]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-051 U(P(0,1,2), 3-4).closenessCentrality() is [0.333333333333, 0.5, 0.333333333333, 0.25, 0.25]")
    func closeness051() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [0.3333333333333333, 0.5, 0.3333333333333333, 0.25, 0.25]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-052 U(P(0,1,2), 3-4).closenessCentrality(wfImproved: false) is [0.666666666667, 1, 0.666666666667, 1, 1]: Per component: K₂ scores 1, as P₃'s middle")
    func closeness052() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality(wfImproved: false)
        let expected: [Double] = [0.6666666666666666, 1, 0.6666666666666666, 1, 1]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v, wfImproved: false)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality(wfImproved: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-053 U([0..3] P(0,1,2)).closenessCentrality() is [0.444444444444, 0.666666666667, 0.444444444444, 0]: Isolated vertex: Σd = 0 gives 0")
    func closeness053() {
        // U: [0..3] P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [0.4444444444444444, 0.6666666666666666, 0.4444444444444444, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-054 D(P(0,1,2)).closenessCentrality() is [0, 0.5, 0.666666666667]: Incoming distances d(v, u) (NetworkX): the source scores 0")
    func closeness054() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [0, 0.5, 0.6666666666666666]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
    }

    @Test("CE-055 D(P(0,1,2)).closenessCentrality(wfImproved: false) is [0, 1, 0.666666666667]")
    func closeness055() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.closenessCentrality(wfImproved: false)
        let expected: [Double] = [0, 1, 0.6666666666666666]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v, wfImproved: false)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
    }

    @Test("CE-056 D(S(0;1..3)).closenessCentrality() is [0, 0.333333333333, 0.333333333333, 0.333333333333]: Arcs out of the hub: the leaves are reached, the hub is not")
    func closeness056() {
        // D: S(0;1..3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [0, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
    }

    @Test("CE-057 U(nx(krackhardt_kite)).closenessCentrality() is 10 scores, [0.529411764706, 0.529411764706, …]: Krackhardt 1990's kite, the standard closeness/betweenness contrast")
    func closeness057() {
        // U: nx(krackhardt_kite)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5),
            (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [
            0.5294117647058824, 0.5294117647058824, 0.5, 0.6, 0.5, 0.6428571428571429,
            0.6428571428571429, 0.6, 0.42857142857142855, 0.3103448275862069
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
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-058 U(nx(florentine_families)).closenessCentrality() is 15 scores, [0.368421052632, 0.56, …]: NetworkX test values")
    func closeness058() {
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
        let result = graph.closenessCentrality()
        let expected: [Double] = [
            0.3684210526315789, 0.56, 0.3888888888888889, 0.3684210526315789, 0.4375, 0.4375, 0.5,
            0.4827586206896552, 0.4827586206896552, 0.3888888888888889, 0.2857142857142857, 0.4,
            0.4666666666666667, 0.3333333333333333, 0.32558139534883723
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
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-059 U(nx(karate_club)).closenessCentrality() is 34 scores, [0.568965517241, 0.485294117647, …]")
    func closeness059() {
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
        let result = graph.closenessCentrality()
        let expected: [Double] = [
            0.5689655172413793, 0.4852941176470588, 0.559322033898305, 0.4647887323943662,
            0.3793103448275862, 0.38372093023255816, 0.38372093023255816, 0.44, 0.515625,
            0.4342105263157895, 0.3793103448275862, 0.36666666666666664, 0.3707865168539326, 0.515625,
            0.3707865168539326, 0.3707865168539326, 0.28448275862068967, 0.375, 0.3707865168539326, 0.5,
            0.3707865168539326, 0.375, 0.3707865168539326, 0.39285714285714285, 0.375, 0.375,
            0.3626373626373626, 0.4583333333333333, 0.4520547945205479, 0.38372093023255816,
            0.4583333333333333, 0.5409836065573771, 0.515625, 0.55
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
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-060 U(P(0,1,2,3)).closenessCentrality(weight: [1, 2, 3]) is [0.3, 0.375, 0.375, 0.214285714286]: Integer weights, sums converted to Double after the search")
    func closeness060() {
        // U: P(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3]
        let result = graph.closenessCentrality(weight: { w[$0] })
        let expected: [Double] = [0.3, 0.375, 0.375, 0.21428571428571427]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v, weight: { w[$0] })
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-061 U(C(0,1,2,3)).closenessCentrality(weight: [1.5, 0.5, 2.0, 1.0]) is [0.666666666667, 0.666666666667, 0.666666666667, 0.545454545455]")
    func closeness061() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.5, 0.5, 2, 1]
        let result = graph.closenessCentrality(weight: { w[$0] })
        let expected: [Double] = [
            0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.5454545454545454
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
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v, weight: { w[$0] })
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-062 U(P(0,1,2)).closenessCentrality(weight: [0, 1]) is [2, 2, 1]: Zero weights allowed: d(0, 1) = 0 adds nothing to Σd")
    func closeness062() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [0, 1]
        let result = graph.closenessCentrality(weight: { w[$0] })
        let expected: [Double] = [2, 2, 1]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v, weight: { w[$0] })
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-065 U(P(0..4)).closenessCentrality(of: 2) is #0.666666666667: One search")
    func closeness065() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.closenessCentrality(of: 2)
        let expected: Double = 0.6666666666666666
        let error = abs(value - expected)
        #expect(error <= 1e-12 * max(1, abs(expected)))
        let all = graph.closenessCentrality()
        let fromAll = all.score(of: 2)
        let difference = abs(value - fromAll)
        #expect(difference <= 1e-12 * max(1, abs(expected)))
    }

    @Test("CE-066 D(P(0,1,2)).closenessCentrality(of: 0) is #0: Nothing reaches the source")
    func closeness066() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let value = graph.closenessCentrality(of: 0)
        let expected: Double = 0
        let error = abs(value - expected)
        #expect(error <= 1e-12 * max(1, abs(expected)))
        let all = graph.closenessCentrality()
        let fromAll = all.score(of: 0)
        let difference = abs(value - fromAll)
        #expect(difference <= 1e-12 * max(1, abs(expected)))
    }

    @Test("CE-067 U(0-1, 0-1, 1-1, 1-2).closenessCentrality() is [0.666666666667, 1, 0.666666666667]: Loops and parallel copies change no distance: as P₃")
    func closeness067() {
        // U: 0-1, 0-1, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality()
        let expected: [Double] = [0.6666666666666666, 1, 0.6666666666666666]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.closenessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-068 U(P(0,1,2)).directed.closenessCentrality() is [0.666666666667, 1, 0.666666666667]: Same as undirected")
    func closeness068() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.directed.closenessCentrality()
        let expected: [Double] = [0.6666666666666666, 1, 0.6666666666666666]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.directed.vertices {
            let one = graph.directed.closenessCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
    }

    @Test("CE-070 U(P(0..4)).harmonicCentrality() is [2.08333333333, 2.83333333333, 3, 2.83333333333, 2.08333333333]: Σ 1/d, not normalized (NetworkX")
    func harmonic070() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.harmonicCentrality()
        let expected: [Double] = [
            2.0833333333333335, 2.8333333333333335, 3, 2.8333333333333335, 2.0833333333333335
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
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.harmonicCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-071 U(P(0,1,2), 3-4).harmonicCentrality() is [1.5, 2, 1.5, 1, 1]: Unreachable vertices contribute 0: no Wasserman–Faust needed")
    func harmonic071() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.harmonicCentrality()
        let expected: [Double] = [1.5, 2, 1.5, 1, 1]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.harmonicCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-072 D(P(0,1,2)).harmonicCentrality() is [0, 1, 1.5]: Incoming, as closeness (NetworkX)")
    func harmonic072() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.harmonicCentrality()
        let expected: [Double] = [0, 1, 1.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
    }

    @Test("CE-073 D(C(0,1,2), 2>3).harmonicCentrality() is [1.5, 1.5, 1.5, 1.83333333333]")
    func harmonic073() {
        // D: C(0,1,2), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.harmonicCentrality()
        let expected: [Double] = [1.5, 1.5, 1.5, 1.8333333333333333]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
    }

    @Test("CE-074 U(nx(karate_club)).harmonicCentrality() is 34 scores, [23.1666666667, 19.1666666667, …]")
    func harmonic074() {
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
        let result = graph.harmonicCentrality()
        let expected: [Double] = [
            23.166666666666668, 19.166666666666668, 21, 17.666666666666668, 14.666666666666666,
            15.166666666666666, 15.166666666666666, 16.416666666666668, 18.5, 15.583333333333334,
            14.666666666666666, 13.5, 14, 18.5, 14.2, 14.2, 11.1, 14.166666666666666, 14.2, 17.5, 14.2,
            14.166666666666666, 14.2, 16.033333333333335, 13.916666666666666, 13.916666666666666, 13.95,
            16.916666666666668, 16.416666666666668, 15.366666666666667, 16.916666666666668,
            19.333333333333332, 20.916666666666668, 23.25
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
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.harmonicCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-075 U(nx(florentine_families)).harmonicCentrality() is 15 scores, [5.91666666667, 9.5, …]")
    func harmonic075() {
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
        let result = graph.harmonicCentrality()
        let expected: [Double] = [
            5.916666666666667, 9.5, 6.916666666666667, 6.783333333333333, 7.833333333333333,
            7.083333333333333, 8, 7.833333333333333, 7.833333333333333, 6.583333333333333,
            4.766666666666667, 7.2, 8.083333333333334, 5.333333333333333, 5.366666666666666
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
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v)
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.harmonicCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-076 U(P(0,1,2)).harmonicCentrality(weight: [0, 1]) is [1, 1, 2]: A zero distance to another vertex is skipped (NetworkX), not 1/0")
    func harmonic076() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [0, 1]
        let result = graph.harmonicCentrality(weight: { w[$0] })
        let expected: [Double] = [1, 1, 2]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v, weight: { w[$0] })
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.harmonicCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-077 U(C(0,1,2,3)).harmonicCentrality(weight: [1.5, 0.5, 2.0, 1.0]) is [2.16666666667, 3.06666666667, 3, 1.9]")
    func harmonic077() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.5, 0.5, 2, 1]
        let result = graph.harmonicCentrality(weight: { w[$0] })
        let expected: [Double] = [2.1666666666666665, 3.0666666666666664, 3, 1.9]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        for v in graph.vertices {
            let one = graph.harmonicCentrality(of: v, weight: { w[$0] })
            let difference = abs(one - result.score(of: v))
            #expect(difference <= 1e-12 * max(1, abs(one)), "vertex \(v)")
        }
        let arcs = graph.directed.harmonicCentrality(weight: { w[$0.position] })
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-078 U(P(0..4)).harmonicCentrality(of: 0) is #2.08333333333")
    func harmonic078() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.harmonicCentrality(of: 0)
        let expected: Double = 2.0833333333333335
        let error = abs(value - expected)
        #expect(error <= 1e-12 * max(1, abs(expected)))
        let all = graph.harmonicCentrality()
        let fromAll = all.score(of: 0)
        let difference = abs(value - fromAll)
        #expect(difference <= 1e-12 * max(1, abs(expected)))
    }

    @Test("CE-079 D(C(0,1,2), 2>3).harmonicCentrality(of: 3) is #1.83333333333")
    func harmonic079() {
        // D: C(0,1,2), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let value = graph.harmonicCentrality(of: 3)
        let expected: Double = 1.8333333333333333
        let error = abs(value - expected)
        #expect(error <= 1e-12 * max(1, abs(expected)))
        let all = graph.harmonicCentrality()
        let fromAll = all.score(of: 3)
        let difference = abs(value - fromAll)
        #expect(difference <= 1e-12 * max(1, abs(expected)))
    }
}
