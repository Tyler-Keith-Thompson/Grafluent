// The GraphOperations section: the materialized operations on each case graph. The power (k = 2
// and 3), the ego graph of the first source (radius 2; directed also with arcs followed
// backwards), the contraction of the first source with the target, the transitive closure and
// reduction (directed), a merging relabeling (v ↦ v mod 3), and the four binary operations with a
// second graph on the same vertices whose edges are the case's with both ends shifted by one
// (mod n). scripts/differential.py compares them with NetworkX's power, ego_graph,
// contracted_nodes, transitive_closure, condensation and transitive_reduction, relabel_nodes,
// compose, intersection, difference and symmetric_difference.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphOperations
import GraphProtocols

struct OperationsAnswers: Encodable {
    var square: [[Int]] = []
    var cube: [[Int]] = []
    var ego: [Int] = []
    var egoEdges: [[Int]] = []
    var egoUndirected: [Int]?
    /// The ego graph of every source at radius 2, and the same cut to 4 vertices with the vertex
    /// number as the priority.
    var egoCenters: [Int] = []
    var egoBudget: [Int] = []
    var contraction: [[Int]] = []
    var contractionCount = 0
    var closure: [[Int]]?
    var reduction: [[Int]]?
    var relabeledVertices: [Int] = []
    var relabeledEdges: [[Int]] = []
    var union: [[Int]] = []
    var intersection: [[Int]] = []
    var difference: [[Int]] = []
    var symmetricDifference: [[Int]] = []
}

func directedOperationsAnswers(n: Int, edges: [[Int]], sources: [Int], target: Int) -> OperationsAnswers {
    var a = OperationsAnswers()
    guard n > 0 else { return a }
    let source = sources[0]
    let graph = AdjacencyList(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
    func pairs(_ g: some DirectedGraph<Int>) -> [[Int]] { g.edges.map { [$0.source, $0.target] } }
    a.square = pairs(CompressedSparseRow.power(of: graph, 2))
    a.cube = pairs(CompressedSparseRow.power(of: graph, 3))
    let ego = graph.egoGraphView(of: source, radius: 2)
    a.ego = Array(ego.vertices)
    a.egoEdges = pairs(ego)
    a.egoUndirected = Array(graph.egoGraphView(of: source, radius: 2, undirected: true).vertices)
    a.egoCenters = Array(graph.egoGraphView(of: sources, radius: 2).vertices)
    a.egoBudget = Array(graph.egoGraphView(of: sources, radius: 2, maximumVertexCount: 4, priority: { $0 }).vertices)
    let contraction = CompressedSparseRow.contraction(of: graph, source, target)
    a.contraction = pairs(contraction)
    a.contractionCount = contraction.vertexCount
    a.closure = pairs(CompressedSparseRow.transitiveClosure(of: graph))
    a.reduction = pairs(CompressedSparseRow.transitiveReduction(of: graph))
    let relabeled = AdjacencyList<Int>.relabeled(graph) { $0 % 3 }
    a.relabeledVertices = Array(relabeled.vertices)
    a.relabeledEdges = pairs(relabeled)
    let shifted = AdjacencyList(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: ($0[0] + 1) % n, to: ($0[1] + 1) % n) })
    a.union = pairs(AdjacencyList<Int>.union(graph, shifted))
    a.intersection = pairs(AdjacencyList<Int>.intersection(graph, shifted))
    a.difference = pairs(AdjacencyList<Int>.difference(graph, shifted))
    a.symmetricDifference = pairs(AdjacencyList<Int>.symmetricDifference(graph, shifted))
    return a
}

func undirectedOperationsAnswers(n: Int, edges: [[Int]], sources: [Int], target: Int) -> OperationsAnswers {
    var a = OperationsAnswers()
    guard n > 0 else { return a }
    let source = sources[0]
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    func pairs(_ g: some Graph<Int>) -> [[Int]] { g.edges.map { [$0.u, $0.v] } }
    a.square = pairs(UndirectedAdjacencyList<Int>.power(of: graph, 2))
    a.cube = pairs(UndirectedAdjacencyList<Int>.power(of: graph, 3))
    let ego = graph.egoGraphView(of: source, radius: 2)
    a.ego = Array(ego.vertices)
    a.egoEdges = pairs(ego)
    a.egoCenters = Array(graph.egoGraphView(of: sources, radius: 2).vertices)
    a.egoBudget = Array(graph.egoGraphView(of: sources, radius: 2, maximumVertexCount: 4, priority: { $0 }).vertices)
    let contraction = UndirectedAdjacencyList<Int>.contraction(of: graph, source, target)
    a.contraction = pairs(contraction)
    a.contractionCount = contraction.vertexCount
    let relabeled = UndirectedAdjacencyList<Int>.relabeled(graph) { $0 % 3 }
    a.relabeledVertices = Array(relabeled.vertices)
    a.relabeledEdges = pairs(relabeled)
    let shifted = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge(($0[0] + 1) % n, ($0[1] + 1) % n) })
    a.union = pairs(UndirectedAdjacencyList<Int>.union(graph, shifted))
    a.intersection = pairs(UndirectedAdjacencyList<Int>.intersection(graph, shifted))
    a.difference = pairs(UndirectedAdjacencyList<Int>.difference(graph, shifted))
    a.symmetricDifference = pairs(UndirectedAdjacencyList<Int>.symmetricDifference(graph, shifted))
    return a
}
