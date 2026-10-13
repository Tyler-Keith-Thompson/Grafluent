import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import Connectivity
import DirectedAcyclicGraphModule
import GraphOperations
import GraphProtocols
import Traversal

// Each view against the same algorithm on the base or on a materialized copy.

/// The index-space edges of a directed view, in `edges` order: what a materialized copy holds.
func indexEdges<G: DirectedGraph>(_ graph: G) -> [DirectedEdge<Int>] {
    graph.edges.indices.map { DirectedEdge(from: graph.sourceIndex(ofEdgeAt: $0), to: graph.targetIndex(ofEdgeAt: $0)) }
}

/// The index-space edges of an undirected view.
func indexEdges<G: Graph>(_ graph: G) -> [UndirectedEdge<Int>] {
    graph.edges.indices.map {
        let ends = graph.endpointIndices(ofEdgeAt: $0)
        return UndirectedEdge(ends.u, ends.v)
    }
}

/// The complement of `graph` as compressed sparse rows, built row by row: the materialized
/// baseline for the complement view.
func materializedComplement(_ graph: CompressedSparseRow) -> CompressedSparseRow {
    let n = graph.vertexCount
    var edges: [DirectedEdge<Int>] = []
    edges.reserveCapacity(n * (n - 1) - graph.edgeCount)
    var mark = [Int](repeating: -1, count: n)
    for i in 0 ..< n {
        for w in graph.successors(of: i) { mark[w] = i }
        for j in 0 ..< n where j != i && mark[j] != i { edges.append(DirectedEdge(from: i, to: j)) }
    }
    return CompressedSparseRow(vertexCount: n, edges: edges)
}

/// A sparse G(20k, 6·10⁴) as compressed sparse rows, its complement view, and the complement
/// materialized (about 4·10⁸ arcs): built on first use, since a global is initialized lazily.
let complementInputs: (view: ComplementView<CompressedSparseRow>, copy: CompressedSparseRow) = {
    let count = 20_000
    let sparse = CompressedSparseRow(vertexCount: count, edges: Inputs.randomEdges(vertexCount: count, edgeCount: 60_000, seed: 3))
    let view = sparse.complementView
    let copy = materializedComplement(sparse)
    precondition(view.edgeCount == copy.edgeCount)
    precondition(view.breadthFirstLayers(from: 0).map(\.count) == copy.breadthFirstLayers(from: 0).map(\.count))
    return (view, copy)
}()

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // G(10⁵, 10⁶), directed and undirected, deduplicated.
    let n = 100_000
    let arcs = Inputs.sortedUnique(Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000))
    let list = AdjacencyList<Int>(vertices: 0 ..< n, edges: arcs)
    let csr = CompressedSparseRow(vertexCount: n, edges: arcs)
    let undirectedEdges = arcs.filter { $0.source < $0.target }.map { UndirectedEdge($0.source, $0.target) }
    let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: undirectedEdges)

    // MARK: transposedView vs AdjacencyList(g.transposedView)

    let reverse = list.transposedView
    let reversedCopy = AdjacencyList<Int>(reverse)
    precondition(reverse.breadthFirstLayers(from: 0) == reversedCopy.breadthFirstLayers(from: 0))
    precondition(reverse.stronglyConnectedComponents().count == reversedCopy.stronglyConnectedComponents().count)

    Benchmark("GraphOperations: BASELINE breadthFirstLayers on AdjacencyList(g.transposedView)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reversedCopy.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: breadthFirstLayers on g.transposedView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reverse.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: BASELINE stronglyConnectedComponents on AdjacencyList(g.transposedView)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reversedCopy.stronglyConnectedComponents().count) }
    }
    Benchmark("GraphOperations: stronglyConnectedComponents on g.transposedView") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(reverse.stronglyConnectedComponents().count) }
    }

    // MARK: inducedSubgraphView keeping 100% vs the base

    let all = list.inducedSubgraphView(on: 0 ..< n)
    let allUndirected = undirected.inducedSubgraphView(on: 0 ..< n)
    precondition(all.edgeCount == list.edgeCount && allUndirected.edgeCount == undirected.edgeCount)

    Benchmark("GraphOperations: BASELINE breadthFirstLayers on AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: breadthFirstLayers on AdjacencyList.inducedSubgraphView (100%)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(all.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: BASELINE weaklyConnectedComponents on AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.weaklyConnectedComponents().count) }
    }
    Benchmark("GraphOperations: weaklyConnectedComponents on AdjacencyList.inducedSubgraphView (100%)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(all.weaklyConnectedComponents().count) }
    }
    Benchmark("GraphOperations: BASELINE breadthFirstLayers on UndirectedAdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.directedView.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: breadthFirstLayers on UndirectedAdjacencyList.inducedSubgraphView (100%)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(allUndirected.directedView.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: BASELINE connectedComponents on UndirectedAdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.connectedComponents().count) }
    }
    Benchmark("GraphOperations: connectedComponents on UndirectedAdjacencyList.inducedSubgraphView (100%)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(allUndirected.connectedComponents().count) }
    }

    // MARK: inducedSubgraphView keeping 50% vs a materialized copy, build included

    var generator = SeededRandomNumberGenerator(seed: 11)
    let half = (0 ..< n).filter { _ in Bool.random(using: &generator) }
    let halfView = list.inducedSubgraphView(on: half)
    let halfCopy = CompressedSparseRow(vertexCount: half.count, edges: indexEdges(halfView))
    let halfUndirectedView = undirected.inducedSubgraphView(on: half)
    let halfUndirectedCopy = UndirectedAdjacencyList<Int>(vertices: 0 ..< half.count, edges: indexEdges(halfUndirectedView))
    let start = half[0]
    precondition(halfView.breadthFirstLayers(from: start).map(\.count) == halfCopy.breadthFirstLayers(from: 0).map(\.count))
    precondition(halfView.weaklyConnectedComponents().count == halfCopy.weaklyConnectedComponents().count)
    precondition(halfUndirectedView.connectedComponents().count == halfUndirectedCopy.connectedComponents().count)

    // Both sides build what they walk: the copy is materialized each time, as the view is.
    Benchmark("GraphOperations: BASELINE materializing the 50% induced subgraph as CompressedSparseRow + breadthFirstLayers") { benchmark in
        for _ in benchmark.scaledIterations {
            let copy = CompressedSparseRow(vertexCount: half.count, edges: indexEdges(list.inducedSubgraphView(on: half)))
            blackHole(copy.breadthFirstLayers(from: 0))
        }
    }
    Benchmark("GraphOperations: AdjacencyList.inducedSubgraphView (50%) built + breadthFirstLayers") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.inducedSubgraphView(on: half).breadthFirstLayers(from: start)) }
    }
    Benchmark("GraphOperations: BASELINE materializing the 50% induced subgraph as CompressedSparseRow + weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations {
            let copy = CompressedSparseRow(vertexCount: half.count, edges: indexEdges(list.inducedSubgraphView(on: half)))
            blackHole(copy.weaklyConnectedComponents().count)
        }
    }
    Benchmark("GraphOperations: AdjacencyList.inducedSubgraphView (50%) built + weaklyConnectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.inducedSubgraphView(on: half).weaklyConnectedComponents().count) }
    }
    Benchmark("GraphOperations: BASELINE materializing the 50% induced subgraph as UndirectedAdjacencyList + connectedComponents") { benchmark in
        for _ in benchmark.scaledIterations {
            let copy = UndirectedAdjacencyList<Int>(vertices: 0 ..< half.count, edges: indexEdges(undirected.inducedSubgraphView(on: half)))
            blackHole(copy.connectedComponents().count)
        }
    }
    Benchmark("GraphOperations: UndirectedAdjacencyList.inducedSubgraphView (50%) built + connectedComponents") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.inducedSubgraphView(on: half).connectedComponents().count) }
    }
    Benchmark("GraphOperations: BASELINE materializing the 50% induced subgraph as CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow(vertexCount: half.count, edges: indexEdges(list.inducedSubgraphView(on: half)))) }
    }
    Benchmark("GraphOperations: building AdjacencyList.inducedSubgraphView (50%), target ≤ 0.1× materializing") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.inducedSubgraphView(on: half)) }
    }

    // MARK: inducedSubgraphView over CompressedSparseRow keeping 100%

    let allCSR = csr.inducedSubgraphView(on: 0 ..< n)
    Benchmark("GraphOperations: BASELINE breadthFirstLayers on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: breadthFirstLayers on CompressedSparseRow.inducedSubgraphView (100%)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(allCSR.breadthFirstLayers(from: 0)) }
    }

    // MARK: spanningSubgraphView of a spanning forest's edges vs BFS on the base

    // The view walks every base entry and tests the mask's words at the base's edge index, so the
    // baseline is BFS over the same base rows (the BASELINE on UndirectedAdjacencyList above).
    var parentEdge = [Int](repeating: -1, count: n)
    var seen = [Bool](repeating: false, count: n)
    for root in 0 ..< n where !seen[root] {
        seen[root] = true
        var queue = [root]
        var head = 0
        while head < queue.count {
            let u = queue[head]
            head += 1
            for (w, p) in zip(undirected.neighborIndices(ofIndex: u), undirected.incidentEdges(ofIndex: u)) where !seen[w] {
                seen[w] = true
                parentEdge[w] = p
                queue.append(w)
            }
        }
    }
    let treeEdges = parentEdge.filter { $0 >= 0 }
    let tree = undirected.spanningSubgraphView(edges: treeEdges)
    precondition(tree.connectedComponents().count == undirected.connectedComponents().count)
    precondition(tree.directedView.breadthFirstLayers(from: 0).map(\.count) == undirected.directedView.breadthFirstLayers(from: 0).map(\.count))

    Benchmark("GraphOperations: breadthFirstLayers on UndirectedAdjacencyList.spanningSubgraphView (a spanning forest), against the base") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(tree.directedView.breadthFirstLayers(from: 0)) }
    }

    // MARK: complement of a sparse graph (n = 20k) vs a materialized complement

    Benchmark("GraphOperations: BASELINE breadthFirstLayers on a materialized complement (n = 20k, 4·10⁸ arcs)", configuration: .init(maxDuration: .seconds(10))) { benchmark in
        let copy = complementInputs.copy
        for _ in benchmark.scaledIterations { blackHole(copy.breadthFirstLayers(from: 0)) }
    }
    Benchmark("GraphOperations: breadthFirstLayers on CompressedSparseRow.complement (n = 20k)", configuration: .init(maxDuration: .seconds(10))) { benchmark in
        let complement = complementInputs.view
        for _ in benchmark.scaledIterations { blackHole(complement.breadthFirstLayers(from: 0)) }
    }

    // MARK: walking a complement's edges.indices vs iterating its edges (n = 2000)

    // index(after:) steps from the current cell, one contains(edge:) per column passed.
    let walkCount = 2000
    let walkBase = CompressedSparseRow(vertexCount: walkCount, edges: Inputs.randomEdges(vertexCount: walkCount, edgeCount: 3 * walkCount, seed: 3))
    let walkComplement = walkBase.complementView
    precondition(walkComplement.edges.indices.count == walkComplement.edgeCount)
    Benchmark("GraphOperations: BASELINE iterating CompressedSparseRow.complementView.edges (n = 2000)") { benchmark in
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in walkComplement.edges { count &+= 1 }
            blackHole(count)
        }
    }
    Benchmark("GraphOperations: walking CompressedSparseRow.complementView.edges.indices (n = 2000)") { benchmark in
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in walkComplement.edges.indices { count &+= 1 }
            blackHole(count)
        }
    }

    // MARK: lineGraph and the condensation

    // No self-loops: a directed self-loop's line graph has a self-loop, which traps.
    let lineInput = CompressedSparseRow(vertexCount: n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: 300_000, seed: 4).filter { $0.source != $0.target })
    Benchmark("GraphOperations: CompressedSparseRow.lineGraph(of:), G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(CompressedSparseRow.lineGraph(of: lineInput)) }
    }
    let undirectedLineInput = UndirectedAdjacencyList<Int>(
        vertices: 0 ..< n, edges: Inputs.randomEdges(vertexCount: n, edgeCount: 300_000, seed: 4).filter { $0.source != $0.target }.map { UndirectedEdge($0.source, $0.target) })
    Benchmark("GraphOperations: UndirectedAdjacencyList<Int>.lineGraph(of:), G(10⁵, 3·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList<Int>.lineGraph(of: undirectedLineInput)) }
    }

    precondition(DirectedAcyclicGraph<AdjacencyList<Int>>(list.condensation()).vertexCount == list.condensation().components.count)
    Benchmark("GraphOperations: BASELINE condensation() on AdjacencyList") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(list.condensation()) }
    }
    Benchmark("GraphOperations: DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()), target ≤ 1.1× condensation()") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedAcyclicGraph<AdjacencyList<Int>>(list.condensation())) }
    }
    let lowerTriangle = AdjacencyList<Int>(vertices: 0 ..< n, edges: arcs.filter { $0.source > $0.target })
    precondition(lowerTriangle.condensation().components.count == n)
    Benchmark("GraphOperations: BASELINE condensation() on an acyclic AdjacencyList (10⁵ components)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(lowerTriangle.condensation()) }
    }
    Benchmark("GraphOperations: DirectedAcyclicGraph<AdjacencyList<Int>>(condensation()) on an acyclic AdjacencyList (10⁵ components)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(DirectedAcyclicGraph<AdjacencyList<Int>>(lowerTriangle.condensation())) }
    }

    // MARK: Index-space hooks of the representations vs reads by vertex lookup

    Benchmark("GraphOperations: BASELINE outDegree(of: vertex(atIndex:)) + edge ends by lookup, AdjacencyList<Int>, every vertex and edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for i in 0 ..< n { total &+= list.outDegree(of: list.vertex(atIndex: i)) &+ list.inDegree(of: list.vertex(atIndex: i)) }
            for p in list.edges.indices { total &+= list.vertexIndex(of: list.source(ofEdgeAt: p)) &+ list.vertexIndex(of: list.target(ofEdgeAt: p)) }
            blackHole(total)
        }
    }
    Benchmark("GraphOperations: outDegree(ofIndex:) + sourceIndex/targetIndex(ofEdgeAt:), AdjacencyList<Int>, every vertex and edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for i in 0 ..< n { total &+= list.outDegree(ofIndex: i) &+ list.inDegree(ofIndex: i) }
            for p in list.edges.indices { total &+= list.sourceIndex(ofEdgeAt: p) &+ list.targetIndex(ofEdgeAt: p) }
            blackHole(total)
        }
    }
    Benchmark("GraphOperations: BASELINE degree(of: vertex(atIndex:)) + edge ends by lookup, UndirectedAdjacencyList<Int>, every vertex and edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for i in 0 ..< n { total &+= undirected.degree(of: undirected.vertex(atIndex: i)) }
            for p in undirected.edges.indices {
                let edge = undirected.edges[p]
                total &+= undirected.vertexIndex(of: edge.u) &+ undirected.vertexIndex(of: edge.v)
            }
            blackHole(total)
        }
    }
    Benchmark("GraphOperations: degree(ofIndex:) + endpointIndices(ofEdgeAt:), UndirectedAdjacencyList<Int>, every vertex and edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var total = 0
            for i in 0 ..< n { total &+= undirected.degree(ofIndex: i) }
            for p in undirected.edges.indices {
                let ends = undirected.endpointIndices(ofEdgeAt: p)
                total &+= ends.u &+ ends.v
            }
            blackHole(total)
        }
    }
}
