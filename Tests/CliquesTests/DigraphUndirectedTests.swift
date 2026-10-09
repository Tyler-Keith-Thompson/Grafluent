// §F: directed graphs through `digraph.undirected` (CQ-501 – CQ-515). The view keeps two opposite
// arcs as two parallel edges; the simple graph merges them, which is igraph's "directions ignored"
// reading (NetworkX raises for cliques and triangles on a DiGraph and counts in + out degree for
// cores). Digraphs are `ReferenceDirectedMultigraph`s with arcs in written order. Every literal is
// a catalog cell (`ref.py`). Case IDs (CQ-nnn) refer to the catalog; see README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Directed graphs through undirected")
struct DigraphUndirectedTests {
    @Test("CQ-501 D(0>1, 1>0, 1>2, 2>0).undirected > maximalCliques is [[0, 1, 2]]: Reciprocal pair collapses (NetworkX `core_number` on the DiGraph: in + out degree)")
    func maximalCliques501() {
        // D: 0>1, 1>0, 1>2, 2>0
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expected: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-502 D(0>1, 1>0, 1>2, 2>0).undirected > coreNumbers is [2, 2, 2]")
    func coreNumbers502() {
        // D: 0>1, 1>0, 1>2, 2>0
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expected: [Int] = [2, 2, 2]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-503 D(0>1, 1>0, 1>2, 2>0).undirected > triangleCounts is [1, 1, 1]")
    func triangleCounts503() {
        // D: 0>1, 1>0, 1>2, 2>0
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
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

    @Test("CQ-504 D(0>1, 1>0, 1>2, 2>0).undirected > clusteringCoefficients is [1.0, 1.0, 1.0]")
    func clusteringCoefficients504() {
        // D: 0>1, 1>0, 1>2, 2>0
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
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

    @Test("CQ-505 D(0>1, 1>0, 1>2, 2>0).undirected > transitivity is #1.0")
    func transitivity505() {
        // D: 0>1, 1>0, 1>2, 2>0
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.transitivity() == 1.0)
        #expect(graph.clusteringCoefficients().transitivity == 1.0)
        #expect(graph.directed.undirected.transitivity() == 1.0)
    }

    @Test("CQ-506 D(C(0..2), C(2..0)).undirected > maximalCliques is [[0, 1, 2]]: Both orientations: one triangle")
    func maximalCliques506() {
        // D: C(0..2), C(2..0)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expected: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-507 D(C(0..2), C(2..0)).undirected > coreNumbers is [2, 2, 2]")
    func coreNumbers507() {
        // D: C(0..2), C(2..0)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expected: [Int] = [2, 2, 2]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-508 D(C(0..2), C(2..0)).undirected > triangleCounts is [1, 1, 1]")
    func triangleCounts508() {
        // D: C(0..2), C(2..0)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
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

    @Test("CQ-509 D(C(0..2), C(2..0)).undirected > clusteringCoefficients is [1.0, 1.0, 1.0]")
    func clusteringCoefficients509() {
        // D: C(0..2), C(2..0)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
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

    @Test("CQ-510 D(C(0..2), C(2..0)).undirected > transitivity is #1.0")
    func transitivity510() {
        // D: C(0..2), C(2..0)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.transitivity() == 1.0)
        #expect(graph.clusteringCoefficients().transitivity == 1.0)
        #expect(graph.directed.undirected.transitivity() == 1.0)
    }

    @Test("CQ-511 D(0>1, 1>2, 0>2, 2>3, 3>2).undirected > maximalCliques is [[2, 3], [0, 1, 2]]")
    func maximalCliques511() {
        // D: 0>1, 1>2, 0>2, 2>3, 3>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expected: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-512 D(0>1, 1>2, 0>2, 2>3, 3>2).undirected > coreNumbers is [2, 2, 2, 1]")
    func coreNumbers512() {
        // D: 0>1, 1>2, 0>2, 2>3, 3>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expected: [Int] = [2, 2, 2, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-513 D(0>1, 1>2, 0>2, 2>3, 3>2).undirected > triangleCounts is [1, 1, 1, 0]")
    func triangleCounts513() {
        // D: 0>1, 1>2, 0>2, 2>3, 3>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
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

    @Test("CQ-514 D(0>1, 1>2, 0>2, 2>3, 3>2).undirected > clusteringCoefficients is [1.0, 1.0, 0.3333333333333333, 0.0]")
    func clusteringCoefficients514() {
        // D: 0>1, 1>2, 0>2, 2>3, 3>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
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

    @Test("CQ-515 D(0>1, 1>2, 0>2, 2>3, 3>2).undirected > transitivity is #0.6")
    func transitivity515() {
        // D: 0>1, 1>2, 0>2, 2>3, 3>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.transitivity() == 0.6)
        #expect(graph.clusteringCoefficients().transitivity == 0.6)
        #expect(graph.directed.undirected.transitivity() == 0.6)
    }
}
