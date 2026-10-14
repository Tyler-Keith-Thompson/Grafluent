import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Connectivity
import GraphProtocols

/// k-edge-connected classes by hand over flat rows (`offsets`, `targets`, the edge of each slot):
/// unit-capacity flows by breadth-first augmenting paths, capped at k, each joining a vertex to
/// the source's class or splitting the rest by the cut. The baseline for CN-B10.
func handWrittenEdgeClasses(_ offsets: [Int], _ targets: [Int], _ slotEdge: [Int], edgeCount: Int, k: Int) -> Int {
    let n = offsets.count - 1
    var flow = [Int8](repeating: 0, count: edgeCount)
    var seen = [Int](repeating: 0, count: n), parent = [Int](repeating: 0, count: n), via = [Int](repeating: 0, count: n)
    var epoch = 0
    var queue: [Int] = []
    func maximumFlow(_ s: Int, _ t: Int) -> Int {
        for e in 0 ..< edgeCount { flow[e] = 0 }
        var value = 0
        while value < k {
            epoch += 1
            seen[s] = epoch
            queue.removeAll(keepingCapacity: true)
            queue.append(s)
            var head = 0, reached = false
            search: while head < queue.count {
                let x = queue[head]
                head += 1
                for slot in offsets[x] ..< offsets[x + 1] {
                    let y = targets[slot]
                    let forward: Int8 = x < y ? 1 : -1
                    guard seen[y] != epoch, flow[slotEdge[slot]] != forward else { continue }
                    seen[y] = epoch
                    parent[y] = x
                    via[y] = slot
                    if y == t { reached = true; break search }
                    queue.append(y)
                }
            }
            guard reached else { return value }
            var y = t
            while y != s {
                let x = parent[y]
                flow[slotEdge[via[y]]] += x < y ? 1 : -1
                y = x
            }
            value += 1
        }
        return value
    }
    var classes = 0
    var work: [([Int], Int)] = [(Array(1 ..< n), 0)]
    while let (group, s) = work.popLast() {
        var left = group
        while let t = left.popLast() {
            if maximumFlow(s, t) >= k { continue }
            work.append((left.filter { seen[$0] != epoch }, t))
            left = left.filter { seen[$0] == epoch }
        }
        classes += 1
    }
    return classes
}

func edgeConnectivityBenchmarks() {
    // CN-B10: k-edge-connected components and subgraphs on G(2000, 8000).
    let n = 2000
    var seen = Set<UndirectedEdge<Int>>()
    let pairs = Inputs.randomEdges(vertexCount: n, edgeCount: 8000, seed: 11).map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted }
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    var offsets = [0], targets: [Int] = [], slotEdge: [Int] = []
    var rows = [[(Int, Int)]](repeating: [], count: n)
    for (e, edge) in pairs.enumerated() {
        rows[edge.u].append((edge.v, e))
        rows[edge.v].append((edge.u, e))
    }
    for v in 0 ..< n {
        for (w, e) in rows[v] {
            targets.append(w)
            slotEdge.append(e)
        }
        offsets.append(targets.count)
    }
    precondition(handWrittenEdgeClasses(offsets, targets, slotEdge, edgeCount: pairs.count, k: 3) == graph.kEdgeConnectedComponents(3).count)
    Benchmark("Connectivity: BASELINE hand-written 3-edge-connected classes, G(2000, 8000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenEdgeClasses(offsets, targets, slotEdge, edgeCount: pairs.count, k: 3)) }
    }
    Benchmark("Connectivity: kEdgeConnectedComponents(3), G(2000, 8000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.kEdgeConnectedComponents(3)) }
    }
    Benchmark("Connectivity: kEdgeConnectedSubgraphs(3), G(2000, 8000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.kEdgeConnectedSubgraphs(3)) }
    }
    Benchmark("Connectivity: kEdgeConnectedComponents(5), G(2000, 8000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(graph.kEdgeConnectedComponents(5)) }
    }
    var kept = Set<UndirectedEdge<Int>>()
    let cohesive = UndirectedAdjacencyList(vertices: 0 ..< 300, edges: Inputs.randomEdges(vertexCount: 300, edgeCount: 1500, seed: 12)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && kept.insert($0).inserted })
    Benchmark("Connectivity: kComponents(), G(300, 1500)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(cohesive.kComponents()) }
    }
}
