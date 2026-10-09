import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Cycles
import GraphProtocols
import Walks

/// Johnson by hand: every simple cycle counted from each start s over the vertices ≥ s, with
/// blocking and B-lists, over `[[Int]]` rows, iteratively, no decomposition and no cycle values.
/// The floor for CY-B01.
func handWrittenJohnsonCount(_ rows: [[Int]]) -> Int {
    let n = rows.count
    var blocked = [Bool](repeating: false, count: n)
    var b = [[Int]](repeating: [], count: n)
    var count = 0
    var path: [Int] = [], cursor: [Int] = [], found: [Bool] = []
    for s in 0 ..< n {
        for v in s ..< n {
            blocked[v] = false
            b[v].removeAll(keepingCapacity: true)
        }
        path = [s]
        cursor = [0]
        found = [false]
        blocked[s] = true
        while let v = path.last {
            let d = path.count - 1
            if cursor[d] < rows[v].count {
                let w = rows[v][cursor[d]]
                cursor[d] += 1
                if w < s { continue }
                if w == s {
                    count += 1
                    found[d] = true
                } else if !blocked[w] {
                    path.append(w)
                    cursor.append(0)
                    found.append(false)
                    blocked[w] = true
                }
            } else {
                path.removeLast()
                cursor.removeLast()
                let f = found.removeLast()
                if d > 0, f { found[d - 1] = true }
                if f {
                    var stack = [v]
                    while let x = stack.popLast() {
                        guard blocked[x] else { continue }
                        blocked[x] = false
                        stack.append(contentsOf: b[x].filter { blocked[$0] })
                        b[x].removeAll(keepingCapacity: true)
                    }
                } else {
                    for w in rows[v] where w >= s && !b[w].contains(v) { b[w].append(v) }
                }
            }
        }
    }
    return count
}

/// Undirected cycle detection by hand: a depth-first search over `UndirectedAdjacencyList`'s
/// index rows, skipping the parent edge, stopping at the first edge back to the path; the
/// cycle's length. The floor for CY-B03.
func handWrittenFindCycle(_ graph: UndirectedAdjacencyList<Int>) -> Int? {
    let n = graph.vertexCount
    var depth = [Int](repeating: -1, count: n)
    var stack: [(v: Int, k: Int, e: Int)] = []
    for root in 0 ..< n where depth[root] < 0 {
        depth[root] = 0
        stack.append((root, 0, -1))
        while let (v, k, parent) = stack.last {
            let row = graph.neighborIndices(ofIndex: v)
            guard k < row.count else {
                depth[v] = -2
                stack.removeLast()
                continue
            }
            stack[stack.count - 1].k = k + 1
            let edges = graph.incidentEdges(ofIndex: v)
            let e = edges[edges.startIndex + k]
            if e == parent { continue }
            let w = row[row.startIndex + k]
            if depth[w] >= 0 { return depth[v] - depth[w] + 1 }
            if depth[w] == -1 {
                depth[w] = depth[v] + 1
                stack.append((w, 0, e))
            }
        }
    }
    return nil
}

/// Forest test by hand: union–find with path halving over `edges`, by index. The floor for
/// CY-B04.
func handWrittenIsForest(_ graph: UndirectedAdjacencyList<Int>) -> Bool {
    var parent = Array(0 ..< graph.vertexCount)
    func find(_ x: Int) -> Int {
        var x = x
        while parent[x] != x {
            parent[x] = parent[parent[x]]
            x = parent[x]
        }
        return x
    }
    for e in graph.edges {
        let a = find(graph.vertexIndex(of: e.u)), b = find(graph.vertexIndex(of: e.v))
        if a == b { return false }
        parent[a] = b
    }
    return true
}

/// Girth by hand: a breadth-first search from every vertex over `[[(Int, Int)]]` rows, skipping
/// the parent edge, with the same depth bound. The floor for CY-B06.
func handWrittenGirth(_ rows: [[(w: Int, e: Int)]]) -> Int? {
    let n = rows.count
    var best = Int.max
    var root = [Int](repeating: -1, count: n), dist = [Int](repeating: 0, count: n), parent = [Int](repeating: -1, count: n)
    var queue: [Int] = []
    for r in 0 ..< n {
        root[r] = r
        dist[r] = 0
        parent[r] = -1
        queue.removeAll(keepingCapacity: true)
        queue.append(r)
        var head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            if 2 * dist[v] >= best { break }
            for (w, e) in rows[v] where e != parent[v] {
                if root[w] == r {
                    best = min(best, dist[v] + dist[w] + 1)
                } else {
                    root[w] = r
                    dist[w] = dist[v] + 1
                    parent[w] = e
                    queue.append(w)
                }
            }
        }
    }
    return best == .max ? nil : best
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A sparse random digraph with many cycles: G(40, 100).
    let small = Inputs.randomEdges(vertexCount: 40, edgeCount: 100, seed: 7).filter { $0.source != $0.target }
    let digraph = AdjacencyList(vertices: 0 ..< 40, edges: small)
    let rows = (0 ..< 40).map { Array(digraph.successorIndices(ofIndex: $0)) }
    let cycleCount = handWrittenJohnsonCount(rows)
    precondition(digraph.simpleCycles().reduce(0) { n, _ in n + 1 } == cycleCount)

    // A 300 × 300 grid: its 4- and 6-cycles, bounded.
    let side = 300
    let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: (0 ..< side * side).flatMap { v -> [UndirectedEdge<Int>] in
        var out: [UndirectedEdge<Int>] = []
        if v % side + 1 < side { out.append(UndirectedEdge(v, v + 1)) }
        if v + side < side * side { out.append(UndirectedEdge(v, v + side)) }
        return out
    })

    // A random tree on 10⁶ vertices, and the same with one extra edge at the end.
    let n = 1_000_000
    let treeEdges = (1 ..< n).map { UndirectedEdge($0, Int((UInt64($0) &* 0x9E37_79B9_7F4A_7C15) >> 20) % $0) }
    let tree = UndirectedAdjacencyList(vertices: 0 ..< n, edges: treeEdges)
    let almost = UndirectedAdjacencyList(vertices: 0 ..< n, edges: treeEdges + [UndirectedEdge(n - 1, n - 2)])
    precondition(tree.isAcyclic && handWrittenIsForest(tree) && tree.findCycle() == nil && handWrittenFindCycle(tree) == nil)
    precondition(almost.findCycle()?.length == handWrittenFindCycle(almost))

    // G(10⁵, 1.2·10⁵) for the cycle basis; G(2000, 3000) for girth.
    var seen = Set<UndirectedEdge<Int>>()
    let pairs = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 130_000)
        .map { UndirectedEdge($0.source, $0.target) }
        .filter { !$0.isSelfLoop && seen.insert($0).inserted }
    let sparse = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: Array(pairs.prefix(120_000)))
    var seenSmall = Set<UndirectedEdge<Int>>()
    let girthPairs = Inputs.randomEdges(vertexCount: 2000, edgeCount: 3200, seed: 3)
        .map { UndirectedEdge($0.source, $0.target) }
        .filter { !$0.isSelfLoop && seenSmall.insert($0).inserted }
    let girthGraph = UndirectedAdjacencyList(vertices: 0 ..< 2000, edges: Array(girthPairs.prefix(3000)))
    let girthRows = (0 ..< 2000).map { v in Array(zip(girthGraph.neighborIndices(ofIndex: v), girthGraph.incidentEdges(ofIndex: v))).map { (w: $0.0, e: $0.1) } }
    precondition(girthGraph.girth() == handWrittenGirth(girthRows))
    let girthDigraph = AdjacencyList(vertices: 0 ..< 2000, edges: Inputs.randomEdges(vertexCount: 2000, edgeCount: 3000, seed: 3).filter { $0.source != $0.target })

    // CY-B01: enumeration against hand-written Johnson.
    Benchmark("Cycles: BASELINE hand-written Johnson count, G(40, 100) (\(cycleCount) cycles)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenJohnsonCount(rows)) }
    }
    Benchmark("Cycles: directed simpleCycles count, G(40, 100)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(digraph.simpleCycles().reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cycles: directed simpleCycles(maxLength: 6), G(40, 100)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(digraph.simpleCycles(maxLength: 6).reduce(0) { n, _ in n + 1 }) }
    }
    // CY-B02: bounded undirected enumeration.
    Benchmark("Cycles: undirected simpleCycles(maxLength: 6), 300 × 300 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.simpleCycles(maxLength: 6).reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Cycles: undirected simpleCycles().first, 300 × 300 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.simpleCycles().first { _ in true }) }
    }
    // CY-B03: findCycle on a large tree (the whole graph) and with one cycle at the end.
    Benchmark("Cycles: BASELINE hand-written findCycle, 10⁶ tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenFindCycle(tree)) }
    }
    Benchmark("Cycles: findCycle, 10⁶ tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.findCycle()) }
    }
    Benchmark("Cycles: findCycle, 10⁶ tree plus one edge") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(almost.findCycle()) }
    }
    // CY-B04: isAcyclic.
    Benchmark("Cycles: BASELINE hand-written union–find forest test, 10⁶ tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenIsForest(tree)) }
    }
    Benchmark("Cycles: isAcyclic, 10⁶ tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.isAcyclic) }
    }
    // CY-B05: the cycle basis.
    Benchmark("Cycles: cycleBasis, G(10⁵, 1.2·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.cycleBasis()) }
    }
    // CY-B06: girth.
    Benchmark("Cycles: BASELINE hand-written girth, G(2000, 3000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenGirth(girthRows)) }
    }
    Benchmark("Cycles: girth, G(2000, 3000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(girthGraph.girth()) }
    }
    Benchmark("Cycles: directed girth, G(2000, 3000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(girthDigraph.girth()) }
    }
}
