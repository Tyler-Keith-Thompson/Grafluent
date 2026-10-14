// StableUndirectedGraph on large shapes, each inside a Task with a one-minute limit, meant to
// finish within a few seconds in a debug build; the benchmarks take timings. Every expected value
// is known by construction: a cycle on 10⁵ vertices with every other vertex removed and the
// survivors joined again, 10⁵ copies of one pair in both orientations churned from the front and
// the back, and 10⁵ steps of vertex churn across freed pages. See README.md.

import Connectivity
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("StableUndirectedGraph at 10⁵")
struct StableUndirectedGraphStressTests {
    @Test("A cycle on 10⁵ vertices, every other vertex removed, the survivors joined again in a cycle", .timeLimit(.minutes(1)))
    func cycleWithEveryOtherVertexRemoved() async {
        await Task {
            let n = 100_000
            var graph = StableUndirectedGraph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(graph.vertexIndexBound == n && graph.edgeIndexBound == n)
            #expect(graph.connectedComponents().count == 1)
            for v in stride(from: 1, to: n, by: 2) { #expect(graph.remove(v) == v) }
            #expect(graph.vertexCount == n / 2 && graph.edgeCount == 0)
            #expect(Array(graph.vertices.indices) == Array(stride(from: 0, to: n, by: 2)))
            #expect(graph.connectedComponents().count == n / 2)
            let survivors = Array(graph.vertices)
            for (k, v) in survivors.enumerated() {
                #expect(graph.insert(edge: UndirectedEdge(v, survivors[(k + 1) % survivors.count])) == n + k)
            }
            #expect(graph.connectedComponents().count == 1)
            #expect(graph.bridges().isEmpty)
            #expect(Array(graph.incidentEdges(of: 0)) == [n, n + survivors.count - 1])
            #expect(graph.vertices.allSatisfy { graph.degree(of: $0) == 2 })
            let compacted = Pseudograph(graph)
            #expect(compacted.edgeCount == n / 2 && Array(compacted.vertices) == survivors)
        }.value
    }

    @Test("10⁵ copies of one pair in both orientations, removed newest first and oldest first", .timeLimit(.minutes(1)))
    func churnOnOnePair() async {
        await Task {
            let n = 100_000
            var graph = StableUndirectedGraph<Int>(vertices: [0, 1])
            for k in 0 ..< n { #expect(graph.insert(edge: k.isMultiple(of: 2) ? UndirectedEdge(0, 1) : UndirectedEdge(1, 0)) == k) }
            #expect(graph.edgeCount(between: 1, and: 0) == n && graph.degree(of: 0) == n && graph.degree(of: 1) == n)
            // The newest copy each time, whichever its orientation.
            for k in 0 ..< n / 4 {
                let removed = graph.remove(edge: UndirectedEdge(0, 1))
                #expect(removed?.u == ((n - 1 - k).isMultiple(of: 2) ? 0 : 1))
            }
            for p in 0 ..< n / 4 { #expect(graph.remove(edgeAt: p) == UndirectedEdge(0, 1)) }
            #expect(Array(graph.edges(between: 0, and: 1)) == Array(n / 4 ..< 3 * n / 4))
            #expect(graph.edges.startIndex == n / 4 && graph.edges.endIndex == n)
            #expect(graph.removeAllEdges(between: 1, and: 0) == n / 2)
            #expect(graph.edgeCount == 0 && graph.edges.endIndex == n && graph.vertexIndexBound == 2)
        }.value
    }

    @Test("10⁵ steps of vertex churn finish in linear time: each step a new vertex with an edge, the previous vertex removed", .timeLimit(.minutes(1)))
    func vertexChurn() async {
        await Task {
            let n = 100_000
            var graph = StableUndirectedGraph<Int>()
            let weights = graph.addEdgeMap(default: 0)
            for i in 0 ..< n {
                let p = graph.insert(edge: UndirectedEdge(i + 1, i))
                #expect(p == i)
                graph[weights, ofEdgeAt: p] = i
                #expect(graph.remove(i) == i)
            }
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
            #expect(Array(graph.vertices) == [n] && graph.vertices.firstIndex(of: n) == n)
            #expect(graph.vertices.endIndex == n + 1 && graph.edges.endIndex == n)
            #expect(graph.insert(edge: UndirectedEdge(n, n)) == n)
            #expect(Array(graph.incidentEdges(of: n)) == [n, n] && graph[weights, ofEdgeAt: n] == 0)
        }.value
    }
}
