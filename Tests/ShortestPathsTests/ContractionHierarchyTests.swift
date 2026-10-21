// `contractionHierarchy(weight:)`: every query distance is Dijkstra's and every path is a path of
// that length, on random directed and undirected graphs with parallel edges, loops and zero weights,
// on several representations; small hand-worked cases; the empty and one-vertex graphs; the
// checked lookups.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing
import Walks

@Suite("contractionHierarchy")
struct ContractionHierarchyTests {
    @Test("A hand-worked road: the shortcut through the middle, the path unpacked to the edges")
    func road() throws {
        // 0 → 1 → 2 → 3 in a line, plus the detour 0 → 3 of weight 10 and a parallel 1 → 2 of weight 5.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2)]
        let weights = [1, 2, 3, 10, 5]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: edges)
        let hierarchy = graph.contractionHierarchy { weights[$0] }
        #expect(hierarchy.distance(from: 0, to: 3) == 6)
        #expect(hierarchy.distance(from: 3, to: 0) == nil)
        #expect(hierarchy.distance(from: 2, to: 2) == 0)
        let path = try #require(hierarchy.path(from: 0, to: 3))
        #expect(path.vertices == [0, 1, 2, 3] && path.edges == [0, 1, 2])
        #expect(hierarchy.path(from: 1, to: 1)?.vertices == [1])
        #expect(hierarchy.hasPath(from: 1, to: 3) && !hierarchy.hasPath(from: 3, to: 1))
        #expect(try hierarchy.distance(checkedFrom: 0, to: 3) == 6)
        #expect(throws: VertexNotFound.self) { try hierarchy.distance(checkedFrom: 0, to: 9) }
        #expect(throws: VertexNotFound.self) { try hierarchy.path(checkedFrom: 9, to: 0) }
        #expect(throws: VertexNotFound.self) { try hierarchy.hasPath(checkedFrom: 0, to: -1) }
    }

    @Test("A complete graph with unit weights needs no shortcut, whatever the witness budget; on random graphs the budget changes the shortcuts but not the distances")
    func witnesses() {
        var arcs: [DirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in 0 ..< 5 where u != v { arcs.append(DirectedEdge(from: u, to: v)) } }
        let complete = AdjacencyList<Int>(vertices: 0 ..< 5, edges: arcs)
        #expect(complete.contractionHierarchy { _ in 1 }.shortcutCount == 0)
        #expect(complete.contractionHierarchy(witnessLimit: 0) { _ in 1 }.shortcutCount == 0)
        var fewer = 0
        for seed in 0 ..< 10 {
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var edges: [DirectedEdge<Int>] = []
            var weights: [Int] = []
            for _ in 0 ..< 36 {
                edges.append(DirectedEdge(from: Int.random(in: 0 ..< 12, using: &draw), to: Int.random(in: 0 ..< 12, using: &draw)))
                weights.append(Int.random(in: 1 ... 9, using: &draw))
            }
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 12, edges: edges)
            let searched = graph.contractionHierarchy { weights[$0] }
            let unsearched = graph.contractionHierarchy(witnessLimit: 0) { weights[$0] }
            // The budget changes the shortcuts (and, through the priorities, the order), never the distances.
            if searched.shortcutCount != unsearched.shortcutCount { fewer += 1 }
            for s in 0 ..< 12 {
                for t in 0 ..< 12 { #expect(searched.distance(from: s, to: t) == unsearched.distance(from: s, to: t)) }
            }
        }
        #expect(fewer > 0)
    }

    @Test("Empty graph, one vertex, a self-loop only")
    func small() {
        #expect(AdjacencyList<Int>().contractionHierarchy { _ in 1 }.shortcutCount == 0)
        let one = AdjacencyList<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
        let hierarchy = one.contractionHierarchy { _ in 3 }
        #expect(hierarchy.distance(from: "a", to: "a") == 0 && hierarchy.path(from: "a", to: "a")?.edges == [])
    }

    @Test("Random directed graphs: Dijkstra's distances, valid paths of those lengths, on several representations", .tags(.randomized))
    func directedAgainstDijkstra() async {
        await propertyCheck(count: 150, input: Gen.int(in: 1 ... 12), Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 2)) { n, seed, variant in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var arcs: [DirectedEdge<Int>] = []
            var weights: [Int] = []
            let m = Int.random(in: 0 ... 3 * n, using: &draw)
            for _ in 0 ..< m {
                arcs.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &draw), to: Int.random(in: 0 ..< n, using: &draw)))
                weights.append(Int.random(in: 0 ... 6, using: &draw))
            }
            let limit = [0, 3, 500][variant]
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
            let hierarchy = graph.contractionHierarchy(witnessLimit: limit) { weights[$0] }
            // The rows reorder the edges: weighed by endpoints, the lightest of a parallel pair.
            var lightest: [DirectedEdge<Int>: Int] = [:]
            for (k, arc) in arcs.enumerated() { lightest[arc] = min(lightest[arc] ?? Int.max, weights[k]) }
            let csr = CompressedSparseRow(vertexCount: n, edges: arcs)
            let csrHierarchy = csr.contractionHierarchy(witnessLimit: limit) { lightest[csr.edges[$0]]! }
            var stable = StableDirectedGraph<Int>()
            for v in 0 ..< n { stable.insert(v) }
            var stablePositions: [StableDirectedGraph<Int>.Edges.Index] = []
            for arc in arcs { stablePositions.append(stable.insert(edge: arc)) }
            if n > 2 { stable.remove(1) }
            var stableWeight: [StableDirectedGraph<Int>.Edges.Index: Int] = [:]
            for (k, p) in stablePositions.enumerated() { stableWeight[p] = weights[k] }
            let stableHierarchy = stable.contractionHierarchy(witnessLimit: limit) { stableWeight[$0]! }
            for s in 0 ..< n {
                let tree = graph.dijkstraShortestPaths(from: s) { weights[$0] }
                let stableTree = stable.contains(s) ? stable.dijkstraShortestPaths(from: s) { stableWeight[$0]! } : nil
                for t in 0 ..< n {
                    let expected = tree.distance(to: t)
                    #expect(hierarchy.distance(from: s, to: t) == expected, "n \(n), seed \(seed), \(s)→\(t)")
                    #expect(csrHierarchy.distance(from: s, to: t) == expected, "csr n \(n), seed \(seed), \(s)→\(t)")
                    if let stableTree, stable.contains(t) {
                        #expect(stableHierarchy.distance(from: s, to: t) == stableTree.distance(to: t), "stable n \(n), seed \(seed), \(s)→\(t)")
                    }
                    let path = hierarchy.path(from: s, to: t)
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
            let hierarchy = graph.contractionHierarchy { weights[$0] }
            for s in 0 ..< n {
                let tree = graph.dijkstraShortestPaths(from: s) { weights[$0] }
                for t in 0 ..< n {
                    #expect(hierarchy.distance(from: s, to: t) == tree.distance(to: t), "n \(n), seed \(seed), \(s)→\(t)")
                    if let path = hierarchy.path(from: s, to: t) {
                        #expect(Path(vertices: path.vertices, edges: path.edges.map(\.position), in: graph) != nil, "not a path: \(path)")
                        #expect(path.weight { weights[$0.position] } == tree.distance(to: t))
                    }
                }
            }
        }
    }

    @Test("Negative weights trap")
    func negative() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.contractionHierarchy { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.contractionHierarchy(witnessLimit: -1) { _ in 1 }
        }
    }
}
