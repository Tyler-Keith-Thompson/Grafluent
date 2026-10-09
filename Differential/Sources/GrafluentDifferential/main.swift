// Reads a JSON array of cases on standard input and writes a JSON array of results, one per case,
// in order. Each case is a simple graph on 0..<n (self-loops allowed, no repeated pair) with
// integer weights, sources, an optional cutoff and a target.

import AdjacencyListModule
import Connectivity
import Cycles
import Distances
import Foundation
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
        results.append(result)
    }
}
let encoder = JSONEncoder()
FileHandle.standardOutput.write(try encoder.encode(results))
