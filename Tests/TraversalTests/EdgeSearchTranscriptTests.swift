// Exact event transcripts of the edge-position searches, on the ReferenceDirectedMultigraph and
// ReferencePseudograph test conformers, whose rows follow the edges as written and whose edge
// positions are the edges' offsets. Expected transcripts come from the reference model in the
// catalog's edges.py, which reports each edge at the first row that reaches it. Case IDs (TR-nn)
// refer to the catalog; see README.md.
//
// GENERATED from the catalog by a script, then checked in: each test is self-contained.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Edge-position search transcripts, directed")
struct DirectedEdgeSearchTranscriptTests {
    @Test("TR-200 a repeated tree edge is a forward edge at its own position")
    func tr200dfs() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.edgeDepthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) backEdge(2) finish(1) forwardEdge(1) finish(0)")
    }

    @Test("TR-200 a repeated edge is a non-tree edge at its own position")
    func tr200bfs() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.edgeBreadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) nonTreeEdge(1) finish(0) nonTreeEdge(2) finish(1)")
    }

    @Test("TR-201 each copy of a directed self-loop is a back edge")
    func tr201dfs() {
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(graph.edgeDepthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) backEdge(0) backEdge(1) finish(0) discover(1) finish(1)")
    }

    @Test("TR-201 each copy of a directed self-loop is a non-tree edge")
    func tr201bfs() {
        let graph = ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(graph.edgeBreadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) nonTreeEdge(0) nonTreeEdge(1) finish(0)")
    }

    @Test("TR-202 a tripled cross edge, each copy at its position")
    func tr202dfs() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(graph.edgeDepthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) backEdge(1) backEdge(5) finish(1) finish(0) discover(2) crossEdge(2) crossEdge(3) crossEdge(4) finish(2)")
    }

    @Test("TR-203 a directed depth limit")
    func tr203dfs() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 1)])
        #expect(graph.edgeDepthFirstSearch(from: 0, depthLimit: 1).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) finish(1) treeEdge(2) discover(2) finish(2) finish(0)")
    }

    @Test("TR-203 a directed breadth-first depth limit")
    func tr203bfs() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 1)])
        #expect(graph.edgeBreadthFirstSearch(from: 0, depthLimit: 1).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(2) discover(2) finish(0) finish(1) finish(2)")
    }

}

@Suite("Edge-position search transcripts, undirected")
struct UndirectedEdgeSearchTranscriptTests {
    @Test("TR-204 the tree edge is reported once; a parallel edge to the parent is a back edge")
    func tr204dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.edgeDepthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) backEdge(1) finish(1) finish(0)")
    }

    @Test("TR-204 the tree edge is reported once; a parallel edge to the parent is a non-tree edge")
    func tr204bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.edgeBreadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) nonTreeEdge(1) finish(0) finish(1)")
    }

    @Test("TR-205 an undirected self-loop is one back edge")
    func tr205dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 0)])
        #expect(graph.edgeDepthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) backEdge(0) treeEdge(1) discover(1) finish(1) backEdge(2) finish(0)")
    }

    @Test("TR-205 an undirected self-loop is one non-tree edge")
    func tr205bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 0)])
        #expect(graph.edgeBreadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) nonTreeEdge(0) treeEdge(1) discover(1) nonTreeEdge(2) finish(0) finish(1)")
    }

    @Test("TR-206 a triangle with a doubled side and a loop: tree and back edges only")
    func tr206dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        #expect(graph.edgeDepthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(1) discover(2) backEdge(2) backEdge(3) backEdge(4) finish(2) finish(1) finish(0)")
    }

    @Test("TR-206 a triangle with a doubled side and a loop, breadth-first")
    func tr206bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        #expect(graph.edgeBreadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(2) discover(2) finish(0) nonTreeEdge(1) nonTreeEdge(3) finish(1) nonTreeEdge(4) finish(2)")
    }

    @Test("TR-207 each edge once, reported from the end that reaches it first")
    func tr207dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 0), UndirectedEdge(0, 4)])
        #expect(graph.edgeDepthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(1) discover(2) treeEdge(3) discover(4) backEdge(5) finish(4) finish(2) treeEdge(2) discover(3) backEdge(4) finish(3) finish(1) finish(0)")
    }

    @Test("TR-207 each edge once, from the end explored first")
    func tr207bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 0), UndirectedEdge(0, 4)])
        #expect(graph.edgeBreadthFirstSearch(from: 0).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(4) discover(3) treeEdge(5) discover(4) finish(0) treeEdge(1) discover(2) nonTreeEdge(2) finish(1) finish(3) nonTreeEdge(3) finish(4) finish(2)")
    }

    @Test("TR-208 the whole of a disconnected undirected graph")
    func tr208dfs() {
        let graph = ReferencePseudograph(vertices: [5], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 2), UndirectedEdge(2, 3)])
        #expect(graph.edgeDepthFirstSearch().map(\.description).joined(separator: " ") == "discover(5) finish(5) discover(0) treeEdge(0) discover(1) finish(1) finish(0) discover(2) treeEdge(1) discover(3) treeEdge(2) discover(4) backEdge(3) finish(4) backEdge(4) finish(3) finish(2)")
    }

    @Test("TR-209 an undirected depth limit leaves forward and cross edges")
    func tr209dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 3), UndirectedEdge(3, 2), UndirectedEdge(0, 2)])
        #expect(graph.edgeDepthFirstSearch(from: 0, depthLimit: 2).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(1) discover(2) finish(2) finish(1) treeEdge(2) discover(3) crossEdge(3) finish(3) forwardEdge(4) finish(0)")
    }

    @Test("TR-209 an undirected breadth-first depth limit")
    func tr209bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 3), UndirectedEdge(3, 2), UndirectedEdge(0, 2)])
        #expect(graph.edgeBreadthFirstSearch(from: 0, depthLimit: 1).map(\.description).joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(2) discover(3) treeEdge(4) discover(2) finish(0) finish(1) finish(3) finish(2)")
    }

    @Test("TR-210 an edge to a pruned vertex is reported from its other end")
    func tr210dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(1, 1)])
        var search = graph.edgeDepthFirstSearch(from: 0).makeIterator()
        var events: [String] = []
        while let event = search.next() {
            events.append(event.description)
            if case .discover(let v) = event, [1].contains(v) { search.prune() }
        }
        #expect(events.joined(separator: " ") == "discover(0) treeEdge(0) discover(1) finish(1) treeEdge(2) discover(2) crossEdge(1) finish(2) finish(0)")
    }

    @Test("TR-210 an edge to a pruned vertex is reported from its other end, breadth-first")
    func tr210bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(1, 1)])
        var search = graph.edgeBreadthFirstSearch(from: 0).makeIterator()
        var events: [String] = []
        while let event = search.next() {
            events.append(event.description)
            if case .discover(let v) = event, [1].contains(v) { search.prune() }
        }
        #expect(events.joined(separator: " ") == "discover(0) treeEdge(0) discover(1) treeEdge(2) discover(2) finish(0) finish(1) nonTreeEdge(1) finish(2)")
    }

    @Test("TR-211 several roots; a reached root is skipped")
    func tr211dfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(1, 0)])
        #expect(graph.edgeDepthFirstSearch(from: [2, 1, 3, 0]).map(\.description).joined(separator: " ") == "discover(2) treeEdge(1) discover(3) finish(3) finish(2) discover(1) treeEdge(0) discover(0) backEdge(2) finish(0) finish(1)")
    }

    @Test("TR-211 several sources, all discovered first")
    func tr211bfs() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 3)])
        #expect(graph.edgeBreadthFirstSearch(from: [0, 2]).map(\.description).joined(separator: " ") == "discover(0) discover(2) treeEdge(0) discover(1) nonTreeEdge(2) finish(0) nonTreeEdge(1) treeEdge(3) discover(3) finish(2) finish(1) finish(3)")
    }

}
