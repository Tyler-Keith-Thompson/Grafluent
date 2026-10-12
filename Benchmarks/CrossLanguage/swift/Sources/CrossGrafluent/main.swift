// The Grafluent harness: `CrossGrafluent <algorithm> <instance file> <repeats>`.
//
// Reads one instance (gen.py's format), builds the graph outside the timed region, times the
// algorithm `repeats` times and prints one line per representation:
//
//     RESULT <representation> <check> <ms,ms,…>
//
// or `NA <reason>`. The check is what run.py compares across libraries.

import AdjacencyListModule
import BipartiteGraphs
import Centrality
import Cliques
import CompressedSparseRowModule
import Connectivity
import Flows
import Foundation
import GraphProtocols
import IsomorphismModule
import MatchingModule
import Multigraphs
import ShortestPaths
import SpanningTrees
import Traversal

@inline(never) @_optimize(none)
func blackHole<T>(_ value: T) {}

struct Instance {
    var n = 0, m = 0, s = 0, t = 0, nleft = 0
    var u: [Int] = [], v: [Int] = [], w: [Int] = []
    var u2: [Int] = [], v2: [Int] = []
}

func load(_ path: String) -> Instance {
    guard let data = FileManager.default.contents(atPath: path) else { fatalError("cannot read \(path)") }
    return data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Instance in
        let bytes = raw.bindMemory(to: UInt8.self)
        var i = 0
        func next() -> Int {
            while bytes[i] < 48 || bytes[i] > 57 { i += 1 }
            var x = 0
            while i < bytes.count, bytes[i] >= 48, bytes[i] <= 57 { x = x * 10 + Int(bytes[i] - 48); i += 1 }
            return x
        }
        var g = Instance()
        g.n = next(); g.m = next(); g.s = next(); g.t = next(); g.nleft = next()
        let blocks = next()
        g.u.reserveCapacity(g.m); g.v.reserveCapacity(g.m); g.w.reserveCapacity(g.m)
        for _ in 0 ..< g.m { g.u.append(next()); g.v.append(next()); g.w.append(next()) }
        if blocks > 1 {
            for _ in 0 ..< g.m { g.u2.append(next()); g.v2.append(next()); _ = next() }
        }
        return g
    }
}

func measure<R>(_ repeats: Int, _ body: () -> R) -> (R, [Double]) {
    var times: [Double] = []
    var last: R?
    for _ in 0 ..< repeats {
        let start = DispatchTime.now().uptimeNanoseconds
        let result = body()
        let end = DispatchTime.now().uptimeNanoseconds
        times.append(Double(end - start) / 1e6)
        blackHole(result)
        last = result
    }
    return (last!, times)
}

func report(_ representation: String, _ check: String, _ times: [Double]) {
    print("RESULT \(representation) \(check) \(times.map { String(format: "%.4f", $0) }.joined(separator: ","))")
}

func float(_ x: Double) -> String { String(format: "%.12e", x) }

// Everything below runs inside a function, so the graphs and weights are locals rather than
// top-level globals reached through accessors.
func main() {
    let arguments = CommandLine.arguments
    guard arguments.count == 4, let repeats = Int(arguments[3]) else {
        print("usage: CrossGrafluent <algorithm> <instance> <repeats>")
        exit(2)
    }
    let algorithm = arguments[1]
    let g = load(arguments[2])
    let n = g.n
    let directedEdges = (0 ..< g.m).map { DirectedEdge(from: g.u[$0], to: g.v[$0]) }
    let undirectedEdges = (0 ..< g.m).map { UndirectedEdge(g.u[$0], g.v[$0]) }
    let weights = g.w

    /// CSR stores rows sorted, so an edge's index is not its input position: carry the weights over.
    func csrWithWeights() -> (CompressedSparseRow, [Int]) {
        var indices: [Int] = []
        let csr = CompressedSparseRow(vertexCount: n, edges: directedEdges, edgeIndices: &indices)
        var permuted = [Int](repeating: 0, count: csr.edgeCount)
        for (i, k) in indices.enumerated() { permuted[k] += weights[i] }  // repeated arcs: capacities add
        return (csr, permuted)
    }

    func pathChecksum(_ reached: Int, _ total: Int) -> String { "\(reached),\(total)" }

    func pageRankChecksum(_ scores: [Double]) -> String {
        let sum = scores.reduce(0, +)
        var x = 0.0
        for (i, s) in scores.enumerated() { x += s / sum * Double(i % 97 + 1) }
        return float(x)
    }

    func topologicalCheck(_ order: [Int]?) -> String {
        guard let order else { return "cyclic" }
        var position = [Int](repeating: -1, count: n)
        for (k, v) in order.enumerated() { position[v] = k }
        let valid = order.count == n && (0 ..< g.m).allSatisfy { position[g.u[$0]] < position[g.v[$0]] }
        return valid ? "valid,\(order.count)" : "invalid"
    }

    switch algorithm {
    case "build-directed":
        let (list, t1) = measure(repeats) { AdjacencyList(vertices: 0 ..< n, edges: directedEdges) }
        report("AdjacencyList", "\(list.vertexCount),\(list.edgeCount)", t1)
        let (csr, t2) = measure(repeats) { CompressedSparseRow(vertexCount: n, edges: directedEdges) }
        report("CompressedSparseRow", "\(csr.vertexCount),\(csr.edgeCount)", t2)

    case "build-undirected":
        let (graph, t1) = measure(repeats) { UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges) }
        report("UndirectedAdjacencyList", "\(graph.vertexCount),\(graph.edgeCount)", t1)

    case "bfs", "dfs":
        let list = AdjacencyList(vertices: 0 ..< n, edges: directedEdges)
        let csr = CompressedSparseRow(vertexCount: n, edges: directedEdges)
        if algorithm == "bfs" {
            let (a, t1) = measure(repeats) { var c = 0; list.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { c += 1 } }; return c }
            report("AdjacencyList", "\(a)", t1)
            let (b, t2) = measure(repeats) { var c = 0; csr.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { c += 1 } }; return c }
            report("CompressedSparseRow", "\(b)", t2)
        } else {
            let (a, t1) = measure(repeats) { var c = 0; list.depthFirstSearch(from: 0).forEach { if case .discover = $0 { c += 1 } }; return c }
            report("AdjacencyList", "\(a)", t1)
            let (b, t2) = measure(repeats) { var c = 0; csr.depthFirstSearch(from: 0).forEach { if case .discover = $0 { c += 1 } }; return c }
            report("CompressedSparseRow", "\(b)", t2)
        }

    case "scc":
        let list = AdjacencyList(vertices: 0 ..< n, edges: directedEdges)
        let csr = CompressedSparseRow(vertexCount: n, edges: directedEdges)
        let (a, t1) = measure(repeats) { list.stronglyConnectedComponents().count }
        report("AdjacencyList", "\(a)", t1)
        let (b, t2) = measure(repeats) { csr.stronglyConnectedComponents().count }
        report("CompressedSparseRow", "\(b)", t2)

    case "cc":
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        let (a, t1) = measure(repeats) { graph.connectedComponents().count }
        report("UndirectedAdjacencyList", "\(a)", t1)

    case "dijkstra", "bellman-ford":
        let list = AdjacencyList(vertices: 0 ..< n, edges: directedEdges)
        let (csr, cw) = csrWithWeights()
        func check(_ distance: (Int) -> Int?) -> String {
            var reached = 0, total = 0
            for i in 0 ..< n { if let d = distance(i) { reached += 1; total += d } }
            return pathChecksum(reached, total)
        }
        if algorithm == "dijkstra" {
            let (a, t1) = measure(repeats) { list.dijkstraShortestPaths(from: 0) { weights[$0] } }
            report("AdjacencyList", check { a.distance(toIndex: $0) }, t1)
            let (b, t2) = measure(repeats) { csr.dijkstraShortestPaths(from: 0) { cw[$0] } }
            report("CompressedSparseRow", check { b.distance(toIndex: $0) }, t2)
        } else {
            let (a, t1) = measure(repeats) { list.bellmanFordShortestPaths(from: 0) { weights[$0] }! }
            report("AdjacencyList", check { a.distance(toIndex: $0) }, t1)
            let (b, t2) = measure(repeats) { csr.bellmanFordShortestPaths(from: 0) { cw[$0] }! }
            report("CompressedSparseRow", check { b.distance(toIndex: $0) }, t2)
        }

    case "mst-kruskal", "mst-prim":
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        if algorithm == "mst-kruskal" {
            let (f, t1) = measure(repeats) { graph.kruskalMinimumSpanningTree { weights[$0] } }
            report("UndirectedAdjacencyList", "\(f.edges.count),\(f.weight)", t1)
        } else {
            let (f, t1) = measure(repeats) { graph.primMinimumSpanningTree { weights[$0] } }
            report("UndirectedAdjacencyList", "\(f.edges.count),\(f.weight)", t1)
        }

    case "topo":
        let list = AdjacencyList(vertices: 0 ..< n, edges: directedEdges)
        let csr = CompressedSparseRow(vertexCount: n, edges: directedEdges)
        let (a, t1) = measure(repeats) { list.topologicalSort() }
        report("AdjacencyList", topologicalCheck(a), t1)
        let (b, t2) = measure(repeats) { csr.topologicalSort() }
        report("CompressedSparseRow", topologicalCheck(b), t2)

    case "maxflow-pr", "maxflow-value", "maxflow-dinic":
        let pseudo = DirectedPseudograph(vertices: 0 ..< n, edges: directedEdges)
        let (csr, cw) = csrWithWeights()
        let (s, t) = (g.s, g.t)
        switch algorithm {
        case "maxflow-pr":
            let (a, t1) = measure(repeats) { pseudo.maximumFlow(from: s, to: t) { weights[$0] }.value }
            report("DirectedPseudograph", "\(a)", t1)
            let (b, t2) = measure(repeats) { csr.maximumFlow(from: s, to: t) { cw[$0] }.value }
            report("CompressedSparseRow", "\(b)", t2)
        case "maxflow-value":
            let (a, t1) = measure(repeats) { pseudo.maximumFlowValue(from: s, to: t) { weights[$0] } }
            report("DirectedPseudograph", "\(a)", t1)
            let (b, t2) = measure(repeats) { csr.maximumFlowValue(from: s, to: t) { cw[$0] } }
            report("CompressedSparseRow", "\(b)", t2)
        default:
            let (a, t1) = measure(repeats) { pseudo.dinicMaximumFlow(from: s, to: t) { weights[$0] }.value }
            report("DirectedPseudograph", "\(a)", t1)
            let (b, t2) = measure(repeats) { csr.dinicMaximumFlow(from: s, to: t) { cw[$0] }.value }
            report("CompressedSparseRow", "\(b)", t2)
        }

    case "matching":
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        let (a, t1) = measure(repeats) { graph.maximumMatching().edges.count }
        report("UndirectedAdjacencyList", "\(a)", t1)

    case "bip-matching":
        let graph = BipartiteGraph(left: 0 ..< g.nleft, right: g.nleft ..< n, edges: undirectedEdges)!
        let (a, t1) = measure(repeats) { graph.maximumBipartiteMatching().edges.count }
        report("BipartiteGraph", "\(a)", t1)

    case "iso":
        let first = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        let second = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< g.m).map { UndirectedEdge(g.u2[$0], g.v2[$0]) })
        let (a, t1) = measure(repeats) { first.isIsomorphic(to: second) }
        report("UndirectedAdjacencyList", a ? "1" : "0", t1)

    case "bc":
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        let (a, t1) = measure(repeats) { graph.betweennessCentrality(normalized: false) }
        report("UndirectedAdjacencyList", float(a.scores.reduce(0, +)), t1)

    case "pagerank":
        let list = AdjacencyList(vertices: 0 ..< n, edges: directedEdges)
        let csr = CompressedSparseRow(vertexCount: n, edges: directedEdges)
        let (a, t1) = measure(repeats) { try! list.pageRank() }
        report("AdjacencyList", pageRankChecksum(a.scores), t1)
        let (b, t2) = measure(repeats) { try! csr.pageRank() }
        report("CompressedSparseRow", pageRankChecksum(b.scores), t2)

    case "triangles", "transitivity":
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        if algorithm == "triangles" {
            let (a, t1) = measure(repeats) { graph.triangleCount() }
            report("UndirectedAdjacencyList", "\(a)", t1)
        } else {
            let (a, t1) = measure(repeats) { graph.transitivity() }
            report("UndirectedAdjacencyList", float(a), t1)
        }

    case "articulation", "bridges":
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirectedEdges)
        if algorithm == "articulation" {
            let (a, t1) = measure(repeats) { graph.articulationPoints().count }
            report("UndirectedAdjacencyList", "\(a)", t1)
        } else {
            let (a, t1) = measure(repeats) { graph.bridges().count }
            report("UndirectedAdjacencyList", "\(a)", t1)
        }

    case "fw":
        let list = AdjacencyList(vertices: 0 ..< n, edges: directedEdges)
        let (csr, cw) = csrWithWeights()
        let lw = weights.map(Double.init), cwd = cw.map(Double.init)
        func check(_ distance: (Int, Int) -> Double?) -> String {
            var finite = 0, total = 0.0
            for i in 0 ..< n { for j in 0 ..< n { if let d = distance(i, j) { finite += 1; total += d } } }
            return "\(finite),\(String(format: "%.0f", total))"
        }
        let (a, t1) = measure(repeats) { list.floydWarshallShortestPaths { lw[$0] }! }
        report("AdjacencyList", check { a.distance(fromIndex: $0, toIndex: $1) }, t1)
        let (b, t2) = measure(repeats) { csr.floydWarshallShortestPaths { cwd[$0] }! }
        report("CompressedSparseRow", check { b.distance(fromIndex: $0, toIndex: $1) }, t2)

    default:
        print("NA unknown algorithm")
    }
}

main()
