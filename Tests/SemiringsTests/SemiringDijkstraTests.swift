// Dijkstra over a selective semiring (catalog Dijkstra rows): shortest paths (tropical), widest
// paths (bottleneck, with a cutoff meaning at least this wide) and reachability (Boolean); an
// edge of weight zero carries no path; undirected graphs through .directed.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: Dijkstra over a selective semiring")
struct SemiringDijkstraTests {
    @Test("SR-218 small digraph, an isolated vertex (TropicalSemiring<Int>)")
    func sr218() {
        // dijkstraShortestPaths(from: 0) → [0, 3, 1, 4, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [0, 3, 1, 4, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-219 parallel edges, a loop and a cycle (TropicalSemiring<Int>)")
    func sr219() {
        // dijkstraShortestPaths(from: 0) → [0, 2, 6]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Int] = [5, 2, 3, 4, 1]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
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

    @Test("SR-220 undirected through .directed (TropicalSemiring<Int>)")
    func sr220() {
        // dijkstraShortestPaths(from: 0) → [0, 2, 9, 9]
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3)])
        let directed = graph.directed
        let w: [Int] = [2, 7, 1, 9]
        let tree = directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0.position]) }
        let expected: [Int?] = [0, 2, 9, 9]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e.position]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-221 several sources (TropicalSemiring<Int>)")
    func sr221() {
        // dijkstraShortestPaths(from: [3, 2]) → [—, 2, 0, 0, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        let tree = graph.dijkstraShortestPaths(from: [3, 2]) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [nil, 2, 0, 0, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [3, 2])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-222 cutoff (not worse than) (TropicalSemiring<Int>)")
    func sr222() {
        // dijkstraShortestPaths(from: 0, cutoff: 3) → [0, 3, 1, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        let tree = graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring<Int>(3)) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [0, 3, 1, nil, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-224 an edge of weight zero reaches nothing (TropicalSemiring<Int>)")
    func sr224() {
        // dijkstraShortestPaths(from: 0) → [0, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w: [Int] = [Int.max, 0]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Int?] = [0, nil, nil]
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

    @Test("SR-225 one path (TropicalSemiring<Int>)")
    func sr225() throws {
        // dijkstraShortestPath(from: 0, to: 3) → vertices [0, 2, 1, 3], edges [1, 2, 3], distance 4
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        let result = try #require(graph.dijkstraShortestPath(from: 0, to: 3) { TropicalSemiring(w[$0]) })
        #expect(result.path.vertices == [0, 2, 1, 3] && result.path.edges == [1, 2, 3])
        #expect(result.distance.value == 4)
        // The same distance as the tree's.
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }.distance(to: 3) == result.distance)
        var product = TropicalSemiring<Int>.one
        for (k, e) in result.path.edges.enumerated() {
            #expect(graph.source(ofEdgeAt: e) == result.path.vertices[k] && graph.target(ofEdgeAt: e) == result.path.vertices[k + 1])
            product = product.times(TropicalSemiring(w[e]))
        }
        #expect(result.path.vertices.first == 0 && result.path.vertices.last == 3)
        #expect(product == result.distance)
    }

    @Test("SR-226 no path (TropicalSemiring<Int>)")
    func sr226() {
        // dijkstraShortestPath(from: 0, to: 4) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        #expect(graph.dijkstraShortestPath(from: 0, to: 4) { TropicalSemiring(w[$0]) } == nil)
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }.distance(to: 4) == nil)
    }

    @Test("SR-241 small digraph, an isolated vertex (TropicalSemiring<Double>)")
    func sr241() {
        // dijkstraShortestPaths(from: 0) → [0.0, 3.0, 1.0, 4.0, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [0.0, 3.0, 1.0, 4.0, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-242 parallel edges, a loop and a cycle (TropicalSemiring<Double>)")
    func sr242() {
        // dijkstraShortestPaths(from: 0) → [0.0, 2.0, 6.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Double] = [5.0, 2.0, 3.0, 4.0, 1.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
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

    @Test("SR-243 undirected through .directed (TropicalSemiring<Double>)")
    func sr243() {
        // dijkstraShortestPaths(from: 0) → [0.0, 2.0, 9.0, 9.0]
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3)])
        let directed = graph.directed
        let w: [Double] = [2.0, 7.0, 1.0, 9.0]
        let tree = directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0.position]) }
        let expected: [Double?] = [0.0, 2.0, 9.0, 9.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = TropicalSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(TropicalSemiring(w[e.position]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-244 several sources (TropicalSemiring<Double>)")
    func sr244() {
        // dijkstraShortestPaths(from: [3, 2]) → [—, 2.0, 0.0, 0.0, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        let tree = graph.dijkstraShortestPaths(from: [3, 2]) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [nil, 2.0, 0.0, 0.0, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [3, 2])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-245 cutoff (not worse than) (TropicalSemiring<Double>)")
    func sr245() {
        // dijkstraShortestPaths(from: 0, cutoff: 3) → [0.0, 3.0, 1.0, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        let tree = graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring<Double>(3)) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [0.0, 3.0, 1.0, nil, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-247 an edge of weight zero reaches nothing (TropicalSemiring<Double>)")
    func sr247() {
        // dijkstraShortestPaths(from: 0) → [0.0, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w: [Double] = [Double.infinity, 0.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        let expected: [Double?] = [0.0, nil, nil]
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

    @Test("SR-248 one path (TropicalSemiring<Double>)")
    func sr248() throws {
        // dijkstraShortestPath(from: 0, to: 3) → vertices [0, 2, 1, 3], edges [1, 2, 3], distance 4.0
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        let result = try #require(graph.dijkstraShortestPath(from: 0, to: 3) { TropicalSemiring(w[$0]) })
        #expect(result.path.vertices == [0, 2, 1, 3] && result.path.edges == [1, 2, 3])
        #expect(result.distance.value == 4.0)
        // The same distance as the tree's.
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }.distance(to: 3) == result.distance)
        var product = TropicalSemiring<Double>.one
        for (k, e) in result.path.edges.enumerated() {
            #expect(graph.source(ofEdgeAt: e) == result.path.vertices[k] && graph.target(ofEdgeAt: e) == result.path.vertices[k + 1])
            product = product.times(TropicalSemiring(w[e]))
        }
        #expect(result.path.vertices.first == 0 && result.path.vertices.last == 3)
        #expect(product == result.distance)
    }

    @Test("SR-249 no path (TropicalSemiring<Double>)")
    func sr249() {
        // dijkstraShortestPath(from: 0, to: 4) → nil
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        #expect(graph.dijkstraShortestPath(from: 0, to: 4) { TropicalSemiring(w[$0]) } == nil)
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }.distance(to: 4) == nil)
    }

    @Test("SR-275 widest paths (BottleneckSemiring<Int>)")
    func sr275() {
        // dijkstraShortestPaths(from: 0) → [Int.max, 5, 4, 4, 4]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Int] = [5, 3, 4, 2, 6, 7, 1]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [Int?] = [Int.max, 5, 4, 4, 4]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-276 parallel widths and a cycle (BottleneckSemiring<Int>)")
    func sr276() {
        // dijkstraShortestPaths(from: 0) → [Int.max, 8, 2, 5]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 3),
        ])
        let w: [Int] = [3, 8, 2, 9, 5]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
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

    @Test("SR-277 undirected through .directed (BottleneckSemiring<Int>)")
    func sr277() {
        // dijkstraShortestPaths(from: 0) → [Int.max, 2, 2, 9]
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3)])
        let directed = graph.directed
        let w: [Int] = [2, 7, 1, 9]
        let tree = directed.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0.position]) }
        let expected: [Int?] = [Int.max, 2, 2, 9]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = BottleneckSemiring<Int>.one
            for (k, e) in path.edges.enumerated() {
                #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BottleneckSemiring(w[e.position]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-278 an isolated vertex (BottleneckSemiring<Int>)")
    func sr278() {
        // dijkstraShortestPaths(from: 0) → [Int.max, 4, 1, 1, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [4, 1, 2, 1, 5]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [Int?] = [Int.max, 4, 1, 1, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-279 cutoff: only paths at least this wide (BottleneckSemiring<Int>)")
    func sr279() {
        // dijkstraShortestPaths(from: 0, cutoff: 5) → [Int.max, 5, —, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Int] = [5, 3, 4, 2, 6, 7, 1]
        let tree = graph.dijkstraShortestPaths(from: 0, cutoff: BottleneckSemiring<Int>(5)) { BottleneckSemiring(w[$0]) }
        let expected: [Int?] = [Int.max, 5, nil, nil, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-280 negative widths are fine (one is +∞) (BottleneckSemiring<Int>)")
    func sr280() {
        // dijkstraShortestPaths(from: 0) → [Int.max, -2, 3, -2]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
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

    @Test("SR-281 the widest path (BottleneckSemiring<Int>)")
    func sr281() throws {
        // dijkstraShortestPath(from: 0, to: 4) → vertices [0, 1, 2, 3, 4], edges [0, 2, 4, 5], distance 4
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Int] = [5, 3, 4, 2, 6, 7, 1]
        let result = try #require(graph.dijkstraShortestPath(from: 0, to: 4) { BottleneckSemiring(w[$0]) })
        #expect(result.path.vertices == [0, 1, 2, 3, 4] && result.path.edges == [0, 2, 4, 5])
        #expect(result.distance.value == 4)
        // The same distance as the tree's.
        #expect(graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }.distance(to: 4) == result.distance)
        var product = BottleneckSemiring<Int>.one
        for (k, e) in result.path.edges.enumerated() {
            #expect(graph.source(ofEdgeAt: e) == result.path.vertices[k] && graph.target(ofEdgeAt: e) == result.path.vertices[k + 1])
            product = product.times(BottleneckSemiring(w[e]))
        }
        #expect(result.path.vertices.first == 0 && result.path.vertices.last == 4)
        #expect(product == result.distance)
    }

    @Test("SR-288 widest paths (BottleneckSemiring<Double>)")
    func sr288() {
        // dijkstraShortestPaths(from: 0) → [.infinity, 5.0, 4.0, 4.0, 4.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Double] = [5.0, 3.0, 4.0, 2.0, 6.0, 7.0, 1.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [Double?] = [Double.infinity, 5.0, 4.0, 4.0, 4.0]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-289 parallel widths and a cycle (BottleneckSemiring<Double>)")
    func sr289() {
        // dijkstraShortestPaths(from: 0) → [.infinity, 8.0, 2.0, 5.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 3),
        ])
        let w: [Double] = [3.0, 8.0, 2.0, 9.0, 5.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
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

    @Test("SR-290 undirected through .directed (BottleneckSemiring<Double>)")
    func sr290() {
        // dijkstraShortestPaths(from: 0) → [.infinity, 2.0, 2.0, 9.0]
        let graph = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 3)])
        let directed = graph.directed
        let w: [Double] = [2.0, 7.0, 1.0, 9.0]
        let tree = directed.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0.position]) }
        let expected: [Double?] = [Double.infinity, 2.0, 2.0, 9.0]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = BottleneckSemiring<Double>.one
            for (k, e) in path.edges.enumerated() {
                #expect(directed.source(ofEdgeAt: e) == path.vertices[k] && directed.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BottleneckSemiring(w[e.position]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }

    @Test("SR-291 an isolated vertex (BottleneckSemiring<Double>)")
    func sr291() {
        // dijkstraShortestPaths(from: 0) → [.infinity, 4.0, 1.0, 1.0, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [4.0, 1.0, 2.0, 1.0, 5.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [Double?] = [Double.infinity, 4.0, 1.0, 1.0, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-292 cutoff: only paths at least this wide (BottleneckSemiring<Double>)")
    func sr292() {
        // dijkstraShortestPaths(from: 0, cutoff: 5) → [.infinity, 5.0, —, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Double] = [5.0, 3.0, 4.0, 2.0, 6.0, 7.0, 1.0]
        let tree = graph.dijkstraShortestPaths(from: 0, cutoff: BottleneckSemiring<Double>(5)) { BottleneckSemiring(w[$0]) }
        let expected: [Double?] = [Double.infinity, 5.0, nil, nil, nil]
        #expect((0 ..< 5).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 5).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 5 {
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

    @Test("SR-293 negative widths are fine (one is +∞) (BottleneckSemiring<Double>)")
    func sr293() {
        // dijkstraShortestPaths(from: 0) → [.infinity, -2.0, 3.0, -2.0]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
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

    @Test("SR-294 the widest path (BottleneckSemiring<Double>)")
    func sr294() throws {
        // dijkstraShortestPath(from: 0, to: 4) → vertices [0, 1, 2, 3, 4], edges [0, 2, 4, 5], distance 4.0
        let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 4),
        ])
        let w: [Double] = [5.0, 3.0, 4.0, 2.0, 6.0, 7.0, 1.0]
        let result = try #require(graph.dijkstraShortestPath(from: 0, to: 4) { BottleneckSemiring(w[$0]) })
        #expect(result.path.vertices == [0, 1, 2, 3, 4] && result.path.edges == [0, 2, 4, 5])
        #expect(result.distance.value == 4.0)
        // The same distance as the tree's.
        #expect(graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }.distance(to: 4) == result.distance)
        var product = BottleneckSemiring<Double>.one
        for (k, e) in result.path.edges.enumerated() {
            #expect(graph.source(ofEdgeAt: e) == result.path.vertices[k] && graph.target(ofEdgeAt: e) == result.path.vertices[k + 1])
            product = product.times(BottleneckSemiring(w[e]))
        }
        #expect(result.path.vertices.first == 0 && result.path.vertices.last == 4)
        #expect(product == result.distance)
    }

    @Test("SR-305 reachability; a false edge is absent (BooleanSemiring)")
    func sr305() {
        // dijkstraShortestPaths(from: 0) → [true, true, true, —, —, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 5, to: 5),
        ])
        let w: [Bool] = [true, true, true, false, true, true]
        let tree = graph.dijkstraShortestPaths(from: 0) { BooleanSemiring(w[$0]) }
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

    @Test("SR-308 parallel edges, a loop (BooleanSemiring)")
    func sr308() {
        // dijkstraShortestPaths(from: 0) → [true, true, true]
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0),
        ])
        let w: [Bool] = [true, false, true, true, true]
        let tree = graph.dijkstraShortestPaths(from: 0) { BooleanSemiring(w[$0]) }
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

    @Test("SR-311 several sources (BooleanSemiring)")
    func sr311() {
        // dijkstraShortestPaths(from: [3, 5]) → [—, —, —, true, true, true]
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 5, to: 5),
        ])
        let w: [Bool] = [true, true, true, false, true, true]
        let tree = graph.dijkstraShortestPaths(from: [3, 5]) { BooleanSemiring(w[$0]) }
        let expected: [Bool?] = [nil, nil, nil, true, true, true]
        #expect((0 ..< 6).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 6).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [3, 5])
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

    @Test("SR-355 unsigned: a capacity-0 edge is zero and carries no path (BottleneckSemiring<UInt>)")
    func sr355() {
        // dijkstraShortestPaths(from: 0) → [UInt.max, —, 3, —]
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3)])
        let w: [UInt] = [0, 5, 3, 0]
        let tree = graph.dijkstraShortestPaths(from: 0) { BottleneckSemiring(w[$0]) }
        let expected: [UInt?] = [UInt.max, nil, 3, nil]
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.distance(toIndex: $0)?.value } == expected)
        #expect((0 ..< 4).map { tree.hasPath(to: $0) } == expected.map { $0 != nil })
        #expect(tree.sources == [0])
        // Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.
        for v in 0 ..< 4 {
            guard let path = tree.path(to: v) else { continue }
            var product = BottleneckSemiring<UInt>.one
            for (k, e) in path.edges.enumerated() {
                #expect(graph.source(ofEdgeAt: e) == path.vertices[k] && graph.target(ofEdgeAt: e) == path.vertices[k + 1])
                product = product.times(BottleneckSemiring(w[e]))
            }
            #expect(path.vertices.last == v && tree.sources.contains(path.vertices[0]))
            #expect(product == tree.distance(to: v))
            #expect(tree.parentEdge(of: v) == path.edges.last)
        }
    }
}
