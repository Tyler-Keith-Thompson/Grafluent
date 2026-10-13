import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import BipartiteGraphs
import GraphProtocols

/// Two-colouring by hand over flat rows: the baseline for `isBipartite`.
func handWrittenIsBipartite(_ offsets: [Int], _ targets: [Int]) -> Bool {
    let n = offsets.count - 1
    var side = [Int8](repeating: -1, count: n)
    var queue = [Int](repeating: 0, count: n)
    var tail = 0
    for root in 0 ..< n where side[root] < 0 {
        side[root] = 0
        var head = tail
        queue[tail] = root
        tail += 1
        while head < tail {
            let v = queue[head]
            head += 1
            for k in offsets[v] ..< offsets[v + 1] {
                let w = targets[k]
                if side[w] < 0 {
                    side[w] = 1 - side[v]
                    queue[tail] = w
                    tail += 1
                } else if side[w] == side[v] {
                    return false
                }
            }
        }
    }
    return true
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A 700 × 700 grid (bipartite) and a random bipartite graph: 10⁵ + 10⁵ vertices, 5·10⁵ edges.
    var gridEdges: [UndirectedEdge<Int>] = []
    for r in 0 ..< 700 {
        for c in 0 ..< 700 {
            let v = r * 700 + c
            if c + 1 < 700 { gridEdges.append(UndirectedEdge(v, v + 1)) }
            if r + 1 < 700 { gridEdges.append(UndirectedEdge(v, v + 700)) }
        }
    }
    let grid = UndirectedAdjacencyList(vertices: 0 ..< 490_000, edges: gridEdges)
    var seen = Set<UndirectedEdge<Int>>()
    let random = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 500_000, seed: 31)
        .map { UndirectedEdge($0.source, 100_000 + $0.target) }.filter { seen.insert($0).inserted }
    let affiliation = UndirectedAdjacencyList(vertices: 0 ..< 200_000, edges: random)
    var go = [0], gt: [Int] = []
    for v in 0 ..< grid.vertexCount { gt.append(contentsOf: grid.neighborIndices(ofIndex: v)); go.append(gt.count) }
    precondition(handWrittenIsBipartite(go, gt) && grid.isBipartite)
    let bipartite = BipartiteGraph(affiliation)!
    // People (left, 10⁵) in groups (right, 2000): each person in 3 random groups.
    var memberships = Set<UndirectedEdge<Int>>()
    for (k, e) in Inputs.randomEdges(vertexCount: 100_000, edgeCount: 300_000, seed: 32).enumerated() {
        memberships.insert(UndirectedEdge(k / 3, 100_000 + e.target % 2000))
    }
    let groups = BipartiteGraph(left: 0 ..< 100_000, right: 100_000 ..< 102_000, edges: memberships)!

    Benchmark("BipartiteGraphs: BASELINE hand-written two-colouring, 700 × 700 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenIsBipartite(go, gt)) }
    }
    Benchmark("BipartiteGraphs: isBipartite, 700 × 700 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.isBipartite) }
    }
    Benchmark("BipartiteGraphs: bipartition(), 700 × 700 grid") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.bipartition()) }
    }
    Benchmark("BipartiteGraphs: BASELINE UndirectedAdjacencyList(vertices:edges:), 2·10⁵ vertices, 5·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< 200_000, edges: random)) }
    }
    Benchmark("BipartiteGraphs: BipartiteGraph(graph), 2·10⁵ vertices, 5·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(BipartiteGraph(affiliation)) }
    }
    let shuffledOrientation = UndirectedAdjacencyList(vertices: 0 ..< 200_000, edges: random.enumerated().map { $0.offset % 2 == 0 ? $0.element : UndirectedEdge($0.element.v, $0.element.u) })
    Benchmark("BipartiteGraphs: BipartiteGraph(graph), half the edges stored right end first") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(BipartiteGraph(shuffledOrientation)) }
    }
    Benchmark("BipartiteGraphs: BipartiteGraph(left:right:edges:), 2·10⁵ vertices, 5·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(BipartiteGraph(left: 0 ..< 100_000, right: 100_000 ..< 200_000, edges: random)) }
    }
    Benchmark("BipartiteGraphs: == of a copy, 2·10⁵ vertices, 5·10⁵ edges") { benchmark in
        let copy = bipartite
        for _ in benchmark.scaledIterations { blackHole(copy == bipartite) }
    }
    Benchmark("BipartiteGraphs: isBipartite on a BipartiteGraph, 2·10⁵ vertices, 5·10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(bipartite.isBipartite) }
    }
    Benchmark("BipartiteGraphs: projectedGraph(onto: .right), 10⁵ people in 2000 groups") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(groups.projectedGraph(onto: .right)) }
    }

    // Attached maps (the base's): inserting the affiliation graph's 5·10⁵ edges one at a time with
    // 0 and 2 maps (an edge Double, a vertex Int), against the caller appending to two side arrays;
    // then removing 10⁴ vertices, each with its edges, with 0 and 2 maps.
    func inserted(maps: Bool) -> BipartiteGraph<Int> {
        var graph = BipartiteGraph(left: 0 ..< 100_000, right: 100_000 ..< 200_000)!
        graph.reserveCapacity(vertexCount: 200_000, edgeCount: random.count)
        if maps {
            _ = graph.addEdgeMap(default: 1.0)
            _ = graph.addVertexMap(default: 0)
        }
        for e in random { _ = try! graph.insert(edge: e) }
        return graph
    }
    Benchmark("BipartiteGraphs: insert(edge:) 5·10⁵ edges, 0 maps") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(inserted(maps: false)) }
    }
    Benchmark("BipartiteGraphs: insert(edge:) 5·10⁵ edges, 2 maps") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(inserted(maps: true)) }
    }
    Benchmark("BipartiteGraphs: BASELINE insert(edge:) 5·10⁵ edges, 0 maps and hand-maintained side arrays") { benchmark in
        // The caller's own graph type keeps the side arrays, inside its insertion, as the base keeps its maps.
        struct SideArrayGraph {
            var graph: BipartiteGraph<Int>
            var weights: [Double] = []
            var ranks = [Int](repeating: 0, count: 200_000)
            mutating func insert(edge: UndirectedEdge<Int>) {
                if try! graph.insert(edge: edge).inserted { weights.append(1.0) }
            }
        }
        for _ in benchmark.scaledIterations {
            var built = SideArrayGraph(graph: BipartiteGraph(left: 0 ..< 100_000, right: 100_000 ..< 200_000)!)
            built.graph.reserveCapacity(vertexCount: 200_000, edgeCount: random.count)
            built.weights.reserveCapacity(random.count)
            for e in random { built.insert(edge: e) }
            blackHole(built)
        }
    }
    let plain = inserted(maps: false)
    let mapped = inserted(maps: true)
    Benchmark("BipartiteGraphs: remove(_:) 10⁴ vertices with their edges, 0 maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var graph = plain
            for v in stride(from: 0, to: 200_000, by: 20) { graph.remove(v) }
            blackHole(graph)
        }
    }
    Benchmark("BipartiteGraphs: remove(_:) 10⁴ vertices with their edges, 2 maps") { benchmark in
        for _ in benchmark.scaledIterations {
            var graph = mapped
            for v in stride(from: 0, to: 200_000, by: 20) { graph.remove(v) }
            blackHole(graph)
        }
    }
}
