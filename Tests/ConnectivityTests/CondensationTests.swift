// Condensation (the components plus a CompressedSparseRow on 0..<k whose vertex i is
// components[i]) and attracting components (the strong components no edge leaves). Rows are
// written out with `successors(of:)`. Expected values come from the catalog's reference, checked
// against NetworkX's `condensation` and `attracting_components`. Case IDs (CN-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Condensation")
struct CondensationTests {
    @Test("CN-58 petgraph's scc9")
    func scc9() {
        let fixture = DirectedFixture<Int>.scc9
        for condensation in [AdjacencyMatrix(vertexCount: 9, edges: fixture.edges).condensation().graph, CompressedSparseRow(vertexCount: 9, edges: fixture.edges).condensation().graph] {
            #expect((0 ..< condensation.vertexCount).map { Array(condensation.successors(of: $0)) } == [[], [0], [1]])
            #expect(condensation.edgeCount == 2)
        }
        let matrix = AdjacencyMatrix(vertexCount: 9, edges: fixture.edges).condensation()
        #expect(matrix.components.map(Array.init) == [[0, 3, 6], [2, 5, 8], [1, 4, 7]])
        let sparse = CompressedSparseRow(vertexCount: 9, edges: fixture.edges).condensation()
        #expect(sparse.components.map(Array.init) == [[0, 3, 6], [2, 5, 8], [1, 4, 7]])
    }

    @Test("CN-59 petgraph's condensation test (scc9 plus 2→3) is acyclic")
    func petgraphCondensation() {
        let edges = DirectedFixture<Int>.scc9.edges + [DirectedEdge(from: 2, to: 3)]
        let condensation = CompressedSparseRow(vertexCount: 9, edges: edges).condensation()
        #expect(condensation.graph.vertexCount == 3)
        #expect(condensation.graph.edgeCount == 2)
        #expect((0 ..< 3).map { Array(condensation.graph.successors(of: $0)) } == [[], [0], [1]])
        #expect(condensation.graph.isAcyclic)
        #expect(AdjacencyMatrix(vertexCount: 9, edges: edges).condensation().graph == condensation.graph)
    }

    @Test("CN-60 a DAG condenses to itself, renumbered")
    func house() {
        let fixture = DirectedFixture<Int>.house
        for condensation in [AdjacencyMatrix(vertexCount: 6, edges: fixture.edges).condensation().graph, CompressedSparseRow(vertexCount: 6, edges: fixture.edges).condensation().graph] {
            // Component 3 is vertex 4.
            #expect((0 ..< 6).map { Array(condensation.successors(of: $0)) } == [[], [0], [1], [0, 1], [2, 3], [4]])
            #expect(condensation.edgeCount == 7)
        }
    }

    @Test("CN-61 NetworkX test_contract_scc1")
    func contractSCC1() {
        let pairs = [(1, 2), (2, 3), (2, 11), (2, 12), (3, 4), (4, 3), (4, 5), (5, 6), (6, 5), (6, 7), (7, 8), (7, 9), (7, 10), (8, 9), (9, 7), (10, 6), (11, 2), (11, 4), (11, 6), (12, 6), (12, 11)]
        let graph = ReferenceDirectedMultigraph(vertices: 1 ... 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }.sorted())
        let condensation = graph.condensation()
        #expect(condensation.components.map(Array.init) == [[5, 6, 7, 8, 9, 10], [3, 4], [2, 11, 12], [1]])
        #expect((0 ..< 4).map { Array(condensation.graph.successors(of: $0)) } == [[], [0], [0, 1], [2]])
        let c = condensation.components
        #expect(condensation.graph.contains(edge: DirectedEdge(from: c.component(of: 2), to: c.component(of: 3))))
        #expect(condensation.graph.contains(edge: DirectedEdge(from: c.component(of: 2), to: c.component(of: 5))))
        #expect(condensation.graph.contains(edge: DirectedEdge(from: c.component(of: 3), to: c.component(of: 5))))
        #expect(c.component(of: 2) == 2)
        #expect(c.component(of: 3) == 1)
        #expect(c.component(of: 5) == 0)
    }

    @Test("CN-62 NetworkX's isolate and edge cases")
    func networkXSmall() {
        let isolate = ReferenceDirectedMultigraph(vertices: 1 ... 2, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)]).condensation()
        #expect(isolate.graph.vertexCount == 1)
        #expect(isolate.graph.edgeCount == 0)
        let pairs = [(1, 2), (2, 1), (2, 3), (3, 4), (4, 3)]
        let edge = ReferenceDirectedMultigraph(vertices: 1 ... 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).condensation()
        #expect(edge.components.map(Array.init) == [[3, 4], [1, 2]])
        #expect(Array(edge.graph.edges) == [DirectedEdge(from: 1, to: 0)])
    }

    @Test("CN-63 JGraphT's condensations")
    func jgrapht() {
        let first = ReferenceDirectedMultigraph(vertices: 1 ... 5, edges: [(1, 2), (2, 1), (3, 4), (5, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }).condensation()
        #expect(first.components.map(Array.init) == [[1, 2], [4], [3], [5]])
        #expect((0 ..< 4).map { Array(first.graph.successors(of: $0)) } == [[], [], [1], [1]])
        // 1→3 and 2→4 collapse into one edge.
        let second = ReferenceDirectedMultigraph(vertices: 1 ... 4, edges: [(1, 2), (2, 1), (3, 4), (4, 3), (1, 3), (2, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }.sorted()).condensation()
        #expect(second.components.map(Array.init) == [[3, 4], [1, 2]])
        #expect(Array(second.graph.edges) == [DirectedEdge(from: 1, to: 0)])
    }

    @Test("CN-64 petgraph's documentation graph has one condensation edge (no make_acyclic: false mode)")
    func petgraphDocumentation() {
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 5), (5, 6), (6, 7), (7, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let condensation = CompressedSparseRow(vertexCount: 8, edges: edges).condensation()
        #expect(condensation.graph.vertexCount == 2)
        #expect(Array(condensation.graph.edges) == [DirectedEdge(from: 1, to: 0)])
        #expect(AdjacencyMatrix(vertexCount: 8, edges: edges).condensation().graph == condensation.graph)
    }

    @Test("CN-65 repeated and internal edges collapse", .tags(.selfLoops))
    func collapse() {
        let complete = DirectedFixture<Int>.completeDirected3
        let completeCondensation = CompressedSparseRow(vertexCount: 3, edges: complete.edges).condensation()
        #expect(completeCondensation.graph.vertexCount == 1)
        #expect(completeCondensation.graph.edgeCount == 0)
        // 2→4 is written three times (13 edges); without deduplication there would be 10.
        let sparseFixture = DirectedFixture<Int>.jgraphtSparseDirected
        let multigraph = ReferenceDirectedMultigraph(vertices: sparseFixture.vertices, edges: sparseFixture.edges).condensation()
        #expect((0 ..< 7).map { Array(multigraph.graph.successors(of: $0)) } == [[], [0], [1], [0, 1, 2], [2], [2], [0]])
        #expect(multigraph.graph.edgeCount == 8)
        let csr1 = DirectedFixture<Int>.petgraphCsr1
        for condensation in [AdjacencyMatrix(vertexCount: 3, edges: csr1.edges).condensation().graph, CompressedSparseRow(vertexCount: 3, edges: csr1.edges).condensation().graph] {
            #expect((0 ..< 3).map { Array(condensation.successors(of: $0)) } == [[], [0], [0, 1]])
        }
    }

    @Test("CN-66 the empty graph condenses to the empty graph")
    func empty() {
        let condensation = CompressedSparseRow(vertexCount: 0).condensation()
        #expect(condensation.components.isEmpty)
        #expect(condensation.graph.vertexCount == 0)
        #expect(AdjacencyMatrix(vertexCount: 0).condensation().graph.vertexCount == 0)
        #expect(AdjacencyList<Int>().condensation().components.isEmpty)
    }

    @Test("CN-67 condensation laws", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func laws(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let condensation = g.condensation()
            let components = condensation.components
            let graph = condensation.graph
            #expect(components == g.stronglyConnectedComponents())
            #expect(graph.vertexCount == components.count)
            for i in 0 ..< graph.vertexCount {
                let row = Array(graph.successors(of: i))
                #expect(zip(row, row.dropFirst()).allSatisfy { $0 < $1 }, "row \(i) ascending without repeats")
                for j in row { #expect(i > j, "\(i)→\(j)") }
            }
            #expect(graph.isAcyclic)
            #expect(graph.topologicalSort() != nil)
            var expected = Set<DirectedEdge<Int>>()
            for edge in fixture.edges {
                let (i, j) = (components.component(of: edge.source), components.component(of: edge.target))
                if i != j { expected.insert(DirectedEdge(from: i, to: j)) }
            }
            #expect(Set(graph.edges) == expected)
            #expect(graph.edgeCount == expected.count)
            #expect(graph.stronglyConnectedComponents().allSatisfy { $0.count == 1 })
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(ReferenceDirectedMultigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }
}

@Suite("Attracting components")
struct AttractingComponentTests {
    @Test("CN-68 NetworkX G1")
    func networkXG1() {
        let pairs = [(5, 11), (11, 2), (11, 9), (11, 10), (7, 11), (7, 8), (8, 9), (3, 8), (3, 10)]
        let graph = ReferenceDirectedMultigraph(vertices: [2, 3, 5, 7, 8, 9, 10, 11], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }.sorted())
        #expect(graph.attractingComponents() == [[2], [9], [10]])
        #expect(graph.attractingComponents().count == 3)
    }

    @Test("CN-69 NetworkX G2, G3 and G4")
    func networkXG2G3G4() {
        let g2 = [(0, 1), (0, 2), (1, 1), (1, 2), (2, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 3, edges: g2).attractingComponents() == [[1, 2]])
        #expect(CompressedSparseRow(vertexCount: 3, edges: g2).attractingComponents() == [[1, 2]])
        let g3 = [(0, 1), (1, 2), (2, 1), (0, 3), (3, 4), (4, 3)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 5, edges: g3).attractingComponents() == [[1, 2], [3, 4]])
        #expect(CompressedSparseRow(vertexCount: 5, edges: g3).attractingComponents() == [[1, 2], [3, 4]])
        #expect(CompressedSparseRow(vertexCount: 0).attractingComponents() == [])
        #expect(AdjacencyMatrix(vertexCount: 0).attractingComponents() == [])
    }

    @Test("CN-70 a self-loop is not a way out", .tags(.selfLoops))
    func selfLoops() {
        let cases: [(DirectedFixture<Int>, [[Int]])] = [
            (.singleSelfLoop, [[0]]),
            (.petgraphCsr1, [[2]]),
            // 6 has only a self-loop.
            (.petgraphEdgesDirected, [[3], [5], [6]]),
        ]
        for (fixture, expected) in cases {
            #expect(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).attractingComponents().map(Array.init) == expected, "\(fixture.name)")
            #expect(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).attractingComponents().map(Array.init) == expected, "\(fixture.name)")
        }
    }

    @Test("CN-71 attracting components of the fixtures", .tags(.fixture))
    func fixtures() {
        let cases: [(DirectedFixture<Int>, [[Int]])] = [
            (.networkXFunctionGraph, [[2], [3], [4]]),
            (.boostExample, [[0], [3, 4]]),
            (.boostCsrUnsorted, [[2], [1]]),
            (.scipyConstructor2, [[0], [1], [2], [4], [5]]),
            (.scc9, [[0, 3, 6]]),
            (.trivial, [[0]]),
            (.singleSelfLoop, [[0]]),
            (.completeDirected3, [[0, 1, 2]]),
            (.completeDirected10, [Array(0 ..< 10)]),
            (.petersen, [Array(0 ..< 10)]),
            (.cube, [Array(0 ..< 8)]),
            (.directedCycle10, [Array(0 ..< 10)]),
            (.boostWebGraph, [Array(0 ..< 6)]),
        ]
        for (fixture, expected) in cases {
            #expect(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).attractingComponents().map(Array.init) == expected, "\(fixture.name)")
            #expect(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).attractingComponents().map(Array.init) == expected, "\(fixture.name)")
        }
        let cycle = DirectedFixture<Int>.directedCycle4
        #expect(ReferenceDirectedMultigraph(vertices: cycle.vertices, edges: cycle.edges).attractingComponents() == [[1, 2, 3, 4]])
        let triangle = DirectedFixture<Int>.triangleWithReciprocalEdge
        #expect(ReferenceDirectedMultigraph(vertices: triangle.vertices, edges: triangle.edges).attractingComponents() == [[1, 2, 3]])
    }

    @Test("CN-72 attracting components are the components whose condensation row is empty, in that order", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func law(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let condensation = g.condensation()
            let expected = condensation.components.indices.filter { condensation.graph.outDegree(of: $0) == 0 }.map { Array(condensation.components[$0]) }
            #expect(g.attractingComponents().map(Array.init) == expected)
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(ReferenceDirectedMultigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }
}
