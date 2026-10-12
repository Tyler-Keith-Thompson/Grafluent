// FunctionalGraph, ImplicitDirectedGraph and the closure Dijkstra and A* (decision D19) against
// written-out models.
//
// A functional-graph step reads a mapping on up to 48 vertices (random, a permutation, or long
// tails into small cycles) and checks every vertex against its orbit, iterated with a dictionary
// of first visits: the tail length, cycle length and root, the component's cycle (listed from its
// least vertex in walk order, the cycles ordered by least vertex), preimages and in-degrees; the
// k-th successor on the graph and on the decomposition against stepping, for every k up to 3n + 3
// and for huge k (up to Int.max) through the orbit's tail and period; Floyd's and Brent's cycle
// detection from every vertex against the decomposition, with Floyd's exact call count; and the
// round trip through a DirectedPseudograph (`init?(_:)`, nil once a vertex has a second edge).
//
// An implicit-graph step reads rows of up to 4 targets (loops and repeats allowed) on up to 12
// vertices, and checks the graph against a DirectedPseudograph built from the same rows: edges
// by iteration and by index stepping (positions' source, rank and target, ascending), counts,
// rows, out-edges, degrees, edge membership including non-vertices, the closure's call counts,
// components, breadth-first layers and Dijkstra distances.
//
// A search step reads a weighted digraph with parallel edges and zero weights and a goal set, and
// runs the closure Dijkstra and A* (heuristics admissible, some inconsistent) from every vertex
// against a quadratic Dijkstra on the explicit graph: the distance, nil exactly when no goal is
// reachable, the path a genuine walk of that cost from the start to a goal, at most one
// expansion per state under Dijkstra and a consistent heuristic, none when the start is a goal;
// under a cutoff, the same answer when the nearest goal is that close and nil otherwise.

import Connectivity
import FunctionalGraphs
import FuzzSupport
import GraphProtocols
import ImplicitGraphs
import Multigraphs
import ShortestPaths
import Traversal

@main
enum FuzzFunctionalGraphs {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        while !input.isEmpty {
            switch input.int(below: 3) {
            case 0: functional(&input)
            case 1: implicit(&input)
            default: search(&input)
            }
        }
    }

    // MARK: - Functional graphs

    struct Orbit {
        var tail: Int
        var cycle: Int
        var root: Int
        var cycleVertices: [Int]  // from the root, in walk order
    }

    static func orbit(_ f: [Int], from v: Int) -> Orbit {
        var seen: [Int: Int] = [:]
        var walk: [Int] = []
        var x = v
        while seen[x] == nil {
            seen[x] = walk.count
            walk.append(x)
            x = f[x]
        }
        let tail = seen[x]!
        return Orbit(tail: tail, cycle: walk.count - tail, root: x, cycleVertices: Array(walk[tail...]))
    }

    static func step(_ f: [Int], _ v: Int, _ k: Int) -> Int {
        var x = v
        for _ in 0 ..< k { x = f[x] }
        return x
    }

    static func functional(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 48)
        var f = [Int](repeating: 0, count: n)
        switch input.int(below: 3) {
        case 0:
            for v in 0 ..< n { f[v] = input.int(below: n) }
        case 1:
            var perm = Array(0 ..< n)
            for i in 0 ..< n {
                let j = i + input.int(below: n - i)
                perm.swapAt(i, j)
            }
            f = perm
        default:
            // Long tails: mostly v → v − 1, into a few small cycles at the bottom.
            for v in 0 ..< n {
                let b = input.byte()
                f[v] = b < 200 ? Swift.max(v - 1 - (b % 3 == 0 ? 1 : 0), 0) : b % n
            }
        }
        let graph = FunctionalGraph(successors: f)
        check(FunctionalGraph(vertexCount: n) { f[$0] } == graph, "init(vertexCount:successor:) \(f)")
        let d = graph.cycleDecomposition()
        let orbits = (0 ..< n).map { orbit(f, from: $0) }

        // The cycles, each from its least vertex, ordered by least vertex.
        var cycles: [[Int]] = []
        var onCycle = Set<Int>()
        for v in 0 ..< n where orbits[v].tail == 0 && !onCycle.contains(v) {
            var c = [v]
            var x = f[v]
            while x != v { c.append(x); x = f[x] }
            onCycle.formUnion(c)
            cycles.append(c)
        }
        check(d.cycles.map { Array($0) } == cycles, "cycles \(d.cycles.map { Array($0) }), expected \(cycles) for \(f)")
        for v in 0 ..< n {
            let o = orbits[v]
            check(d.tailLength(of: v) == o.tail, "tailLength(of: \(v)) for \(f)")
            check(d.cycleLength(of: v) == o.cycle, "cycleLength(of: \(v)) for \(f)")
            check(d.root(of: v) == o.root, "root(of: \(v)) for \(f)")
            let c = d.component(of: v)
            check(c >= 0 && c < cycles.count && cycles[c].contains(o.root), "component(of: \(v)) for \(f)")
            let pre = (0 ..< n).filter { f[$0] == v }
            check(Array(d.preimages(of: v)) == pre && d.inDegree(of: v) == pre.count, "preimages(of: \(v)) for \(f)")
            check(graph.successor(of: v) == f[v], "successor(of: \(v))")
            for k in 0 ... (3 * n + 3) {
                let expected = step(f, v, k)
                check(graph.successor(of: v, steps: k) == expected, "graph successor(of: \(v), steps: \(k)) for \(f)")
                check(d.successor(of: v, steps: k) == expected, "decomposition successor(of: \(v), steps: \(k)) for \(f)")
            }
            var huge = [Int.max, Int.max - 1, Int.max - o.cycle, 1 << 40]
            huge.append(Int.max - input.int(below: 256))
            for k in huge {
                let expected = step(f, v, o.tail + (k - o.tail) % o.cycle)
                check(graph.successor(of: v, steps: k) == expected, "graph successor(of: \(v), steps: \(k)) for \(f)")
                check(d.successor(of: v, steps: k) == expected, "decomposition successor(of: \(v), steps: \(k)) for \(f)")
            }

            var calls = 0
            let floyd = floydCycleDetection(from: v) { (x: Int) -> Int in calls += 1; return f[x] }
            check(floyd.tailLength == d.tailLength(of: v) && floyd.cycleLength == d.cycleLength(of: v) && floyd.root == d.root(of: v), "Floyd from \(v) for \(f)")
            let mu = o.tail, lambda = o.cycle
            let nu = (Swift.max(mu, 1) + lambda - 1) / lambda * lambda
            check(calls == 3 * nu + 2 * mu + lambda, "Floyd's calls \(calls) from \(v) for \(f)")
            calls = 0
            let brent = brentCycleDetection(from: v) { (x: Int) -> Int in calls += 1; return f[x] }
            check(brent.tailLength == mu && brent.cycleLength == lambda && brent.root == o.root, "Brent from \(v) for \(f)")
            check(calls <= 2 * (mu + lambda) + 2 * Swift.max(mu, lambda) + 2, "Brent's calls \(calls) from \(v) for \(f)")
        }

        // Round trip through a stored graph.
        let stored = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: f[$0]) })
        check(FunctionalGraph(stored) == graph, "init?(_:) round trip for \(f)")
        check(Array(graph.edges) == (0 ..< n).map { DirectedEdge(from: $0, to: f[$0]) }, "edges for \(f)")
        if n > 0 {
            var extra = stored
            let v = input.int(below: n)
            _ = extra.insert(edge: DirectedEdge(from: v, to: input.int(below: n)))
            check(FunctionalGraph(extra) == nil, "init?(_:) with a second edge at \(v) for \(f)")
        }
    }

    // MARK: - Implicit graphs

    static func normalized(_ components: [[Int]]) -> [[Int]] {
        components.map { $0.sorted() }.sorted { $0.lexicographicallyPrecedes($1) }
    }

    static func implicit(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 12)
        var rows: [[Int]] = []
        for _ in 0 ..< n {
            rows.append((0 ..< input.int(below: 5)).map { _ in input.int(below: n) })
        }
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: n) { (v: Int) -> [Int] in calls += 1; return rows[v] }
        let edges = rows.enumerated().flatMap { v, row in row.map { DirectedEdge(from: v, to: $0) } }
        let stored = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: edges)
        let context = "for \(rows)"

        calls = 0
        check(Array(graph.edges) == edges && calls == n, "Array(edges), \(calls) calls \(context)")
        calls = 0
        check(graph.edges.map { $0 } == edges && calls == n, "edges.map, \(calls) calls \(context)")
        calls = 0
        check(graph.edgeCount == edges.count && calls == n, "edgeCount \(context)")
        check(graph.vertexCount == n && Array(graph.vertices) == Array(0 ..< n), "vertices \(context)")

        // Stepping by index.
        var position = graph.edges.startIndex
        var k = 0
        var previous: ImplicitDirectedGraph<[Int]>.Edges.Index?
        while position != graph.edges.endIndex {
            check(k < edges.count, "too many positions \(context)")
            let e = edges[k]
            check(graph.edges[position] == e && position.source == e.source && position.target == e.target, "position \(position) \(context)")
            check(graph.source(ofEdgeAt: position) == e.source && graph.target(ofEdgeAt: position) == e.target, "ends at \(position) \(context)")
            check(graph.sourceIndex(ofEdgeAt: position) == e.source && graph.targetIndex(ofEdgeAt: position) == e.target, "index ends at \(position) \(context)")
            let rank = edges[..<k].filter { $0.source == e.source }.count
            check(position.rank == rank, "rank at \(position) \(context)")
            if let previous { check(previous < position && previous != position, "positions ascending \(context)") }
            previous = position
            position = graph.edges.index(after: position)
            k += 1
        }
        check(k == edges.count, "positions \(k), expected \(edges.count) \(context)")

        for v in 0 ..< n {
            calls = 0
            check(Array(graph.successors(of: v)) == rows[v] && calls == 1, "successors(of: \(v)) \(context)")
            check(Array(graph.successorIndices(ofIndex: v)) == rows[v], "successorIndices(ofIndex: \(v)) \(context)")
            let out = Array(graph.outEdges(of: v))
            check(out.map(\.source) == rows[v].map { _ in v } && out.map(\.rank) == Array(rows[v].indices) && out.map(\.target) == rows[v], "outEdges(of: \(v)) \(context)")
            check(Array(graph.outEdges(ofIndex: v)) == out, "outEdges(ofIndex: \(v)) \(context)")
            check(graph.outDegree(of: v) == rows[v].count && graph.outDegree(ofIndex: v) == rows[v].count, "outDegree(of: \(v)) \(context)")
            check(graph.vertexIndex(of: v) == v && graph.vertex(atIndex: v) == v, "indices \(context)")
        }
        for a in -1 ... n {
            check(graph.contains(a) == (a >= 0 && a < n), "contains(\(a)) \(context)")
            for b in -1 ... n {
                calls = 0
                let present = a >= 0 && a < n && rows[a].contains(b)
                check(graph.contains(edge: DirectedEdge(from: a, to: b)) == present, "contains(edge: \(a)→\(b)) \(context)")
                let inRange = a >= 0 && a < n && b >= 0 && b < n
                check(calls == (inRange ? 1 : 0), "contains(edge: \(a)→\(b)) calls \(calls) \(context)")
            }
        }

        check(normalized(graph.stronglyConnectedComponents().map { Array($0) }) == normalized(stored.stronglyConnectedComponents().map { Array($0) }), "strong components \(context)")
        check(normalized(graph.weaklyConnectedComponents().map { Array($0) }) == normalized(stored.weaklyConnectedComponents().map { Array($0) }), "weak components \(context)")
        check((graph.topologicalSort() == nil) == (stored.topologicalSort() == nil), "acyclic \(context)")
        func weight(_ s: Int, _ t: Int) -> Int { (s &* 31 &+ t &* 17 &+ 5) % 7 }
        for v in 0 ..< n {
            check(graph.breadthFirstLayers(from: v).map { $0.sorted() } == stored.breadthFirstLayers(from: v).map { $0.sorted() }, "layers from \(v) \(context)")
            let tree = graph.dijkstraShortestPaths(from: v) { weight($0.source, $0.target) }
            let copy = stored.dijkstraShortestPaths(from: v) { weight(stored.source(ofEdgeAt: $0), stored.target(ofEdgeAt: $0)) }
            for w in 0 ..< n {
                check(tree.distance(to: w) == copy.distance(to: w), "Dijkstra \(v)→\(w) \(context)")
            }
        }
    }

    // MARK: - Closure Dijkstra and A*

    /// Distances to the nearest goal, over the reversed edges, by a quadratic Dijkstra.
    static func distancesToGoals(_ n: Int, _ arcs: [(Int, Int, Int)], _ goals: Set<Int>) -> [Int?] {
        var dist = [Int?](repeating: nil, count: n)
        var done = [Bool](repeating: false, count: n)
        for g in goals { dist[g] = 0 }
        while true {
            var best = -1
            for v in 0 ..< n where !done[v] && dist[v] != nil {
                if best < 0 || dist[v]! < dist[best]! { best = v }
            }
            if best < 0 { break }
            done[best] = true
            for (s, t, w) in arcs where t == best {
                let c = dist[best]! + w
                if dist[s] == nil || c < dist[s]! { dist[s] = c }
            }
        }
        return dist
    }

    static func search(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 12)
        var arcs: [(Int, Int, Int)] = []
        for _ in 0 ..< input.int(below: 40) {
            arcs.append((input.int(below: n), input.int(below: n), input.int(below: 10)))
        }
        var goals = Set<Int>()
        for v in 0 ..< n where input.int(below: 4) == 0 { goals.insert(v) }
        var out = [[(Int, Int)]](repeating: [], count: n)
        for (s, t, w) in arcs { out[s].append((t, w)) }
        let toGoal = distancesToGoals(n, arcs, goals)
        let context = "for \(arcs) goals \(goals.sorted())"
        // Per vertex, a fraction in [0, 1] of the true distance: admissible, often inconsistent.
        let fractions = (0 ..< n).map { _ in input.int(below: 5) }

        func verify(_ result: (path: [Int], distance: Int)?, from start: Int, _ name: String) {
            guard let expected = toGoal[start] else {
                check(result == nil, "\(name) from \(start) found \(String(describing: result)), expected nil \(context)")
                return
            }
            guard let result else { return check(false, "\(name) from \(start) found nil, expected \(expected) \(context)") }
            check(result.distance == expected, "\(name) from \(start): \(result.distance), expected \(expected) \(context)")
            check(result.path.first == start && goals.contains(result.path.last!), "\(name) path \(result.path) ends \(context)")
            var cost = 0
            for (a, b) in zip(result.path, result.path.dropFirst()) {
                let ws = out[a].filter { $0.0 == b }.map(\.1)
                check(!ws.isEmpty, "\(name) path \(result.path) uses no edge \(a)→\(b) \(context)")
                cost += ws.min() ?? 0
            }
            check(cost == expected, "\(name) path \(result.path) costs \(cost), expected \(expected) \(context)")
        }

        for start in 0 ..< n {
            var expansions = [Int: Int]()
            let dijkstra = dijkstraShortestPath(from: start, successors: { (v: Int) -> [(Int, Int)] in
                expansions[v, default: 0] += 1
                return out[v]
            }, success: { goals.contains($0) })
            verify(dijkstra, from: start, "Dijkstra")
            check(expansions.values.allSatisfy { $0 == 1 }, "Dijkstra expanded a state twice \(context)")
            if goals.contains(start) { check(expansions.isEmpty, "Dijkstra expanded a goal start \(context)") }

            // The exact distance is consistent (a dead end's estimate must be large for that: zero
            // there is admissible but not consistent), so no state is expanded twice.
            expansions = [:]
            let exact = aStarShortestPath(from: start, successors: { (v: Int) -> [(Int, Int)] in
                expansions[v, default: 0] += 1
                return out[v]
            }, heuristic: { toGoal[$0] ?? 1_000_000 }, success: { goals.contains($0) })
            verify(exact, from: start, "A* (exact)")
            check(expansions.values.allSatisfy { $0 == 1 }, "A* with a consistent heuristic expanded a state twice \(context)")

            var heuristicCalls = 0
            let scaled = aStarShortestPath(from: start, successors: { out[$0] }, heuristic: { (v: Int) -> Int in
                heuristicCalls += 1
                return (toGoal[v] ?? 0) * fractions[v] / 4
            }, success: { goals.contains($0) })
            verify(scaled, from: start, "A* (scaled)")
            check(heuristicCalls >= 1, "A* never called the heuristic \(context)")

            // Doubles, quartered so every sum is exact.
            let doubled = dijkstraShortestPath(from: start, successors: { (v: Int) -> [(Int, Double)] in
                out[v].map { ($0.0, Double($0.1) / 4) }
            }, success: { goals.contains($0) })
            check(doubled.map { $0.distance * 4 } == toGoal[start].map(Double.init), "Dijkstra over Double from \(start) \(context)")

            // A cutoff (inclusive, on the distance alone; under a negative one only the start is
            // reached, even across zero-cost steps): the same answer when the nearest goal is that
            // close, nil otherwise, under Dijkstra and under A* with a scaled heuristic.
            let cutoff = input.int(in: -1 ... 30)
            let near = goals.contains(start) ? 0 : toGoal[start].flatMap { $0 <= cutoff ? $0 : nil }
            let bounded = dijkstraShortestPath(from: start, cutoff: cutoff, successors: { out[$0] }, success: { goals.contains($0) })
            check(bounded?.distance == near, "Dijkstra with cutoff \(cutoff) from \(start): \(String(describing: bounded?.distance)), expected \(String(describing: near)) \(context)")
            let boundedAStar = aStarShortestPath(from: start, cutoff: cutoff, successors: { out[$0] }, heuristic: { (toGoal[$0] ?? 0) * fractions[$0] / 4 }, success: { goals.contains($0) })
            check(boundedAStar?.distance == near, "A* with cutoff \(cutoff) from \(start) \(context)")
        }
    }
}
