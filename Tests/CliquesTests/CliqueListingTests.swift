// Every clique by size (`allCliques(sizes:)`), the maximal cliques through a vertex, each
// vertex's clique number and a maximum-weight clique (Östergård), on the simple graph.
// Hand-computed graphs, representations, the checked spellings, exits, and property tests against
// every vertex subset.

import AdjacencyListModule
import AdjacencyMatrixModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("Clique listings, clique numbers per vertex and maximum-weight cliques")
struct CliqueListingTests {
    @Test("CQ-930 allCliques on a triangle with a pendant: nine cliques in all, four edges, one triangle, none of four")
    func allCliquesTrianglePendant() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let every = Array(graph.allCliques(sizes: 1...))
        #expect(Set(every) == [[0], [1], [2], [3], [0, 1], [0, 2], [1, 2], [2, 3], [0, 1, 2]])
        #expect(every.count == 9)
        #expect(Set(graph.allCliques(sizes: 2 ... 2)) == [[0, 1], [0, 2], [1, 2], [2, 3]])
        #expect(Array(graph.allCliques(sizes: 3 ... 3)) == [[0, 1, 2]])
        #expect(Array(graph.allCliques(sizes: 4...)).isEmpty)
        #expect(Array(graph.allCliques(sizes: 0 ... 0)).isEmpty)
        #expect(Set(graph.allCliques(sizes: 0 ..< 2)) == [[0], [1], [2], [3]])
        #expect(Set(graph.allCliques(sizes: ...2)).count == 8)
        // Iterating again gives the same sequence.
        #expect(Array(graph.allCliques(sizes: 1...)) == every)
    }

    @Test("CQ-931 allCliques on K₅ lists C(5, k) cliques of each size k, and the documented order on a triangle: by first vertex in the degeneracy ordering, then depth first")
    func allCliquesComplete() {
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect((1 ... 6).map { Array(graph.allCliques(sizes: $0 ... $0)).count } == [5, 10, 10, 5, 1, 0])
        #expect(Array(graph.allCliques(sizes: 1...)).count == 31)
        let triangle = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
        // Degeneracy ordering [0, 1, 2]: 0's cliques, then 1's, then 2's.
        #expect(triangle.coreNumbers().degeneracyOrdering == [0, 1, 2])
        #expect(Array(triangle.allCliques(sizes: 1...)) == [[0], [0, 1], [0, 1, 2], [0, 2], [1], [1, 2], [2]])
    }

    @Test("CQ-932 allCliques ignores loops and parallel edges, keeps `vertices` order for String vertices listed in reverse, and lists nothing for the empty graph")
    func allCliquesDegenerate() {
        let graph = Pseudograph(vertices: 0 ..< 3, edges: [(0, 1), (0, 1), (1, 1), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(Set(graph.allCliques(sizes: 1...)) == [[0], [1], [2], [0, 1], [1, 2]])
        #expect(Array(ReferencePseudograph<Int>(edges: []).allCliques(sizes: 1...)).isEmpty)
        let named = UndirectedAdjacencyList(vertices: ["c", "b", "a"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("a", "c")])
        #expect(Array(named.allCliques(sizes: 3 ... 3)) == [["c", "b", "a"]])
    }

    @Test("CQ-933 allCliques traps on a negative size")
    func allCliquesTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).allCliques(sizes: -1 ... 2)
        }
    }

    @Test("CQ-934 maximalCliques(containing:) on a bowtie, an isolated vertex and a vertex with only a loop")
    func containing() throws {
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4), (6, 6)].map { UndirectedEdge($0.0, $0.1) })
        #expect(Set(graph.maximalCliques(containing: 2)) == [[0, 1, 2], [2, 3, 4]])
        #expect(Array(graph.maximalCliques(containing: 2)).count == 2)
        #expect(Array(graph.maximalCliques(containing: 0)) == [[0, 1, 2]])
        #expect(Array(graph.maximalCliques(containing: 5)) == [[5]])
        #expect(Array(graph.maximalCliques(containing: 6)) == [[6]])
        // Iterating again starts over.
        let sequence = graph.maximalCliques(containing: 3)
        #expect(Array(sequence) == [[2, 3, 4]])
        #expect(Array(sequence) == [[2, 3, 4]])
        #expect(throws: VertexNotFound.self) { try graph.maximalCliques(checkedContaining: 9) }
        #expect(Array(try graph.maximalCliques(checkedContaining: 4)) == [[2, 3, 4]])
        let named = UndirectedAdjacencyList(vertices: ["c", "b", "a"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        #expect(Set(named.maximalCliques(containing: "b")) == [["c", "b"], ["b", "a"]])
    }

    @Test("CQ-935 maximalCliques(containing:) traps on a non-vertex")
    func containingTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).maximalCliques(containing: 5)
        }
    }

    @Test("CQ-936 cliqueNumber(of:): a triangle with a pendant, K₄ with a pendant triangle, isolated vertices and loops")
    func vertexCliqueNumbers() throws {
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: [(0, 1), (0, 2), (1, 2), (2, 3), (5, 5)].map { UndirectedEdge($0.0, $0.1) })
        #expect((0 ..< 6).map { graph.cliqueNumber(of: $0) } == [3, 3, 3, 2, 1, 1])
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (4, 5)]
        let k4 = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect((0 ..< 6).map { k4.cliqueNumber(of: $0) } == [4, 4, 4, 4, 3, 3])
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        #expect((0 ..< 6).map { matrix.cliqueNumber(of: $0) } == [4, 4, 4, 4, 3, 3])
        #expect(throws: VertexNotFound.self) { try graph.cliqueNumber(checked: 6) }
        #expect(try graph.cliqueNumber(checked: 3) == 2)
    }

    @Test("CQ-937 cliqueNumber(of:) traps on a non-vertex")
    func vertexCliqueNumberTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).cliqueNumber(of: 5)
        }
    }

    @Test("CQ-938 maximumWeightClique: a heavy pendant edge beats the triangle; weights at or below zero are never taken")
    func weighted() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(graph.maximumWeightClique { [1, 1, 1, 10][$0] } == [2, 3])
        #expect(graph.maximumWeightClique { [4, 4, 1, 4][$0] } == [0, 1, 2])
        #expect(graph.maximumWeightClique { [4, 4, -1, 4][$0] } == [0, 1])
        #expect(graph.maximumWeightClique { [0.5, 0.5, 0.0, 2.5][$0] } == [3])
        #expect(graph.maximumWeightClique { _ in 0 } == [])
        #expect(graph.maximumWeightClique { _ in -3 } == [])
        #expect(ReferencePseudograph<Int>(edges: []).maximumWeightClique { _ in 1 } == [])
        // The heaviest triangle, 1–3–5, among lighter ones sharing its vertices: a bound that
        // undercounts any candidate's weight prunes it.
        let pairs = [(0, 1), (0, 2), (0, 6), (1, 2), (1, 3), (1, 5), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (4, 6), (5, 6)]
        let bounded = ReferencePseudograph(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(bounded.maximumWeightClique { [2, 2, 2, 3, 1, 6, 3][$0] } == [1, 3, 5])
        // Unit weights: a maximum clique.
        #expect(graph.maximumWeightClique { _ in 1 }.count == 3)
        let loops = Pseudograph(vertices: 0 ..< 3, edges: [(0, 0), (0, 1), (0, 1), (2, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(loops.maximumWeightClique { [1, 2, 4][$0] } == [2])
        let named = UndirectedAdjacencyList(vertices: ["c", "b", "a"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        #expect(named.maximumWeightClique { ["a": 1, "b": 2, "c": 3][$0]! } == ["c", "b"])
    }

    @Test("CQ-939 allCliques, maximalCliques(containing:), cliqueNumber(of:) and maximumWeightClique against every vertex subset", .tags(.randomized))
    func againstSubsets() async {
        // A local function rather than the closure given to propertyCheck: in a closure, Swift 6.3
        // numbers a closure inside a #expect argument like the next closure written after it. Here
        // that crashed the Linux compiler (SendNonSendable, "map::at"). Function bodies number
        // their closures correctly.
        @Sendable func check(_ n: Int, _ raw: [(Int, Int)], _ bounds: (Int, Int), _ seed: Int) {
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var neighbours = [Int](repeating: 0, count: n)
            for (a, b) in pairs where a != b {
                neighbours[a] |= 1 << b
                neighbours[b] |= 1 << a
            }
            var cliques: [[Int]] = []
            var maximal: [[Int]] = []
            for mask in 1 ..< 1 << n {
                let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
                guard members.allSatisfy({ (mask & ~(1 << $0)) & ~neighbours[$0] == 0 }) else { continue }
                cliques.append(members)
                if (0 ..< n).allSatisfy({ w in mask & (1 << w) != 0 || mask & ~neighbours[w] != 0 }) { maximal.append(members) }
            }
            let low = min(bounds.0, bounds.1), high = max(bounds.0, bounds.1)
            let listed = Array(graph.allCliques(sizes: low ... high))
            #expect(Set(listed) == Set(cliques.filter { (low ... high).contains($0.count) }))
            #expect(listed.count == cliques.filter { (low ... high).contains($0.count) }.count)
            let v = seed % n
            #expect(Set(graph.maximalCliques(containing: v)) == Set(maximal.filter { $0.contains(v) }))
            #expect(Array(graph.maximalCliques(containing: v)).count == maximal.filter { $0.contains(v) }.count)
            #expect((0 ..< n).map { graph.cliqueNumber(of: $0) } == (0 ..< n).map { u in cliques.filter { $0.contains(u) }.map(\.count).max()! })
            let weights = (0 ..< n).map { ($0 * 7 + seed) % 11 - 3 }
            let best = cliques.map { $0.reduce(0) { $0 + max(weights[$1], 0) } }.max() ?? 0
            let chosen = graph.maximumWeightClique { weights[$0] }
            #expect(chosen.reduce(0) { $0 + weights[$1] } == best, "\(pairs) \(weights)")
            #expect(chosen == chosen.sorted() && chosen.allSatisfy { weights[$0] > 0 })
            #expect(chosen.isEmpty || cliques.contains(chosen))
        }
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 9), edges, zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)), Gen.int(in: 0 ... 1_000_000)) { n, raw, bounds, seed in check(n, raw, bounds, seed) }
    }
}
