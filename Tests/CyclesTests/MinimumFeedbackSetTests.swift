// minimumFeedbackArcSet(), minimumFeedbackArcSet(weight:) and minimumFeedbackVertexSet(): exact
// minimum sets whose removal leaves no directed cycle, or a forest in the undirected case, checked
// against the heuristic's size, against brute force over orderings and subsets on random
// multigraphs, and on several representations. Removal leaving an acyclic graph is checked by
// Kahn's algorithm, or union–find, inside each test.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

@Suite("minimum feedback sets")
struct MinimumFeedbackSetTests {
    @Test("Two triangles sharing an arc: one arc and one vertex suffice, the shared ones")
    func sharedArc() {
        // 0 → 1 → 2 → 0 and 0 → 1 → 3 → 0: every cycle uses 0 → 1.
        let arcs = [(0, 1), (1, 2), (2, 0), (1, 3), (3, 0)]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            #expect(g.minimumFeedbackArcSet().map { g.edges[$0] } == [DirectedEdge(from: 0, to: 1)])
            // 0 → 1 weighs 10, the arcs out of 1 weigh 1, the arcs into 0 weigh 2.
            let heavy = g.minimumFeedbackArcSet(weight: { g.edges[$0].source == 0 ? 10 : (g.edges[$0].source == 1 ? 1 : 2) })
            #expect(heavy.map { g.edges[$0] } == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3)])
            #expect(g.minimumFeedbackVertexSet() == [0])
            #expect(g.feedbackArcSet().count >= g.minimumFeedbackArcSet().count)
        }
        check(ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }))
        check(AdjacencyList(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }))
        check(CompressedSparseRow(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }))
        check(AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }))
    }

    @Test("Self-loops and parallel arcs: every loop is in the arc set, a looped vertex in the vertex set, parallel arcs count one each")
    func loopsAndParallels() {
        // 0 ⇄ 1 twice each way, a loop at 2, and 2 → 3.
        let arcs = [(0, 1), (1, 0), (0, 1), (1, 0), (2, 2), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let set = graph.minimumFeedbackArcSet()
        #expect(set.count == 3 && set.contains(4))
        #expect(set == [1, 3, 4] || set == [0, 2, 4])
        #expect(graph.minimumFeedbackVertexSet() == [0, 2])
        let pseudograph = DirectedPseudograph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(pseudograph.minimumFeedbackArcSet().count == 3)
        #expect(pseudograph.minimumFeedbackVertexSet() == [0, 2])
    }

    @Test("Acyclic and empty graphs give empty sets; a lone loop gives its vertex and its edge")
    func trivial() {
        let dag = AdjacencyList(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "c")])
        #expect(dag.minimumFeedbackArcSet().isEmpty && dag.minimumFeedbackVertexSet().isEmpty)
        let empty = AdjacencyList<Int>()
        #expect(empty.minimumFeedbackArcSet().isEmpty && empty.minimumFeedbackVertexSet().isEmpty)
        let loop = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 7, to: 7)])
        #expect(loop.minimumFeedbackArcSet() == [0] && loop.minimumFeedbackVertexSet() == [7])
        let forest = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(forest.minimumFeedbackVertexSet().isEmpty)
    }

    @Test("Ties go to the set that lists first in vertices order: a 4-cycle removes vertex 0")
    func tieOrder() {
        let cycle = AdjacencyList(vertices: [3, 1, 2, 0], edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3)])
        #expect(cycle.minimumFeedbackVertexSet() == [3])
        let ring = UndirectedAdjacencyList(vertices: ["d", "a", "c", "b"], edges: [UndirectedEdge("d", "a"), UndirectedEdge("a", "c"), UndirectedEdge("c", "b"), UndirectedEdge("b", "d")])
        #expect(ring.minimumFeedbackVertexSet() == ["d"])
        // Four 2-cycles around 0 – 1 – 3 – 2 – 0: {0, 3} and {1, 2} both hit every cycle, and [0, 3] lists first.
        let pairs = [(0, 1), (1, 3), (3, 2), (2, 0)]
        let bidirected = AdjacencyList(vertices: 0 ..< 4, edges: pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] })
        #expect(bidirected.minimumFeedbackVertexSet() == [0, 3])
        let doubled = Pseudograph(vertices: 0 ..< 4, edges: pairs.flatMap { [UndirectedEdge($0.0, $0.1), UndirectedEdge($0.0, $0.1)] })
        #expect(doubled.minimumFeedbackVertexSet() == [0, 3])
    }

    @Test("Undirected: a loop, a double edge and a triangle each need one vertex; K4 needs two")
    func undirected() {
        let pseudograph = Pseudograph(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3), UndirectedEdge(5, 6)])
        #expect(pseudograph.minimumFeedbackVertexSet() == [0, 1, 3])
        let k4 = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(k4.minimumFeedbackVertexSet() == [0, 1])
        var stable = StableUndirectedGraph<Int>()
        for v in 0 ..< 5 { _ = stable.insert(v) }
        for edge in k4.edges { _ = stable.insert(edge: edge) }
        _ = stable.remove(4)
        #expect(stable.minimumFeedbackVertexSet() == [0, 1])
    }

    @Test("Random directed multigraphs: sizes match brute force over orderings and subsets, the sets are valid, weights are honoured")
    func randomDirected() async {
        let arcs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 14)
        let weights = Gen.int(in: 1 ... 4).array(of: 14 ... 14)
        await propertyCheck(count: 300, input: arcs, weights) { arcs, weights in
            let n = 6
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let context = "arcs \(arcs)"
            // Brute force over every ordering: the cheapest set of leftward arcs, with every loop.
            func backwardCost(_ order: [Int], _ cost: (Int) -> Double) -> Double {
                var rank = [Int](repeating: 0, count: n)
                for (k, v) in order.enumerated() { rank[v] = k }
                return arcs.indices.filter { rank[arcs[$0].1] <= rank[arcs[$0].0] }.reduce(0.0) { $0 + cost($1) }
            }
            var orders: [[Int]] = []
            func permute(_ prefix: [Int], _ rest: [Int]) {
                if rest.isEmpty { orders.append(prefix); return }
                for (i, v) in rest.enumerated() { permute(prefix + [v], Array(rest[..<i] + rest[(i + 1)...])) }
            }
            permute([], Array(0 ..< n))
            let unweighted = graph.minimumFeedbackArcSet()
            #expect(Double(unweighted.count) == orders.map { backwardCost($0) { _ in 1 } }.min()!, "\(context)")
            let weighted = graph.minimumFeedbackArcSet(weight: { Double(weights[$0]) })
            #expect(weighted.reduce(0.0) { $0 + Double(weights[$1]) } == orders.map { backwardCost($0) { Double(weights[$0]) } }.min()!, "\(context)")
            #expect(unweighted.count <= graph.feedbackArcSet().count, "\(context)")
            for set in [unweighted, weighted] {
                #expect(set == set.sorted() && Set(set).count == set.count, "\(context)")
                #expect(arcs.indices.filter { arcs[$0].0 == arcs[$0].1 }.allSatisfy(set.contains), "\(context)")
                #expect(isAcyclic(arcs.indices.filter { !set.contains($0) }.map { arcs[$0] }, n), "\(context) \(set)")
            }
            // Brute force over every vertex subset: the smallest whose removal leaves no cycle.
            let vertexSet = graph.minimumFeedbackVertexSet()
            var smallest = n
            for mask in 0 ..< 1 << n {
                let removed = (0 ..< n).filter { mask >> $0 & 1 == 1 }
                let kept = arcs.filter { !removed.contains($0.0) && !removed.contains($0.1) }
                if isAcyclic(kept, n) { smallest = min(smallest, removed.count) }
            }
            #expect(vertexSet.count == smallest && vertexSet == vertexSet.sorted(), "\(context)")
            #expect(isAcyclic(arcs.filter { !vertexSet.contains($0.0) && !vertexSet.contains($0.1) }, n), "\(context) \(vertexSet)")
        }
    }

    @Test("Random undirected multigraphs: the vertex set's size matches brute force over subsets, and removal leaves a forest")
    func randomUndirected() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges) { edges in
            let n = 6
            let graph = Pseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let set = graph.minimumFeedbackVertexSet()
            func isForest(_ kept: [(Int, Int)]) -> Bool {
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for (a, b) in kept {
                    let ra = find(a), rb = find(b)
                    if ra == rb { return false }
                    parent[ra] = rb
                }
                return true
            }
            var smallest = n
            for mask in 0 ..< 1 << n {
                let removed = (0 ..< n).filter { mask >> $0 & 1 == 1 }
                if isForest(edges.filter { !removed.contains($0.0) && !removed.contains($0.1) }) { smallest = min(smallest, removed.count) }
            }
            #expect(set.count == smallest && set == set.sorted(), "edges \(edges)")
            #expect(isForest(edges.filter { !set.contains($0.0) && !set.contains($0.1) }), "edges \(edges) \(set)")
        }
    }

    @Test("Preconditions: a negative or infinite weight traps; too many vertices for the table trap")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]).minimumFeedbackArcSet(weight: { _ in -1 })
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]).minimumFeedbackArcSet(weight: { _ in .infinity })
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(vertices: 0 ..< 30, edges: [DirectedEdge<Int>]()).minimumFeedbackArcSet()
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(vertices: 0 ..< 33, edges: [DirectedEdge<Int>]()).minimumFeedbackVertexSet()
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(vertices: 0 ..< 33, edges: [UndirectedEdge<Int>]()).minimumFeedbackVertexSet()
        }
        // Within the limits: 28 vertices for the arc set would be a 2.4 GB table, so 20 here.
        #expect(AdjacencyList(vertices: 0 ..< 20, edges: [DirectedEdge<Int>]()).minimumFeedbackArcSet().isEmpty)
        #expect(AdjacencyList(vertices: 0 ..< 20, edges: [DirectedEdge<Int>]()).minimumFeedbackVertexSet().isEmpty)
    }
}

/// Kahn's algorithm: whether `arcs` on `n` vertices have no directed cycle.
private func isAcyclic(_ arcs: [(Int, Int)], _ n: Int) -> Bool {
    var indegree = [Int](repeating: 0, count: n)
    for (_, b) in arcs { indegree[b] += 1 }
    var ready = (0 ..< n).filter { indegree[$0] == 0 }
    var removed = 0
    while let v = ready.popLast() {
        removed += 1
        for (a, b) in arcs where a == v {
            indegree[b] -= 1
            if indegree[b] == 0 { ready.append(b) }
        }
    }
    return removed == n
}
