import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import PriorityQueueModule
import SpanningTrees

/// Skew heaps with pending subtractions on flat `Int` arrays, for `handWrittenEdmonds`.
struct HandSkewHeaps {
    var key: [Int], pending: [Int], left: [Int], right: [Int]

    init(_ cost: [Int]) {
        key = cost
        pending = [Int](repeating: 0, count: cost.count)
        left = [Int](repeating: -1, count: cost.count)
        right = left
    }

    mutating func settle(_ x: Int) {
        let d = pending[x]
        if d == 0 { return }
        key[x] -= d
        if left[x] >= 0 { pending[left[x]] += d }
        if right[x] >= 0 { pending[right[x]] += d }
        pending[x] = 0
    }

    mutating func merge(_ a: Int, _ b: Int) -> Int {
        if a < 0 { return b }
        if b < 0 { return a }
        settle(a)
        settle(b)
        var top = a, other = b
        if key[b] < key[a] || (key[b] == key[a] && b < a) { swap(&top, &other) }
        let root = top
        while true {
            let r = right[top]
            right[top] = left[top]
            if r < 0 {
                left[top] = other
                return root
            }
            settle(r)
            if key[r] < key[other] || (key[r] == key[other] && r < other) {
                left[top] = r
                top = r
            } else {
                left[top] = other
                top = other
                other = r
            }
        }
    }
}

/// The root of `x` in a union–find without path compression.
func handFind(_ parent: [Int], _ x: Int) -> Int {
    var x = x
    while parent[x] != x { x = parent[x] }
    return x
}

/// Edmonds' algorithm by hand on flat `Int` arrays already gathered (the arcs into `root` and the
/// self-loops dropped): skew heaps with pending subtractions, a union–find with rollback, the
/// contraction walk and the expansion. The floor for ST-B05. Returns the total weight.
func handWrittenEdmonds(_ n: Int, _ root: Int, _ from: [Int], _ to: [Int], _ cost: [Int]) -> Int {
    var heaps = HandSkewHeaps(cost)
    var heap = [Int](repeating: -1, count: n)
    for e in cost.indices { heap[to[e]] = heaps.merge(heap[to[e]], e) }
    var parent = Array(0 ..< n), size = [Int](repeating: 1, count: n), history: [Int] = []
    var seen = [Int](repeating: -1, count: n)
    seen[root] = root
    var path = [Int](repeating: 0, count: n), walked = path, inArc = [Int](repeating: -1, count: n)
    var cycles: [(Int, Int, Int, Int)] = [], cycleArcs: [Int] = []
    for s in 0 ..< n where seen[s] < 0 {
        var u = s, count = 0
        while seen[u] < 0 {
            var h = heap[u]
            while h >= 0 {
                heaps.settle(h)
                if handFind(parent, from[h]) != u { break }
                h = heaps.merge(heaps.left[h], heaps.right[h])
            }
            if h < 0 { return -1 }
            heaps.pending[h] = heaps.key[h]
            heaps.settle(h)
            heap[u] = heaps.merge(heaps.left[h], heaps.right[h])
            walked[count] = h
            path[count] = u
            count += 1
            seen[u] = s
            u = handFind(parent, from[h])
            if seen[u] == s {
                var merged = -1
                let end = count, unions = history.count
                while true {
                    count -= 1
                    let w = path[count]
                    merged = heaps.merge(merged, heap[w])
                    var a = handFind(parent, u), b = handFind(parent, w)
                    if a == b { break }
                    if size[a] < size[b] { swap(&a, &b) }
                    size[a] += size[b]
                    parent[b] = a
                    history.append(b)
                }
                u = handFind(parent, u)
                heap[u] = merged
                seen[u] = -1
                cycles.append((u, unions, cycleArcs.count, cycleArcs.count + end - count))
                cycleArcs.append(contentsOf: walked[count ..< end])
            }
        }
        for i in 0 ..< count { inArc[handFind(parent, to[walked[i]])] = walked[i] }
    }
    for (vertex, unions, start, end) in cycles.reversed() {
        while history.count > unions {
            let b = history.removeLast()
            size[parent[b]] -= size[b]
            parent[b] = b
        }
        let entering = inArc[vertex]
        for e in cycleArcs[start ..< end] { inArc[handFind(parent, to[e])] = e }
        inArc[handFind(parent, to[entering])] = entering
    }
    var total = 0
    for v in 0 ..< n where inArc[v] >= 0 { total += cost[inArc[v]] }
    return total
}

/// Dijkstra by hand from every terminal at once on flat rows: the search Mehlhorn's Steiner tree
/// starts with, and the floor for ST-B06.
func handWrittenVoronoi(_ offsets: [Int], _ neighbor: [Int], _ weight: [Int], _ terminals: [Int]) -> Int {
    let n = offsets.count - 1
    var distance = [Int](repeating: .max, count: n)
    var queue = IndexedPriorityQueue<Int>(indexBound: n)
    for t in terminals {
        distance[t] = 0
        queue.insert(t, priority: 0)
    }
    var total = 0
    while let (u, d) = queue.popMin() {
        total &+= d
        for slot in offsets[u] ..< offsets[u + 1] {
            let v = neighbor[slot], nd = d + weight[slot]
            if nd < distance[v] {
                distance[v] = nd
                queue.insertOrDecreasePriority(of: v, to: nd)
            }
        }
    }
    return total
}

/// Wilson's algorithm by hand on flat rows: uniform steps by rejection on the top bits of each
/// draw, as the library draws. The floor for ST-B07. Returns the number of edges taken.
func handWrittenWilson(_ offsets: [Int], _ neighbor: [Int], _ generator: inout SeededRandomNumberGenerator) -> Int {
    let n = offsets.count - 1
    var inTree = [Bool](repeating: false, count: n)
    inTree[0] = true
    var next = [Int](repeating: -1, count: n)
    var taken = 0
    for start in 0 ..< n where !inTree[start] {
        var u = start
        while !inTree[u] {
            let d = offsets[u + 1] - offsets[u]
            let shift = UInt64(truncatingIfNeeded: d.leadingZeroBitCount)
            var r: Int
            repeat { r = Int(truncatingIfNeeded: generator.next() >> shift) } while r >= d
            next[u] = offsets[u] + r
            u = neighbor[next[u]]
        }
        u = start
        while !inTree[u] {
            inTree[u] = true
            taken += 1
            u = neighbor[next[u]]
        }
    }
    return taken
}

let arborescenceBenchmarks: @Sendable () -> Void = {
    // G(10⁵, 10⁶) directed, plus a Hamiltonian cycle so every vertex reaches every other, weights
    // 1…1000 by position.
    let n = 100_000
    var seen = Set<DirectedEdge<Int>>()
    let random = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000, seed: 7) + (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) }
    let pairs = random.filter { !$0.isSelfLoop && seen.insert($0).inserted }
    let digraph = AdjacencyList(vertices: 0 ..< n, edges: pairs)
    var generator = SeededRandomNumberGenerator(seed: 41)
    let weights = (0 ..< digraph.edgeCount).map { _ in Int.random(in: 1 ... 1000, using: &generator) }
    var from: [Int] = [], to: [Int] = [], cost: [Int] = []
    for (k, e) in digraph.edges.enumerated() where e.target != 0 {
        from.append(e.source)
        to.append(e.target)
        cost.append(weights[k])
    }
    let expected = handWrittenEdmonds(n, 0, from, to, cost)
    precondition(digraph.minimumSpanningArborescence(from: 0) { weights[$0] }?.weight == expected)
    precondition(digraph.minimumSpanningArborescence { weights[$0] }!.weight <= expected)

    // A 300 × 300 grid with weights 1…9 and 60 terminals.
    let side = 300
    let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: (0 ..< side * side).flatMap { v -> [UndirectedEdge<Int>] in
        var out: [UndirectedEdge<Int>] = []
        if v % side + 1 < side { out.append(UndirectedEdge(v, v + 1)) }
        if v + side < side * side { out.append(UndirectedEdge(v, v + side)) }
        return out
    })
    let gridWeights = (0 ..< grid.edgeCount).map { _ in Int.random(in: 1 ... 9, using: &generator) }
    let terminals = (0 ..< 60).map { _ in Int.random(in: 0 ..< side * side, using: &generator) }
    var offsets = [0], neighbor: [Int] = [], rowWeight: [Int] = []
    for v in 0 ..< grid.vertexCount {
        for (u, e) in zip(grid.neighborIndices(ofIndex: v), grid.incidentEdges(ofIndex: v)) {
            neighbor.append(u)
            rowWeight.append(gridWeights[e])
        }
        offsets.append(neighbor.count)
    }
    precondition(grid.steinerTree(terminals: terminals) { gridWeights[$0] } != nil)

    Benchmark("SpanningTrees: BASELINE hand-written Edmonds on flat arrays, G(10⁵, 10⁶) directed") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenEdmonds(n, 0, from, to, cost)) }
    }
    Benchmark("SpanningTrees: minimumSpanningArborescence(from:), G(10⁵, 10⁶) directed") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(digraph.minimumSpanningArborescence(from: 0) { weights[$0] }) }
    }
    Benchmark("SpanningTrees: minimumSpanningArborescence() over every root, G(10⁵, 10⁶) directed") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(digraph.minimumSpanningArborescence { weights[$0] }) }
    }
    Benchmark("SpanningTrees: maximumBranching, G(10⁵, 10⁶) directed") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(digraph.maximumBranching { weights[$0] }) }
    }
    Benchmark("SpanningTrees: BASELINE hand-written multi-source Dijkstra, 300 × 300 grid, 60 terminals") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenVoronoi(offsets, neighbor, rowWeight, terminals)) }
    }
    Benchmark("SpanningTrees: steinerTree (Mehlhorn), 300 × 300 grid, 60 terminals") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.steinerTree(terminals: terminals) { gridWeights[$0] }) }
    }
    Benchmark("SpanningTrees: kouSteinerTree, 300 × 300 grid, 60 terminals") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.kouSteinerTree(terminals: terminals) { gridWeights[$0] }) }
    }
    Benchmark("SpanningTrees: BASELINE hand-written Wilson on flat rows, 300 × 300 grid") { benchmark in
        var g = SeededRandomNumberGenerator(seed: 5)
        for _ in benchmark.scaledIterations { blackHole(handWrittenWilson(offsets, neighbor, &g)) }
    }
    Benchmark("SpanningTrees: randomSpanningTree, 300 × 300 grid") { benchmark in
        var g = SeededRandomNumberGenerator(seed: 5)
        for _ in benchmark.scaledIterations { blackHole(grid.randomSpanningTree(using: &g)) }
    }
    Benchmark("SpanningTrees: randomSpanningTree(weight:), 300 × 300 grid") { benchmark in
        var g = SeededRandomNumberGenerator(seed: 5)
        for _ in benchmark.scaledIterations { blackHole(grid.randomSpanningTree(weight: { Double(gridWeights[$0]) }, using: &g)) }
    }
}
