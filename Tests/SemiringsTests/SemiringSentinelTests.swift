// The sentinels the catalog leaves out: the unsigned scalars (the bottleneck zero is 0, and
// UInt.max is the tropical zero and absorbs) and the signed tropical −∞ (Int.min), which absorbs
// every finite value but not the zero, on its own and as an edge weight in Bellman–Ford, where a
// cycle behind −∞ stops relaxing; and the tropical zero as an edge weight in DAG paths, an edge
// that carries no path. Hand-written; they catch mutants in scripts/mutants/Semirings.py that the
// catalog rows miss.

import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: the unsigned and −∞ sentinels")
struct SemiringSentinelTests {
    @Test("The unsigned bottleneck zero is 0: the identity of ⊕ and the annihilator of ⊗")
    func unsignedBottleneckZero() {
        let zero = BottleneckSemiring<UInt>.zero
        #expect(zero.value == 0)
        #expect(BottleneckSemiring<UInt8>.zero.value == 0 && BottleneckSemiring<UInt8>.one.value == UInt8.max)
        for a: UInt in [0, 1, 7, UInt.max] {
            let x = BottleneckSemiring(a)
            #expect(x.plus(zero) == x && zero.plus(x) == x, "identity: \(a)")
            #expect(x.times(zero) == zero && zero.times(x) == zero, "annihilator: \(a)")
            #expect(!(zero < x) && (x == zero || x < zero), "zero is the worst: \(a)")
        }
    }

    @Test("UInt.max is the unsigned tropical zero: it absorbs instead of overflowing")
    func unsignedTropicalZero() {
        let zero = TropicalSemiring<UInt>.zero
        #expect(zero.value == UInt.max && TropicalSemiring<UInt>.one.value == 0)
        for a: UInt in [0, 1, 7, UInt.max - 1, UInt.max] {
            let x = TropicalSemiring(a)
            #expect(x.times(zero) == zero && zero.times(x) == zero, "annihilator: \(a)")
            let product = x ⊗ zero
            #expect(product.value == UInt.max, "operator: \(a)")
        }
        #expect(TropicalSemiring<UInt8>(250).times(TropicalSemiring(UInt8.max)).value == UInt8.max)
        #expect(TropicalSemiring<UInt>(3).times(TropicalSemiring(4)).value == 7)
    }

    @Test("Int.min is the tropical −∞: it absorbs every finite value, including negative ones")
    func negativeInfinityAbsorbs() {
        let minus = TropicalSemiring(Int.min)
        for a in [-5, -1, 0, 1, 5, Int.max - 1] {
            let x = TropicalSemiring(a)
            #expect(minus.times(x).value == Int.min && x.times(minus).value == Int.min, "−∞ ⊗ \(a)")
        }
        #expect(minus.times(minus).value == Int.min)
        #expect(TropicalSemiring<Int8>(Int8.min).times(TropicalSemiring(-3)).value == Int8.min)
        #expect(TropicalSemiring<Int8>(4).times(TropicalSemiring(Int8.min)).value == Int8.min)
    }

    @Test("The tropical zero absorbs first: Int.max ⊗ Int.min is the zero")
    func zeroAbsorbsBeforeNegativeInfinity() {
        let zero = TropicalSemiring<Int>.zero, minus = TropicalSemiring(Int.min)
        #expect(zero.times(minus) == zero && minus.times(zero) == zero)
        let product = minus ⊗ zero
        #expect(product.value == Int.max)
        #expect(TropicalSemiring<Int16>(Int16.max).times(TropicalSemiring(Int16.min)).value == Int16.max)
    }

    @Test("Bellman–Ford: a chain of −∞ edges, with a zero-weight edge back, is no cycle")
    func negativeInfinityChain() throws {
        // 0 → 1 → 2 at −∞, and 2 → 1 at the tropical zero, which carries no path.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let w = [Int.min, Int.min, Int.max]
        let tree = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == [0, Int.min, Int.min])
        #expect(tree.path(to: 2)?.vertices == [0, 1, 2])
        // Without the zero edge, the same.
        let chain = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(chain.bellmanFordShortestPaths(from: 0) { _ in TropicalSemiring(Int.min) }?.distance(to: 2)?.value == Int.min)
    }

    @Test("Bellman–Ford: a cycle through a −∞ edge, closed two edges later, is nil")
    func negativeInfinityLongCycle() {
        // 0 → 1 at −∞, then 1 → 2 at −∞, 2 → 3 and 3 → 1 at 0: the cycle 1 → 2 → 3 → 1 is −∞.
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 1),
        ])
        let w = [Int.min, Int.min, 0, 0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0] == Int.min ? -Double.infinity : 0.0) } == nil)
        // A −∞ edge only into the cycle, whose own edges add to 1: a tree.
        let outside = [Int.min, 1, 0, 0]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(outside[$0]) }?.distance(to: 3)?.value == Int.min)
    }

    @Test("Bellman–Ford: a finite negative cycle behind a −∞ edge is nil")
    func finiteCycleBehindNegativeInfinity() {
        // 0 → 1 → 2 at −∞; 2 ⇄ 3 at -1 each, a negative cycle every vertex of which is at −∞.
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2),
        ])
        let w = [Int.min, Int.min, -1, -1]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) } == nil)
        #expect(graph.bellmanFordShortestPaths(from: 0) { w[$0] == Int.min ? -1000 : w[$0] } == nil)
        // At +1 each, a tree.
        let positive = [Int.min, Int.min, 1, 1]
        #expect(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(positive[$0]) }?.distance(to: 3)?.value == Int.min)
    }

    @Test("DAG paths: an edge at the tropical zero reaches nothing")
    func zeroWeightEdgeInDAGPaths() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [3, Int.max]
        let tree = try #require(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == [0, 3, nil])
        #expect(!tree.hasPath(to: 2) && tree.path(to: 2) == nil && tree.parentEdge(of: 2) == nil)
        let dag = try #require(DirectedAcyclicGraph(graph))
        let ordered = dag.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        #expect((0 ..< 3).map { ordered.distance(to: $0)?.value } == [0, 3, nil])
        #expect(!ordered.hasPath(to: 2) && ordered.parentEdge(of: 2) == nil)
        // Over Double, +∞ is the zero.
        let real = dag.dagShortestPaths(from: 0) { w[$0] == Int.max ? TropicalSemiring(Double.infinity) : TropicalSemiring(3.0) }
        #expect(!real.hasPath(to: 2))
    }
}
