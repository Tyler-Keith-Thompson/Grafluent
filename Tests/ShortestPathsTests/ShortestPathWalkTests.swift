// The searches return walks: `Path` for a shortest path and `Cycle` for a negative-cycle witness,
// each naming the edges taken, so parallel copies are told apart. Case IDs (WK-12nn) refer to the
// Walks catalog's migration section; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing
import Walks

@Suite("Shortest paths and witnesses as walks")
struct ShortestPathWalkTests {
    @Test("WK-1201 an undirected negative edge is the 2-cycle over its two arcs", arguments: 0 ..< 5)
    func undirectedNegativeEdge(source: Int) {
        // NetworkX's cycle_graph(5); edge {1, 2}, at position 1, is the negative one.
        let cycle = UndirectedAdjacencyList(edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        let weights = [1, -3, 1, 1, 1]
        let witness = cycle.findNegativeCycle(from: source) { weights[$0] }
        #expect(witness?.vertices == [1, 2])
        #expect(witness?.edges == [.init(position: 1, reversed: false), .init(position: 1, reversed: true)])
        #expect(witness?.length == 2)
        #expect(cycle.findNegativeCycle { weights[$0] } == witness)
        #expect(cycle.directed.findNegativeCycle(from: source) { weights[$0.position] } == witness)
        if let witness {
            #expect(Cycle(vertices: witness.vertices, edges: witness.edges, in: cycle.directed) != nil)
        }
    }

    @Test("WK-1206 a negative 2-cycle does not repeat its start, as NetworkX's find_negative_cycle does")
    func witnessDoesNotRepeatStart() {
        // NetworkX returns [0, 1, 0].
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let witness = graph.findNegativeCycle(from: 0) { _ in -1 }
        #expect(witness?.vertices == [0, 1])
        #expect(witness?.count == 2)
        #expect(witness?.edges == [0, 1])
        #expect(witness?.weight { _ in -1 } == -2)
    }

    @Test("WK-1207 the path to the source is the trivial path")
    func pathToSource() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let dijkstra = graph.dijkstraShortestPaths(from: 0) { _ in 1 }
        #expect(dijkstra.path(to: 0) == Path(vertex: 0))
        #expect(dijkstra.path(to: 0)?.length == 0)
        #expect(dijkstra.path(to: 0)?.isTrivial == true)
        #expect(dijkstra.path(to: 0)?.source == 0 && dijkstra.path(to: 0)?.target == 0)
        #expect(graph.bellmanFordShortestPaths(from: 0) { _ in -1 }?.path(to: 0) == Path(vertex: 0))
        #expect(graph.shortestPaths(from: 0).path(to: 0) == Path(vertex: 0))
        #expect(graph.dijkstraShortestPath(from: 0, to: 0) { _ in 1 }?.path == Path(vertex: 0))
        #expect(graph.aStarShortestPath(from: 0, to: 0, weight: { _ in 1 }, heuristic: { _ in 0 })?.path == Path(vertex: 0))
    }

    @Test("WK-1208 the path to an unreached vertex is nil")
    func pathToUnreached() {
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in 1 }.path(to: 2) == nil)
        #expect(graph.bellmanFordShortestPaths(from: 0) { _ in 1 }?.path(to: 2) == nil)
        #expect(graph.shortestPaths(from: 0).path(to: 2) == nil)
        #expect(graph.dijkstraShortestPaths(from: 1) { _ in 1 }.path(to: 0) == nil)
        #expect(graph.dijkstraShortestPath(from: 0, to: 2) { _ in 1 } == nil)
    }

    @Test("WK-1209 between parallel edges the path names the lighter copy, and weighs the distance")
    func parallelEdgesInPath() {
        // 0→1 twice, at weights 5 and 1.
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let weights = [5, 1]
        let result = graph.dijkstraShortestPath(from: 0, to: 1) { weights[$0] }
        #expect(result?.path.vertices == [0, 1])
        #expect(result?.path.edges == [1])
        #expect(result?.path.weight { weights[$0] } == result?.distance)
        #expect(result?.distance == 1)
        let star = graph.aStarShortestPath(from: 0, to: 1, weight: { weights[$0] }, heuristic: { _ in 0 })
        #expect(star?.path.edges == [1])
        #expect(graph.dijkstraShortestPaths(from: 0) { weights[$0] }.path(to: 1)?.edges == [1])
        #expect(graph.bellmanFordShortestPaths(from: 0) { weights[$0] }?.path(to: 1)?.edges == [1])
    }

    @Test("WK-1210 every tree path is a path of the graph and weighs the distance", .tags(.randomized), arguments: 0 ..< 20)
    func treePathLaws(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 12, using: &rng)
        let m = Int.random(in: 0 ... 3 * n, using: &rng)
        // Self-loops and parallel copies happen; weights are non-negative so all three searches run.
        let raw = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ... 10, using: &rng)) }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights = raw.map(\.2)
        let source = Int.random(in: 0 ..< n, using: &rng)
        let dijkstra = graph.dijkstraShortestPaths(from: source) { weights[$0] }
        let bellmanFord = graph.bellmanFordShortestPaths(from: source) { weights[$0] }
        let unweighted = graph.shortestPaths(from: source)
        #expect(bellmanFord != nil)
        for v in 0 ..< n {
            guard let distance = dijkstra.distance(to: v) else {
                #expect(dijkstra.path(to: v) == nil)
                continue
            }
            for path in [dijkstra.path(to: v), bellmanFord?.path(to: v)] {
                guard let path else {
                    Issue.record("no path to reached \(v): \(raw)")
                    continue
                }
                #expect(path.source == source && path.target == v, "\(raw)")
                #expect(path.weight { weights[$0] } == distance, "\(v): \(raw)")
                #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil, "\(v): \(raw)")
            }
            let hops = unweighted.path(to: v)
            #expect(hops?.length == unweighted.distance(to: v), "\(v): \(raw)")
            if let hops { #expect(Path(vertices: hops.vertices, edges: hops.edges, in: graph) != nil, "\(v): \(raw)") }
        }
    }

    @Test("WK-1211 a negative cycle through parallel edges names the copy that closes it")
    func parallelEdgesInWitness() {
        // M: 0→1 twice and 1→0, at −1, −5 and 1; only the −5 copy makes 0→1→0 negative.
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let weights = [-1, -5, 1]
        let witness = graph.findNegativeCycle(from: 0) { weights[$0] }
        #expect(witness?.vertices == [0, 1])
        #expect(witness?.edges == [1, 2])
        #expect(witness?.weight { weights[$0] } == -4)
        #expect(graph.findNegativeCycle { weights[$0] } == witness)
        #expect(graph.findNegativeCycle(from: [1]) { weights[$0] } == witness)
    }

    @Test("WK-1212 every witness is a cycle of the graph that weighs less than zero", .tags(.randomized), arguments: 0 ..< 20)
    func witnessIsACycle(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 12, using: &rng)
        let m = Int.random(in: 0 ... 3 * n, using: &rng)
        let raw = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: -4 ... 10, using: &rng)) }
        let directed = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
        let undirected = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
        let weights = raw.map(\.2)
        for source in 0 ..< n {
            if let witness = directed.findNegativeCycle(from: source, weight: { weights[$0] }) {
                #expect(Cycle(vertices: witness.vertices, edges: witness.edges, in: directed) != nil, "\(witness): \(raw)")
                #expect(witness.weight { weights[$0] } < 0, "\(witness): \(raw)")
            } else {
                #expect(directed.bellmanFordShortestPaths(from: source) { weights[$0] } != nil)
            }
            if let witness = undirected.findNegativeCycle(from: source, weight: { weights[$0] }) {
                #expect(Cycle(vertices: witness.vertices, edges: witness.edges, in: undirected.directed) != nil, "\(witness): \(raw)")
                #expect(witness.weight { weights[$0.position] } < 0, "\(witness): \(raw)")
            } else {
                #expect(undirected.bellmanFordShortestPaths(from: source) { weights[$0] } != nil)
            }
        }
        if let witness = directed.findNegativeCycle(weight: { weights[$0] }) {
            #expect(Cycle(vertices: witness.vertices, edges: witness.edges, in: directed) != nil, "\(witness): \(raw)")
            #expect(witness.weight { weights[$0] } < 0, "\(witness): \(raw)")
        }
    }
}
