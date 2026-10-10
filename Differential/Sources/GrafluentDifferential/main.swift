// Reads a JSON array of cases on standard input and writes a JSON array of results, one per case,
// in order. Each case is a simple graph on 0..<n (self-loops allowed, no repeated pair) with
// integer weights, sources, an optional cutoff and a target.

import AdjacencyListModule
import BipartiteGraphs
import Centrality
import Cliques
import CommunityDetection
import Connectivity
import Covering
import Cycles
import Distances
import Foundation
import MatchingModule
import GraphProtocols
import ShortestPaths
import Walks
import SpanningTrees
import TreeAlgorithms
import Trees

struct Case: Decodable {
    let directed: Bool
    let n: Int
    let edges: [[Int]]  // [u, v, w]
    let sources: [Int]
    let cutoff: Int?
    let target: Int
}

struct Result: Encodable {
    /// Dijkstra from the sources, with the cutoff; nil when a weight is negative.
    var dijkstra: [Int?]?
    /// The single-target query from the first source; nil when a weight is negative.
    var single: Single?
    /// Bellman–Ford from the sources, or nil when it reports a negative cycle.
    var bellmanFord: [Int?]?
    var witness: [Int]?
    var wholeGraphWitness: [Int]?
    var unweighted: [Int?]
    /// Undirected only: spanning forests as offsets in the case's edge list, and their weights.
    var spanning: Spanning?
    var connectivity: UndirectedConnectivity?
    var cycles: Cycles?
    var trees = TreeAnswers()
    var distances: DistanceAnswers?
    var cliques: CliqueAnswers?
    var centrality = CentralityAnswers()
    var communities = CommunityAnswers()
    var bipartite = BipartiteAnswers()
    var matching = MatchingAnswers()
    var covering = CoveringAnswers()
}

/// Cliques on the simple graph: maximal cliques (each sorted), the clique number and the
/// lexicographically least maximum clique, core numbers, triangles, clustering and averages.
struct CliqueAnswers: Encodable {
    var maximal: [[Int]] = []
    var cliqueNumber = 0
    var maximum: [Int] = []
    var cores: [Int] = []
    var degeneracyOrderValid = true
    var triangles: [Int] = []
    var clustering: [Double] = []
    var transitivity = 0.0
    var average = 0.0
    var oneShotsAgree = true
}

/// Distances, unweighted and (with nonnegative weights) weighted, by eccentricities() and by
/// the one-shot calls; `consistent` checks the one-shot calls agree with eccentricities().
struct DistanceAnswers: Encodable {
    var eccentricities: [Int?] = []
    var radius: Int?
    var diameter: Int?
    var center: [Int] = []
    var periphery: [Int] = []
    var centroid: [Int] = []
    var wiener: Int?
    var average: Double?
    var density = 0.0
    var diameterPath: [Int]?
    var weightedEccentricities: [Int?]?
    var weightedCentroid: [Int]?
    var weightedWiener: Int?
    var weightedPath: [Int]?
    var weightedPathDistance: Int?
    var consistent = true
}

func basics<G: DirectedGraph<Int>>(_ e: Eccentricities<G, Int>, _ n: Int) -> DistanceAnswers {
    var answers = DistanceAnswers()
    answers.eccentricities = (0 ..< n).map { e.eccentricity(of: $0) }
    answers.radius = e.radius
    answers.diameter = e.diameter
    answers.center = e.center
    answers.periphery = e.periphery
    return answers
}

/// Trees: recognition, and for a tree rooted at the first source its orders, depths and the path
/// to the target; for a forest, its trees' vertex sets.
struct TreeAnswers: Encodable {
    var isTree = false
    var tree = false
    var forest = false
    var forestTrees: [[Int]]?
    var prufer: [Int]?
    var preorder: [Int]?
    var postorder: [Int]?
    var depths: [Int]?
    var height: Int?
    var path: [Int]?
    var isArborescence = false
    var arborescence = false
    var root: Int?
    var center: [Int]?
    var weightedCenter: [Int]?
    var centroid: [Int]?
    var diameter: Int?
    var weightedDiameter: Int?
    var diameterPath: [Int]?
    /// lowestCommonAncestors[u][v] from the first source, by LowestCommonAncestors; checked
    /// against the one-shot query and HLD inside, flagged in `lcaAgree`.
    var lowestCommonAncestors: [[Int]]?
    var lcaAgree: Bool?
    var centroidHeight: Int?
}

/// Cycles as vertex lists (and, undirected, edge positions: the case's edge offsets). A list is
/// nil when the graph has more than `cycleLimit` cycles of that kind.
struct Cycles: Encodable {
    var simple: [[Int]]?
    var simpleEdges: [[Int]]?
    /// maxLength 3.
    var bounded: [[Int]]?
    /// Every cycle a cycle of the graph through `Cycle(vertices:edges:in:)`.
    var valid = true
    var girth: Int?
    var isAcyclic: Bool?
    var findCycle: [Int]?
    var findCycleEdges: [Int]?
    var basis: [[Int]]?
    var basisEdges: [[Int]]?
}

let cycleLimit = 3000

func listed<S: Sequence<Cycle<Int, Int>>>(_ cycles: S, _ isValid: (Cycle<Int, Int>) -> Bool, _ valid: inout Bool) -> (vertices: [[Int]], edges: [[Int]])? {
    var vertices: [[Int]] = [], edges: [[Int]] = []
    for cycle in cycles {
        if vertices.count == cycleLimit { return nil }
        if !isValid(cycle) { valid = false }
        vertices.append(cycle.vertices)
        edges.append(cycle.edges)
    }
    return (vertices, edges)
}

struct UndirectedConnectivity: Encodable {
    let components: [[Int]]
    let isConnected: Bool
    let bridges: [Int]
    let hasBridges: Bool
    let articulationPoints: [Int]
    let blocks: [[Int]]
    let blockVertices: [[Int]]
    let isBiconnected: Bool
    let biEdgeComponents: [[Int]]
    let isBiEdgeConnected: Bool
    let blockCutTreeEdges: Int
}

struct Spanning: Encodable {
    let minimum: [Int]
    let minimumWeight: Int
    let kruskal: [Int]
    let boruvka: [Int]
    let prim: [Int]
    let primWeight: Int
    let primFromFirstSource: [Int]
    let maximum: [Int]
    let maximumWeight: Int
    let unweighted: [Int]
}

struct Single: Encodable {
    let reached: Bool
    let distance: Int?
    let path: [Int]?
}

/// Centrality scores. Weighted measures use |w| (betweenness |w| + 1, which must be positive).
struct CentralityAnswers: Encodable {
    var degree: [Double] = []
    var inDegree: [Double]?
    var outDegree: [Double]?
    var closeness: [Double] = []
    var closenessPlain: [Double] = []
    var harmonic: [Double] = []
    var weightedCloseness: [Double] = []
    var weightedHarmonic: [Double] = []
    var betweenness: [Double] = []
    var betweennessRaw: [Double] = []
    var betweennessEndpoints: [Double] = []
    var weightedBetweenness: [Double] = []
    var eigenvector: [Double]?
    var katz: [Double]?
    var pageRank: [Double]?
    var weightedPageRank: [Double]?
    var hubs: [Double]?
    var authorities: [Double]?
    /// One-vertex forms, floating-point weights and the directed view agree with the rest.
    var consistent = true
}

func directedCentrality<G: DirectedGraph<Int>>(_ graph: G, _ n: Int, _ w: (G.Edges.Index) -> Int) -> CentralityAnswers {
    var a = CentralityAnswers()
    a.degree = graph.degreeCentrality().scores
    a.inDegree = graph.inDegreeCentrality().scores
    a.outDegree = graph.outDegreeCentrality().scores
    a.closeness = graph.closenessCentrality().scores
    a.closenessPlain = graph.closenessCentrality(wfImproved: false).scores
    a.harmonic = graph.harmonicCentrality().scores
    a.weightedCloseness = graph.closenessCentrality(weight: { abs(w($0)) }).scores
    a.weightedHarmonic = graph.harmonicCentrality(weight: { abs(w($0)) }).scores
    a.betweenness = graph.betweennessCentrality().scores
    a.betweennessRaw = graph.betweennessCentrality(normalized: false).scores
    a.betweennessEndpoints = graph.betweennessCentrality(endpoints: true).scores
    a.weightedBetweenness = graph.betweennessCentrality(weight: { abs(w($0)) + 1 }).scores
    a.eigenvector = graph.eigenvectorCentrality()?.scores
    a.katz = graph.katzCentrality()?.scores
    a.pageRank = graph.pageRank()?.scores
    a.weightedPageRank = graph.pageRank(weight: { Double(abs(w($0))) })?.scores
    let hits = graph.hits()
    a.hubs = hits?.hubs.scores
    a.authorities = hits?.authorities.scores
    a.consistent = (0 ..< n).allSatisfy { v in
        graph.closenessCentrality(of: v) == a.closeness[v] && graph.harmonicCentrality(of: v) == a.harmonic[v]
            && graph.closenessCentrality(of: v, weight: { Double(abs(w($0))) }) == a.weightedCloseness[v]
            && graph.harmonicCentrality(of: v, weight: { abs(w($0)) }) == a.weightedHarmonic[v]
    }
    return a
}

func undirectedCentrality<G: Graph<Int>>(_ graph: G, _ n: Int, _ w: (G.Edges.Index) -> Int) -> CentralityAnswers {
    var a = CentralityAnswers()
    a.degree = graph.degreeCentrality().scores
    a.closeness = graph.closenessCentrality().scores
    a.closenessPlain = graph.closenessCentrality(wfImproved: false).scores
    a.harmonic = graph.harmonicCentrality().scores
    a.weightedCloseness = graph.closenessCentrality(weight: { abs(w($0)) }).scores
    a.weightedHarmonic = graph.harmonicCentrality(weight: { abs(w($0)) }).scores
    a.betweenness = graph.betweennessCentrality().scores
    a.betweennessRaw = graph.betweennessCentrality(normalized: false).scores
    a.betweennessEndpoints = graph.betweennessCentrality(endpoints: true).scores
    a.weightedBetweenness = graph.betweennessCentrality(weight: { abs(w($0)) + 1 }).scores
    a.eigenvector = graph.eigenvectorCentrality()?.scores
    a.katz = graph.katzCentrality()?.scores
    a.pageRank = graph.pageRank()?.scores
    a.weightedPageRank = graph.pageRank(weight: { Double(abs(w($0))) })?.scores
    let view = graph.directed
    a.consistent = (0 ..< n).allSatisfy { v in
        graph.closenessCentrality(of: v) == a.closeness[v] && graph.harmonicCentrality(of: v) == a.harmonic[v]
            && graph.closenessCentrality(of: v, weight: { Double(abs(w($0))) }) == a.weightedCloseness[v]
            && graph.harmonicCentrality(of: v, weight: { abs(w($0)) }) == a.weightedHarmonic[v]
    }
    // The directed view: equal closeness and normalized betweenness, twice the degree.
    let viewBetweenness = view.betweennessCentrality().scores
    let viewDegree = view.degreeCentrality().scores
    if view.closenessCentrality().scores != a.closeness
        || (0 ..< n).contains(where: { abs(viewBetweenness[$0] - a.betweenness[$0]) > 1e-9 || abs(viewDegree[$0] - (n == 1 ? 1 : 2 * a.degree[$0])) > 1e-12 }) {
        a.consistent = false
    }
    return a
}

/// Community detection, partitions as a canonical label per vertex. Weighted forms use |w|; the
/// fixed partition for modularity and quality is v mod 3.
struct CommunityAnswers: Encodable {
    var modularity = 0.0
    var weightedModularity = 0.0
    var resolutionModularity = 0.0
    var coverage: Double?
    var performance: Double?
    var louvain: [Int] = []
    var weightedLouvain: [Int] = []
    var greedy: [Int] = []
    var weightedGreedy: [Int] = []
    var labelPropagation: [Int]?
    var asynchronous: [Int]?
    var weightedAsynchronous: [Int]?
    var louvainModularity = 0.0
    var singletonModularity = 0.0
}

func labels<G: DirectedGraph<Int>>(_ p: Partition<G>, _ n: Int) -> [Int] { (0 ..< n).map { p.community(of: $0) } }

func directedCommunities<G: DirectedGraph<Int>>(_ graph: G, _ n: Int, _ w: @escaping (G.Edges.Index) -> Int) -> CommunityAnswers {
    var a = CommunityAnswers()
    let fixed = (0 ..< 3).map { r in (0 ..< n).filter { $0 % 3 == r } }
    let dw = { (e: G.Edges.Index) in Double(abs(w(e))) }
    a.modularity = graph.modularity(of: fixed)
    a.weightedModularity = graph.modularity(of: fixed, weight: dw)
    a.resolutionModularity = graph.modularity(of: fixed, resolution: 0.5)
    let quality = graph.partitionQuality(of: fixed)
    a.coverage = quality.coverage.isNaN ? nil : quality.coverage
    a.performance = quality.performance.isNaN ? nil : quality.performance
    let louvain = graph.louvainCommunities()
    a.louvain = labels(louvain, n)
    a.weightedLouvain = labels(graph.louvainCommunities(weight: dw), n)
    a.greedy = labels(graph.greedyModularityCommunities(), n)
    a.weightedGreedy = labels(graph.greedyModularityCommunities(weight: dw), n)
    a.louvainModularity = graph.modularity(of: louvain)
    a.singletonModularity = graph.modularity(of: (0 ..< n).map { [$0] })
    return a
}

func undirectedCommunities<G: Graph<Int>>(_ graph: G, _ n: Int, _ w: @escaping (G.Edges.Index) -> Int) -> CommunityAnswers {
    var a = CommunityAnswers()
    let fixed = (0 ..< 3).map { r in (0 ..< n).filter { $0 % 3 == r } }
    let dw = { (e: G.Edges.Index) in Double(abs(w(e))) }
    a.modularity = graph.modularity(of: fixed)
    a.weightedModularity = graph.modularity(of: fixed, weight: dw)
    a.resolutionModularity = graph.modularity(of: fixed, resolution: 0.5)
    let quality = graph.partitionQuality(of: fixed)
    a.coverage = quality.coverage.isNaN ? nil : quality.coverage
    a.performance = quality.performance.isNaN ? nil : quality.performance
    let louvain = graph.louvainCommunities()
    a.louvain = labels(louvain, n)
    a.weightedLouvain = labels(graph.louvainCommunities(weight: dw), n)
    a.greedy = labels(graph.greedyModularityCommunities(), n)
    a.weightedGreedy = labels(graph.greedyModularityCommunities(weight: dw), n)
    a.labelPropagation = labels(graph.labelPropagationCommunities(), n)
    a.asynchronous = labels(graph.asynchronousLabelPropagationCommunities(), n)
    a.weightedAsynchronous = labels(graph.asynchronousLabelPropagationCommunities(weight: dw), n)
    a.louvainModularity = graph.modularity(of: louvain)
    a.singletonModularity = graph.modularity(of: (0 ..< n).map { [$0] })
    return a
}

/// Bipartiteness on the undirected graph (a directed case through `.undirected`): the canonical
/// side per vertex (0 left), the odd cycle (checked for validity by the script), and for bipartite
/// graphs the projection onto the left side and the round trip through `BipartiteGraph`.
struct BipartiteAnswers: Encodable {
    var isBipartite = false
    var sides: [Int]?
    var oddCycle: [Int]?
    var oddCycleEdges: [[Int]]?
    var projectionEdges: [[Int]]?
    var consistent = true
}

func bipartiteAnswers<G: Graph<Int>>(_ graph: G, _ n: Int) -> BipartiteAnswers {
    var a = BipartiteAnswers()
    a.isBipartite = graph.isBipartite
    let partition = graph.bipartition()
    let cycle = graph.findOddCycle()
    a.sides = partition.map { p in (0 ..< n).map { p.side(of: $0) == .left ? 0 : 1 } }
    a.oddCycle = cycle?.vertices
    a.oddCycleEdges = cycle.map { c in c.edges.map { [graph.edges[$0].u, graph.edges[$0].v] } }
    let built = BipartiteGraph(graph)
    a.consistent = (partition != nil) == a.isBipartite && (cycle == nil) == a.isBipartite && (built != nil) == a.isBipartite
    if let built, let partition {
        a.consistent = a.consistent && Array(built.left) == Array(partition.left) && Array(built.right) == Array(partition.right)
            && BipartiteGraph(graph, left: partition.left) == built && built.edgeCount == Set(graph.edges).count
        a.projectionEdges = built.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] }
    }
    return a
}

/// Matchings on the undirected graph (a directed case through `.undirected`), as endpoint pairs:
/// maximal, maximum (Edmonds), and on bipartite graphs Hopcroft–Karp and the minimum-weight full
/// matching with |w| (nil when none); every result checked with `isMatching` and friends.
struct MatchingAnswers: Encodable {
    var maximal: [[Int]] = []
    var maximum: [[Int]] = []
    var hopcroftKarp: [[Int]]?
    var fullMatching: [[Int]]?
    var fullWeight: Int?
    var hasFullMatching = false
    var maximumWeight: [[Int]] = []
    var maximumWeightCardinality: [[Int]] = []
    var minimumWeight: [[Int]] = []
    var consistent = true
}

func matchingAnswers<G: Graph<Int>>(_ graph: G, _ w: (G.Edges.Index) -> Int) -> MatchingAnswers {
    var a = MatchingAnswers()
    func pairs(_ edges: [G.Edges.Index]) -> [[Int]] { edges.map { [graph.edges[$0].u, graph.edges[$0].v] } }
    let maximal = graph.maximalMatching(), maximum = graph.maximumMatching()
    a.maximal = pairs(maximal.edges)
    a.maximum = pairs(maximum.edges)
    a.consistent = graph.isMaximalMatching(maximal.edges) && graph.isMatching(maximum.edges) && graph.isMaximalMatching(maximum.edges)
        && maximum.isPerfect == graph.isPerfectMatching(maximum.edges)
        && graph.vertices.allSatisfy { v in maximum.mate(of: v).map { maximum.mate(of: $0) == v } ?? true }
    a.maximumWeight = pairs(graph.maximumWeightMatching(weight: w).edges)
    a.maximumWeightCardinality = pairs(graph.maximumWeightMatching(weight: w, maximumCardinality: true).edges)
    a.minimumWeight = pairs(graph.minimumWeightMatching(weight: w).edges)
    if let partition = graph.bipartition() {
        let hk = graph.maximumBipartiteMatching(bipartition: partition)
        a.hopcroftKarp = pairs(hk.edges)
        a.consistent = a.consistent && graph.isMatching(hk.edges) && hk.edges.count == maximum.edges.count
        if let full = graph.minimumWeightFullMatching(bipartition: partition, weight: { abs(w($0)) }) {
            a.hasFullMatching = true
            a.fullMatching = pairs(full.edges)
            a.fullWeight = full.weight
        }
    }
    return a
}

/// Covering on the undirected graph (vertex weights v mod 5): Bar-Yehuda–Even covers, the greedy
/// dominating sets, maximal independent sets, König's cover on bipartite graphs, edge covers, and
/// the checks on every result.
struct CoveringAnswers: Encodable {
    var vertexCover: [Int] = []
    var weightedVertexCover: [Int] = []
    var dominatingSet: [Int] = []
    var weightedDominatingSet: [Int] = []
    var maximalIndependentSet: [Int] = []
    var konig: [Int]?
    var edgeCover: [[Int]]?
    var maximumIndependentSet: [Int]?
    var independenceNumber: Int?
    var minimumVertexCover: [Int]?
    var minimumDominatingSet: [Int]?
    var consistent = true
}

func coveringAnswers<G: Graph<Int>>(_ graph: G) -> CoveringAnswers {
    var a = CoveringAnswers()
    a.vertexCover = graph.approximateMinimumVertexCover()
    a.weightedVertexCover = graph.approximateMinimumVertexCover { $0 % 5 }
    a.dominatingSet = graph.approximateMinimumDominatingSet()
    a.weightedDominatingSet = graph.approximateMinimumDominatingSet { $0 % 5 }
    a.maximalIndependentSet = graph.maximalIndependentSet()
    a.consistent = graph.isVertexCover(a.vertexCover) && graph.isVertexCover(a.weightedVertexCover)
        && graph.isDominatingSet(a.dominatingSet) && graph.isDominatingSet(a.weightedDominatingSet)
        && graph.isIndependentSet(a.maximalIndependentSet)
        // Maximal, hence dominating, on graphs without self-loops.
        && (graph.edges.contains { $0.u == $0.v } || graph.isDominatingSet(a.maximalIndependentSet))
    if let partition = graph.bipartition() {
        let cover = graph.minimumVertexCover(bipartition: partition)
        a.konig = cover
        a.consistent = a.consistent && graph.isVertexCover(cover) && cover.count == graph.maximumBipartiteMatching(bipartition: partition).edges.count
    }
    // The exact searches, on graphs small enough for the script's brute force or NetworkX's
    // max_weight_clique on the complement.
    if graph.vertexCount <= 40 {
        let mis = graph.maximumIndependentSet(), cover = graph.minimumVertexCover()
        a.maximumIndependentSet = mis
        a.independenceNumber = graph.independenceNumber()
        a.minimumVertexCover = cover
        a.consistent = a.consistent && graph.isIndependentSet(mis) && graph.isVertexCover(cover) && mis.count + cover.count == graph.vertexCount
            && a.independenceNumber == mis.count
    }
    if graph.vertexCount <= 16 {
        let dominating = graph.minimumDominatingSet()
        a.minimumDominatingSet = dominating
        a.consistent = a.consistent && graph.isDominatingSet(dominating)
    }
    if let cover = graph.minimumEdgeCover() {
        a.edgeCover = cover.map { [graph.edges[$0].u, graph.edges[$0].v] }
        a.consistent = a.consistent && graph.isEdgeCover(cover)
    }
    return a
}

func answer<G: DirectedGraph<Int>>(_ graph: G, _ c: Case, _ weight: (G.Edges.Index) -> Int,
                                   _ dijkstraTree: () -> ShortestPathTree<G, Int>,
                                   _ single: () -> (path: Path<Int, G.Edges.Index>, distance: Int)?,
                                   _ bellmanFord: () -> ShortestPathTree<G, Int>?,
                                   _ witness: () -> [Int]?, _ wholeGraph: () -> [Int]?, _ unweighted: () -> ShortestPathTree<G, Int>) -> Result {
    let nonnegative = c.edges.allSatisfy { $0[2] >= 0 }
    var result = Result(unweighted: (0 ..< c.n).map { unweighted().distance(to: $0) })
    if nonnegative {
        let tree = dijkstraTree()
        result.dijkstra = (0 ..< c.n).map { tree.distance(to: $0) }
        let s = single()
        result.single = Single(reached: s != nil, distance: s?.distance, path: s?.path.vertices)
    }
    result.bellmanFord = bellmanFord().map { tree in (0 ..< c.n).map { tree.distance(to: $0) } }
    result.witness = witness()
    result.wholeGraphWitness = wholeGraph()
    return result
}

let cases = try JSONDecoder().decode([Case].self, from: FileHandle.standardInput.readDataToEndOfFile())
var results: [Result] = []
results.reserveCapacity(cases.count)
for c in cases {
    if c.directed {
        let graph = AdjacencyList(vertices: 0 ..< c.n, edges: c.edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        var byEdge: [DirectedEdge<Int>: Int] = [:]
        for e in c.edges { byEdge[DirectedEdge(from: e[0], to: e[1])] = e[2] }
        let weights = graph.edges.map { byEdge[$0]! }
        let w: (Int) -> Int = { weights[$0] }
        results.append(answer(graph, c, w,
            { graph.dijkstraShortestPaths(from: c.sources, cutoff: c.cutoff, weight: w) },
            { graph.dijkstraShortestPath(from: c.sources[0], to: c.target, weight: w) },
            { graph.bellmanFordShortestPaths(from: c.sources, weight: w) },
            { graph.findNegativeCycle(from: c.sources, weight: w)?.vertices },
            { graph.findNegativeCycle(weight: w)?.vertices },
            { graph.shortestPaths(from: c.sources) }))
        var cycles = Cycles()
        let isValid = { (cycle: Cycle<Int, Int>) in Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil }
        let all = listed(graph.simpleCycles(), isValid, &cycles.valid)
        cycles.simple = all?.vertices
        cycles.simpleEdges = all?.edges
        cycles.bounded = listed(graph.simpleCycles(maxLength: 3), isValid, &cycles.valid)?.vertices
        cycles.girth = graph.girth()
        results[results.count - 1].cycles = cycles
        var trees = TreeAnswers()
        trees.isArborescence = graph.isArborescence
        if let arborescence = Arborescence(graph) {
            trees.arborescence = true
            trees.root = arborescence.root
            trees.preorder = Array(arborescence.preorder)
        }
        results[results.count - 1].trees = trees
        let nonnegative = weights.allSatisfy { $0 >= 0 }
        let directedEccentricities = graph.eccentricities()
        var answers = basics(directedEccentricities, c.n)
        answers.centroid = graph.centroid()
        answers.wiener = graph.wienerIndex()
        answers.average = graph.averageShortestPathLength()
        answers.density = graph.density
        answers.diameterPath = graph.diameterPath()?.vertices
        let first: Int? = c.n > 0 ? graph.eccentricity(of: 0) : nil
        let firstAgrees = c.n == 0 || first == directedEccentricities.eccentricity(of: 0)
        answers.consistent = graph.radius() == answers.radius && graph.diameter() == answers.diameter
            && graph.center() == answers.center && graph.periphery() == answers.periphery && firstAgrees
        if nonnegative {
            let weighted = graph.eccentricities(weight: w)
            answers.weightedEccentricities = (0 ..< c.n).map { weighted.eccentricity(of: $0) }
            answers.weightedCentroid = graph.centroid(weight: w)
            answers.weightedWiener = graph.wienerIndex(weight: w)
            let path = graph.diameterPath(weight: w)
            answers.weightedPath = path?.path.vertices
            answers.weightedPathDistance = path?.distance
        }
        results[results.count - 1].distances = answers
        results[results.count - 1].centrality = directedCentrality(graph, c.n, w)
        results[results.count - 1].communities = directedCommunities(graph, c.n, w)
        results[results.count - 1].bipartite = bipartiteAnswers(graph.undirected, c.n)
        results[results.count - 1].matching = matchingAnswers(graph.undirected, { weights[$0] })
        results[results.count - 1].covering = coveringAnswers(graph.undirected)
    } else {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< c.n, edges: c.edges.map { UndirectedEdge($0[0], $0[1]) })
        var byEdge: [UndirectedEdge<Int>: Int] = [:]
        for e in c.edges { byEdge[UndirectedEdge(e[0], e[1])] = e[2] }
        let weights = graph.edges.map { byEdge[$0]! }
        let w: (Int) -> Int = { weights[$0] }
        let view = graph.directed
        // Positions are insertion order, which is the case's edge order.
        let minimum = graph.minimumSpanningTree(weight: w)
        let prim = graph.primMinimumSpanningTree(weight: w)
        let maximum = graph.maximumSpanningTree(weight: w)
        let spanning = Spanning(
            minimum: minimum.edges, minimumWeight: minimum.weight,
            kruskal: graph.kruskalMinimumSpanningTree(weight: w).edges,
            boruvka: graph.boruvkaMinimumSpanningTree(weight: w).edges,
            prim: prim.edges, primWeight: prim.weight,
            primFromFirstSource: graph.primMinimumSpanningTree(from: c.sources[0], weight: w).edges,
            maximum: maximum.edges, maximumWeight: maximum.weight,
            unweighted: graph.minimumSpanningTree().edges)
        var result = answer(view, c, { weights[$0.position] },
            { graph.dijkstraShortestPaths(from: c.sources, cutoff: c.cutoff, weight: w) },
            { graph.dijkstraShortestPath(from: c.sources[0], to: c.target, weight: w) },
            { graph.bellmanFordShortestPaths(from: c.sources, weight: w) },
            { graph.findNegativeCycle(from: c.sources, weight: w)?.vertices },
            { graph.findNegativeCycle(weight: w)?.vertices },
            { graph.shortestPaths(from: c.sources) })
        result.spanning = spanning
        let blocks = graph.biconnectedComponents()
        result.connectivity = UndirectedConnectivity(
            components: graph.connectedComponents().map(Array.init),
            isConnected: graph.isConnected,
            bridges: graph.bridges(),
            hasBridges: graph.hasBridges,
            articulationPoints: graph.articulationPoints(),
            blocks: blocks.map(Array.init),
            blockVertices: blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) },
            isBiconnected: graph.isBiconnected,
            biEdgeComponents: graph.biEdgeConnectedComponents().map(Array.init),
            isBiEdgeConnected: graph.isBiEdgeConnected,
            blockCutTreeEdges: graph.blockCutTree().edgeCount)
        var cycles = Cycles()
        let isValid = { (cycle: Cycle<Int, Int>) in Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil }
        let all = listed(graph.simpleCycles(), isValid, &cycles.valid)
        cycles.simple = all?.vertices
        cycles.simpleEdges = all?.edges
        cycles.bounded = listed(graph.simpleCycles(maxLength: 3), isValid, &cycles.valid)?.vertices
        cycles.girth = graph.girth()
        cycles.isAcyclic = graph.isAcyclic
        if let found = graph.findCycle() {
            if !isValid(found) { cycles.valid = false }
            cycles.findCycle = found.vertices
            cycles.findCycleEdges = found.edges
        }
        let basis = graph.cycleBasis()
        if !basis.allSatisfy(isValid) { cycles.valid = false }
        cycles.basis = basis.map(\.vertices)
        cycles.basisEdges = basis.map(\.edges)
        result.cycles = cycles
        var trees = TreeAnswers()
        trees.isTree = graph.isTree
        if let forest = Forest(graph) {
            trees.forest = true
            trees.forestTrees = forest.trees.map { $0.vertices.sorted() }
        }
        if let tree = Tree(graph) {
            trees.tree = true
            trees.prufer = tree.pruferSequence
            let rooted = RootedTree(tree, root: c.sources[0])
            trees.preorder = Array(rooted.preorder)
            trees.postorder = rooted.postorder
            trees.depths = (0 ..< c.n).map { rooted.depth(of: $0) }
            trees.height = rooted.height
            trees.path = rooted.path(from: c.sources[0], to: c.target).vertices
            let w: (Int) -> Int = { weights[$0] }
            trees.center = tree.center()
            let nonnegative = weights.allSatisfy { $0 >= 0 }
            if nonnegative { trees.weightedCenter = tree.center(weight: w) }
            trees.centroid = tree.centroid()
            trees.diameter = tree.diameter()
            if nonnegative { trees.weightedDiameter = tree.diameter(weight: w) }
            trees.diameterPath = tree.diameterPath().vertices
            let lca = LowestCommonAncestors(rooted)
            let hld = HeavyLightDecomposition(rooted)
            var agree = true
            trees.lowestCommonAncestors = (0 ..< c.n).map { u in
                (0 ..< c.n).map { v in
                    let a = lca.lowestCommonAncestor(of: u, v)
                    if a != rooted.lowestCommonAncestor(of: u, v) || a != hld.lowestCommonAncestor(of: u, v) { agree = false }
                    if lca.distance(from: u, to: v) != rooted.path(from: u, to: v).length { agree = false }
                    var expanded: [Int] = []
                    for segment in hld.segments(from: u, to: v) {
                        let range = Array(segment.positions)
                        expanded += segment.isReversed ? range.reversed() : range
                    }
                    if expanded.map({ hld.preorder[$0] }) != rooted.path(from: u, to: v).vertices { agree = false }
                    return a
                }
            }
            trees.lcaAgree = agree
            trees.centroidHeight = tree.centroidDecomposition().height
        }
        result.trees = trees
        let nonnegativeWeights = weights.allSatisfy { $0 >= 0 }
        let undirectedEccentricities = graph.eccentricities()
        var answers = basics(undirectedEccentricities, c.n)
        answers.centroid = graph.centroid()
        answers.wiener = graph.wienerIndex()
        answers.average = graph.averageShortestPathLength()
        answers.density = graph.density
        answers.diameterPath = graph.diameterPath()?.vertices
        let first: Int? = c.n > 0 ? graph.eccentricity(of: 0) : nil
        let firstAgrees = c.n == 0 || first == undirectedEccentricities.eccentricity(of: 0)
        answers.consistent = graph.radius() == answers.radius && graph.diameter() == answers.diameter
            && graph.center() == answers.center && graph.periphery() == answers.periphery && firstAgrees
        if nonnegativeWeights {
            let weighted = graph.eccentricities(weight: w)
            answers.weightedEccentricities = (0 ..< c.n).map { weighted.eccentricity(of: $0) }
            answers.weightedCentroid = graph.centroid(weight: w)
            answers.weightedWiener = graph.wienerIndex(weight: w)
            let path = graph.diameterPath(weight: w)
            answers.weightedPath = path?.path.vertices
            answers.weightedPathDistance = path?.distance
        }
        // The directed view gives the same eccentricities.
        let viaView = view.eccentricities()
        if (0 ..< c.n).contains(where: { viaView.eccentricity(of: $0) != undirectedEccentricities.eccentricity(of: $0) }) { answers.consistent = false }
        result.distances = answers
        var cliques = CliqueAnswers()
        cliques.maximal = Array(graph.maximalCliques())
        cliques.cliqueNumber = graph.cliqueNumber()
        cliques.maximum = graph.maximumClique()
        let cores = graph.coreNumbers()
        cliques.cores = (0 ..< c.n).map { cores.coreNumber(of: $0) }
        // Each vertex has at most its core number of distinct neighbors after it in the ordering.
        let ordering = cores.degeneracyOrdering
        var position = [Int](repeating: 0, count: c.n)
        for (i, v) in ordering.enumerated() { position[v] = i }
        for v in 0 ..< c.n {
            let later = Set(graph.neighbors(of: v).filter { $0 != v && position[$0] > position[v] })
            if later.count > cores.coreNumber(of: v) { cliques.degeneracyOrderValid = false }
        }
        let clustering = graph.clusteringCoefficients()
        cliques.triangles = (0 ..< c.n).map { clustering.triangleCount(of: $0) }
        cliques.clustering = (0 ..< c.n).map { clustering.clusteringCoefficient(of: $0) }
        cliques.transitivity = clustering.transitivity
        cliques.average = clustering.averageClustering
        cliques.oneShotsAgree = graph.triangleCount() == clustering.triangleCount && graph.transitivity() == clustering.transitivity
            && (0 ..< c.n).allSatisfy { graph.triangleCount(of: $0) == clustering.triangleCount(of: $0) && graph.clusteringCoefficient(of: $0) == clustering.clusteringCoefficient(of: $0) }
        result.cliques = cliques
        result.centrality = undirectedCentrality(graph, c.n, w)
        result.communities = undirectedCommunities(graph, c.n, w)
        result.bipartite = bipartiteAnswers(graph, c.n)
        result.matching = matchingAnswers(graph, w)
        result.covering = coveringAnswers(graph)
        results.append(result)
    }
}
let encoder = JSONEncoder()
FileHandle.standardOutput.write(try encoder.encode(results))
