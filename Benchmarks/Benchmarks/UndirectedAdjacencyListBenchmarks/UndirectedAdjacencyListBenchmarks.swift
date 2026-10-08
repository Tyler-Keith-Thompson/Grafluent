import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import GraphProtocols
import Traversal

/// Generic code, so the calls go through the protocol's requirements.
@inline(never)
func degreeAndContains<G: Graph>(_ graph: G, _ hub: G.Vertex, _ probes: [UndirectedEdge<G.Vertex>]) -> Int {
    var sum = graph.degree(of: hub)
    for edge in probes where graph.contains(edge: edge) { sum &+= 1 }
    return sum
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 500_000).map { UndirectedEdge($0.source, $0.target) }
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
    let star = UndirectedAdjacencyList(edges: Inputs.star(leaves: 20_000).map { UndirectedEdge($0.source, $0.target) })
    let probes = (0 ..< 20_000).map { UndirectedEdge($0 + 1, 0) }

    Benchmark("UndirectedAdjacencyList: build from 500k random edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)) }
    }
    // UG-B01: breadth-first search, hand-written over neighborIndices vs Traversal through `directed`.
    Benchmark("UndirectedAdjacencyList: BASELINE hand-written BFS over neighborIndices") { benchmark in
        for _ in benchmark.scaledIterations {
            var visited = [Bool](repeating: false, count: n)
            visited[0] = true
            var queue = [0]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in graph.neighborIndices(ofIndex: v) where !visited[w] {
                    visited[w] = true
                    queue.append(w)
                }
            }
            blackHole(queue.count)
        }
    }
    Benchmark("UndirectedAdjacencyList: breadthFirstSearch through directed, pushed with forEach") { benchmark in
        for _ in benchmark.scaledIterations {
            var discovered = 0
            graph.directed.breadthFirstSearch(from: 0).forEach { if case .discover = $0 { discovered += 1 } }
            blackHole(discovered)
        }
    }
    Benchmark("UndirectedAdjacencyList: visit every neighbor of every vertex") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in graph.vertices {
                for w in graph.neighbors(of: v) { sum &+= w }
            }
            blackHole(sum)
        }
    }
    // Edge identity: walking incident edges, their far ends, and the arcs of the directed view.
    let named = UndirectedAdjacencyList(edges: edges.map { UndirectedEdge("v\($0.u)", "v\($0.v)") })
    Benchmark("UndirectedAdjacencyList: oppositeVertex across every incident edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in graph.vertices {
                for e in graph.incidentEdges(of: v) { sum &+= graph.oppositeVertex(to: v, acrossEdgeAt: e) }
            }
            blackHole(sum)
        }
    }
    Benchmark("UndirectedAdjacencyList<String>: oppositeVertex across every incident edge") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in named.vertices {
                for e in named.incidentEdges(of: v) { sum &+= named.oppositeVertex(to: v, acrossEdgeAt: e).utf8.count }
            }
            blackHole(sum)
        }
    }
    Benchmark("UndirectedAdjacencyList: incidentEdgeIndices of every vertex, in index space") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for i in 0 ..< n {
                for e in graph.incidentEdgeIndices(ofIndex: i) { sum &+= e }
            }
            blackHole(sum)
        }
    }
    Benchmark("UndirectedAdjacencyList: outEdges of every vertex through directed") { benchmark in
        let view = graph.directed
        for _ in benchmark.scaledIterations {
            var sum = 0
            for v in view.vertices {
                for arc in view.outEdges(of: v) { sum &+= view.target(ofEdgeAt: arc) }
            }
            blackHole(sum)
        }
    }
    // UG-B02: O(1) degree and contains(edge:) through generic code at a 20k hub.
    Benchmark("UndirectedAdjacencyList: degree and 20k contains(edge:) at a hub, generic") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(degreeAndContains(star, 0, probes)) }
    }
    // UG-B03: removing the hub is O(degree).
    Benchmark("UndirectedAdjacencyList: remove the hub of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = star
            blackHole(copy.remove(0))
        }
    }
    Benchmark("UndirectedAdjacencyList: remove every edge of a 20k-leaf star") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = star
            for leaf in 1 ... 20_000 { copy.remove(edge: UndirectedEdge(leaf, 0)) }
            blackHole(copy.edgeCount)
        }
    }
    // UG-B04: a copy shares storage until its first mutation, which copies a constant number of buffers.
    Benchmark("UndirectedAdjacencyList: first mutation of a copy (copies)") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = graph
            copy.insert(edge: UndirectedEdge(n, n + 1))
            blackHole(copy.edgeCount)
        }
    }
    Benchmark("UndirectedAdjacencyList: == on a graph and its copy") { benchmark in
        let copy = graph
        for _ in benchmark.scaledIterations { blackHole(graph == copy) }
    }
}
