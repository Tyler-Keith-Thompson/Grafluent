// Spanning arborescences and branchings by Edmonds' algorithm: NetworkX's `test_branchings.py`
// graph with every rooted optimum (each unique, checked by brute force in ref.py), the trivial
// graphs, self-loops, parallel edges, unreachable vertices, which edges are weighed, the checked
// spellings, the conversion to `Arborescence`, and the traps. Case IDs (ST-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import SpanningTrees
import StableGraphs
import Testing
import Trees

@Suite("Spanning arborescences and branchings")
struct ArborescenceTests {
    @Test("ST-200 NetworkX's branching graph: the maximum branching and both spanning optima")
    func networkXGraph() {
        // NetworkX `test_branchings.py` G_array, its edges in row-major order.
        let edges: [(Int, Int, Int)] = [
            (0, 2, 12), (0, 4, 12), (1, 0, 4), (1, 5, 13), (2, 1, 17), (2, 3, 21), (2, 5, 12), (3, 0, 5), (3, 4, 17),
            (3, 6, 18), (4, 7, 12), (5, 6, 14), (5, 8, 12), (6, 2, 21), (6, 8, 15), (7, 3, 19), (7, 6, 15), (8, 7, 18),
        ]
        let graph = AdjacencyList(vertices: 0 ..< 9, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: (Int) -> Int = { edges[$0].2 }
        let maximum = graph.maximumBranching(weight: w)
        #expect(maximum.edges == [0, 3, 4, 5, 8, 9, 14, 17])
        #expect(maximum.weight == 131)
        #expect(graph.maximumSpanningArborescence(weight: w) == maximum)
        #expect(graph.maximumSpanningArborescence(from: 0, weight: w) == maximum)
        let minimum = graph.minimumSpanningArborescence(weight: w)
        #expect(minimum?.edges == [0, 1, 4, 6, 7, 10, 11, 12])
        #expect(minimum?.weight == 96)
        #expect(graph.minimumSpanningArborescence(from: 3, weight: w) == minimum)
        #expect(graph.minimumBranching(weight: w).edges == [])
        #expect(graph.minimumBranching(weight: w).weight == 0)
        // Negated, the minimum branching is the maximum one.
        let negated = graph.minimumBranching { -edges[$0].2 }
        #expect(negated.edges == maximum.edges)
        #expect(negated.weight == -131)
        #expect(graph.maximumBranching { -edges[$0].2 }.edges == [])
    }

    @Test("ST-201 the optimum from each root of NetworkX's branching graph", arguments: [
        (0, 131, [0, 3, 4, 5, 8, 9, 14, 17], 110, [0, 1, 4, 6, 10, 11, 12, 15]),
        (1, 124, [3, 5, 7, 8, 11, 13, 14, 17], 97, [0, 1, 2, 6, 10, 11, 12, 15]),
        (2, 124, [3, 4, 5, 7, 8, 9, 14, 17], 102, [1, 2, 4, 6, 10, 11, 12, 15]),
        (3, 124, [3, 4, 7, 8, 9, 13, 14, 17], 96, [0, 1, 4, 6, 7, 10, 11, 12]),
        (4, 120, [3, 4, 7, 9, 10, 13, 14, 15], 103, [0, 4, 6, 7, 10, 11, 12, 15]),
        (5, 128, [4, 5, 7, 8, 11, 13, 14, 17], 109, [0, 1, 4, 7, 11, 12, 15, 17]),
        (6, 127, [3, 4, 5, 7, 8, 13, 14, 17], 109, [1, 2, 4, 6, 10, 12, 13, 15]),
        (7, 125, [3, 4, 7, 8, 9, 13, 14, 15], 103, [0, 1, 4, 6, 7, 11, 12, 15]),
        (8, 128, [3, 4, 7, 8, 9, 13, 15, 17], 109, [0, 1, 4, 6, 7, 11, 15, 17]),
    ])
    func everyRoot(root: Int, maximumWeight: Int, maximumEdges: [Int], minimumWeight: Int, minimumEdges: [Int]) {
        let edges: [(Int, Int, Int)] = [
            (0, 2, 12), (0, 4, 12), (1, 0, 4), (1, 5, 13), (2, 1, 17), (2, 3, 21), (2, 5, 12), (3, 0, 5), (3, 4, 17),
            (3, 6, 18), (4, 7, 12), (5, 6, 14), (5, 8, 12), (6, 2, 21), (6, 8, 15), (7, 3, 19), (7, 6, 15), (8, 7, 18),
        ]
        let graph = CompressedSparseRow(vertexCount: 9, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        // Row-major input: CompressedSparseRow keeps the order, so positions are the offsets above.
        let w: (Int) -> Int = { edges[$0].2 }
        let maximum = graph.maximumSpanningArborescence(from: root, weight: w)
        #expect(maximum?.edges == maximumEdges)
        #expect(maximum?.weight == maximumWeight)
        let minimum = graph.minimumSpanningArborescence(from: root, weight: w)
        #expect(minimum?.edges == minimumEdges)
        #expect(minimum?.weight == minimumWeight)
        let tree = Arborescence(minimum!, in: graph)
        #expect(tree?.root == root)
        #expect(tree?.vertexCount == 9)
        #expect(tree.map { Array($0.edges) } == minimumEdges.map { graph.edges[$0] })
    }

    @Test("ST-202 a graph with no vertices: empty branchings, and no spanning arborescence")
    func emptyGraph() {
        let graph = AdjacencyList<Int>()
        var asked = 0
        let weight: (Int) -> Int = { _ in
            asked += 1
            return 1
        }
        #expect(graph.minimumBranching(weight: weight).edges == [])
        #expect(graph.maximumBranching(weight: weight).weight == 0)
        #expect(graph.minimumSpanningArborescence(weight: weight) == nil)
        #expect(graph.maximumSpanningArborescence(weight: weight) == nil)
        #expect(asked == 0)
    }

    @Test("ST-203 a single vertex: the empty arborescence from it, with or without a self-loop")
    func singleVertex() {
        for edges in [[], [DirectedEdge(from: "a", to: "a")]] {
            let graph = ReferenceDirectedMultigraph(vertices: ["a"], edges: edges)
            var asked = 0
            let weight: (Int) -> Int = { _ in
                asked += 1
                return -5
            }
            let empty = graph.minimumSpanningArborescence(from: "a", weight: weight)
            #expect(empty?.edges == [])
            #expect(empty?.weight == 0)
            #expect(graph.maximumSpanningArborescence(from: "a", weight: weight) == empty)
            #expect(graph.minimumSpanningArborescence(weight: weight) == empty)
            #expect(graph.maximumSpanningArborescence(weight: weight) == empty)
            #expect(graph.minimumBranching(weight: weight) == empty)
            #expect(graph.maximumBranching(weight: weight) == empty)
            // A self-loop is never weighed.
            #expect(asked == 0)
            let tree = Arborescence(empty!, in: graph)
            #expect(tree?.root == "a")
            #expect(tree?.edgeCount == 0)
        }
    }

    @Test("ST-204 parallel edges: the lighter (or heavier) copy is taken, by its position")
    func parallelEdges() {
        let edges: [(Int, Int, Int)] = [(0, 1, 5), (0, 1, 2), (1, 0, 1), (0, 1, 9), (1, 1, -7)]
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: (Int) -> Int = { edges[$0].2 }
        #expect(graph.minimumSpanningArborescence(from: 0, weight: w)?.edges == [1])
        #expect(graph.maximumSpanningArborescence(from: 0, weight: w)?.edges == [3])
        #expect(graph.minimumSpanningArborescence(weight: w)?.edges == [2])
        #expect(graph.minimumSpanningArborescence(weight: w)?.weight == 1)
        #expect(graph.maximumSpanningArborescence(weight: w)?.edges == [3])
        #expect(graph.maximumBranching(weight: w).edges == [3])
        // The −7 self-loop never counts.
        #expect(graph.minimumBranching(weight: w).edges == [])
    }

    @Test("ST-205 a vertex the root cannot reach: nil from that root, and nil without a root when no vertex reaches all")
    func unreachable() {
        // 0 → 1, 2 → 1: 1 is reached from both, but neither 0 nor 2 reaches the other.
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        #expect(graph.minimumSpanningArborescence(from: 0) { _ in 1 } == nil)
        #expect(graph.maximumSpanningArborescence(from: 2) { _ in 1 } == nil)
        #expect(graph.minimumSpanningArborescence(from: 1) { _ in 1 } == nil)
        #expect(graph.minimumSpanningArborescence { _ in 1 } == nil)
        #expect(graph.maximumSpanningArborescence { _ in 1 } == nil)
        #expect(graph.maximumBranching { _ in 1 }.edges.count == 1)
        // Two isolated vertices: no spanning arborescence.
        let isolated = AdjacencyList(vertices: 0 ..< 2, edges: [])
        #expect(isolated.minimumSpanningArborescence { _ in 1 } == nil)
        #expect(isolated.minimumBranching { _ in 1 }.edges == [])
    }

    @Test("ST-206 the root is the vertex only it can be: a source the others hang from")
    func forcedRoot() {
        // 3 has no entering edge, so it is the root of any spanning arborescence.
        let edges: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (2, 0, 1), (3, 0, 50), (3, 2, 60)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: (Int) -> Int = { edges[$0].2 }
        let minimum = graph.minimumSpanningArborescence(weight: w)
        #expect(minimum?.edges == [0, 1, 3])
        #expect(minimum?.weight == 52)
        #expect(Arborescence(minimum!, in: graph)?.root == 3)
        // Both of 3's edges and the one cycle edge into 1, which is also the maximum branching.
        let maximum = graph.maximumSpanningArborescence(weight: w)
        #expect(maximum?.edges == [0, 3, 4])
        #expect(maximum?.weight == 111)
        #expect(graph.maximumBranching(weight: w) == maximum)
    }

    @Test("ST-207 edges into the root and self-loops are never weighed; every other edge once")
    func weighedOnce() {
        let edges: [(Int, Int, Int)] = [(0, 1, 3), (1, 0, 4), (1, 2, 1), (2, 2, 9), (2, 0, 2), (0, 2, 5)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        var asked: [Int] = []
        let weight: (Int) -> Int = {
            asked.append($0)
            return edges[$0].2
        }
        _ = graph.minimumSpanningArborescence(from: 0, weight: weight)
        #expect(asked.sorted() == [0, 2, 5])
        asked = []
        _ = graph.maximumSpanningArborescence(from: 0, weight: weight)
        #expect(asked.sorted() == [0, 2, 5])
        asked = []
        _ = graph.minimumSpanningArborescence(weight: weight)
        #expect(asked.sorted() == [0, 1, 2, 4, 5])
        asked = []
        _ = graph.maximumBranching(weight: weight)
        #expect(asked.sorted() == [0, 1, 2, 4, 5])
    }

    @Test("ST-208 checked spellings throw for a missing root and agree otherwise")
    func checked() throws {
        let edges: [(String, String, Double)] = [("a", "b", 1.5), ("b", "c", 0.25), ("a", "c", 2)]
        let graph = AdjacencyList(edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: (Int) -> Double = { p in edges.first { DirectedEdge(from: $0.0, to: $0.1) == graph.edges[p] }!.2 }
        #expect(throws: VertexNotFound.self) { try graph.minimumSpanningArborescence(checkedFrom: "z", weight: w) }
        #expect(throws: VertexNotFound.self) { try graph.maximumSpanningArborescence(checkedFrom: "z", weight: w) }
        let minimum = try graph.minimumSpanningArborescence(checkedFrom: "a", weight: w)
        #expect(minimum == graph.minimumSpanningArborescence(from: "a", weight: w))
        #expect(minimum?.weight == 1.75)
        let maximum = try graph.maximumSpanningArborescence(checkedFrom: "a", weight: w)
        #expect(maximum?.weight == 3.5)
        #expect(try graph.minimumSpanningArborescence(checkedFrom: "b", weight: w) == nil)
    }

    @Test("ST-209 a graph without vertex indices (a stable graph with holes) gives the same answers")
    func unindexed() {
        let edges: [(Int, Int, Int)] = [
            (0, 2, 12), (0, 4, 12), (1, 0, 4), (1, 5, 13), (2, 1, 17), (2, 3, 21), (2, 5, 12), (3, 0, 5), (3, 4, 17),
            (3, 6, 18), (4, 7, 12), (5, 6, 14), (5, 8, 12), (6, 2, 21), (6, 8, 15), (7, 3, 19), (7, 6, 15), (8, 7, 18),
        ]
        var graph = StableDirectedGraph(vertices: [99] + Array(0 ..< 9), edges: [DirectedEdge(from: 99, to: 0)] + edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        _ = graph.remove(99)
        #expect(graph.vertexIndexBound == nil)
        // Position p + 1 holds the p-th listed edge.
        let w: (Int) -> Int = { edges[$0 - 1].2 }
        #expect(graph.maximumBranching(weight: w).edges == [0, 3, 4, 5, 8, 9, 14, 17].map { $0 + 1 })
        #expect(graph.maximumBranching(weight: w).weight == 131)
        #expect(graph.minimumSpanningArborescence(weight: w)?.weight == 96)
        #expect(graph.minimumSpanningArborescence(from: 1, weight: w)?.weight == 97)
        #expect(graph.maximumSpanningArborescence(from: 4, weight: w)?.weight == 120)
        let tree = Arborescence(graph.minimumSpanningArborescence(from: 1, weight: w)!, in: graph)
        #expect(tree?.root == 1)
        #expect(tree?.parent(of: 0) == 1)
    }

    @Test("ST-210 an adjacency matrix and Double weights")
    func adjacencyMatrix() {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1)])
        let weights: [DirectedEdge<Int>: Double] = [
            DirectedEdge(from: 0, to: 1): 0.5, DirectedEdge(from: 1, to: 2): 0.25, DirectedEdge(from: 0, to: 2): 1, DirectedEdge(from: 2, to: 1): 0.125,
        ]
        let w = { weights[matrix.edges[$0]]! }
        let minimum = matrix.minimumSpanningArborescence(from: 0, weight: w)
        #expect(minimum?.weight == 0.75)
        #expect(minimum.map { $0.edges.map { matrix.edges[$0] } } == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let maximum = matrix.maximumSpanningArborescence(from: 0, weight: w)
        #expect(maximum?.weight == 1.5)
        #expect(matrix.maximumBranching(weight: w).weight == 1.5)
        #expect(matrix.minimumSpanningArborescence(weight: w)?.weight == 0.75)
    }

    @Test("ST-211 Arborescence(_:in:) is nil for a branching that does not span")
    func conversion() {
        let edges: [(Int, Int, Int)] = [(0, 1, 2), (2, 3, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let branching = graph.maximumBranching { edges[$0].2 }
        #expect(branching.edges == [0, 1])
        #expect(Arborescence(branching, in: graph) == nil)
        let empty = AdjacencyList<Int>()
        #expect(Arborescence(empty.maximumBranching { _ in 1 }, in: empty) == nil)
    }

    @Test("ST-212 a NaN or infinite weight traps", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumSpanningArborescence(from: 0) { _ in Double.nan }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.maximumBranching { _ in Double.infinity }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumSpanningArborescence { _ in -Double.infinity }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.minimumSpanningArborescence(from: 5) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: ["a"], edges: [])
            _ = graph.maximumSpanningArborescence(from: "b") { _ in 1 }
        }
    }
}
