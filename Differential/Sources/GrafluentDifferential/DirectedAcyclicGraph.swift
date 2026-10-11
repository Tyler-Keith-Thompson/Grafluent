// The DirectedAcyclicGraph section: each directed case's edges inserted one at a time, in the
// case's order, into a DirectedAcyclicGraph over DirectedPseudograph, and the DAG's answers.
// scripts/differential.py replays the insertions in NetworkX (rejected exactly when the edge is a
// self-loop or its target reaches its source) and compares.

import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import Walks

struct DirectedAcyclicGraphAnswers: Encodable {
    /// Whether each of the case's edges was inserted.
    var accepted: [Bool] = []
    var order: [Int] = []
    var closure: [[Int]] = []
    var reduction: [[Int]] = []
    var longestPath: [Int]?
    var hasPath: Bool?
    /// Each vertex's `topologicalPosition(of:)` equals its offset in `topologicalOrder`.
    var positionsAgree = true
}

func directedAcyclicGraphAnswers(n: Int, edges: [[Int]], source: Int, target: Int) -> DirectedAcyclicGraphAnswers {
    var dag = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
    var a = DirectedAcyclicGraphAnswers()
    for e in edges { a.accepted.append(dag.insert(edge: DirectedEdge(from: e[0], to: e[1])) != nil) }
    a.order = Array(dag.topologicalOrder)
    a.positionsAgree = a.order.indices.allSatisfy { dag.topologicalPosition(of: a.order[$0]) == $0 }
    a.closure = dag.transitiveClosure().edges.map { [$0.source, $0.target] }
    a.reduction = dag.transitiveReduction().edges.map { [$0.source, $0.target] }
    a.longestPath = dag.longestPath()?.vertices
    if n > 0 { a.hasPath = dag.hasPath(from: source, to: target) }
    return a
}
