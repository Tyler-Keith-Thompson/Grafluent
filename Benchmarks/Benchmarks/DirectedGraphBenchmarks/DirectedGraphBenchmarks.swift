import AdjacencyListModule
import AdjacencyMatrixModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import EdgeListModule
import GraphProtocols

// Generic code over the protocol should cost what concrete code costs, once specialized; an
// existential pays for dispatch. Each pair below measures the same work both ways.

// Per-vertex state in an array when the graph has vertex indices, as algorithm modules will do.
@inline(never)
func reachedGeneric<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> Int {
    guard let n = g.vertexIndexBound else { return reachedByDictionary(g, from: source) }
    var visited = [Bool](repeating: false, count: n)
    visited[g.vertexIndex(of: source)] = true
    var queue = [source]
    var head = 0
    while head < queue.count {
        let v = queue[head]
        head += 1
        for w in g.successors(of: v) {
            let i = g.vertexIndex(of: w)
            if !visited[i] {
                visited[i] = true
                queue.append(w)
            }
        }
    }
    return queue.count
}

@inline(never)
func reachedByDictionary<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> Int {
    var visited: Set = [source]
    var queue = [source]
    var head = 0
    while head < queue.count {
        let v = queue[head]
        head += 1
        for w in g.successors(of: v) where visited.insert(w).inserted {
            queue.append(w)
        }
    }
    return queue.count
}

@inline(never)
func reachedExistential(_ g: any DirectedGraph<Int>, from source: Int) -> Int {
    let n = g.vertexIndexBound!
    var visited = [Bool](repeating: false, count: n)
    visited[g.vertexIndex(of: source)] = true
    var queue = [source]
    var head = 0
    while head < queue.count {
        let v = queue[head]
        head += 1
        for w in g.successors(of: v) {
            let i = g.vertexIndex(of: w)
            if !visited[i] {
                visited[i] = true
                queue.append(w)
            }
        }
    }
    return queue.count
}

@inline(never)
func outDegreeSum(_ g: some DirectedGraph<Int>) -> Int {
    var sum = 0
    for v in g.vertices { sum &+= g.outDegree(of: v) }
    return sum
}

@inline(never)
func containsCount(_ g: some DirectedGraph<Int>, _ probes: [DirectedEdge<Int>]) -> Int {
    var found = 0
    for edge in probes where g.contains(edge: edge) { found += 1 }
    return found
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000)
    let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
    let list = AdjacencyList(vertices: 0 ..< n, edges: edges)

    // DG-B01: breadth-first search, concrete vs generic vs existential.
    Benchmark("DirectedGraph: BFS on CompressedSparseRow, concrete") { benchmark in
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
    Benchmark("DirectedGraph: BFS on CompressedSparseRow, generic") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reachedGeneric(sparse, from: 0)) }
    }
    Benchmark("DirectedGraph: BFS on CompressedSparseRow, existential") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reachedExistential(sparse, from: 0)) }
    }
    Benchmark("DirectedGraph: BFS on AdjacencyList, generic through vertex indices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reachedGeneric(list, from: 0)) }
    }
    Benchmark("DirectedGraph: BFS on AdjacencyList, generic through a Set of vertices") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reachedByDictionary(list, from: 0)) }
    }

    // DG-B02: the matrix's O(1) outDegree, not BitSet.count, through generic code.
    let matrix = AdjacencyMatrix(vertexCount: 4096, edges: Inputs.randomEdges(vertexCount: 4096, edgeCount: 4096 * 4096 / 8))
    Benchmark("DirectedGraph: outDegree of every vertex of a 4096² matrix, generic (must be O(1) each)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(outDegreeSum(matrix)) }
    }
    Benchmark("DirectedGraph: BASELINE the same, concrete") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in 0 ..< 4096 { sum &+= matrix.outDegree(of: v) }
            blackHole(sum)
        }
    }

    // DG-B03: CSR's binary-search contains(edge:), not the default scan, through generic code.
    let hub = CompressedSparseRow(vertexCount: 20_001, edges: (1 ... 20_000).map { DirectedEdge(from: 0, to: $0) })
    let probes = (0 ..< 10_000).map { DirectedEdge(from: 0, to: ($0 &* 7919) % 20_001) }
    Benchmark("DirectedGraph: contains(edge:) on a 20k hub of CompressedSparseRow, generic (must be O(log d))") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(containsCount(hub, probes)) }
    }
}
