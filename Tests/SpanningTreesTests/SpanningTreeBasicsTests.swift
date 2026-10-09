// The trivial cases and the graphs the established suites pin: NetworkX's Wikipedia graph,
// petgraph's Prim example and its TEST_CASES, JGraphT's, Boost's and LEMON's examples, NetworkX's
// spanning-tree-iterator graph and igraph's Frucht graph. Every case runs under every algorithm:
// the default, Kruskal and Borůvka give the canonical forest (Borůvka as a set), and Prim gives
// the same weight, and the same set where the optimum is unique. Case IDs (ST-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

@Suite("Spanning-tree basics")
struct SpanningTreeBasicsTests {
    @Test("ST-01 a graph with no vertices has the empty forest, of weight zero")
    func emptyGraph() {
        let graph = ReferencePseudograph<Int>(edges: [])
        var asked = 0
        let weight: (Int) -> Int = { _ in
            asked += 1
            return 1
        }
        let tree = graph.minimumSpanningTree(weight: weight)
        #expect(tree.edges == [])
        #expect(tree.weight == 0)
        #expect(graph.kruskalMinimumSpanningTree(weight: weight) == tree)
        #expect(graph.boruvkaMinimumSpanningTree(weight: weight) == tree)
        #expect(graph.primMinimumSpanningTree(weight: weight) == tree)
        #expect(graph.maximumSpanningTree(weight: weight) == tree)
        #expect(graph.minimumSpanningTree().edges == [])
        #expect(graph.minimumSpanningTree().weight == 0)
        #expect(asked == 0)

        let list = UndirectedAdjacencyList<String>()
        #expect(list.minimumSpanningTree { _ in 1.5 }.edges == [])
        #expect(list.minimumSpanningTree { _ in 1.5 }.weight == 0)
        #expect(list.primMinimumSpanningTree { _ in 1.5 }.weight == 0)
        #expect(list.boruvkaMinimumSpanningTree { _ in 1.5 }.edges == [])
    }

    @Test("ST-02 a single vertex with no edges has the empty forest")
    func singleVertex() {
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = graph.minimumSpanningTree { _ in 1 }
        #expect(tree.edges == [])
        #expect(tree.weight == 0)
        #expect(graph.kruskalMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.primMinimumSpanningTree { _ in 1 } == tree)
        #expect(graph.primMinimumSpanningTree(from: 0) { _ in 1 } == tree)
        #expect(graph.maximumSpanningTree { _ in 1 } == tree)
        #expect(graph.minimumSpanningTree().edges == [])
    }

    @Test("ST-03 one edge (petgraph mst_prim_trivial_graph)")
    func oneEdge() {
        let edges: [(String, String, Int)] = [("A", "B", 7)]
        let graph = ReferencePseudograph(edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0])
        #expect(tree.weight == 7)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree(from: "A") { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree(from: "B") { edges[$0].2 } == tree)
        #expect(graph.maximumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.minimumSpanningTree().edges == [0])
        #expect(graph.minimumSpanningTree().weight == 1)
    }

    @Test("ST-04 Wikipedia's Kruskal graph (NetworkX test_minimum_edges): 39, unique, from every Prim root")
    func wikipedia() {
        let edges: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        // Nondecreasing (weight, position): 0–3 (5), 2–4 (5), 3–5 (6), 0–1 (7), 1–4 (7), 4–6 (9).
        let canonical = [1, 5, 7, 0, 4, 9]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 39)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 6)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 39)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 6)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 39)
        for root in 0 ..< 7 {
            let rooted = graph.primMinimumSpanningTree(from: root) { edges[$0].2 }
            #expect(rooted.edges.count == 6, "from \(root)")
            #expect(Set(rooted.edges) == Set(canonical), "from \(root)")
            #expect(rooted.weight == 39, "from \(root)")
        }
        // NetworkX's expected edge set.
        let expected: Set = [UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 4), UndirectedEdge(3, 5), UndirectedEdge(4, 6)]
        #expect(Set(tree.edges.map { graph.edges[$0] }) == expected)
    }

    @Test("ST-05 petgraph's mst_prim graph, with String vertices: 39, unique")
    func petgraphPrim() {
        let edges: [(String, String, Int)] = [
            ("B", "A", 7), ("D", "A", 5), ("D", "B", 9), ("B", "C", 8), ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6),
            ("F", "E", 8), ("F", "G", 11), ("E", "G", 9),
        ]
        let graph = ReferencePseudograph(vertices: ["A", "B", "C", "D", "E", "F", "G"], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [1, 5, 7, 0, 4, 10]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 39)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 6)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 39)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 6)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 39)
        // petgraph's expected set: A–D, A–B, D–F, B–E, E–C, E–G.
        let expected: Set = [
            UndirectedEdge("A", "D"), UndirectedEdge("A", "B"), UndirectedEdge("D", "F"), UndirectedEdge("B", "E"), UndirectedEdge("E", "C"),
            UndirectedEdge("E", "G"),
        ]
        #expect(Set(tree.edges.map { graph.edges[$0] }) == expected)
    }

    @Test("ST-06 petgraph's min_spanning_tree doc example: 9, unique")
    func petgraphDocExample() {
        let edges: [(Int, Int, Int)] = [(0, 1, 2), (0, 3, 4), (1, 2, 1), (1, 5, 7), (2, 4, 5), (4, 5, 1), (3, 4, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [2, 5, 6, 0, 1]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 9)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 5)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 9)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 5)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 9)
    }

    @Test("ST-07 JGraphT's testSimpleConnectedWeightedGraph: 15, unique")
    func jgraphtConnected() {
        let edges: [(String, String, Int)] = [("A", "B", 2), ("A", "C", 3), ("B", "D", 5), ("C", "D", 20), ("D", "E", 5), ("A", "E", 100)]
        let graph = ReferencePseudograph(vertices: ["A", "B", "C", "D", "E"], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [0, 1, 2, 4]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 15)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 4)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 15)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 4)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 15)
        for root in ["A", "B", "C", "D", "E"] {
            #expect(Set(graph.primMinimumSpanningTree(from: root) { edges[$0].2 }.edges) == Set(canonical), "from \(root)")
        }
    }

    @Test("ST-08 Boost's kruskal doc example: 10, two optima (0–1 or 1–3)")
    func boostKruskalDoc() {
        let edges: [(Int, Int, Int)] = [(0, 1, 2), (0, 3, 1), (1, 2, 3), (1, 3, 2), (2, 3, 5), (2, 4, 4), (3, 4, 6)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        // 0–1 and 1–3 both weigh 2; position 0 comes first, so the canonical forest takes 0–1.
        let canonical = [1, 0, 2, 5]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 10)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 4)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 10)
        // Prim's ties are unspecified: either optimum.
        let optima: [Set<Int>] = [[1, 0, 2, 5], [1, 3, 2, 5]]
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 4)
        #expect(optima.contains(Set(prim.edges)))
        #expect(prim.weight == 10)
    }

    @Test("ST-09 Boost's prim doc example: 10, two optima")
    func boostPrimDoc() {
        let edges: [(Int, Int, Int)] = [(0, 1, 2), (0, 3, 1), (1, 2, 3), (1, 3, 2), (2, 4, 4), (3, 4, 6)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [1, 0, 2, 4]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 10)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 4)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 10)
        let optima: [Set<Int>] = [[1, 0, 2, 4], [1, 3, 2, 4]]
        let prims = [graph.primMinimumSpanningTree { edges[$0].2 }, graph.primMinimumSpanningTree(from: 0) { edges[$0].2 }]
        for prim in prims {
            #expect(prim.edges.count == 4)
            #expect(optima.contains(Set(prim.edges)))
            #expect(prim.weight == 10)
        }
    }

    @Test("ST-10 Boost's prim-example.cpp: 4, unique, and Prim from 0 matches Boost's predecessor map")
    func boostPrimExample() {
        let edges: [(Int, Int, Int)] = [(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [0, 1, 5, 6]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 4)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 4)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 4)
        #expect(Set(graph.primMinimumSpanningTree { edges[$0].2 }.edges) == Set(canonical))
        // Boost: p[1] = 3, p[2] = 0, p[3] = 4, p[4] = 0; those are positions 1, 0, 5 and 6.
        let fromZero = graph.primMinimumSpanningTree(from: 0) { edges[$0].2 }
        #expect(fromZero.edges.count == 4)
        #expect(Set(fromZero.edges) == [0, 1, 5, 6])
        #expect(fromZero.weight == 4)
        // Each edge joins a vertex already spanned to a new one, starting at the root.
        var spanned: Set = [0]
        for position in fromZero.edges {
            let (u, v, _) = edges[position]
            #expect(spanned.contains(u) != spanned.contains(v), "\(position)")
            spanned.formUnion([u, v])
        }
    }

    @Test("ST-11 LEMON's kruskal_test with every cost 2: 10, 81 optima")
    func lemonConstantCost() {
        let pairs = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (3, 2), (2, 4), (4, 3), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        // Every weight equal: the canonical forest is the first forest in position order.
        let canonical = [0, 1, 4, 6, 8]
        let tree = graph.minimumSpanningTree { _ in 2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 10)
        #expect(graph.kruskalMinimumSpanningTree { _ in 2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { _ in 2 }
        #expect(boruvka.edges.count == 5)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 10)
        let prim = graph.primMinimumSpanningTree { _ in 2 }
        #expect(prim.edges.count == 5)
        #expect(prim.weight == 10)
        #expect(graph.minimumSpanningTree().edges == canonical)
        #expect(graph.minimumSpanningTree().weight == 5)
    }

    @Test("ST-12 LEMON's kruskal_test with costs −10…−1: −31, e1 e2 e5 e7 e9 in that order")
    func lemonNegativeCosts() {
        let pairs = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (3, 2), (2, 4), (4, 3), (3, 5), (4, 5)]
        let edges = pairs.enumerated().map { ($0.element.0, $0.element.1, -10 + $0.offset) }
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        // LEMON checks the output order: by weight, which here is position order.
        let canonical = [0, 1, 4, 6, 8]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == -31)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 5)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == -31)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 5)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == -31)
    }

    @Test("ST-13 petgraph TEST_CASES, order 9: 112, in petgraph's order")
    func petgraphOrder9() {
        let edges: [(Int, Int, Int)] = [
            (0, 2, 107), (0, 3, 24), (0, 4, 47), (0, 5, 60), (0, 6, 98), (0, 7, 29), (0, 8, 20), (1, 2, 62), (1, 3, 115), (1, 6, 42),
            (1, 7, 117), (1, 8, 19), (2, 3, 39), (2, 4, 12), (2, 5, 27), (2, 7, 3), (2, 8, 66), (3, 4, 54), (3, 5, 129), (3, 6, 18),
            (3, 7, 137), (3, 8, 120), (4, 5, 9), (4, 6, 124), (4, 7, 103), (4, 8, 7), (5, 7, 77), (5, 8, 63), (6, 7, 130), (7, 8, 138),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [15, 25, 22, 13, 19, 11, 6, 1]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 112)
        // petgraph's expected list, in its order.
        let petgraph = [
            UndirectedEdge(2, 7), UndirectedEdge(4, 8), UndirectedEdge(4, 5), UndirectedEdge(2, 4), UndirectedEdge(3, 6), UndirectedEdge(1, 8),
            UndirectedEdge(0, 8), UndirectedEdge(0, 3),
        ]
        #expect(tree.edges.map { graph.edges[$0] } == petgraph)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 8)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 112)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 8)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 112)
    }

    @Test("ST-14 petgraph TEST_CASES, order 10: 257, in petgraph's order")
    func petgraphOrder10() {
        let edges: [(Int, Int, Int)] = [
            (0, 2, 84), (0, 4, 5), (0, 5, 17), (0, 6, 97), (0, 7, 74), (0, 8, 16), (1, 3, 49), (1, 4, 28), (1, 8, 51), (1, 9, 137),
            (2, 3, 125), (2, 4, 87), (2, 6, 114), (2, 8, 131), (3, 4, 136), (3, 5, 43), (3, 8, 24), (3, 9, 112), (4, 5, 61), (4, 7, 99),
            (4, 8, 63), (4, 9, 108), (5, 6, 13), (5, 7, 9), (5, 8, 133), (6, 9, 147), (7, 8, 10), (7, 9, 88), (8, 9, 68),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [1, 23, 26, 22, 5, 16, 7, 28, 0]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 257)
        let petgraph = [
            UndirectedEdge(0, 4), UndirectedEdge(5, 7), UndirectedEdge(7, 8), UndirectedEdge(5, 6), UndirectedEdge(0, 8), UndirectedEdge(3, 8),
            UndirectedEdge(1, 4), UndirectedEdge(8, 9), UndirectedEdge(0, 2),
        ]
        #expect(tree.edges.map { graph.edges[$0] } == petgraph)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 9)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 257)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 9)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 257)
    }

    @Test("ST-15 petgraph TEST_CASES, order 15: 503, in petgraph's order")
    func petgraphOrder15() {
        let edges: [(Int, Int, Int)] = [
            (0, 1, 124), (0, 3, 126), (0, 6, 84), (0, 7, 87), (0, 9, 93), (0, 12, 32), (1, 2, 51), (1, 4, 144), (1, 6, 36), (1, 8, 46),
            (1, 9, 8), (1, 13, 26), (2, 8, 111), (3, 4, 114), (3, 6, 98), (3, 8, 86), (3, 9, 73), (4, 5, 41), (4, 6, 7), (4, 8, 82),
            (4, 9, 48), (4, 10, 113), (4, 11, 54), (4, 12, 10), (5, 8, 60), (5, 13, 34), (6, 13, 85), (6, 14, 52), (7, 8, 74), (7, 12, 137),
            (8, 10, 118), (8, 12, 69), (8, 13, 133), (9, 12, 13), (10, 12, 65), (10, 14, 107), (11, 14, 102), (12, 13, 140), (12, 14, 11),
            (13, 14, 25),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 15, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [18, 10, 23, 38, 33, 39, 5, 25, 9, 6, 22, 34, 16, 28]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 503)
        let petgraph = [
            UndirectedEdge(4, 6), UndirectedEdge(1, 9), UndirectedEdge(4, 12), UndirectedEdge(12, 14), UndirectedEdge(9, 12), UndirectedEdge(13, 14),
            UndirectedEdge(0, 12), UndirectedEdge(5, 13), UndirectedEdge(1, 8), UndirectedEdge(1, 2), UndirectedEdge(4, 11), UndirectedEdge(10, 12),
            UndirectedEdge(3, 9), UndirectedEdge(7, 8),
        ]
        #expect(tree.edges.map { graph.edges[$0] } == petgraph)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 14)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 503)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 14)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 503)
    }

    @Test("ST-16 petgraph TEST_CASES, order 20: 699, in petgraph's order; vertex 19 hangs on one edge")
    func petgraphOrder20() {
        let edges: [(Int, Int, Int)] = [
            (0, 2, 5), (0, 19, 73), (0, 12, 3), (1, 17, 145), (1, 18, 16), (1, 3, 125), (1, 5, 6), (1, 10, 76), (1, 11, 13), (1, 15, 12),
            (2, 7, 34), (2, 9, 118), (3, 12, 43), (3, 13, 146), (4, 7, 31), (5, 6, 62), (5, 8, 147), (6, 14, 66), (7, 16, 67), (7, 17, 48),
            (7, 10, 93), (7, 12, 113), (7, 14, 85), (8, 16, 40), (8, 18, 111), (9, 17, 102), (10, 16, 128), (10, 18, 120), (11, 17, 35),
            (11, 18, 88), (11, 13, 54), (11, 14, 36), (12, 16, 148), (13, 15, 75), (16, 17, 71), (16, 18, 10),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 20, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [2, 0, 6, 35, 9, 8, 4, 14, 10, 28, 31, 23, 12, 19, 30, 15, 1, 7, 25]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 699)
        let petgraph = [
            UndirectedEdge(0, 12), UndirectedEdge(0, 2), UndirectedEdge(1, 5), UndirectedEdge(16, 18), UndirectedEdge(1, 15), UndirectedEdge(1, 11),
            UndirectedEdge(1, 18), UndirectedEdge(4, 7), UndirectedEdge(2, 7), UndirectedEdge(11, 17), UndirectedEdge(11, 14), UndirectedEdge(8, 16),
            UndirectedEdge(3, 12), UndirectedEdge(7, 17), UndirectedEdge(11, 13), UndirectedEdge(5, 6), UndirectedEdge(0, 19), UndirectedEdge(1, 10),
            UndirectedEdge(9, 17),
        ]
        #expect(tree.edges.map { graph.edges[$0] } == petgraph)
        #expect(tree.edges.contains(1))
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 19)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 699)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 19)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 699)
        // From the leaf, the same tree.
        #expect(Set(graph.primMinimumSpanningTree(from: 19) { edges[$0].2 }.edges) == Set(canonical))
    }

    @Test("ST-17 NetworkX test_attributes: 2, unique")
    func networkXAttributes() {
        let edges: [(Int, Int, Int)] = [(1, 2, 1), (2, 3, 1), (1, 3, 10)]
        let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 2)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 2)
        #expect(Set(boruvka.edges) == [0, 1])
        #expect(boruvka.weight == 2)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 2)
        #expect(Set(prim.edges) == [0, 1])
        #expect(prim.weight == 2)
    }

    @Test("ST-18 NetworkX's spanning-tree-iterator graph (Sörensen–Janssens): 17, unique")
    func sorensenJanssens() {
        let edges: [(Int, Int, Int)] = [(0, 1, 5), (1, 2, 4), (1, 4, 6), (2, 3, 5), (2, 4, 7), (3, 4, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [5, 1, 0, 3]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 17)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 4)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 17)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 4)
        #expect(Set(prim.edges) == Set(canonical))
        #expect(prim.weight == 17)
    }

    @Test("ST-19 igraph's Frucht graph weighed by edge betweenness: min 293/4, max 410/4, both unique")
    func igraphFrucht() {
        // igraph's edge order; the weights are 4 × betweenness, so Int is exact and Double (÷ 4) too.
        let pairs = [
            (0, 1), (0, 2), (0, 11), (1, 3), (1, 6), (2, 5), (2, 10), (3, 4), (3, 6), (4, 8), (4, 11), (5, 9), (5, 10), (6, 7), (7, 8), (7, 9),
            (8, 9), (10, 11),
        ]
        let quarters = [45, 38, 27, 19, 30, 29, 13, 33, 18, 39, 46, 49, 24, 38, 18, 32, 25, 33]
        let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let minimum = [6, 8, 14, 3, 12, 16, 2, 7, 17, 13, 0]
        let tree = graph.minimumSpanningTree { quarters[$0] }
        #expect(tree.edges == minimum)
        #expect(tree.weight == 293)
        // igraph's output, as a set.
        #expect(Set(tree.edges) == [2, 17, 6, 12, 0, 3, 8, 7, 13, 14, 16])
        #expect(graph.kruskalMinimumSpanningTree { quarters[$0] } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { quarters[$0] }
        #expect(boruvka.edges.count == 11)
        #expect(Set(boruvka.edges) == Set(minimum))
        let prim = graph.primMinimumSpanningTree { quarters[$0] }
        #expect(prim.edges.count == 11)
        #expect(Set(prim.edges) == Set(minimum))
        #expect(prim.weight == 293)

        let betweenness = quarters.map { Double($0) / 4 }
        let doubleTree = graph.minimumSpanningTree { betweenness[$0] }
        #expect(doubleTree.edges == minimum)
        #expect(doubleTree.weight == 73.25)
        #expect(graph.primMinimumSpanningTree { betweenness[$0] }.weight == 73.25)
        #expect(graph.boruvkaMinimumSpanningTree { betweenness[$0] }.weight == 73.25)

        let maximum = graph.maximumSpanningTree { quarters[$0] }
        #expect(maximum.edges == [11, 10, 0, 9, 1, 13, 7, 17, 15, 4, 2])
        #expect(maximum.weight == 410)
        #expect(graph.maximumSpanningTree { betweenness[$0] }.weight == 102.5)
    }
}
