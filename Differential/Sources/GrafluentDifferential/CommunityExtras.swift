// Community detection beyond CommunityAnswers' deterministic rules: Leiden (both quality
// functions), Louvain's levels, Kernighan–Lin bisection from a fixed split, k-clique percolation,
// asynchronous fluid communities, Walktrap, and spectral clustering of a planted partition. The
// script checks Leiden's partitions for node
// optimality and connectivity and compares its modularity with igraph's, compares Kernighan–Lin
// and k-clique communities with NetworkX exactly, Walktrap's modularity with igraph's, and the
// spectral clustering with the planted labels. The randomized calls draw from Tours.swift's
// SplitMix64.

import CommunityDetection
import GraphProtocols
import Multigraphs

/// The planted partition spectral clustering is run on: a graph on 0..<n, its edges, the cluster
/// count and the k-means++ seed.
struct PlantedPartitionCase: Decodable {
    let n: Int
    let edges: [[Int]]
    let clusters: Int
    let seed: UInt64
}

struct CommunityExtras: Encodable {
    /// Leiden with modularity (unweighted and |w|) and the constant Potts model at γ = 0.1.
    var leiden: [Int] = []
    var weightedLeiden: [Int] = []
    var leidenPotts: [Int] = []
    var leidenModularity = 0.0
    /// The greatest modularity of five more Leiden runs, each from its own generator.
    var leidenBestModularity = 0.0
    var leidenPottsQuality = 0.0
    /// Whether louvainPartitions() ends with louvainCommunities(), each level coarsening the last.
    var louvainLevelsAgree = true
    /// Undirected only: Kernighan–Lin from {0 ..< n/2}, {n/2 ..< n}, unweighted and |w|.
    var kernighanLin: [Int]?
    var weightedKernighanLin: [Int]?
    /// Undirected only: k-clique communities for k = 3 and 4, each sorted.
    var kClique3: [[Int]]?
    var kClique4: [[Int]]?
    /// Undirected, connected, n ≥ 2: fluid communities with k = 2.
    var fluid: [Int]?
    /// Undirected only: Walktrap (t = 4), and its modularity.
    var walktrap: [Int]?
    var walktrapModularity: Double?
    /// With a planted partition: the spectral clustering's community per vertex; nil when it threw.
    var spectralClusters: [Int]?
    /// Undirected only: Infomap (10 trials), unweighted and |w|, and the code length of each.
    var infomap: [Int]?
    var infomapCodeLength: Double?
    var weightedInfomap: [Int]?
    var weightedInfomapCodeLength: Double?
}

/// Spectral clustering of the planted partition into its cluster count, seeded by the case.
func plantedSpectralClusters(_ planted: PlantedPartitionCase) -> [Int]? {
    let blocks = Pseudograph(vertices: 0 ..< planted.n, edges: planted.edges.map { UndirectedEdge($0[0], $0[1]) })
    var generator = SplitMix64(state: planted.seed)
    guard let clustering = try? blocks.spectralClustering(clusterCount: planted.clusters, using: &generator) else { return nil }
    return labels(clustering, planted.n)
}

func louvainLevelsAgree<G: DirectedGraph<Int>>(_ levels: [Partition<G>], _ final: Partition<G>, _ n: Int) -> Bool {
    guard levels.last == final else { return false }
    for (finer, coarser) in zip(levels, levels.dropFirst()) {
        for community in finer where !community.allSatisfy({ coarser.community(of: $0) == coarser.community(of: community.first!) }) {
            return false
        }
    }
    return true
}

func directedCommunityExtras<G: DirectedGraph<Int>>(_ graph: G, _ n: Int, _ dw: (G.Edges.Index) -> Double) -> CommunityExtras {
    var a = CommunityExtras()
    var generator = SplitMix64(state: UInt64(n) &* 31 &+ 7)
    let leiden = graph.leidenCommunities(using: &generator)
    a.leiden = labels(leiden, n)
    a.leidenModularity = graph.modularity(of: leiden)
    a.leidenBestModularity = (1 ... 5).map { seed -> Double in
        var g = SplitMix64(state: UInt64(seed) &* 1_000_003)
        return graph.modularity(of: graph.leidenCommunities(using: &g))
    }.max()!
    a.weightedLeiden = labels(graph.leidenCommunities(weight: dw, using: &generator), n)
    let potts = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.1, using: &generator)
    a.leidenPotts = labels(potts, n)
    a.leidenPottsQuality = graph.constantPottsModel(of: potts, resolution: 0.1)
    a.louvainLevelsAgree = louvainLevelsAgree(graph.louvainPartitions(), graph.louvainCommunities(), n)
    return a
}

func undirectedCommunityExtras<G: Graph<Int>>(_ graph: G, _ n: Int, _ dw: (G.Edges.Index) -> Double) -> CommunityExtras {
    var a = CommunityExtras()
    var generator = SplitMix64(state: UInt64(n) &* 31 &+ 7)
    let leiden = graph.leidenCommunities(using: &generator)
    a.leiden = labels(leiden, n)
    a.leidenModularity = graph.modularity(of: leiden)
    a.leidenBestModularity = (1 ... 5).map { seed -> Double in
        var g = SplitMix64(state: UInt64(seed) &* 1_000_003)
        return graph.modularity(of: graph.leidenCommunities(using: &g))
    }.max()!
    a.weightedLeiden = labels(graph.leidenCommunities(weight: dw, using: &generator), n)
    let potts = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.1, using: &generator)
    a.leidenPotts = labels(potts, n)
    a.leidenPottsQuality = graph.constantPottsModel(of: potts, resolution: 0.1)
    a.louvainLevelsAgree = louvainLevelsAgree(graph.louvainPartitions(), graph.louvainCommunities(), n)
    let halves = [Array(0 ..< n / 2), Array(n / 2 ..< n)]
    a.kernighanLin = labels(graph.kernighanLinBisection(startingFrom: halves), n)
    a.weightedKernighanLin = labels(graph.kernighanLinBisection(startingFrom: halves, weight: dw), n)
    a.kClique3 = graph.kCliqueCommunities(3)
    a.kClique4 = graph.kCliqueCommunities(4)
    if n >= 2, graph.connectedComponents(within: [Array(0 ..< n)]).count == 1 {
        a.fluid = labels(graph.asynchronousFluidCommunities(count: 2, using: &generator), n)
    }
    let walktrap = graph.walktrapCommunities()
    a.walktrap = labels(walktrap, n)
    a.walktrapModularity = graph.modularity(of: walktrap)
    let infomap = graph.infomapCommunities(using: &generator)
    a.infomap = labels(infomap, n)
    a.infomapCodeLength = graph.codeLength(of: infomap)
    let weightedInfomap = graph.infomapCommunities(weight: dw, using: &generator)
    a.weightedInfomap = labels(weightedInfomap, n)
    a.weightedInfomapCodeLength = graph.codeLength(of: weightedInfomap, weight: dw)
    return a
}
