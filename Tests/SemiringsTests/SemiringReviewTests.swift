// Hand-written tests from the Semirings review: the binary floating-point Floyd–Warshall overload
// (+∞ is "no edge", as in scipy), DistanceMatrix.hasPath(from:to:), the bottleneck order being the
// reverse of the values', and the Double tropical carrier ℝ ∪ {+∞}.

import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: review additions")
struct SemiringReviewTests {
    @Test("Floyd–Warshall over Double and Float reads a weight of .infinity as no edge")
    func floatingPointFloydWarshall() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])
        let double: [Double] = [.infinity, 1.5, 4]
        let matrix = try #require(graph.floydWarshallShortestPaths { double[$0] })
        #expect(matrix.distance(from: 0, to: 1) == nil && !matrix.hasPath(from: 0, to: 1))
        #expect(matrix.distance(from: 0, to: 2) == 4 && matrix.path(from: 0, to: 2)?.edges == [2])
        #expect(matrix.distance(from: 1, to: 2) == 1.5)
        // The same as the tropical overload.
        let tropical = try #require(graph.floydWarshallShortestPaths { TropicalSemiring(double[$0]) })
        #expect((0 ..< 3).map { i in (0 ..< 3).map { matrix.distance(from: i, to: $0) } } == (0 ..< 3).map { i in (0 ..< 3).map { tropical.distance(from: i, to: $0)?.value } })
        let float: [Float] = [.infinity, 1.5, 4]
        let floatMatrix = try #require(graph.floydWarshallShortestPaths { float[$0] })
        #expect(floatMatrix.distance(from: 0, to: 1) == nil && floatMatrix.distance(from: 0, to: 2) == 4)
        // A path whose length rounds to .infinity is no path either.
        let huge: [Double] = [Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, .infinity]
        let rounded = try #require(graph.floydWarshallShortestPaths { huge[$0] })
        #expect(rounded.distance(from: 0, to: 1) == Double.greatestFiniteMagnitude && rounded.distance(from: 0, to: 2) == nil)
        // A negative cycle is still nil.
        let cyclic = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let negative: [Double] = [1, -2]
        #expect(cyclic.floydWarshallShortestPaths { negative[$0] } == nil)
    }

    @Test("Floyd–Warshall over integers, or through a generic W, keeps every weight as an edge")
    func reachedFlagFloydWarshall() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let integer = try #require(graph.floydWarshallShortestPaths { _ in Int.max })
        #expect(integer.distance(from: 0, to: 1) == Int.max && integer.hasPath(from: 0, to: 1))
        func generic<W: Comparable & AdditiveArithmetic>(_ weight: W) -> W? {
            graph.floydWarshallShortestPaths { _ in weight }?.distance(from: 0, to: 1)
        }
        #expect(generic(Double.infinity) == .infinity)
    }

    @Test("Floyd–Warshall over Double on an undirected graph reads .infinity as no edge")
    func undirectedFloatingPointFloydWarshall() throws {
        let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let w: [Double] = [2, .infinity]
        let matrix = try #require(graph.floydWarshallShortestPaths { w[$0] })
        #expect(matrix.distance(from: 1, to: 0) == 2 && matrix.distance(from: 1, to: 2) == nil && !matrix.hasPath(from: 0, to: 2))
        let negative: [Double] = [2, -1]
        #expect(graph.floydWarshallShortestPaths { negative[$0] } == nil)
    }

    @Test("DistanceMatrix.hasPath(from:to:) is distance(from:to:) != nil, true on the diagonal")
    func hasPath() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let matrix = try #require(graph.floydWarshallShortestPaths { _ in BottleneckSemiring(3) })
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(matrix.hasPath(from: i, to: j) == (matrix.distance(from: i, to: j) != nil))
                #expect(matrix.hasPath(from: i, to: j) == (i <= j))
            }
        }
    }

    @Test("BottleneckSemiring's order is the reverse of the values': max() is the narrowest")
    func bottleneckOrder() {
        let widths = [BottleneckSemiring(2), BottleneckSemiring(9), BottleneckSemiring(5)]
        #expect(widths.max() == BottleneckSemiring(2) && widths.min() == BottleneckSemiring(9))
        #expect(widths.reduce(BottleneckSemiring<Int>.zero) { $0.plus($1) } == BottleneckSemiring(9))
        // Unsigned: zero is 0, so a capacity-0 edge carries no path.
        #expect(BottleneckSemiring<UInt>.zero.value == 0 && BottleneckSemiring<UInt>(0) == .zero)
    }

    @Test("TropicalSemiring<Double>'s carrier is ℝ ∪ {+∞}: −∞ ⊗ +∞ is NaN, and Int.min ⊗ Int.max is zero")
    func tropicalCarrier() {
        #expect(TropicalSemiring(-Double.infinity).times(.zero).value.isNaN)
        #expect(TropicalSemiring(Int.min).times(.zero) == .zero)
        #expect(TropicalSemiring(-Double.infinity).times(TropicalSemiring(5)).value == -.infinity)
    }

    @Test("dagShortestDistances(from: []) is every distance .zero, with no sources")
    func dagShortestDistancesFromNoSources() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [2, 3]
        let distances = try #require(graph.dagShortestDistances(from: [Int]()) { TropicalSemiring(w[$0]) })
        #expect(distances.sources == [])
        #expect((0 ..< 3).map { distances.distance(to: $0) } == [TropicalSemiring<Int>.zero, .zero, .zero])
        let counts = try #require(graph.dagShortestDistances(from: EmptyCollection<Int>()) { _ in CountingSemiring(1) })
        #expect(counts.sources == [] && (0 ..< 3).map { counts.distance(toIndex: $0) } == [.zero, .zero, .zero])
    }
}
