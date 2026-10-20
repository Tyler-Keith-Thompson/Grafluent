// The spanning-forest algorithms against a canonical Kruskal written here, on graphs of at most
// 8 vertices: a simple graph (UndirectedAdjacencyList), a multigraph with self-loops (the
// undirected view of a directed AdjacencyList, where u→v and v→u are parallel edges), and the same
// multigraph through conformers with vertex indices only and with none. Kruskal, the default, the maximum and the
// unweighted forest must be exactly the canonical forests; Borůvka the same edge set; Prim the
// same weight and a spanning forest; Prim from a root a minimum tree of the root's component.
// Every algorithm weighs each non-loop edge exactly once and never a self-loop.
//
// On the directed list: spanning arborescences and branchings against brute force over every
// choice of entering edge when that is small, and otherwise against each other (the unrooted
// optimum is the best rooted one; branchings bound them). Steiner trees by both methods: trees
// over the terminals with terminal leaves, exact for two terminals (a shortest path) and for every
// vertex (a minimum spanning tree), and within 2(1 − 1/t) of brute force on small edge sets.
// Random spanning trees: spanning forests, reproducible from the seed.

import AdjacencyListModule
import FuzzSupport
import Trees
import GraphProtocols
import SpanningTrees

/// An undirected multigraph with no vertex indices.
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

/// The same multigraph with vertex indices (positions in `vertices`) but no edge indices.
struct VertexIndexedGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] { PlainGraph(vertices: vertices, edges: edges).incidentEdges(of: vertex) }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Int { vertices[index] }
}

@main
enum FuzzSpanningTrees {
    static func main() { runFuzzer(fuzz) }

    /// Kruskal over `edges` (u, v, w) in offset order, by `less` on weights, ties by offset.
    static func canonical(_ n: Int, _ edges: [(Int, Int, Int)], _ less: (Int, Int) -> Bool) -> [Int] {
        var parent = Array(0 ..< n)
        func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
        var taken: [Int] = []
        for k in edges.indices.sorted(by: { less(edges[$0].2, edges[$1].2) || (!less(edges[$1].2, edges[$0].2) && $0 < $1) }) {
            let (a, b) = (find(edges[k].0), find(edges[k].1))
            if a != b { parent[a] = b; taken.append(k) }
        }
        return taken
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 8)
        let root = input.int(below: n)
        var raw: [(Int, Int, Int)] = []
        // Up to 48 edges, so even 8 vertices can reach the default's dense path (m ≥ 4n).
        while !input.isEmpty && raw.count < 48 {
            raw.append((input.int(below: n), input.int(below: n), input.int(in: -3 ... 6)))
        }
        let components: (Int, [(Int, Int, Int)]) -> [[Int]] = { n, edges in
            var label = Array(0 ..< n)
            for (u, v, _) in edges { let (a, b) = (label[u], label[v]); for i in label.indices where label[i] == b { label[i] = a } }
            return Dictionary(grouping: 0 ..< n) { label[$0] }.values.map { $0.sorted() }
        }

        func checkAll<G: Graph<Int>>(_ graph: G, _ edges: [(Int, Int, Int)], _ rankOf: (G.Edges.Index) -> Int, _ name: String) {
            let minimum = canonical(n, edges, <)
            let maximum = canonical(n, edges, >)
            let first = canonical(n, edges) { _, _ in false }
            let weightOf: ([Int]) -> Int = { $0.map { edges[$0].2 }.reduce(0, +) }
            let componentCount = components(n, edges).count

            var calls = [Int](repeating: 0, count: edges.count)
            func counted(_ p: G.Edges.Index) -> Int { calls[rankOf(p)] += 1; return edges[rankOf(p)].2 }
            func checkCalls(_ algorithm: String) {
                for k in edges.indices {
                    let expected = edges[k].0 == edges[k].1 ? 0 : 1
                    check(calls[k] == expected, "\(name) \(algorithm): edge \(k) weighed \(calls[k]) times")
                }
                calls = [Int](repeating: 0, count: edges.count)
            }

            let kruskal = graph.kruskalMinimumSpanningTree(weight: counted)
            checkCalls("Kruskal")
            check(kruskal.edges.map(rankOf) == minimum, "\(name) Kruskal \(kruskal.edges.map(rankOf)), canonical \(minimum)")
            check(kruskal.weight == weightOf(minimum), "\(name) Kruskal weight")
            check(graph.minimumSpanningTree(weight: counted) == kruskal, "\(name) the default is Kruskal's forest")
            checkCalls("default")

            // Every spanning forest, in nondecreasing weight: exactly the acyclic edge sets of full
            // size, the first the canonical minimum.
            if edges.count <= 9 {
                let forests = Array(graph.spanningForests(weight: counted))
                calls = [Int](repeating: 0, count: edges.count)
                let size = n - componentCount
                var expected = Set<[Int]>()
                for mask in 0 ..< 1 << edges.count where mask.nonzeroBitCount == size {
                    let chosen = edges.indices.filter { mask >> $0 & 1 == 1 }
                    if chosen.allSatisfy({ edges[$0].0 != edges[$0].1 }) && components(n, chosen.map { edges[$0] }).count == componentCount { expected.insert(chosen) }
                }
                check(Set(forests.map { $0.edges.map(rankOf).sorted() }) == expected && forests.count == expected.count, "\(name) spanningForests lists \(forests.count), expected \(expected.count)")
                check(forests.map(\.weight) == forests.map(\.weight).sorted(), "\(name) spanningForests out of order")
                check(forests.first == kruskal, "\(name) spanningForests does not start with the minimum forest")
                check(forests.allSatisfy { $0.weight == weightOf($0.edges.map(rankOf)) }, "\(name) spanningForests weight")
            }
            let boruvka = graph.boruvkaMinimumSpanningTree(weight: counted)
            checkCalls("Borůvka")
            check(boruvka.edges.map(rankOf).sorted() == minimum.sorted() && boruvka.weight == kruskal.weight, "\(name) Borůvka \(boruvka.edges.map(rankOf))")

            let prim = graph.primMinimumSpanningTree(weight: counted)
            checkCalls("Prim")
            let primEdges = prim.edges.map(rankOf)
            check(prim.weight == kruskal.weight && weightOf(primEdges) == prim.weight, "\(name) Prim weight \(prim.weight), expected \(kruskal.weight)")
            check(primEdges.count == n - componentCount && components(n, primEdges.map { edges[$0] }).count == componentCount, "\(name) Prim is not a spanning forest")

            let rooted = graph.primMinimumSpanningTree(from: root, weight: counted)
            let component = Set(components(n, edges).first { $0.contains(root) }!)
            let inside = edges.enumerated().filter { component.contains($0.element.0) }.map(\.element)
            for k in edges.indices {
                let expected = component.contains(edges[k].0) && edges[k].0 != edges[k].1 ? 1 : 0
                check(calls[k] == expected, "\(name) Prim from \(root): edge \(k) weighed \(calls[k]) times")
            }
            calls = [Int](repeating: 0, count: edges.count)
            check(rooted.edges.count == component.count - 1, "\(name) Prim from \(root): \(rooted.edges.count) edges, component of \(component.count)")
            let insideWeight = canonical(n, inside, <).map { inside[$0].2 }.reduce(0, +)
            check(rooted.weight == insideWeight, "\(name) Prim from \(root): weight \(rooted.weight), expected \(insideWeight)")

            // The event sequences replay the plain calls: Kruskal's tree edges are its forest,
            // examined in sorted order, each decided right after it is examined; Prim's joining
            // edges are its forest, from every vertex and from the root.
            let byPosition = Dictionary(uniqueKeysWithValues: graph.edges.indices.map { ($0, edges[rankOf($0)].2) })
            var kruskalTree: [G.Edges.Index] = []
            var examined: [Int] = []
            var undecided = false
            for event in graph.lazy.kruskal(weight: { byPosition[$0]! }) {
                switch event {
                case .examineEdge(let p, let w):
                    check(!undecided && w == byPosition[p]!, "\(name) Kruskal events: examineEdge(\(p), \(w)) out of turn")
                    examined.append(rankOf(p))
                    undecided = true
                case .treeEdge(let p, let merging, let into):
                    check(undecided && rankOf(p) == examined.last! && merging != into, "\(name) Kruskal events: treeEdge(\(p))")
                    kruskalTree.append(p)
                    undecided = false
                case .nonTreeEdge(let p, _):
                    check(undecided && rankOf(p) == examined.last!, "\(name) Kruskal events: nonTreeEdge(\(p))")
                    undecided = false
                }
            }
            check(!undecided && kruskalTree == kruskal.edges, "\(name) Kruskal events' tree \(kruskalTree.map(rankOf)), plain \(kruskal.edges.map(rankOf))")
            check(examined.map { edges[$0].2 } == examined.map { edges[$0].2 }.sorted(), "\(name) Kruskal events out of weight order")
            for (events, plain, label) in [(graph.lazy.prim(weight: { byPosition[$0]! }), prim, "every vertex"), (graph.lazy.prim(from: root, weight: { byPosition[$0]! }), rooted, "\(root)")] {
                var joined: [G.Edges.Index] = []
                var starts = 0
                for event in events {
                    if case .examine(_, let p?, let w) = event {
                        check(w == byPosition[p]!, "\(name) Prim events from \(label): examine through \(p) at \(w)")
                        joined.append(p)
                    }
                    if case .startVertex = event { starts += 1 }
                }
                check(joined == plain.edges, "\(name) Prim events from \(label): \(joined.map(rankOf)), plain \(plain.edges.map(rankOf))")
                check(starts == (label == "every vertex" ? componentCount : 1), "\(name) Prim events from \(label): \(starts) trees started")
            }

            let maximal = graph.maximumSpanningTree(weight: counted)
            checkCalls("maximum")
            check(maximal.edges.map(rankOf) == maximum && maximal.weight == weightOf(maximum), "\(name) maximum \(maximal.edges.map(rankOf)), canonical \(maximum)")

            let unweighted = graph.minimumSpanningTree()
            check(unweighted.edges.map(rankOf) == first && unweighted.weight == first.count, "\(name) unweighted \(unweighted.edges.map(rankOf)), first forest \(first)")
        }

        // Simple: the first copy of each pair (self-loops kept).
        var seen = Set<UndirectedEdge<Int>>()
        let simple = raw.filter { seen.insert(UndirectedEdge($0.0, $0.1)).inserted }
        let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: simple.map { UndirectedEdge($0.0, $0.1) })
        checkAll(list, simple, { $0 }, "UndirectedAdjacencyList")

        // Multigraph: arcs of a directed list, so u→v and v→u are parallel edges.
        var seenArcs = Set<DirectedEdge<Int>>()
        let arcs = raw.filter { seenArcs.insert(DirectedEdge(from: $0.0, to: $0.1)).inserted }
        let directed = AdjacencyList(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let view = directed.undirectedView
        // The view's edges are the list's arcs in its position order.
        let viewEdges = view.edges.map { e in arcs.first { $0.0 == e.u && $0.1 == e.v }! }
        let viewRanks = Dictionary(uniqueKeysWithValues: view.edges.indices.enumerated().map { ($1, $0) })
        checkAll(view, viewEdges, { viewRanks[$0]! }, "AdjacencyList.undirectedView")

        // The same multigraph without vertex indices.
        let plain = PlainGraph(vertices: Array(0 ..< n), edges: raw.map { UndirectedEdge($0.0, $0.1) })
        checkAll(plain, raw, { $0 }, "PlainGraph")
        checkAll(VertexIndexedGraph(vertices: Array(0 ..< n), edges: raw.map { UndirectedEdge($0.0, $0.1) }), raw, { $0 }, "VertexIndexedGraph")
        checkBranchings(n, directed, arcs)
        // The terminals: bits of a hash of the edges (the input is used up by now).
        checkSteiner(n, plain, raw, raw.reduce(root + 1) { ($0 &* 31 &+ $1.0 &* 7 &+ $1.1) & ((1 << n) - 1) })
        checkRandomTrees(n, plain, raw, UInt64(raw.count * 31 + root))
    }
    /// Branchings and spanning arborescences of `graph`, whose position k is `arcs[k]`.
    static func checkBranchings(_ n: Int, _ graph: AdjacencyList<Int>, _ arcs: [(Int, Int, Int)]) {
        let w: (Int) -> Int = { arcs[$0].2 }
        func valid(_ b: Branching<AdjacencyList<Int>, Int>, _ name: String, spanning: Bool, root: Int?) {
            check(b.edges == b.edges.sorted() && b.weight == b.edges.reduce(0) { $0 + arcs[$1].2 }, "\(name): edges or weight \(b)")
            var parent = [Int](repeating: -1, count: n)
            for k in b.edges {
                check(arcs[k].0 != arcs[k].1 && parent[arcs[k].1] == -1, "\(name): a loop or two edges into \(arcs[k].1)")
                parent[arcs[k].1] = arcs[k].0
            }
            for start in 0 ..< n {
                var v = start, steps = 0
                while parent[v] >= 0 && steps <= n { v = parent[v]; steps += 1 }
                check(steps <= n, "\(name): a cycle")
                if let root { check(v == root, "\(name): \(start) does not hang from \(root)") }
            }
            if spanning { check(b.edges.count == n - 1 && Arborescence(b, in: graph) != nil, "\(name): does not span") }
        }
        let minimumBranching = graph.minimumBranching(weight: w)
        let maximumBranching = graph.maximumBranching(weight: w)
        valid(minimumBranching, "minimumBranching", spanning: false, root: nil)
        valid(maximumBranching, "maximumBranching", spanning: false, root: nil)
        var rootedMinima: [Int] = [], rootedMaxima: [Int] = []
        for r in 0 ..< n {
            let minimum = graph.minimumSpanningArborescence(from: r, weight: w)
            let maximum = graph.maximumSpanningArborescence(from: r, weight: w)
            check((minimum == nil) == (maximum == nil), "from \(r): one of min and max is nil")
            if let minimum { valid(minimum, "min from \(r)", spanning: true, root: r); rootedMinima.append(minimum.weight) }
            if let maximum { valid(maximum, "max from \(r)", spanning: true, root: r); rootedMaxima.append(maximum.weight) }
        }
        let minimum = graph.minimumSpanningArborescence(weight: w), maximum = graph.maximumSpanningArborescence(weight: w)
        check(minimum?.weight == rootedMinima.min() && maximum?.weight == rootedMaxima.max(), "unrooted \(String(describing: minimum?.weight)) / \(String(describing: maximum?.weight)) vs rooted \(rootedMinima) / \(rootedMaxima)")
        if let minimum { valid(minimum, "unrooted min", spanning: true, root: nil) }
        if let maximum { valid(maximum, "unrooted max", spanning: true, root: nil) }
        check(minimumBranching.weight <= min(0, rootedMinima.min() ?? 0) && maximumBranching.weight >= max(0, rootedMaxima.max() ?? 0), "branchings do not bound the arborescences")
        // Brute force over every choice of entering edge, when there are few.
        var entering = [[Int]](repeating: [], count: n)
        for (k, e) in arcs.enumerated() where e.0 != e.1 { entering[e.1].append(k) }
        guard entering.reduce(1, { $0 * ($1.count + 1) }) <= 20_000 else { return }
        var choice = [Int](repeating: -1, count: n)
        var best = (minB: 0, maxB: 0, minA: Int?.none, maxA: Int?.none)
        func visit(_ v: Int) {
            if v == n {
                for start in 0 ..< n {
                    var x = start, steps = 0
                    while choice[x] >= 0 && steps <= n { x = arcs[entering[x][choice[x]]].0; steps += 1 }
                    if steps > n { return }
                }
                let total = (0 ..< n).reduce(0) { $0 + (choice[$1] < 0 ? 0 : arcs[entering[$1][choice[$1]]].2) }
                best.minB = min(best.minB, total)
                best.maxB = max(best.maxB, total)
                if choice.filter({ $0 < 0 }).count == 1 {
                    best.minA = min(best.minA ?? total, total)
                    best.maxA = max(best.maxA ?? total, total)
                }
                return
            }
            for c in -1 ..< entering[v].count { choice[v] = c; visit(v + 1) }
            choice[v] = -1
        }
        visit(0)
        check(minimumBranching.weight == best.minB && maximumBranching.weight == best.maxB, "branchings \(minimumBranching.weight) / \(maximumBranching.weight), brute force \(best)")
        check(minimum?.weight == best.minA && maximum?.weight == best.maxA, "arborescences vs brute force \(best)")
    }

    /// Both Steiner methods on `graph` (position k is `raw[k]`, weights |w|), terminals the bits
    /// of `mask`.
    static func checkSteiner(_ n: Int, _ graph: PlainGraph, _ raw: [(Int, Int, Int)], _ mask: Int) {
        let w: (Int) -> Int = { abs(raw[$0].2) }
        let terminals = (0 ..< n).filter { mask & (1 << $0) != 0 }
        // Floyd–Warshall, and the components.
        var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for v in 0 ..< n { d[v][v] = 0 }
        for (k, e) in raw.enumerated() where e.0 != e.1 { d[e.0][e.1] = min(d[e.0][e.1] ?? .max, w(k)); d[e.1][e.0] = d[e.0][e.1] }
        for k in 0 ..< n { for i in 0 ..< n { for j in 0 ..< n { if let a = d[i][k], let b = d[k][j], a + b < (d[i][j] ?? .max) { d[i][j] = a + b } } } }
        let connected = terminals.allSatisfy { d[terminals[0]][$0] != nil }
        var optimum: Int?
        if raw.count <= 12 && connected {
            for subset in 0 ..< (1 << raw.count) {
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
                var total = 0
                for k in raw.indices where subset & (1 << k) != 0 { parent[find(raw[k].0)] = find(raw[k].1); total += w(k) }
                if terminals.allSatisfy({ find($0) == find(terminals[0]) }) { optimum = min(optimum ?? total, total) }
            }
        }
        for (name, tree) in [("Mehlhorn", graph.steinerTree(terminals: terminals, weight: w)), ("Kou", graph.kouSteinerTree(terminals: terminals, weight: w))] {
            guard let tree else { check(!connected, "\(name) is nil for connected terminals"); continue }
            check(connected, "\(name) connects disconnected terminals")
            check(tree.edges == tree.edges.sorted() && tree.weight == tree.edges.reduce(0) { $0 + w($1) }, "\(name): edges or weight")
            var parent = Array(0 ..< n), degree = [Int](repeating: 0, count: n)
            func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
            for k in tree.edges {
                check(raw[k].0 != raw[k].1 && find(raw[k].0) != find(raw[k].1), "\(name): a loop or a cycle")
                parent[find(raw[k].0)] = find(raw[k].1)
                degree[raw[k].0] += 1
                degree[raw[k].1] += 1
            }
            check(terminals.allSatisfy { find($0) == find(terminals.first ?? 0) }, "\(name): terminals not joined")
            for v in 0 ..< n where degree[v] == 1 { check(terminals.contains(v), "\(name): leaf \(v) is not a terminal") }
            if terminals.count == 2 { check(tree.weight == d[terminals[0]][terminals[1]], "\(name): two terminals, not a shortest path") }
            if terminals.count == n { check(tree.weight == graph.minimumSpanningTree(weight: w).weight, "\(name): every vertex, not a minimum spanning tree") }
            if let optimum { check(tree.weight >= optimum && terminals.count * tree.weight <= 2 * (terminals.count - 1) * optimum || terminals.count < 2, "\(name): \(tree.weight) vs optimum \(optimum)") }
        }
    }

    /// Random spanning trees of `graph` (position k is `raw[k]`): spanning forests, and the same
    /// forest from the same seed.
    static func checkRandomTrees(_ n: Int, _ graph: PlainGraph, _ raw: [(Int, Int, Int)], _ seed: UInt64) {
        var label = Array(0 ..< n)
        for (u, v, _) in raw { let (a, b) = (label[u], label[v]); for i in label.indices where label[i] == b { label[i] = a } }
        let components = Set(label).count
        var first = SplitMix(state: seed), second = SplitMix(state: seed)
        let uniform = graph.randomSpanningTree(using: &first)
        check(uniform == graph.randomSpanningTree(using: &second), "the same seed gave another forest")
        let weighted = graph.randomSpanningTree(weight: { Double(abs(raw[$0].2) + 1) }, using: &first)
        for (name, forest) in [("uniform", uniform.edges), ("weighted", weighted.edges)] {
            check(forest.count == n - components, "\(name): \(forest.count) edges, \(components) components")
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
            for k in forest {
                check(raw[k].0 != raw[k].1 && find(raw[k].0) != find(raw[k].1), "\(name): a loop or a cycle")
                parent[find(raw[k].0)] = find(raw[k].1)
            }
        }
    }
}

/// SplitMix64, a seeded generator.
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
