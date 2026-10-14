// §I: edge betweenness (Brandes' edge accumulation) with its rescaling, parallel copies sharing
// their pairs' paths, self-loops scoring 0, weights with ties by exact equality; and vertex and
// edge betweenness estimated from pivots (Brandes and Pich), a lone pivot's own estimate NaN.
// Edge rows read each score by position, and on `graph.directedView` an edge's two arcs add up
// to its value (twice it unnormalized).
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directedView` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Edge betweenness and pivots")
struct EdgeBetweennessTests {
    @Test("CE-207 U(P(0..4)).edgeBetweennessCentrality() is [0.4, 0.6, 0.6, 0.4]: Normalized (default): ÷ n(n − 1)/2 pairs")
    func edgeBetweenness207() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = [0.4, 0.6000000000000001, 0.6000000000000001, 0.4]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality()
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-208 U(P(0..4)).edgeBetweennessCentrality(normalized: false) is [4, 6, 6, 4]: Unordered pairs: each edge separates i + 1 from 4 − i vertices")
    func edgeBetweenness208() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [4, 6, 6, 4]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-209 U(C(0,1,2,3)).edgeBetweennessCentrality(normalized: false) is [2, 2, 2, 2]: Opposite pairs split ½ ½")
    func edgeBetweenness209() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [2, 2, 2, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-210 U(0-1, 1-2, 0-2, 2-3, 3-4, 4-5, 3-5).edgeBetweennessCentrality(normalized: false) is [1, 4, 4, 9, 4, 1, 4]: Two triangles and a bridge: the bridge carries all 9 crossing pairs")
    func edgeBetweenness210() {
        // U: 0-1, 1-2, 0-2, 2-3, 3-4, 4-5, 3-5
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (4, 5), (3, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [1, 4, 4, 9, 4, 1, 4]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-211 U(nx(krackhardt_kite)).edgeBetweennessCentrality() is 18 scores, [0.0592592592593, 0.0333333333333, …]: NetworkX agrees")
    func edgeBetweenness211() {
        // U: nx(krackhardt_kite)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5),
            (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = [
            0.05925925925925925, 0.03333333333333333, 0.040740740740740744, 0.1037037037037037,
            0.040740740740740744, 0.03333333333333333, 0.1037037037037037, 0.06666666666666667, 0.1,
            0.06666666666666667, 0.07407407407407408, 0.07407407407407407, 0.1, 0.05925925925925926,
            0.23333333333333334, 0.23333333333333334, 0.35555555555555557, 0.2
        ]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality()
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-212 U(nx(karate_club)).edgeBetweennessCentrality() is 78 scores, [0.0252525252525, 0.0777876807289, …]")
    func edgeBetweenness212() {
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
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = [
            0.025252525252525245, 0.0777876807288572, 0.02049910873440285, 0.0522875816993464,
            0.07813428401663694, 0.07813428401663695, 0.0228206434088787, 0.07423959482783014,
            0.0522875816993464, 0.058823529411764705, 0.04652406417112298, 0.04237189825425121,
            0.04012392835922248, 0.045936960642843, 0.040123928359222474, 0.12725999490705373,
            0.023232323232323233, 0.0077243018419489, 0.007422969187675069, 0.012405568287921232,
            0.01869960105254222, 0.014633732280791106, 0.018699601052542224, 0.032280791104320514,
            0.022430184194890075, 0.02521432815550462, 0.009175791528732704, 0.030803836686189634,
            0.007630931160342923, 0.04119203236850297, 0.022782446311858072, 0.06898678663384543,
            0.003365588659706307, 0.012299465240641707, 0.01492233256939139, 0.0047534165181224,
            0.0029708853238265, 0.0029708853238265003, 0.0047534165181224, 0.029411764705882353,
            0.029411764705882353, 0.00980392156862745, 0.0304416716181422, 0.04043657867187279,
            0.029615482556659026, 0.06782389723566191, 0.024083977025153493, 0.0347395523866112,
            0.024083977025153493, 0.0347395523866112, 0.024083977025153493, 0.0347395523866112,
            0.0593823387941035, 0.024083977025153493, 0.0347395523866112, 0.024083977025153493,
            0.03473955238661121, 0.019776193305605066, 0.010536739948504653, 0.00665478312537136,
            0.022341057635175274, 0.03266983561101209, 0.0042186571598336305, 0.018657159833630418,
            0.040106951871657755, 0.04205783323430382, 0.004532722179781003, 0.0542908072319837,
            0.030477039300568713, 0.0148544266191325, 0.024564977506153975, 0.023328523328523323,
            0.029807882749059215, 0.01705288175876411, 0.02681436210847975, 0.04143394731630025,
            0.05339388280564751, 0.008225108225108226
        ]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality()
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-213 D(P(0,1,2)).edgeBetweennessCentrality() is [0.333333333333, 0.333333333333]: Directed normalized: ÷ n(n − 1) ordered pairs")
    func edgeBetweenness213() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = [0.3333333333333333, 0.3333333333333333]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-214 D(P(0,1,2)).edgeBetweennessCentrality(normalized: false) is [2, 2]: Ordered pairs, not halved")
    func edgeBetweenness214() {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [2, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-215 D(C(0,1,2,3)).edgeBetweennessCentrality(normalized: false) is [6, 6, 6, 6]")
    func edgeBetweenness215() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [6, 6, 6, 6]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-216 U(0-1, 0-1, 1-2).edgeBetweennessCentrality(normalized: false) is [1, 1, 2]: Parallel copies share their pairs' paths equally (NetworkX's MultiGraph split agrees here)")
    func edgeBetweenness216() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [1, 1, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-217 D(0>1, 0>1, 1>2).edgeBetweennessCentrality(normalized: false) is [1, 1, 2]")
    func edgeBetweenness217() {
        // D: 0>1, 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [1, 1, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-218 U(P(0,1,2), 1-1).edgeBetweennessCentrality(normalized: false) is [2, 2, 0]: A self-loop scores 0")
    func edgeBetweenness218() {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [2, 2, 0]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-219 U(P(0,1,2), 3-4).edgeBetweennessCentrality() is [0.2, 0.2, 0.1]: Unreachable pairs add nothing")
    func edgeBetweenness219() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = [0.2, 0.2, 0.1]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality()
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-220 U([]).edgeBetweennessCentrality() is []")
    func edgeBetweenness220() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = []
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality()
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-221 U(0-0).edgeBetweennessCentrality() is [0]: n < 2: nothing is scaled")
    func edgeBetweenness221() {
        // U: 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality()
        let expected: [Double] = [0]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality()
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-222 U(P(0,1,2)).directedView.edgeBetweennessCentrality(normalized: false) is [2, 2, 2, 2]: Each arc its direction's ordered pairs")
    func edgeBetweenness222() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.directedView.edgeBetweennessCentrality(normalized: false)
        let expected: [Double] = [2, 2, 2, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.directedView.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.directedView.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-223 U(C(0,1,2,3)).edgeBetweennessCentrality(normalized: false, weight: [1, 1, 1, 3]) is [2.5, 3.5, 2.5, 0.5]: 0 → 3 ties at 3: direct, and through 1, 2")
    func edgeBetweenness223() {
        // U: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1, 3]
        let result = graph.edgeBetweennessCentrality(weight: { w[$0] }, normalized: false)
        let expected: [Double] = [2.5, 3.5, 2.5, 0.5]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(weight: { w[$0.position] }, normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-224 U(0-1, 1-2, 0-3, 3-2).edgeBetweennessCentrality(normalized: false, weight: [0.1, 0.2, 0.15, 0.15]) is [2, 1, 3, 2]: Exact equality of sums: 0.1 + 0.2 > 0.15 + 0.15, so 0 → 2 has one shortest path")
    func edgeBetweenness224() {
        // U: 0-1, 1-2, 0-3, 3-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.1, 0.2, 0.15, 0.15]
        let result = graph.edgeBetweennessCentrality(weight: { w[$0] }, normalized: false)
        let expected: [Double] = [2, 1, 3, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(weight: { w[$0.position] }, normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-225 D(0>1, 1>2, 0>2).edgeBetweennessCentrality(normalized: false, weight: [1, 1, 2]) is [1.5, 1.5, 0.5]: 0 → 2 ties: the arc and the two-step path, ½ each")
    func edgeBetweenness225() {
        // D: 0>1, 1>2, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 1, 2]
        let result = graph.edgeBetweennessCentrality(weight: { w[$0] }, normalized: false)
        let expected: [Double] = [1.5, 1.5, 0.5]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-226 U(nx(karate_club)).edgeBetweennessCentrality(weight: e%3+1) is 78 scores, [0.0776886512181, 0.0332739156269, …]")
    func edgeBetweenness226() {
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
        let result = graph.edgeBetweennessCentrality(weight: { w[$0] })
        let expected: [Double] = [
            0.07768865121806297, 0.033273915626856804, 0.004753416518122399, 0.10695187165775401,
            0.10695187165775401, 0.0516934046345811, 0.03683897801544861, 0.0225787284610814, 0,
            0.058823529411764705, 0.03832442067736185, 0.0071301247771836, 0.058823529411764705,
            0.011734997029114676, 0.017231134878193697, 0.2887700534759358, 0.016785502079619725,
            0.00267379679144385, 0.0148544266191325, 0.025252525252525245, 0, 0.03743315508021391,
            0.04159239453357099, 0.0148544266191325, 0.04604872251931075, 0.006238859180035651,
            0.00267379679144385, 0.049910873440285206, 0.00920974450386215, 0.013071895424836598,
            0.024212715389185978, 0.046048722519310754, 0.00089126559714795, 0.030005941770647648,
            0.0213903743315508, 0.0035650623885918, 0.0552584670231729, 0.0017825311942959,
            0.0035650623885918, 0.0570409982174688, 0.0017825311942959, 0.00089126559714795,
            0.02204396910279263, 0.01194295900178253, 0.0089126559714795, 0.0641711229946524,
            0.0463458110516934, 0.012477718360071301, 0.046999405822935235, 0.01313131313131313,
            0.0017825311942959, 0.0570409982174688, 0.03342245989304812, 0.0017825311942959,
            0.0570409982174688, 0.0463458110516934, 0.012477718360071301, 0.04486036838978015,
            0.0160427807486631, 0.0029708853238265, 0.08116458704693998, 0.02263814616755793,
            0.0017825311942959, 0.031491384432560894, 0.06535947712418301, 0.01218062982768865,
            0.03178847296494355, 0.027035056446821155, 0.017825311942959, 0.04486036838978015,
            0.014705882352941176, 0.0035650623885918, 0.08051099227569815, 0.032382650029708845,
            0.0106951871657754, 0.16048722519310754, 0.09096850861556742, 0.0006535947712418301
        ]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(weight: { w[$0.position] })
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-229 U(P(0..4)).betweennessCentrality(pivots: [0, 2]) is [0, 0.666666666667, 0.666666666667, 0.333333333333, 0]")
    func betweenness229() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [0, 2])
        let expected: [Double] = [0, 0.6666666666666666, 0.6666666666666666, 0.3333333333333333, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directedView.betweennessCentrality(pivots: [0, 2])
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-230 U(P(0..4)).betweennessCentrality(normalized: false, pivots: [0, 2]) is [0, 4, 4, 2, 0]")
    func betweenness230() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [0, 2], normalized: false)
        let expected: [Double] = [0, 4, 4, 2, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directedView.betweennessCentrality(pivots: [0, 2], normalized: false)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-231 U(P(0..4)).betweennessCentrality(endpoints: true, pivots: [2, 0]) is [0.625, 0.75, 0.875, 0.5, 0.25]: With endpoints N = n and every vertex is scaled by N/k")
    func betweenness231() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [2, 0], endpoints: true)
        let expected: [Double] = [0.625, 0.75, 0.875, 0.5, 0.25]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directedView.betweennessCentrality(pivots: [2, 0], endpoints: true)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-232 U(P(0..4)).betweennessCentrality(normalized: false, endpoints: true, pivots: [0, 2]) is [6.25, 7.5, 8.75, 5, 2.5]")
    func betweenness232() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [0, 2], normalized: false, endpoints: true)
        let expected: [Double] = [6.25, 7.5, 8.75, 5, 2.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directedView.betweennessCentrality(pivots: [0, 2], normalized: false, endpoints: true)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-233 U(P(0..4)).betweennessCentrality(pivots: [2]) is [0, 0.333333333333, nan, 0.333333333333, 0]: One pivot: its own estimate is 0/0 (NaN), as in NetworkX")
    func betweenness233() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [2])
        let expected: [Double] = [0, 0.3333333333333333, .nan, 0.3333333333333333, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            if value.isNaN {
                #expect(result.score(ofIndex: i).isNaN, "index \(i)")
                continue
            }
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex.map(\.bitPattern) == result.scores.map(\.bitPattern))
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex.map(\.bitPattern) == result.scores.map(\.bitPattern))
        let arcs = graph.directedView.betweennessCentrality(pivots: [2])
        for (i, value) in expected.enumerated() {
            if value.isNaN {
                #expect(arcs.score(ofIndex: i).isNaN, "graph.directedView, index \(i)")
                continue
            }
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-234 U(P(0..4)).betweennessCentrality(pivots: [0, 1, 2, 3, 4]) is [0, 0.5, 0.666666666667, 0.5, 0]: Every vertex a pivot: CE-090")
    func betweenness234() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [0, 1, 2, 3, 4])
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
        let arcs = graph.directedView.betweennessCentrality(pivots: [0, 1, 2, 3, 4])
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-235 U(P(0..4)).edgeBetweennessCentrality(pivots: [0, 2]) is [0.625, 0.625, 0.5, 0.25]: Edges: scaled by n/k, ÷ k(n − 1) when normalized")
    func edgeBetweenness235() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(pivots: [0, 2])
        let expected: [Double] = [0.625, 0.625, 0.5, 0.25]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(pivots: [0, 2])
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-236 U(P(0..4)).edgeBetweennessCentrality(normalized: false, pivots: [0, 2]) is [6.25, 6.25, 5, 2.5]")
    func edgeBetweenness236() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.edgeBetweennessCentrality(pivots: [0, 2], normalized: false)
        let expected: [Double] = [6.25, 6.25, 5, 2.5]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(pivots: [0, 2], normalized: false)
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - 2 * expected[e])
            #expect(error <= 1e-12 * max(1, abs(2 * expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-237 D(C(0,1,2,3)).betweennessCentrality(pivots: [0, 1]) is [0, 1, 0.75, 0.25]")
    func betweenness237() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality(pivots: [0, 1])
        let expected: [Double] = [0, 1, 0.75, 0.25]
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

    @Test("CE-238 D(C(0,1,2,3)).betweennessCentrality(normalized: false, pivots: [0, 1]) is [0, 6, 4.5, 1.5]")
    func betweenness238() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.betweennessCentrality(pivots: [0, 1], normalized: false)
        let expected: [Double] = [0, 6, 4.5, 1.5]
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

    @Test("CE-239 D(C(0,1,2,3)).edgeBetweennessCentrality(normalized: false, pivots: [1, 0]) is [6, 10, 6, 2]")
    func edgeBetweenness239() {
        // D: C(0,1,2,3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.edgeBetweennessCentrality(pivots: [1, 0], normalized: false)
        let expected: [Double] = [6, 10, 6, 2]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
    }

    @Test("CE-240 U(nx(karate_club)).betweennessCentrality(pivots: [0, 5, 10, 33]) is 34 scores, [0.675992063492, 0.0200892857143, …]")
    func betweenness240() {
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
        let result = graph.betweennessCentrality(pivots: [0, 5, 10, 33])
        let expected: [Double] = [
            0.6759920634920633, 0.020089285714285712, 0.09505208333333333, 0.0021205357142857146,
            0.0026041666666666665, 0.024305555555555552, 0.010416666666666666, 0, 0.09652157738095238,
            0.0018601190476190475, 0.003472222222222222, 0, 0, 0.06962425595238095, 0, 0, 0, 0, 0,
            0.057831101190476186, 0, 0, 0, 0.00390625, 0, 0.0026041666666666665, 0,
            0.008370535714285714, 0.0018601190476190475, 0, 0.005394345238095237, 0.151953125,
            0.06994047619047618, 0.152281746031746
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
        let arcs = graph.directedView.betweennessCentrality(pivots: [0, 5, 10, 33])
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-241 U(nx(karate_club)).edgeBetweennessCentrality(pivots: [0, 5, 10, 33]) is 78 scores, [0.0340909090909, 0.111652236652, …]")
    func edgeBetweenness241() {
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
        let result = graph.edgeBetweennessCentrality(pivots: [0, 5, 10, 33])
        let expected: [Double] = [
            0.03409090909090909, 0.11165223665223666, 0.022727272727272728, 0.017676767676767676,
            0.24494949494949492, 0.025252525252525252, 0.024891774891774892, 0.11452020202020202,
            0.23737373737373738, 0.030303030303030304, 0.028787878787878786, 0.07357503607503608,
            0.027056277056277056, 0.07357503607503608, 0.027056277056277056, 0.1625, 0, 0,
            0.0016233766233766233, 0.00523088023088023, 0.0032467532467532465, 0.00523088023088023,
            0.0032467532467532465, 0.016594516594516592, 0, 0.0032467532467532465,
            0.0018037518037518038, 0.024531024531024532, 0.0018037518037518038, 0.02705627705627706,
            0.013167388167388168, 0.031385281385281384, 0.0005411255411255411, 0.0015151515151515154,
            0.009632034632034632, 0.00505050505050505, 0.012626262626262626, 0.012626262626262626,
            0.027777777777777773, 0.022727272727272728, 0.007575757575757576, 0.011363636363636364,
            0.029581529581529577, 0.060227272727272727, 0.00937950937950938, 0.07509018759018758,
            0.00974025974025974, 0.020562770562770564, 0.00974025974025974, 0.020562770562770564,
            0.00974025974025974, 0.020562770562770564, 0.06365440115440116, 0.00974025974025974,
            0.020562770562770564, 0.00974025974025974, 0.020562770562770564, 0.006313131313131313,
            0.002525252525252525, 0, 0.007575757575757576, 0.021464646464646464, 0,
            0.003787878787878788, 0.026515151515151516, 0.029040404040404044, 0, 0.030303030303030304,
            0.013167388167388168, 0.011363636363636364, 0.00937950937950938, 0.00974025974025974,
            0.020562770562770564, 0, 0.012806637806637806, 0.029581529581529577, 0.0659992784992785,
            0.00937950937950938
        ]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(pivots: [0, 5, 10, 33])
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-242 U(nx(karate_club)).betweennessCentrality(weight: e%3+1, pivots: [0, 5, 10, 33]) is 34 scores, [0.670138888889, 0.0598958333333, …]")
    func betweenness242() {
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
        let result = graph.betweennessCentrality(weight: { w[$0] }, pivots: [0, 5, 10, 33])
        let expected: [Double] = [
            0.6701388888888888, 0.05989583333333333, 0.03125, 0.0078125, 0.25, 0.03125, 0, 0, 0.0015625,
            0, 0, 0, 0.0078125, 0.029947916666666664, 0, 0.0015625, 0, 0, 0, 0.010416666666666666, 0, 0,
            0, 0.02109375, 0.0234375, 0, 0, 0.00390625, 0.00390625, 0.015625, 0, 0.41041666666666665,
            0.1171875, 0.125
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
        let arcs = graph.directedView.betweennessCentrality(weight: { w[$0.position] }, pivots: [0, 5, 10, 33])
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-243 U(nx(karate_club)).edgeBetweennessCentrality(weight: e%3+1, pivots: [33, 0]) is 78 scores, [0.0454545454545, 0.0353535353535, …]")
    func edgeBetweenness243() {
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
        let result = graph.edgeBetweennessCentrality(weight: { w[$0] }, pivots: [33, 0])
        let expected: [Double] = [
            0.045454545454545456, 0.03535353535353535, 0.00505050505050505, 0.06060606060606061,
            0.06060606060606061, 0.030303030303030304, 0.0202020202020202, 0.015151515151515152, 0,
            0.030303030303030304, 0.0202020202020202, 0.007575757575757576, 0.030303030303030304,
            0.007575757575757576, 0.007575757575757576, 0.3611111111111111, 0, 0, 0.0101010101010101,
            0.027777777777777776, 0, 0.027777777777777776, 0.022727272727272728, 0.007575757575757576,
            0.00505050505050505, 0, 0, 0.015151515151515152, 0.007575757575757576, 0,
            0.007575757575757576, 0, 0, 0.0202020202020202, 0.030303030303030304, 0,
            0.030303030303030304, 0, 0, 0.030303030303030304, 0, 0, 0.0030303030303030307,
            0.01818181818181818, 0.015151515151515152, 0.07323232323232323, 0.015151515151515152,
            0.015151515151515152, 0.01818181818181818, 0.01818181818181818, 0, 0.030303030303030304,
            0.03535353535353535, 0, 0.030303030303030304, 0.015151515151515152, 0.015151515151515152,
            0.022727272727272728, 0, 0, 0.025757575757575757, 0.03333333333333334, 0,
            0.022727272727272728, 0.03787878787878788, 0.007575757575757576, 0.015151515151515152,
            0.015151515151515152, 0.022727272727272728, 0.015151515151515152, 0.022727272727272728, 0,
            0.045454545454545456, 0.007575757575757576, 0.015151515151515152, 0.09393939393939395,
            0.22777777777777775, 0.0030303030303030307
        ]
        #expect(result.scores.count == expected.count)
        for (e, position) in graph.edges.indices.enumerated() {
            let error = abs(result.score(ofEdgeAt: position) - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "edge \(e)")
        }
        let byPosition = graph.edges.indices.map { result.score(ofEdgeAt: $0) }
        #expect(byPosition == result.scores)
        let arcs = graph.directedView.edgeBetweennessCentrality(weight: { w[$0.position] }, pivots: [33, 0])
        for (e, position) in graph.edges.indices.enumerated() {
            let pair = arcs.score(ofEdgeAt: .init(position: position, reversed: false)) + arcs.score(ofEdgeAt: .init(position: position, reversed: true))
            let error = abs(pair - expected[e])
            #expect(error <= 1e-12 * max(1, abs(expected[e])), "graph.directedView, edge \(e)")
        }
    }

    @Test("CE-244 U(0-1, 0-1, 1-2).betweennessCentrality(pivots: [0]) is [nan, 1, 0]: Parallel copies count as distinct paths")
    func betweenness244() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(pivots: [0])
        let expected: [Double] = [.nan, 1, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            if value.isNaN {
                #expect(result.score(ofIndex: i).isNaN, "index \(i)")
                continue
            }
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex.map(\.bitPattern) == result.scores.map(\.bitPattern))
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex.map(\.bitPattern) == result.scores.map(\.bitPattern))
        let arcs = graph.directedView.betweennessCentrality(pivots: [0])
        for (i, value) in expected.enumerated() {
            if value.isNaN {
                #expect(arcs.score(ofIndex: i).isNaN, "graph.directedView, index \(i)")
                continue
            }
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }

    @Test("CE-248 U([]).betweennessCentrality(pivots: []) is []: No vertices: no pivots, an empty result")
    func betweenness248() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.betweennessCentrality(pivots: [])
        let expected: [Double] = []
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = graph.directedView.betweennessCentrality(pivots: [])
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directedView, index \(i)")
        }
    }
}
