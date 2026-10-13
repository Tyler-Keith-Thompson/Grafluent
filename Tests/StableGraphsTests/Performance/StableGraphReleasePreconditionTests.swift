// The index-space and key reads that reach the page tables, each run in a child process (exit
// test). They are here because `--config=release` runs only this target: in a debug build an
// out-of-range page read traps through the buffer pointer's debug check, so only an optimized
// build shows that the preconditions themselves trap. StableGraphPreconditionTests runs the same
// calls in debug. See README.md.

import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs preconditions in an optimized build")
struct StableGraphReleasePreconditionTests {
    @Test("outEdges(ofIndex:), inEdges(ofIndex:) and successorIndices(ofIndex:) trap past the page table and at a vertex hole")
    func indexRowsOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = Array(graph.outEdges(ofIndex: 5000))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = Array(graph.outEdges(ofIndex: -1))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = Array(graph.inEdges(ofIndex: 5000))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(1)
            _ = Array(graph.outEdges(ofIndex: 1))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(1)
            _ = Array(graph.successorIndices(ofIndex: 1))
        }
        // Without the calls: in range and without holes, the rows answer.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.outEdges(ofIndex: 1)) == [0] && Array(graph.inEdges(ofIndex: 0)) == [0])
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [0])
    }

    @Test("vertices.index(before:) and edges.index(before:) trap far past the end")
    func steppingBackFromPastTheEnd() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = graph.vertices.index(before: 1_000_000)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.edges.index(before: 1_000_000)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = graph.vertices.indices.index(before: 1_000_000)
        }
        // Without the calls: stepping back from the end reaches the last live position.
        let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
        #expect(graph.vertices.index(before: graph.vertices.endIndex) == 0 && graph.edges.index(before: graph.edges.endIndex) == 0)
    }

    @Test("The key hooks trap past the page table and in a freed page; _vertex(atKey:) traps at a hole")
    func keyHooksOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = graph._outDegree(ofKey: 5000)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = graph._inDegree(ofKey: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = Array(graph._successorKeys(ofKey: -1))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = Array(graph._outEdges(ofKey: 5000))
        }
        await #expect(processExitsWith: .failure) {
            // Positions 1024 ..< 2048 all removed: their page is freed, between two live pages.
            var graph = StableDirectedGraph<Int>(vertices: 0 ..< 3072)
            for v in 1024 ..< 2048 { _ = graph.remove(v) }
            _ = graph._outDegree(ofKey: 1500)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.remove(1)
            _ = graph._vertex(atKey: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0])
            _ = graph._vertex(atKey: 5000)
        }
        // Without the calls: live keys answer on either side of the freed page.
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 3072, edges: [DirectedEdge(from: 0, to: 2500)])
        for v in 1024 ..< 2048 { _ = graph.remove(v) }
        #expect(graph._outDegree(ofKey: 0) == 1 && graph._inDegree(ofKey: 2500) == 1)
        #expect(Array(graph._successorKeys(ofKey: 0)) == [2500] && graph._vertex(atKey: 2500) == 2500)
    }
}
