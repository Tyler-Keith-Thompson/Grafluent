// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in a
// debug build; the benchmarks take timings. Every expected value is known by construction or is the
// base's own result through the labels: a CSR on 10⁵ String labels and 4 × 10⁵ edges (BFS, weak and
// strong components, topological order, Dijkstra), a matrix grown one label at a time to 2 048
// labels with 10⁵ edge insertions and removals against a set, and a CSR of 2 × 10⁴ counted labels
// whose topological sort and components hash no label. See README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import ShortestPaths
import Testing
import Traversal

@Suite("LabeledGraphs at scale")
struct LabeledGraphStressTests {
    @Test("CSR over 10⁵ String labels: algorithms equal the base's through the labels", .timeLimit(.minutes(1)))
    func csrAtScale() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 7)
            // A forward DAG: i → i + 1 and three random forward edges per vertex.
            var edges: [DirectedEdge<String>] = []
            edges.reserveCapacity(4 * n)
            for i in 0 ..< n - 1 {
                edges.append(DirectedEdge(from: "v\(i)", to: "v\(i + 1)"))
                for _ in 0 ..< 3 { edges.append(DirectedEdge(from: "v\(i)", to: "v\(Int.random(in: i + 1 ..< n, using: &rng))")) }
            }
            let graph = LabeledGraph<String, CompressedSparseRow>(edges: edges)
            let base = graph.base
            let labels = Array(graph.vertices)
            #expect(graph.vertexCount == n && labels[0] == "v0" && labels[1] == "v1")
            #expect(graph.edgeCount == base.edgeCount && graph.edgeIndexBound == base.edgeCount)
            #expect(graph.topologicalSort() == base.topologicalSort()?.map { labels[$0] })
            #expect(graph.weaklyConnectedComponents().count == 1)
            #expect(graph.stronglyConnectedComponents().count == n)
            let discovered = graph.lazy.breadthFirstSearch(from: "v0").compactMap { event -> String? in
                if case .discover(let v) = event { return v }
                return nil
            }
            let baseDiscovered = base.lazy.breadthFirstSearch(from: 0).compactMap { event -> Int? in
                if case .discover(let v) = event { return v }
                return nil
            }
            #expect(discovered == baseDiscovered.map { labels[$0] } && discovered.count == n)
            let weight = (0 ..< graph.edgeCount).map { $0 % 7 + 1 }
            let tree = graph.dijkstraShortestPaths(from: "v0") { weight[$0] }
            let baseTree = base.dijkstraShortestPaths(from: 0) { weight[$0] }
            for k in stride(from: 0, to: n, by: 997) {
                #expect(tree.distance(to: labels[k]) == baseTree.distance(to: k))
                #expect(tree.parentEdge(of: labels[k]) == baseTree.parentEdge(of: k))
            }
            #expect(graph.descendants(of: "v\(n - 2)") == ["v\(n - 1)"])
        }.value
    }

    @Test("A matrix grown label by label to 2 048, with 10⁵ edge insertions and removals against a set", .timeLimit(.minutes(1)))
    func matrixChurn() async {
        await Task {
            let n = 2_048
            var rng = SeededRandomNumberGenerator(seed: 11)
            var graph = LabeledGraph<Int, AdjacencyMatrix>()
            graph.reserveCapacity(vertexCount: n)
            // Labels are a permutation, so label and index differ.
            let order = Array(0 ..< n).shuffled(using: &rng)
            for (k, l) in order.enumerated() {
                #expect(graph.insert(l).inserted)
                if k.isMultiple(of: 256) { #expect(graph.vertexIndex(of: l) == k) }
            }
            var arcs = Set<[Int]>()
            for _ in 0 ..< 100_000 {
                let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
                if Bool.random(using: &rng) {
                    #expect(graph.insert(edge: DirectedEdge(from: a, to: b)).inserted == arcs.insert([a, b]).inserted)
                } else {
                    #expect((graph.remove(edge: DirectedEdge(from: a, to: b)) != nil) == (arcs.remove([a, b]) != nil))
                }
            }
            #expect(graph.vertexCount == n && graph.edgeCount == arcs.count)
            #expect(Set(graph.edges.map { [$0.source, $0.target] }) == arcs)
            for k in stride(from: 0, to: n, by: 61) {
                let l = order[k]
                #expect(graph.vertexIndex(of: l) == k && graph.vertex(atIndex: k) == l)
                #expect(Set(graph.successors(of: l)) == Set(arcs.filter { $0[0] == l }.map { $0[1] }))
                #expect(graph.inDegree(of: l) == arcs.filter { $0[1] == l }.count)
            }
            graph.removeAllEdges()
            #expect(graph.edgeCount == 0 && graph.vertexCount == n && graph.vertexIndex(of: order[n - 1]) == n - 1)
        }.value
    }

    @Test("2 × 10⁴ counted labels: whole-graph algorithms hash no label", .timeLimit(.minutes(1)))
    func countedAtScale() async {
        await Task {
            final class Tally: @unchecked Sendable {
                var hashes = 0
            }
            struct Counted: Hashable, @unchecked Sendable {
                let name: Int
                let tally: Tally
                static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
                func hash(into hasher: inout Hasher) {
                    tally.hashes += 1
                    hasher.combine(name)
                }
            }
            let tally = Tally()
            let n = 20_000
            let edges = (0 ..< n - 1).flatMap { i in
                [DirectedEdge(from: Counted(name: i, tally: tally), to: Counted(name: i + 1, tally: tally)),
                 DirectedEdge(from: Counted(name: i, tally: tally), to: Counted(name: min(n - 1, i * 2 + 1), tally: tally))]
            }
            let graph = LabeledGraph<Counted, CompressedSparseRow>(edges: edges)
            tally.hashes = 0
            let order = graph.topologicalSort()
            let weak = graph.weaklyConnectedComponents()
            let strong = graph.stronglyConnectedComponents()
            #expect(tally.hashes == 0)
            #expect(order?.count == n && weak.count == 1 && strong.count == n)
            tally.hashes = 0
            let layers = graph.breadthFirstLayers(from: Counted(name: 0, tally: tally))
            #expect(tally.hashes <= 4)
            #expect(layers.joined().count == n)
        }.value
    }
}
