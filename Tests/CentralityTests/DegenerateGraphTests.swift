// §A: the empty graph (both kinds), K₁, three isolated vertices and K₂: every measure. The empty graph
// gives an empty result for every measure, iterative ones included (not nil: there is nothing to
// iterate); one vertex scores 1 for degree (NetworkX's rule) and 0 for closeness, harmonic and
// betweenness; edgeless graphs are uniform for eigenvector, Katz, PageRank and HITS (api.md).
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the
// iterative ones within the catalog's Tol of the limit. Undirected rows also run on
// `graph.directed` (the same values; twice for degree and unnormalized betweenness).
// Case IDs (CE-nnn) refer to the catalog; see README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Degenerate graphs")
struct CentralityDegenerateGraphTests {
    @Test("CE-001 U([]).degreeCentrality() is []: Empty graph: every measure gives an empty result")
    func degree001() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.degreeCentrality()
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
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-002 U([]).closenessCentrality() is []")
    func closeness002() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.closenessCentrality()
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

    @Test("CE-003 U([]).harmonicCentrality() is []")
    func harmonic003() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.harmonicCentrality()
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

    @Test("CE-004 U([]).betweennessCentrality() is []")
    func betweenness004() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.betweennessCentrality()
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
        let arcs = graph.directed.betweennessCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-005 U([]).eigenvectorCentrality() is []: Not nil: there is nothing to iterate")
    func eigenvector005() throws {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = []
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-006 U([]).katzCentrality() is []: NetworkX {}")
    func katz006() throws {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = []
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = try #require(graph.directed.katzCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-007 U([]).pageRank() is []: NetworkX {}")
    func pageRank007() throws {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = try #require(graph.pageRank())
        let expected: [Double] = []
        #expect(result.scores.count == expected.count)
        for (i, value) in expected.enumerated() {
            let error = abs(result.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "index \(i)")
        }
        let byIndex = result.scores.indices.map { result.score(ofIndex: $0) }
        #expect(byIndex == result.scores)
        let byVertex = graph.vertices.map { result.score(of: $0) }
        #expect(byVertex == result.scores)
        let arcs = try #require(graph.directed.pageRank())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-008 D([]).hits().hubs is []: NetworkX ({}, {})")
    func hits008() throws {
        // D: []
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [], edges: [])
        let scores = try #require(graph.hits())
        let result = scores.hubs
        let expected: [Double] = []
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
    }

    @Test("CE-009 U([0]).degreeCentrality() is [1]: NetworkX's rule: one vertex scores 1 (no n − 1 to divide by)")
    func degree009() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = graph.degreeCentrality()
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
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-010 U([0]).closenessCentrality() is [0]")
    func closeness010() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = graph.closenessCentrality()
        let expected: [Double] = [0]
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

    @Test("CE-011 U([0]).harmonicCentrality() is [0]")
    func harmonic011() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = graph.harmonicCentrality()
        let expected: [Double] = [0]
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

    @Test("CE-012 U([0]).betweennessCentrality() is [0]")
    func betweenness012() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0]
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

    @Test("CE-013 U([0]).betweennessCentrality(endpoints: true) is [0]: No pair, so no endpoint credit")
    func betweenness013() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = graph.betweennessCentrality(endpoints: true)
        let expected: [Double] = [0]
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

    @Test("CE-014 U([0]).eigenvectorCentrality() is [1]")
    func eigenvector014() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = try #require(graph.eigenvectorCentrality())
        let expected: [Double] = [1]
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

    @Test("CE-015 U([0]).katzCentrality() is [1]")
    func katz015() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [1]
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

    @Test("CE-016 U([0]).pageRank() is [1]")
    func pageRank016() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: [])
        let result = try #require(graph.pageRank())
        let expected: [Double] = [1]
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

    @Test("CE-017 D([0]).hits().hubs is [1]: No edge: uniform by rule (api.md)")
    func hits017() throws {
        // D: [0]
        let graph = ReferenceDirectedMultigraph<Int>(vertices: 0 ..< 1, edges: [])
        let scores = try #require(graph.hits())
        let result = scores.hubs
        let expected: [Double] = [1]
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

    @Test("CE-018 U([0..2]).degreeCentrality() is [0, 0, 0]: Edgeless")
    func degree018() {
        // U: [0..2]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
        let result = graph.degreeCentrality()
        let expected: [Double] = [0, 0, 0]
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

    @Test("CE-019 U([0..2]).eigenvectorCentrality() is [0.57735026919, 0.57735026919, 0.57735026919]: (A + I)x = x: uniform, converged on the first iteration")
    func eigenvector019() throws {
        // U: [0..2]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
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
        let arcs = try #require(graph.directed.eigenvectorCentrality())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-020 U([0..2]).katzCentrality() is [0.57735026919, 0.57735026919, 0.57735026919]")
    func katz020() throws {
        // U: [0..2]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
        let result = try #require(graph.katzCentrality())
        let expected: [Double] = [0.5773502691896258, 0.5773502691896258, 0.5773502691896258]
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

    @Test("CE-021 U([0..2]).katzCentrality(normalized: false) is [1, 1, 1]: β everywhere")
    func katz021() throws {
        // U: [0..2]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
        let result = try #require(graph.katzCentrality(normalized: false))
        let expected: [Double] = [1, 1, 1]
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

    @Test("CE-022 U([0..2]).pageRank() is [0.333333333333, 0.333333333333, 0.333333333333]: Every vertex dangling")
    func pageRank022() throws {
        // U: [0..2]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
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
        let arcs = try #require(graph.directed.pageRank())
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-4 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-023 D([0..2]).hits().authorities is [0.333333333333, 0.333333333333, 0.333333333333]: NetworkX's svds gives NaN here")
    func hits023() throws {
        // D: [0..2]
        let graph = ReferenceDirectedMultigraph<Int>(vertices: 0 ..< 3, edges: [])
        let scores = try #require(graph.hits())
        let result = scores.authorities
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
        let hubs = scores.hubs.scores
        #expect(hubs.count == expected.count)
        // Each vector sums to 1 (api.md).
        let total = result.scores.reduce(0, +)
        #expect(abs(total - 1) <= 1e-12)
        let otherTotal = hubs.reduce(0, +)
        #expect(abs(otherTotal - 1) <= 1e-12)
    }

    @Test("CE-024 U(0-1).degreeCentrality() is [1, 1]")
    func degree024() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.degreeCentrality()
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
        let arcs = graph.directed.degreeCentrality()
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - 2 * value)
            #expect(error <= 1e-12 * max(1, abs(2 * value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-025 U(0-1).betweennessCentrality() is [0, 0]: n ≤ 2: scale skipped (NetworkX)")
    func betweenness025() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality()
        let expected: [Double] = [0, 0]
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

    @Test("CE-026 U(0-1).betweennessCentrality(endpoints: true) is [1, 1]: Each ordered pair credits both ends, scaled by 1/(n(n − 1))")
    func betweenness026() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.betweennessCentrality(endpoints: true)
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
        let arcs = graph.directed.betweennessCentrality(endpoints: true)
        for (i, value) in expected.enumerated() {
            let error = abs(arcs.score(ofIndex: i) - value)
            #expect(error <= 1e-12 * max(1, abs(value)), "graph.directed, index \(i)")
        }
    }

    @Test("CE-027 U(0-1).closenessCentrality() is [1, 1]")
    func closeness027() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.closenessCentrality()
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
}
