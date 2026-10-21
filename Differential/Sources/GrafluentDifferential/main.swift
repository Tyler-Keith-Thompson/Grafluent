// Reads a JSON array of cases on standard input and writes a JSON array of results, one per case,
// in order. Each case is a simple graph on 0..<n (self-loops allowed, no repeated pair) with
// integer weights, sources, an optional cutoff and a target.
//
// The arguments, if any, name the sections to answer (scripts/differential.py's --module):
// shortestpaths, spanningtrees, connectivity, cycles, trees, distances, cliques, centrality,
// communities, bipartite, matching, covering, coloring, flows, tours, dag, planarity, traversal, operations,
// similarity, assortativity, isomorphism, drawing, generators, spectral. With none,
// every section is answered. A section not asked for is left at its default and not computed.
// `flows-catalog` or `tours-catalog` as the only argument answers catalog requests instead
// (Flows.swift, Tours.swift); `formats` answers GraphFormats read and write requests
// (GraphFormats.swift).

import AdjacencyListModule
import BipartiteGraphs
import Centrality
import Cliques
import ColoringModule
import CommunityDetection
import Connectivity
import Covering
import Cycles
import Distances
import Foundation
import MatchingModule
import ParallelCentrality
import GraphProtocols
import IsomorphismModule
import ShortestPaths
import Similarity
import SpectralGraphTheory
import Walks
import SpanningTrees
import TreeAlgorithms
import Traversal
import Trees

struct Case: Decodable {
    let directed: Bool
    let n: Int
    let edges: [[Int]]  // [u, v, w]
    let sources: [Int]
    let cutoff: Int?
    let target: Int
    /// The flow network, when the flows section is asked for.
    let flow: FlowCase?
    /// The Tours inputs, when the tours section is asked for.
    let tours: ToursCase?
    /// The generator inputs, when the generators section is asked for.
    let generators: GeneratorCase?
    /// The planted partition, when the communities section is asked for.
    let plantedPartition: PlantedPartitionCase?
}

struct Result: Encodable {
    /// Dijkstra from the sources, with the cutoff; nil when a weight is negative.
    var dijkstra: [Int?]?
    /// The single-target query from the first source; nil when a weight is negative.
    var single: Single?
    /// Bellman–Ford from the sources, or nil when it reports a negative cycle.
    var bellmanFord: [Int?]?
    /// Goldberg–Radzik from the sources: the same answer as Bellman–Ford.
    var goldbergRadzik: [Int?]?
    var witness: [Int]?
    var wholeGraphWitness: [Int]?
    var unweighted: [Int?]?
    /// Yen, all shortest paths, bidirectional Dijkstra, all pairs (ShortestPathEnumeration.swift).
    var paths: PathAnswers?
    /// Undirected only: spanning forests as offsets in the case's edge list, and their weights.
    var spanning: Spanning?
    /// Directed only: spanning arborescences and branchings (SpanningTrees.swift).
    var arborescences: ArborescenceAnswers?
    /// Undirected only: Steiner trees over the sources and the target (SpanningTrees.swift).
    var steiner: SteinerAnswers?
    var connectivity: UndirectedConnectivity?
    /// Directed only: nontrivial strong components, with the full partition for their order.
    var directedConnectivity: DirectedConnectivity?
    /// Self-loop queries, both kinds (answered in the connectivity section).
    var selfLoops: SelfLoopAnswers?
    var cycles: Cycles?
    var trees = TreeAnswers()
    var distances: DistanceAnswers?
    var cliques: CliqueAnswers?
    /// Trusses, onion layers, crusts, coronas, clique listings and weights (Cohesion.swift).
    var cliqueExtras: CliqueExtraAnswers?
    /// k-edge-connected components and subgraphs (Cohesion.swift).
    var edgeConnectivity: EdgeConnectivityAnswers?
    /// d-separation and the moral graph (Cohesion.swift).
    var dSeparation: DSeparationAnswers?
    var centrality = CentralityAnswers()
    var communities = CommunityAnswers()
    var bipartite = BipartiteAnswers()
    var matching = MatchingAnswers()
    var covering = CoveringAnswers()
    var coloring = ColoringAnswers()
    var flows: FlowAnswers?
    var tours: ToursAnswers?
    var dag: DirectedAcyclicGraphAnswers?
    var planarity: PlanarityAnswers?
    var assortativity: AssortativityAnswers?
    var similarity: SimilarityAnswers?
    var isomorphism: IsomorphismAnswers?
    var drawing: DrawingAnswers?
    var operations: OperationsAnswers?
    var traversal: TraversalAnswers?
    var generators: GeneratorAnswers?
    var spectral: SpectralAnswers?
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
    /// Chordal graphs: isChordal, the perfect elimination ordering (the reverse of
    /// maximumCardinalitySearch(), checked here), the cliques and treewidth, or the hole.
    var isChordal = false
    var eliminationOrder: [Int]?
    var eliminationIsReversedSearch = true
    var chordalCliques: [[Int]]?
    var treewidth: Int?
    var hole: [Int]?
    var holeValid = true
    /// Tree decompositions: treewidthMinDegree() and treewidthMinFillIn(), with the library's
    /// own isTreeDecomposition(_:) verdict.
    var minDegreeBags: [[Int]] = []
    var minDegreeEdges: [[Int]] = []
    var minDegreeWidth = 0
    var minFillInBags: [[Int]] = []
    var minFillInEdges: [[Int]] = []
    var minFillInWidth = 0
    var decompositionsValid = true
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
    /// The prefix tree of every vertex's neighbor list: the words, each vertex's prefix, and the
    /// prefix at each word's end.
    var prefixWords: [[Int]]?
    var prefixes: [[Int]]?
    var prefixEnds: [[Int]]?
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
    /// minimumCycleBasis(): its cycles' edge positions, and the weighted basis's total weight with
    /// weights position % 4 + 1.
    var minimumBasisEdges: [[Int]]?
    var minimumBasisWeight: Int?
    /// chordlessCycles(), and (directed) the minimum mean cycle's vertices, weight and length.
    var chordless: [[Int]]?
    var chordlessEdges: [[Int]]?
    var meanCycle: [Int]?
    var meanWeight: Int?
    var meanLength: Int?
    /// On at most 14 vertices: minimumFeedbackArcSet() as [source, target] pairs (directed) and
    /// minimumFeedbackVertexSet().
    var feedbackArcs: [[Int]]?
    var feedbackVertices: [Int]?
}

/// Traversal: allSimplePaths from the first source to the target, unbounded and with maxLength 3
/// (nil past `cycleLimit` paths, and on cases above `enumerationLimit` vertices), and (directed) the number of topological orders (nil past
/// `cycleLimit`), with whether every path and order is valid and the orders are in
/// lexicographic order.
struct TraversalAnswers: Encodable {
    var paths: [[Int]]?
    var boundedPaths: [[Int]]?
    var pathsValid = true
    var topologicalSorts: Int?
    var sortsValid = true
}

let cycleLimit = 3000
/// The most vertices a case has for the enumerations whose time between answers is not bounded
/// (all simple paths, chordless cycles); the larger cases skip them.
let enumerationLimit = 30

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

struct DirectedConnectivity: Encodable {
    let strong: [[Int]]
    let nontrivial: [[Int]]
}

/// The self-loop edges as their endpoint pairs, in the library's order.
struct SelfLoopAnswers: Encodable {
    let hasSelfLoops: Bool
    let vertices: [Int]
    let edges: [[Int]]
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
    /// The weights of the first 64 spanning forests in nondecreasing weight, on at most 12 edges.
    let forestWeights: [Int]?
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
    /// ParallelCentrality's measures at three tasks.
    var parallelBetweenness: [Double] = []
    var parallelWeightedBetweenness: [Double] = []
    var parallelCloseness: [Double] = []
    var parallelHarmonic: [Double] = []
    /// Edge betweenness as [u, v, score] per edge; normalized, unnormalized, weighted (|w| + 1).
    var edgeBetweenness: [[Double]] = []
    var edgeBetweennessRaw: [[Double]] = []
    var weightedEdgeBetweenness: [[Double]] = []
    /// From the case's sources as pivots: vertex betweenness (NaN as nil), with endpoints, and
    /// unweighted and weighted edge betweenness.
    var pivotBetweenness: [Double?] = []
    var pivotBetweennessEndpoints: [Double] = []
    var pivotEdgeBetweenness: [[Double]] = []
    var weightedPivotEdgeBetweenness: [[Double]] = []
    var eigenvector: [Double]?
    var katz: [Double]?
    var pageRank: [Double]?
    var weightedPageRank: [Double]?
    var hubs: [Double]?
    var authorities: [Double]?
    /// One-vertex forms, floating-point weights and the directed view agree with the rest.
    var consistent = true
    /// Load, percolation, group, VoteRank, current-flow and subgraph centrality (CentralityExtras.swift).
    var extras = CentralityExtras()
}

/// Each edge's [u, v, score].
func edgeRows<G: DirectedGraph<Int>>(_ graph: G, _ scores: EdgeCentralityScores<G.Edges.Index>) -> [[Double]] {
    graph.edges.indices.map { [Double(graph.source(ofEdgeAt: $0)), Double(graph.target(ofEdgeAt: $0)), scores.score(ofEdgeAt: $0)] }
}

func edgeRows<G: Graph<Int>>(_ graph: G, _ scores: EdgeCentralityScores<G.Edges.Index>) -> [[Double]] {
    graph.edges.indices.map { [Double(graph.edges[$0].u), Double(graph.edges[$0].v), scores.score(ofEdgeAt: $0)] }
}

func directedCentrality<G: DirectedGraph<Int>>(_ graph: G, _ n: Int, _ w: (G.Edges.Index) -> Int, pivots: [Int]) async -> CentralityAnswers {
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
    do {
        a.parallelBetweenness = await graph.betweennessCentrality(parallelism: 3).scores
        a.parallelWeightedBetweenness = await graph.betweennessCentrality(weight: { abs(w($0)) + 1 }, parallelism: 3).scores
        a.parallelCloseness = await graph.closenessCentrality(parallelism: 3).scores
        a.parallelHarmonic = await graph.harmonicCentrality(parallelism: 3).scores
    }
    a.edgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality())
    a.edgeBetweennessRaw = edgeRows(graph, graph.edgeBetweennessCentrality(normalized: false))
    a.weightedEdgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality(weight: { abs(w($0)) + 1 }))
    a.pivotBetweenness = graph.betweennessCentrality(pivots: pivots).scores.map { $0.isNaN ? nil : $0 }
    a.pivotBetweennessEndpoints = graph.betweennessCentrality(pivots: pivots, endpoints: true).scores
    a.pivotEdgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality(pivots: pivots))
    a.weightedPivotEdgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality(weight: { abs(w($0)) + 1 }, pivots: pivots, normalized: false))
    a.eigenvector = (try? graph.eigenvectorCentrality())?.scores
    a.katz = (try? graph.katzCentrality())?.scores
    a.pageRank = (try? graph.pageRank())?.scores
    a.weightedPageRank = (try? graph.pageRank(weight: { Double(abs(w($0))) }))?.scores
    let hits = try? graph.hits()
    a.hubs = hits?.hubs.scores
    a.authorities = hits?.authorities.scores
    a.consistent = (0 ..< n).allSatisfy { v in
        graph.closenessCentrality(of: v) == a.closeness[v] && graph.harmonicCentrality(of: v) == a.harmonic[v]
            && graph.closenessCentrality(of: v, weight: { Double(abs(w($0))) }) == a.weightedCloseness[v]
            && graph.harmonicCentrality(of: v, weight: { abs(w($0)) }) == a.weightedHarmonic[v]
    }
    a.extras = directedCentralityExtras(graph, n, w)
    return a
}

func undirectedCentrality<G: Graph<Int>>(_ graph: G, _ n: Int, _ w: (G.Edges.Index) -> Int, pivots: [Int]) async -> CentralityAnswers {
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
    do {
        a.parallelBetweenness = await graph.betweennessCentrality(parallelism: 3).scores
        a.parallelWeightedBetweenness = await graph.betweennessCentrality(weight: { abs(w($0)) + 1 }, parallelism: 3).scores
        a.parallelCloseness = await graph.closenessCentrality(parallelism: 3).scores
        a.parallelHarmonic = await graph.harmonicCentrality(parallelism: 3).scores
    }
    a.edgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality())
    a.edgeBetweennessRaw = edgeRows(graph, graph.edgeBetweennessCentrality(normalized: false))
    a.weightedEdgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality(weight: { abs(w($0)) + 1 }))
    a.pivotBetweenness = graph.betweennessCentrality(pivots: pivots).scores.map { $0.isNaN ? nil : $0 }
    a.pivotBetweennessEndpoints = graph.betweennessCentrality(pivots: pivots, endpoints: true).scores
    a.pivotEdgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality(pivots: pivots))
    a.weightedPivotEdgeBetweenness = edgeRows(graph, graph.edgeBetweennessCentrality(weight: { abs(w($0)) + 1 }, pivots: pivots, normalized: false))
    a.eigenvector = (try? graph.eigenvectorCentrality())?.scores
    a.katz = (try? graph.katzCentrality())?.scores
    a.pageRank = (try? graph.pageRank())?.scores
    a.weightedPageRank = (try? graph.pageRank(weight: { Double(abs(w($0))) }))?.scores
    let view = graph.directedView
    a.consistent = (0 ..< n).allSatisfy { v in
        graph.closenessCentrality(of: v) == a.closeness[v] && graph.harmonicCentrality(of: v) == a.harmonic[v]
            && graph.closenessCentrality(of: v, weight: { Double(abs(w($0))) }) == a.weightedCloseness[v]
            && graph.harmonicCentrality(of: v, weight: { abs(w($0)) }) == a.weightedHarmonic[v]
    }
    // The directed view: equal closeness and normalized betweenness, twice the degree; an edge's
    // two arcs add up to its normalized edge betweenness.
    let viewBetweenness = view.betweennessCentrality().scores
    let viewDegree = view.degreeCentrality().scores
    let viewEdges = view.edgeBetweennessCentrality()
    let edges = graph.edgeBetweennessCentrality()
    if view.closenessCentrality().scores != a.closeness
        || (0 ..< n).contains(where: { abs(viewBetweenness[$0] - a.betweenness[$0]) > 1e-9 || abs(viewDegree[$0] - (n == 1 ? 1 : 2 * a.degree[$0])) > 1e-12 })
        || graph.edges.indices.contains(where: { p in
            abs(viewEdges.score(ofEdgeAt: .init(position: p, reversed: false)) + viewEdges.score(ofEdgeAt: .init(position: p, reversed: true)) - edges.score(ofEdgeAt: p)) > 1e-9
        }) {
        a.consistent = false
    }
    a.extras = undirectedCentralityExtras(graph, n, w)
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
    /// Undirected cases with at most 30 vertices: Girvan–Newman's first five levels.
    var girvanNewman: [[Int]]?
    /// Leiden, Louvain's levels, Kernighan–Lin, k-clique, fluid, Walktrap and spectral clustering
    /// (CommunityExtras.swift).
    var extras = CommunityExtras()
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
    a.extras = directedCommunityExtras(graph, n, dw)
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
    if n <= 30 { a.girvanNewman = graph.girvanNewmanCommunities().prefix(5).map { labels($0, n) } }
    a.louvainModularity = graph.modularity(of: louvain)
    a.singletonModularity = graph.modularity(of: (0 ..< n).map { [$0] })
    a.extras = undirectedCommunityExtras(graph, n, dw)
    return a
}

/// Bipartiteness on the undirected graph (a directed case through `.undirectedView`): the canonical
/// side per vertex (0 left), the odd cycle (checked for validity by the script), and for bipartite
/// graphs the projection onto the left side and the round trip through `BipartiteGraph`.
struct BipartiteAnswers: Encodable {
    var isBipartite = false
    var sides: [Int]?
    var oddCycle: [Int]?
    var oddCycleEdges: [[Int]]?
    var projectionEdges: [[Int]]?
    /// The weighted projections onto the left side, by position of `projectionEdges`, and whether
    /// each one's graph is the plain projection's.
    var sharedWeights: [Int]?
    var jaccardWeights: [Double]?
    var lesserOverlapWeights: [Double]?
    var collaborationWeights: [Double]?
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
        func weights<W>(_ p: WeightedProjection<Int, W>) -> [W] {
            if p.graph.edges.map({ [$0.u, $0.v] }) != a.projectionEdges { a.consistent = false }
            return p.graph.edges.indices.map { p.graph[p.weights, ofEdgeAt: $0] }
        }
        a.sharedWeights = weights(built.weightedProjectedGraph(onto: .left))
        a.jaccardWeights = weights(built.overlapWeightedProjectedGraph(onto: .left))
        a.lesserOverlapWeights = weights(built.overlapWeightedProjectedGraph(onto: .left, jaccard: false))
        a.collaborationWeights = weights(built.collaborationWeightedProjectedGraph(onto: .left))
    }
    return a
}

/// Matchings on the undirected graph (a directed case through `.undirectedView`), as endpoint pairs:
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
    var bMatching: [[Int]]?
    var bMatchingWeight: Int?
    var bMatchingCapacity: [Int]?
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
        // A b-matching with capacities 0, 1, 2 by vertex number, on the case's weights.
        let capacity = graph.vertices.map { $0 % 3 }
        let bMatching = graph.maximumWeightBMatching(bipartition: partition, capacity: { $0 % 3 }, weight: w)
        a.bMatching = pairs(bMatching.edges)
        a.bMatchingWeight = bMatching.weight
        a.bMatchingCapacity = capacity
        a.consistent = a.consistent && bMatching.edges.map(w).reduce(0, +) == bMatching.weight
            && graph.vertices.allSatisfy { bMatching.degree(of: $0) <= $0 % 3 && bMatching.matchedEdges(of: $0).count == bMatching.degree(of: $0) }
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
    var leastMinimumVertexCover: [Int]?
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
        // The script compares the lexicographically first set; the fast spelling must match its size.
        let mis = graph.lexicographicallyFirstMaximumIndependentSet(), cover = graph.minimumVertexCover()
        let fast = graph.maximumIndependentSet()
        a.maximumIndependentSet = mis
        a.independenceNumber = graph.independenceNumber()
        a.minimumVertexCover = cover
        let leastCover = graph.lexicographicallyFirstMinimumVertexCover()
        a.leastMinimumVertexCover = leastCover
        a.consistent = a.consistent && graph.isIndependentSet(mis) && graph.isVertexCover(cover) && mis.count + cover.count == graph.vertexCount
            && a.independenceNumber == mis.count && fast.count == mis.count && graph.isIndependentSet(fast)
            && graph.isVertexCover(leastCover) && leastCover.count == cover.count
    }
    if graph.vertexCount <= 16 {
        let dominating = graph.lexicographicallyFirstMinimumDominatingSet()
        let fast = graph.minimumDominatingSet()
        a.minimumDominatingSet = dominating
        a.consistent = a.consistent && graph.isDominatingSet(dominating) && fast.count == dominating.count && graph.isDominatingSet(fast)
    }
    if let cover = graph.minimumEdgeCover() {
        a.edgeCover = cover.map { [graph.edges[$0].u, graph.edges[$0].v] }
        a.consistent = a.consistent && graph.isEdgeCover(cover)
    }
    return a
}

/// Colouring on the undirected graph (a directed case through `.undirectedView`): every greedy
/// strategy's colours, first fit in reverse vertex order, the exact colouring on small graphs,
/// Misra–Gries on the simple graph (self-loops dropped, parallel copies once, first appearance
/// order), König and the greedy edge colouring on the graph itself (parallel copies kept), igraph's
/// colored neighbours, every strategy with fixed preset colours, and the checks against fixed
/// colourings the script judges on its own.
struct ColoringAnswers: Encodable {
    var greedy: [String: [Int]] = [:]
    var coloredNeighbors: [Int] = []
    /// The preset colour of each vertex (−1 for none), and every strategy's colours from them.
    var preset: [Int] = []
    var presetGreedy: [String: [Int]] = [:]
    /// The greedy edge colouring's colour per edge of the graph, in position order.
    var greedyEdgeColors: [Int] = []
    var reversedOrder: [Int] = []
    var chromaticNumber: Int?
    var minimum: [Int]?
    var lexicographicallyFirstMinimum: [Int]?
    /// The simple graph's edges, in its position order, and Misra–Gries's colour for each.
    var simpleEdges: [[Int]] = []
    var edgeColors: [Int] = []
    var edgeColorCount = 0
    /// The graph's edges in position order.
    var edges: [[Int]] = []
    /// König's colour per edge of the graph, in position order; nil when it is not bipartite.
    var bipartiteEdgeColors: [Int]?
    var bipartiteEdgeColorCount: Int?
    /// isVertexColoring of v mod 2 and v mod 3, isEdgeColoring of position mod 3 and of the position.
    var isVertexColoringMod2 = false
    var isVertexColoringMod3 = false
    var isEdgeColoringMod3 = false
    var isEdgeColoringDistinct = false
    var consistent = true
}

func coloringAnswers<G: Graph<Int>>(_ graph: G) -> ColoringAnswers {
    var a = ColoringAnswers()
    let n = graph.vertexCount
    // Every result is proper by isVertexColoring, and its colour classes, colour(of:) and colorCount agree.
    func check(_ coloring: Coloring<G>) -> [Int] {
        let colors = graph.vertices.map { coloring.color(of: $0) }
        let classes = coloring.colorClasses
        a.consistent = a.consistent && graph.isVertexColoring { coloring.color(of: $0) }
            && classes.count == coloring.colorCount && classes.allSatisfy { !$0.isEmpty }
            && classes.enumerated().allSatisfy { c, members in members.allSatisfy { colors[$0] == c } }
            && classes.reduce(0) { $0 + $1.count } == n
            && (0 ..< n).allSatisfy { coloring.color(ofIndex: $0) == colors[$0] }
        return colors
    }
    let names: [(ColoringStrategy, String)] = [
        (.largestFirst, "largestFirst"), (.smallestLast, "smallestLast"),
        (.saturationLargestFirst, "saturationLargestFirst"), (.independentSet, "independentSet"),
        (.connectedSequentialBreadthFirst, "connectedSequentialBreadthFirst"),
        (.connectedSequentialDepthFirst, "connectedSequentialDepthFirst"),
    ]
    for (strategy, name) in names { a.greedy[name] = check(graph.greedyColoring(strategy: strategy)) }
    a.coloredNeighbors = check(graph.greedyColoring(strategy: .coloredNeighbors))
    // Presets: every third vertex v takes (v / 3) mod 4 unless a neighbour preset before it has it.
    var preset = [Int?](repeating: nil, count: n)
    for v in stride(from: 0, to: n, by: 3) {
        let c = (v / 3) % 4
        if !graph.neighbors(of: v).contains(where: { $0 != v && preset[$0] == c }) { preset[v] = c }
    }
    a.preset = preset.map { $0 ?? -1 }
    for (strategy, name) in names + [(.coloredNeighbors, "coloredNeighbors")] {
        let coloring = graph.greedyColoring(strategy: strategy) { preset[$0] }
        let colors = graph.vertices.map { coloring.color(of: $0) }
        let classes = coloring.colorClasses
        a.consistent = a.consistent && graph.isVertexColoring { coloring.color(of: $0) } && coloring.colors == colors
            && classes.count == coloring.colorCount && classes.reduce(0) { $0 + $1.count } == n
            && classes.enumerated().allSatisfy { c, members in members.allSatisfy { colors[$0] == c } }
        a.presetGreedy[name] = colors
    }
    a.consistent = a.consistent && graph.greedyColoring() == graph.greedyColoring(strategy: .largestFirst)
    a.reversedOrder = check(graph.greedyColoring(order: graph.vertices.reversed()))
    if n <= 40 {
        let minimum = graph.minimumColoring()
        a.minimum = check(minimum)
        let first = graph.lexicographicallyFirstMinimumColoring()
        a.lexicographicallyFirstMinimum = check(first)
        a.chromaticNumber = graph.chromaticNumber()
        a.consistent = a.consistent && minimum.colorCount == a.chromaticNumber && first.colorCount == a.chromaticNumber
    }
    var seen = Set<UndirectedEdge<Int>>()
    var simple: [UndirectedEdge<Int>] = []
    for e in graph.edges where e.u != e.v && seen.insert(UndirectedEdge(e.u, e.v)).inserted { simple.append(UndirectedEdge(e.u, e.v)) }
    let s = UndirectedAdjacencyList(vertices: 0 ..< n, edges: simple)
    let edgeColoring = s.edgeColoring()
    a.simpleEdges = s.edges.map { [$0.u, $0.v] }
    a.edgeColors = s.edges.indices.map { edgeColoring.color(ofEdgeAt: $0) }
    a.edgeColorCount = edgeColoring.colorCount
    func consistent<H: Graph>(_ h: H, _ c: EdgeColoring<H>) -> Bool {
        let classes = c.colorClasses
        return h.isEdgeColoring { c.color(ofEdgeAt: $0) } && classes.count == c.colorCount && classes.allSatisfy { !$0.isEmpty }
            && classes.enumerated().allSatisfy { k, members in members.allSatisfy { c.color(ofEdgeAt: $0) == k } }
            && classes.reduce(0) { $0 + $1.count } == h.edgeCount
    }
    a.consistent = a.consistent && consistent(s, edgeColoring)
    let konig = graph.bipartiteEdgeColoring()
    a.consistent = a.consistent && (konig != nil) == graph.isBipartite
    if let konig {
        a.bipartiteEdgeColors = graph.edges.indices.map { konig.color(ofEdgeAt: $0) }
        a.bipartiteEdgeColorCount = konig.colorCount
        a.consistent = a.consistent && consistent(graph, konig)
    }
    let greedyEdges = graph.greedyEdgeColoring()
    a.greedyEdgeColors = graph.edges.indices.map { greedyEdges.color(ofEdgeAt: $0) }
    a.consistent = a.consistent && consistent(graph, greedyEdges)
    a.edges = graph.edges.map { [$0.u, $0.v] }
    let positions = Array(graph.edges.indices)
    var rank: [G.Edges.Index: Int] = [:]
    for (i, p) in positions.enumerated() { rank[p] = i }
    a.isVertexColoringMod2 = graph.isVertexColoring { $0 % 2 }
    a.isVertexColoringMod3 = graph.isVertexColoring { $0 % 3 }
    a.isEdgeColoringMod3 = graph.isEdgeColoring { rank[$0]! % 3 }
    a.isEdgeColoringDistinct = graph.isEdgeColoring { rank[$0]! * 1000 - 7 }
    return a
}

func answer<G: DirectedGraph<Int>>(_ graph: G, _ c: Case, _ weight: (G.Edges.Index) -> Int,
                                   _ dijkstraTree: () -> ShortestPathTree<G, Int>,
                                   _ single: () -> (path: Path<Int, G.Edges.Index>, distance: Int)?,
                                   _ bellmanFord: () -> ShortestPathTree<G, Int>?,
                                   _ goldbergRadzik: () -> ShortestPathTree<G, Int>?,
                                   _ witness: () -> [Int]?, _ wholeGraph: () -> [Int]?, _ unweighted: () -> ShortestPathTree<G, Int>) -> Result {
    guard wants("shortestpaths") else { return Result() }
    let nonnegative = c.edges.allSatisfy { $0[2] >= 0 }
    var result = Result(unweighted: (0 ..< c.n).map { unweighted().distance(to: $0) })
    if nonnegative {
        let tree = dijkstraTree()
        result.dijkstra = (0 ..< c.n).map { tree.distance(to: $0) }
        let s = single()
        result.single = Single(reached: s != nil, distance: s?.distance, path: s?.path.vertices)
    }
    result.bellmanFord = bellmanFord().map { tree in (0 ..< c.n).map { tree.distance(to: $0) } }
    result.goldbergRadzik = goldbergRadzik().map { tree in (0 ..< c.n).map { tree.distance(to: $0) } }
    result.witness = witness()
    result.wholeGraphWitness = wholeGraph()
    return result
}

let sections = Set(CommandLine.arguments.dropFirst())
func wants(_ section: String) -> Bool { sections.isEmpty || sections.contains(section) }

if CommandLine.arguments.dropFirst().first == "flows-catalog" {
    let requests = try JSONDecoder().decode([CatalogRequest].self, from: FileHandle.standardInput.readDataToEndOfFile())
    FileHandle.standardOutput.write(try JSONEncoder().encode(requests.map(answerCatalog)))
    exit(0)
}

if CommandLine.arguments.dropFirst().first == "formats" {
    let requests = try JSONDecoder().decode([FormatRequest].self, from: FileHandle.standardInput.readDataToEndOfFile())
    FileHandle.standardOutput.write(try JSONEncoder().encode(requests.map(answerFormat)))
    exit(0)
}

if CommandLine.arguments.dropFirst().first == "tours-catalog" {
    let requests = try JSONDecoder().decode([ToursRequest].self, from: FileHandle.standardInput.readDataToEndOfFile())
    FileHandle.standardOutput.write(try JSONEncoder().encode(requests.map(answerToursCatalog)))
    exit(0)
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
            { graph.goldbergRadzikShortestPaths(from: c.sources, weight: w) },
            { graph.findNegativeCycle(from: c.sources, weight: w)?.vertices },
            { graph.findNegativeCycle(weight: w)?.vertices },
            { graph.shortestPaths(from: c.sources) }))
        if wants("shortestpaths") { results[results.count - 1].paths = pathAnswers(graph, c, w) }
        if wants("cycles") {
            var cycles = Cycles()
            let isValid = { (cycle: Cycle<Int, Int>) in Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil }
            let all = listed(graph.simpleCycles(), isValid, &cycles.valid)
            cycles.simple = all?.vertices
            cycles.simpleEdges = all?.edges
            cycles.bounded = listed(graph.simpleCycles(maxLength: 3), isValid, &cycles.valid)?.vertices
            cycles.girth = graph.girth()
            let chordless = c.n <= enumerationLimit ? listed(graph.chordlessCycles(), isValid, &cycles.valid) : nil
            cycles.chordless = chordless?.vertices
            cycles.chordlessEdges = chordless?.edges
            if let mean = graph.minimumMeanCycle(weight: w) {
                if !isValid(mean) { cycles.valid = false }
                cycles.meanCycle = mean.vertices
                cycles.meanWeight = mean.weight(w)
                cycles.meanLength = mean.length
            }
            if c.n <= 14 {
                cycles.feedbackArcs = graph.minimumFeedbackArcSet().map { [graph.edges[$0].source, graph.edges[$0].target] }
                cycles.feedbackVertices = graph.minimumFeedbackVertexSet()
            }
            results[results.count - 1].cycles = cycles
        }
        if wants("traversal") {
            var traversal = TraversalAnswers()
            func paths(_ maxLength: Int) -> [[Int]]? {
                var found: [[Int]] = []
                for path in graph.allSimplePaths(from: c.sources[0], to: c.target, maxLength: maxLength) {
                    if found.count == cycleLimit { return nil }
                    if Path(vertices: path.vertices, edges: path.edges, in: graph) == nil || path.target != c.target { traversal.pathsValid = false }
                    found.append(path.vertices)
                }
                return found
            }
            // Exponential: only on the small cases, as `enumerationLimit` says.
            if c.n <= enumerationLimit {
                traversal.paths = paths(.max)
                traversal.boundedPaths = paths(3)
            }
            var count = 0
            var previous: [Int]?
            var position = [Int](repeating: 0, count: c.n)
            for order in graph.allTopologicalSorts() {
                if count == cycleLimit { count = -1; break }
                count += 1
                for (i, v) in order.enumerated() { position[v] = i }
                if order.count != c.n || !graph.edges.allSatisfy({ position[$0.source] < position[$0.target] }) { traversal.sortsValid = false }
                if let previous, !previous.lexicographicallyPrecedes(order) { traversal.sortsValid = false }
                previous = order
            }
            traversal.topologicalSorts = count < 0 ? nil : count
            results[results.count - 1].traversal = traversal
        }
        if wants("connectivity") {
            results[results.count - 1].directedConnectivity = DirectedConnectivity(
                strong: graph.stronglyConnectedComponents().map(Array.init),
                nontrivial: graph.nontrivialStronglyConnectedComponents().map(Array.init))
            results[results.count - 1].selfLoops = SelfLoopAnswers(
                hasSelfLoops: graph.hasSelfLoops, vertices: graph.verticesWithSelfLoops(),
                edges: graph.selfLoopEdges().map { [graph.edges[$0].source, graph.edges[$0].target] })
        }
        if wants("trees") {
            var trees = TreeAnswers()
            trees.isArborescence = graph.isArborescence
            if let arborescence = Arborescence(graph) {
                trees.arborescence = true
                trees.root = arborescence.root
                trees.preorder = Array(arborescence.preorder)
            }
            results[results.count - 1].trees = trees
        }
        if wants("distances") {
            let nonnegative = weights.allSatisfy { $0 >= 0 }
            let directedEccentricities = graph.eccentricities()
            var answers = basics(directedEccentricities, c.n)
            answers.centroid = graph.centroid()
            answers.wiener = graph.wienerIndex().map { Int($0) }
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
        }
        if wants("centrality") { results[results.count - 1].centrality = await directedCentrality(graph, c.n, w, pivots: c.sources) }
        if wants("communities") { results[results.count - 1].communities = directedCommunities(graph, c.n, w) }
        if wants("communities"), let p = c.plantedPartition { results[results.count - 1].communities.extras.spectralClusters = plantedSpectralClusters(p) }
        if wants("bipartite") { results[results.count - 1].bipartite = bipartiteAnswers(graph.undirectedView, c.n) }
        if wants("matching") { results[results.count - 1].matching = matchingAnswers(graph.undirectedView, { weights[$0] }) }
        if wants("covering") { results[results.count - 1].covering = coveringAnswers(graph.undirectedView) }
        if wants("coloring") { results[results.count - 1].coloring = coloringAnswers(graph.undirectedView) }
        if wants("flows"), let f = c.flow { results[results.count - 1].flows = flowAnswers(directed: true, n: c.n, f) }
        if wants("tours"), let t = c.tours { results[results.count - 1].tours = toursAnswers(directed: true, n: c.n, edges: c.edges, sources: c.sources, target: c.target, t) }
        if wants("dag") { results[results.count - 1].dag = directedAcyclicGraphAnswers(n: c.n, edges: c.edges, source: c.sources[0], target: c.target) }
        if wants("dag") { results[results.count - 1].dSeparation = dSeparationAnswers(n: c.n, edges: c.edges, sources: c.sources, target: c.target) }
        if wants("planarity") { results[results.count - 1].planarity = planarityAnswers(n: c.n, edges: c.edges) }
        if wants("spanningtrees") { results[results.count - 1].arborescences = arborescenceAnswers(n: c.n, edges: c.edges, root: c.sources[0]) }
        if wants("assortativity") { results[results.count - 1].assortativity = assortativityAnswers(directed: true, n: c.n, edges: c.edges) }
        if wants("similarity") { results[results.count - 1].similarity = directedSimilarityAnswers(n: c.n, edges: c.edges) }
        if wants("isomorphism") { results[results.count - 1].isomorphism = isomorphismAnswers(directed: true, n: c.n, edges: c.edges) }
        if wants("drawing") { results[results.count - 1].drawing = drawingAnswers(n: c.n, edges: c.edges) }
        if wants("operations") { results[results.count - 1].operations = directedOperationsAnswers(n: c.n, edges: c.edges, sources: c.sources, target: c.target) }
        if wants("generators"), let g = c.generators { results[results.count - 1].generators = generatorAnswers(g) }
        if wants("spectral") { results[results.count - 1].spectral = spectralAnswers(directed: true, n: c.n, edges: c.edges, source: c.sources[0], target: c.target) }
    } else {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< c.n, edges: c.edges.map { UndirectedEdge($0[0], $0[1]) })
        var byEdge: [UndirectedEdge<Int>: Int] = [:]
        for e in c.edges { byEdge[UndirectedEdge(e[0], e[1])] = e[2] }
        let weights = graph.edges.map { byEdge[$0]! }
        let w: (Int) -> Int = { weights[$0] }
        let view = graph.directedView
        var result = answer(view, c, { weights[$0.position] },
            { graph.dijkstraShortestPaths(from: c.sources, cutoff: c.cutoff, weight: w) },
            { graph.dijkstraShortestPath(from: c.sources[0], to: c.target, weight: w) },
            { graph.bellmanFordShortestPaths(from: c.sources, weight: w) },
            { graph.goldbergRadzikShortestPaths(from: c.sources, weight: w) },
            { graph.findNegativeCycle(from: c.sources, weight: w)?.vertices },
            { graph.findNegativeCycle(weight: w)?.vertices },
            { graph.shortestPaths(from: c.sources) })
        if wants("shortestpaths") { result.paths = pathAnswers(view, c, { weights[$0.position] }) }
        if wants("spanningtrees") {
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
                unweighted: graph.minimumSpanningTree().edges,
                forestWeights: c.edges.count <= 12 ? graph.spanningForests(weight: w).prefix(64).map(\.weight) : nil)
            result.spanning = spanning
            var terminals: [Int] = []
            for v in c.sources + [c.target] where !terminals.contains(v) { terminals.append(v) }
            result.steiner = steinerAnswers(n: c.n, edges: c.edges, terminals: terminals)
        }
        if wants("connectivity") {
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
            result.selfLoops = SelfLoopAnswers(
                hasSelfLoops: graph.hasSelfLoops, vertices: graph.verticesWithSelfLoops(),
                edges: graph.selfLoopEdges().map { [graph.edges[$0].u, graph.edges[$0].v] })
        }
        if wants("cycles") {
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
            let minimum = graph.minimumCycleBasis()
            if !minimum.allSatisfy(isValid) { cycles.valid = false }
            cycles.minimumBasisEdges = minimum.map(\.edges)
            let weighted = graph.minimumCycleBasis(weight: { Double($0 % 4 + 1) })
            if !weighted.allSatisfy(isValid) { cycles.valid = false }
            cycles.minimumBasisWeight = weighted.reduce(0) { $0 + $1.edges.reduce(0) { $0 + $1 % 4 + 1 } }
            let chordless = c.n <= enumerationLimit ? listed(graph.chordlessCycles(), isValid, &cycles.valid) : nil
            cycles.chordless = chordless?.vertices
            cycles.chordlessEdges = chordless?.edges
            if c.n <= 14 { cycles.feedbackVertices = graph.minimumFeedbackVertexSet() }
            result.cycles = cycles
        }
        if wants("traversal") {
            var traversal = TraversalAnswers()
            func paths(_ maxLength: Int) -> [[Int]]? {
                var found: [[Int]] = []
                for path in graph.allSimplePaths(from: c.sources[0], to: c.target, maxLength: maxLength) {
                    if found.count == cycleLimit { return nil }
                    if Path(vertices: path.vertices, edges: path.edges, in: graph) == nil || path.target != c.target { traversal.pathsValid = false }
                    found.append(path.vertices)
                }
                return found
            }
            // Exponential: only on the small cases, as `enumerationLimit` says.
            if c.n <= enumerationLimit {
                traversal.paths = paths(.max)
                traversal.boundedPaths = paths(3)
            }
            result.traversal = traversal
        }
        if wants("trees") {
            var trees = TreeAnswers()
            trees.isTree = graph.isTree
            let words = (0 ..< c.n).map { Array(graph.neighbors(of: $0)) }
            let trie = prefixTree(of: words)
            var spelled = [[Int]](repeating: [], count: trie.arborescence.vertexCount)
            for v in 1 ..< max(spelled.count, 1) { spelled[v] = spelled[trie.arborescence.parent(of: v)!] + [trie.symbol(ofEdgeAt: v - 1)] }
            trees.prefixWords = words
            trees.prefixes = spelled
            trees.prefixEnds = trie.sequenceEnds.map { spelled[$0] }
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
        }
        if wants("distances") {
            let nonnegativeWeights = weights.allSatisfy { $0 >= 0 }
            let undirectedEccentricities = graph.eccentricities()
            var answers = basics(undirectedEccentricities, c.n)
            answers.centroid = graph.centroid()
            answers.wiener = graph.wienerIndex().map { Int($0) }
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
        }
        if wants("cliques") {
            var cliques = CliqueAnswers()
            cliques.maximal = Array(graph.maximalCliques())
            cliques.cliqueNumber = graph.cliqueNumber()
            cliques.maximum = graph.lexicographicallyFirstMaximumClique()
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
            cliques.isChordal = graph.isChordal
            cliques.eliminationOrder = graph.perfectEliminationOrdering()
            if let order = cliques.eliminationOrder { cliques.eliminationIsReversedSearch = order == graph.maximumCardinalitySearch().reversed() }
            cliques.chordalCliques = graph.chordalGraphCliques()
            cliques.treewidth = graph.chordalGraphTreewidth()
            let minDegree = graph.treewidthMinDegree(), minFillIn = graph.treewidthMinFillIn()
            cliques.minDegreeBags = minDegree.bags
            cliques.minDegreeEdges = minDegree.edges.map { [$0.u, $0.v] }
            cliques.minDegreeWidth = minDegree.width
            cliques.minFillInBags = minFillIn.bags
            cliques.minFillInEdges = minFillIn.edges.map { [$0.u, $0.v] }
            cliques.minFillInWidth = minFillIn.width
            cliques.decompositionsValid = graph.isTreeDecomposition(minDegree) && graph.isTreeDecomposition(minFillIn)
            if let hole = graph.findHole() {
                cliques.hole = hole.vertices
                cliques.holeValid = Cycle(vertices: hole.vertices, edges: hole.edges, in: graph) != nil
            }
            result.cliques = cliques
        }
        if wants("cliques") { result.cliqueExtras = cliqueExtraAnswers(n: c.n, edges: c.edges, target: c.target) }
        if wants("connectivity") { result.edgeConnectivity = edgeConnectivityAnswers(n: c.n, edges: c.edges) }
        if wants("centrality") { result.centrality = await undirectedCentrality(graph, c.n, w, pivots: c.sources) }
        if wants("communities") { result.communities = undirectedCommunities(graph, c.n, w) }
        if wants("communities"), let p = c.plantedPartition { result.communities.extras.spectralClusters = plantedSpectralClusters(p) }
        if wants("bipartite") { result.bipartite = bipartiteAnswers(graph, c.n) }
        if wants("matching") { result.matching = matchingAnswers(graph, w) }
        if wants("covering") { result.covering = coveringAnswers(graph) }
        if wants("coloring") { result.coloring = coloringAnswers(graph) }
        if wants("flows"), let f = c.flow { result.flows = flowAnswers(directed: false, n: c.n, f) }
        if wants("tours"), let t = c.tours { result.tours = toursAnswers(directed: false, n: c.n, edges: c.edges, sources: c.sources, target: c.target, t) }
        if wants("planarity") { result.planarity = planarityAnswers(n: c.n, edges: c.edges) }
        if wants("assortativity") { result.assortativity = assortativityAnswers(directed: false, n: c.n, edges: c.edges) }
        if wants("similarity") { result.similarity = undirectedSimilarityAnswers(graph, n: c.n) }
        if wants("isomorphism") { result.isomorphism = isomorphismAnswers(directed: false, n: c.n, edges: c.edges) }
        if wants("drawing") { result.drawing = drawingAnswers(n: c.n, edges: c.edges) }
        if wants("operations") { result.operations = undirectedOperationsAnswers(n: c.n, edges: c.edges, sources: c.sources, target: c.target) }
        if wants("generators"), let g = c.generators { result.generators = generatorAnswers(g) }
        if wants("spectral") { result.spectral = spectralAnswers(directed: false, n: c.n, edges: c.edges, source: c.sources[0], target: c.target) }
        results.append(result)
    }
}
let encoder = JSONEncoder()
FileHandle.standardOutput.write(try encoder.encode(results))
