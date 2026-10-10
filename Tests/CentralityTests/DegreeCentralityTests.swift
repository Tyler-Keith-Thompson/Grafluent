// §B: degree(of: v)/(n − 1), so a self-loop counts 2 and each parallel copy counts (the score can
// exceed 1); directed: in + out, in, out, a directed loop one in-arc and one out-arc;
// `graph.directed` doubles the undirected value.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Degree")
struct DegreeCentralityTests {
    @Test("CE-030 U(S(0;1..4)).degreeCentrality() is [1, 0.25, 0.25, 0.25, 0.25]")
    func degree030() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.degreeCentrality()
        let expected: [Double] = [1, 0.25, 0.25, 0.25, 0.25]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-031 U(P(0,1,2), 1-1).degreeCentrality() is [0.5, 2, 0.5]: A self-loop counts 2, as degree(of:)")
    func degree031() {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.degreeCentrality()
        let expected: [Double] = [0.5, 2, 0.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-032 U(0-1, 0-1, 1-2).degreeCentrality() is [1, 1.5, 0.5]: Parallel copies each count (NetworkX MultiGraph agrees)")
    func degree032() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.degreeCentrality()
        let expected: [Double] = [1, 1.5, 0.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-033 D(P(0,1,2)).degreeCentrality() is [0.5, 1, 0.5]: Directed: in + out")
    func degree033() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.degreeCentrality()
        let expected: [Double] = [0.5, 1, 0.5]
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

    @Test("CE-034 D(P(0,1,2)).inDegreeCentrality() is [0, 0.5, 0.5]")
    func inDegree034() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.inDegreeCentrality()
        let expected: [Double] = [0, 0.5, 0.5]
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

    @Test("CE-035 D(P(0,1,2)).outDegreeCentrality() is [0.5, 0.5, 0]")
    func outDegree035() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.outDegreeCentrality()
        let expected: [Double] = [0.5, 0.5, 0]
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

    @Test("CE-036 D(0>0, 0>1).inDegreeCentrality() is [1, 1]: A directed loop is one in-arc and one out-arc")
    func inDegree036() {
        // D: 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.inDegreeCentrality()
        let expected: [Double] = [1, 1]
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

    @Test("CE-037 D(0>0, 0>1).outDegreeCentrality() is [2, 0]")
    func outDegree037() {
        // D: 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.outDegreeCentrality()
        let expected: [Double] = [2, 0]
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

    @Test("CE-038 D([0..3] C(0,1,2)).degreeCentrality() is [0.666666666667, 0.666666666667, 0.666666666667, 0]: Isolated vertex")
    func degree038() {
        // D: [0..3] C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.degreeCentrality()
        let expected: [Double] = [0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0]
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

    @Test("CE-039 U(nx(karate_club)).degreeCentrality() is 34 scores, [0.484848484848, 0.272727272727, …]")
    func degree039() {
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
        let result = graph.degreeCentrality()
        let expected: [Double] = [
            0.48484848484848486, 0.2727272727272727, 0.30303030303030304, 0.18181818181818182,
            0.09090909090909091, 0.12121212121212122, 0.12121212121212122, 0.12121212121212122,
            0.15151515151515152, 0.06060606060606061, 0.09090909090909091, 0.030303030303030304,
            0.06060606060606061, 0.15151515151515152, 0.06060606060606061, 0.06060606060606061,
            0.06060606060606061, 0.06060606060606061, 0.06060606060606061, 0.09090909090909091,
            0.06060606060606061, 0.06060606060606061, 0.06060606060606061, 0.15151515151515152,
            0.09090909090909091, 0.09090909090909091, 0.06060606060606061, 0.12121212121212122,
            0.09090909090909091, 0.12121212121212122, 0.12121212121212122, 0.18181818181818182,
            0.36363636363636365, 0.5151515151515151
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
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-040 U(P(0,1,2)).directed.degreeCentrality() is [1, 2, 1]: Twice the undirected degree centrality ([0.5, 1, 0.5]): in + out over two arcs per edge")
    func degree040() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.directed.degreeCentrality()
        let expected: [Double] = [1, 2, 1]
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

    @Test("CE-041 D([0]).inDegreeCentrality() is [1]: One vertex: 1 (NetworkX)")
    func inDegree041() {
        // D: [0]
        let graph = ReferenceDirectedMultigraph<Int>(vertices: 0 ..< 1, edges: [])
        let result = graph.inDegreeCentrality()
        let expected: [Double] = [1]
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
