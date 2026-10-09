// §K: preconditions (exit tests), value semantics, Sendable and Equatable, index-space dispatch
// (no vertex hashing on an indexed adjacency list), generic code and existentials, digraphs through
// `.undirected`, the result type of connectedComponents(), and determinism. Case IDs (CN-nnn) refer
// to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
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

/// An undirected pseudograph with no vertex or edge indices: queries look vertices and positions
/// up in dictionaries.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Undirected connectivity dispatch and value semantics", .tags(.conformance))
struct UndirectedConnectivityConformanceTests {
    @Test("CN-391 component(ofEdgeAt:) of a self-loop is nil", .tags(.selfLoops))
    func selfLoopHasNoBlock() {
        // 0-1 1-1 1-2: the loop at position 1.
        let edges = [(0, 1), (1, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) }
        let reference = ReferencePseudograph(edges: edges).biconnectedComponents()
        #expect(reference.component(ofEdgeAt: 1) == nil)
        #expect(reference.component(ofEdgeAt: 0) == 0)
        #expect(reference.component(ofEdgeAt: 2) == 1)
        let list = UndirectedAdjacencyList(edges: edges).biconnectedComponents()
        #expect(list.component(ofEdgeAt: 1) == nil)
        let plain = PlainGraph(vertices: [0, 1, 2], edges: edges).biconnectedComponents()
        #expect(plain.component(ofEdgeAt: 1) == nil)
        #expect(plain.component(ofEdgeAt: 2) == 1)
        let matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)]).undirected
        let cells = matrix.biconnectedComponents()
        #expect(matrix.edges.indices.map { cells.component(ofEdgeAt: $0) } == [nil, 0])
    }

    @Test("CN-393 results are values: mutating the graph afterwards changes nothing in them", .tags(.copyOnWrite))
    func valueSemantics() {
        // The path 0-1-2-3: three bridges, points 1 and 2.
        var graph = UndirectedAdjacencyList(edges: [(0, 1), (1, 2), (2, 3)].map { UndirectedEdge($0.0, $0.1) })
        let components = graph.connectedComponents()
        let blocks = graph.biconnectedComponents()
        let twoEdge = graph.biEdgeConnectedComponents()
        let tree = graph.blockCutTree()
        // 3-0 closes the cycle; 4 is new and isolated.
        graph.insert(edge: UndirectedEdge(3, 0))
        graph.insert(4)
        #expect(components.map(Array.init) == [[0, 1, 2, 3]])
        #expect(components.component(of: 3) == 0)
        #expect(blocks.map(Array.init) == [[0], [1], [2]])
        #expect(blocks.component(ofEdgeAt: 2) == 2)
        #expect(Array(blocks.components(containing: 1)) == [0, 1])
        #expect(twoEdge.map(Array.init) == [[0], [1], [2], [3]])
        #expect(tree.articulationPoints == [1, 2])
        #expect(tree.node(of: 1) == .articulationPoint(0))
        #expect(tree.edgeCount == 4)
        // The graph itself has changed.
        #expect(graph.connectedComponents().map(Array.init) == [[0, 1, 2, 3], [4]])
        #expect(graph.biconnectedComponents().map(Array.init) == [[0, 1, 2, 3]])
        #expect(graph.articulationPoints().isEmpty)
    }

    @Test("CN-394 results are Sendable")
    func sendable() async {
        let graph = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0), (2, 3)].map { UndirectedEdge($0.0, $0.1) })
        let components = graph.connectedComponents()
        let blocks = graph.biconnectedComponents()
        let tree = graph.blockCutTree()
        let count = await Task.detached { components.count }.value
        #expect(count == 1)
        let block = await Task.detached { blocks.component(ofEdgeAt: 3) }.value
        #expect(block == 1)
        let node = await Task.detached { tree.node(of: 2) }.value
        #expect(node == .articulationPoint(0))
        let list = UndirectedAdjacencyList(edges: [(0, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
        let listTree = list.blockCutTree()
        let edgeCount = await Task.detached { listTree.edgeCount }.value
        #expect(edgeCount == 2)
    }

    @Test("CN-394 equality compares blocks, their vertices and the tree, in order, not the graph")
    func equality() {
        let path = ReferencePseudograph(edges: [(0, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
        // A loop appended: a different graph with the same blocks.
        let looped = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(path.biconnectedComponents() == looped.biconnectedComponents())
        #expect(path.blockCutTree() == looped.blockCutTree())
        #expect(path.biconnectedComponents() == path.biconnectedComponents())
        // The same edge positions on other vertices: not equal.
        let elsewhere = ReferencePseudograph(edges: [(5, 6), (6, 7)].map { UndirectedEdge($0.0, $0.1) })
        #expect(path.biconnectedComponents().map(Array.init) == elsewhere.biconnectedComponents().map(Array.init))
        #expect(path.biconnectedComponents() != elsewhere.biconnectedComponents())
        #expect(path.blockCutTree() != elsewhere.blockCutTree())
        // The same vertices, the blocks split differently: a triangle against a path plus an edge.
        let triangle = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let fan = ReferencePseudograph(edges: [(0, 1), (1, 2), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(triangle.biconnectedComponents() != fan.biconnectedComponents())
        // Node is Hashable.
        let nodes: Set<BlockCutTree<ReferencePseudograph<Int>>.Node> = [.block(0), .articulationPoint(0), .block(0)]
        #expect(nodes.count == 2)
        #expect(!path.biconnectedComponents().description.isEmpty)
    }

    @Test("CN-395 an indexed UndirectedAdjacencyList is processed in index space: no entry point hashes a vertex")
    func indexSpace() {
        let counter = HashCounter()
        // CN-243: JGraphT's testWikiGraph.
        let wiki = [(1, 3), (1, 2), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (7, 9), (9, 10), (9, 11), (11, 12), (12, 13), (13, 14), (12, 14), (7, 14)]
        let graph = UndirectedAdjacencyList(edges: wiki.map { UndirectedEdge(HashCountingVertex(value: $0.0, counter: counter), HashCountingVertex(value: $0.1, counter: counter)) })
        counter.hashes = 0
        let components = graph.connectedComponents()
        #expect(counter.hashes == 0)
        #expect(components.count == 1)
        #expect(graph.isConnected)
        #expect(counter.hashes == 0)
        #expect(graph.bridges() == [4, 5, 6, 7, 9])
        #expect(graph.hasBridges)
        #expect(counter.hashes == 0)
        #expect(graph.articulationPoints().map(\.value) == [4, 5, 6, 7, 9])
        #expect(counter.hashes == 0)
        let blocks = graph.biconnectedComponents()
        #expect(counter.hashes == 0)
        #expect(blocks.count == 7)
        #expect(!graph.isBiconnected)
        #expect(counter.hashes == 0)
        let twoEdge = graph.biEdgeConnectedComponents()
        #expect(!graph.isBiEdgeConnected)
        #expect(counter.hashes == 0)
        #expect(twoEdge.count == 6)
        let tree = graph.blockCutTree()
        #expect(counter.hashes == 0)
        #expect(tree.edgeCount == 11)
        // Queries hash only their argument, once for the adjacency list's own lookup.
        let seven = HashCountingVertex(value: 7, counter: counter)
        counter.hashes = 0
        #expect(Array(blocks.components(containing: seven)) == [3, 4, 5])
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        #expect(tree.node(of: seven) == .articulationPoint(3))
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        #expect(twoEdge.component(of: seven) == 3)
        #expect(counter.hashes <= 2)
        counter.hashes = 0
        #expect(blocks.component(ofEdgeAt: 8) == 5)
        #expect(counter.hashes == 0)
    }

    @Test("CN-396 generic code: every entry point is callable from some Graph, and an existential is opened by a some wrapper")
    func genericCode() {
        func summary(_ g: some Graph<Int>) -> [Int] {
            let blocks = g.biconnectedComponents()
            let tree = g.blockCutTree()
            return [
                g.connectedComponents().count, g.isConnected ? 1 : 0, g.bridges().count, g.hasBridges ? 1 : 0,
                g.articulationPoints().count, blocks.count, g.isBiconnected ? 1 : 0,
                g.biEdgeConnectedComponents().count, g.isBiEdgeConnected ? 1 : 0, tree.edgeCount,
            ]
        }
        func outer<G: Graph<Int>>(_ g: G) -> [Int] { summary(g) }
        // CN-208: 0-1 2-1 0-2 2-3 3-4.
        let edges = [(0, 1), (2, 1), (0, 2), (2, 3), (3, 4)].map { UndirectedEdge($0.0, $0.1) }
        let expected = [1, 1, 2, 1, 2, 3, 0, 3, 0, 4]
        #expect(summary(ReferencePseudograph(edges: edges)) == expected)
        #expect(outer(UndirectedAdjacencyList(edges: edges)) == expected)
        #expect(outer(PlainGraph(vertices: [0, 1, 2, 3, 4], edges: edges)) == expected)
        let graphs: [any Graph<Int>] = [ReferencePseudograph(edges: edges), UndirectedAdjacencyList(edges: edges)]
        for g in graphs { #expect(summary(g) == expected) }
    }

    @Test("CN-397 CN-296 a bidirectional digraph reaches the undirected half through .undirected, each arc an edge")
    func digraphThroughUndirected() {
        let arcs = [(0, 1), (1, 0), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let list = AdjacencyList(edges: arcs).undirected
        #expect(list.bridges() == [2])
        #expect(list.articulationPoints() == [1])
        #expect(list.biconnectedComponents().map(Array.init) == [[0, 1], [2]])
        #expect(list.biEdgeConnectedComponents().map(Array.init) == [[0, 1], [2]])
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: arcs).undirected
        #expect(matrix.bridges().map { [$0.source, $0.target] } == [[1, 2]])
        #expect(matrix.articulationPoints() == [1])
        // The digraph's own weak components are the view's connected components.
        let digraph = AdjacencyList(edges: arcs)
        #expect(list.connectedComponents().map(Array.init) == digraph.weaklyConnectedComponents().map(Array.init))
        #expect(list.isConnected == digraph.isWeaklyConnected)
    }

    @Test("CN-398 connectedComponents() returns Components<DirectedView<Self>>, equal to directed.weaklyConnectedComponents()")
    func componentsType() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [(0, 3), (1, 4), (2, 5), (3, 0)].map { UndirectedEdge($0.0, $0.1) })
        let components: Components<DirectedView<UndirectedAdjacencyList<Int>>> = graph.connectedComponents()
        #expect(components == graph.directed.weaklyConnectedComponents())
        #expect(components.map(Array.init) == [[0, 3], [1, 4], [2, 5]])
        #expect(components.component(of: 4) == 1)
        #expect(components.component(ofIndex: 5) == 2)
        let twoEdge: Components<DirectedView<UndirectedAdjacencyList<Int>>> = graph.biEdgeConnectedComponents()
        // The adjacency list collapsed 3-0 into 0-3, so every edge is a bridge.
        #expect(twoEdge.map(Array.init) == [[0], [1], [2], [3], [4], [5]])
        #expect(twoEdge.component(of: 4) == 4)
    }

    @Test("CN-399 results computed twice, or from equal graphs built apart, are equal")
    func determinism() {
        let pairs = [(0, 1), (0, 5), (0, 6), (0, 14), (1, 5), (1, 6), (1, 14), (2, 4), (2, 10), (3, 4), (3, 15), (4, 6), (4, 7), (4, 10), (5, 14), (6, 14), (7, 9), (8, 9), (8, 12), (8, 13), (10, 15), (11, 12), (11, 13), (12, 13)]
        let one = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let two = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(one.connectedComponents() == one.connectedComponents())
        #expect(one.bridges() == two.bridges())
        #expect(one.articulationPoints() == two.articulationPoints())
        #expect(one.biconnectedComponents() == two.biconnectedComponents())
        #expect(one.biEdgeConnectedComponents() == two.biEdgeConnectedComponents())
        #expect(one.blockCutTree() == two.blockCutTree())
        let strings = pairs.map { UndirectedEdge("v\($0.0)", "v\($0.1)") }
        let first = ReferencePseudograph(edges: strings)
        let second = ReferencePseudograph(edges: strings)
        #expect(first.biconnectedComponents() == second.biconnectedComponents())
        #expect(first.blockCutTree() == second.blockCutTree())
        #expect(first.articulationPoints() == ["v6", "v4", "v7", "v9", "v8"])
    }
}

@Suite("Undirected connectivity preconditions", .tags(.precondition))
struct UndirectedConnectivityPreconditionTests {
    @Test("CN-390 components(containing:) and node(of:) with a vertex not in the graph trap; so does component(of:)")
    func vertexQueries() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().components(containing: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().components(containing: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().components(containing: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).blockCutTree().node(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).blockCutTree().node(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).connectedComponents().component(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)]).biEdgeConnectedComponents().component(of: 9)
        }
    }

    @Test("CN-391 component(ofEdgeAt:) with a position not in the graph traps")
    func edgeQueries() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().component(ofEdgeAt: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().component(ofEdgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().component(ofEdgeAt: 5)
        }
    }

    @Test("CN-392 the subscript, vertices(ofComponentAt:), articulationPoints(ofBlock:) and blocks(ofArticulationPoint:) out of range trap")
    func outOfRange() async {
        // 0-1 1-2: two blocks, one articulation point.
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents()[2]
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents()[-1]
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).biconnectedComponents().vertices(ofComponentAt: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).blockCutTree().articulationPoints(ofBlock: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).blockCutTree().blocks(ofArticulationPoint: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(vertices: [0]).blockCutTree().blocks(ofArticulationPoint: 0)
        }
    }
}
