// Preconditions (exit tests), value semantics, Sendable, existentials, index-space dispatch (no
// per-vertex hashing on an indexed adjacency list) and lazy weight reads. Case IDs (SP-nn) refer
// to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import ShortestPaths
import Testing

/// Counts the hashes made through it, so a test can tell index-space algorithms from ones that
/// map every vertex back to its index.
private final class HashCounter: @unchecked Sendable {
    var hashes = 0
}

private struct HashCountingVertex: Hashable {
    let value: String
    let counter: HashCounter

    static func == (lhs: HashCountingVertex, rhs: HashCountingVertex) -> Bool { lhs.value == rhs.value }

    func hash(into hasher: inout Hasher) {
        counter.hashes += 1
        hasher.combine(value)
    }
}

@Suite("Shortest-path preconditions, value semantics and dispatch")
struct ShortestPathConformanceTests {
    @Test("SP-125 a source that is not a vertex traps, in every algorithm", .tags(.precondition))
    func sourceNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 2) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPath(from: 9, to: 1) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).bellmanFordShortestPaths(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).bellmanFordShortestPaths(from: 2) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).aStarShortestPath(from: 9, to: 1, weight: { _ in 1 }, heuristic: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).shortestPaths(from: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).findNegativeCycle(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).dijkstraShortestPaths(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            // One bad source among good ones.
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: [0, 9]) { _ in 1 }
        }
    }

    @Test("SP-125 a target that is not a vertex traps", .tags(.precondition))
    func targetNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPath(from: 0, to: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).aStarShortestPath(from: 0, to: 9, weight: { _ in 1 }, heuristic: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPath(from: 0, to: 2) { _ in 1 }
        }
    }

    @Test("SP-125 an empty source sequence traps", .tags(.precondition))
    func emptySources() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: [Int]()) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).bellmanFordShortestPaths(from: [Int]()) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).shortestPaths(from: [Int]())
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).findNegativeCycle(from: [Int]()) { _ in 1 }
        }
    }

    @Test("SP-125 tree queries of a vertex or index outside the graph trap", .tags(.precondition))
    func treeQueries() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.distance(to: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.parent(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.parentEdge(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.path(to: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).shortestPaths(from: 0).distance(to: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.distance(toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.distance(toIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).dijkstraShortestPaths(from: 0) { _ in 1 }.parent(ofIndex: 2)
        }
    }

    @Test("SP-125 index-space queries agree with vertex queries")
    func indexSpaceQueries() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = AdjacencyList(vertices: ["moon"], edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let tree = graph.dijkstraShortestPaths(from: "s") { xg[$0].2 }
        for v in graph.vertices {
            let index = graph.vertexIndex(of: v)
            #expect(tree.distance(toIndex: index) == tree.distance(to: v))
            #expect(tree.parent(ofIndex: index).map { graph.vertex(atIndex: $0) } == tree.parent(of: v))
        }
        #expect(tree.distance(toIndex: graph.vertexIndex(of: "moon")) == nil)
    }

    @Test("SP-126 a tree is a value: mutating the graph afterwards changes nothing", .tags(.copyOnWrite))
    func valueSemantics() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        var graph = AdjacencyList(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        var weights = xg.map(\.2)
        let tree = graph.dijkstraShortestPaths(from: "s") { weights[$0] }
        let unweighted = graph.shortestPaths(from: "s")
        #expect(graph.insert(edge: DirectedEdge(from: "s", to: "v")).inserted)
        weights.append(1)
        #expect(tree.distance(to: "v") == 9)
        #expect(tree.path(to: "v") == ["s", "x", "u", "v"])
        #expect(unweighted.distance(to: "v") == 2)
        let after = graph.dijkstraShortestPaths(from: "s") { weights[$0] }
        #expect(after.distance(to: "v") == 1)
        #expect(after.path(to: "v") == ["s", "v"])
        #expect(graph.shortestPaths(from: "s").distance(to: "v") == 1)
    }

    @Test("SP-127 a tree over a Sendable graph crosses into a Task")
    func sendable() async {
        let path = CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        let tree: ShortestPathTree<CompressedSparseRow, Int> = path.dijkstraShortestPaths(from: 0) { _ in 2 }
        let distance = await Task { tree.distance(to: 3) }.value
        #expect(distance == 6)
        let undirected = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "b")]).dijkstraShortestPaths(from: "a") { _ in 1.5 }
        let fromTask = await Task { undirected.path(to: "b") }.value
        #expect(fromTask == ["a", "b"])
    }

    @Test("SP-128 existentials work through a some wrapper")
    func existentials() {
        func run(_ g: some DirectedGraph<Int>) -> Int? {
            g.dijkstraShortestPaths(from: 0) { _ in 1 }.distance(to: 3)
        }
        func runAll(_ g: some DirectedGraph<Int>) -> [Int?] {
            [g.shortestPaths(from: 0).distance(to: 3), g.bellmanFordShortestPaths(from: 0) { _ in 1 }?.distance(to: 3),
             g.dijkstraShortestPath(from: 0, to: 3) { _ in 1 }?.distance, g.aStarShortestPath(from: 0, to: 3, weight: { _ in 1 }, heuristic: { _ in 0 })?.distance]
        }
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]
        let graphs: [any DirectedGraph<Int>] = [
            AdjacencyMatrix(vertexCount: 4, edges: edges),
            CompressedSparseRow(vertexCount: 4, edges: edges),
            AdjacencyList(edges: edges),
            ReferenceDirectedMultigraph(edges: edges),
            UndirectedAdjacencyList(edges: edges.map { UndirectedEdge($0.source, $0.target) }).directed,
        ]
        for graph in graphs {
            #expect(run(graph) == 3)
            #expect(runAll(graph) == [3, 3, 3, 3])
        }
    }

    @Test("SP-129 an indexed adjacency list is searched in index space, without hashing vertices")
    func noPerVertexHashing() {
        let counter = HashCounter()
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = AdjacencyList(edges: xg.map { DirectedEdge(from: HashCountingVertex(value: $0.0, counter: counter), to: HashCountingVertex(value: $0.1, counter: counter)) })
        // Positions are insertion order, so the weights are an array beside the graph.
        let weights = xg.map(\.2)
        let source = HashCountingVertex(value: "s", counter: counter)
        let target = HashCountingVertex(value: "v", counter: counter)

        counter.hashes = 0
        let dijkstra = graph.dijkstraShortestPaths(from: source) { weights[$0] }
        // Looking up the source (and checking it is a vertex), not one hash per vertex or edge.
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        let bellmanFord = graph.bellmanFordShortestPaths(from: source) { weights[$0] }
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        let unweighted = graph.shortestPaths(from: source)
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        let single = graph.dijkstraShortestPath(from: source, to: target) { weights[$0] }
        #expect(counter.hashes <= 4)
        counter.hashes = 0
        _ = graph.findNegativeCycle(from: source) { weights[$0] }
        #expect(counter.hashes <= 2)

        #expect(dijkstra.distance(to: target) == 9)
        #expect(bellmanFord?.distance(to: target) == 9)
        #expect(unweighted.distance(to: target) == 2)
        #expect(single?.distance == 9)
        #expect(dijkstra.path(to: target)?.map(\.value) == ["s", "x", "u", "v"])
    }

    @Test("SP-130 weights are read only for examined edges: the single-target query reads fewer than all")
    func lazyWeightReads() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        var reads = 0
        let result = graph.dijkstraShortestPath(from: "s", to: "v") { position in
            reads += 1
            return xg[position].2
        }
        #expect(result?.distance == 9)
        // v's own out-edge (v→y) is never examined.
        #expect(reads < graph.edgeCount)
        var near = 0
        _ = graph.dijkstraShortestPath(from: "s", to: "x") { position in
            near += 1
            return xg[position].2
        }
        #expect(near <= 2)
    }
}
