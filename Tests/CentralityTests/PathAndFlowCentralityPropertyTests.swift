// Load, percolation, group, current-flow and subgraph centrality and communicability against oracles
// written inside each test, with shrinking (swift-property-based). Graphs are small multigraphs with
// self-loops (simple, connected or not, where a measure needs it), by vertex value over the edge
// list. The oracles: shortest paths enumerated one by one (σ_st(v), σ_st(C)); load by recursion
// over predecessor edges; potentials by Gaussian elimination on the Laplacian grounded at vertex 0
// for current flow; Σ_k A^k / k! to 60 terms for the exponential.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Path and flow centrality against oracles, with shrinking", .tags(.randomized))
struct PathAndFlowCentralityPropertyTests {
    @Test("Load, percolation and group betweenness equal their definitions over enumerated shortest paths (both kinds, parallel edges and loops)")
    func pathMeasures() async {
        let pairs = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        let groupBits = Gen.bool.array(of: 7 ... 7)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 1 ... 7), Gen.bool, groupBits, Gen.bool) { raw, n, directed, rawGroup, endpoints in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            // Out-slots by value: each edge once per direction it can be walked; loops never.
            var out = [[Int]](repeating: [], count: n)
            for (u, v) in ends where u != v {
                out[u].append(v)
                if !directed { out[v].append(u) }
            }
            func distances(from s: Int) -> [Int] {
                var d = [Int](repeating: -1, count: n)
                d[s] = 0
                var queue = [s], head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for w in out[v] where d[w] < 0 {
                        d[w] = d[v] + 1
                        queue.append(w)
                    }
                }
                return d
            }
            let d = (0 ..< n).map(distances)
            // Every shortest s–t path as its vertex sequence (parallel copies give repeats).
            func paths(_ s: Int, _ t: Int) -> [[Int]] {
                if s == t { return [[s]] }
                guard d[s][t] > 0 else { return [] }
                var result: [[Int]] = []
                for v in 0 ..< n where d[s][v] == d[s][t] - 1 {
                    let copies = out[v].filter { $0 == t }.count
                    for prefix in paths(s, v) { for _ in 0 ..< copies { result.append(prefix + [t]) } }
                }
                return result
            }
            let group = (0 ..< n).filter { rawGroup[$0] }
            let inGroup = Set(group)
            var load = [Double](repeating: 0, count: n)
            var percolation = [Double](repeating: 0, count: n)
            let states = (0 ..< n).map { Double($0 % 3) / 2 }
            let total = states.reduce(0, +)
            var groupSum = 0.0
            for s in 0 ..< n {
                // Load toward s: a packet from t splits evenly over t's predecessor slots.
                var share = [Double](repeating: 0, count: n)
                func send(_ v: Int, _ amount: Double) {
                    if v == s { return }
                    share[v] += amount
                    let predecessors = (0 ..< n).flatMap { u in out[u].filter { $0 == v && d[s][u] == d[s][v] - 1 }.map { _ in u } }
                    for u in predecessors { send(u, amount / Double(predecessors.count)) }
                }
                for t in 0 ..< n where t != s && d[s][t] > 0 {
                    send(t, 1)
                    share[t] -= 1
                    let all = paths(s, t)
                    for v in 0 ..< n where v != s && v != t {
                        let through = Double(all.filter { $0.contains(v) }.count) / Double(all.count)
                        if total - states[v] > 0 { percolation[v] += through * states[s] / (total - states[v]) }
                    }
                    if inGroup.contains(s) || inGroup.contains(t) {
                        if endpoints { groupSum += 1 }
                    } else {
                        groupSum += Double(all.filter { !inGroup.isDisjoint(with: $0) }.count) / Double(all.count)
                    }
                }
                for v in 0 ..< n where v != s { load[v] += share[v] }
            }
            if n > 2 {
                let scale = 1 / Double((n - 1) * (n - 2))
                load = load.map { $0 * scale }
                percolation = percolation.map { $0 / Double(n - 2) }
            }
            let size = Double(endpoints ? n : n - group.count)
            let groupBetweenness = size < 2 ? groupSum : groupSum / (size * (size - 1))
            let rawGroupBetweenness = directed ? groupSum : groupSum / 2
            let context = "\(ends), directed \(directed), group \(group), endpoints \(endpoints)"
            func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) <= 1e-9 * max(1, abs(b)) }
            if directed {
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                #expect(zip(graph.loadCentrality().scores, load).allSatisfy(near), "load; \(context)")
                #expect(zip(graph.loadCentrality(weight: { _ in 1 }).scores, load).allSatisfy(near), "weighted load; \(context)")
                #expect(zip(graph.percolationCentrality(state: { states[$0] }).scores, percolation).allSatisfy(near), "percolation; \(context)")
                #expect(near(graph.groupBetweennessCentrality(of: group, endpoints: endpoints), groupBetweenness), "group; \(context)")
                #expect(near(graph.groupBetweennessCentrality(of: group, weight: { _ in 2.5 }, normalized: false, endpoints: endpoints), rawGroupBetweenness), "raw group; \(context)")
            } else {
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                #expect(zip(graph.loadCentrality().scores, load).allSatisfy(near), "load; \(context)")
                #expect(zip(graph.loadCentrality(weight: { _ in 1.0 }).scores, load).allSatisfy(near), "weighted load; \(context)")
                #expect(zip(graph.percolationCentrality(state: { states[$0] }, weight: { _ in 3 }).scores, percolation).allSatisfy(near), "percolation; \(context)")
                #expect(near(graph.groupBetweennessCentrality(of: group, endpoints: endpoints), groupBetweenness), "group; \(context)")
                #expect(near(graph.groupBetweennessCentrality(of: group, normalized: false, endpoints: endpoints), rawGroupBetweenness), "raw group; \(context)")
            }
        }
    }

    @Test("Group closeness and degree equal their definitions (multi-source distances, neighbor sets), both kinds")
    func groupClosenessAndDegree() async {
        let pairs = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        let groupBits = Gen.bool.array(of: 7 ... 7)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 2 ... 7), Gen.bool, groupBits) { raw, n, directed, rawGroup in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            var group = (0 ..< n).filter { rawGroup[$0] }
            if group.count == n { group.removeLast() }
            let inGroup = Set(group)
            // d(S, v) by repeated relaxation over arcs u → v (toward S for directed: reversed).
            var d = (0 ..< n).map { inGroup.contains($0) ? 0 : Int.max }
            for _ in 0 ..< n {
                for (u, v) in ends {
                    let arcs = directed ? [(v, u)] : [(u, v), (v, u)]
                    for (a, b) in arcs where d[a] != Int.max && d[a] + 1 < d[b] { d[b] = d[a] + 1 }
                }
            }
            let sum = (0 ..< n).filter { !inGroup.contains($0) && d[$0] != Int.max }.reduce(0) { $0 + d[$1] }
            let closeness = sum == 0 ? 0 : Double(n - group.count) / Double(sum)
            let outside = Double(n - group.count)
            let context = "\(ends), directed \(directed), group \(group)"
            if directed {
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                #expect(abs(graph.groupClosenessCentrality(of: group) - closeness) <= 1e-12, "\(context)")
                #expect(abs(graph.groupClosenessCentrality(of: group, weight: { _ in 1.0 }) - closeness) <= 1e-12, "\(context)")
                let into = Set(ends.filter { inGroup.contains($0.1) && !inGroup.contains($0.0) }.map(\.0))
                let from = Set(ends.filter { inGroup.contains($0.0) && !inGroup.contains($0.1) }.map(\.1))
                #expect(graph.groupInDegreeCentrality(of: group) == Double(into.count) / outside, "\(context)")
                #expect(graph.groupOutDegreeCentrality(of: group) == Double(from.count) / outside, "\(context)")
            } else {
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                #expect(abs(graph.groupClosenessCentrality(of: group) - closeness) <= 1e-12, "\(context)")
                #expect(abs(graph.groupClosenessCentrality(of: group, weight: { _ in Float(1) }) - closeness) <= 1e-12, "\(context)")
                var adjacent = Set<Int>()
                for (u, v) in ends {
                    if inGroup.contains(u), !inGroup.contains(v) { adjacent.insert(v) }
                    if inGroup.contains(v), !inGroup.contains(u) { adjacent.insert(u) }
                }
                #expect(graph.groupDegreeCentrality(of: group) == Double(adjacent.count) / outside, "\(context)")
            }
        }
    }

    @Test("Current-flow betweenness and closeness equal the definition by potentials (Gaussian elimination), on connected multigraphs with loops and weights")
    func currentFlow() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 1 ... 3)).array(of: 0 ... 12)
        await propertyCheck(count: 120, input: triples, Gen.int(in: 2 ... 7)) { raw, n in
            // A path through every vertex keeps the graph connected; the generated edges are extra.
            var edges = (0 ..< n - 1).map { ($0, $0 + 1, 1.0) }
            edges += raw.map { ($0.0 % n, $0.1 % n, Double($0.2)) }
            // Potentials for a unit from s to t: solve the Laplacian with vertex 0 grounded.
            func potentials(_ s: Int, _ t: Int) -> [Double] {
                var l = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
                for (u, v, c) in edges where u != v {
                    l[u][u] += c
                    l[v][v] += c
                    l[u][v] -= c
                    l[v][u] -= c
                }
                var b = [Double](repeating: 0, count: n)
                b[s] += 1
                b[t] -= 1
                // Ground 0: drop its row and column.
                var a = (1 ..< n).map { i in (1 ..< n).map { l[i][$0] } + [b[i]] }
                let k = n - 1
                for col in 0 ..< k {
                    let pivot = (col ..< k).max { abs(a[$0][col]) < abs(a[$1][col]) }!
                    a.swapAt(col, pivot)
                    for row in 0 ..< k where row != col {
                        let f = a[row][col] / a[col][col]
                        for j in col ... k { a[row][j] -= f * a[col][j] }
                    }
                }
                return [0] + (0 ..< k).map { a[$0][k] / a[$0][$0] }
            }
            var betweenness = [Double](repeating: 0, count: n)
            var resistance = [Double](repeating: 0, count: n)
            for s in 0 ..< n {
                for t in s + 1 ..< n {
                    let p = potentials(s, t)
                    for v in 0 ..< n where v != s && v != t {
                        var through = 0.0
                        for (a, b, c) in edges where a != b && (a == v || b == v) { through += c * abs(p[a] - p[b]) }
                        betweenness[v] += through / 2
                    }
                    resistance[s] += p[s] - p[t]
                    resistance[t] += p[s] - p[t]
                }
            }
            let normalized = n > 2 ? betweenness.map { $0 * 2 / Double((n - 1) * (n - 2)) } : betweenness.map { _ in 0 }
            let closeness = resistance.map { 1 / $0 }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let w = edges.map(\.2)
            let context = "\(edges)"
            func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) <= 1e-9 * max(1, abs(b)) }
            #expect(zip(graph.currentFlowBetweennessCentrality(weight: { w[$0] }).scores, normalized).allSatisfy(near), "\(context)")
            #expect(zip(graph.currentFlowClosenessCentrality(weight: { w[$0] }).scores, closeness).allSatisfy(near), "\(context)")
            if n > 2 {
                #expect(zip(graph.currentFlowBetweennessCentrality(weight: { w[$0] }, normalized: false).scores, betweenness).allSatisfy(near), "\(context)")
            }
        }
    }

    @Test("Subgraph centrality and communicability equal Σ_k A^k / k! on the 0/1 adjacency matrix")
    func exponential() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        await propertyCheck(count: 100, input: pairs, Gen.int(in: 1 ... 8)) { raw, n in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (u, v) in ends {
                a[u][v] = 1
                a[v][u] = 1
            }
            var sum = (0 ..< n).map { i in (0 ..< n).map { $0 == i ? 1.0 : 0 } }
            var term = sum
            for k in 1 ... 60 {
                term = (0 ..< n).map { i in (0 ..< n).map { j in (0 ..< n).reduce(0.0) { $0 + term[i][$1] * a[$1][j] } / Double(k) } }
                for i in 0 ..< n { for j in 0 ..< n { sum[i][j] += term[i][j] } }
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let c = graph.communicability()
            let s = graph.subgraphCentrality()
            for i in 0 ..< n {
                #expect(abs(s.score(of: i) - sum[i][i]) <= 1e-10 * sum[i][i], "\(ends)")
                for j in 0 ..< n { #expect(abs(c.communicability(of: i, and: j) - sum[i][j]) <= 1e-10 * max(1, sum[i][j]), "\(ends)") }
            }
        }
    }
}
