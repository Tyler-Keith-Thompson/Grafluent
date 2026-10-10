// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in
// a debug build; the benchmarks take timings. 10⁵ parallel copies of one pair (directed and
// undirected), removed newest first and from the front; a seeded random multigraph on 10⁵
// vertices with copies and loops, against the reference conformer and then half its vertices
// removed; every edge inserted and then removed again, by edge and by pair, until the graph is
// empty. Expected values are closed forms or computed inside the test from the graph's own edges.
// See README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import Testing

@Suite("Multigraphs at 10⁵")
struct MultigraphStressTests {
    @Test("10⁵ copies of one pair: positions, the class order, newest-first removal and removal from the front", .timeLimit(.minutes(1)))
    func manyCopiesOfOnePair() async throws {
        try await Task {
            let n = 100_000
            var graph = Pseudograph<Int>()
            for k in 0 ..< n { #expect(graph.insert(edge: k.isMultiple(of: 2) ? UndirectedEdge(0, 1) : UndirectedEdge(1, 0)) == k) }
            #expect(graph.edgeCount == n && graph.vertexCount == 2)
            #expect(graph.edgeCount(between: 1, and: 0) == n)
            #expect(graph.degree(of: 0) == n && graph.degree(of: 1) == n)
            #expect(Array(graph.edges(between: 0, and: 1)) == Array(0 ..< n))
            #expect(graph.contains(edge: UndirectedEdge(1, 0)) && !graph.contains(edge: UndirectedEdge(0, 0)))
            // Removing the newest copy takes the last position each time: nothing moves.
            var front = graph
            for k in stride(from: n - 1, through: n / 2, by: -1) {
                let removed = graph.remove(edge: UndirectedEdge(0, 1))
                #expect(removed.map { [$0.u, $0.v] } == (k.isMultiple(of: 2) ? [0, 1] : [1, 0]))
            }
            #expect(graph.edgeCount == n / 2)
            #expect(Array(graph.edges(between: 0, and: 1)) == Array(0 ..< n / 2))
            #expect(Array(graph.incidentEdges(of: 0)) == Array(0 ..< n / 2))
            #expect(graph.removeAllEdges(between: 1, and: 0) == n / 2)
            #expect(graph.edgeCount == 0 && graph.vertexCount == 2 && graph.degree(of: 0) == 0)
            // Removing position 0 k times moves the newest remaining copy into 0 each time, so the
            // class is 1, 2, …, n − k − 1, then 0.
            let k = n / 2
            for _ in 0 ..< k { front.remove(edgeAt: 0) }
            #expect(front.edgeCount == n - k)
            #expect(Array(front.edges(between: 0, and: 1)) == Array(1 ..< n - k) + [0])
            #expect(front.degree(of: 1) == n - k)
            let newest = front.remove(edge: UndirectedEdge(1, 0))
            // The newest copy is the one inserted n − k-th, now at position 0; the last position moves in.
            #expect(newest.map { [$0.u, $0.v] } == ((n - k).isMultiple(of: 2) ? [0, 1] : [1, 0]))
            #expect(front.edgeCount == n - k - 1)
            #expect(Array(front.edges(between: 0, and: 1)) == Array(1 ..< n - k - 1) + [0])

            // Directed, with the opposite arcs as a second class.
            var digraph = DirectedPseudograph<Int>()
            for k in 0 ..< n { digraph.insert(edge: k % 3 == 0 ? DirectedEdge(from: 1, to: 0) : DirectedEdge(from: 0, to: 1)) }
            let backward = (0 ..< n).filter { $0 % 3 == 0 }
            #expect(digraph.edgeCount(from: 1, to: 0) == backward.count)
            #expect(digraph.edgeCount(from: 0, to: 1) == n - backward.count)
            #expect(Array(digraph.edges(from: 1, to: 0)) == backward)
            #expect(digraph.outDegree(of: 0) == n - backward.count && digraph.inDegree(of: 0) == backward.count)
            #expect(digraph.degree(of: 1) == n)
            #expect(digraph.removeAllEdges(from: 0, to: 1) == n - backward.count)
            #expect(digraph.edgeCount == backward.count)
            #expect(Set(digraph.edges(from: 1, to: 0)) == Set(0 ..< backward.count))
            #expect(digraph.edges.allSatisfy { $0 == DirectedEdge(from: 1, to: 0) })
            var multigraph = try #require(DirectedMultigraph(digraph))
            #expect(multigraph.remove(1) == 1)
            #expect(multigraph.edgeCount == 0 && Array(multigraph.vertices) == [0])
        }.value
    }

    @Test("A seeded random multigraph on 10⁵ vertices: the reference conformer's rows, class counts, then half the vertices removed", .timeLimit(.minutes(1)))
    func randomMultigraph() async {
        await Task {
            let n = 100_000
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 2026)
            var edges: [UndirectedEdge<Int>] = []
            for _ in 0 ..< 2 * n {
                let u = Int.random(in: 0 ..< n, using: &rng)
                // About one in ten repeats a recent edge; one in fifty is a loop.
                switch Int.random(in: 0 ..< 50, using: &rng) {
                case 0: edges.append(UndirectedEdge(u, u))
                case 1 ... 5 where !edges.isEmpty: edges.append(edges[edges.count - 1 - Int.random(in: 0 ..< min(edges.count, 10), using: &rng)])
                default: edges.append(UndirectedEdge(u, Int.random(in: 0 ..< n, using: &rng)))
                }
            }
            var graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
            let reference = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            #expect(graph.vertexCount == n && graph.edgeCount == edges.count)
            for v in stride(from: 0, to: n, by: 97) {
                #expect(Array(graph.incidentEdges(of: v)) == reference.incidentEdges(of: v))
                #expect(Array(graph.neighbors(of: v)) == reference.neighbors(of: v))
            }
            var counts: [UndirectedEdge<Int>: Int] = [:]
            for e in edges { counts[e, default: 0] += 1 }
            for (e, c) in counts.prefix(2_000) { #expect(graph.edgeCount(between: e.v, and: e.u) == c) }
            #expect(counts.values.reduce(0, +) == graph.edgeCount)
            #expect(graph.vertices.reduce(0) { $0 + graph.degree(of: $1) } == 2 * edges.count)

            // Half the vertices removed, in a shuffled order.
            let removed = Array((0 ..< n).shuffled(using: &rng).prefix(n / 2))
            for v in removed { #expect(graph.remove(v) == v) }
            let gone = Set(removed)
            let kept = edges.filter { !gone.contains($0.u) && !gone.contains($0.v) }
            #expect(graph.vertexCount == n - n / 2)
            #expect(graph.edgeCount == kept.count)
            #expect(Set(graph.vertices) == Set(0 ..< n).subtracting(gone))
            var keptCounts: [UndirectedEdge<Int>: Int] = [:]
            for e in kept { keptCounts[e, default: 0] += 1 }
            var listed: [UndirectedEdge<Int>: Int] = [:]
            for e in graph.edges { listed[e, default: 0] += 1 }
            #expect(listed == keptCounts)
            for (e, c) in keptCounts.prefix(2_000) {
                let copies = Array(graph.edges(between: e.u, and: e.v))
                #expect(copies.count == c)
                #expect(copies.allSatisfy { graph.edges[$0] == e })
            }
            var degreeSum = 0
            for (i, v) in graph.vertices.enumerated() {
                #expect(graph.vertexIndex(of: v) == i)
                degreeSum += graph.degree(of: v)
            }
            #expect(degreeSum == 2 * kept.count)
            #expect(graph == Pseudograph<Int>(vertices: Array(graph.vertices).reversed(), edges: kept))
        }.value
    }

    @Test("A seeded random directed multigraph on 10⁵ vertices: the reference conformer's rows, then half the vertices removed", .timeLimit(.minutes(1)))
    func randomDirectedMultigraph() async {
        await Task {
            let n = 100_000
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1969)
            var arcs: [DirectedEdge<Int>] = []
            for _ in 0 ..< 2 * n {
                let u = Int.random(in: 0 ..< n, using: &rng)
                if Int.random(in: 0 ..< 10, using: &rng) == 0, let recent = arcs.last {
                    arcs.append(Bool.random(using: &rng) ? recent : DirectedEdge(from: recent.target, to: recent.source))
                } else {
                    arcs.append(DirectedEdge(from: u, to: Int.random(in: 0 ..< n, using: &rng)))
                }
            }
            var graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
            let reference = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: arcs)
            for v in stride(from: 0, to: n, by: 101) {
                #expect(Array(graph.outEdges(of: v)) == reference.outEdges(of: v))
                #expect(Array(graph.inEdges(of: v)) == reference.inEdges(of: v))
            }
            let removed = Array((0 ..< n).shuffled(using: &rng).prefix(n / 2))
            for v in removed { graph.remove(v) }
            let gone = Set(removed)
            let kept = arcs.filter { !gone.contains($0.source) && !gone.contains($0.target) }
            #expect(graph.edgeCount == kept.count)
            var outSum = 0, inSum = 0
            for v in graph.vertices {
                outSum += graph.outDegree(of: v)
                inSum += graph.inDegree(of: v)
            }
            #expect(outSum == kept.count && inSum == kept.count)
            #expect(graph == DirectedPseudograph<Int>(vertices: Array(graph.vertices), edges: kept.reversed()))
            if let multigraph = DirectedMultigraph(graph) {
                #expect(!kept.contains { $0.isSelfLoop })
                #expect(multigraph.edgeCount == kept.count)
            } else {
                #expect(kept.contains { $0.isSelfLoop })
            }
        }.value
    }

    @Test("Insert 10⁵ edges, then remove them all: by edge in a shuffled order, by pair, and by vertex", .timeLimit(.minutes(1)))
    func insertThenRemoveAll() async {
        await Task {
            let n = 100_000
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 7)
            let edges = (0 ..< n).map { _ in UndirectedEdge(Int.random(in: 0 ..< 300, using: &rng), Int.random(in: 0 ..< 300, using: &rng)) }
            var graph = Pseudograph<Int>()
            for (k, e) in edges.enumerated() { #expect(graph.insert(edge: e) == k) }
            let full = graph
            // By edge: each removal takes one copy.
            for e in edges.shuffled(using: &rng) { #expect(graph.remove(edge: UndirectedEdge(e.v, e.u)) == e) }
            #expect(graph.edgeCount == 0)
            #expect(graph.vertexCount == full.vertexCount)
            #expect(graph.vertices.allSatisfy { graph.degree(of: $0) == 0 })
            #expect(graph.remove(edge: edges[0]) == nil)
            // By pair.
            graph = full
            let pairs = Set(edges)
            var removedCount = 0
            for e in pairs.shuffled(using: &rng) { removedCount += graph.removeAllEdges(between: e.u, and: e.v) }
            #expect(removedCount == n && graph.edgeCount == 0)
            #expect(graph == Pseudograph<Int>(vertices: full.vertices))
            // By vertex.
            graph = full
            for v in Array(full.vertices).shuffled(using: &rng) { #expect(graph.remove(v) == v) }
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
            // By position from the front, on the directed type.
            var digraph = DirectedPseudograph<Int>(edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) })
            while digraph.edgeCount > 0 { digraph.remove(edgeAt: 0) }
            #expect(digraph.vertices.allSatisfy { digraph.outDegree(of: $0) == 0 && digraph.inDegree(of: $0) == 0 })
            #expect(full.edgeCount == n)
        }.value
    }
}
