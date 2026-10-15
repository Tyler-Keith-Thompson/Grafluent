// Traversal's enumerations and walks against brute force, on multigraphs of at most 7 vertices
// with self-loops and parallel edges, directed and undirected: allSimplePaths to one target and to
// two, with and without a bound, against a recursive enumeration in row order (content and
// order, each a path of the graph); allTopologicalSorts against every permutation filtered, in
// lexicographic order; random walks, uniform, weighted and biased, each a walk of the graph of
// the asked length unless it stops where no edge can be taken, the same for the same seed;
// lexicographic breadth-first and maximum cardinality search valid at every step by their
// definitions with explicit labels and counts, from the first vertex and from the source.
// Directed graphs are checked on AdjacencyList and on a conformer without vertex indices;
// undirected on UndirectedAdjacencyList after removals (rows out of position order) and a
// conformer without vertex indices.

import AdjacencyListModule
import FuzzSupport
import GraphProtocols
import Traversal
import Walks

/// A directed multigraph with no vertex indices; rows in position order.
struct PlainDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

/// An undirected multigraph with no vertex indices; rows in position order.
struct PlainGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

/// SplitMix64, so a walk's seed reproduces it.
struct SplitMix: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@main
enum FuzzTraversal {
    static func main() { runFuzzer(fuzz) }

    static func checkDirected<G: DirectedGraph>(_ graph: G, _ name: String, source: Int, targets: [Int], maxLength: Int, seed: UInt64) where G.Vertex == Int {
        // Simple paths, by recursion in row order.
        var expected: [(vertices: [Int], edges: [G.Edges.Index])] = []
        var path = [source]
        var taken: [G.Edges.Index] = []
        func extend() {
            let v = path[path.count - 1]
            if targets.contains(v) {
                expected.append((path, taken))
                if Set(targets).count == 1 { return }
            }
            guard taken.count < maxLength else { return }
            for e in graph.outEdges(of: v) where !path.contains(graph.target(ofEdgeAt: e)) {
                path.append(graph.target(ofEdgeAt: e))
                taken.append(e)
                extend()
                path.removeLast()
                taken.removeLast()
            }
        }
        extend()
        let paths = Array(graph.allSimplePaths(from: source, to: targets, maxLength: maxLength))
        check(paths.map(\.vertices) == expected.map(\.vertices) && paths.map(\.edges) == expected.map(\.edges), "\(name): allSimplePaths from \(source) to \(targets), maxLength \(maxLength)")
        for p in paths { check(Path(vertices: p.vertices, edges: p.edges, in: graph) != nil, "\(name): \(p) is not a path of the graph") }

        // Topological orders, by every permutation in vertices order.
        let listed = Array(graph.vertices)
        var orders: [[Int]] = []
        var order: [Int] = []
        func place() {
            if order.count == listed.count {
                orders.append(order)
                return
            }
            for v in listed where !order.contains(v) && !graph.edges.contains(where: { $0.target == v && !order.contains($0.source) }) {
                order.append(v)
                place()
                order.removeLast()
            }
        }
        place()
        check(Array(graph.allTopologicalSorts()) == orders, "\(name): allTopologicalSorts")

        // Random walks.
        for mode in 0 ..< 3 {
            var g1 = SplitMix(state: seed), g2 = SplitMix(state: seed)
            let length = min(maxLength, 12)
            let (p, q) = mode == 2 ? (0.5, 2.0) : (1.0, 1.0)
            func weight(_ e: G.Edges.Index) -> Double { Double((graph.source(ofEdgeAt: e) * 3 + graph.target(ofEdgeAt: e)) % 3) }
            let walk = mode == 1 ? graph.randomWalk(from: source, length: length, weight: weight, using: &g1) : graph.randomWalk(from: source, length: length, returnParameter: p, inOutParameter: q, using: &g1)
            let again = mode == 1 ? graph.randomWalk(from: source, length: length, weight: weight, using: &g2) : graph.randomWalk(from: source, length: length, returnParameter: p, inOutParameter: q, using: &g2)
            check(walk == again, "\(name): randomWalk mode \(mode) is not reproducible")
            check(Walk(vertices: walk.vertices, edges: walk.edges, in: graph) != nil && walk.source == source, "\(name): randomWalk mode \(mode) \(walk) is not a walk of the graph")
            check(walk.length <= length, "\(name): randomWalk mode \(mode) is too long")
            if walk.length < length {
                let row = Array(graph.outEdges(of: walk.target))
                check(mode == 1 ? row.allSatisfy { weight($0) == 0 } : row.isEmpty, "\(name): randomWalk mode \(mode) stopped where it could go on")
            }
            if mode == 1 { check(walk.edges.allSatisfy { weight($0) > 0 }, "\(name): randomWalk took an edge weighing zero") }
        }
    }

    static func checkUndirected<G: Graph>(_ graph: G, _ name: String, source: Int, targets: [Int], maxLength: Int, seed: UInt64) where G.Vertex == Int {
        var expected: [(vertices: [Int], edges: [G.Edges.Index])] = []
        var path = [source]
        var taken: [G.Edges.Index] = []
        func extend() {
            let v = path[path.count - 1]
            if targets.contains(v) {
                expected.append((path, taken))
                if Set(targets).count == 1 { return }
            }
            guard taken.count < maxLength else { return }
            for e in graph.incidentEdges(of: v) where !path.contains(graph.oppositeVertex(to: v, acrossEdgeAt: e)) {
                path.append(graph.oppositeVertex(to: v, acrossEdgeAt: e))
                taken.append(e)
                extend()
                path.removeLast()
                taken.removeLast()
            }
        }
        extend()
        let paths = Array(graph.allSimplePaths(from: source, to: targets, maxLength: maxLength))
        check(paths.map(\.vertices) == expected.map(\.vertices) && paths.map(\.edges) == expected.map(\.edges), "\(name): allSimplePaths from \(source) to \(targets), maxLength \(maxLength)")
        for p in paths { check(Path(vertices: p.vertices, edges: p.edges, in: graph) != nil, "\(name): \(p) is not a path of the graph") }

        // Orderings, by their definitions on the simple graph.
        let listed = Array(graph.vertices)
        let n = listed.count
        var number: [Int: Int] = [:]
        for (i, v) in listed.enumerated() { number[v] = i }
        var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        for e in graph.edges where e.u != e.v {
            adjacent[number[e.u]!][number[e.v]!] = true
            adjacent[number[e.v]!][number[e.u]!] = true
        }
        for first in [nil, number[source]!] as [Int?] {
            let ourLex = (first == nil ? graph.lexicographicBreadthFirstSearch() : graph.lexicographicBreadthFirstSearch(from: source)).map { number[$0]! }
            let ourMCS = (first == nil ? graph.maximumCardinalitySearch() : graph.maximumCardinalitySearch(from: source)).map { number[$0]! }
            check(ourLex.sorted() == Array(0 ..< n) && ourMCS.sorted() == Array(0 ..< n), "\(name): an ordering is not of every vertex")
            check(ourLex.first == (first ?? 0) && ourMCS.first == (first ?? 0), "\(name): an ordering starts elsewhere")
            var labels = [[Int]](repeating: [], count: n), counts = [Int](repeating: 0, count: n)
            var lexVisited = [Bool](repeating: false, count: n), mcsVisited = lexVisited
            for step in 0 ..< n {
                let a = ourLex[step], b = ourMCS[step]
                if step > 0 {
                    for v in 0 ..< n where !lexVisited[v] {
                        let x = labels[v], y = labels[a]
                        var greater = x.count > y.count
                        for (i, j) in zip(x, y) where i != j {
                            greater = i < j
                            break
                        }
                        check(!greater, "\(name): lexicographicBreadthFirstSearch \(ourLex) passes over \(v) at step \(step)")
                    }
                    for v in 0 ..< n where !mcsVisited[v] { check(counts[v] <= counts[b], "\(name): maximumCardinalitySearch \(ourMCS) passes over \(v) at step \(step)") }
                }
                lexVisited[a] = true
                mcsVisited[b] = true
                for w in 0 ..< n where adjacent[a][w] && !lexVisited[w] { labels[w].append(step) }
                for w in 0 ..< n where adjacent[b][w] && !mcsVisited[w] { counts[w] += 1 }
            }
        }

        for mode in 0 ..< 3 {
            var g1 = SplitMix(state: seed), g2 = SplitMix(state: seed)
            let length = min(maxLength, 12)
            let (p, q) = mode == 2 ? (2.0, 0.5) : (1.0, 1.0)
            func weight(_ e: G.Edges.Index) -> Double { Double((graph.edges[e].u + graph.edges[e].v) % 3) }
            let walk = mode == 1 ? graph.randomWalk(from: source, length: length, weight: weight, using: &g1) : graph.randomWalk(from: source, length: length, returnParameter: p, inOutParameter: q, using: &g1)
            let again = mode == 1 ? graph.randomWalk(from: source, length: length, weight: weight, using: &g2) : graph.randomWalk(from: source, length: length, returnParameter: p, inOutParameter: q, using: &g2)
            check(walk == again, "\(name): randomWalk mode \(mode) is not reproducible")
            check(Walk(vertices: walk.vertices, edges: walk.edges, in: graph) != nil && walk.source == source, "\(name): randomWalk mode \(mode) \(walk) is not a walk of the graph")
            check(walk.length <= length, "\(name): randomWalk mode \(mode) is too long")
            if walk.length < length {
                let row = Array(graph.incidentEdges(of: walk.target))
                check(mode == 1 ? row.allSatisfy { weight($0) == 0 } : row.isEmpty, "\(name): randomWalk mode \(mode) stopped where it could go on")
            }
            if mode == 1 { check(walk.edges.allSatisfy { weight($0) > 0 }, "\(name): randomWalk took an edge weighing zero") }
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 7)
        let bound = input.int(in: 0 ... 7)
        let maxLength = bound == 7 ? Int.max : bound
        let source = input.int(below: n)
        let target = input.int(below: n)
        let other = input.int(below: n + 1)
        let removals = input.int(below: 4)
        let seed = UInt64(input.byte()) << 8 | UInt64(input.byte())
        var pairs: [(Int, Int)] = []
        while !input.isEmpty, pairs.count < 14 { pairs.append((input.int(below: n), input.int(below: n))) }
        let targets = other == n ? [target] : [target, other]

        let directed = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        checkDirected(directed, "AdjacencyList", source: source, targets: targets, maxLength: maxLength, seed: seed)
        checkDirected(PlainDigraph(vertices: Array((0 ..< n).reversed()), edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }), "PlainDigraph", source: source, targets: targets, maxLength: maxLength, seed: seed)
        // Kahn's events: in-degrees count down to each ready event, every vertex is ready once
        // before it is emitted, and the emitted order is topologicalGenerations() joined.
        // An adjacency list keeps the first copy of each pair, in order, so its positions are these.
        var firstCopies = Set<DirectedEdge<Int>>()
        let simple = pairs.filter { firstCopies.insert(DirectedEdge(from: $0.0, to: $0.1)).inserted }
        func checkKahn<G: DirectedGraph<Int>>(_ graph: G, _ pairs: [(Int, Int)], _ name: String) where G.Edges.Index == Int {
            var inDegree = [Int](repeating: 0, count: n)
            for (_, v) in pairs { inDegree[v] += 1 }
            var ready = Set<Int>(), emitted: [Int] = [], current = -1
            for event in graph.lazy.kahn() {
                switch event {
                case .ready(let v): check(inDegree[v] == 0 && ready.insert(v).inserted, "\(name): ready \(v)")
                case .emit(let v):
                    check(ready.contains(v) && !emitted.contains(v), "\(name): emit \(v)")
                    emitted.append(v)
                    current = v
                case .removeEdge(let e, let d):
                    check(pairs[e].0 == current, "\(name): edge \(e) not out of \(current)")
                    inDegree[pairs[e].1] -= 1
                    check(d == inDegree[pairs[e].1], "\(name): edge \(e) leaves \(d)")
                }
            }
            let generations = graph.topologicalGenerations()
            check((generations == nil) == (emitted.count < n) && (generations.map { $0.flatMap { $0 } == emitted } ?? true), "\(name): Kahn emitted \(emitted), generations \(String(describing: generations))")
        }
        checkKahn(AdjacencyList(vertices: 0 ..< n, edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) }), simple, "Kahn on AdjacencyList")
        checkKahn(PlainDigraph(vertices: Array(0 ..< n), edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }), pairs, "Kahn on PlainDigraph")

        var list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for k in 0 ..< removals where list.edgeCount > 0 { _ = list.remove(edge: Array(list.edges)[k % list.edgeCount]) }
        checkUndirected(list, "UndirectedAdjacencyList", source: source, targets: targets, maxLength: maxLength, seed: seed)
        checkUndirected(PlainGraph(vertices: Array((0 ..< n).reversed()), edges: pairs.map { UndirectedEdge($0.0, $0.1) }), "PlainGraph", source: source, targets: targets, maxLength: maxLength, seed: seed)
    }
}
