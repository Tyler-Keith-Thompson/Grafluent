// The shortest-path algorithms against Floyd–Warshall, on graphs of at most 8 vertices with
// integer weights, from one to three sources.
//
// With nonnegative weights: Dijkstra on AdjacencyList and on CompressedSparseRow (with and without
// a cutoff), the single-target query, and A* with admissible heuristics (scaled Floyd–Warshall
// distances, often inconsistent, and negative at the target) all give Floyd–Warshall's distances,
// and every tree is a valid shortest-path tree. With negative weights: Bellman–Ford returns nil
// exactly when a negative cycle is reachable from a source, and otherwise treats the sources as
// one super-source; the reachable and whole-graph witnesses are negative cycles. Undirected:
// Dijkstra on UndirectedAdjacencyList equals Floyd–Warshall over both directions, and with
// negative weights Bellman–Ford returns nil exactly when a negative edge is reachable.
//
// Path enumeration and all pairs: Johnson's matrix is Floyd–Warshall's, nil exactly when a negative
// cycle exists, and its paths weigh their distances. With nonnegative weights, all-pairs Dijkstra is
// Floyd–Warshall's too; bidirectional Dijkstra gives the target's distance; Yen's sequence lists every
// simple path to the target once, in nondecreasing length, as a brute-force enumeration does; and
// every shortest path is listed once, as brute force finds them.

import AdjacencyListModule
import CompressedSparseRowModule
import FuzzSupport
import GraphProtocols
import ShortestPaths
import Walks

@main
enum FuzzShortestPaths {
    static func main() { runFuzzer(fuzz) }

    static let infinity = Int.max / 4

    /// All-pairs distances; `d[i][i] < 0` marks a vertex on a negative cycle.
    static func floydWarshall(_ n: Int, _ arcs: [(Int, Int, Int)]) -> [[Int]] {
        var d = [[Int]](repeating: [Int](repeating: infinity, count: n), count: n)
        for i in 0 ..< n { d[i][i] = 0 }
        for (u, v, w) in arcs { d[u][v] = min(d[u][v], w) }
        for k in 0 ..< n { for i in 0 ..< n { for j in 0 ..< n where d[i][k] < infinity && d[k][j] < infinity {
            d[i][j] = min(d[i][j], max(d[i][k] + d[k][j], -infinity))
        } } }
        return d
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 8)
        let negative = input.int(below: 2) == 1
        let sources = (0 ..< input.int(in: 1 ... 3)).map { _ in input.int(below: n) }
        let cutoff = input.int(below: 3) == 0 ? input.int(in: -1 ... 30) : nil
        let target = input.int(below: n)
        let fractions = (0 ..< n).map { _ in input.int(in: 0 ... 4) }
        // Edges as given, first weight wins for a repeated pair (both representations keep one).
        var weight: [DirectedEdge<Int>: Int] = [:]
        var order: [DirectedEdge<Int>] = []
        while !input.isEmpty {
            let edge = DirectedEdge(from: input.int(below: n), to: input.int(below: n))
            let w = negative ? input.int(in: -4 ... 9) : input.int(in: 0 ... 9)
            if weight[edge] == nil { weight[edge] = w; order.append(edge) }
        }

        let d = floydWarshall(n, order.map { ($0.source, $0.target, weight[$0]!) })
        // From the nearest source; a source is at zero unless a negative path from another
        // improves it (Bellman–Ford's super-source; Dijkstra never sees one).
        let expected: [Int?] = (0 ..< n).map { v in
            let best = sources.map { d[$0][v] }.min()!
            return best < infinity ? best : nil
        }
        let cycleReachable = (0 ..< n).contains { v in sources.contains { d[$0][v] < infinity } && d[v][v] < 0 }
        let cycleAnywhere = (0 ..< n).contains { d[$0][$0] < 0 }

        let list = AdjacencyList(vertices: 0 ..< n, edges: order)
        let w: (Int) -> Int = { weight[list.edges[$0]]! }

        func checkTree<G: DirectedGraph<Int>>(_ tree: ShortestPathTree<G, Int>, _ graph: G, _ weight: (G.Edges.Index) -> Int, _ expected: [Int?], _ name: String) {
            check((0 ..< n).map { tree.distance(to: $0) } == expected, "\(name): \((0 ..< n).map { tree.distance(to: $0) }), expected \(expected)")
            for v in 0 ..< n {
                guard let edge = tree.parentEdge(of: v) else {
                    check(expected[v] == nil || sources.contains(v), "\(name): \(v) is reached but has no parent")
                    continue
                }
                let parent = tree.parent(of: v)!
                check(graph.source(ofEdgeAt: edge) == parent && graph.target(ofEdgeAt: edge) == v, "\(name): parent edge of \(v)")
                check(tree.distance(to: parent)! + weight(edge) == expected[v], "\(name): parent of \(v) is not on a shortest path")
                let path = tree.path(to: v)!
                let edges = path.edges
                check(sources.contains(path.source) && path.target == v && edges.count == path.count - 1, "\(name): path to \(v)")
                check(Path(vertices: path.vertices, edges: edges, in: graph) != nil, "\(name): path to \(v) is not a path of the graph")
                check(edges.map(weight).reduce(0, +) == expected[v], "\(name): path edges to \(v)")
            }
        }

        if !negative {
            checkTree(list.dijkstraShortestPaths(from: sources, weight: w), list, w, expected, "Dijkstra on AdjacencyList")
            if let cutoff {
                let limited = expected.enumerated().map { v, e in sources.contains(v) ? 0 : e.flatMap { $0 <= cutoff ? $0 : nil } }
                checkTree(list.dijkstraShortestPaths(from: sources, cutoff: cutoff, weight: w), list, w, limited, "Dijkstra with cutoff \(cutoff)")
            }

            var edgeIndices: [Int] = []
            let sparse = CompressedSparseRow(vertexCount: n, edges: order, edgeIndices: &edgeIndices)
            var sparseWeight = [Int](repeating: 0, count: sparse.edgeCount)
            for (i, k) in edgeIndices.enumerated() { sparseWeight[k] = weight[order[i]]! }
            checkTree(sparse.dijkstraShortestPaths(from: sources) { sparseWeight[$0] }, sparse, { sparseWeight[$0] }, expected, "Dijkstra on CSR")

            // The event sequence: every reached vertex settled once, in nondecreasing order, at
            // Floyd–Warshall's distance; each examined edge offers d(u) + w and is then relaxed
            // or not exactly when its target is unsettled; the last relaxed edge into each vertex
            // is a parent edge on a shortest path; a vertex finishes right after its edges.
            func checkSearch<G: DirectedGraph<Int>>(_ graph: G, _ weight: @escaping (G.Edges.Index) -> Int, _ name: String) {
                var settled = [Int?](repeating: nil, count: n)
                var order: [Int] = []
                var parent = [G.Edges.Index?](repeating: nil, count: n)
                var current = -1
                var decisionDue: G.Edges.Index?
                for event in graph.dijkstraSearch(from: sources, weight: weight) {
                    if let due = decisionDue {
                        switch event {
                        case .edgeRelaxed(let e, _), .edgeNotRelaxed(let e, _): check(e == due, "\(name): decision for another edge")
                        default: check(false, "\(name): an edge into an unsettled vertex was not decided")
                        }
                        decisionDue = nil
                    }
                    switch event {
                    case .discover(let v, let dv):
                        check(settled[v] == nil && (sources.contains(v) ? dv == 0 : dv >= expected[v]!), "\(name): discover \(v)")
                    case .examine(let v, let dv):
                        check(settled[v] == nil && dv == expected[v], "\(name): \(v) settled at \(dv), expected \(String(describing: expected[v]))")
                        settled[v] = dv
                        order.append(dv)
                        current = v
                    case .examineEdge(let e, let offer):
                        check(graph.source(ofEdgeAt: e) == current && offer == settled[current]! + weight(e), "\(name): offer")
                        if settled[graph.target(ofEdgeAt: e)] == nil { decisionDue = e }
                    case .edgeRelaxed(let e, let dv):
                        check(dv == settled[current]! + weight(e), "\(name): relaxed distance")
                        parent[graph.target(ofEdgeAt: e)] = e
                    case .edgeNotRelaxed(let e, let dv):
                        check(dv <= settled[current]! + weight(e), "\(name): not relaxed but shorter")
                    case .finish(let v, let dv):
                        check(v == current && dv == settled[v], "\(name): finish")
                    }
                }
                check(settled == expected, "\(name): settled \(settled), expected \(expected)")
                check(order == order.sorted(), "\(name): settled out of order")
                for v in 0 ..< n where !sources.contains(v) && expected[v] != nil {
                    guard let e = parent[v] else { check(false, "\(name): \(v) has no relaxed edge"); continue }
                    check(expected[graph.source(ofEdgeAt: e)]! + weight(e) == expected[v], "\(name): last relaxed edge into \(v)")
                }
            }
            checkSearch(list, w, "search on AdjacencyList")
            checkSearch(sparse, { sparseWeight[$0] }, "search on CSR")

            // A* with h(v) a fraction of the true distance to the target (admissible, usually not
            // consistent), any value where the target is unreachable, and negative at the target.
            let source = sources[0]
            let truth = d[source][target] < infinity ? d[source][target] : nil
            let heuristic: (Int) -> Int = { v in v == target ? -fractions[v] : d[v][target] < infinity ? d[v][target] * fractions[v] / 4 : 50 }
            let single = list.dijkstraShortestPath(from: source, to: target, weight: w)
            let star = list.aStarShortestPath(from: source, to: target, weight: w, heuristic: heuristic)
            for (result, name) in [(single, "single target"), (star, "A*")] {
                check(result?.distance == truth, "\(name) \(source)→\(target): \(String(describing: result?.distance)), expected \(String(describing: truth))")
                if let result {
                    check(result.path.first == source && result.path.last == target, "\(name) path ends")
                    check(zip(result.path, result.path.dropFirst()).map { weight[DirectedEdge(from: $0, to: $1)]! } == result.path.edges.map(w), "\(name) edges follow the path")
                    check(result.path.weight(w) == truth, "\(name) path length")
                    check(Path(vertices: result.path.vertices, edges: result.path.edges, in: list) != nil, "\(name) is not a path of the graph")
                }
            }

            // Undirected: each pair once, lighter direction wins, Floyd–Warshall over both arcs.
            var undirected: [UndirectedEdge<Int>: Int] = [:]
            for e in order { undirected[UndirectedEdge(e.source, e.target)] = min(undirected[UndirectedEdge(e.source, e.target)] ?? .max, weight[e]!) }
            let u = floydWarshall(n, undirected.flatMap { [($0.key.u, $0.key.v, $0.value), ($0.key.v, $0.key.u, $0.value)] })
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirected.keys.sorted())
            let tree = graph.dijkstraShortestPaths(from: sources) { undirected[graph.edges[$0]]! }
            let distances = (0 ..< n).map { tree.distance(to: $0) }
            check(distances == (0 ..< n).map { v in sources.map { u[$0][v] }.min()!.nilIfInfinite }, "undirected Dijkstra \(distances)")
            let starUndirected = graph.aStarShortestPath(from: source, to: target, weight: { undirected[graph.edges[$0]]! }, heuristic: { v in v == target ? -1 : 0 })
            check(starUndirected?.distance == u[source][target].nilIfInfinite, "undirected A*")
        } else {
            // Undirected with negative weights: a negative cycle exactly when a negative edge is
            // reachable from a source.
            var undirected: [UndirectedEdge<Int>: Int] = [:]
            for e in order where undirected[UndirectedEdge(e.source, e.target)] == nil { undirected[UndirectedEdge(e.source, e.target)] = weight[e]! }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirected.keys.sorted())
            var reached = Set(sources)
            var frontier = Array(reached)
            while let x = frontier.popLast() {
                for y in graph.neighbors(of: x) where reached.insert(y).inserted { frontier.append(y) }
            }
            let negativeReachable = undirected.contains { $0.value < 0 && reached.contains($0.key.u) }
            let uw: (Int) -> Int = { undirected[graph.edges[$0]]! }
            check((graph.bellmanFordShortestPaths(from: sources, weight: uw) == nil) == negativeReachable, "undirected Bellman–Ford")
            let cycle = graph.findNegativeCycle(from: sources, weight: uw)
            check((cycle != nil) == negativeReachable, "undirected findNegativeCycle \(String(describing: cycle))")
            if let cycle {
                let closing = cycle.count == 1 ? UndirectedEdge(cycle[0], cycle[0]) : UndirectedEdge(cycle[0], cycle[1])
                check(cycle.count <= 2 && cycle.vertices == cycle.vertices.sorted() && (undirected[closing] ?? 0) < 0, "undirected witness \(cycle)")
                // A cycle of the directed view: its arcs, over one undirected edge.
                check(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph.directedView) != nil, "undirected witness \(cycle) is not a cycle of the directed view")
                check(Set(cycle.edges.map(\.position)).count == 1, "undirected witness \(cycle) uses more than one edge")
            }
            check((graph.findNegativeCycle(weight: uw) != nil) == undirected.values.contains { $0 < 0 }, "undirected whole-graph witness")
        }

        // Johnson, against Floyd–Warshall; nil exactly when a negative cycle exists.
        let johnson = list.johnsonShortestPaths(weight: w)
        check((johnson == nil) == cycleAnywhere, "Johnson returned \(johnson == nil ? "nil" : "a matrix"), a negative cycle \(cycleAnywhere ? "exists" : "does not")")
        func checkMatrix(_ matrix: DistanceMatrix<AdjacencyList<Int>, Int>, _ name: String) {
            for i in 0 ..< n {
                for j in 0 ..< n {
                    check(matrix.distance(from: i, to: j) == d[i][j].nilIfInfinite, "\(name) \(i)→\(j): \(String(describing: matrix.distance(from: i, to: j))), expected \(d[i][j])")
                    guard let path = matrix.path(from: i, to: j) else { continue }
                    check(Path(vertices: path.vertices, edges: path.edges, in: list) != nil && path.source == i && path.target == j, "\(name) path \(i)→\(j)")
                    check(path.weight(w) == d[i][j], "\(name) path \(i)→\(j) weighs \(path.weight(w))")
                }
            }
        }
        if let johnson { checkMatrix(johnson, "Johnson") }
        if !negative {
            checkMatrix(list.allPairsDijkstraShortestPaths(weight: w), "all-pairs Dijkstra")
            let source = sources[0]
            let both = list.bidirectionalDijkstraShortestPath(from: source, to: target, weight: w)
            check(both?.distance == d[source][target].nilIfInfinite, "bidirectional Dijkstra \(source)→\(target)")
            if let both {
                check(Path(vertices: both.path.vertices, edges: both.path.edges, in: list) != nil && both.path.weight(w) == both.distance, "bidirectional Dijkstra path")
            }
            // Brute force: every simple path from the source to the target, with its length.
            var lengths: [[Int]: Int] = [:]
            var onPath = [source]
            var steps: [Int] = []
            func extend(_ x: Int) {
                if x == target {
                    lengths[steps] = steps.map(w).reduce(0, +)
                    return
                }
                for e in list.outEdges(of: x) where !onPath.contains(list.target(ofEdgeAt: e)) {
                    onPath.append(list.target(ofEdgeAt: e))
                    steps.append(e)
                    extend(list.target(ofEdgeAt: e))
                    steps.removeLast()
                    onPath.removeLast()
                }
            }
            extend(source)
            let simple = Array(list.shortestSimplePaths(from: source, to: target, weight: w))
            check(simple.count == lengths.count && Set(simple.map(\.path.edges)) == Set(lengths.keys), "Yen \(source)→\(target): \(simple.count) paths, brute force \(lengths.count)")
            check(simple.map(\.distance) == lengths.values.sorted(), "Yen \(source)→\(target) lengths")
            check(simple.allSatisfy { lengths[$0.path.edges] == $0.distance }, "Yen \(source)→\(target) distances")
            let best = lengths.values.min()
            let shortest = list.allShortestPaths(from: source, to: target, weight: w)
            check(shortest.distance == best, "allShortestPaths distance \(String(describing: shortest.distance)), expected \(String(describing: best))")
            let listed = Array(shortest).map(\.edges)
            check(listed.count == Set(listed).count && Set(listed) == Set(lengths.filter { $0.value == best }.keys), "allShortestPaths \(source)→\(target)")
        }

        // Unweighted search counts edges from the nearest source.
        let hops = list.shortestPaths(from: sources)
        var level = [Int?](repeating: nil, count: n)
        var frontier: [Int] = []
        for s in sources where level[s] == nil { level[s] = 0; frontier.append(s) }
        while !frontier.isEmpty {
            var next: [Int] = []
            for x in frontier { for y in list.successors(of: x) where level[y] == nil { level[y] = level[x]! + 1; next.append(y) } }
            frontier = next
        }
        check((0 ..< n).map { hops.distance(to: $0) } == level, "unweighted search")

        let bellmanFord = list.bellmanFordShortestPaths(from: sources, weight: w)
        check((bellmanFord == nil) == cycleReachable, "Bellman–Ford returned \(bellmanFord == nil ? "nil" : "a tree"), a negative cycle is \(cycleReachable ? "" : "not ")reachable")
        if let bellmanFord { checkTree(bellmanFord, list, w, expected, "Bellman–Ford") }

        func checkWitness(_ cycle: Cycle<Int, Int>?, _ exists: Bool, _ name: String) {
            check((cycle != nil) == exists, "\(name) found \(String(describing: cycle))")
            guard let cycle else { return }
            check(cycle.first == cycle.min(), "\(name): \(cycle) is not rotated to its first vertex")
            // Its own edges: a cycle of the graph, negative by the weights of the edges it names.
            check(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: list) != nil, "\(name): \(cycle) is not a cycle of the graph")
            check(cycle.weight(w) < 0, "\(name): \(cycle) is not a negative cycle")
        }
        checkWitness(list.findNegativeCycle(from: sources, weight: w), cycleReachable, "findNegativeCycle(from:)")
        checkWitness(list.findNegativeCycle(weight: w), cycleAnywhere, "findNegativeCycle()")
    }
}

extension Int {
    var nilIfInfinite: Int? { self < FuzzShortestPaths.infinity ? self : nil }
}
