import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Cliques
import GraphProtocols

/// Triangles by hand: for each vertex, mark its neighbors, then count marked neighbors of each
/// neighbor with a greater index (node iterator over flat rows). The baseline for CQ-B03.
func handWrittenTriangles(_ offsets: [Int], _ targets: [Int]) -> Int {
    let n = offsets.count - 1
    var mark = [Int](repeating: -1, count: n)
    var total = 0
    for v in 0 ..< n {
        for k in offsets[v] ..< offsets[v + 1] { mark[targets[k]] = v }
        for k in offsets[v] ..< offsets[v + 1] where targets[k] > v {
            let w = targets[k]
            for j in offsets[w] ..< offsets[w + 1] where targets[j] > w && mark[targets[j]] == v { total += 1 }
        }
    }
    return total
}

/// Core numbers by hand: Batagelj–Zaversnik over flat rows. The baseline for CQ-B01.
func handWrittenCores(_ offsets: [Int], _ targets: [Int]) -> [Int] {
    let n = offsets.count - 1
    var degree = (0 ..< n).map { offsets[$0 + 1] - offsets[$0] }
    let maxDegree = degree.max() ?? 0
    var bin = [Int](repeating: 0, count: maxDegree + 1)
    for d in degree { bin[d] += 1 }
    var start = 0
    for d in 0 ... maxDegree { let c = bin[d]; bin[d] = start; start += c }
    var vert = [Int](repeating: 0, count: n), pos = [Int](repeating: 0, count: n)
    for v in 0 ..< n { pos[v] = bin[degree[v]]; vert[pos[v]] = v; bin[degree[v]] += 1 }
    for d in stride(from: maxDegree, to: 0, by: -1) { bin[d] = bin[d - 1] }
    if maxDegree >= 0 { bin[0] = 0 }
    for i in 0 ..< n {
        let v = vert[i]
        for k in offsets[v] ..< offsets[v + 1] {
            let u = targets[k]
            if degree[u] > degree[v] {
                let du = degree[u], pu = pos[u], pw = bin[du], w = vert[pw]
                if u != w { pos[u] = pw; vert[pu] = w; pos[w] = pu; vert[pw] = u }
                bin[du] += 1
                degree[u] -= 1
            }
        }
    }
    return degree
}

/// Chordality by hand: maximum cardinality search with buckets (ties in any order) over flat
/// rows, then Tarjan and Yannakakis's zero fill-in test of its reverse. The baseline for CQ-B05.
func handWrittenIsChordal(_ offsets: [Int], _ targets: [Int]) -> Bool {
    let n = offsets.count - 1
    guard n > 0 else { return true }
    var count = [Int](repeating: 0, count: n)
    var bucketHead = [Int](repeating: -1, count: n + 1)
    var next = [Int](repeating: -1, count: n), previous = [Int](repeating: -1, count: n)
    for v in 0 ..< n {
        next[v] = bucketHead[0]
        if bucketHead[0] >= 0 { previous[bucketHead[0]] = v }
        bucketHead[0] = v
    }
    var visited = [Bool](repeating: false, count: n)
    var order: [Int] = [], position = [Int](repeating: 0, count: n)
    var top = 0
    for _ in 0 ..< n {
        while bucketHead[top] < 0 { top -= 1 }
        let v = bucketHead[top]
        bucketHead[top] = next[v]
        if next[v] >= 0 { previous[next[v]] = -1 }
        visited[v] = true
        position[v] = order.count
        order.append(v)
        for k in offsets[v] ..< offsets[v + 1] where !visited[targets[k]] {
            let w = targets[k], c = count[w]
            if previous[w] >= 0 { next[previous[w]] = next[w] } else { bucketHead[c] = next[w] }
            if next[w] >= 0 { previous[next[w]] = previous[w] }
            count[w] = c + 1
            previous[w] = -1
            next[w] = bucketHead[c + 1]
            if bucketHead[c + 1] >= 0 { previous[bucketHead[c + 1]] = w }
            bucketHead[c + 1] = w
            if c + 1 > top { top = c + 1 }
        }
    }
    // The zero fill-in test on the elimination order, the reverse of the visit order.
    let elimination = Array(order.reversed())
    for (i, v) in elimination.enumerated() { position[v] = i }
    var follower = [Int](repeating: -1, count: n), index = [Int](repeating: -1, count: n)
    for i in 0 ..< n {
        let v = elimination[i]
        follower[v] = v
        index[v] = i
        for k in offsets[v] ..< offsets[v + 1] where position[targets[k]] < i {
            let w = targets[k]
            index[w] = i
            if follower[w] == w { follower[w] = v }
        }
        for k in offsets[v] ..< offsets[v + 1] where position[targets[k]] < i {
            if index[follower[targets[k]]] < i { return false }
        }
    }
    return true
}

/// Truss numbers by hand: rows sorted, edges numbered, supports by marking, then peeling in a
/// bucket order with binary searches in the rows (Wang–Cheng) over flat arrays. The baseline for
/// CQ-B06.
func handWrittenTrusses(_ offsets: [Int], _ targets: [Int]) -> [Int] {
    let n = offsets.count - 1
    var rows = targets
    for v in 0 ..< n { rows[offsets[v] ..< offsets[v + 1]].sort() }
    func slot(_ w: Int, _ v: Int) -> Int {
        var low = offsets[v], high = offsets[v + 1]
        while low < high { let mid = (low + high) >> 1; if rows[mid] < w { low = mid + 1 } else { high = mid } }
        return low < offsets[v + 1] && rows[low] == w ? low : -1
    }
    var edge = [Int](repeating: 0, count: rows.count), ends: [Int] = []
    for v in 0 ..< n {
        for s in offsets[v] ..< offsets[v + 1] {
            if rows[s] > v { edge[s] = ends.count >> 1; ends.append(v); ends.append(rows[s]) } else { edge[s] = edge[slot(v, rows[s])] }
        }
    }
    let m = ends.count >> 1
    var support = [Int](repeating: 0, count: m)
    var mark = [Int](repeating: -1, count: n)
    for v in 0 ..< n {
        for k in offsets[v] ..< offsets[v + 1] { mark[rows[k]] = v }
        for k in offsets[v] ..< offsets[v + 1] where rows[k] > v {
            let w = rows[k]
            for j in offsets[w] ..< offsets[w + 1] where rows[j] > w && mark[rows[j]] == v {
                support[edge[k]] += 1
                support[edge[j]] += 1
                support[edge[slot(rows[j], v)]] += 1
            }
        }
    }
    let maxSupport = support.max() ?? 0
    var bin = [Int](repeating: 0, count: maxSupport + 1)
    for s in support { bin[s] += 1 }
    var start = 0
    for s in 0 ... maxSupport { let c = bin[s]; bin[s] = start; start += c }
    var sorted = [Int](repeating: 0, count: m), pos = [Int](repeating: 0, count: m)
    for e in 0 ..< m { pos[e] = bin[support[e]]; sorted[pos[e]] = e; bin[support[e]] += 1 }
    for s in stride(from: maxSupport, to: 0, by: -1) { bin[s] = bin[s - 1] }
    bin[0] = 0
    var removed = [Bool](repeating: false, count: m), truss = [Int](repeating: 0, count: m)
    for i in 0 ..< m {
        let e = sorted[i], s = support[e]
        truss[e] = s + 2
        removed[e] = true
        var a = ends[2 * e], b = ends[2 * e + 1]
        if offsets[a + 1] - offsets[a] > offsets[b + 1] - offsets[b] { swap(&a, &b) }
        for k in offsets[a] ..< offsets[a + 1] where rows[k] != b && !removed[edge[k]] {
            let j = slot(rows[k], b)
            guard j >= 0, !removed[edge[j]] else { continue }
            for side in 0 ..< 2 {
                let f = side == 0 ? edge[k] : edge[j]
                guard support[f] > s else { continue }
                let sf = support[f], pf = pos[f], pg = bin[sf], g = sorted[pg]
                if f != g { pos[f] = pg; sorted[pf] = g; pos[g] = pf; sorted[pg] = f }
                bin[sf] += 1
                support[f] -= 1
            }
        }
    }
    return truss
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A sparse random graph G(10⁵, 5·10⁵) and a denser G(2000, 20 000).
    func simple(_ n: Int, _ m: Int, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var seen = Set<UndirectedEdge<Int>>()
        let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: m, seed: seed).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    let sparse = simple(100_000, 500_000, 7)
    let dense = simple(2000, 20_000, 8)
    // G(n, p): each pair an edge with probability p, so ω grows with n (the branch-and-bound case).
    func bernoulli(_ n: Int, _ p: Double, _ seed: UInt) -> UndirectedAdjacencyList<Int> {
        var rng = SeededRandomNumberGenerator(seed: seed)
        var pairs: [UndirectedEdge<Int>] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p { pairs.append(UndirectedEdge(u, v)) }
        }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    }
    let packed = bernoulli(150, 0.9, 9)
    let packedSmall = bernoulli(120, 0.9, 10)
    func rows(_ g: UndirectedAdjacencyList<Int>) -> ([Int], [Int]) {
        var offsets = [0], targets: [Int] = []
        for v in 0 ..< g.vertexCount {
            targets.append(contentsOf: g.neighborIndices(ofIndex: v))
            offsets.append(targets.count)
        }
        return (offsets, targets)
    }
    let (so, st) = rows(sparse)
    precondition(handWrittenTriangles(so, st) == sparse.triangleCount())
    let sparseCores = sparse.coreNumbers()
    precondition(handWrittenCores(so, st) == (0 ..< sparse.vertexCount).map { sparseCores.coreNumber(ofIndex: $0) })

    // CQ-B01: cores.
    Benchmark("Cliques: BASELINE hand-written Batagelj–Zaversnik, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenCores(so, st)) }
    }
    Benchmark("Cliques: coreNumbers(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.coreNumbers()) }
    }
    // CQ-B02: maximal cliques, maximum clique.
    Benchmark("Cliques: maximalCliques() counted, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.maximalCliques().reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cliques: maximalCliques() counted, G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.maximalCliques().reduce(0) { n, _ in n + 1 }) }
    }
    // Every event of the Bron–Kerbosch search, against the plain call above.
    Benchmark("Cliques: bronKerboschEvents() counted, G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations {
            var cliques = 0
            for case .maximalClique in dense.lazy.bronKerbosch() { cliques &+= 1 }
            blackHole(cliques)
        }
    }
    Benchmark("Cliques: cliqueNumber(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.cliqueNumber()) }
    }
    Benchmark("Cliques: maximumClique(), G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.maximumClique()) }
    }
    Benchmark("Cliques: lexicographicallyFirstMaximumClique(), G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.lexicographicallyFirstMaximumClique()) }
    }
    Benchmark("Cliques: cliqueNumber(), G(150, 0.9)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(packed.cliqueNumber()) }
    }
    Benchmark("Cliques: maximumClique(), G(120, 0.9)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(packedSmall.maximumClique()) }
    }
    Benchmark("Cliques: lexicographicallyFirstMaximumClique(), G(120, 0.9)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(packedSmall.lexicographicallyFirstMaximumClique()) }
    }
    // CQ-B03: triangles and clustering.
    Benchmark("Cliques: BASELINE hand-written node-iterator triangles, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenTriangles(so, st)) }
    }
    Benchmark("Cliques: triangleCount(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.triangleCount()) }
    }
    Benchmark("Cliques: clusteringCoefficients(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.clusteringCoefficients()) }
    }

    // CQ-B05: chordality on 10⁵ vertices, each joined to a random earlier vertex and to that
    // vertex's own parent (chordal), and the same with one long hole closed through the root.
    var parent = [0, 0]
    var chordalEdges = [UndirectedEdge(0, 1)]
    var state: UInt64 = 0x9E37_79B9_7F4A_7C15
    for v in 2 ..< 100_000 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        let p = Int(state >> 33) % v
        parent.append(p)
        chordalEdges.append(UndirectedEdge(v, p))
        if parent[p] != p { chordalEdges.append(UndirectedEdge(v, parent[p])) }
    }
    let chordal = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: chordalEdges)
    let (co, ct) = rows(chordal)
    precondition(chordal.isChordal && handWrittenIsChordal(co, ct))
    Benchmark("Cliques: BASELINE hand-written MCS chordality test, chordal 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenIsChordal(co, ct)) }
    }
    Benchmark("Cliques: isChordal, chordal 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(chordal.isChordal) }
    }
    Benchmark("Cliques: chordalGraphCliques, chordal 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(chordal.chordalGraphCliques()) }
    }
    Benchmark("Cliques: findHole, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.findHole()) }
    }

    // CQ-B06: trusses, onion layers, every triangle, clique numbers by vertex, a maximum-weight
    // clique; k-crusts and k-coronas read the core numbers.
    let trussBaseline = handWrittenTrusses(so, st)
    let trusses = sparse.trussNumbers()
    precondition(trussBaseline.reduce(0, +) == sparse.edges.indices.reduce(0) { $0 + trusses.trussNumber(ofEdgeAt: $1)! })
    Benchmark("Cliques: BASELINE hand-written Wang–Cheng trusses, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenTrusses(so, st)) }
    }
    Benchmark("Cliques: trussNumbers(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.trussNumbers()) }
    }
    Benchmark("Cliques: onionLayers(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.onionLayers()) }
    }
    Benchmark("Cliques: kCorona(2), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparseCores.kCorona(2)) }
    }
    Benchmark("Cliques: allCliques(sizes: 3...3) counted, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.allCliques(sizes: 3 ... 3).reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cliques: allCliques(sizes: 1...) counted, G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.allCliques(sizes: 1...).reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cliques: maximumWeightClique, G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.maximumWeightClique { ($0 * 7) % 11 + 1 }) }
    }
    Benchmark("Cliques: maximumWeightClique, G(120, 0.9)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(packedSmall.maximumWeightClique { ($0 * 7) % 11 + 1 }) }
    }
    Benchmark("Cliques: cliqueNumber(of:) for 100 vertices, G(2000, 2·10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole((0 ..< 100).map { dense.cliqueNumber(of: $0 * 20) }) }
    }
    // Tree decompositions: a 60 × 60 grid (treewidth 60) and a sparse G(2000, 3000).
    var gridEdges: [UndirectedEdge<Int>] = []
    for r in 0 ..< 60 {
        for c in 0 ..< 60 {
            if c < 59 { gridEdges.append(UndirectedEdge(60 * r + c, 60 * r + c + 1)) }
            if r < 59 { gridEdges.append(UndirectedEdge(60 * r + c, 60 * r + c + 60)) }
        }
    }
    let grid = UndirectedAdjacencyList(vertices: 0 ..< 3600, edges: gridEdges)
    let thin = simple(2000, 3000, 11)
    Benchmark("Cliques: treewidthMinDegree(), 60 × 60 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.treewidthMinDegree().width) }
    }
    Benchmark("Cliques: treewidthMinFillIn(), 60 × 60 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.treewidthMinFillIn().width) }
    }
    Benchmark("Cliques: treewidthMinDegree(), G(2000, 3000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(thin.treewidthMinDegree().width) }
    }
    Benchmark("Cliques: treewidthMinFillIn(), G(2000, 3000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(thin.treewidthMinFillIn().width) }
    }
}
