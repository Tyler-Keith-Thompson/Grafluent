// §K: deep, wide and dense graphs. Deep graphs run inside a Task, whose stack is much smaller than
// the main thread's, so a recursive search to the depth of a 100 000-vertex cycle overflows; the
// searches must keep explicit stacks. Johnson's figure 1 and a chain of 2³⁰ dead-end paths catch a
// search without blocking (Tiernan's), K₂₀₀ catches an eager sequence, a chain of triangles and a
// wide star catch per-round work proportional to the whole graph. Each test has a one-minute limit
// and is meant to stay well under two seconds in a debug build; the benchmarks take the big sizes.
// girth() is O(n·m), so it is checked on a 2 000-vertex cycle (CY-813), not a 100 000-vertex one.
// Expected values come from the catalog's reference (`ref.py stress()`: the proposed algorithm and
// closed forms). Case IDs (CY-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Cycles on deep, wide and dense graphs")
struct CycleStressTests {
    @Test("CY-800 Johnson's figure 1 for k = 3 … 9: exactly 3k cycles", .timeLimit(.minutes(1)))
    func johnsonFigureOne() async {
        await Task {
            for k in 3 ... 9 {
                // NetworkX's worst_case_graph(k) in its edge order, the arc (2k+1)>(2k+2), which the
                // construction adds twice, kept once as nx.DiGraph keeps it.
                var pairs: [(Int, Int)] = []
                for n in 2 ..< k + 2 {
                    pairs.append((1, n))
                    pairs.append((n, k + 2))
                }
                pairs.append((2 * k + 1, 1))
                for n in k + 2 ..< 2 * k + 2 {
                    pairs.append((n, 2 * k + 2))
                    if n + 1 != 2 * k + 2 { pairs.append((n, n + 1)) }
                }
                pairs.append((2 * k + 3, k + 2))
                for n in 2 * k + 3 ..< 3 * k + 3 {
                    pairs.append((2 * k + 2, n))
                    pairs.append((n, 3 * k + 3))
                }
                pairs.append((3 * k + 3, 2 * k + 2))
                #expect(pairs.count == 6 * k + 2)
                let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
                #expect(Array(graph.simpleCycles()).count == 3 * k, "k = \(k)")
            }
        }.value
    }

    @Test("CY-801 Johnson's figure 1 for k = 1000: 3000 cycles, linear time per cycle", .timeLimit(.minutes(1)))
    func johnsonFigureOneLarge() async {
        await Task {
            let k = 1000
            var pairs: [(Int, Int)] = []
            for n in 2 ..< k + 2 {
                pairs.append((1, n))
                pairs.append((n, k + 2))
            }
            pairs.append((2 * k + 1, 1))
            for n in k + 2 ..< 2 * k + 2 {
                pairs.append((n, 2 * k + 2))
                if n + 1 != 2 * k + 2 { pairs.append((n, n + 1)) }
            }
            pairs.append((2 * k + 3, k + 2))
            for n in 2 * k + 3 ..< 3 * k + 3 {
                pairs.append((2 * k + 2, n))
                pairs.append((n, 3 * k + 3))
            }
            pairs.append((3 * k + 3, 2 * k + 2))
            let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeCount == 6 * k + 2)
            #expect(Array(graph.simpleCycles()).count == 3000)
        }.value
    }

    @Test("CY-802 30 diamonds in a chain (2³⁰ dead-end paths) and one 2-cycle: Johnson blocks after the first dead end", .timeLimit(.minutes(1)))
    func diamonds() async {
        await Task {
            // Diamond i: 3i>3i+1, 3i>3i+2, 3i+1>3i+3, 3i+2>3i+3; then 0>-1 and -1>0.
            let k = 30
            var pairs: [(Int, Int)] = []
            for i in 0 ..< k {
                let (c, x, y, d) = (3 * i, 3 * i + 1, 3 * i + 2, 3 * i + 3)
                pairs += [(c, x), (c, y), (x, d), (y, d)]
            }
            pairs += [(0, -1), (-1, 0)]
            let graph = ReferenceDirectedMultigraph(vertices: Array(0 ... 3 * k) + [-1], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.map(\.vertices) == [[0, -1]])
            #expect(cycles.map(\.edges) == [[4 * k, 4 * k + 1]])
        }.value
    }

    @Test("CY-803 a 100 000-vertex directed cycle: one cycle, the path stack 10⁵ deep, no recursion", .timeLimit(.minutes(1)))
    func deepDirectedCycle() async {
        await Task {
            let n = 100_000
            let graph = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.count == 1)
            #expect(cycles.first?.vertices == Array(0 ..< n))
            #expect(cycles.first?.edges == Array(0 ..< n))
        }.value
    }

    @Test("CY-804 a 100 000-vertex undirected cycle: findCycle() is the whole cycle, simpleCycles() one cycle, no recursion", .timeLimit(.minutes(1)))
    func deepUndirectedCycle() async throws {
        try await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            // The search walks 0, 1, …, n − 1 and closes at edge n − 1, back to 0.
            let found = try #require(graph.findCycle())
            #expect(found.length == n)
            #expect(found.vertices == Array(0 ..< n))
            #expect(found.edges == Array(0 ..< n))
            #expect(!graph.isAcyclic)
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.count == 1)
            #expect(cycles.first?.vertices == Array(0 ..< n))
            #expect(cycles.first?.edges == Array(0 ..< n))
            #expect(graph.cycleBasis().map(\.edges) == [Array(0 ..< n)])
        }.value
    }

    @Test("CY-805 a 100 000-vertex path: acyclic, no cycle, an empty basis, no girth", .timeLimit(.minutes(1)))
    func deepPath() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.isAcyclic)
            #expect(graph.findCycle() == nil)
            #expect(graph.findCycle(from: [n / 2]) == nil)
            #expect(Array(graph.simpleCycles()).isEmpty)
            #expect(graph.cycleBasis().isEmpty)
        }.value
    }

    @Test("CY-806 JGraphT RESULTS[9]: DKL(9), every arc including loops, has 125 673 cycles", .timeLimit(.minutes(1)))
    func completeDigraphWithLoops() async {
        await Task {
            let n = 9
            var pairs: [(Int, Int)] = []
            for a in 0 ..< n { for b in 0 ..< n { pairs.append((a, b)) } }
            let graph = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(Array(graph.simpleCycles()).count == 125_673)
        }.value
    }

    @Test("CY-807 NetworkX A002807: K₉ has 62 814 cycles", .timeLimit(.minutes(1)))
    func completeGraphNine() async {
        await Task {
            let n = 9
            var pairs: [(Int, Int)] = []
            for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(Array(graph.simpleCycles()).count == 62_814)
        }.value
    }

    @Test("CY-808 the sequence is lazy: the first cycle of K₂₀₀ comes without enumerating the rest", .timeLimit(.minutes(1)))
    func firstCycleOfLargeCompleteGraph() async {
        await Task {
            let n = 200
            var pairs: [(Int, Int)] = []
            for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var iterator = graph.simpleCycles().makeIterator()
            let first = iterator.next()
            #expect(first?.vertices == [0, 1, 2])
            #expect(first?.edges == [0, 199, 1])
            // And the bounded sequence's first is the same triangle.
            var bounded = graph.simpleCycles(maxLength: 3).makeIterator()
            #expect(bounded.next()?.edges == [0, 199, 1])
        }.value
    }

    @Test("CY-809 10 000 triangles in a chain, each a block of its own: 10 000 cycles, in order", .timeLimit(.minutes(1)))
    func triangleChain() async {
        await Task {
            // Triangle i: 2i-(2i+1), (2i+1)-(2i+2), (2i+2)-2i.
            let k = 10_000
            var pairs: [(Int, Int)] = []
            for i in 0 ..< k { pairs += [(2 * i, 2 * i + 1), (2 * i + 1, 2 * i + 2), (2 * i + 2, 2 * i)] }
            let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.count == k)
            #expect(cycles.indices.allSatisfy { cycles[$0].vertices == [2 * $0, 2 * $0 + 1, 2 * $0 + 2] })
            #expect(cycles.indices.allSatisfy { cycles[$0].edges == [3 * $0, 3 * $0 + 1, 3 * $0 + 2] })
            #expect(graph.cycleBasis().count == k)
        }.value
    }

    @Test("CY-810 a star of 100 000 leaves with a loop on each: 100 000 one-cycles, wide rows", .timeLimit(.minutes(1)))
    func loopedStar() async {
        await Task {
            // S(0;1..n), then i-i for each leaf: the loop at leaf i is at position n + i − 1.
            let n = 100_000
            let graph = UndirectedAdjacencyList(edges: (1 ... n).map { UndirectedEdge(0, $0) } + (1 ... n).map { UndirectedEdge($0, $0) })
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.count == n)
            #expect(cycles.indices.allSatisfy { cycles[$0].vertices == [$0 + 1] && cycles[$0].edges == [n + $0] })
            #expect(graph.girth() == 1)
        }.value
    }

    @Test("CY-811 a 2 × 1000 ladder bounded by 4: the 999 squares, out of 499 500 cycles", .timeLimit(.minutes(1)))
    func boundedLadder() async {
        await Task {
            // grid(2,1000): vertex i·1000 + j; for each vertex in order, the edge right, then down.
            let (rows, columns) = (2, 1000)
            var pairs: [(Int, Int)] = []
            for i in 0 ..< rows {
                for j in 0 ..< columns {
                    let v = i * columns + j
                    if j + 1 < columns { pairs.append((v, v + 1)) }
                    if i + 1 < rows { pairs.append((v, v + columns)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< rows * columns, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let squares = Array(graph.simpleCycles(maxLength: 4))
            #expect(squares.count == 999)
            #expect(squares.allSatisfy { $0.length == 4 })
            #expect(graph.girth() == 4)
        }.value
    }

    @Test("CY-813 girth() on a 2 000-vertex cycle, undirected and directed: 2000, every search running to the end", .timeLimit(.minutes(1)))
    func girthOfLongCycle() async {
        await Task {
            let n = 2000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(graph.girth() == 2000)
            let digraph = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
            #expect(digraph.girth() == 2000)
        }.value
    }

    @Test("CY-814 girth() of a 100 × 100 grid is 4: every search after the first stops at depth 2", .timeLimit(.minutes(1)))
    func girthOfGrid() async {
        await Task {
            let (rows, columns) = (100, 100)
            var pairs: [(Int, Int)] = []
            for i in 0 ..< rows {
                for j in 0 ..< columns {
                    let v = i * columns + j
                    if j + 1 < columns { pairs.append((v, v + 1)) }
                    if i + 1 < rows { pairs.append((v, v + columns)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< rows * columns, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.girth() == 4)
        }.value
    }
}
