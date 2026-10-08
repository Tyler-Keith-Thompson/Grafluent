// Exact event transcripts. AdjacencyMatrix and CompressedSparseRow list successors in ascending
// order, so a search over either gives one fixed transcript; the ReferenceDirectedMultigraph test conformer gives
// written order. Expected transcripts were computed independently and checked against NetworkX.
// Case IDs (TR-nn) refer to the catalog; see README.md.
//
// GENERATED from the catalog by a script, then checked in: each test is self-contained.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Breadth-first search transcripts")
struct BreadthFirstSearchTranscriptTests {
    @Test("TR-01 a single vertex is discovered and finished")
    func tr01() {
        let edges = DirectedFixture<Int>.trivial.edges
        let expected = "discover(0) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: 1, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 1, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-02 a path: a vertex finishes after its last out-edge")
    func tr02() {
        let edges = DirectedFixture<Int>.directedPath3.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) finish(0) treeEdge(1→2) discover(2) finish(1) finish(2)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.directedPath3.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.directedPath3.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-03 a complete digraph: every edge out of a reached vertex is reported once")
    func tr03() {
        let edges = DirectedFixture<Int>.completeDirected3.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(0→2) discover(2) finish(0) nonTreeEdge(1→0) nonTreeEdge(1→2) finish(1) nonTreeEdge(2→0) nonTreeEdge(2→1) finish(2)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.completeDirected3.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.completeDirected3.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-04 a self-loop is a non-tree edge")
    func tr04() {
        let edges = DirectedFixture<Int>.singleSelfLoop.edges
        let expected = "discover(0) nonTreeEdge(0→0) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.singleSelfLoop.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.singleSelfLoop.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-05 a self-loop among other out-edges")
    func tr05() {
        let edges = DirectedFixture<Int>.networkXFunctionGraph.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(0→2) discover(2) treeEdge(0→3) discover(3) finish(0) nonTreeEdge(1→0) nonTreeEdge(1→1) nonTreeEdge(1→2) finish(1) finish(2) finish(3)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.networkXFunctionGraph.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.networkXFunctionGraph.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-06 a DAG from its source")
    func tr06() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(5) treeEdge(5→3) discover(3) finish(5) treeEdge(3→2) discover(2) treeEdge(3→4) discover(4) finish(3) treeEdge(2→1) discover(1) finish(2) treeEdge(4→0) discover(0) nonTreeEdge(4→1) finish(4) nonTreeEdge(1→0) finish(1) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 5).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 5).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-07 a cyclic graph")
    func tr07() {
        let edges = DirectedFixture<Int>.scc9.edges
        let expected = "discover(1) treeEdge(1→7) discover(7) finish(1) treeEdge(7→4) discover(4) treeEdge(7→5) discover(5) finish(7) nonTreeEdge(4→1) finish(4) treeEdge(5→8) discover(8) finish(5) treeEdge(8→2) discover(2) treeEdge(8→6) discover(6) finish(8) nonTreeEdge(2→5) finish(2) treeEdge(6→0) discover(0) finish(6) treeEdge(0→3) discover(3) finish(0) nonTreeEdge(3→6) finish(3)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.scc9.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.scc9.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-08 unreached vertices produce no events")
    func tr08() {
        let edges = DirectedFixture<Int>.petgraphEdgesDirected.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(0→2) discover(2) treeEdge(0→3) discover(3) treeEdge(0→5) discover(5) finish(0) nonTreeEdge(1→3) finish(1) nonTreeEdge(2→3) treeEdge(2→4) discover(4) finish(2) finish(3) finish(5) nonTreeEdge(4→0) finish(4)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.petgraphEdgesDirected.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.petgraphEdgesDirected.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-09 NetworkX's TestBFS graph")
    func tr09() {
        // NetworkX test_bfs.py, undirected, written as both directions.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 2), DirectedEdge(from: 4, to: 3)]
        let expected = "discover(0) treeEdge(0→1) discover(1) finish(0) nonTreeEdge(1→0) treeEdge(1→2) discover(2) treeEdge(1→3) discover(3) finish(1) nonTreeEdge(2→1) treeEdge(2→4) discover(4) finish(2) nonTreeEdge(3→1) nonTreeEdge(3→4) finish(3) nonTreeEdge(4→2) nonTreeEdge(4→3) finish(4)"
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 5, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-10 a directed 5-cycle with a loop")
    func tr10() {
        // NetworkX test_bfs.py: tree ×4, (4, 0) reverse, (4, 4) level.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 4)]
        let expected = "discover(0) treeEdge(0→1) discover(1) finish(0) treeEdge(1→2) discover(2) finish(1) treeEdge(2→3) discover(3) finish(2) treeEdge(3→4) discover(4) finish(3) nonTreeEdge(4→0) nonTreeEdge(4→4) finish(4)"
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 5, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-11 a 5-cycle with chords")
    func tr11() {
        // NetworkX test_bfs.py: 1→2 level, 2→5 forward, 4→0 reverse.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 5), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 5), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0)]
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(0→2) discover(2) finish(0) nonTreeEdge(1→2) treeEdge(1→5) discover(5) finish(1) treeEdge(2→3) discover(3) nonTreeEdge(2→5) finish(2) finish(5) treeEdge(3→4) discover(4) finish(3) nonTreeEdge(4→0) finish(4)"
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 6, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-12 every source is discovered before any edge")
    func tr12() {
        // NetworkX bfs_labeled_edges doctest: K3 from [0, 1].
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1)]
        let expected = "discover(0) discover(1) nonTreeEdge(0→1) treeEdge(0→2) discover(2) finish(0) nonTreeEdge(1→0) nonTreeEdge(1→2) finish(1) nonTreeEdge(2→0) nonTreeEdge(2→1) finish(2)"
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 3, edges: edges)
        #expect(matrix.breadthFirstSearch(from: [0, 1]).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: [0, 1]).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-13 several sources on a DAG")
    func tr13() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(3) discover(4) treeEdge(3→2) discover(2) nonTreeEdge(3→4) finish(3) treeEdge(4→0) discover(0) treeEdge(4→1) discover(1) finish(4) nonTreeEdge(2→1) finish(2) finish(0) nonTreeEdge(1→0) finish(1)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: [3, 4]).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: [3, 4]).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-18 String vertices in written order")
    func tr18() {
        let graph = ReferenceDirectedMultigraph(vertices: DirectedFixture<String>.petgraphDAG.vertices, edges: DirectedFixture<String>.petgraphDAG.edges)
        #expect(graph.breadthFirstSearch(from: "a").map(\.description).joined(separator: " ") == "discover(a) treeEdge(a→b) discover(b) treeEdge(a→d) discover(d) finish(a) treeEdge(b→c) discover(c) treeEdge(b→e) discover(e) finish(b) nonTreeEdge(d→b) nonTreeEdge(d→e) treeEdge(d→f) discover(f) finish(d) nonTreeEdge(c→e) finish(c) treeEdge(e→g) discover(g) finish(e) nonTreeEdge(f→e) nonTreeEdge(f→g) finish(f) finish(g)")
    }

    @Test("TR-67 every copy of a self-loop is a non-tree edge in breadth-first search")
    func tr67() {
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(graph.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) nonTreeEdge(0→0) nonTreeEdge(0→0) finish(0)")
    }

    @Test("TR-68 antiparallel and parallel edges, breadth-first")
    func tr68() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) nonTreeEdge(0→1) finish(0) nonTreeEdge(1→0) finish(1)")
    }

    @Test("TR-69 a duplicated chord, breadth-first")
    func tr69() {
        let graph = ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.pathWithChord.edges)
        #expect(graph.breadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) finish(0) treeEdge(1→2) discover(2) treeEdge(1→3) discover(3) nonTreeEdge(1→3) finish(1) nonTreeEdge(2→3) finish(2) treeEdge(3→4) discover(4) finish(3) treeEdge(4→5) discover(5) finish(4) finish(5)")
    }

    @Test("TR-73 depth limit 0 reports only the sources, breadth-first")
    func tr73() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(5) finish(5)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 5, depthLimit: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 5, depthLimit: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-80 a depth-limited breadth-first transcript")
    func tr80() {
        // NetworkX test_bfs.py depth limit.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 5, to: 4), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 6, to: 5), DirectedEdge(from: 7, to: 2), DirectedEdge(from: 7, to: 8), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 9, to: 8), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 10, to: 9)]
        let expected = "discover(1) treeEdge(1→0) discover(0) treeEdge(1→2) discover(2) finish(1) nonTreeEdge(0→1) finish(0) nonTreeEdge(2→1) treeEdge(2→3) discover(3) treeEdge(2→7) discover(7) finish(2) nonTreeEdge(3→2) treeEdge(3→4) discover(4) finish(3) nonTreeEdge(7→2) treeEdge(7→8) discover(8) finish(7) finish(4) finish(8)"
        let matrix = AdjacencyMatrix(vertexCount: 11, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 11, edges: edges)
        #expect(matrix.breadthFirstSearch(from: 1, depthLimit: 3).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.breadthFirstSearch(from: 1, depthLimit: 3).map(\.description).joined(separator: " ") == expected)
    }

}

@Suite("Depth-first search transcripts")
struct DepthFirstSearchTranscriptTests {
    @Test("TR-31 a single vertex")
    func tr31() {
        let edges = DirectedFixture<Int>.trivial.edges
        let expected = "discover(0) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: 1, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 1, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-32 a self-loop is a back edge")
    func tr32() {
        let edges = DirectedFixture<Int>.singleSelfLoop.edges
        let expected = "discover(0) backEdge(0→0) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.singleSelfLoop.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.singleSelfLoop.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-33 a path has only tree edges and finishes in reverse")
    func tr33() {
        let edges = DirectedFixture<Int>.directedPath3.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(1→2) discover(2) finish(2) finish(1) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.directedPath3.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.directedPath3.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-34 a complete digraph has back and forward edges")
    func tr34() {
        let edges = DirectedFixture<Int>.completeDirected3.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) treeEdge(1→2) discover(2) backEdge(2→0) backEdge(2→1) finish(2) finish(1) forwardEdge(0→2) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.completeDirected3.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.completeDirected3.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-35 back edges to the parent and to self")
    func tr35() {
        let edges = DirectedFixture<Int>.networkXFunctionGraph.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) backEdge(1→1) treeEdge(1→2) discover(2) finish(2) finish(1) forwardEdge(0→2) treeEdge(0→3) discover(3) finish(3) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.networkXFunctionGraph.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.networkXFunctionGraph.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-36 a DAG has cross edges and no back edges")
    func tr36() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(5) treeEdge(5→3) discover(3) treeEdge(3→2) discover(2) treeEdge(2→1) discover(1) treeEdge(1→0) discover(0) finish(0) finish(1) finish(2) treeEdge(3→4) discover(4) crossEdge(4→0) crossEdge(4→1) finish(4) finish(3) finish(5)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 5).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 5).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-37 three strongly connected components")
    func tr37() {
        let edges = DirectedFixture<Int>.scc9.edges
        let expected = "discover(1) treeEdge(1→7) discover(7) treeEdge(7→4) discover(4) backEdge(4→1) finish(4) treeEdge(7→5) discover(5) treeEdge(5→8) discover(8) treeEdge(8→2) discover(2) backEdge(2→5) finish(2) treeEdge(8→6) discover(6) treeEdge(6→0) discover(0) treeEdge(0→3) discover(3) backEdge(3→6) finish(3) finish(0) finish(6) finish(8) finish(5) finish(7) finish(1)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.scc9.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.scc9.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-38 all four edge classes in one search")
    func tr38() {
        let edges = DirectedFixture<Int>.petgraphEdgesDirected.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(1→3) discover(3) finish(3) finish(1) treeEdge(0→2) discover(2) crossEdge(2→3) treeEdge(2→4) discover(4) backEdge(4→0) finish(4) finish(2) forwardEdge(0→3) treeEdge(0→5) discover(5) finish(5) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.petgraphEdgesDirected.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.petgraphEdgesDirected.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-39 petgraph's dfs_visit graph")
    func tr39() {
        // petgraph tests/graph.rs dfs_visit.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 5)]
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(1→3) discover(3) finish(3) finish(1) treeEdge(0→2) discover(2) crossEdge(2→3) treeEdge(2→4) discover(4) backEdge(4→0) treeEdge(4→5) discover(5) finish(5) finish(4) finish(2) forwardEdge(0→3) forwardEdge(0→5) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 6, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-40 NetworkX's TestDFS graph")
    func tr40() {
        // NetworkX test_dfs.py; its nontree labels are these back and forward edges.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 2)]
        let expected = "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) treeEdge(1→2) discover(2) backEdge(2→1) treeEdge(2→4) discover(4) backEdge(4→0) backEdge(4→2) finish(4) finish(2) treeEdge(1→3) discover(3) backEdge(3→0) backEdge(3→1) finish(3) finish(1) forwardEdge(0→3) forwardEdge(0→4) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 5, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-41 the whole of a disconnected graph")
    func tr41() {
        // NetworkX test_dfs.py D.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)]
        let expected = "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) finish(1) finish(0) discover(2) treeEdge(2→3) discover(3) backEdge(3→2) finish(3) finish(2)"
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 4, edges: edges)
        #expect(matrix.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-42 a reciprocal edge and a triangle")
    func tr42() {
        let edges = DirectedFixture<Int>.triangleWithReciprocalEdge.edges
        let expected = "discover(1) treeEdge(1→2) discover(2) backEdge(2→1) treeEdge(2→3) discover(3) backEdge(3→1) finish(3) finish(2) finish(1)"
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 4, edges: edges)
        #expect(matrix.depthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-43 a directed cycle has one back edge, closing it")
    func tr43() {
        let edges = DirectedFixture<Int>.directedCycle4.edges
        let expected = "discover(1) treeEdge(1→2) discover(2) treeEdge(2→3) discover(3) treeEdge(3→4) discover(4) backEdge(4→1) finish(4) finish(3) finish(2) finish(1)"
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 5, edges: edges)
        #expect(matrix.depthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 1).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-44 a DAG with forward and cross edges")
    func tr44() {
        let edges = DirectedFixture<Int>.neo4jDirected.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(1→2) discover(2) treeEdge(2→4) discover(4) finish(4) finish(2) treeEdge(1→3) discover(3) crossEdge(3→4) finish(3) finish(1) forwardEdge(0→2) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.neo4jDirected.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.neo4jDirected.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-45 self-loops at a root and at a leaf")
    func tr45() {
        let edges = DirectedFixture<Int>.petgraphCsr1.edges
        let expected = "discover(0) backEdge(0→0) treeEdge(0→2) discover(2) backEdge(2→2) finish(2) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.petgraphCsr1.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.petgraphCsr1.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-46 String vertices in written order")
    func tr46() {
        let graph = ReferenceDirectedMultigraph(vertices: DirectedFixture<String>.petgraphDAG.vertices, edges: DirectedFixture<String>.petgraphDAG.edges)
        #expect(graph.depthFirstSearch(from: "a").map(\.description).joined(separator: " ") == "discover(a) treeEdge(a→b) discover(b) treeEdge(b→c) discover(c) treeEdge(c→e) discover(e) treeEdge(e→g) discover(g) finish(g) finish(e) finish(c) forwardEdge(b→e) finish(b) treeEdge(a→d) discover(d) crossEdge(d→b) crossEdge(d→e) treeEdge(d→f) discover(f) crossEdge(f→e) crossEdge(f→g) finish(f) finish(d) finish(a)")
    }

    @Test("TR-47 neighbor order changes the transcript, not its validity")
    func tr47() {
        // Written order: 3's successors are [4, 2], 4's are [0, 1]; compare TR-36.
        let graph = ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.house.edges)
        #expect(graph.depthFirstSearch(from: 5).map(\.description).joined(separator: " ") == "discover(5) treeEdge(5→3) discover(3) treeEdge(3→4) discover(4) treeEdge(4→0) discover(0) finish(0) treeEdge(4→1) discover(1) crossEdge(1→0) finish(1) finish(4) treeEdge(3→2) discover(2) crossEdge(2→1) finish(2) finish(3) finish(5)")
    }

    @Test("TR-48 NetworkX's ABCD graph in written order")
    func tr48() {
        let graph = ReferenceDirectedMultigraph(edges: DirectedFixture<String>.networkXABCD.edges)
        #expect(graph.depthFirstSearch(from: "A").map(\.description).joined(separator: " ") == "discover(A) treeEdge(A→B) discover(B) treeEdge(B→D) discover(D) finish(D) treeEdge(B→C) discover(C) crossEdge(C→D) finish(C) finish(B) forwardEdge(A→C) finish(A)")
    }

    @Test("TR-49 a symmetric graph has no cross edges")
    func tr49() {
        let edges = DirectedFixture<Int>.cube.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) treeEdge(1→3) discover(3) backEdge(3→1) treeEdge(3→2) discover(2) backEdge(2→0) backEdge(2→3) treeEdge(2→6) discover(6) backEdge(6→2) treeEdge(6→4) discover(4) backEdge(4→0) treeEdge(4→5) discover(5) backEdge(5→1) backEdge(5→4) treeEdge(5→7) discover(7) backEdge(7→3) backEdge(7→5) backEdge(7→6) finish(7) finish(5) backEdge(4→6) finish(4) forwardEdge(6→7) finish(6) finish(2) forwardEdge(3→7) finish(3) forwardEdge(1→5) finish(1) forwardEdge(0→2) forwardEdge(0→4) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.cube.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.cube.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-50 a row dense with self-loops")
    func tr50() {
        let edges = DirectedFixture<Int>.jgraphtMatrixCSV.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) finish(1) treeEdge(0→2) discover(2) backEdge(2→0) treeEdge(2→3) discover(3) treeEdge(3→4) discover(4) backEdge(4→0) crossEdge(4→1) backEdge(4→2) backEdge(4→3) backEdge(4→4) finish(4) finish(3) finish(2) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.jgraphtMatrixCSV.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.jgraphtMatrixCSV.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-51 LEMON's test digraph")
    func tr51() {
        // LEMON test/dfs_test.cc.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 4, to: 2), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 5, to: 0), DirectedEdge(from: 6, to: 3)]
        let expected = "discover(0) treeEdge(0→1) discover(1) treeEdge(1→2) discover(2) treeEdge(2→3) discover(3) finish(3) finish(2) treeEdge(1→4) discover(4) crossEdge(4→2) treeEdge(4→5) discover(5) backEdge(5→0) finish(5) finish(4) finish(1) finish(0)"
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 7, edges: edges)
        #expect(matrix.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-56 the whole graph, roots in vertices' order")
    func tr56() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(0) finish(0) discover(1) crossEdge(1→0) finish(1) discover(2) crossEdge(2→1) finish(2) discover(3) crossEdge(3→2) treeEdge(3→4) discover(4) crossEdge(4→0) crossEdge(4→1) finish(4) finish(3) discover(5) crossEdge(5→3) finish(5)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-57 the whole graph with an isolated vertex and a 2-cycle")
    func tr57() {
        let edges = DirectedFixture<Int>.boostExample.edges
        let expected = "discover(0) finish(0) discover(1) treeEdge(1→2) discover(2) crossEdge(2→0) backEdge(2→2) finish(2) treeEdge(1→5) discover(5) crossEdge(5→0) finish(5) finish(1) discover(3) treeEdge(3→4) discover(4) backEdge(4→3) finish(4) finish(3)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.boostExample.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.boostExample.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-58 the whole graph: the second tree has only cross edges into the first")
    func tr58() {
        let edges = DirectedFixture<Int>.scc9.edges
        let expected = "discover(0) treeEdge(0→3) discover(3) treeEdge(3→6) discover(6) backEdge(6→0) finish(6) finish(3) finish(0) discover(1) treeEdge(1→7) discover(7) treeEdge(7→4) discover(4) backEdge(4→1) finish(4) treeEdge(7→5) discover(5) treeEdge(5→8) discover(8) treeEdge(8→2) discover(2) backEdge(2→5) finish(2) crossEdge(8→6) finish(8) finish(5) finish(7) finish(1)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.scc9.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.scc9.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-59 the whole graph with isolated String vertices, listed first")
    func tr59() {
        let graph = ReferenceDirectedMultigraph(vertices: ["G", "J", "K"], edges: DirectedFixture<String>.networkXABCD.edges)
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(G) finish(G) discover(J) finish(J) discover(K) finish(K) discover(A) treeEdge(A→B) discover(B) treeEdge(B→D) discover(D) finish(D) treeEdge(B→C) discover(C) crossEdge(C→D) finish(C) finish(B) forwardEdge(A→C) finish(A)")
    }

    @Test("TR-62 several roots in the order given; a reached root is skipped")
    func tr62() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(3) treeEdge(3→2) discover(2) treeEdge(2→1) discover(1) treeEdge(1→0) discover(0) finish(0) finish(1) finish(2) treeEdge(3→4) discover(4) crossEdge(4→0) crossEdge(4→1) finish(4) finish(3) discover(5) crossEdge(5→3) finish(5)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: [3, 0, 5]).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: [3, 0, 5]).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-63 isolated vertices only")
    func tr63() {
        let edges = DirectedFixture<Int>.isolatedVertices.edges
        let expected = "discover(0) finish(0) discover(1) finish(1) discover(2) finish(2) discover(3) finish(3) discover(4) finish(4) discover(5) finish(5) discover(6) finish(6) discover(7) finish(7) discover(8) finish(8) discover(9) finish(9)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.isolatedVertices.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.isolatedVertices.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-65 the whole of petgraph's Bellman–Ford graph")
    func tr65() {
        let edges = DirectedFixture<Int>.petgraphBellmanFord.edges
        let expected = "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) backEdge(1→1) treeEdge(1→2) discover(2) treeEdge(2→3) discover(3) finish(3) finish(2) forwardEdge(1→3) finish(1) forwardEdge(0→2) finish(0) discover(4) treeEdge(4→5) discover(5) treeEdge(5→7) discover(7) treeEdge(7→8) discover(8) finish(8) finish(7) finish(5) finish(4) discover(6) crossEdge(6→7) finish(6)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.petgraphBellmanFord.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.petgraphBellmanFord.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch().map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-66 the second copy of a tree edge is a forward edge")
    func tr66() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) finish(1) forwardEdge(0→1) finish(0)")
    }

    @Test("TR-67 every copy of a self-loop is a back edge")
    func tr67() {
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) backEdge(0→0) backEdge(0→0) finish(0) discover(1) finish(1)")
    }

    @Test("TR-68 antiparallel and parallel edges, depth-first")
    func tr68() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) finish(1) forwardEdge(0→1) finish(0)")
    }

    @Test("TR-69 a duplicated chord, depth-first")
    func tr69() {
        let graph = ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.pathWithChord.edges)
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) treeEdge(1→2) discover(2) treeEdge(2→3) discover(3) treeEdge(3→4) discover(4) treeEdge(4→5) discover(5) finish(5) finish(4) finish(3) finish(2) forwardEdge(1→3) forwardEdge(1→3) finish(1) finish(0)")
    }

    @Test("TR-70 parallel edges and self-loop pairs")
    func tr70() {
        let graph = ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(1) treeEdge(1→2) discover(2) treeEdge(2→3) discover(3) finish(3) forwardEdge(2→3) treeEdge(2→4) discover(4) backEdge(4→4) finish(4) finish(2) finish(1) discover(5) backEdge(5→5) crossEdge(5→2) backEdge(5→5) finish(5)")
    }

    @Test("TR-71 a tripled cross edge is three cross events")
    func tr71() {
        let graph = ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(graph.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) backEdge(1→0) treeEdge(1→4) discover(4) treeEdge(4→5) discover(5) treeEdge(5→6) discover(6) finish(6) finish(5) finish(4) forwardEdge(1→5) forwardEdge(1→6) finish(1) finish(0) discover(2) crossEdge(2→4) crossEdge(2→4) crossEdge(2→4) finish(2) discover(3) crossEdge(3→4) finish(3) discover(7) crossEdge(7→6) backEdge(7→7) finish(7)")
    }

    @Test("TR-73 depth limit 0 reports only the sources, depth-first")
    func tr73() {
        let edges = DirectedFixture<Int>.house.edges
        let expected = "discover(5) finish(5)"
        let matrix = AdjacencyMatrix(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: DirectedFixture<Int>.house.vertexCount, edges: edges)
        #expect(matrix.depthFirstSearch(from: 5, depthLimit: 0).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 5, depthLimit: 0).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-76 depth-limited transcripts")
    func tr76() {
        // NetworkX test_dfs.py: path 0…6 plus 2–7–8–9–10.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 5, to: 4), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 6, to: 5), DirectedEdge(from: 7, to: 2), DirectedEdge(from: 7, to: 8), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 9, to: 8), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 10, to: 9)]
        let expected = "discover(5) treeEdge(5→4) discover(4) finish(4) treeEdge(5→6) discover(6) finish(6) finish(5)"
        let matrix = AdjacencyMatrix(vertexCount: 11, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 11, edges: edges)
        #expect(matrix.depthFirstSearch(from: 5, depthLimit: 1).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 5, depthLimit: 1).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-76 depth-limited transcripts, from 6")
    func tr76v2() {
        // NetworkX: (5, 4) reverse-depth_limit, (5, 6) nontree.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 5, to: 4), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 6, to: 5), DirectedEdge(from: 7, to: 2), DirectedEdge(from: 7, to: 8), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 9, to: 8), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 10, to: 9)]
        let expected = "discover(6) treeEdge(6→5) discover(5) treeEdge(5→4) discover(4) finish(4) backEdge(5→6) finish(5) finish(6)"
        let matrix = AdjacencyMatrix(vertexCount: 11, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: 11, edges: edges)
        #expect(matrix.depthFirstSearch(from: 6, depthLimit: 2).map(\.description).joined(separator: " ") == expected)
        #expect(sparse.depthFirstSearch(from: 6, depthLimit: 2).map(\.description).joined(separator: " ") == expected)
    }

    @Test("TR-79 depth limit 1 over the whole of a disconnected graph")
    func tr79() {
        // NetworkX test_dfs.py: 8→7 and 10→9 nontree.
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1, 2, 3, 7, 8, 9, 10], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 7, to: 2), DirectedEdge(from: 7, to: 8), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 9, to: 8), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 10, to: 9)])
        #expect(graph.depthFirstSearch(depthLimit: 1).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) finish(1) finish(0) discover(2) treeEdge(2→3) discover(3) finish(3) treeEdge(2→7) discover(7) finish(7) finish(2) discover(8) crossEdge(8→7) treeEdge(8→9) discover(9) finish(9) finish(8) discover(10) crossEdge(10→9) finish(10)")
    }

}
