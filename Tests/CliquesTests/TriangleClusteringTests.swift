// §E: triangle counts, local clustering, transitivity and average clustering (CQ-401 – CQ-465), on
// the simple graph: a parallel edge and a loop change nothing (CQ-441; JGraphT would count 2). Local
// clustering is 2T/(d(d − 1)) with d the simple degree, 0 when d < 2 (igraph: NaN); transitivity 0
// with no triangle, even with no connected triple (CQ-459; igraph NaN); the average over every
// vertex, zeros included. Doubles are compared exactly: api.md computes each ratio as one integer
// division converted once, and sums the average plainly in `vertices` order, and the catalog pins
// those bits. Per-vertex values are checked by index, by vertex on the value, one vertex at a time
// on the graph, and on `graph.directed.undirected`. Every literal is a catalog cell (`ref.py`:
// marking, Latapy's compact-forward, NetworkX 3.7). CQ-466 (not a vertex) is an exit test in
// `CliquePreconditionTests.swift`. Case IDs (CQ-nnn) refer to the catalog; see README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Triangles and clustering")
struct TriangleClusteringTests {
    @Test("CQ-401 U(K(0..2), 2-3).triangleCount is #1: NetworkX doc: transitivity 0.6 (also igraph 0.6000000000000001)")
    func triangleCount401() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 1)
        #expect(graph.directed.undirected.triangleCount() == 1)
    }

    @Test("CQ-402 U(K(0..2), 2-3).triangleCounts is [1, 1, 1, 0]")
    func triangleCounts402() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1, 1, 0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-403 U(K(0..2), 2-3).clusteringCoefficients is [1.0, 1.0, 0.3333333333333333, 0.0]")
    func clusteringCoefficients403() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [1.0, 1.0, 0.3333333333333333, 0.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-404 U(K(0..2), 2-3).transitivity is #0.6")
    func transitivity404() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.6)
        #expect(graph.clusteringCoefficients().transitivity == 0.6)
        #expect(graph.directed.undirected.transitivity() == 0.6)
    }

    @Test("CQ-405 U(K(0..2), 2-3).averageClustering is #0.5833333333333334: igraph `transitivity_avglocal_undirected`: 0.5833333333333334 with `mode=\"zero\"`, 0.7777777777777778 by default (degree < 2 left out)")
    func averageClustering405() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.5833333333333334)
        #expect(graph.clusteringCoefficients().averageClustering == 0.5833333333333334)
        #expect(graph.directed.undirected.averageClustering() == 0.5833333333333334)
    }

    @Test("CQ-406 U(K(5)).triangleCount is #10: NetworkX docstring: 10 triangles, 6 per vertex")
    func triangleCount406() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 10)
        #expect(values.triangleCount == 10)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 10)
        #expect(graph.directed.undirected.triangleCount() == 10)
    }

    @Test("CQ-407 U(K(5)).triangleCounts is [6, 6, 6, 6, 6]")
    func triangleCounts407() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [6, 6, 6, 6, 6]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-408 U(K(5)).clusteringCoefficients is [1.0, 1.0, 1.0, 1.0, 1.0]")
    func clusteringCoefficients408() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-409 U(K(5)).transitivity is #1.0")
    func transitivity409() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 1.0)
        #expect(graph.clusteringCoefficients().transitivity == 1.0)
        #expect(graph.directed.undirected.transitivity() == 1.0)
    }

    @Test("CQ-410 U(K(5)).averageClustering is #1.0")
    func averageClustering410() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 1.0)
        #expect(graph.clusteringCoefficients().averageClustering == 1.0)
        #expect(graph.directed.undirected.averageClustering() == 1.0)
    }

    @Test("CQ-411 U(K(0..2), K(2..4)).triangleCount is #2: Bowtie")
    func triangleCount411() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 2)
        #expect(graph.directed.undirected.triangleCount() == 2)
    }

    @Test("CQ-412 U(K(0..2), K(2..4)).triangleCounts is [1, 1, 2, 1, 1]")
    func triangleCounts412() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1, 2, 1, 1]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-413 U(K(0..2), K(2..4)).clusteringCoefficients is [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]")
    func clusteringCoefficients413() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-414 U(K(0..2), K(2..4)).transitivity is #0.6")
    func transitivity414() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.6)
        #expect(graph.clusteringCoefficients().transitivity == 0.6)
        #expect(graph.directed.undirected.transitivity() == 0.6)
    }

    @Test("CQ-415 U(K(0..2), K(2..4)).averageClustering is #0.8666666666666668")
    func averageClustering415() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(graph.clusteringCoefficients().averageClustering == 0.8666666666666668)
        #expect(graph.directed.undirected.averageClustering() == 0.8666666666666668)
    }

    @Test("CQ-416 U(K(0..2), 1-3, 2-3).triangleCount is #2: Diamond")
    func triangleCount416() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 2)
        #expect(graph.directed.undirected.triangleCount() == 2)
    }

    @Test("CQ-417 U(K(0..2), 1-3, 2-3).triangleCounts is [1, 2, 2, 1]")
    func triangleCounts417() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 2, 2, 1]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-418 U(K(0..2), 1-3, 2-3).clusteringCoefficients is [1.0, 0.6666666666666666, 0.6666666666666666, 1.0]")
    func clusteringCoefficients418() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [1.0, 0.6666666666666666, 0.6666666666666666, 1.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-419 U(K(0..2), 1-3, 2-3).transitivity is #0.75")
    func transitivity419() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.75)
        #expect(graph.clusteringCoefficients().transitivity == 0.75)
        #expect(graph.directed.undirected.transitivity() == 0.75)
    }

    @Test("CQ-420 U(K(0..2), 1-3, 2-3).averageClustering is #0.8333333333333333")
    func averageClustering420() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.8333333333333333)
        #expect(graph.clusteringCoefficients().averageClustering == 0.8333333333333333)
        #expect(graph.directed.undirected.averageClustering() == 0.8333333333333333)
    }

    @Test("CQ-421 U(S(0;1..5), C(1..5)).triangleCount is #5: Wheel")
    func triangleCount421() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 5)
        #expect(graph.directed.undirected.triangleCount() == 5)
    }

    @Test("CQ-422 U(S(0;1..5), C(1..5)).triangleCounts is [5, 2, 2, 2, 2, 2]")
    func triangleCounts422() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [5, 2, 2, 2, 2, 2]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-423 U(S(0;1..5), C(1..5)).clusteringCoefficients is listed below")
    func clusteringCoefficients423() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-424 U(S(0;1..5), C(1..5)).transitivity is #0.6")
    func transitivity424() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.6)
        #expect(graph.clusteringCoefficients().transitivity == 0.6)
        #expect(graph.directed.undirected.transitivity() == 0.6)
    }

    @Test("CQ-425 U(S(0;1..5), C(1..5)).averageClustering is #0.6388888888888887")
    func averageClustering425() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(graph.clusteringCoefficients().averageClustering == 0.6388888888888887)
        #expect(graph.directed.undirected.averageClustering() == 0.6388888888888887)
    }

    @Test("CQ-426 U(C(0..3)).triangleCount is #0: Square: no triangle")
    func triangleCount426() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-427 U(C(0..3)).triangleCounts is [0, 0, 0, 0]")
    func triangleCounts427() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 0, 0, 0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-428 U(C(0..3)).clusteringCoefficients is [0.0, 0.0, 0.0, 0.0]")
    func clusteringCoefficients428() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0, 0.0, 0.0, 0.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-429 U(C(0..3)).transitivity is #0.0")
    func transitivity429() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-430 U(C(0..3)).averageClustering is #0.0")
    func averageClustering430() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-431 U(nx(petersen)).triangleCount is #0: Girth 5")
    func triangleCount431() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-432 U(nx(petersen)).triangleCounts is [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]")
    func triangleCounts432() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-433 U(nx(petersen)).clusteringCoefficients is [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]")
    func clusteringCoefficients433() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-434 U(nx(petersen)).transitivity is #0.0")
    func transitivity434() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-435 U(nx(petersen)).averageClustering is #0.0")
    func averageClustering435() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-436 U(nx(karate_club)).triangleCount is #45")
    func triangleCount436() {
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
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 45)
        #expect(graph.directed.undirected.triangleCount() == 45)
    }

    @Test("CQ-437 U(nx(karate_club)).triangleCounts is listed below")
    func triangleCounts437() {
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
        let expected: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-438 U(nx(karate_club)).clusteringCoefficients is listed below")
    func clusteringCoefficients438() {
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
        let expected: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-439 U(nx(karate_club)).transitivity is #0.2556818181818182: igraph `transitivity_undirected`: the same")
    func transitivity439() {
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
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(graph.clusteringCoefficients().transitivity == 0.2556818181818182)
        #expect(graph.directed.undirected.transitivity() == 0.2556818181818182)
    }

    @Test("CQ-440 U(nx(karate_club)).averageClustering is #0.5706384782076823: igraph: the same with `mode=\"zero\"`, 0.5879305533048848 by default")
    func averageClustering440() {
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
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(graph.clusteringCoefficients().averageClustering == 0.5706384782076823)
        #expect(graph.directed.undirected.averageClustering() == 0.5706384782076823)
    }

    @Test("CQ-441 U(0-1, 1-2, 2-0, 0-1, 1-1).triangleCount is #1: Parallel edge and loop: as the triangle (JGraphT `getNumberOfTriangles`: 2)")
    func triangleCount441() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 1)
        #expect(graph.directed.undirected.triangleCount() == 1)
    }

    @Test("CQ-442 U(0-1, 1-2, 2-0, 0-1, 1-1).triangleCounts is [1, 1, 1]")
    func triangleCounts442() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1, 1]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-443 U(0-1, 1-2, 2-0, 0-1, 1-1).clusteringCoefficients is [1.0, 1.0, 1.0]")
    func clusteringCoefficients443() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [1.0, 1.0, 1.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-444 U(0-1, 1-2, 2-0, 0-1, 1-1).transitivity is #1.0")
    func transitivity444() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 1.0)
        #expect(graph.clusteringCoefficients().transitivity == 1.0)
        #expect(graph.directed.undirected.transitivity() == 1.0)
    }

    @Test("CQ-445 U(0-1, 1-2, 2-0, 0-1, 1-1).averageClustering is #1.0")
    func averageClustering445() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 1.0)
        #expect(graph.clusteringCoefficients().averageClustering == 1.0)
        #expect(graph.directed.undirected.averageClustering() == 1.0)
    }

    @Test("CQ-446 U([0, 1, 2, 3]).triangleCount is #0: Edgeless")
    func triangleCount446() {
        // U: [0, 1, 2, 3]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3], edges: [])
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-447 U([0, 1, 2, 3]).triangleCounts is [0, 0, 0, 0]")
    func triangleCounts447() {
        // U: [0, 1, 2, 3]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3], edges: [])
        let expected: [Int] = [0, 0, 0, 0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-448 U([0, 1, 2, 3]).clusteringCoefficients is [0.0, 0.0, 0.0, 0.0]")
    func clusteringCoefficients448() {
        // U: [0, 1, 2, 3]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3], edges: [])
        let expected: [Double] = [0.0, 0.0, 0.0, 0.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-449 U([0, 1, 2, 3]).transitivity is #0.0")
    func transitivity449() {
        // U: [0, 1, 2, 3]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3], edges: [])
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-450 U([0, 1, 2, 3]).averageClustering is #0.0")
    func averageClustering450() {
        // U: [0, 1, 2, 3]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3], edges: [])
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-451 U(P(0..2)).triangleCount is #0: No triangle: transitivity 0/1")
    func triangleCount451() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-452 U(P(0..2)).triangleCounts is [0, 0, 0]")
    func triangleCounts452() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 0, 0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-453 U(P(0..2)).clusteringCoefficients is [0.0, 0.0, 0.0]")
    func clusteringCoefficients453() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0, 0.0, 0.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-454 U(P(0..2)).transitivity is #0.0")
    func transitivity454() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-455 U(P(0..2)).averageClustering is #0.0")
    func averageClustering455() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-456 U([0, 1] 0-1, 2-3).triangleCount is #0: No connected triple: transitivity 0 (0/0; NetworkX 0, igraph NaN)")
    func triangleCount456() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-457 U([0, 1] 0-1, 2-3).triangleCounts is [0, 0, 0, 0]")
    func triangleCounts457() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 0, 0, 0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.triangleCount * 3 == expected.reduce(0, +))
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-458 U([0, 1] 0-1, 2-3).clusteringCoefficients is [0.0, 0.0, 0.0, 0.0]")
    func clusteringCoefficients458() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0, 0.0, 0.0, 0.0]
        let values = graph.clusteringCoefficients()
        let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(oneByOne == expected)
        #expect(values.transitivity == graph.transitivity())
        #expect(values.averageClustering == graph.averageClustering())
        let view = graph.directed.undirected.clusteringCoefficients()
        let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-459 U([0, 1] 0-1, 2-3).transitivity is #0.0")
    func transitivity459() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-460 U([0, 1] 0-1, 2-3).averageClustering is #0.0")
    func averageClustering460() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-461 U(K(0..2), 2-3).triangleCount(of: 2) is #1")
    func triangleCountOf461() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.triangleCount(of: 2) == 1)
        #expect(graph.clusteringCoefficients().triangleCount(of: 2) == 1)
        #expect(graph.directed.undirected.triangleCount(of: 2) == 1)
    }

    @Test("CQ-462 U(K(0..2), 2-3).clusteringCoefficient(of: 2) is #0.3333333333333333")
    func clusteringCoefficientOf462() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.clusteringCoefficient(of: 2) == 0.3333333333333333)
        #expect(graph.clusteringCoefficients().clusteringCoefficient(of: 2) == 0.3333333333333333)
        #expect(graph.directed.undirected.clusteringCoefficient(of: 2) == 0.3333333333333333)
    }

    @Test("CQ-463 U(K(0..2), 2-3).clusteringCoefficient(of: 3) is #0.0: Degree 1")
    func clusteringCoefficientOf463() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.clusteringCoefficient(of: 3) == 0.0)
        #expect(graph.clusteringCoefficients().clusteringCoefficient(of: 3) == 0.0)
        #expect(graph.directed.undirected.clusteringCoefficient(of: 3) == 0.0)
    }

    @Test("CQ-464 U(nx(karate_club)).clusteringCoefficient(of: 0) is #0.15")
    func clusteringCoefficientOf464() {
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
        #expect(graph.clusteringCoefficient(of: 0) == 0.15)
        #expect(graph.clusteringCoefficients().clusteringCoefficient(of: 0) == 0.15)
        #expect(graph.directed.undirected.clusteringCoefficient(of: 0) == 0.15)
    }

    @Test("CQ-465 U(nx(karate_club)).triangleCount(of: 33) is #15")
    func triangleCountOf465() {
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
        #expect(graph.triangleCount(of: 33) == 15)
        #expect(graph.clusteringCoefficients().triangleCount(of: 33) == 15)
        #expect(graph.directed.undirected.triangleCount(of: 33) == 15)
    }
}
