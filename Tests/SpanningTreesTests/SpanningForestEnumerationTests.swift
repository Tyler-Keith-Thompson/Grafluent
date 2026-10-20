// spanningForests(weight:) and spanningForests(): every spanning forest in nondecreasing weight,
// the first the minimum one, checked against brute force over edge subsets on small graphs,
// against Cayley's count on complete graphs, with parallel edges, self-loops, disconnected graphs
// and several representations. Each forest is checked to be one with union–find inside the test.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import SpanningTrees
import StableGraphs
import Testing

@Suite("spanning forest enumeration")
struct SpanningForestEnumerationTests {
    @Test("A triangle has three spanning trees, lightest first; the first is the minimum spanning tree")
    func triangle() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
        let weights = [3.0, 1.0, 2.0]
        let forests = Array(graph.spanningForests(weight: { weights[$0] }))
        #expect(forests.map(\.weight) == [3.0, 4.0, 5.0])
        #expect(forests.map(\.edges) == [[1, 2], [1, 0], [2, 0]])
        #expect(forests[0] == graph.minimumSpanningTree(weight: { weights[$0] }))
        #expect(Array(graph.spanningForests().map(\.weight)) == [2, 2, 2])
        #expect(Array(graph.spanningForests(weight: { weights[$0] }).prefix(2)).count == 2)
    }

    @Test("Complete graphs have nⁿ⁻² spanning trees (Cayley), each with n − 1 edges")
    func cayley() {
        for n in 1 ... 6 {
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< n { for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let forests = Array(graph.spanningForests())
            let expected = n <= 2 ? 1 : (0 ..< n - 2).reduce(1) { x, _ in x * n }
            #expect(forests.count == expected, "n \(n)")
            #expect(forests.allSatisfy { $0.edges.count == n - 1 && $0.weight == n - 1 }, "n \(n)")
            #expect(Set(forests.map { $0.edges.sorted() }).count == forests.count, "n \(n): a forest listed twice")
        }
    }

    @Test("Parallel edges give distinct forests; a self-loop is never in one; a disconnected graph lists forests")
    func multigraphAndForests() {
        // 0 = 1 (two parallel edges) – 2, a loop at 2, and the separate edge 3 – 4.
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(3, 4)]
        let graph = Pseudograph(vertices: 0 ..< 5, edges: edges)
        let weights = [2, 1, 1, 100, 5]
        let forests = Array(graph.spanningForests(weight: { weights[$0] }))
        #expect(forests.map(\.weight) == [7, 8])
        #expect(forests.map { $0.edges.sorted() } == [[1, 2, 4], [0, 2, 4]])
        #expect(forests.allSatisfy { !$0.edges.contains(3) })
        // The stable graph with a hole lists the same forests by its own positions.
        var stable = StableUndirectedGraph<Int>()
        for v in 0 ..< 6 { _ = stable.insert(v) }
        for edge in edges { _ = stable.insert(edge: edge) }
        _ = stable.remove(5)
        let stableForests = Array(stable.spanningForests(weight: { weights[$0] }))
        #expect(stableForests.map(\.weight) == [7, 8] && stableForests.map { $0.edges.sorted() } == [[1, 2, 4], [0, 2, 4]])
    }

    @Test("Trivial graphs: no vertices, one vertex and no edges each list one empty forest")
    func trivial() {
        #expect(Array(UndirectedAdjacencyList<Int>().spanningForests()).map(\.edges) == [[]])
        #expect(Array(UndirectedAdjacencyList(vertices: [7], edges: [UndirectedEdge<Int>]()).spanningForests()).map(\.weight) == [0])
        let three = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge<Int>]())
        #expect(Array(three.spanningForests(weight: { _ in 1.5 })).map(\.edges) == [[]])
    }

    @Test("Random multigraphs: the forests are exactly the acyclic edge sets of size n − c, in nondecreasing weight, on three representations", arguments: [3, 4, 5, 6])
    func bruteForce(n: Int) async {
        let edges = zip(Gen.int(in: 0 ..< n), Gen.int(in: 0 ..< n)).array(of: 0 ... 9)
        let weights = Gen.int(in: 1 ... 5).array(of: 9 ... 9)
        await propertyCheck(count: 120, input: edges, weights) { edges, weights in
            let graph = Pseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let context = "edges \(edges) weights \(weights)"
            // Union–find over an edge subset: acyclic, and how many components it leaves.
            func components(_ chosen: [Int]) -> Int? {
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                var count = n
                for k in chosen {
                    let a = find(edges[k].0), b = find(edges[k].1)
                    if a == b { return nil }
                    parent[a] = b
                    count -= 1
                }
                return count
            }
            var allComponents = n
            do {
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for (a, b) in edges where find(a) != find(b) {
                    parent[find(a)] = find(b)
                    allComponents -= 1
                }
            }
            let size = n - allComponents
            var expected: [(edges: [Int], weight: Int)] = []
            for mask in 0 ..< 1 << edges.count where mask.nonzeroBitCount == size {
                let chosen = edges.indices.filter { mask >> $0 & 1 == 1 }
                if components(chosen) == allComponents { expected.append((chosen, chosen.reduce(0) { $0 + weights[$1] })) }
            }
            let forests = Array(graph.spanningForests(weight: { weights[$0] }))
            #expect(forests.count == expected.count, "\(context)")
            #expect(forests.map(\.weight) == forests.map(\.weight).sorted(), "\(context)")
            #expect(Set(forests.map { $0.edges.sorted() }) == Set(expected.map(\.edges)), "\(context)")
            #expect(forests.allSatisfy { $0.weight == $0.edges.reduce(0) { $0 + weights[$1] } }, "\(context)")
            // Each forest lists its edges by nondecreasing (weight, position).
            #expect(forests.allSatisfy { f in f.edges == f.edges.sorted { (weights[$0], $0) < (weights[$1], $1) } }, "\(context)")
            #expect(forests.first == graph.minimumSpanningTree(weight: { weights[$0] }), "\(context)")
            // The simple graph on the cheapest copy of each pair.
            var cheapest: [UndirectedEdge<Int>: Int] = [:]
            for (k, (a, b)) in edges.enumerated() where a != b {
                let key = UndirectedEdge(a, b)
                if let other = cheapest[key], weights[other] <= weights[k] { continue }
                cheapest[key] = k
            }
            let simpleEdges = cheapest.values.sorted().map { UndirectedEdge(edges[$0].0, edges[$0].1) }
            let simple = UndirectedAdjacencyList(vertices: 0 ..< n, edges: simpleEdges)
            let simpleWeights = simple.edges.map { weights[cheapest[$0]!] }
            let simpleForests = Array(simple.spanningForests(weight: { simpleWeights[$0] }))
            let simpleExpected = expected.filter { $0.edges.allSatisfy { k in edges[k].0 != edges[k].1 && cheapest[UndirectedEdge(edges[k].0, edges[k].1)] == k } }
            #expect(simpleForests.count == simpleExpected.count && simpleForests.map(\.weight) == simpleExpected.map(\.weight).sorted(), "\(context)")
        }
    }
}
