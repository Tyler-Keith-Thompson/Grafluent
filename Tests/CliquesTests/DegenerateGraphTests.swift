// §A: the empty graph, K₁, K₁ with a self-loop, two isolated vertices, K₂ and K₂ as three parallel
// edges, every op on each (CQ-001 – CQ-060), and the 0-core, a loop adding no degree, the 0-shell,
// and one-vertex queries (CQ-061 – CQ-067). The empty graph has no cliques, ω = 0, degeneracy 0,
// transitivity and average clustering 0 (NetworkX raises on the average; igraph gives NaN). An
// isolated vertex is a clique of one; a loop and parallel copies are ignored by every op. Each
// test also checks the one-shot calls against the members of the returned value and the same op on
// `graph.directed.undirected` (every edge as two arcs, read back as two parallel edges). Every
// literal is a catalog cell (`ref.py`: api.md's model, brute force, NetworkX 3.7). CQ-068 and
// CQ-069 (preconditions) are exit tests in `CliquePreconditionTests.swift`. Case IDs (CQ-nnn) refer
// to the catalog; see README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Degenerate graphs")
struct DegenerateGraphTests {
    @Test("CQ-001 U([]).maximalCliques is []: Empty graph")
    func maximalCliques001() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [[Int]] = []
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

    @Test("CQ-002 U([]).maximumClique is []")
    func maximumClique002() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [Int] = []
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-003 U([]).cliqueNumber is #0")
    func cliqueNumber003() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.cliqueNumber() == 0)
        #expect(graph.maximumClique().count == 0)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(0 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 0)
    }

    @Test("CQ-004 U([]).coreNumbers is []")
    func coreNumbers004() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [Int] = []
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

    @Test("CQ-005 U([]).degeneracy is #0")
    func degeneracy005() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 0)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 0)
        #expect(graph.cliqueNumber() <= 0 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 0)
    }

    @Test("CQ-006 U([]).degeneracyOrdering is []")
    func degeneracyOrdering006() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-007 U([]).triangleCount is #0")
    func triangleCount007() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-008 U([]).clusteringCoefficients is []")
    func clusteringCoefficients008() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [Double] = []
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

    @Test("CQ-009 U([]).transitivity is #0.0")
    func transitivity009() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-010 U([]).averageClustering is #0.0")
    func averageClustering010() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-011 U([0]).maximalCliques is [[0]]: K₁")
    func maximalCliques011() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [[Int]] = [[0]]
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

    @Test("CQ-012 U([0]).maximumClique is [0]")
    func maximumClique012() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Int] = [0]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-013 U([0]).cliqueNumber is #1")
    func cliqueNumber013() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.cliqueNumber() == 1)
        #expect(graph.maximumClique().count == 1)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(1 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 1)
    }

    @Test("CQ-014 U([0]).coreNumbers is [0]")
    func coreNumbers014() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Int] = [0]
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

    @Test("CQ-015 U([0]).degeneracy is #0")
    func degeneracy015() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 0)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 0)
        #expect(graph.cliqueNumber() <= 0 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 0)
    }

    @Test("CQ-016 U([0]).degeneracyOrdering is [0]")
    func degeneracyOrdering016() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Int] = [0]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-017 U([0]).triangleCount is #0")
    func triangleCount017() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-018 U([0]).clusteringCoefficients is [0.0]")
    func clusteringCoefficients018() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Double] = [0.0]
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

    @Test("CQ-019 U([0]).transitivity is #0.0")
    func transitivity019() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-020 U([0]).averageClustering is #0.0")
    func averageClustering020() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-021 U([0] 0-0).maximalCliques is [[0]]: K₁ with a self-loop: the loop is ignored by every op")
    func maximalCliques021() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0]]
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

    @Test("CQ-022 U([0] 0-0).maximumClique is [0]")
    func maximumClique022() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-023 U([0] 0-0).cliqueNumber is #1")
    func cliqueNumber023() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 1)
        #expect(graph.maximumClique().count == 1)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(1 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 1)
    }

    @Test("CQ-024 U([0] 0-0).coreNumbers is [0]")
    func coreNumbers024() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0]
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

    @Test("CQ-025 U([0] 0-0).degeneracy is #0")
    func degeneracy025() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 0)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 0)
        #expect(graph.cliqueNumber() <= 0 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 0)
    }

    @Test("CQ-026 U([0] 0-0).degeneracyOrdering is [0]")
    func degeneracyOrdering026() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-027 U([0] 0-0).triangleCount is #0")
    func triangleCount027() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-028 U([0] 0-0).clusteringCoefficients is [0.0]")
    func clusteringCoefficients028() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0]
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

    @Test("CQ-029 U([0] 0-0).transitivity is #0.0")
    func transitivity029() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-030 U([0] 0-0).averageClustering is #0.0")
    func averageClustering030() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-031 U([0, 1]).maximalCliques is [[0], [1]]: Two isolated vertices")
    func maximalCliques031() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [[Int]] = [[0], [1]]
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

    @Test("CQ-032 U([0, 1]).maximumClique is [0]")
    func maximumClique032() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [Int] = [0]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-033 U([0, 1]).cliqueNumber is #1")
    func cliqueNumber033() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.cliqueNumber() == 1)
        #expect(graph.maximumClique().count == 1)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(1 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 1)
    }

    @Test("CQ-034 U([0, 1]).coreNumbers is [0, 0]")
    func coreNumbers034() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [Int] = [0, 0]
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

    @Test("CQ-035 U([0, 1]).degeneracy is #0")
    func degeneracy035() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 0)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 0)
        #expect(graph.cliqueNumber() <= 0 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 0)
    }

    @Test("CQ-036 U([0, 1]).degeneracyOrdering is [0, 1]")
    func degeneracyOrdering036() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [Int] = [0, 1]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-037 U([0, 1]).triangleCount is #0")
    func triangleCount037() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-038 U([0, 1]).clusteringCoefficients is [0.0, 0.0]")
    func clusteringCoefficients038() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [Double] = [0.0, 0.0]
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

    @Test("CQ-039 U([0, 1]).transitivity is #0.0")
    func transitivity039() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-040 U([0, 1]).averageClustering is #0.0")
    func averageClustering040() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-041 U(0-1).maximalCliques is [[0, 1]]: K₂")
    func maximalCliques041() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1]]
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

    @Test("CQ-042 U(0-1).maximumClique is [0, 1]")
    func maximumClique042() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-043 U(0-1).cliqueNumber is #2")
    func cliqueNumber043() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 2)
        #expect(graph.maximumClique().count == 2)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(2 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 2)
    }

    @Test("CQ-044 U(0-1).coreNumbers is [1, 1]")
    func coreNumbers044() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1]
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

    @Test("CQ-045 U(0-1).degeneracy is #1")
    func degeneracy045() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-046 U(0-1).degeneracyOrdering is [0, 1]")
    func degeneracyOrdering046() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-047 U(0-1).triangleCount is #0")
    func triangleCount047() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-048 U(0-1).clusteringCoefficients is [0.0, 0.0]")
    func clusteringCoefficients048() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0, 0.0]
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

    @Test("CQ-049 U(0-1).transitivity is #0.0")
    func transitivity049() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-050 U(0-1).averageClustering is #0.0")
    func averageClustering050() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-051 U(0-1, 0-1, 1-0).maximalCliques is [[0, 1]]: K₂ as three parallel edges: one edge in the simple graph")
    func maximalCliques051() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1]]
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

    @Test("CQ-052 U(0-1, 0-1, 1-0).maximumClique is [0, 1]")
    func maximumClique052() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-053 U(0-1, 0-1, 1-0).cliqueNumber is #2")
    func cliqueNumber053() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 2)
        #expect(graph.maximumClique().count == 2)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(2 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 2)
    }

    @Test("CQ-054 U(0-1, 0-1, 1-0).coreNumbers is [1, 1]")
    func coreNumbers054() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1]
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

    @Test("CQ-055 U(0-1, 0-1, 1-0).degeneracy is #1")
    func degeneracy055() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-056 U(0-1, 0-1, 1-0).degeneracyOrdering is [0, 1]")
    func degeneracyOrdering056() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-057 U(0-1, 0-1, 1-0).triangleCount is #0")
    func triangleCount057() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let values = graph.clusteringCoefficients()
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(perVertex.reduce(0, +) == 3 * 0)
        #expect(graph.directed.undirected.triangleCount() == 0)
    }

    @Test("CQ-058 U(0-1, 0-1, 1-0).clusteringCoefficients is [0.0, 0.0]")
    func clusteringCoefficients058() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Double] = [0.0, 0.0]
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

    @Test("CQ-059 U(0-1, 0-1, 1-0).transitivity is #0.0")
    func transitivity059() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.transitivity() == 0.0)
        #expect(graph.clusteringCoefficients().transitivity == 0.0)
        #expect(graph.directed.undirected.transitivity() == 0.0)
    }

    @Test("CQ-060 U(0-1, 0-1, 1-0).averageClustering is #0.0")
    func averageClustering060() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageClustering() == 0.0)
        #expect(graph.clusteringCoefficients().averageClustering == 0.0)
        #expect(graph.directed.undirected.averageClustering() == 0.0)
    }

    @Test("CQ-061 U([]).kCore(0) is []")
    func kCore061() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kCore(0) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 0 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(0) == expected)
    }

    @Test("CQ-062 U([0]).kCore(0) is [0]: Every vertex is in the 0-core")
    func kCore062() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Int] = [0]
        let cores = graph.coreNumbers()
        #expect(cores.kCore(0) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 0 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(0) == expected)
    }

    @Test("CQ-063 U([0]).kCore(1) is []")
    func kCore063() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kCore(1) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 1 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(1) == expected)
    }

    @Test("CQ-064 U([0] 0-0).kCore(1) is []: A loop adds no degree (igraph: coreness 2, NetworkX raises)")
    func kCore064() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kCore(1) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 1 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(1) == expected)
    }

    @Test("CQ-065 U([0, 1]).kShell(0) is [0, 1]")
    func kShell065() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [Int] = [0, 1]
        let cores = graph.coreNumbers()
        #expect(cores.kShell(0) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 0 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(0) == expected)
    }

    @Test("CQ-066 U([0]).triangleCount(of: 0) is #0")
    func triangleCountOf066() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.triangleCount(of: 0) == 0)
        #expect(graph.clusteringCoefficients().triangleCount(of: 0) == 0)
        #expect(graph.directed.undirected.triangleCount(of: 0) == 0)
    }

    @Test("CQ-067 U([0]).clusteringCoefficient(of: 0) is #0.0: Degree < 2: 0 (NetworkX, JGraphT, Boost; igraph NaN)")
    func clusteringCoefficientOf067() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.clusteringCoefficient(of: 0) == 0.0)
        #expect(graph.clusteringCoefficients().clusteringCoefficient(of: 0) == 0.0)
        #expect(graph.directed.undirected.clusteringCoefficient(of: 0) == 0.0)
    }
}
