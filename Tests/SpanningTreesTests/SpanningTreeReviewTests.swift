// Cases added after planting bugs and after the critical review: a NaN weight traps when it is
// read, even on an edge the algorithm never takes; the default's dense path (Prim under
// (weight, position)) on every kind of conformer, its total added up in the listed order, and
// Prim from a root on a disconnected graph. Case IDs (ST-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

/// An undirected multigraph with no vertex indices, so weights are read through the walk of
/// `edges`.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// An undirected multigraph with vertex indices (positions in `vertices`) but no edge indices,
/// so ranks come from the walk of `edges`.
private struct VertexIndexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Vertex { vertices[index] }
}

@Suite("Spanning-tree review cases")
struct SpanningTreeReviewTests {
    @Test("ST-130 without the NaN edge the forests below are 0–1 and 1–2, so a trap comes from reading the weight")
    func nanEdgeIsNeverTaken() {
        // The triangle with the third edge removed, and K₉ with weights 1 by position.
        let triangle = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(triangle.kruskalMinimumSpanningTree { _ in 1.0 }.edges == [0, 1])
        let complete = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: (0 ..< 9).flatMap { u in (u + 1 ..< 9).map { UndirectedEdge(u, $0) } })
        // 36 edges on 9 vertices: dense enough for the default's Prim path; edge 35 is 7–8.
        #expect(complete.edgeCount == 36 && complete.edges[35] == UndirectedEdge(7, 8))
        #expect(!complete.minimumSpanningTree { _ in 1.0 }.edges.contains(35))
    }

    @Test("ST-130 a NaN weight on an edge never taken still traps, through the rows, the walk of edges, and the default's Prim", .tags(.precondition))
    func nanEdgeNeverTakenTraps() async {
        // The NaN edge 0–2 is last in the triangle: when it is reached, 0 and 2 are joined.
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
            _ = graph.kruskalMinimumSpanningTree { [1.0, 1.0, .nan][$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
            _ = graph.kruskalMinimumSpanningTree { [1.0, 1.0, .nan][$0] }
        }
        await #expect(processExitsWith: .failure) {
            let graph = PlainGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
            _ = graph.boruvkaMinimumSpanningTree { [1.0, 1.0, .nan][$0] }
        }
        // K₉ is dense, so the default runs Prim under (weight, position); 8 is first reached from 0
        // by an earlier edge, so the NaN edge 7–8 never wins.
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: (0 ..< 9).flatMap { u in (u + 1 ..< 9).map { UndirectedEdge(u, $0) } })
            _ = graph.minimumSpanningTree { $0 == 35 ? .nan : 1.0 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = PlainGraph(vertices: Array(0 ..< 9), edges: (0 ..< 9).flatMap { u in (u + 1 ..< 9).map { UndirectedEdge(u, $0) } })
            _ = graph.minimumSpanningTree { $0 == 35 ? .nan : 1.0 }
        }
    }

    @Test("ST-131 the default's total is added up in the order listed, so it overflows exactly when Kruskal's does")
    func defaultTotalOrder() {
        // 16 edges on 4 vertices, dense enough for the Prim path. Prim from 0 meets Int.max, then
        // 1, and a running total there would overflow; sorted, −1 + 1 + Int.max is exact.
        var edges: [(Int, Int, Int)] = [(0, 1, .max), (1, 2, 1), (2, 3, -1)]
        edges += Array(repeating: (2, 3, 0), count: 13)
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4 * graph.vertexCount)
        let kruskal = graph.kruskalMinimumSpanningTree { edges[$0].2 }
        #expect(kruskal.edges == [2, 1, 0])
        #expect(kruskal.weight == .max)
        #expect(graph.minimumSpanningTree { edges[$0].2 } == kruskal)
    }

    @Test("ST-132 the dense path follows the tie rule on every kind of conformer: vertex and edge indices, vertex indices only, none")
    func densePathOnEveryConformer() {
        // K₉, all weights equal: the canonical forest is the first forest in position order.
        let pairs = (0 ..< 9).flatMap { u in (u + 1 ..< 9).map { UndirectedEdge(u, $0) } }

        let matrix = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.u, to: $0.v) }).undirected
        #expect(matrix.vertexIndexBound == 9 && matrix.edgeIndexBound == nil && matrix.edgeCount == 36)
        let fromMatrix = matrix.minimumSpanningTree { _ in 1 }
        #expect(fromMatrix == matrix.kruskalMinimumSpanningTree { _ in 1 })
        #expect(fromMatrix.edges == matrix.minimumSpanningTree().edges)
        #expect(fromMatrix.edges.map { matrix.edges[$0] } == (1 ..< 9).map { UndirectedEdge(0, $0) })

        // Shuffled vertices, so index order and value order differ.
        let shuffled = [4, 7, 0, 2, 8, 1, 6, 3, 5]
        let indexed = VertexIndexedGraph(vertices: shuffled, edges: pairs.reversed())
        #expect(indexed.edgeIndexBound == nil)
        let fromIndexed = indexed.minimumSpanningTree { _ in 1 }
        #expect(fromIndexed == indexed.kruskalMinimumSpanningTree { _ in 1 })
        #expect(fromIndexed.edges == indexed.minimumSpanningTree().edges)
        // Reversed, the edges run 7–8, 6–8, 6–7, 5–8, …: the first forest takes the first edge to
        // each new vertex, at the triangular positions.
        #expect(fromIndexed.edges == [0, 1, 3, 6, 10, 15, 21, 28])

        let plain = PlainGraph(vertices: shuffled, edges: pairs.reversed())
        let fromPlain = plain.minimumSpanningTree { _ in 1 }
        #expect(fromPlain == plain.kruskalMinimumSpanningTree { _ in 1 })
        #expect(fromPlain.edges == fromIndexed.edges)

        let list = UndirectedAdjacencyList(vertices: shuffled, edges: pairs.reversed())
        #expect(list.minimumSpanningTree { _ in 1 } == list.kruskalMinimumSpanningTree { _ in 1 })
        #expect(list.minimumSpanningTree { _ in 1 }.edges == fromIndexed.edges)
    }

    @Test("ST-133 on the dense path a Double total is exactly Kruskal's, bit for bit")
    func densePathDoubleTotal() {
        // Weights that are not exact in binary, so the order of addition shows in the last bits.
        let pairs = (0 ..< 10).flatMap { u in (u + 1 ..< 10).map { UndirectedEdge(u, $0) } }
        let weights = pairs.indices.map { Double(($0 * 7919) % 97) / 10 + 0.1 }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs)
        let kruskal = graph.kruskalMinimumSpanningTree { weights[$0] }
        let fallback = graph.minimumSpanningTree { weights[$0] }
        #expect(fallback.edges == kruskal.edges)
        #expect(fallback.weight.bitPattern == kruskal.weight.bitPattern)
        #expect(fallback.weight == kruskal.edges.map { weights[$0] }.reduce(0, +))
    }

    @Test("ST-134 Prim from a root on a disconnected graph: edges start at the root and stay in its component, each joining a new vertex")
    func primFromRootOrder() {
        // Two components: a 5-cycle on 0…4 and a triangle on 5…7.
        let edges: [(Int, Int, Int)] = [(0, 1, 3), (1, 2, 1), (2, 3, 4), (3, 4, 1), (4, 0, 5), (5, 6, 1), (6, 7, 1), (7, 5, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 8, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        for root in [2, 4] {
            let tree = graph.primMinimumSpanningTree(from: root) { edges[$0].2 }
            #expect(tree.edges.count == 4)
            #expect(tree.weight == 9)
            var spanned: Set = [root]
            for position in tree.edges {
                let (u, v, _) = edges[position]
                #expect(u < 5 && v < 5, "edge \(position) leaves the root's component")
                #expect(spanned.contains(u) != spanned.contains(v), "edge \(position) does not join a new vertex")
                spanned.formUnion([u, v])
            }
            #expect(tree.edges.first.map { edges[$0].0 == root || edges[$0].1 == root } == true)
        }
        let other = graph.primMinimumSpanningTree(from: 6) { edges[$0].2 }
        #expect(other.edges.count == 2 && other.weight == 2)
        #expect(other.edges.allSatisfy { $0 >= 5 })
    }
}
