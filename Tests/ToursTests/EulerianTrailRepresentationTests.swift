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

@Suite("eulerianTrail on every representation")
struct EulerianTrailRepresentationTests {
    @Test("TO-004 empty graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to004() {
        // V []; E []; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-008 one vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to008() throws {
        // V [0]; E []; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
    }

    @Test("TO-012 two isolated vertices (isolated vertices ignored), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to012() throws {
        // V [0, 1]; E []; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
    }

    @Test("TO-016 one self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to016() throws {
        // multigraph V [0]; E [0-0]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-020 two self-loops at one vertex, on ReferencePseudograph, no indices")
    func to020() throws {
        // multigraph V [0]; E [0-0, 0-0]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0, 0] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0, 0] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-024 self-loop beside an isolated vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to024() throws {
        // multigraph V [0, 1]; E [1-1]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
    }

    @Test("TO-028 self-loops at two vertices: two components with edges, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to028() {
        // multigraph V [0, 1]; E [0-0, 1-1]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-032 one edge: a trail, no circuit, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to032() throws {
        // V [0, 1]; E [0-1]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-036 two parallel edges: a circuit of length 2, on ReferencePseudograph, no indices")
    func to036() throws {
        // multigraph V [0, 1]; E [0-1, 0-1]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-040 three parallel edges: odd at both ends, on ReferencePseudograph, no indices")
    func to040() throws {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-044 path P(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to044() throws {
        // P(3); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-048 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to048() throws {
        // P(4); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-052 triangle C(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to052() throws {
        // C(3); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-056 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to056() throws {
        // C(5); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-060 triangle beside an isolated vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to060() throws {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-064 isolated first vertex: the circuit starts at the first vertex with an edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to064() throws {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
    }

    @Test("TO-068 two triangles apart, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to068() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-072 bowtie: two triangles at a shared vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to072() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3, 4, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-076 triangle with a loop: loops add 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to076() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 0] as [Int])
            #expect(trail.edges == [0, 2, 3, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 0] as [Int])
            #expect(trail.edges == [0, 2, 3, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 0] as [Int])
            #expect(trail.edges == [0, 2, 3, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-080 edge with a loop at the end: odd 0 and 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to080() throws {
        // multigraph V [0, 1]; E [0-1, 1-1]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-084 loop at a vertex, an edge elsewhere: two components, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to084() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-088 star(3): four odd vertices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to088() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-092 K(4): every degree 3, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to092() {
        // K(4); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-096 K(5): every degree 4, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to096() throws {
        // K(5); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 1, 4, 2, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 1, 4, 2, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-100 Königsberg: seven bridges, four odd land masses, on ReferencePseudograph, no indices")
    func to100() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-104 Königsberg less one A–B bridge: a trail, on ReferencePseudograph, no indices")
    func to104() throws {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == ["C", "A", "B", "D", "A", "C", "D"] as [String])
            #expect(trail.edges == [1, 0, 4, 3, 2, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 2)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == ["C", "A", "B", "D", "A", "C", "D"] as [String])
            #expect(trail.edges == [1, 0, 4, 3, 2, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 2)
        }
    }

    @Test("TO-108 house: odd at the base, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to108() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [2, 1, 0, 3, 2, 4, 3] as [Int])
            #expect(trail.edges == [1, 0, 3, 2, 4, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [2, 1, 0, 3, 2, 4, 3] as [Int])
            #expect(trail.edges == [1, 0, 3, 2, 4, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 2)
        }
    }

    @Test("TO-112 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to112() throws {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = Pseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == ["a", "c", "b", "a", "d", "c"] as [String])
            #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == ["a", "c", "b", "a", "d", "c"] as [String])
            #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == ["a", "c", "b", "a", "d", "c"] as [String])
            #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1), (0, 1), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1, 0, 2] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
    }

    @Test("TO-116 odd vertices last in the order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to116() throws {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 0, 3, 4, 0, 2, 1, 4] as [Int])
            #expect(trail.edges == [2, 1, 0, 5, 4, 3, 6] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 0, 3, 4, 0, 2, 1, 4] as [Int])
            #expect(trail.edges == [2, 1, 0, 5, 4, 3, 6] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 1)
        }
    }

    @Test("TO-120 grid(3,3): four odd corners' neighbours, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to120() {
        // grid(3,3); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-124 Petersen: every degree 3, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to124() {
        // nx(petersen_graph); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-128 octahedral: every degree 4, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to128() throws {
        // nx(octahedral_graph); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 1, 5, 2, 4, 3, 5, 4, 0] as [Int])
            #expect(trail.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 10, 11, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 1, 5, 2, 4, 3, 5, 4, 0] as [Int])
            #expect(trail.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 10, 11, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-132 wheel(4): rim odd, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to132() {
        // wheel(4); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-136 K(3,3) less nothing: degree 3, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to136() {
        // Kb(3,3); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-140 Kb(2,4): even sides, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to140() throws {
        // Kb(2,4); eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 1, 3, 0, 4, 1, 5, 0] as [Int])
            #expect(trail.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 1, 3, 0, 4, 1, 5, 0] as [Int])
            #expect(trail.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 1, 3, 0, 4, 1, 5, 0] as [Int])
            #expect(trail.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 1, 3, 0, 4, 1, 5, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-144 rows decide: the first edge out of 0 is the second chord, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to144() throws {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; eulerianTrail()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 3, 4, 0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 4, 5, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 3, 4, 0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 4, 5, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 3, 4, 0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 4, 5, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-148 parallel edges inside a longer circuit, on ReferencePseudograph, no indices")
    func to148() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 1, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 5, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 1, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 5, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-152 lcgwalk(6,14,1), on ReferencePseudograph, no indices")
    func to152() throws {
        // lcgwalk(6,14,1); eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-156 lcgwalk(8,30,2), on ReferencePseudograph, no indices")
    func to156() throws {
        // lcgwalk(8,30,2); eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-160 lcgwalk(5,20,3,open), on ReferencePseudograph, no indices")
    func to160() throws {
        // lcgwalk(5,20,3,open); eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 3, 0, 3, 4, 3, 0, 0, 4, 4, 3, 2, 1, 4, 3, 0, 4, 4, 2, 1] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 3, 0, 3, 4, 3, 0, 0, 4, 4, 3, 2, 1, 4, 3, 0, 4, 4, 2, 1] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-164 lcgwalk(10,40,4,open), on ReferencePseudograph, no indices")
    func to164() throws {
        // lcgwalk(10,40,4,open); eulerianTrail()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 6, 2, 4, 1, 5, 7, 1, 3, 4, 6, 5, 4, 6, 4, 1, 7, 4, 7, 8, 8, 8, 5, 0, 8, 7, 6, 6, 3, 7, 0, 9, 8, 9, 0, 0, 5, 3, 2, 8, 4] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 6, 2, 4, 1, 5, 7, 1, 3, 4, 6, 5, 4, 6, 4, 1, 7, 4, 7, 8, 8, 8, 5, 0, 8, 7, 6, 6, 3, 7, 0, 9, 8, 9, 0, 0, 5, 3, 2, 8, 4] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the first odd vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-168 empty digraph, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to168() {
        // V []; E []; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-172 one vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to172() throws {
        // V [0]; E []; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [] as [Int])
            // No edges: the trivial trail at the first vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [0])
        }
    }

    @Test("TO-176 one self-loop: in 1, out 1, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to176() throws {
        // multigraph V [0]; E [0→0]; eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-180 one edge 0→1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to180() throws {
        // V [0, 1]; E [0→1]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges == [0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
    }

    @Test("TO-184 antiparallel pair, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to184() throws {
        // V [0, 1]; E [0→1, 1→0]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0] as [Int])
            #expect(trail.edges == [0, 1] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-188 parallel pair 0→1 twice: unbalanced by 2, on ReferenceDirectedMultigraph, no indices")
    func to188() {
        // multigraph V [0, 1]; E [0→1, 0→1]; eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-192 directed cycle Cd(3), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to192() throws {
        // Cd(3); eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-196 directed path Pd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to196() throws {
        // Pd(4); eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
    }

    @Test("TO-200 two sources: no trail, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to200() {
        // V [0, 1, 2]; E [0→2, 1→2]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-204 balanced but two components, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to204() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-208 Cd(3) beside an isolated vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to208() throws {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-212 isolated first vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to212() throws {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [1, 2, 3, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 1)
        }
    }

    @Test("TO-216 start is the vertex with out − in = 1, not the first, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to216() throws {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [2, 0, 1, 2, 3, 1, 3] as [Int])
            #expect(trail.edges == [1, 2, 0, 3, 4, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [2, 0, 1, 2, 3, 1, 3] as [Int])
            #expect(trail.edges == [1, 2, 0, 3, 4, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [2, 0, 1, 2, 3, 1, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [1, 2, 0, 3, 4, 5] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [2, 0, 1, 2, 3, 1, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [1, 2, 0, 3, 4, 5] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 2)
        }
    }

    @Test("TO-220 two directed cycles at a shared vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to220() throws {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 4, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 4, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 3, 4, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-224 loop on a directed cycle, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to224() throws {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-228 Cd(3) with a chord: a trail from 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to228() throws {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 2] as [Int])
            #expect(trail.edges == [0, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 2] as [Int])
            #expect(trail.edges == [0, 1, 2, 3] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 2] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 2, 0, 2] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
    }

    @Test("TO-232 in − out = 2 at one vertex, on ReferenceDirectedMultigraph, no indices")
    func to232() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-236 Kd(3): every in = out = 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to236() throws {
        // Kd(3); eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 1, 2, 0] as [Int])
            #expect(trail.edges == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 1, 2, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-240 Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to240() throws {
        // Kd(4); eulerianTrail()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3, 0] as [Int])
            #expect(trail.edges == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3, 0] as [Int])
            #expect(trail.edges == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-244 self-loop and an edge elsewhere, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to244() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail() == nil)
        }
    }

    @Test("TO-248 lcgwalkd(6,14,1), on ReferenceDirectedMultigraph, no indices")
    func to248() throws {
        // lcgwalkd(6,14,1); eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-252 lcgwalkd(8,30,2), on ReferenceDirectedMultigraph, no indices")
    func to252() throws {
        // lcgwalkd(8,30,2); eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3, 0] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: Eulerian, so the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-256 lcgwalkd(5,20,3,open), on ReferenceDirectedMultigraph, no indices")
    func to256() throws {
        // lcgwalkd(5,20,3,open); eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 3, 0, 3, 4, 3, 0, 0, 4, 4, 3, 2, 1, 4, 3, 0, 4, 4, 2, 1] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 4, 3, 0, 3, 4, 3, 0, 0, 4, 4, 3, 2, 1, 4, 3, 0, 4, 4, 2, 1] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
    }

    @Test("TO-260 lcgwalkd(9,40,5,open), on ReferenceDirectedMultigraph, no indices")
    func to260() throws {
        // lcgwalkd(9,40,5,open); eulerianTrail()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 7, 8, 7, 1, 4, 5, 8, 7, 5, 6, 3, 6, 6, 2, 3, 5, 2, 3, 1, 3, 4, 1, 3, 3, 0, 5, 1, 0, 5, 4, 5, 4, 8, 3, 4, 2, 6, 6, 8, 5] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail())
            #expect(trail.vertices == [0, 7, 8, 7, 1, 4, 5, 8, 7, 5, 6, 3, 6, 6, 2, 3, 5, 2, 3, 1, 3, 4, 1, 3, 3, 0, 5, 1, 0, 5, 4, 5, 4, 8, 3, 4, 2, 6, 6, 8, 5] as [Int])
            #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the vertex with out − in = 1.
            #expect(at.first == 0)
        }
    }

    @Test("TO-272 P(4) from 0, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to272() throws {
        // P(4); eulerianTrail(from: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-273 P(4) from 3: the other odd end, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to273() throws {
        // P(4); eulerianTrail(from: 3)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 3))
            #expect(trail.vertices == [3, 2, 1, 0] as [Int])
            #expect(trail.edges == [2, 1, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 3))
            #expect(trail.vertices == [3, 2, 1, 0] as [Int])
            #expect(trail.edges == [2, 1, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 3))
            #expect(trail.vertices == [3, 2, 1, 0] as [Int])
            #expect(trail.edges == [2, 1, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 3))
            #expect(trail.vertices == [3, 2, 1, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [2, 1, 0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
    }

    @Test("TO-274 P(4) from an even vertex: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to274() {
        // P(4); eulerianTrail(from: 1)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 1) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 1) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 1) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 1) == nil)
        }
    }

    @Test("TO-275 Eulerian: a closed trail from any vertex with an edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to275() throws {
        // C(4); eulerianTrail(from: 2)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 2))
            #expect(trail.vertices == [2, 1, 0, 3, 2] as [Int])
            #expect(trail.edges == [1, 0, 3, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 2))
            #expect(trail.vertices == [2, 1, 0, 3, 2] as [Int])
            #expect(trail.edges == [1, 0, 3, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 2))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 2))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
    }

    @Test("TO-276 Eulerian, isolated start: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to276() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianTrail(from: 3)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
    }

    @Test("TO-277 edgeless: the trivial trail at the start, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to277() throws {
        // V [0, 1]; E []; eulerianTrail(from: 1)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the given vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [1])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the given vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [1])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1] as [Int])
            #expect(trail.edges == [] as [Int])
            // No edges: the trivial trail at the given vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [1])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [] as [Int])
            // No edges: the trivial trail at the given vertex.
            #expect(trail.edges.isEmpty && trail.vertices == [1])
        }
    }

    @Test("TO-278 no trail: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to278() {
        // K(4); eulerianTrail(from: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 0) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 0) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 0) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 0) == nil)
        }
    }

    @Test("TO-279 Königsberg less one bridge, from D, on ReferencePseudograph, no indices")
    func to279() throws {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; eulerianTrail(from: D)
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: "D"))
            #expect(trail.vertices == ["D", "A", "B", "D", "C", "A", "C"] as [String])
            #expect(trail.edges == [3, 0, 4, 5, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: "D"))
            #expect(trail.vertices == ["D", "A", "B", "D", "C", "A", "C"] as [String])
            #expect(trail.edges == [3, 0, 4, 5, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
    }

    @Test("TO-280 loop at the end vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to280() throws {
        // multigraph V [0, 1]; E [0-1, 1-1]; eulerianTrail(from: 1)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 1, 0] as [Int])
            #expect(trail.edges == [1, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 1, 0] as [Int])
            #expect(trail.edges == [1, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 1, 0] as [Int])
            #expect(trail.edges == [1, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 1, 0] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [1, 0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
    }

    @Test("TO-281 Pd(4) from 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to281() throws {
        // Pd(4); eulerianTrail(from: 0)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges == [0, 1, 2] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 0))
            #expect(trail.vertices == [0, 1, 2, 3] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-282 Pd(4) from the end: nil, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to282() {
        // Pd(4); eulerianTrail(from: 3)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 3) == nil)
        }
    }

    @Test("TO-283 Cd(3) from 1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to283() throws {
        // Cd(3); eulerianTrail(from: 1)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 2, 0, 1] as [Int])
            #expect(trail.edges == [1, 2, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 2, 0, 1] as [Int])
            #expect(trail.edges == [1, 2, 0] as [Int])
            let walked = trail.edges
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 2, 0, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [1, 2, 0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let trail = try #require(graph.eulerianTrail(from: 1))
            #expect(trail.vertices == [1, 2, 0, 1] as [Int])
            #expect(trail.edges.map { edgeOf[$0]! } == [1, 2, 0] as [Int])
            let walked = trail.edges.map { edgeOf[$0]! }
            let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count + 1)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
    }

    @Test("TO-284 chord: from 0 only, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to284() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; eulerianTrail(from: 2)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 2) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 2) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 2) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianTrail(from: 2) == nil)
        }
    }
}
