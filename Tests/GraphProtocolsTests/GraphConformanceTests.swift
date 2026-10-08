// Which types conform to Graph, what their associated types are, generic and existential use,
// Sendable, the result builder, and conditional Comparable. Case IDs (UG-Tnn) refer to the
// catalog in README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Graph conformances", .tags(.conformance))
struct GraphConformanceTests {
    @Test("UG-T01 the associated types, read through generic code, are the adjacency list's own")
    func associatedTypes() {
        func neighbors<G: Graph>(_: G.Type) -> Any.Type { G.Neighbors.self }
        func incidentEdges<G: Graph>(_: G.Type) -> Any.Type { G.IncidentEdges.self }
        func neighborIndices<G: Graph>(_: G.Type) -> Any.Type { G.NeighborIndices.self }
        func edgeIndex<G: Graph>(_: G.Type) -> Any.Type { G.Edges.Index.self }
        func vertices<G: Graph>(_: G.Type) -> Any.Type { G.Vertices.self }
        func edges<G: Graph>(_: G.Type) -> Any.Type { G.Edges.self }
        #expect(ObjectIdentifier(incidentEdges(UndirectedAdjacencyList<Int>.self)) == ObjectIdentifier(ArraySlice<Int>.self))
        #expect(ObjectIdentifier(neighborIndices(UndirectedAdjacencyList<Int>.self)) == ObjectIdentifier(ArraySlice<Int>.self))
        #expect(ObjectIdentifier(edgeIndex(UndirectedAdjacencyList<Int>.self)) == ObjectIdentifier(Int.self))
        #expect(ObjectIdentifier(neighbors(UndirectedAdjacencyList<Int>.self)) == ObjectIdentifier(UndirectedAdjacencyList<Int>.Neighbors.self))
        #expect(ObjectIdentifier(vertices(UndirectedAdjacencyList<Int>.self)) == ObjectIdentifier(UndirectedAdjacencyList<Int>.Vertices.self))
        #expect(ObjectIdentifier(edges(UndirectedAdjacencyList<Int>.self)) == ObjectIdentifier(UndirectedAdjacencyList<Int>.Edges.self))
        #expect(ObjectIdentifier(neighbors(UndirectedAdjacencyList<String>.self)) == ObjectIdentifier(UndirectedAdjacencyList<String>.Neighbors.self))
    }

    @Test("UG-T02 some Graph<Int> accepts the adjacency list, the pseudograph and the undirected view")
    func someGraph() {
        func count(_ g: some Graph<Int>) -> Int { g.edgeCount }
        let house = UndirectedFixture<Int>.house
        #expect(count(UndirectedAdjacencyList(edges: house.edges)) == 6)
        #expect(count(ReferencePseudograph(edges: house.edges)) == 6)
        #expect(count(AdjacencyList(edges: DirectedFixture<Int>.house.edges).undirected) == 7)
    }

    @Test("UG-T03 existentials hold every conformer")
    func existentials() {
        let house = UndirectedFixture<Int>.house
        let graphs: [any Graph<Int>] = [
            UndirectedAdjacencyList(edges: house.edges),
            ReferencePseudograph(edges: house.edges),
            // Each edge's two arcs become two parallel edges.
            AdjacencyList(UndirectedAdjacencyList(edges: house.edges).directed).undirected,
        ]
        #expect(graphs.map(\.edgeCount) == [6, 6, 12])
        for g in graphs {
            #expect(g.vertexCount == 5)
            #expect(Set(g.neighbors(of: 2)) == [0, 3, 4])
            #expect(g.contains(edge: UndirectedEdge(4, 2)))
            #expect(!g.contains(edge: UndirectedEdge(0, 3)))
            #expect(g.vertexIndexBound == 5)
        }
        #expect(graphs.map { $0.degree(of: 2) } == [3, 3, 6])
    }

    @Test("UG-T04 Sendable composes with the protocol")
    func sendable() async {
        func count<G: Graph & Sendable>(_ g: G) async -> Int {
            await Task.detached { g.edgeCount }.value
        }
        let house = UndirectedFixture<Int>.house
        #expect(await count(UndirectedAdjacencyList(edges: house.edges)) == 6)
        #expect(await count(UndirectedAdjacencyList(vertices: ["a"], edges: [UndirectedEdge("a", "b")])) == 1)
        #expect(await count(ReferencePseudograph(edges: house.edges)) == 6)
    }

    @Test("UG-T05 no type is both a Graph and a DirectedGraph")
    func noDualConformance() {
        #expect((UndirectedAdjacencyList<Int>() as Any) is any DirectedGraph == false)
        #expect((UndirectedAdjacencyList<Int>() as Any) is any Graph)
        #expect((AdjacencyList<Int>() as Any) is any Graph == false)
        #expect((AdjacencyList<Int>() as Any) is any DirectedGraph)
        #expect((ReferencePseudograph<Int>(edges: []) as Any) is any DirectedGraph == false)
        // The views cross over, each to the other protocol only.
        #expect((UndirectedAdjacencyList<Int>().directed as Any) is any Graph == false)
        #expect((UndirectedAdjacencyList<Int>().directed as Any) is any BidirectionalDirectedGraph)
        #expect((AdjacencyList<Int>().undirected as Any) is any DirectedGraph == false)
        #expect((AdjacencyList<Int>().undirected as Any) is any Graph)
    }

    @Test("UG-T08 the result builder: edges, bare vertices and for loops")
    func builder() {
        let ring = UndirectedAdjacencyList<Int> {
            for i in 0 ..< 5 { UndirectedEdge(i, (i + 1) % 5) }
            99
        }
        func counts(_ g: some Graph<Int>) -> [Int] { [g.vertexCount, g.edgeCount, g.degree(of: 99), g.degree(of: 0)] }
        #expect(counts(ring) == [6, 5, 0, 2])
        let unannotated = UndirectedAdjacencyList {
            UndirectedEdge(0, 1)
            UndirectedEdge(1, 1)
        }
        #expect(unannotated.vertexCount == 2)
        #expect(unannotated.edgeCount == 2)
    }

    @Test("UG-T08 the result builder reads an edge as an edge even when the vertex type could hold it")
    func builderPrefersEdges() {
        // Both buildExpression overloads accept this first statement; the vertex one is disfavored.
        let anyHashable = UndirectedAdjacencyList<AnyHashable> {
            UndirectedEdge<AnyHashable>(0, 1)
            AnyHashable(UndirectedEdge(5, 6))
        }
        #expect(anyHashable.vertexCount == 3)
        #expect(anyHashable.edgeCount == 1)
        #expect(anyHashable.contains(AnyHashable(UndirectedEdge(5, 6))))
        // A graph whose vertices are edges (a line graph): an edge of edges is an edge, a bare edge is a vertex.
        let a = UndirectedEdge(0, 1)
        let b = UndirectedEdge(1, 2)
        let line = UndirectedAdjacencyList<UndirectedEdge<Int>> {
            UndirectedEdge(a, b)
            UndirectedEdge(2, 3)
        }
        #expect(line.vertexCount == 3)
        #expect(line.edgeCount == 1)
        #expect(line.contains(edge: UndirectedEdge(b, a)))
        #expect(line.contains(UndirectedEdge(3, 2)))
    }

    @Test("UG-T09 UndirectedEdge is Comparable only when its vertices are")
    func comparableOnlyWhenPossible() {
        #expect((UndirectedEdge(1, 2) as Any) is any Comparable)
        #expect((UndirectedEdge("a", "b") as Any) is any Comparable)
        #expect((UndirectedEdge<AnyHashable>(1, 2) as Any) is any Comparable == false)
    }
}

@Suite("Edge identity and vertex indices through generic code")
struct GraphIdentityTests {
    @Test("UG-L17 parallel edges are told apart by position, so the cheaper copy wins")
    func parallelEdgesByPosition() {
        // 0–1 weighs 5, a parallel 1–0 weighs 1, 0–2 weighs 2, and a loop at 0 weighs 9.
        func cheapest<G: Graph>(_ g: G, from source: G.Vertex, weight: (G.Edges.Index) -> Double) -> [G.Vertex: Double] {
            var best: [G.Vertex: Double] = [:]
            for e in g.incidentEdges(of: source) {
                let w = g.oppositeVertex(to: source, acrossEdgeAt: e)
                best[w] = min(best[w] ?? .infinity, weight(e))
            }
            return best
        }
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(0, 2), UndirectedEdge(0, 0)])
        let weights = [5.0, 1.0, 2.0, 9.0]
        #expect(cheapest(graph, from: 0) { weights[$0] } == [1: 1, 2: 2, 0: 9])
        #expect(cheapest(graph, from: 1) { weights[$0] } == [0: 1])
    }

    @Test("UG-L19 dense vertex indices are found through generic layers and existentials")
    func indicesThroughLayers() {
        func bound(_ g: some Graph<Int>) -> Int? { g.vertexIndexBound }
        func outer(_ g: some Graph<Int>) -> Int? { bound(g) }
        func existential(_ g: any Graph<Int>) -> Int? { g.vertexIndexBound }
        let house = UndirectedFixture<Int>.house
        let list = UndirectedAdjacencyList(edges: house.edges)
        let pseudograph = ReferencePseudograph(edges: house.edges)
        #expect([outer(list), outer(pseudograph)] == [5, 5])
        #expect([existential(list), existential(pseudograph)] == [5, 5])
        let strings = UndirectedFixture<String>.networkXABCD
        func stringBound(_ g: some Graph<String>) -> Int? { g.vertexIndexBound }
        #expect(stringBound(UndirectedAdjacencyList(vertices: strings.vertices, edges: strings.edges)) == 7)
    }

    @Test("UG-L21 breadth-first search on index rows when the graph has indices")
    func indexedSearch() {
        func reached<G: Graph>(_ g: G, from source: G.Vertex) -> Set<G.Vertex> {
            guard let n = g.vertexIndexBound else { return [] }
            var visited = [Bool](repeating: false, count: n)
            visited[g.vertexIndex(of: source)] = true
            var queue = [g.vertexIndex(of: source)]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in g.neighborIndices(ofIndex: v) where !visited[w] {
                    visited[w] = true
                    queue.append(w)
                }
            }
            return Set(queue.map { g.vertex(atIndex: $0) })
        }
        let abcd = UndirectedFixture<String>.networkXABCD
        #expect(reached(UndirectedAdjacencyList(vertices: abcd.vertices, edges: abcd.edges), from: "D") == ["A", "B", "C", "D"])
        #expect(reached(ReferencePseudograph(vertices: abcd.vertices, edges: abcd.edges), from: "G") == ["G"])
        // Vertices that are not 0..<n: the index is not the vertex value.
        let sparse = UndirectedAdjacencyList(edges: [UndirectedEdge(5, 1000), UndirectedEdge(-3, 1000)])
        #expect(reached(sparse, from: 5) == [5, 1000, -3])
        let components = UndirectedFixture<Int>.components7
        #expect(reached(UndirectedAdjacencyList(vertices: components.vertices, edges: components.edges), from: 4) == [3, 4])
    }
}
