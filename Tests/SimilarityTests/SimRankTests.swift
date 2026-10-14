// SimRank against values worked by hand. s(a, a) = 1; for a ≠ b, s(a, b) = C / (|I(a)| |I(b)|) ·
// Σ s(i, j) over i ∈ I(a), j ∈ I(b), and 0 when either set is empty, where I(x) is the set of
// in-neighbors (neighbors, undirected), parallel edges once and a self-loop's vertex its own
// in-neighbor. The fixed points used: on a path a-b-c, s(a, c) = C after one step and stays; on
// K₂,₂ the two vertices of a side reach x = (C/2)/(1 − C/2) through x ← (C/2)(1 + x), and opposite
// sides stay 0.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Similarity
import Testing

/// A directed graph with no vertex indices, its vertices listed out of value order.
private struct UnindexedDigraph: DirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

/// An undirected multigraph with no vertex or edge indices.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("SimRank")
struct SimRankTests {
    @Test("An undirected path 0-1-2: the ends are C-similar, neighbors 0-similar, exactly")
    func path() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let s = try graph.simRankSimilarity()
        #expect(s.similarity(of: 0, and: 2) == 0.9)
        #expect(s.similarity(of: 2, and: 0) == 0.9)
        #expect(s.similarity(of: 0, and: 1) == 0)
        #expect(s.similarity(of: 1, and: 2) == 0)
        for v in 0 ..< 3 { #expect(s.similarity(of: v, and: v) == 1) }
        let c = try graph.simRankSimilarity(importanceFactor: 0.5)
        #expect(c.similarity(of: 0, and: 2) == 0.5)
    }

    @Test("A directed out-star 0 → 1, 0 → 2: the leaves share their only in-neighbor; the root has none")
    func directedStar() throws {
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        let s = try graph.simRankSimilarity(importanceFactor: 0.8)
        #expect(s.similarity(of: 1, and: 2) == 0.8)
        #expect(s.similarity(of: 0, and: 1) == 0)
        #expect(s.similarity(of: 2, and: 0) == 0)
        #expect(s.similarity(of: 0, and: 0) == 1)
        // Reversed, the leaves have no in-neighbors, and the root's in-neighbors are dissimilar.
        let reversed = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 0)])
        let r = try reversed.simRankSimilarity()
        #expect(r.similarity(of: 1, and: 2) == 0)
        #expect(r.similarity(of: 0, and: 1) == 0)
    }

    @Test("K₂,₂: each side's pair converges to (C/2)/(1 − C/2), the opposite pairs stay 0")
    func completeBipartite() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3)])
        let s = try graph.simRankSimilarity(importanceFactor: 0.9, tolerance: 1e-12)
        #expect(abs(s.similarity(of: 0, and: 1) - 9.0 / 11.0) < 1e-10)
        #expect(abs(s.similarity(of: 2, and: 3) - 9.0 / 11.0) < 1e-10)
        #expect(s.similarity(of: 0, and: 1) == s.similarity(of: 2, and: 3))
        for (a, b) in [(0, 2), (0, 3), (1, 2), (1, 3)] { #expect(s.similarity(of: a, and: b) == 0) }
        let c = try graph.simRankSimilarity(importanceFactor: 0.8, tolerance: 1e-12)
        #expect(abs(c.similarity(of: 0, and: 1) - 2.0 / 3.0) < 1e-10)
        // The default tolerance 1e-4 stops after twelve steps, 0.45¹² ≈ 6.9e-5 into the gap, short of 9/11.
        let loose = try graph.simRankSimilarity()
        #expect(abs(loose.similarity(of: 0, and: 1) - 9.0 / 11.0) < 1e-3)
        #expect(loose.similarity(of: 0, and: 1) < 9.0 / 11.0)
    }

    @Test("A two-vertex cycle: each is the other's only in-neighbor, so the pair stays 0")
    func twoCycle() throws {
        let undirected = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(try undirected.simRankSimilarity().similarity(of: 0, and: 1) == 0)
        let directed = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(try directed.simRankSimilarity().similarity(of: 0, and: 1) == 0)
    }

    @Test("A self-loop makes its vertex its own in-neighbor", .tags(.selfLoops))
    func selfLoops() throws {
        // Directed 0 → 0, 0 → 1: I(0) = I(1) = {0}, so s(0, 1) = C · s(0, 0).
        let directed = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        #expect(try directed.simRankSimilarity().similarity(of: 0, and: 1) == 0.9)
        // Undirected 0-0, 0-1: Γ(0) = {0, 1}, Γ(1) = {0}, so x ← (C/2)(1 + x), x = 9/11.
        let undirected = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let s = try undirected.simRankSimilarity(tolerance: 1e-12)
        #expect(abs(s.similarity(of: 0, and: 1) - 9.0 / 11.0) < 1e-10)
        // A loop is counted once, however many there are.
        let twice = Pseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        #expect(try twice.simRankSimilarity(tolerance: 1e-12).similarity(of: 0, and: 1) == s.similarity(of: 0, and: 1))
    }

    @Test("Parallel edges count once, undirected and directed")
    func parallelEdges() throws {
        let single = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 1, to: 3)])
        let doubled = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 0, to: 1)])
        let a = try single.simRankSimilarity(tolerance: 1e-12), b = try doubled.simRankSimilarity(tolerance: 1e-12)
        for u in 0 ..< 4 { for v in 0 ..< 4 { #expect(a.similarity(of: u, and: v) == b.similarity(of: u, and: v)) } }
        // I(1) = {0}, I(2) = {0, 3}, I(3) = {1}: s(1, 2) = C/2 (1 + s(0, 3)) with s(0, 3) = 0.
        #expect(a.similarity(of: 1, and: 2) == 0.45)
        let path = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let multi = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2), UndirectedEdge(2, 1), UndirectedEdge(1, 2)])
        let p = try path.simRankSimilarity(), m = try multi.simRankSimilarity()
        for u in 0 ..< 3 { for v in 0 ..< 3 { #expect(p.similarity(of: u, and: v) == m.similarity(of: u, and: v)) } }
    }

    @Test("Isolated vertices are similar only to themselves; disconnected parts never meet")
    func disconnected() throws {
        // Two paths 0-1-2 and 3-4-5, and an isolated 6.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 4), UndirectedEdge(4, 5)])
        let s = try graph.simRankSimilarity()
        #expect(s.similarity(of: 0, and: 2) == 0.9)
        #expect(s.similarity(of: 3, and: 5) == 0.9)
        for v in 0 ..< 6 { #expect(s.similarity(of: 6, and: v) == 0) }
        #expect(s.similarity(of: 6, and: 6) == 1)
        // The two middles' neighbors are dissimilar across parts.
        #expect(s.similarity(of: 1, and: 4) == 0)
        #expect(s.similarity(of: 0, and: 3) == 0)
    }

    @Test("The empty graph and a single vertex")
    func degenerate() throws {
        let empty = UndirectedAdjacencyList<Int>()
        _ = try empty.simRankSimilarity(maxIterations: 1)
        let directedEmpty = AdjacencyList<Int>()
        _ = try directedEmpty.simRankSimilarity(maxIterations: 1)
        let one = UndirectedAdjacencyList<Int>(vertices: [4], edges: [])
        #expect(try one.simRankSimilarity(maxIterations: 1).similarity(of: 4, and: 4) == 1)
        let loop = AdjacencyList(vertices: [4], edges: [DirectedEdge(from: 4, to: 4)])
        #expect(try loop.simRankSimilarity(maxIterations: 1).similarity(of: 4, and: 4) == 1)
    }

    @Test("An edgeless graph converges in one step, so maxIterations: 1 does not throw")
    func edgelessOneStep() throws {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: [])
        let s = try graph.simRankSimilarity(maxIterations: 1)
        for u in 0 ..< 5 { for v in 0 ..< 5 { #expect(s.similarity(of: u, and: v) == (u == v ? 1 : 0)) } }
    }

    @Test("NoConvergence: K₂,₂ with three steps reports 3 and the third step's change, 0.45³ = 0.091125")
    func noConvergence() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3)])
        // x₁ = 0.45, x₂ = 0.6525, x₃ = 0.743625.
        do {
            _ = try graph.simRankSimilarity(tolerance: 1e-6, maxIterations: 3)
            Issue.record("expected NoConvergence")
        } catch {
            #expect(error.iterations == 3)
            #expect(abs(error.residual - 0.091125) < 1e-12)
        }
        // A tolerance just above the third step's change converges there.
        #expect(throws: Never.self) { try graph.simRankSimilarity(tolerance: 0.0912, maxIterations: 3) }
        // The directed form throws the same.
        #expect(throws: NoConvergence.self) { try graph.directedView.simRankSimilarity(tolerance: 1e-6, maxIterations: 3) }
    }

    @Test("Symmetric exactly, 1 on the diagonal, and in [0, 1] on a graph with every feature")
    func invariants() throws {
        let graph = AdjacencyList(vertices: 0 ..< 7, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 0), DirectedEdge(from: 4, to: 4), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 5, to: 2),
        ])
        let s = try graph.simRankSimilarity(tolerance: 1e-9)
        for u in 0 ..< 7 {
            #expect(s.similarity(of: u, and: u) == 1)
            for v in 0 ..< 7 {
                #expect(s.similarity(of: u, and: v) == s.similarity(of: v, and: u))
                #expect(s.similarity(of: u, and: v) >= 0 && s.similarity(of: u, and: v) <= 1)
                #expect(s.similarity(ofIndex: u, andIndex: v) == s.similarity(of: u, and: v))
            }
        }
        // 6 has no in-neighbor.
        for v in 0 ..< 6 { #expect(s.similarity(of: 6, and: v) == 0) }
    }

    @Test("An undirected graph equals its directed view up to rounding")
    func undirectedEqualsDirectedView() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 4)])
        let a = try graph.simRankSimilarity(tolerance: 1e-10), b = try graph.directedView.simRankSimilarity(tolerance: 1e-10)
        for u in 0 ..< 6 { for v in 0 ..< 6 { #expect(abs(a.similarity(of: u, and: v) - b.similarity(of: u, and: v)) < 1e-12) } }
    }

    @Test("Without vertex indices: looked up by vertex, indexed by position in vertices")
    func unindexed() throws {
        let digraph = UnindexedDigraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c")])
        let s = try digraph.simRankSimilarity()
        #expect(s.similarity(of: "b", and: "c") == 0.9)
        #expect(s.similarity(ofIndex: 0, andIndex: 2) == 0.9)
        #expect(s.similarity(of: "a", and: "b") == 0)
        let graph = UnindexedGraph(vertices: ["z", "x", "y"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("y", "z")])
        let t = try graph.simRankSimilarity()
        #expect(t.similarity(of: "x", and: "z") == 0.9)
        #expect(t.similarity(ofIndex: 0, andIndex: 1) == 0.9)
        #expect(t.similarity(of: "y", and: "x") == 0)
    }

    @Test("CompressedSparseRow and AdjacencyMatrix agree with AdjacencyList exactly")
    func representations() throws {
        let arcs = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 4, to: 4), DirectedEdge(from: 4, to: 1)]
        let list = try AdjacencyList(vertices: 0 ..< 5, edges: arcs).simRankSimilarity(tolerance: 1e-9)
        let csr = try CompressedSparseRow(vertexCount: 5, edges: arcs).simRankSimilarity(tolerance: 1e-9)
        let matrix = try AdjacencyMatrix(vertexCount: 5, edges: arcs).simRankSimilarity(tolerance: 1e-9)
        let reference = try ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: arcs).simRankSimilarity(tolerance: 1e-9)
        for u in 0 ..< 5 {
            for v in 0 ..< 5 {
                #expect(csr.similarity(of: u, and: v) == list.similarity(of: u, and: v))
                #expect(matrix.similarity(of: u, and: v) == list.similarity(of: u, and: v))
                #expect(reference.similarity(of: u, and: v) == list.similarity(of: u, and: v))
            }
        }
    }
}
