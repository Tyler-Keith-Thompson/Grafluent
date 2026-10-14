// Cliques against brute force, on multigraphs of at most 11 vertices with self-loops and parallel
// edges (read as their simple graph): maximal cliques as a set, each in vertex order, every one
// maximal; the clique number and the lexicographically least maximum clique by checking every
// vertex subset; core numbers by peeling, and the degeneracy ordering's property; triangles,
// clustering and transitivity by counting triples; chordality by searching every vertex subset for
// a hole, the perfect elimination ordering by its definition, the chordal cliques against the
// maximal cliques, the treewidth, and the hole a chordless cycle of the graph of four or more,
// canonical. Trusses, onion layers, crusts, coronas, every clique by size, the maximal cliques
// through each vertex, clique numbers per vertex and maximum-weight cliques against brute force.
// On UndirectedAdjacencyList and on a conformer without vertex indices that keeps loops and
// parallel edges.

import AdjacencyListModule
import Cliques
import FuzzSupport
import GraphProtocols
import Walks

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

@main
enum FuzzCliques {
    static func main() { runFuzzer(fuzz) }

    static func check<G: Graph>(_ graph: G, _ n: Int, _ adjacent: [[Bool]], _ name: String) where G.Vertex == Int {
        func isClique(_ set: [Int]) -> Bool {
            for i in set.indices { for j in set.indices where j > i && !adjacent[set[i]][set[j]] { return false } }
            return true
        }
        // Every clique by brute force over subsets.
        var cliques: [[Int]] = []
        for mask in 1 ..< (1 << n) {
            let set = (0 ..< n).filter { mask & (1 << $0) != 0 }
            if isClique(set) { cliques.append(set) }
        }
        let maximal = Set(cliques.filter { c in !(0 ..< n).contains { v in !c.contains(v) && c.allSatisfy { adjacent[$0][v] } } })
        let found = Array(graph.maximalCliques())
        FuzzSupport.check(found.allSatisfy { $0 == $0.sorted() }, "\(name): a clique is not in vertex order")
        FuzzSupport.check(Set(found) == maximal && found.count == maximal.count, "\(name): maximalCliques \(found), expected \(maximal.sorted { $0.lexicographicallyPrecedes($1) })")
        let omega = cliques.map(\.count).max() ?? 0
        FuzzSupport.check(graph.cliqueNumber() == omega, "\(name): cliqueNumber \(graph.cliqueNumber()), expected \(omega)")
        let least = cliques.filter { $0.count == omega }.min { $0.lexicographicallyPrecedes($1) } ?? []
        FuzzSupport.check(graph.lexicographicallyFirstMaximumClique() == least, "\(name): lexicographicallyFirstMaximumClique \(graph.lexicographicallyFirstMaximumClique()), expected \(least)")
        let anyLargest = graph.maximumClique()
        FuzzSupport.check(anyLargest.count == omega && anyLargest == anyLargest.sorted() && isClique(anyLargest), "\(name): maximumClique \(anyLargest), ω \(omega)")

        // Cores by peeling the least-degree vertex.
        var core = [Int](repeating: 0, count: n)
        var alive = Set(0 ..< n)
        var k = 0
        while !alive.isEmpty {
            let degree = { (v: Int) in alive.filter { adjacent[v][$0] }.count }
            let v = alive.min { degree($0) < degree($1) }!
            k = max(k, degree(v))
            core[v] = k
            alive.remove(v)
        }
        let cores = graph.coreNumbers()
        FuzzSupport.check((0 ..< n).map { cores.coreNumber(of: $0) } == core, "\(name): core numbers")
        FuzzSupport.check(cores.degeneracy == (core.max() ?? 0), "\(name): degeneracy")
        let ordering = cores.degeneracyOrdering
        FuzzSupport.check(ordering.sorted() == Array(0 ..< n), "\(name): degeneracyOrdering is not a permutation")
        for (i, v) in ordering.enumerated() {
            let later = ordering[(i + 1)...].filter { adjacent[v][$0] }.count
            FuzzSupport.check(later <= core[v], "\(name): \(v) has \(later) later neighbors, core \(core[v])")
        }
        for k in 0 ... (core.max() ?? 0) + 1 {
            FuzzSupport.check(cores.kCore(k) == (0 ..< n).filter { core[$0] >= k } && cores.kShell(k) == (0 ..< n).filter { core[$0] == k }, "\(name): kCore/kShell(\(k))")
        }

        // Triangles and clustering by triples.
        var triangles = [Int](repeating: 0, count: n)
        for a in 0 ..< n { for b in a + 1 ..< max(n, a + 1) where adjacent[a][b] { for c in b + 1 ..< max(n, b + 1) where adjacent[a][c] && adjacent[b][c] {
            triangles[a] += 1; triangles[b] += 1; triangles[c] += 1
        } } }
        let degrees = (0 ..< n).map { v in (0 ..< n).filter { adjacent[v][$0] }.count }
        let clustering = graph.clusteringCoefficients()
        for v in 0 ..< n {
            let expected = degrees[v] < 2 ? 0 : Double(2 * triangles[v]) / Double(degrees[v] * (degrees[v] - 1))
            FuzzSupport.check(clustering.triangleCount(of: v) == triangles[v] && graph.triangleCount(of: v) == triangles[v], "\(name): triangles of \(v)")
            FuzzSupport.check(clustering.clusteringCoefficient(of: v) == expected && graph.clusteringCoefficient(of: v) == expected, "\(name): clustering of \(v)")
        }
        let corners = triangles.reduce(0, +), triples = degrees.reduce(0) { $0 + $1 * ($1 - 1) / 2 }
        FuzzSupport.check(clustering.triangleCount == corners / 3 && graph.triangleCount() == corners / 3, "\(name): triangle count")
        FuzzSupport.check(clustering.transitivity == (corners == 0 ? 0 : Double(corners) / Double(triples)), "\(name): transitivity")

        // Chordal graphs.
        var hasHole = false
        for mask in 0 ..< (1 << n) where mask.nonzeroBitCount >= 4 && !hasHole {
            let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
            guard members.allSatisfy({ v in members.filter { adjacent[v][$0] }.count == 2 }) else { continue }
            var seen: Set = [members[0]], stack = [members[0]]
            while let v = stack.popLast() {
                for w in members where adjacent[v][w] && seen.insert(w).inserted { stack.append(w) }
            }
            hasHole = seen.count == members.count
        }
        FuzzSupport.check(graph.isChordal == !hasHole, "\(name): isChordal \(graph.isChordal)")
        // Tree decompositions: valid, checked here as well as by isTreeDecomposition; no narrower
        // than the clique number allows; exact under minimum fill-in on a chordal graph.
        for (heuristic, decomposition) in [("min degree", graph.treewidthMinDegree()), ("min fill-in", graph.treewidthMinFillIn())] {
            FuzzSupport.check(graph.isTreeDecomposition(decomposition), "\(name): \(heuristic) decomposition rejected")
            let bags = decomposition.bags.map { Set($0) }
            FuzzSupport.check(decomposition.edges.count == bags.count - 1 && !bags.isEmpty, "\(name): \(heuristic) tree edge count")
            FuzzSupport.check(bags.reduce(into: Set<Int>()) { $0.formUnion($1) } == Set(0 ..< n), "\(name): \(heuristic) bags miss a vertex")
            for u in 0 ..< n {
                for v in u + 1 ..< n where adjacent[u][v] {
                    FuzzSupport.check(bags.contains { $0.contains(u) && $0.contains(v) }, "\(name): \(heuristic) leaves \(u)–\(v) uncovered")
                }
            }
            FuzzSupport.check(decomposition.width >= omega - 1, "\(name): \(heuristic) width \(decomposition.width) below ω − 1")
            if !hasHole && heuristic == "min fill-in" {
                FuzzSupport.check(decomposition.width == omega - 1, "\(name): min fill-in width \(decomposition.width) on a chordal graph")
            }
        }
        if let order = graph.perfectEliminationOrdering() {
            var place = [Int](repeating: 0, count: n)
            for (i, v) in order.enumerated() { place[v] = i }
            for v in 0 ..< n {
                let later = (0 ..< n).filter { adjacent[v][$0] && place[$0] > place[v] }
                FuzzSupport.check(later.allSatisfy { a in later.allSatisfy { b in a == b || adjacent[a][b] } }, "\(name): \(order) is not a perfect elimination ordering")
            }
            let cliques = graph.chordalGraphCliques() ?? []
            FuzzSupport.check(Set(cliques) == maximal && cliques.count == maximal.count, "\(name): chordalGraphCliques \(cliques)")
            FuzzSupport.check(graph.chordalGraphTreewidth() == omega - 1, "\(name): chordalGraphTreewidth")
            FuzzSupport.check(graph.findHole() == nil, "\(name): a hole in a chordal graph")
        } else {
            FuzzSupport.check(graph.chordalGraphCliques() == nil && graph.chordalGraphTreewidth() == nil, "\(name): chordal answers for a graph that is not")
            if let hole = graph.findHole() {
                let vs = hole.vertices
                FuzzSupport.check(Cycle(vertices: vs, edges: hole.edges, in: graph) != nil, "\(name): \(hole) is not a cycle of the graph")
                FuzzSupport.check(vs.count >= 4 && vs[0] == vs.min()! && hole.edges[0] < hole.edges[hole.edges.count - 1], "\(name): \(hole) is not canonical, or too short")
                FuzzSupport.check(vs.allSatisfy { v in vs.filter { adjacent[v][$0] }.count == 2 }, "\(name): \(hole) has a chord")
            } else {
                FuzzSupport.check(false, "\(name): no hole in a graph that is not chordal")
            }
        }
    }

    /// Trusses by peeling, onion layers by NetworkX's rounds, crusts and coronas by their
    /// definitions, every clique by size, the maximal cliques through each vertex, each vertex's
    /// clique number and a maximum-weight clique, all against brute force.
    static func checkCohesion<G: Graph>(_ graph: G, _ n: Int, _ adjacent: [[Bool]], _ seed: Int, _ name: String) where G.Vertex == Int {
        func isClique(_ set: [Int]) -> Bool {
            for i in set.indices { for j in set.indices where j > i && !adjacent[set[i]][set[j]] { return false } }
            return true
        }
        var cliques: [[Int]] = []
        for mask in 1 ..< (1 << n) {
            let set = (0 ..< n).filter { mask & (1 << $0) != 0 }
            if isClique(set) { cliques.append(set) }
        }
        let low = seed % 4, high = low + seed / 4 % 4
        let listed = Array(graph.allCliques(sizes: low ... high))
        let expectedListed = cliques.filter { (low ... high).contains($0.count) }
        FuzzSupport.check(Set(listed) == Set(expectedListed) && listed.count == expectedListed.count, "\(name): allCliques(sizes: \(low)...\(high))")
        let maximal = cliques.filter { c in !(0 ..< n).contains { v in !c.contains(v) && c.allSatisfy { adjacent[$0][v] } } }
        for v in 0 ..< n {
            let through = Array(graph.maximalCliques(containing: v))
            let expected = maximal.filter { $0.contains(v) }
            FuzzSupport.check(Set(through) == Set(expected) && through.count == expected.count, "\(name): maximalCliques(containing: \(v))")
            FuzzSupport.check(graph.cliqueNumber(of: v) == cliques.filter { $0.contains(v) }.map(\.count).max()!, "\(name): cliqueNumber(of: \(v))")
        }
        let weights = (0 ..< n).map { ($0 * 7 + seed) % 11 - 3 }
        let heaviest = cliques.map { $0.reduce(0) { $0 + max(weights[$1], 0) } }.max() ?? 0
        let chosen = graph.maximumWeightClique { weights[$0] }
        FuzzSupport.check(chosen.reduce(0) { $0 + weights[$1] } == heaviest && chosen == chosen.sorted() && isClique(chosen) && chosen.allSatisfy { weights[$0] > 0 }, "\(name): maximumWeightClique \(chosen)")

        // Trusses by peeling edges in fewer than k − 2 triangles.
        var simple = Set<[Int]>()
        for a in 0 ..< n { for b in a + 1 ..< max(n, a + 1) where adjacent[a][b] { simple.insert([a, b]) } }
        var truss: [[Int]: Int] = [:]
        for e in simple { truss[e] = 2 }
        var k = 3
        while true {
            var alive = simple
            var changed = true
            while changed {
                changed = false
                for e in alive where (0 ..< n).filter({ alive.contains([min(e[0], $0), max(e[0], $0)]) && alive.contains([min(e[1], $0), max(e[1], $0)]) }).count < k - 2 {
                    alive.remove(e)
                    changed = true
                }
            }
            if alive.isEmpty { break }
            for e in alive { truss[e] = k }
            k += 1
        }
        let trusses = graph.trussNumbers()
        for p in graph.edges.indices {
            let e = graph.edges[p]
            let expected = e.u == e.v ? nil : truss[[min(e.u, e.v), max(e.u, e.v)]]
            FuzzSupport.check(trusses.trussNumber(ofEdgeAt: p) == expected, "\(name): truss number of \(e)")
        }

        // Onion layers by NetworkX's rounds, then crusts and coronas.
        var layer = [Int](repeating: 0, count: n)
        var remaining = Set(0 ..< n)
        var number = 1, current = 1
        let isolated = (0 ..< n).filter { v in !(0 ..< n).contains { adjacent[v][$0] } }
        if !isolated.isEmpty {
            for v in isolated { layer[v] = 1 }
            remaining.subtract(isolated)
            number = 2
        }
        while !remaining.isEmpty {
            let degree = { (v: Int) in remaining.filter { adjacent[v][$0] }.count }
            current = max(current, remaining.map(degree).min()!)
            let taken = remaining.filter { degree($0) <= current }
            for v in taken { layer[v] = number }
            remaining.subtract(taken)
            number += 1
        }
        let onion = graph.onionLayers()
        FuzzSupport.check((0 ..< n).map { onion.layer(of: $0) } == layer, "\(name): onion layers")
        let cores = graph.coreNumbers()
        let core = (0 ..< n).map { cores.coreNumber(of: $0) }
        for k in 0 ... cores.degeneracy + 1 {
            FuzzSupport.check(cores.kCrust(k) == (0 ..< n).filter { core[$0] <= k }, "\(name): kCrust(\(k))")
            let corona = (0 ..< n).filter { v in core[v] == k && (0 ..< n).filter { adjacent[v][$0] && core[$0] >= k }.count == k }
            FuzzSupport.check(cores.kCorona(k) == corona, "\(name): kCorona(\(k))")
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 11)
        var pairs: [(Int, Int)] = []
        while !input.isEmpty, pairs.count < 30 { pairs.append((input.int(below: n), input.int(below: n))) }
        var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        for (u, v) in pairs where u != v {
            adjacent[u][v] = true
            adjacent[v][u] = true
        }
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges), n, adjacent, "UndirectedAdjacencyList")
        check(PlainGraph(vertices: Array(0 ..< n), edges: edges), n, adjacent, "multigraph without indices")
        let seed = pairs.reduce(n) { $0 &* 31 &+ $1.0 &* 7 &+ $1.1 } & 0xFFFF
        checkCohesion(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges), n, adjacent, seed, "UndirectedAdjacencyList")
        checkCohesion(PlainGraph(vertices: Array(0 ..< n), edges: edges), n, adjacent, seed, "multigraph without indices")
    }
}
