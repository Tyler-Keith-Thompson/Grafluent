// The semiring overloads against brute force, on random multigraphs (loops, parallel edges) of at
// most 7 vertices, from one to three sources (repeats allowed), and the semiring laws on random
// values with the sentinels.
//
// Tropical: Dijkstra (with and without a cutoff, and the single-target search), Bellman–Ford,
// Floyd–Warshall and the DAG paths against the numeric (`W`) overloads, with the tropical zero
// (`Int.max`, `.infinity`) as an edge that carries no path, over Int and Double; every tree and
// matrix path is a walk of the graph from a source whose product is its distance. Widest paths
// (bottleneck): the best width over every simple path, enumerated. Counting: the sum over every
// path of a DAG of its product, enumerated, on the graph and on its DirectedAcyclicGraph wrapper;
// on any graph the DAG entry points are nil exactly when a cycle is reachable. Boolean:
// Floyd–Warshall, Dijkstra and Bellman–Ford against breadth-first search. Undirected (Graph): the
// same against the numeric overloads and the enumeration over both arcs, on a Pseudograph (native
// search) and on an UndirectedAdjacencyList of strings (through the view). Tropical −∞ (Int.min)
// edges, often on cycles: Bellman–Ford, Floyd–Warshall and DAG paths against the W engine with
// −∞ stood in by -1000: nil together, or the same distances. UInt, Int8 and Float against Int, Double and the enumeration. NaN weights
// on edges the sources never reach: Dijkstra and Bellman–Ford answer as without them.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import FuzzSupport
import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Walks

@main
enum FuzzSemirings {
    static func main() { runFuzzer(fuzz) }

    typealias Arc = (u: Int, v: Int, w: Int)

    static func fuzz(_ input: inout FuzzInput) {
        laws(&input)
        let n = input.int(in: 1 ... 7)
        let sources = (0 ..< input.int(in: 1 ... 3)).map { _ in input.int(below: n) }
        let cutoff = input.int(in: -1 ... 20)
        let target = input.int(below: n)
        var raw: [(u: Int, v: Int, byte: Int)] = []
        while !input.isEmpty && raw.count < 16 {
            raw.append((input.int(below: n), input.int(below: n), input.byte()))
        }
        tropical(n, sources, cutoff, target, raw)
        widest(n, sources, cutoff, target, raw)
        counting(n, sources, raw)
        boolean(n, sources, raw)
        undirected(n, sources, cutoff, target, raw)
        negativeInfinity(n, sources, raw)
        otherScalars(n, sources, raw)
        unexaminedNaN(n, sources, raw)
    }

    // MARK: - Laws

    static func laws(_ input: inout FuzzInput) {
        let bytes = (0 ..< 3).map { _ in input.byte() }
        // Small values, with the sentinels at the top of the byte range.
        func int(_ b: Int, top: Int, bottom: Int?) -> Int {
            if b >= 250 { return top }
            if let bottom, b >= 244 { return bottom }
            return b % 41 - 20
        }
        let t = bytes.map { int($0, top: Int.max, bottom: nil) }
        semiring(TropicalSemiring(t[0]), TropicalSemiring(t[1]), TropicalSemiring(t[2]))
        selective(TropicalSemiring(t[0]), TropicalSemiring(t[1]), TropicalSemiring(t[2]))
        let t8 = bytes.map { Int8(int($0, top: Int(Int8.max), bottom: nil)) }
        semiring(TropicalSemiring(t8[0]), TropicalSemiring(t8[1]), TropicalSemiring(t8[2]))
        selective(TropicalSemiring(t8[0]), TropicalSemiring(t8[1]), TropicalSemiring(t8[2]))
        let tu = bytes.map { $0 >= 250 ? UInt.max : UInt($0 % 21) }
        semiring(TropicalSemiring(tu[0]), TropicalSemiring(tu[1]), TropicalSemiring(tu[2]))
        selective(TropicalSemiring(tu[0]), TropicalSemiring(tu[1]), TropicalSemiring(tu[2]))
        let td = bytes.map { $0 >= 250 ? Double.infinity : Double($0 % 41 - 20) / 4 }
        semiring(TropicalSemiring(td[0]), TropicalSemiring(td[1]), TropicalSemiring(td[2]))
        selective(TropicalSemiring(td[0]), TropicalSemiring(td[1]), TropicalSemiring(td[2]))
        let b = bytes.map { int($0, top: Int.max, bottom: Int.min) }
        semiring(BottleneckSemiring(b[0]), BottleneckSemiring(b[1]), BottleneckSemiring(b[2]))
        selective(BottleneckSemiring(b[0]), BottleneckSemiring(b[1]), BottleneckSemiring(b[2]))
        let bu = bytes.map { $0 >= 250 ? UInt.max : UInt($0 % 21) }
        semiring(BottleneckSemiring(bu[0]), BottleneckSemiring(bu[1]), BottleneckSemiring(bu[2]))
        selective(BottleneckSemiring(bu[0]), BottleneckSemiring(bu[1]), BottleneckSemiring(bu[2]))
        let bd = bytes.map { $0 >= 250 ? Double.infinity : $0 >= 244 ? -Double.infinity : Double($0 % 41 - 20) / 4 }
        semiring(BottleneckSemiring(bd[0]), BottleneckSemiring(bd[1]), BottleneckSemiring(bd[2]))
        selective(BottleneckSemiring(bd[0]), BottleneckSemiring(bd[1]), BottleneckSemiring(bd[2]))
        let o = bytes.map { $0 % 2 == 1 }
        semiring(BooleanSemiring(o[0]), BooleanSemiring(o[1]), BooleanSemiring(o[2]))
        selective(BooleanSemiring(o[0]), BooleanSemiring(o[1]), BooleanSemiring(o[2]))
        let c = bytes.map { $0 % 41 - 20 }
        semiring(CountingSemiring(c[0]), CountingSemiring(c[1]), CountingSemiring(c[2]))
        semiring(CountingSemiring(Double(c[0]) / 4), CountingSemiring(Double(c[1]) / 4), CountingSemiring(Double(c[2]) / 4))

        // The raw operations.
        check(TropicalSemiring(t[0]).plus(TropicalSemiring(t[1])).value == min(t[0], t[1]), "tropical plus \(t)")
        let sum = t[0] == Int.max || t[1] == Int.max ? Int.max : t[0] + t[1]
        check(TropicalSemiring(t[0]).times(TropicalSemiring(t[1])).value == sum, "tropical times \(t)")
        check(BottleneckSemiring(b[0]).plus(BottleneckSemiring(b[1])).value == max(b[0], b[1]), "bottleneck plus \(b)")
        check(BottleneckSemiring(b[0]).times(BottleneckSemiring(b[1])).value == min(b[0], b[1]), "bottleneck times \(b)")
        check(CountingSemiring(c[0]).plus(CountingSemiring(c[1])).value == c[0] + c[1] && CountingSemiring(c[0]).times(CountingSemiring(c[1])).value == c[0] * c[1], "counting \(c)")
        check(BooleanSemiring(o[0]).plus(BooleanSemiring(o[1])).value == (o[0] || o[1]) && BooleanSemiring(o[0]).times(BooleanSemiring(o[1])).value == (o[0] && o[1]), "Boolean \(o)")
        check(TropicalSemiring<Int>.zero.value == Int.max && TropicalSemiring<Int>.one.value == 0, "tropical sentinels")
        check(BottleneckSemiring<Int>.zero.value == Int.min && BottleneckSemiring<Int>.one.value == Int.max, "bottleneck sentinels")
        check(BottleneckSemiring<UInt>.zero.value == 0 && TropicalSemiring<Double>.zero.value == .infinity && BottleneckSemiring<Double>.zero.value == -.infinity, "other sentinels")
        check(CountingSemiring<Int>.zero.value == 0 && CountingSemiring<Int>.one.value == 1 && !BooleanSemiring.zero.value && BooleanSemiring.one.value, "counting and Boolean sentinels")
        // -∞ absorbs every finite value, below the zero.
        let minus = TropicalSemiring(Int.min)
        check(minus.times(TropicalSemiring(c[0])).value == Int.min && minus.times(.zero) == .zero, "tropical -∞ \(c[0])")
    }

    static func semiring<S: Semiring & Hashable>(_ a: S, _ b: S, _ c: S) {
        let context = "\(S.self) \(a) \(b) \(c)"
        check(a.plus(b).plus(c) == a.plus(b.plus(c)), "⊕ associative: \(context)")
        check(a.plus(b) == b.plus(a), "⊕ commutative: \(context)")
        check(a.plus(.zero) == a && S.zero.plus(a) == a, "zero is ⊕'s identity: \(context)")
        check(a.times(b).times(c) == a.times(b.times(c)), "⊗ associative: \(context)")
        check(a.times(.one) == a && S.one.times(a) == a, "one is ⊗'s identity: \(context)")
        check(a.times(.zero) == .zero && S.zero.times(a) == .zero, "zero annihilates: \(context)")
        check(a.times(b.plus(c)) == a.times(b).plus(a.times(c)), "left distributive: \(context)")
        check(a.plus(b).times(c) == a.times(c).plus(b.times(c)), "right distributive: \(context)")
        check(a.times(b) == b.times(a), "⊗ commutative: \(context)")
        let sum = a ⊕ b, product = a ⊗ b, mixed = a ⊕ b ⊗ c, grouped = (a ⊕ b) ⊗ c
        check(sum == a.plus(b) && product == a.times(b), "operators: \(context)")
        check(mixed == a.plus(b.times(c)) && grouped == a.plus(b).times(c), "precedence: \(context)")
        if a == b { check(a.hashValue == b.hashValue, "hash: \(context)") }
    }

    static func selective<S: SelectiveSemiring & Hashable>(_ a: S, _ b: S, _ c: S) {
        let context = "\(S.self) \(a) \(b) \(c)"
        check(a.plus(b) == (b < a ? b : a) && a.plus(a) == a, "selective, idempotent: \(context)")
        check((a < b) == (a.plus(b) == a && a != b), "natural order: \(context)")
        check([a < b, b < a, a == b].filter { $0 }.count == 1, "trichotomy: \(context)")
        if a < b && b < c { check(a < c, "transitive: \(context)") }
        check(!(S.zero < a) && !(a < a), "zero is the worst: \(context)")
    }

    // MARK: - Brute force

    /// The best value of `combine` over every simple path from the sources, `fold`ing edge weights
    /// from `start`; nil where no path. A source's own value is `start`.
    static func simplePaths(_ n: Int, _ arcs: [Arc], _ sources: [Int], start: Int, fold: (Int, Int) -> Int, better: (Int, Int) -> Bool) -> [Int?] {
        var best = [Int?](repeating: nil, count: n)
        func walk(_ u: Int, _ value: Int, _ seen: inout [Bool]) {
            if best[u] == nil || better(value, best[u]!) { best[u] = value }
            for a in arcs where a.u == u && !seen[a.v] {
                seen[a.v] = true
                walk(a.v, fold(value, a.w), &seen)
                seen[a.v] = false
            }
        }
        for s in Set(sources) {
            var seen = [Bool](repeating: false, count: n)
            seen[s] = true
            walk(s, start, &seen)
        }
        return best
    }

    static func reachable(_ n: Int, _ arcs: [Arc], _ sources: [Int], using: (Arc) -> Bool = { _ in true }) -> [Bool] {
        var reached = [Bool](repeating: false, count: n)
        var stack: [Int] = []
        for s in sources where !reached[s] {
            reached[s] = true
            stack.append(s)
        }
        while let u = stack.popLast() {
            for a in arcs where a.u == u && using(a) && !reached[a.v] {
                reached[a.v] = true
                stack.append(a.v)
            }
        }
        return reached
    }

    /// Whether a cycle (a loop included) is reachable from the sources.
    static func cycleReachable(_ n: Int, _ arcs: [Arc], _ sources: [Int]) -> Bool {
        let reached = reachable(n, arcs, sources)
        return (0 ..< n).contains { v in
            reached[v] && arcs.contains { $0.u == v && reachable(n, arcs, [$0.v])[v] }
        }
    }

    // MARK: - Tree and matrix checks

    /// The distances are `expected`; every reached vertex's path is a walk of the graph from a
    /// source, ending at the vertex and in its parent edge, whose product is its distance.
    static func checkTree<G: DirectedGraph, S: SelectiveSemiring>(
        _ tree: ShortestPathTree<G, S>, _ graph: G, _ vertices: [G.Vertex], _ sources: [G.Vertex],
        _ weight: (G.Edges.Index) -> S, _ expected: [S?], _ name: String
    ) {
        let distances = vertices.map { tree.distance(to: $0) }
        check(distances == expected, "\(name): \(distances), expected \(expected)")
        check(Set(tree.sources) == Set(sources) && tree.sources.count == Set(sources).count, "\(name): sources \(tree.sources)")
        for (i, v) in vertices.enumerated() {
            check(tree.hasPath(to: v) == (expected[i] != nil) && tree.distance(toIndex: i) == expected[i], "\(name): hasPath and index read at \(v)")
            guard let distance = expected[i] else {
                check(tree.path(to: v) == nil && tree.parentEdge(of: v) == nil, "\(name): unreached \(v) has a path")
                continue
            }
            guard let path = tree.path(to: v) else { return check(false, "\(name): no path to \(v)") }
            check(sources.contains(path.vertices.first!) && path.vertices.last == v && path.edges.count == path.vertices.count - 1, "\(name): path ends to \(v)")
            var product = S.one
            for (k, e) in path.edges.enumerated() {
                check(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1], "\(name): path to \(v) is not a walk")
                product = product.times(weight(e))
            }
            check(product == distance, "\(name): path product to \(v) is \(product), distance \(distance)")
            check(tree.parentEdge(of: v) == path.edges.last, "\(name): parent edge of \(v)")
            check(tree.parent(of: v) == (path.edges.isEmpty ? nil : path.vertices[path.vertices.count - 2]), "\(name): parent of \(v)")
        }
    }

    static func checkMatrix<G: DirectedGraph, S: SelectiveSemiring>(
        _ matrix: DistanceMatrix<G, S>, _ graph: G, _ vertices: [G.Vertex], _ weight: (G.Edges.Index) -> S,
        _ expected: (Int, Int) -> S?, _ name: String
    ) {
        for (i, s) in vertices.enumerated() {
            for (j, t) in vertices.enumerated() {
                let distance = matrix.distance(from: s, to: t)
                check(distance == expected(i, j) && matrix.distance(fromIndex: i, toIndex: j) == distance, "\(name): \(s) to \(t) is \(String(describing: distance)), expected \(String(describing: expected(i, j)))")
                guard let path = matrix.path(from: s, to: t) else {
                    check(distance == nil, "\(name): no path \(s) to \(t)")
                    continue
                }
                check(distance != nil && path.vertices.first == s && path.vertices.last == t && Set(path.vertices).count == path.vertices.count, "\(name): path \(s) to \(t)")
                var product = S.one
                for (k, e) in path.edges.enumerated() {
                    check(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1], "\(name): path \(s) to \(t) is not a walk")
                    product = product.times(weight(e))
                }
                check(product == distance, "\(name): path product \(s) to \(t)")
            }
        }
    }

    // MARK: - Tropical against the W engine

    static func tropical(_ n: Int, _ sources: [Int], _ cutoff: Int, _ target: Int, _ raw: [(u: Int, v: Int, byte: Int)]) {
        // Weights in -4...9; 255 is the tropical zero, an edge that carries no path.
        let arcs: [Arc] = raw.map { ($0.u, $0.v, $0.byte == 255 ? Int.max : $0.byte % 14 - 4) }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
        let live = arcs.filter { $0.w != Int.max }
        let reference = DirectedPseudograph(vertices: 0 ..< n, edges: live.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "n \(n), sources \(sources): \(arcs)"
        let nonnegative: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(arcs[$0].w == Int.max ? Int.max : max(arcs[$0].w, 0)) }
        let signed: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(arcs[$0].w) }

        // Dijkstra.
        let dijkstraReference = reference.dijkstraShortestPaths(from: sources) { max(live[$0].w, 0) }
        let expected = vertices.map { dijkstraReference.distance(to: $0).map(TropicalSemiring.init) }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: nonnegative), graph, vertices, sources, nonnegative, expected, "Dijkstra, \(context)")
        let limit = TropicalSemiring(cutoff)
        let limited = vertices.map { v in sources.contains(v) ? TropicalSemiring.one : expected[v].flatMap { limit < $0 ? nil : $0 } }
        if cutoff >= 0 {
            checkTree(graph.dijkstraShortestPaths(from: sources, cutoff: limit, weight: nonnegative), graph, vertices, sources, nonnegative, limited, "Dijkstra cutoff \(cutoff), \(context)")
        }
        let single = graph.dijkstraShortestPath(from: sources[0], to: target, weight: nonnegative)
        let singleExpected = reference.dijkstraShortestPath(from: sources[0], to: target) { max(live[$0].w, 0) }?.distance
        check(single?.distance.value == singleExpected, "single target \(sources[0])→\(target): \(String(describing: single?.distance)), \(context)")
        if let single {
            check(single.path.vertices.first == sources[0] && single.path.vertices.last == target, "single target path ends, \(context)")
            check(single.path.edges.reduce(TropicalSemiring.one) { $0.times(nonnegative($1)) } == single.distance, "single target product, \(context)")
            check(Path(vertices: single.path.vertices, edges: single.path.edges, in: graph) != nil, "single target walk, \(context)")
        }
        let quarters: (Int) -> TropicalSemiring<Double> = { arcs[$0].w == Int.max ? .zero : TropicalSemiring(Double(max(arcs[$0].w, 0)) / 4) }
        let real = graph.dijkstraShortestPaths(from: sources, weight: quarters)
        let realReference = reference.dijkstraShortestPaths(from: sources) { Double(max(live[$0].w, 0)) / 4 }
        check(vertices.map { real.distance(to: $0)?.value } == vertices.map { realReference.distance(to: $0) }, "Double Dijkstra, \(context)")

        // Bellman–Ford with negative weights: nil together, or the same distances.
        let bellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: signed)
        let bellmanFordReference = reference.bellmanFordShortestPaths(from: sources) { live[$0].w }
        check((bellmanFord == nil) == (bellmanFordReference == nil), "Bellman–Ford nil, \(context)")
        if let bellmanFord, let bellmanFordReference {
            checkTree(bellmanFord, graph, vertices, sources, signed, vertices.map { bellmanFordReference.distance(to: $0).map(TropicalSemiring.init) }, "Bellman–Ford, \(context)")
        }
        let realBellmanFord = graph.bellmanFordShortestPaths(from: sources) { arcs[$0].w == Int.max ? TropicalSemiring<Double>.zero : TropicalSemiring(Double(arcs[$0].w) / 4) }
        let realBellmanFordReference = reference.bellmanFordShortestPaths(from: sources) { Double(live[$0].w) / 4 }
        check((realBellmanFord == nil) == (realBellmanFordReference == nil), "Double Bellman–Ford nil, \(context)")
        if let realBellmanFord, let realBellmanFordReference {
            check(vertices.map { realBellmanFord.distance(to: $0)?.value } == vertices.map { realBellmanFordReference.distance(to: $0) }, "Double Bellman–Ford, \(context)")
        }

        // Floyd–Warshall: nil together, or the same matrix.
        let matrix = graph.floydWarshallShortestPaths(weight: signed)
        let matrixReference = reference.floydWarshallShortestPaths { live[$0].w }
        check((matrix == nil) == (matrixReference == nil), "Floyd–Warshall nil, \(context)")
        if let matrix, let matrixReference {
            checkMatrix(matrix, graph, vertices, signed, { matrixReference.distance(from: $0, to: $1).map(TropicalSemiring.init) }, "Floyd–Warshall, \(context)")
        }

        // DAG entry points on the graph: nil exactly when a cycle is reachable.
        let cyclic = cycleReachable(n, arcs, sources)
        let dagTree = graph.dagShortestPaths(from: sources, weight: signed)
        check((dagTree == nil) == cyclic, "DAG paths nil, \(context)")
        check((graph.dagShortestDistances(from: sources, weight: signed) == nil) == cyclic, "DAG distances nil, \(context)")
        // On the acyclic orientation: against the W overload, on the graph and on its wrapper.
        let forward: [Arc] = arcs.filter { $0.u != $0.v }.map { (min($0.u, $0.v), max($0.u, $0.v), $0.w) }
        let forwardLive = forward.filter { $0.w != Int.max }
        let dagGraph = DirectedPseudograph(vertices: 0 ..< n, edges: forward.map { DirectedEdge(from: $0.u, to: $0.v) })
        let dagReference = DirectedPseudograph(vertices: 0 ..< n, edges: forwardLive.map { DirectedEdge(from: $0.u, to: $0.v) })
        guard let dag = DirectedAcyclicGraph(dagGraph) else { return check(false, "not acyclic: \(context)") }
        let forwardWeight: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(forward[$0].w) }
        guard let dagExpectedTree = dagReference.dagShortestPaths(from: sources, weight: { forwardLive[$0].w }) else { return check(false, "W DAG nil, \(context)") }
        let dagExpected = vertices.map { dagExpectedTree.distance(to: $0).map(TropicalSemiring.init) }
        if let tree = dagGraph.dagShortestPaths(from: sources, weight: forwardWeight) {
            checkTree(tree, dagGraph, vertices, sources, forwardWeight, dagExpected, "DAG paths, \(context)")
        } else {
            check(false, "DAG paths nil on a DAG, \(context)")
        }
        checkTree(dag.dagShortestPaths(from: sources, weight: forwardWeight), dag, vertices, sources, forwardWeight, dagExpected, "DirectedAcyclicGraph paths, \(context)")
        let distances = dagGraph.dagShortestDistances(from: sources, weight: forwardWeight)
        check(vertices.map { distances?.distance(to: $0) } == dagExpected.map { $0 ?? .zero }, "DAG distances, \(context)")
        let ordered = dag.dagShortestDistances(from: sources, weight: forwardWeight)
        check(vertices.map { ordered.distance(to: $0) } == dagExpected.map { $0 ?? .zero } && vertices.map { ordered.distance(toIndex: $0) } == dagExpected.map { $0 ?? .zero }, "DirectedAcyclicGraph distances, \(context)")
    }

    // MARK: - −∞ edges

    static func negativeInfinity(_ n: Int, _ sources: [Int], _ raw: [(u: Int, v: Int, byte: Int)]) {
        // Weights in -4...9, and Int.min (−∞) for one byte in 16, often on a cycle. The W engine
        // stands −∞ in with -1000: every path through it is below -500 and every other above -100.
        let arcs: [Arc] = raw.map { ($0.u, $0.v, $0.byte % 16 == 0 ? Int.min : $0.byte % 14 - 4) }
        let finite = arcs.map { $0.w == Int.min ? -1000 : $0.w }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "−∞, n \(n), sources \(sources): \(arcs)"
        let weight: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(arcs[$0].w) }
        let lift: (Int?) -> TropicalSemiring<Int>? = { $0.map { TropicalSemiring($0 < -500 ? Int.min : $0) } }
        let bellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: weight)
        let bellmanFordReference = graph.bellmanFordShortestPaths(from: sources) { finite[$0] }
        check((bellmanFord == nil) == (bellmanFordReference == nil), "Bellman–Ford nil, \(context)")
        if let bellmanFord, let bellmanFordReference {
            checkTree(bellmanFord, graph, vertices, sources, weight, vertices.map { lift(bellmanFordReference.distance(to: $0)) }, "Bellman–Ford, \(context)")
        }
        let matrix = graph.floydWarshallShortestPaths(weight: weight)
        let matrixReference = graph.floydWarshallShortestPaths { finite[$0] }
        check((matrix == nil) == (matrixReference == nil), "Floyd–Warshall nil, \(context)")
        if let matrix, let matrixReference {
            checkMatrix(matrix, graph, vertices, weight, { lift(matrixReference.distance(from: $0, to: $1)) }, "Floyd–Warshall, \(context)")
        }
        let forward: [Arc] = arcs.filter { $0.u < $0.v }
        let dagGraph = DirectedPseudograph(vertices: 0 ..< n, edges: forward.map { DirectedEdge(from: $0.u, to: $0.v) })
        let forwardWeight: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(forward[$0].w) }
        if let tree = dagGraph.dagShortestPaths(from: sources, weight: forwardWeight), let reference = dagGraph.dagShortestPaths(from: sources, weight: { forward[$0].w == Int.min ? -1000 : forward[$0].w }) {
            checkTree(tree, dagGraph, vertices, sources, forwardWeight, vertices.map { lift(reference.distance(to: $0)) }, "DAG paths, \(context)")
        } else {
            check(false, "DAG paths nil on a DAG, \(context)")
        }
    }

    // MARK: - UInt, Int8 and Float

    static func otherScalars(_ n: Int, _ sources: [Int], _ raw: [(u: Int, v: Int, byte: Int)]) {
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "scalars, n \(n), sources \(sources): \(raw)"
        // Tropical UInt: weights 0...9, 255 the zero (UInt.max), against the Int engine.
        let unsigned = raw.map { $0.byte == 255 ? nil : $0.byte % 10 }
        let unsignedWeight: (Int) -> TropicalSemiring<UInt> = { TropicalSemiring(unsigned[$0].map(UInt.init) ?? UInt.max) }
        let intWeight: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(unsigned[$0] ?? Int.max) }
        let asUInt: (TropicalSemiring<Int>?) -> TropicalSemiring<UInt>? = { $0.map { TropicalSemiring(UInt($0.value)) } }
        let intTree = graph.dijkstraShortestPaths(from: sources, weight: intWeight)
        let expected = vertices.map { asUInt(intTree.distance(to: $0)) }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: unsignedWeight), graph, vertices, sources, unsignedWeight, expected, "UInt Dijkstra, \(context)")
        if let tree = graph.bellmanFordShortestPaths(from: sources, weight: unsignedWeight) {
            checkTree(tree, graph, vertices, sources, unsignedWeight, expected, "UInt Bellman–Ford, \(context)")
        } else {
            check(false, "UInt Bellman–Ford nil, \(context)")
        }
        if let matrix = graph.floydWarshallShortestPaths(weight: unsignedWeight) {
            let rows = vertices.map { s in graph.dijkstraShortestPaths(from: s, weight: intWeight) }
            checkMatrix(matrix, graph, vertices, unsignedWeight, { asUInt(rows[$0].distance(to: $1)) }, "UInt Floyd–Warshall, \(context)")
        } else {
            check(false, "UInt Floyd–Warshall nil, \(context)")
        }

        // Tropical Int8: weights -1...9 (every examined sum fits), 255 the zero, against Int.
        let small = raw.map { $0.byte == 255 ? nil : $0.byte % 11 - 1 }
        let int8Weight: (Int) -> TropicalSemiring<Int8> = { TropicalSemiring(small[$0].map(Int8.init) ?? Int8.max) }
        let smallInt: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(small[$0] ?? Int.max) }
        let asInt8: (TropicalSemiring<Int>?) -> TropicalSemiring<Int8>? = { $0.map { TropicalSemiring(Int8($0.value)) } }
        let int8BellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: int8Weight)
        let intBellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: smallInt)
        check((int8BellmanFord == nil) == (intBellmanFord == nil), "Int8 Bellman–Ford nil, \(context)")
        if let int8BellmanFord, let intBellmanFord {
            checkTree(int8BellmanFord, graph, vertices, sources, int8Weight, vertices.map { asInt8(intBellmanFord.distance(to: $0)) }, "Int8 Bellman–Ford, \(context)")
        }
        let int8Matrix = graph.floydWarshallShortestPaths(weight: int8Weight)
        let intMatrix = graph.floydWarshallShortestPaths(weight: smallInt)
        check((int8Matrix == nil) == (intMatrix == nil), "Int8 Floyd–Warshall nil, \(context)")
        if let int8Matrix, let intMatrix {
            checkMatrix(int8Matrix, graph, vertices, int8Weight, { asInt8(intMatrix.distance(from: $0, to: $1)) }, "Int8 Floyd–Warshall, \(context)")
        }

        // Tropical Float: quarters, 255 the zero (.infinity), against Double.
        let floatWeight: (Int) -> TropicalSemiring<Float> = { unsigned[$0].map { TropicalSemiring(Float($0) / 4) } ?? .zero }
        let doubleWeight: (Int) -> TropicalSemiring<Double> = { unsigned[$0].map { TropicalSemiring(Double($0) / 4) } ?? .zero }
        let floatTree = graph.dijkstraShortestPaths(from: sources, weight: floatWeight)
        let doubleTree = graph.dijkstraShortestPaths(from: sources, weight: doubleWeight)
        let floatExpected = vertices.map { doubleTree.distance(to: $0).map { TropicalSemiring(Float($0.value)) } }
        checkTree(floatTree, graph, vertices, sources, floatWeight, floatExpected, "Float Dijkstra, \(context)")
        if let matrix = graph.floydWarshallShortestPaths(weight: floatWeight), let reference = graph.floydWarshallShortestPaths(weight: doubleWeight) {
            checkMatrix(matrix, graph, vertices, floatWeight, { reference.distance(from: $0, to: $1).map { TropicalSemiring(Float($0.value)) } }, "Float Floyd–Warshall, \(context)")
        } else {
            check(false, "Float Floyd–Warshall nil, \(context)")
        }

        // Widest paths over UInt (0 is the zero), Int8 (its own sentinels) and Float, by enumeration.
        let widths = raw.map { $0.byte == 255 ? Int.min : $0.byte == 254 ? Int.max : $0.byte % 36 - 5 }
        let arcs: [Arc] = raw.enumerated().map { ($0.element.u, $0.element.v, widths[$0.offset]) }
        let unsignedArcs: [Arc] = arcs.compactMap { $0.w <= 0 ? nil : $0 }
        let unsignedWidth: (Int) -> BottleneckSemiring<UInt> = { BottleneckSemiring(widths[$0] <= 0 ? 0 : widths[$0] == Int.max ? UInt.max : UInt(widths[$0])) }
        let unsignedExpected = simplePaths(n, unsignedArcs, sources, start: Int.max, fold: min, better: >).map { $0.map { BottleneckSemiring($0 == Int.max ? UInt.max : UInt($0)) } }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: unsignedWidth), graph, vertices, sources, unsignedWidth, unsignedExpected, "UInt widest Dijkstra, \(context)")
        let live = arcs.filter { $0.w != Int.min }
        let widest = simplePaths(n, live, sources, start: Int.max, fold: min, better: >)
        let int8Width: (Int) -> BottleneckSemiring<Int8> = { BottleneckSemiring(widths[$0] == Int.min ? Int8.min : widths[$0] == Int.max ? Int8.max : Int8(widths[$0])) }
        let int8Expected = widest.map { $0.map { BottleneckSemiring($0 == Int.max ? Int8.max : Int8($0)) } }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: int8Width), graph, vertices, sources, int8Width, int8Expected, "Int8 widest Dijkstra, \(context)")
        if let tree = graph.bellmanFordShortestPaths(from: sources, weight: int8Width) {
            checkTree(tree, graph, vertices, sources, int8Width, int8Expected, "Int8 widest Bellman–Ford, \(context)")
        } else {
            check(false, "Int8 widest Bellman–Ford nil, \(context)")
        }
        let floatWidth: (Int) -> BottleneckSemiring<Float> = { BottleneckSemiring(widths[$0] == Int.min ? -.infinity : widths[$0] == Int.max ? .infinity : Float(widths[$0])) }
        let floatWidest = widest.map { $0.map { BottleneckSemiring($0 == Int.max ? Float.infinity : Float($0)) } }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: floatWidth), graph, vertices, sources, floatWidth, floatWidest, "Float widest Dijkstra, \(context)")
        if let matrix = graph.floydWarshallShortestPaths(weight: floatWidth) {
            let rows = vertices.map { simplePaths(n, live, [$0], start: Int.max, fold: min, better: >) }
            checkMatrix(matrix, graph, vertices, floatWidth, { rows[$0][$1].map { BottleneckSemiring($0 == Int.max ? Float.infinity : Float($0)) } }, "Float widest Floyd–Warshall, \(context)")
        } else {
            check(false, "Float widest Floyd–Warshall nil, \(context)")
        }
    }

    // MARK: - NaN on edges never examined

    static func unexaminedNaN(_ n: Int, _ sources: [Int], _ raw: [(u: Int, v: Int, byte: Int)]) {
        // NaN weights may only sit on edges out of vertices the sources do not reach, which the
        // single-source searches never examine: the answers are those without the NaN.
        let plain: [Arc] = raw.map { ($0.u, $0.v, $0.byte % 10) }
        let reached = reachable(n, plain, sources)
        let isNaN = raw.map { !reached[$0.u] && $0.byte % 3 == 0 }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "NaN, n \(n), sources \(sources): \(raw.indices.map { isNaN[$0] ? "\(raw[$0].u)→\(raw[$0].v) NaN" : "\(raw[$0].u)→\(raw[$0].v) \(plain[$0].w)" })"
        let tropical: (Int) -> TropicalSemiring<Double> = { TropicalSemiring(isNaN[$0] ? .nan : Double(plain[$0].w)) }
        let clean: (Int) -> TropicalSemiring<Double> = { TropicalSemiring(isNaN[$0] ? 0 : Double(plain[$0].w)) }
        let expected = graph.dijkstraShortestPaths(from: sources, weight: clean)
        let expectedDistances = vertices.map { expected.distance(to: $0) }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: tropical), graph, vertices, sources, tropical, expectedDistances, "NaN Dijkstra, \(context)")
        if let tree = graph.bellmanFordShortestPaths(from: sources, weight: tropical) {
            checkTree(tree, graph, vertices, sources, tropical, expectedDistances, "NaN Bellman–Ford, \(context)")
        } else {
            check(false, "NaN Bellman–Ford nil, \(context)")
        }
        let width: (Int) -> BottleneckSemiring<Float> = { BottleneckSemiring(isNaN[$0] ? .nan : Float(plain[$0].w)) }
        let cleanWidth: (Int) -> BottleneckSemiring<Float> = { BottleneckSemiring(isNaN[$0] ? 0 : Float(plain[$0].w)) }
        let widest = graph.dijkstraShortestPaths(from: sources, weight: cleanWidth)
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: width), graph, vertices, sources, width, vertices.map { widest.distance(to: $0) }, "NaN widest Dijkstra, \(context)")
    }

    // MARK: - Widest paths

    static func widest(_ n: Int, _ sources: [Int], _ cutoff: Int, _ target: Int, _ raw: [(u: Int, v: Int, byte: Int)]) {
        // Widths in -5...30; 255 is the bottleneck zero (no path), 254 the one (unlimited).
        let arcs: [Arc] = raw.map { ($0.u, $0.v, $0.byte == 255 ? Int.min : $0.byte == 254 ? Int.max : $0.byte % 36 - 5) }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "n \(n), sources \(sources): \(arcs)"
        let weight: (Int) -> BottleneckSemiring<Int> = { BottleneckSemiring(arcs[$0].w) }
        let live = arcs.filter { $0.w != Int.min }
        let expected = simplePaths(n, live, sources, start: Int.max, fold: min, better: >).map { $0.map(BottleneckSemiring.init) }

        checkTree(graph.dijkstraShortestPaths(from: sources, weight: weight), graph, vertices, sources, weight, expected, "widest Dijkstra, \(context)")
        let limit = BottleneckSemiring(cutoff)
        checkTree(graph.dijkstraShortestPaths(from: sources, cutoff: limit, weight: weight), graph, vertices, sources, weight, expected.map { $0.flatMap { limit < $0 ? nil : $0 } }, "widest Dijkstra cutoff \(cutoff), \(context)")
        if let bellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: weight) {
            checkTree(bellmanFord, graph, vertices, sources, weight, expected, "widest Bellman–Ford, \(context)")
        } else {
            check(false, "widest Bellman–Ford nil, \(context)")
        }
        let real = graph.dijkstraShortestPaths(from: sources) { BottleneckSemiring(arcs[$0].w == Int.min ? -Double.infinity : arcs[$0].w == Int.max ? .infinity : Double(arcs[$0].w)) }
        check(vertices.map { real.distance(to: $0)?.value } == expected.map { $0.map { $0.value == Int.max ? .infinity : Double($0.value) } }, "Double widest Dijkstra, \(context)")
        let single = graph.dijkstraShortestPath(from: sources[0], to: target, weight: weight)
        let singleExpected = simplePaths(n, live, [sources[0]], start: Int.max, fold: min, better: >)[target]
        check(single?.distance.value == singleExpected, "widest single target, \(context)")
        if let single {
            check(single.path.edges.reduce(BottleneckSemiring.one) { $0.times(weight($1)) } == single.distance && single.path.vertices.last == target, "widest single target path, \(context)")
        }
        guard let matrix = graph.floydWarshallShortestPaths(weight: weight) else { return check(false, "widest Floyd–Warshall nil, \(context)") }
        let rows = vertices.map { simplePaths(n, live, [$0], start: Int.max, fold: min, better: >) }
        checkMatrix(matrix, graph, vertices, weight, { rows[$0][$1].map(BottleneckSemiring.init) }, "widest Floyd–Warshall, \(context)")
        // The acyclic orientation.
        let forward = arcs.filter { $0.u < $0.v }
        let dagGraph = DirectedPseudograph(vertices: 0 ..< n, edges: forward.map { DirectedEdge(from: $0.u, to: $0.v) })
        let forwardWeight: (Int) -> BottleneckSemiring<Int> = { BottleneckSemiring(forward[$0].w) }
        let dagExpected = simplePaths(n, forward.filter { $0.w != Int.min }, sources, start: Int.max, fold: min, better: >).map { $0.map(BottleneckSemiring.init) }
        if let tree = dagGraph.dagShortestPaths(from: sources, weight: forwardWeight) {
            checkTree(tree, dagGraph, vertices, sources, forwardWeight, dagExpected, "widest DAG, \(context)")
        } else {
            check(false, "widest DAG nil, \(context)")
        }
        if let dag = DirectedAcyclicGraph(dagGraph) {
            checkTree(dag.dagShortestPaths(from: sources, weight: forwardWeight), dag, vertices, sources, forwardWeight, dagExpected, "widest DirectedAcyclicGraph, \(context)")
            check(vertices.map { dag.dagShortestDistances(from: sources, weight: forwardWeight).distance(to: $0) } == dagExpected.map { $0 ?? .zero }, "widest DAG distances, \(context)")
        }
    }

    // MARK: - Counting on DAGs

    static func counting(_ n: Int, _ sources: [Int], _ raw: [(u: Int, v: Int, byte: Int)]) {
        let arcs: [Arc] = raw.compactMap { $0.u == $0.v ? nil : (min($0.u, $0.v), max($0.u, $0.v), $0.byte % 4) }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "n \(n), sources \(sources): \(arcs)"
        // Every path from each distinct source: the sum of the products of its weights.
        func enumerate(unit: Bool) -> [Int] {
            var total = [Int](repeating: 0, count: n)
            var stack = Set(sources).map { ($0, 1) }
            while let (u, product) = stack.popLast() {
                total[u] += product
                for a in arcs where a.u == u { stack.append((a.v, unit ? product : product * a.w)) }
            }
            return total
        }
        let expected = enumerate(unit: false)
        guard let dag = DirectedAcyclicGraph(graph) else { return check(false, "not acyclic: \(context)") }
        let counts = graph.dagShortestDistances(from: sources) { CountingSemiring(arcs[$0].w) }
        check(vertices.map { counts?.distance(to: $0).value } == expected, "counting, \(context)")
        check(counts.map { Set($0.sources) == Set(sources) && $0.sources.count == Set(sources).count } == true, "counting sources, \(context)")
        let ordered = dag.dagShortestDistances(from: sources) { CountingSemiring(arcs[$0].w) }
        check(vertices.map { ordered.distance(to: $0).value } == expected, "DirectedAcyclicGraph counting, \(context)")
        let real = graph.dagShortestDistances(from: sources) { CountingSemiring(Double(arcs[$0].w)) }
        check(vertices.map { real?.distance(to: $0).value } == expected.map(Double.init), "Double counting, \(context)")
        let paths = enumerate(unit: true)
        check(vertices.map { graph.dagShortestDistances(from: sources) { _ in CountingSemiring(1) }?.distance(to: $0).value } == paths, "path counts, \(context)")
        check(vertices.map { dag.dagShortestDistances(from: sources) { _ in CountingSemiring(1) }.distance(toIndex: $0).value } == paths, "DirectedAcyclicGraph path counts, \(context)")
        // With the arcs as given (cycles possible): nil exactly when a cycle is reachable.
        let given: [Arc] = raw.map { ($0.u, $0.v, 1) }
        let cyclicGraph = DirectedPseudograph(vertices: 0 ..< n, edges: given.map { DirectedEdge(from: $0.u, to: $0.v) })
        check((cyclicGraph.dagShortestDistances(from: sources) { _ in CountingSemiring(1) } == nil) == cycleReachable(n, given, sources), "counting nil, \(context)")
    }

    // MARK: - Boolean

    static func boolean(_ n: Int, _ sources: [Int], _ raw: [(u: Int, v: Int, byte: Int)]) {
        let arcs: [Arc] = raw.map { ($0.u, $0.v, $0.byte % 4 == 0 ? 0 : 1) }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
        let vertices = Array(0 ..< n)
        let context = "n \(n), sources \(sources): \(arcs)"
        let weight: (Int) -> BooleanSemiring = { BooleanSemiring(arcs[$0].w == 1) }
        guard let matrix = graph.floydWarshallShortestPaths(weight: weight) else { return check(false, "Boolean Floyd–Warshall nil, \(context)") }
        let rows = vertices.map { reachable(n, arcs, [$0]) { $0.w == 1 } }
        checkMatrix(matrix, graph, vertices, weight, { rows[$0][$1] ? .one : nil }, "Boolean Floyd–Warshall, \(context)")
        let expected = reachable(n, arcs, sources) { $0.w == 1 }.map { $0 ? BooleanSemiring.one : nil }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: weight), graph, vertices, sources, weight, expected, "Boolean Dijkstra, \(context)")
        if let bellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: weight) {
            checkTree(bellmanFord, graph, vertices, sources, weight, expected, "Boolean Bellman–Ford, \(context)")
        } else {
            check(false, "Boolean Bellman–Ford nil, \(context)")
        }
        let cyclic = cycleReachable(n, arcs, sources)
        if let tree = graph.dagShortestPaths(from: sources, weight: weight) {
            check(!cyclic, "Boolean DAG not nil, \(context)")
            checkTree(tree, graph, vertices, sources, weight, expected, "Boolean DAG, \(context)")
        } else {
            check(cyclic, "Boolean DAG nil, \(context)")
        }
    }

    // MARK: - Undirected

    static func undirected(_ n: Int, _ sources: [Int], _ cutoff: Int, _ target: Int, _ raw: [(u: Int, v: Int, byte: Int)]) {
        let edges: [Arc] = raw.map { ($0.u, $0.v, $0.byte % 14 - 4) }
        let graph = Pseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.u, $0.v) })
        let view = graph.directedView
        let vertices = Array(0 ..< n)
        let context = "undirected n \(n), sources \(sources): \(edges)"
        let nonnegative: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(max(edges[$0].w, 0)) }
        let viewNonnegative: (DirectedView<Pseudograph<Int>>.Edges.Index) -> TropicalSemiring<Int> = { nonnegative($0.position) }

        // Tropical against the numeric overloads.
        let reference = graph.dijkstraShortestPaths(from: sources) { max(edges[$0].w, 0) }
        let expected = vertices.map { reference.distance(to: $0).map(TropicalSemiring.init) }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: nonnegative), view, vertices, sources, viewNonnegative, expected, "Dijkstra, \(context)")
        let limit = TropicalSemiring(cutoff)
        if cutoff >= 0 {
            let limited = vertices.map { v in sources.contains(v) ? TropicalSemiring.one : expected[v].flatMap { limit < $0 ? nil : $0 } }
            checkTree(graph.dijkstraShortestPaths(from: sources, cutoff: limit, weight: nonnegative), view, vertices, sources, viewNonnegative, limited, "Dijkstra cutoff \(cutoff), \(context)")
        }
        let single = graph.dijkstraShortestPath(from: sources[0], to: target, weight: nonnegative)
        check(single?.distance.value == graph.dijkstraShortestPath(from: sources[0], to: target) { max(edges[$0].w, 0) }?.distance, "single target, \(context)")
        if let single {
            check(single.path.vertices.first == sources[0] && single.path.vertices.last == target, "single target ends, \(context)")
            check(single.path.edges.reduce(TropicalSemiring.one) { $0.times(viewNonnegative($1)) } == single.distance, "single target product, \(context)")
            check(Path(vertices: single.path.vertices, edges: single.path.edges, in: view) != nil, "single target walk, \(context)")
        }
        let signed: (Int) -> TropicalSemiring<Int> = { TropicalSemiring(edges[$0].w) }
        let bellmanFord = graph.bellmanFordShortestPaths(from: sources, weight: signed)
        let bellmanFordReference = graph.bellmanFordShortestPaths(from: sources) { edges[$0].w }
        let negativeReachable = edges.contains { $0.w < 0 && reachable(n, edges.flatMap { [$0, ($0.v, $0.u, $0.w)] }, sources)[$0.u] }
        check((bellmanFord == nil) == negativeReachable && (bellmanFordReference == nil) == negativeReachable, "Bellman–Ford nil, \(context)")
        if let bellmanFord, let bellmanFordReference {
            checkTree(bellmanFord, view, vertices, sources, { signed($0.position) }, vertices.map { bellmanFordReference.distance(to: $0).map(TropicalSemiring.init) }, "Bellman–Ford, \(context)")
        }
        let matrix = graph.floydWarshallShortestPaths(weight: signed)
        let matrixReference = graph.floydWarshallShortestPaths { edges[$0].w }
        check((matrix == nil) == (matrixReference == nil) && (matrix == nil) == edges.contains { $0.w < 0 }, "Floyd–Warshall nil, \(context)")
        if let matrix, let matrixReference {
            checkMatrix(matrix, view, vertices, { signed($0.position) }, { matrixReference.distance(from: $0, to: $1).map(TropicalSemiring.init) }, "Floyd–Warshall, \(context)")
        }

        // Widest paths against the enumeration over both arcs.
        let both = edges.flatMap { [$0, ($0.v, $0.u, $0.w)] }
        let width: (Int) -> BottleneckSemiring<Int> = { BottleneckSemiring(edges[$0].w) }
        let viewWidth: (DirectedView<Pseudograph<Int>>.Edges.Index) -> BottleneckSemiring<Int> = { width($0.position) }
        let widest = simplePaths(n, both, sources, start: Int.max, fold: min, better: >).map { $0.map(BottleneckSemiring.init) }
        checkTree(graph.dijkstraShortestPaths(from: sources, weight: width), view, vertices, sources, viewWidth, widest, "widest Dijkstra, \(context)")
        if let tree = graph.bellmanFordShortestPaths(from: sources, weight: width) {
            checkTree(tree, view, vertices, sources, viewWidth, widest, "widest Bellman–Ford, \(context)")
        } else {
            check(false, "widest Bellman–Ford nil, \(context)")
        }
        if let widestMatrix = graph.floydWarshallShortestPaths(weight: width) {
            let rows = vertices.map { simplePaths(n, both, [$0], start: Int.max, fold: min, better: >) }
            checkMatrix(widestMatrix, view, vertices, viewWidth, { rows[$0][$1].map(BottleneckSemiring.init) }, "widest Floyd–Warshall, \(context)")
        } else {
            check(false, "widest Floyd–Warshall nil, \(context)")
        }

        // Without vertex indices (strings, one edge per pair, the first width): through the view.
        var firstWidth: [UndirectedEdge<Int>: Int] = [:]
        for e in edges where firstWidth[UndirectedEdge(e.u, e.v)] == nil { firstWidth[UndirectedEdge(e.u, e.v)] = e.w }
        let names = vertices.map { "v\($0)" }
        let named = UndirectedAdjacencyList(vertices: names, edges: firstWidth.keys.sorted().map { UndirectedEdge(names[$0.u], names[$0.v]) })
        let namedWidth: (UndirectedAdjacencyList<String>.Edges.Index) -> BottleneckSemiring<Int> = { e in
            let edge = named.edges[e]
            return BottleneckSemiring(firstWidth[UndirectedEdge(names.firstIndex(of: edge.u)!, names.firstIndex(of: edge.v)!)]!)
        }
        let simple = firstWidth.flatMap { [($0.key.u, $0.key.v, $0.value), ($0.key.v, $0.key.u, $0.value)] }
        let simpleWidest = simplePaths(n, simple, sources, start: Int.max, fold: min, better: >).map { $0.map(BottleneckSemiring.init) }
        let namedTree = named.dijkstraShortestPaths(from: sources.map { names[$0] }, weight: namedWidth)
        checkTree(namedTree, named.directedView, names, sources.map { names[$0] }, { namedWidth($0.position) }, simpleWidest, "widest Dijkstra without indices, \(context)")
        let namedSingle = named.dijkstraShortestPath(from: names[sources[0]], to: names[target], weight: namedWidth)
        check(namedSingle?.distance == simplePaths(n, simple, [sources[0]], start: Int.max, fold: min, better: >)[target].map(BottleneckSemiring.init), "widest single target without indices, \(context)")
        if let namedSingle {
            check(namedSingle.path.vertices.first == names[sources[0]] && namedSingle.path.vertices.last == names[target], "single target ends without indices, \(context)")
        }
    }
}
