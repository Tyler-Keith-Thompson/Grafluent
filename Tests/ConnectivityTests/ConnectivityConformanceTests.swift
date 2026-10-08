// Index-space dispatch (no per-vertex hashing on an indexed adjacency list, even through another
// generic layer), conformers without vertex indices, existentials, value semantics, Sendable,
// equality and preconditions. Case IDs (CN-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

/// Counts the hashes made through it, so a test can tell index-space algorithms from ones that
/// map every vertex back to its index.
private final class HashCounter: @unchecked Sendable {
    var hashes = 0
}

private struct HashCountingVertex: Hashable {
    let value: Int
    let counter: HashCounter

    static func == (lhs: HashCountingVertex, rhs: HashCountingVertex) -> Bool { lhs.value == rhs.value }

    func hash(into hasher: inout Hasher) {
        counter.hashes += 1
        hasher.combine(value)
    }
}

/// Supplies only what DirectedGraph requires: no vertex indices, so algorithms use dictionaries.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Connectivity dispatch and value semantics", .tags(.conformance))
struct ConnectivityConformanceTests {
    @Test("CN-136 an indexed adjacency list is processed in index space, without hashing vertices")
    func indexSpace() {
        let counter = HashCounter()
        let boost = DirectedFixture<Int>.boost24
        let graph = AdjacencyList(edges: boost.edges.map { DirectedEdge(from: HashCountingVertex(value: $0.source, counter: counter), to: HashCountingVertex(value: $0.target, counter: counter)) })
        let root = HashCountingVertex(value: 7, counter: counter)
        counter.hashes = 0
        let strong = graph.stronglyConnectedComponents()
        #expect(counter.hashes == 0)
        #expect(strong.count == 3)
        counter.hashes = 0
        let weak = graph.weaklyConnectedComponents()
        #expect(counter.hashes == 0)
        #expect(weak.count == 1)
        counter.hashes = 0
        let condensation = graph.condensation()
        #expect(counter.hashes == 0)
        #expect(condensation.graph.edgeCount == 2)
        counter.hashes = 0
        let tree = graph.dominatorTree(root: root)
        // Looking up the root (and checking it is a vertex), not one hash per vertex or edge.
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        #expect(tree.immediateDominator(of: HashCountingVertex(value: 2, counter: counter)) == HashCountingVertex(value: 1, counter: counter))
    }

    @Test("CN-137 a conformer without vertex indices works on dictionaries and matches the ReferenceDirectedMultigraph")
    func withoutIndices() {
        let house = DirectedFixture<Int>.house
        let multigraph = ReferenceDirectedMultigraph(vertices: house.vertices, edges: house.edges)
        // The same vertices order as the ReferenceDirectedMultigraph's, [5, 3, 4, 2, 0, 1], and edges in written order.
        let unindexed = DictionaryGraph(vertices: multigraph.vertices, edges: house.edges)
        #expect(unindexed.vertexIndexBound == nil)
        #expect(unindexed.stronglyConnectedComponents().map(Array.init) == [[0], [1], [4], [2], [3], [5]])
        #expect(multigraph.stronglyConnectedComponents().map(Array.init) == [[0], [1], [4], [2], [3], [5]])
        #expect(unindexed.weaklyConnectedComponents().map(Array.init) == multigraph.weaklyConnectedComponents().map(Array.init))
        #expect(unindexed.condensation().graph == multigraph.condensation().graph)
        #expect(unindexed.attractingComponents() == multigraph.attractingComponents())
        let unindexedComponents = unindexed.stronglyConnectedComponents()
        for v in multigraph.vertices { #expect(unindexedComponents[unindexedComponents.component(of: v)].contains(v)) }
        let tree = unindexed.dominatorTree(root: 5)
        let expected = multigraph.dominatorTree(root: 5)
        let frontiers = unindexed.dominanceFrontiers(root: 5)
        let expectedFrontiers = multigraph.dominanceFrontiers(root: 5)
        for v in multigraph.vertices {
            #expect(tree.immediateDominator(of: v) == expected.immediateDominator(of: v))
            #expect(tree.dominators(of: v) == expected.dominators(of: v))
            #expect(Array(tree.children(of: v)) == Array(expected.children(of: v)))
            #expect(frontiers[v].map { Array($0) } == expectedFrontiers[v].map { Array($0) })
        }
        // CN-42's conformer.
        let strings = DictionaryGraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a")])
        #expect(strings.stronglyConnectedComponents().map(Array.init) == [["a", "b"], ["c"]])
        #expect(strings.dominatorTree(root: "c").immediateDominator(of: "b") == "a")
    }

    @Test("CN-138 a second generic layer still reaches the representation's successorIndices")
    func genericLayer() {
        func run<G: DirectedGraph>(_ g: G) -> Int {
            g.stronglyConnectedComponents().count + g.weaklyConnectedComponents().count + g.condensation().graph.edgeCount
        }
        func outer<G: DirectedGraph>(_ g: G) -> Int { run(g) }
        let counter = HashCounter()
        let boost = DirectedFixture<Int>.boost24
        let graph = AdjacencyList(edges: boost.edges.map { DirectedEdge(from: HashCountingVertex(value: $0.source, counter: counter), to: HashCountingVertex(value: $0.target, counter: counter)) })
        counter.hashes = 0
        #expect(outer(graph) == 3 + 1 + 2)
        #expect(counter.hashes == 0)
        func dominators<G: DirectedGraph>(_ g: G, root: G.Vertex) -> DominatorTree<G> { g.dominatorTree(root: root) }
        func outerDominators<G: DirectedGraph>(_ g: G, root: G.Vertex) -> DominatorTree<G> { dominators(g, root: root) }
        let root = HashCountingVertex(value: 7, counter: counter)
        counter.hashes = 0
        let tree = outerDominators(graph, root: root)
        // The root lookup only.
        #expect(counter.hashes <= 2)
        #expect(tree.children(of: root).count == 16)
    }

    @Test("CN-139 existentials reach the algorithms through a some wrapper")
    func existentials() {
        func partition(_ g: some DirectedGraph<Int>) -> [[Int]] { g.stronglyConnectedComponents().map(Array.init) }
        let scc9 = DirectedFixture<Int>.scc9
        let graphs: [(any DirectedGraph<Int>, [[Int]])] = [
            (AdjacencyMatrix(vertexCount: 9, edges: scc9.edges), [[0, 3, 6], [2, 5, 8], [1, 4, 7]]),
            (CompressedSparseRow(vertexCount: 9, edges: scc9.edges), [[0, 3, 6], [2, 5, 8], [1, 4, 7]]),
            (ReferenceDirectedMultigraph(vertices: scc9.vertices, edges: scc9.edges), [[6, 0, 3], [8, 2, 5], [7, 1, 4]]),
        ]
        for (g, expected) in graphs { #expect(partition(g) == expected) }
        let list: any DirectedGraph<Int> = AdjacencyList(vertices: scc9.vertices, edges: scc9.edges)
        #expect(Set(partition(list).map(Set.init)) == [[0, 3, 6], [2, 5, 8], [1, 4, 7]])
    }

    @Test("CN-140 results hold a copy of the graph", .tags(.copyOnWrite))
    func valueSemantics() {
        let scc9 = DirectedFixture<Int>.scc9
        var graph = AdjacencyList(vertices: scc9.vertices, edges: scc9.edges)
        let components = graph.stronglyConnectedComponents()
        let tree = graph.dominatorTree(root: 0)
        let frontiers = graph.dominanceFrontiers(root: 0)
        // 0→1 closes A→C→B→A.
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(components.count == 3)
        #expect(components.component(of: 0) == 0)
        #expect(tree.dominators(of: 1) == nil)
        #expect(frontiers[1] == nil)
        let after = graph.stronglyConnectedComponents()
        #expect(after.count == 1)
        #expect(Set(after[0]) == Set(0 ..< 9))
        #expect(graph.dominatorTree(root: 0).immediateDominator(of: 1) == 0)
    }

    @Test("CN-141 results are Sendable")
    func sendable() async {
        let graph = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges)
        let components = graph.stronglyConnectedComponents()
        let condensation = graph.condensation()
        let tree = graph.dominatorTree(root: 5)
        let frontiers = graph.dominanceFrontiers(root: 5)
        let count = await Task.detached { components.count }.value
        #expect(count == 6)
        let edges = await Task.detached { condensation.graph.edgeCount }.value
        #expect(edges == 7)
        let idom = await Task.detached { tree.immediateDominator(of: 4) }.value
        #expect(idom == 3)
        let frontier = await Task.detached { frontiers[4].map { Array($0) } }.value
        #expect(frontier == [0, 1])
    }

    @Test("CN-143 equality compares the partition and its order, not the graph")
    func equality() {
        let scc9 = DirectedFixture<Int>.scc9
        let matrix = AdjacencyMatrix(vertexCount: 9, edges: scc9.edges)
        #expect(matrix.stronglyConnectedComponents() == matrix.stronglyConnectedComponents())
        #expect(matrix.weaklyConnectedComponents() == matrix.weaklyConnectedComponents())
        let looped = AdjacencyMatrix(vertexCount: 9, edges: scc9.edges + [DirectedEdge(from: 0, to: 0)])
        #expect(matrix.stronglyConnectedComponents() == looped.stronglyConnectedComponents())
        let joined = AdjacencyMatrix(vertexCount: 9, edges: scc9.edges + [DirectedEdge(from: 0, to: 1)])
        #expect(matrix.stronglyConnectedComponents() != joined.stronglyConnectedComponents())
        // Strong and weak components of a strongly connected graph are the same partition.
        let cycle = CompressedSparseRow(vertexCount: 10, edges: DirectedFixture<Int>.directedCycle10.edges)
        #expect(cycle.stronglyConnectedComponents() == cycle.weaklyConnectedComponents())
        // Same members, different order.
        let path = CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges)
        let reversedPath = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(path.stronglyConnectedComponents() != reversedPath.stronglyConnectedComponents())
        // The same vertices in the same order, split differently: [[0], [1]] against [[0, 1]].
        let apart = CompressedSparseRow(vertexCount: 2)
        let together = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Array(apart.stronglyConnectedComponents().joined()) == Array(together.stronglyConnectedComponents().joined()))
        #expect(apart.stronglyConnectedComponents() != together.stronglyConnectedComponents())
    }
}

@Suite("Connectivity preconditions", .tags(.precondition))
struct ConnectivityPreconditionTests {
    @Test("CN-142 a root or exit that is not a vertex traps")
    func roots() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominanceFrontiers(root: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).postDominatorTree(exit: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).postDominatorTree(exit: 6)
        }
    }

    @Test("CN-142 a component query for a vertex or index outside the graph traps")
    func components() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).stronglyConnectedComponents().component(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).weaklyConnectedComponents().component(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).stronglyConnectedComponents().component(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).stronglyConnectedComponents().component(ofIndex: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).stronglyConnectedComponents().component(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            // No vertex indices at all.
            _ = DictionaryGraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)]).stronglyConnectedComponents().component(ofIndex: 0)
        }
    }

    @Test("CN-142 a dominator query for a vertex outside the graph traps")
    func dominatorQueries() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).immediateDominator(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).immediateDominator(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).dominators(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).strictDominators(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).children(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).dominates(9, 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominatorTree(root: 5).dominates(0, 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: DirectedFixture<Int>.house.edges).dominanceFrontiers(root: 5)[9]
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).dominanceFrontiers(root: 5)[9]
        }
    }
}
