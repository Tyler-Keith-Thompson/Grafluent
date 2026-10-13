import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import GraphProducts
import GraphProtocols
import NamedGraphs
import Traversal

// Each product against the same algorithm on a materialized copy.

/// A sparse undirected graph on `n` vertices: a random spanning tree plus `extra` random edges, no
/// self-loops or repeats.
func sparseFactor(vertexCount n: Int, extra: Int, seed: UInt) -> UndirectedAdjacencyList<Int> {
    var rng = SeededRandomNumberGenerator(seed: seed)
    var pairs = Set<[Int]>()
    for v in 1 ..< n { pairs.insert([Int.random(in: 0 ..< v, using: &rng), v]) }
    while pairs.count < n - 1 + extra {
        let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
        if a != b { pairs.insert([min(a, b), max(a, b)]) }
    }
    return UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: pairs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }.map { UndirectedEdge($0[0], $0[1]) })
}

/// A product materialized on its vertex indices, edges in `edges` order.
func materialized<P: Graph>(_ product: P) -> UndirectedAdjacencyList<Int> {
    UndirectedAdjacencyList<Int>(vertices: 0 ..< product.vertexCount, edges: product.edges.indices.map {
        let ends = product.endpointIndices(ofEdgeAt: $0)
        return UndirectedEdge(ends.u, ends.v)
    })
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // Two 1k-vertex sparse factors (a tree plus 500 edges: 1499 edges each).
    let g = sparseFactor(vertexCount: 1000, extra: 500, seed: 1)
    let h = sparseFactor(vertexCount: 1000, extra: 500, seed: 2)
    // ∘ copies all of H per G-edge, so its H is smaller: |E| = 1499·30² + 1000·m_H.
    let small = sparseFactor(vertexCount: 30, extra: 10, seed: 3)

    let cartesian = cartesianProductView(g, h)
    let strong = strongProductView(g, h)
    let lexicographic = lexicographicProductView(g, small)
    let cartesianCopy = materialized(cartesian)
    let strongCopy = materialized(strong)
    let lexicographicCopy = materialized(lexicographic)
    let origin = Pair(0, 0)
    precondition(cartesian.directedView.breadthFirstLayers(from: origin).map(\.count) == cartesianCopy.directedView.breadthFirstLayers(from: 0).map(\.count))
    precondition(strong.connectedComponents().count == strongCopy.connectedComponents().count)
    precondition(lexicographic.connectedComponents().count == lexicographicCopy.connectedComponents().count)

    // MARK: □, ⊠ and ∘ against a materialized copy, target ≤ 1.2×

    for (name, product, copy) in [
        ("cartesianProductView (10⁶ vertices, 3·10⁶ edges)", AnyProduct(cartesian), cartesianCopy),
        ("strongProductView (10⁶ vertices, 7.5·10⁶ edges)", AnyProduct(strong), strongCopy),
        ("lexicographicProductView (3·10⁴ vertices, 1.4·10⁶ edges)", AnyProduct(lexicographic), lexicographicCopy),
    ] {
        Benchmark("GraphProducts: BASELINE breadthFirstLayers on the materialized \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(copy.directedView.breadthFirstLayers(from: 0)) }
        }
        Benchmark("GraphProducts: breadthFirstLayers on \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(product.breadthFirstLayers()) }
        }
        Benchmark("GraphProducts: BASELINE connectedComponents on the materialized \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(copy.connectedComponents().count) }
        }
        Benchmark("GraphProducts: connectedComponents on \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(product.connectedComponents()) }
        }
    }

    // MARK: P_r □ P_c vs NamedGraphs' grid, target ≤ 1.2×

    let side = 1000
    let path = UndirectedAdjacencyList<Int>.path(vertexCount: side)
    let gridProduct = cartesianProductView(path, path)
    let grid = UndirectedAdjacencyList<Int>.grid(dimensions: [side, side])
    let gridCSR = CompressedSparseRow.grid(dimensions: [side, side])
    precondition(gridProduct.directedView.breadthFirstLayers(from: origin).count == grid.directedView.breadthFirstLayers(from: 0).count)
    Benchmark("GraphProducts: BASELINE breadthFirstLayers on UndirectedAdjacencyList.grid(dimensions: [1000, 1000])") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(grid.directedView.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphProducts: BASELINE breadthFirstLayers on CompressedSparseRow.grid(dimensions: [1000, 1000])") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(gridCSR.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphProducts: breadthFirstLayers on cartesianProductView(P1000, P1000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(gridProduct.directedView.breadthFirstLayers(from: origin)) }
    }

    // MARK: Materializing into CompressedSparseRow (directed factors)

    let gArcs = CompressedSparseRow(vertexCount: 1000, edges: g.edges.flatMap { [DirectedEdge(from: $0.u, to: $0.v), DirectedEdge(from: $0.v, to: $0.u)] })
    let hArcs = CompressedSparseRow(vertexCount: 1000, edges: h.edges.flatMap { [DirectedEdge(from: $0.u, to: $0.v), DirectedEdge(from: $0.v, to: $0.u)] })
    let directedCartesian = cartesianProductView(gArcs, hArcs)
    Benchmark("GraphProducts: CompressedSparseRow of cartesianProductView (10⁶ vertices, 6·10⁶ arcs), row by row") { benchmark in
        for _ in benchmark.scaledIterations {
            var arcs: [DirectedEdge<Int>] = []
            arcs.reserveCapacity(directedCartesian.edgeCount)
            for v in 0 ..< directedCartesian.vertexCount {
                for w in directedCartesian.successorIndices(ofIndex: v) { arcs.append(DirectedEdge(from: v, to: w)) }
            }
            blackHole(CompressedSparseRow(vertexCount: directedCartesian.vertexCount, edges: arcs))
        }
    }
}

/// One of the undirected products, so the loop above can register each.
struct AnyProduct {
    let layers: () -> [[Pair<Int, Int>]]
    let components: () -> Int

    init<P: Graph>(_ product: P) where P.Vertex == Pair<Int, Int> {
        layers = { product.directedView.breadthFirstLayers(from: Pair(0, 0)) }
        components = { product.connectedComponents().count }
    }

    func breadthFirstLayers() -> [[Pair<Int, Int>]] { layers() }
    func connectedComponents() -> Int { components() }
}
