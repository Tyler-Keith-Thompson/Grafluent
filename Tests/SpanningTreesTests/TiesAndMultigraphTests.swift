// The tie rule (weight, position), self-loops (never in the forest and never weighed), parallel
// edges (the lightest copy, and among equal copies the first), zero weights, and NetworkX's and
// Boost's multigraphs. Where the optimum is not unique Prim is checked on its weight and on being
// one of the optima. Case IDs (ST-nn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

@Suite("Ties, self-loops and parallel edges", .tags(.selfLoops))
struct TiesAndMultigraphTests {
    @Test("ST-25 a triangle of equal weights: the first two positions")
    func equalTriangle() {
        let edges: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (0, 2, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 2)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 2)
        #expect(Set(boruvka.edges) == [0, 1])
        // Any two of the three edges is an optimum.
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 2)
        #expect(Set(prim.edges).count == 2)
        #expect(prim.weight == 2)
        #expect(graph.minimumSpanningTree().edges == [0, 1])
        #expect(graph.minimumSpanningTree().weight == 2)
    }

    @Test("ST-26 K₄ with every weight 1, in combinations order: the star at 0, one of 16 optima")
    func uniformK4() {
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { _ in 1 }
        #expect(tree.edges == [0, 1, 2])
        #expect(tree.weight == 3)
        #expect(graph.kruskalMinimumSpanningTree { _ in 1 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { _ in 1 }
        #expect(boruvka.edges.count == 3)
        #expect(Set(boruvka.edges) == [0, 1, 2])
        #expect(graph.minimumSpanningTree().edges == [0, 1, 2])
        // Prim gives some spanning tree: three distinct edges joining all four vertices.
        let prim = graph.primMinimumSpanningTree { _ in 1 }
        #expect(prim.weight == 3)
        var parent = Array(0 ..< 4)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for position in prim.edges {
            let (ru, rv) = (find(pairs[position].0), find(pairs[position].1))
            #expect(ru != rv, "\(prim.edges) has a cycle")
            parent[ru] = rv
        }
        #expect(prim.edges.count == 3)
    }

    @Test("ST-27 Boost's kruskal-example.cpp: 4, exactly kruskal.expected; parallel 1–4 at 2 and 1")
    func boostKruskalExample() {
        let edges: [(Int, Int, Int)] = [(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [0, 1, 5, 6]
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 4)
        // Boost's expected output: 0–2, 3–4, 4–0, 1–3.
        #expect(Set(tree.edges.map { graph.edges[$0] }) == [UndirectedEdge(0, 2), UndirectedEdge(3, 4), UndirectedEdge(4, 0), UndirectedEdge(1, 3)])
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 4)
        #expect(Set(boruvka.edges) == Set(canonical))
        #expect(boruvka.weight == 4)
        // Three optima: 0–2 and 4–0 with any two of 1–3, 3–4 and 4–1 (position 7).
        let optima: [Set<Int>] = [[0, 6, 1, 5], [0, 6, 1, 7], [0, 6, 5, 7]]
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 4)
        #expect(optima.contains(Set(prim.edges)))
        #expect(prim.weight == 4)
        // The heavier copy of 1–4 (position 2) is never in an optimum.
        #expect(!prim.edges.contains(2))
    }

    @Test("ST-28 NetworkX test_multigraph_keys_min/max: the lighter copy for the minimum, the heavier for the maximum")
    func parallelPair() {
        let edges: [(Int, Int, Int)] = [(0, 1, 2), (0, 1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [1])
        #expect(tree.weight == 1)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree(from: 1) { edges[$0].2 } == tree)
        let maximum = graph.maximumSpanningTree { edges[$0].2 }
        #expect(maximum.edges == [0])
        #expect(maximum.weight == 2)
    }

    @Test("ST-29 NetworkX test_key_data_bool: min 4, max 7")
    func networkXKeyData() {
        let edges: [(Int, Int, Int)] = [(1, 2, 2), (1, 2, 3), (3, 2, 2), (3, 1, 4)]
        let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 2])
        #expect(tree.weight == 4)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 2)
        #expect(Set(boruvka.edges) == [0, 2])
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 2)
        #expect(Set(prim.edges) == [0, 2])
        #expect(prim.weight == 4)
        let maximum = graph.maximumSpanningTree { edges[$0].2 }
        #expect(maximum.edges == [3, 1])
        #expect(maximum.weight == 7)
    }

    @Test("ST-30 two equal parallel copies: the first position")
    func equalParallelCopies() {
        let edges: [(Int, Int, Int)] = [(0, 1, 3), (0, 1, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0])
        #expect(tree.weight == 3)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.maximumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.minimumSpanningTree().edges == [0])
        // Either copy is an optimum.
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges == [0] || prim.edges == [1])
        #expect(prim.weight == 3)
    }

    @Test("ST-31 self-loops lighter than every edge are neither taken nor weighed")
    func lightSelfLoops() {
        let edges: [(Int, Int, Int)] = [(0, 0, -100), (0, 1, 5), (1, 1, -1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        var asked: [Int] = []
        let weight: (Int) -> Int = { position in
            asked.append(position)
            return edges[position].2
        }
        let tree = graph.minimumSpanningTree(weight: weight)
        #expect(tree.edges == [1])
        #expect(tree.weight == 5)
        #expect(asked == [1])
        asked = []
        #expect(graph.kruskalMinimumSpanningTree(weight: weight) == tree)
        #expect(asked == [1])
        asked = []
        #expect(graph.boruvkaMinimumSpanningTree(weight: weight) == tree)
        #expect(asked == [1])
        asked = []
        #expect(graph.primMinimumSpanningTree(weight: weight) == tree)
        #expect(asked == [1])
        asked = []
        #expect(graph.primMinimumSpanningTree(from: 1, weight: weight) == tree)
        #expect(asked == [1])
        asked = []
        #expect(graph.maximumSpanningTree(weight: weight) == tree)
        #expect(asked == [1])
        #expect(graph.minimumSpanningTree().edges == [1])
        #expect(graph.minimumSpanningTree().weight == 1)
    }

    @Test("ST-32 a single vertex with a self-loop (NetworkX single_node_loop): the empty forest")
    func singleLoop() {
        let graph = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        var asked = 0
        let weight: (Int) -> Int = { _ in
            asked += 1
            return 4
        }
        let tree = graph.minimumSpanningTree(weight: weight)
        #expect(tree.edges == [])
        #expect(tree.weight == 0)
        #expect(graph.kruskalMinimumSpanningTree(weight: weight) == tree)
        #expect(graph.boruvkaMinimumSpanningTree(weight: weight) == tree)
        #expect(graph.primMinimumSpanningTree(weight: weight) == tree)
        #expect(graph.primMinimumSpanningTree(from: 0, weight: weight) == tree)
        #expect(graph.maximumSpanningTree(weight: weight) == tree)
        #expect(asked == 0)
        #expect(graph.minimumSpanningTree().edges == [])
        #expect(graph.minimumSpanningTree().weight == 0)
    }

    @Test("ST-33 every weight zero: the first forest in position order, weight 0")
    func zeroWeights() {
        let edges: [(Int, Int, Int)] = [(0, 1, 0), (1, 2, 0), (2, 3, 0), (3, 0, 0), (0, 2, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1, 2])
        #expect(tree.weight == 0)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 3)
        #expect(Set(boruvka.edges) == [0, 1, 2])
        #expect(boruvka.weight == 0)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 3)
        #expect(Set(prim.edges).count == 3)
        #expect(prim.weight == 0)
        #expect(graph.minimumSpanningTree().edges == [0, 1, 2])
        #expect(graph.minimumSpanningTree().weight == 3)
        // Eight optima; Prim's is a spanning tree.
        var parent = Array(0 ..< 4)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for position in prim.edges {
            let (ru, rv) = (find(edges[position].0), find(edges[position].1))
            #expect(ru != rv, "\(prim.edges) has a cycle")
            parent[ru] = rv
        }
    }

    @Test("ST-34 the tie rule follows positions, not vertex names")
    func positionsNotNames() {
        // ST-25 with the edges listed in another order: now 0–2 and 1–2 come first.
        let edges: [(Int, Int, Int)] = [(0, 2, 1), (1, 2, 1), (0, 1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 2)
        #expect(Set(tree.edges.map { graph.edges[$0] }) == [UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [0, 1])
        #expect(graph.maximumSpanningTree { edges[$0].2 }.edges == [0, 1])
        #expect(graph.primMinimumSpanningTree { edges[$0].2 }.weight == 2)
    }

    @Test("ST-35 NetworkX test_weight_attribute: min 2 with an isolated vertex; max 8, the earlier of two ties")
    func networkXWeightAttribute() {
        let edges: [(Int, Int, Int)] = [(0, 1, 7), (0, 2, 1), (1, 2, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [1, 2])
        #expect(tree.weight == 2)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(boruvka.edges.count == 2)
        #expect(Set(boruvka.edges) == [1, 2])
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(prim.edges.count == 2)
        #expect(Set(prim.edges) == [1, 2])
        #expect(prim.weight == 2)
        // NetworkX's expected maximum: {0–1, 0–2}; 0–2 and 1–2 tie and the earlier position wins.
        let maximum = graph.maximumSpanningTree { edges[$0].2 }
        #expect(maximum.edges == [0, 1])
        #expect(maximum.weight == 8)
    }

    @Test("ST-36 NetworkX's multigraph iterator graph, each edge doubled at twice the weight: the light copies")
    func doubledMultigraph() {
        let edges: [(Int, Int, Int)] = [
            (0, 1, 5), (0, 1, 10), (1, 2, 4), (1, 2, 8), (1, 4, 6), (1, 4, 12), (2, 3, 5), (2, 3, 10), (2, 4, 7), (2, 4, 14), (3, 4, 3), (3, 4, 6),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [10, 2, 0, 6]
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
        let maximum = graph.maximumSpanningTree { edges[$0].2 }
        #expect(maximum.edges == [9, 5, 1, 7])
        #expect(maximum.weight == 46)
    }
}
