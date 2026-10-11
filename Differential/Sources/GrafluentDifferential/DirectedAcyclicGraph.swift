// The DirectedAcyclicGraph section: each directed case's edges inserted one at a time, in the
// case's order, into a DirectedAcyclicGraph over DirectedPseudograph, and the DAG's answers, the
// weighted ones with the case's weights. scripts/differential.py replays the insertions in
// NetworkX (rejected exactly when the edge is a self-loop or its target reaches its source) and
// compares. ShortestPaths' `dagShortestPaths` also runs on the whole case graph, cycles included.

import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import ShortestPaths
import Walks

struct DirectedAcyclicGraphAnswers: Encodable {
    /// Whether each of the case's edges was inserted.
    var accepted: [Bool] = []
    var order: [Int] = []
    var closure: [[Int]] = []
    var reduction: [[Int]] = []
    var longestPath: [Int]?
    /// `longestPath(weight:)` with the case's weights, and its weight.
    var weightedLongestPath: [Int]?
    var weightedLongestLength: Int?
    /// `dagShortestPaths(from: sources[0])` on the DAG, in its order: each vertex's distance, and
    /// whether each tree path's weight is that distance.
    var dagDistances: [Int?] = []
    var dagPathsAgree = true
    /// `dagShortestPaths(from: sources[0])` on the whole case graph; nil when a cycle is reachable.
    var caseDistances: [Int?]?
    var hasPath: Bool?
    /// Each vertex's `topologicalPosition(of:)` equals its offset in `topologicalOrder`.
    var positionsAgree = true
}

func directedAcyclicGraphAnswers(n: Int, edges: [[Int]], source: Int, target: Int) -> DirectedAcyclicGraphAnswers {
    var dag = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
    var a = DirectedAcyclicGraphAnswers()
    // Accepted edges take positions 0, 1, … in order, so their weights are listed in that order.
    var weights: [Int] = []
    for e in edges {
        let accepted = dag.insert(edge: DirectedEdge(from: e[0], to: e[1])) != nil
        a.accepted.append(accepted)
        if accepted { weights.append(e[2]) }
    }
    a.order = Array(dag.topologicalOrder)
    a.positionsAgree = a.order.indices.allSatisfy { dag.topologicalPosition(of: a.order[$0]) == $0 }
    a.closure = dag.transitiveClosure().edges.map { [$0.source, $0.target] }
    a.reduction = dag.transitiveReduction().edges.map { [$0.source, $0.target] }
    a.longestPath = dag.longestPath()?.vertices
    if let path = dag.longestPath(weight: { weights[$0] }) {
        a.weightedLongestPath = path.vertices
        a.weightedLongestLength = path.edges.reduce(0) { $0 + weights[$1] }
    }
    if n > 0 {
        let tree = dag.dagShortestPaths(from: source) { weights[$0] }
        a.dagDistances = (0 ..< n).map { tree.distance(to: $0) }
        a.dagPathsAgree = (0 ..< n).allSatisfy { v in tree.path(to: v).map { $0.edges.reduce(0) { $0 + weights[$1] } } == tree.distance(to: v) }
        let whole = DirectedPseudograph(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        a.caseDistances = whole.dagShortestPaths(from: source) { edges[$0][2] }.map { tree in (0 ..< n).map { tree.distance(to: $0) } }
    }
    if n > 0 { a.hasPath = dag.hasPath(from: source, to: target) }
    return a
}
