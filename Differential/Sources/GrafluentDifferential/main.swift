// Reads a JSON array of cases on standard input and writes a JSON array of results, one per case,
// in order. Each case is a simple graph on 0..<n (self-loops allowed, no repeated pair) with
// integer weights, sources, an optional cutoff and a target.

import AdjacencyListModule
import Connectivity
import Foundation
import GraphProtocols
import ShortestPaths
import SpanningTrees

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
                                   _ single: () -> (path: [Int], edges: [G.Edges.Index], distance: Int)?,
                                   _ bellmanFord: () -> ShortestPathTree<G, Int>?,
                                   _ witness: () -> [Int]?, _ wholeGraph: () -> [Int]?, _ unweighted: () -> ShortestPathTree<G, Int>) -> Result {
    let nonnegative = c.edges.allSatisfy { $0[2] >= 0 }
    var result = Result(unweighted: (0 ..< c.n).map { unweighted().distance(to: $0) })
    if nonnegative {
        let tree = dijkstraTree()
        result.dijkstra = (0 ..< c.n).map { tree.distance(to: $0) }
        let s = single()
        result.single = Single(reached: s != nil, distance: s?.distance, path: s?.path)
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
            { graph.findNegativeCycle(from: c.sources, weight: w) },
            { graph.findNegativeCycle(weight: w) },
            { graph.shortestPaths(from: c.sources) }))
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
            { graph.findNegativeCycle(from: c.sources, weight: w) },
            { graph.findNegativeCycle(weight: w) },
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
        results.append(result)
    }
}
let encoder = JSONEncoder()
FileHandle.standardOutput.write(try encoder.encode(results))
