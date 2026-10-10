// Flows against invariants that need no oracle, on multigraphs of at most 8 vertices with
// self-loops, parallel and antiparallel edges, with vertex labels in a shuffled order. Maximum
// flows (push–relabel, Edmonds–Karp, Dinic) on `DirectedPseudograph` and `Pseudograph`: every flow
// within capacity (on an undirected edge, one direction at most) and conserved, its value the net
// flow out of the source, the three values and `maximumFlowValue` equal, the cut of every flow the
// same as `minimumCut(from:to:)` with the max-flow value, its sink side exactly the vertices that
// still reach the sink in that flow's residual network, its edges exactly those leaving the source
// side and removing them separating the terminals; dyadic `Double` capacities give the integer
// results scaled. Global cuts: on `DirectedPseudograph` the least λ(vᵢ, vᵢ₊₁) (mod n), which is the
// least over every ordered pair; Nagamochi–Ibaraki's value at most every pair's λ and equal to the
// least λ(v₀, v); the Gomory–Hu tree's path minimum equal to `maximumFlowValue` on every pair, and
// its cuts splitting the pair at that value. A graph without vertex or edge indices gives the same
// values. Minimum-cost flow: when it returns a flow, the flow is within capacity, meets every
// supply, costs what it says, and the potentials certify optimality (reduced cost ≥ 0 below
// capacity, ≤ 0 with flow, saturated negative self-loops); when it returns nil, the supplies are
// unbalanced or the super-source maximum flow falls short of them, and conversely; capacities of
// Int.max (at cost zero where Σ capacity × |cost| would pass Int) included.
// `minimumCostMaximumFlow` ships the maximum flow value under the same certificate. Connectivity:
// λ(s, t) and λ(G) by unit flows, κ(s, t) and κ(G) by deleting every vertex set, and the vertex
// cuts separating at that size. Small types: `Int8` and `UInt8` capacities near the maximum, and
// `Int8` costs, run only where the documented preconditions hold (computed here in `Int`), and
// then give the `Int` results: no trap from an overflow the documentation does not name.

import FuzzSupport
import Flows
import GraphProtocols
import Multigraphs

/// An undirected multigraph with no vertex or edge indices.
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

/// A random network by vertex index: labels (index i is `labels[i]`), ends and capacities.
struct Network {
    var n: Int
    var labels: [Int]
    var ends: [(Int, Int)]
    var capacities: [Int]
    var m: Int { ends.count }

    init(_ input: inout FuzzInput, vertices: ClosedRange<Int>, edges: Int, palette: [Int]) {
        n = input.int(in: vertices)
        labels = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { labels.swapAt(i, input.int(below: i + 1)) }
        let count = n == 0 ? 0 : input.int(below: edges + 1)
        var ends: [(Int, Int)] = []
        for _ in 0 ..< count { ends.append((input.int(below: max(n, 1)), input.int(below: max(n, 1)))) }
        self.ends = ends
        var capacities: [Int] = []
        for _ in 0 ..< count { capacities.append(palette[input.int(below: palette.count)]) }
        self.capacities = capacities
    }

    func directed() -> DirectedPseudograph<Int> {
        DirectedPseudograph(vertices: labels, edges: ends.map { DirectedEdge(from: labels[$0.0], to: labels[$0.1]) })
    }

    func undirected() -> Pseudograph<Int> {
        Pseudograph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) })
    }

    func plain() -> PlainGraph {
        PlainGraph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) })
    }

    /// Whether `t` is reachable from `s` over the edges `usable` (by position), directed or not,
    /// avoiding the vertices in `removed`.
    func reaches(_ s: Int, _ t: Int, directed: Bool, removed: Set<Int> = [], usable: (Int) -> Bool = { _ in true }) -> Bool {
        var seen = [Bool](repeating: false, count: n)
        seen[s] = true
        var stack = [s]
        while let x = stack.popLast() {
            if x == t { return true }
            for k in 0 ..< m where usable(k) {
                let (u, v) = ends[k]
                var next = -1
                if u == x { next = v } else if !directed && v == x { next = u }
                if next >= 0 && !seen[next] && !removed.contains(next) {
                    seen[next] = true
                    stack.append(next)
                }
            }
        }
        return false
    }
}

@main
enum FuzzFlows {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        switch input.int(below: 8) {
        case 0, 1: directedFlows(&input)
        case 2, 3: undirectedFlows(&input)
        case 4: costFlows(&input)
        case 5: connectivity(&input)
        default: smallTypes(&input)
        }
    }

    static func palette(_ input: inout FuzzInput) -> [Int] {
        [[0, 1], [0, 1, 2, 3], [0, 1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 4, 8, 16, 32]][input.int(below: 4)]
    }

    static func terminals(_ input: inout FuzzInput, _ n: Int) -> (Int, Int) {
        let s = input.int(below: n)
        return (s, (s + 1 + input.int(below: n - 1)) % n)
    }

    // MARK: Directed maximum flows and cuts

    static func directedFlows(_ input: inout FuzzInput) {
        let p = palette(&input)
        let net = Network(&input, vertices: 2 ... 8, edges: 20, palette: p)
        let graph = net.directed()
        let (s, t) = terminals(&input, net.n)
        let n = net.n, labels = net.labels, ends = net.ends, caps = net.capacities
        let context = "\(n) vertices \(labels), edges \(ends), capacities \(caps), \(s) → \(t)"
        let capacity: (Int) -> Int = { caps[$0] }

        let value = graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: capacity)
        let cut = graph.minimumCut(from: labels[s], to: labels[t], capacity: capacity)
        checkDirectedCut(net, cut, s, t, value, context)
        let flows = [("push–relabel", graph.maximumFlow(from: labels[s], to: labels[t], capacity: capacity)),
                     ("Edmonds–Karp", graph.edmondsKarpMaximumFlow(from: labels[s], to: labels[t], capacity: capacity)),
                     ("Dinic", graph.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: capacity))]
        for (name, flow) in flows {
            check(flow.value == value, "\(name) value \(flow.value), maximumFlowValue \(value): \(context)")
            check(flow.source == labels[s] && flow.sink == labels[t], "\(name) terminals: \(context)")
            check(flow.minimumCut == cut, "\(name) cut \(flow.minimumCut), minimumCut \(cut): \(context)")
            let f = (0 ..< net.m).map { flow.flow(ofEdgeAt: $0) }
            var net0 = [Int](repeating: 0, count: n)
            for k in 0 ..< net.m {
                let (u, v) = ends[k]
                check(f[k] >= 0 && f[k] <= caps[k], "\(name) edge \(k) carries \(f[k]) of \(caps[k]): \(context)")
                check(u != v || f[k] == 0, "\(name) self-loop \(k) carries \(f[k]): \(context)")
                net0[u] += f[k]
                net0[v] -= f[k]
            }
            for v in 0 ..< n {
                let expected = v == s ? value : v == t ? -value : 0
                check(net0[v] == expected, "\(name) net flow \(net0[v]) at \(v), expected \(expected): \(context)")
            }
            // The residual network's vertices that reach t: the canonical sink side.
            var reach = [Bool](repeating: false, count: n)
            reach[t] = true
            var stack = [t]
            while let x = stack.popLast() {
                for k in 0 ..< net.m {
                    let (u, v) = ends[k]
                    if u == v { continue }
                    // u → v has residual c − f; v → u has residual f.
                    if v == x && !reach[u] && f[k] < caps[k] { reach[u] = true; stack.append(u) }
                    if u == x && !reach[v] && f[k] > 0 { reach[v] = true; stack.append(v) }
                }
            }
            let sink = Set(cut.sinkSide)
            check((0 ..< n).allSatisfy { reach[$0] == sink.contains(labels[$0]) }, "\(name) residual sink side \(reach) against the cut \(cut): \(context)")
        }

        // Dyadic doubles: the same values scaled.
        let quarter = graph.maximumFlowValue(from: labels[s], to: labels[t]) { Double(caps[$0]) / 4 }
        check(quarter == Double(value) / 4, "Double value \(quarter), expected \(Double(value) / 4): \(context)")
        let dinicQuarter = graph.dinicMaximumFlow(from: labels[s], to: labels[t]) { Double(caps[$0]) / 4 }
        check(dinicQuarter.value == Double(value) / 4, "Double Dinic value \(dinicQuarter.value): \(context)")
        check(Array(dinicQuarter.minimumCut.sinkSide) == Array(cut.sinkSide), "Double Dinic cut \(dinicQuarter.minimumCut): \(context)")

        // The directed global cut: the least over the cyclic pairs, which is the least over all.
        var cyclic = Int.max, every = Int.max
        for a in 0 ..< n {
            for b in 0 ..< n where a != b {
                let λ = graph.maximumFlowValue(from: labels[a], to: labels[b], capacity: capacity)
                every = min(every, λ)
                if b == (a + 1) % n { cyclic = min(cyclic, λ) }
            }
        }
        guard let global = graph.minimumCut(capacity: capacity) else {
            check(false, "no directed global cut: \(context)")
            return
        }
        check(global.value == cyclic && cyclic == every, "directed global cut \(global.value), cyclic pairs \(cyclic), all pairs \(every): \(context)")
        check(!global.sourceSide.isEmpty && !global.sinkSide.isEmpty, "directed global cut sides \(global): \(context)")
        let inSink = Set(global.sinkSide)
        var crossing: [Int] = [], total = 0
        for k in 0 ..< net.m {
            let (u, v) = ends[k]
            if u != v && !inSink.contains(labels[u]) && inSink.contains(labels[v]) {
                crossing.append(k)
                total += caps[k]
            }
        }
        check(global.edges == crossing && global.value == total, "directed global cut edges \(global): \(context)")
    }

    static func checkDirectedCut(_ net: Network, _ cut: Cut<DirectedPseudograph<Int>, Int>, _ s: Int, _ t: Int, _ value: Int, _ context: String) {
        let labels = net.labels
        let sink = Set(cut.sinkSide)
        check(Array(cut.sourceSide) == labels.filter { !sink.contains($0) } && Array(cut.sinkSide) == labels.filter { sink.contains($0) },
              "cut sides out of order \(cut): \(context)")
        check(!sink.contains(labels[s]) && sink.contains(labels[t]), "cut does not separate: \(cut): \(context)")
        var crossing: [Int] = [], total = 0
        for k in 0 ..< net.m {
            let (u, v) = net.ends[k]
            if u != v && !sink.contains(labels[u]) && sink.contains(labels[v]) {
                crossing.append(k)
                total += net.capacities[k]
            }
        }
        check(cut.edges == crossing, "cut edges \(cut.edges), expected \(crossing): \(context)")
        check(cut.value == total && total == value, "cut value \(cut.value), edges sum \(total), max flow \(value): \(context)")
        let removed = Set(cut.edges)
        check(!net.reaches(s, t, directed: true, usable: { !removed.contains($0) }), "the cut edges do not separate: \(context)")
    }

    // MARK: Undirected maximum flows, Nagamochi–Ibaraki and Gomory–Hu

    static func undirectedFlows(_ input: inout FuzzInput) {
        let p = palette(&input)
        let net = Network(&input, vertices: 2 ... 8, edges: 18, palette: p)
        let graph = net.undirected()
        let (s, t) = terminals(&input, net.n)
        let n = net.n, labels = net.labels, ends = net.ends, caps = net.capacities
        let context = "undirected \(n) vertices \(labels), edges \(ends), capacities \(caps), \(s) – \(t)"
        let capacity: (Int) -> Int = { caps[$0] }

        let value = graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: capacity)
        let cut = graph.minimumCut(from: labels[s], to: labels[t], capacity: capacity)
        checkUndirectedCut(net, cut, s, t, value, context)
        let flows = [("push–relabel", graph.maximumFlow(from: labels[s], to: labels[t], capacity: capacity)),
                     ("Edmonds–Karp", graph.edmondsKarpMaximumFlow(from: labels[s], to: labels[t], capacity: capacity)),
                     ("Dinic", graph.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: capacity))]
        typealias Arc = DirectedView<Pseudograph<Int>>.Edges.Index
        for (name, flow) in flows {
            check(flow.value == value, "\(name) value \(flow.value), maximumFlowValue \(value): \(context)")
            check(flow.minimumCut == cut, "\(name) cut \(flow.minimumCut), minimumCut \(cut): \(context)")
            var along: [Int] = [], against: [Int] = []
            var balance = [Int](repeating: 0, count: n)
            for k in 0 ..< net.m {
                let a = flow.flow(ofEdgeAt: Arc(position: k, reversed: false)), b = flow.flow(ofEdgeAt: Arc(position: k, reversed: true))
                let (u, v) = ends[k]
                check(a >= 0 && b >= 0 && a <= caps[k] && b <= caps[k] && (a == 0 || b == 0),
                      "\(name) edge \(k) carries \(a) and \(b) of \(caps[k]): \(context)")
                check(u != v || a + b == 0, "\(name) self-loop \(k) carries flow: \(context)")
                along.append(a)
                against.append(b)
                balance[u] += a - b
                balance[v] -= a - b
            }
            for v in 0 ..< n {
                let expected = v == s ? value : v == t ? -value : 0
                check(balance[v] == expected, "\(name) net flow \(balance[v]) at \(v), expected \(expected): \(context)")
            }
            var reach = [Bool](repeating: false, count: n)
            reach[t] = true
            var stack = [t]
            while let x = stack.popLast() {
                for k in 0 ..< net.m {
                    let (u, v) = ends[k]
                    if u == v { continue }
                    let forward = caps[k] - along[k] + against[k], backward = caps[k] - against[k] + along[k]
                    if v == x && !reach[u] && forward > 0 { reach[u] = true; stack.append(u) }
                    if u == x && !reach[v] && backward > 0 { reach[v] = true; stack.append(v) }
                }
            }
            let sink = Set(cut.sinkSide)
            check((0 ..< n).allSatisfy { reach[$0] == sink.contains(labels[$0]) }, "\(name) residual sink side \(reach) against the cut \(cut): \(context)")
        }

        // Every pair's λ, for the global cut and the Gomory–Hu tree.
        var λ = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for a in 0 ..< n {
            for b in (a + 1) ..< n {
                λ[a][b] = graph.maximumFlowValue(from: labels[a], to: labels[b], capacity: capacity)
                λ[b][a] = λ[a][b]
            }
        }
        check(λ[s][t] == value, "λ(\(s), \(t)) \(λ[s][t]) against \(value): \(context)")
        guard let global = graph.minimumCut(capacity: capacity) else {
            check(false, "no Nagamochi–Ibaraki cut: \(context)")
            return
        }
        let fromFirst = (1 ..< n).map { λ[0][$0] }.min()!
        check(global.value == fromFirst, "Nagamochi–Ibaraki \(global.value), least λ(v₀, v) \(fromFirst): \(context)")
        for a in 0 ..< n {
            for b in (a + 1) ..< n { check(global.value <= λ[a][b], "Nagamochi–Ibaraki \(global.value) above λ(\(a), \(b)) \(λ[a][b]): \(context)") }
        }
        check(global.sourceSide.contains(labels[0]) && !global.sinkSide.isEmpty, "Nagamochi–Ibaraki sides \(global): \(context)")
        let inSink = Set(global.sinkSide)
        var total = 0, crossing = 0
        for k in 0 ..< net.m where inSink.contains(labels[ends[k].0]) != inSink.contains(labels[ends[k].1]) {
            total += caps[k]
            crossing += 1
        }
        check(global.value == total && global.edges.count == crossing, "Nagamochi–Ibaraki edges \(global): \(context)")

        guard let tree = graph.gomoryHuTree(capacity: capacity) else {
            check(false, "no Gomory–Hu tree: \(context)")
            return
        }
        check(tree.tree.edgeCount == n - 1, "Gomory–Hu tree with \(tree.tree.edgeCount) edges: \(context)")
        for a in 0 ..< n {
            for b in (a + 1) ..< n {
                let got = tree.minimumCutValue(between: labels[a], and: labels[b])
                check(got == λ[a][b], "Gomory–Hu λ(\(a), \(b)) \(got), max flow \(λ[a][b]): \(context)")
                let split = tree.minimumCut(between: labels[a], and: labels[b])
                let side = Set(split.sinkSide)
                check(!side.contains(labels[a]) && side.contains(labels[b]) && split.value == λ[a][b],
                      "Gomory–Hu cut \(split) between \(a) and \(b), λ \(λ[a][b]): \(context)")
                var sum = 0
                for k in 0 ..< net.m where side.contains(labels[ends[k].0]) != side.contains(labels[ends[k].1]) { sum += caps[k] }
                check(sum == split.value, "Gomory–Hu cut value \(split.value), crossing \(sum): \(context)")
            }
        }

        // Without vertex or edge indices: the same values.
        let plain = net.plain()
        check(plain.maximumFlowValue(from: labels[s], to: labels[t], capacity: capacity) == value, "plain value: \(context)")
        check(plain.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: capacity).value == value, "plain Dinic: \(context)")
        check(plain.minimumCut(capacity: capacity)?.value == global.value, "plain Nagamochi–Ibaraki: \(context)")
        if let plainTree = plain.gomoryHuTree(capacity: capacity) {
            for a in 0 ..< n {
                for b in (a + 1) ..< n {
                    check(plainTree.minimumCutValue(between: labels[a], and: labels[b]) == λ[a][b], "plain Gomory–Hu: \(context)")
                }
            }
        } else {
            check(false, "plain Gomory–Hu tree missing: \(context)")
        }
    }

    static func checkUndirectedCut(_ net: Network, _ cut: Cut<DirectedView<Pseudograph<Int>>, Int>, _ s: Int, _ t: Int, _ value: Int, _ context: String) {
        let labels = net.labels
        let sink = Set(cut.sinkSide)
        check(Array(cut.sourceSide) == labels.filter { !sink.contains($0) } && Array(cut.sinkSide) == labels.filter { sink.contains($0) },
              "cut sides out of order \(cut): \(context)")
        check(!sink.contains(labels[s]) && sink.contains(labels[t]), "cut does not separate: \(cut): \(context)")
        var crossing: [DirectedView<Pseudograph<Int>>.Edges.Index] = [], total = 0
        for k in 0 ..< net.m {
            let (u, v) = net.ends[k]
            let su = sink.contains(labels[u]), sv = sink.contains(labels[v])
            if su != sv {
                crossing.append(.init(position: k, reversed: su))
                total += net.capacities[k]
            }
        }
        check(cut.edges == crossing, "cut edges \(cut.edges), expected \(crossing): \(context)")
        check(cut.value == total && total == value, "cut value \(cut.value), edges sum \(total), max flow \(value): \(context)")
        let removed = Set(cut.edges.map(\.position))
        check(!net.reaches(s, t, directed: false, usable: { !removed.contains($0) }), "the cut edges do not separate: \(context)")
    }

    // MARK: Minimum-cost flow

    static func costFlows(_ input: inout FuzzInput) {
        var net = Network(&input, vertices: 1 ... 7, edges: 16, palette: [0, 1, 2, 3, 4, 5])
        var costs = (0 ..< net.m).map { _ in input.int(below: 11) - 4 }
        // One input in four puts Int.max on some capacities; their costs go to zero when
        // Σ capacity × |cost| would pass Int (a documented precondition).
        if input.int(below: 4) == 0 {
            for k in 0 ..< net.m where input.int(below: 3) == 0 { net.capacities[k] = Int.max }
            var bound = 0, overflow = false
            for k in 0 ..< net.m {
                let (product, o1) = net.capacities[k].multipliedReportingOverflow(by: abs(costs[k]))
                let (sum, o2) = bound.addingReportingOverflow(product)
                overflow = overflow || o1 || o2
                bound = sum
            }
            if overflow { for k in 0 ..< net.m where net.capacities[k] == Int.max { costs[k] = 0 } }
        }
        let n = net.n, labels = net.labels, ends = net.ends, caps = net.capacities
        var supply = [Int](repeating: 0, count: n)
        for _ in 0 ..< input.int(below: 4) {
            let u = input.int(below: n), v = input.int(below: n), amount = input.int(below: 5)
            supply[u] += amount
            supply[v] -= amount
        }
        if input.int(below: 8) == 0 { supply[input.int(below: n)] += input.int(below: 3) - 1 }
        let graph = net.directed()
        var index: [Int: Int] = [:]
        for (i, label) in labels.enumerated() { index[label] = i }
        let context = "\(n) vertices \(labels), edges \(ends), capacities \(caps), costs \(costs), supplies \(supply)"

        // Feasibility by a maximum flow from a super source to a super sink.
        let positive = supply.filter { $0 > 0 }.reduce(0, +)
        let balanced = supply.reduce(0, +) == 0
        var feasible = false
        if balanced {
            var superEdges = ends.map { DirectedEdge(from: $0.0, to: $0.1) }
            var superCaps = caps
            for v in 0 ..< n where supply[v] != 0 {
                superEdges.append(supply[v] > 0 ? DirectedEdge(from: n, to: v) : DirectedEdge(from: v, to: n + 1))
                superCaps.append(abs(supply[v]))
            }
            let superGraph = DirectedPseudograph(vertices: 0 ..< n + 2, edges: superEdges)
            feasible = superGraph.maximumFlowValue(from: n, to: n + 1) { superCaps[$0] } == positive
        }

        let result = graph.minimumCostFlow(supply: { supply[index[$0]!] }, capacity: { caps[$0] }, cost: { costs[$0] })
        guard let result else {
            check(!feasible, "minimumCostFlow nil, but the supplies can be met: \(context)")
            return
        }
        check(feasible, "minimumCostFlow returned a flow for supplies that cannot be met: \(context)")
        check(result.value == positive, "value \(result.value), positive supplies \(positive): \(context)")
        checkCertificate(net, costs, supply, result, context)

        // Int8 capacities and costs give the same result when the preconditions hold.
        if fitsSmallCosts(net, costs, supply) {
            let small = graph.minimumCostFlow(supply: { Int8(supply[index[$0]!]) }, capacity: { Int8(caps[$0]) }, cost: { Int8(costs[$0]) })
            check(small.map { Int($0.cost) } == result.cost, "Int8 minimum cost \(String(describing: small?.cost)), Int \(result.cost): \(context)")
            if let small {
                check((0 ..< net.m).allSatisfy { Int(small.flow(ofEdgeAt: $0)) == result.flow(ofEdgeAt: $0) }, "Int8 flows differ: \(context)")
            }
        }

        // The least-cost maximum flow between two terminals.
        if n >= 2 {
            let (s, t) = terminals(&input, n)
            // The capacities out of the source must sum within Int.
            var out = 0, overflow = false
            for k in 0 ..< net.m where ends[k].0 == s && ends[k].1 != s {
                let (sum, o) = out.addingReportingOverflow(caps[k])
                overflow = overflow || o
                out = sum
            }
            guard !overflow else { return }
            let value = graph.maximumFlowValue(from: labels[s], to: labels[t]) { caps[$0] }
            let flow = graph.minimumCostMaximumFlow(from: labels[s], to: labels[t], capacity: { caps[$0] }, cost: { costs[$0] })
            check(flow.value == value, "minimumCostMaximumFlow value \(flow.value), max flow \(value): \(context), \(s) → \(t)")
            var shipped = [Int](repeating: 0, count: n)
            shipped[s] = value
            shipped[t] = -value
            checkCertificate(net, costs, shipped, flow, context + ", \(s) → \(t)")
        }
    }

    static func checkCertificate(_ net: Network, _ costs: [Int], _ supply: [Int], _ result: MinimumCostFlow<DirectedPseudograph<Int>, Int, Int>, _ context: String) {
        let caps = net.capacities
        var balance = [Int](repeating: 0, count: net.n)
        var total = 0
        for k in 0 ..< net.m {
            let f = result.flow(ofEdgeAt: k), (u, v) = net.ends[k]
            check(f >= 0 && f <= caps[k], "edge \(k) carries \(f) of \(caps[k]): \(context)")
            total += f * costs[k]
            if u == v {
                check(f == (costs[k] < 0 ? caps[k] : 0), "self-loop \(k) carries \(f): \(context)")
                continue
            }
            balance[u] &+= f
            balance[v] &-= f
            let reduced = costs[k] + result.potential(of: net.labels[u]) - result.potential(of: net.labels[v])
            check(f == caps[k] || reduced >= 0, "edge \(k) below capacity with reduced cost \(reduced): \(context)")
            check(f == 0 || reduced <= 0, "edge \(k) with flow and reduced cost \(reduced): \(context)")
        }
        check(balance == supply, "net flows \(balance), supplies \(supply): \(context)")
        check(result.cost == total, "cost \(result.cost), Σ flow × cost \(total): \(context)")
    }

    /// The preconditions of `minimumCostFlow` with `Int8` capacities, supplies and costs.
    static func fitsSmallCosts(_ net: Network, _ costs: [Int], _ supply: [Int]) -> Bool {
        let range = Int(Int8.min) ... Int(Int8.max)
        var bound = 0, greatest = 0
        for k in 0 ..< net.m {
            guard net.capacities[k] <= Int(Int8.max) else { return false }
            bound += net.capacities[k] * abs(costs[k])
            if net.ends[k].0 != net.ends[k].1 { greatest = max(greatest, abs(costs[k])) }
        }
        return supply.allSatisfy(range.contains) && net.capacities.allSatisfy(range.contains) && range.contains(bound)
            && range.contains((net.n + 1) * greatest) && range.contains(supply.filter { $0 > 0 }.reduce(0, +))
    }

    // MARK: Connectivity

    static func connectivity(_ input: inout FuzzInput) {
        let net = Network(&input, vertices: 0 ... 7, edges: 22, palette: [1])
        let n = net.n, labels = net.labels, ends = net.ends
        let directed = input.int(below: 2) == 0
        let context = "\(directed ? "directed" : "undirected") \(n) vertices \(labels), edges \(ends)"
        // κ by deleting vertex sets: the least set whose removal leaves fewer than two vertices or
        // a graph that is not (strongly) connected.
        func connected(_ removed: Set<Int>) -> Bool {
            let rest = (0 ..< n).filter { !removed.contains($0) }
            guard rest.count >= 2 else { return false }
            return rest.allSatisfy { a in rest.allSatisfy { b in a == b || net.reaches(a, b, directed: directed, removed: removed) } }
        }
        var kappa = 0
        if n >= 2 {
            kappa = n - 1
            for mask in 0 ..< (1 << n) where mask.nonzeroBitCount < kappa {
                let removed = Set((0 ..< n).filter { mask & (1 << $0) != 0 })
                if !connected(removed) { kappa = mask.nonzeroBitCount }
            }
        }
        func adjacent(_ s: Int, _ t: Int) -> Bool {
            ends.contains { ($0.0 == s && $0.1 == t) || (!directed && $0.0 == t && $0.1 == s) }
        }
        // κ(s, t): the least set separating them once the edges s → t are gone, plus one for those edges.
        func localKappa(_ s: Int, _ t: Int) -> Int {
            let usable: (Int) -> Bool = { k in !((ends[k].0 == s && ends[k].1 == t) || (!directed && ends[k].0 == t && ends[k].1 == s)) }
            var best = n
            let others = (0 ..< n).filter { $0 != s && $0 != t }
            for mask in 0 ..< (1 << others.count) where mask.nonzeroBitCount < best {
                let removed = Set(others.indices.filter { mask & (1 << $0) != 0 }.map { others[$0] })
                if !net.reaches(s, t, directed: directed, removed: removed, usable: usable) { best = mask.nonzeroBitCount }
            }
            return best + (adjacent(s, t) ? 1 : 0)
        }
        let unit: (Int) -> Int = { _ in 1 }
        if directed {
            let graph = net.directed()
            var lambda = n >= 2 ? Int.max : 0
            for a in 0 ..< n {
                for b in 0 ..< n where a != b {
                    let local = graph.edgeConnectivity(from: labels[a], to: labels[b])
                    check(local == graph.maximumFlowValue(from: labels[a], to: labels[b], capacity: unit), "λ(\(a), \(b)) \(local): \(context)")
                    lambda = min(lambda, local)
                    let k = graph.vertexConnectivity(from: labels[a], to: labels[b])
                    check(k == localKappa(a, b), "κ(\(a), \(b)) \(k), by deletion \(localKappa(a, b)): \(context)")
                    let cut = graph.minimumVertexCut(from: labels[a], to: labels[b])
                    check((cut == nil) == adjacent(a, b), "vertex cut \(String(describing: cut)) for \(a) → \(b): \(context)")
                    if let cut {
                        let removed = Set(cut.map { labels.firstIndex(of: $0)! })
                        check(cut.count == k && !removed.contains(a) && !removed.contains(b) && !net.reaches(a, b, directed: true, removed: removed),
                              "vertex cut \(cut) for \(a) → \(b), κ \(k): \(context)")
                    }
                }
            }
            check(graph.edgeConnectivity() == lambda, "λ(G) \(graph.edgeConnectivity()), least pair \(lambda): \(context)")
            check(graph.vertexConnectivity() == kappa, "κ(G) \(graph.vertexConnectivity()), by deletion \(kappa): \(context)")
            let cut = graph.minimumVertexCut()
            checkGlobalVertexCut(cut, kappa, n, labels, connected, context)
        } else {
            let graph = net.undirected()
            var lambda = n >= 2 ? Int.max : 0
            for a in 0 ..< n {
                for b in 0 ..< n where a != b {
                    let local = graph.edgeConnectivity(from: labels[a], to: labels[b])
                    check(local == graph.maximumFlowValue(from: labels[a], to: labels[b], capacity: unit), "λ(\(a), \(b)) \(local): \(context)")
                    lambda = min(lambda, local)
                    let k = graph.vertexConnectivity(from: labels[a], to: labels[b])
                    check(k == localKappa(a, b), "κ(\(a), \(b)) \(k), by deletion \(localKappa(a, b)): \(context)")
                    let cut = graph.minimumVertexCut(from: labels[a], to: labels[b])
                    check((cut == nil) == adjacent(a, b), "vertex cut \(String(describing: cut)) for \(a) – \(b): \(context)")
                    if let cut {
                        let removed = Set(cut.map { labels.firstIndex(of: $0)! })
                        check(cut.count == k && !removed.contains(a) && !removed.contains(b) && !net.reaches(a, b, directed: false, removed: removed),
                              "vertex cut \(cut) for \(a) – \(b), κ \(k): \(context)")
                    }
                }
            }
            check(graph.edgeConnectivity() == lambda, "λ(G) \(graph.edgeConnectivity()), least pair \(lambda): \(context)")
            check(graph.vertexConnectivity() == kappa, "κ(G) \(graph.vertexConnectivity()), by deletion \(kappa): \(context)")
            checkGlobalVertexCut(graph.minimumVertexCut(), kappa, n, labels, connected, context)
        }
    }

    static func checkGlobalVertexCut(_ cut: [Int], _ kappa: Int, _ n: Int, _ labels: [Int], _ connected: (Set<Int>) -> Bool, _ context: String) {
        let removed = Set(cut.map { labels.firstIndex(of: $0)! })
        check(removed.count == cut.count, "repeated vertices in the cut \(cut): \(context)")
        check(Array(cut) == labels.filter { cut.contains($0) }, "vertex cut \(cut) not in vertex order: \(context)")
        if kappa == 0 {
            check(cut.isEmpty, "vertex cut \(cut) with κ 0: \(context)")
        } else {
            check(cut.count == kappa && !connected(removed), "vertex cut \(cut), κ \(kappa): \(context)")
        }
    }

    // MARK: Small capacity types near their maximum

    static func smallTypes(_ input: inout FuzzInput) {
        let signed = input.int(below: 2) == 0
        let mid = input.int(below: 2) == 0
        let palette = signed ? (mid ? [0, 1, 20, 31, 40, 63] : [0, 1, 2, 63, 64, 100, 126, 127])
            : (mid ? [0, 1, 40, 63, 64, 100] : [0, 1, 2, 127, 128, 200, 254, 255])
        let maximum = signed ? Int(Int8.max) : Int(UInt8.max)
        let net = Network(&input, vertices: 2 ... 7, edges: 14, palette: palette)
        let (s, t) = terminals(&input, net.n)
        let n = net.n, labels = net.labels, ends = net.ends, caps = net.capacities
        let directed = input.int(below: 2) == 0
        let context = "\(signed ? "Int8" : "UInt8") \(directed ? "directed" : "undirected") \(n) vertices \(labels), edges \(ends), capacities \(caps), \(s) → \(t)"
        // The capacities at each vertex: out of it when directed, at it when undirected.
        var sums = [Int](repeating: 0, count: n)
        for k in 0 ..< net.m where ends[k].0 != ends[k].1 {
            sums[ends[k].0] += caps[k]
            if !directed { sums[ends[k].1] += caps[k] }
        }
        let sourceFits = sums[s] <= maximum
        let capacity: (Int) -> Int = { caps[$0] }
        if directed {
            let graph = net.directed()
            let value = graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: capacity)
            if sourceFits {
                if signed {
                    let small: (Int) -> Int8 = { Int8(caps[$0]) }
                    check(Int(graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: small)) == value, "value: \(context)")
                    check(Int(graph.maximumFlow(from: labels[s], to: labels[t], capacity: small).value) == value, "push–relabel: \(context)")
                    check(Int(graph.edmondsKarpMaximumFlow(from: labels[s], to: labels[t], capacity: small).value) == value, "Edmonds–Karp: \(context)")
                    check(Int(graph.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: small).value) == value, "Dinic: \(context)")
                    check(Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: small).sinkSide) == Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: capacity).sinkSide), "cut: \(context)")
                } else {
                    let small: (Int) -> UInt8 = { UInt8(caps[$0]) }
                    check(Int(graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: small)) == value, "value: \(context)")
                    check(Int(graph.maximumFlow(from: labels[s], to: labels[t], capacity: small).value) == value, "push–relabel: \(context)")
                    check(Int(graph.edmondsKarpMaximumFlow(from: labels[s], to: labels[t], capacity: small).value) == value, "Edmonds–Karp: \(context)")
                    check(Int(graph.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: small).value) == value, "Dinic: \(context)")
                    check(Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: small).sinkSide) == Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: capacity).sinkSide), "cut: \(context)")
                }
            }
            // The global cut's precondition is only that its value fits; its sums are formed wider.
            let wide = graph.minimumCut(capacity: capacity)!.value
            if wide <= maximum {
                let narrow = signed ? Int(graph.minimumCut { Int8(caps[$0]) }!.value) : Int(graph.minimumCut { UInt8(caps[$0]) }!.value)
                check(narrow == wide, "directed global cut \(narrow), Int \(wide): \(context)")
            }
        } else {
            let graph = net.undirected()
            let value = graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: capacity)
            typealias Arc = DirectedView<Pseudograph<Int>>.Edges.Index
            if sourceFits {
                if signed {
                    let small: (Int) -> Int8 = { Int8(caps[$0]) }
                    check(Int(graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: small)) == value, "value: \(context)")
                    for flow in [graph.maximumFlow(from: labels[s], to: labels[t], capacity: small), graph.edmondsKarpMaximumFlow(from: labels[s], to: labels[t], capacity: small), graph.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: small)] {
                        check(Int(flow.value) == value, "flow value \(flow.value): \(context)")
                        checkSmallUndirected(net, s, t, value, { Int(flow.flow(ofEdgeAt: Arc(position: $0, reversed: $1))) }, context)
                    }
                    check(Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: small).sinkSide) == Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: capacity).sinkSide), "cut: \(context)")
                } else {
                    let small: (Int) -> UInt8 = { UInt8(caps[$0]) }
                    check(Int(graph.maximumFlowValue(from: labels[s], to: labels[t], capacity: small)) == value, "value: \(context)")
                    for flow in [graph.maximumFlow(from: labels[s], to: labels[t], capacity: small), graph.edmondsKarpMaximumFlow(from: labels[s], to: labels[t], capacity: small), graph.dinicMaximumFlow(from: labels[s], to: labels[t], capacity: small)] {
                        check(Int(flow.value) == value, "flow value \(flow.value): \(context)")
                        checkSmallUndirected(net, s, t, value, { Int(flow.flow(ofEdgeAt: Arc(position: $0, reversed: $1))) }, context)
                    }
                    check(Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: small).sinkSide) == Array(graph.minimumCut(from: labels[s], to: labels[t], capacity: capacity).sinkSide), "cut: \(context)")
                }
            }
            // The global cut and Gomory–Hu need only their answers to fit: the cut's value, and every
            // tree capacity; their sums are formed wider.
            let wide = graph.minimumCut(capacity: capacity)!.value
            let tree = graph.gomoryHuTree(capacity: capacity)!
            let treeFits = (0 ..< n - 1).allSatisfy { tree.capacity(ofEdgeAt: $0) <= maximum }
            if signed {
                if wide <= maximum { check(Int(graph.minimumCut { Int8(caps[$0]) }!.value) == wide, "Nagamochi–Ibaraki: \(context)") }
                if treeFits {
                    let small = graph.gomoryHuTree { Int8(caps[$0]) }!
                    check((0 ..< n - 1).allSatisfy { Int(small.capacity(ofEdgeAt: $0)) == tree.capacity(ofEdgeAt: $0) }, "Gomory–Hu: \(context)")
                }
            } else {
                if wide <= maximum { check(Int(graph.minimumCut { UInt8(caps[$0]) }!.value) == wide, "Nagamochi–Ibaraki: \(context)") }
                if treeFits {
                    let small = graph.gomoryHuTree { UInt8(caps[$0]) }!
                    check((0 ..< n - 1).allSatisfy { Int(small.capacity(ofEdgeAt: $0)) == tree.capacity(ofEdgeAt: $0) }, "Gomory–Hu: \(context)")
                }
            }
        }
    }

    /// An undirected flow read through `flow(edge, reversed)`: within capacity one way, conserved.
    static func checkSmallUndirected(_ net: Network, _ s: Int, _ t: Int, _ value: Int, _ flow: (Int, Bool) -> Int, _ context: String) {
        var balance = [Int](repeating: 0, count: net.n)
        for k in 0 ..< net.m {
            let a = flow(k, false), b = flow(k, true), (u, v) = net.ends[k]
            check(a >= 0 && b >= 0 && a <= net.capacities[k] && b <= net.capacities[k] && (a == 0 || b == 0), "edge \(k) carries \(a) and \(b): \(context)")
            balance[u] += a - b
            balance[v] -= a - b
        }
        for v in 0 ..< net.n {
            let expected = v == s ? value : v == t ? -value : 0
            check(balance[v] == expected, "net flow \(balance[v]) at \(v): \(context)")
        }
    }
}
