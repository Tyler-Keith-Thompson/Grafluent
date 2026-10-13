// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in
// a debug build; the benchmarks take timings. Every expected value is known by construction: a
// cycle on 10⁵ vertices with every other vertex removed, 10⁵ copies of one pair churned from the
// front and the back, a star whose every other edge is removed by position, and a grid with
// vertices removed and re-inserted, 10⁵ steps of vertex churn, and the bulk removals over 10⁵
// edges. See README.md.

import Connectivity
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("StableGraphs at 10⁵")
struct StableGraphStressTests {
    @Test("A cycle on 10⁵ vertices, every other vertex removed: survivors keep their positions; isolated vertices remain", .timeLimit(.minutes(1)))
    func cycleWithEveryOtherVertexRemoved() async {
        await Task {
            let n = 100_000
            var graph = StableDirectedGraph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
            #expect(graph.vertexIndexBound == n && graph.edgeIndexBound == n)
            for v in stride(from: 1, to: n, by: 2) { #expect(graph.remove(v) == v) }
            // Edge k is k → k+1, so every edge touches an odd vertex: none is left.
            #expect(graph.vertexCount == n / 2 && graph.edgeCount == 0)
            #expect(graph.vertices.endIndex == n && graph.edges.endIndex == n)
            #expect(Array(graph.vertices.indices) == Array(stride(from: 0, to: n, by: 2)))
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.weaklyConnectedComponents().count == n / 2)
            // Re-connect the survivors in a cycle: new edges get positions n, n + 1, ….
            let survivors = Array(graph.vertices)
            for (k, v) in survivors.enumerated() {
                #expect(graph.insert(edge: DirectedEdge(from: v, to: survivors[(k + 1) % survivors.count])) == n + k)
            }
            #expect(graph.stronglyConnectedComponents().count == 1)
            #expect(Array(graph.outEdges(of: 0)) == [n] && Array(graph.inEdges(of: 0)) == [n + survivors.count - 1])
            for p in [0, 1, n - 1] { #expect(!graph.edges.indices.contains(p)) }
            let compacted = DirectedPseudograph<Int>(graph)
            #expect(compacted.edgeCount == n / 2 && Array(compacted.vertices) == survivors)
        }.value
    }

    @Test("10⁵ copies of one pair, removed newest first and oldest first: positions are never reused", .timeLimit(.minutes(1)))
    func churnOnOnePair() async {
        await Task {
            let n = 100_000
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            for k in 0 ..< n { #expect(graph.insert(edge: DirectedEdge(from: 0, to: 1)) == k) }
            #expect(graph.edgeCount(from: 0, to: 1) == n && graph.outDegree(of: 0) == n && graph.inDegree(of: 1) == n)
            for _ in 0 ..< n / 4 { #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)) == DirectedEdge(from: 0, to: 1)) }
            for p in 0 ..< n / 4 { #expect(graph.remove(edgeAt: p) == DirectedEdge(from: 0, to: 1)) }
            #expect(Array(graph.edges(from: 0, to: 1)) == Array(n / 4 ..< 3 * n / 4))
            #expect(Array(graph.outEdges(of: 0)) == Array(n / 4 ..< 3 * n / 4))
            #expect(graph.edges.startIndex == n / 4 && graph.edges.endIndex == n)
            #expect(graph.insert(edge: DirectedEdge(from: 1, to: 0)) == n)
            #expect(graph.removeAllEdges(from: 0, to: 1) == n / 2)
            #expect(Array(graph.edges.indices) == [n] && graph.edgeCount == 1 && graph.edges.endIndex == n + 1)
            #expect(graph.edgeIndexBound == nil && graph.vertexIndexBound == 2)
        }.value
    }

    @Test("A star of 10⁵ edges, every other edge removed by position: rows are the odd positions", .timeLimit(.minutes(1)))
    func starWithEveryOtherEdgeRemoved() async {
        await Task {
            let n = 100_000
            var graph = StableDirectedGraph<Int>(edges: (1 ... n).map { DirectedEdge(from: 0, to: $0) })
            for p in stride(from: 0, to: n, by: 2) { #expect(graph.remove(edgeAt: p) == DirectedEdge(from: 0, to: p + 1)) }
            #expect(graph.edgeCount == n / 2 && graph.vertexCount == n + 1)
            #expect(Array(graph.outEdges(of: 0)) == Array(stride(from: 1, to: n, by: 2)))
            #expect(Array(graph.successors(of: 0)) == Array(stride(from: 2, through: n, by: 2)))
            #expect(graph.outDegree(of: 0) == n / 2 && graph.inDegree(of: 1) == 0 && graph.inDegree(of: 2) == 1)
            #expect(graph.vertexIndexBound == n + 1 && graph.edgeIndexBound == nil)
            for p in stride(from: 1, to: n, by: 2) {
                #expect(graph.target(ofEdgeAt: p) == p + 1)
            }
            #expect(graph.weaklyConnectedComponents().count == 1 + n / 2)
        }.value
    }

    @Test("A 300 × 300 grid with vertices removed and re-inserted: surviving edges keep their positions and ends", .timeLimit(.minutes(1)))
    func gridWithReinsertedVertices() async {
        await Task {
            let side = 300
            var edges: [DirectedEdge<Int>] = []
            for r in 0 ..< side {
                for c in 0 ..< side {
                    if c + 1 < side { edges.append(DirectedEdge(from: r * side + c, to: r * side + c + 1)) }
                    if r + 1 < side { edges.append(DirectedEdge(from: r * side + c, to: (r + 1) * side + c)) }
                }
            }
            var graph = StableDirectedGraph<Int>(vertices: 0 ..< side * side, edges: edges)
            let removed = Set(stride(from: 0, to: side * side, by: 7))
            for v in removed.sorted() { graph.remove(v) }
            let alive = edges.indices.filter { !removed.contains(edges[$0].source) && !removed.contains(edges[$0].target) }
            #expect(Array(graph.edges.indices) == alive)
            #expect(alive.allSatisfy { graph.edges[$0] == edges[$0] })
            for v in removed.sorted() { #expect(graph.insert(v).inserted) }
            #expect(Array(graph.vertices.suffix(removed.count)) == removed.sorted())
            #expect(graph.vertices.endIndex == side * side + removed.count)
            #expect(graph.vertices.firstIndex(of: 0) == side * side)
            #expect(graph.weaklyConnectedComponents().count >= removed.count)
            #expect(graph.edges.endIndex == edges.count && graph.edgeCount == alive.count)
        }.value
    }

    @Test("10⁵ steps of vertex churn finish in linear time: each step a new vertex with an edge, the previous vertex removed", .timeLimit(.minutes(1)))
    func vertexChurn() async {
        await Task {
            let n = 100_000
            var graph = StableDirectedGraph<Int>()
            for i in 0 ..< n {
                #expect(graph.insert(edge: DirectedEdge(from: i, to: i + 1)) == i)
                #expect(graph.remove(i) == i)
            }
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
            #expect(Array(graph.vertices) == [n] && graph.vertices.firstIndex(of: n) == n)
            #expect(graph.vertices.endIndex == n + 1 && graph.edges.endIndex == n)
            #expect(graph.insert(edge: DirectedEdge(from: n, to: n)) == n)
            #expect(Array(graph.outEdges(of: n)) == [n] && Array(graph.inEdges(of: n)) == [n])
        }.value
    }

    @Test("Bulk removals on a 10⁵-edge star: removeAllEdges(from:where:), removeAllEdges(where:), removeAllEdges(from:to:)", .timeLimit(.minutes(1)))
    func bulkRemovalsOnAStar() async {
        await Task {
            let n = 100_000
            var graph = StableDirectedGraph<Int>(edges: (1 ... n).map { DirectedEdge(from: 0, to: $0 % 10 + 1) })
            #expect(graph.removeAllEdges(from: 0) { $0.isMultiple(of: 2) } == n / 2)
            #expect(Array(graph.outEdges(of: 0)) == Array(stride(from: 1, to: n, by: 2)))
            #expect(graph.removeAllEdges { $0 % 4 == 1 } == n / 4)
            #expect(Array(graph.outEdges(of: 0)) == Array(stride(from: 3, to: n, by: 4)))
            // Position p is 0 → (p + 1) % 10 + 1: the survivors to 5 are p ≡ 3 (mod 20), to 9 p ≡ 7 (mod 20).
            let toFive = Array(stride(from: 3, to: n, by: 20))
            #expect(Array(graph.edges(from: 0, to: 5)) == toFive)
            #expect(graph.removeAllEdges(from: 0, to: 5) == n / 20)
            #expect(graph.edgeCount == n / 4 - n / 20 && graph.inDegree(of: 5) == 0)
            #expect(Array(graph.inEdges(of: 9)) == Array(stride(from: 7, to: n, by: 20)))
        }.value
    }
}
