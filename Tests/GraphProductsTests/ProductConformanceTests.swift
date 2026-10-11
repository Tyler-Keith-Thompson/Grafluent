// Algorithms see a product as they see a stored graph. Traversal, Connectivity and ShortestPaths run
// on seeded random products of all four kinds, and each result must equal the same algorithm on a
// materialized copy, with the copy's positions mapped back to the product's through `edges` order.
// Directed: the copy is built by inserting every vertex's out-edges in row order, so its out-rows
// are the product's and order-sensitive results (search events, Tarjan's component order, parent
// edges) must agree exactly. Undirected: the copy is `Pseudograph(product)`, whose positions are
// the offsets in `edges`; results that do not depend on row order must agree. Then P_r □ P_c
// against NamedGraphs' grid. See README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Connectivity
import GrafluentTestSupport
import GraphProducts
import GraphProtocols
import Multigraphs
import NamedGraphs
import ShortestPaths
import Testing
import Traversal

@Suite("GraphProducts conformances and algorithms", .tags(.randomized))
struct ProductConformanceTests {
    @Test("Directed products: Traversal, Connectivity and ShortestPaths equal a row-order copy", arguments: [1, 2, 3, 4, 5, 6])
    func directedAlgorithms(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let nG = Int.random(in: 1 ... 4, using: &rng), nH = Int.random(in: 1 ... 4, using: &rng)
        // Pseudographs: parallel arcs and self-loops included.
        var g = DirectedPseudograph<Int>(vertices: 0 ..< nG)
        var h = DirectedPseudograph<Int>(vertices: 0 ..< nH)
        for _ in 0 ..< Int.random(in: 0 ... 6, using: &rng) {
            _ = g.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< nG, using: &rng), to: Int.random(in: 0 ..< nG, using: &rng)))
        }
        for _ in 0 ..< Int.random(in: 0 ... 6, using: &rng) {
            _ = h.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< nH, using: &rng), to: Int.random(in: 0 ..< nH, using: &rng)))
        }
        func check<P: BidirectionalDirectedGraph>(_ product: P, _ kind: String) where P.Vertex == Pair<Int, Int> {
            let context = "\(kind) of G \(Array(g.edges)) and H \(Array(h.edges))"
            let positions = Array(product.edges.indices)
            let offset = Dictionary(uniqueKeysWithValues: zip(positions, positions.indices))
            // The copy: every vertex, then each vertex's out-edges in row order.
            var copy = DirectedPseudograph<Pair<Int, Int>>(vertices: product.vertices)
            var copyToProduct: [Int] = []
            for v in product.vertices {
                for p in product.outEdges(of: v) {
                    let k = copy.insert(edge: product.edges[p])
                    #expect(k == copyToProduct.count, "\(context)")
                    copyToProduct.append(offset[p] ?? -1)
                }
            }
            #expect(Array(copy.vertices) == Array(product.vertices), "\(context)")
            #expect(copy.edgeCount == product.edgeCount && Set(copyToProduct).count == product.edgeCount, "\(context)")
            for v in product.vertices {
                #expect(Array(copy.successors(of: v)) == Array(product.successors(of: v)), "\(context)")
                #expect(copy.predecessors(of: v).sorted() == product.predecessors(of: v).sorted(), "\(context)")
            }
            let weight = (0 ..< product.edgeCount).map { ($0 &* 2_654_435_761) % 7 + 1 }
            #expect(Array(product.depthFirstSearch()) == Array(copy.depthFirstSearch()), "\(context)")
            #expect(product.topologicalSort() == copy.topologicalSort(), "\(context)")
            #expect(product.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) }, "\(context)")
            #expect(product.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) }, "\(context)")
            #expect(product.condensation().components.map { Array($0) } == copy.condensation().components.map { Array($0) }, "\(context)")
            #expect(Array(product.condensation().graph.edges) == Array(copy.condensation().graph.edges), "\(context)")
            #expect(product.isStronglyConnected == copy.isStronglyConnected, "\(context)")
            for source in product.vertices {
                #expect(Array(product.breadthFirstSearch(from: source)) == Array(copy.breadthFirstSearch(from: source)), "\(context)")
                #expect(Array(product.depthFirstSearch(from: source)) == Array(copy.depthFirstSearch(from: source)), "\(context)")
                #expect(product.breadthFirstLayers(from: source) == copy.breadthFirstLayers(from: source), "\(context)")
                #expect(product.descendants(of: source) == copy.descendants(of: source), "\(context)")
                #expect(product.ancestors(of: source) == copy.ancestors(of: source), "\(context)")
                let hops = product.shortestPaths(from: source), copyHops = copy.shortestPaths(from: source)
                let tree = product.dijkstraShortestPaths(from: source) { weight[offset[$0] ?? 0] }
                let copyTree = copy.dijkstraShortestPaths(from: source) { weight[copyToProduct[$0]] }
                for target in product.vertices {
                    #expect(hops.distance(to: target) == copyHops.distance(to: target), "\(context)")
                    #expect(hops.parentEdge(of: target).flatMap { offset[$0] } == copyHops.parentEdge(of: target).map { copyToProduct[$0] }, "\(context)")
                    #expect(tree.distance(to: target) == copyTree.distance(to: target), "\(context)")
                    #expect(tree.parent(of: target) == copyTree.parent(of: target), "\(context)")
                    #expect(tree.parentEdge(of: target).flatMap { offset[$0] } == copyTree.parentEdge(of: target).map { copyToProduct[$0] }, "\(context)")
                    #expect(tree.path(to: target)?.vertices == copyTree.path(to: target)?.vertices, "\(context)")
                    #expect(product.hasPath(from: source, to: target) == copy.hasPath(from: source, to: target), "\(context)")
                }
            }
        }
        check(cartesianProduct(g, h), "cartesian")
        check(tensorProduct(g, h), "tensor")
        check(strongProduct(g, h), "strong")
        check(lexicographicProduct(g, h), "lexicographic")
        check(lexicographicProduct(h, g), "lexicographic, swapped")
    }

    @Test("Products of CompressedSparseRow factors (no in-rows) search like a row-order copy", arguments: [1, 2, 3, 4])
    func forwardOnlyFactors(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(50 + seed))
        let nG = Int.random(in: 1 ... 5, using: &rng), nH = Int.random(in: 1 ... 4, using: &rng)
        let g = CompressedSparseRow(vertexCount: nG, edges: (0 ..< nG * 2).map { _ in
            DirectedEdge(from: Int.random(in: 0 ..< nG, using: &rng), to: Int.random(in: 0 ..< nG, using: &rng))
        })
        let h = CompressedSparseRow(vertexCount: nH, edges: (0 ..< nH).map { _ in
            DirectedEdge(from: Int.random(in: 0 ..< nH, using: &rng), to: Int.random(in: 0 ..< nH, using: &rng))
        })
        func check<P: DirectedGraph>(_ product: P, _ kind: String) where P.Vertex == Pair<Int, Int> {
            let context = "\(kind) of G \(Array(g.edges)) and H \(Array(h.edges))"
            // The copy: every vertex, then each vertex's successors in row order (a factor's
            // self-loop can make a strong product's arcs parallel, so the copy keeps repeats).
            var copy = DirectedPseudograph<Pair<Int, Int>>(vertices: product.vertices)
            for v in product.vertices {
                for w in product.successors(of: v) { _ = copy.insert(edge: DirectedEdge(from: v, to: w)) }
            }
            #expect(copy.edgeCount == product.edgeCount, "\(context)")
            #expect(Array(product.depthFirstSearch()) == Array(copy.depthFirstSearch()), "\(context)")
            #expect(product.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) }, "\(context)")
            for source in product.vertices {
                #expect(Array(product.breadthFirstSearch(from: source)) == Array(copy.breadthFirstSearch(from: source)), "\(context)")
                #expect(product.descendants(of: source) == copy.descendants(of: source), "\(context)")
                let hops = product.shortestPaths(from: source), copyHops = copy.shortestPaths(from: source)
                for target in product.vertices {
                    #expect(hops.distance(to: target) == copyHops.distance(to: target), "\(context)")
                }
            }
        }
        check(cartesianProduct(g, h), "cartesian")
        check(tensorProduct(g, h), "tensor")
        check(strongProduct(g, h), "strong")
        check(lexicographicProduct(g, h), "lexicographic")
    }

    @Test("Undirected products: Connectivity and ShortestPaths equal Pseudograph(product)", arguments: [1, 2, 3, 4, 5, 6])
    func undirectedAlgorithms(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(100 + seed))
        let nG = Int.random(in: 1 ... 4, using: &rng), nH = Int.random(in: 1 ... 4, using: &rng)
        var g = Pseudograph<Int>(vertices: 0 ..< nG)
        var h = Pseudograph<Int>(vertices: 0 ..< nH)
        for _ in 0 ..< Int.random(in: 0 ... 5, using: &rng) {
            _ = g.insert(edge: UndirectedEdge(Int.random(in: 0 ..< nG, using: &rng), Int.random(in: 0 ..< nG, using: &rng)))
        }
        for _ in 0 ..< Int.random(in: 0 ... 5, using: &rng) {
            _ = h.insert(edge: UndirectedEdge(Int.random(in: 0 ..< nH, using: &rng), Int.random(in: 0 ..< nH, using: &rng)))
        }
        func check<P: Graph>(_ product: P, _ kind: String) where P.Vertex == Pair<Int, Int> {
            let context = "\(kind) of G \(Array(g.edges)) and H \(Array(h.edges))"
            let positions = Array(product.edges.indices)
            let offset = Dictionary(uniqueKeysWithValues: zip(positions, positions.indices))
            let copy = Pseudograph<Pair<Int, Int>>(product)
            // The copy keeps `vertices` order, and its position k is the product's k-th edge.
            #expect(Array(copy.vertices) == Array(product.vertices), "\(context)")
            #expect(Array(copy.edges) == Array(product.edges), "\(context)")
            for v in product.vertices {
                #expect(copy.neighbors(of: v).sorted() == product.neighbors(of: v).sorted(), "\(context)")
                #expect(product.incidentEdges(of: v).map { offset[$0] ?? -1 }.sorted() == copy.incidentEdges(of: v).sorted(), "\(context)")
            }
            let weight = (0 ..< product.edgeCount).map { ($0 &* 2_654_435_761) % 7 + 1 }
            #expect(product.connectedComponents().map { Array($0) } == copy.connectedComponents().map { Array($0) }, "\(context)")
            #expect(product.isConnected == copy.isConnected, "\(context)")
            #expect(product.bridges().map { offset[$0] ?? -1 } == copy.bridges(), "\(context)")
            #expect(Set(product.articulationPoints()) == Set(copy.articulationPoints()), "\(context)")
            for source in product.vertices {
                #expect(product.directed.breadthFirstLayers(from: source).map { Set($0) } == copy.directed.breadthFirstLayers(from: source).map { Set($0) }, "\(context)")
                #expect(product.directed.descendants(of: source) == copy.directed.descendants(of: source), "\(context)")
                let hops = product.shortestPaths(from: source), copyHops = copy.shortestPaths(from: source)
                let tree = product.dijkstraShortestPaths(from: source) { weight[offset[$0] ?? 0] }
                let copyTree = copy.dijkstraShortestPaths(from: source) { weight[$0] }
                for target in product.vertices {
                    #expect(hops.distance(to: target) == copyHops.distance(to: target), "\(context)")
                    #expect(tree.distance(to: target) == copyTree.distance(to: target), "\(context)")
                }
            }
        }
        check(cartesianProduct(g, h), "cartesian")
        check(tensorProduct(g, h), "tensor")
        check(strongProduct(g, h), "strong")
        check(lexicographicProduct(g, h), "lexicographic")
        check(lexicographicProduct(h, g), "lexicographic, swapped")
    }

    @Test("P_r □ P_c is NamedGraphs' grid(dimensions: [r, c]) in index space", arguments: [(1, 1), (1, 4), (2, 3), (3, 3), (4, 2), (5, 7)])
    func gridIdentity(r: Int, c: Int) {
        let pr = UndirectedAdjacencyList<Int>.path(vertexCount: r)
        let pc = UndirectedAdjacencyList<Int>.path(vertexCount: c)
        let product = cartesianProduct(pr, pc)
        let grid = UndirectedAdjacencyList<Int>.grid(dimensions: [r, c])
        #expect(product.vertexIndexBound == grid.vertexCount && product.edgeCount == grid.edgeCount)
        #expect(product.vertices.map { product.vertexIndex(of: $0) } == Array(0 ..< r * c))
        #expect(product.vertices.map { [$0.first, $0.second] } == (0 ..< r * c).map { [$0 / c, $0 % c] })
        #expect(Set(product.edges.indices.map { [product.endpointIndices(ofEdgeAt: $0).u, product.endpointIndices(ofEdgeAt: $0).v].sorted() })
            == Set(grid.edges.map { [$0.u, $0.v].sorted() }))
        for i in 0 ..< r * c {
            #expect(Array(product.neighborIndices(ofIndex: i)).sorted() == Array(grid.neighborIndices(ofIndex: i)).sorted())
            #expect(product.degree(ofIndex: i) == grid.degree(of: i))
        }
        let hops = product.shortestPaths(from: Pair(0, 0)), gridHops = grid.shortestPaths(from: 0)
        for (i, v) in product.vertices.enumerated() {
            #expect(hops.distance(to: v) == gridHops.distance(to: i))
            #expect(hops.distance(to: v) == v.first + v.second)
        }
        #expect(product.connectedComponents().count == 1 && grid.connectedComponents().count == 1)
        #expect(product.bridges().count == grid.bridges().count)
    }

    @Test("Products are Sendable when their factors are, and nest")
    func sendableAndNesting() async {
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let h = UndirectedAdjacencyList<String>(vertices: ["x", "y", "z"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("y", "z")])
        let product = strongProduct(g, h)
        let count = await Task.detached { product.edgeCount }.value
        #expect(count == product.edgeCount && count == 1 * 3 + 2 * 2 + 2 * 1 * 2)
        // Q3 = K2 □ K2 □ K2, nested either way, is 3-regular with 12 edges.
        let k2 = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let left = cartesianProduct(cartesianProduct(k2, k2), k2)
        let right = cartesianProduct(k2, cartesianProduct(k2, k2))
        #expect(left.edgeCount == 12 && right.edgeCount == 12)
        #expect((0 ..< 8).allSatisfy { left.degree(ofIndex: $0) == 3 && right.degree(ofIndex: $0) == 3 })
        #expect(left.vertex(atIndex: 5) == Pair(Pair(1, 0), 1) && right.vertex(atIndex: 5) == Pair(1, Pair(0, 1)))
        #expect(left.vertexIndex(of: Pair(Pair(1, 1), 0)) == 6)
        #expect(Pseudograph(left).connectedComponents().count == 1)
    }
}
