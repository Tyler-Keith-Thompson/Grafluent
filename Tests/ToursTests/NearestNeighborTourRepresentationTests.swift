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
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

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

@Suite("nearestNeighborTour on every representation")
struct NearestNeighborTourRepresentationTests {
    @Test("TO-400 square: the perimeter, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to400() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
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

    @Test("TO-401 square listed crosswise, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to401() throws {
        // pts[(0,0),(1,1),(0,1),(1,0)]; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
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

    @Test("TO-402 five points on a line, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to402() throws {
        // pts[(0,0),(3,0),(1,0),(4,0),(2,0)]; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3] as [Int])
            #expect(tour.edges == [1, 8, 6, 5, 2] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3] as [Int])
            #expect(tour.edges == [1, 8, 6, 5, 2] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3] as [Int])
            #expect(tour.edges == [1, 8, 6, 5, 2] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 4, 1, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 8, 6, 5, 2] as [Int])
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

    @Test("TO-403 all weights equal: K(5) weight 1, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to403() throws {
        // K(5) weight 1; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
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

    @Test("TO-404 K(4) with weights 1..6, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to404() throws {
        // K(4) weights 1, 2, 3, 4, 5, 6 in edge order; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
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

    @Test("TO-405 lcgpts(6,1,10), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to405() throws {
        // lcgpts(6,1,10); nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 5, 3, 1, 4] as [Int])
            #expect(tour.edges == [1, 11, 13, 6, 7, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 34)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 5, 3, 1, 4] as [Int])
            #expect(tour.edges == [1, 11, 13, 6, 7, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 34)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 5, 3, 1, 4] as [Int])
            #expect(tour.edges == [1, 11, 13, 6, 7, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 34)
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 5, 3, 1, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 11, 13, 6, 7, 3] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 34)
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

    @Test("TO-406 lcgpts(8,2,20), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to406() throws {
        // lcgpts(8,2,20); nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 5, 4, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges == [4, 22, 9, 12, 27, 16, 13, 2] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 5, 4, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges == [4, 22, 9, 12, 27, 16, 13, 2] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 5, 4, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges == [4, 22, 9, 12, 27, 16, 13, 2] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 5, 4, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [4, 22, 9, 12, 27, 16, 13, 2] as [Int])
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

    @Test("TO-407 lcgpts(9,3,30), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to407() throws {
        // lcgpts(9,3,30); nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 6, 3, 7, 2, 8, 5, 1] as [Int])
            #expect(tour.edges == [3, 27, 23, 24, 19, 20, 32, 11, 0] as [Int])
            #expect(tour.weight({ weights[$0] }) == 130)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 6, 3, 7, 2, 8, 5, 1] as [Int])
            #expect(tour.edges == [3, 27, 23, 24, 19, 20, 32, 11, 0] as [Int])
            #expect(tour.weight({ weights[$0] }) == 130)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 6, 3, 7, 2, 8, 5, 1] as [Int])
            #expect(tour.edges == [3, 27, 23, 24, 19, 20, 32, 11, 0] as [Int])
            #expect(tour.weight({ weights[$0] }) == 130)
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 6, 3, 7, 2, 8, 5, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 27, 23, 24, 19, 20, 32, 11, 0] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 130)
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

    @Test("TO-408 lcgK(7,4,9): not metric, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to408() throws {
        // lcgK(7,4,9); nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 3, 6, 4] as [Int])
            #expect(tour.edges == [1, 6, 9, 16, 17, 19, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 26)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 3, 6, 4] as [Int])
            #expect(tour.edges == [1, 6, 9, 16, 17, 19, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 26)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 3, 6, 4] as [Int])
            #expect(tour.edges == [1, 6, 9, 16, 17, 19, 3] as [Int])
            #expect(tour.weight({ weights[$0] }) == 26)
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 2, 1, 5, 3, 6, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [1, 6, 9, 16, 17, 19, 3] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 26)
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

    @Test("TO-409 lcgK(8,5,20): not metric, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to409() throws {
        // lcgK(8,5,20); nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 5, 3, 1, 2, 6] as [Int])
            #expect(tour.edges == [3, 24, 26, 19, 8, 7, 16, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 53)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 5, 3, 1, 2, 6] as [Int])
            #expect(tour.edges == [3, 24, 26, 19, 8, 7, 16, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 53)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 5, 3, 1, 2, 6] as [Int])
            #expect(tour.edges == [3, 24, 26, 19, 8, 7, 16, 5] as [Int])
            #expect(tour.weight({ weights[$0] }) == 53)
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 5, 3, 1, 2, 6] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 24, 26, 19, 8, 7, 16, 5] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 53)
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

    @Test("TO-410 lcgK(6,6,9,/4): Double weights, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to410() throws {
        // lcgK(6,6,9,/4); nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(tour.edges == [0, 5, 9, 12, 14, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6.5)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(tour.edges == [0, 5, 9, 12, 14, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6.5)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(tour.edges == [0, 5, 9, 12, 14, 4] as [Int])
            #expect(tour.weight({ weights[$0] }) == 6.5)
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [0, 5, 9, 12, 14, 4] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 6.5)
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

    @Test("TO-411 negative weights, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to411() throws {
        // K(4) weights -1, 2, -3, 4, 0, -2; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 2, 1] as [Int])
            #expect(tour.edges == [2, 5, 3, 0] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 2, 1] as [Int])
            #expect(tour.edges == [2, 5, 3, 0] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 2, 1] as [Int])
            #expect(tour.edges == [2, 5, 3, 0] as [Int])
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 3, 2, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [2, 5, 3, 0] as [Int])
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

    @Test("TO-412 parallel copies: the lightest, on ReferencePseudograph, no indices")
    func to412() throws {
        // multigraph V [0, 1, 2]; E [0-1 5, 0-1 2, 1-2 1, 2-0 3, 2-0 3]; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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

    @Test("TO-413 self-loops ignored, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to413() throws {
        // multigraph V [0, 1, 2]; E [0-0 -9, 0-1 1, 1-2 2, 1-1 -9, 2-0 3]; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
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

    @Test("TO-414 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to414() throws {
        // V [d, a, c, b]; E [d-a 1, d-c 4, d-b 2, a-c 2, a-b 5, c-b 1]; nearestNeighborTour(weight:)
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[$0] })
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
            let result = graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] })
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

    @Test("TO-415 one vertex: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to415() {
        // V [0]; E []; nearestNeighborTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-416 two vertices: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to416() {
        // V [0, 1]; E [0-1 3]; nearestNeighborTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-417 two vertices, parallel edges: nil (tours read the simple graph), on ReferencePseudograph, no indices")
    func to417() {
        // multigraph V [0, 1]; E [0-1 3, 0-1 4]; nearestNeighborTour(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let weights: [Int] = [3, 4]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
        }
    }

    @Test("TO-418 empty graph: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to418() {
        // V []; E []; nearestNeighborTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-419 square from 2, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to419() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; nearestNeighborTour(from: 2, weight:)
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
            let result = graph.nearestNeighborTour(from: 2, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [2, 1, 0, 3] as [Int])
            #expect(tour.edges == [3, 0, 2, 5] as [Int])
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
            // It starts at the given vertex.
            #expect(at[0] == 2)
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
            let result = graph.nearestNeighborTour(from: 2, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [2, 1, 0, 3] as [Int])
            #expect(tour.edges == [3, 0, 2, 5] as [Int])
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
            // It starts at the given vertex.
            #expect(at[0] == 2)
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
            let result = graph.nearestNeighborTour(from: 2, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [2, 1, 0, 3] as [Int])
            #expect(tour.edges == [3, 0, 2, 5] as [Int])
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
            // It starts at the given vertex.
            #expect(at[0] == 2)
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
            let result = graph.nearestNeighborTour(from: 2, weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [2, 1, 0, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 0, 2, 5] as [Int])
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
            // It starts at the given vertex.
            #expect(at[0] == 2)
        }
    }

    @Test("TO-420 lcgpts(8,2,20) from 5, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to420() throws {
        // lcgpts(8,2,20); nearestNeighborTour(from: 5, weight:)
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
            let result = graph.nearestNeighborTour(from: 5, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [5, 4, 0, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges == [22, 3, 0, 12, 27, 16, 13, 19] as [Int])
            #expect(tour.weight({ weights[$0] }) == 72)
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
            // It starts at the given vertex.
            #expect(at[0] == 5)
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
            let result = graph.nearestNeighborTour(from: 5, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [5, 4, 0, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges == [22, 3, 0, 12, 27, 16, 13, 19] as [Int])
            #expect(tour.weight({ weights[$0] }) == 72)
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
            // It starts at the given vertex.
            #expect(at[0] == 5)
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
            let result = graph.nearestNeighborTour(from: 5, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [5, 4, 0, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges == [22, 3, 0, 12, 27, 16, 13, 19] as [Int])
            #expect(tour.weight({ weights[$0] }) == 72)
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
            // It starts at the given vertex.
            #expect(at[0] == 5)
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
            let result = graph.nearestNeighborTour(from: 5, weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [5, 4, 0, 1, 7, 6, 2, 3] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [22, 3, 0, 12, 27, 16, 13, 19] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 72)
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
            // It starts at the given vertex.
            #expect(at[0] == 5)
        }
    }

    @Test("TO-421 lcgK(7,4,9) from 3, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to421() throws {
        // lcgK(7,4,9); nearestNeighborTour(from: 3, weight:)
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
            let result = graph.nearestNeighborTour(from: 3, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 5, 1, 0, 2, 6, 4] as [Int])
            #expect(tour.edges == [16, 9, 0, 1, 14, 19, 15] as [Int])
            #expect(tour.weight({ weights[$0] }) == 24)
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
            // It starts at the given vertex.
            #expect(at[0] == 3)
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
            let result = graph.nearestNeighborTour(from: 3, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 5, 1, 0, 2, 6, 4] as [Int])
            #expect(tour.edges == [16, 9, 0, 1, 14, 19, 15] as [Int])
            #expect(tour.weight({ weights[$0] }) == 24)
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
            // It starts at the given vertex.
            #expect(at[0] == 3)
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
            let result = graph.nearestNeighborTour(from: 3, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 5, 1, 0, 2, 6, 4] as [Int])
            #expect(tour.edges == [16, 9, 0, 1, 14, 19, 15] as [Int])
            #expect(tour.weight({ weights[$0] }) == 24)
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
            // It starts at the given vertex.
            #expect(at[0] == 3)
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
            let result = graph.nearestNeighborTour(from: 3, weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 5, 1, 0, 2, 6, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [16, 9, 0, 1, 14, 19, 15] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 24)
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
            // It starts at the given vertex.
            #expect(at[0] == 3)
        }
    }
}
