import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Trees
import Walks

/// Rooting by hand: parent, depth and preorder by an iterative depth-first search over flat
/// rows (offsets, neighbors), the floor for building a rooted tree from rows (TS-B01).
func handWrittenRooting(_ offsets: [Int], _ neighbors: [Int], root: Int) -> (parent: [Int], depth: [Int], preorder: [Int]) {
    let n = offsets.count - 1
    var parent = [Int](repeating: -1, count: n), depth = [Int](repeating: -1, count: n)
    var preorder: [Int] = []
    preorder.reserveCapacity(n)
    var stack: [(v: Int, k: Int)] = [(root, offsets[root])]
    depth[root] = 0
    preorder.append(root)
    while let (v, k) = stack.last {
        guard k < offsets[v + 1] else {
            stack.removeLast()
            continue
        }
        stack[stack.count - 1].k = k + 1
        let w = neighbors[k]
        if w == parent[v] || depth[w] >= 0 { continue }
        parent[w] = v
        depth[w] = depth[v] + 1
        preorder.append(w)
        stack.append((w, offsets[w]))
    }
    return (parent, depth, preorder)
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A random recursive tree on 10⁶ vertices, and a 10⁶ path.
    let n = 1_000_000
    let pairs = (1 ..< n).map { UndirectedEdge($0, Int((UInt64($0) &* 0x9E37_79B9_7F4A_7C15) >> 20) % $0) }
    let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
    let tree = Tree(list)!
    let rooted = RootedTree(tree, root: n / 2)
    let parents: [Int?] = (0 ..< n).map { rooted.parent(of: $0) }
    var offsets = [Int](repeating: 0, count: n + 1)
    for e in pairs {
        offsets[e.u + 1] += 1
        offsets[e.v + 1] += 1
    }
    for v in 0 ..< n { offsets[v + 1] += offsets[v] }
    var fill = offsets, neighbors = [Int](repeating: 0, count: 2 * (n - 1))
    for e in pairs {
        neighbors[fill[e.u]] = e.v
        fill[e.u] += 1
        neighbors[fill[e.v]] = e.u
        fill[e.v] += 1
    }
    precondition(handWrittenRooting(offsets, neighbors, root: n / 2).preorder.count == n)
    let code = tree.pruferSequence!
    let stringTree = Tree(edges: pairs.prefix(100_000).map { UndirectedEdge("v\($0.u)", "v\($0.v)") })!
    let forest = Forest(vertices: 0 ..< n, edges: pairs.enumerated().filter { $0.offset % 10 != 0 }.map(\.element))!

    // TS-B01: building.
    Benchmark("Trees: BASELINE hand-written rooting over flat rows, 10⁶ random tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenRooting(offsets, neighbors, root: n / 2)) }
    }
    Benchmark("Trees: Tree(UndirectedAdjacencyList), 10⁶ random tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree(list)) }
    }
    Benchmark("Trees: Tree(edges:), 10⁶ random tree (Int vertices by first appearance)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree(edges: pairs)) }
    }
    Benchmark("Trees: RootedTree(vertices:parent:) with String vertices, 10⁵") { benchmark in
        let names = (0 ..< 100_000).map { "v\($0)" }
        let parent: [String: String] = Dictionary(uniqueKeysWithValues: (1 ..< 100_000).map { ("v\($0)", "v\(Int((UInt64($0) &* 0x9E37_79B9_7F4A_7C15) >> 20) % $0)") })
        for _ in benchmark.scaledIterations { blackHole(RootedTree(vertices: names) { parent[$0] }) }
    }
    Benchmark("Trees: every tree of 10⁶ isolated vertices") { benchmark in
        let isolated = Forest(vertices: 0 ..< n, edges: [])!
        for _ in benchmark.scaledIterations { blackHole(isolated.trees.reduce(0) { $0 &+ $1.vertexCount }) }
    }
    Benchmark("Trees: Tree(vertices:edges:), 10⁶ random tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree(vertices: 0 ..< n, edges: pairs)) }
    }
    Benchmark("Trees: RootedTree(tree, root:), 10⁶ random tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(RootedTree(tree, root: n / 2)) }
    }
    Benchmark("Trees: RootedTree(parents:), 10⁶ random tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(RootedTree(parents: parents)) }
    }
    Benchmark("Trees: Tree(edges:) with String vertices, 10⁵") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree(edges: pairs.prefix(100_000).map { UndirectedEdge("v\($0.u)", "v\($0.v)") })) }
    }
    // TS-B02: recognition.
    Benchmark("Trees: isTree, UndirectedAdjacencyList of a 10⁶ random tree") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.isTree) }
    }
    Benchmark("Trees: Forest(vertices:edges:), 10⁶ vertices in 10⁵ trees") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Forest(vertices: 0 ..< n, edges: pairs.enumerated().filter { $0.offset % 10 != 0 }.map(\.element))) }
    }
    // TS-B03: queries.
    Benchmark("Trees: preorder, summed, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(rooted.preorder.reduce(0, &+)) }
    }
    Benchmark("Trees: postorder, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(rooted.postorder) }
    }
    Benchmark("Trees: children(of:) of every vertex, counted, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for v in 0 ..< n { total &+= rooted.children(of: v).count }
            blackHole(total)
        }
    }
    Benchmark("Trees: 1000 paths between random vertices, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for k in 0 ..< 1000 { total &+= rooted.path(from: (k &* 7919) % n, to: (k &* 104_729) % n).length }
            blackHole(total)
        }
    }
    Benchmark("Trees: isAncestor for 10⁶ pairs") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for v in 0 ..< n where rooted.isAncestor(n / 2, of: v) { total &+= 1 }
            blackHole(total)
        }
    }
    // TS-B04: Prüfer codes.
    Benchmark("Trees: pruferSequence, 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.pruferSequence) }
    }
    Benchmark("Trees: Tree(pruferSequence:), 10⁶") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(Tree(pruferSequence: code)) }
    }
    // TS-B05: a forest's trees.
    Benchmark("Trees: every tree of a forest of 10⁵ trees on 10⁶ vertices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(forest.trees.reduce(0) { $0 &+ $1.vertexCount }) }
    }
    Benchmark("Trees: equality of a 10⁵ String tree and a copy built again") { benchmark in
        let other = Tree(edges: pairs.prefix(100_000).map { UndirectedEdge("v\($0.u)", "v\($0.v)") })!
        for _ in benchmark.scaledIterations { blackHole(stringTree == other) }
    }
}
