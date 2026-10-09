// The searches return walks: `Cycle` for the cycle `findCycle` finds and `Path` for a
// bidirectional shortest path, each naming the edges taken, so parallel copies are told apart.
// Case IDs (WK-12nn) refer to the Walks catalog's migration section; see README.md.

import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal
import Walks

@Suite("Cycles and paths as walks")
struct TraversalWalkTests {
    @Test("WK-1202 the cycle found keeps its vertex order, and equals any rotation of itself")
    func cycleRotation() {
        // igraph's Wikipedia DAG with 5→0 added, at position 9.
        let edges = [(0, 3), (0, 4), (1, 3), (2, 4), (2, 7), (3, 5), (3, 6), (3, 7), (4, 6), (5, 0)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: edges)
        let cycle = graph.findCycle()
        #expect(cycle?.vertices == [0, 3, 5])
        #expect(cycle?.edges == [0, 5, 9])
        #expect(cycle == Cycle(vertices: [3, 5, 0], edges: [5, 9, 0]))
        #expect(cycle == Cycle(vertices: [5, 0, 3], edges: [9, 0, 5]))
        #expect(cycle != Cycle(vertices: [0, 5, 3], edges: [9, 5, 0]))
        // The same vertices on a compressed sparse row, whose edges are its own positions.
        let sparse = CompressedSparseRow(vertexCount: 8, edges: edges)
        let found = sparse.findCycle()
        #expect(found?.vertices == [0, 3, 5])
        if let found { #expect(Cycle(vertices: found.vertices, edges: found.edges, in: sparse) != nil) }
    }

    @Test("WK-1203 NetworkX's find_cycle digraph: the cycle names the first 1→0 copy the search meets")
    func networkXFindCycle() {
        // NetworkX: [(-1, 0), (0, 1), (1, 0), (1, 0), (2, 1), (3, 1)] from [0, 1, 2, 3] is [(0, 1), (1, 0)].
        let edges = [(-1, 0), (0, 1), (1, 0), (1, 0), (2, 1), (3, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = ReferenceDirectedMultigraph(edges: edges)
        let cycle = graph.findCycle(from: [0, 1, 2, 3])
        #expect(cycle?.vertices == [0, 1])
        #expect(cycle?.edges == [1, 2])
        if let cycle { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil) }
    }

    @Test("WK-1204 NetworkX's undirected find_cycle answer is a cycle of the pseudograph")
    func networkXUndirectedFindCycle() {
        // NetworkX's undirected graph merges the 0–1 copies; the pseudograph keeps them, at 1, 2, 3.
        let edges = [(-1, 0), (0, 1), (1, 0), (1, 0), (2, 1), (3, 1), (2, 0)].map { UndirectedEdge($0.0, $0.1) }
        let graph = ReferencePseudograph(edges: edges)
        // NetworkX: [(0, 1), (1, 2), (2, 0)].
        #expect(Cycle(vertices: [0, 1, 2], edges: [1, 4, 6], in: graph) != nil)
        #expect(Cycle(vertices: [0, 1, 2], edges: [1, 4, 5], in: graph) == nil)
        // In the directed view the first cycle found is the 2-cycle over one edge's two arcs.
        #expect(graph.directed.findCycle()?.length == 2)
    }

    @Test("WK-1205 an orientation-ignoring cycle of a DAG is a cycle of its undirected view, not of the DAG")
    func orientationIgnoringCycle() {
        // NetworkX find_cycle(orientation='ignore'): [(0, 1, forward), (1, 2, forward), (0, 2, reverse)].
        let dag = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        #expect(dag.findCycle() == nil)
        #expect(Cycle(vertices: [0, 1, 2], edges: [0, 2, 1], in: dag.undirected) != nil)
        #expect(Cycle(vertices: [0, 1, 2], edges: [0, 2, 1], in: dag) == nil)
    }

    @Test("WK-1213 the bidirectional path from a vertex to itself is the trivial path")
    func bidirectionalTrivialPath() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let path = graph.bidirectionalShortestPath(from: 1, to: 1)
        #expect(path == Path(vertex: 1))
        #expect(path?.length == 0)
        #expect(path?.edges == [])
        #expect(path?.source == 1 && path?.target == 1)
        let step = graph.bidirectionalShortestPath(from: 0, to: 1)
        #expect(step?.vertices == [0, 1])
        #expect(step?.edges == [0])
    }

    @Test("WK-1214 a self-loop is a cycle of one vertex and that loop", .tags(.selfLoops))
    func selfLoopCycle() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0)])
        let cycle = graph.findCycle()
        #expect(cycle?.vertices == [0])
        #expect(cycle?.edges == [0])
        #expect(cycle?.length == 1)
        #expect(cycle == Cycle(vertices: [0], edges: [0]))
        #expect(graph.findCycle(from: [0]) == cycle)
    }

    @Test("WK-1215 with parallel copies the cycle's edges are edges of the graph")
    func parallelCopiesCycle() {
        // 1→2 twice, at 0 and 1, and 2→1 at 2.
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let cycle = graph.findCycle()
        #expect(cycle?.vertices == [1, 2])
        #expect(cycle?.edges == [0, 2])
        if let cycle { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil) }
        let path = graph.bidirectionalShortestPath(from: 1, to: 2)
        #expect(path?.edges == [0])
        if let path { #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil) }
    }
}
