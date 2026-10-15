// DAG paths over a selective semiring and dagShortestDistances over any semiring (catalog DAG and
// DAG distances rows): nil when a cycle is reachable, the maintained order of
// DirectedAcyclicGraph, path counting with CountingSemiring (2^k, lattice paths, up to C(66, 33)),
// weighted path sums, and several sources adding.
// Generated from cases.md by swiftgen.py; see README.md.

import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: DAG paths and Mohri's shortest distances")
struct SemiringDAGTests {
    @Test("SR-231 negative weights (TropicalSemiring<Int>)")
    func sr231() throws {
        // dagShortestPaths(from: 0) → [0, -2, 2, -4]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let tree = try #require(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [0, -2, 2, -4]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
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

    @Test("SR-232 a reachable cycle (TropicalSemiring<Int>)")
    func sr232() {
        // dagShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Int] = [5, 2, 3, 4, 1]
        #expect(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-233 the maintained order (DirectedAcyclicGraph) (TropicalSemiring<Int>)")
    func sr233() throws {
        // DirectedAcyclicGraph(g).dagShortestPaths(from: 1) → [—, 0, 4, -2]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let dag = try #require(DirectedAcyclicGraph(graph))
        let tree = dag.dagShortestPaths(from: 1) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [nil, 0, 4, -2]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [1])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(dag.source(ofEdgeAt: e) == path.vertices[k] && dag.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-234 a selective semiring: the same as dagShortestPaths, zero where unreached (TropicalSemiring<Int>)")
    func sr234() throws {
        // dagShortestDistances(from: 1) → [Int.max, 0, 4, -2]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let distances = try #require(graph.dagShortestDistances(from: 1) { TropicalSemiring(w[$0]) })
        let expected: [Int] = [Int.max, 0, 4, -2]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [1])
        // The same as dagShortestPaths, with zero where it reaches nothing.
        let tree = try #require(graph.dagShortestPaths(from: 1) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 4).map { tree.distance(to: $0) ?? .zero } == (0 ..< 4).map { distances.distance(to: $0) })
    }

    @Test("SR-254 negative weights (TropicalSemiring<Double>)")
    func sr254() throws {
        // dagShortestPaths(from: 0) → [0.0, -2.0, 2.0, -4.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let tree = try #require(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Double?] = [0.0, -2.0, 2.0, -4.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
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
    }

    @Test("SR-255 a reachable cycle (TropicalSemiring<Double>)")
    func sr255() {
        // dagShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Double] = [5.0, 2.0, 3.0, 4.0, 1.0]
        #expect(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-256 the maintained order (DirectedAcyclicGraph) (TropicalSemiring<Double>)")
    func sr256() throws {
        // DirectedAcyclicGraph(g).dagShortestPaths(from: 1) → [—, 0.0, 4.0, -2.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let dag = try #require(DirectedAcyclicGraph(graph))
        let tree = dag.dagShortestPaths(from: 1) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [nil, 0.0, 4.0, -2.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [1])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(dag.source(ofEdgeAt: e) == path.vertices[k] && dag.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-257 a selective semiring: the same as dagShortestPaths, zero where unreached (TropicalSemiring<Double>)")
    func sr257() throws {
        // dagShortestDistances(from: 1) → [.infinity, 0.0, 4.0, -2.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let distances = try #require(graph.dagShortestDistances(from: 1) { TropicalSemiring(w[$0]) })
        let expected: [Double] = [Double.infinity, 0.0, 4.0, -2.0]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [1])
        // The same as dagShortestPaths, with zero where it reaches nothing.
        let tree = try #require(graph.dagShortestPaths(from: 1) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 4).map { tree.distance(to: $0) ?? .zero } == (0 ..< 4).map { distances.distance(to: $0) })
    }

    @Test("SR-284 widest paths in a DAG (BottleneckSemiring<Int>)")
    func sr284() throws {
        // dagShortestPaths(from: 0) → [Int.max, -2, 3, -2]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let tree = try #require(graph.dagShortestPaths(from: 0) { BottleneckSemiring(w[$0]) })
        let expected: [Int?] = [Int.max, -2, 3, -2]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
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

    @Test("SR-297 widest paths in a DAG (BottleneckSemiring<Double>)")
    func sr297() throws {
        // dagShortestPaths(from: 0) → [.infinity, -2.0, 3.0, -2.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let tree = try #require(graph.dagShortestPaths(from: 0) { BottleneckSemiring(w[$0]) })
        let expected: [Double?] = [Double.infinity, -2.0, 3.0, -2.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = BottleneckSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BottleneckSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-312 reachability in a DAG (BooleanSemiring)")
    func sr312() throws {
        // dagShortestPaths(from: 0) → [true, true, true, true, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 4, to: 3),
        ])
        let w: [Bool] = [true, true, true, false, true]
        let tree = try #require(graph.dagShortestPaths(from: 0) { BooleanSemiring(w[$0]) })
        let expected: [Bool?] = [true, true, true, true, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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
    }

    @Test("SR-313 reachability in a DAG, false where unreached (BooleanSemiring)")
    func sr313() throws {
        // dagShortestDistances(from: 0) → [true, true, true, true, false]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 4, to: 3),
        ])
        let w: [Bool] = [true, true, true, false, true]
        let distances = try #require(graph.dagShortestDistances(from: 0) { BooleanSemiring(w[$0]) })
        let expected: [Bool] = [true, true, true, true, false]
        #expect((0 ..< 5).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 5).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
        // The same as dagShortestPaths, with zero where it reaches nothing.
        let tree = try #require(graph.dagShortestPaths(from: 0) { BooleanSemiring(w[$0]) })
        #expect((0 ..< 5).map { tree.distance(to: $0) ?? .zero } == (0 ..< 5).map { distances.distance(to: $0) })
    }

    @Test("SR-316 paths in a diamond chain: 2^k (CountingSemiring<Int>)")
    func sr316() throws {
        // dagShortestDistances(from: 0) → [1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32, 64, 64, 128, 128, 256, 256, 512, 512, 1024]
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 10 {
            edges += [DirectedEdge(from: 2 * i, to: 2 * i + 1), DirectedEdge(from: 2 * i, to: 2 * i + 2), DirectedEdge(from: 2 * i + 1, to: 2 * i + 2)]
        }
        #expect(edges.count == 30)
        let graph = DirectedPseudograph(vertices: 0 ..< 21, edges: edges)
        let w = [Int](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [
            1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32,
            64, 64, 128, 128, 256, 256, 512, 512, 1024,
        ]
        #expect((0 ..< 21).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 21).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-317 lattice paths: C(r+c−2, r−1) (CountingSemiring<Int>)")
    func sr317() throws {
        // dagShortestDistances(from: 0) → [1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 1, 3, 6, 10, 15, 1, 4, 10, 20, 35]
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 4 {
            for j in 0 ..< 5 {
                if j + 1 < 5 { edges.append(DirectedEdge(from: i * 5 + j, to: i * 5 + j + 1)) }
                if i + 1 < 4 { edges.append(DirectedEdge(from: i * 5 + j, to: (i + 1) * 5 + j)) }
            }
        }
        #expect(edges.count == 31)
        let graph = DirectedPseudograph(vertices: 0 ..< 20, edges: edges)
        let w = [Int](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [
            1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 1, 3,
            6, 10, 15, 1, 4, 10, 20, 35,
        ]
        #expect((0 ..< 20).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 20).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-318 parallel edges count separately (CountingSemiring<Int>)")
    func sr318() throws {
        // dagShortestDistances(from: 0) → [1, 2, 3]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])
        let w: [Int] = [1, 1, 1, 1]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 2, 3]
        #expect((0 ..< 3).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 3).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-319 weights multiply along a path and add across paths (CountingSemiring<Int>)")
    func sr319() throws {
        // dagShortestDistances(from: 0) → [1, 2, 3, 32]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 0, to: 3),
        ])
        let w: [Int] = [2, 3, 5, 7, 1]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 2, 3, 32]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-320 a reachable cycle: nil (CountingSemiring<Int>)")
    func sr320() {
        // dagShortestDistances(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Int] = [1, 1, 1]
        #expect(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) } == nil)
    }

    @Test("SR-321 a cycle not reachable is fine (CountingSemiring<Int>)")
    func sr321() throws {
        // dagShortestDistances(from: 0) → [1, 1, 0, 0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let w: [Int] = [1, 1, 1]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 1, 0, 0]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-322 several sources add (a source reached from another counts both) (CountingSemiring<Int>)")
    func sr322() throws {
        // dagShortestDistances(from: [0, 2]) → [1, 1, 3, 3]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, 1, 1, 1]
        let distances = try #require(graph.dagShortestDistances(from: [0, 2]) { CountingSemiring(w[$0]) })
        let expected: [Int] = [1, 1, 3, 3]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0, 2])
    }

    @Test("SR-323 the maintained order (DirectedAcyclicGraph) (CountingSemiring<Int>)")
    func sr323() throws {
        // DirectedAcyclicGraph(g).dagShortestDistances(from: 0) → [1, 1, 1, 2]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, 1, 1, 1]
        let dag = try #require(DirectedAcyclicGraph(graph))
        let distances = dag.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        let expected: [Int] = [1, 1, 1, 2]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-325 paths in a diamond chain: 2^k (CountingSemiring<Double>)")
    func sr325() throws {
        // dagShortestDistances(from: 0) → [1.0, 1.0, 2.0, 2.0, 4.0, 4.0, 8.0, 8.0, 16.0, 16.0, 32.0, 32.0, 64.0, 64.0, 128.0, 128.0, 256.0, 256.0, 512.0, 512.0, 1024.0]
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 10 {
            edges += [DirectedEdge(from: 2 * i, to: 2 * i + 1), DirectedEdge(from: 2 * i, to: 2 * i + 2), DirectedEdge(from: 2 * i + 1, to: 2 * i + 2)]
        }
        #expect(edges.count == 30)
        let graph = DirectedPseudograph(vertices: 0 ..< 21, edges: edges)
        let w = [Double](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Double] = [
            1.0, 1.0, 2.0, 2.0, 4.0, 4.0, 8.0, 8.0, 16.0, 16.0, 32.0, 32.0,
            64.0, 64.0, 128.0, 128.0, 256.0, 256.0, 512.0, 512.0, 1024.0,
        ]
        #expect((0 ..< 21).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 21).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-326 lattice paths: C(r+c−2, r−1) (CountingSemiring<Double>)")
    func sr326() throws {
        // dagShortestDistances(from: 0) → [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 4.0, 5.0, 1.0, 3.0, 6.0, 10.0, 15.0, 1.0, 4.0, 10.0, 20.0, 35.0]
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 4 {
            for j in 0 ..< 5 {
                if j + 1 < 5 { edges.append(DirectedEdge(from: i * 5 + j, to: i * 5 + j + 1)) }
                if i + 1 < 4 { edges.append(DirectedEdge(from: i * 5 + j, to: (i + 1) * 5 + j)) }
            }
        }
        #expect(edges.count == 31)
        let graph = DirectedPseudograph(vertices: 0 ..< 20, edges: edges)
        let w = [Double](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Double] = [
            1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 4.0, 5.0, 1.0, 3.0,
            6.0, 10.0, 15.0, 1.0, 4.0, 10.0, 20.0, 35.0,
        ]
        #expect((0 ..< 20).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 20).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-327 parallel edges count separately (CountingSemiring<Double>)")
    func sr327() throws {
        // dagShortestDistances(from: 0) → [1.0, 2.0, 3.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])
        let w: [Double] = [1.0, 1.0, 1.0, 1.0]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Double] = [1.0, 2.0, 3.0]
        #expect((0 ..< 3).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 3).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-328 weights multiply along a path and add across paths (CountingSemiring<Double>)")
    func sr328() throws {
        // dagShortestDistances(from: 0) → [1.0, 2.0, 3.0, 32.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 0, to: 3),
        ])
        let w: [Double] = [2.0, 3.0, 5.0, 7.0, 1.0]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Double] = [1.0, 2.0, 3.0, 32.0]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-329 a reachable cycle: nil (CountingSemiring<Double>)")
    func sr329() {
        // dagShortestDistances(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Double] = [1.0, 1.0, 1.0]
        #expect(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) } == nil)
    }

    @Test("SR-330 a cycle not reachable is fine (CountingSemiring<Double>)")
    func sr330() throws {
        // dagShortestDistances(from: 0) → [1.0, 1.0, 0.0, 0.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let w: [Double] = [1.0, 1.0, 1.0]
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Double] = [1.0, 1.0, 0.0, 0.0]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    @Test("SR-331 several sources add (a source reached from another counts both) (CountingSemiring<Double>)")
    func sr331() throws {
        // dagShortestDistances(from: [0, 2]) → [1.0, 1.0, 3.0, 3.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, 1.0, 1.0, 1.0]
        let distances = try #require(graph.dagShortestDistances(from: [0, 2]) { CountingSemiring(w[$0]) })
        let expected: [Double] = [1.0, 1.0, 3.0, 3.0]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0, 2])
    }

    @Test("SR-332 the maintained order (DirectedAcyclicGraph) (CountingSemiring<Double>)")
    func sr332() throws {
        // DirectedAcyclicGraph(g).dagShortestDistances(from: 0) → [1.0, 1.0, 1.0, 2.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, 1.0, 1.0, 1.0]
        let dag = try #require(DirectedAcyclicGraph(graph))
        let distances = dag.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        let expected: [Double] = [1.0, 1.0, 1.0, 2.0]
        #expect((0 ..< 4).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 4).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }

    #if _pointerBitWidth(_64)
    @Test("SR-334 the largest diamond chain that fits: 2^62 (CountingSemiring<Int>)")
    func sr334() throws {
        // dagShortestDistances(from: 0) → [1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32, 64, 64, 128, 128, 256, 256, 512, 512, 1024, 1024, 2048, 2048, 4096, 4096, 8192, 8192, 16384, 16384, 32768, 32768, 65536, 65536, 131072, 131072, 262144, 262144, …
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 62 {
            edges += [DirectedEdge(from: 2 * i, to: 2 * i + 1), DirectedEdge(from: 2 * i, to: 2 * i + 2), DirectedEdge(from: 2 * i + 1, to: 2 * i + 2)]
        }
        #expect(edges.count == 186)
        let graph = DirectedPseudograph(vertices: 0 ..< 125, edges: edges)
        let w = [Int](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [
            1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32,
            64, 64, 128, 128, 256, 256, 512, 512, 1024, 1024, 2048, 2048,
            4096, 4096, 8192, 8192, 16384, 16384, 32768, 32768, 65536, 65536, 131072, 131072,
            262144, 262144, 524288, 524288, 1048576, 1048576, 2097152, 2097152, 4194304, 4194304, 8388608, 8388608,
            16777216, 16777216, 33554432, 33554432, 67108864, 67108864, 134217728, 134217728, 268435456, 268435456, 536870912, 536870912,
            1073741824, 1073741824, 2147483648, 2147483648, 4294967296, 4294967296, 8589934592, 8589934592, 17179869184, 17179869184, 34359738368, 34359738368,
            68719476736, 68719476736, 137438953472, 137438953472, 274877906944, 274877906944, 549755813888, 549755813888, 1099511627776, 1099511627776, 2199023255552, 2199023255552,
            4398046511104, 4398046511104, 8796093022208, 8796093022208, 17592186044416, 17592186044416, 35184372088832, 35184372088832, 70368744177664, 70368744177664, 140737488355328, 140737488355328,
            281474976710656, 281474976710656, 562949953421312, 562949953421312, 1125899906842624, 1125899906842624, 2251799813685248, 2251799813685248, 4503599627370496, 4503599627370496, 9007199254740992, 9007199254740992,
            18014398509481984, 18014398509481984, 36028797018963968, 36028797018963968, 72057594037927936, 72057594037927936, 144115188075855872, 144115188075855872, 288230376151711744, 288230376151711744, 576460752303423488, 576460752303423488,
            1152921504606846976, 1152921504606846976, 2305843009213693952, 2305843009213693952, 4611686018427387904,
        ]
        #expect((0 ..< 125).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 125).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }
    #endif

    #if _pointerBitWidth(_64)
    @Test("SR-336 C(66,33) fits (CountingSemiring<Int>)")
    func sr336() throws {
        // dagShortestDistances(from: 0) → [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 …
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 34 {
            for j in 0 ..< 34 {
                if j + 1 < 34 { edges.append(DirectedEdge(from: i * 34 + j, to: i * 34 + j + 1)) }
                if i + 1 < 34 { edges.append(DirectedEdge(from: i * 34 + j, to: (i + 1) * 34 + j)) }
            }
        }
        #expect(edges.count == 2244)
        let graph = DirectedPseudograph(vertices: 0 ..< 1156, edges: edges)
        let w = [Int](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) })
        let expected: [Int] = [
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
            3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
            15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
            27, 28, 29, 30, 31, 32, 33, 34, 1, 3, 6, 10,
            15, 21, 28, 36, 45, 55, 66, 78, 91, 105, 120, 136,
            153, 171, 190, 210, 231, 253, 276, 300, 325, 351, 378, 406,
            435, 465, 496, 528, 561, 595, 1, 4, 10, 20, 35, 56,
            84, 120, 165, 220, 286, 364, 455, 560, 680, 816, 969, 1140,
            1330, 1540, 1771, 2024, 2300, 2600, 2925, 3276, 3654, 4060, 4495, 4960,
            5456, 5984, 6545, 7140, 1, 5, 15, 35, 70, 126, 210, 330,
            495, 715, 1001, 1365, 1820, 2380, 3060, 3876, 4845, 5985, 7315, 8855,
            10626, 12650, 14950, 17550, 20475, 23751, 27405, 31465, 35960, 40920, 46376, 52360,
            58905, 66045, 1, 6, 21, 56, 126, 252, 462, 792, 1287, 2002,
            3003, 4368, 6188, 8568, 11628, 15504, 20349, 26334, 33649, 42504, 53130, 65780,
            80730, 98280, 118755, 142506, 169911, 201376, 237336, 278256, 324632, 376992, 435897, 501942,
            1, 7, 28, 84, 210, 462, 924, 1716, 3003, 5005, 8008, 12376,
            18564, 27132, 38760, 54264, 74613, 100947, 134596, 177100, 230230, 296010, 376740, 475020,
            593775, 736281, 906192, 1107568, 1344904, 1623160, 1947792, 2324784, 2760681, 3262623, 1, 8,
            36, 120, 330, 792, 1716, 3432, 6435, 11440, 19448, 31824, 50388, 77520,
            116280, 170544, 245157, 346104, 480700, 657800, 888030, 1184040, 1560780, 2035800, 2629575, 3365856,
            4272048, 5379616, 6724520, 8347680, 10295472, 12620256, 15380937, 18643560, 1, 9, 45, 165,
            495, 1287, 3003, 6435, 12870, 24310, 43758, 75582, 125970, 203490, 319770, 490314,
            735471, 1081575, 1562275, 2220075, 3108105, 4292145, 5852925, 7888725, 10518300, 13884156, 18156204, 23535820,
            30260340, 38608020, 48903492, 61523748, 76904685, 95548245, 1, 10, 55, 220, 715, 2002,
            5005, 11440, 24310, 48620, 92378, 167960, 293930, 497420, 817190, 1307504, 2042975, 3124550,
            4686825, 6906900, 10015005, 14307150, 20160075, 28048800, 38567100, 52451256, 70607460, 94143280, 124403620, 163011640,
            211915132, 273438880, 350343565, 445891810, 1, 11, 66, 286, 1001, 3003, 8008, 19448,
            43758, 92378, 184756, 352716, 646646, 1144066, 1961256, 3268760, 5311735, 8436285, 13123110, 20030010,
            30045015, 44352165, 64512240, 92561040, 131128140, 183579396, 254186856, 348330136, 472733756, 635745396, 847660528, 1121099408,
            1471442973, 1917334783, 1, 12, 78, 364, 1365, 4368, 12376, 31824, 75582, 167960,
            352716, 705432, 1352078, 2496144, 4457400, 7726160, 13037895, 21474180, 34597290, 54627300, 84672315, 129024480,
            193536720, 286097760, 417225900, 600805296, 854992152, 1203322288, 1676056044, 2311801440, 3159461968, 4280561376, 5752004349, 7669339132,
            1, 13, 91, 455, 1820, 6188, 18564, 50388, 125970, 293930, 646646, 1352078,
            2704156, 5200300, 9657700, 17383860, 30421755, 51895935, 86493225, 141120525, 225792840, 354817320, 548354040, 834451800,
            1251677700, 1852482996, 2707475148, 3910797436, 5586853480, 7898654920, 11058116888, 15338678264, 21090682613, 28760021745, 1, 14,
            105, 560, 2380, 8568, 27132, 77520, 203490, 497420, 1144066, 2496144, 5200300, 10400600,
            20058300, 37442160, 67863915, 119759850, 206253075, 347373600, 573166440, 927983760, 1476337800, 2310789600, 3562467300, 5414950296,
            8122425444, 12033222880, 17620076360, 25518731280, 36576848168, 51915526432, 73006209045, 101766230790, 1, 15, 120, 680,
            3060, 11628, 38760, 116280, 319770, 817190, 1961256, 4457400, 9657700, 20058300, 40116600, 77558760,
            145422675, 265182525, 471435600, 818809200, 1391975640, 2319959400, 3796297200, 6107086800, 9669554100, 15084504396, 23206929840, 35240152720,
            52860229080, 78378960360, 114955808528, 166871334960, 239877544005, 341643774795, 1, 16, 136, 816, 3876, 15504,
            54264, 170544, 490314, 1307504, 3268760, 7726160, 17383860, 37442160, 77558760, 155117520, 300540195, 565722720,
            1037158320, 1855967520, 3247943160, 5567902560, 9364199760, 15471286560, 25140840660, 40225345056, 63432274896, 98672427616, 151532656696, 229911617056,
            344867425584, 511738760544, 751616304549, 1093260079344, 1, 17, 153, 969, 4845, 20349, 74613, 245157,
            735471, 2042975, 5311735, 13037895, 30421755, 67863915, 145422675, 300540195, 601080390, 1166803110, 2203961430, 4059928950,
            7307872110, 12875774670, 22239974430, 37711260990, 62852101650, 103077446706, 166509721602, 265182149218, 416714805914, 646626422970, 991493848554, 1503232609098,
            2254848913647, 3348108992991, 1, 18, 171, 1140, 5985, 26334, 100947, 346104, 1081575, 3124550,
            8436285, 21474180, 51895935, 119759850, 265182525, 565722720, 1166803110, 2333606220, 4537567650, 8597496600, 15905368710, 28781143380,
            51021117810, 88732378800, 151584480450, 254661927156, 421171648758, 686353797976, 1103068603890, 1749695026860, 2741188875414, 4244421484512, 6499270398159, 9847379391150,
            1, 19, 190, 1330, 7315, 33649, 134596, 480700, 1562275, 4686825, 13123110, 34597290,
            86493225, 206253075, 471435600, 1037158320, 2203961430, 4537567650, 9075135300, 17672631900, 33578000610, 62359143990, 113380261800, 202112640600,
            353697121050, 608359048206, 1029530696964, 1715884494940, 2818953098830, 4568648125690, 7309837001104, 11554258485616, 18053528883775, 27900908274925, 1, 20,
            210, 1540, 8855, 42504, 177100, 657800, 2220075, 6906900, 20030010, 54627300, 141120525, 347373600,
            818809200, 1855967520, 4059928950, 8597496600, 17672631900, 35345263800, 68923264410, 131282408400, 244662670200, 446775310800, 800472431850, 1408831480056,
            2438362177020, 4154246671960, 6973199770790, 11541847896480, 18851684897584, 30405943383200, 48459472266975, 76360380541900, 1, 21, 231, 1771,
            10626, 53130, 230230, 888030, 3108105, 10015005, 30045015, 84672315, 225792840, 573166440, 1391975640, 3247943160,
            7307872110, 15905368710, 33578000610, 68923264410, 137846528820, 269128937220, 513791607420, 960566918220, 1761039350070, 3169870830126, 5608233007146, 9762479679106,
            16735679449896, 28277527346376, 47129212243960, 77535155627160, 125994627894135, 202355008436035, 1, 22, 253, 2024, 12650, 65780,
            296010, 1184040, 4292145, 14307150, 44352165, 129024480, 354817320, 927983760, 2319959400, 5567902560, 12875774670, 28781143380,
            62359143990, 131282408400, 269128937220, 538257874440, 1052049481860, 2012616400080, 3773655750150, 6943526580276, 12551759587422, 22314239266528, 39049918716424, 67327446062800,
            114456658306760, 191991813933920, 317986441828055, 520341450264090, 1, 23, 276, 2300, 14950, 80730, 376740, 1560780,
            5852925, 20160075, 64512240, 193536720, 548354040, 1476337800, 3796297200, 9364199760, 22239974430, 51021117810, 113380261800, 244662670200,
            513791607420, 1052049481860, 2104098963720, 4116715363800, 7890371113950, 14833897694226, 27385657281648, 49699896548176, 88749815264600, 156077261327400, 270533919634160, 462525733568080,
            780512175396135, 1300853625660225, 1, 24, 300, 2600, 17550, 98280, 475020, 2035800, 7888725, 28048800,
            92561040, 286097760, 834451800, 2310789600, 6107086800, 15471286560, 37711260990, 88732378800, 202112640600, 446775310800, 960566918220, 2012616400080,
            4116715363800, 8233430727600, 16123801841550, 30957699535776, 58343356817424, 108043253365600, 196793068630200, 352870329957600, 623404249591760, 1085929983159840, 1866442158555975, 3167295784216200,
            1, 25, 325, 2925, 20475, 118755, 593775, 2629575, 10518300, 38567100, 131128140, 417225900,
            1251677700, 3562467300, 9669554100, 25140840660, 62852101650, 151584480450, 353697121050, 800472431850, 1761039350070, 3773655750150, 7890371113950, 16123801841550,
            32247603683100, 63205303218876, 121548660036300, 229591913401900, 426384982032100, 779255311989700, 1402659561581460, 2488589544741300, 4355031703297275, 7522327487513475, 1, 26,
            351, 3276, 23751, 142506, 736281, 3365856, 13884156, 52451256, 183579396, 600805296, 1852482996, 5414950296,
            15084504396, 40225345056, 103077446706, 254661927156, 608359048206, 1408831480056, 3169870830126, 6943526580276, 14833897694226, 30957699535776, 63205303218876, 126410606437752,
            247959266474052, 477551179875952, 903936161908052, 1683191473897752, 3085851035479212, 5574440580220512, 9929472283517787, 17451799771031262, 1, 27, 378, 3654,
            27405, 169911, 906192, 4272048, 18156204, 70607460, 254186856, 854992152, 2707475148, 8122425444, 23206929840, 63432274896,
            166509721602, 421171648758, 1029530696964, 2438362177020, 5608233007146, 12551759587422, 27385657281648, 58343356817424, 121548660036300, 247959266474052, 495918532948104, 973469712824056,
            1877405874732108, 3560597348629860, 6646448384109072, 12220888964329584, 22150361247847371, 39602161018878633, 1, 28, 406, 4060, 31465, 201376,
            1107568, 5379616, 23535820, 94143280, 348330136, 1203322288, 3910797436, 12033222880, 35240152720, 98672427616, 265182149218, 686353797976,
            1715884494940, 4154246671960, 9762479679106, 22314239266528, 49699896548176, 108043253365600, 229591913401900, 477551179875952, 973469712824056, 1946939425648112, 3824345300380220, 7384942649010080,
            14031391033119152, 26252279997448736, 48402641245296107, 88004802264174740, 1, 29, 435, 4495, 35960, 237336, 1344904, 6724520,
            30260340, 124403620, 472733756, 1676056044, 5586853480, 17620076360, 52860229080, 151532656696, 416714805914, 1103068603890, 2818953098830, 6973199770790,
            16735679449896, 39049918716424, 88749815264600, 196793068630200, 426384982032100, 903936161908052, 1877405874732108, 3824345300380220, 7648690600760440, 15033633249770520, 29065024282889672, 55317304280338408,
            103719945525634515, 191724747789809255, 1, 30, 465, 4960, 40920, 278256, 1623160, 8347680, 38608020, 163011640,
            635745396, 2311801440, 7898654920, 25518731280, 78378960360, 229911617056, 646626422970, 1749695026860, 4568648125690, 11541847896480, 28277527346376, 67327446062800,
            156077261327400, 352870329957600, 779255311989700, 1683191473897752, 3560597348629860, 7384942649010080, 15033633249770520, 30067266499541040, 59132290782430712, 114449595062769120, 218169540588403635, 409894288378212890,
            1, 31, 496, 5456, 46376, 324632, 1947792, 10295472, 48903492, 211915132, 847660528, 3159461968,
            11058116888, 36576848168, 114955808528, 344867425584, 991493848554, 2741188875414, 7309837001104, 18851684897584, 47129212243960, 114456658306760, 270533919634160, 623404249591760,
            1402659561581460, 3085851035479212, 6646448384109072, 14031391033119152, 29065024282889672, 59132290782430712, 118264581564861424, 232714176627630544, 450883717216034179, 860778005594247069, 1, 32,
            528, 5984, 52360, 376992, 2324784, 12620256, 61523748, 273438880, 1121099408, 4280561376, 15338678264, 51915526432,
            166871334960, 511738760544, 1503232609098, 4244421484512, 11554258485616, 30405943383200, 77535155627160, 191991813933920, 462525733568080, 1085929983159840, 2488589544741300, 5574440580220512,
            12220888964329584, 26252279997448736, 55317304280338408, 114449595062769120, 232714176627630544, 465428353255261088, 916312070471295267, 1777090076065542336, 1, 33, 561, 6545,
            58905, 435897, 2760681, 15380937, 76904685, 350343565, 1471442973, 5752004349, 21090682613, 73006209045, 239877544005, 751616304549,
            2254848913647, 6499270398159, 18053528883775, 48459472266975, 125994627894135, 317986441828055, 780512175396135, 1866442158555975, 4355031703297275, 9929472283517787, 22150361247847371, 48402641245296107,
            103719945525634515, 218169540588403635, 450883717216034179, 916312070471295267, 1832624140942590534, 3609714217008132870, 1, 34, 595, 7140, 66045, 501942,
            3262623, 18643560, 95548245, 445891810, 1917334783, 7669339132, 28760021745, 101766230790, 341643774795, 1093260079344, 3348108992991, 9847379391150,
            27900908274925, 76360380541900, 202355008436035, 520341450264090, 1300853625660225, 3167295784216200, 7522327487513475, 17451799771031262, 39602161018878633, 88004802264174740, 191724747789809255, 409894288378212890,
            860778005594247069, 1777090076065542336, 3609714217008132870, 7219428434016265740,
        ]
        #expect((0 ..< 1156).map { distances.distance(to: $0).value } == expected)
        #expect((0 ..< 1156).map { distances.distance(toIndex: $0).value } == expected)
        #expect(distances.sources == [0])
    }
    #endif

    @Test("SR-550 longest paths: the critical path (MaxPlusSemiring<Int>)")
    func sr550() throws {
        // dagShortestPaths(from: 0) → [0, 3, 2, 7, 7, 10]
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 4, to: 5),
        ])
        let w: [Int] = [3, 2, 4, 1, 5, 2, 3]
        let tree = try #require(graph.dagShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Int?] = [0, 3, 2, 7, 7, 10]
        #expect((0 ..< 6).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 6 {
            guard let path = tree.path(to: v) else { continue }
            var product = MaxPlusSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(MaxPlusSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-551 longest paths with negative weights (MaxPlusSemiring<Int>)")
    func sr551() throws {
        // dagShortestPaths(from: 0) → [0, -2, 3, -3]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let tree = try #require(graph.dagShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Int?] = [0, -2, 3, -3]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = MaxPlusSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(MaxPlusSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-560 longest paths: the critical path (MaxPlusSemiring<Double>)")
    func sr560() throws {
        // dagShortestPaths(from: 0) → [0.0, 3.0, 2.0, 7.0, 7.0, 10.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 4, to: 5),
        ])
        let w: [Double] = [3.0, 2.0, 4.0, 1.0, 5.0, 2.0, 3.0]
        let tree = try #require(graph.dagShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Double?] = [0.0, 3.0, 2.0, 7.0, 7.0, 10.0]
        #expect((0 ..< 6).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 6 {
            guard let path = tree.path(to: v) else { continue }
            var product = MaxPlusSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(MaxPlusSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-561 longest paths with negative weights (MaxPlusSemiring<Double>)")
    func sr561() throws {
        // dagShortestPaths(from: 0) → [0.0, -2.0, 3.0, -3.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let tree = try #require(graph.dagShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Double?] = [0.0, -2.0, 3.0, -3.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = MaxPlusSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(MaxPlusSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-576 most probable paths in a DAG (ViterbiSemiring<Double>)")
    func sr576() throws {
        // dagShortestPaths(from: 0) → [1.0, 0.5, 0.375, 0.375]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [0.5, 0.375, 0.5, 0.125, 1.0]
        let tree = try #require(graph.dagShortestPaths(from: 0) { ViterbiSemiring(w[$0]) })
        let expected: [Double?] = [1.0, 0.5, 0.375, 0.375]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = ViterbiSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(ViterbiSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }
}
