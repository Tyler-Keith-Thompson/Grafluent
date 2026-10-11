import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import IsomorphismModule
import RandomGraphs

// Targets and baselines: Tests/Catalogs/Isomorphism/api.md, Performance (ref.py --bench: igraph's
// bliss and VF2, NetworkX vf2pp, rustworkx VF2 on the same families).

/// `graph` with its vertices renamed by a seeded permutation and its edges shuffled.
func relabelled(_ graph: UndirectedAdjacencyList<Int>, seed: UInt) -> UndirectedAdjacencyList<Int> {
    var rng = SeededRandomNumberGenerator(seed: seed)
    let n = graph.vertexCount
    let permutation = Array(0 ..< n).shuffled(using: &rng)
    let edges = graph.edges.map { UndirectedEdge(permutation[$0.u], permutation[$0.v]) }.shuffled(using: &rng)
    return UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
}

/// The Paley graph on a prime q ≡ 1 (mod 4): i–j when j − i is a nonzero square mod q.
func paley(_ q: Int) -> UndirectedAdjacencyList<Int> {
    var square = [Bool](repeating: false, count: q)
    for x in 1 ..< q { square[x * x % q] = true }
    var edges: [UndirectedEdge<Int>] = []
    for i in 0 ..< q { for j in i + 1 ..< q where square[j - i] { edges.append(UndirectedEdge(i, j)) } }
    return UndirectedAdjacencyList(vertices: 0 ..< q, edges: edges)
}

/// The Cai–Fürer–Immerman graph over a cubic base (cases.md's construction); `twisted` twists the
/// base's first edge.
func cfi(_ base: UndirectedAdjacencyList<Int>, twisted: Bool) -> UndirectedAdjacencyList<Int> {
    let baseEdges = Array(base.edges)
    var incidences = [[Int]](repeating: [], count: base.vertexCount)
    for (k, e) in baseEdges.enumerated() {
        incidences[e.u].append(k)
        incidences[e.v].append(k)
    }
    var next = 0
    var a: [[Int: [Int]]] = Array(repeating: [:], count: base.vertexCount)   // a[v][edge] = [a0, a1]
    var edges: [UndirectedEdge<Int>] = []
    for v in 0 ..< base.vertexCount {
        let d = incidences[v].count
        var middles: [(Int, Int)] = []
        for mask in 0 ..< (1 << d) where mask.nonzeroBitCount % 2 == 0 {
            middles.append((next, mask))
            next += 1
        }
        for j in 0 ..< d {
            a[v][incidences[v][j]] = [next, next + 1]
            next += 2
        }
        for (m, mask) in middles {
            for j in 0 ..< d { edges.append(UndirectedEdge(m, a[v][incidences[v][j]]![(mask >> j) & 1])) }
        }
    }
    for (k, e) in baseEdges.enumerated() {
        let t = twisted && k == 0 ? 1 : 0
        for i in 0 ..< 2 { edges.append(UndirectedEdge(a[e.u][k]![i], a[e.v][k]![i ^ t])) }
    }
    return UndirectedAdjacencyList(vertices: 0 ..< next, edges: edges)
}

func randomRegular(_ n: Int, _ d: Int, seed: UInt64) -> UndirectedAdjacencyList<Int> {
    var generator = Xoshiro256StarStar(seed: seed)
    return UndirectedAdjacencyList<Int>.randomRegular(vertexCount: n, degree: d, using: &generator)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // Random regular graphs against relabelled copies: one class after the root refinement.
    // Targets: within 2× igraph bliss (11.1 ms, 1052.4 ms, 18.7 ms).
    for (n, d, bliss) in [(1000, 3, "11.1 ms"), (10_000, 3, "1052.4 ms"), (1000, 10, "18.7 ms")] {
        let graph = randomRegular(n, d, seed: UInt64(n + d))
        let copy = relabelled(graph, seed: 7)
        precondition(graph.isIsomorphic(to: copy))
        Benchmark("Isomorphism: isIsomorphic(to:), random \(d)-regular, \(n) vertices, relabelled (bliss \(bliss))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.isIsomorphic(to: copy)) }
        }
    }

    // Non-regular: the root refinement decides. Target: ≤ igraph VF2 (> 30 s); bliss 12.0 ms.
    var gridEdges: [UndirectedEdge<Int>] = []
    for i in 0 ..< 100 {
        for j in 0 ..< 100 {
            if j + 1 < 100 { gridEdges.append(UndirectedEdge(i * 100 + j, i * 100 + j + 1)) }
            if i + 1 < 100 { gridEdges.append(UndirectedEdge(i * 100 + j, (i + 1) * 100 + j)) }
        }
    }
    let grid = UndirectedAdjacencyList(vertices: 0 ..< 10_000, edges: gridEdges)
    let gridCopy = relabelled(grid, seed: 8)
    Benchmark("Isomorphism: isIsomorphic(to:), grid 100 × 100, relabelled (bliss 12.0 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.isIsomorphic(to: gridCopy)) }
    }

    // Paley graphs and the Shrikhande/rook pair. Target: ≤ igraph VF2 (1.7 ms, 212.7 ms, 0.3 ms).
    for (q, vf2) in [(101, "1.7 ms"), (401, "212.7 ms")] {
        let graph = paley(q), copy = relabelled(paley(q), seed: 9)
        precondition(graph.isIsomorphic(to: copy))
        Benchmark("Isomorphism: isIsomorphic(to:), Paley(\(q)), relabelled (igraph VF2 \(vf2))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.isIsomorphic(to: copy)) }
        }
    }
    var shrikhandeEdges: [UndirectedEdge<Int>] = [], rookEdges: [UndirectedEdge<Int>] = []
    for a in 0 ..< 16 {
        for b in a + 1 ..< 16 {
            let (ai, aj, bi, bj) = (a / 4, a % 4, b / 4, b % 4)
            let di = (bi - ai + 4) % 4, dj = (bj - aj + 4) % 4
            if [(1, 0), (3, 0), (0, 1), (0, 3), (1, 1), (3, 3)].contains(where: { $0 == (di, dj) }) { shrikhandeEdges.append(UndirectedEdge(a, b)) }
            if ai == bi || aj == bj { rookEdges.append(UndirectedEdge(a, b)) }
        }
    }
    let shrikhande = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: shrikhandeEdges)
    let rook = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: rookEdges)
    precondition(!shrikhande.isIsomorphic(to: rook))
    Benchmark("Isomorphism: isIsomorphic(to:), Shrikhande against rook(4) (igraph VF2 0.3 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(shrikhande.isIsomorphic(to: rook)) }
    }

    // CFI graphs over random cubic bases. Target, isomorphic pairs: ≤ igraph VF2 (4.7 ms at 10,
    // 5.0 ms at 20); twisted pairs: none in phase 1 (igraph VF2 300.4 ms at 10, > 30 s at 20).
    for (b, vf2) in [(10, "4.7 ms"), (20, "5.0 ms"), (40, "> 30 s")] {
        let base = randomRegular(b, 3, seed: UInt64(100 + b))
        let graph = cfi(base, twisted: false)
        let copy = relabelled(graph, seed: 10)
        precondition(graph.isIsomorphic(to: copy))
        Benchmark("Isomorphism: isIsomorphic(to:), CFI over a cubic base of \(b), relabelled (igraph VF2 \(vf2))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.isIsomorphic(to: copy)) }
        }
    }
    let twistBase = randomRegular(10, 3, seed: 110)
    let untwisted = cfi(twistBase, twisted: false), twisted = relabelled(cfi(twistBase, twisted: true), seed: 11)
    Benchmark("Isomorphism: isIsomorphic(to:), CFI pair over a cubic base of 10, twisted (no phase 1 target; igraph VF2 300.4 ms)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(untwisted.isIsomorphic(to: twisted)) }
    }

    // Pattern counts in a random graph with 10⁴ edges: C4, C5, P4. Target: ≤ igraph VF2.
    var seen = Set<UndirectedEdge<Int>>()
    let sparse = UndirectedAdjacencyList(vertices: 0 ..< 2000, edges: Inputs.randomEdges(vertexCount: 2000, edgeCount: 10_000, seed: 12)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted })
    let c4 = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
    let c5 = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
    let p4 = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
    for (name, pattern) in [("C4", c4), ("C5", c5), ("P4", p4)] {
        Benchmark("Isomorphism: monomorphisms(to:).count, \(name) in G(2000, 10⁴)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(pattern.monomorphisms(to: sparse).reduce(0) { n, _ in n + 1 }) }
        }
        Benchmark("Isomorphism: subgraphIsomorphisms(to:).count, \(name) in G(2000, 10⁴)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(pattern.subgraphIsomorphisms(to: sparse).reduce(0) { n, _ in n + 1 }) }
        }
    }

    // Weisfeiler–Leman on 10⁶ edges. Target: ≥ 50× NetworkX (pure Python).
    var wlSeen = Set<UndirectedEdge<Int>>()
    let large = UndirectedAdjacencyList(vertices: 0 ..< 200_000, edges: Inputs.randomEdges(vertexCount: 200_000, edgeCount: 1_000_000, seed: 13)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && wlSeen.insert($0).inserted })
    Benchmark("Isomorphism: weisfeilerLehmanGraphHash(iterations: 3), 2·10⁵ vertices, 10⁶ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(large.weisfeilerLehmanGraphHash(iterations: 3)) }
    }

    // Allocations per extra element: the 120 automorphisms of K5 (one [Int] each, plus set-up).
    var k5Edges: [UndirectedEdge<Int>] = []
    for u in 0 ..< 5 { for v in u + 1 ..< 5 { k5Edges.append(UndirectedEdge(u, v)) } }
    let k5 = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: k5Edges)
    Benchmark("Isomorphism: isomorphisms(to:), all 120 of K5 onto itself") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(k5.isomorphisms(to: k5).reduce(0) { n, _ in n + 1 }) }
    }
}
