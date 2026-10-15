// The Bron–Kerbosch algorithm with pivoting as an event sequence (`lazy.bronKerbosch()`): a
// hand-traced graph against Tests/Catalogs/Cliques/cases_events.py, the trivial cases, value
// semantics, and a property test replaying the events against `maximalCliques()` and a recursive
// model written here. Case IDs (CQ-11nn) are listed in README.md.

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Bron–Kerbosch events")
struct BronKerboschEventsTests {
    @Test("CQ-1100 two triangles sharing an edge, a path, a loop, an isolated vertex: every event in order", .tags(.fixture, .selfLoops))
    func handTraced() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        // The outer order cases_events.py takes as given.
        #expect(graph.coreNumbers().degeneracyOrdering == [6, 5, 4, 0, 3, 1, 2])
        // Tests/Catalogs/Cliques/cases_events.out, CQ-1100.
        let expected: [BronKerboschEvent<Int>] = [
            .call(adding: 6, clique: [6], candidates: [], excluded: []), .maximalClique([6]), .backtrack,
            .call(adding: 5, clique: [5], candidates: [4], excluded: []), .pivot(4),
            .call(adding: 4, clique: [4, 5], candidates: [], excluded: []), .maximalClique([4, 5]), .backtrack, .backtrack,
            .call(adding: 4, clique: [4], candidates: [3], excluded: [5]), .pivot(3),
            .call(adding: 3, clique: [3, 4], candidates: [], excluded: []), .maximalClique([3, 4]), .backtrack, .backtrack,
            .call(adding: 0, clique: [0], candidates: [1, 2], excluded: []), .pivot(1),
            .call(adding: 1, clique: [0, 1], candidates: [2], excluded: []), .pivot(2),
            .call(adding: 2, clique: [0, 1, 2], candidates: [], excluded: []), .maximalClique([0, 1, 2]), .backtrack, .backtrack, .backtrack,
            .call(adding: 3, clique: [3], candidates: [1, 2], excluded: [4]), .pivot(1),
            .call(adding: 1, clique: [1, 3], candidates: [2], excluded: []), .pivot(2),
            .call(adding: 2, clique: [1, 2, 3], candidates: [], excluded: []), .maximalClique([1, 2, 3]), .backtrack, .backtrack, .backtrack,
            // 1's only later neighbor is 2, adjacent to the pivot 0: no branch.
            .call(adding: 1, clique: [1], candidates: [2], excluded: [0, 3]), .pivot(0), .backtrack,
            .call(adding: 2, clique: [2], candidates: [], excluded: [0, 1, 3]), .backtrack,
        ]
        let events = Array(graph.lazy.bronKerbosch())
        #expect(events == expected)
        // R, rebuilt from the nesting, is each reported clique.
        var r: [Int] = []
        for event in events {
            switch event {
            case .call(let v, let clique, _, _):
                r.append(v)
                #expect(clique == r.sorted())
            case .maximalClique(let c): #expect(c == r.sorted())
            case .backtrack: r.removeLast()
            case .pivot: break
            }
        }
        #expect(r.isEmpty)
        let cliques = events.compactMap { event -> [Int]? in if case .maximalClique(let c) = event { c } else { nil } }
        #expect(cliques == Array(graph.maximalCliques()))
        let list = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(list.lazy.bronKerbosch()) == expected)
        #expect(expected[0].description == "call(+6, [6], [], [])" && expected[1].description == "maximalClique([6])")
        #expect(expected[2].description == "backtrack" && expected[4].description == "pivot(4)")
        #expect(Set(expected).count < expected.count)
    }

    @Test("CQ-1101 no vertices: no events; String vertices; a later insertion does not change the events; each iterator starts over; stopping early")
    func trivialAndValueSemantics() {
        #expect(Array(UndirectedAdjacencyList<Int>(vertices: []).lazy.bronKerbosch()).isEmpty)
        var graph = UndirectedAdjacencyList(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
        let events = graph.lazy.bronKerbosch()
        _ = graph.insert(edge: UndirectedEdge("b", "c"))
        let first = Array(events)
        let cliques = first.compactMap { event -> [String]? in if case .maximalClique(let c) = event { c } else { nil } }
        #expect(Set(cliques) == [["a", "b"], ["c"]])
        #expect(Array(events) == first)
        #expect(Array(events.prefix(2)) == Array(first.prefix(2)))
        var iterator = events.makeIterator()
        for _ in first { _ = iterator.next() }
        #expect(iterator.next() == nil)
        #expect(iterator.next() == nil)
    }

    @Test("CQ-1102 seeded dense graphs, 14 vertices at p = 0.5: the events of a recursive Bron–Kerbosch with Tomita's pivot, X merging tried candidates with the outer call's excluded vertices", .tags(.randomized))
    func dense() {
        var rng = SeededRandomNumberGenerator(seed: 1102)
        for _ in 0 ..< 40 {
            var pairs: [(Int, Int)] = []
            for u in 0 ..< 14 {
                for v in u + 1 ..< 14 where Double.random(in: 0 ..< 1, using: &rng) < 0.5 { pairs.append((u, v)) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 14, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var neighbors = [Set<Int>](repeating: [], count: 14)
            for (u, v) in pairs {
                neighbors[u].insert(v)
                neighbors[v].insert(u)
            }
            let order = graph.coreNumbers().degeneracyOrdering
            var rank = [Int](repeating: 0, count: 14)
            for (i, v) in order.enumerated() { rank[v] = i }
            var expected: [BronKerboschEvent<Int>] = []
            func call(_ r: [Int], _ p: Set<Int>, _ x: Set<Int>) {
                expected.append(.call(adding: r.last!, clique: r.sorted(), candidates: p.sorted(), excluded: x.sorted()))
                guard !p.isEmpty else {
                    if x.isEmpty { expected.append(.maximalClique(r.sorted())) }
                    expected.append(.backtrack)
                    return
                }
                let pivot = (p.sorted() + x.sorted()).min { a, b in
                    let (sa, sb) = (p.intersection(neighbors[a]).count, p.intersection(neighbors[b]).count)
                    return sa > sb || (sa == sb && a < b)
                }!
                expected.append(.pivot(pivot))
                var p = p, x = x
                for w in p.subtracting(neighbors[pivot]).sorted() {
                    call(r + [w], p.intersection(neighbors[w]), x.intersection(neighbors[w]))
                    p.remove(w)
                    x.insert(w)
                }
                expected.append(.backtrack)
            }
            for v in order {
                call([v], neighbors[v].filter { rank[$0] > rank[v] }, neighbors[v].filter { rank[$0] < rank[v] })
            }
            #expect(Array(graph.lazy.bronKerbosch()) == expected)
        }
    }

    @Test("CQ-1102 property (PropertyBased): the events of a recursive Bron–Kerbosch with Tomita's pivot over the degeneracy ordering; the cliques are maximalCliques()", .tags(.randomized))
    func property() async {
        // Up to 30 edges on vertices 0..<9; repeats and self-loops allowed.
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges) { raw in
            let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var neighbors = [Set<Int>](repeating: [], count: 9)
            for (u, v) in raw where u != v {
                neighbors[u].insert(v)
                neighbors[v].insert(u)
            }
            let order = graph.coreNumbers().degeneracyOrdering
            var rank = [Int](repeating: 0, count: 9)
            for (i, v) in order.enumerated() { rank[v] = i }
            var expected: [BronKerboschEvent<Int>] = []
            func call(_ r: [Int], _ p: Set<Int>, _ x: Set<Int>) {
                expected.append(.call(adding: r.last!, clique: r.sorted(), candidates: p.sorted(), excluded: x.sorted()))
                guard !p.isEmpty else {
                    if x.isEmpty { expected.append(.maximalClique(r.sorted())) }
                    expected.append(.backtrack)
                    return
                }
                let pivot = (p.sorted() + x.sorted()).min { a, b in
                    let (sa, sb) = (p.intersection(neighbors[a]).count, p.intersection(neighbors[b]).count)
                    return sa > sb || (sa == sb && a < b)
                }!
                expected.append(.pivot(pivot))
                var p = p, x = x
                for w in p.subtracting(neighbors[pivot]).sorted() {
                    call(r + [w], p.intersection(neighbors[w]), x.intersection(neighbors[w]))
                    p.remove(w)
                    x.insert(w)
                }
                expected.append(.backtrack)
            }
            for v in order {
                call([v], neighbors[v].filter { rank[$0] > rank[v] }, neighbors[v].filter { rank[$0] < rank[v] })
            }
            let events = Array(graph.lazy.bronKerbosch())
            #expect(events == expected)
            let cliques = events.compactMap { event -> [Int]? in if case .maximalClique(let c) = event { c } else { nil } }
            #expect(cliques == Array(graph.maximalCliques()))
        }
    }
}
