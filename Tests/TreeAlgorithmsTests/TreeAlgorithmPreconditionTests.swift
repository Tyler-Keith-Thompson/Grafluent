// Preconditions, as exit tests. A vertex argument that is not a vertex of the tree traps, as every
// Trees query does (TA-019, TA-020 one-shot; TA-123 `LowestCommonAncestors`; TA-336
// `HeavyLightDecomposition`), and api.md's rule is applied to every vertex-taking member of both
// structures. A weight below `.zero` or NaN traps in every weighted entry point (TA-421, TA-422
// `center(weight:)`; TA-620 `diameter(weight:)`; TA-621 `diameterPath(weight:)`), with `Int` and
// `Double` weights, as Dijkstra's precondition in ShortestPaths does; NetworkX raises `ValueError`
// ("negative weights?"). Each exit test builds its inputs inside the closure. Case IDs (TA-nnn)
// refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("TreeAlgorithms preconditions", .tags(.precondition))
struct TreeAlgorithmPreconditionTests {
    @Test("TA-019 RootedTree(a-b, b-c, b-d, d-e; root: c).lowestCommonAncestor(of: e, z) traps: not a vertex")
    func oneShotOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: [] a-b, b-c, b-d, d-e
            let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
            let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let rooted = RootedTree(graph, root: "c")!
            _ = rooted.lowestCommonAncestor(of: "e", "z")
        }
        await #expect(processExitsWith: .failure) {
            let rooted = RootedTree(parents: [nil, 0])!
            _ = rooted.lowestCommonAncestor(of: 9, 0)
        }
    }

    @Test("TA-020 Arborescence(NX).lowestCommonAncestor(of: 0, 9) traps: not a vertex")
    func arborescenceOneShotOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
            let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let arborescence = Arborescence(graph)!
            _ = arborescence.lowestCommonAncestor(of: 0, 9)
        }
    }

    @Test("TA-123 LowestCommonAncestors(a-b, b-c, b-d, d-e; root: e).distance(from: a, to: z) traps: not a vertex")
    func structureDistanceOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: [] a-b, b-c, b-d, d-e
            let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
            let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let lca = LowestCommonAncestors(RootedTree(graph, root: "e")!)
            _ = lca.distance(from: "a", to: "z")
        }
    }

    @Test("Every LowestCommonAncestors query on a non-vertex traps, either argument")
    func structureQueriesOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = LowestCommonAncestors(RootedTree(parents: [nil, 0])!).lowestCommonAncestor(of: 9, 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = LowestCommonAncestors(RootedTree(parents: [nil, 0])!).lowestCommonAncestor(of: 0, 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = LowestCommonAncestors(RootedTree(parents: [nil, 0])!).distance(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = LowestCommonAncestors(Arborescence(parents: [nil, 0])!).lowestCommonAncestor(of: 0, 9)
        }
    }

    @Test("TA-336 HeavyLightDecomposition(a-b, b-c, b-d, d-e; root: c).position(of: z) traps: not a vertex")
    func positionOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: [] a-b, b-c, b-d, d-e
            let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
            let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let hld = HeavyLightDecomposition(RootedTree(graph, root: "c")!)
            _ = hld.position(of: "z")
        }
    }

    @Test("Every HeavyLightDecomposition query on a non-vertex traps")
    func decompositionQueriesOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(RootedTree(parents: [nil, 0])!).heavyChild(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(RootedTree(parents: [nil, 0])!).head(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(RootedTree(parents: [nil, 0])!).subtree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(RootedTree(parents: [nil, 0])!).segments(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(RootedTree(parents: [nil, 0])!).segments(from: 0, to: 9, includingCommonAncestor: false)
        }
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(RootedTree(parents: [nil, 0])!).lowestCommonAncestor(of: 0, 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = HeavyLightDecomposition(Arborescence(parents: [nil, 0])!).position(of: 9)
        }
    }

    @Test("TA-421 Tree(P(0..3)).center(weight: [1, -1, 1]) traps: a negative weight")
    func centerNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [] P(0..3)
            let pairs = (0 ..< 3).map { ($0, $0 + 1) }
            let tree = Tree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))!
            let w = [1, -1, 1]
            _ = tree.center(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let pairs = (0 ..< 3).map { ($0, $0 + 1) }
            let tree = Tree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))!
            let w: [Double] = [1, -1, 1]
            _ = tree.center(weight: { w[$0] })
        }
    }

    @Test("TA-422 Tree(P(0..3)).center(weight: [1, nan, 1]) traps: NaN")
    func centerNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [] P(0..3)
            let pairs = (0 ..< 3).map { ($0, $0 + 1) }
            let tree = Tree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))!
            let w: [Double] = [1, .nan, 1]
            _ = tree.center(weight: { w[$0] })
        }
    }

    @Test("TA-620 Tree(K₂).diameter(weight: [-1]) traps: a negative weight")
    func diameterNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [] 0-1
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1)]))!
            let w = [-1]
            _ = tree.diameter(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1)]))!
            let w: [Double] = [-1]
            _ = tree.diameter(weight: { w[$0] })
        }
    }

    @Test("TA-621 Tree(K₂).diameterPath(weight: [nan]) traps: NaN")
    func diameterPathNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [] 0-1
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1)]))!
            let w: [Double] = [.nan]
            _ = tree.diameterPath(weight: { w[$0] })
        }
    }

    @Test("Every weighted entry point traps on a negative or NaN weight, Int and Double")
    func everyWeightedEntryPoint() async {
        // The negative or NaN edge is last, so a check that stops early would miss it.
        await #expect(processExitsWith: .failure) {
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))!
            let w = [1, -1]
            _ = tree.diameterPath(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))!
            let w: [Double] = [1, -0.5]
            _ = tree.diameterPath(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))!
            let w: [Double] = [1, .nan]
            _ = tree.diameter(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))!
            let w: [Double] = [1, -.infinity]
            _ = tree.center(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))!
            let w = [0, Int.min]
            _ = tree.center(weight: { w[$0] })
        }
    }
}
