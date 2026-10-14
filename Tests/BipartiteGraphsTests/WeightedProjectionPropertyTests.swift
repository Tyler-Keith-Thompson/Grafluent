// The weighted projections of random bipartite graphs, after random vertex and edge removals,
// against the definitions written out over neighbour sets: shared-neighbour counts exactly; the
// Jaccard and lesser-degree overlaps and Newman's collaboration sums within 1e-12. Each graph is
// `projectedGraph(onto:)`'s at the same positions, and the weight map stays in step when the
// projection is mutated. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import PropertyBased
import Testing

@Suite("Weighted projections against their definitions, with shrinking", .tags(.randomized))
struct WeightedProjectionPropertyTests {
    @Test("Every weighted projection is projectedGraph(onto:)'s graph with its definition's weights")
    func weightsAgainstDefinitions() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 7).array(of: 0 ... 3), Gen.bool) { raw, removals, ontoLeft in
            let left = (0 ..< 6).map { "l\($0)" }, right = (0 ..< 6).map { "r\($0)" }
            var graph = BipartiteGraph<String>(left: left, right: right, edges: raw.map { UndirectedEdge(left[$0.0], right[$0.1]) })!
            // Removals swap-move slots, so side order differs from insertion order.
            for k in removals {
                if k < 6 { graph.remove(k % 2 == 0 ? left[k] : right[k]) } else if let edge = graph.edges.first { graph.remove(edge: edge) }
            }
            let side: BipartiteSide = ontoLeft ? .left : .right
            let plain = graph.projectedGraph(onto: side)
            let count = graph.weightedProjectedGraph(onto: side)
            let jaccard = graph.overlapWeightedProjectedGraph(onto: side)
            let lesser = graph.overlapWeightedProjectedGraph(onto: side, jaccard: false)
            let collaboration = graph.collaborationWeightedProjectedGraph(onto: side)
            let context = "\(raw) \(removals) \(side)"
            for projection in [jaccard.graph, lesser.graph, collaboration.graph, count.graph] {
                #expect(Array(projection.vertices) == Array(plain.vertices), "\(context)")
                #expect(projection.edges.map { [$0.u, $0.v] } == plain.edges.map { [$0.u, $0.v] }, "\(context)")
            }
            func nbrs(_ v: String) -> Set<String> { Set(graph.neighbors(of: v)) }
            for (p, edge) in plain.edges.enumerated() {
                let a = nbrs(edge.u), b = nbrs(edge.v)
                let shared = a.intersection(b)
                #expect(count.graph[count.weights, ofEdgeAt: p] == shared.count, "\(context) \(edge)")
                let wantJaccard = Double(shared.count) / Double(a.union(b).count)
                #expect(abs(jaccard.graph[jaccard.weights, ofEdgeAt: p] - wantJaccard) <= 1e-12, "\(context) \(edge)")
                let wantLesser = Double(shared.count) / Double(min(a.count, b.count))
                #expect(abs(lesser.graph[lesser.weights, ofEdgeAt: p] - wantLesser) <= 1e-12, "\(context) \(edge)")
                let wantSum = shared.reduce(0.0) { $0 + 1 / Double(graph.degree(of: $1) - 1) }
                #expect(abs(collaboration.graph[collaboration.weights, ofEdgeAt: p] - wantSum) <= 1e-12, "\(context) \(edge)")
                #expect(shared.count >= 1, "\(context) \(edge)")
            }
        }
    }

    @Test("The weight map is the projection's own: it follows a swap-remove of an edge")
    func mapFollowsMutation() throws {
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2], right: [3, 4, 5, 6],
                                                     edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge($0.0, $0.1) }))
        var projection = graph.weightedProjectedGraph(onto: .right)
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [2, 1, 1, 1, 1, 1])
        // Removing 3–4 moves the last edge, 5–6, into position 0, with its weight.
        projection.graph.remove(edge: UndirectedEdge(3, 4))
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[5, 6], [3, 5], [3, 6], [4, 5], [4, 6]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1, 1, 1, 1, 1])
        // An algorithm reads the weights through a closure over positions.
        let total = projection.graph.edges.indices.reduce(0) { $0 + projection.graph[projection.weights, ofEdgeAt: $1] }
        #expect(total == 5)
    }
}
