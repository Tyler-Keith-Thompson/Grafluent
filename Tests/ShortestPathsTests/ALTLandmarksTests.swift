// `altLandmarks(count:weight:)`: every query distance is Dijkstra's and every path is a path of
// that length, on random directed and undirected graphs with parallel edges, loops and zero
// weights, with no landmarks, one, and more than the graph has vertices, on several representations;
// a hand-worked case; the landmarks chosen; the empty and one-vertex graphs; the checked lookups.

import AdjacencyListModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing
import Walks

@Suite("altLandmarks")
struct ALTLandmarksTests {
    @Test("A hand-worked road: the path and distance, the landmarks farthest apart")
    func road() throws {
        // A line 0 → 1 → 2 → 3 → 4 with a detour 0 → 4 of weight 10 and a parallel 1 → 2.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4),
                     DirectedEdge(from: 0, to: 4), DirectedEdge(from: 1, to: 2)]
        let weights = [1, 2, 3, 1, 10, 5]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: edges)
        let landmarks = graph.altLandmarks(count: 2) { weights[$0] }
        // Farthest from 0 is 4 (at 7); farthest from 4 by the forward table is 0 (unreached, so first of the unreached).
        #expect(landmarks.landmarks == [4, 0])
        #expect(landmarks.distance(from: 0, to: 4) == 7)
        #expect(landmarks.distance(from: 4, to: 0) == nil)
        #expect(landmarks.distance(from: 2, to: 2) == 0)
        let path = try #require(landmarks.path(from: 0, to: 4))
        #expect(path.vertices == [0, 1, 2, 3, 4] && path.edges == [0, 1, 2, 3])
        #expect(landmarks.path(from: 1, to: 1)?.vertices == [1])
        #expect(landmarks.hasPath(from: 1, to: 4) && !landmarks.hasPath(from: 4, to: 1))
        #expect(try landmarks.distance(checkedFrom: 0, to: 4) == 7)
        #expect(throws: VertexNotFound.self) { try landmarks.distance(checkedFrom: 0, to: 9) }
        #expect(throws: VertexNotFound.self) { try landmarks.path(checkedFrom: 9, to: 0) }
        #expect(throws: VertexNotFound.self) { try landmarks.hasPath(checkedFrom: 0, to: -1) }
    }

    @Test("Farthest landmarks on an undirected path: the far end, the near end, then the middle")
    func farthest() {
        let path = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        #expect(path.altLandmarks(count: 3) { _ in 1 }.landmarks == [4, 0, 2])
        #expect(path.altLandmarks(count: 9) { _ in 1 }.landmarks.count == 5)
    }

    @Test("Empty graph, one vertex, a self-loop only, more landmarks than vertices, no landmarks")
    func small() {
        #expect(AdjacencyList<Int>().altLandmarks { _ in 1 }.landmarks.isEmpty)
        let one = AdjacencyList<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
        let landmarks = one.altLandmarks(count: 5) { _ in 3 }
        #expect(landmarks.landmarks == ["a"])
        #expect(landmarks.distance(from: "a", to: "a") == 0 && landmarks.path(from: "a", to: "a")?.edges == [])
        let none = one.altLandmarks(count: 0) { _ in 3 }
        #expect(none.landmarks.isEmpty && none.distance(from: "a", to: "a") == 0)
    }

    @Test("Random directed graphs: Dijkstra's distances, valid paths of those lengths, on several representations", .tags(.randomized))
    func directedAgainstDijkstra() async {
        await propertyCheck(count: 150, input: Gen.int(in: 1 ... 12), Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 2)) { n, seed, variant in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var arcs: [DirectedEdge<Int>] = []
            var weights: [Int] = []
            for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &draw) {
                arcs.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &draw), to: Int.random(in: 0 ..< n, using: &draw)))
                weights.append(Int.random(in: 0 ... 6, using: &draw))
            }
            let count = [0, 1, 16][variant]
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
            let landmarks = graph.altLandmarks(count: count) { weights[$0] }
            var lightest: [DirectedEdge<Int>: Int] = [:]
            for (k, arc) in arcs.enumerated() { lightest[arc] = min(lightest[arc] ?? Int.max, weights[k]) }
            let csr = CompressedSparseRow(vertexCount: n, edges: arcs)
            let csrLandmarks = csr.altLandmarks(count: count) { lightest[csr.edges[$0]]! }
            var stable = StableDirectedGraph<Int>()
            for v in 0 ..< n { stable.insert(v) }
            var stablePositions: [StableDirectedGraph<Int>.Edges.Index] = []
            for arc in arcs { stablePositions.append(stable.insert(edge: arc)) }
            if n > 2 { stable.remove(1) }
            var stableWeight: [StableDirectedGraph<Int>.Edges.Index: Int] = [:]
            for (k, p) in stablePositions.enumerated() { stableWeight[p] = weights[k] }
            let stableLandmarks = stable.altLandmarks(count: count) { stableWeight[$0]! }
            for s in 0 ..< n {
                let tree = graph.dijkstraShortestPaths(from: s) { weights[$0] }
                let stableTree = stable.contains(s) ? stable.dijkstraShortestPaths(from: s) { stableWeight[$0]! } : nil
                for t in 0 ..< n {
                    let expected = tree.distance(to: t)
                    #expect(landmarks.distance(from: s, to: t) == expected, "n \(n), seed \(seed), count \(count), \(s)→\(t)")
                    #expect(csrLandmarks.distance(from: s, to: t) == expected, "csr n \(n), seed \(seed), \(s)→\(t)")
                    if let stableTree, stable.contains(t) {
                        #expect(stableLandmarks.distance(from: s, to: t) == stableTree.distance(to: t), "stable n \(n), seed \(seed), \(s)→\(t)")
                    }
                    let path = landmarks.path(from: s, to: t)
                    #expect((path == nil) == (expected == nil))
                    if let path {
                        #expect(path.vertices.first == s && path.vertices.last == t)
                        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil, "not a path: \(path)")
                        #expect(path.weight { weights[$0] } == expected)
                    }
                }
            }
        }
    }

    @Test("Random undirected graphs: both directions of every edge, Dijkstra's distances", .tags(.randomized))
    func undirectedAgainstDijkstra() async {
        await propertyCheck(count: 100, input: Gen.int(in: 1 ... 12), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var ends: [UndirectedEdge<Int>] = []
            var weights: [Double] = []
            for _ in 0 ..< Int.random(in: 0 ... 2 * n, using: &draw) {
                ends.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &draw), Int.random(in: 0 ..< n, using: &draw)))
                weights.append(Double(Int.random(in: 0 ... 9, using: &draw)) / 2)
            }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: ends)
            let landmarks = graph.altLandmarks(count: 3) { weights[$0] }
            for s in 0 ..< n {
                let tree = graph.dijkstraShortestPaths(from: s) { weights[$0] }
                for t in 0 ..< n {
                    #expect(landmarks.distance(from: s, to: t) == tree.distance(to: t), "n \(n), seed \(seed), \(s)→\(t)")
                    if let path = landmarks.path(from: s, to: t) {
                        #expect(Path(vertices: path.vertices, edges: path.edges.map(\.position), in: graph) != nil, "not a path: \(path)")
                        #expect(path.weight { weights[$0.position] } == tree.distance(to: t))
                    }
                }
            }
        }
    }

    @Test("Negative weights and a negative count trap")
    func negative() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.altLandmarks { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.altLandmarks(count: -1) { _ in 1 }
        }
    }
}
