// Agreement rows: the semiring and W overloads give the same distances on the catalog's LCG
// graphs; Boolean reachability is Traversal's descendants(of:); the bottleneck, Boolean and
// counting rows were checked by ref.py against brute force and NetworkX. And SR-274: an Int.max
// weight is the tropical zero, so it neither traps nor reaches.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing
import Traversal

@Suite("Semirings: agreement with the W overloads and the references")
struct SemiringAgreementTests {
    @Test("SR-264 the W overload gives the same distances (TropicalSemiring<Int>)")
    func sr264() {
        // dijkstraShortestPaths(from: 0) → [0, 18, 31, 19, 10, 16, 21, 23, 18, 11, 40, 19, 21, 7, 35, 31, 10, 22, 11, 19, 23, 9, 19, 27, 22, 28, 26, 19, 13, 23]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 14, to: 3), DirectedEdge(from: 6, to: 0), DirectedEdge(from: 24, to: 5), DirectedEdge(from: 20, to: 22),
            DirectedEdge(from: 9, to: 16), DirectedEdge(from: 3, to: 22), DirectedEdge(from: 12, to: 0), DirectedEdge(from: 14, to: 22),
            DirectedEdge(from: 10, to: 5), DirectedEdge(from: 22, to: 15), DirectedEdge(from: 26, to: 0), DirectedEdge(from: 9, to: 8),
            DirectedEdge(from: 24, to: 2), DirectedEdge(from: 21, to: 28), DirectedEdge(from: 17, to: 28), DirectedEdge(from: 18, to: 5),
            DirectedEdge(from: 14, to: 12), DirectedEdge(from: 6, to: 28), DirectedEdge(from: 16, to: 19), DirectedEdge(from: 5, to: 22),
            DirectedEdge(from: 20, to: 10), DirectedEdge(from: 21, to: 4), DirectedEdge(from: 18, to: 21), DirectedEdge(from: 23, to: 4),
            DirectedEdge(from: 12, to: 4), DirectedEdge(from: 26, to: 4), DirectedEdge(from: 1, to: 20), DirectedEdge(from: 8, to: 25),
            DirectedEdge(from: 7, to: 10), DirectedEdge(from: 3, to: 12), DirectedEdge(from: 18, to: 11), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 13, to: 6), DirectedEdge(from: 12, to: 19), DirectedEdge(from: 12, to: 21), DirectedEdge(from: 29, to: 8),
            DirectedEdge(from: 5, to: 8), DirectedEdge(from: 9, to: 24), DirectedEdge(from: 15, to: 5), DirectedEdge(from: 1, to: 27),
            DirectedEdge(from: 19, to: 8), DirectedEdge(from: 22, to: 27), DirectedEdge(from: 20, to: 21), DirectedEdge(from: 8, to: 22),
            DirectedEdge(from: 2, to: 28), DirectedEdge(from: 27, to: 14), DirectedEdge(from: 29, to: 8), DirectedEdge(from: 11, to: 24),
            DirectedEdge(from: 9, to: 0), DirectedEdge(from: 9, to: 24), DirectedEdge(from: 20, to: 26), DirectedEdge(from: 18, to: 13),
            DirectedEdge(from: 26, to: 9), DirectedEdge(from: 18, to: 2), DirectedEdge(from: 4, to: 18), DirectedEdge(from: 3, to: 29),
            DirectedEdge(from: 15, to: 29), DirectedEdge(from: 15, to: 24), DirectedEdge(from: 29, to: 20), DirectedEdge(from: 12, to: 24),
            DirectedEdge(from: 1, to: 7), DirectedEdge(from: 25, to: 9), DirectedEdge(from: 4, to: 18), DirectedEdge(from: 16, to: 4),
            DirectedEdge(from: 8, to: 1), DirectedEdge(from: 14, to: 3), DirectedEdge(from: 26, to: 20), DirectedEdge(from: 20, to: 9),
            DirectedEdge(from: 13, to: 9), DirectedEdge(from: 24, to: 28), DirectedEdge(from: 12, to: 23), DirectedEdge(from: 2, to: 26),
            DirectedEdge(from: 11, to: 22), DirectedEdge(from: 27, to: 5), DirectedEdge(from: 17, to: 25), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 15, to: 19), DirectedEdge(from: 6, to: 27), DirectedEdge(from: 26, to: 23), DirectedEdge(from: 18, to: 28),
            DirectedEdge(from: 20, to: 29), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 23, to: 17), DirectedEdge(from: 6, to: 17),
            DirectedEdge(from: 10, to: 20), DirectedEdge(from: 19, to: 2), DirectedEdge(from: 20, to: 29), DirectedEdge(from: 29, to: 3),
            DirectedEdge(from: 5, to: 22), DirectedEdge(from: 19, to: 29), DirectedEdge(from: 28, to: 21), DirectedEdge(from: 5, to: 6),
            DirectedEdge(from: 2, to: 11), DirectedEdge(from: 26, to: 24), DirectedEdge(from: 28, to: 1), DirectedEdge(from: 6, to: 5),
            DirectedEdge(from: 8, to: 3), DirectedEdge(from: 25, to: 14), DirectedEdge(from: 6, to: 28), DirectedEdge(from: 18, to: 27),
            DirectedEdge(from: 0, to: 13), DirectedEdge(from: 21, to: 16), DirectedEdge(from: 20, to: 17), DirectedEdge(from: 21, to: 7),
            DirectedEdge(from: 0, to: 21), DirectedEdge(from: 2, to: 9), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 22, to: 27),
            DirectedEdge(from: 12, to: 18), DirectedEdge(from: 27, to: 16), DirectedEdge(from: 17, to: 23), DirectedEdge(from: 5, to: 26),
            DirectedEdge(from: 4, to: 18), DirectedEdge(from: 7, to: 9), DirectedEdge(from: 10, to: 4), DirectedEdge(from: 17, to: 3),
            DirectedEdge(from: 29, to: 25), DirectedEdge(from: 9, to: 13), DirectedEdge(from: 1, to: 17), DirectedEdge(from: 25, to: 2),
        ])
        let w: [Int] = [
            13, 16, 12, 18, 20, 6, 14, 5, 3, 12, 8, 19,
            17, 8, 20, 5, 17, 15, 9, 3, 20, 1, 13, 18,
            12, 8, 5, 20, 17, 2, 8, 9, 14, 5, 2, 4,
            2, 11, 2, 1, 0, 5, 17, 12, 7, 16, 17, 11,
            17, 20, 3, 4, 9, 20, 5, 8, 3, 15, 18, 3,
            7, 9, 6, 8, 0, 8, 1, 6, 4, 17, 6, 6,
            19, 5, 6, 18, 14, 8, 3, 2, 0, 0, 3, 11,
            12, 15, 15, 1, 17, 14, 14, 20, 18, 3, 12, 6,
            1, 7, 0, 9, 7, 1, 1, 14, 9, 13, 19, 19,
            5, 10, 15, 11, 1, 15, 12, 7, 7, 5, 4, 7,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [
            0, 18, 31, 19, 10, 16, 21, 23, 18, 11, 40, 19,
            21, 7, 35, 31, 10, 22, 11, 19, 23, 9, 19, 27,
            22, 28, 26, 19, 13, 23,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = graph.dijkstraShortestPaths(from: 0) { w[$0] }
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-265 the W overload gives the same distances (TropicalSemiring<Int>)")
    func sr265() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 14, to: 3), DirectedEdge(from: 6, to: 0), DirectedEdge(from: 24, to: 5), DirectedEdge(from: 20, to: 22),
            DirectedEdge(from: 9, to: 16), DirectedEdge(from: 3, to: 22), DirectedEdge(from: 12, to: 0), DirectedEdge(from: 14, to: 22),
            DirectedEdge(from: 10, to: 5), DirectedEdge(from: 22, to: 15), DirectedEdge(from: 26, to: 0), DirectedEdge(from: 9, to: 8),
            DirectedEdge(from: 24, to: 2), DirectedEdge(from: 21, to: 28), DirectedEdge(from: 17, to: 28), DirectedEdge(from: 18, to: 5),
            DirectedEdge(from: 14, to: 12), DirectedEdge(from: 6, to: 28), DirectedEdge(from: 16, to: 19), DirectedEdge(from: 5, to: 22),
            DirectedEdge(from: 20, to: 10), DirectedEdge(from: 21, to: 4), DirectedEdge(from: 18, to: 21), DirectedEdge(from: 23, to: 4),
            DirectedEdge(from: 12, to: 4), DirectedEdge(from: 26, to: 4), DirectedEdge(from: 1, to: 20), DirectedEdge(from: 8, to: 25),
            DirectedEdge(from: 7, to: 10), DirectedEdge(from: 3, to: 12), DirectedEdge(from: 18, to: 11), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 13, to: 6), DirectedEdge(from: 12, to: 19), DirectedEdge(from: 12, to: 21), DirectedEdge(from: 29, to: 8),
            DirectedEdge(from: 5, to: 8), DirectedEdge(from: 9, to: 24), DirectedEdge(from: 15, to: 5), DirectedEdge(from: 1, to: 27),
            DirectedEdge(from: 19, to: 8), DirectedEdge(from: 22, to: 27), DirectedEdge(from: 20, to: 21), DirectedEdge(from: 8, to: 22),
            DirectedEdge(from: 2, to: 28), DirectedEdge(from: 27, to: 14), DirectedEdge(from: 29, to: 8), DirectedEdge(from: 11, to: 24),
            DirectedEdge(from: 9, to: 0), DirectedEdge(from: 9, to: 24), DirectedEdge(from: 20, to: 26), DirectedEdge(from: 18, to: 13),
            DirectedEdge(from: 26, to: 9), DirectedEdge(from: 18, to: 2), DirectedEdge(from: 4, to: 18), DirectedEdge(from: 3, to: 29),
            DirectedEdge(from: 15, to: 29), DirectedEdge(from: 15, to: 24), DirectedEdge(from: 29, to: 20), DirectedEdge(from: 12, to: 24),
            DirectedEdge(from: 1, to: 7), DirectedEdge(from: 25, to: 9), DirectedEdge(from: 4, to: 18), DirectedEdge(from: 16, to: 4),
            DirectedEdge(from: 8, to: 1), DirectedEdge(from: 14, to: 3), DirectedEdge(from: 26, to: 20), DirectedEdge(from: 20, to: 9),
            DirectedEdge(from: 13, to: 9), DirectedEdge(from: 24, to: 28), DirectedEdge(from: 12, to: 23), DirectedEdge(from: 2, to: 26),
            DirectedEdge(from: 11, to: 22), DirectedEdge(from: 27, to: 5), DirectedEdge(from: 17, to: 25), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 15, to: 19), DirectedEdge(from: 6, to: 27), DirectedEdge(from: 26, to: 23), DirectedEdge(from: 18, to: 28),
            DirectedEdge(from: 20, to: 29), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 23, to: 17), DirectedEdge(from: 6, to: 17),
            DirectedEdge(from: 10, to: 20), DirectedEdge(from: 19, to: 2), DirectedEdge(from: 20, to: 29), DirectedEdge(from: 29, to: 3),
            DirectedEdge(from: 5, to: 22), DirectedEdge(from: 19, to: 29), DirectedEdge(from: 28, to: 21), DirectedEdge(from: 5, to: 6),
            DirectedEdge(from: 2, to: 11), DirectedEdge(from: 26, to: 24), DirectedEdge(from: 28, to: 1), DirectedEdge(from: 6, to: 5),
            DirectedEdge(from: 8, to: 3), DirectedEdge(from: 25, to: 14), DirectedEdge(from: 6, to: 28), DirectedEdge(from: 18, to: 27),
            DirectedEdge(from: 0, to: 13), DirectedEdge(from: 21, to: 16), DirectedEdge(from: 20, to: 17), DirectedEdge(from: 21, to: 7),
            DirectedEdge(from: 0, to: 21), DirectedEdge(from: 2, to: 9), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 22, to: 27),
            DirectedEdge(from: 12, to: 18), DirectedEdge(from: 27, to: 16), DirectedEdge(from: 17, to: 23), DirectedEdge(from: 5, to: 26),
            DirectedEdge(from: 4, to: 18), DirectedEdge(from: 7, to: 9), DirectedEdge(from: 10, to: 4), DirectedEdge(from: 17, to: 3),
            DirectedEdge(from: 29, to: 25), DirectedEdge(from: 9, to: 13), DirectedEdge(from: 1, to: 17), DirectedEdge(from: 25, to: 2),
        ])
        let w: [Int] = [
            10, 16, 3, 6, -1, 18, 8, 11, 9, 15, 20, 1,
            11, 2, 14, 5, 14, 18, -3, 3, 2, 13, 19, 15,
            9, 8, 17, 5, 11, 8, -1, 0, 2, 17, 8, 4,
            5, 14, 17, -2, 6, -1, 2, 3, 10, 16, 11, 14,
            -1, 8, 18, 13, 6, 20, 5, 17, 6, 15, 0, 6,
            16, 6, 12, 2, 12, -1, 7, 12, 4, 20, 12, 12,
            1, 2, 15, 9, 20, -1, 18, 5, 9, 12, 3, 5,
            6, 3, -3, 7, -1, -1, 20, 20, 6, 0, 12, 15,
            16, 10, 0, 12, 4, 16, 16, 8, 12, 19, -2, 19,
            14, 13, 12, -1, 16, 6, -3, -2, 4, 8, 7, 16,
        ]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
        // The W overload: nil too.
        #expect(graph.bellmanFordShortestPaths(from: 0) { w[$0] } == nil)
    }

    @Test("SR-266 the W overload gives the same distances (TropicalSemiring<Int>)")
    func sr266() {
        // dijkstraShortestPaths(from: 0) → [0, 34, 16, 39, 2, 11, 32, 16, 11, 29, 43, 38, 23, 22, 26, 15, 25, 36, 34, 18, 25, 33, 19, 18, 32, 14, 13, 29, 7, 23]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 10, to: 12), DirectedEdge(from: 6, to: 14), DirectedEdge(from: 5, to: 29), DirectedEdge(from: 15, to: 2),
            DirectedEdge(from: 23, to: 2), DirectedEdge(from: 6, to: 24), DirectedEdge(from: 24, to: 23), DirectedEdge(from: 26, to: 25),
            DirectedEdge(from: 2, to: 8), DirectedEdge(from: 25, to: 6), DirectedEdge(from: 29, to: 12), DirectedEdge(from: 23, to: 7),
            DirectedEdge(from: 18, to: 22), DirectedEdge(from: 3, to: 16), DirectedEdge(from: 9, to: 19), DirectedEdge(from: 17, to: 4),
            DirectedEdge(from: 6, to: 4), DirectedEdge(from: 15, to: 26), DirectedEdge(from: 25, to: 13), DirectedEdge(from: 10, to: 26),
            DirectedEdge(from: 26, to: 5), DirectedEdge(from: 10, to: 2), DirectedEdge(from: 7, to: 25), DirectedEdge(from: 6, to: 20),
            DirectedEdge(from: 20, to: 27), DirectedEdge(from: 6, to: 21), DirectedEdge(from: 21, to: 0), DirectedEdge(from: 2, to: 16),
            DirectedEdge(from: 12, to: 29), DirectedEdge(from: 29, to: 17), DirectedEdge(from: 23, to: 2), DirectedEdge(from: 20, to: 3),
            DirectedEdge(from: 27, to: 14), DirectedEdge(from: 14, to: 11), DirectedEdge(from: 0, to: 4), DirectedEdge(from: 16, to: 4),
            DirectedEdge(from: 7, to: 26), DirectedEdge(from: 24, to: 21), DirectedEdge(from: 14, to: 18), DirectedEdge(from: 3, to: 6),
            DirectedEdge(from: 18, to: 13), DirectedEdge(from: 0, to: 28), DirectedEdge(from: 11, to: 3), DirectedEdge(from: 19, to: 15),
            DirectedEdge(from: 9, to: 8), DirectedEdge(from: 24, to: 4), DirectedEdge(from: 13, to: 28), DirectedEdge(from: 17, to: 25),
            DirectedEdge(from: 22, to: 17), DirectedEdge(from: 10, to: 24), DirectedEdge(from: 6, to: 27), DirectedEdge(from: 7, to: 28),
            DirectedEdge(from: 8, to: 26), DirectedEdge(from: 26, to: 23), DirectedEdge(from: 12, to: 23), DirectedEdge(from: 6, to: 7),
            DirectedEdge(from: 12, to: 25), DirectedEdge(from: 20, to: 9), DirectedEdge(from: 14, to: 16), DirectedEdge(from: 3, to: 17),
            DirectedEdge(from: 14, to: 20), DirectedEdge(from: 0, to: 4), DirectedEdge(from: 3, to: 18), DirectedEdge(from: 25, to: 13),
            DirectedEdge(from: 25, to: 4), DirectedEdge(from: 24, to: 29), DirectedEdge(from: 25, to: 16), DirectedEdge(from: 10, to: 25),
            DirectedEdge(from: 13, to: 2), DirectedEdge(from: 24, to: 5), DirectedEdge(from: 13, to: 6), DirectedEdge(from: 17, to: 4),
            DirectedEdge(from: 24, to: 16), DirectedEdge(from: 24, to: 4), DirectedEdge(from: 10, to: 27), DirectedEdge(from: 18, to: 23),
            DirectedEdge(from: 13, to: 22), DirectedEdge(from: 9, to: 12), DirectedEdge(from: 27, to: 23), DirectedEdge(from: 20, to: 5),
            DirectedEdge(from: 8, to: 15), DirectedEdge(from: 3, to: 8), DirectedEdge(from: 23, to: 7), DirectedEdge(from: 28, to: 20),
            DirectedEdge(from: 20, to: 7), DirectedEdge(from: 20, to: 3), DirectedEdge(from: 6, to: 3), DirectedEdge(from: 23, to: 9),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 26, to: 22), DirectedEdge(from: 10, to: 8), DirectedEdge(from: 2, to: 24),
            DirectedEdge(from: 6, to: 22), DirectedEdge(from: 14, to: 1), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 28, to: 4),
            DirectedEdge(from: 15, to: 2), DirectedEdge(from: 1, to: 25), DirectedEdge(from: 26, to: 19), DirectedEdge(from: 29, to: 12),
            DirectedEdge(from: 19, to: 22), DirectedEdge(from: 0, to: 7), DirectedEdge(from: 17, to: 1), DirectedEdge(from: 14, to: 0),
            DirectedEdge(from: 10, to: 2), DirectedEdge(from: 20, to: 21), DirectedEdge(from: 27, to: 21), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 6, to: 14), DirectedEdge(from: 8, to: 26), DirectedEdge(from: 13, to: 0), DirectedEdge(from: 23, to: 22),
            DirectedEdge(from: 9, to: 6), DirectedEdge(from: 25, to: 27), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 5, to: 14),
            DirectedEdge(from: 8, to: 22), DirectedEdge(from: 27, to: 10), DirectedEdge(from: 10, to: 6), DirectedEdge(from: 27, to: 24),
        ])
        let w: [Int] = [
            2, 10, 12, 1, 8, 9, 0, 1, 0, 19, 0, 12,
            17, 19, 12, 11, 17, 17, 8, 10, 2, 16, 14, 19,
            5, 1, 6, 16, 13, 17, 12, 16, 18, 12, 2, 4,
            9, 4, 8, 10, 8, 7, 7, 16, 4, 2, 2, 9,
            17, 17, 17, 15, 5, 5, 0, 6, 10, 7, 10, 13,
            19, 4, 3, 18, 1, 14, 11, 6, 17, 3, 15, 8,
            13, 4, 16, 9, 3, 9, 9, 0, 4, 7, 2, 18,
            11, 14, 16, 11, 9, 20, 8, 16, 8, 8, 9, 6,
            14, 0, 5, 17, 12, 16, 16, 7, 14, 13, 8, 0,
            20, 2, 5, 2, 3, 15, 3, 15, 8, 14, 18, 11,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [
            0, 34, 16, 39, 2, 11, 32, 16, 11, 29, 43, 38,
            23, 22, 26, 15, 25, 36, 34, 18, 25, 33, 19, 18,
            32, 14, 13, 29, 7, 23,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = graph.dijkstraShortestPaths(from: 0) { w[$0] }
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-267 the W overload gives the same distances (TropicalSemiring<Int>)")
    func sr267() throws {
        // bellmanFordShortestPaths(from: 0) → [0, 7, 13, 14, -1, -4, 4, -2, 8, 20, 18, 8, 16, 1, 8, 9, 8, -2, 13, 15, 10, 14, 12, 10, 1, -2, 1, 16, -5, -1]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 10, to: 12), DirectedEdge(from: 6, to: 14), DirectedEdge(from: 5, to: 29), DirectedEdge(from: 15, to: 2),
            DirectedEdge(from: 23, to: 2), DirectedEdge(from: 6, to: 24), DirectedEdge(from: 24, to: 23), DirectedEdge(from: 26, to: 25),
            DirectedEdge(from: 2, to: 8), DirectedEdge(from: 25, to: 6), DirectedEdge(from: 29, to: 12), DirectedEdge(from: 23, to: 7),
            DirectedEdge(from: 18, to: 22), DirectedEdge(from: 3, to: 16), DirectedEdge(from: 9, to: 19), DirectedEdge(from: 17, to: 4),
            DirectedEdge(from: 6, to: 4), DirectedEdge(from: 15, to: 26), DirectedEdge(from: 25, to: 13), DirectedEdge(from: 10, to: 26),
            DirectedEdge(from: 26, to: 5), DirectedEdge(from: 10, to: 2), DirectedEdge(from: 7, to: 25), DirectedEdge(from: 6, to: 20),
            DirectedEdge(from: 20, to: 27), DirectedEdge(from: 6, to: 21), DirectedEdge(from: 21, to: 0), DirectedEdge(from: 2, to: 16),
            DirectedEdge(from: 12, to: 29), DirectedEdge(from: 29, to: 17), DirectedEdge(from: 23, to: 2), DirectedEdge(from: 20, to: 3),
            DirectedEdge(from: 27, to: 14), DirectedEdge(from: 14, to: 11), DirectedEdge(from: 0, to: 4), DirectedEdge(from: 16, to: 4),
            DirectedEdge(from: 7, to: 26), DirectedEdge(from: 24, to: 21), DirectedEdge(from: 14, to: 18), DirectedEdge(from: 3, to: 6),
            DirectedEdge(from: 18, to: 13), DirectedEdge(from: 0, to: 28), DirectedEdge(from: 11, to: 3), DirectedEdge(from: 19, to: 15),
            DirectedEdge(from: 9, to: 8), DirectedEdge(from: 24, to: 4), DirectedEdge(from: 13, to: 28), DirectedEdge(from: 17, to: 25),
            DirectedEdge(from: 22, to: 17), DirectedEdge(from: 10, to: 24), DirectedEdge(from: 6, to: 27), DirectedEdge(from: 7, to: 28),
            DirectedEdge(from: 8, to: 26), DirectedEdge(from: 26, to: 23), DirectedEdge(from: 12, to: 23), DirectedEdge(from: 6, to: 7),
            DirectedEdge(from: 12, to: 25), DirectedEdge(from: 20, to: 9), DirectedEdge(from: 14, to: 16), DirectedEdge(from: 3, to: 17),
            DirectedEdge(from: 14, to: 20), DirectedEdge(from: 0, to: 4), DirectedEdge(from: 3, to: 18), DirectedEdge(from: 25, to: 13),
            DirectedEdge(from: 25, to: 4), DirectedEdge(from: 24, to: 29), DirectedEdge(from: 25, to: 16), DirectedEdge(from: 10, to: 25),
            DirectedEdge(from: 13, to: 2), DirectedEdge(from: 24, to: 5), DirectedEdge(from: 13, to: 6), DirectedEdge(from: 17, to: 4),
            DirectedEdge(from: 24, to: 16), DirectedEdge(from: 24, to: 4), DirectedEdge(from: 10, to: 27), DirectedEdge(from: 18, to: 23),
            DirectedEdge(from: 13, to: 22), DirectedEdge(from: 9, to: 12), DirectedEdge(from: 27, to: 23), DirectedEdge(from: 20, to: 5),
            DirectedEdge(from: 8, to: 15), DirectedEdge(from: 3, to: 8), DirectedEdge(from: 23, to: 7), DirectedEdge(from: 28, to: 20),
            DirectedEdge(from: 20, to: 7), DirectedEdge(from: 20, to: 3), DirectedEdge(from: 6, to: 3), DirectedEdge(from: 23, to: 9),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 26, to: 22), DirectedEdge(from: 10, to: 8), DirectedEdge(from: 2, to: 24),
            DirectedEdge(from: 6, to: 22), DirectedEdge(from: 14, to: 1), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 28, to: 4),
            DirectedEdge(from: 15, to: 2), DirectedEdge(from: 1, to: 25), DirectedEdge(from: 26, to: 19), DirectedEdge(from: 29, to: 12),
            DirectedEdge(from: 19, to: 22), DirectedEdge(from: 0, to: 7), DirectedEdge(from: 17, to: 1), DirectedEdge(from: 14, to: 0),
            DirectedEdge(from: 10, to: 2), DirectedEdge(from: 20, to: 21), DirectedEdge(from: 27, to: 21), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 6, to: 14), DirectedEdge(from: 8, to: 26), DirectedEdge(from: 13, to: 0), DirectedEdge(from: 23, to: 22),
            DirectedEdge(from: 9, to: 6), DirectedEdge(from: 25, to: 27), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 5, to: 14),
            DirectedEdge(from: 8, to: 22), DirectedEdge(from: 27, to: 10), DirectedEdge(from: 10, to: 6), DirectedEdge(from: 27, to: 24),
        ])
        let w: [Int] = [
            -1, 4, 3, 4, 14, -3, 9, 1, 3, 19, 18, 6,
            -1, 1, 3, 2, 2, -1, 8, 13, 2, 1, 17, 7,
            20, 10, 0, 1, 1, -1, 6, 4, 3, 0, -1, 19,
            3, 13, 5, 4, 2, 16, 13, 7, 13, 8, 11, 0,
            8, 14, 17, -3, 5, 14, 6, 0, 13, 10, 4, 10,
            7, 4, 18, 3, 16, 20, 14, 9, 20, 9, 3, 8,
            7, 19, 13, 18, 12, 6, 6, 3, 1, 4, 5, 15,
            8, 5, 16, 17, 18, 17, -1, 19, 8, -1, -3, 9,
            8, 6, 14, 17, 0, -2, 16, 16, 8, 16, 2, 12,
            14, 11, 5, 20, -3, 18, -3, 12, 8, 2, 9, 17,
        ]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [
            0, 7, 13, 14, -1, -4, 4, -2, 8, 20, 18, 8,
            16, 1, 8, 9, 8, -2, 13, 15, 10, 14, 12, 10,
            1, -2, 1, 16, -5, -1,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = try #require(graph.bellmanFordShortestPaths(from: 0) { w[$0] })
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-268 the W overload gives the same distances (TropicalSemiring<Int>)")
    func sr268() {
        // dijkstraShortestPaths(from: 0) → [0, 15, 16, 18, 19, 11, 14, 14, 16, 16, 25, 11, 20, 12, 2, 10, 7, 8, 8, 8, 29, 11, 18, 0, 3, 25, 10, 24, 4, 5]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 29, to: 13), DirectedEdge(from: 5, to: 28), DirectedEdge(from: 24, to: 23), DirectedEdge(from: 25, to: 5),
            DirectedEdge(from: 29, to: 9), DirectedEdge(from: 13, to: 12), DirectedEdge(from: 26, to: 9), DirectedEdge(from: 28, to: 5),
            DirectedEdge(from: 9, to: 19), DirectedEdge(from: 7, to: 26), DirectedEdge(from: 5, to: 16), DirectedEdge(from: 11, to: 6),
            DirectedEdge(from: 25, to: 24), DirectedEdge(from: 19, to: 24), DirectedEdge(from: 11, to: 19), DirectedEdge(from: 5, to: 18),
            DirectedEdge(from: 21, to: 3), DirectedEdge(from: 18, to: 19), DirectedEdge(from: 25, to: 9), DirectedEdge(from: 0, to: 16),
            DirectedEdge(from: 0, to: 17), DirectedEdge(from: 5, to: 19), DirectedEdge(from: 19, to: 8), DirectedEdge(from: 11, to: 16),
            DirectedEdge(from: 25, to: 5), DirectedEdge(from: 16, to: 11), DirectedEdge(from: 5, to: 16), DirectedEdge(from: 14, to: 11),
            DirectedEdge(from: 1, to: 20), DirectedEdge(from: 7, to: 25), DirectedEdge(from: 5, to: 21), DirectedEdge(from: 11, to: 7),
            DirectedEdge(from: 29, to: 9), DirectedEdge(from: 12, to: 6), DirectedEdge(from: 29, to: 14), DirectedEdge(from: 3, to: 0),
            DirectedEdge(from: 7, to: 9), DirectedEdge(from: 18, to: 15), DirectedEdge(from: 9, to: 19), DirectedEdge(from: 24, to: 6),
            DirectedEdge(from: 15, to: 13), DirectedEdge(from: 19, to: 1), DirectedEdge(from: 10, to: 16), DirectedEdge(from: 19, to: 15),
            DirectedEdge(from: 29, to: 15), DirectedEdge(from: 8, to: 17), DirectedEdge(from: 25, to: 27), DirectedEdge(from: 15, to: 8),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 25, to: 16), DirectedEdge(from: 27, to: 25), DirectedEdge(from: 3, to: 4),
            DirectedEdge(from: 8, to: 17), DirectedEdge(from: 18, to: 19), DirectedEdge(from: 26, to: 29), DirectedEdge(from: 6, to: 17),
            DirectedEdge(from: 27, to: 25), DirectedEdge(from: 11, to: 25), DirectedEdge(from: 23, to: 29), DirectedEdge(from: 15, to: 26),
            DirectedEdge(from: 6, to: 28), DirectedEdge(from: 6, to: 2), DirectedEdge(from: 16, to: 18), DirectedEdge(from: 21, to: 27),
            DirectedEdge(from: 0, to: 23), DirectedEdge(from: 18, to: 21), DirectedEdge(from: 6, to: 3), DirectedEdge(from: 18, to: 17),
            DirectedEdge(from: 25, to: 8), DirectedEdge(from: 22, to: 15), DirectedEdge(from: 23, to: 14), DirectedEdge(from: 21, to: 10),
            DirectedEdge(from: 13, to: 19), DirectedEdge(from: 20, to: 17), DirectedEdge(from: 6, to: 18), DirectedEdge(from: 12, to: 17),
            DirectedEdge(from: 11, to: 24), DirectedEdge(from: 23, to: 6), DirectedEdge(from: 22, to: 0), DirectedEdge(from: 15, to: 16),
            DirectedEdge(from: 6, to: 8), DirectedEdge(from: 19, to: 7), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 7, to: 13),
            DirectedEdge(from: 26, to: 11), DirectedEdge(from: 11, to: 17), DirectedEdge(from: 24, to: 15), DirectedEdge(from: 14, to: 18),
            DirectedEdge(from: 9, to: 6), DirectedEdge(from: 23, to: 28), DirectedEdge(from: 11, to: 14), DirectedEdge(from: 6, to: 19),
            DirectedEdge(from: 26, to: 22), DirectedEdge(from: 20, to: 12), DirectedEdge(from: 10, to: 29), DirectedEdge(from: 2, to: 27),
            DirectedEdge(from: 14, to: 24), DirectedEdge(from: 28, to: 18), DirectedEdge(from: 18, to: 17), DirectedEdge(from: 5, to: 25),
            DirectedEdge(from: 2, to: 23), DirectedEdge(from: 27, to: 29), DirectedEdge(from: 20, to: 6), DirectedEdge(from: 27, to: 5),
            DirectedEdge(from: 8, to: 29), DirectedEdge(from: 19, to: 26), DirectedEdge(from: 13, to: 16), DirectedEdge(from: 16, to: 28),
            DirectedEdge(from: 17, to: 29), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 5, to: 3), DirectedEdge(from: 20, to: 12),
            DirectedEdge(from: 24, to: 18), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 10, to: 1), DirectedEdge(from: 4, to: 23),
            DirectedEdge(from: 25, to: 9), DirectedEdge(from: 14, to: 17), DirectedEdge(from: 22, to: 0), DirectedEdge(from: 23, to: 1),
        ])
        let w: [Int] = [
            7, 20, 9, 15, 14, 8, 20, 7, 14, 10, 9, 17,
            17, 5, 20, 2, 18, 15, 6, 7, 8, 16, 13, 5,
            19, 4, 14, 9, 14, 11, 13, 3, 11, 14, 16, 2,
            17, 2, 16, 11, 8, 7, 10, 14, 15, 5, 16, 9,
            20, 5, 20, 3, 15, 0, 1, 3, 14, 20, 5, 0,
            0, 2, 15, 14, 0, 3, 4, 11, 5, 13, 2, 14,
            16, 16, 1, 8, 2, 18, 18, 18, 2, 18, 1, 9,
            16, 18, 8, 6, 3, 4, 1, 13, 8, 12, 7, 8,
            1, 5, 6, 15, 12, 0, 4, 13, 2, 3, 8, 17,
            10, 4, 7, 1, 20, 0, 9, 15, 9, 17, 6, 15,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [
            0, 15, 16, 18, 19, 11, 14, 14, 16, 16, 25, 11,
            20, 12, 2, 10, 7, 8, 8, 8, 29, 11, 18, 0,
            3, 25, 10, 24, 4, 5,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = graph.dijkstraShortestPaths(from: 0) { w[$0] }
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-269 the W overload gives the same distances (TropicalSemiring<Int>)")
    func sr269() throws {
        // bellmanFordShortestPaths(from: 0) → [0, 6, 9, 23, 23, 18, 7, 9, 5, 7, 35, 9, 17, 21, 15, 8, 13, 7, 12, 6, 17, 24, 13, 9, 11, 11, 5, 14, 10, 11]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 29, to: 13), DirectedEdge(from: 5, to: 28), DirectedEdge(from: 24, to: 23), DirectedEdge(from: 25, to: 5),
            DirectedEdge(from: 29, to: 9), DirectedEdge(from: 13, to: 12), DirectedEdge(from: 26, to: 9), DirectedEdge(from: 28, to: 5),
            DirectedEdge(from: 9, to: 19), DirectedEdge(from: 7, to: 26), DirectedEdge(from: 5, to: 16), DirectedEdge(from: 11, to: 6),
            DirectedEdge(from: 25, to: 24), DirectedEdge(from: 19, to: 24), DirectedEdge(from: 11, to: 19), DirectedEdge(from: 5, to: 18),
            DirectedEdge(from: 21, to: 3), DirectedEdge(from: 18, to: 19), DirectedEdge(from: 25, to: 9), DirectedEdge(from: 0, to: 16),
            DirectedEdge(from: 0, to: 17), DirectedEdge(from: 5, to: 19), DirectedEdge(from: 19, to: 8), DirectedEdge(from: 11, to: 16),
            DirectedEdge(from: 25, to: 5), DirectedEdge(from: 16, to: 11), DirectedEdge(from: 5, to: 16), DirectedEdge(from: 14, to: 11),
            DirectedEdge(from: 1, to: 20), DirectedEdge(from: 7, to: 25), DirectedEdge(from: 5, to: 21), DirectedEdge(from: 11, to: 7),
            DirectedEdge(from: 29, to: 9), DirectedEdge(from: 12, to: 6), DirectedEdge(from: 29, to: 14), DirectedEdge(from: 3, to: 0),
            DirectedEdge(from: 7, to: 9), DirectedEdge(from: 18, to: 15), DirectedEdge(from: 9, to: 19), DirectedEdge(from: 24, to: 6),
            DirectedEdge(from: 15, to: 13), DirectedEdge(from: 19, to: 1), DirectedEdge(from: 10, to: 16), DirectedEdge(from: 19, to: 15),
            DirectedEdge(from: 29, to: 15), DirectedEdge(from: 8, to: 17), DirectedEdge(from: 25, to: 27), DirectedEdge(from: 15, to: 8),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 25, to: 16), DirectedEdge(from: 27, to: 25), DirectedEdge(from: 3, to: 4),
            DirectedEdge(from: 8, to: 17), DirectedEdge(from: 18, to: 19), DirectedEdge(from: 26, to: 29), DirectedEdge(from: 6, to: 17),
            DirectedEdge(from: 27, to: 25), DirectedEdge(from: 11, to: 25), DirectedEdge(from: 23, to: 29), DirectedEdge(from: 15, to: 26),
            DirectedEdge(from: 6, to: 28), DirectedEdge(from: 6, to: 2), DirectedEdge(from: 16, to: 18), DirectedEdge(from: 21, to: 27),
            DirectedEdge(from: 0, to: 23), DirectedEdge(from: 18, to: 21), DirectedEdge(from: 6, to: 3), DirectedEdge(from: 18, to: 17),
            DirectedEdge(from: 25, to: 8), DirectedEdge(from: 22, to: 15), DirectedEdge(from: 23, to: 14), DirectedEdge(from: 21, to: 10),
            DirectedEdge(from: 13, to: 19), DirectedEdge(from: 20, to: 17), DirectedEdge(from: 6, to: 18), DirectedEdge(from: 12, to: 17),
            DirectedEdge(from: 11, to: 24), DirectedEdge(from: 23, to: 6), DirectedEdge(from: 22, to: 0), DirectedEdge(from: 15, to: 16),
            DirectedEdge(from: 6, to: 8), DirectedEdge(from: 19, to: 7), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 7, to: 13),
            DirectedEdge(from: 26, to: 11), DirectedEdge(from: 11, to: 17), DirectedEdge(from: 24, to: 15), DirectedEdge(from: 14, to: 18),
            DirectedEdge(from: 9, to: 6), DirectedEdge(from: 23, to: 28), DirectedEdge(from: 11, to: 14), DirectedEdge(from: 6, to: 19),
            DirectedEdge(from: 26, to: 22), DirectedEdge(from: 20, to: 12), DirectedEdge(from: 10, to: 29), DirectedEdge(from: 2, to: 27),
            DirectedEdge(from: 14, to: 24), DirectedEdge(from: 28, to: 18), DirectedEdge(from: 18, to: 17), DirectedEdge(from: 5, to: 25),
            DirectedEdge(from: 2, to: 23), DirectedEdge(from: 27, to: 29), DirectedEdge(from: 20, to: 6), DirectedEdge(from: 27, to: 5),
            DirectedEdge(from: 8, to: 29), DirectedEdge(from: 19, to: 26), DirectedEdge(from: 13, to: 16), DirectedEdge(from: 16, to: 28),
            DirectedEdge(from: 17, to: 29), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 5, to: 3), DirectedEdge(from: 20, to: 12),
            DirectedEdge(from: 24, to: 18), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 10, to: 1), DirectedEdge(from: 4, to: 23),
            DirectedEdge(from: 25, to: 9), DirectedEdge(from: 14, to: 17), DirectedEdge(from: 22, to: 0), DirectedEdge(from: 23, to: 1),
        ])
        let w: [Int] = [
            10, 8, 3, 9, 14, 17, 2, 16, -1, 7, 9, 2,
            20, 5, 14, 17, 0, 0, 0, 16, 8, 7, 4, 5,
            7, -2, 5, 18, 11, 2, 19, 6, -1, 20, 4, 8,
            5, 14, 10, 11, 17, 16, -2, 5, -3, 2, 19, -3,
            14, 2, 20, 15, 12, -3, 16, 18, 17, 5, 2, -3,
            3, 2, 9, 11, 9, 12, 16, -1, 8, 10, 17, 11,
            4, 4, 10, 8, 8, 3, 15, 15, 20, 3, 19, 18,
            4, 6, 5, 0, 0, 16, 19, 16, 8, 0, 16, 5,
            13, 2, -3, 3, 6, -3, 19, 10, 11, 15, 14, 2,
            13, 16, 13, 4, 20, 12, -3, 9, 6, 11, 0, -3,
        ]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [
            0, 6, 9, 23, 23, 18, 7, 9, 5, 7, 35, 9,
            17, 21, 15, 8, 13, 7, 12, 6, 17, 24, 13, 9,
            11, 11, 5, 14, 10, 11,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = try #require(graph.bellmanFordShortestPaths(from: 0) { w[$0] })
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-270 the W overload gives the same matrix (TropicalSemiring<Int>)")
    func sr270() throws {
        // floydWarshallShortestPaths() → [0, 2, 4, 1, 3, 5, 3, 4, 4, 2, 4, 6; 3, 0, 7, 4, 6, 8, 6, 7, 7, 5, 7, 9; 8, 7, 0, 2, 4, 6, 4, 5, 0, 3, 8, 10; 6, 5, 3, 0, 2, 4, 2, 3, 3, 1, 6, 8; 8, 5, 6, 6, 0, 4, 5, 6, 4, 7, 9, 11; 4, 1, 8, 5, 7, 0, …
        let graph = DirectedPseudograph(vertices: 0 ..< 12, edges: [
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 5, to: 11), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 7, to: 2), DirectedEdge(from: 2, to: 8), DirectedEdge(from: 11, to: 7),
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 10), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 6, to: 10),
            DirectedEdge(from: 9, to: 4), DirectedEdge(from: 2, to: 5), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 7, to: 0),
            DirectedEdge(from: 1, to: 0), DirectedEdge(from: 6, to: 7), DirectedEdge(from: 9, to: 2), DirectedEdge(from: 8, to: 10),
            DirectedEdge(from: 10, to: 2), DirectedEdge(from: 8, to: 3), DirectedEdge(from: 6, to: 3), DirectedEdge(from: 4, to: 6),
            DirectedEdge(from: 7, to: 11), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 4, to: 2), DirectedEdge(from: 3, to: 6),
            DirectedEdge(from: 4, to: 5), DirectedEdge(from: 3, to: 9), DirectedEdge(from: 9, to: 0), DirectedEdge(from: 3, to: 9),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 6, to: 5), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 4, to: 8),
            DirectedEdge(from: 7, to: 2), DirectedEdge(from: 0, to: 6), DirectedEdge(from: 5, to: 1), DirectedEdge(from: 4, to: 5),
        ])
        let w: [Int] = [
            6, 2, 9, 9, 7, 0, 0, 8, 2, 4, 9, 4,
            2, 6, 2, 5, 3, 1, 7, 9, 5, 2, 5, 5,
            6, 1, 7, 2, 6, 8, 5, 1, 8, 2, 9, 4,
            5, 5, 1, 4,
        ]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [0, 2, 4, 1, 3, 5, 3, 4, 4, 2, 4, 6],
            [3, 0, 7, 4, 6, 8, 6, 7, 7, 5, 7, 9],
            [8, 7, 0, 2, 4, 6, 4, 5, 0, 3, 8, 10],
            [6, 5, 3, 0, 2, 4, 2, 3, 3, 1, 6, 8],
            [8, 5, 6, 6, 0, 4, 5, 6, 4, 7, 9, 11],
            [4, 1, 8, 5, 7, 0, 7, 8, 8, 6, 8, 9],
            [6, 3, 1, 3, 5, 2, 0, 1, 1, 4, 4, 6],
            [5, 7, 0, 2, 4, 6, 4, 0, 0, 3, 8, 6],
            [8, 7, 5, 2, 4, 6, 4, 5, 0, 3, 8, 10],
            [5, 7, 7, 6, 2, 6, 7, 8, 6, 0, 9, 11],
            [13, 12, 5, 7, 9, 11, 9, 10, 5, 8, 0, 2],
            [13, 15, 8, 10, 12, 14, 12, 8, 8, 11, 16, 0],
        ]
        #expect((0 ..< 12).map { i in (0 ..< 12).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 12).map { i in (0 ..< 12).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 12 {
            for j in 0 ..< 12 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Int>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
        // The W overload: the same matrix.
        let reference = try #require(graph.floydWarshallShortestPaths { w[$0] })
        #expect((0 ..< 12).map { i in (0 ..< 12).map { reference.distance(from: i, to: $0) } } == expected)
    }

    @Test("SR-271 the W overload gives the same distances (TropicalSemiring<Double>)")
    func sr271() {
        // dijkstraShortestPaths(from: 0) → [0.0, 38.5, 19.5, 23.0, 30.75, 5.0, 27.75, 37.75, 34.75, 20.5, 13.5, 17.0, 25.25, 14.5, 15.0, 35.0, 18.25, 24.0, 14.5, 32.75, 30.75, 20.5, 29.25, 17.25, 35.25, 14.75, 47.25, 17.75, 40.5, 28.75]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 22, to: 23), DirectedEdge(from: 4, to: 25), DirectedEdge(from: 25, to: 11), DirectedEdge(from: 29, to: 19),
            DirectedEdge(from: 20, to: 24), DirectedEdge(from: 15, to: 24), DirectedEdge(from: 18, to: 11), DirectedEdge(from: 3, to: 17),
            DirectedEdge(from: 8, to: 3), DirectedEdge(from: 22, to: 0), DirectedEdge(from: 10, to: 4), DirectedEdge(from: 18, to: 12),
            DirectedEdge(from: 21, to: 14), DirectedEdge(from: 1, to: 24), DirectedEdge(from: 29, to: 19), DirectedEdge(from: 20, to: 19),
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 25, to: 23), DirectedEdge(from: 15, to: 9), DirectedEdge(from: 20, to: 11),
            DirectedEdge(from: 14, to: 18), DirectedEdge(from: 10, to: 14), DirectedEdge(from: 10, to: 0), DirectedEdge(from: 14, to: 16),
            DirectedEdge(from: 8, to: 4), DirectedEdge(from: 2, to: 20), DirectedEdge(from: 17, to: 6), DirectedEdge(from: 0, to: 10),
            DirectedEdge(from: 1, to: 7), DirectedEdge(from: 21, to: 12), DirectedEdge(from: 21, to: 5), DirectedEdge(from: 4, to: 16),
            DirectedEdge(from: 1, to: 28), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 15, to: 29), DirectedEdge(from: 21, to: 22),
            DirectedEdge(from: 28, to: 29), DirectedEdge(from: 1, to: 22), DirectedEdge(from: 12, to: 11), DirectedEdge(from: 28, to: 20),
            DirectedEdge(from: 4, to: 25), DirectedEdge(from: 7, to: 1), DirectedEdge(from: 7, to: 11), DirectedEdge(from: 27, to: 22),
            DirectedEdge(from: 22, to: 27), DirectedEdge(from: 28, to: 26), DirectedEdge(from: 24, to: 25), DirectedEdge(from: 8, to: 21),
            DirectedEdge(from: 17, to: 14), DirectedEdge(from: 16, to: 5), DirectedEdge(from: 11, to: 23), DirectedEdge(from: 19, to: 20),
            DirectedEdge(from: 17, to: 3), DirectedEdge(from: 5, to: 18), DirectedEdge(from: 3, to: 27), DirectedEdge(from: 18, to: 23),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 29, to: 15), DirectedEdge(from: 23, to: 8), DirectedEdge(from: 23, to: 2),
            DirectedEdge(from: 24, to: 13), DirectedEdge(from: 5, to: 2), DirectedEdge(from: 13, to: 3), DirectedEdge(from: 6, to: 19),
            DirectedEdge(from: 4, to: 2), DirectedEdge(from: 28, to: 22), DirectedEdge(from: 7, to: 17), DirectedEdge(from: 22, to: 15),
            DirectedEdge(from: 24, to: 7), DirectedEdge(from: 19, to: 15), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 5, to: 25),
            DirectedEdge(from: 10, to: 12), DirectedEdge(from: 26, to: 0), DirectedEdge(from: 29, to: 13), DirectedEdge(from: 29, to: 24),
            DirectedEdge(from: 12, to: 14), DirectedEdge(from: 11, to: 18), DirectedEdge(from: 13, to: 29), DirectedEdge(from: 18, to: 21),
            DirectedEdge(from: 2, to: 7), DirectedEdge(from: 27, to: 14), DirectedEdge(from: 16, to: 9), DirectedEdge(from: 23, to: 2),
            DirectedEdge(from: 7, to: 21), DirectedEdge(from: 13, to: 12), DirectedEdge(from: 1, to: 5), DirectedEdge(from: 19, to: 14),
            DirectedEdge(from: 15, to: 5), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 4, to: 1), DirectedEdge(from: 29, to: 12),
            DirectedEdge(from: 20, to: 9), DirectedEdge(from: 2, to: 23), DirectedEdge(from: 17, to: 23), DirectedEdge(from: 20, to: 25),
            DirectedEdge(from: 25, to: 14), DirectedEdge(from: 23, to: 22), DirectedEdge(from: 7, to: 28), DirectedEdge(from: 17, to: 16),
            DirectedEdge(from: 17, to: 16), DirectedEdge(from: 5, to: 27), DirectedEdge(from: 1, to: 12), DirectedEdge(from: 29, to: 5),
            DirectedEdge(from: 15, to: 8), DirectedEdge(from: 7, to: 10), DirectedEdge(from: 19, to: 24), DirectedEdge(from: 4, to: 18),
            DirectedEdge(from: 21, to: 1), DirectedEdge(from: 11, to: 6), DirectedEdge(from: 4, to: 2), DirectedEdge(from: 0, to: 5),
            DirectedEdge(from: 20, to: 25), DirectedEdge(from: 12, to: 14), DirectedEdge(from: 29, to: 16), DirectedEdge(from: 4, to: 11),
            DirectedEdge(from: 5, to: 13), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 27, to: 2),
        ])
        let w: [Double] = [
            14.75, 1.75, 2.25, 12.0, 7.5, 10.75, 15.75, 1.0, 9.5, 19.5, 17.25, 18.5,
            13.25, 7.25, 10.5, 16.5, 18.0, 16.0, 2.75, 15.5, 8.25, 1.5, 12.5, 3.25,
            1.0, 11.25, 14.5, 13.5, 18.0, 14.5, 9.5, 7.0, 2.0, 5.25, 11.75, 12.25,
            19.75, 11.0, 0.25, 12.0, 2.25, 14.75, 11.0, 19.25, 14.75, 6.75, 14.75, 6.75,
            2.5, 9.5, 0.25, 14.5, 11.0, 9.5, 13.0, 14.75, 0.5, 9.0, 17.5, 12.5,
            6.5, 14.5, 18.5, 5.0, 10.0, 17.5, 3.0, 5.75, 15.0, 19.5, 13.25, 9.75,
            19.75, 15.0, 7.0, 6.5, 9.0, 17.0, 14.25, 6.0, 18.25, 13.5, 2.25, 5.0,
            9.25, 10.75, 9.0, 19.0, 4.25, 3.5, 7.75, 7.25, 20.0, 5.0, 8.5, 19.0,
            19.0, 12.0, 14.5, 4.0, 11.5, 12.75, 6.5, 6.5, 7.75, 11.0, 12.5, 19.75,
            19.25, 10.75, 3.0, 5.0, 7.0, 15.5, 11.0, 14.25, 9.5, 6.75, 9.25, 8.5,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [
            0.0, 38.5, 19.5, 23.0, 30.75, 5.0, 27.75, 37.75, 34.75, 20.5, 13.5, 17.0,
            25.25, 14.5, 15.0, 35.0, 18.25, 24.0, 14.5, 32.75, 30.75, 20.5, 29.25, 17.25,
            35.25, 14.75, 47.25, 17.75, 40.5, 28.75,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = graph.dijkstraShortestPaths(from: 0) { w[$0] }
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-272 the W overload gives the same distances (TropicalSemiring<Double>)")
    func sr272() {
        // dijkstraShortestPaths(from: 0) → [0.0, 6.25, 23.75, 25.75, 14.0, 20.5, 10.5, —, 33.5, 18.75, 33.75, 13.5, 21.25, 15.0, 13.75, 26.75, 37.75, 31.75, 32.25, 27.25, 28.0, 13.75, 14.0, 37.25, 17.25, 10.5, 28.0, 22.25, 13.5, 35.5]
        let graph = DirectedPseudograph(vertices: 0 ..< 30, edges: [
            DirectedEdge(from: 11, to: 2), DirectedEdge(from: 3, to: 9), DirectedEdge(from: 14, to: 5), DirectedEdge(from: 4, to: 9),
            DirectedEdge(from: 5, to: 4), DirectedEdge(from: 10, to: 16), DirectedEdge(from: 25, to: 20), DirectedEdge(from: 1, to: 21),
            DirectedEdge(from: 3, to: 1), DirectedEdge(from: 13, to: 4), DirectedEdge(from: 15, to: 4), DirectedEdge(from: 7, to: 19),
            DirectedEdge(from: 15, to: 26), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 21, to: 13), DirectedEdge(from: 12, to: 14),
            DirectedEdge(from: 28, to: 0), DirectedEdge(from: 27, to: 8), DirectedEdge(from: 10, to: 27), DirectedEdge(from: 24, to: 1),
            DirectedEdge(from: 23, to: 17), DirectedEdge(from: 0, to: 22), DirectedEdge(from: 15, to: 0), DirectedEdge(from: 17, to: 2),
            DirectedEdge(from: 6, to: 11), DirectedEdge(from: 6, to: 22), DirectedEdge(from: 26, to: 25), DirectedEdge(from: 29, to: 11),
            DirectedEdge(from: 14, to: 24), DirectedEdge(from: 20, to: 9), DirectedEdge(from: 28, to: 4), DirectedEdge(from: 7, to: 1),
            DirectedEdge(from: 20, to: 26), DirectedEdge(from: 24, to: 12), DirectedEdge(from: 6, to: 15), DirectedEdge(from: 5, to: 2),
            DirectedEdge(from: 3, to: 18), DirectedEdge(from: 11, to: 21), DirectedEdge(from: 28, to: 11), DirectedEdge(from: 27, to: 19),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 26, to: 20), DirectedEdge(from: 3, to: 15), DirectedEdge(from: 7, to: 12),
            DirectedEdge(from: 7, to: 23), DirectedEdge(from: 16, to: 26), DirectedEdge(from: 18, to: 21), DirectedEdge(from: 0, to: 25),
            DirectedEdge(from: 19, to: 3), DirectedEdge(from: 19, to: 24), DirectedEdge(from: 21, to: 11), DirectedEdge(from: 9, to: 13),
            DirectedEdge(from: 4, to: 5), DirectedEdge(from: 25, to: 14), DirectedEdge(from: 7, to: 5), DirectedEdge(from: 18, to: 25),
            DirectedEdge(from: 28, to: 0), DirectedEdge(from: 11, to: 28), DirectedEdge(from: 6, to: 12), DirectedEdge(from: 9, to: 18),
            DirectedEdge(from: 15, to: 22), DirectedEdge(from: 12, to: 10), DirectedEdge(from: 22, to: 13), DirectedEdge(from: 20, to: 11),
            DirectedEdge(from: 7, to: 11), DirectedEdge(from: 1, to: 11), DirectedEdge(from: 6, to: 1), DirectedEdge(from: 26, to: 5),
            DirectedEdge(from: 5, to: 11), DirectedEdge(from: 23, to: 14), DirectedEdge(from: 22, to: 14), DirectedEdge(from: 1, to: 11),
            DirectedEdge(from: 26, to: 17), DirectedEdge(from: 28, to: 4), DirectedEdge(from: 15, to: 27), DirectedEdge(from: 6, to: 22),
            DirectedEdge(from: 20, to: 24), DirectedEdge(from: 23, to: 2), DirectedEdge(from: 11, to: 6), DirectedEdge(from: 4, to: 8),
            DirectedEdge(from: 0, to: 28), DirectedEdge(from: 16, to: 0), DirectedEdge(from: 26, to: 12), DirectedEdge(from: 26, to: 21),
            DirectedEdge(from: 9, to: 23), DirectedEdge(from: 26, to: 22), DirectedEdge(from: 6, to: 27), DirectedEdge(from: 3, to: 5),
            DirectedEdge(from: 7, to: 3), DirectedEdge(from: 9, to: 25), DirectedEdge(from: 18, to: 1), DirectedEdge(from: 15, to: 26),
            DirectedEdge(from: 17, to: 6), DirectedEdge(from: 29, to: 1), DirectedEdge(from: 11, to: 6), DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 5, to: 29), DirectedEdge(from: 7, to: 3), DirectedEdge(from: 12, to: 13), DirectedEdge(from: 13, to: 19),
            DirectedEdge(from: 22, to: 20), DirectedEdge(from: 19, to: 12), DirectedEdge(from: 17, to: 28), DirectedEdge(from: 3, to: 11),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 5, to: 19), DirectedEdge(from: 27, to: 16), DirectedEdge(from: 8, to: 20),
            DirectedEdge(from: 22, to: 21), DirectedEdge(from: 17, to: 29), DirectedEdge(from: 15, to: 11), DirectedEdge(from: 26, to: 4),
            DirectedEdge(from: 16, to: 21), DirectedEdge(from: 16, to: 24), DirectedEdge(from: 20, to: 25), DirectedEdge(from: 20, to: 6),
            DirectedEdge(from: 2, to: 28), DirectedEdge(from: 22, to: 27), DirectedEdge(from: 24, to: 10), DirectedEdge(from: 19, to: 2),
        ])
        let w: [Double] = [
            10.25, 1.0, 6.75, 4.75, 10.25, 19.75, 17.5, 7.5, 13.75, 19.25, 16.0, 17.5,
            2.25, 4.25, 1.25, 18.75, 3.0, 17.5, 1.5, 11.0, 0.5, 14.0, 8.5, 3.25,
            10.75, 15.0, 10.75, 9.5, 3.5, 10.5, 6.25, 8.75, 14.0, 4.0, 16.25, 19.25,
            12.75, 3.25, 18.25, 5.0, 19.5, 7.0, 1.25, 19.5, 2.75, 16.75, 14.25, 10.5,
            5.5, 7.0, 17.25, 1.75, 12.75, 3.25, 7.25, 7.75, 15.25, 0.0, 15.25, 13.5,
            15.5, 13.0, 18.5, 4.25, 16.25, 15.5, 16.0, 4.5, 9.75, 0.75, 4.75, 7.25,
            3.75, 0.5, 18.25, 6.0, 17.25, 0.0, 5.5, 19.5, 16.75, 10.5, 1.0, 16.75,
            18.5, 18.5, 11.75, 6.25, 16.0, 8.5, 15.0, 1.25, 0.5, 15.75, 5.0, 6.25,
            15.0, 3.5, 19.5, 15.75, 18.75, 0.75, 9.25, 18.0, 7.75, 13.0, 15.5, 6.0,
            11.0, 13.75, 11.0, 3.0, 8.0, 14.5, 2.5, 17.25, 10.0, 15.5, 16.5, 11.75,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [
            0.0, 6.25, 23.75, 25.75, 14.0, 20.5, 10.5, nil, 33.5, 18.75, 33.75, 13.5,
            21.25, 15.0, 13.75, 26.75, 37.75, 31.75, 32.25, 27.25, 28.0, 13.75, 14.0, 37.25,
            17.25, 10.5, 28.0, 22.25, 13.5, 35.5,
        ]
        #expect((0 ..< 30).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 30).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 30 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // The W overload: the same distances.
        let reference = graph.dijkstraShortestPaths(from: 0) { w[$0] }
        #expect((0 ..< 30).map { reference.distance(to: $0) } == expected)
    }

    @Test("SR-274 Int.max weight is zero: no trap, not reached (TropicalSemiring<Int>)")
    func sr274() {
        // dijkstraShortestPaths(from: 0) → [0, 5, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w: [Int] = [5, Int.max]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [0, 5, nil]
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 3 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-301 against brute force over simple paths (BottleneckSemiring<Int>)")
    func sr301() {
        // dijkstraShortestPaths(from: 0) → [Int.max, -3, 7, 7, -3, 26, -3, 6, -3]
        let graph = DirectedPseudograph(vertices: 0 ..< 9, edges: [
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 4, to: 7),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 6, to: 2),
            DirectedEdge(from: 7, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 6, to: 1), DirectedEdge(from: 7, to: 4),
            DirectedEdge(from: 8, to: 7), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 4, to: 8),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 8, to: 3),
            DirectedEdge(from: 5, to: 2), DirectedEdge(from: 5, to: 7), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 7),
        ])
        let w: [Int] = [
            26, 8, 30, 7, 30, 12, -5, 18, 27, 25, 16, -3,
            -3, 14, -1, 28, 25, -4, -3, 25, 7, 6, 3, -5,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [Int?] = [Int.max, -3, 7, 7, -3, 26, -3, 6, -3]
        #expect((0 ..< 9).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 9).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 9).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 9 {
            guard let path = tree.path(to: v) else { continue }
            var product = BottleneckSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BottleneckSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-302 against brute force over simple paths (BottleneckSemiring<Int>)")
    func sr302() throws {
        // floydWarshallShortestPaths() → [Int.max, -3, 7, 7, -3, 26, -3, 6, -3; 30, Int.max, 7, 8, -1, 26, -1, 6, 8; -5, -5, Int.max, 25, -5, -5, -5, -5, -5; -5, -5, -5, Int.max, -5, -5, -5, -5, -5; 7, -3, 7, 30, Int.max, 7, -3, 7, 28; 6, -3 …
        let graph = DirectedPseudograph(vertices: 0 ..< 9, edges: [
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 4, to: 7),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 6, to: 2),
            DirectedEdge(from: 7, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 6, to: 1), DirectedEdge(from: 7, to: 4),
            DirectedEdge(from: 8, to: 7), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 4, to: 8),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 8, to: 3),
            DirectedEdge(from: 5, to: 2), DirectedEdge(from: 5, to: 7), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 7),
        ])
        let w: [Int] = [
            26, 8, 30, 7, 30, 12, -5, 18, 27, 25, 16, -3,
            -3, 14, -1, 28, 25, -4, -3, 25, 7, 6, 3, -5,
        ]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [Int.max, -3, 7, 7, -3, 26, -3, 6, -3],
            [30, Int.max, 7, 8, -1, 26, -1, 6, 8],
            [-5, -5, Int.max, 25, -5, -5, -5, -5, -5],
            [-5, -5, -5, Int.max, -5, -5, -5, -5, -5],
            [7, -3, 7, 30, Int.max, 7, -3, 7, 28],
            [6, -3, 7, 7, -3, Int.max, -3, 6, -3],
            [16, 16, 18, 18, 14, 16, Int.max, 7, 14],
            [27, -3, 7, 7, -3, 26, -3, Int.max, -3],
            [-3, -3, -3, 25, -3, -3, -3, -3, Int.max],
        ]
        #expect((0 ..< 9).map { i in (0 ..< 9).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 9).map { i in (0 ..< 9).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 9 {
            for j in 0 ..< 9 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = BottleneckSemiring<Int>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(BottleneckSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-303 against brute force over simple paths (BottleneckSemiring<Int>)")
    func sr303() {
        // dijkstraShortestPaths(from: 0) → [Int.max, 23, 0, 23, 22, 23, 23, 22, -5]
        let graph = DirectedPseudograph(vertices: 0 ..< 9, edges: [
            DirectedEdge(from: 4, to: 6), DirectedEdge(from: 5, to: 7), DirectedEdge(from: 7, to: 5), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 3, to: 5),
            DirectedEdge(from: 6, to: 0), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 7, to: 4), DirectedEdge(from: 3, to: 1),
            DirectedEdge(from: 4, to: 7), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 7, to: 6), DirectedEdge(from: 6, to: 7),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 3, to: 6), DirectedEdge(from: 8, to: 0),
            DirectedEdge(from: 2, to: 5), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 6, to: 1), DirectedEdge(from: 2, to: 6),
        ])
        let w: [Int] = [
            28, -2, 11, 0, 23, -1, 3, 27, 18, 14, -1, 24,
            24, 2, 28, 22, 23, 22, 25, -5, 13, -5, 18, -1,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [Int?] = [Int.max, 23, 0, 23, 22, 23, 23, 22, -5]
        #expect((0 ..< 9).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 9).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 9).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 9 {
            guard let path = tree.path(to: v) else { continue }
            var product = BottleneckSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BottleneckSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-304 against brute force over simple paths (BottleneckSemiring<Int>)")
    func sr304() throws {
        // floydWarshallShortestPaths() → [Int.max, 23, 0, 23, 22, 23, 23, 22, -5; 0, Int.max, 0, 0, 0, 0, 0, 0, -5; 14, 14, Int.max, 14, 14, 14, 14, 14, -5; 18, 24, 0, Int.max, 22, 27, 25, 22, -5; 18, 18, 0, 18, Int.max, 18, 28, 24, -5; -2,  …
        let graph = DirectedPseudograph(vertices: 0 ..< 9, edges: [
            DirectedEdge(from: 4, to: 6), DirectedEdge(from: 5, to: 7), DirectedEdge(from: 7, to: 5), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 7), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 3, to: 5),
            DirectedEdge(from: 6, to: 0), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 7, to: 4), DirectedEdge(from: 3, to: 1),
            DirectedEdge(from: 4, to: 7), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 7, to: 6), DirectedEdge(from: 6, to: 7),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 3, to: 6), DirectedEdge(from: 8, to: 0),
            DirectedEdge(from: 2, to: 5), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 6, to: 1), DirectedEdge(from: 2, to: 6),
        ])
        let w: [Int] = [
            28, -2, 11, 0, 23, -1, 3, 27, 18, 14, -1, 24,
            24, 2, 28, 22, 23, 22, 25, -5, 13, -5, 18, -1,
        ]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [Int.max, 23, 0, 23, 22, 23, 23, 22, -5],
            [0, Int.max, 0, 0, 0, 0, 0, 0, -5],
            [14, 14, Int.max, 14, 14, 14, 14, 14, -5],
            [18, 24, 0, Int.max, 22, 27, 25, 22, -5],
            [18, 18, 0, 18, Int.max, 18, 28, 24, -5],
            [-2, -2, -2, -2, -2, Int.max, -2, -2, -5],
            [18, 18, 0, 18, 22, 18, Int.max, 22, -5],
            [18, 18, 0, 18, 22, 18, 28, Int.max, -5],
            [-5, -5, -5, -5, -5, -5, -5, -5, Int.max],
        ]
        #expect((0 ..< 9).map { i in (0 ..< 9).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 9).map { i in (0 ..< 9).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 9 {
            for j in 0 ..< 9 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = BottleneckSemiring<Int>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(BottleneckSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-314 the same set as Traversal's descendants(of:) (BooleanSemiring)")
    func sr314() {
        // dijkstraShortestPaths(from: 0) → [true, —, —, —, —, —, true, —, —, —, true, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 12, edges: [
            DirectedEdge(from: 11, to: 9), DirectedEdge(from: 7, to: 11), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 3, to: 1),
            DirectedEdge(from: 0, to: 10), DirectedEdge(from: 5, to: 10), DirectedEdge(from: 2, to: 11), DirectedEdge(from: 11, to: 2),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 7, to: 6), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 11, to: 8),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 5, to: 9), DirectedEdge(from: 2, to: 9), DirectedEdge(from: 8, to: 4),
            DirectedEdge(from: 9, to: 0), DirectedEdge(from: 0, to: 6), DirectedEdge(from: 9, to: 4), DirectedEdge(from: 1, to: 0),
        ])
        let w: [Bool] = [
            true, true, true, true, true, true, true, true, true, true, true, true,
            true, true, true, true, true, true, true, true,
        ]
        let tree = graph.dijkstraShortestPaths(from: 0) { BooleanSemiring(w[$0]) }
        let expected: [Bool?] = [true, nil, nil, nil, nil, nil, true, nil, nil, nil, true, nil]
        #expect((0 ..< 12).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 12).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 12).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 12 {
            guard let path = tree.path(to: v) else { continue }
            var product = BooleanSemiring.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BooleanSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
        // Traversal's descendants(of:), with the source.
        #expect(Set((0 ..< 12).filter { tree.hasPath(to: $0) }) == graph.descendants(of: 0).union([0]))
    }

    @Test("SR-315 NetworkX transitive_closure(reflexive=True) (BooleanSemiring)")
    func sr315() throws {
        // floydWarshallShortestPaths() → [true, —, —, —, —, —, —, —, —, —; true, true, true, true, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, true, true, true, true, true, true, t …
        let graph = DirectedPseudograph(vertices: 0 ..< 10, edges: [
            DirectedEdge(from: 9, to: 2), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 5, to: 7),
            DirectedEdge(from: 6, to: 7), DirectedEdge(from: 7, to: 5), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 7, to: 0),
            DirectedEdge(from: 8, to: 6), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 8), DirectedEdge(from: 7, to: 4),
            DirectedEdge(from: 4, to: 5), DirectedEdge(from: 1, to: 0),
        ])
        let w: [Bool] = [
            true, true, true, true, true, true, true, true, true, true, true, true,
            true, true,
        ]
        let matrix = try #require(graph.floydWarshallShortestPaths { BooleanSemiring(w[$0]) })
        let expected: [[Bool?]] = [
            [true, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [true, true, true, true, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
            [true, nil, true, true, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
            [true, nil, true, nil, true, true, true, true, true, true],
        ]
        #expect((0 ..< 10).map { i in (0 ..< 10).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 10).map { i in (0 ..< 10).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 10 {
            for j in 0 ..< 10 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = BooleanSemiring.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(BooleanSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-338 against NetworkX all_simple_edge_paths (CountingSemiring<Int>)")
    func sr338() throws {
        // dagShortestDistances(from: 0) → [1, 2, 4, 19, 40, 80, 46, 436, 189, 1044]
        let graph = DirectedPseudograph(vertices: 0 ..< 10, edges: [
            DirectedEdge(from: 1, to: 6), DirectedEdge(from: 3, to: 8), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 5, to: 7), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 7, to: 9),
            DirectedEdge(from: 4, to: 7), DirectedEdge(from: 3, to: 7), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 0, to: 8),
            DirectedEdge(from: 6, to: 9), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 3, to: 7),
            DirectedEdge(from: 0, to: 4), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 4, to: 6), DirectedEdge(from: 4, to: 9),
            DirectedEdge(from: 4, to: 5), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 0, to: 2),
        ])
        let w: [Int] = [
            3, 2, 2, 1, 3, 3, 3, 2, 3, 1, 2, 3,
            2, 2, 1, 3, 2, 1, 1, 1, 2, 2, 3, 2,
            2,
        ]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 2, 4, 19, 40, 80, 46, 436, 189, 1044]
        #expect((0 ..< 10).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 10).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-339 against NetworkX all_simple_edge_paths (CountingSemiring<Int>)")
    func sr339() throws {
        // dagShortestDistances(from: 0) → [1, 0, 0, 0, 0, 1, 0, 5, 16, 49]
        let graph = DirectedPseudograph(vertices: 0 ..< 10, edges: [
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 5, to: 7), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 1, to: 4),
            DirectedEdge(from: 5, to: 7), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 1, to: 7), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 2, to: 7), DirectedEdge(from: 2, to: 5), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 1, to: 9),
            DirectedEdge(from: 0, to: 9), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 7, to: 9),
            DirectedEdge(from: 7, to: 8), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 0, to: 7), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 5, to: 9),
            DirectedEdge(from: 4, to: 9),
        ])
        let w: [Int] = [
            1, 2, 2, 3, 2, 2, 2, 1, 3, 2, 2, 2,
            1, 1, 1, 3, 3, 1, 1, 1, 3, 2, 1, 1,
            3,
        ]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 0, 0, 0, 0, 1, 0, 5, 16, 49]
        #expect((0 ..< 10).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 10).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-340 against NetworkX all_simple_edge_paths (CountingSemiring<Int>)")
    func sr340() throws {
        // dagShortestDistances(from: 0) → [1, 2, 0, 2, 9, 6, 27, 91, 64, 198]
        let graph = DirectedPseudograph(vertices: 0 ..< 10, edges: [
            DirectedEdge(from: 2, to: 5), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 6, to: 8), DirectedEdge(from: 1, to: 8),
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 5, to: 9), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 8, to: 9),
            DirectedEdge(from: 6, to: 7), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 2, to: 6),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 8), DirectedEdge(from: 4, to: 6), DirectedEdge(from: 2, to: 5),
            DirectedEdge(from: 1, to: 5), DirectedEdge(from: 0, to: 6), DirectedEdge(from: 1, to: 8), DirectedEdge(from: 1, to: 7),
            DirectedEdge(from: 5, to: 7),
        ])
        let w: [Int] = [
            1, 3, 1, 3, 1, 1, 1, 3, 3, 1, 1, 3,
            3, 1, 2, 1, 3, 3, 2, 3, 1, 3, 2, 2,
            1,
        ]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 2, 0, 2, 9, 6, 27, 91, 64, 198]
        #expect((0 ..< 10).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 10).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }
}
