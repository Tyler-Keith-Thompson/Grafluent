// Every entry point on each representation: the same undirected graph (a triangle with a pendant
// and an isolated vertex) on UndirectedAdjacencyList, AdjacencyList.undirectedView and Pseudograph,
// and on a conformer without vertex or edge indices; the same digraph on AdjacencyList,
// CompressedSparseRow, AdjacencyMatrix, DirectedPseudograph and a conformer without indices.
// Every answer must equal UndirectedAdjacencyList's or AdjacencyList's, by vertex value.

import AdjacencyListModule
import AdjacencyMatrixModule
import Assortativity
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import Testing

/// An undirected graph with no vertex or edge indices, its vertices listed in reverse.
private struct UnindexedGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

/// A digraph with no vertex or edge indices, its vertices listed in reverse.
private struct UnindexedDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@Suite("Assortativity on every representation")
struct AssortativityRepresentationTests {
    @Test("Undirected entry points agree across representations")
    func undirected() {
        let pairs = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        let reference = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: edges)
        let w: [Double] = [1, 2, 0.5, 4]
        // Weights by endpoints, so each representation can read them through its own positions.
        func weight(_ e: UndirectedEdge<Int>) -> Double { w[edges.firstIndex(of: e)!] }
        let classes = [0, 0, 1, 1, 2]
        let values: [Double] = [1, 2, 3, 5, 8]

        let expectedDegree = reference.degreeAssortativityCoefficient()
        let expectedWeighted = reference.degreeAssortativityCoefficient(weight: { weight(reference.edges[$0]) })
        let expectedClasses = reference.attributeAssortativityCoefficient(attribute: { classes[$0] })
        let expectedNumeric = reference.numericAssortativityCoefficient(attribute: { values[$0] })
        let expectedAverages = reference.averageNeighborDegrees()
        let expectedConnectivity = reference.averageDegreeConnectivity()
        let expectedWeightedAverages = reference.averageNeighborDegrees(weight: { weight(reference.edges[$0]) })
        let expectedWeightedConnectivity = reference.averageDegreeConnectivity(weight: { weight(reference.edges[$0]) })
        #expect(expectedDegree != nil && expectedWeighted != nil && expectedClasses != nil && expectedNumeric != nil)
        #expect(reference.degreeHistogram() == [1, 1, 2, 1])
        #expect(!reference.isRegular)
        #expect(reference.sMetric() == 19)
        #expect(reference.richClubCoefficients() == [2.0 / 3.0, 1])

        func check<G: Graph<Int>>(_ graph: G, _ name: String, weightOf: (G.Edges.Index) -> Double) {
            let degree = graph.degreeAssortativityCoefficient()
            #expect(abs((degree ?? 9) - expectedDegree!) <= 1e-12, "\(name)")
            let weighted = graph.degreeAssortativityCoefficient(weight: weightOf)
            #expect(abs((weighted ?? 9) - expectedWeighted!) <= 1e-12, "\(name)")
            let byClass = graph.attributeAssortativityCoefficient(attribute: { classes[$0] })
            #expect(byClass == expectedClasses, "\(name)")
            let byValue = graph.numericAssortativityCoefficient(attribute: { values[$0] })
            #expect(abs((byValue ?? 9) - expectedNumeric!) <= 1e-12, "\(name)")
            let averages = graph.averageNeighborDegrees()
            for v in 0 ..< 5 { #expect(averages.averageNeighborDegree(of: v) == expectedAverages.averageNeighborDegree(of: v), "\(name) \(v)") }
            #expect(graph.averageDegreeConnectivity() == expectedConnectivity, "\(name)")
            let weightedAverages = graph.averageNeighborDegrees(weight: weightOf)
            for v in 0 ..< 5 { #expect(abs(weightedAverages.averageNeighborDegree(of: v) - expectedWeightedAverages.averageNeighborDegree(of: v)) <= 1e-12, "\(name) \(v)") }
            let weightedConnectivity = graph.averageDegreeConnectivity(weight: weightOf)
            #expect(Set(weightedConnectivity.keys) == Set(expectedWeightedConnectivity.keys), "\(name)")
            for (k, value) in expectedWeightedConnectivity { #expect(abs(weightedConnectivity[k]! - value) <= 1e-12, "\(name) k = \(k)") }
            #expect(graph.degreeHistogram() == [1, 1, 2, 1], "\(name)")
            #expect(!graph.isRegular && !graph.isRegular(degree: 2), "\(name)")
            #expect(graph.sMetric() == 19, "\(name)")
            #expect(graph.richClubCoefficients() == [2.0 / 3.0, 1], "\(name)")
        }
        check(reference, "UndirectedAdjacencyList") { weight(reference.edges[$0]) }
        let digraph = AdjacencyList(vertices: 0 ..< 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let view = digraph.undirectedView
        check(view, "AdjacencyList.undirectedView") { p in
            let e = view.edges[p]
            return weight(UndirectedEdge(e.u, e.v))
        }
        let pseudograph = Pseudograph(vertices: 0 ..< 5, edges: edges)
        check(pseudograph, "Pseudograph") { weight(pseudograph.edges[$0]) }
        let unindexed = UnindexedGraph(vertices: Array((0 ..< 5).reversed()), edges: edges)
        check(unindexed, "no indices") { weight(unindexed.edges[$0]) }
    }

    @Test("Directed entry points agree across representations")
    func directed() {
        let pairs = [(0, 1), (0, 2), (1, 2), (2, 0), (2, 3), (3, 2), (4, 4)]
        let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let reference = AdjacencyList(vertices: 0 ..< 5, edges: arcs)
        func weight(_ e: DirectedEdge<Int>) -> Double { Double(arcs.firstIndex(of: e)! + 1) / 2 }
        let classes = [0, 0, 1, 1, 2]
        let values: [Double] = [1, 2, 3, 5, 8]
        let census = reference.triadicCensus()
        let reciprocity = reference.reciprocity()
        #expect(reciprocity == 4.0 / 6.0)

        func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String, weightOf: (G.Edges.Index) -> Double) {
            for source in DegreeType.allCases {
                for target in DegreeType.allCases {
                    // Sums run in `vertices` order, so the last bits may differ.
                    let plain = graph.degreeAssortativityCoefficient(source: source, target: target)
                    let expectedPlain = reference.degreeAssortativityCoefficient(source: source, target: target)
                    #expect((plain == nil) == (expectedPlain == nil) && abs((plain ?? 9) - (expectedPlain ?? 9)) <= 1e-12, "\(name) \(source) \(target)")
                    let weighted = graph.degreeAssortativityCoefficient(source: source, target: target, weight: weightOf)
                    let expected = reference.degreeAssortativityCoefficient(source: source, target: target) { weight(reference.edges[$0]) }
                    #expect(abs((weighted ?? 9) - (expected ?? 9)) <= 1e-12, "\(name) weighted \(source) \(target)")
                    let averages = graph.averageNeighborDegrees(source: source, target: target)
                    let expectedAverages = reference.averageNeighborDegrees(source: source, target: target)
                    for v in 0 ..< 5 { #expect(averages.averageNeighborDegree(of: v) == expectedAverages.averageNeighborDegree(of: v), "\(name) \(source) \(target) \(v)") }
                    let weightedAverages = graph.averageNeighborDegrees(source: source, target: target, weight: weightOf)
                    let expectedWeighted = reference.averageNeighborDegrees(source: source, target: target) { weight(reference.edges[$0]) }
                    for v in 0 ..< 5 { #expect(abs(weightedAverages.averageNeighborDegree(of: v) - expectedWeighted.averageNeighborDegree(of: v)) <= 1e-12, "\(name) \(v)") }
                    #expect(graph.averageDegreeConnectivity(source: source, target: target) == reference.averageDegreeConnectivity(source: source, target: target), "\(name) \(source) \(target)")
                    let connectivity = graph.averageDegreeConnectivity(source: source, target: target, weight: weightOf)
                    let expectedConnectivity = reference.averageDegreeConnectivity(source: source, target: target) { weight(reference.edges[$0]) }
                    #expect(Set(connectivity.keys) == Set(expectedConnectivity.keys), "\(name)")
                    for (k, value) in expectedConnectivity { #expect(abs(connectivity[k]! - value) <= 1e-12, "\(name) k = \(k)") }
                }
            }
            let byClass = graph.attributeAssortativityCoefficient(attribute: { classes[$0] })
            #expect(byClass == reference.attributeAssortativityCoefficient(attribute: { classes[$0] }), "\(name)")
            let byValue = graph.numericAssortativityCoefficient(attribute: { values[$0] })
            let expectedValue = reference.numericAssortativityCoefficient(attribute: { values[$0] })
            #expect(abs((byValue ?? 9) - (expectedValue ?? 9)) <= 1e-12, "\(name)")
            #expect(graph.reciprocity() == reciprocity, "\(name)")
            #expect(graph.triadicCensus() == census, "\(name)")
            #expect(graph.inDegreeHistogram() == reference.inDegreeHistogram(), "\(name)")
            #expect(graph.outDegreeHistogram() == reference.outDegreeHistogram(), "\(name)")
            #expect(graph.isRegular == reference.isRegular, "\(name)")
        }
        check(reference, "AdjacencyList") { weight(reference.edges[$0]) }
        let csr = CompressedSparseRow(vertexCount: 5, edges: arcs)
        check(csr, "CompressedSparseRow") { weight(csr.edges[$0]) }
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: arcs)
        check(matrix, "AdjacencyMatrix") { weight(matrix.edges[$0]) }
        let pseudograph = DirectedPseudograph(vertices: 0 ..< 5, edges: arcs)
        check(pseudograph, "DirectedPseudograph") { weight(pseudograph.edges[$0]) }
        let unindexed = UnindexedDigraph(vertices: Array((0 ..< 5).reversed()), edges: arcs)
        check(unindexed, "no indices") { weight(unindexed.edges[$0]) }
        // The bidirectional representations' per-vertex reciprocity.
        for v in 0 ..< 5 {
            #expect(pseudograph.reciprocity(of: v) == reference.reciprocity(of: v))
        }
    }
}
