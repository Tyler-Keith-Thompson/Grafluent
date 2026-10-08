// Weak components: ordered by their first vertex in `vertices` order, members in `vertices` order,
// with edge directions ignored. Exact on the matrix and CSR (ascending) and the ReferenceDirectedMultigraph
// (written order). Expected values come from the catalog's reference, which matches NetworkX's
// order of first vertices. Case IDs (CN-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Weak components")
struct WeakComponentTests {
    @Test("CN-51 ordered by first vertex, members in vertices order", .tags(.fixture))
    func ascending() {
        let cases: [(DirectedFixture<Int>, [[Int]])] = [
            (.networkXFunctionGraph, [[0, 1, 2, 3], [4]]),
            (.boostExample, [[0, 1, 2, 5], [3, 4]]),
            (.petgraphEdgesDirected, [[0, 1, 2, 3, 4, 5], [6]]),
            (.petgraphCsrFrom, [[0, 1, 2, 4], [3]]),
            (.petgraphBellmanFord, [[0, 1, 2, 3], [4, 5, 6, 7, 8]]),
            (.scipyConstructor2, [[0], [1], [2], [3, 4], [5]]),
            (.isolatedVertices, (0 ..< 10).map { [$0] }),
            (.house, [[0, 1, 2, 3, 4, 5]]),
            (.scc9, [Array(0 ..< 9)]),
            (.boost24, [Array(0 ..< 24)]),
        ]
        for (fixture, expected) in cases {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).weaklyConnectedComponents()
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).weaklyConnectedComponents()
            #expect(matrix.map(Array.init) == expected, "\(fixture.name)")
            #expect(sparse.map(Array.init) == expected, "\(fixture.name)")
            for (position, component) in expected.enumerated() {
                for v in component {
                    #expect(matrix.component(of: v) == position, "\(fixture.name): \(v)")
                    #expect(sparse.component(of: v) == position, "\(fixture.name): \(v)")
                }
            }
        }
    }

    @Test("CN-52 the same in written vertex order on the ReferenceDirectedMultigraph", .tags(.fixture))
    func written() {
        let cases: [(DirectedFixture<Int>, [[Int]])] = [
            (.networkXFunctionGraph, [[4], [0, 1, 2, 3]]),
            (.scipyConstructor2, [[0], [1], [2], [5], [3, 4]]),
            (.house, [[5, 3, 4, 2, 0, 1]]),
            (.petgraphBellmanFord, [[0, 1, 2, 3], [4, 5, 7, 6, 8]]),
        ]
        for (fixture, expected) in cases {
            let graph = ReferenceDirectedMultigraph(vertices: fixture.vertices, edges: fixture.edges)
            #expect(graph.weaklyConnectedComponents().map(Array.init) == expected, "\(fixture.name)")
        }
        let abcd = DirectedFixture<String>.networkXABCD
        #expect(ReferenceDirectedMultigraph(vertices: abcd.vertices, edges: abcd.edges).weaklyConnectedComponents().map(Array.init) == [["G"], ["J"], ["K"], ["A", "B", "C", "D"]])
    }

    @Test("CN-53 direction is ignored")
    func directionIgnored() {
        // Vertex 0 of the house has no successors.
        let house = DirectedFixture<Int>.house
        #expect(AdjacencyMatrix(vertexCount: 6, edges: house.edges).weaklyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5]])
        #expect(CompressedSparseRow(vertexCount: 6, edges: house.edges).weaklyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 5]])
        let reversed = [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0)]
        #expect(AdjacencyMatrix(vertexCount: 3, edges: reversed).weaklyConnectedComponents().map(Array.init) == [[0, 1, 2]])
        #expect(CompressedSparseRow(vertexCount: 3, edges: reversed).weaklyConnectedComponents().map(Array.init) == [[0, 1, 2]])
    }

    @Test("CN-54 petgraph's connected_comp")
    func petgraphConnectedComponents() {
        let edges = DirectedFixture<Int>.scc9.edges
        #expect(CompressedSparseRow(vertexCount: 9, edges: edges).weaklyConnectedComponents().count == 1)
        #expect(AdjacencyMatrix(vertexCount: 9, edges: edges).weaklyConnectedComponents().count == 1)
        let isolated = CompressedSparseRow(vertexCount: 11, edges: edges).weaklyConnectedComponents()
        #expect(isolated.map(Array.init) == [Array(0 ..< 9), [9], [10]])
        #expect(AdjacencyMatrix(vertexCount: 11, edges: edges).weaklyConnectedComponents().map(Array.init) == [Array(0 ..< 9), [9], [10]])
        let joined = edges + [DirectedEdge(from: 9, to: 10)]
        #expect(CompressedSparseRow(vertexCount: 11, edges: joined).weaklyConnectedComponents().map(Array.init) == [Array(0 ..< 9), [9, 10]])
        #expect(AdjacencyMatrix(vertexCount: 11, edges: joined).weaklyConnectedComponents().map(Array.init) == [Array(0 ..< 9), [9, 10]])
    }

    @Test("CN-55 weak components from other suites")
    func otherSuites() {
        let one = ReferenceDirectedMultigraph(vertices: 1 ... 4, edges: [(1, 2), (2, 1), (3, 4)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(one.weaklyConnectedComponents().map(Array.init) == [[1, 2], [3, 4]])
        let eightPairs = [(1, 2), (1, 4), (2, 3), (2, 5), (3, 1), (3, 7), (4, 3), (5, 6), (5, 7), (6, 7), (6, 8), (6, 9), (6, 10), (7, 5), (8, 10), (9, 10), (10, 9)]
        let eight = ReferenceDirectedMultigraph(vertices: 1 ... 11, edges: eightPairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(eight.weaklyConnectedComponents().map(Array.init) == [Array(1 ... 10), [11]])
        let rustworkx = [(0, 1), (1, 2), (2, 0), (3, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 5, edges: rustworkx).weaklyConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4]])
        #expect(CompressedSparseRow(vertexCount: 5, edges: rustworkx).weaklyConnectedComponents().map(Array.init) == [[0, 1, 2], [3, 4]])
        let lemon = ReferenceDirectedMultigraph(vertices: 1 ... 6, edges: [(1, 3), (3, 2), (2, 1), (4, 2), (4, 3), (5, 6), (6, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(lemon.weaklyConnectedComponents().map(Array.init) == [[1, 2, 3, 4], [5, 6]])
        // NetworkX test_weakly_connected uses test_strongly_connected's five graphs: each is weakly connected.
        let networkX: [([(Int, Int)], ClosedRange<Int>)] = [
            ([(1, 2), (2, 3), (2, 8), (3, 4), (3, 7), (4, 5), (5, 3), (5, 6), (7, 4), (7, 6), (8, 1), (8, 7)], 1 ... 8),
            ([(1, 2), (1, 3), (1, 4), (4, 2), (3, 4), (2, 3)], 1 ... 4),
            ([(1, 2), (2, 3), (3, 2), (2, 1)], 1 ... 3),
            ([(0, 1), (1, 2), (1, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 6)], 0 ... 6),
            ([(0, 1), (1, 2), (1, 3), (1, 4), (2, 0), (2, 3), (3, 4), (4, 3)], 0 ... 4),
        ]
        for (pairs, vertices) in networkX {
            let graph = ReferenceDirectedMultigraph(vertices: vertices, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.isWeaklyConnected)
            #expect(graph.weaklyConnectedComponents().map(Array.init) == [Array(vertices)])
        }
    }

    @Test("CN-56 weak components need no predecessors: CSR works")
    func compressedSparseRow() {
        let sparse = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges)
        #expect(sparse.weaklyConnectedComponents().count == 1)
        #expect(sparse.isWeaklyConnected)
    }

    @Test("CN-57 every strong component lies inside one weak component", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func strongRefinesWeak(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let strong = g.stronglyConnectedComponents()
            let weak = g.weaklyConnectedComponents()
            for component in strong {
                #expect(Set(component.map { weak.component(of: $0) }).count == 1)
            }
            // Weak labels agree with membership, and an edge never crosses weak components.
            for v in g.vertices { #expect(weak[weak.component(of: v)].contains(v)) }
            for edge in fixture.edges { #expect(weak.component(of: edge.source) == weak.component(of: edge.target)) }
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(ReferenceDirectedMultigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }
}
