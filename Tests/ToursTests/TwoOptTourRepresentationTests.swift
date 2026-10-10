// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirected` (each edge an arc as written; a vertex's row
// its out-edges, then its in-edges) and `AdjacencyMatrix.undirected` (rows by neighbour).
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

@Suite("twoOptTour on every representation")
struct TwoOptTourRepresentationTests {
    @Test("TO-443 square: the perimeter, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to443() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-444 square listed crosswise, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to444() throws {
        // pts[(0,0),(1,1),(0,1),(1,0)]; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [2, 1, 1, 1, 1, 2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [2, 1, 1, 1, 1, 2]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-445 five points on a line, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to445() throws {
        // pts[(0,0),(3,0),(1,0),(4,0),(2,0)]; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-446 all weights equal: K(5) weight 1, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to446() throws {
        // K(5) weight 1; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-447 K(4) with weights 1..6, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to447() throws {
        // K(4) weights 1, 2, 3, 4, 5, 6 in edge order; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 3, 4, 5, 6]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-448 lcgpts(6,1,10), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to448() throws {
        // lcgpts(6,1,10); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-449 lcgpts(8,2,20), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to449() throws {
        // lcgpts(8,2,20); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-450 lcgpts(9,3,30), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to450() throws {
        // lcgpts(9,3,30); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 3, 6, 5, 8, 1, 2] as [Int])
            #expect(tour.edges == [3, 28, 24, 23, 30, 32, 14, 8, 1] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 3, 6, 5, 8, 1, 2] as [Int])
            #expect(tour.edges == [3, 28, 24, 23, 30, 32, 14, 8, 1] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 3, 6, 5, 8, 1, 2] as [Int])
            #expect(tour.edges == [3, 28, 24, 23, 30, 32, 14, 8, 1] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 4, 7, 3, 6, 5, 8, 1, 2] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [3, 28, 24, 23, 30, 32, 14, 8, 1] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-451 lcgK(7,4,9): not metric, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to451() throws {
        // lcgK(7,4,9); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-452 lcgK(8,5,20): not metric, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to452() throws {
        // lcgK(8,5,20); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-453 lcgK(6,6,9,/4): Double weights, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to453() throws {
        // lcgK(6,6,9,/4); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Double = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Double = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Double = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Double = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-454 negative weights, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to454() throws {
        // K(4) weights -1, 2, -3, 4, 0, -2; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [-1, 2, -3, 4, 0, -2]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [-1, 2, -3, 4, 0, -2]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-455 parallel copies: the lightest, on ReferencePseudograph, no indices")
    func to455() throws {
        // multigraph V [0, 1, 2]; E [0-1 5, 0-1 2, 1-2 1, 2-0 3, 2-0 3]; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
    }

    @Test("TO-456 self-loops ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to456() throws {
        // multigraph V [0, 1, 2]; E [0-0 -9, 0-1 1, 1-2 2, 1-1 -9, 2-0 3]; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
            let weights: [Int] = [-9, 1, 2, -9, 3]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-457 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to457() throws {
        // V [d, a, c, b]; E [d-a 1, d-c 4, d-b 2, a-c 2, a-b 5, c-b 1]; twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("d", "c"), ("d", "b"), ("a", "c"), ("a", "b"), ("c", "b")]
            let weights: [Int] = [1, 4, 2, 2, 5, 1]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 4, 2, 2, 5, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-458 one vertex: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to458() {
        // V [0]; E []; twoOptTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-459 two vertices: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to459() {
        // V [0, 1]; E [0-1 3]; twoOptTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let weights: [Int] = [3]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-460 two vertices, parallel edges: nil (tours read the simple graph), on ReferencePseudograph, no indices")
    func to460() {
        // multigraph V [0, 1]; E [0-1 3, 0-1 4]; twoOptTour(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let weights: [Int] = [3, 4]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
    }

    @Test("TO-461 empty graph: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to461() {
        // V []; E []; twoOptTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
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
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[$0] }) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let weights: [Int] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.twoOptTour(weight: { weights[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("TO-462 lcgpts(12,7,50), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to462() throws {
        // lcgpts(12,7,50); twoOptTour(weight:)
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
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 5, 2, 7, 9, 3, 1, 11, 8, 10, 4] as [Int])
            #expect(tour.edges == [5, 45, 23, 25, 57, 35, 12, 20, 62, 61, 43, 3] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
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
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 5, 2, 7, 9, 3, 1, 11, 8, 10, 4] as [Int])
            #expect(tour.edges == [5, 45, 23, 25, 57, 35, 12, 20, 62, 61, 43, 3] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
            let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 5, 2, 7, 9, 3, 1, 11, 8, 10, 4] as [Int])
            #expect(tour.edges == [5, 45, 23, 25, 57, 35, 12, 20, 62, 61, 43, 3] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
            let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 6, 5, 2, 7, 9, 3, 1, 11, 8, 10, 4] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [5, 45, 23, 25, 57, 35, 12, 20, 62, 61, 43, 3] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-463 lcgpts(20,9,100), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to463() throws {
        // lcgpts(20,9,100); twoOptTour(weight:)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12), (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15), (2, 16), (2, 17), (2, 18), (2, 19), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13), (3, 14), (3, 15), (3, 16), (3, 17), (3, 18), (3, 19), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (4, 16), (4, 17), (4, 18), (4, 19), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15), (5, 16), (5, 17), (5, 18), (5, 19), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16), (6, 17), (6, 18), (6, 19), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 15), (7, 16), (7, 17), (7, 18), (7, 19), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (8, 15), (8, 16), (8, 17), (8, 18), (8, 19), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 17), (10, 18), (10, 19), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 18), (11, 19), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (14, 15), (14, 16), (14, 17), (14, 18), (14, 19), (15, 16), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19), (18, 19)]
            let weights: [Int] = [10, 62, 81, 64, 54, 40, 63, 73, 63, 40, 69, 8, 51, 50, 82, 81, 38, 61, 58, 70, 91, 72, 62, 50, 73, 65, 53, 32, 61, 14, 53, 58, 92, 89, 28, 71, 66, 47, 50, 32, 24, 105, 135, 97, 102, 131, 70, 113, 12, 84, 19, 72, 63, 14, 97, 79, 41, 72, 102, 144, 69, 98, 77, 80, 39, 51, 64, 119, 30, 61, 18, 56, 107, 137, 73, 104, 133, 72, 115, 58, 98, 33, 68, 77, 36, 38, 97, 127, 65, 94, 123, 62, 105, 40, 80, 27, 58, 59, 18, 81, 111, 103, 78, 107, 46, 89, 12, 60, 43, 78, 39, 20, 52, 126, 45, 26, 59, 20, 93, 21, 124, 101, 42, 101, 74, 33, 26, 65, 32, 123, 71, 154, 69, 72, 131, 81, 100, 67, 106, 105, 145, 90, 25, 124, 83, 29, 32, 25, 90, 64, 121, 56, 43, 98, 61, 18, 119, 47, 150, 75, 68, 127, 43, 58, 78, 89, 42, 57, 66, 101, 39, 132, 81, 50, 109, 72, 31, 80, 51, 22, 103, 120, 21, 80, 85, 82, 23, 99, 62, 59]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 12, 10, 8, 11, 13, 7, 15, 18, 3, 14, 6, 19, 2, 16, 4, 5, 9, 17, 1] as [Int])
            #expect(tour.edges == [11, 146, 125, 126, 155, 117, 119, 182, 68, 64, 106, 111, 53, 50, 81, 70, 88, 142, 34, 0] as [Int])
            #expect(tour.weight({ weights[$0] }) == 492)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12), (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15), (2, 16), (2, 17), (2, 18), (2, 19), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13), (3, 14), (3, 15), (3, 16), (3, 17), (3, 18), (3, 19), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (4, 16), (4, 17), (4, 18), (4, 19), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15), (5, 16), (5, 17), (5, 18), (5, 19), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16), (6, 17), (6, 18), (6, 19), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 15), (7, 16), (7, 17), (7, 18), (7, 19), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (8, 15), (8, 16), (8, 17), (8, 18), (8, 19), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 17), (10, 18), (10, 19), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 18), (11, 19), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (14, 15), (14, 16), (14, 17), (14, 18), (14, 19), (15, 16), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19), (18, 19)]
            let weights: [Int] = [10, 62, 81, 64, 54, 40, 63, 73, 63, 40, 69, 8, 51, 50, 82, 81, 38, 61, 58, 70, 91, 72, 62, 50, 73, 65, 53, 32, 61, 14, 53, 58, 92, 89, 28, 71, 66, 47, 50, 32, 24, 105, 135, 97, 102, 131, 70, 113, 12, 84, 19, 72, 63, 14, 97, 79, 41, 72, 102, 144, 69, 98, 77, 80, 39, 51, 64, 119, 30, 61, 18, 56, 107, 137, 73, 104, 133, 72, 115, 58, 98, 33, 68, 77, 36, 38, 97, 127, 65, 94, 123, 62, 105, 40, 80, 27, 58, 59, 18, 81, 111, 103, 78, 107, 46, 89, 12, 60, 43, 78, 39, 20, 52, 126, 45, 26, 59, 20, 93, 21, 124, 101, 42, 101, 74, 33, 26, 65, 32, 123, 71, 154, 69, 72, 131, 81, 100, 67, 106, 105, 145, 90, 25, 124, 83, 29, 32, 25, 90, 64, 121, 56, 43, 98, 61, 18, 119, 47, 150, 75, 68, 127, 43, 58, 78, 89, 42, 57, 66, 101, 39, 132, 81, 50, 109, 72, 31, 80, 51, 22, 103, 120, 21, 80, 85, 82, 23, 99, 62, 59]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 12, 10, 8, 11, 13, 7, 15, 18, 3, 14, 6, 19, 2, 16, 4, 5, 9, 17, 1] as [Int])
            #expect(tour.edges == [11, 146, 125, 126, 155, 117, 119, 182, 68, 64, 106, 111, 53, 50, 81, 70, 88, 142, 34, 0] as [Int])
            #expect(tour.weight({ weights[$0] }) == 492)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12), (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15), (2, 16), (2, 17), (2, 18), (2, 19), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13), (3, 14), (3, 15), (3, 16), (3, 17), (3, 18), (3, 19), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (4, 16), (4, 17), (4, 18), (4, 19), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15), (5, 16), (5, 17), (5, 18), (5, 19), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16), (6, 17), (6, 18), (6, 19), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 15), (7, 16), (7, 17), (7, 18), (7, 19), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (8, 15), (8, 16), (8, 17), (8, 18), (8, 19), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 17), (10, 18), (10, 19), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 18), (11, 19), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (14, 15), (14, 16), (14, 17), (14, 18), (14, 19), (15, 16), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19), (18, 19)]
            let weights: [Int] = [10, 62, 81, 64, 54, 40, 63, 73, 63, 40, 69, 8, 51, 50, 82, 81, 38, 61, 58, 70, 91, 72, 62, 50, 73, 65, 53, 32, 61, 14, 53, 58, 92, 89, 28, 71, 66, 47, 50, 32, 24, 105, 135, 97, 102, 131, 70, 113, 12, 84, 19, 72, 63, 14, 97, 79, 41, 72, 102, 144, 69, 98, 77, 80, 39, 51, 64, 119, 30, 61, 18, 56, 107, 137, 73, 104, 133, 72, 115, 58, 98, 33, 68, 77, 36, 38, 97, 127, 65, 94, 123, 62, 105, 40, 80, 27, 58, 59, 18, 81, 111, 103, 78, 107, 46, 89, 12, 60, 43, 78, 39, 20, 52, 126, 45, 26, 59, 20, 93, 21, 124, 101, 42, 101, 74, 33, 26, 65, 32, 123, 71, 154, 69, 72, 131, 81, 100, 67, 106, 105, 145, 90, 25, 124, 83, 29, 32, 25, 90, 64, 121, 56, 43, 98, 61, 18, 119, 47, 150, 75, 68, 127, 43, 58, 78, 89, 42, 57, 66, 101, 39, 132, 81, 50, 109, 72, 31, 80, 51, 22, 103, 120, 21, 80, 85, 82, 23, 99, 62, 59]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let result = graph.twoOptTour(weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 12, 10, 8, 11, 13, 7, 15, 18, 3, 14, 6, 19, 2, 16, 4, 5, 9, 17, 1] as [Int])
            #expect(tour.edges == [11, 146, 125, 126, 155, 117, 119, 182, 68, 64, 106, 111, 53, 50, 81, 70, 88, 142, 34, 0] as [Int])
            #expect(tour.weight({ weights[$0] }) == 492)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[$0] }))
            #expect(weight <= first.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12), (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15), (2, 16), (2, 17), (2, 18), (2, 19), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13), (3, 14), (3, 15), (3, 16), (3, 17), (3, 18), (3, 19), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (4, 16), (4, 17), (4, 18), (4, 19), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15), (5, 16), (5, 17), (5, 18), (5, 19), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16), (6, 17), (6, 18), (6, 19), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 15), (7, 16), (7, 17), (7, 18), (7, 19), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (8, 15), (8, 16), (8, 17), (8, 18), (8, 19), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 17), (10, 18), (10, 19), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 18), (11, 19), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (14, 15), (14, 16), (14, 17), (14, 18), (14, 19), (15, 16), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19), (18, 19)]
            let weights: [Int] = [10, 62, 81, 64, 54, 40, 63, 73, 63, 40, 69, 8, 51, 50, 82, 81, 38, 61, 58, 70, 91, 72, 62, 50, 73, 65, 53, 32, 61, 14, 53, 58, 92, 89, 28, 71, 66, 47, 50, 32, 24, 105, 135, 97, 102, 131, 70, 113, 12, 84, 19, 72, 63, 14, 97, 79, 41, 72, 102, 144, 69, 98, 77, 80, 39, 51, 64, 119, 30, 61, 18, 56, 107, 137, 73, 104, 133, 72, 115, 58, 98, 33, 68, 77, 36, 38, 97, 127, 65, 94, 123, 62, 105, 40, 80, 27, 58, 59, 18, 81, 111, 103, 78, 107, 46, 89, 12, 60, 43, 78, 39, 20, 52, 126, 45, 26, 59, 20, 93, 21, 124, 101, 42, 101, 74, 33, 26, 65, 32, 123, 71, 154, 69, 72, 131, 81, 100, 67, 106, 105, 145, 90, 25, 124, 83, 29, 32, 25, 90, 64, 121, 56, 43, 98, 61, 18, 119, 47, 150, 75, 68, 127, 43, 58, 78, 89, 42, 57, 66, 101, 39, 132, 81, 50, 109, 72, 31, 80, 51, 22, 103, 120, 21, 80, 85, 82, 23, 99, 62, 59]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let result = graph.twoOptTour(weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [0, 12, 10, 8, 11, 13, 7, 15, 18, 3, 14, 6, 19, 2, 16, 4, 5, 9, 17, 1] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [11, 146, 125, 126, 155, 117, 119, 182, 68, 64, 106, 111, 53, 50, 81, 70, 88, 142, 34, 0] as [Int])
            #expect(tour.weight({ weights[edgeOf[$0]!] }) == 492)
            // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
            // ignored. `d` is its weight.
            var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if let e = lightest[a][b], weights[e] <= weights[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the nearest-neighbour tour it starts from.
            let first = try #require(graph.nearestNeighborTour(weight: { weights[edgeOf[$0]!] }))
            #expect(weight <= first.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-464 crossed square, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to464() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; twoOptTour(improving: [0, 2, 1, 3], weight:)
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
            let start = try #require(Cycle([0, 2, 1, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
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
            let start = try #require(Cycle([0, 2, 1, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let start = try #require(Cycle([0, 2, 1, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let start = try #require(Cycle([0, 2, 1, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-465 already 2-optimal: unchanged, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to465() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; twoOptTour(improving: [0, 1, 2, 3], weight:)
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
            let start = try #require(Cycle([0, 1, 2, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
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
            let start = try #require(Cycle([0, 1, 2, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let start = try #require(Cycle([0, 1, 2, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let start = try #require(Cycle([0, 1, 2, 3] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-466 reversed start: the first vertex stays, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to466() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; twoOptTour(improving: [3, 2, 1, 0], weight:)
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
            let start = try #require(Cycle([3, 2, 1, 0] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 2, 1, 0] as [Int])
            #expect(tour.edges == [5, 3, 0, 2] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 3)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
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
            let start = try #require(Cycle([3, 2, 1, 0] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 2, 1, 0] as [Int])
            #expect(tour.edges == [5, 3, 0, 2] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 3)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let start = try #require(Cycle([3, 2, 1, 0] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 2, 1, 0] as [Int])
            #expect(tour.edges == [5, 3, 0, 2] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 3)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let weights: [Int] = [1, 2, 1, 1, 2, 1]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let start = try #require(Cycle([3, 2, 1, 0] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[edgeOf[$0]!] })
            let tour = try #require(result)
            #expect(tour.vertices == [3, 2, 1, 0] as [Int])
            #expect(tour.edges.map { edgeOf[$0]! } == [5, 3, 0, 2] as [Int])
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 3)
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-467 lcgpts(9,3,30) from index order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to467() throws {
        // lcgpts(9,3,30); twoOptTour(improving: [0, 1, 2, 3, 4, 5, 6, 7, 8], weight:)
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
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
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
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
            let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[edgeOf[$0]!] }))
        }
    }

    @Test("TO-468 lcgK(8,5,20) from index order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to468() throws {
        // lcgK(8,5,20); twoOptTour(improving: [0, 1, 2, 3, 4, 5, 6, 7], weight:)
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
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
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
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[$0] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[$0] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[$0] }))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
            let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let start = try #require(Cycle([0, 1, 2, 3, 4, 5, 6, 7] as [Int], in: graph))
            let result = graph.twoOptTour(improving: start, weight: { weights[edgeOf[$0]!] })
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
            let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
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
            // It starts at the first vertex of the tour it improves.
            #expect(at[0] == 0)
            let weight = tour.weight({ weights[edgeOf[$0]!] })
            // 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.
            for i in 0 ..< n {
                for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {
                    let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]
                    #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), "move \(i), \(j)")
                }
            }
            // No heavier than the tour it improves.
            #expect(weight <= start.weight({ weights[edgeOf[$0]!] }))
        }
    }
}
