// Bellman–Ford over a selective semiring (catalog Bellman–Ford rows): nil when a cycle better
// than one is reachable, which only the tropical semiring has.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: Bellman–Ford over a selective semiring")
struct SemiringBellmanFordTests {
    @Test("SR-227 negative weights (TropicalSemiring<Int>)")
    func sr227() throws {
        // bellmanFordShortestPaths(from: 0) → [0, -2, 2, -4]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
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

    @Test("SR-228 a reachable negative cycle (TropicalSemiring<Int>)")
    func sr228() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, -3, 1, 2]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-229 a negative cycle not reachable (TropicalSemiring<Int>)")
    func sr229() throws {
        // bellmanFordShortestPaths(from: 3) → [—, —, —, 0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, -3, 1, 2]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 3) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [nil, nil, nil, 0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [3])
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

    @Test("SR-230 parallel edges, a loop and a cycle (TropicalSemiring<Int>)")
    func sr230() throws {
        // bellmanFordShortestPaths(from: 0) → [0, 2, 6]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Int] = [5, 2, 3, 4, 1]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [0, 2, 6]
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

    @Test("SR-250 negative weights (TropicalSemiring<Double>)")
    func sr250() throws {
        // bellmanFordShortestPaths(from: 0) → [0.0, -2.0, 2.0, -4.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
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

    @Test("SR-251 a reachable negative cycle (TropicalSemiring<Double>)")
    func sr251() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, -3.0, 1.0, 2.0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-252 a negative cycle not reachable (TropicalSemiring<Double>)")
    func sr252() throws {
        // bellmanFordShortestPaths(from: 3) → [—, —, —, 0.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, -3.0, 1.0, 2.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 3) { TropicalSemiring(w[$0]) })
        let expected: [Double?] = [nil, nil, nil, 0.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [3])
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

    @Test("SR-253 parallel edges, a loop and a cycle (TropicalSemiring<Double>)")
    func sr253() throws {
        // bellmanFordShortestPaths(from: 0) → [0.0, 2.0, 6.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Double] = [5.0, 2.0, 3.0, 4.0, 1.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Double?] = [0.0, 2.0, 6.0]
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 3 {
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

    @Test("SR-282 cycles never improve (BottleneckSemiring<Int>)")
    func sr282() throws {
        // bellmanFordShortestPaths(from: 0) → [Int.max, 8, 2, 5]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 3),
        ])
        let w: [Int] = [3, 8, 2, 9, 5]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { BottleneckSemiring(w[$0]) })
        let expected: [Int?] = [Int.max, 8, 2, 5]
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

    @Test("SR-283 the 'negative' cycle of the tropical rows is harmless (BottleneckSemiring<Int>)")
    func sr283() throws {
        // bellmanFordShortestPaths(from: 0) → [Int.max, 1, -3, -3]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, -3, 1, 2]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { BottleneckSemiring(w[$0]) })
        let expected: [Int?] = [Int.max, 1, -3, -3]
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

    @Test("SR-295 cycles never improve (BottleneckSemiring<Double>)")
    func sr295() throws {
        // bellmanFordShortestPaths(from: 0) → [.infinity, 8.0, 2.0, 5.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 3),
        ])
        let w: [Double] = [3.0, 8.0, 2.0, 9.0, 5.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { BottleneckSemiring(w[$0]) })
        let expected: [Double?] = [Double.infinity, 8.0, 2.0, 5.0]
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

    @Test("SR-296 the 'negative' cycle of the tropical rows is harmless (BottleneckSemiring<Double>)")
    func sr296() throws {
        // bellmanFordShortestPaths(from: 0) → [.infinity, 1.0, -3.0, -3.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, -3.0, 1.0, 2.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { BottleneckSemiring(w[$0]) })
        let expected: [Double?] = [Double.infinity, 1.0, -3.0, -3.0]
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

    @Test("SR-306 reachability; a false edge is absent (BooleanSemiring)")
    func sr306() throws {
        // bellmanFordShortestPaths(from: 0) → [true, true, true, —, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 5, to: 5),
        ])
        let w: [Bool] = [true, true, true, false, true, true]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { BooleanSemiring(w[$0]) })
        let expected: [Bool?] = [true, true, true, nil, nil, nil]
        #expect((0 ..< 6).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 6 {
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

    @Test("SR-309 parallel edges, a loop (BooleanSemiring)")
    func sr309() throws {
        // bellmanFordShortestPaths(from: 0) → [true, true, true]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Bool] = [true, false, true, true, true]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { BooleanSemiring(w[$0]) })
        let expected: [Bool?] = [true, true, true]
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 3 {
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

    @Test("SR-341 a cycle through a −∞ weight: nil (the parents would form a cycle) (TropicalSemiring<Int>)")
    func sr341() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)])
        let w: [Int] = [Int.min, 5, 1]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-342 a −∞ weight on no cycle: −∞ behind it (TropicalSemiring<Int>)")
    func sr342() throws {
        // bellmanFordShortestPaths(from: 0) → [0, 3, Int.min, Int.min]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        let w: [Int] = [3, Int.min, 5, 2]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [0, 3, Int.min, Int.min]
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

    @Test("SR-343 a cycle through a −∞ weight on vertices already at −∞: nil (TropicalSemiring<Int>)")
    func sr343() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Int] = [Int.min, Int.min, 5]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-344 a negative loop on a vertex already at −∞: nil (TropicalSemiring<Int>)")
    func sr344() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        let w: [Int] = [Int.min, 3, -1]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-345 a negative cycle of finite weights on vertices already at −∞: nil (TropicalSemiring<Int>)")
    func sr345() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let w: [Int] = [Int.min, 4, -2, -3]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-346 a positive cycle behind a −∞ weight is harmless (TropicalSemiring<Int>)")
    func sr346() throws {
        // bellmanFordShortestPaths(from: 0) → [0, Int.min, Int.min]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Int] = [Int.min, 5, 5]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Int?] = [0, Int.min, Int.min]
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

    @Test("SR-347 a cycle through a −∞ weight: nil (the parents would form a cycle) (TropicalSemiring<Double>)")
    func sr347() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)])
        let w: [Double] = [-Double.infinity, 5.0, 1.0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-348 a −∞ weight on no cycle: −∞ behind it (TropicalSemiring<Double>)")
    func sr348() throws {
        // bellmanFordShortestPaths(from: 0) → [0.0, 3.0, -.infinity, -.infinity]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        let w: [Double] = [3.0, -Double.infinity, 5.0, 2.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Double?] = [0.0, 3.0, -Double.infinity, -Double.infinity]
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

    @Test("SR-349 a cycle through a −∞ weight on vertices already at −∞: nil (TropicalSemiring<Double>)")
    func sr349() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Double] = [-Double.infinity, -Double.infinity, 5.0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-350 a negative loop on a vertex already at −∞: nil (TropicalSemiring<Double>)")
    func sr350() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        let w: [Double] = [-Double.infinity, 3.0, -1.0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-351 a negative cycle of finite weights on vertices already at −∞: nil (TropicalSemiring<Double>)")
    func sr351() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let w: [Double] = [-Double.infinity, 4.0, -2.0, -3.0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
    }

    @Test("SR-352 a positive cycle behind a −∞ weight is harmless (TropicalSemiring<Double>)")
    func sr352() throws {
        // bellmanFordShortestPaths(from: 0) → [0.0, -.infinity, -.infinity]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Double] = [-Double.infinity, 5.0, 5.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        let expected: [Double?] = [0.0, -Double.infinity, -Double.infinity]
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 3 {
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

    @Test("SR-555 longest paths; a negative cycle is harmless (MaxPlusSemiring<Int>)")
    func sr555() throws {
        // bellmanFordShortestPaths(from: 0) → [0, 1, -2, 0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Int] = [1, -3, 1, 2]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Int?] = [0, 1, -2, 0]
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

    @Test("SR-556 a reachable positive cycle (MaxPlusSemiring<Int>)")
    func sr556() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Int] = [1, 2, 1]
        #expect(graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) } == nil)
    }

    @Test("SR-557 a positive cycle not reachable (MaxPlusSemiring<Int>)")
    func sr557() throws {
        // bellmanFordShortestPaths(from: 0) → [0, 1, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let w: [Int] = [1, 2, 1]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Int?] = [0, 1, nil, nil]
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

    @Test("SR-565 longest paths; a negative cycle is harmless (MaxPlusSemiring<Double>)")
    func sr565() throws {
        // bellmanFordShortestPaths(from: 0) → [0.0, 1.0, -2.0, 0.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        let w: [Double] = [1.0, -3.0, 1.0, 2.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Double?] = [0.0, 1.0, -2.0, 0.0]
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

    @Test("SR-566 a reachable positive cycle (MaxPlusSemiring<Double>)")
    func sr566() {
        // bellmanFordShortestPaths(from: 0) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Double] = [1.0, 2.0, 1.0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) } == nil)
    }

    @Test("SR-567 a positive cycle not reachable (MaxPlusSemiring<Double>)")
    func sr567() throws {
        // bellmanFordShortestPaths(from: 0) → [0.0, 1.0, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let w: [Double] = [1.0, 2.0, 1.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(w[$0]) })
        let expected: [Double?] = [0.0, 1.0, nil, nil]
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

    @Test("SR-575 cycles never improve (ViterbiSemiring<Double>)")
    func sr575() throws {
        // bellmanFordShortestPaths(from: 0) → [1.0, 0.5, 0.25]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w: [Double] = [0.5, 0.5, 1.0]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { ViterbiSemiring(w[$0]) })
        let expected: [Double?] = [1.0, 0.5, 0.25]
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 3).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 3 {
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
