// Disconnected graphs: every entry point but `primMinimumSpanningTree(from:)` returns a forest of
// n − c edges, one tree per component; `from:` returns the root's component only, as Boost's
// predecessor map does. Case IDs (ST-nn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

@Suite("Spanning forests of disconnected graphs")
struct ForestTests {
    @Test("ST-40 two components (NetworkX test_disconnected): both edges")
    func twoComponents() {
        let edges: [(Int, Int, Int)] = [(0, 1, 1), (2, 3, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 3)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 2)
        #expect(Set(boruvka.edges) == [0, 1])
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 2)
        #expect(Set(prim.edges) == [0, 1])
        #expect(prim.weight == 3)
        #expect(graph.maximumSpanningTree { edges[$0].2 }.edges == [1, 0])
        #expect(graph.minimumSpanningTree().edges == [0, 1])
        #expect(graph.primMinimumSpanningTree(from: 2) { edges[$0].2 }.edges == [1])
    }

    @Test("ST-41 three isolated vertices (NetworkX empty_graph(3)): the empty forest")
    func threeIsolated() {
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
        let tree = graph.minimumSpanningTree { _ in 1 }
        #expect(tree.edges == [])
        #expect(tree.weight == 0)
        #expect(graph.kruskalMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.primMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.maximumSpanningTree { _ in 1 } == tree)
        for root in 0 ..< 3 {
            #expect(graph.primMinimumSpanningTree(from: root) { _ in 1 } == tree)
        }
        #expect(graph.minimumSpanningTree().edges == [])
    }

    @Test("ST-42 an isolated vertex listed last (NetworkX test_isolated_node)")
    func isolatedVertexLast() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let edges = wiki.map { ($0.0 + 1, $0.1 + 1, $0.2) }
        let graph = ReferencePseudograph(vertices: [1, 2, 3, 4, 5, 6, 7, 0], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [1, 5, 7, 0, 4, 9]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 39)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 6)
        #expect(Set(boruvka.edges) == Set(canonical))
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 6)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 39)
        // 0 is in no edge.
        #expect(!tree.edges.contains { graph.edges[$0].u == 0 || graph.edges[$0].v == 0 })
        let fromIsolated = graph.primMinimumSpanningTree(from: 0) { edges[$0].2 }
        #expect(fromIsolated.edges == [])
        #expect(fromIsolated.weight == 0)
    }

    @Test("ST-43 petgraph's mst_kruskal with a disjoint part: 41, n − 2 edges")
    func petgraphDisjoint() {
        let edges: [(String, String, Int)] = [
            ("A", "B", 7), ("A", "D", 5), ("D", "B", 9), ("B", "C", 8), ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6),
            ("F", "E", 8), ("F", "G", 11), ("E", "G", 9), ("H", "I", 1), ("H", "J", 3), ("I", "J", 1),
        ]
        let vertices = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        let graph = ReferencePseudograph(vertices: vertices, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [11, 13, 1, 5, 7, 0, 4, 10]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 41)
        #expect(tree.edges.count == vertices.count - 2)
        // H–I and I–J are in; H–J, D–B and B–C are not.
        #expect(tree.edges.contains(11) && tree.edges.contains(13))
        #expect(!tree.edges.contains(12) && !tree.edges.contains(2) && !tree.edges.contains(3))
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 8)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 41)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 8)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 41)
        let fromH = graph.primMinimumSpanningTree(from: "H") { edges[$0].2 }
        #expect(Set(fromH.edges) == [11, 13])
        #expect(fromH.weight == 2)
        let fromA = graph.primMinimumSpanningTree(from: "A") { edges[$0].2 }
        #expect(Set(fromA.edges) == [1, 5, 7, 0, 4, 10])
        #expect(fromA.weight == 39)
    }

    @Test("ST-44 JGraphT's testSimpleDisconnectedWeightedGraph: 60, unique")
    func jgraphtDisconnected() {
        let edges: [(String, String, Int)] = [
            ("A", "B", 5), ("A", "C", 10), ("B", "D", 15), ("C", "D", 20), ("E", "F", 20), ("E", "G", 15), ("G", "H", 10), ("F", "H", 5),
        ]
        let graph = ReferencePseudograph(vertices: ["A", "B", "C", "D", "E", "F", "G", "H"], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [0, 7, 1, 6, 2, 5]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 60)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 6)
        #expect(Set(boruvka.edges) == Set(canonical))
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 6)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 60)
        // JGraphT's expected set: ab, ac, bd, eg, gh, fh.
        let expected: Set = [
            UndirectedEdge("A", "B"), UndirectedEdge("A", "C"), UndirectedEdge("B", "D"), UndirectedEdge("E", "G"), UndirectedEdge("G", "H"),
            UndirectedEdge("F", "H"),
        ]
        #expect(Set(tree.edges.map { graph.edges[$0] }) == expected)
        #expect(graph.primMinimumSpanningTree(from: "F") { edges[$0].2 }.weight == 30)
    }

    @Test("ST-45 scipy's test_minimum_spanning_tree graph: 7, scipy's expected matrix")
    func scipyGraph() {
        let edges: [(Int, Int, Int)] = [(0, 1, 1), (2, 3, 8), (2, 4, 5), (3, 4, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 3, 2])
        #expect(tree.weight == 7)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [0, 3, 2])
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 3)
        #expect(Set(prim.edges) == [0, 3, 2])
        #expect(Set(tree.edges.map { graph.edges[$0] }) == [UndirectedEdge(0, 1), UndirectedEdge(3, 4), UndirectedEdge(2, 4)])
    }

    @Test("ST-46 seven isolated vertices (petgraph mst_prim_graph_without_edges)")
    func sevenIsolated() {
        let graph = ReferencePseudograph<String>(vertices: ["a", "b", "c", "d", "e", "f", "g"], edges: [])
        let tree = graph.minimumSpanningTree { _ in 1 }
        #expect(tree.edges == [])
        #expect(tree.weight == 0)
        #expect(graph.kruskalMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.primMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.primMinimumSpanningTree(from: "d") { _ in 1 } == tree)
        #expect(graph.maximumSpanningTree { _ in 1 } == tree)
        #expect(graph.minimumSpanningTree().edges == [])
    }

    @Test("ST-47 Prim's forest spans every component; from: spans only the root's")
    func primRoots() {
        let edges: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 2), (0, 2, 3), (3, 4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1, 3])
        #expect(tree.weight == 8)
        let forest = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(forest.edges.count == 3)
        #expect(Set(forest.edges) == [0, 1, 3])
        #expect(forest.weight == 8)
        for root in [0, 1, 2] {
            let rooted = graph.primMinimumSpanningTree(from: root) { edges[$0].2 }
            #expect(rooted.edges.count == 2, "from \(root)")
            #expect(Set(rooted.edges) == [0, 1], "from \(root)")
            #expect(rooted.weight == 3, "from \(root)")
        }
        for root in [3, 4] {
            let rooted = graph.primMinimumSpanningTree(from: root) { edges[$0].2 }
            #expect(rooted.edges == [3], "from \(root)")
            #expect(rooted.weight == 5, "from \(root)")
        }
        let fromFive = graph.primMinimumSpanningTree(from: 5) { edges[$0].2 }
        #expect(fromFive.edges == [])
        #expect(fromFive.weight == 0)
    }

    @Test("ST-48 scipy's planted path: Kₙ with weights in [3, 4) and a path at weight 1", .tags(.randomized), arguments: [5, 10, 15, 20])
    func plantedPath(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(48 + n))
        var edges: [(Int, Int, Double)] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n {
                edges.append((u, v, v == u + 1 ? 1 : Double.random(in: 3 ..< 4, using: &rng)))
            }
        }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        // The path's positions, in position order (every one weighs 1).
        let path = edges.indices.filter { edges[$0].1 == edges[$0].0 + 1 }
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == path)
        #expect(tree.weight == Double(n - 1))
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == n - 1)
        #expect(Set(boruvka.edges) == Set(path))
        #expect(boruvka.weight == Double(n - 1))
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == n - 1)
        #expect(Set(prim.edges) == Set(path))
        #expect(prim.weight == Double(n - 1))
    }
}
