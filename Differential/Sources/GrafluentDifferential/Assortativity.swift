import AdjacencyListModule
import Assortativity
import Distances
import GraphProtocols

/// Assortativity on a case. Directed: the case's digraph, self-loops kept (NetworkX reads them as
/// this module does). Undirected: the measures whose self-loop conventions differ from
/// NetworkX's (degree, attribute and numeric assortativity, neighbor degrees, the rich club,
/// efficiency) on the graph without its loops; the histogram, regularity and the s-metric on the
/// whole graph. Weights are the case's, as doubles. Classes are v mod 3, values (7v mod 11).
struct AssortativityAnswers: Encodable {
    /// Keyed "x-y" by degree type, nil where undefined.
    var degree: [String: Double?] = [:]
    var weightedDegree: [String: Double?] = [:]
    var attribute: Double?
    var numeric: Double?
    /// Keyed "source-target", each vertex's value.
    var averageNeighborDegrees: [String: [Double]] = [:]
    var weightedAverageNeighborDegrees: [String: [Double]] = [:]
    /// Keyed "source-target", k_nn by degree as [k, value] pairs.
    var connectivity: [String: [[Double]]] = [:]
    var weightedConnectivity: [String: [[Double]]] = [:]
    var reciprocity: Double?
    var vertexReciprocity: [Double?] = []
    var census: [Int] = []
    var histogram: [Int] = []
    var inHistogram: [Int] = []
    var outHistogram: [Int] = []
    var isRegular = false
    var sMetric = 0
    var richClub: [Double] = []
    var globalEfficiency = 0.0
    var localEfficiency = 0.0
}

private func name(_ type: DegreeType) -> String {
    switch type {
    case .in: "in"
    case .out: "out"
    case .total: "in+out"
    }
}

private func pairs(_ knn: [Int: Double]) -> [[Double]] { knn.keys.sorted().map { [Double($0), knn[$0]!] } }

func assortativityAnswers(directed: Bool, n: Int, edges: [[Int]]) -> AssortativityAnswers {
    var a = AssortativityAnswers()
    let classOf = { (v: Int) in v % 3 }
    let valueOf = { (v: Int) in Double((7 * v) % 11) }
    if directed {
        let graph = AdjacencyList(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        var byEdge: [DirectedEdge<Int>: Double] = [:]
        for e in edges { byEdge[DirectedEdge(from: e[0], to: e[1])] = Double(e[2]) }
        let weights = graph.edges.map { byEdge[$0]! }
        for x in [DegreeType.in, .out] {
            for y in [DegreeType.in, .out] {
                a.degree["\(name(x))-\(name(y))"] = graph.degreeAssortativityCoefficient(source: x, target: y)
                a.weightedDegree["\(name(x))-\(name(y))"] = graph.degreeAssortativityCoefficient(source: x, target: y, weight: { weights[$0] })
            }
        }
        a.attribute = graph.attributeAssortativityCoefficient(attribute: classOf)
        a.numeric = graph.numericAssortativityCoefficient(attribute: valueOf)
        for s in DegreeType.allCases {
            for t in DegreeType.allCases {
                let key = "\(name(s))-\(name(t))"
                a.averageNeighborDegrees[key] = graph.averageNeighborDegrees(source: s, target: t).values
                a.weightedAverageNeighborDegrees[key] = graph.averageNeighborDegrees(source: s, target: t, weight: { weights[$0] }).values
                if s != .total {
                    a.connectivity[key] = pairs(graph.averageDegreeConnectivity(source: s, target: t))
                    a.weightedConnectivity[key] = pairs(graph.averageDegreeConnectivity(source: s, target: t, weight: { weights[$0] }))
                }
            }
        }
        a.reciprocity = graph.reciprocity()
        a.vertexReciprocity = (0 ..< n).map { graph.reciprocity(of: $0) }
        a.census = graph.triadicCensus().counts
        a.inHistogram = graph.inDegreeHistogram()
        a.outHistogram = graph.outDegreeHistogram()
        a.isRegular = graph.isRegular
        return a
    }
    let whole = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    a.histogram = whole.degreeHistogram()
    a.isRegular = whole.isRegular
    a.sMetric = whole.sMetric()
    let loopless = edges.filter { $0[0] != $0[1] }
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: loopless.map { UndirectedEdge($0[0], $0[1]) })
    var byEdge: [UndirectedEdge<Int>: Double] = [:]
    for e in loopless { byEdge[UndirectedEdge(e[0], e[1])] = Double(e[2]) }
    let weights = graph.edges.map { byEdge[$0]! }
    a.degree["in+out-in+out"] = graph.degreeAssortativityCoefficient()
    a.weightedDegree["in+out-in+out"] = graph.degreeAssortativityCoefficient(weight: { weights[$0] })
    a.attribute = graph.attributeAssortativityCoefficient(attribute: classOf)
    a.numeric = graph.numericAssortativityCoefficient(attribute: valueOf)
    a.averageNeighborDegrees["out-out"] = graph.averageNeighborDegrees().values
    a.weightedAverageNeighborDegrees["out-out"] = graph.averageNeighborDegrees(weight: { weights[$0] }).values
    a.connectivity["in+out-in+out"] = pairs(graph.averageDegreeConnectivity())
    a.weightedConnectivity["in+out-in+out"] = pairs(graph.averageDegreeConnectivity(weight: { weights[$0] }))
    a.richClub = graph.richClubCoefficients()
    a.globalEfficiency = graph.globalEfficiency()
    a.localEfficiency = graph.localEfficiency()
    return a
}
