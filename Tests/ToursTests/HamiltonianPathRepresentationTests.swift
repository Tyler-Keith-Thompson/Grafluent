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

@Suite("hamiltonianPath on every representation")
struct HamiltonianPathRepresentationTests {
    @Test("TO-290 empty graph, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to290() {
        // V []; E []; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-292 one vertex, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to292() throws {
        // V [0]; E []; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-294 one vertex with a self-loop: a cycle of length 1, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to294() throws {
        // multigraph V [0]; E [0-0]; hamiltonianPath()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-296 two vertices, one edge: a path, no cycle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to296() throws {
        // V [0, 1]; E [0-1]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-298 two parallel edges: a cycle of length 2, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to298() throws {
        // multigraph V [0, 1]; E [0-1, 1-0]; hamiltonianPath()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-300 two isolated vertices, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to300() {
        // V [0, 1]; E []; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-302 self-loops never help, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to302() throws {
        // multigraph V [0, 1, 2]; E [0-0, 0-1, 1-1, 1-2, 2-2]; hamiltonianPath()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [1, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [1, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [1, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [1, 3] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-304 triangle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to304() throws {
        // C(3); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-306 path P(5), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to306() throws {
        // P(5); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 1, 2, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 1, 2, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 1, 2, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-308 cycle C(6), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to308() throws {
        // C(6); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-310 star(3): no path, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to310() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-312 K(4), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to312() throws {
        // K(4); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 3, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 3, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 3, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 3, 5] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-314 K(5), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to314() throws {
        // K(5); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 4, 7, 9] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 4, 7, 9] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 4, 7, 9] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 4, 7, 9] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-316 Kb(2,3): a path, no cycle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to316() throws {
        // Kb(2,3); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [2, 0, 3, 1, 4] as [Int])
            #expect(path.edges == [0, 1, 4, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [2, 0, 3, 1, 4] as [Int])
            #expect(path.edges == [0, 1, 4, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 2)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [2, 0, 3, 1, 4] as [Int])
            #expect(path.edges == [0, 1, 4, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 2)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [2, 0, 3, 1, 4] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 4, 5] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 2)
        }
    }

    @Test("TO-318 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to318() throws {
        // Kb(3,3); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 1, 4, 2, 5] as [Int])
            #expect(path.edges == [0, 3, 4, 7, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 1, 4, 2, 5] as [Int])
            #expect(path.edges == [0, 3, 4, 7, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 1, 4, 2, 5] as [Int])
            #expect(path.edges == [0, 3, 4, 7, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 1, 4, 2, 5] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 3, 4, 7, 8] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-320 Kb(2,4): no path, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to320() {
        // Kb(2,4); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-322 triangle with a pendant: a path, no cycle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to322() throws {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0, 2-3]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 3] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-324 two triangles apart: none, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to324() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-326 bowtie: a path, no cycle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to326() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 1, 3, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 1, 3, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges == [0, 1, 3, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 3, 4] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-328 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to328() throws {
        // V [d, a, c, b]; E [a-c, c-b, b-d, d-a, a-b]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "d"), ("d", "a"), ("a", "b")]
            let graph = Pseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == ["d", "b", "c", "a"] as [String])
            #expect(path.edges == [2, 1, 0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "d"), ("d", "a"), ("a", "b")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == ["d", "b", "c", "a"] as [String])
            #expect(path.edges == [2, 1, 0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "d"), ("d", "a"), ("a", "b")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 0), (0, 1), (1, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-330 parallel copies: the first in the row, on ReferencePseudograph, no indices")
    func to330() throws {
        // multigraph V [0, 1, 2]; E [0-2, 0-1, 0-1, 1-2, 2-0]; hamiltonianPath()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (0, 1), (1, 2), (2, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 1] as [Int])
            #expect(path.edges == [0, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 1] as [Int])
            #expect(path.edges == [0, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-332 rows decide: the first edge of 0 leads to the dead end, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to332() throws {
        // V [0, 1, 2, 3]; E [0-3, 0-1, 1-2, 2-3]; hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 2, 1] as [Int])
            #expect(path.edges == [0, 3, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 2, 1] as [Int])
            #expect(path.edges == [0, 3, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 3, 2, 1] as [Int])
            #expect(path.edges == [0, 3, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-334 wheel(5), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to334() throws {
        // wheel(5); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges == [0, 5, 6, 7, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges == [0, 5, 6, 7, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges == [0, 5, 6, 7, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 5, 6, 7, 8] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-336 grid(3,3): a path, no cycle (odd bipartite), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to336() throws {
        // grid(3,3); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
            #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
            #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
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
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-338 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to338() throws {
        // grid(3,4); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11] as [Int])
            #expect(path.edges == [0, 2, 4, 6, 11, 9, 7, 8, 14, 15, 16] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11] as [Int])
            #expect(path.edges == [0, 2, 4, 6, 11, 9, 7, 8, 14, 15, 16] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
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
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-340 Petersen: a path, no cycle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to340() throws {
        // nx(petersen_graph); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] as [Int])
            #expect(path.edges == [0, 3, 5, 7, 9, 13, 12, 11, 10] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] as [Int])
            #expect(path.edges == [0, 3, 5, 7, 9, 13, 12, 11, 10] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] as [Int])
            #expect(path.edges == [0, 3, 5, 7, 9, 13, 12, 11, 10] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 3, 5, 7, 9, 13, 12, 11, 10] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-342 dodecahedral, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to342() throws {
        // nx(dodecahedral_graph); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(path.edges == [0, 3, 5, 7, 9, 11, 13, 14, 16, 17, 19, 20, 22, 24, 25, 26, 27, 28, 29] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(path.edges == [0, 3, 5, 7, 9, 11, 13, 14, 16, 17, 19, 20, 22, 24, 25, 26, 27, 28, 29] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(path.edges == [0, 3, 5, 7, 9, 11, 13, 14, 16, 17, 19, 20, 22, 24, 25, 26, 27, 28, 29] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 3, 5, 7, 9, 11, 13, 14, 16, 17, 19, 20, 22, 24, 25, 26, 27, 28, 29] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-344 knight(3,4): open tour, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to344() throws {
        // knight(3,4); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (5, 11), (6, 8), (7, 9)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 6, 8, 1, 7, 9, 2, 11, 5, 3, 10, 4] as [Int])
            #expect(path.edges == [0, 12, 4, 2, 13, 6, 5, 11, 9, 8, 10] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (5, 11), (6, 8), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 6, 8, 1, 7, 9, 2, 11, 5, 3, 10, 4] as [Int])
            #expect(path.edges == [0, 12, 4, 2, 13, 6, 5, 11, 9, 8, 10] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (5, 11), (6, 8), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 6, 8, 1, 7, 9, 2, 11, 5, 3, 10, 4] as [Int])
            #expect(path.edges == [0, 12, 4, 2, 13, 6, 5, 11, 9, 8, 10] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (5, 11), (6, 8), (7, 9)]
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
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-346 knight(4,4): no tour at all, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to346() {
        // knight(4,4); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (4, 13), (5, 11), (5, 14), (5, 12), (6, 15), (6, 13), (6, 8), (7, 14), (7, 9), (8, 14), (9, 15), (10, 12), (11, 13)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (4, 13), (5, 11), (5, 14), (5, 12), (6, 15), (6, 13), (6, 8), (7, 14), (7, 9), (8, 14), (9, 15), (10, 12), (11, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (4, 13), (5, 11), (5, 14), (5, 12), (6, 15), (6, 13), (6, 8), (7, 14), (7, 9), (8, 14), (9, 15), (10, 12), (11, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (4, 13), (5, 11), (5, 14), (5, 12), (6, 15), (6, 13), (6, 8), (7, 14), (7, 9), (8, 14), (9, 15), (10, 12), (11, 13)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-348 lcg(10,20,1), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to348() throws {
        // lcg(10,20,1); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4), (6, 4), (1, 0), (7, 0), (1, 5), (3, 6)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 5, 1, 4, 3, 6, 9, 8, 7] as [Int])
            #expect(path.edges == [3, 8, 18, 14, 0, 19, 4, 9, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4), (6, 4), (1, 0), (7, 0), (1, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 5, 1, 4, 3, 6, 9, 8, 7] as [Int])
            #expect(path.edges == [3, 8, 18, 14, 0, 19, 4, 9, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4), (6, 4), (1, 0), (7, 0), (1, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 5, 1, 4, 3, 6, 9, 8, 7] as [Int])
            #expect(path.edges == [3, 8, 18, 14, 0, 19, 4, 9, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4), (6, 4), (1, 0), (7, 0), (1, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 5, 1, 4, 3, 6, 9, 8, 7] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [3, 8, 18, 14, 0, 19, 4, 9, 11] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-350 lcg(12,30,2), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to350() throws {
        // lcg(12,30,2); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(4, 6), (0, 8), (0, 6), (9, 2), (11, 2), (6, 5), (2, 7), (8, 2), (1, 6), (11, 6), (11, 7), (9, 10), (3, 1), (5, 4), (0, 4), (3, 8), (4, 8), (8, 11), (10, 2), (7, 1), (6, 8), (8, 9), (6, 3), (2, 5), (1, 8), (6, 9), (2, 6), (6, 10), (5, 9), (7, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 8, 2, 11, 7, 1, 3, 6, 4, 5, 9, 10] as [Int])
            #expect(path.edges == [1, 7, 4, 10, 19, 12, 22, 0, 13, 28, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(4, 6), (0, 8), (0, 6), (9, 2), (11, 2), (6, 5), (2, 7), (8, 2), (1, 6), (11, 6), (11, 7), (9, 10), (3, 1), (5, 4), (0, 4), (3, 8), (4, 8), (8, 11), (10, 2), (7, 1), (6, 8), (8, 9), (6, 3), (2, 5), (1, 8), (6, 9), (2, 6), (6, 10), (5, 9), (7, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 8, 2, 11, 7, 1, 3, 6, 4, 5, 9, 10] as [Int])
            #expect(path.edges == [1, 7, 4, 10, 19, 12, 22, 0, 13, 28, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(4, 6), (0, 8), (0, 6), (9, 2), (11, 2), (6, 5), (2, 7), (8, 2), (1, 6), (11, 6), (11, 7), (9, 10), (3, 1), (5, 4), (0, 4), (3, 8), (4, 8), (8, 11), (10, 2), (7, 1), (6, 8), (8, 9), (6, 3), (2, 5), (1, 8), (6, 9), (2, 6), (6, 10), (5, 9), (7, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(4, 6), (0, 8), (0, 6), (9, 2), (11, 2), (6, 5), (2, 7), (8, 2), (1, 6), (11, 6), (11, 7), (9, 10), (3, 1), (5, 4), (0, 4), (3, 8), (4, 8), (8, 11), (10, 2), (7, 1), (6, 8), (8, 9), (6, 3), (2, 5), (1, 8), (6, 9), (2, 6), (6, 10), (5, 9), (7, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-352 lcg(14,22,3): sparse, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to352() {
        // lcg(14,22,3); hamiltonianPath()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11), (5, 10)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11), (5, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11), (5, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11), (5, 10)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-354 empty digraph, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to354() {
        // V []; E []; hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
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
            #expect(graph.hamiltonianPath() == nil)
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
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-356 one vertex with a self-loop, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to356() throws {
        // multigraph V [0]; E [0→0]; hamiltonianPath()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-358 one edge 0→1: a path, no cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to358() throws {
        // V [0, 1]; E [0→1]; hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-360 antiparallel pair: a cycle of length 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to360() throws {
        // V [0, 1]; E [0→1, 1→0]; hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-362 edge 1→0 only: the path starts at 1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to362() throws {
        // V [0, 1]; E [1→0]; hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [1, 0] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [1, 0] as [Int])
            #expect(path.edges == [0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [1, 0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [1, 0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 1)
        }
    }

    @Test("TO-364 directed cycle Cd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to364() throws {
        // Cd(4); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-366 directed path Pd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to366() throws {
        // Pd(4); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-368 two sinks: no path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to368() {
        // V [0, 1, 2]; E [0→1, 0→2]; hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath() == nil)
        }
    }

    @Test("TO-370 Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to370() throws {
        // Kd(4); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 4, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 4, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 4, 8] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 4, 8] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-372 transitive tournament: one path, no cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to372() throws {
        // V [0, 1, 2, 3]; E [0→1, 0→2, 0→3, 1→2, 1→3, 2→3]; hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 3, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 3, 5] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 3, 5] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 3, 5] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-374 tournament(6,1), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to374() throws {
        // tournament(6,1); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 3, 4, 2, 5] as [Int])
            #expect(path.edges == [0, 6, 12, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 3, 4, 2, 5] as [Int])
            #expect(path.edges == [0, 6, 12, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 3, 4, 2, 5] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 6, 12, 10, 11] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 3, 4, 2, 5] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 6, 12, 10, 11] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-376 tournament(8,2), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to376() throws {
        // tournament(8,2); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 0), (6, 0), (0, 7), (1, 2), (3, 1), (1, 4), (5, 1), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (7, 2), (3, 4), (5, 3), (3, 6), (3, 7), (4, 5), (4, 6), (7, 4), (5, 6), (7, 5), (6, 7)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(path.edges == [0, 7, 13, 18, 22, 25, 27] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 0), (6, 0), (0, 7), (1, 2), (3, 1), (1, 4), (5, 1), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (7, 2), (3, 4), (5, 3), (3, 6), (3, 7), (4, 5), (4, 6), (7, 4), (5, 6), (7, 5), (6, 7)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(path.edges == [0, 7, 13, 18, 22, 25, 27] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 0), (6, 0), (0, 7), (1, 2), (3, 1), (1, 4), (5, 1), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (7, 2), (3, 4), (5, 3), (3, 6), (3, 7), (4, 5), (4, 6), (7, 4), (5, 6), (7, 5), (6, 7)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 7, 13, 18, 22, 25, 27] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 0), (6, 0), (0, 7), (1, 2), (3, 1), (1, 4), (5, 1), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (7, 2), (3, 4), (5, 3), (3, 6), (3, 7), (4, 5), (4, 6), (7, 4), (5, 6), (7, 5), (6, 7)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 7, 13, 18, 22, 25, 27] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-378 lcgd(9,25,1), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to378() throws {
        // lcgd(9,25,1); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(5, 3), (0, 8), (5, 7), (3, 4), (3, 7), (5, 4), (1, 8), (7, 6), (1, 4), (8, 0), (3, 2), (6, 2), (2, 1), (3, 8), (0, 7), (4, 7), (2, 4), (6, 4), (3, 6), (2, 7), (8, 7), (7, 5), (5, 1), (7, 4), (3, 5)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 8, 7, 5, 3, 6, 2, 1, 4] as [Int])
            #expect(path.edges == [1, 20, 21, 0, 18, 11, 12, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(5, 3), (0, 8), (5, 7), (3, 4), (3, 7), (5, 4), (1, 8), (7, 6), (1, 4), (8, 0), (3, 2), (6, 2), (2, 1), (3, 8), (0, 7), (4, 7), (2, 4), (6, 4), (3, 6), (2, 7), (8, 7), (7, 5), (5, 1), (7, 4), (3, 5)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 8, 7, 5, 3, 6, 2, 1, 4] as [Int])
            #expect(path.edges == [1, 20, 21, 0, 18, 11, 12, 8] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(5, 3), (0, 8), (5, 7), (3, 4), (3, 7), (5, 4), (1, 8), (7, 6), (1, 4), (8, 0), (3, 2), (6, 2), (2, 1), (3, 8), (0, 7), (4, 7), (2, 4), (6, 4), (3, 6), (2, 7), (8, 7), (7, 5), (5, 1), (7, 4), (3, 5)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 8, 7, 5, 3, 6, 2, 1, 4] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [1, 20, 21, 0, 18, 11, 12, 8] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(5, 3), (0, 8), (5, 7), (3, 4), (3, 7), (5, 4), (1, 8), (7, 6), (1, 4), (8, 0), (3, 2), (6, 2), (2, 1), (3, 8), (0, 7), (4, 7), (2, 4), (6, 4), (3, 6), (2, 7), (8, 7), (7, 5), (5, 1), (7, 4), (3, 5)]
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
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 8, 7, 5, 3, 6, 2, 1, 4] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [1, 20, 21, 0, 18, 11, 12, 8] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-380 lcgd(10,40,2), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to380() throws {
        // lcgd(10,40,2); hamiltonianPath()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 2), (6, 4), (5, 9), (5, 2), (3, 2), (4, 3), (6, 5), (2, 8), (5, 6), (9, 2), (3, 7), (8, 2), (3, 6), (7, 4), (5, 3), (0, 6), (7, 5), (6, 0), (0, 7), (6, 1), (1, 0), (2, 6), (2, 9), (9, 7), (0, 3), (4, 1), (0, 4), (7, 6), (4, 8), (8, 3), (0, 8), (1, 3), (9, 5), (9, 8), (3, 8), (2, 7), (6, 7), (7, 8), (8, 6), (6, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 8, 3, 6, 5, 9, 7, 4, 1] as [Int])
            #expect(path.edges == [0, 7, 29, 12, 6, 2, 23, 13, 25] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (6, 4), (5, 9), (5, 2), (3, 2), (4, 3), (6, 5), (2, 8), (5, 6), (9, 2), (3, 7), (8, 2), (3, 6), (7, 4), (5, 3), (0, 6), (7, 5), (6, 0), (0, 7), (6, 1), (1, 0), (2, 6), (2, 9), (9, 7), (0, 3), (4, 1), (0, 4), (7, 6), (4, 8), (8, 3), (0, 8), (1, 3), (9, 5), (9, 8), (3, 8), (2, 7), (6, 7), (7, 8), (8, 6), (6, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath())
            #expect(path.vertices == [0, 2, 8, 3, 6, 5, 9, 7, 4, 1] as [Int])
            #expect(path.edges == [0, 7, 29, 12, 6, 2, 23, 13, 25] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (6, 4), (5, 9), (5, 2), (3, 2), (4, 3), (6, 5), (2, 8), (5, 6), (9, 2), (3, 7), (8, 2), (3, 6), (7, 4), (5, 3), (0, 6), (7, 5), (6, 0), (0, 7), (6, 1), (1, 0), (2, 6), (2, 9), (9, 7), (0, 3), (4, 1), (0, 4), (7, 6), (4, 8), (8, 3), (0, 8), (1, 3), (9, 5), (9, 8), (3, 8), (2, 7), (6, 7), (7, 8), (8, 6), (6, 3)]
            let graph = CompressedSparseRow(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (6, 4), (5, 9), (5, 2), (3, 2), (4, 3), (6, 5), (2, 8), (5, 6), (9, 2), (3, 7), (8, 2), (3, 6), (7, 4), (5, 3), (0, 6), (7, 5), (6, 0), (0, 7), (6, 1), (1, 0), (2, 6), (2, 9), (9, 7), (0, 3), (4, 1), (0, 4), (7, 6), (4, 8), (8, 3), (0, 8), (1, 3), (9, 5), (9, 8), (3, 8), (2, 7), (6, 7), (7, 8), (8, 6), (6, 3)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // The first vertex from which some Hamiltonian path starts.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-382 P(3) from 0, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to382() throws {
        // P(3); hamiltonianPath(from: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
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
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-383 P(3) from 1, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to383() {
        // P(3); hamiltonianPath(from: 1)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
    }

    @Test("TO-384 P(3) from 2, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to384() throws {
        // P(3); hamiltonianPath(from: 2)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 2))
            #expect(path.vertices == [2, 1, 0] as [Int])
            #expect(path.edges == [1, 0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 2))
            #expect(path.vertices == [2, 1, 0] as [Int])
            #expect(path.edges == [1, 0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 2))
            #expect(path.vertices == [2, 1, 0] as [Int])
            #expect(path.edges == [1, 0] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
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
            let path = try #require(graph.hamiltonianPath(from: 2))
            #expect(path.vertices == [2, 1, 0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [1, 0] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
    }

    @Test("TO-385 C(5) from 2, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to385() throws {
        // C(5); hamiltonianPath(from: 2)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 2))
            #expect(path.vertices == [2, 1, 0, 4, 3] as [Int])
            #expect(path.edges == [1, 0, 4, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 2))
            #expect(path.vertices == [2, 1, 0, 4, 3] as [Int])
            #expect(path.edges == [1, 0, 4, 3] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 2))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
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
            let path = try #require(graph.hamiltonianPath(from: 2))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 2)
        }
    }

    @Test("TO-386 Petersen from 4, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to386() throws {
        // nx(petersen_graph); hamiltonianPath(from: 4)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 4))
            #expect(path.vertices == [4, 0, 1, 2, 3, 8, 5, 7, 9, 6] as [Int])
            #expect(path.edges == [1, 0, 3, 5, 8, 11, 10, 14, 13] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 4))
            #expect(path.vertices == [4, 0, 1, 2, 3, 8, 5, 7, 9, 6] as [Int])
            #expect(path.edges == [1, 0, 3, 5, 8, 11, 10, 14, 13] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 4)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 4))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 4)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath(from: 4))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 4)
        }
    }

    @Test("TO-387 P(4) from 0 to 3, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to387() throws {
        // P(4); hamiltonianPath(from: 0, to: 3)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 3))
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 3))
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 3)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 3))
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges == [0, 1, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 3)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath(from: 0, to: 3))
            #expect(path.vertices == [0, 1, 2, 3] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 3)
        }
    }

    @Test("TO-388 P(4) from 0 to 2: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to388() {
        // P(4); hamiltonianPath(from: 0, to: 2)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 2) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 2) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 2) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 2) == nil)
        }
    }

    @Test("TO-389 K(4) from 1 to 0, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to389() throws {
        // K(4); hamiltonianPath(from: 1, to: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 1, to: 0))
            #expect(path.vertices == [1, 2, 3, 0] as [Int])
            #expect(path.edges == [3, 5, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 1)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 1, to: 0))
            #expect(path.vertices == [1, 2, 3, 0] as [Int])
            #expect(path.edges == [3, 5, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 1)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 1, to: 0))
            #expect(path.vertices == [1, 2, 3, 0] as [Int])
            #expect(path.edges == [3, 5, 2] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 1)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
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
            let path = try #require(graph.hamiltonianPath(from: 1, to: 0))
            #expect(path.vertices == [1, 2, 3, 0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [3, 5, 2] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 1)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
    }

    @Test("TO-390 one vertex from 0 to 0: the trivial path, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to390() throws {
        // V [0]; E []; hamiltonianPath(from: 0, to: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 0))
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 0))
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 0))
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges == [] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath(from: 0, to: 0))
            #expect(path.vertices == [0] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 0)
        }
    }

    @Test("TO-391 same ends, two vertices: nil, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to391() {
        // P(2); hamiltonianPath(from: 0, to: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 0) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 0) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 0) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 0) == nil)
        }
    }

    @Test("TO-392 grid(3,3) from corner to corner, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to392() throws {
        // grid(3,3); hamiltonianPath(from: 0, to: 8)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 8))
            #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
            #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 8)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 8))
            #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
            #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 8)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0, to: 8))
            #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
            #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 8)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
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
            let path = try #require(graph.hamiltonianPath(from: 0, to: 8))
            #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
            // To the given end.
            #expect(at[n - 1] == 8)
        }
    }

    @Test("TO-393 grid(3,3) from corner to an edge midpoint: nil (parity), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to393() {
        // grid(3,3); hamiltonianPath(from: 0, to: 1)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 1) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 1) == nil)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 1) == nil)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 0, to: 1) == nil)
        }
    }

    @Test("TO-394 Pd(3) from 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to394() throws {
        // Pd(3); hamiltonianPath(from: 0)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges == [0, 1] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
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
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
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
            let path = try #require(graph.hamiltonianPath(from: 0))
            #expect(path.vertices == [0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 0)
        }
    }

    @Test("TO-395 Pd(3) from 1: nil, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to395() {
        // Pd(3); hamiltonianPath(from: 1)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.hamiltonianPath(from: 1) == nil)
        }
    }

    @Test("TO-396 Kd(4) from 3 to 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to396() throws {
        // Kd(4); hamiltonianPath(from: 3, to: 2)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 3, to: 2))
            #expect(path.vertices == [3, 0, 1, 2] as [Int])
            #expect(path.edges == [9, 0, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 3)
            // To the given end.
            #expect(at[n - 1] == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let path = try #require(graph.hamiltonianPath(from: 3, to: 2))
            #expect(path.vertices == [3, 0, 1, 2] as [Int])
            #expect(path.edges == [9, 0, 4] as [Int])
            let walked = path.edges
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 3)
            // To the given end.
            #expect(at[n - 1] == 2)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath(from: 3, to: 2))
            #expect(path.vertices == [3, 0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [9, 0, 4] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 3)
            // To the given end.
            #expect(at[n - 1] == 2)
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
            let n = vertexList.count
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs
            let path = try #require(graph.hamiltonianPath(from: 3, to: 2))
            #expect(path.vertices == [3, 0, 1, 2] as [Int])
            #expect(path.edges.map { edgeOf[$0]! } == [9, 0, 4] as [Int])
            let walked = path.edges.map { edgeOf[$0]! }
            let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
            #expect(at.sorted() == Array(0 ..< n))
            #expect(walked.count == n - 1 && Set(walked).count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[i + 1]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
            // From the given start.
            #expect(at[0] == 3)
            // To the given end.
            #expect(at[n - 1] == 2)
        }
    }
}
