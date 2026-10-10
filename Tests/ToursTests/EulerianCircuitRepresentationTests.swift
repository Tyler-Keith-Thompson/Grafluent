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

@Suite("eulerianCircuit on every representation")
struct EulerianCircuitRepresentationTests {
    @Test("TO-003 empty graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to003() {
        // V []; E []; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-007 one vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to007() {
        // V [0]; E []; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-011 two isolated vertices (isolated vertices ignored), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to011() {
        // V [0, 1]; E []; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-015 one self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to015() throws {
        // multigraph V [0]; E [0-0]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-019 two self-loops at one vertex, on ReferencePseudograph, no indices")
    func to019() throws {
        // multigraph V [0]; E [0-0, 0-0]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 0] as [Int])
            #expect(circuit.edges == [0, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 0] as [Int])
            #expect(circuit.edges == [0, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-023 self-loop beside an isolated vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to023() throws {
        // multigraph V [0, 1]; E [1-1]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 1)
        }
    }

    @Test("TO-027 self-loops at two vertices: two components with edges, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to027() {
        // multigraph V [0, 1]; E [0-0, 1-1]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-031 one edge: a trail, no circuit, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to031() {
        // V [0, 1]; E [0-1]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-035 two parallel edges: a circuit of length 2, on ReferencePseudograph, no indices")
    func to035() throws {
        // multigraph V [0, 1]; E [0-1, 0-1]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1] as [Int])
            #expect(circuit.edges == [0, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1] as [Int])
            #expect(circuit.edges == [0, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-039 three parallel edges: odd at both ends, on ReferencePseudograph, no indices")
    func to039() {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-043 path P(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to043() {
        // P(3); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-047 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to047() {
        // P(4); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-051 triangle C(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to051() throws {
        // C(3); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-055 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to055() throws {
        // C(5); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-059 triangle beside an isolated vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to059() throws {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-063 isolated first vertex: the circuit starts at the first vertex with an edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to063() throws {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 1)
        }
    }

    @Test("TO-067 two triangles apart, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to067() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-071 bowtie: two triangles at a shared vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to071() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4, 2] as [Int])
            #expect(circuit.edges == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4, 2] as [Int])
            #expect(circuit.edges == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4, 2] as [Int])
            #expect(circuit.edges == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 3, 4, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 3, 4, 5, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-075 triangle with a loop: loops add 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to075() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0] as [Int])
            #expect(circuit.edges == [0, 2, 3, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0] as [Int])
            #expect(circuit.edges == [0, 2, 3, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0] as [Int])
            #expect(circuit.edges == [0, 2, 3, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-079 edge with a loop at the end: odd 0 and 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to079() {
        // multigraph V [0, 1]; E [0-1, 1-1]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-083 loop at a vertex, an edge elsewhere: two components, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to083() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-087 star(3): four odd vertices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to087() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-091 K(4): every degree 3, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to091() {
        // K(4); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-095 K(5): every degree 4, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to095() throws {
        // K(5); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 1, 4, 2, 3, 4] as [Int])
            #expect(circuit.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 1, 4, 2, 3, 4] as [Int])
            #expect(circuit.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-099 Königsberg: seven bridges, four odd land masses, on ReferencePseudograph, no indices")
    func to099() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-103 Königsberg less one A–B bridge: a trail, on ReferencePseudograph, no indices")
    func to103() {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-107 house: odd at the base, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to107() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-111 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to111() {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = Pseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-115 odd vertices last in the order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to115() {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-119 grid(3,3): four odd corners' neighbours, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to119() {
        // grid(3,3); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-123 Petersen: every degree 3, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to123() {
        // nx(petersen_graph); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-127 octahedral: every degree 4, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to127() throws {
        // nx(octahedral_graph); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 1, 5, 2, 4, 3, 5, 4] as [Int])
            #expect(circuit.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 10, 11, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 1, 5, 2, 4, 3, 5, 4] as [Int])
            #expect(circuit.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 10, 11, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-131 wheel(4): rim odd, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to131() {
        // wheel(4); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-135 K(3,3) less nothing: degree 3, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to135() {
        // Kb(3,3); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-139 Kb(2,4): even sides, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to139() throws {
        // Kb(2,4); eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 1, 3, 0, 4, 1, 5] as [Int])
            #expect(circuit.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 1, 3, 0, 4, 1, 5] as [Int])
            #expect(circuit.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 1, 3, 0, 4, 1, 5] as [Int])
            #expect(circuit.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 1, 3, 0, 4, 1, 5] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-143 rows decide: the first edge out of 0 is the second chord, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to143() throws {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; eulerianCircuit()
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 3, 4, 0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 4, 5, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 3, 4, 0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 4, 5, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 3, 4, 0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 4, 5, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-147 parallel edges inside a longer circuit, on ReferencePseudograph, no indices")
    func to147() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 1, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2, 5, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 1, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2, 5, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-151 lcgwalk(6,14,1), on ReferencePseudograph, no indices")
    func to151() throws {
        // lcgwalk(6,14,1); eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-155 lcgwalk(8,30,2), on ReferencePseudograph, no indices")
    func to155() throws {
        // lcgwalk(8,30,2); eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-159 lcgwalk(5,20,3,open), on ReferencePseudograph, no indices")
    func to159() {
        // lcgwalk(5,20,3,open); eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-163 lcgwalk(10,40,4,open), on ReferencePseudograph, no indices")
    func to163() {
        // lcgwalk(10,40,4,open); eulerianCircuit()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-167 empty digraph, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to167() {
        // V []; E []; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-171 one vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to171() {
        // V [0]; E []; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-175 one self-loop: in 1, out 1, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to175() throws {
        // multigraph V [0]; E [0→0]; eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-179 one edge 0→1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to179() {
        // V [0, 1]; E [0→1]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-183 antiparallel pair, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to183() throws {
        // V [0, 1]; E [0→1, 1→0]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1] as [Int])
            #expect(circuit.edges == [0, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1] as [Int])
            #expect(circuit.edges == [0, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-187 parallel pair 0→1 twice: unbalanced by 2, on ReferenceDirectedMultigraph, no indices")
    func to187() {
        // multigraph V [0, 1]; E [0→1, 0→1]; eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-191 directed cycle Cd(3), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to191() throws {
        // Cd(3); eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-195 directed path Pd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to195() {
        // Pd(4); eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-199 two sources: no trail, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to199() {
        // V [0, 1, 2]; E [0→2, 1→2]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-203 balanced but two components, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to203() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-207 Cd(3) beside an isolated vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to207() throws {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-211 isolated first vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to211() throws {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [1, 2, 3] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 1)
        }
    }

    @Test("TO-215 start is the vertex with out − in = 1, not the first, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to215() {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-219 two directed cycles at a shared vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to219() throws {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 4] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 4] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 4] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 2, 0, 3, 4] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2, 3, 4, 5] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-223 loop on a directed cycle, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to223() throws {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 1, 2] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-227 Cd(3) with a chord: a trail from 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to227() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-231 in − out = 2 at one vertex, on ReferenceDirectedMultigraph, no indices")
    func to231() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-235 Kd(3): every in = out = 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to235() throws {
        // Kd(3); eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 1, 2] as [Int])
            #expect(circuit.edges == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 1, 2] as [Int])
            #expect(circuit.edges == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 1, 2] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 2, 1, 5, 3, 4] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-239 Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to239() throws {
        // Kd(4); eulerianCircuit()
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3] as [Int])
            #expect(circuit.edges == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3] as [Int])
            #expect(circuit.edges == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-243 self-loop and an edge elsewhere, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to243() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
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
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-247 lcgwalkd(6,14,1), on ReferenceDirectedMultigraph, no indices")
    func to247() throws {
        // lcgwalkd(6,14,1); eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-251 lcgwalkd(8,30,2), on ReferenceDirectedMultigraph, no indices")
    func to251() throws {
        // lcgwalkd(8,30,2); eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
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
            let circuit = try #require(graph.eulerianCircuit())
            #expect(circuit.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the first vertex with an edge.
            #expect(at.first == 0)
        }
    }

    @Test("TO-255 lcgwalkd(5,20,3,open), on ReferenceDirectedMultigraph, no indices")
    func to255() {
        // lcgwalkd(5,20,3,open); eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-259 lcgwalkd(9,40,5,open), on ReferenceDirectedMultigraph, no indices")
    func to259() {
        // lcgwalkd(9,40,5,open); eulerianCircuit()
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit() == nil)
        }
    }

    @Test("TO-261 C(4) from 0, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to261() throws {
        // C(4); eulerianCircuit(from: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0, 1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
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
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0, 1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0, 1, 2, 3] as [Int])
            #expect(circuit.edges == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
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
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0, 1, 2, 3] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0, 1, 2, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-262 C(4) from 1, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to262() throws {
        // C(4); eulerianCircuit(from: 1)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 1))
            #expect(circuit.vertices == [1, 0, 3, 2] as [Int])
            #expect(circuit.edges == [0, 3, 2, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
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
            let circuit = try #require(graph.eulerianCircuit(from: 1))
            #expect(circuit.vertices == [1, 0, 3, 2] as [Int])
            #expect(circuit.edges == [0, 3, 2, 1] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 1))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
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
            let circuit = try #require(graph.eulerianCircuit(from: 1))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 1)
        }
    }

    @Test("TO-263 bowtie from the shared vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to263() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianCircuit(from: 2)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            #expect(circuit.vertices == [2, 1, 0, 2, 3, 4] as [Int])
            #expect(circuit.edges == [1, 0, 2, 3, 4, 5] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
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
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            #expect(circuit.vertices == [2, 1, 0, 2, 3, 4] as [Int])
            #expect(circuit.edges == [1, 0, 2, 3, 4, 5] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
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
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
    }

    @Test("TO-264 bowtie from a wing, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to264() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianCircuit(from: 4)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 4))
            #expect(circuit.vertices == [4, 3, 2, 1, 0, 2] as [Int])
            #expect(circuit.edges == [4, 3, 1, 0, 2, 5] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 4)
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
            let circuit = try #require(graph.eulerianCircuit(from: 4))
            #expect(circuit.vertices == [4, 3, 2, 1, 0, 2] as [Int])
            #expect(circuit.edges == [4, 3, 1, 0, 2, 5] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 4))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 4)
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
            let circuit = try #require(graph.eulerianCircuit(from: 4))
            // Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 4)
        }
    }

    @Test("TO-265 isolated start: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to265() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianCircuit(from: 3)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 3) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 3) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 3) == nil)
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
            #expect(graph.eulerianCircuit(from: 3) == nil)
        }
    }

    @Test("TO-266 not Eulerian: nil, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to266() {
        // P(3); eulerianCircuit(from: 1)
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 1) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 1) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 1) == nil)
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
            #expect(graph.eulerianCircuit(from: 1) == nil)
        }
    }

    @Test("TO-267 edgeless: nil (a circuit has an edge), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to267() {
        // V [0, 1]; E []; eulerianCircuit(from: 0)
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 0) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 0) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 0) == nil)
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
            #expect(graph.eulerianCircuit(from: 0) == nil)
        }
    }

    @Test("TO-268 one self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func to268() throws {
        // multigraph V [0]; E [0-0]; eulerianCircuit(from: 0)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
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
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
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
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges == [0] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
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
            let circuit = try #require(graph.eulerianCircuit(from: 0))
            #expect(circuit.vertices == [0] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [0] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 0)
        }
    }

    @Test("TO-269 two directed cycles from 3, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to269() throws {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; eulerianCircuit(from: 3)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 3))
            #expect(circuit.vertices == [3, 4, 0, 1, 2, 0] as [Int])
            #expect(circuit.edges == [4, 5, 0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
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
            let circuit = try #require(graph.eulerianCircuit(from: 3))
            #expect(circuit.vertices == [3, 4, 0, 1, 2, 0] as [Int])
            #expect(circuit.edges == [4, 5, 0, 1, 2, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
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
            let circuit = try #require(graph.eulerianCircuit(from: 3))
            #expect(circuit.vertices == [3, 4, 0, 1, 2, 0] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [4, 5, 0, 1, 2, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
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
            let circuit = try #require(graph.eulerianCircuit(from: 3))
            #expect(circuit.vertices == [3, 4, 0, 1, 2, 0] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [4, 5, 0, 1, 2, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 3)
        }
    }

    @Test("TO-270 Kd(3) from 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to270() throws {
        // Kd(3); eulerianCircuit(from: 2)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            #expect(circuit.vertices == [2, 0, 1, 0, 2, 1] as [Int])
            #expect(circuit.edges == [4, 0, 2, 1, 5, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
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
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            #expect(circuit.vertices == [2, 0, 1, 0, 2, 1] as [Int])
            #expect(circuit.edges == [4, 0, 2, 1, 5, 3] as [Int])
            let walked = circuit.edges
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
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
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            #expect(circuit.vertices == [2, 0, 1, 0, 2, 1] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [4, 0, 2, 1, 5, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
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
            let circuit = try #require(graph.eulerianCircuit(from: 2))
            #expect(circuit.vertices == [2, 0, 1, 0, 2, 1] as [Int])
            #expect(circuit.edges.map { edgeOf[$0]! } == [4, 0, 2, 1, 5, 3] as [Int])
            let walked = circuit.edges.map { edgeOf[$0]! }
            let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
            // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
            #expect(walked.sorted() == Array(pairs.indices))
            #expect(at.count == walked.count)
            for (i, k) in walked.enumerated() {
                let x = at[i], y = at[(i + 1) % at.count]
                let (a, b) = ends[k]
                #expect(a == x && b == y, "step \(i)")
            }
            #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
            // The documented start: the given vertex.
            #expect(at.first == 2)
        }
    }

    @Test("TO-271 unbalanced: nil, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to271() {
        // Pd(3); eulerianCircuit(from: 0)
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 0) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.eulerianCircuit(from: 0) == nil)
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
            #expect(graph.eulerianCircuit(from: 0) == nil)
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
            #expect(graph.eulerianCircuit(from: 0) == nil)
        }
    }
}
