// Centrality beyond CentralityAnswers: load, percolation (state v mod 3 / 2), the group measures of
// {0, n/2} (the case's first and middle vertices), VoteRank, and on undirected cases current-flow
// betweenness and closeness (connected, n ≥ 3) and subgraph centrality (n ≤ 60). Weighted forms use
// |w| + 1. scripts/differential_centrality.py compares each with NetworkX.

import Centrality
import GraphProtocols

struct CentralityExtras: Encodable {
    var load: [Double] = []
    var loadRaw: [Double] = []
    var weightedLoad: [Double] = []
    var percolation: [Double] = []
    var weightedPercolation: [Double] = []
    var groupBetweenness = 0.0
    var groupBetweennessRaw = 0.0
    var groupBetweennessEndpoints = 0.0
    var weightedGroupBetweenness = 0.0
    var groupCloseness: Double?
    var weightedGroupCloseness: Double?
    var groupDegree: Double?
    var groupInDegree: Double?
    var groupOutDegree: Double?
    var voteRank: [Int] = []
    var currentFlowBetweenness: [Double]?
    var currentFlowBetweennessRaw: [Double]?
    var weightedCurrentFlowBetweenness: [Double]?
    var currentFlowCloseness: [Double]?
    var subgraph: [Double]?
}

func centralityGroup(_ n: Int) -> [Int] { n == 0 ? [] : Array(Set([0, n / 2])).sorted() }

func directedCentralityExtras<G: DirectedGraph<Int>>(_ graph: G, _ n: Int, _ w: (G.Edges.Index) -> Int) -> CentralityExtras {
    var a = CentralityExtras()
    a.load = graph.loadCentrality().scores
    a.loadRaw = graph.loadCentrality(normalized: false).scores
    a.weightedLoad = graph.loadCentrality(weight: { abs(w($0)) + 1 }).scores
    a.percolation = graph.percolationCentrality(state: { Double($0 % 3) / 2 }).scores
    a.weightedPercolation = graph.percolationCentrality(state: { Double($0 % 3) / 2 }, weight: { abs(w($0)) + 1 }).scores
    let group = centralityGroup(n)
    a.groupBetweenness = graph.groupBetweennessCentrality(of: group)
    a.groupBetweennessRaw = graph.groupBetweennessCentrality(of: group, normalized: false)
    a.groupBetweennessEndpoints = graph.groupBetweennessCentrality(of: group, endpoints: true)
    a.weightedGroupBetweenness = graph.groupBetweennessCentrality(of: group, weight: { abs(w($0)) + 1 })
    if group.count < n {
        a.groupCloseness = graph.groupClosenessCentrality(of: group)
        a.weightedGroupCloseness = graph.groupClosenessCentrality(of: group, weight: { Double(abs(w($0)) + 1) })
        a.groupInDegree = graph.groupInDegreeCentrality(of: group)
        a.groupOutDegree = graph.groupOutDegreeCentrality(of: group)
    }
    a.voteRank = graph.voteRank()
    return a
}

func undirectedCentralityExtras<G: Graph<Int>>(_ graph: G, _ n: Int, _ w: (G.Edges.Index) -> Int) -> CentralityExtras {
    var a = CentralityExtras()
    a.load = graph.loadCentrality().scores
    a.loadRaw = graph.loadCentrality(normalized: false).scores
    a.weightedLoad = graph.loadCentrality(weight: { abs(w($0)) + 1 }).scores
    a.percolation = graph.percolationCentrality(state: { Double($0 % 3) / 2 }).scores
    a.weightedPercolation = graph.percolationCentrality(state: { Double($0 % 3) / 2 }, weight: { abs(w($0)) + 1 }).scores
    let group = centralityGroup(n)
    a.groupBetweenness = graph.groupBetweennessCentrality(of: group)
    a.groupBetweennessRaw = graph.groupBetweennessCentrality(of: group, normalized: false)
    a.groupBetweennessEndpoints = graph.groupBetweennessCentrality(of: group, endpoints: true)
    a.weightedGroupBetweenness = graph.groupBetweennessCentrality(of: group, weight: { abs(w($0)) + 1 })
    if group.count < n {
        a.groupCloseness = graph.groupClosenessCentrality(of: group)
        a.weightedGroupCloseness = graph.groupClosenessCentrality(of: group, weight: { Double(abs(w($0)) + 1) })
        a.groupDegree = graph.groupDegreeCentrality(of: group)
    }
    a.voteRank = graph.voteRank()
    // Connected: every vertex reached from 0.
    var seen = Set([0]), stack = [0]
    while let v = stack.popLast() {
        for u in graph.neighbors(of: v) where seen.insert(u).inserted { stack.append(u) }
    }
    if n >= 3, seen.count == n {
        a.currentFlowBetweenness = graph.currentFlowBetweennessCentrality().scores
        a.currentFlowBetweennessRaw = graph.currentFlowBetweennessCentrality(normalized: false).scores
        a.weightedCurrentFlowBetweenness = graph.currentFlowBetweennessCentrality(weight: { Double(abs(w($0)) + 1) }).scores
        a.currentFlowCloseness = graph.currentFlowClosenessCentrality().scores
    }
    if n <= 60 { a.subgraph = graph.subgraphCentrality().scores }
    return a
}
