// Strong components: exact orders on the fixtures (ascending on the matrix and CSR, written order
// on the Multigraph), partitions on adjacency lists, graphs ported from other libraries' suites,
// the documented order guarantees, and the strong and weak connectivity tests. Expected values
// come from the catalog's independent reference (checked against NetworkX). Case IDs (CN-nn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

/// Supplies only what DirectedGraph requires: no vertex indices, so algorithms use dictionaries.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Strong components on the fixtures", .tags(.fixture))
struct StrongComponentFixtureTests {
    @Test("CN-01 the empty graph has no strong components")
    func empty() {
        let matrix = AdjacencyMatrix(vertexCount: 0)
        let sparse = CompressedSparseRow(vertexCount: 0)
        #expect(matrix.stronglyConnectedComponents().isEmpty)
        #expect(matrix.stronglyConnectedComponents().count == 0)
        #expect(sparse.stronglyConnectedComponents().isEmpty)
        #expect(sparse.stronglyConnectedComponents().count == 0)
        #expect(AdjacencyList<Int>().stronglyConnectedComponents().isEmpty)
        #expect(Multigraph<Int>(edges: []).stronglyConnectedComponents().isEmpty)
    }

    @Test("CN-02 one vertex, with and without a self-loop, is one component")
    func singleton() {
        for fixture in [DirectedFixture<Int>.trivial, .singleSelfLoop] {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(matrix.stronglyConnectedComponents().map(Array.init) == [[0]], "\(fixture.name)")
            #expect(sparse.stronglyConnectedComponents().map(Array.init) == [[0]], "\(fixture.name)")
            #expect(matrix.stronglyConnectedComponents().component(of: 0) == 0)
        }
    }

    @Test("CN-03 without edges every vertex is its own component, in vertex order")
    func isolated() {
        let fixture = DirectedFixture<Int>.isolatedVertices
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == (0 ..< 10).map { [$0] })
            #expect(g.vertices.map { scc.component(of: $0) } == Array(0 ..< 10))
        }
        check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
    }

    @Test("CN-04 a path completes its sink first")
    func paths() {
        func check<G: DirectedGraph<Int>>(_ g: G, _ expected: [[Int]], labels: [Int]) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == expected)
            #expect(g.vertices.map { scc.component(of: $0) } == labels)
        }
        let path3 = DirectedFixture<Int>.directedPath3
        check(AdjacencyMatrix(vertexCount: 3, edges: path3.edges), [[2], [1], [0]], labels: [2, 1, 0])
        check(CompressedSparseRow(vertexCount: 3, edges: path3.edges), [[2], [1], [0]], labels: [2, 1, 0])
        let path10 = DirectedFixture<Int>.directedPath10
        let expected = (0 ..< 10).reversed().map { [$0] }
        check(AdjacencyMatrix(vertexCount: 10, edges: path10.edges), expected, labels: Array((0 ..< 10).reversed()))
        check(CompressedSparseRow(vertexCount: 10, edges: path10.edges), expected, labels: Array((0 ..< 10).reversed()))
    }

    @Test("CN-05 strongly connected fixtures are one component of every vertex in ascending order")
    func oneComponent() {
        for fixture in [DirectedFixture<Int>.completeDirected3, .completeDirected10, .directedCycle10, .petersen, .cube, .boostWebGraph] {
            let all = Array(0 ..< fixture.vertexCount)
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(matrix.stronglyConnectedComponents().map(Array.init) == [all], "\(fixture.name)")
            #expect(sparse.stronglyConnectedComponents().map(Array.init) == [all], "\(fixture.name)")
            #expect(all.allSatisfy { sparse.stronglyConnectedComponents().component(of: $0) == 0 })
        }
    }

    @Test("CN-06 a self-loop and a 2-cycle in one graph")
    func functionGraph() {
        let fixture = DirectedFixture<Int>.networkXFunctionGraph
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == [[2], [3], [0, 1], [4]])
            #expect(g.vertices.map { scc.component(of: $0) } == [2, 2, 0, 1, 3])
        }
        check(AdjacencyMatrix(vertexCount: 5, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: 5, edges: fixture.edges))
    }

    @Test("CN-07 completion order is not ascending: in the house, 4 completes before 3")
    func house() {
        let fixture = DirectedFixture<Int>.house
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == [[0], [1], [2], [4], [3], [5]])
            #expect(g.vertices.map { scc.component(of: $0) } == [0, 1, 2, 4, 3, 5])
        }
        check(AdjacencyMatrix(vertexCount: 6, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: 6, edges: fixture.edges))
    }

    @Test("CN-08 petgraph's SCC fixture, order significant")
    func scc9() {
        let fixture = DirectedFixture<Int>.scc9
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == [[0, 3, 6], [2, 5, 8], [1, 4, 7]])
            #expect(g.vertices.map { scc.component(of: $0) } == [0, 2, 1, 0, 2, 1, 0, 2, 1])
        }
        check(AdjacencyMatrix(vertexCount: 9, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: 9, edges: fixture.edges))
    }

    @Test("CN-09 members are in vertices order, not Tarjan stack order")
    func membersInVertexOrder() {
        // Stack orders: scc9 [5, 8, 2] and [1, 7, 4]; petersen [0, 1, 2, 3, 4, 9, 6, 8, 5, 7];
        // boostWebGraph [0, 1, 3, 4, 5, 2].
        let scc9 = DirectedFixture<Int>.scc9
        let petersen = DirectedFixture<Int>.petersen
        let web = DirectedFixture<Int>.boostWebGraph
        let matrix = AdjacencyMatrix(vertexCount: 9, edges: scc9.edges).stronglyConnectedComponents()
        let sparse = CompressedSparseRow(vertexCount: 9, edges: scc9.edges).stronglyConnectedComponents()
        #expect(Array(matrix[1]) == [2, 5, 8])
        #expect(Array(matrix[2]) == [1, 4, 7])
        #expect(Array(sparse[1]) == [2, 5, 8])
        #expect(Array(sparse[2]) == [1, 4, 7])
        #expect(AdjacencyMatrix(vertexCount: 10, edges: petersen.edges).stronglyConnectedComponents().map(Array.init) == [Array(0 ..< 10)])
        #expect(CompressedSparseRow(vertexCount: 10, edges: petersen.edges).stronglyConnectedComponents().map(Array.init) == [Array(0 ..< 10)])
        #expect(AdjacencyMatrix(vertexCount: 6, edges: web.edges).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5]])
        #expect(CompressedSparseRow(vertexCount: 6, edges: web.edges).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5]])
    }

    @Test("CN-10 a giant component between a source and a sink")
    func boost24() {
        let fixture = DirectedFixture<Int>.boost24
        let giant = Array(1 ... 6) + Array(8 ... 23)
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == [[0], giant, [7]])
            #expect(g.vertices.map { scc.component(of: $0) } == (0 ..< 24).map { $0 == 0 ? 0 : $0 == 7 ? 2 : 1 })
        }
        check(AdjacencyMatrix(vertexCount: 24, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: 24, edges: fixture.edges))
    }

    @Test("CN-11 an isolated vertex with a self-loop")
    func isolatedSelfLoop() {
        let fixture = DirectedFixture<Int>.petgraphEdgesDirected
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == [[3], [1], [5], [0, 2, 4], [6]])
            #expect(g.vertices.map { scc.component(of: $0) } == [3, 1, 3, 0, 3, 2, 4])
        }
        check(AdjacencyMatrix(vertexCount: 7, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: 7, edges: fixture.edges))
    }

    @Test("CN-12 three small cases from DG-A09")
    func smallCases() {
        func check<G: DirectedGraph<Int>>(_ g: G, _ expected: [[Int]], labels: [Int]? = nil) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == expected)
            if let labels { #expect(g.vertices.map { scc.component(of: $0) } == labels) }
        }
        let igraph = DirectedFixture<Int>.igraphReverseEdges
        check(AdjacencyMatrix(vertexCount: 5, edges: igraph.edges), [[4], [1, 2, 3], [0]])
        check(CompressedSparseRow(vertexCount: 5, edges: igraph.edges), [[4], [1, 2, 3], [0]])
        let csv = DirectedFixture<Int>.jgraphtMatrixCSV
        check(AdjacencyMatrix(vertexCount: 5, edges: csv.edges), [[1], [0, 2, 3, 4]])
        check(CompressedSparseRow(vertexCount: 5, edges: csv.edges), [[1], [0, 2, 3, 4]])
        let boost = DirectedFixture<Int>.boostExample
        check(AdjacencyMatrix(vertexCount: 6, edges: boost.edges), [[0], [2], [5], [1], [3, 4]], labels: [0, 3, 1, 4, 4, 2])
        check(CompressedSparseRow(vertexCount: 6, edges: boost.edges), [[0], [2], [5], [1], [3, 4]], labels: [0, 3, 1, 4, 4, 2])
    }

    @Test("CN-13 DAGs with several roots")
    func severalRoots() {
        func check<G: DirectedGraph<Int>>(_ g: G, _ expected: [[Int]], labels: [Int]? = nil) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == expected)
            if let labels { #expect(g.vertices.map { scc.component(of: $0) } == labels) }
        }
        let unsorted = DirectedFixture<Int>.boostCsrUnsorted
        check(AdjacencyMatrix(vertexCount: 6, edges: unsorted.edges), [[2], [0], [1], [3], [4], [5]], labels: [1, 2, 0, 3, 4, 5])
        check(CompressedSparseRow(vertexCount: 6, edges: unsorted.edges), [[2], [0], [1], [3], [4], [5]], labels: [1, 2, 0, 3, 4, 5])
        let neo4j = DirectedFixture<Int>.neo4jDirected
        check(AdjacencyMatrix(vertexCount: 5, edges: neo4j.edges), [[4], [2], [3], [1], [0]])
        check(CompressedSparseRow(vertexCount: 5, edges: neo4j.edges), [[4], [2], [3], [1], [0]])
        let scipy = DirectedFixture<Int>.scipyConstructor2
        check(AdjacencyMatrix(vertexCount: 6, edges: scipy.edges), [[0], [1], [2], [4], [3], [5]])
        check(CompressedSparseRow(vertexCount: 6, edges: scipy.edges), [[0], [1], [2], [4], [3], [5]])
    }

    @Test("CN-14 self-loops in every row")
    func selfLoopRows() {
        let csr1 = DirectedFixture<Int>.petgraphCsr1
        #expect(AdjacencyMatrix(vertexCount: 3, edges: csr1.edges).stronglyConnectedComponents().map(Array.init) == [[2], [0], [1]])
        #expect(CompressedSparseRow(vertexCount: 3, edges: csr1.edges).stronglyConnectedComponents().map(Array.init) == [[2], [0], [1]])
        let from = DirectedFixture<Int>.petgraphCsrFrom
        #expect(AdjacencyMatrix(vertexCount: 5, edges: from.edges).stronglyConnectedComponents().map(Array.init) == [[4], [2], [0, 1], [3]])
        #expect(CompressedSparseRow(vertexCount: 5, edges: from.edges).stronglyConnectedComponents().map(Array.init) == [[4], [2], [0, 1], [3]])
    }

    @Test("CN-15 two weak pieces with cycles")
    func twoWeakPieces() {
        func check<G: DirectedGraph<Int>>(_ g: G, _ expected: [[Int]], labels: [Int]? = nil) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.map(Array.init) == expected)
            if let labels { #expect(g.vertices.map { scc.component(of: $0) } == labels) }
        }
        let bellmanFord = DirectedFixture<Int>.petgraphBellmanFord
        let expected = [[3], [2], [0, 1], [8], [7], [5], [4], [6]]
        check(AdjacencyMatrix(vertexCount: 9, edges: bellmanFord.edges), expected, labels: [2, 2, 1, 0, 6, 5, 7, 4, 3])
        check(CompressedSparseRow(vertexCount: 9, edges: bellmanFord.edges), expected, labels: [2, 2, 1, 0, 6, 5, 7, 4, 3])
        let sparseFixture = DirectedFixture<Int>.jgraphtSparseDirected
        check(AdjacencyMatrix(vertexCount: 8, edges: sparseFixture.edges), [[6], [5], [4], [0, 1], [2], [3], [7]])
        check(CompressedSparseRow(vertexCount: 8, edges: sparseFixture.edges), [[6], [5], [4], [0, 1], [2], [3], [7]])
    }

    @Test("CN-16 a chord does not merge anything")
    func chord() {
        let fixture = DirectedFixture<Int>.pathWithChord
        let expected = [[5], [4], [3], [2], [1], [0]]
        #expect(AdjacencyMatrix(vertexCount: 6, edges: fixture.edges).stronglyConnectedComponents().map(Array.init) == expected)
        #expect(CompressedSparseRow(vertexCount: 6, edges: fixture.edges).stronglyConnectedComponents().map(Array.init) == expected)
    }
}

@Suite("Strong components in written order and on adjacency lists")
struct StrongComponentWrittenOrderTests {
    @Test("CN-17 written order changes the order, not the partition")
    func scc9() {
        let fixture = DirectedFixture<Int>.scc9
        let graph = Multigraph(vertices: fixture.vertices, edges: fixture.edges)
        #expect(graph.vertices == [6, 0, 3, 8, 2, 5, 7, 1, 4])
        let scc = graph.stronglyConnectedComponents()
        #expect(scc.map(Array.init) == [[6, 0, 3], [8, 2, 5], [7, 1, 4]])
        #expect(graph.vertices.map { scc.component(of: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2])
    }

    @Test("CN-18 listed vertices come first")
    func listedFirst() {
        let function = DirectedFixture<Int>.networkXFunctionGraph
        let functionGraph = Multigraph(vertices: function.vertices, edges: function.edges)
        #expect(functionGraph.vertices == [4, 0, 1, 2, 3])
        #expect(functionGraph.stronglyConnectedComponents().map(Array.init) == [[4], [2], [3], [0, 1]])
        let from = DirectedFixture<Int>.petgraphCsrFrom
        let fromGraph = Multigraph(vertices: from.vertices, edges: from.edges)
        #expect(fromGraph.vertices == [3, 0, 1, 2, 4])
        #expect(fromGraph.stronglyConnectedComponents().map(Array.init) == [[3], [4], [2], [0, 1]])
        let scipy = DirectedFixture<Int>.scipyConstructor2
        let scipyGraph = Multigraph(vertices: scipy.vertices, edges: scipy.edges)
        #expect(scipyGraph.vertices == [0, 1, 2, 5, 3, 4])
        #expect(scipyGraph.stronglyConnectedComponents().map(Array.init) == [[0], [1], [2], [5], [4], [3]])
    }

    @Test("CN-19 written order of successors moves components")
    func successorOrder() {
        let house = DirectedFixture<Int>.house
        let houseGraph = Multigraph(vertices: house.vertices, edges: house.edges)
        #expect(houseGraph.vertices == [5, 3, 4, 2, 0, 1])
        #expect(houseGraph.stronglyConnectedComponents().map(Array.init) == [[0], [1], [4], [2], [3], [5]])
        let directed = DirectedFixture<Int>.petgraphEdgesDirected
        let directedGraph = Multigraph(vertices: directed.vertices, edges: directed.edges)
        #expect(directedGraph.vertices == [0, 5, 2, 3, 1, 4, 6])
        #expect(directedGraph.stronglyConnectedComponents().map(Array.init) == [[5], [3], [1], [0, 2, 4], [6]])
        let unsorted = DirectedFixture<Int>.boostCsrUnsorted
        let unsortedGraph = Multigraph(vertices: unsorted.vertices, edges: unsorted.edges)
        #expect(unsortedGraph.vertices == [5, 0, 3, 2, 4, 1])
        #expect(unsortedGraph.stronglyConnectedComponents().map(Array.init) == [[2], [0], [5], [3], [1], [4]])
    }

    @Test("CN-20 String vertices")
    func strings() {
        let abcd = DirectedFixture<String>.networkXABCD
        let abcdGraph = Multigraph(vertices: abcd.vertices, edges: abcd.edges)
        #expect(abcdGraph.vertices == ["G", "J", "K", "A", "B", "C", "D"])
        #expect(abcdGraph.stronglyConnectedComponents().map(Array.init) == [["G"], ["J"], ["K"], ["D"], ["C"], ["B"], ["A"]])
        let dag = DirectedFixture<String>.petgraphDAG
        let dagGraph = Multigraph(vertices: dag.vertices, edges: dag.edges)
        #expect(dagGraph.vertices == ["a", "b", "d", "c", "e", "f", "g"])
        #expect(dagGraph.stronglyConnectedComponents().map(Array.init) == [["g"], ["e"], ["c"], ["b"], ["f"], ["d"], ["a"]])
    }

    @Test("CN-21 fixtures whose vertices are not 0..<n")
    func notZeroBased() {
        let loops = DirectedFixture<Int>.selfLoopsAndDuplicates
        #expect(Multigraph(vertices: loops.vertices, edges: loops.edges).stronglyConnectedComponents().map(Array.init) == [[3], [4], [2], [1], [5]])
        let cycle = DirectedFixture<Int>.directedCycle4
        #expect(Multigraph(vertices: cycle.vertices, edges: cycle.edges).stronglyConnectedComponents().map(Array.init) == [[1, 2, 3, 4]])
        let triangle = DirectedFixture<Int>.triangleWithReciprocalEdge
        #expect(Multigraph(vertices: triangle.vertices, edges: triangle.edges).stronglyConnectedComponents().map(Array.init) == [[1, 2, 3]])
    }

    @Test("CN-22 adjacency lists: the same partition as the Multigraph, and the reverse topological law", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func adjacencyList(_ fixture: DirectedFixture<Int>) {
        let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let multigraph = Multigraph(vertices: fixture.vertices, edges: fixture.edges)
        let scc = list.stronglyConnectedComponents()
        #expect(Set(scc.map(Set.init)) == Set(multigraph.stronglyConnectedComponents().map(Set.init)))
        for edge in fixture.edges {
            #expect(scc.component(of: edge.source) >= scc.component(of: edge.target), "\(edge)")
        }
    }

    @Test("CN-22 adjacency lists with String vertices")
    func adjacencyListStrings() {
        for fixture in DirectedFixture<String>.all {
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            let multigraph = Multigraph(vertices: fixture.vertices, edges: fixture.edges)
            let scc = list.stronglyConnectedComponents()
            #expect(Set(scc.map(Set.init)) == Set(multigraph.stronglyConnectedComponents().map(Set.init)), "\(fixture.name)")
            for edge in fixture.edges {
                #expect(scc.component(of: edge.source) >= scc.component(of: edge.target), "\(edge)")
            }
        }
    }
}

@Suite("Strong components of graphs from other suites")
struct StrongComponentPortedTests {
    @Test("CN-23 NetworkX gc[0]")
    func networkXGC0() {
        let pairs = [(1, 2), (2, 3), (2, 8), (3, 4), (3, 7), (4, 5), (5, 3), (5, 6), (7, 4), (7, 6), (8, 1), (8, 7)]
        let graph = Multigraph(vertices: 1 ... 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }.sorted())
        #expect(graph.stronglyConnectedComponents().map(Array.init) == [[6], [3, 4, 5, 7], [1, 2, 8]])
    }

    @Test("CN-24 NetworkX gc[1] and gc[2]")
    func networkXGC1() {
        let first = [(1, 2), (1, 3), (1, 4), (4, 2), (3, 4), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(Multigraph(vertices: 1 ... 4, edges: first.sorted()).stronglyConnectedComponents().map(Array.init) == [[2, 3, 4], [1]])
        let second = [(1, 2), (2, 3), (3, 2), (2, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(Multigraph(vertices: 1 ... 3, edges: second.sorted()).stronglyConnectedComponents().map(Array.init) == [[1, 2, 3]])
    }

    @Test("CN-25 Eppstein's tests")
    func eppstein() {
        let first = [(0, 1), (1, 2), (1, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 7, edges: first).stronglyConnectedComponents().map(Array.init) == [[6], [4], [5], [2], [3], [1], [0]])
        #expect(CompressedSparseRow(vertexCount: 7, edges: first).stronglyConnectedComponents().map(Array.init) == [[6], [4], [5], [2], [3], [1], [0]])
        let second = [(0, 1), (1, 2), (1, 3), (1, 4), (2, 0), (2, 3), (3, 4), (4, 3)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 5, edges: second).stronglyConnectedComponents().map(Array.init) == [[3, 4], [0, 1, 2]])
        #expect(CompressedSparseRow(vertexCount: 5, edges: second).stronglyConnectedComponents().map(Array.init) == [[3, 4], [0, 1, 2]])
    }

    @Test("CN-26 NetworkX's early-exit graph is one component")
    func earlyExit() {
        let edges = [(0, 1), (1, 2), (1, 5), (2, 3), (3, 1), (3, 4), (4, 0), (5, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 6, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5]])
        #expect(CompressedSparseRow(vertexCount: 6, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5]])
    }

    @Test("CN-27 NetworkX docstrings")
    func networkXDocstrings() {
        let counted = [(0, 1), (1, 2), (2, 0), (2, 3), (4, 5), (3, 4), (5, 6), (6, 3), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let countedComponents = CompressedSparseRow(vertexCount: 8, edges: counted).stronglyConnectedComponents()
        #expect(countedComponents.map(Array.init) == [[7], [3, 4, 5, 6], [0, 1, 2]])
        #expect(countedComponents.count == 3)
        #expect(AdjacencyMatrix(vertexCount: 8, edges: counted).stronglyConnectedComponents().map(Array.init) == [[7], [3, 4, 5, 6], [0, 1, 2]])
        let connected = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(CompressedSparseRow(vertexCount: 5, edges: connected).isStronglyConnected)
        #expect(AdjacencyMatrix(vertexCount: 5, edges: connected).isStronglyConnected)
        let broken = connected.filter { $0 != DirectedEdge(from: 2, to: 3) }
        #expect(!CompressedSparseRow(vertexCount: 5, edges: broken).isStronglyConnected)
        #expect(CompressedSparseRow(vertexCount: 5, edges: broken).stronglyConnectedComponents().map(Array.init) == [[2, 4], [1], [0], [3]])
        #expect(AdjacencyMatrix(vertexCount: 5, edges: broken).stronglyConnectedComponents().map(Array.init) == [[2, 4], [1], [0], [3]])
        let twoCycles = [(0, 1), (1, 2), (2, 3), (3, 0), (10, 11), (11, 12), (12, 10)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let twoCycleGraph = Multigraph(vertices: [0, 1, 2, 3, 10, 11, 12], edges: twoCycles.sorted())
        #expect(twoCycleGraph.stronglyConnectedComponents().map(Array.init) == [[0, 1, 2, 3], [10, 11, 12]])
    }

    @Test("CN-28 two disjoint paths: ten singletons")
    func disjointPaths() {
        let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (5, 6), (6, 7), (7, 8), (8, 9)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [[4], [3], [2], [1], [0], [9], [8], [7], [6], [5]]
        #expect(AdjacencyMatrix(vertexCount: 10, edges: edges).stronglyConnectedComponents().map(Array.init) == expected)
        #expect(CompressedSparseRow(vertexCount: 10, edges: edges).stronglyConnectedComponents().map(Array.init) == expected)
    }

    @Test("CN-29 petgraph's acyclic non-tree graph (#14)")
    func acyclicNonTree() {
        let edges = [(3, 2), (3, 1), (2, 0), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 4, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
        #expect(CompressedSparseRow(vertexCount: 4, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
    }

    @Test("CN-30 petgraph's Kosaraju bug from PR #60: self-loops on a source and a sink, and an isolated vertex")
    func kosarajuBug() {
        let edges = [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 4, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
        #expect(CompressedSparseRow(vertexCount: 4, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0], [1], [2], [3]])
    }

    @Test("CN-31 petgraph's condensation documentation graph")
    func condensationDocumentation() {
        // a…h = 0…7
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 5), (5, 6), (6, 7), (7, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 8, edges: edges).stronglyConnectedComponents().map(Array.init) == [[4, 5, 6, 7], [0, 1, 2, 3]])
        #expect(CompressedSparseRow(vertexCount: 8, edges: edges).stronglyConnectedComponents().map(Array.init) == [[4, 5, 6, 7], [0, 1, 2, 3]])
    }

    @Test("CN-32 Boost's test: a↔b, b↔c")
    func boostTest() {
        let edges = [(0, 1), (1, 0), (1, 2), (2, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let scc = CompressedSparseRow(vertexCount: 3, edges: edges).stronglyConnectedComponents()
        #expect(scc.map(Array.init) == [[0, 1, 2]])
        #expect((0 ..< 3).map { scc.component(of: $0) } == [0, 0, 0])
        #expect(AdjacencyMatrix(vertexCount: 3, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2]])
    }

    @Test("CN-33 LEMON's test digraph; a self-loop and a repeated edge change nothing")
    func lemon() {
        let edges = [(1, 3), (3, 2), (2, 1), (4, 2), (4, 3), (5, 6), (6, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }.sorted()
        let graph = Multigraph(vertices: 1 ... 6, edges: edges)
        let scc = graph.stronglyConnectedComponents()
        #expect(scc.map(Array.init) == [[1, 2, 3], [4], [5, 6]])
        #expect(scc.count == 3)
        #expect(!graph.isStronglyConnected)
        let extra = Multigraph(vertices: 1 ... 6, edges: edges + [DirectedEdge(from: 3, to: 3), DirectedEdge(from: 3, to: 2)])
        #expect(extra.stronglyConnectedComponents().map(Array.init) == [[1, 2, 3], [4], [5, 6]])
    }

    @Test("CN-34 gonum's Tarjan tests")
    func gonum() {
        let first = [(0, 1), (1, 2), (1, 7), (2, 3), (2, 6), (3, 4), (4, 2), (4, 5), (6, 3), (6, 5), (7, 0), (7, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 8, edges: first).stronglyConnectedComponents().map(Array.init) == [[5], [2, 3, 4, 6], [0, 1, 7]])
        #expect(CompressedSparseRow(vertexCount: 8, edges: first).stronglyConnectedComponents().map(Array.init) == [[5], [2, 3, 4, 6], [0, 1, 7]])
        let second = [(0, 1), (0, 2), (0, 3), (1, 2), (2, 3), (3, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 4, edges: second).stronglyConnectedComponents().map(Array.init) == [[1, 2, 3], [0]])
        #expect(CompressedSparseRow(vertexCount: 4, edges: second).stronglyConnectedComponents().map(Array.init) == [[1, 2, 3], [0]])
    }

    @Test("CN-35 JGraphT tests 1–4 and 7")
    func jgraphtSmall() {
        func graph(_ pairs: [(Int, Int)], _ vertices: ClosedRange<Int>) -> Multigraph<Int> {
            Multigraph(vertices: vertices, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }.sorted())
        }
        #expect(graph([(1, 2), (2, 1), (3, 4)], 1 ... 4).stronglyConnectedComponents().map(Array.init) == [[1, 2], [4], [3]])
        #expect(graph([(1, 2), (2, 1), (4, 3), (3, 2)], 1 ... 4).stronglyConnectedComponents().map(Array.init) == [[1, 2], [3], [4]])
        #expect(graph([(1, 2), (2, 3), (3, 1), (1, 4), (2, 4), (3, 4)], 1 ... 4).stronglyConnectedComponents().map(Array.init) == [[4], [1, 2, 3]])
        let ring = [(0, 1), (1, 2), (2, 0)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 3, edges: ring).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2]])
        #expect(CompressedSparseRow(vertexCount: 3, edges: ring).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2]])
        #expect(graph([(1, 2), (2, 3), (3, 4), (3, 5), (4, 1), (5, 3)], 1 ... 5).stronglyConnectedComponents().map(Array.init) == [[1, 2, 3, 4, 5]])
    }

    @Test("CN-36 Gabow's example, the Wikipedia graph and JGraphT's test 8")
    func jgraphtLarger() {
        func graph(_ pairs: [(Int, Int)], _ vertices: ClosedRange<Int>) -> Multigraph<Int> {
            Multigraph(vertices: vertices, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }.sorted())
        }
        let gabow = graph([(1, 2), (1, 3), (2, 3), (2, 4), (4, 3), (4, 5), (5, 2), (5, 6), (6, 3), (6, 4)], 1 ... 6)
        #expect(gabow.stronglyConnectedComponents().map(Array.init) == [[3], [2, 4, 5, 6], [1]])
        let wikipedia = graph([(1, 5), (2, 1), (3, 2), (3, 4), (4, 3), (5, 2), (6, 2), (6, 5), (6, 7), (7, 3), (7, 6), (8, 4), (8, 7)], 1 ... 8)
        #expect(wikipedia.stronglyConnectedComponents().map(Array.init) == [[1, 2, 5], [3, 4], [6, 7], [8]])
        let eight = graph([(1, 2), (1, 4), (2, 3), (2, 5), (3, 1), (3, 7), (4, 3), (5, 6), (5, 7), (6, 7), (6, 8), (6, 9), (6, 10), (7, 5), (8, 10), (9, 10), (10, 9)], 1 ... 11)
        #expect(eight.stronglyConnectedComponents().map(Array.init) == [[9, 10], [8], [5, 6, 7], [1, 2, 3, 4], [11]])
    }

    @Test("CN-37 Kosaraju's order differs from Tarjan's; only the reverse topological law is shared")
    func kosarajuOrderDiffers() {
        let edges = [(0, 1), (1, 2), (2, 0), (3, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = CompressedSparseRow(vertexCount: 5, edges: edges)
        let scc = graph.stronglyConnectedComponents()
        #expect(scc.map(Array.init) == [[0, 1, 2], [4], [3]])
        // rustworkx (petgraph's Kosaraju) documents [[4], [3], [0, 1, 2]]: also reverse topological.
        #expect(scc.map(Array.init) != [[4], [3], [0, 1, 2]])
        for edge in edges { #expect(scc.component(of: edge.source) >= scc.component(of: edge.target)) }
        #expect(AdjacencyMatrix(vertexCount: 5, edges: edges).stronglyConnectedComponents().map(Array.init) == [[0, 1, 2], [4], [3]])
    }

    @Test("CN-38 petgraph's Tarjan documentation example")
    func tarjanDocumentation() {
        // A…E = 0…4
        let edges = [(0, 1), (1, 2), (2, 0), (1, 3), (3, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 5, edges: edges).stronglyConnectedComponents().map(Array.init) == [[4], [3], [0, 1, 2]])
        #expect(CompressedSparseRow(vertexCount: 5, edges: edges).stronglyConnectedComponents().map(Array.init) == [[4], [3], [0, 1, 2]])
    }
}

@Suite("Strong component order guarantees")
struct StrongComponentOrderTests {
    @Test("CN-39 labels agree with membership, and component(ofIndex:) with component(of:)", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func labels(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            for v in g.vertices {
                #expect(scc[scc.component(of: v)].contains(v), "\(v)")
                #expect(scc.component(ofIndex: g.vertexIndex(of: v)) == scc.component(of: v), "\(v)")
            }
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(Multigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }

    @Test("CN-40 every edge between components goes from a later component to an earlier one", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func reverseTopological(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            for edge in fixture.edges {
                #expect(scc.component(of: edge.source) >= scc.component(of: edge.target), "\(edge)")
            }
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(Multigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }

    @Test("CN-40 the reverse topological law on String fixtures")
    func reverseTopologicalStrings() {
        for fixture in DirectedFixture<String>.all {
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).stronglyConnectedComponents()
            let multigraph = Multigraph(vertices: fixture.vertices, edges: fixture.edges).stronglyConnectedComponents()
            for edge in fixture.edges {
                #expect(list.component(of: edge.source) >= list.component(of: edge.target), "\(edge)")
                #expect(multigraph.component(of: edge.source) >= multigraph.component(of: edge.target), "\(edge)")
            }
        }
    }

    @Test("CN-41 the matrix and CSR give identical results on every zero-based fixture", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func matrixEqualsCSR(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).stronglyConnectedComponents()
        let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).stronglyConnectedComponents()
        #expect(Array(matrix.map(Array.init)) == Array(sparse.map(Array.init)))
        #expect((0 ..< fixture.vertexCount).map { matrix.component(of: $0) } == (0 ..< fixture.vertexCount).map { sparse.component(of: $0) })
    }

    @Test("CN-42 a conformer without vertex indices follows vertices order")
    func withoutIndices() {
        let graph = DictionaryGraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a")])
        #expect(graph.vertexIndexBound == nil)
        let scc = graph.stronglyConnectedComponents()
        #expect(scc.map(Array.init) == [["a", "b"], ["c"]])
        #expect(["c", "a", "b"].map { scc.component(of: $0) } == [1, 0, 0])
        #expect(graph.weaklyConnectedComponents().map(Array.init) == [["c", "a", "b"]])
    }

    @Test("CN-43 spread-out Int vertices")
    func spreadOut() {
        let edges = [(30, 10), (10, 20), (20, 10), (20, 40)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = Multigraph(vertices: [30, 10, 20, 40], edges: edges)
        let scc = graph.stronglyConnectedComponents()
        #expect(scc.map(Array.init) == [[40], [10, 20], [30]])
        #expect(graph.vertices.map { scc.component(of: $0) } == [2, 1, 1, 0])
    }

    @Test("CN-44 component slices keep their positions in flat storage")
    func sliceIndices() {
        let scc = AdjacencyMatrix(vertexCount: 9, edges: DirectedFixture<Int>.scc9.edges).stronglyConnectedComponents()
        #expect(scc.startIndex == 0)
        #expect(scc.endIndex == 3)
        #expect(scc[0].startIndex == 0)
        #expect(scc[1].startIndex == 3)
        #expect(scc[2].startIndex == 6)
        #expect(Array(scc[1]) == [2, 5, 8])
        #expect(scc[1].first == 2)
        #expect(scc[1][3] == 2)
    }

    @Test("CN-45 the partition is invariant under relabeling (JGraphT rotates every vertex)")
    func rotations() {
        let wikipedia = [(1, 5), (2, 1), (3, 2), (3, 4), (4, 3), (5, 2), (6, 2), (6, 5), (6, 7), (7, 3), (7, 6), (8, 4), (8, 7)]
        let unrotated: Set<Set<Int>> = [[1, 2, 5], [3, 4], [6, 7], [8]]
        let exact = [
            [[1, 2, 5], [3, 4], [6, 7], [8]],
            [[2, 3, 6], [4, 5], [7, 8], [1]],
            [[3, 4, 7], [5, 6], [1, 8], [2]],
            [[4, 5, 8], [6, 7], [1, 2], [3]],
            [[1, 5, 6], [7, 8], [2, 3], [4]],
            [[2, 6, 7], [1, 8], [3, 4], [5]],
            [[3, 7, 8], [1, 2], [4, 5], [6]],
            [[1, 4, 8], [2, 3], [5, 6], [7]],
        ]
        for k in 0 ..< 8 {
            let rotate = { (v: Int) in ((v - 1 + k) % 8) + 1 }
            let edges = wikipedia.map { DirectedEdge(from: rotate($0.0), to: rotate($0.1)) }.sorted()
            let scc = Multigraph(vertices: 1 ... 8, edges: edges).stronglyConnectedComponents()
            #expect(Set(scc.map(Set.init)) == Set(unrotated.map { Set($0.map(rotate)) }), "k = \(k)")
            #expect(scc.map(Array.init) == exact[k], "k = \(k)")
        }
    }
}

@Suite("Strong and weak connectivity")
struct ConnectivityTestTests {
    @Test("CN-46 isStronglyConnected on every fixture", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func stronglyConnected(_ fixture: DirectedFixture<Int>) {
        let strong: Set<String> = [
            DirectedFixture<Int>.trivial.name, DirectedFixture<Int>.singleSelfLoop.name, DirectedFixture<Int>.completeDirected3.name,
            DirectedFixture<Int>.completeDirected10.name, DirectedFixture<Int>.directedCycle4.name, DirectedFixture<Int>.triangleWithReciprocalEdge.name,
            DirectedFixture<Int>.petersen.name, DirectedFixture<Int>.cube.name, DirectedFixture<Int>.directedCycle10.name, DirectedFixture<Int>.boostWebGraph.name,
        ]
        let expected = strong.contains(fixture.name)
        #expect(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).isStronglyConnected == expected)
        #expect(Multigraph(vertices: fixture.vertices, edges: fixture.edges).isStronglyConnected == expected)
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            #expect(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).isStronglyConnected == expected)
            #expect(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).isStronglyConnected == expected)
        }
    }

    @Test("CN-46 a path reaches everything from its start but is not strongly connected; String fixtures are not either")
    func pathIsNotStronglyConnected() {
        #expect(!CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges).isStronglyConnected)
        for fixture in DirectedFixture<String>.all {
            #expect(!Multigraph(vertices: fixture.vertices, edges: fixture.edges).isStronglyConnected)
        }
    }

    @Test("CN-47 the empty graph is neither strongly nor weakly connected")
    func emptyGraph() {
        let matrix = AdjacencyMatrix(vertexCount: 0)
        let sparse = CompressedSparseRow(vertexCount: 0)
        let list = AdjacencyList<Int>()
        #expect(!matrix.isStronglyConnected)
        #expect(!matrix.isWeaklyConnected)
        #expect(!sparse.isStronglyConnected)
        #expect(!sparse.isWeaklyConnected)
        #expect(!list.isStronglyConnected)
        #expect(!list.isWeaklyConnected)
        #expect(sparse.stronglyConnectedComponents().count == 0)
        #expect(sparse.weaklyConnectedComponents().count == 0)
    }

    @Test("CN-48 isStronglyConnected is count == 1 and isWeaklyConnected is weak count == 1", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func connectedIsOneComponent(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            #expect(g.isStronglyConnected == (g.stronglyConnectedComponents().count == 1))
            #expect(g.isWeaklyConnected == (g.weaklyConnectedComponents().count == 1))
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(Multigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }

    @Test("CN-49 isWeaklyConnected on every fixture", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func weaklyConnected(_ fixture: DirectedFixture<Int>) {
        let notWeak: Set<String> = [
            DirectedFixture<Int>.isolatedVertices.name, DirectedFixture<Int>.networkXFunctionGraph.name, DirectedFixture<Int>.boostExample.name,
            DirectedFixture<Int>.petgraphEdgesDirected.name, DirectedFixture<Int>.petgraphCsrFrom.name, DirectedFixture<Int>.petgraphBellmanFord.name,
            DirectedFixture<Int>.scipyConstructor2.name, DirectedFixture<Int>.empty.name,
        ]
        let expected = !notWeak.contains(fixture.name)
        #expect(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).isWeaklyConnected == expected)
        #expect(Multigraph(vertices: fixture.vertices, edges: fixture.edges).isWeaklyConnected == expected)
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            #expect(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).isWeaklyConnected == expected)
            #expect(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).isWeaklyConnected == expected)
        }
    }

    @Test("CN-49 isWeaklyConnected on String fixtures")
    func weaklyConnectedStrings() {
        let abcd = DirectedFixture<String>.networkXABCD
        let dag = DirectedFixture<String>.petgraphDAG
        #expect(!Multigraph(vertices: abcd.vertices, edges: abcd.edges).isWeaklyConnected)
        #expect(!AdjacencyList(vertices: abcd.vertices, edges: abcd.edges).isWeaklyConnected)
        #expect(Multigraph(vertices: dag.vertices, edges: dag.edges).isWeaklyConnected)
        #expect(AdjacencyList(vertices: dag.vertices, edges: dag.edges).isWeaklyConnected)
    }

    @Test("CN-50 component counts from other suites and the real-world fixtures")
    func counts() {
        let docstring = [(0, 1), (1, 2), (2, 0), (2, 3), (4, 5), (3, 4), (5, 6), (6, 3), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(CompressedSparseRow(vertexCount: 8, edges: docstring).stronglyConnectedComponents().count == 3)
        let lemon = Multigraph(vertices: 1 ... 6, edges: [(1, 3), (3, 2), (2, 1), (4, 2), (4, 3), (5, 6), (6, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(lemon.stronglyConnectedComponents().count == 3)
        #expect(lemon.weaklyConnectedComponents().count == 2)
        let eightPairs = [(1, 2), (1, 4), (2, 3), (2, 5), (3, 1), (3, 7), (4, 3), (5, 6), (5, 7), (6, 7), (6, 8), (6, 9), (6, 10), (7, 5), (8, 10), (9, 10), (10, 9)]
        let eight = Multigraph(vertices: 1 ... 11, edges: eightPairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(eight.stronglyConnectedComponents().count == 5)
        #expect(eight.weaklyConnectedComponents().count == 2)
        let cases: [(DirectedFixture<Int>, Int, Int)] = [(.gap4, 14, 2), (.graph500Scale8, 256, 16), (.ligraRMat, 4, 4)]
        for (fixture, strong, weak) in cases {
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(sparse.stronglyConnectedComponents().count == strong, "\(fixture.name)")
            #expect(sparse.weaklyConnectedComponents().count == weak, "\(fixture.name)")
        }
    }
}
