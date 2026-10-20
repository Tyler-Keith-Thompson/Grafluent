// Hierarchical Leiden: Leiden on the whole graph, then again inside every community over the size
// cap. Hand cases where every seed gives the same answer (a cap no community exceeds gives one
// level equal to `leidenCommunities`; a K₅ Leiden keeps whole stays final though over the cap; a
// ring of 40 K₄, whose cliques modularity merges into runs, splits back into the cliques one level
// down), degenerate graphs, self-loops and parallel edges, weights (read once per edge, in position order), directed graphs, the hierarchy's
// numbering (levels and children as ranges, parents, leaves, `community(of:)` and its checked and
// index spellings), equality and description, and the representations.

import AdjacencyListModule
import AdjacencyMatrixModule
import CommunityDetection
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

/// An undirected graph with no vertex or edge indices.
private struct UnindexedGraph: Graph {
    let vertices: [String]
    let edges: [UndirectedEdge<String>]
    func incidentEdges(of vertex: String) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: String) -> [String] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Hierarchical Leiden")
struct HierarchicalLeidenTests {
    @Test("A cap no community exceeds: one level, the same communities as leidenCommunities from the same seed")
    func oneLevel() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for seed in 0 ..< 10 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
            var again = SeededRandomNumberGenerator(seed: UInt(seed))
            let flat = graph.leidenCommunities(using: &again)
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected, "seed \(seed)")
            #expect(flat.map { Array($0) } == expected, "seed \(seed)")
            #expect(result.levelCount == 1)
            #expect(result.communities(atLevel: 0) == 0 ..< 2)
            #expect(result.leaves == [0, 1])
            #expect(result.parent(of: 0) == nil)
            #expect(result.parent(of: 1) == nil)
            #expect(result.children(of: 0).isEmpty)
            #expect(result.level(of: 1) == 0)
            #expect(result.community(of: 4) == 1)
            #expect(result.community(ofIndex: 0) == 0)
            #expect(result.description == "[[0, 1, 2], [3, 4, 5]]")
        }
    }

    @Test("Two K₅ joined by an edge, cap 4: each K₅ is clustered again and stays whole, so it is final though over the cap")
    func unsplittable() {
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        for i in 5 ..< 10 { for j in i + 1 ..< 10 { pairs.append((i, j)) } }
        pairs.append((4, 5))
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for seed in 0 ..< 10 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator)
            let expected: [[Int]] = [Array(0 ..< 5), Array(5 ..< 10)]
            #expect(result.map { Array($0) } == expected, "seed \(seed)")
            #expect(result.levelCount == 1, "seed \(seed)")
            #expect(result.leaves == [0, 1], "seed \(seed)")
            #expect(result.children(of: 1).isEmpty, "seed \(seed)")
        }
    }

    @Test("A ring of 40 K₄: modularity merges cliques into runs (1 > 14²/560), and a cap of 4 splits every run back into its cliques")
    func ringOfCliques() {
        let k = 40
        var pairs: [(Int, Int)] = []
        for c in 0 ..< k {
            for i in 0 ..< 4 { for j in i + 1 ..< 4 { pairs.append((4 * c + i, 4 * c + j)) } }
            pairs.append((4 * c + 3, 4 * ((c + 1) % k)))
        }
        let graph = ReferencePseudograph(vertices: 0 ..< 4 * k, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cliques = (0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) }
        for seed in 0 ..< 5 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator)
            let top = result.communities(atLevel: 0)
            #expect(top.count < k, "seed \(seed): \(top.count) communities on level 0")
            #expect(result.levelCount >= 2, "seed \(seed)")
            // Every top community is a run of whole cliques, and its children are those cliques.
            for c in top {
                let members = Array(result[c])
                #expect(members.count % 4 == 0, "seed \(seed), community \(c)")
                for clique in cliques where clique.contains(members[0]) || members.contains(clique[0]) {
                    #expect(Set(members).isSuperset(of: clique), "seed \(seed), community \(c)")
                }
                let children = result.children(of: c)
                if members.count > 4 {
                    #expect(children.count == members.count / 4, "seed \(seed), community \(c)")
                    #expect(children.flatMap { Array(result[$0]) } == members, "seed \(seed), community \(c)")
                    for d in children {
                        #expect(result.parent(of: d) == c, "seed \(seed), community \(d)")
                        #expect(result.level(of: d) == 1, "seed \(seed), community \(d)")
                        #expect(cliques.contains(Array(result[d])), "seed \(seed), community \(d)")
                    }
                } else {
                    #expect(children.isEmpty, "seed \(seed), community \(c)")
                }
            }
            let leaves = result.leaves
            #expect(leaves.count == k, "seed \(seed)")
            #expect(Set(leaves.map { Array(result[$0]) }) == Set(cliques), "seed \(seed)")
            for v in 0 ..< 4 * k {
                #expect(Array(result[result.community(of: v)]) == cliques[v / 4], "seed \(seed), vertex \(v)")
            }
            // Level 1 holds exactly the children, in parent order.
            #expect(Array(result.communities(atLevel: 1)) == top.flatMap { Array(result.children(of: $0)) }, "seed \(seed)")
            #expect((0 ..< result.levelCount).reduce(0) { $0 + result.communities(atLevel: $1).count } == result.count, "seed \(seed)")
        }
    }

    @Test("The ring of 40 K₄ as a symmetric digraph, directed entry point: the same split")
    func ringDirected() {
        let k = 40
        var arcs: [DirectedEdge<Int>] = []
        for c in 0 ..< k {
            for i in 0 ..< 4 {
                for j in i + 1 ..< 4 {
                    arcs.append(DirectedEdge(from: 4 * c + i, to: 4 * c + j))
                    arcs.append(DirectedEdge(from: 4 * c + j, to: 4 * c + i))
                }
            }
            arcs.append(DirectedEdge(from: 4 * c + 3, to: 4 * ((c + 1) % k)))
            arcs.append(DirectedEdge(from: 4 * ((c + 1) % k), to: 4 * c + 3))
        }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4 * k, edges: arcs)
        let cliques = (0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) }
        for seed in 0 ..< 3 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator)
            #expect(result.communities(atLevel: 0).count < k, "seed \(seed)")
            #expect(Set(result.leaves.map { Array(result[$0]) }) == Set(cliques), "seed \(seed)")
            for c in result.leaves { #expect(result.children(of: c).isEmpty, "seed \(seed)") }
            for c in 0 ..< result.count where !result.children(of: c).isEmpty {
                #expect(result.children(of: c).flatMap { Array(result[$0]) } == Array(result[c]), "seed \(seed), community \(c)")
            }
        }
    }

    @Test("Weights: a ring of 40 K₄ whose links weigh ½ still merges cliques into runs and splits them back at a cap of 4; the weight closure is read once per edge, in position order")
    func weights() {
        let k = 40
        var pairs: [(Int, Int)] = []
        for c in 0 ..< k {
            for i in 0 ..< 4 { for j in i + 1 ..< 4 { pairs.append((4 * c + i, 4 * c + j)) } }
            pairs.append((4 * c + 3, 4 * ((c + 1) % k)))
        }
        let graph = ReferencePseudograph(vertices: 0 ..< 4 * k, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cliques = Set((0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) })
        for seed in 0 ..< 5 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            var read: [Int] = []
            let result = graph.hierarchicalLeidenCommunities(weight: { position -> Double in
                read.append(position)
                return position % 7 == 6 ? 0.5 : 1
            }, maximumCommunitySize: 4, using: &generator)
            #expect(read == Array(0 ..< 7 * k), "seed \(seed)")
            #expect(result.communities(atLevel: 0).count < k, "seed \(seed)")
            #expect(Set(result.leaves.map { Array(result[$0]) }) == cliques, "seed \(seed)")
            for c in result.communities(atLevel: 0) where result[c].count > 4 {
                #expect(result.children(of: c).flatMap { Array(result[$0]) }.sorted() == Array(result[c]), "seed \(seed), community \(c)")
            }
        }
    }

    @Test("Degenerate graphs: no vertices (no levels), one vertex, no edges, self-loops and parallel edges, a disconnected graph")
    func degenerate() {
        var generator = SeededRandomNumberGenerator(seed: 5)
        let empty = ReferencePseudograph(vertices: 0 ..< 0, edges: [])
        let none = empty.hierarchicalLeidenCommunities(maximumCommunitySize: 1, using: &generator)
        #expect(none.count == 0)
        #expect(none.levelCount == 0)
        #expect(none.leaves == [])
        let one = ReferencePseudograph(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        let single = one.hierarchicalLeidenCommunities(maximumCommunitySize: 1, using: &generator)
        #expect(single.map { Array($0) } == [[0]])
        #expect(single.levelCount == 1)
        #expect(single.leaves == [0])
        let isolated = ReferencePseudograph(vertices: 0 ..< 4, edges: [])
        let singletons = isolated.hierarchicalLeidenCommunities(maximumCommunitySize: 1, using: &generator)
        #expect(singletons.map { Array($0) } == [[0], [1], [2], [3]])
        #expect(singletons.levelCount == 1)
        // Parallel edges add and a loop never moves a vertex: {0, 1} (three edges) and {2, 3}, with
        // the single 1–2 edge between; a cap of 1 clusters each pair again and finds them whole.
        let multi = ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(2, 3), UndirectedEdge(1, 2), UndirectedEdge(3, 3)])
        for seed in 0 ..< 5 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = multi.hierarchicalLeidenCommunities(maximumCommunitySize: 1, using: &generator)
            #expect(pairs.map { Array($0) } == [[0, 1], [2, 3]], "seed \(seed)")
            #expect(pairs.levelCount == 1, "seed \(seed)")
        }
        // Two components, each two triangles joined by an edge: level 0 has the four triangles.
        var edges: [UndirectedEdge<Int>] = []
        for base in [0, 6] {
            for (u, v) in [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)] { edges.append(UndirectedEdge(base + u, base + v)) }
        }
        let two = ReferencePseudograph(vertices: 0 ..< 12, edges: edges)
        let four = two.hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
        #expect(four.map { Array($0) } == [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]])
    }

    @Test("Equality compares communities, numbering and parents; the system-generator spellings give a hierarchy with the same leaves")
    func equality() {
        let k = 40
        var pairs: [(Int, Int)] = []
        for c in 0 ..< k {
            for i in 0 ..< 4 { for j in i + 1 ..< 4 { pairs.append((4 * c + i, 4 * c + j)) } }
            pairs.append((4 * c + 3, 4 * ((c + 1) % k)))
        }
        let graph = ReferencePseudograph(vertices: 0 ..< 4 * k, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var first = SeededRandomNumberGenerator(seed: 2)
        var second = SeededRandomNumberGenerator(seed: 2)
        let a = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &first)
        let b = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &second)
        #expect(a == b)
        var third = SeededRandomNumberGenerator(seed: 2)
        let flat = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4 * k, using: &third)
        #expect(flat.levelCount == 1)
        #expect(a != flat)
        let cliques = Set((0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) })
        let system = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 4)
        #expect(Set(system.leaves.map { Array(system[$0]) }) == cliques)
        let weighted = graph.hierarchicalLeidenCommunities(weight: { _ in 2.0 }, maximumCommunitySize: 4)
        #expect(Set(weighted.leaves.map { Array(weighted[$0]) }) == cliques)
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4 * k, edges: pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] })
        let directed = digraph.hierarchicalLeidenCommunities(maximumCommunitySize: 4)
        #expect(Set(directed.leaves.map { Array(directed[$0]) }) == cliques)
        let directedWeighted = digraph.hierarchicalLeidenCommunities(weight: { _ in 2.0 }, maximumCommunitySize: 4)
        #expect(Set(directedWeighted.leaves.map { Array(directedWeighted[$0]) }) == cliques)
    }

    @Test("community(checked:) answers as community(of:) and throws for a non-vertex, on indexed graphs and one without indices")
    func checked() throws {
        let vertices = ["a", "b", "c", "x", "y", "z"]
        let edges = [("a", "b"), ("b", "c"), ("c", "a"), ("x", "y"), ("y", "z"), ("z", "x"), ("c", "x")].map { UndirectedEdge($0.0, $0.1) }
        var generator = SeededRandomNumberGenerator(seed: 1)
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges).hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(plain.vertexIndexBound == nil)
        let unindexed = plain.hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
        let directed = AdjacencyList(vertices: vertices, edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) }).hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
        let expected = [["a", "b", "c"], ["x", "y", "z"]]
        #expect(indexed.map { Array($0) } == expected)
        #expect(unindexed.map { Array($0) } == expected)
        #expect(directed.map { Array($0) } == expected)
        for v in vertices {
            #expect(try indexed.community(checked: v) == indexed.community(of: v))
            #expect(try unindexed.community(checked: v) == unindexed.community(of: v))
            #expect(try directed.community(checked: v) == directed.community(of: v))
        }
        #expect(unindexed.community(of: "y") == 1)
        #expect(unindexed.community(ofIndex: 4) == 1)
        #expect(throws: VertexNotFound.self) { try indexed.community(checked: "q") }
        #expect(throws: VertexNotFound.self) { try unindexed.community(checked: "q") }
        #expect(throws: VertexNotFound.self) { try directed.community(checked: "q") }
    }

    @Test("The ring of 40 K₄ on UndirectedAdjacencyList, AdjacencyList, CompressedSparseRow and AdjacencyMatrix: the cliques as leaves")
    func representations() {
        let k = 40
        var pairs: [(Int, Int)] = []
        for c in 0 ..< k {
            for i in 0 ..< 4 { for j in i + 1 ..< 4 { pairs.append((4 * c + i, 4 * c + j)) } }
            pairs.append((4 * c + 3, 4 * ((c + 1) % k)))
        }
        let cliques = Set((0 ..< k).map { Array(4 * $0 ..< 4 * $0 + 4) })
        let arcs = pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] }
        func check<G: DirectedGraph>(_ result: CommunityHierarchy<G>, _ name: String) where G.Vertex == Int {
            #expect(result.communities(atLevel: 0).count < k, "\(name)")
            #expect(Set(result.leaves.map { Array(result[$0]) }) == cliques, "\(name)")
            for c in 0 ..< result.count where !result.children(of: c).isEmpty {
                #expect(result.children(of: c).flatMap { Array(result[$0]) } == Array(result[c]), "\(name), community \(c)")
                for d in result.children(of: c) { #expect(result.parent(of: d) == c, "\(name), community \(d)") }
            }
            for v in 0 ..< 4 * k { #expect(Array(result[result.community(of: v)]) == Array(4 * (v / 4) ..< 4 * (v / 4) + 4), "\(name), vertex \(v)") }
        }
        var generator = SeededRandomNumberGenerator(seed: 7)
        let list = UndirectedAdjacencyList(vertices: 0 ..< 4 * k, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        check(list.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator), "UndirectedAdjacencyList")
        let directedList = AdjacencyList(vertices: 0 ..< 4 * k, edges: arcs)
        check(directedList.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator), "AdjacencyList")
        let csr = CompressedSparseRow(vertexCount: 4 * k, edges: arcs)
        check(csr.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator), "CompressedSparseRow")
        let matrix = AdjacencyMatrix(vertexCount: 4 * k, edges: arcs)
        check(matrix.hierarchicalLeidenCommunities(maximumCommunitySize: 4, using: &generator), "AdjacencyMatrix")
        // Weighted on the matrix, whose positions are cells: every arc weight 3.
        check(matrix.hierarchicalLeidenCommunities(weight: { _ in 3.0 }, maximumCommunitySize: 4, using: &generator), "AdjacencyMatrix weighted")
    }
}
