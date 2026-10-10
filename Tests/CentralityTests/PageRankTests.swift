// §G: PageRank with the damping factor, dangling vertices following the personalization, each
// undirected edge two arcs and a loop two loop arcs, parallel arcs adding, weights per row; nil with
// too few iterations.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("PageRank")
struct PageRankTests {
    @Test("CE-175 D(P(0,1,2)).pageRank() is [0.184416781927, 0.341171046565, 0.474412171508]: Dangling vertex 2 spreads its rank by the personalization (uniform)")
    func pageRank175() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.pageRank())
        let expected: [Double] = [0.18441678192715505, 0.3411710465652378, 0.47441217150760673]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-176 D(C(0,1,2)).pageRank() is [0.333333333333, 0.333333333333, 0.333333333333]")
    func pageRank176() throws {
        // D: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.pageRank())
        let expected: [Double] = [0.3333333333333333, 0.3333333333333333, 0.3333333333333333]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-177 D(0>1, 0>2, 1>2, 2>0, 3>2).pageRank() is [0.372526851328, 0.195823911815, 0.394149236857, 0.0375]")
    func pageRank177() throws {
        // D: 0>1, 0>2, 1>2, 2>0, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.pageRank())
        let expected: [Double] = [
            0.3725268513284352, 0.1958239118145841, 0.39414923685698067, 0.037500000000000006
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
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-178 D(P(0,1,2)).pageRank(personalization: [1, 0, 0]) is [0.388726919339, 0.330417881438, 0.280855199223]: igraph personalized_pagerank(reset=) agrees")
    func pageRank178() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let p: [Double] = [1, 0, 0]
        let result = try #require(graph.pageRank(personalization: { p[$0] }))
        let expected: [Double] = [0.38872691933916437, 0.33041788143829026, 0.2808551992225454]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-179 D(P(0,1,2)).pageRank(dampingFactor: 0.5) is [0.235294117647, 0.352941176471, 0.411764705882]")
    func pageRank179() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.pageRank(dampingFactor: 0.5))
        let expected: [Double] = [0.23529411764705863, 0.3529411764705885, 0.4117647058823528]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-180 U(nx(karate_club)).pageRank() is 34 scores, [0.0969972853883, 0.0528769240611, …]: Undirected: each edge two arcs")
    func pageRank180() throws {
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
        let result = try #require(graph.pageRank())
        let expected: [Double] = [
            0.09699728538830414, 0.05287692406114842, 0.0570785094884618, 0.03585985778641361,
            0.0219779523645932, 0.02911115467837563, 0.02911115467837563, 0.024490497035283804,
            0.029766056081016023, 0.01430939712903229, 0.0219779523645932, 0.009564745492136189,
            0.014644892011878227, 0.029536456151914494, 0.01453599399791999, 0.01453599399791999,
            0.016784005444192826, 0.014558677209022517, 0.01453599399791999, 0.019604636325653207,
            0.01453599399791999, 0.014558677209022517, 0.01453599399791999, 0.031522514776674566,
            0.02107603355922096, 0.02100619739449101, 0.015044038082724125, 0.02563976748284584,
            0.019573459463827398, 0.026288537695112, 0.02459015524857899, 0.03715808706914281,
            0.07169322600574758, 0.10091918233261697
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
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        let arcs = try #require(graph.directed.pageRank())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-181 U(S(0;1..4)).pageRank() is 5 scores, [0.475675675676, 0.131081081081, …]")
    func pageRank181() throws {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.pageRank())
        let expected: [Double] = [
            0.47567567567567465, 0.13108108108108138, 0.13108108108108138, 0.13108108108108138,
            0.13108108108108138
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
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        let arcs = try #require(graph.directed.pageRank())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-182 U(P(0,1,2), 1-1).pageRank() is [0.184210526316, 0.631578947368, 0.184210526316]: The loop is two arcs 1 → 1 (graph.directed's reading)")
    func pageRank182() throws {
        // U: P(0,1,2), 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.pageRank())
        let expected: [Double] = [0.1842105263157897, 0.6315789473684206, 0.1842105263157897]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
        let arcs = try #require(graph.directed.pageRank())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-183 D(0>1, 0>1, 0>2, 2>0, 1>0).pageRank() is [0.486486486486, 0.325675675676, 0.187837837838]: Parallel arcs add (NetworkX MultiDiGraph and igraph agree)")
    func pageRank183() throws {
        // D: 0>1, 0>1, 0>2, 2>0, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 2), (2, 0), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = try #require(graph.pageRank())
        let expected: [Double] = [0.4864864864864869, 0.3256756756756751, 0.18783783783783758]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-184 D(0>1, 0>2, 1>0, 2>0).pageRank(weight: [1.0, 3.0, 1.0, 1.0]) is [0.486486486486, 0.153378378378, 0.360135135135]: Out-weights normalized per row")
    func pageRank184() throws {
        // D: 0>1, 0>2, 1>0, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [1, 3, 1, 1]
        let result = try #require(graph.pageRank(weight: { w[$0] }))
        let expected: [Double] = [0.486486486486487, 0.15337837837837817, 0.3601351351351345]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-185 D(0>1, 1>2).pageRank(weight: [0.0, 1.0]) is [0.25974025974, 0.25974025974, 0.480519480519]: Zero out-weight: vertex 0 is dangling")
    func pageRank185() throws {
        // D: 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [0, 1]
        let result = try #require(graph.pageRank(weight: { w[$0] }))
        let expected: [Double] = [0.25974025974025955, 0.25974025974025955, 0.4805194805194806]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-186 U(nx(karate_club)).pageRank(maxIterations: 3) is nil: NetworkX raises with max_iter=3 too")
    func pageRank186() {
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
        #expect(graph.pageRank(maxIterations: 3) == nil)
        #expect(graph.directed.pageRank(maxIterations: 3) == nil)
    }

    @Test("CE-189 D([0..2]).pageRank(personalization: [1, 2, 1]) is [0.25, 0.5, 0.25]: No arcs: the personalization itself")
    func pageRank189() throws {
        // D: [0..2]
        let graph = ReferenceDirectedMultigraph<Int>(vertices: 0 ..< 3, edges: [])
        let p: [Double] = [1, 2, 1]
        let result = try #require(graph.pageRank(personalization: { p[$0] }))
        let expected: [Double] = [0.25, 0.5, 0.25]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }

    @Test("CE-190 U(P(0,1,2)).directed.pageRank() is [0.256756756757, 0.486486486486, 0.256756756757]: Same as undirected")
    func pageRank190() throws {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.directed.pageRank())
        let expected: [Double] = [0.256756756756757, 0.4864864864864858, 0.256756756756757]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12, "scores sum to 1")
    }
}
