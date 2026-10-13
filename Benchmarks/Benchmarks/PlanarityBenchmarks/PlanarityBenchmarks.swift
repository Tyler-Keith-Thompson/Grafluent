import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Planarity

// Planarity on Delaunay triangulations of uniform random points in the unit square (10⁴ and 10⁵
// points), a 316 × 316 grid, a stacked triangulation of 10⁵ vertices (the catalog's tri(n, 11)),
// and each made non-planar by one edge joining vertex 0 to the highest-numbered vertex not adjacent
// to it. The grid and the stacked triangulation are the catalog's instances exactly. The Delaunay
// graphs are triangulated here (incremental insertion with Lawson flips), from seeded points, so
// they are instances of the same kind as the catalog's scipy ones rather than the same graphs;
// vertices are numbered in insertion order (random in the plane) and edges listed in increasing
// (u, v), as in ref.py.

/// The Delaunay triangulation of `count` seeded uniform points in the unit square: its edges, each
/// (u, v) with u < v, ascending.
func delaunayEdges(_ count: Int, seed: UInt) -> [(Int, Int)] {
    var rng = SeededRandomNumberGenerator(seed: seed)
    var x = (0 ..< count).map { _ in Double.random(in: 0 ..< 1, using: &rng) }
    var y = (0 ..< count).map { _ in Double.random(in: 0 ..< 1, using: &rng) }
    // A super-triangle far around the square, vertices count ..< count + 3.
    x += [-100, 200, -100]
    y += [-100, -100, 200]
    var tv = [count, count + 1, count + 2]      // three vertices per triangle, counterclockwise
    var ta = [-1, -1, -1]                       // the triangle across the edge opposite each vertex
    func orient(_ a: Int, _ b: Int, _ c: Int) -> Double { (x[b] - x[a]) * (y[c] - y[a]) - (y[b] - y[a]) * (x[c] - x[a]) }
    /// Whether d is inside the circumcircle of the counterclockwise triangle a, b, c.
    func inCircle(_ a: Int, _ b: Int, _ c: Int, _ d: Int) -> Bool {
        let adx = x[a] - x[d], ady = y[a] - y[d], bdx = x[b] - x[d], bdy = y[b] - y[d], cdx = x[c] - x[d], cdy = y[c] - y[d]
        let ad = adx * adx + ady * ady, bd = bdx * bdx + bdy * bdy, cd = cdx * cdx + cdy * cdy
        return adx * (bdy * cd - bd * cdy) - ady * (bdx * cd - bd * cdx) + ad * (bdx * cdy - bdy * cdx) > 0
    }
    func repoint(_ t: Int, from old: Int, to new: Int) {
        guard t >= 0 else { return }
        for i in 0 ..< 3 where ta[3 * t + i] == old { ta[3 * t + i] = new; return }
    }
    // Insert in a snake order over a grid of cells, so each walk is short.
    let side = max(1, Int(Double(count).squareRoot() / 2))
    let order = (0 ..< count).sorted { a, b in
        let ra = min(side - 1, Int(y[a] * Double(side))), rb = min(side - 1, Int(y[b] * Double(side)))
        if ra != rb { return ra < rb }
        let ca = min(side - 1, Int(x[a] * Double(side))), cb = min(side - 1, Int(x[b] * Double(side)))
        return ra % 2 == 0 ? (ca, a) < (cb, b) : (ca, a) > (cb, b)
    }
    var last = 0
    var stack: [Int] = []
    for p in order {
        // Walk to the triangle holding p.
        var t = last
        walk: while true {
            for i in 0 ..< 3 {
                let u = tv[3 * t + (i + 1) % 3], w = tv[3 * t + (i + 2) % 3]
                if orient(u, w, p) < 0 {
                    t = ta[3 * t + i]
                    continue walk
                }
            }
            break
        }
        // Split t = (a, b, c) into (a, b, p), (b, c, p), (c, a, p).
        let a = tv[3 * t], b = tv[3 * t + 1], c = tv[3 * t + 2]
        let na = ta[3 * t], nb = ta[3 * t + 1], nc = ta[3 * t + 2]
        let t1 = tv.count / 3, t2 = t1 + 1
        tv[3 * t + 2] = p
        ta[3 * t] = t1; ta[3 * t + 1] = t2; ta[3 * t + 2] = nc
        tv += [b, c, p, c, a, p]
        ta += [t2, t, na, t, t1, nb]
        repoint(na, from: t, to: t1)
        repoint(nb, from: t, to: t2)
        last = t
        stack += [t, t1, t2]
        // Lawson flips: each new triangle has p at slot 2; check the edge opposite it.
        while let s = stack.popLast() {
            var i = 0
            while tv[3 * s + i] != p { i += 1 }
            let u = ta[3 * s + i]
            guard u >= 0 else { continue }
            let px = tv[3 * s + (i + 1) % 3], py = tv[3 * s + (i + 2) % 3]
            var j = 0
            while ta[3 * u + j] != s { j += 1 }
            let q = tv[3 * u + j]
            guard inCircle(p, px, py, q) else { continue }
            // T = (p, px, py), U = (q, py, px). After: T = (p, px, q), U = (p, q, py).
            let nA = ta[3 * s + (i + 1) % 3]          // across (py, p)
            let nB = ta[3 * s + (i + 2) % 3]          // across (p, px)
            let nC = ta[3 * u + (j + 1) % 3]          // across (px, q)
            let nD = ta[3 * u + (j + 2) % 3]          // across (q, py)
            tv[3 * s] = p; tv[3 * s + 1] = px; tv[3 * s + 2] = q
            ta[3 * s] = nC; ta[3 * s + 1] = u; ta[3 * s + 2] = nB
            tv[3 * u] = p; tv[3 * u + 1] = q; tv[3 * u + 2] = py
            ta[3 * u] = nD; ta[3 * u + 1] = nA; ta[3 * u + 2] = s
            repoint(nC, from: u, to: s)
            repoint(nA, from: s, to: u)
            stack += [s, u]
        }
    }
    var seen = Set<Int>()
    var edges: [(Int, Int)] = []
    for t in 0 ..< tv.count / 3 {
        for i in 0 ..< 3 {
            let u = tv[3 * t + i], w = tv[3 * t + (i + 1) % 3]
            guard u < count && w < count else { continue }
            let key = min(u, w) * count + max(u, w)
            if seen.insert(key).inserted { edges.append((min(u, w), max(u, w))) }
        }
    }
    edges.sort { $0 < $1 }
    return edges
}

/// The catalog's tri(n, s): a stacked triangulation grown by an LCG.
func stackedTriangulation(_ n: Int, seed: UInt64) -> [(Int, Int)] {
    var state = seed
    func step(_ k: Int) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Int((state >> 33) % UInt64(k))
    }
    var edges = [(0, 1), (0, 2), (1, 2)]
    var faces = [(0, 1, 2), (0, 1, 2)]
    for k in 3 ..< n {
        let i = step(faces.count)
        let (a, b, c) = faces[i]
        edges += [(a, k), (b, k), (c, k)]
        faces[i] = (a, b, k)
        faces += [(b, c, k), (a, c, k)]
    }
    return edges
}

/// The catalog's grid(k, k): vertices in row-major order, each one's edge right, then down.
func gridEdges(_ k: Int) -> [(Int, Int)] {
    var edges: [(Int, Int)] = []
    for i in 0 ..< k {
        for j in 0 ..< k {
            let v = i * k + j
            if j + 1 < k { edges.append((v, v + 1)) }
            if i + 1 < k { edges.append((v, v + k)) }
        }
    }
    return edges
}

/// One more edge: vertex 0 to the highest-numbered vertex not adjacent to it.
func plusFarEdge(_ n: Int, _ edges: [(Int, Int)]) -> [(Int, Int)] {
    var near = Set<Int>()
    for (u, v) in edges where u == 0 || v == 0 { near.insert(u == 0 ? v : u) }
    var v = n - 1
    while near.contains(v) { v -= 1 }
    return edges + [(0, v)]
}

func graph(_ n: Int, _ edges: [(Int, Int)]) -> UndirectedAdjacencyList<Int> {
    UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let delaunay10k = delaunayEdges(10_000, seed: 1)
    let delaunay100k = delaunayEdges(100_000, seed: 1)
    let delaunay1k = delaunayEdges(1_000, seed: 2)
    let planar: [(String, Int, [(Int, Int)])] = [
        ("Delaunay, 10⁴ points", 10_000, delaunay10k),
        ("Delaunay, 10⁵ points", 100_000, delaunay100k),
        ("grid 316 × 316", 316 * 316, gridEdges(316)),
        ("stacked triangulation, 10⁵", 100_000, stackedTriangulation(100_000, seed: 11)),
    ]
    let nearPlanar: [(String, Int, [(Int, Int)])] = [
        ("Delaunay, 10⁴ points + one edge", 10_000, plusFarEdge(10_000, delaunay10k)),
        ("stacked triangulation, 10⁵ + one edge", 100_000, plusFarEdge(100_000, stackedTriangulation(100_000, seed: 11))),
        ("Delaunay, 10³ points + one edge", 1_000, plusFarEdge(1_000, delaunay1k)),
    ]
    for (name, n, edges) in planar {
        let g = graph(n, edges)
        precondition(g.isPlanar, "\(name) is not planar")
        Benchmark("Planarity: isPlanar, \(name) (m = \(edges.count))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.isPlanar) }
        }
        Benchmark("Planarity: planarEmbedding(), \(name) (m = \(edges.count))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.planarEmbedding()) }
        }
    }
    for (name, n, edges) in nearPlanar {
        let g = graph(n, edges)
        precondition(!g.isPlanar, "\(name) is planar")
        Benchmark("Planarity: isPlanar, \(name) (m = \(edges.count))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.isPlanar) }
        }
        Benchmark("Planarity: findKuratowskiSubgraph(), \(name) (m = \(edges.count))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.findKuratowskiSubgraph()) }
        }
    }
    // Dense: K₃₀₀ has m > 3n − 6, answered after counting distinct pairs.
    var complete: [(Int, Int)] = []
    for u in 0 ..< 300 { for v in u + 1 ..< 300 { complete.append((u, v)) } }
    let k300 = graph(300, complete)
    Benchmark("Planarity: isPlanar, K₃₀₀ (m = \(complete.count), dense shortcut)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(k300.isPlanar) }
    }
    Benchmark("Planarity: findKuratowskiSubgraph(), K₃₀₀ (first 3n − 5 pairs)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(k300.findKuratowskiSubgraph()) }
    }
    let grid = graph(316 * 316, gridEdges(316))
    Benchmark("Planarity: isOuterplanar, grid 316 × 316") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.isOuterplanar) }
    }
}
