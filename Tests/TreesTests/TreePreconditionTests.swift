// Preconditions, as exit tests. A root that is not a vertex traps, as Cycles' `findCycle(from:)`
// does (TS-109), both when rooting a graph and when rerooting a tree; a query on a vertex that is
// not in the tree traps, as `DominatorTree`'s do (TS-246 for `depth(of:)`, TS-315 for
// `path(from:to:)`), and api.md's "a query on a non-vertex traps" is applied to every rooted query
// and to `Forest.component(of:)` and `Forest.path(from:to:)`. Each exit test builds its inputs
// inside the closure. Case IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Trees preconditions", .tags(.precondition))
struct TreePreconditionTests {
    @Test("TS-109 RootedTree(g, root: 7) traps when 7 is not a vertex; so does RootedTree(tree, root: 7)")
    func rootNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: 0-1
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = RootedTree(graph, root: 7)
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(edges: [UndirectedEdge(0, 1)])!
            _ = RootedTree(tree, root: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<String>(vertices: ["x"], edges: [])
            _ = RootedTree(graph, root: "y")
        }
    }

    @Test("TS-246 RootedTree(E1, root: 0).depth(of: 9) traps: not a vertex")
    func depthOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
            let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let rooted = RootedTree(graph, root: 0)!
            _ = rooted.depth(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let arborescence = Arborescence(parents: [nil, 0])!
            _ = arborescence.depth(of: 9)
        }
    }

    @Test("TS-315 Tree(E1).path(from: 0, to: 9) traps: not a vertex, either end, on every type")
    func pathToNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
            let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let tree = Tree(graph)!
            _ = tree.path(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let tree = Tree(edges: [UndirectedEdge(0, 1)])!
            _ = tree.path(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let rooted = RootedTree(parents: [nil, 0])!
            _ = rooted.path(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let arborescence = Arborescence(parents: [nil, 0])!
            _ = arborescence.path(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let forest = Forest(vertices: [5], edges: [UndirectedEdge(0, 1)])!
            _ = forest.path(from: 0, to: 9)
        }
    }

    @Test("Every rooted query on a non-vertex traps")
    func rootedQueriesOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = RootedTree(parents: [nil, 0])!.parent(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = RootedTree(parents: [nil, 0])!.parentEdge(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = RootedTree(parents: [nil, 0])!.children(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = RootedTree(parents: [nil, 0])!.descendants(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Array(RootedTree(parents: [nil, 0])!.ancestors(of: 9))
        }
        await #expect(processExitsWith: .failure) {
            _ = RootedTree(parents: [nil, 0])!.isAncestor(9, of: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = RootedTree(parents: [nil, 0])!.isAncestor(0, of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Arborescence(parents: [nil, 0])!.parent(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Arborescence(parents: [nil, 0])!.children(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Arborescence(parents: [nil, 0])!.isAncestor(9, of: 0)
        }
    }

    @Test("Forest.component(of:) on a non-vertex traps")
    func componentOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let forest = Forest(vertices: [5], edges: [UndirectedEdge(0, 1)])!
            _ = forest.component(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Forest<Int>().component(of: 0)
        }
    }
}
