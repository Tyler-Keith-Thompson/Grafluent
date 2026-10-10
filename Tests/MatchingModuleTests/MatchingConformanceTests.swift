// The result types and the entry points' shared conventions, which the catalog does not list:
// `Matching` equality (edges and weight; the graphs and the algorithm are not compared) and
// hashing, its description, `Sendable` across a `Task`, the graph copy it keeps (a later mutation
// of the original leaves it unchanged), unweighted entry points as `Matching<G, Int>` with
// `weight == edges.count`, generic code over `some Graph`, `CompressedSparseRow` through
// `AdjacencyList(csr).undirected`, an undirected graph read as directed and back (every edge a
// parallel pair), other weight types (`Int32`, `Float`), forbidden pairs under `maximize`,
// `LinearSumAssignment` and `StableMatching` as values. Expected values are worked out in each
// test's comments. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("Matching results and conventions", .tags(.conformance))
struct MatchingConformanceTests {
    @Test("Equality compares edges and weight: two algorithms, or two graphs, with the same edges and weight give equal matchings")
    func equality() {
        // P4 in path order: the greedy and Edmonds' matchings are both edges 0 and 2, weight 2.
        let path = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(path.maximalMatching() == path.maximumMatching())
        // Another graph whose greedy matching is also positions 0 and 2: equal (graphs not compared).
        let other = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(other.maximalMatching().edges == [0, 2])
        #expect(other.maximalMatching() == path.maximalMatching())
        // MA-025's P4 listed from the middle: the greedy matching is [0], Edmonds' [1, 2].
        let middle = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(middle.maximalMatching() != middle.maximumMatching())
        // The same edge with weights 3 and 5: equal edges, different weights.
        let edge = UndirectedAdjacencyList(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let light = edge.maximumWeightMatching(weight: { (_: Int) -> Int in 3 })
        let heavy = edge.maximumWeightMatching(weight: { (_: Int) -> Int in 5 })
        #expect(light.edges == heavy.edges)
        #expect(light != heavy)
        #expect(light == edge.maximumWeightMatching(weight: { (_: Int) -> Int in 3 }))
    }

    @Test("Hashable: equal matchings hash alike, and a set keeps one of each")
    func hashing() {
        let path = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let a = path.maximalMatching()
        let b = path.maximumMatching()
        #expect(a.hashValue == b.hashValue)
        let middle = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let set: Set<Matching<UndirectedAdjacencyList<Int>, Int>> = [a, b, middle.maximalMatching(), middle.maximumMatching()]
        #expect(set.count == 3)   // [0, 2] twice (one graph's), [0] and [1, 2] from the other
        // Weight is part of the value: the same edges, weights 3 and 5.
        let edge = UndirectedAdjacencyList(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let weighted: Set = [edge.maximumWeightMatching(weight: { (_: Int) -> Int in 3 }), edge.maximumWeightMatching(weight: { (_: Int) -> Int in 5 }), edge.maximumWeightMatching(weight: { (_: Int) -> Int in 3 })]
        #expect(weighted.count == 2)
    }

    @Test("description: {u–v, …} in edges order, each edge as stored; {} when empty")
    func descriptions() {
        let path = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(path.maximumMatching().description == "{0–1, 2–3}")
        #expect(UndirectedAdjacencyList<Int>(vertices: [0, 1]).maximumMatching().description == "{}")
        #expect(UndirectedAdjacencyList<Int>().maximalMatching().description == "{}")
        // String vertices: the format of the endpoints is not pinned, only that both appear.
        let named = UndirectedAdjacencyList(vertices: ["one", "two", "three"], edges: [UndirectedEdge("one", "two"), UndirectedEdge("two", "three")])
        let text = named.maximumWeightMatching(weight: { (e: Int) -> Int in [10, 11][e] }).description
        #expect(text.hasPrefix("{") && text.hasSuffix("}") && text.contains("two") && text.contains("three") && !text.contains("one"))
    }

    @Test("Unweighted entry points return Matching<G, Int> with weight == edges.count; the empty graph's matching is perfect")
    func unweightedResults() throws {
        // K4: every unweighted entry point finds a perfect matching of 2 edges.
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let k4 = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let maximal: Matching<UndirectedAdjacencyList<Int>, Int> = k4.maximalMatching()
        let maximum: Matching<UndirectedAdjacencyList<Int>, Int> = k4.maximumMatching()
        #expect(maximal.weight == 2 && maximum.weight == 2)
        #expect(maximal.isPerfect && maximum.isPerfect)
        // K2,2 as a BipartiteGraph and through a bipartition.
        let k22 = try #require(BipartiteGraph(left: [0, 1], right: [2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3)]))
        let hk: Matching<BipartiteGraph<Int>, Int> = k22.maximumBipartiteMatching()
        #expect(hk.weight == hk.edges.count && hk.edges == [0, 3])
        let plain = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3)])
        let viaSides = plain.maximumBipartiteMatching(bipartition: try #require(plain.bipartition()))
        #expect(viaSides.weight == 2 && viaSides.edges == [0, 3])
        // The empty graph: no edges, perfect (2 · 0 == 0), as NetworkX's is_perfect_matching.
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.maximumMatching().isPerfect && empty.maximalMatching().isPerfect)
        #expect(empty.maximumWeightMatching(weight: { (_: Int) -> Int in 1 }).isPerfect)
        #expect(empty.isPerfectMatching([]) && empty.isMatching([]) && empty.isMaximalMatching([]))
    }

    @Test("Sendable: a matching, an assignment and a stable matching cross a Task boundary")
    func sendable() async throws {
        let path = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let matching = path.maximumMatching()
        let mate = await Task { matching.mate(of: 0) }.value
        #expect(mate == 1)
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { (i: Int, j: Int) -> Int? in i == j ? 0 : 1 })
        let columns = await Task { assignment.columns }.value
        #expect(columns == [0, 1])
        let stable = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[0]])
        let reviewer = await Task { stable.mate(ofProposer: 0) }.value
        #expect(reviewer == 0)
    }

    @Test("A matching keeps its graph: mutating the original afterwards changes neither its mates nor its description")
    func keepsGraphCopy() {
        var graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 2])
        // Removing vertex 0 moves the last slot (3) into its place and edge 2 into position 0.
        graph.remove(0)
        graph.insert(edge: UndirectedEdge(1, 3))
        #expect(matching.mate(of: 0) == 1 && matching.mate(of: 1) == 0)
        #expect(matching.mate(of: 2) == 3 && matching.mate(of: 3) == 2)
        #expect(matching.mate(ofIndex: 0) == 1 && matching.mate(ofIndex: 3) == 2)
        #expect(matching.matchedEdge(of: 3) == 2)
        #expect(matching.description == "{0–1, 2–3}")
    }

    @Test("Generic code over some Graph: a BipartiteGraph as a Graph gets Edmonds' maximumMatching(), the same as concrete code")
    func genericCode() throws {
        func sizes<G: Graph>(_ graph: G) -> (maximal: Int, maximum: Int, weighted: Int) {
            (graph.maximalMatching().edges.count, graph.maximumMatching().edges.count,
             graph.maximumWeightMatching(weight: { (_: G.Edges.Index) -> Int in 1 }, maximumCardinality: true).edges.count)
        }
        func edmonds<G: Graph>(_ graph: G) -> [G.Edges.Index] { graph.maximumMatching().edges }
        // MA-062's path a–x–b–y: every maximum matching has 2 edges.
        let graph = try #require(BipartiteGraph(left: ["a", "b"], right: ["x", "y"], edges: [UndirectedEdge("a", "x"), UndirectedEdge("b", "x"), UndirectedEdge("a", "y")]))
        let s = sizes(graph)
        #expect(s.maximal == 1 && s.maximum == 2 && s.weighted == 2)
        #expect(edmonds(graph) == graph.maximumMatching().edges)
        #expect(graph.maximumBipartiteMatching().edges == [1, 2])
    }

    @Test("CompressedSparseRow through AdjacencyList(csr).undirected: K3,3 matched perfectly by every entry point")
    func compressedSparseRow() throws {
        let csr = CompressedSparseRow(vertexCount: 6, edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = AdjacencyList(csr).undirected
        #expect(graph.edgeCount == 9)
        #expect(graph.maximumMatching().edges.count == 3)
        #expect(graph.maximalMatching().edges.count == 3)
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 1, 2])
        let hk = graph.maximumBipartiteMatching(bipartition: sides)
        #expect(hk.isPerfect && graph.isPerfectMatching(hk.edges))
        // Weights i·j on the arc (i, 3 + j) for i, j in 1 ... 3 (MA-155): the heaviest is the diagonal, 14.
        let weighted = graph.maximumWeightMatching(weight: { (e: Int) -> Int in (graph.edges[e].u + 1) * (graph.edges[e].v - 2) })
        #expect(weighted.weight == 14)
        #expect(weighted.mate(of: 0) == 3 && weighted.mate(of: 1) == 4 && weighted.mate(of: 2) == 5)
        // The least full matching under the same weights: the anti-diagonal, 3 + 4 + 3 = 10.
        let full = try #require(graph.minimumWeightFullMatching(bipartition: sides, weight: { (e: Int) -> Int in (graph.edges[e].u + 1) * (graph.edges[e].v - 2) }))
        #expect(full.weight == 10)
        #expect(full.mate(of: 0) == 5 && full.mate(of: 1) == 4 && full.mate(of: 2) == 3)
    }

    @Test("An undirected graph read as directed and back: every edge a parallel pair; sizes unchanged, the weighted algorithms keep the earlier copy")
    func directedAndBack() {
        // C5: a maximum matching has 2 edges; every edge is now two copies, (k, forward) then (k, reversed).
        let cycle = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        let doubled = cycle.directed.undirected
        #expect(doubled.edgeCount == 10)
        let maximum = doubled.maximumMatching()
        #expect(maximum.edges.count == 2 && doubled.isMatching(maximum.edges) && doubled.isMaximalMatching(maximum.edges))
        #expect(doubled.maximalMatching().edges.count == 2)
        // Equal weights on both copies: "the heaviest copy, the earliest on ties", so never a reversed one.
        let weighted = doubled.maximumWeightMatching(weight: { $0.position + 1 })
        #expect(weighted.edges.allSatisfy { !$0.reversed })
        // The heaviest matching of C5 with weights 1 … 5 on edges 0 … 4: edges 2–3 and 4–0, weight 3 + 5 = 8.
        #expect(weighted.weight == 8)
        #expect(weighted.edges.map(\.position) == [2, 4])
    }

    @Test("Other weight types: Int32 through the SignedInteger overload, Float through the FloatingPoint one, Int8 for an assignment")
    func weightTypes() throws {
        // MA-122's s_blossom: weights 8, 9, 10, 7; the heaviest matching is 1–2 and 3–4, 15.
        let graph = UndirectedAdjacencyList(vertices: [1, 2, 3, 4], edges: [UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let narrow: [Int32] = [8, 9, 10, 7]
        let matching: Matching<UndirectedAdjacencyList<Int>, Int32> = graph.maximumWeightMatching(weight: { narrow[$0] })
        #expect(matching.edges == [0, 3] && matching.weight == 15)
        let floats: [Float] = [8, 9, 10, 7]
        let floating: Matching<UndirectedAdjacencyList<Int>, Float> = graph.maximumWeightMatching(weight: { floats[$0] })
        #expect(floating.edges == [0, 3] && floating.weight == 15)
        let least: Matching<UndirectedAdjacencyList<Int>, Int32> = graph.minimumWeightMatching(weight: { narrow[$0] })
        #expect(least.edges == [0, 3] && least.weight == 15)   // MA-161
        // MA-199's [-1 -5; -3 -2] in Int8: columns [1, 0], cost -8.
        let small: [[Int8]] = [[-1, -5], [-3, -2]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { small[$0][$1] })
        #expect(assignment.columns == [1, 0] && assignment.cost == -8)
    }

    @Test("linearSumAssignment allows forbidden pairs under maximize (scipy rejects them): the best feasible assignment")
    func forbiddenUnderMaximize() throws {
        // [5 ∞ 1; 2 3 ∞], maximize: the feasible assignments cost 5 + 3 = 8, 1 + 2 = 3 and 1 + 3 = 4.
        let matrix: [[Int?]] = [[5, nil, 1], [2, 3, nil]]
        let best = try #require(linearSumAssignment(rowCount: 2, columnCount: 3, maximize: true) { matrix[$0][$1] })
        #expect(best.rows == [0, 1] && best.columns == [0, 1] && best.cost == 8)
        // Minimizing the same matrix: 1 + 2 = 3, rows [0, 1], columns [2, 0].
        let least = try #require(linearSumAssignment(rowCount: 2, columnCount: 3) { matrix[$0][$1] })
        #expect(least.columns == [2, 0] && least.cost == 3)
        // Infeasible under maximize too: two rows that can only use column 0.
        let blocked: [[Int?]] = [[1, nil], [2, nil]]
        #expect(linearSumAssignment(rowCount: 2, columnCount: 2, maximize: true) { blocked[$0][$1] } == nil)
    }

    @Test("LinearSumAssignment and StableMatching are values: Equatable and Hashable by their contents")
    func valueTypes() throws {
        let matrix: [[Int?]] = [[400, 150, 400], [400, 450, 600], [300, 225, 300]]
        let a = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        let b = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        let c = try #require(linearSumAssignment(rowCount: 3, columnCount: 3, maximize: true) { matrix[$0][$1] })
        #expect(a == b && a.hashValue == b.hashValue)
        #expect(a != c)                        // MA-182 against MA-187
        #expect(Set([a, b, c]).count == 2)
        let gs = stableMatching(proposerPreferences: [[0, 1, 2], [1, 2, 0], [2, 0, 1]], reviewerPreferences: [[1, 2, 0], [2, 0, 1], [0, 1, 2]])
        let same = stableMatching(proposerPreferences: [[0, 1, 2], [1, 2, 0], [2, 0, 1]], reviewerPreferences: [[1, 2, 0], [2, 0, 1], [0, 1, 2]])
        let swapped = stableMatching(proposerPreferences: [[1, 2, 0], [2, 0, 1], [0, 1, 2]], reviewerPreferences: [[0, 1, 2], [1, 2, 0], [2, 0, 1]])
        #expect(gs == same && gs.hashValue == same.hashValue)
        #expect(gs != swapped)                 // MA-213 against MA-214: mates [0, 1, 2] and [1, 2, 0]
        #expect(!gs.description.isEmpty)
        for r in 0 ..< 3 { #expect(gs.mate(ofReviewer: r) == r) }
    }
}
