import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import Traversal

/// An adjacency list without its own successorIndices, so a search maps each neighbor back to
/// its index through a hash.
struct WithoutSuccessorIndices: DirectedGraph {
    let base: AdjacencyList<Int>
    var vertices: AdjacencyList<Int>.Vertices { base.vertices }
    var edges: AdjacencyList<Int>.Edges { base.edges }
    func successors(of vertex: Int) -> AdjacencyList<Int>.Neighbors { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> ArraySlice<Int> { base.outEdges(of: vertex) }
    var vertexCount: Int { base.vertexCount }
    var edgeCount: Int { base.edgeCount }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
    func contains(edge: DirectedEdge<Int>) -> Bool { base.contains(edge: edge) }
    func outDegree(of vertex: Int) -> Int { base.outDegree(of: vertex) }
    var vertexIndexBound: Int? { base.vertexIndexBound }
    func vertexIndex(of vertex: Int) -> Int { base.vertexIndex(of: vertex) }
    func vertex(atIndex index: Int) -> Int { base.vertex(atIndex: index) }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000)
    let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
    let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
    let listWithoutIndices = WithoutSuccessorIndices(base: list)
    let named = AdjacencyList(vertices: (0 ..< n).map { "v\($0)" }, edges: edges.map { DirectedEdge(from: "v\($0.source)", to: "v\($0.target)") })
    let path = CompressedSparseRow(vertexCount: 1_000_000, edges: (0 ..< 999_999).map { DirectedEdge(from: $0, to: $0 + 1) })

    // TR-B01: the event sequence against a hand-written breadth-first search.
    Benchmark("Traversal: BASELINE hand-written BFS on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited = [Bool](repeating: false, count: n)
            visited[0] = true
            var queue = [0]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in sparse.successors(of: v) where !visited[w] {
                    visited[w] = true
                    queue.append(w)
                }
            }
            blackHole(queue.count)
        }
    }
    Benchmark("Traversal: breadthFirstSearch events on CompressedSparseRow, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            sparse.lazy.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: depthFirstSearch events on CompressedSparseRow, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            sparse.lazy.depthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: BASELINE hand-written iterative DFS on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited = [Bool](repeating: false, count: n)
            var stack: [(Int, Int)] = [(0, sparse.offsets[0])]
            visited[0] = true
            var discovered = 1
            while let (v, k) = stack.last {
                if k == sparse.offsets[v + 1] {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 = k + 1
                let w = sparse.targets[k]
                if !visited[w] {
                    visited[w] = true
                    discovered += 1
                    stack.append((w, sparse.offsets[w]))
                }
            }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstSearch on AdjacencyList<String>, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            named.lazy.breadthFirstSearch(from: "v0").forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstSearch events on CompressedSparseRow, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in sparse.lazy.breadthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstLayers on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.breadthFirstLayers(from: 0)) }
    }
    Benchmark("Traversal: breadthFirstTree on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.breadthFirstTree(from: 0)) }
    }
    Benchmark("Traversal: depthFirstTree on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.depthFirstTree(from: 0)) }
    }
    Benchmark("Traversal: descendants on AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.descendants(of: 0)) }
    }
    Benchmark("Traversal: depthFirstSearch events on CompressedSparseRow, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in sparse.lazy.depthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }

    // TR-B02: index-based adjacency on an adjacency list.
    Benchmark("Traversal: breadthFirstSearch on AdjacencyList, with successorIndices") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in list.lazy.breadthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstSearch on AdjacencyList, mapping each neighbor to its index") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in listWithoutIndices.lazy.breadthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }

    Benchmark("Traversal: topologicalSort of a 1M-vertex path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.topologicalSort()) }
    }
    Benchmark("Traversal: topologicalGenerations of a 1M-vertex path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.topologicalGenerations()) }
    }
    Benchmark("Traversal: kahnEvents, every event, of a 1M-vertex path") { benchmark in
        for _ in benchmark.scaledIterations {
            var emitted = 0
            for case .emit in path.lazy.kahn() { emitted &+= 1 }
            blackHole(emitted)
        }
    }

    // TR-B05: the explicit stack on a deep graph.
    Benchmark("Traversal: depth-first preorder of a 1M-vertex path") { benchmark in
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in path.lazy.depthFirstSearch(from: 0).preorder { count += 1 }
            blackHole(count)
        }
    }

    Benchmark("Traversal: findCycle on a random graph with 1M edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.findCycle()) }
    }

    // TR-B06: the edge-position searches, against the endpoint searches above and against
    // hand-written edge-position loops over the flat rows (the position is the slot on CSR; on
    // AdjacencyList it is read from the pool beside the targets).
    Benchmark("Traversal: BASELINE hand-written edge-position DFS on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            let sum = sparse.withUnsafeBufferPointers { offsets, targets in
                var order = [Int](repeating: -1, count: n)
                var finished = [Bool](repeating: false, count: n)
                var stack: [(Int, Int)] = [(0, offsets[0])]
                order[0] = 0
                var discoveries = 1
                var sum = 0
                while let (v, k) = stack.last {
                    if k == offsets[v + 1] {
                        stack.removeLast()
                        finished[v] = true
                        continue
                    }
                    stack[stack.count - 1].1 = k + 1
                    let w = targets[k]
                    if order[w] < 0 {
                        order[w] = discoveries
                        discoveries += 1
                        sum &+= k
                        stack.append((w, offsets[w]))
                    } else {
                        sum &+= !finished[w] ? 1 : order[w] > order[v] ? 2 : 3
                    }
                }
                return sum
            }
            blackHole(sum)
        }
    }
    Benchmark("Traversal: BASELINE hand-written edge-position BFS on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            let sum = sparse.withUnsafeBufferPointers { offsets, targets in
                var depth = [Int](repeating: -1, count: n)
                depth[0] = 0
                var queue = [0]
                var head = 0
                var sum = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for k in offsets[v] ..< offsets[v + 1] {
                        let w = targets[k]
                        if depth[w] < 0 {
                            depth[w] = depth[v] + 1
                            queue.append(w)
                        }
                        sum &+= k
                    }
                }
                return sum
            }
            blackHole(sum)
        }
    }
    Benchmark("Traversal: BASELINE hand-written edge-position BFS on AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations {
            let sum = list._withOutIndexRows { targets, targetRows, edges, edgeRows in
                var depth = [Int](repeating: -1, count: n)
                depth[0] = 0
                var queue = [0]
                var head = 0
                var sum = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    let (start, length, edgeStart) = (targetRows[3 * v], targetRows[3 * v + 1], edgeRows[3 * v])
                    for i in 0 ..< length {
                        let w = targets[start + i]
                        if depth[w] < 0 {
                            depth[w] = depth[v] + 1
                            queue.append(w)
                        }
                        sum &+= edges[edgeStart + i]
                    }
                }
                return sum
            }
            blackHole(sum)
        }
    }
    func edgeBenchmarks<G: DirectedGraph & Sendable>(_ name: String, _ g: G) where G.Vertex == Int, G.Edges.Index == Int {
        Benchmark("Traversal: edgeBreadthFirstSearch on \(name), pulled with for-in") { benchmark in
            for _ in benchmark.scaledIterations {
                var positions = 0
                for case .treeEdge(let e) in g.lazy.edgeBreadthFirstSearch(from: 0) { positions &+= e }
                blackHole(positions)
            }
        }
        Benchmark("Traversal: edgeBreadthFirstSearch on \(name), pushed with forEach") { benchmark in
            for _ in benchmark.scaledIterations {
                var positions = 0
                g.lazy.edgeBreadthFirstSearch(from: 0).forEach { if case .treeEdge(let e) = $0 { positions &+= e } }
                blackHole(positions)
            }
        }
        Benchmark("Traversal: edgeDepthFirstSearch on \(name), pulled with for-in") { benchmark in
            for _ in benchmark.scaledIterations {
                var positions = 0
                for case .treeEdge(let e) in g.lazy.edgeDepthFirstSearch(from: 0) { positions &+= e }
                blackHole(positions)
            }
        }
        Benchmark("Traversal: edgeDepthFirstSearch on \(name), pushed with forEach") { benchmark in
            for _ in benchmark.scaledIterations {
                var positions = 0
                g.lazy.edgeDepthFirstSearch(from: 0).forEach { if case .treeEdge(let e) = $0 { positions &+= e } }
                blackHole(positions)
            }
        }
    }
    edgeBenchmarks("CompressedSparseRow", sparse)
    edgeBenchmarks("AdjacencyList", list)
    Benchmark("Traversal: depthFirstSearch on AdjacencyList, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in list.lazy.depthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: depthFirstSearch on AdjacencyList, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            list.lazy.depthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstSearch on AdjacencyList, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            list.lazy.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    let undirected = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.source, $0.target) })
    Benchmark("Traversal: edgeDepthFirstSearch on UndirectedAdjacencyList, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var positions = 0
            for case .treeEdge(let e) in undirected.lazy.edgeDepthFirstSearch(from: 0) { positions &+= e }
            blackHole(positions)
        }
    }
    Benchmark("Traversal: edgeDepthFirstSearch on UndirectedAdjacencyList, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var positions = 0
            undirected.lazy.edgeDepthFirstSearch(from: 0).forEach { if case .treeEdge(let e) = $0 { positions &+= e } }
            blackHole(positions)
        }
    }
    Benchmark("Traversal: depthFirstSearch on the directedView of UndirectedAdjacencyList, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in undirected.directedView.lazy.depthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: depthFirstSearch on the directedView of UndirectedAdjacencyList, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            undirected.directedView.lazy.depthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }

    // TR-B07: allSimplePaths against a hand-written iterative enumeration over the flat rows: the
    // 10 × 10 grid DAG (edges right and down), whose 48 620 corner-to-corner paths all reach the
    // target, and G(12, 40), whose paths mostly do not.
    let side = 10
    var gridArcs: [DirectedEdge<Int>] = []
    for v in 0 ..< side * side {
        if v % side + 1 < side { gridArcs.append(DirectedEdge(from: v, to: v + 1)) }
        if v + side < side * side { gridArcs.append(DirectedEdge(from: v, to: v + side)) }
    }
    let gridDAG = CompressedSparseRow(vertexCount: side * side, edges: gridArcs)
    let dense = CompressedSparseRow(vertexCount: 12, edges: Inputs.randomEdges(vertexCount: 12, edgeCount: 40, seed: 5))
    func rows(_ g: CompressedSparseRow) -> (offsets: [Int], targets: [Int]) {
        var offsets = [0], targets: [Int] = []
        for v in 0 ..< g.vertexCount {
            targets += g.successorIndices(ofIndex: v)
            offsets.append(targets.count)
        }
        return (offsets, targets)
    }
    /// Every simple path from `s` to `t` counted by an iterative DFS with integer cursors.
    func handWrittenPathCount(_ r: (offsets: [Int], targets: [Int]), _ s: Int, _ t: Int) -> Int {
        var onPath = [Bool](repeating: false, count: r.offsets.count - 1)
        var path = [s], cursor = [r.offsets[s]]
        onPath[s] = true
        var count = 0
        while let u = path.last {
            let k = cursor[cursor.count - 1]
            if k < r.offsets[u + 1] {
                cursor[cursor.count - 1] = k + 1
                let w = r.targets[k]
                if onPath[w] { continue }
                if w == t {
                    count += 1
                    continue
                }
                onPath[w] = true
                path.append(w)
                cursor.append(r.offsets[w])
            } else {
                onPath[u] = false
                path.removeLast()
                cursor.removeLast()
            }
        }
        return count
    }
    let gridRows = rows(gridDAG), denseRows = rows(dense)
    precondition(handWrittenPathCount(gridRows, 0, side * side - 1) == gridDAG.allSimplePaths(from: 0, to: side * side - 1).reduce(0) { n, _ in n + 1 })
    precondition(handWrittenPathCount(denseRows, 0, 11) == dense.allSimplePaths(from: 0, to: 11).reduce(0) { n, _ in n + 1 })
    Benchmark("Traversal: BASELINE hand-written simple path count, 10 × 10 grid DAG") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenPathCount(gridRows, 0, side * side - 1)) }
    }
    Benchmark("Traversal: allSimplePaths count, 10 × 10 grid DAG") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(gridDAG.allSimplePaths(from: 0, to: side * side - 1).reduce(0) { n, _ in n + 1 }) }
    }
    Benchmark("Traversal: BASELINE hand-written simple path count, G(12, 40)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenPathCount(denseRows, 0, 11)) }
    }
    Benchmark("Traversal: allSimplePaths count, G(12, 40)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(dense.allSimplePaths(from: 0, to: 11).reduce(0) { n, _ in n + 1 }) }
    }

    // TR-B08: random walks of 10⁵ steps against a hand-written walk over the flat rows drawing
    // the same bits.
    let walkRows = rows(sparse)
    func handWrittenWalk(_ r: (offsets: [Int], targets: [Int]), from s: Int, length: Int, seed: UInt) -> Int {
        var generator = SeededRandomNumberGenerator(seed: seed)
        var u = s, sum = 0
        for _ in 0 ..< length {
            let d = r.offsets[u + 1] - r.offsets[u]
            if d == 0 { break }
            let shift = UInt64(d.leadingZeroBitCount)
            var k = d
            while k >= d { k = Int(truncatingIfNeeded: generator.next() >> shift) }
            u = r.targets[r.offsets[u] + k]
            sum &+= u
        }
        return sum
    }
    var check = SeededRandomNumberGenerator(seed: 9)
    precondition(handWrittenWalk(walkRows, from: 0, length: 1000, seed: 9) == sparse.randomWalk(from: 0, length: 1000, using: &check).vertices.dropFirst().reduce(0, &+))
    Benchmark("Traversal: BASELINE hand-written random walk, 10⁵ steps, CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenWalk(walkRows, from: 0, length: 100_000, seed: 9)) }
    }
    Benchmark("Traversal: randomWalk, 10⁵ steps, CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 9)
            blackHole(sparse.randomWalk(from: 0, length: 100_000, using: &generator))
        }
    }
    Benchmark("Traversal: randomWalk, 10⁵ steps, AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 9)
            blackHole(list.randomWalk(from: 0, length: 100_000, using: &generator))
        }
    }
    Benchmark("Traversal: randomWalk weighted, 10⁵ steps, CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 9)
            blackHole(sparse.randomWalk(from: 0, length: 100_000, weight: { Double($0 & 7) + 1 }, using: &generator))
        }
    }
    Benchmark("Traversal: randomWalk node2vec (p 0.5, q 2), 10⁵ steps, UndirectedAdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations {
            var generator = SeededRandomNumberGenerator(seed: 9)
            blackHole(undirected.randomWalk(from: 0, length: 100_000, returnParameter: 0.5, inOutParameter: 2, using: &generator))
        }
    }

    // TR-B09: allTopologicalSorts of 9 vertices, two chains of 3 and 3 free (60 480 orders),
    // against a hand-written backtracking count.
    let poset = CompressedSparseRow(vertexCount: 9, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5)])
    let posetRows = rows(poset)
    func handWrittenOrderCount(_ r: (offsets: [Int], targets: [Int])) -> Int {
        let n = r.offsets.count - 1
        var inDegree = [Int](repeating: 0, count: n)
        for w in r.targets { inDegree[w] += 1 }
        var placed = [Bool](repeating: false, count: n)
        var depth = 0, count = 0
        var cursor = [Int](repeating: -1, count: n + 1)
        var chosen = [Int](repeating: -1, count: n)
        while depth >= 0 {
            if depth == n {
                count += 1
                depth -= 1
                continue
            }
            if chosen[depth] >= 0 {
                let v = chosen[depth]
                placed[v] = false
                for k in r.offsets[v] ..< r.offsets[v + 1] { inDegree[r.targets[k]] += 1 }
                chosen[depth] = -1
            }
            var v = cursor[depth] + 1
            while v < n && (placed[v] || inDegree[v] != 0) { v += 1 }
            if v == n {
                cursor[depth] = -1
                depth -= 1
                continue
            }
            cursor[depth] = v
            chosen[depth] = v
            placed[v] = true
            for k in r.offsets[v] ..< r.offsets[v + 1] { inDegree[r.targets[k]] -= 1 }
            depth += 1
        }
        return count
    }
    precondition(handWrittenOrderCount(posetRows) == poset.allTopologicalSorts().reduce(0) { n, _ in n + 1 })
    Benchmark("Traversal: BASELINE hand-written topological order count, 9 vertices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenOrderCount(posetRows)) }
    }
    Benchmark("Traversal: allTopologicalSorts count, 9 vertices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(poset.allTopologicalSorts().reduce(0) { n, _ in n + 1 }) }
    }

    // TR-B10: lexicographic breadth-first and maximum cardinality search on
    // UndirectedAdjacencyList, G(10⁵, 10⁶), against a hand-written breadth-first search of the
    // same graph by index (the floor: LexBFS is a breadth-first search that also refines classes).
    Benchmark("Traversal: BASELINE hand-written BFS on UndirectedAdjacencyList, every component") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited = [Bool](repeating: false, count: n)
            var queue: [Int] = []
            queue.reserveCapacity(n)
            for root in 0 ..< n where !visited[root] {
                visited[root] = true
                queue.append(root)
                var head = queue.count - 1
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for w in undirected.neighborIndices(ofIndex: v) where !visited[w] {
                        visited[w] = true
                        queue.append(w)
                    }
                }
            }
            blackHole(queue.count)
        }
    }
    Benchmark("Traversal: lexicographicBreadthFirstSearch, UndirectedAdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.lexicographicBreadthFirstSearch()) }
    }
    Benchmark("Traversal: maximumCardinalitySearch, UndirectedAdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.maximumCardinalitySearch()) }
    }
}
