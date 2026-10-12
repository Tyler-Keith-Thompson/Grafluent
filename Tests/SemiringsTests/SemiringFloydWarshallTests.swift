// Floyd–Warshall over a selective semiring (catalog Floyd–Warshall rows): all-pairs shortest and
// widest paths, Warshall's reflexive transitive closure, nil when a diagonal entry ends better
// than one (a negative cycle or loop).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: Floyd–Warshall over a selective semiring")
struct SemiringFloydWarshallTests {
    @Test("SR-235 small digraph (TropicalSemiring<Int>)")
    func sr235() throws {
        // floydWarshallShortestPaths() → [0, 3, 1, 4, —; —, 0, —, 1, —; —, 2, 0, 3, —; —, —, —, 0, —; —, —, —, —, 0]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [0, 3, 1, 4, nil],
            [nil, 0, nil, 1, nil],
            [nil, 2, 0, 3, nil],
            [nil, nil, nil, 0, nil],
            [nil, nil, nil, nil, 0],
        ]
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 5 {
            for j in 0 ..< 5 {
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
    }

    @Test("SR-236 parallel edges, a loop and a cycle (TropicalSemiring<Int>)")
    func sr236() throws {
        // floydWarshallShortestPaths() → [0, 2, 6; 5, 0, 4; 1, 3, 0]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Int] = [5, 2, 3, 4, 1]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [0, 2, 6],
            [5, 0, 4],
            [1, 3, 0],
        ]
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
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
    }

    @Test("SR-237 negative weights (TropicalSemiring<Int>)")
    func sr237() throws {
        // floydWarshallShortestPaths() → [0, -2, 2, -4; —, 0, 4, -2; —, —, 0, -6; —, —, —, 0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [0, -2, 2, -4],
            [nil, 0, 4, -2],
            [nil, nil, 0, -6],
            [nil, nil, nil, 0],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
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
    }

    @Test("SR-238 a negative cycle (TropicalSemiring<Int>)")
    func sr238() {
        // floydWarshallShortestPaths() → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, -3, 1, 2]
        #expect(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-239 undirected through .directedView (TropicalSemiring<Int>)")
    func sr239() throws {
        // floydWarshallShortestPaths() → [0, 2, 9, 9; 2, 0, 7, 8; 9, 7, 0, 1; 9, 8, 1, 0]
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3)])
        let directed = graph.directedView
        let w: [Int] = [2, 7, 1, 9]
        let matrix = try #require(directed.floydWarshallShortestPaths { TropicalSemiring(w[$0.position]) })
        let expected: [[Int?]] = [
            [0, 2, 9, 9],
            [2, 0, 7, 8],
            [9, 7, 0, 1],
            [9, 8, 1, 0],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Int>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e.position]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-240 a negative loop (TropicalSemiring<Int>)")
    func sr240() {
        // floydWarshallShortestPaths() → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 2)])
        let w: [Int] = [-1, 3]
        #expect(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-258 small digraph (TropicalSemiring<Double>)")
    func sr258() throws {
        // floydWarshallShortestPaths() → [0.0, 3.0, 1.0, 4.0, —; —, 0.0, —, 1.0, —; —, 2.0, 0.0, 3.0, —; —, —, —, 0.0, —; —, —, —, —, 0.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Double?]] = [
            [0.0, 3.0, 1.0, 4.0, nil],
            [nil, 0.0, nil, 1.0, nil],
            [nil, 2.0, 0.0, 3.0, nil],
            [nil, nil, nil, 0.0, nil],
            [nil, nil, nil, nil, 0.0],
        ]
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 5 {
            for j in 0 ..< 5 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-259 parallel edges, a loop and a cycle (TropicalSemiring<Double>)")
    func sr259() throws {
        // floydWarshallShortestPaths() → [0.0, 2.0, 6.0; 5.0, 0.0, 4.0; 1.0, 3.0, 0.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Double] = [5.0, 2.0, 3.0, 4.0, 1.0]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Double?]] = [
            [0.0, 2.0, 6.0],
            [5.0, 0.0, 4.0],
            [1.0, 3.0, 0.0],
        ]
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-260 negative weights (TropicalSemiring<Double>)")
    func sr260() throws {
        // floydWarshallShortestPaths() → [0.0, -2.0, 2.0, -4.0; —, 0.0, 4.0, -2.0; —, —, 0.0, -6.0; —, —, —, 0.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let matrix = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) })
        let expected: [[Double?]] = [
            [0.0, -2.0, 2.0, -4.0],
            [nil, 0.0, 4.0, -2.0],
            [nil, nil, 0.0, -6.0],
            [nil, nil, nil, 0.0],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-261 a negative cycle (TropicalSemiring<Double>)")
    func sr261() {
        // floydWarshallShortestPaths() → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, -3.0, 1.0, 2.0]
        #expect(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-262 undirected through .directedView (TropicalSemiring<Double>)")
    func sr262() throws {
        // floydWarshallShortestPaths() → [0.0, 2.0, 9.0, 9.0; 2.0, 0.0, 7.0, 8.0; 9.0, 7.0, 0.0, 1.0; 9.0, 8.0, 1.0, 0.0]
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3)])
        let directed = graph.directedView
        let w: [Double] = [2.0, 7.0, 1.0, 9.0]
        let matrix = try #require(directed.floydWarshallShortestPaths { TropicalSemiring(w[$0.position]) })
        let expected: [[Double?]] = [
            [0.0, 2.0, 9.0, 9.0],
            [2.0, 0.0, 7.0, 8.0],
            [9.0, 7.0, 0.0, 1.0],
            [9.0, 8.0, 1.0, 0.0],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = TropicalSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(TropicalSemiring(w[e.position]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-263 a negative loop (TropicalSemiring<Double>)")
    func sr263() {
        // floydWarshallShortestPaths() → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 2)])
        let w: [Double] = [-1.0, 3.0]
        #expect(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-285 all-pairs widest paths (BottleneckSemiring<Int>)")
    func sr285() throws {
        // floydWarshallShortestPaths() → [Int.max, 5, 4, 4, 4; —, Int.max, 4, 4, 4; —, —, Int.max, 6, 6; —, —, —, Int.max, 7; —, —, —, —, Int.max]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Int] = [5, 3, 4, 2, 6, 7, 1]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [Int.max, 5, 4, 4, 4],
            [nil, Int.max, 4, 4, 4],
            [nil, nil, Int.max, 6, 6],
            [nil, nil, nil, Int.max, 7],
            [nil, nil, nil, nil, Int.max],
        ]
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 5 {
            for j in 0 ..< 5 {
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

    @Test("SR-286 parallel widths and a cycle (BottleneckSemiring<Int>)")
    func sr286() throws {
        // floydWarshallShortestPaths() → [Int.max, 8, 2, 5; —, Int.max, 2, 5; —, 9, Int.max, 5; —, —, —, Int.max]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 3),
        ])
        let w: [Int] = [3, 8, 2, 9, 5]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [Int.max, 8, 2, 5],
            [nil, Int.max, 2, 5],
            [nil, 9, Int.max, 5],
            [nil, nil, nil, Int.max],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
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

    @Test("SR-287 a 'negative' cycle is harmless (BottleneckSemiring<Int>)")
    func sr287() throws {
        // floydWarshallShortestPaths() → [Int.max, 1, -3, -3; —, Int.max, -3, -3; —, 1, Int.max, 2; —, —, —, Int.max]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, -3, 1, 2]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Int?]] = [
            [Int.max, 1, -3, -3],
            [nil, Int.max, -3, -3],
            [nil, 1, Int.max, 2],
            [nil, nil, nil, Int.max],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
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

    @Test("SR-298 all-pairs widest paths (BottleneckSemiring<Double>)")
    func sr298() throws {
        // floydWarshallShortestPaths() → [.infinity, 5.0, 4.0, 4.0, 4.0; —, .infinity, 4.0, 4.0, 4.0; —, —, .infinity, 6.0, 6.0; —, —, —, .infinity, 7.0; —, —, —, —, .infinity]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Double] = [5.0, 3.0, 4.0, 2.0, 6.0, 7.0, 1.0]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Double?]] = [
            [Double.infinity, 5.0, 4.0, 4.0, 4.0],
            [nil, Double.infinity, 4.0, 4.0, 4.0],
            [nil, nil, Double.infinity, 6.0, 6.0],
            [nil, nil, nil, Double.infinity, 7.0],
            [nil, nil, nil, nil, Double.infinity],
        ]
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 5).map { i in (0 ..< 5).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 5 {
            for j in 0 ..< 5 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = BottleneckSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(BottleneckSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-299 parallel widths and a cycle (BottleneckSemiring<Double>)")
    func sr299() throws {
        // floydWarshallShortestPaths() → [.infinity, 8.0, 2.0, 5.0; —, .infinity, 2.0, 5.0; —, 9.0, .infinity, 5.0; —, —, —, .infinity]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 3),
        ])
        let w: [Double] = [3.0, 8.0, 2.0, 9.0, 5.0]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Double?]] = [
            [Double.infinity, 8.0, 2.0, 5.0],
            [nil, Double.infinity, 2.0, 5.0],
            [nil, 9.0, Double.infinity, 5.0],
            [nil, nil, nil, Double.infinity],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = BottleneckSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(BottleneckSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-300 a 'negative' cycle is harmless (BottleneckSemiring<Double>)")
    func sr300() throws {
        // floydWarshallShortestPaths() → [.infinity, 1.0, -3.0, -3.0; —, .infinity, -3.0, -3.0; —, 1.0, .infinity, 2.0; —, —, —, .infinity]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, -3.0, 1.0, 2.0]
        let matrix = try #require(graph.floydWarshallShortestPaths { BottleneckSemiring(w[$0]) })
        let expected: [[Double?]] = [
            [Double.infinity, 1.0, -3.0, -3.0],
            [nil, Double.infinity, -3.0, -3.0],
            [nil, 1.0, Double.infinity, 2.0],
            [nil, nil, nil, Double.infinity],
        ]
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 4).map { i in (0 ..< 4).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                let path = matrix.path(from: i, to: j)
                #expect((path == nil) == (expected[i][j] == nil))
                guard let path else { continue }
                var product = BottleneckSemiring<Double>.one
                for (k, e) in path.edges.enumerated() {
                    #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                    product = product.times(BottleneckSemiring(w[e]))
                }
                #expect(path.vertices.first == i && path.vertices.last == j)
                #expect(product == matrix.distance(from: i, to: j))
            }
        }
    }

    @Test("SR-307 reflexive transitive closure (Warshall) (BooleanSemiring)")
    func sr307() throws {
        // floydWarshallShortestPaths() → [true, true, true, —, —, —; true, true, true, —, —, —; true, true, true, —, —, —; —, —, —, true, true, —; —, —, —, —, true, —; —, —, —, —, —, true]
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 5, to: 5),
        ])
        let w: [Bool] = [true, true, true, false, true, true]
        let matrix = try #require(graph.floydWarshallShortestPaths { BooleanSemiring(w[$0]) })
        let expected: [[Bool?]] = [
            [true, true, true, nil, nil, nil],
            [true, true, true, nil, nil, nil],
            [true, true, true, nil, nil, nil],
            [nil, nil, nil, true, true, nil],
            [nil, nil, nil, nil, true, nil],
            [nil, nil, nil, nil, nil, true],
        ]
        #expect((0 ..< 6).map { i in (0 ..< 6).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 6).map { i in (0 ..< 6).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 6).map { i in (0 ..< 6).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 6 {
            for j in 0 ..< 6 {
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

    @Test("SR-310 reflexive transitive closure (Warshall) (BooleanSemiring)")
    func sr310() throws {
        // floydWarshallShortestPaths() → [true, true, true; true, true, true; true, true, true]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Bool] = [true, false, true, true, true]
        let matrix = try #require(graph.floydWarshallShortestPaths { BooleanSemiring(w[$0]) })
        let expected: [[Bool?]] = [
            [true, true, true],
            [true, true, true],
            [true, true, true],
        ]
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(from: i, to: $0)?.value } } == expected)
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(fromIndex: i, toIndex: $0)?.value } } == expected)
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })
        // Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
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
}
