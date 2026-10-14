// Kernighan–Lin bisection: hand-computed cases and NetworkX 3.7's kernighan_lin_bisection with the
// same starting partition (its single-vertex alternating moves and heap ties, which the library
// follows), degenerate graphs, weights, parallel edges and self-loops, the random start, and a
// property test: the halves keep the starting sizes and never cut more than the start.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Kernighan–Lin bisection")
struct KernighanLinTests {
    @Test("Two triangles joined by an edge, from {0, 3, 4} and {1, 2, 5}: the triangles (NetworkX agrees)")
    func twoTriangles() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]])
        #expect(result.map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        let list = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(list.kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]]).map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        // Zero passes keep the start.
        #expect(graph.kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]], iterations: 0).map { Array($0) } == [[0, 3, 4], [1, 2, 5]])
    }

    @Test("The karate club from {0 ..< 17} and {17 ..< 34}: NetworkX's halves, unweighted and with its weights")
    func karate() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
            (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
            (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
            (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3,
            3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let start = [Array(0 ..< 17), Array(17 ..< 34)]
        let expected = [[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        #expect(graph.kernighanLinBisection(startingFrom: start).map { Array($0) } == expected)
        #expect(graph.kernighanLinBisection(startingFrom: start, weight: { w[$0] }).map { Array($0) } == expected)
    }

    @Test("NetworkX's halves where the heap's ties (earliest insertion first), the side moved first (the first community's) and the shortest best prefix decide, from the first ⌊n/2⌋ vertices")
    func networkXTies() {
        let cases: [(Int, [(Int, Int)], [[Int]])] = [
            (5, [(0, 3), (1, 4), (0, 4), (1, 3), (3, 4), (2, 4)], [[0, 2, 4], [1, 3]]),
            (10, [(1, 9), (0, 8), (3, 5), (6, 9), (0, 6), (2, 6), (4, 5), (5, 6), (5, 9), (4, 8), (4, 6), (2, 9), (4, 7)],
             [[0, 3, 4, 7, 8], [1, 2, 5, 6, 9]]),
            (10, [(1, 3), (6, 9), (0, 6), (3, 6), (0, 4), (0, 9), (1, 9), (2, 4), (2, 3), (1, 2), (4, 8), (2, 5), (0, 3), (3, 5), (0, 7),
                  (0, 8), (1, 4), (1, 8)], [[0, 3, 6, 7, 9], [1, 2, 4, 5, 8]]),
        ]
        for (n, pairs, expected) in cases {
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.kernighanLinBisection(startingFrom: [Array(0 ..< n / 2), Array(n / 2 ..< n)])
            #expect(result.map { Array($0) } == expected, "\(pairs)")
        }
    }

    @Test("Degenerate graphs: no vertices, one vertex, no edges; parallel edges add and self-loops never matter")
    func degenerate() {
        var generator = SeededRandomNumberGenerator(seed: 3)
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).kernighanLinBisection(using: &generator).isEmpty)
        #expect(ReferencePseudograph<Int>(vertices: [0], edges: []).kernighanLinBisection(using: &generator).map { Array($0) } == [[0]])
        let edgeless = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: [])
        #expect(edgeless.kernighanLinBisection(startingFrom: [[0, 1], [2, 3]]).map { Array($0) } == [[0, 1], [2, 3]])
        // A path 0-1-2-3 with 1-2 tripled and loops: from {0, 2}, {1, 3} the cut of 5 becomes 2,
        // {0, 3} and {1, 2}.
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(1, 2), UndirectedEdge(2, 1), UndirectedEdge(0, 0), UndirectedEdge(3, 3)]
        let multi = ReferencePseudograph(vertices: 0 ..< 4, edges: edges)
        let result = multi.kernighanLinBisection(startingFrom: [[0, 2], [1, 3]])
        #expect(result.map { Array($0) } == [[0, 3], [1, 2]])
        let cut = edges.filter { result.community(of: $0.u) != result.community(of: $0.v) }.count
        #expect(cut == 2)
    }

    @Test("A random start: balanced halves, the same seed the same halves, and the system generator")
    func randomStart() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (5, 6)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var a = SeededRandomNumberGenerator(seed: 8), b = a
        let first = graph.kernighanLinBisection(using: &a)
        #expect(first == graph.kernighanLinBisection(using: &b))
        #expect(first.map(\.count).sorted() == [3, 4])
        #expect(graph.kernighanLinBisection(weight: { _ in 1.0 }, using: &a).map(\.count).sorted() == [3, 4])
        #expect(graph.kernighanLinBisection().map(\.count).sorted() == [3, 4])
    }

    @Test("Properties: the halves keep the starting sizes and cut no more weight than the start", .tags(.randomized))
    func properties() async {
        let triples = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 3)).array(of: 0 ... 25)
        let sides = Gen.bool.array(of: 10 ... 10)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 10), sides) { raw, n, rawSides in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let w = raw.map { Double($0.2) }
            let first = (0 ..< n).filter { rawSides[$0] }, second = (0 ..< n).filter { !rawSides[$0] }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.kernighanLinBisection(startingFrom: [first, second], weight: { w[$0] })
            func cut(_ side: (Int) -> Bool) -> Double {
                var total = 0.0
                for (k, (u, v)) in ends.enumerated() where side(u) != side(v) { total += w[k] }
                return total
            }
            let startCut = cut { rawSides[$0] }
            let firstSide = result.community(of: 0)
            let endCut = cut { result.community(of: $0) == firstSide }
            #expect(endCut <= startCut, "\(ends), \(w), \(first)")
            #expect(result.map(\.count).sorted() == [first.count, second.count].filter { $0 > 0 }.sorted(), "\(ends), \(first)")
        }
    }
}
