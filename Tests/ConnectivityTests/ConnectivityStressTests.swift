// Deep and wide graphs, and the real-world fixtures. Deep graphs run inside a Task, whose stack is
// much smaller than the main thread's, so any recursion to the depth of a 100 000-vertex path
// overflows. Per-vertex checks are folded into one expectation each to keep the suite fast.
// Expected values come from the catalog's reference (`stress.py`), checked against NetworkX.
// Case IDs (CN-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Connectivity on deep and wide graphs")
struct ConnectivityDeepGraphTests {
    @Test("CN-127 a 100 000-vertex path: no recursion")
    func deepPath() async {
        await Task {
            let n = 100_000
            let edges = (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) }
            func check<G: DirectedGraph<Int>>(_ g: G) {
                let scc = g.stronglyConnectedComponents()
                #expect(scc.count == n)
                #expect(scc.indices.allSatisfy { Array(scc[$0]) == [n - 1 - $0] })
                #expect(!g.isStronglyConnected)
                #expect(g.weaklyConnectedComponents().count == 1)
                #expect(g.isWeaklyConnected)
                #expect(g.condensation().graph.edgeCount == n - 1)
                let tree = g.dominatorTree(root: 0)
                #expect((1 ..< n).allSatisfy { tree.immediateDominator(of: $0) == $0 - 1 })
                #expect(tree.dominators(of: n - 1)?.count == n)
                #expect(tree.dominates(0, n - 1))
                let frontiers = g.dominanceFrontiers(root: 0)
                #expect((0 ..< n).allSatisfy { frontiers[$0]?.isEmpty == true })
            }
            check(CompressedSparseRow(vertexCount: n, edges: edges))
            check(AdjacencyList(vertices: 0 ..< n, edges: edges))
            check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges))
        }.value
    }

    @Test("CN-128 a 100 000-vertex cycle")
    func deepCycle() async {
        await Task {
            let n = 100_000
            let edges = (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) }
            func check<G: DirectedGraph<Int>>(_ g: G) {
                let scc = g.stronglyConnectedComponents()
                #expect(scc.map(Array.init) == [Array(0 ..< n)])
                #expect(g.isStronglyConnected)
                let tree = g.dominatorTree(root: 0)
                #expect((1 ..< n).allSatisfy { tree.immediateDominator(of: $0) == $0 - 1 })
                let frontiers = g.dominanceFrontiers(root: 0)
                #expect((0 ..< n).allSatisfy { frontiers[$0].map { Array($0) } == [0] })
            }
            check(CompressedSparseRow(vertexCount: n, edges: edges))
            check(AdjacencyList(vertices: 0 ..< n, edges: edges))
        }.value
    }

    @Test("CN-129 a 100 000-vertex lasso catches a recursive path compression")
    func lasso() async {
        await Task {
            // 0→1→…→99 999→1: when Lengauer–Tarjan processes 1 it evaluates predecessor 99 999,
            // whose chain of linked ancestors is about 10⁵ long.
            let n = 100_000
            let edges = (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) } + [DirectedEdge(from: n - 1, to: 1)]
            func check<G: DirectedGraph<Int>>(_ g: G) {
                #expect(g.stronglyConnectedComponents().map(Array.init) == [Array(1 ..< n), [0]])
                let tree = g.dominatorTree(root: 0)
                #expect((1 ..< n).allSatisfy { tree.immediateDominator(of: $0) == $0 - 1 })
                let frontiers = g.dominanceFrontiers(root: 0)
                #expect(frontiers[0].map { Array($0) } == [])
                #expect((1 ..< n).allSatisfy { frontiers[$0].map { Array($0) } == [1] })
            }
            check(CompressedSparseRow(vertexCount: n, edges: edges))
            check(AdjacencyList(vertices: 0 ..< n, edges: edges))
        }.value
    }

    @Test("CN-130 Cooper–Harvey–Kennedy's quadratic family: two entries into a bidirectional path")
    func twoEntryPath() async {
        await Task {
            // 0→1, 0→m and i↔i+1: CHK needs m passes. Time is the benchmark's job (CN-B05); this
            // asserts the answer.
            let m = 100_000
            var edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: m)]
            for i in 1 ..< m { edges += [DirectedEdge(from: i, to: i + 1), DirectedEdge(from: i + 1, to: i)] }
            let graph = CompressedSparseRow(vertexCount: m + 1, edges: edges)
            let tree = graph.dominatorTree(root: 0)
            #expect((1 ... m).allSatisfy { tree.immediateDominator(of: $0) == 0 })
            #expect(graph.stronglyConnectedComponents().map(Array.init) == [Array(1 ... m), [0]])
        }.value
    }

    @Test("CN-131 wide graphs: isolated vertices, a bidirectional star and an out-star")
    func wide() async {
        await Task {
            let n = 100_000
            let isolated = CompressedSparseRow(vertexCount: n)
            let strong = isolated.stronglyConnectedComponents()
            #expect(strong.count == n)
            #expect(strong.indices.allSatisfy { Array(strong[$0]) == [$0] })
            let weak = isolated.weaklyConnectedComponents()
            #expect(weak.count == n)
            #expect(weak.indices.allSatisfy { Array(weak[$0]) == [$0] })
            let star = CompressedSparseRow(vertexCount: n, edges: (1 ..< n).flatMap { [DirectedEdge(from: 0, to: $0), DirectedEdge(from: $0, to: 0)] })
            #expect(star.stronglyConnectedComponents().map(Array.init) == [Array(0 ..< n)])
            #expect(star.isStronglyConnected)
            let out = CompressedSparseRow(vertexCount: n, edges: (1 ..< n).map { DirectedEdge(from: 0, to: $0) })
            #expect(out.stronglyConnectedComponents().map(Array.init) == (1 ..< n).map { [$0] } + [[0]])
            let list = AdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { DirectedEdge(from: 0, to: $0) })
            let listComponents = list.stronglyConnectedComponents()
            #expect(listComponents.count == n)
            #expect(Array(listComponents[n - 1]) == [0])
        }.value
    }
}

@Suite("Connectivity on the real-world fixtures", .tags(.fixture))
struct ConnectivityRealWorldTests {
    @Test("CN-132 gap4: 14 vertices, 58 distinct edges, 5 self-loops")
    func gap4() {
        let fixture = DirectedFixture<Int>.gap4
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.count == 14)
            #expect(scc.allSatisfy { $0.count == 1 })
            #expect(scc.prefix(8).map(Array.init) == [[1], [6], [4], [10], [11], [9], [2], [12]])
            #expect(scc.suffix(3).map(Array.init) == [[8], [0], [5]])
            #expect(g.condensation().graph.edgeCount == 53)
            #expect(g.attractingComponents().count == 4)
            #expect(g.weaklyConnectedComponents().map(Array.init) == [[0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13], [5]])
            let tree = g.dominatorTree(root: 0)
            let frontiers = g.dominanceFrontiers(root: 0)
            let reachable = (0 ..< 14).filter { tree.dominators(of: $0) != nil }
            #expect(reachable.count == 13)
            #expect(reachable.filter { $0 != 0 }.allSatisfy { tree.immediateDominator(of: $0) == 0 })
            #expect(reachable.map { frontiers[$0]!.count }.reduce(0, +) == 46)
            #expect(reachable.filter { !frontiers[$0]!.isEmpty }.count == 10)
            let fromFive = g.dominatorTree(root: 5)
            #expect((0 ..< 14).filter { fromFive.dominators(of: $0) != nil } == [5])
        }
        check(CompressedSparseRow(vertexCount: 14, edges: fixture.edges))
        check(AdjacencyMatrix(vertexCount: 14, edges: fixture.edges))
    }

    @Test("CN-133 graph500Scale8: 256 vertices, 2171 distinct edges, 19 self-loops")
    func graph500() {
        let fixture = DirectedFixture<Int>.graph500Scale8
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let scc = g.stronglyConnectedComponents()
            #expect(scc.count == 256)
            #expect(scc.allSatisfy { $0.count == 1 })
            #expect(scc.prefix(8).map(Array.init) == [[189], [37], [157], [0], [21], [241], [120], [15]])
            #expect(scc.suffix(3).map(Array.init) == [[240], [246], [255]])
            #expect(g.condensation().graph.edgeCount == 2152)
            #expect(g.attractingComponents().count == 107)
            let weak = g.weaklyConnectedComponents()
            #expect(weak.count == 16)
            #expect(weak.map(\.count).sorted(by: >) == [241] + Array(repeating: 1, count: 15))
            #expect(Array(weak.prefix(8).map { $0.first! }) == [0, 30, 70, 107, 112, 114, 133, 158])
            let cases: [(root: Int, reachable: Int, children: Int, height: Int, total: Int, nonempty: Int)] = [
                (82, 235, 209, 2, 1972, 142),
                (17, 216, 178, 3, 1435, 128),
            ]
            for c in cases {
                let tree = g.dominatorTree(root: c.root)
                let frontiers = g.dominanceFrontiers(root: c.root)
                let reachable = (0 ..< 256).filter { tree.dominators(of: $0) != nil }
                #expect(reachable.count == c.reachable, "from \(c.root)")
                #expect(reachable.filter { tree.immediateDominator(of: $0) == c.root }.count == c.children, "from \(c.root)")
                #expect(tree.children(of: c.root).count == c.children, "from \(c.root)")
                #expect(reachable.map { tree.dominators(of: $0)!.count - 1 }.max() == c.height, "from \(c.root)")
                #expect(reachable.map { frontiers[$0]!.count }.reduce(0, +) == c.total, "from \(c.root)")
                #expect(reachable.filter { !frontiers[$0]!.isEmpty }.count == c.nonempty, "from \(c.root)")
            }
        }
        check(CompressedSparseRow(vertexCount: 256, edges: fixture.edges))
        check(AdjacencyMatrix(vertexCount: 256, edges: fixture.edges))
    }

    @Test("CN-134 ligraRMat: 128 vertices, 708 edges, symmetric")
    func ligra() {
        let fixture = DirectedFixture<Int>.ligraRMat
        let giant = (0 ..< 128).filter { ![1, 5, 40].contains($0) }
        func check<G: DirectedGraph<Int>>(_ g: G) {
            #expect(giant.count == 125)
            #expect(g.stronglyConnectedComponents().map(Array.init) == [giant, [1], [5], [40]])
            #expect(g.weaklyConnectedComponents().map(Array.init) == [giant, [1], [5], [40]])
            #expect(g.condensation().graph.edgeCount == 0)
            #expect(g.attractingComponents().count == 4)
            let tree = g.dominatorTree(root: 0)
            let frontiers = g.dominanceFrontiers(root: 0)
            let reachable = (0 ..< 128).filter { tree.dominators(of: $0) != nil }
            #expect(reachable == giant)
            #expect(reachable.filter { tree.immediateDominator(of: $0) == 0 }.count == 119)
            #expect(reachable.map { tree.dominators(of: $0)!.count - 1 }.max() == 2)
            #expect(Set(reachable.compactMap { tree.immediateDominator(of: $0) }.filter { $0 != 0 }) == [4, 72, 79, 80, 97])
            #expect(reachable.map { frontiers[$0]!.count }.reduce(0, +) == 701)
            #expect(reachable.allSatisfy { !frontiers[$0]!.isEmpty })
        }
        check(CompressedSparseRow(vertexCount: 128, edges: fixture.edges))
        check(AdjacencyMatrix(vertexCount: 128, edges: fixture.edges))
    }

    @Test("CN-135 adjacency lists, matrices and CSR agree on the real-world fixtures")
    func agreement() {
        for fixture in DirectedFixture<Int>.realWorld {
            let list = AdjacencyList(vertices: 0 ..< fixture.vertexCount, edges: fixture.edges)
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let strong = Set(sparse.stronglyConnectedComponents().map(Set.init))
            #expect(Set(list.stronglyConnectedComponents().map(Set.init)) == strong, "\(fixture.name)")
            #expect(Set(matrix.stronglyConnectedComponents().map(Set.init)) == strong, "\(fixture.name)")
            let weak = Set(sparse.weaklyConnectedComponents().map(Set.init))
            #expect(Set(list.weaklyConnectedComponents().map(Set.init)) == weak, "\(fixture.name)")
            #expect(Set(matrix.weaklyConnectedComponents().map(Set.init)) == weak, "\(fixture.name)")
            for root in stride(from: 0, to: fixture.vertexCount, by: 17) {
                let listTree = list.dominatorTree(root: root)
                let matrixTree = matrix.dominatorTree(root: root)
                let sparseTree = sparse.dominatorTree(root: root)
                #expect((0 ..< fixture.vertexCount).allSatisfy { listTree.immediateDominator(of: $0) == sparseTree.immediateDominator(of: $0) }, "\(fixture.name) from \(root)")
                #expect((0 ..< fixture.vertexCount).allSatisfy { matrixTree.immediateDominator(of: $0) == sparseTree.immediateDominator(of: $0) }, "\(fixture.name) from \(root)")
            }
        }
    }
}
