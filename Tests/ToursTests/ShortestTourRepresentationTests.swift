// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirectedView` (each edge an arc as written; a vertex's
// row its out-edges, then its in-edges) and `AdjacencyMatrix.undirectedView` (rows by neighbour).
// CompressedSparseRow and AdjacencyMatrix number edges by row-major cell, so there each catalog
// edge's position is looked up. The walks follow each vertex's row, and Christofides' ties follow
// positions: where ref.py's models, run by swiftgen.py on the representation's rows and positions,
// give the catalog's result, it is pinned exactly; otherwise (a comment says so) the result is
// checked as genuine, with the documented start, and existing exactly when the catalog's does. See
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

/// A directed graph with no vertex or edge indices: only the protocol's vertex-level members. Out-rows
/// are in position order; parallel edges and self-loops are kept.
private struct UnindexedDirectedGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]

    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
}

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members. Rows
/// are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("shortestTour on every representation")
struct ShortestTourRepresentationTests {
    @Test("TO-469 square: the perimeter, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to469() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-470 square listed crosswise, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to470() throws {
        // pts[(0,0),(1,1),(0,1),(1,0)]; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [2, 1, 1, 1, 1, 2]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 3] as [Int])
            #expect(tour.edges == [1, 3, 4, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [2, 1, 1, 1, 1, 2]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 3] as [Int])
            #expect(tour.edges == [1, 3, 4, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [2, 1, 1, 1, 1, 2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 3] as [Int])
            #expect(tour.edges == [1, 3, 4, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [2, 1, 1, 1, 1, 2]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 3, 4, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-471 five points on a line, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to471() throws {
        // pts[(0,0),(3,0),(1,0),(4,0),(2,0)]; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 3, 4, 2] as [Int])
            #expect(tour.edges == [0, 5, 9, 8, 1] as [Int])
            #expect(tour.weight({ weights[$0] }) == 8)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 3, 4, 2] as [Int])
            #expect(tour.edges == [0, 5, 9, 8, 1] as [Int])
            #expect(tour.weight({ weights[$0] }) == 8)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 3, 4, 2] as [Int])
            #expect(tour.edges == [0, 5, 9, 8, 1] as [Int])
            #expect(tour.weight({ weights[$0] }) == 8)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 3, 4, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 5, 9, 8, 1] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 8)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-472 all weights equal: K(5) weight 1, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to472() throws {
        // K(5) weight 1; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 4, 7, 9, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 4, 7, 9, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 4, 7, 9, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 4, 7, 9, 3] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-473 K(4) with weights 1..6, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to473() throws {
        // K(4) weights 1, 2, 3, 4, 5, 6 in edge order; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 14)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 14)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 14)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 14)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-474 lcgpts(6,1,10), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to474() throws {
        // lcgpts(6,1,10); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3, 5] as [Int])
            #expect(tour.edges == [1, 10, 7, 6, 13, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 30)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3, 5] as [Int])
            #expect(tour.edges == [1, 10, 7, 6, 13, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 30)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3, 5] as [Int])
            #expect(tour.edges == [1, 10, 7, 6, 13, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 30)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3, 5] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 10, 7, 6, 13, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 30)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-475 lcgpts(8,2,20), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to475() throws {
        // lcgpts(8,2,20); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 7, 6, 2, 3, 4, 5] as [Int])
            #expect(tour.edges == [0, 12, 27, 16, 13, 18, 22, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 68)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 7, 6, 2, 3, 4, 5] as [Int])
            #expect(tour.edges == [0, 12, 27, 16, 13, 18, 22, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 68)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 7, 6, 2, 3, 4, 5] as [Int])
            #expect(tour.edges == [0, 12, 27, 16, 13, 18, 22, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 68)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 7, 6, 2, 3, 4, 5] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 12, 27, 16, 13, 18, 22, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 68)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-476 lcgpts(9,3,30), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to476() throws {
        // lcgpts(9,3,30); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 8, 5, 6, 3, 7, 4] as [Int])
            #expect(tour.edges == [1, 8, 14, 32, 30, 23, 24, 28, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 96)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 8, 5, 6, 3, 7, 4] as [Int])
            #expect(tour.edges == [1, 8, 14, 32, 30, 23, 24, 28, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 96)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 8, 5, 6, 3, 7, 4] as [Int])
            #expect(tour.edges == [1, 8, 14, 32, 30, 23, 24, 28, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 96)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 8, 5, 6, 3, 7, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 8, 14, 32, 30, 23, 24, 28, 3] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 96)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-477 lcgK(7,4,9): not metric, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to477() throws {
        // lcgK(7,4,9); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 4, 6, 3] as [Int])
            #expect(tour.edges == [1, 6, 9, 18, 19, 17, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 22)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 4, 6, 3] as [Int])
            #expect(tour.edges == [1, 6, 9, 18, 19, 17, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 22)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 4, 6, 3] as [Int])
            #expect(tour.edges == [1, 6, 9, 18, 19, 17, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 22)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 4, 6, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 6, 9, 18, 19, 17, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 22)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-478 lcgK(8,5,20): not metric, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to478() throws {
        // lcgK(8,5,20); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 7, 5, 3, 4, 6] as [Int])
            #expect(tour.edges == [0, 7, 17, 26, 19, 18, 23, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 48)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 7, 5, 3, 4, 6] as [Int])
            #expect(tour.edges == [0, 7, 17, 26, 19, 18, 23, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 48)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 7, 5, 3, 4, 6] as [Int])
            #expect(tour.edges == [0, 7, 17, 26, 19, 18, 23, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 48)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 7, 5, 3, 4, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 7, 17, 26, 19, 18, 23, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 48)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-479 lcgK(6,6,9,/4): Double weights, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to479() throws {
        // lcgK(6,6,9,/4); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 4, 3] as [Int])
            #expect(tour.edges == [0, 5, 11, 14, 12, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 5.5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 4, 3] as [Int])
            #expect(tour.edges == [0, 5, 11, 14, 12, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 5.5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 4, 3] as [Int])
            #expect(tour.edges == [0, 5, 11, 14, 12, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 5.5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 4, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 5, 11, 14, 12, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 5.5)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-480 negative weights, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to480() throws {
        // K(4) weights -1, 2, -3, 4, 0, -2; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [-1, 2, -3, 4, 0, -2]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == -2)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [-1, 2, -3, 4, 0, -2]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == -2)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [-1, 2, -3, 4, 0, -2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == -2)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [-1, 2, -3, 4, 0, -2]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == -2)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-481 parallel copies: the lightest, on ReferencePseudograph, no indices")
    func to481() throws {
        // multigraph V [0, 1, 2]; E [0-1 5, 0-1 2, 1-2 1, 2-0 3, 2-0 3]; shortestTour(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
            let weights: [Int] = [5, 2, 1, 3, 3]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
            let weights: [Int] = [5, 2, 1, 3, 3]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-482 self-loops ignored, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to482() throws {
        // multigraph V [0, 1, 2]; E [0-0 -9, 0-1 1, 1-2 2, 1-1 -9, 2-0 3]; shortestTour(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-483 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to483() throws {
        // V [d, a, c, b]; E [d-a 1, d-c 4, d-b 2, a-c 2, a-b 5, c-b 1]; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(String, String)] = [("d", "a"), ("d", "c"), ("d", "b"), ("a", "c"), ("a", "b"), ("c", "b")]
            let weights: [Int] = [1, 4, 2, 2, 5, 1]
            let graph = Pseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == ["d", "a", "c", "b"] as [String])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("d", "c"), ("d", "b"), ("a", "c"), ("a", "b"), ("c", "b")]
            let weights: [Int] = [1, 4, 2, 2, 5, 1]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == ["d", "a", "c", "b"] as [String])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(String, String)] = [("d", "a"), ("d", "c"), ("d", "b"), ("a", "c"), ("a", "b"), ("c", "b")]
            let weights: [Int] = [1, 4, 2, 2, 5, 1]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == ["d", "a", "c", "b"] as [String])
            #expect(tour.edges == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 4, 2, 2, 5, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 3, 5, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-484 one vertex: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to484() {
        // V [0]; E []; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-485 two vertices: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to485() {
        // V [0, 1]; E [0-1 3]; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-486 two vertices, parallel edges: nil (tours read the simple graph), on ReferencePseudograph, no indices")
    func to486() {
        // multigraph V [0, 1]; E [0-1 3, 0-1 4]; shortestTour(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let weights: [Int] = [3, 4]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let weights: [Int] = [3, 4]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
    }

    @Test("TO-487 empty graph: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to487() {
        // V []; E []; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-488 not complete: C(5) is its only tour, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to488() throws {
        // C(5) weights 1, 2, 3, 4, 5; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 15)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 15)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 15)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 15)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-489 not complete, no Hamiltonian cycle: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to489() {
        // V [0, 1, 2, 3]; E [0-1 1, 0-2 1, 0-3 1, 1-2 1]; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2)]
            let weights: [Int] = [1, 1, 1, 1]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2)]
            let weights: [Int] = [1, 1, 1, 1]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2)]
            let weights: [Int] = [1, 1, 1, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2)]
            let weights: [Int] = [1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-490 Petersen weight 1: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to490() {
        // nx(petersen_graph) weight 1; shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-491 lcgpts(12,7,50), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to491() throws {
        // lcgpts(12,7,50); shortestTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
            let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 10, 8, 11, 1, 3, 7, 9, 2, 5, 6] as [Int])
            #expect(tour.edges == [3, 43, 61, 62, 20, 12, 33, 57, 27, 23, 45, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 210)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
            let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 10, 8, 11, 1, 3, 7, 9, 2, 5, 6] as [Int])
            #expect(tour.edges == [3, 43, 61, 62, 20, 12, 33, 57, 27, 23, 45, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 210)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
            let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 10, 8, 11, 1, 3, 7, 9, 2, 5, 6] as [Int])
            #expect(tour.edges == [3, 43, 61, 62, 20, 12, 33, 57, 27, 23, 45, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 210)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
            let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 10, 8, 11, 1, 3, 7, 9, 2, 5, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 43, 61, 62, 20, 12, 33, 57, 27, 23, 45, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 210)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-507 asymmetric triangle: the lighter direction, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to507() throws {
        // V [0, 1, 2]; E [0→1 1, 1→2 1, 2→0 1, 0→2 2, 2→1 2, 1→0 2]; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [1, 1, 1, 2, 2, 2]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [0, 1, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [1, 1, 1, 2, 2, 2]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [0, 1, 2] as [Int])
            #expect(tour.weight({ weights[$0] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [1, 1, 1, 2, 2, 2]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [1, 1, 1, 2, 2, 2]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-508 asymmetric triangle, the other way, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to508() throws {
        // V [0, 1, 2]; E [0→1 3, 1→2 3, 2→0 3, 0→2 1, 2→1 2, 1→0 1]; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [3, 3, 3, 1, 2, 1]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1] as [Int])
            #expect(tour.edges == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [3, 3, 3, 1, 2, 1]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1] as [Int])
            #expect(tour.edges == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [3, 3, 3, 1, 2, 1]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [3, 3, 3, 1, 2, 1]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-509 Kd(4) with weights 1..12, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to509() throws {
        // Kd(4) weights 1, 2, …, 12 in edge order; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[$0] }) == 25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[$0] }) == 25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-510 all weights equal: Kd(4) weight 1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to510() throws {
        // Kd(4) weight 1; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 4, 8, 9] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-511 lcgKd(5,1,9), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to511() throws {
        // lcgKd(5,1,9); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3)]
            let weights: [Int] = [6, 4, 4, 4, 1, 9, 6, 8, 4, 5, 4, 8, 4, 4, 6, 5, 2, 9, 8, 7]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 2, 3, 1] as [Int])
            #expect(tour.edges == [3, 18, 10, 13, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 21)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3)]
            let weights: [Int] = [6, 4, 4, 4, 1, 9, 6, 8, 4, 5, 4, 8, 4, 4, 6, 5, 2, 9, 8, 7]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 2, 3, 1] as [Int])
            #expect(tour.edges == [3, 18, 10, 13, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 21)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3)]
            let weights: [Int] = [6, 4, 4, 4, 1, 9, 6, 8, 4, 5, 4, 8, 4, 4, 6, 5, 2, 9, 8, 7]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 2, 3, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 18, 10, 13, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 21)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3)]
            let weights: [Int] = [6, 4, 4, 4, 1, 9, 6, 8, 4, 5, 4, 8, 4, 4, 6, 5, 2, 9, 8, 7]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 2, 3, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 18, 10, 13, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 21)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-512 lcgKd(6,2,20), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to512() throws {
        // lcgKd(6,2,20); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Int] = [1, 3, 17, 5, 16, 20, 9, 19, 6, 3, 4, 3, 15, 15, 17, 15, 15, 14, 7, 16, 13, 19, 5, 15, 6, 7, 20, 3, 4, 8]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 5, 3, 4, 2] as [Int])
            #expect(tour.edges == [0, 9, 28, 18, 22, 10] as [Int])
            #expect(tour.weight({ weights[$0] }) == 24)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Int] = [1, 3, 17, 5, 16, 20, 9, 19, 6, 3, 4, 3, 15, 15, 17, 15, 15, 14, 7, 16, 13, 19, 5, 15, 6, 7, 20, 3, 4, 8]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 5, 3, 4, 2] as [Int])
            #expect(tour.edges == [0, 9, 28, 18, 22, 10] as [Int])
            #expect(tour.weight({ weights[$0] }) == 24)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Int] = [1, 3, 17, 5, 16, 20, 9, 19, 6, 3, 4, 3, 15, 15, 17, 15, 15, 14, 7, 16, 13, 19, 5, 15, 6, 7, 20, 3, 4, 8]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 5, 3, 4, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 9, 28, 18, 22, 10] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 24)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Int] = [1, 3, 17, 5, 16, 20, 9, 19, 6, 3, 4, 3, 15, 15, 17, 15, 15, 14, 7, 16, 13, 19, 5, 15, 6, 7, 20, 3, 4, 8]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 5, 3, 4, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 9, 28, 18, 22, 10] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 24)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-513 lcgKd(7,3,9), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to513() throws {
        // lcgKd(7,3,9); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5)]
            let weights: [Int] = [6, 2, 6, 8, 7, 3, 8, 3, 9, 7, 5, 4, 9, 4, 2, 6, 7, 2, 5, 6, 3, 2, 3, 7, 6, 9, 5, 2, 5, 1, 5, 4, 6, 2, 3, 7, 7, 7, 7, 8, 2, 4]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 6, 4, 3, 5] as [Int])
            #expect(tour.edges == [1, 13, 11, 40, 27, 22, 30] as [Int])
            #expect(tour.weight({ weights[$0] }) == 22)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5)]
            let weights: [Int] = [6, 2, 6, 8, 7, 3, 8, 3, 9, 7, 5, 4, 9, 4, 2, 6, 7, 2, 5, 6, 3, 2, 3, 7, 6, 9, 5, 2, 5, 1, 5, 4, 6, 2, 3, 7, 7, 7, 7, 8, 2, 4]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 6, 4, 3, 5] as [Int])
            #expect(tour.edges == [1, 13, 11, 40, 27, 22, 30] as [Int])
            #expect(tour.weight({ weights[$0] }) == 22)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5)]
            let weights: [Int] = [6, 2, 6, 8, 7, 3, 8, 3, 9, 7, 5, 4, 9, 4, 2, 6, 7, 2, 5, 6, 3, 2, 3, 7, 6, 9, 5, 2, 5, 1, 5, 4, 6, 2, 3, 7, 7, 7, 7, 8, 2, 4]
            let graph = CompressedSparseRow(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 6, 4, 3, 5] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 13, 11, 40, 27, 22, 30] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 22)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5)]
            let weights: [Int] = [6, 2, 6, 8, 7, 3, 8, 3, 9, 7, 5, 4, 9, 4, 2, 6, 7, 2, 5, 6, 3, 2, 3, 7, 6, 9, 5, 2, 5, 1, 5, 4, 6, 2, 3, 7, 7, 7, 7, 8, 2, 4]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 6, 4, 3, 5] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 13, 11, 40, 27, 22, 30] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 22)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-514 lcgKd(8,4,30), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to514() throws {
        // lcgKd(8,4,30); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6)]
            let weights: [Int] = [27, 23, 5, 12, 6, 18, 2, 24, 15, 17, 26, 15, 27, 15, 12, 8, 25, 8, 19, 29, 9, 26, 1, 29, 28, 17, 27, 24, 28, 11, 20, 19, 20, 1, 1, 26, 4, 3, 9, 5, 5, 15, 6, 12, 21, 10, 7, 4, 29, 7, 8, 30, 7, 22, 5, 27]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 7, 3, 1, 5, 2, 4, 6] as [Int])
            #expect(tour.edges == [6, 52, 22, 11, 37, 17, 33, 42] as [Int])
            #expect(tour.weight({ weights[$0] }) == 43)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6)]
            let weights: [Int] = [27, 23, 5, 12, 6, 18, 2, 24, 15, 17, 26, 15, 27, 15, 12, 8, 25, 8, 19, 29, 9, 26, 1, 29, 28, 17, 27, 24, 28, 11, 20, 19, 20, 1, 1, 26, 4, 3, 9, 5, 5, 15, 6, 12, 21, 10, 7, 4, 29, 7, 8, 30, 7, 22, 5, 27]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 7, 3, 1, 5, 2, 4, 6] as [Int])
            #expect(tour.edges == [6, 52, 22, 11, 37, 17, 33, 42] as [Int])
            #expect(tour.weight({ weights[$0] }) == 43)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6)]
            let weights: [Int] = [27, 23, 5, 12, 6, 18, 2, 24, 15, 17, 26, 15, 27, 15, 12, 8, 25, 8, 19, 29, 9, 26, 1, 29, 28, 17, 27, 24, 28, 11, 20, 19, 20, 1, 1, 26, 4, 3, 9, 5, 5, 15, 6, 12, 21, 10, 7, 4, 29, 7, 8, 30, 7, 22, 5, 27]
            let graph = CompressedSparseRow(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 7, 3, 1, 5, 2, 4, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [6, 52, 22, 11, 37, 17, 33, 42] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 43)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6)]
            let weights: [Int] = [27, 23, 5, 12, 6, 18, 2, 24, 15, 17, 26, 15, 27, 15, 12, 8, 25, 8, 19, 29, 9, 26, 1, 29, 28, 17, 27, 24, 28, 11, 20, 19, 20, 1, 1, 26, 4, 3, 9, 5, 5, 15, 6, 12, 21, 10, 7, 4, 29, 7, 8, 30, 7, 22, 5, 27]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 7, 3, 1, 5, 2, 4, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [6, 52, 22, 11, 37, 17, 33, 42] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 43)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-515 lcgKd(9,5,50), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to515() throws {
        // lcgKd(9,5,50); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7)]
            let weights: [Int] = [43, 24, 35, 6, 26, 12, 20, 10, 41, 25, 6, 35, 39, 22, 44, 28, 19, 14, 43, 41, 1, 15, 29, 3, 42, 15, 12, 5, 20, 30, 21, 40, 36, 44, 16, 4, 36, 40, 21, 32, 15, 49, 31, 35, 41, 41, 5, 37, 19, 25, 23, 1, 18, 27, 21, 1, 12, 8, 42, 13, 42, 26, 25, 37, 22, 9, 13, 41, 26, 20, 12, 13]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 8, 1, 3, 4, 2, 5, 7] as [Int])
            #expect(tour.edges == [5, 55, 65, 10, 27, 34, 20, 46, 56] as [Int])
            #expect(tour.weight({ weights[$0] }) == 67)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7)]
            let weights: [Int] = [43, 24, 35, 6, 26, 12, 20, 10, 41, 25, 6, 35, 39, 22, 44, 28, 19, 14, 43, 41, 1, 15, 29, 3, 42, 15, 12, 5, 20, 30, 21, 40, 36, 44, 16, 4, 36, 40, 21, 32, 15, 49, 31, 35, 41, 41, 5, 37, 19, 25, 23, 1, 18, 27, 21, 1, 12, 8, 42, 13, 42, 26, 25, 37, 22, 9, 13, 41, 26, 20, 12, 13]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 8, 1, 3, 4, 2, 5, 7] as [Int])
            #expect(tour.edges == [5, 55, 65, 10, 27, 34, 20, 46, 56] as [Int])
            #expect(tour.weight({ weights[$0] }) == 67)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7)]
            let weights: [Int] = [43, 24, 35, 6, 26, 12, 20, 10, 41, 25, 6, 35, 39, 22, 44, 28, 19, 14, 43, 41, 1, 15, 29, 3, 42, 15, 12, 5, 20, 30, 21, 40, 36, 44, 16, 4, 36, 40, 21, 32, 15, 49, 31, 35, 41, 41, 5, 37, 19, 25, 23, 1, 18, 27, 21, 1, 12, 8, 42, 13, 42, 26, 25, 37, 22, 9, 13, 41, 26, 20, 12, 13]
            let graph = CompressedSparseRow(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 8, 1, 3, 4, 2, 5, 7] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [5, 55, 65, 10, 27, 34, 20, 46, 56] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 67)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7)]
            let weights: [Int] = [43, 24, 35, 6, 26, 12, 20, 10, 41, 25, 6, 35, 39, 22, 44, 28, 19, 14, 43, 41, 1, 15, 29, 3, 42, 15, 12, 5, 20, 30, 21, 40, 36, 44, 16, 4, 36, 40, 21, 32, 15, 49, 31, 35, 41, 41, 5, 37, 19, 25, 23, 1, 18, 27, 21, 1, 12, 8, 42, 13, 42, 26, 25, 37, 22, 9, 13, 41, 26, 20, 12, 13]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 8, 1, 3, 4, 2, 5, 7] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [5, 55, 65, 10, 27, 34, 20, 46, 56] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 67)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-516 lcgKd(6,6,9,/4): Double weights, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to516() throws {
        // lcgKd(6,6,9,/4); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5, 1.5, 2.0, 1.0, 0.25, 0.5, 0.5, 2.0, 1.75, 2.0, 0.5, 1.25, 1.75, 2.25, 0.5, 1.0]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 3, 4] as [Int])
            #expect(tour.edges == [0, 6, 14, 28, 18, 20] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4.25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5, 1.5, 2.0, 1.0, 0.25, 0.5, 0.5, 2.0, 1.75, 2.0, 0.5, 1.25, 1.75, 2.25, 0.5, 1.0]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 3, 4] as [Int])
            #expect(tour.edges == [0, 6, 14, 28, 18, 20] as [Int])
            #expect(tour.weight({ weights[$0] }) == 4.25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5, 1.5, 2.0, 1.0, 0.25, 0.5, 0.5, 2.0, 1.75, 2.0, 0.5, 1.25, 1.75, 2.25, 0.5, 1.0]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 3, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 6, 14, 28, 18, 20] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4.25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5, 1.5, 2.0, 1.0, 0.25, 0.5, 0.5, 2.0, 1.75, 2.0, 0.5, 1.25, 1.75, 2.25, 0.5, 1.0]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 5, 3, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 6, 14, 28, 18, 20] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 4.25)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-517 negative weights, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to517() throws {
        // Kd(3) weights -1, 2, 3, -4, 5, 0; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let weights: [Int] = [-1, 2, 3, -4, 5, 0]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [0, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 0)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let weights: [Int] = [-1, 2, 3, -4, 5, 0]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [0, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 0)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let weights: [Int] = [-1, 2, 3, -4, 5, 0]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 3, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 0)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let weights: [Int] = [-1, 2, 3, -4, 5, 0]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 3, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 0)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-518 parallel arcs: the lightest, on ReferenceDirectedMultigraph, no indices")
    func to518() throws {
        // multigraph V [0, 1, 2]; E [0→1 5, 0→1 2, 1→2 1, 2→0 3, 2→0 3]; shortestTour(weight:)
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
            let weights: [Int] = [5, 2, 1, 3, 3]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
            let weights: [Int] = [5, 2, 1, 3, 3]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-519 self-loops ignored, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to519() throws {
        // multigraph V [0, 1, 2]; E [0→0 -9, 0→1 1, 1→2 2, 1→1 -9, 2→0 3]; shortestTour(weight:)
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 2, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-520 vertex order, not label order, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to520() throws {
        // V [d, a, c]; E [d→a 4, a→c 4, c→d 4, d→c 1, c→a 1, a→d 1]; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "d"), ("d", "c"), ("c", "a"), ("a", "d")]
            let weights: [Int] = [4, 4, 4, 1, 1, 1]
            let graph = DirectedPseudograph<String>(vertices: ["d", "a", "c"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c"] as [String])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == ["d", "c", "a"] as [String])
            #expect(tour.edges == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "d"), ("d", "c"), ("c", "a"), ("a", "d")]
            let weights: [Int] = [4, 4, 4, 1, 1, 1]
            let graph = UnindexedDirectedGraph<String>(vertices: ["d", "a", "c"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c"] as [String])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == ["d", "c", "a"] as [String])
            #expect(tour.edges == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [4, 4, 4, 1, 1, 1]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
            let weights: [Int] = [4, 4, 4, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 4, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 3)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-521 not complete: Cd(5) is its only tour, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to521() throws {
        // Cd(5) weights 1, 2, 3, 4, 5; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 15)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 15)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 15)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let weights: [Int] = [1, 2, 3, 4, 5]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 15)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-522 not complete, one way only: Pd(4) has no tour, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to522() {
        // Pd(4) weight 1; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let weights: [Int] = [1, 1, 1]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let weights: [Int] = [1, 1, 1]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let weights: [Int] = [1, 1, 1]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let weights: [Int] = [1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-523 tournament(6,1) weight 1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to523() throws {
        // tournament(6,1) weight 1; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 5, 1, 4, 2] as [Int])
            #expect(tour.edges == [2, 13, 8, 7, 10, 1] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 5, 1, 4, 2] as [Int])
            #expect(tour.edges == [2, 13, 8, 7, 10, 1] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 5, 1, 4, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [2, 13, 8, 7, 10, 1] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 5, 1, 4, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [2, 13, 8, 7, 10, 1] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-524 transitive tournament: nil, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to524() {
        // V [0, 1, 2, 3]; E [0→1 1, 0→2 1, 0→3 1, 1→2 1, 1→3 1, 2→3 1]; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-525 one vertex: nil, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to525() {
        // V [0]; E []; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-526 antiparallel pair: nil (tours need three vertices), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to526() {
        // V [0, 1]; E [0→1 1, 1→0 2]; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let weights: [Int] = [1, 2]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let weights: [Int] = [1, 2]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let weights: [Int] = [1, 2]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let weights: [Int] = [1, 2]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-527 empty digraph: nil, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to527() {
        // V []; E []; shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = CompressedSparseRow(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.shortestTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-528 lcgKd(12,7,100), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to528() throws {
        // lcgKd(12,7,100); shortestTour(weight:)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (7, 9), (7, 10), (7, 11), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 9), (8, 10), (8, 11), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (9, 11), (10, 0), (10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (10, 6), (10, 7), (10, 8), (10, 9), (10, 11), (11, 0), (11, 1), (11, 2), (11, 3), (11, 4), (11, 5), (11, 6), (11, 7), (11, 8), (11, 9), (11, 10)]
            let weights: [Int] = [79, 32, 54, 74, 46, 20, 65, 65, 40, 87, 96, 76, 33, 81, 50, 63, 6, 100, 97, 52, 37, 94, 55, 99, 54, 5, 41, 46, 94, 33, 53, 18, 51, 76, 74, 40, 10, 8, 73, 53, 46, 36, 89, 11, 81, 45, 5, 5, 47, 91, 73, 55, 58, 69, 75, 52, 9, 57, 7, 4, 60, 34, 64, 61, 56, 86, 1, 84, 53, 39, 22, 99, 11, 24, 9, 66, 19, 82, 51, 35, 33, 36, 77, 33, 78, 100, 79, 68, 40, 80, 26, 22, 18, 55, 49, 59, 16, 77, 26, 84, 17, 7, 86, 73, 32, 52, 56, 5, 95, 72, 82, 4, 29, 1, 6, 55, 83, 22, 11, 8, 28, 47, 99, 51, 71, 89, 13, 15, 86, 74, 11, 10]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 9, 8, 11, 10, 7, 2, 4, 3, 5, 1, 6] as [Int])
            #expect(tour.edges == [8, 107, 98, 131, 117, 79, 25, 47, 37, 56, 16, 66] as [Int])
            #expect(tour.weight({ weights[$0] }) == 172)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (7, 9), (7, 10), (7, 11), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 9), (8, 10), (8, 11), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (9, 11), (10, 0), (10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (10, 6), (10, 7), (10, 8), (10, 9), (10, 11), (11, 0), (11, 1), (11, 2), (11, 3), (11, 4), (11, 5), (11, 6), (11, 7), (11, 8), (11, 9), (11, 10)]
            let weights: [Int] = [79, 32, 54, 74, 46, 20, 65, 65, 40, 87, 96, 76, 33, 81, 50, 63, 6, 100, 97, 52, 37, 94, 55, 99, 54, 5, 41, 46, 94, 33, 53, 18, 51, 76, 74, 40, 10, 8, 73, 53, 46, 36, 89, 11, 81, 45, 5, 5, 47, 91, 73, 55, 58, 69, 75, 52, 9, 57, 7, 4, 60, 34, 64, 61, 56, 86, 1, 84, 53, 39, 22, 99, 11, 24, 9, 66, 19, 82, 51, 35, 33, 36, 77, 33, 78, 100, 79, 68, 40, 80, 26, 22, 18, 55, 49, 59, 16, 77, 26, 84, 17, 7, 86, 73, 32, 52, 56, 5, 95, 72, 82, 4, 29, 1, 6, 55, 83, 22, 11, 8, 28, 47, 99, 51, 71, 89, 13, 15, 86, 74, 11, 10]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.shortestTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 9, 8, 11, 10, 7, 2, 4, 3, 5, 1, 6] as [Int])
            #expect(tour.edges == [8, 107, 98, 131, 117, 79, 25, 47, 37, 56, 16, 66] as [Int])
            #expect(tour.weight({ weights[$0] }) == 172)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (7, 9), (7, 10), (7, 11), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 9), (8, 10), (8, 11), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (9, 11), (10, 0), (10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (10, 6), (10, 7), (10, 8), (10, 9), (10, 11), (11, 0), (11, 1), (11, 2), (11, 3), (11, 4), (11, 5), (11, 6), (11, 7), (11, 8), (11, 9), (11, 10)]
            let weights: [Int] = [79, 32, 54, 74, 46, 20, 65, 65, 40, 87, 96, 76, 33, 81, 50, 63, 6, 100, 97, 52, 37, 94, 55, 99, 54, 5, 41, 46, 94, 33, 53, 18, 51, 76, 74, 40, 10, 8, 73, 53, 46, 36, 89, 11, 81, 45, 5, 5, 47, 91, 73, 55, 58, 69, 75, 52, 9, 57, 7, 4, 60, 34, 64, 61, 56, 86, 1, 84, 53, 39, 22, 99, 11, 24, 9, 66, 19, 82, 51, 35, 33, 36, 77, 33, 78, 100, 79, 68, 40, 80, 26, 22, 18, 55, 49, 59, 16, 77, 26, 84, 17, 7, 86, 73, 32, 52, 56, 5, 95, 72, 82, 4, 29, 1, 6, 55, 83, 22, 11, 8, 28, 47, 99, 51, 71, 89, 13, 15, 86, 74, 11, 10]
            let graph = CompressedSparseRow(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 9, 8, 11, 10, 7, 2, 4, 3, 5, 1, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [8, 107, 98, 131, 117, 79, 25, 47, 37, 56, 16, 66] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 172)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (7, 9), (7, 10), (7, 11), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 9), (8, 10), (8, 11), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (9, 11), (10, 0), (10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (10, 6), (10, 7), (10, 8), (10, 9), (10, 11), (11, 0), (11, 1), (11, 2), (11, 3), (11, 4), (11, 5), (11, 6), (11, 7), (11, 8), (11, 9), (11, 10)]
            let weights: [Int] = [79, 32, 54, 74, 46, 20, 65, 65, 40, 87, 96, 76, 33, 81, 50, 63, 6, 100, 97, 52, 37, 94, 55, 99, 54, 5, 41, 46, 94, 33, 53, 18, 51, 76, 74, 40, 10, 8, 73, 53, 46, 36, 89, 11, 81, 45, 5, 5, 47, 91, 73, 55, 58, 69, 75, 52, 9, 57, 7, 4, 60, 34, 64, 61, 56, 86, 1, 84, 53, 39, 22, 99, 11, 24, 9, 66, 19, 82, 51, 35, 33, 36, 77, 33, 78, 100, 79, 68, 40, 80, 26, 22, 18, 55, 49, 59, 16, 77, 26, 84, 17, 7, 86, 73, 32, 52, 56, 5, 95, 72, 82, 4, 29, 1, 6, 55, 83, 22, 11, 8, 28, 47, 99, 51, 71, 89, 13, 15, 86, 74, 11, 10]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.shortestTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 9, 8, 11, 10, 7, 2, 4, 3, 5, 1, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [8, 107, 98, 131, 117, 79, 25, 47, 37, 56, 16, 66] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 172)
            // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
            // self-loops ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
            }
            let walked = tour.edges.map { edgeOf[$0]! }
            let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % n]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
            // Each step through its pair's lightest edge.
            for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
            // It starts at the first vertex.
            #expect(at[0] == 0)
        }
    }
}
