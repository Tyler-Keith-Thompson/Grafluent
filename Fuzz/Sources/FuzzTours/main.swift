// Tours against invariants that need no oracle, on multigraphs with self-loops and parallel (and
// antiparallel) edges, with vertex labels in a shuffled order, on `Pseudograph`,
// `DirectedPseudograph`, the undirected view of a `DirectedPseudograph`, `CompressedSparseRow`
// (which lends its own rows, and keeps one copy of a repeated edge) and conformers without vertex
// or edge indices.
//
// Eulerian: `isEulerian` and `hasEulerianTrail` exactly when the degree rules (a self-loop adds 2,
// or one in and one out) and the connectivity of the vertices with edges say; every circuit and
// trail a genuine walk using each edge exactly once, starting where the documentation says (the
// first vertex with an edge; the first odd vertex, or the one with out − in = 1), the trail ending
// at the other odd vertex (in − out = 1); `(from:)` existing exactly for the documented starts and
// starting there. Hamiltonian: every path and cycle genuine (each vertex once, consecutive vertices
// joined by the listed edges, no edge twice), existing exactly when a bitmask dynamic program over
// subsets says (n ≤ 10), `hamiltonianPath()` from the first vertex that has one, `(from:to:)` from
// and to the asked vertices, the cycle from the first vertex. Tours on complete multigraphs: each
// tour a permutation through each pair's lightest copy (the earliest on ties), nearest neighbour
// by its definition step by step, 2-opt no heavier than its start tour and 2-optimal, Held–Karp
// equal to brute force with its lexicographically least optimal tour (n ≤ 8) and no heavier than
// any heuristic, Christofides within 3/2 of Held–Karp on Manhattan points, `Double` quarters
// giving the `Int` optima scaled; Held–Karp on graphs that need not be complete nil exactly when
// there is no Hamiltonian cycle, and on directed multigraphs (each ordered pair's lightest arc)
// equal to brute force with its lexicographically least optimum. Representations agree on existence, and the tours, which read only
// the simple graph, are the same on a conformer without indices. Simulated annealing and
// threshold accepting give a tour through the lightest copies from the first vertex, between
// Held–Karp's weight and the nearest-neighbour tour they start from, the same on the conformer
// for the same seed. Chinese postman tours: nil exactly when there are no edges or the vertices
// with edges are not (strongly) connected; otherwise a closed walk from the first vertex with an
// edge, each edge once plus once per duplicate listing, weighing the sum along it, never more
// than walking every edge twice (undirected), equal to the least over every set of duplicated
// edges (undirected, up to 12 non-loop edges) and the same on the conformer.

import CompressedSparseRowModule
import FuzzSupport
import GraphProtocols
import Multigraphs
import Tours
import Walks

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

/// A directed multigraph with no vertex or edge indices.
struct PlainDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

/// A random multigraph by vertex index: labels (index i is `labels[i]`) and ends.
struct Multi {
    var n: Int
    var labels: [Int]
    var ends: [(Int, Int)]
    var m: Int { ends.count }

    init(_ input: inout FuzzInput, vertices: ClosedRange<Int>, edges: Int) {
        n = input.int(in: vertices)
        labels = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { labels.swapAt(i, input.int(below: i + 1)) }
        ends = []
        guard n > 0 else { return }
        // A walk-shaped start makes Eulerian graphs common: a closed or open walk, then extras.
        let walk = input.int(below: edges + 1)
        var at = input.int(below: n)
        for _ in 0 ..< walk {
            let next = input.int(below: n)
            ends.append((at, next))
            at = next
        }
        let extra = input.int(below: 4)
        for _ in 0 ..< extra { ends.append((input.int(below: n), input.int(below: n))) }
        if input.int(below: 2) == 0 && !ends.isEmpty { ends.append((at, ends[0].0)) }
        // Shuffle the positions, so rows are not in walk order.
        for i in stride(from: ends.count - 1, to: 0, by: -1) { ends.swapAt(i, input.int(below: i + 1)) }
    }

    func undirected() -> Pseudograph<Int> {
        Pseudograph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) })
    }

    func directed() -> DirectedPseudograph<Int> {
        DirectedPseudograph(vertices: labels, edges: ends.map { DirectedEdge(from: labels[$0.0], to: labels[$0.1]) })
    }

    func plain() -> PlainGraph { PlainGraph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) }) }

    func plainDirected() -> PlainDigraph { PlainDigraph(vertices: labels, edges: ends.map { DirectedEdge(from: labels[$0.0], to: labels[$0.1]) }) }

    /// By index, not label: vertex i is i.
    func compressed() -> CompressedSparseRow {
        CompressedSparseRow(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
    }
}

// MARK: - Definitions

/// Whether the vertices with an edge are all connected (ignoring direction), by union–find.
func edgedConnected(_ n: Int, _ ends: [(Int, Int)]) -> Bool {
    var parent = Array(0 ..< n)
    func find(_ x: Int) -> Int {
        var x = x
        while parent[x] != x {
            parent[x] = parent[parent[x]]
            x = parent[x]
        }
        return x
    }
    for (u, v) in ends { parent[find(u)] = find(v) }
    var root = -1
    for (u, _) in ends {
        let r = find(u)
        if root < 0 { root = r } else if r != root { return false }
    }
    return true
}

/// Each start's set (bit s) of ends v such that a Hamiltonian path from s covers `full` and ends at
/// v: `ends[v]` has bit s. `adjacent(v, w)` for v ≠ w.
func hamiltonianEnds(_ n: Int, _ adjacent: [[Bool]]) -> [Int] {
    guard n > 0 else { return [] }
    let full = (1 << n) - 1
    var dp = [Int](repeating: 0, count: (full + 1) * n)
    for v in 0 ..< n { dp[(1 << v) * n + v] = 1 << v }
    for mask in 1 ... full {
        for v in 0 ..< n where dp[mask * n + v] != 0 {
            for w in 0 ..< n where mask & (1 << w) == 0 && adjacent[v][w] {
                dp[(mask | 1 << w) * n + w] |= dp[mask * n + v]
            }
        }
    }
    return (0 ..< n).map { dp[full * n + $0] }
}

// MARK: - Checking walks (generic over the representation)

/// The walk's ends at each position, in label space, for an undirected graph.
func undirectedEnds<G: Graph>(_ graph: G) -> [G.Edges.Index: (Int, Int)] where G.Vertex == Int {
    var map: [G.Edges.Index: (Int, Int)] = [:]
    for p in graph.edges.indices { map[p] = (graph.edges[p].u, graph.edges[p].v) }
    return map
}

func directedEnds<G: DirectedGraph>(_ graph: G) -> [G.Edges.Index: (Int, Int)] where G.Vertex == Int {
    var map: [G.Edges.Index: (Int, Int)] = [:]
    for p in graph.edges.indices { map[p] = (graph.source(ofEdgeAt: p), graph.target(ofEdgeAt: p)) }
    return map
}

/// Whether edge `e` joins `a` to `b` (either way when undirected).
func joins(_ ends: (Int, Int), _ a: Int, _ b: Int, directed: Bool) -> Bool {
    (ends.0 == a && ends.1 == b) || (!directed && ends.0 == b && ends.1 == a)
}

/// Checks a walk listed as `vertices` (closed: the last vertex joins the first through the last
/// edge) through `edges`: consecutive vertices joined by the edges, each in `ends`.
func checkWalk<Index: Hashable>(_ vertices: [Int], _ edges: [Index], closed: Bool, ends: [Index: (Int, Int)], directed: Bool, _ what: String, _ context: String) {
    check(edges.count == (closed ? vertices.count : vertices.count - 1), "\(what): \(vertices.count) vertices, \(edges.count) edges: \(context)")
    for i in 0 ..< edges.count {
        let a = vertices[i], b = vertices[i + 1 == vertices.count ? 0 : i + 1]
        guard let e = ends[edges[i]] else {
            check(false, "\(what): edge \(i) is not a position of the graph: \(context)")
            return
        }
        check(joins(e, a, b, directed: directed), "\(what): edge \(i) \(e) does not join \(a) and \(b): \(context)")
    }
}

/// Every edge exactly once.
func checkEveryEdgeOnce<Index: Hashable>(_ edges: [Index], ends: [Index: (Int, Int)], _ what: String, _ context: String) {
    check(edges.count == ends.count && Set(edges).count == edges.count, "\(what): \(edges.count) edges, \(Set(edges).count) distinct, of \(ends.count): \(context)")
}

// MARK: - Eulerian facts and walks

/// The documented Eulerian answers on an undirected graph, from its ends (labels) and vertex
/// order, against `graph`.
func checkUndirectedEulerian<G: Graph>(_ graph: G, order: [Int], _ ends: [(Int, Int)], _ context: String) where G.Vertex == Int {
    let m = ends.count
    var degree: [Int: Int] = [:]
    for v in order { degree[v] = 0 }
    for (u, v) in ends {
        degree[u, default: 0] += 1
        degree[v, default: 0] += 1
    }
    let odd = order.filter { degree[$0]! & 1 != 0 }
    var index: [Int: Int] = [:]
    for (i, v) in order.enumerated() { index[v] = i }
    let connected = edgedConnected(order.count, ends.map { (index[$0.0]!, index[$0.1]!) })
    let eulerian = odd.isEmpty && connected
    let trail = (odd.isEmpty || odd.count == 2) && connected
    check(graph.isEulerian == eulerian, "isEulerian \(graph.isEulerian), expected \(eulerian): \(context)")
    check(graph.hasEulerianTrail == trail, "hasEulerianTrail \(graph.hasEulerianTrail), expected \(trail): \(context)")
    let positions = undirectedEnds(graph)
    let firstEdged = order.first { degree[$0]! > 0 }

    let circuit = graph.eulerianCircuit()
    check((circuit != nil) == (eulerian && m > 0), "eulerianCircuit \(String(describing: circuit)), Eulerian \(eulerian), \(m) edges: \(context)")
    if let circuit {
        checkWalk(circuit.vertices, circuit.edges, closed: true, ends: positions, directed: false, "circuit", context)
        checkEveryEdgeOnce(circuit.edges, ends: positions, "circuit", context)
        check(circuit.vertices.first == firstEdged, "circuit starts at \(circuit.vertices[0]), not \(String(describing: firstEdged)): \(context)")
    }
    let walk = graph.eulerianTrail()
    check((walk != nil) == (trail && !order.isEmpty), "eulerianTrail \(String(describing: walk)), expected one: \(trail): \(context)")
    if let walk {
        checkWalk(walk.vertices, walk.edges, closed: false, ends: positions, directed: false, "trail", context)
        checkEveryEdgeOnce(walk.edges, ends: positions, "trail", context)
        let start = m == 0 ? order.first : odd.isEmpty ? firstEdged : odd.first
        check(walk.vertices.first == start, "trail starts at \(walk.vertices[0]), not \(String(describing: start)): \(context)")
        if odd.count == 2 { check(walk.vertices.last == odd[1], "trail ends at \(walk.vertices.last!), not \(odd[1]): \(context)") }
    }
    for v in order {
        let from = graph.eulerianCircuit(from: v)
        check((from != nil) == (eulerian && degree[v]! > 0), "eulerianCircuit(from: \(v)) \(String(describing: from)): \(context)")
        if let from {
            check(from.vertices.first == v, "eulerianCircuit(from: \(v)) starts at \(from.vertices[0]): \(context)")
            checkWalk(from.vertices, from.edges, closed: true, ends: positions, directed: false, "circuit from \(v)", context)
            checkEveryEdgeOnce(from.edges, ends: positions, "circuit from \(v)", context)
        }
        let fromTrail = graph.eulerianTrail(from: v)
        let allowed = m == 0 || (trail && (odd.isEmpty ? degree[v]! > 0 : odd.contains(v)))
        check((fromTrail != nil) == allowed, "eulerianTrail(from: \(v)) \(String(describing: fromTrail)), expected one: \(allowed): \(context)")
        if let fromTrail {
            check(fromTrail.vertices.first == v, "eulerianTrail(from: \(v)) starts at \(fromTrail.vertices[0]): \(context)")
            checkWalk(fromTrail.vertices, fromTrail.edges, closed: false, ends: positions, directed: false, "trail from \(v)", context)
            checkEveryEdgeOnce(fromTrail.edges, ends: positions, "trail from \(v)", context)
        }
    }
}

func checkDirectedEulerian<G: DirectedGraph>(_ graph: G, order: [Int], _ ends: [(Int, Int)], _ context: String) where G.Vertex == Int {
    let m = ends.count
    var balance: [Int: Int] = [:], touched: Set<Int> = []
    for v in order { balance[v] = 0 }
    for (u, v) in ends {
        balance[u, default: 0] += 1
        balance[v, default: 0] -= 1
        touched.insert(u)
        touched.insert(v)
    }
    let plus = order.filter { balance[$0]! == 1 }, minus = order.filter { balance[$0]! == -1 }
    let unbalanced = order.filter { balance[$0]! != 0 }.count
    var index: [Int: Int] = [:]
    for (i, v) in order.enumerated() { index[v] = i }
    let connected = edgedConnected(order.count, ends.map { (index[$0.0]!, index[$0.1]!) })
    let eulerian = unbalanced == 0 && connected
    let trail = (unbalanced == 0 || (unbalanced == 2 && plus.count == 1 && minus.count == 1)) && connected
    check(graph.isEulerian == eulerian, "directed isEulerian \(graph.isEulerian), expected \(eulerian): \(context)")
    check(graph.hasEulerianTrail == trail, "directed hasEulerianTrail \(graph.hasEulerianTrail), expected \(trail): \(context)")
    let positions = directedEnds(graph)
    let firstEdged = order.first { touched.contains($0) }

    let circuit = graph.eulerianCircuit()
    check((circuit != nil) == (eulerian && m > 0), "directed eulerianCircuit \(String(describing: circuit)), Eulerian \(eulerian): \(context)")
    if let circuit {
        checkWalk(circuit.vertices, circuit.edges, closed: true, ends: positions, directed: true, "directed circuit", context)
        checkEveryEdgeOnce(circuit.edges, ends: positions, "directed circuit", context)
        check(circuit.vertices.first == firstEdged, "directed circuit starts at \(circuit.vertices[0]): \(context)")
    }
    let walk = graph.eulerianTrail()
    check((walk != nil) == (trail && !order.isEmpty), "directed eulerianTrail \(String(describing: walk)), expected one: \(trail): \(context)")
    if let walk {
        checkWalk(walk.vertices, walk.edges, closed: false, ends: positions, directed: true, "directed trail", context)
        checkEveryEdgeOnce(walk.edges, ends: positions, "directed trail", context)
        let start = m == 0 ? order.first : unbalanced == 0 ? firstEdged : plus.first
        check(walk.vertices.first == start, "directed trail starts at \(walk.vertices[0]), not \(String(describing: start)): \(context)")
        if unbalanced == 2 { check(walk.vertices.last == minus[0], "directed trail ends at \(walk.vertices.last!): \(context)") }
    }
    for v in order {
        let from = graph.eulerianCircuit(from: v)
        check((from != nil) == (eulerian && touched.contains(v)), "directed eulerianCircuit(from: \(v)) \(String(describing: from)): \(context)")
        if let from {
            check(from.vertices.first == v, "directed eulerianCircuit(from: \(v)) starts at \(from.vertices[0]): \(context)")
            checkWalk(from.vertices, from.edges, closed: true, ends: positions, directed: true, "directed circuit from \(v)", context)
            checkEveryEdgeOnce(from.edges, ends: positions, "directed circuit from \(v)", context)
        }
        let fromTrail = graph.eulerianTrail(from: v)
        let allowed = m == 0 || (trail && (unbalanced == 0 ? touched.contains(v) : plus.first == v))
        check((fromTrail != nil) == allowed, "directed eulerianTrail(from: \(v)) \(String(describing: fromTrail)), expected one: \(allowed): \(context)")
        if let fromTrail {
            check(fromTrail.vertices.first == v, "directed eulerianTrail(from: \(v)) starts at \(fromTrail.vertices[0]): \(context)")
            checkWalk(fromTrail.vertices, fromTrail.edges, closed: false, ends: positions, directed: true, "directed trail from \(v)", context)
            checkEveryEdgeOnce(fromTrail.edges, ends: positions, "directed trail from \(v)", context)
        }
    }
}

// MARK: - Hamiltonian paths and cycles

/// Existence facts by index from the dynamic program: `pathEnds[t]` has bit s when a path runs
/// from s to t; `cycle` whether a Hamiltonian cycle exists (n = 1: a self-loop; n = 2: two
/// distinct edges, both directions when directed).
struct HamiltonianFacts {
    var pathEnds: [Int]
    var cycle: Bool

    init(_ net: Multi, directed: Bool) {
        let n = net.n
        var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        for (u, v) in net.ends where u != v {
            adjacent[u][v] = true
            if !directed { adjacent[v][u] = true }
        }
        let ends = hamiltonianEnds(n, adjacent)
        pathEnds = ends
        switch n {
        case 0: cycle = false
        case 1: cycle = net.ends.contains { $0.0 == $0.1 }
        case 2:
            let between = net.ends.filter { $0.0 != $0.1 }
            cycle = directed ? adjacent[0][1] && adjacent[1][0] : between.count >= 2
        default: cycle = (0 ..< n).contains { ends[$0] & 1 != 0 && adjacent[$0][0] }
        }
    }

    func path(from s: Int, to t: Int) -> Bool { pathEnds[t] & (1 << s) != 0 }
    func path(from s: Int) -> Bool { pathEnds.contains { $0 & (1 << s) != 0 } }
}

/// The Hamiltonian checks on one representation, whose `order` is its vertices in `vertices`
/// order and `index` maps a label to the facts' index.
func checkHamiltonian<Index: Hashable>(order: [Int], index: [Int: Int], facts: HamiltonianFacts, positions: [Index: (Int, Int)], directed: Bool,
                                       pathFromAll: Path<Int, Index>?, pathFrom: (Int) -> Path<Int, Index>?, pathFromTo: (Int, Int) -> Path<Int, Index>?, cycle: Cycle<Int, Index>?,
                                       starts: [Int], pairs: [(Int, Int)], _ context: String) {
    let n = order.count
    func genuine(_ vertices: [Int], _ edges: [Index], closed: Bool, _ what: String) {
        check(vertices.count == n && Set(vertices).count == n, "\(what) is not a permutation: \(vertices): \(context)")
        checkWalk(vertices, edges, closed: closed, ends: positions, directed: directed, what, context)
        check(Set(edges).count == edges.count, "\(what) repeats an edge: \(context)")
    }
    let firstStart = order.first { facts.path(from: index[$0]!) }
    check((pathFromAll != nil) == (firstStart != nil), "hamiltonianPath() \(String(describing: pathFromAll)), expected one: \(firstStart != nil): \(context)")
    if let p = pathFromAll {
        genuine(p.vertices, p.edges, closed: false, "hamiltonianPath()")
        check(p.vertices.first == firstStart, "hamiltonianPath() from \(p.vertices[0]), not the first start \(firstStart!): \(context)")
    }
    for s in starts {
        let p = pathFrom(s)
        check((p != nil) == facts.path(from: index[s]!), "hamiltonianPath(from: \(s)) \(String(describing: p)): \(context)")
        if let p {
            genuine(p.vertices, p.edges, closed: false, "hamiltonianPath(from: \(s))")
            check(p.vertices.first == s, "hamiltonianPath(from: \(s)) starts at \(p.vertices[0]): \(context)")
        }
    }
    for (s, t) in pairs {
        let p = pathFromTo(s, t)
        let expected = s == t ? n == 1 : facts.path(from: index[s]!, to: index[t]!)
        check((p != nil) == expected, "hamiltonianPath(from: \(s), to: \(t)) \(String(describing: p)), expected one: \(expected): \(context)")
        if let p {
            genuine(p.vertices, p.edges, closed: false, "hamiltonianPath(from: \(s), to: \(t))")
            check(p.vertices.first == s && p.vertices.last == t, "hamiltonianPath(from: \(s), to: \(t)) is \(p.vertices): \(context)")
        }
    }
    check((cycle != nil) == facts.cycle, "hamiltonianCycle() \(String(describing: cycle)), expected one: \(facts.cycle): \(context)")
    if let c = cycle {
        genuine(c.vertices, c.edges, closed: true, "hamiltonianCycle()")
        check(c.vertices.first == order.first, "hamiltonianCycle() starts at \(c.vertices[0]): \(context)")
    }
}

// MARK: - Tours

/// A complete multigraph by index: each pair once in a shuffled position, extra parallel copies and
/// self-loops, weights from a small palette (ties common), or Manhattan distances between grid
/// points (a metric, with heavier parallel copies only).
struct TourInstance {
    var n: Int
    var labels: [Int]
    var ends: [(Int, Int)]
    var weights: [Int]
    var metric: Bool

    init(_ input: inout FuzzInput, vertices: ClosedRange<Int>, complete: Bool) {
        n = input.int(in: vertices)
        labels = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { labels.swapAt(i, input.int(below: i + 1)) }
        metric = complete && input.int(below: 3) == 0
        var points: [(Int, Int)] = []
        for _ in 0 ..< n { points.append((input.int(below: 8), input.int(below: 8))) }
        let palette = [[0, 1], [1, 2, 3], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 10, 100, 1000]][input.int(below: 4)]
        ends = []
        weights = []
        for u in 0 ..< n {
            for v in u + 1 ..< n where complete || input.int(below: 3) != 0 {
                ends.append(input.int(below: 2) == 0 ? (u, v) : (v, u))
                weights.append(metric ? abs(points[u].0 - points[v].0) + abs(points[u].1 - points[v].1) : palette[input.int(below: palette.count)])
            }
        }
        let extra = input.int(below: 5)
        for _ in 0 ..< extra {
            let u = input.int(below: n), v = input.int(below: n)
            ends.append((u, v))
            if metric && u != v {
                weights.append(abs(points[u].0 - points[v].0) + abs(points[u].1 - points[v].1) + input.int(below: 3))
            } else {
                weights.append(palette[input.int(below: palette.count)])
            }
        }
        var order = Array(0 ..< ends.count)
        for i in stride(from: order.count - 1, to: 0, by: -1) { order.swapAt(i, input.int(below: i + 1)) }
        ends = order.map { ends[$0] }
        weights = order.map { weights[$0] }
    }

    func graph() -> Pseudograph<Int> { Pseudograph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) }) }

    func plain() -> PlainGraph { PlainGraph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) }) }

    /// Each pair's lightest copy (the earliest position on ties), by index; −1 when none.
    func lightest() -> [[Int]] {
        var best = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for (k, (u, v)) in ends.enumerated() where u != v {
            if best[u][v] < 0 || weights[k] < weights[best[u][v]] {
                best[u][v] = k
                best[v][u] = k
            }
        }
        return best
    }
}

/// The tour's weight, after checking it is a Hamiltonian cycle through the lightest copies, and
/// its vertex numbers (indices).
func checkTour(_ tour: Cycle<Int, Int>?, _ instance: TourInstance, _ light: [[Int]], _ what: String, _ context: String) -> (weight: Int, order: [Int])? {
    guard let tour else {
        check(false, "\(what) is nil: \(context)")
        return nil
    }
    var index: [Int: Int] = [:]
    for (i, v) in instance.labels.enumerated() { index[v] = i }
    let order = tour.vertices.map { index[$0]! }
    let n = instance.n
    check(order.count == n && Set(order).count == n, "\(what) \(tour.vertices) is not a permutation: \(context)")
    check(tour.edges.count == n, "\(what) has \(tour.edges.count) edges: \(context)")
    var total = 0
    for i in 0 ..< n {
        let a = order[i], b = order[(i + 1) % n]
        check(tour.edges[i] == light[a][b], "\(what) edge \(i) is \(tour.edges[i]), the lightest copy of \(a)–\(b) is \(light[a][b]): \(context)")
        total += instance.weights[light[a][b]]
    }
    return (total, order)
}

/// Whether no exchange of two tour edges for two lighter ones remains (`d` by index).
func twoOptimal(_ order: [Int], _ d: (Int, Int) -> Int) -> Bool {
    let n = order.count
    for i in 0 ..< n - 2 {
        for j in i + 2 ..< n {
            let a = order[i], b = order[i + 1], c = order[j], e = order[(j + 1) % n]
            if d(a, c) + d(b, e) < d(a, b) + d(c, e) { return false }
        }
    }
    return true
}

/// Every Hamiltonian cycle from vertex 0 through the simple graph: the least weight and the
/// lexicographically least optimal order, or nil.
func bruteForceTour(_ n: Int, _ d: (Int, Int) -> Int?) -> (weight: Int, order: [Int])? {
    var best: (weight: Int, order: [Int])?
    var order = [0], used = [Bool](repeating: false, count: n)
    used[0] = true
    func extend(_ weight: Int) {
        if order.count == n {
            guard let back = d(order[n - 1], 0) else { return }
            let total = weight + back
            // Orders come out in lexicographic order, so the first optimum found stays.
            if best == nil || total < best!.weight { best = (total, order) }
            return
        }
        for v in 1 ..< n where !used[v] {
            guard let w = d(order[order.count - 1], v) else { continue }
            used[v] = true
            order.append(v)
            extend(weight + w)
            order.removeLast()
            used[v] = false
        }
    }
    extend(0)
    return best
}

/// SplitMix64, for the metaheuristics' draws.
struct SplitMix64: RandomNumberGenerator {
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
enum FuzzTours {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        switch input.int(below: 11) {
        case 0, 1: undirectedEulerian(&input)
        case 2, 3: directedEulerian(&input)
        case 4: undirectedHamiltonian(&input)
        case 5: directedHamiltonian(&input)
        case 6: tours(&input)
        case 7: partialHeldKarp(&input)
        case 8: directedHeldKarp(&input)
        default: postman(&input)
        }
    }

    // MARK: Eulerian

    static func undirectedEulerian(_ input: inout FuzzInput) {
        let net = Multi(&input, vertices: 0 ... 8, edges: 14)
        let labelled = net.ends.map { (net.labels[$0.0], net.labels[$0.1]) }
        let context = "undirected \(net.labels), edges \(labelled)"
        let graph = net.undirected()
        checkUndirectedEulerian(graph, order: Array(graph.vertices), labelled, context)
        checkUndirectedEulerian(net.plain(), order: net.labels, labelled, "plain " + context)
        // The undirected view of the directed graph: the same multigraph.
        let view = net.directed().undirectedView
        checkUndirectedEulerian(view, order: Array(view.vertices), labelled, "view " + context)
        check(graph.isEulerian == net.plain().isEulerian && graph.hasEulerianTrail == view.hasEulerianTrail, "representations disagree: \(context)")
    }

    static func directedEulerian(_ input: inout FuzzInput) {
        let net = Multi(&input, vertices: 0 ... 8, edges: 14)
        let labelled = net.ends.map { (net.labels[$0.0], net.labels[$0.1]) }
        let context = "directed \(net.labels), edges \(labelled)"
        let graph = net.directed()
        checkDirectedEulerian(graph, order: Array(graph.vertices), labelled, context)
        checkDirectedEulerian(net.plainDirected(), order: net.labels, labelled, "plain " + context)
        // The compressed sparse row keeps one copy of a repeated edge, so its own edges are the ends.
        let csr = net.compressed()
        let csrEnds = csr.edges.indices.map { (csr.source(ofEdgeAt: $0), csr.target(ofEdgeAt: $0)) }
        checkDirectedEulerian(csr, order: Array(csr.vertices), csrEnds, "compressed " + context)
        if csrEnds.count == net.m {
            check(graph.isEulerian == csr.isEulerian && graph.hasEulerianTrail == csr.hasEulerianTrail, "representations disagree: \(context)")
        }
    }

    // MARK: Hamiltonian

    /// One start and up to three pairs (by label) to ask about.
    static func asks(_ input: inout FuzzInput, _ labels: [Int]) -> (starts: [Int], pairs: [(Int, Int)]) {
        guard !labels.isEmpty else { return ([], []) }
        let n = labels.count
        let starts = [labels[input.int(below: n)]]
        var pairs: [(Int, Int)] = []
        for _ in 0 ..< 3 { pairs.append((labels[input.int(below: n)], labels[input.int(below: n)])) }
        return (starts, pairs)
    }

    static func undirectedHamiltonian(_ input: inout FuzzInput) {
        let net = Multi(&input, vertices: 0 ... 10, edges: 24)
        let facts = HamiltonianFacts(net, directed: false)
        let (starts, pairs) = asks(&input, net.labels)
        let labelled = net.ends.map { (net.labels[$0.0], net.labels[$0.1]) }
        let context = "undirected \(net.labels), edges \(labelled)"
        var index: [Int: Int] = [:]
        for (i, v) in net.labels.enumerated() { index[v] = i }
        let graph = net.undirected()
        checkHamiltonian(order: Array(graph.vertices), index: index, facts: facts, positions: undirectedEnds(graph), directed: false,
                         pathFromAll: graph.hamiltonianPath(), pathFrom: { graph.hamiltonianPath(from: $0) }, pathFromTo: { graph.hamiltonianPath(from: $0, to: $1) },
                         cycle: graph.hamiltonianCycle(), starts: starts, pairs: pairs, context)
        let plain = net.plain()
        checkHamiltonian(order: net.labels, index: index, facts: facts, positions: undirectedEnds(plain), directed: false,
                         pathFromAll: plain.hamiltonianPath(), pathFrom: { plain.hamiltonianPath(from: $0) }, pathFromTo: { plain.hamiltonianPath(from: $0, to: $1) },
                         cycle: plain.hamiltonianCycle(), starts: starts, pairs: pairs, "plain " + context)
    }

    static func directedHamiltonian(_ input: inout FuzzInput) {
        let net = Multi(&input, vertices: 0 ... 10, edges: 30)
        let facts = HamiltonianFacts(net, directed: true)
        let (starts, pairs) = asks(&input, net.labels)
        let labelled = net.ends.map { (net.labels[$0.0], net.labels[$0.1]) }
        let context = "directed \(net.labels), edges \(labelled)"
        var index: [Int: Int] = [:]
        for (i, v) in net.labels.enumerated() { index[v] = i }
        let graph = net.directed()
        checkHamiltonian(order: Array(graph.vertices), index: index, facts: facts, positions: directedEnds(graph), directed: true,
                         pathFromAll: graph.hamiltonianPath(), pathFrom: { graph.hamiltonianPath(from: $0) }, pathFromTo: { graph.hamiltonianPath(from: $0, to: $1) },
                         cycle: graph.hamiltonianCycle(), starts: starts, pairs: pairs, context)
        let plain = net.plainDirected()
        checkHamiltonian(order: net.labels, index: index, facts: facts, positions: directedEnds(plain), directed: true,
                         pathFromAll: plain.hamiltonianPath(), pathFrom: { plain.hamiltonianPath(from: $0) }, pathFromTo: { plain.hamiltonianPath(from: $0, to: $1) },
                         cycle: plain.hamiltonianCycle(), starts: starts, pairs: pairs, "plain " + context)
        // The compressed sparse row is by index (its labels are the indices) and keeps one copy of a
        // repeated edge, which changes no Hamiltonian answer.
        let csr = net.compressed()
        let identity = Dictionary(uniqueKeysWithValues: (0 ..< net.n).map { ($0, $0) })
        let csrStarts = starts.map { index[$0]! }, csrPairs = pairs.map { (index[$0.0]!, index[$0.1]!) }
        checkHamiltonian(order: Array(csr.vertices), index: identity, facts: facts, positions: directedEnds(csr), directed: true,
                         pathFromAll: csr.hamiltonianPath(), pathFrom: { csr.hamiltonianPath(from: $0) }, pathFromTo: { csr.hamiltonianPath(from: $0, to: $1) },
                         cycle: csr.hamiltonianCycle(), starts: csrStarts, pairs: csrPairs, "compressed " + context)
    }

    // MARK: Tours on complete multigraphs

    static func tours(_ input: inout FuzzInput) {
        let instance = TourInstance(&input, vertices: 3 ... 10, complete: true)
        let n = instance.n, labels = instance.labels, weights = instance.weights
        let context = "\(n) vertices \(labels), edges \(instance.ends), weights \(weights)\(instance.metric ? " (metric)" : "")"
        let graph = instance.graph(), plain = instance.plain()
        let light = instance.lightest()
        let d: (Int, Int) -> Int = { weights[light[$0][$1]] }
        let weight: (Int) -> Int = { weights[$0] }

        // Nearest neighbour, from the first vertex and from a chosen one, by its definition.
        let start = input.int(below: n)
        for (from, tour) in [(0, graph.nearestNeighborTour(weight: weight)), (start, graph.nearestNeighborTour(from: labels[start], weight: weight))] {
            guard let (_, order) = checkTour(tour, instance, light, "nearestNeighborTour from \(from)", context) else { return }
            var expected = [from], left = Array(0 ..< n).filter { $0 != from }
            while !left.isEmpty {
                var best = 0
                for k in 1 ..< left.count where d(expected.last!, left[k]) < d(expected.last!, left[best]) { best = k }
                expected.append(left.remove(at: best))
            }
            check(order == expected, "nearestNeighborTour from \(from) is \(order), expected \(expected): \(context)")
        }
        guard let nn = checkTour(graph.nearestNeighborTour(weight: weight), instance, light, "nearestNeighborTour", context) else { return }

        // 2-opt from nearest neighbour, and from a shuffled tour.
        guard let two = checkTour(graph.twoOptTour(weight: weight), instance, light, "twoOptTour", context) else { return }
        check(two.weight <= nn.weight, "twoOptTour \(two.weight) is heavier than its start \(nn.weight): \(context)")
        check(two.order[0] == 0, "twoOptTour starts at \(two.order[0]): \(context)")
        check(twoOptimal(two.order, d), "twoOptTour \(two.order) is not 2-optimal: \(context)")
        var shuffled = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { shuffled.swapAt(i, input.int(below: i + 1)) }
        guard let initial = Cycle(shuffled.map { labels[$0] }, in: graph) else {
            check(false, "no cycle through \(shuffled) in a complete graph: \(context)")
            return
        }
        var initialWeight = 0
        for i in 0 ..< n { initialWeight += d(shuffled[i], shuffled[(i + 1) % n]) }
        guard let improved = checkTour(graph.twoOptTour(improving: initial, weight: weight), instance, light, "twoOptTour(improving:)", context) else { return }
        check(improved.weight <= initialWeight, "twoOptTour(improving:) \(improved.weight) is heavier than \(initialWeight): \(context)")
        check(improved.order[0] == shuffled[0], "twoOptTour(improving:) starts at \(improved.order[0]), not \(shuffled[0]): \(context)")
        check(twoOptimal(improved.order, d), "twoOptTour(improving:) \(improved.order) is not 2-optimal: \(context)")

        // Christofides and Held–Karp.
        guard let chr = checkTour(graph.christofidesTour(weight: weight), instance, light, "christofidesTour", context),
              let hk = checkTour(graph.shortestTour(weight: weight), instance, light, "shortestTour", context) else { return }
        check(chr.order[0] == 0 && hk.order[0] == 0, "christofidesTour or shortestTour not from vertex 0: \(context)")
        for (name, other) in [("nearest neighbour", nn.weight), ("2-opt", two.weight), ("2-opt improving", improved.weight), ("Christofides", chr.weight)] {
            check(hk.weight <= other, "shortestTour \(hk.weight) is heavier than \(name) \(other): \(context)")
        }
        if instance.metric { check(2 * chr.weight <= 3 * hk.weight, "christofidesTour \(chr.weight) is past 3/2 of \(hk.weight) on a metric: \(context)") }
        if n <= 8, let brute = bruteForceTour(n, { a, b in d(a, b) }) {
            check(hk.weight == brute.weight && hk.order == brute.order, "shortestTour \(hk.order) weighs \(hk.weight), brute force \(brute.order) \(brute.weight): \(context)")
        }

        // Dyadic doubles: the same optimum, scaled; the heuristics still genuine and no lighter.
        let quarter: (Int) -> Double = { Double(weights[$0]) / 4 }
        if let hkq = graph.shortestTour(weight: quarter) {
            check(hkq.weight(quarter) == Double(hk.weight) / 4, "Double shortestTour weighs \(hkq.weight(quarter)), expected \(Double(hk.weight) / 4): \(context)")
        } else {
            check(false, "Double shortestTour is nil: \(context)")
        }
        guard let chrq = checkTour(graph.christofidesTour(weight: quarter), instance, light, "Double christofidesTour", context) else { return }
        check(chrq.weight >= hk.weight, "Double christofidesTour \(chrq.weight) is lighter than the optimum \(hk.weight): \(context)")
        if instance.metric { check(2 * chrq.weight <= 3 * hk.weight, "Double christofidesTour \(chrq.weight) is past 3/2 of \(hk.weight): \(context)") }

        // The metaheuristics, from nearest neighbour, both moves, seeded from the input.
        let seed = UInt64(input.int(below: 1 << 30))
        for move in [TourMove.swap, .relocate] {
            var g1 = SplitMix64(state: seed), g2 = SplitMix64(state: seed), g3 = SplitMix64(state: seed), g4 = SplitMix64(state: seed)
            let rounds = input.int(below: 4), inner = input.int(below: 40)
            let annealed = graph.simulatedAnnealingTour(move: move, maximumIterations: rounds, innerIterations: inner, weight: weight, using: &g1)
            let accepted = graph.thresholdAcceptingTour(move: move, threshold: Double(input.int(below: 5)), maximumIterations: rounds, innerIterations: inner, weight: weight, using: &g2)
            for (name, tour) in [("simulatedAnnealingTour", annealed), ("thresholdAcceptingTour", accepted)] {
                guard let found = checkTour(tour, instance, light, "\(name) \(move)", context) else { return }
                check(found.order[0] == 0, "\(name) starts at \(found.order[0]): \(context)")
                check(found.weight <= nn.weight && found.weight >= hk.weight, "\(name) weighs \(found.weight), outside [\(hk.weight), \(nn.weight)]: \(context)")
            }
            let plainAnnealed = plain.simulatedAnnealingTour(move: move, maximumIterations: rounds, innerIterations: inner, weight: weight, using: &g3)
            check(plainAnnealed?.vertices == annealed?.vertices && plainAnnealed?.edges == annealed?.edges, "simulatedAnnealingTour differs without indices: \(context)")
            let doubled = graph.simulatedAnnealingTour(move: move, maximumIterations: rounds, innerIterations: inner, weight: { Double(weights[$0]) }, using: &g4)
            check(doubled?.vertices == annealed?.vertices, "Double simulatedAnnealingTour differs from Int: \(context)")
        }

        // A conformer without indices: the same simple graph, so the same tours.
        let same: [(String, Cycle<Int, Int>?, Cycle<Int, Int>?)] = [
            ("nearestNeighborTour", graph.nearestNeighborTour(weight: weight), plain.nearestNeighborTour(weight: weight)),
            ("twoOptTour", graph.twoOptTour(weight: weight), plain.twoOptTour(weight: weight)),
            ("christofidesTour", graph.christofidesTour(weight: weight), plain.christofidesTour(weight: weight)),
            ("shortestTour", graph.shortestTour(weight: weight), plain.shortestTour(weight: weight)),
        ]
        for (name, a, b) in same {
            check(a?.vertices == b?.vertices && a?.edges == b?.edges, "\(name) differs without indices: \(String(describing: a)) and \(String(describing: b)): \(context)")
        }
    }

    // MARK: Held–Karp on graphs that need not be complete

    static func partialHeldKarp(_ input: inout FuzzInput) {
        let instance = TourInstance(&input, vertices: 3 ... 8, complete: false)
        let n = instance.n, weights = instance.weights
        let context = "partial \(n) vertices \(instance.labels), edges \(instance.ends), weights \(weights)"
        let graph = instance.graph()
        let light = instance.lightest()
        let weight: (Int) -> Int = { weights[$0] }
        let brute = bruteForceTour(n) { a, b in light[a][b] < 0 ? nil : weights[light[a][b]] }
        let tour = graph.shortestTour(weight: weight)
        check((tour != nil) == (brute != nil), "shortestTour \(String(describing: tour)), brute force \(String(describing: brute)): \(context)")
        check((graph.hamiltonianCycle() != nil) == (brute != nil), "hamiltonianCycle and the brute force disagree: \(context)")
        guard tour != nil, let brute else { return }
        guard let hk = checkTour(tour, instance, light, "partial shortestTour", context) else { return }
        check(hk.weight == brute.weight && hk.order == brute.order, "partial shortestTour \(hk.order) weighs \(hk.weight), brute force \(brute.order) \(brute.weight): \(context)")
        let plain = instance.plain().shortestTour(weight: weight)
        check(plain?.vertices == tour?.vertices && plain?.edges == tour?.edges, "partial shortestTour differs without indices: \(context)")
    }

    // MARK: Held–Karp on directed graphs

    static func directedHeldKarp(_ input: inout FuzzInput) {
        // Arcs by index with parallel copies and loops, each ordered pair present or not.
        let n = input.int(in: 3 ... 8)
        var labels = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { labels.swapAt(i, input.int(below: i + 1)) }
        let palette = [[0, 1], [1, 2, 3], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 10, 100, 1000]][input.int(below: 4)]
        let density = input.int(below: 4)
        var ends: [(Int, Int)] = [], weights: [Int] = []
        for u in 0 ..< n {
            for v in 0 ..< n where u != v && input.int(below: 4) >= density {
                ends.append((u, v))
                weights.append(palette[input.int(below: palette.count)])
            }
        }
        for _ in 0 ..< input.int(below: 5) {
            ends.append((input.int(below: n), input.int(below: n)))
            weights.append(palette[input.int(below: palette.count)])
        }
        for i in stride(from: ends.count - 1, to: 0, by: -1) {
            let j = input.int(below: i + 1)
            ends.swapAt(i, j)
            weights.swapAt(i, j)
        }
        let context = "directed \(n) vertices \(labels), arcs \(ends), weights \(weights)"
        // Each ordered pair's lightest arc, the earliest on ties.
        var light = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for (k, (u, v)) in ends.enumerated() where u != v {
            if light[u][v] < 0 || weights[k] < weights[light[u][v]] { light[u][v] = k }
        }
        let brute = bruteForceTour(n) { a, b in light[a][b] < 0 ? nil : weights[light[a][b]] }
        let graph = DirectedPseudograph(vertices: labels, edges: ends.map { DirectedEdge(from: labels[$0.0], to: labels[$0.1]) })
        let weight: (Int) -> Int = { weights[$0] }
        let tour = graph.shortestTour(weight: weight)
        check((tour != nil) == (brute != nil), "directed shortestTour \(String(describing: tour)), brute force \(String(describing: brute)): \(context)")
        check((graph.hamiltonianCycle() != nil) == (brute != nil), "directed hamiltonianCycle and the brute force disagree: \(context)")
        let plain = PlainDigraph(vertices: labels, edges: ends.map { DirectedEdge(from: labels[$0.0], to: labels[$0.1]) }).shortestTour(weight: weight)
        check(plain?.vertices == tour?.vertices && plain?.edges == tour?.edges, "directed shortestTour differs without indices: \(context)")
        guard let tour, let brute else { return }
        var index: [Int: Int] = [:]
        for (i, v) in labels.enumerated() { index[v] = i }
        let order = tour.vertices.map { index[$0]! }
        check(order == brute.order, "directed shortestTour \(order), brute force \(brute.order): \(context)")
        var total = 0
        for i in 0 ..< n {
            let a = order[i], b = order[(i + 1) % n]
            check(tour.edges[i] == light[a][b], "directed shortestTour arc \(i) is \(tour.edges[i]), the lightest \(a) → \(b) is \(light[a][b]): \(context)")
            total += weights[light[a][b]]
        }
        check(total == brute.weight, "directed shortestTour weighs \(total), brute force \(brute.weight): \(context)")
    }

    // MARK: Chinese postman tours

    static func postman(_ input: inout FuzzInput) {
        let net = Multi(&input, vertices: 0 ... 8, edges: 12)
        let directed = input.int(below: 2) == 0
        let palette = [[0, 1], [1], [1, 2, 3], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 10, 100, 1000]][input.int(below: 5)]
        let weights = net.ends.map { _ in palette[input.int(below: palette.count)] }
        let labelled = net.ends.map { (net.labels[$0.0], net.labels[$0.1]) }
        let context = "\(directed ? "directed" : "undirected") \(net.labels), edges \(labelled), weights \(weights)"
        let n = net.n, m = net.m
        var index: [Int: Int] = [:]
        for (i, v) in net.labels.enumerated() { index[v] = i }
        let weight: (Int) -> Int = { weights[$0] }
        // Whether a tour must exist: some edge, and the vertices with edges (strongly) connected.
        var exists = m > 0 && edgedConnected(n, net.ends)
        if directed && exists {
            var reach = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
            for v in 0 ..< n { reach[v][v] = true }
            for (u, v) in net.ends { reach[u][v] = true }
            for k in 0 ..< n { for i in 0 ..< n where reach[i][k] { for j in 0 ..< n where reach[k][j] { reach[i][j] = true } } }
            let touched = Set(net.ends.flatMap { [$0.0, $0.1] })
            exists = touched.allSatisfy { a in touched.allSatisfy { reach[a][$0] } }
        }
        let tour = directed ? net.directed().chinesePostmanTour(weight: weight) : net.undirected().chinesePostmanTour(weight: weight)
        let plain = directed ? net.plainDirected().chinesePostmanTour(weight: weight) : net.plain().chinesePostmanTour(weight: weight)
        check((tour != nil) == exists, "chinesePostmanTour \(String(describing: tour)), a tour exists: \(exists): \(context)")
        check(plain?.walk.vertices == tour?.walk.vertices && plain?.walk.edges == tour?.walk.edges && plain?.duplicatedEdges == tour?.duplicatedEdges,
              "chinesePostmanTour differs without indices: \(context)")
        guard let tour else { return }
        let vs = tour.walk.vertices.map { index[$0]! }, es = tour.walk.edges
        var uses = [Int](repeating: 0, count: m), expected = [Int](repeating: 1, count: m)
        for e in es { uses[e] += 1 }
        for e in tour.duplicatedEdges { expected[e] += 1 }
        check(uses == expected, "chinesePostmanTour uses \(uses), duplicates \(tour.duplicatedEdges): \(context)")
        let firstVertex = net.labels.indices.first { v in net.ends.contains { $0.0 == v || $0.1 == v } } ?? -1
        check(vs.first == firstVertex && vs.last == firstVertex, "chinesePostmanTour from \(vs.first ?? -1), not \(firstVertex): \(context)")
        for (i, e) in es.enumerated() {
            let (a, b) = net.ends[e]
            check(directed ? (a == vs[i] && b == vs[i + 1]) : ((a == vs[i] && b == vs[i + 1]) || (b == vs[i] && a == vs[i + 1])), "chinesePostmanTour step \(i): \(context)")
        }
        check(tour.duplicatedEdges == tour.duplicatedEdges.sorted(), "duplicatedEdges not in position order: \(context)")
        check(es.reduce(0) { $0 + weights[$1] } == tour.weight, "chinesePostmanTour weight \(tour.weight) is not the walk's: \(context)")
        guard !directed else { return }
        check(Set(tour.duplicatedEdges).count == tour.duplicatedEdges.count, "an undirected edge duplicated twice: \(context)")
        check(tour.weight <= 2 * weights.reduce(0, +), "chinesePostmanTour \(tour.weight) is past walking every edge twice: \(context)")
        let candidates = (0 ..< m).filter { net.ends[$0].0 != net.ends[$0].1 }
        guard candidates.count <= 12 else { return }
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in net.ends {
            degree[a] += 1
            degree[b] += 1
        }
        var best = Int.max
        for mask in 0 ..< (1 << candidates.count) {
            var parity = degree.map { $0 & 1 }
            var extra = 0
            for (bit, e) in candidates.enumerated() where mask >> bit & 1 == 1 {
                parity[net.ends[e].0] ^= 1
                parity[net.ends[e].1] ^= 1
                extra += weights[e]
            }
            if parity.allSatisfy({ $0 == 0 }) { best = Swift.min(best, extra) }
        }
        check(tour.weight == weights.reduce(0, +) + best, "chinesePostmanTour \(tour.weight), the least over duplicated sets \(weights.reduce(0, +) + best): \(context)")
    }
}
