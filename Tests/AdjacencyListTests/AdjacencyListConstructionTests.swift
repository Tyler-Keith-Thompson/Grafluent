// Construction. Case IDs (C-nn, E-nn, S-nn) refer to the catalog of cases harvested from NetworkX,
// petgraph, Boost.Graph and JGraphT; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList construction")
struct AdjacencyListConstructionTests {
    // MARK: Empty and isolated vertices

    @Test("C-01 an empty graph has no vertices and no edges")
    func empty() {
        let graph = AdjacencyList<Int>()
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
        #expect(graph.vertices.isEmpty)
        #expect(graph.vertices.count == 0)
        #expect(graph.edges.isEmpty)
        #expect(graph.edges.count == 0)
        #expect(!graph.contains(0))
        #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 0)))
    }

    @Test("C-03 isolated vertices only")
    func isolatedVertices() {
        let graph = AdjacencyList(vertices: 0 ..< 10)
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount == 0)
        #expect(Set(graph.vertices) == Set(0 ..< 10))
        #expect(graph.edges.isEmpty)
        for v in 0 ..< 10 {
            #expect(graph.contains(v))
            #expect(graph.successors(of: v).isEmpty)
            #expect(graph.predecessors(of: v).isEmpty)
            #expect(graph.degree(of: v) == 0)
        }
    }

    @Test("C-03 repeated vertices in the input collapse")
    func repeatedVertices() {
        let graph = AdjacencyList(vertices: [3, 1, 3, 2, 1, 3])
        #expect(graph.vertexCount == 3)
        #expect(graph.vertices.count == 3)
        #expect(Set(graph.vertices) == [1, 2, 3])
    }

    // MARK: From edges

    @Test("C-04 / C-05 every fixture, from vertices and edges", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func fromVerticesAndEdges(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)

        #expect(graph.vertexCount == fixture.vertexCount)
        #expect(graph.edgeCount == fixture.edgeCount)
        #expect(graph.vertices.count == fixture.vertexCount)
        #expect(graph.edges.count == fixture.edgeCount)
        #expect(Set(graph.vertices) == fixture.vertexSet)
        #expect(Set(graph.edges) == fixture.edgeSet)
        for v in fixture.vertexSet {
            let expectedOut = Set(fixture.edgeSet.filter { $0.source == v }.map(\.target))
            let expectedIn = Set(fixture.edgeSet.filter { $0.target == v }.map(\.source))
            #expect(Set(graph.successors(of: v)) == expectedOut, "successors(of: \(v))")
            #expect(Set(graph.predecessors(of: v)) == expectedIn, "predecessors(of: \(v))")
            #expect(graph.successors(of: v).count == fixture.outDegree[v], "successors(of: \(v)) has no repeats")
            #expect(graph.predecessors(of: v).count == fixture.inDegree[v], "predecessors(of: \(v)) has no repeats")
            #expect(graph.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(graph.inDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
        }
        for edge in fixture.edgeSet {
            #expect(graph.contains(edge: edge))
        }
    }

    @Test("C-12 init(edges:) creates exactly the endpoints as vertices", .tags(.fixture), arguments: DirectedFixture<Int>.nonempty)
    func fromEdgesOnly(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(edges: fixture.edges)
        let endpoints = Set(fixture.edges.flatMap { [$0.source, $0.target] })
        #expect(Set(graph.vertices) == endpoints)
        #expect(graph.vertexCount == endpoints.count)
        #expect(Set(graph.edges) == fixture.edgeSet)
        #expect(graph.edgeCount == fixture.edgeCount)
    }

    @Test("C-06 duplicate edges collapse and a self-loop is kept")
    func duplicateEdgesCollapse() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        #expect(graph.edgeCount == 2)
        #expect(Set(graph.edges) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.successors(of: 2)) == [2])
        #expect(Set(graph.predecessors(of: 2)) == [1, 2])
    }

    @Test("E-03 antiparallel edges are distinct")
    func antiparallelEdgesAreDistinct() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.edgeCount == 2)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 0)))
    }

    @Test("C-12 a vertex given explicitly and as an endpoint is one vertex")
    func vertexGivenTwice() {
        let graph = AdjacencyList(vertices: [1, 4], edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 4)])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 2)
        #expect(graph.degree(of: 1) == 1)
        #expect(graph.degree(of: 4) == 1)
    }

    // MARK: From an adjacency mapping

    @Test("C-09 a mapping lists out-neighbors, so a symmetric mapping gives two edges")
    func symmetricMapping() {
        let graph = AdjacencyList(adjacency: [1: [2], 2: [1]])
        #expect(graph.edgeCount == 2)
        #expect(Set(graph.edges) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
    }

    @Test("C-11 mapping with a self-loop, a reciprocal edge, and an isolated vertex")
    func networkXFunctionGraphFromMapping() {
        // NetworkX test_function.py: {0: [1, 2, 3], 1: [1, 2, 0], 4: []} as a DiGraph.
        let graph = AdjacencyList(adjacency: [0: [1, 2, 3], 1: [1, 2, 0], 4: []])
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 6)
        #expect(Set(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(Set(graph.edges) == [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 0),
        ])
        #expect([0, 1, 2, 3, 4].map(graph.outDegree(of:)) == [3, 3, 0, 0, 0])
        #expect([0, 1, 2, 3, 4].map(graph.inDegree(of:)) == [1, 2, 2, 1, 0])
    }

    @Test("mapping: a neighbor that is not a key becomes a vertex, and repeated neighbors collapse")
    func mappingNormalization() {
        let graph = AdjacencyList(adjacency: [0: [7, 7, 7]])
        #expect(Set(graph.vertices) == [0, 7])
        #expect(graph.edgeCount == 1)
        #expect(graph.outDegree(of: 0) == 1)
        #expect(graph.outDegree(of: 7) == 0)
        #expect(graph.inDegree(of: 7) == 1)
    }

    @Test("mapping values may be any sequence")
    func mappingWithSets() {
        let graph = AdjacencyList(adjacency: [0: Set([1, 2]), 1: Set<Int>()])
        #expect(Set(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        #expect(graph.vertexCount == 3)
    }

    @Test("a dictionary literal is the adjacency mapping")
    func dictionaryLiteral() {
        let graph: AdjacencyList<Int> = [0: [1, 2, 3], 1: [1, 2, 0], 4: []]
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 6)
        #expect(graph == AdjacencyList(adjacency: [0: [1, 2, 3], 1: [1, 2, 0], 4: []]))
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 1)))
        #expect(graph.degree(of: 4) == 0)

        let empty: AdjacencyList<Int> = [:]
        #expect(empty.vertexCount == 0)
        #expect(empty.edgeCount == 0)
    }

    @Test("a key that appears earlier as a neighbor is not a repeated key")
    func literalKeyAfterNeighbor() {
        let graph: AdjacencyList<Int> = [0: [1], 1: [2]]
        #expect(Set(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
    }

    // MARK: Independence from input order

    @Test("C-15 every order of the same edges gives an equal graph with an equal hash", .tags(.exhaustive))
    func everyEdgeOrder() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1)]
        let reference = AdjacencyList(edges: edges)

        // Every permutation of the 6 edges, by Heap's algorithm.
        var permutation = edges
        var counters = Array(repeating: 0, count: edges.count)
        var seen = 1
        var i = 1
        var graph = AdjacencyList(edges: permutation)
        #expect(graph == reference)
        while i < permutation.count {
            if counters[i] < i {
                permutation.swapAt(i.isMultiple(of: 2) ? 0 : counters[i], i)
                graph = AdjacencyList(edges: permutation)
                #expect(graph == reference, "\(permutation)")
                #expect(graph.hashValue == reference.hashValue, "\(permutation)")
                seen += 1
                counters[i] += 1
                i = 1
            } else {
                counters[i] = 0
                i += 1
            }
        }
        #expect(seen == 720)
    }

    @Test("C-15 shuffled input gives an equal graph", .tags(.randomized, .fixture), arguments: 0 ..< 20 as Range<UInt>)
    func shuffledInput(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        for fixture in DirectedFixture<Int>.all {
            let reference = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            let shuffled = AdjacencyList(vertices: fixture.vertices.shuffled(using: &rng), edges: fixture.edges.shuffled(using: &rng))
            #expect(shuffled == reference, "\(fixture.name)")
            #expect(shuffled.hashValue == reference.hashValue, "\(fixture.name)")
        }
    }

    @Test("construction agrees with incremental insertion", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func constructionMatchesInsertion(_ fixture: DirectedFixture<Int>) {
        var incremental = AdjacencyList<Int>()
        for v in fixture.vertices { incremental.insert(v) }
        for edge in fixture.edges { incremental.insert(edge: edge) }
        #expect(incremental == AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        #expect(incremental.vertexCount == fixture.vertexCount)
        #expect(incremental.edgeCount == fixture.edgeCount)
    }

    // MARK: Single-pass input and capacity hints

    @Test("S-04 init(edges:) consumes a single-pass sequence once", arguments: UnderestimatedCount.all)
    func singlePassEdges(_ hint: UnderestimatedCount) {
        let fixture = DirectedFixture<Int>.petersen
        let graph = AdjacencyList(edges: MinimalSequence(elements: fixture.edges, underestimatedCount: hint))
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount == 30)
        #expect(Set(graph.edges) == fixture.edgeSet)
    }

    @Test("S-04 init(vertices:edges:) consumes single-pass sequences once", arguments: UnderestimatedCount.all)
    func singlePassVerticesAndEdges(_ hint: UnderestimatedCount) {
        let vertices = MinimalSequence(elements: [4, 5], underestimatedCount: hint)
        let edges = MinimalSequence(elements: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)], underestimatedCount: hint)
        let graph = AdjacencyList(vertices: vertices, edges: edges)
        #expect(Set(graph.vertices) == [0, 1, 4, 5])
        #expect(Set(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
    }

    @Test("S-04 init(vertices:) consumes a single-pass sequence once", arguments: UnderestimatedCount.all)
    func singlePassVertices(_ hint: UnderestimatedCount) {
        let graph = AdjacencyList(vertices: MinimalSequence(elements: 0 ..< 10, underestimatedCount: hint))
        #expect(graph.vertexCount == 10)
        #expect(Set(graph.vertices) == Set(0 ..< 10))
    }
}
