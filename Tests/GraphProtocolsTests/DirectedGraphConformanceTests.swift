// Which types conform, what their associated types are, generic and existential use, edge identity
// and vertex indices through generic code, and conversions between representations through the
// protocol. Case IDs (DG-Tnn, DG-Cnn, DG-Enn, DG-Inn) refer to the catalog in README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BitCollections
import CompressedSparseRowModule
import EdgeListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("DirectedGraph conformances", .tags(.conformance))
struct DirectedGraphConformanceTests {
    @Test("DG-T01 the associated types, read through generic code, are the representations' own views")
    func associatedTypes() {
        func successors<G: DirectedGraph>(_: G.Type) -> Any.Type { G.Successors.self }
        func predecessors<G: BidirectionalDirectedGraph>(_: G.Type) -> Any.Type { G.Predecessors.self }
        func vertices<G: DirectedGraph>(_: G.Type) -> Any.Type { G.Vertices.self }
        func edges<G: DirectedGraph>(_: G.Type) -> Any.Type { G.Edges.self }
        func outEdges<G: DirectedGraph>(_: G.Type) -> Any.Type { G.OutEdges.self }
        #expect(ObjectIdentifier(successors(AdjacencyList<Int>.self)) == ObjectIdentifier(AdjacencyList<Int>.Neighbors.self))
        #expect(ObjectIdentifier(predecessors(AdjacencyList<Int>.self)) == ObjectIdentifier(AdjacencyList<Int>.Neighbors.self))
        #expect(ObjectIdentifier(vertices(AdjacencyList<Int>.self)) == ObjectIdentifier(AdjacencyList<Int>.Vertices.self))
        #expect(ObjectIdentifier(edges(AdjacencyList<Int>.self)) == ObjectIdentifier(AdjacencyList<Int>.Edges.self))
        #expect(ObjectIdentifier(successors(AdjacencyMatrix.self)) == ObjectIdentifier(BitSet.self))
        #expect(ObjectIdentifier(predecessors(AdjacencyMatrix.self)) == ObjectIdentifier(BitSet.self))
        #expect(ObjectIdentifier(vertices(AdjacencyMatrix.self)) == ObjectIdentifier(Range<Int>.self))
        #expect(ObjectIdentifier(edges(AdjacencyMatrix.self)) == ObjectIdentifier(AdjacencyMatrix.Edges.self))
        #expect(ObjectIdentifier(successors(CompressedSparseRow.self)) == ObjectIdentifier(ArraySlice<Int>.self))
        #expect(ObjectIdentifier(vertices(CompressedSparseRow.self)) == ObjectIdentifier(Range<Int>.self))
        #expect(ObjectIdentifier(edges(CompressedSparseRow.self)) == ObjectIdentifier(CompressedSparseRow.Edges.self))
        #expect(ObjectIdentifier(outEdges(CompressedSparseRow.self)) == ObjectIdentifier(Range<Int>.self))
    }

    @Test("DG-T02 / DG-R09 which representations conform, and which are bidirectional")
    func conformances() {
        let graphs: [Any] = [AdjacencyList<Int>(), AdjacencyMatrix(), CompressedSparseRow(), EdgeList<Int>()]
        // An edge list answers adjacency by scanning, so it is not a DirectedGraph; convert it first.
        #expect(graphs.map { $0 is any DirectedGraph } == [true, true, true, false])
        #expect(graphs.map { $0 is any BidirectionalDirectedGraph } == [true, true, false, false])
    }

    @Test("DG-T02 some DirectedGraph<Int> accepts every representation")
    func someDirectedGraph() {
        func edgeCount(_ g: some DirectedGraph<Int>) -> Int { g.edgeCount }
        let house = DirectedFixture<Int>.house
        #expect(edgeCount(AdjacencyList(edges: house.edges)) == 7)
        #expect(edgeCount(AdjacencyMatrix(vertexCount: 6, edges: house.edges)) == 7)
        #expect(edgeCount(CompressedSparseRow(vertexCount: 6, edges: house.edges)) == 7)
        #expect(edgeCount(ReferenceDirectedMultigraph(edges: house.edges)) == 7)
    }

    @Test("DG-T03 some BidirectionalDirectedGraph<String> accepts an adjacency list")
    func someBidirectional() {
        func degree(_ g: some BidirectionalDirectedGraph<String>, of v: String) -> Int { g.degree(of: v) }
        let dag = DirectedFixture<String>.petgraphDAG
        #expect(degree(AdjacencyList(vertices: dag.vertices, edges: dag.edges), of: "b") == 4)
        #expect(degree(ReferenceDirectedMultigraph(vertices: dag.vertices, edges: dag.edges), of: "b") == 4)
    }

    @Test("DG-T04 existentials hold every representation")
    func existentials() {
        let house = DirectedFixture<Int>.house
        let graphs: [any DirectedGraph<Int>] = [
            AdjacencyList(edges: house.edges),
            AdjacencyMatrix(vertexCount: 6, edges: house.edges),
            CompressedSparseRow(vertexCount: 6, edges: house.edges),
        ]
        for g in graphs {
            #expect(g.edgeCount == 7)
            #expect(g.vertexCount == 6)
            #expect(Set(g.successors(of: 3)) == [2, 4])
            #expect(g.outDegree(of: 3) == 2)
            #expect(g.contains(edge: DirectedEdge(from: 3, to: 2)))
            #expect(g.vertexIndexBound == 6)
        }
    }

    @Test("DG-T05 Sendable composes with the protocol")
    func sendable() async {
        func count<G: DirectedGraph & Sendable>(_ g: G) async -> Int {
            await Task.detached { g.edgeCount }.value
        }
        let house = DirectedFixture<Int>.house
        #expect(await count(AdjacencyList(edges: house.edges)) == 7)
        #expect(await count(AdjacencyMatrix(vertexCount: 6, edges: house.edges)) == 7)
        #expect(await count(CompressedSparseRow(vertexCount: 6, edges: house.edges)) == 7)
    }
}

@Suite("Edge identity and vertex indices through generic code")
struct DirectedGraphIdentityTests {
    @Test("DG-E01 parallel edges are told apart by position, so the cheaper copy wins")
    func parallelEdgesByPosition() {
        // The review's probe: 0→1 weighs 5, a parallel 0→1 weighs 1, 0→2 weighs 2.
        func cheapest<G: DirectedGraph>(_ g: G, from source: G.Vertex, weight: (G.Edges.Index) -> Double) -> [G.Vertex: Double] {
            var best: [G.Vertex: Double] = [:]
            for e in g.outEdges(of: source) {
                let target = g.target(ofEdgeAt: e)
                best[target] = min(best[target] ?? .infinity, weight(e))
            }
            return best
        }
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        let weights = [5.0, 1.0, 2.0]
        #expect(cheapest(graph, from: 0) { weights[$0] } == [1: 1, 2: 2])
    }

    @Test("DG-E02 Dijkstra written once against edge positions gives the same distances on every representation")
    func dijkstra() {
        // Weights belong to edges, keyed here by (source, target) for the simple representations.
        func distances<G: DirectedGraph>(_ g: G, from source: G.Vertex, weight: (G.Edges.Index) -> Int) -> [G.Vertex: Int] {
            var distance = [source: 0]
            var done = Set<G.Vertex>()
            while let next = distance.filter({ !done.contains($0.key) }).min(by: { $0.value < $1.value }) {
                let (v, d) = (next.key, next.value)
                done.insert(v)
                for e in g.outEdges(of: v) {
                    let w = g.target(ofEdgeAt: e)
                    let candidate = d + weight(e)
                    if candidate < distance[w] ?? .max { distance[w] = candidate }
                }
            }
            return distance
        }
        // petgraph's Bellman–Ford fixture, with integer weights 1…11 by input position.
        let fixture = DirectedFixture<Int>.petgraphBellmanFord
        let weightOf = Dictionary(uniqueKeysWithValues: fixture.edges.enumerated().map { ($0.element, $0.offset + 1) })
        let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let matrix = AdjacencyMatrix(vertexCount: 9, edges: fixture.edges)
        let sparse = CompressedSparseRow(vertexCount: 9, edges: fixture.edges)
        let multigraph = ReferenceDirectedMultigraph(vertices: fixture.vertices, edges: fixture.edges)
        let expected = distances(multigraph, from: 0) { $0 + 1 }
        // 0→1 (1), 0→2 (2), then 3 by 1→3 (1 + 6) rather than 2→3 (2 + 7); 4…8 are unreachable.
        #expect(expected == [0: 0, 1: 1, 2: 2, 3: 7])
        #expect(distances(list, from: 0) { weightOf[list.edges[$0]]! } == expected)
        #expect(distances(matrix, from: 0) { weightOf[matrix.edges[$0]]! } == expected)
        #expect(distances(sparse, from: 0) { weightOf[sparse.edges[$0]]! } == expected)
    }

    @Test("DG-I01 dense vertex indices are found through any number of generic layers and through existentials")
    func indicesThroughLayers() {
        func bound(_ g: some DirectedGraph<Int>) -> Int? { g.vertexIndexBound }
        func outer(_ g: some DirectedGraph<Int>) -> Int? { bound(g) }
        func existential(_ g: any DirectedGraph<Int>) -> Int? { g.vertexIndexBound }
        let house = DirectedFixture<Int>.house
        let list = AdjacencyList(edges: house.edges)
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: house.edges)
        let sparse = CompressedSparseRow(vertexCount: 6, edges: house.edges)
        #expect([outer(list), outer(matrix), outer(sparse)] == [6, 6, 6])
        #expect([existential(list), existential(matrix), existential(sparse)] == [6, 6, 6])
        let strings = DirectedFixture<String>.networkXABCD
        func stringBound(_ g: some DirectedGraph<String>) -> Int? { g.vertexIndexBound }
        #expect(stringBound(AdjacencyList(vertices: strings.vertices, edges: strings.edges)) == 7)
    }

    @Test("DG-I02 breadth-first search on arrays when the graph has indices, on a dictionary when not")
    func indexedSearch() {
        func reached<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> Set<G.Vertex> {
            if let n = g.vertexIndexBound {
                var visited = [Bool](repeating: false, count: n)
                visited[g.vertexIndex(of: source)] = true
                var queue = [source]
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for w in g.successors(of: v) where !visited[g.vertexIndex(of: w)] {
                        visited[g.vertexIndex(of: w)] = true
                        queue.append(w)
                    }
                }
                return Set((0 ..< n).filter { visited[$0] }.map { g.vertex(atIndex: $0) })
            }
            var seen: Set = [source]
            var stack = [source]
            while let v = stack.popLast() {
                for w in g.successors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            return seen
        }
        let abcd = DirectedFixture<String>.networkXABCD
        #expect(reached(AdjacencyList(vertices: abcd.vertices, edges: abcd.edges), from: "A") == ["A", "B", "C", "D"])
        // Vertices that are not 0..<n: the index still works, because it is not the vertex value.
        let sparseInts = AdjacencyList(edges: [DirectedEdge(from: 5, to: 1000), DirectedEdge(from: 1000, to: -3)])
        #expect(reached(sparseInts, from: 5) == [5, 1000, -3])
        let house = DirectedFixture<Int>.house
        #expect(reached(CompressedSparseRow(vertexCount: 6, edges: house.edges), from: 3) == [0, 1, 2, 3, 4])
    }
}

@Suite("Conversions through DirectedGraph")
struct DirectedGraphConversionTests {
    @Test("DG-C01 an adjacency list from a multigraph collapses repeated edges")
    func fromMultigraphCollapses() {
        let chord = DirectedFixture<Int>.pathWithChord
        let graph = AdjacencyList(ReferenceDirectedMultigraph(edges: chord.edges))
        #expect(graph.vertexCount == 6)
        #expect(graph.edgeCount == 6)
        #expect(graph == AdjacencyList(vertices: chord.vertices, edges: chord.edges))
    }

    @Test("DG-C02 / DG-C03 an adjacency list from a matrix keeps isolated vertices")
    func fromMatrixKeepsIsolated() {
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.scipyConstructor2.edges)
        let graph = AdjacencyList(matrix)
        #expect(graph.vertexCount == 6)
        #expect(graph.edgeCount == 1)
        #expect(graph.contains(5))
        #expect(EdgeList(matrix).vertexCount == 2)
        let isolated = AdjacencyList(AdjacencyMatrix(vertexCount: 10))
        #expect(isolated.vertexCount == 10)
        #expect(isolated.edgeCount == 0)
    }

    @Test("DG-C05 / DG-C06 an edge list from any graph takes its edges in that graph's order")
    func edgeListFromGraph() {
        let house = DirectedFixture<Int>.house
        #expect(Array(EdgeList(CompressedSparseRow(vertexCount: 6, edges: house.edges))) == [
            DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 4),
            DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 1), DirectedEdge(from: 5, to: 3),
        ])
        #expect(Array(EdgeList(AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges))) == [
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 5), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 2),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 5, to: 0),
        ])
        let chord = ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.pathWithChord.edges)
        #expect(Array(EdgeList(chord)) == DirectedFixture<Int>.pathWithChord.edges)
        let list = AdjacencyList(edges: house.edges)
        #expect(Array(EdgeList(list)) == Array(list.edges))
        // EdgeList(list) of an EdgeList is still the copy, not a conversion.
        let edges = EdgeList(house.edges)
        #expect(EdgeList(edges) == edges)
    }

    @Test("DG-C07 round trips between the representations", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func roundTrips(_ fixture: DirectedFixture<Int>) {
        let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(AdjacencyMatrix(CompressedSparseRow(list)) == matrix)
        #expect(CompressedSparseRow(matrix) == sparse)
        #expect(AdjacencyList(sparse) == list)
        #expect(AdjacencyList(matrix) == list)
        #expect(CompressedSparseRow(ReferenceDirectedMultigraph(vertices: 0 ..< fixture.vertexCount, edges: fixture.edges)) == sparse)
    }

    @Test("DG-C14 converting keeps a test conformer's vertex order")
    func keepsVertexOrder() {
        let graph = ReferenceDirectedMultigraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "b", to: "a")])
        #expect(Array(AdjacencyList(graph).vertices) == ["c", "a", "b"])
    }

    @Test("DG-C10 a graph whose vertices are not 0..<n cannot become a matrix or compressed sparse row graph", .tags(.precondition))
    func outOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 2)]))
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 2)]))
        }
    }

    @Test("DG-C11 a multigraph whose vertices are exactly 0..<n converts, collapsing repeats")
    func zeroBasedMultigraph() {
        let neo4j = DirectedFixture<Int>.neo4jDirected
        let doubled = ReferenceDirectedMultigraph(edges: neo4j.edges + neo4j.edges)
        #expect(CompressedSparseRow(doubled) == CompressedSparseRow(vertexCount: 5, edges: neo4j.edges))
        #expect(AdjacencyMatrix(doubled) == AdjacencyMatrix(vertexCount: 5, edges: neo4j.edges))
    }

    @Test("DG-C12 String vertices: isolated vertices survive only where they were stored")
    func strings() {
        let abcd = DirectedFixture<String>.networkXABCD
        #expect(AdjacencyList(ReferenceDirectedMultigraph(edges: abcd.edges)).vertexCount == 4)
        #expect(AdjacencyList(AdjacencyList(vertices: abcd.vertices, edges: abcd.edges)).vertexCount == 7)
    }

    @Test("DG-C13 conversion keeps every generic answer", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func conversionKeepsAnswers(_ fixture: DirectedFixture<Int>) {
        func answers<G: DirectedGraph<Int>>(_ g: G) -> [Int] {
            var result = [g.vertexCount, g.edgeCount]
            for v in 0 ..< fixture.vertexCount {
                result.append(g.outDegree(of: v))
                for w in 0 ..< fixture.vertexCount { result.append(g.contains(edge: DirectedEdge(from: v, to: w)) ? 1 : 0) }
            }
            return result
        }
        let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let expected = answers(list)
        #expect(answers(AdjacencyMatrix(list)) == expected)
        #expect(answers(CompressedSparseRow(list)) == expected)
        #expect(answers(AdjacencyList(CompressedSparseRow(list))) == expected)
        #expect(answers(AdjacencyList(AdjacencyMatrix(list))) == expected)
    }
}
