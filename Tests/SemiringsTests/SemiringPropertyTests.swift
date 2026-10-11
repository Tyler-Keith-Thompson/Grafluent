// Properties with shrinking (swift-property-based). The semiring laws on random values of every
// type, in both spellings (the requirements plus(_:) and times(_:), and the operators ⊕ and ⊗),
// with the natural order checked against ⊕. Then random multigraphs (loops, parallel edges,
// negative weights): the semiring and W overloads give the same distances; path counts on DAGs
// equal a brute-force enumeration of the paths; widest paths equal the best bottleneck over the
// simple paths; Boolean Floyd–Warshall is reachability by breadth-first search. See README.md.

import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings properties, with shrinking", .tags(.randomized))
struct SemiringPropertyTests {
    @Test("The semiring laws, in both spellings, on random values of every type")
    func laws() async {
        func check<S: Semiring & Hashable>(_ a: S, _ b: S, _ c: S, commutativeTimes: Bool = true) {
            let context = "\(a) \(b) \(c)"
            #expect(a.plus(b).plus(c) == a.plus(b.plus(c)), "⊕ associative: \(context)")
            #expect(a.plus(b) == b.plus(a), "⊕ commutative: \(context)")
            #expect(a.plus(.zero) == a && S.zero.plus(a) == a, "zero is ⊕'s identity: \(context)")
            #expect(a.times(b).times(c) == a.times(b.times(c)), "⊗ associative: \(context)")
            #expect(a.times(.one) == a && S.one.times(a) == a, "one is ⊗'s identity: \(context)")
            #expect(a.times(.zero) == .zero && S.zero.times(a) == .zero, "zero annihilates: \(context)")
            #expect(a.times(b.plus(c)) == a.times(b).plus(a.times(c)), "left distributive: \(context)")
            #expect(a.plus(b).times(c) == a.times(c).plus(b.times(c)), "right distributive: \(context)")
            if commutativeTimes { #expect(a.times(b) == b.times(a), "⊗ commutative: \(context)") }
            // The operators call the methods.
            // (Outside #expect: the macro folds an expression without the operators' precedences.)
            let sum = a ⊕ b, product = a ⊗ b, sumTimes = (a ⊕ b) ⊗ c, plusProduct = a ⊕ b ⊗ c
            #expect(sum == a.plus(b) && product == a.times(b), "operators: \(context)")
            #expect(sumTimes == a.plus(b).times(c) && plusProduct == a.plus(b.times(c)), "precedence: \(context)")
            // Hashable: equal values hash alike.
            if a == b { #expect(a.hashValue == b.hashValue, "hash: \(context)") }
        }
        func order<S: SelectiveSemiring & Hashable>(_ a: S, _ b: S, _ c: S) {
            let context = "\(a) \(b) \(c)"
            #expect(a.plus(b) == (b < a ? b : a), "selective: \(context)")
            #expect(a.plus(a) == a, "idempotent: \(context)")
            // The natural order: a < b exactly when a ⊕ b == a != b; a strict total order.
            #expect((a < b) == (a.plus(b) == a && a != b), "natural order: \(context)")
            #expect([a < b, b < a, a == b].filter { $0 }.count == 1, "trichotomy: \(context)")
            if a < b && b < c { #expect(a < c, "transitive: \(context)") }
            #expect(!(S.zero < a) && (a < .zero || a == .zero), "zero is the worst: \(context)")
            #expect((a <= b) == (a.plus(b) == a) && (a > b) == (b < a), "Comparable's derived operators: \(context)")
        }
        let tropicalInt = Gen.int(in: -60 ... 50).map { $0 < -50 ? Int.max : $0 }
        await propertyCheck(count: 500, input: tropicalInt, tropicalInt, tropicalInt) { a, b, c in
            check(TropicalSemiring(a), TropicalSemiring(b), TropicalSemiring(c))
            order(TropicalSemiring(a), TropicalSemiring(b), TropicalSemiring(c))
        }
        let tropicalDouble = Gen.int(in: -210 ... 200).map { $0 < -200 ? Double.infinity : Double($0) / 4 }
        await propertyCheck(count: 500, input: tropicalDouble, tropicalDouble, tropicalDouble) { a, b, c in
            check(TropicalSemiring(a), TropicalSemiring(b), TropicalSemiring(c))
            order(TropicalSemiring(a), TropicalSemiring(b), TropicalSemiring(c))
        }
        let bottleneckInt = Gen.int(in: -70 ... 50).map { $0 < -60 ? Int.max : $0 < -50 ? Int.min : $0 }
        await propertyCheck(count: 500, input: bottleneckInt, bottleneckInt, bottleneckInt) { a, b, c in
            check(BottleneckSemiring(a), BottleneckSemiring(b), BottleneckSemiring(c))
            order(BottleneckSemiring(a), BottleneckSemiring(b), BottleneckSemiring(c))
        }
        let bottleneckDouble = Gen.int(in: -220 ... 200).map { $0 < -210 ? Double.infinity : $0 < -200 ? -Double.infinity : Double($0) / 4 }
        await propertyCheck(count: 500, input: bottleneckDouble, bottleneckDouble, bottleneckDouble) { a, b, c in
            check(BottleneckSemiring(a), BottleneckSemiring(b), BottleneckSemiring(c))
            order(BottleneckSemiring(a), BottleneckSemiring(b), BottleneckSemiring(c))
        }
        await propertyCheck(count: 100, input: Gen.bool(), Gen.bool(), Gen.bool()) { a, b, c in
            check(BooleanSemiring(a), BooleanSemiring(b), BooleanSemiring(c))
            order(BooleanSemiring(a), BooleanSemiring(b), BooleanSemiring(c))
            #expect(BooleanSemiring(a).plus(BooleanSemiring(b)).value == (a || b) && BooleanSemiring(a).times(BooleanSemiring(b)).value == (a && b))
        }
        let count = Gen.int(in: -50 ... 50)
        await propertyCheck(count: 500, input: count, count, count) { a, b, c in
            check(CountingSemiring(a), CountingSemiring(b), CountingSemiring(c))
            check(CountingSemiring(Double(a) / 4), CountingSemiring(Double(b) / 4), CountingSemiring(Double(c) / 4))
            #expect(CountingSemiring(a).plus(CountingSemiring(b)).value == a + b && CountingSemiring(a).times(CountingSemiring(b)).value == a * b)
            // Not idempotent: a ⊕ a is 2a.
            #expect((CountingSemiring(a).plus(CountingSemiring(a)) == CountingSemiring(a)) == (a == 0))
        }
        // The raw values: tropical is (min, +), bottleneck (max, min), with Int.max the tropical zero.
        await propertyCheck(count: 300, input: Gen.int(in: -50 ... 50), Gen.int(in: -50 ... 50)) { a, b in
            #expect(TropicalSemiring(a).plus(TropicalSemiring(b)).value == min(a, b) && TropicalSemiring(a).times(TropicalSemiring(b)).value == a + b)
            #expect(BottleneckSemiring(a).plus(BottleneckSemiring(b)).value == max(a, b) && BottleneckSemiring(a).times(BottleneckSemiring(b)).value == min(a, b))
            #expect(TropicalSemiring(a).times(TropicalSemiring(Int.max)) == .zero && (TropicalSemiring(a) < TropicalSemiring(b)) == (a < b))
            #expect((BottleneckSemiring(a) < BottleneckSemiring(b)) == (a > b))
        }
    }

    @Test("The semiring and W overloads give the same distances on random multigraphs, Int and Double")
    func overloadsAgree() async throws {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: -3 ... 12)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 8), edges) { n, raw in
            let arcs = raw.map { (u: $0.0 % n, v: $0.1 % n, w: $0.2) }
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
            let nonnegative = arcs.map { max($0.w, 0) }
            let signed = arcs.map(\.w)
            let quarters = arcs.map { Double($0.w) / 4 }
            let context = "n \(n): \(arcs)"
            for s in 0 ..< n {
                // Dijkstra, with and without a cutoff; every tree path's product is its distance.
                let tree = graph.dijkstraShortestPaths(from: s) { TropicalSemiring(nonnegative[$0]) }
                let reference = graph.dijkstraShortestPaths(from: s) { nonnegative[$0] }
                #expect((0 ..< n).map { tree.distance(to: $0)?.value } == (0 ..< n).map { reference.distance(to: $0) }, "Dijkstra from \(s), \(context)")
                for v in 0 ..< n {
                    guard let path = tree.path(to: v) else { continue }
                    #expect(path.edges.reduce(TropicalSemiring<Int>.one) { $0.times(TropicalSemiring(nonnegative[$1])) } == tree.distance(to: v), "path to \(v) from \(s), \(context)")
                }
                let cut = graph.dijkstraShortestPaths(from: s, cutoff: TropicalSemiring<Int>(6)) { TropicalSemiring(nonnegative[$0]) }
                let cutReference = graph.dijkstraShortestPaths(from: s, cutoff: 6) { nonnegative[$0] }
                #expect((0 ..< n).map { cut.distance(to: $0)?.value } == (0 ..< n).map { cutReference.distance(to: $0) }, "cutoff from \(s), \(context)")
                let real = graph.dijkstraShortestPaths(from: s) { TropicalSemiring(max(quarters[$0], 0)) }
                let realReference = graph.dijkstraShortestPaths(from: s) { max(quarters[$0], 0) }
                #expect((0 ..< n).map { real.distance(to: $0)?.value } == (0 ..< n).map { realReference.distance(to: $0) }, "Double Dijkstra from \(s), \(context)")
                // Bellman–Ford with negative weights: nil together, or the same distances.
                let bellmanFord = graph.bellmanFordShortestPaths(from: s) { TropicalSemiring(signed[$0]) }
                let bellmanFordReference = graph.bellmanFordShortestPaths(from: s) { signed[$0] }
                #expect((bellmanFord == nil) == (bellmanFordReference == nil), "Bellman–Ford nil from \(s), \(context)")
                if let bellmanFord, let bellmanFordReference {
                    #expect((0 ..< n).map { bellmanFord.distance(to: $0)?.value } == (0 ..< n).map { bellmanFordReference.distance(to: $0) }, "Bellman–Ford from \(s), \(context)")
                }
                let realBellmanFord = graph.bellmanFordShortestPaths(from: s) { TropicalSemiring(quarters[$0]) }
                let realBellmanFordReference = graph.bellmanFordShortestPaths(from: s) { quarters[$0] }
                #expect(realBellmanFord?.distance(to: 0)?.value == realBellmanFordReference?.distance(to: 0) && (realBellmanFord == nil) == (realBellmanFordReference == nil), "Double Bellman–Ford from \(s), \(context)")
            }
            let several = graph.dijkstraShortestPaths(from: [0, n - 1]) { TropicalSemiring(nonnegative[$0]) }
            let severalReference = graph.dijkstraShortestPaths(from: [0, n - 1]) { nonnegative[$0] }
            #expect((0 ..< n).map { several.distance(to: $0)?.value } == (0 ..< n).map { severalReference.distance(to: $0) }, "several sources, \(context)")
            // Floyd–Warshall: nil together, or the same matrix, and each row is Bellman–Ford's.
            let matrix = graph.floydWarshallShortestPaths { TropicalSemiring(signed[$0]) }
            let matrixReference = graph.floydWarshallShortestPaths { signed[$0] }
            #expect((matrix == nil) == (matrixReference == nil), "Floyd–Warshall nil, \(context)")
            if let matrix, let matrixReference {
                for i in 0 ..< n {
                    let row = (0 ..< n).map { matrix.distance(from: i, to: $0)?.value }
                    #expect(row == (0 ..< n).map { matrixReference.distance(from: i, to: $0) }, "Floyd–Warshall row \(i), \(context)")
                    let bellmanFord = graph.bellmanFordShortestPaths(from: i) { TropicalSemiring(signed[$0]) }
                    #expect(row == (0 ..< n).map { bellmanFord?.distance(to: $0)?.value }, "Floyd–Warshall row \(i) against Bellman–Ford, \(context)")
                    for j in 0 ..< n {
                        guard let path = matrix.path(from: i, to: j) else { continue }
                        #expect(path.edges.reduce(TropicalSemiring<Int>.one) { $0.times(TropicalSemiring(signed[$1])) } == matrix.distance(from: i, to: j), "path \(i) to \(j), \(context)")
                    }
                }
            }
            // DAG paths on the acyclic orientation (low to high), on the graph and its wrapper.
            let forward = arcs.filter { $0.u != $0.v }.map { (u: min($0.u, $0.v), v: max($0.u, $0.v), w: $0.w) }
            let dagGraph = DirectedPseudograph(vertices: 0 ..< n, edges: forward.map { DirectedEdge(from: $0.u, to: $0.v) })
            guard let dag = DirectedAcyclicGraph(dagGraph) else {
                Issue.record("not acyclic: \(context)")
                return
            }
            for s in 0 ..< n {
                let reference = dagGraph.dagShortestPaths(from: s) { forward[$0].w }
                let tree = dagGraph.dagShortestPaths(from: s) { TropicalSemiring(forward[$0].w) }
                let ordered = dag.dagShortestPaths(from: s) { TropicalSemiring(forward[$0].w) }
                let distances = dagGraph.dagShortestDistances(from: s) { TropicalSemiring(forward[$0].w) }
                let expected = (0 ..< n).map { reference?.distance(to: $0) }
                #expect((0 ..< n).map { tree?.distance(to: $0)?.value } == expected, "DAG from \(s), \(context)")
                #expect((0 ..< n).map { ordered.distance(to: $0)?.value } == expected, "DirectedAcyclicGraph from \(s), \(context)")
                #expect((0 ..< n).map { distances?.distance(to: $0).value } == expected.map { $0 ?? Int.max }, "dagShortestDistances from \(s), \(context)")
            }
        }
    }

    @Test("Path counts on random DAGs equal a brute-force enumeration of the paths, Int and Double, one source or several")
    func countingAgainstEnumeration() async throws {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 3)).array(of: 0 ... 26)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 9), edges, Gen.int(in: 0 ... 8)) { n, raw, second in
            // Low to high, so acyclic; parallel edges stay.
            let arcs = raw.compactMap { e -> (u: Int, v: Int, w: Int)? in
                let u = e.0 % n, v = e.1 % n
                return u == v ? nil : (u: min(u, v), v: max(u, v), w: e.2)
            }
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
            let context = "n \(n): \(arcs)"
            // Every path from `s`, enumerated: the sum over paths of the product of their weights.
            func enumerate(from s: Int) -> [Int] {
                var total = [Int](repeating: 0, count: n)
                var stack = [(s, 1)]
                while let (u, product) = stack.popLast() {
                    total[u] += product
                    for a in arcs where a.u == u { stack.append((a.v, product * a.w)) }
                }
                return total
            }
            guard let dag = DirectedAcyclicGraph(graph) else {
                Issue.record("not acyclic: \(context)")
                return
            }
            for s in 0 ..< n {
                let expected = enumerate(from: s)
                let counts = graph.dagShortestDistances(from: s) { CountingSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { counts?.distance(to: $0).value } == expected, "from \(s), \(context)")
                let ordered = dag.dagShortestDistances(from: s) { CountingSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { ordered.distance(to: $0).value } == expected, "DirectedAcyclicGraph from \(s), \(context)")
                let real = graph.dagShortestDistances(from: s) { CountingSemiring(Double(arcs[$0].w)) }
                #expect((0 ..< n).map { real?.distance(to: $0).value } == expected.map(Double.init), "Double from \(s), \(context)")
                // Unit weights count the paths.
                let unit = graph.dagShortestDistances(from: s) { _ in CountingSemiring(1) }
                let paths = { () -> [Int] in
                    var total = [Int](repeating: 0, count: n)
                    var stack = [s]
                    while let u = stack.popLast() {
                        total[u] += 1
                        for a in arcs where a.u == u { stack.append(a.v) }
                    }
                    return total
                }()
                #expect((0 ..< n).map { unit?.distance(to: $0).value } == paths, "path counts from \(s), \(context)")
            }
            // Several sources add: each listed once, a source reached from another counts both.
            let t = second % n
            let both = graph.dagShortestDistances(from: [0, t, 0]) { CountingSemiring(arcs[$0].w) }
            let first = enumerate(from: 0), other = enumerate(from: t)
            let expected = t == 0 ? first : zip(first, other).map { $0 + $1 }
            #expect((0 ..< n).map { both?.distance(to: $0).value } == expected, "from [0, \(t)], \(context)")
            #expect(both?.sources == (t == 0 ? [0] : [0, t]), "sources, \(context)")
        }
    }

    @Test("Widest paths equal the best bottleneck over the simple paths: Dijkstra, Bellman–Ford, Floyd–Warshall, DAG paths")
    func widestAgainstBruteForce() async throws {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: -5 ... 30)).array(of: 0 ... 18)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 7), edges) { n, raw in
            let arcs = raw.map { (u: $0.0 % n, v: $0.1 % n, w: $0.2) }
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
            let context = "n \(n): \(arcs)"
            // The widest simple path from s to every vertex: Int.max for s itself (the empty path),
            // nil where no path.
            func widest(from s: Int) -> [Int?] {
                var best = [Int?](repeating: nil, count: n)
                best[s] = Int.max
                func walk(_ u: Int, _ width: Int, _ seen: Set<Int>) {
                    for a in arcs where a.u == u && !seen.contains(a.v) {
                        let w = min(width, a.w)
                        if best[a.v] == nil || w > best[a.v]! { best[a.v] = w }
                        walk(a.v, w, seen.union([a.v]))
                    }
                }
                walk(s, Int.max, [s])
                return best
            }
            let matrix = graph.floydWarshallShortestPaths { BottleneckSemiring(arcs[$0].w) }
            #expect(matrix != nil, "a bottleneck matrix is never nil: \(context)")
            for s in 0 ..< n {
                let expected = widest(from: s)
                let tree = graph.dijkstraShortestPaths(from: s) { BottleneckSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { tree.distance(to: $0)?.value } == expected, "Dijkstra from \(s), \(context)")
                let bellmanFord = graph.bellmanFordShortestPaths(from: s) { BottleneckSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { bellmanFord?.distance(to: $0)?.value } == expected, "Bellman–Ford from \(s), \(context)")
                #expect((0 ..< n).map { matrix?.distance(from: s, to: $0)?.value } == expected, "Floyd–Warshall from \(s), \(context)")
                let real = graph.dijkstraShortestPaths(from: s) { BottleneckSemiring(Double(arcs[$0].w)) }
                #expect((0 ..< n).map { real.distance(to: $0)?.value } == expected.map { $0.map { $0 == Int.max ? Double.infinity : Double($0) } }, "Double Dijkstra from \(s), \(context)")
                for t in 0 ..< n {
                    let result = graph.dijkstraShortestPath(from: s, to: t) { BottleneckSemiring(arcs[$0].w) }
                    #expect(result?.distance.value == expected[t], "path \(s) to \(t), \(context)")
                    if let result {
                        #expect(result.path.edges.reduce(Int.max) { min($0, arcs[$1].w) } == expected[t] && result.path.vertices.last == t, "path \(s) to \(t), \(context)")
                    }
                    if let path = matrix?.path(from: s, to: t) {
                        #expect(path.edges.reduce(BottleneckSemiring<Int>.one) { $0 ⊗ BottleneckSemiring(arcs[$1].w) }.value == expected[t], "matrix path \(s) to \(t), \(context)")
                    }
                }
                // With a cutoff: exactly the vertices at least this wide.
                let cut = graph.dijkstraShortestPaths(from: s, cutoff: BottleneckSemiring<Int>(10)) { BottleneckSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { cut.distance(to: $0)?.value } == expected.map { $0.flatMap { $0 >= 10 ? $0 : nil } }, "cutoff from \(s), \(context)")
            }
            // DAG paths on the acyclic orientation.
            let forward = arcs.filter { $0.u < $0.v }
            let dagGraph = DirectedPseudograph(vertices: 0 ..< n, edges: forward.map { DirectedEdge(from: $0.u, to: $0.v) })
            let dagMatrix = dagGraph.floydWarshallShortestPaths { BottleneckSemiring(forward[$0].w) }
            for s in 0 ..< n {
                let tree = dagGraph.dagShortestPaths(from: s) { BottleneckSemiring(forward[$0].w) }
                #expect((0 ..< n).map { tree?.distance(to: $0)?.value } == (0 ..< n).map { dagMatrix?.distance(from: s, to: $0)?.value }, "DAG from \(s), \(context)")
            }
        }
    }

    @Test("Boolean Floyd–Warshall is reflexive reachability by breadth-first search over the true edges")
    func booleanClosureAgainstSearch() async throws {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9), Gen.bool(0.75)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 10), edges) { n, raw in
            let arcs = raw.map { (u: $0.0 % n, v: $0.1 % n, w: $0.2) }
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.u, to: $0.v) })
            let context = "n \(n): \(arcs)"
            guard let matrix = graph.floydWarshallShortestPaths(weight: { BooleanSemiring(arcs[$0].w) }) else {
                Issue.record("a Boolean matrix is never nil: \(context)")
                return
            }
            for s in 0 ..< n {
                // Breadth-first search over the true edges.
                var reached = [Bool](repeating: false, count: n)
                reached[s] = true
                var queue = [s], head = 0
                while head < queue.count {
                    let u = queue[head]
                    head += 1
                    for a in arcs where a.u == u && a.w && !reached[a.v] {
                        reached[a.v] = true
                        queue.append(a.v)
                    }
                }
                let expected = reached.map { $0 ? true : nil }
                #expect((0 ..< n).map { matrix.distance(from: s, to: $0)?.value } == expected, "Floyd–Warshall row \(s), \(context)")
                let tree = graph.dijkstraShortestPaths(from: s) { BooleanSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { tree.distance(to: $0)?.value } == expected, "Dijkstra from \(s), \(context)")
                let bellmanFord = graph.bellmanFordShortestPaths(from: s) { BooleanSemiring(arcs[$0].w) }
                #expect((0 ..< n).map { bellmanFord?.distance(to: $0)?.value } == expected, "Bellman–Ford from \(s), \(context)")
                for t in 0 ..< n {
                    guard let path = matrix.path(from: s, to: t) else { continue }
                    #expect(path.edges.allSatisfy { arcs[$0].w } && path.vertices.first == s && path.vertices.last == t, "path \(s) to \(t), \(context)")
                }
            }
        }
    }
}
