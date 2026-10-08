import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphProtocols
import Traversal

/// An adjacency list without its own successorIndices, so a search maps each neighbor back to
/// its index through a hash: what every traversal paid before index-based adjacency.
struct WithoutSuccessorIndices: DirectedGraph {
    let base: AdjacencyList<Int>
    var vertices: AdjacencyList<Int>.Vertices { base.vertices }
    var edges: AdjacencyList<Int>.Edges { base.edges }
    func successors(of vertex: Int) -> AdjacencyList<Int>.Neighbors { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> LazyMapCollection<Range<Int>, AdjacencyList<Int>.Edges.Index> { base.outEdges(of: vertex) }
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
            sparse.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: depthFirstSearch events on CompressedSparseRow, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            sparse.depthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
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
            named.breadthFirstSearch(from: "v0").forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstSearch events on CompressedSparseRow, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in sparse.breadthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstLayers on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.breadthFirstLayers(from: 0)) }
    }
    Benchmark("Traversal: descendants on AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.descendants(of: 0)) }
    }
    Benchmark("Traversal: depthFirstSearch events on CompressedSparseRow, pulled with for-in") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in sparse.depthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }

    // TR-B02: index-based adjacency on an adjacency list.
    Benchmark("Traversal: breadthFirstSearch on AdjacencyList, with successorIndices") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in list.breadthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }
    Benchmark("Traversal: breadthFirstSearch on AdjacencyList, mapping each neighbor to its index") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            for case .discover in listWithoutIndices.breadthFirstSearch(from: 0) { discovered += 1 }
            blackHole(discovered)
        }
    }

    Benchmark("Traversal: topologicalSort of a 1M-vertex path") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(path.topologicalSort()) }
    }

    // TR-B05: the explicit stack on a deep graph.
    Benchmark("Traversal: depth-first preorder of a 1M-vertex path") { benchmark in
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in path.depthFirstSearch(from: 0).preorder { count += 1 }
            blackHole(count)
        }
    }

    Benchmark("Traversal: findCycle on a random graph with 1M edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(sparse.findCycle()) }
    }
}
