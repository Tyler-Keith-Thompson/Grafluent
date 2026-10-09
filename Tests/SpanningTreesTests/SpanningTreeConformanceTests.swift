// Preconditions (exit tests), value semantics, Equatable, Hashable and Sendable, existentials and
// generic code, weight-call counts on every representation, index-space dispatch (no vertex hashing
// on an indexed adjacency list), and digraphs through `.undirected`. Case IDs (ST-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

/// An undirected pseudograph with no vertex or edge indices. A self-loop is listed twice at its
/// vertex.
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

/// A vertex type that is not Sendable, so a graph of it is not either.
private final class Token: Hashable {
    let id: Int
    init(_ id: Int) { self.id = id }
    static func == (lhs: Token, rhs: Token) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@Suite("Spanning-tree preconditions, value semantics and dispatch")
struct SpanningTreeConformanceTests {
    @Test("ST-120 a NaN weight on a non-loop edge traps, for each weighted entry point and representation", .tags(.precondition))
    func nanWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 12)])
            let weights: [Double] = [1, 2, .nan]
            _ = graph.minimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 12)])
            let weights: [Double] = [1, 2, .nan]
            _ = graph.kruskalMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 12)])
            let weights: [Double] = [1, 2, .nan]
            _ = graph.primMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 12)])
            let weights: [Double] = [1, 2, .nan]
            _ = graph.primMinimumSpanningTree(from: 2) { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 12)])
            let weights: [Double] = [1, 2, .nan]
            _ = graph.boruvkaMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 12)])
            let weights: [Double] = [1, 2, .nan]
            _ = graph.maximumSpanningTree { weights[$0] }
        }
        // ST-58 as arcs: 1→2 (NaN) and 2→1 (3) are parallel edges of the view.
        await #expect(processExitsWith: .failure) {
            let arcs = [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 1)]
            let weights: [Double] = [.nan, 3, 2, 4]
            _ = AdjacencyList(edges: arcs).undirected.kruskalMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let arcs = [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 1)]
            let weights: [Double] = [.nan, 3, 2, 4]
            _ = AdjacencyList(edges: arcs).undirected.boruvkaMinimumSpanningTree { weights[$0] }
        }
        // Without vertex indices.
        await #expect(processExitsWith: .failure) {
            let graph = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [.nan, 1]
            _ = graph.minimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let weights: [Double] = [.nan, 1]
            _ = graph.primMinimumSpanningTree(from: 2) { weights[$0] }
        }
    }

    @Test("ST-121 primMinimumSpanningTree(from:) with a vertex not in the graph traps", .tags(.precondition))
    func rootNotAVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).primMinimumSpanningTree(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge("a", "b")]).primMinimumSpanningTree(from: "z") { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = PlainGraph(vertices: [0, 1], edges: [UndirectedEdge(0, 1)]).primMinimumSpanningTree(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).undirected.primMinimumSpanningTree(from: 9) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).undirected.primMinimumSpanningTree(from: 2) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            // An empty graph has no vertex to start from.
            _ = UndirectedAdjacencyList<Int>().primMinimumSpanningTree(from: 0) { _ in 1 }
        }
    }

    @Test("ST-122 a NaN total traps, for each weighted entry point", .tags(.precondition))
    func nanTotal() async {
        await #expect(processExitsWith: .failure) {
            let weights: [Double] = [.infinity, -.infinity]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).minimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights: [Double] = [.infinity, -.infinity]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).kruskalMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights: [Double] = [.infinity, -.infinity]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).primMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights: [Double] = [.infinity, -.infinity]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).primMinimumSpanningTree(from: 1) { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights: [Double] = [.infinity, -.infinity]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).boruvkaMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights: [Double] = [.infinity, -.infinity]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).maximumSpanningTree { weights[$0] }
        }
    }

    @Test("ST-123 overflow in the total traps, for each weighted entry point", .tags(.precondition))
    func overflow() async {
        await #expect(processExitsWith: .failure) {
            let weights = [Int.max, 1]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).minimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights = [Int.max, 1]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).kruskalMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights = [Int.max, 1]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).primMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights = [Int.max, 1]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).primMinimumSpanningTree(from: 2) { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights = [Int.max, 1]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).boruvkaMinimumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            let weights = [Int.max, 1]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).maximumSpanningTree { weights[$0] }
        }
        await #expect(processExitsWith: .failure) {
            // UInt8 has no room above 255.
            let weights: [UInt8] = [200, 100]
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).maximumSpanningTree { weights[$0] }
        }
    }

    @Test("ST-124 a forest is a value: mutating the graph afterwards changes nothing", .tags(.copyOnWrite))
    func valueSemantics() {
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        var weights = [1, 2, 3]
        let tree = graph.minimumSpanningTree { weights[$0] }
        let prim = graph.primMinimumSpanningTree { weights[$0] }
        let unweighted = graph.minimumSpanningTree()
        #expect(graph.insert(edge: UndirectedEdge(0, 3)).inserted)
        weights.append(-10)
        #expect(tree.edges == [0, 1, 2])
        #expect(tree.weight == 6)
        #expect(Set(prim.edges) == [0, 1, 2])
        #expect(prim.weight == 6)
        #expect(unweighted.edges == [0, 1, 2])
        let after = graph.minimumSpanningTree { weights[$0] }
        #expect(after.edges == [3, 0, 1])
        #expect(after.weight == -7)
        // The old forest still names the old positions, and a copy is equal to it.
        let copy = tree
        #expect(copy == tree)
        #expect(copy != after)
    }

    @Test("ST-125 SpanningForest is Equatable, Hashable and Sendable; two runs are equal", .tags(.conformance))
    func conformances() async {
        let wiki: [(String, String, Int)] = [
            ("0", "1", 7), ("0", "3", 5), ("1", "2", 8), ("1", "3", 9), ("1", "4", 7), ("2", "4", 5), ("3", "4", 15), ("3", "5", 6),
            ("4", "5", 8), ("4", "6", 9), ("5", "6", 11),
        ]
        let graph = UndirectedAdjacencyList(edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        let first = graph.minimumSpanningTree { wiki[$0].2 }
        let second = graph.minimumSpanningTree { wiki[$0].2 }
        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
        #expect(Set([first, second, graph.kruskalMinimumSpanningTree { wiki[$0].2 }]).count == 1)
        // Different weights or different edges make different forests.
        #expect(first != graph.maximumSpanningTree { wiki[$0].2 })
        let shifted = graph.minimumSpanningTree { wiki[$0].2 + 1 }
        #expect(shifted.edges == first.edges)
        #expect(shifted != first)

        // Sendable when the edge positions and the weight are, whatever the graph.
        let fromTask = await Task { first }.value
        #expect(fromTask == first)
        let doubles: SpanningForest<UndirectedAdjacencyList<String>, Double> = graph.primMinimumSpanningTree { Double(wiki[$0].2) }
        let weight = await Task { doubles.weight }.value
        #expect(weight == 39)
        func requireSendable<T: Sendable>(_: T.Type) -> Bool { true }
        #expect(requireSendable(SpanningForest<UndirectedAdjacencyList<Token>, Int>.self))
        let tokens = UndirectedAdjacencyList(edges: [UndirectedEdge(Token(0), Token(1)), UndirectedEdge(Token(1), Token(2))])
        let tokenForest = tokens.minimumSpanningTree { $0 + 1 }
        let tokenEdges = await Task { tokenForest.edges }.value
        #expect(tokenEdges == [0, 1])
    }

    @Test("ST-126 existentials and generic code give the same answers on every representation")
    func existentials() {
        // A path 0–1–2–3 and a chord 0–2, weighed by the endpoints so every representation agrees.
        func answers<G: Graph<Int>>(_ g: G) -> (weights: [Int], tree: Set<UndirectedEdge<Int>>) {
            let weight: (G.Edges.Index) -> Int = { g.edges[$0].u + g.edges[$0].v }
            let tree = g.minimumSpanningTree(weight: weight)
            let weights = [
                tree.weight,
                g.kruskalMinimumSpanningTree(weight: weight).weight,
                g.primMinimumSpanningTree(weight: weight).weight,
                g.primMinimumSpanningTree(from: 3, weight: weight).weight,
                g.boruvkaMinimumSpanningTree(weight: weight).weight,
                g.maximumSpanningTree(weight: weight).weight,
                g.minimumSpanningTree().weight,
            ]
            return (weights, Set(tree.edges.map { g.edges[$0] }))
        }
        let pairs = [(0, 1), (1, 2), (2, 3), (0, 2)]
        let graphs: [any Graph<Int>] = [
            UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) }),
            ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) }),
            PlainGraph(vertices: [0, 1, 2, 3], edges: pairs.map { UndirectedEdge($0.0, $0.1) }),
            AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected,
            AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected,
        ]
        for graph in graphs {
            let result = answers(graph)
            // Weights 1, 3, 5, 2: the minimum is {0–1, 0–2, 2–3} = 8, the maximum {2–3, 1–2, 0–2} = 10.
            #expect(result.weights == [8, 8, 8, 8, 8, 10, 3])
            #expect(result.tree == [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(2, 3)])
        }
    }

    @Test("ST-127 each non-loop edge is weighed exactly once, on every representation and entry point", .tags(.selfLoops))
    func weightCallCounts() {
        func check<G: Graph<Int>>(_ g: G, _ label: String) {
            let expected = g.edges.indices.filter { !g.edges[$0].isSelfLoop }.sorted()
            var asked: [G.Edges.Index] = []
            let weight: (G.Edges.Index) -> Int = { position in
                asked.append(position)
                return g.edges[position].u + g.edges[position].v
            }
            _ = g.minimumSpanningTree(weight: weight)
            #expect(asked.sorted() == expected, "\(label): default")
            asked = []
            _ = g.kruskalMinimumSpanningTree(weight: weight)
            #expect(asked.sorted() == expected, "\(label): Kruskal")
            asked = []
            _ = g.primMinimumSpanningTree(weight: weight)
            #expect(asked.sorted() == expected, "\(label): Prim")
            asked = []
            _ = g.primMinimumSpanningTree(from: 3, weight: weight)
            #expect(asked.sorted() == expected, "\(label): Prim from 3")
            asked = []
            _ = g.boruvkaMinimumSpanningTree(weight: weight)
            #expect(asked.sorted() == expected, "\(label): Borůvka")
            asked = []
            _ = g.maximumSpanningTree(weight: weight)
            #expect(asked.sorted() == expected, "\(label): maximum")
            // From the isolated vertex 4 nothing is weighed.
            asked = []
            _ = g.primMinimumSpanningTree(from: 4, weight: weight)
            #expect(asked.isEmpty, "\(label): Prim from 4")
        }
        // A triangle, a pendant edge and a self-loop at 3; 4 is isolated. The arc forms add a
        // parallel edge 1–0.
        let pairs = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 3)]
        let arcs = pairs + [(1, 0)]
        check(UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) }), "UndirectedAdjacencyList")
        check(ReferencePseudograph(vertices: 0 ..< 5, edges: arcs.map { UndirectedEdge($0.0, $0.1) }), "ReferencePseudograph")
        check(PlainGraph(vertices: [0, 1, 2, 3, 4], edges: arcs.map { UndirectedEdge($0.0, $0.1) }), "PlainGraph")
        check(AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected, "AdjacencyList.undirected")
        check(AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected, "AdjacencyMatrix.undirected")
    }

    @Test("ST-128 an indexed adjacency list is spanned in index space, without hashing vertices")
    func noVertexHashing() {
        let counter = HashCounter()
        let wiki: [(String, String, Int)] = [
            ("0", "1", 7), ("0", "3", 5), ("1", "2", 8), ("1", "3", 9), ("1", "4", 7), ("2", "4", 5), ("3", "4", 15), ("3", "5", 6),
            ("4", "5", 8), ("4", "6", 9), ("5", "6", 11),
        ]
        let graph = UndirectedAdjacencyList(edges: wiki.map {
            UndirectedEdge(HashCountingVertex(value: $0.0, counter: counter), HashCountingVertex(value: $0.1, counter: counter))
        })
        // Positions are insertion order, so the weights are an array beside the graph.
        let weights = wiki.map(\.2)
        let root = HashCountingVertex(value: "3", counter: counter)

        counter.hashes = 0
        let kruskal = graph.kruskalMinimumSpanningTree { weights[$0] }
        #expect(counter.hashes == 0)
        counter.hashes = 0
        let boruvka = graph.boruvkaMinimumSpanningTree { weights[$0] }
        #expect(counter.hashes == 0)
        counter.hashes = 0
        let tree = graph.minimumSpanningTree { weights[$0] }
        #expect(counter.hashes == 0)
        counter.hashes = 0
        let prim = graph.primMinimumSpanningTree { weights[$0] }
        #expect(counter.hashes == 0)
        counter.hashes = 0
        let maximum = graph.maximumSpanningTree { weights[$0] }
        #expect(counter.hashes == 0)
        counter.hashes = 0
        let unweighted = graph.minimumSpanningTree()
        #expect(counter.hashes == 0)
        counter.hashes = 0
        let rooted = graph.primMinimumSpanningTree(from: root) { weights[$0] }
        // Looking up the root (and checking it is a vertex), not one hash per vertex or edge.
        #expect(counter.hashes <= 2)

        #expect(kruskal.edges == [1, 5, 7, 0, 4, 9])
        #expect(tree == kruskal)
        #expect(Set(boruvka.edges) == Set(kruskal.edges))
        #expect(prim.weight == 39)
        #expect(rooted.weight == 39)
        #expect(maximum.weight == 59)
        #expect(unweighted.edges.count == 6)
    }

    @Test("ST-129 a digraph is spanned through .undirected, each arc an edge")
    func digraphThroughUndirected() {
        // Nothing is offered on DirectedGraph itself; that is a compile-time property, documented in
        // the README rather than tested.
        let digraph = AdjacencyList(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c")])
        let weights = [3, 1, 2]
        let forest: SpanningForest<UndirectedView<AdjacencyList<String>>, Int> = digraph.undirected.minimumSpanningTree { weights[$0] }
        #expect(forest.edges == [1, 2])
        #expect(forest.weight == 3)
        #expect(forest.edges.map { digraph.edges[$0] } == [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "c")])
        let unweighted: SpanningForest<UndirectedView<AdjacencyList<String>>, Int> = digraph.undirected.minimumSpanningTree()
        #expect(unweighted.edges == [0, 2])
    }
}
