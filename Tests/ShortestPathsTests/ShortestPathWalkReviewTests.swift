// Cases added after the critical review of Walks: a path to a source that another source improved
// (multi-source Bellman–Ford), undirected Dijkstra and A* results checked as paths of the directed
// view (the orientation of each arc), and an undirected negative self-loop's witness. Case IDs
// (WK-nn) refer to the Walks catalog; see Tests/WalksTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing
import Walks

@Suite("Shortest-path walks: review cases")
struct ShortestPathWalkReviewTests {
    @Test("WK-1220 a source improved by another source has a path from that source, a path of the graph")
    func improvedSource() {
        let edges: [(Int, Int, Int)] = [(0, 1, -5), (1, 2, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let tree = graph.bellmanFordShortestPaths(from: [1, 0]) { edges[$0].2 }
        let path = tree?.path(to: 1)
        #expect(path?.vertices == [0, 1] && path?.edges == [0])
        #expect(path.map { Path(vertices: $0.vertices, edges: $0.edges, in: graph) != nil } == true)
        #expect(tree?.path(to: 2)?.edges == [0, 1])
        #expect(tree?.path(to: 2)?.weight { edges[$0].2 } == tree?.distance(to: 2))
    }

    @Test("WK-1221 undirected Dijkstra and A* paths are paths of the directed view, each arc pointing the way it is crossed", .tags(.randomized), arguments: 0 ..< 6)
    func undirectedPathsAreArcs(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(1221 + seed))
        for _ in 0 ..< 30 {
            let n = Int.random(in: 2 ... 8, using: &rng)
            var edges: [(Int, Int, Int)] = []
            for _ in 0 ..< Int.random(in: 1 ... 14, using: &rng) {
                // Stored in either orientation, so some arcs are crossed against it.
                edges.append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ... 9, using: &rng)))
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let (s, t) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
            for result in [graph.dijkstraShortestPath(from: s, to: t) { edges[$0].2 },
                           graph.aStarShortestPath(from: s, to: t, weight: { edges[$0].2 }, heuristic: { _ in 0 })] {
                guard let result else { continue }
                #expect(Path(vertices: result.path.vertices, edges: result.path.edges, in: graph.directed) != nil, "\(edges) \(s)→\(t)")
                #expect(result.path.weight { edges[$0.position].2 } == result.distance)
            }
            let tree = graph.dijkstraShortestPaths(from: s) { edges[$0].2 }
            for v in 0 ..< n {
                guard let path = tree.path(to: v) else { continue }
                #expect(Path(vertices: path.vertices, edges: path.edges, in: graph.directed) != nil, "\(edges) to \(v)")
            }
        }
    }

    @Test("WK-1222 an undirected negative self-loop is a one-arc cycle of the directed view")
    func undirectedNegativeSelfLoop() {
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let cycle = graph.findNegativeCycle(from: 0) { [1, -2][$0] }
        #expect(cycle?.vertices == [1])
        #expect(cycle?.edges == [DirectedView<ReferencePseudograph<Int>>.Edges.Index(position: 1, reversed: false)])
        #expect(cycle.map { Cycle(vertices: $0.vertices, edges: $0.edges, in: graph.directed) != nil } == true)
        #expect(cycle?.weight { [1, -2][$0.position] } == -2)
    }
}
