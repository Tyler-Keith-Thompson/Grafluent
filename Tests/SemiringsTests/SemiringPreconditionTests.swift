// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the fault, so the trap is the call's and not
// the setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: preconditions", .tags(.precondition))
struct SemiringPreconditionTests {
    @Test("SR-210 overflow traps (TropicalSemiring<Int>: a = Int.max - 3, b = 4)")
    func sr210() async {
        // a ⊗ b → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            let a = TropicalSemiring<Int>(Int.max - 3)
            let b = TropicalSemiring<Int>(4)
            _ = a ⊗ b
        }
        // The method the operator calls traps too.
        await #expect(processExitsWith: .failure) {
            let a = TropicalSemiring<Int>(Int.max - 3)
            let b = TropicalSemiring<Int>(4)
            _ = a.times(b)
        }
        // One less: the largest finite sum, and a sum landing on Int.max is zero.
        #expect((TropicalSemiring<Int>(Int.max - 3) ⊗ TropicalSemiring<Int>(2)).value == Int.max - 1)
        #expect((TropicalSemiring<Int>(Int.max - 3) ⊗ TropicalSemiring<Int>(3)) == .zero)
    }

    @Test("SR-211 negative overflow traps (TropicalSemiring<Int>: a = Int.min + 3, b = -4)")
    func sr211() async {
        // a ⊗ b → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            let a = TropicalSemiring<Int>(Int.min + 3)
            let b = TropicalSemiring<Int>(-4)
            _ = a ⊗ b
        }
        // The method the operator calls traps too.
        await #expect(processExitsWith: .failure) {
            let a = TropicalSemiring<Int>(Int.min + 3)
            let b = TropicalSemiring<Int>(-4)
            _ = a.times(b)
        }
        // One less: the most negative sum that fits.
        #expect((TropicalSemiring<Int>(Int.min + 3) ⊗ TropicalSemiring<Int>(-3)).value == Int.min)
    }

    @Test("SR-214 ⊕ overflow traps (CountingSemiring<Int>: a = Int.max, b = 1)")
    func sr214() async {
        // a ⊕ b → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            let a = CountingSemiring<Int>(Int.max)
            let b = CountingSemiring<Int>(1)
            _ = a ⊕ b
        }
        // The method the operator calls traps too.
        await #expect(processExitsWith: .failure) {
            let a = CountingSemiring<Int>(Int.max)
            let b = CountingSemiring<Int>(1)
            _ = a.plus(b)
        }
        // The largest sums that fit.
        #expect((CountingSemiring<Int>(Int.max) ⊕ CountingSemiring<Int>(0)).value == Int.max)
        #expect((CountingSemiring<Int>(Int.max - 1) ⊕ CountingSemiring<Int>(1)).value == Int.max)
    }

    @Test("SR-215 ⊗ overflow traps (CountingSemiring<Int>: a = 4294967296, b = 2147483648)")
    func sr215() async {
        // a ⊗ b → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            let a = CountingSemiring<Int>(4294967296)
            let b = CountingSemiring<Int>(2147483648)
            _ = a ⊗ b
        }
        // The method the operator calls traps too.
        await #expect(processExitsWith: .failure) {
            let a = CountingSemiring<Int>(4294967296)
            let b = CountingSemiring<Int>(2147483648)
            _ = a.times(b)
        }
        // One less: the largest product that fits (SR-216).
        #expect((CountingSemiring<Int>(4294967296) ⊗ CountingSemiring<Int>(2147483647)).value == 9223372032559808512)
    }

    @Test("SR-223 a negative examined weight traps (TropicalSemiring<Int>)")
    func sr223() async throws {
        // dijkstraShortestPaths(from: 0) → **trap** (a weight is better than one)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
                DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
                DirectedEdge(from: 2, to: 3),
            ])
            let w: [Int] = [-2, 3, 4, -1, -6]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        // Without the fault: from 3 no weight is examined, and Bellman–Ford takes the graph.
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Int] = [-2, 3, 4, -1, -6]
        let tree = graph.dijkstraShortestPaths(from: 3) { TropicalSemiring(w[$0]) }
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == [nil, nil, nil, 0])
        let reference = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 4).map { reference.distance(to: $0)?.value } == [0, -2, 2, -4])
    }

    @Test("SR-246 a negative examined weight traps (TropicalSemiring<Double>)")
    func sr246() async throws {
        // dijkstraShortestPaths(from: 0) → **trap** (a weight is better than one)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
                DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
                DirectedEdge(from: 2, to: 3),
            ])
            let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        // Without the fault: from 3 no weight is examined, and Bellman–Ford takes the graph.
        let graph = DirectedPseudograph(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 3),
        ])
        let w: [Double] = [-2.0, 3.0, 4.0, -1.0, -6.0]
        let tree = graph.dijkstraShortestPaths(from: 3) { TropicalSemiring(w[$0]) }
        #expect((0 ..< 4).map { tree.distance(to: $0)?.value } == [nil, nil, nil, 0.0])
        let reference = try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) })
        #expect((0 ..< 4).map { reference.distance(to: $0)?.value } == [0.0, -2.0, 2.0, -4.0])
    }

    @Test("SR-273 the sum overflows: traps (TropicalSemiring<Int>)")
    func sr273() async {
        // dijkstraShortestPaths(from: 0) → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w: [Int] = [4611686018427387904, 4611686018427387904]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        // Without the fault: from 1, one weight, no sum.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w: [Int] = [4611686018427387904, 4611686018427387904]
        let tree = graph.dijkstraShortestPaths(from: 1) { TropicalSemiring(w[$0]) }
        #expect((0 ..< 3).map { tree.distance(to: $0)?.value } == [nil, 0, 4611686018427387904])
    }

    @Test("SR-335 2^63 overflows: traps (CountingSemiring<Int>)")
    func sr335() async throws {
        // dagShortestDistances(from: 0) → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            var edges: [DirectedEdge<Int>] = []
            for i in 0 ..< 63 {
                edges += [DirectedEdge(from: 2 * i, to: 2 * i + 1), DirectedEdge(from: 2 * i, to: 2 * i + 2), DirectedEdge(from: 2 * i + 1, to: 2 * i + 2)]
            }
            #expect(edges.count == 189)
            let graph = DirectedPseudograph(vertices: 0 ..< 127, edges: edges)
            let w = [Int](repeating: 1, count: edges.count)
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        // Without the fault: from vertex 2 the counts fit; the last is 4611686018427387904.
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 63 {
            edges += [DirectedEdge(from: 2 * i, to: 2 * i + 1), DirectedEdge(from: 2 * i, to: 2 * i + 2), DirectedEdge(from: 2 * i + 1, to: 2 * i + 2)]
        }
        #expect(edges.count == 189)
        let graph = DirectedPseudograph(vertices: 0 ..< 127, edges: edges)
        let w = [Int](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 2) { CountingSemiring(w[$0]) })
        #expect(distances.distance(to: 126).value == 4611686018427387904)
        #expect(distances.distance(to: 0).value == 0 && distances.distance(to: 2).value == 1)
    }

    @Test("SR-337 C(68,34) overflows: traps (CountingSemiring<Int>)")
    func sr337() async throws {
        // dagShortestDistances(from: 0) → **trap** (overflow)
        await #expect(processExitsWith: .failure) {
            var edges: [DirectedEdge<Int>] = []
            for i in 0 ..< 35 {
                for j in 0 ..< 35 {
                    if j + 1 < 35 { edges.append(DirectedEdge(from: i * 35 + j, to: i * 35 + j + 1)) }
                    if i + 1 < 35 { edges.append(DirectedEdge(from: i * 35 + j, to: (i + 1) * 35 + j)) }
                }
            }
            #expect(edges.count == 2380)
            let graph = DirectedPseudograph(vertices: 0 ..< 1225, edges: edges)
            let w = [Int](repeating: 1, count: edges.count)
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        // Without the fault: from vertex 36 the counts fit; the last is 7219428434016265740.
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 35 {
            for j in 0 ..< 35 {
                if j + 1 < 35 { edges.append(DirectedEdge(from: i * 35 + j, to: i * 35 + j + 1)) }
                if i + 1 < 35 { edges.append(DirectedEdge(from: i * 35 + j, to: (i + 1) * 35 + j)) }
            }
        }
        #expect(edges.count == 2380)
        let graph = DirectedPseudograph(vertices: 0 ..< 1225, edges: edges)
        let w = [Int](repeating: 1, count: edges.count)
        let distances = try #require(graph.dagShortestDistances(from: 36) { CountingSemiring(w[$0]) })
        #expect(distances.distance(to: 1224).value == 7219428434016265740)
        #expect(distances.distance(to: 0).value == 0 && distances.distance(to: 36).value == 1)
    }

    @Test("A source or target that is not a vertex traps, in every semiring entry point")
    func nonVertexSources() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPaths(from: [0, 7]) { _ in BottleneckSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dijkstraShortestPath(from: 0, to: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.bellmanFordShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dagShortestPaths(from: 7) { _ in BooleanSemiring(true) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.dagShortestDistances(from: 7) { _ in CountingSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let dag = DirectedAcyclicGraph(graph)!
            _ = dag.dagShortestDistances(from: 7) { _ in CountingSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let dag = DirectedAcyclicGraph(graph)!
            _ = dag.dagShortestPaths(from: 7) { _ in TropicalSemiring(1) }
        }
        // Without the fault: the same calls from vertex 0 answer.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in TropicalSemiring(1) }.distance(to: 2)?.value == 2)
        #expect(graph.dijkstraShortestPaths(from: [0, 1]) { _ in BottleneckSemiring(1) }.distance(to: 2)?.value == 1)
        #expect(graph.dijkstraShortestPath(from: 0, to: 2) { _ in TropicalSemiring(1) }?.distance.value == 2)
        #expect(graph.bellmanFordShortestPaths(from: 0) { _ in TropicalSemiring(1) }?.distance(to: 2)?.value == 2)
        #expect(graph.dagShortestPaths(from: 0) { _ in BooleanSemiring(true) }?.distance(to: 2)?.value == true)
        #expect(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }?.distance(to: 2).value == 1)
        let dag = try #require(DirectedAcyclicGraph(graph))
        #expect(dag.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }.distance(to: 2).value == 1)
        #expect(dag.dagShortestPaths(from: 0) { _ in TropicalSemiring(1) }.distance(to: 2)?.value == 2)
    }

    @Test("No source traps in the tree-returning entry points")
    func noSources() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.bellmanFordShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestPaths(from: [Int]()) { _ in TropicalSemiring(1) }
        }
        // Without the fault: one source, listed twice, is listed once.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.dijkstraShortestPaths(from: [0, 0]) { _ in TropicalSemiring(1) }.sources == [0])
        #expect(try #require(graph.bellmanFordShortestPaths(from: [0, 0]) { _ in TropicalSemiring(1) }).sources == [0])
        #expect(try #require(graph.dagShortestPaths(from: [0, 0]) { _ in TropicalSemiring(1) }).sources == [0])
    }

    @Test("A tropical Int sum that overflows traps in Bellman–Ford, DAG paths, DAG distances and Floyd–Warshall")
    func tropicalOverflowEverywhere() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.dagShortestDistances(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [-4611686018427387904, -4611686018427387905]
            _ = graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        // Without the fault: half the weights fit, and their sum is Int.max - 1, finite.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [4611686018427387903, 4611686018427387903]
        #expect(try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(w[$0]) }).distance(to: 2)?.value == Int.max - 1)
        #expect(try #require(graph.dagShortestPaths(from: 0) { TropicalSemiring(w[$0]) }).distance(to: 2)?.value == Int.max - 1)
        #expect(try #require(graph.dagShortestDistances(from: 0) { TropicalSemiring(w[$0]) }).distance(to: 2).value == Int.max - 1)
        #expect(try #require(graph.floydWarshallShortestPaths { TropicalSemiring(w[$0]) }).distance(from: 0, to: 2)?.value == Int.max - 1)
        let negative = [-4611686018427387904, -4611686018427387904]
        #expect(try #require(graph.bellmanFordShortestPaths(from: 0) { TropicalSemiring(negative[$0]) }).distance(to: 2)?.value == Int.min)
    }

    @Test("A path count that overflows Int traps: a product along a path, a sum across paths")
    func countingOverflowThroughWeights() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [4294967296, 2147483648]
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
            let w = [4611686018427387904, 4611686018427387904]
            _ = graph.dagShortestDistances(from: 0) { CountingSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
            let w = [Int.max, 1]
            _ = graph.dagShortestDistances(from: [0, 1]) { CountingSemiring(w[$0]) }
        }
        // Without the fault: one less in each.
        let path = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let product = [4294967296, 2147483647]
        #expect(try #require(path.dagShortestDistances(from: 0) { CountingSemiring(product[$0]) }).distance(to: 2).value == 9223372032559808512)
        let parallel = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let halves = [4611686018427387904, 4611686018427387903]
        #expect(try #require(parallel.dagShortestDistances(from: 0) { CountingSemiring(halves[$0]) }).distance(to: 1).value == Int.max)
        let join = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        let sum = [Int.max - 1, 1]
        #expect(try #require(join.dagShortestDistances(from: [0, 1]) { CountingSemiring(sum[$0]) }).distance(to: 2).value == Int.max)
    }

    @Test("A weight better than one traps in Dijkstra's single-target search, with a cutoff, over Double, and through .directed")
    func betterThanOneElsewhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [-1, 5]
            _ = graph.dijkstraShortestPath(from: 0, to: 2) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [-1, 5]
            _ = graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring<Int>(100)) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w = [0.0, -0.5]
            _ = graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0]) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [3, -1]
            _ = graph.directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(w[$0.position]) }
        }
        // Without the fault: zero weights are one, not better, and Dijkstra takes them.
        let graph = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = [0, 5]
        #expect(graph.dijkstraShortestPath(from: 0, to: 2) { TropicalSemiring(w[$0]) }?.distance.value == 5)
        #expect(graph.dijkstraShortestPaths(from: 0, cutoff: TropicalSemiring<Int>(100)) { TropicalSemiring(w[$0]) }.distance(to: 2)?.value == 5)
        let halves = [0.0, 0.5]
        #expect(graph.dijkstraShortestPaths(from: 0) { TropicalSemiring(halves[$0]) }.distance(to: 2)?.value == 0.5)
        let undirected = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let positive = [3, 1]
        #expect(undirected.directed.dijkstraShortestPaths(from: 0) { TropicalSemiring(positive[$0.position]) }.distance(to: 2)?.value == 4)
    }

    @Test("Index-space reads of the results trap out of range")
    func indicesOutOfRange() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in BottleneckSemiring(4) }.distance(toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }!.distance(toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }!.distance(toIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }!.distance(fromIndex: 0, toIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }!.distance(fromIndex: -1, toIndex: 0)
        }
        // Without the fault: the last index answers.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in BottleneckSemiring(4) }.distance(toIndex: 1)?.value == 4)
        #expect(try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }).distance(toIndex: 1).value == 1)
        let matrix = try #require(graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) })
        #expect(matrix.distance(fromIndex: 0, toIndex: 1)?.value == true && matrix.distance(fromIndex: 1, toIndex: 0) == nil)
    }

    @Test("Reading a result at a vertex that is not one traps")
    func resultsAtNonVertices() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }!.distance(to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in TropicalSemiring(1) }!.distance(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.floydWarshallShortestPaths { _ in TropicalSemiring(1) }!.path(from: 0, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.dijkstraShortestPaths(from: 0) { _ in TropicalSemiring(1) }.path(to: 9)
        }
        // Without the fault: the vertices answer.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) }).distance(to: 1).value == 1)
        let matrix = try #require(graph.floydWarshallShortestPaths { _ in TropicalSemiring(1) })
        #expect(matrix.distance(from: 1, to: 0) == nil && matrix.path(from: 0, to: 1)?.edges == [0])
        #expect(graph.dijkstraShortestPaths(from: 0) { _ in TropicalSemiring(1) }.path(to: 1)?.vertices == [0, 1])
    }
}
