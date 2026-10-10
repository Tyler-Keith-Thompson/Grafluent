// §H: hubs and authorities from the uniform start, each summing to 1; the limit from the uniform
// start where σ₁ is not simple; parallel arcs adding; weights; `graph.directed` on the karate club
// (hubs = authorities); nil after one iteration. Each test also checks that the other vector has
// one score per vertex.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("HITS")
struct HITSTests {
    @Test("CE-195 D(P(0,1,2)).hits().hubs is [0.5, 0.5, 0]")
    func hits195() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.hubs
        let expected: [Double] = [0.5, 0.5, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-196 D(P(0,1,2)).hits().authorities is [0, 0.5, 0.5]")
    func hits196() throws {
        // D: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.authorities
        let expected: [Double] = [0, 0.5, 0.5]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let hubs = scores.hubs.scores
        #expect(hubs.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = hubs.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-197 D(0>1, 0>2, 3>1).hits().hubs is [0.61803398875, 0, 0, 0.38196601125]: Sum 1 (NetworkX normalized=True)")
    func hits197() throws {
        // D: 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.hubs
        let expected: [Double] = [0.6180339887498947, 0, 0, 0.38196601125010526]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-198 D(0>1, 0>2, 3>1).hits().authorities is [0, 0.61803398875, 0.38196601125, 0]")
    func hits198() throws {
        // D: 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.authorities
        let expected: [Double] = [0, 0.6180339887498951, 0.3819660112501048, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let hubs = scores.hubs.scores
        #expect(hubs.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = hubs.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-199 D(C(0,1,2)).hits().hubs is [0.333333333333, 0.333333333333, 0.333333333333]")
    func hits199() throws {
        // D: C(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.hubs
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
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-200 D(0>1, 0>2, 1>2, 2>0, 3>2).hits().hubs is [0.414213562373, 0.292893218813, 4.01180205256e-16, 0.292893218813]")
    func hits200() throws {
        // D: 0>1, 0>2, 1>2, 2>0, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.hubs
        let expected: [Double] = [
            0.4142135623730949, 0.29289321881345237, 4.0118020525605287e-16, 0.29289321881345237
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
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-201 D(0>1, 0>2, 1>2, 2>0, 3>2).hits().authorities is [9.68534692485e-16, 0.292893218813, 0.707106781187, 0]")
    func hits201() throws {
        // D: 0>1, 0>2, 1>2, 2>0, 3>2
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.authorities
        let expected: [Double] = [9.685346924847842e-16, 0.2928932188134522, 0.7071067811865468, 0]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let hubs = scores.hubs.scores
        #expect(hubs.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = hubs.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-202 D(0>1, 0>1, 0>2, 2>0, 1>0).hits().hubs is [1, 7.55578637259e-16, 7.55578637259e-16]: Parallel arcs add")
    func hits202() throws {
        // D: 0>1, 0>1, 0>2, 2>0, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 2), (2, 0), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let scores = try #require(graph.hits())
        let result = scores.hubs
        let expected: [Double] = [0.9999999999999984, 7.555786372591424e-16, 7.555786372591424e-16]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-203 D(0>1, 0>2, 3>1).hits(weight: [2.0, 1.0, 1.0]).hubs is [0.707106781187, 0, 0, 0.292893218813]")
    func hits203() throws {
        // D: 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [2, 1, 1]
        let scores = try #require(graph.hits(weight: { w[$0] }))
        let result = scores.hubs
        let expected: [Double] = [0.7071067811865476, 0, 0, 0.2928932188134525]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-204 U(nx(karate_club)).directed.hits().hubs is 34 scores, [0.0714127288083, 0.0534272312355, …]: Symmetric A: hubs = authorities = eigenvector centrality rescaled to sum 1")
    func hits204() throws {
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
        let scores = try #require(graph.directed.hits())
        let result = scores.hubs
        let expected: [Double] = [
            0.07141272880825182, 0.05342723123552988, 0.06371906455637473, 0.0424227371247089,
            0.015260959706207434, 0.01596691350305959, 0.01596691350305959, 0.034343167219053575,
            0.04568192511975033, 0.02062566774938866, 0.015260959706207434, 0.010617891511071193,
            0.016925450792306816, 0.045494864068056313, 0.02037034582561433, 0.02037034582561433,
            0.004748031847301551, 0.018561637037432036, 0.02037034582561433, 0.029713333886434774,
            0.02037034582561433, 0.018561637037432036, 0.02037034582561433, 0.030156497509356475,
            0.011460952230971724, 0.011893664396281412, 0.01518273433033843, 0.02681349411710481,
            0.02633150577795392, 0.02711153962821775, 0.035106237976714416, 0.03837574186295609,
            0.06200184647383109, 0.07500294215657563
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let authorities = scores.authorities.scores
        #expect(authorities.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = authorities.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-205 U(nx(karate_club)).directed.hits().authorities is 34 scores, [0.0714127288083, 0.0534272312355, …]")
    func hits205() throws {
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
        let scores = try #require(graph.directed.hits())
        let result = scores.authorities
        let expected: [Double] = [
            0.07141272880825178, 0.053427231235529844, 0.06371906455637472, 0.042422737124708856,
            0.015260959706207415, 0.01596691350305957, 0.01596691350305957, 0.03434316721905354,
            0.04568192511975033, 0.020625667749388666, 0.015260959706207415, 0.01061789151107118,
            0.016925450792306795, 0.045494864068056286, 0.020370345825614346, 0.020370345825614346,
            0.004748031847301543, 0.01856163703743201, 0.020370345825614346, 0.029713333886434764,
            0.020370345825614346, 0.01856163703743201, 0.020370345825614346, 0.030156497509356502,
            0.011460952230971731, 0.011893664396281423, 0.015182734330338446, 0.026813494117104823,
            0.02633150577795393, 0.027111539628217777, 0.03510623797671443, 0.0383757418629561,
            0.06200184647383113, 0.07500294215657567
        ]
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.directed.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let hubs = scores.hubs.scores
        #expect(hubs.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = hubs.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-206 D(0>1, 0>2, 3>1).hits(maxIterations: 1).hubs is nil")
    func hits206() {
        // D: 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.hits(maxIterations: 1) == nil)
    }
}
