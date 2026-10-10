// Every recognition row (BP-001 – BP-084) again on the other representations: the package's
// `UndirectedAdjacencyList` (stored index rows, so recognition reads `_withIncidentIndexRows`),
// a file-private conformer with no vertex or edge indices (rows from `incidentEdges(of:)`,
// `side(ofIndex:)` by position in `vertices`), `AdjacencyList.undirected` with each edge as an
// arc as written, and `AdjacencyMatrix.undirected` with the arcs at their row-major cells, for
// rows on 0..<n with no arc twice. Rows with parallel edges run on the unindexed conformer only.
// Through `.undirected` a row is successors, then predecessors, so the odd cycle those
// searches meet can differ from the catalog's: swiftgen.py computed each expected cycle with
// ref.py's model on that representation's rows (sides do not depend on row order). Matrix
// positions are cells, compared as [source, target]. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import GraphProtocols
import Testing
import Walks

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
/// Rows are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Recognition on every representation")
struct RecognitionRepresentationTests {
    @Test("BP-001 empty graph, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp001() throws {
        // V []; E []
        do { // UndirectedAdjacencyList: the catalog's values
            let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int])
            #expect(graph.edgeCount == 0)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = []
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let graph = UnindexedGraph<Int>(vertices: [], edges: [])
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = []
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = []
            let graph = AdjacencyList(vertices: [] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = []
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = []
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-002 one vertex, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp002() throws {
        // V [0]; E []
        do { // UndirectedAdjacencyList: the catalog's values
            let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int])
            #expect(graph.edgeCount == 0)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let graph = UnindexedGraph<Int>(vertices: [0], edges: [])
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = []
            let graph = AdjacencyList(vertices: [0] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-003 two isolated vertices, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp003() throws {
        // V [0, 1]; E []
        do { // UndirectedAdjacencyList: the catalog's values
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int])
            #expect(graph.edgeCount == 0)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let graph = UnindexedGraph<Int>(vertices: [0, 1], edges: [])
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = []
            let graph = AdjacencyList(vertices: [0, 1] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = []
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-004 one edge, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp004() throws {
        // V [0, 1]; E [0–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList(vertices: [0, 1] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-005 one edge, written 1–0, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp005() throws {
        // V [0, 1]; E [1–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = UnindexedGraph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(1, 0)]
            let graph = AdjacencyList(vertices: [0, 1] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-006 one edge, vertex order [1, 0], on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp006() throws {
        // V [1, 0]; E [0–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UndirectedAdjacencyList(vertices: [1, 0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [1]
            let right: [Int] = [0]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph(vertices: [1, 0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [1]
            let right: [Int] = [0]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList(vertices: [1, 0] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [1]
            let right: [Int] = [0]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-007 self-loop alone, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp007() throws {
        // V [0]; E [0–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0])
            #expect(cycle.edges == [0])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0])
            #expect(cycle.edges == [0])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList(vertices: [0] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0])
            #expect(cycle.edges == [0])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-008 self-loop beside an edge, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp008() throws {
        // V [0, 1]; E [0–1, 1–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1])
            #expect(cycle.edges == [1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UnindexedGraph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1])
            #expect(cycle.edges == [1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyList(vertices: [0, 1] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1])
            #expect(cycle.edges == [1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[1, 1]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-009 self-loop on an isolated vertex of a bipartite graph, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp009() throws {
        // V [0, 1, 2]; E [0–1, 2–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (2, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2])
            #expect(cycle.edges == [1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (2, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2])
            #expect(cycle.edges == [1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (2, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2])
            #expect(cycle.edges == [1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[2, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-010 parallel pair, on no indices")
    func bp010() throws {
        // multigraph V [0, 1]; E [0–1, 0–1]
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = UnindexedGraph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-011 parallel pair, second copy written 1–0, on no indices, AdjacencyMatrix.undirected")
    func bp011() throws {
        // multigraph V [0, 1]; E [0–1, 1–0]
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = UnindexedGraph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-012 three parallel copies, on no indices")
    func bp012() throws {
        // multigraph V [0, 1]; E [0–1, 0–1, 0–1]
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 1)]
            let graph = UnindexedGraph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-013 parallel pair inside a triangle, on no indices")
    func bp013() throws {
        // multigraph V [0, 1, 2]; E [0–1, 0–1, 1–2, 2–0]
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 2, 3])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-014 two self-loops on one vertex, on no indices")
    func bp014() throws {
        // multigraph V [0]; E [0–0, 0–0]
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
            let graph = UnindexedGraph(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0])
            #expect(cycle.edges == [0])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-015 path P3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp015() throws {
        // V [0, 1, 2]; E [0–1, 1–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-016 path P4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp016() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-017 path P7, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp017() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-018 path P5 listed from the middle, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp018() throws {
        // V [2, 0, 1, 3, 4]; E [0–1, 1–2, 2–3, 3–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UndirectedAdjacencyList(vertices: [2, 0, 1, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [2, 0, 4]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph(vertices: [2, 0, 1, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [2, 0, 4]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList(vertices: [2, 0, 1, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [2, 0, 4]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-019 triangle C3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp019() throws {
        // V [0, 1, 2]; E [0–1, 1–2, 2–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-020 triangle written backwards, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp020() throws {
        // V [0, 1, 2]; E [2–1, 1–0, 0–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(2, 1), (1, 0), (0, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [1, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(2, 1), (1, 0), (0, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [1, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(2, 1), (1, 0), (0, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [1, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(2, 1), (1, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 2, 1])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 2], [2, 1], [1, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-021 square C4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp021() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3, 3–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-022 pentagon C5, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp022() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 1–2, 2–3, 3–4, 4–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 1, 2, 3, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 1, 2, 3, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 1, 2, 3, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-023 hexagon C6, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp023() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-024 heptagon C7, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp024() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6])
            #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 7 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6])
            #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 7 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6])
            #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 7 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 7 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-025 C9, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp025() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 9 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 9 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 9 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 9 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-026 C8, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp026() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-027 C5 with vertex order reversed, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp027() throws {
        // V [4, 3, 2, 1, 0]; E [0–1, 1–2, 2–3, 3–4, 4–0]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UndirectedAdjacencyList(vertices: [4, 3, 2, 1, 0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 3, 2, 1, 0])
            #expect(cycle.edges == [3, 2, 1, 0, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph(vertices: [4, 3, 2, 1, 0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 3, 2, 1, 0])
            #expect(cycle.edges == [3, 2, 1, 0, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList(vertices: [4, 3, 2, 1, 0] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 3, 2, 1, 0])
            #expect(cycle.edges == [3, 2, 1, 0, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-028 C5 with shuffled edge positions, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp028() throws {
        // V [0, 1, 2, 3, 4]; E [3–4, 0–1, 4–0, 2–3, 1–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(3, 4), (0, 1), (4, 0), (2, 3), (1, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [1, 4, 3, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(3, 4), (0, 1), (4, 0), (2, 3), (1, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [1, 4, 3, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(3, 4), (0, 1), (4, 0), (2, 3), (1, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [1, 4, 3, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(3, 4), (0, 1), (4, 0), (2, 3), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-029 K4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp029() throws {
        // V [0, 1, 2, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 3, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 3, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 3, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-030 K5, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp030() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 4, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 4, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 4, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-031 star K1,4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp031() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1, 2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1, 2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1, 2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1, 2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-032 star with centre last, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp032() throws {
        // V [0, 1, 2, 3, 4]; E [4–0, 4–1, 4–2, 4–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3]
            let right: [Int] = [4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3]
            let right: [Int] = [4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3]
            let right: [Int] = [4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3]
            let right: [Int] = [4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-033 K2,3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp033() throws {
        // V [0, 1, 2, 3, 4]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = [2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = [2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = [2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1]
            let right: [Int] = [2, 3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-034 K3,3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp034() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2]
            let right: [Int] = [3, 4, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2]
            let right: [Int] = [3, 4, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2]
            let right: [Int] = [3, 4, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2]
            let right: [Int] = [3, 4, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-035 K3,3 plus one edge inside a side, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp035() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 0–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (0, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 1])
            #expect(cycle.edges == [0, 3, 9])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (0, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 1])
            #expect(cycle.edges == [0, 3, 9])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (0, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 1])
            #expect(cycle.edges == [0, 3, 9])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 3])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 3], [0, 3]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-036 K3,3 plus one edge inside the other side, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp036() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 4–5]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 5])
            #expect(cycle.edges == [1, 9, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 5])
            #expect(cycle.edges == [1, 9, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 5])
            #expect(cycle.edges == [1, 9, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 5])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 4], [4, 5], [0, 5]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-037 grid 3×3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp037() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 8]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 8]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 8]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 8]
            let right: [Int] = [1, 3, 5, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-038 grid 2×4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp038() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 5–6, 6–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 5, 7]
            let right: [Int] = [1, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 5, 7]
            let right: [Int] = [1, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 5, 7]
            let right: [Int] = [1, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 5, 7]
            let right: [Int] = [1, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-039 grid 3×3 plus a diagonal, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp039() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8, 0–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8), (0, 4)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 13)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 4])
            #expect(cycle.edges == [0, 3, 12])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8), (0, 4)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 4])
            #expect(cycle.edges == [0, 3, 12])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8), (0, 4)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 4])
            #expect(cycle.edges == [0, 3, 12])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 4], [0, 4]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-040 hypercube Q3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp040() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6]
            let right: [Int] = [1, 2, 4, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6]
            let right: [Int] = [1, 2, 4, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6]
            let right: [Int] = [1, 2, 4, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6]
            let right: [Int] = [1, 2, 4, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-041 Petersen graph, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp041() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 3, 5, 7, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 3, 5, 7, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 3, 5, 7, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [0, 4]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-042 wheel W5 (hub 0, rim C5), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp042() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 2–3, 3–4, 4–5, 5–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 5, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 5, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 5, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-043 wheel W4 (hub 0, rim C4), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp043() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 2–3, 3–4, 4–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 4, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 4, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 4, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-044 two triangles sharing a vertex (bowtie), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp044() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 1–2, 2–0, 2–3, 3–4, 4–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-045 triangle at the end of a path, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp045() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5])
            #expect(cycle.edges == [3, 4, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5])
            #expect(cycle.edges == [3, 4, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5])
            #expect(cycle.edges == [3, 4, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[3, 4], [4, 5], [5, 3]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-046 C5 hanging off a long path, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp046() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5, 6, 7])
            #expect(cycle.edges == [3, 4, 5, 6, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5, 6, 7])
            #expect(cycle.edges == [3, 4, 5, 6, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5, 6, 7])
            #expect(cycle.edges == [3, 4, 5, 6, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 3)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [3, 4, 5, 6, 7])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[3, 4], [4, 5], [5, 6], [6, 7], [7, 3]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-047 theta graph: paths of length 2, 2, 4 between 0 and 1, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp047() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–2, 2–1, 0–3, 3–1, 0–4, 4–5, 5–6, 6–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (2, 1), (0, 3), (3, 1), (0, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 5]
            let right: [Int] = [2, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (2, 1), (0, 3), (3, 1), (0, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 5]
            let right: [Int] = [2, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 2), (2, 1), (0, 3), (3, 1), (0, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 5]
            let right: [Int] = [2, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 2), (2, 1), (0, 3), (3, 1), (0, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 5]
            let right: [Int] = [2, 3, 4, 6]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-048 theta graph: paths of length 1, 2, 3 (odd cycles), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp048() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 2–1, 0–3, 3–4, 4–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1), (0, 3), (3, 4), (4, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 2, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1), (0, 3), (3, 4), (4, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 2, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1), (0, 3), (3, 4), (4, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 2, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1), (0, 3), (3, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [2, 1], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-049 C4 plus a chord, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp049() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3, 3–0, 0–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 4])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-050 C6 plus a long chord (two C4s), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp050() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-051 C6 plus a short chord (two odd cycles), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp051() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-052 first conflict met is a C5 although a triangle exists, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp052() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 0–2, 1–3, 2–4, 3–4, 3–5, 5–6, 6–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (6, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 3, 4, 2])
            #expect(cycle.edges == [0, 2, 4, 3, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (6, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 3, 4, 2])
            #expect(cycle.edges == [0, 2, 4, 3, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (6, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 3, 4, 2])
            #expect(cycle.edges == [0, 2, 4, 3, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (6, 3)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 3, 4, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 3], [3, 4], [2, 4], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-053 disconnected: edge, isolated vertex, path, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp053() throws {
        // V [0, 1, 2, 3, 4, 5]; E [1–2, 3–4, 4–5]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(1, 2), (3, 4), (4, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 5]
            let right: [Int] = [2, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(1, 2), (3, 4), (4, 5)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 5]
            let right: [Int] = [2, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(1, 2), (3, 4), (4, 5)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 5]
            let right: [Int] = [2, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(1, 2), (3, 4), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 5]
            let right: [Int] = [2, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-054 disconnected: least vertex of a component is not its first endpoint, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp054() throws {
        // V [0, 1, 2, 3, 4, 5]; E [5–3, 3–1, 4–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(5, 3), (3, 1), (4, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 5]
            let right: [Int] = [3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(5, 3), (3, 1), (4, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 5]
            let right: [Int] = [3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(5, 3), (3, 1), (4, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 5]
            let right: [Int] = [3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(5, 3), (3, 1), (4, 2)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 5]
            let right: [Int] = [3, 4]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-055 disconnected: bipartite component then triangle, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp055() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 2–3, 3–4, 4–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 3, 4])
            #expect(cycle.edges == [1, 2, 3])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 3, 4])
            #expect(cycle.edges == [1, 2, 3])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 3, 4])
            #expect(cycle.edges == [1, 2, 3])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 3, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[2, 3], [3, 4], [4, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-056 disconnected: triangle in the second component, first is C4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp056() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–0, 4–5, 5–6, 6–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 4)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 5, 6])
            #expect(cycle.edges == [4, 5, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 4)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 5, 6])
            #expect(cycle.edges == [4, 5, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 4)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 5, 6])
            #expect(cycle.edges == [4, 5, 6])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 4)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [4, 5, 6])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[4, 5], [5, 6], [6, 4]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-057 disconnected: two triangles, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp057() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–0, 3–4, 4–5, 5–3]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-058 isolated vertices around a C4, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp058() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [1–2, 2–4, 4–5, 5–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(1, 2), (2, 4), (4, 5), (5, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 6]
            let right: [Int] = [2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(1, 2), (2, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 6]
            let right: [Int] = [2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(1, 2), (2, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 6]
            let right: [Int] = [2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(1, 2), (2, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 6]
            let right: [Int] = [2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-059 string vertices: a–x, b–x, b–y, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected")
    func bp059() throws {
        // V [a, b, x, y]; E [a–x, b–x, b–y]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y")]
            let graph = UndirectedAdjacencyList(vertices: ["a", "b", "x", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [String] = ["a", "b"]
            let right: [String] = ["x", "y"]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y")]
            let graph = UnindexedGraph(vertices: ["a", "b", "x", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [String] = ["a", "b"]
            let right: [String] = ["x", "y"]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y")]
            let graph = AdjacencyList(vertices: ["a", "b", "x", "y"] as [String], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [String] = ["a", "b"]
            let right: [String] = ["x", "y"]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-060 string vertices: triangle a, b, c, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected")
    func bp060() throws {
        // V [c, b, a]; E [a–b, b–c, c–a]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a")]
            let graph = UndirectedAdjacencyList(vertices: ["c", "b", "a"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == ["c", "b", "a"])
            #expect(cycle.edges == [1, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a")]
            let graph = UnindexedGraph(vertices: ["c", "b", "a"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == ["c", "b", "a"])
            #expect(cycle.edges == [1, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a")]
            let graph = AdjacencyList(vertices: ["c", "b", "a"] as [String], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == ["c", "b", "a"])
            #expect(cycle.edges == [1, 0, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-061 tree (caterpillar), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp061() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 1–4, 2–5, 3–6, 3–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5), (3, 6), (3, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 7]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5), (3, 6), (3, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 7]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5), (3, 6), (3, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 7]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5), (3, 6), (3, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4, 6, 7]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-062 Möbius ladder M8 (not bipartite), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp062() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–0, 0–4, 1–5, 2–6, 3–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (0, 4), (1, 5), (2, 6), (3, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 7])
            #expect(cycle.edges == [0, 1, 2, 11, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (0, 4), (1, 5), (2, 6), (3, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 7])
            #expect(cycle.edges == [0, 1, 2, 11, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: rows successors then predecessors, so another cycle
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (0, 4), (1, 5), (2, 6), (3, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges == [0, 1, 2, 3, 8])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (0, 4), (1, 5), (2, 6), (3, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2, 3, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [0, 4]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-063 Möbius ladder M6 = K3,3, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp063() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–3, 1–4, 2–5]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (1, 4), (2, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (1, 4), (2, 5)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (1, 4), (2, 5)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (1, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2, 4]
            let right: [Int] = [1, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-064 prism C3 × K2, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp064() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–0, 3–4, 4–5, 5–3, 0–3, 1–4, 2–5]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (0, 3), (1, 4), (2, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (0, 3), (1, 4), (2, 5)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (0, 3), (1, 4), (2, 5)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (0, 3), (1, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-065 cube with one edge subdivided twice, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp065() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7, 0–8, 8–9, 9–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 9), (9, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 14)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6, 9]
            let right: [Int] = [1, 2, 4, 7, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 9), (9, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6, 9]
            let right: [Int] = [1, 2, 4, 7, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 9), (9, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6, 9]
            let right: [Int] = [1, 2, 4, 7, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 9), (9, 1)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 5, 6, 9]
            let right: [Int] = [1, 2, 4, 7, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-066 cube with one edge subdivided once, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp066() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7, 0–8, 8–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 13)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 2, 3, 1, 8])
            #expect(cycle.edges == [0, 4, 2, 12, 11])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 2, 3, 1, 8])
            #expect(cycle.edges == [0, 4, 2, 12, 11])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 2, 3, 1, 8])
            #expect(cycle.edges == [0, 4, 2, 12, 11])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 1)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 2, 3, 1, 8])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 2], [2, 3], [1, 3], [8, 1], [0, 8]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-067 odd cycle deep in a BFS tree, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp067() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–9, 9–5]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [5, 6, 7, 8, 9])
            #expect(cycle.edges == [5, 6, 7, 8, 9])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 5)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [5, 6, 7, 8, 9])
            #expect(cycle.edges == [5, 6, 7, 8, 9])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 5)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [5, 6, 7, 8, 9])
            #expect(cycle.edges == [5, 6, 7, 8, 9])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 5)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [5, 6, 7, 8, 9])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[5, 6], [6, 7], [7, 8], [8, 9], [9, 5]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-068 two odd cycles; the one met first is later in vertex order, on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp068() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–7, 7–6, 6–0, 1–2, 2–3, 3–1, 0–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 7), (7, 6), (6, 0), (1, 2), (2, 3), (3, 1), (0, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 7, 6])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 7), (7, 6), (6, 0), (1, 2), (2, 3), (3, 1), (0, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 7, 6])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 7), (7, 6), (6, 0), (1, 2), (2, 3), (3, 1), (0, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 7, 6])
            #expect(cycle.edges == [0, 1, 2])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 7), (7, 6), (6, 0), (1, 2), (2, 3), (3, 1), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 7, 6])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 7], [7, 6], [6, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-069 directed path 0→1→2, on AdjacencyMatrix.undirected")
    func bp069() throws {
        // digraph V [0, 1, 2]; E [0–1, 1–2]
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-070 directed 2-cycle 0⇄1 (a parallel pair once undirected), on AdjacencyMatrix.undirected")
    func bp070() throws {
        // digraph V [0, 1]; E [0–1, 1–0]
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0]
            let right: [Int] = [1]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-071 directed triangle 0→1→2→0, on AdjacencyMatrix.undirected")
    func bp071() throws {
        // digraph V [0, 1, 2]; E [0–1, 1–2, 2–0]
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-072 transitive triangle 0→1, 0→2, 1→2, on AdjacencyMatrix.undirected")
    func bp072() throws {
        // digraph V [0, 1, 2]; E [0–1, 0–2, 1–2]
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 2])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [0, 2]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-073 directed self-loop, on AdjacencyMatrix.undirected")
    func bp073() throws {
        // digraph V [0, 1]; E [0–1, 1–1]
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[1, 1]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 1 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-074 directed C4 with all arcs into 0 and 2, on AdjacencyMatrix.undirected")
    func bp074() throws {
        // digraph V [0, 1, 2, 3]; E [1–0, 3–0, 1–2, 3–2]
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(1, 0), (3, 0), (1, 2), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 2]
            let right: [Int] = [1, 3]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-075 random bipartite #1 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp075() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [3–1, 4–1, 6–1, 5–1, 6–2, 3–2, 5–2, 0–2, 0–1, 4–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(3, 1), (4, 1), (6, 1), (5, 1), (6, 2), (3, 2), (5, 2), (0, 2), (0, 1), (4, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4, 5, 6]
            let right: [Int] = [1, 2]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(3, 1), (4, 1), (6, 1), (5, 1), (6, 2), (3, 2), (5, 2), (0, 2), (0, 1), (4, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4, 5, 6]
            let right: [Int] = [1, 2]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(3, 1), (4, 1), (6, 1), (5, 1), (6, 2), (3, 2), (5, 2), (0, 2), (0, 1), (4, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4, 5, 6]
            let right: [Int] = [1, 2]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(3, 1), (4, 1), (6, 1), (5, 1), (6, 2), (3, 2), (5, 2), (0, 2), (0, 1), (4, 2)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4, 5, 6]
            let right: [Int] = [1, 2]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-076 random G(n, m) #1 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp076() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–3, 6–7, 4–8, 3–8, 1–6, 1–8, 1–7, 0–7, 2–6, 2–4, 1–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (6, 7), (4, 8), (3, 8), (1, 6), (1, 8), (1, 7), (0, 7), (2, 6), (2, 4), (1, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 11)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 8, 1, 7])
            #expect(cycle.edges == [0, 3, 5, 6, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 3), (6, 7), (4, 8), (3, 8), (1, 6), (1, 8), (1, 7), (0, 7), (2, 6), (2, 4), (1, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 8, 1, 7])
            #expect(cycle.edges == [0, 3, 5, 6, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 3), (6, 7), (4, 8), (3, 8), (1, 6), (1, 8), (1, 7), (0, 7), (2, 6), (2, 4), (1, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 8, 1, 7])
            #expect(cycle.edges == [0, 3, 5, 6, 7])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 3), (6, 7), (4, 8), (3, 8), (1, 6), (1, 8), (1, 7), (0, 7), (2, 6), (2, 4), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 3, 8, 1, 7])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 3], [3, 8], [1, 8], [1, 7], [0, 7]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-077 random bipartite #2 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp077() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–7, 3–7, 1–2, 4–7, 3–2, 4–2, 6–7, 5–2, 1–7, 6–2, 0–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 7), (3, 7), (1, 2), (4, 7), (3, 2), (4, 2), (6, 7), (5, 2), (1, 7), (6, 2), (0, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 11)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 5, 6]
            let right: [Int] = [2, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 7), (3, 7), (1, 2), (4, 7), (3, 2), (4, 2), (6, 7), (5, 2), (1, 7), (6, 2), (0, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 5, 6]
            let right: [Int] = [2, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 7), (3, 7), (1, 2), (4, 7), (3, 2), (4, 2), (6, 7), (5, 2), (1, 7), (6, 2), (0, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 5, 6]
            let right: [Int] = [2, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 7), (3, 7), (1, 2), (4, 7), (3, 2), (4, 2), (6, 7), (5, 2), (1, 7), (6, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 3, 4, 5, 6]
            let right: [Int] = [2, 7]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-078 random G(n, m) #2 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp078() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 3–7, 4–6, 5–8, 1–6, 7–8, 2–4, 1–5, 2–8, 2–5, 2–6, 4–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (3, 7), (4, 6), (5, 8), (1, 6), (7, 8), (2, 4), (1, 5), (2, 8), (2, 5), (2, 6), (4, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 4, 6])
            #expect(cycle.edges == [6, 2, 10])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 1), (3, 7), (4, 6), (5, 8), (1, 6), (7, 8), (2, 4), (1, 5), (2, 8), (2, 5), (2, 6), (4, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 4, 6])
            #expect(cycle.edges == [6, 2, 10])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 1), (3, 7), (4, 6), (5, 8), (1, 6), (7, 8), (2, 4), (1, 5), (2, 8), (2, 5), (2, 6), (4, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 4, 6])
            #expect(cycle.edges == [6, 2, 10])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 1), (3, 7), (4, 6), (5, 8), (1, 6), (7, 8), (2, 4), (1, 5), (2, 8), (2, 5), (2, 6), (4, 7)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [2, 5, 8])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[2, 5], [5, 8], [2, 8]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-079 random bipartite #3 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp079() throws {
        // V [0, 1, 2, 3, 4, 5]; E [3–2, 0–5, 0–1, 3–1]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(3, 2), (0, 5), (0, 1), (3, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4]
            let right: [Int] = [1, 2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(3, 2), (0, 5), (0, 1), (3, 1)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4]
            let right: [Int] = [1, 2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(3, 2), (0, 5), (0, 1), (3, 1)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4]
            let right: [Int] = [1, 2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(3, 2), (0, 5), (0, 1), (3, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 3, 4]
            let right: [Int] = [1, 2, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-080 random G(n, m) #3 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp080() throws {
        // V [0, 1, 2, 3, 4, 5]; E [4–5, 0–5, 3–4, 2–3, 1–5, 0–2]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(4, 5), (0, 5), (3, 4), (2, 3), (1, 5), (0, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 5, 4, 3, 2])
            #expect(cycle.edges == [1, 0, 2, 3, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(4, 5), (0, 5), (3, 4), (2, 3), (1, 5), (0, 2)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 5, 4, 3, 2])
            #expect(cycle.edges == [1, 0, 2, 3, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(4, 5), (0, 5), (3, 4), (2, 3), (1, 5), (0, 2)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 5, 4, 3, 2])
            #expect(cycle.edges == [1, 0, 2, 3, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(4, 5), (0, 5), (3, 4), (2, 3), (1, 5), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 2, 3, 4, 5])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 2], [2, 3], [3, 4], [4, 5], [0, 5]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 5 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-081 random bipartite #4 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp081() throws {
        // V [0, 1, 2, 3, 4, 5]; E [2–1, 3–4, 5–1, 5–4]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(2, 1), (3, 4), (5, 1), (5, 4)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 4]
            let right: [Int] = [2, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(2, 1), (3, 4), (5, 1), (5, 4)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 4]
            let right: [Int] = [2, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(2, 1), (3, 4), (5, 1), (5, 4)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 4]
            let right: [Int] = [2, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(2, 1), (3, 4), (5, 1), (5, 4)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 4]
            let right: [Int] = [2, 3, 5]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-082 random G(n, m) #4 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp082() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [6–7, 1–6, 0–7, 1–2, 1–5, 1–7, 3–7, 2–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(6, 7), (1, 6), (0, 7), (1, 2), (1, 5), (1, 7), (3, 7), (2, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1, 6, 7])
            #expect(cycle.edges == [1, 0, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(6, 7), (1, 6), (0, 7), (1, 2), (1, 5), (1, 7), (3, 7), (2, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1, 6, 7])
            #expect(cycle.edges == [1, 0, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(6, 7), (1, 6), (0, 7), (1, 2), (1, 5), (1, 7), (3, 7), (2, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1, 6, 7])
            #expect(cycle.edges == [1, 0, 5])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(6, 7), (1, 6), (0, 7), (1, 2), (1, 5), (1, 7), (3, 7), (2, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [1, 2, 7])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[1, 2], [2, 7], [1, 7]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }

    @Test("BP-083 random bipartite #5 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp083() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [5–0, 4–2, 4–1, 5–1, 8–1, 5–3, 8–0, 8–6, 8–3, 4–9, 8–2, 5–2, 8–9]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(5, 0), (4, 2), (4, 1), (5, 1), (8, 1), (5, 3), (8, 0), (8, 6), (8, 3), (4, 9), (8, 2), (5, 2), (8, 9)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 13)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3, 6, 7, 9]
            let right: [Int] = [4, 5, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(5, 0), (4, 2), (4, 1), (5, 1), (8, 1), (5, 3), (8, 0), (8, 6), (8, 3), (4, 9), (8, 2), (5, 2), (8, 9)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3, 6, 7, 9]
            let right: [Int] = [4, 5, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by position in `vertices`.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(5, 0), (4, 2), (4, 1), (5, 1), (8, 1), (5, 3), (8, 0), (8, 6), (8, 3), (4, 9), (8, 2), (5, 2), (8, 9)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3, 6, 7, 9]
            let right: [Int] = [4, 5, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(5, 0), (4, 2), (4, 1), (5, 1), (8, 1), (5, 3), (8, 0), (8, 6), (8, 3), (4, 9), (8, 2), (5, 2), (8, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.isBipartite)
            #expect(graph.findOddCycle() == nil)
            let bipartition = try #require(graph.bipartition())
            let left: [Int] = [0, 1, 2, 3, 6, 7, 9]
            let right: [Int] = [4, 5, 8]
            #expect(Array(bipartition.left) == left)
            #expect(Array(bipartition.right) == right)
            for v in left { #expect(bipartition.side(of: v) == .left) }
            for v in right { #expect(bipartition.side(of: v) == .right) }
            // side(ofIndex:) by vertex index.
            for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
            for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.left) == left)
            #expect(Array(bipartite.right) == right)
        }
    }

    @Test("BP-084 random G(n, m) #5 (seed 20261009), on UndirectedAdjacencyList, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func bp084() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–4, 0–1, 2–6, 3–5, 6–7, 1–4, 3–7, 0–5, 1–2, 2–5, 1–7]
        do { // UndirectedAdjacencyList: the catalog's values
            let pairs: [(Int, Int)] = [(0, 4), (0, 1), (2, 6), (3, 5), (6, 7), (1, 4), (3, 7), (0, 5), (1, 2), (2, 5), (1, 7)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 11)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 1])
            #expect(cycle.edges == [0, 5, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // No vertex or edge indices: the catalog's values
            let pairs: [(Int, Int)] = [(0, 4), (0, 1), (2, 6), (3, 5), (6, 7), (1, 4), (3, 7), (0, 5), (1, 2), (2, 5), (1, 7)]
            let graph = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 1])
            #expect(cycle.edges == [0, 5, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyList.undirected, each edge an arc as written: the catalog's values
            let arcs: [(Int, Int)] = [(0, 4), (0, 1), (2, 6), (3, 5), (6, 7), (1, 4), (3, 7), (0, 5), (1, 2), (2, 5), (1, 7)]
            let graph = AdjacencyList(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 4, 1])
            #expect(cycle.edges == [0, 5, 1])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
        do { // AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors
            let arcs: [(Int, Int)] = [(0, 4), (0, 1), (2, 6), (3, 5), (6, 7), (1, 4), (3, 7), (0, 5), (1, 2), (2, 5), (1, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(!graph.isBipartite)
            #expect(graph.bipartition() == nil)
            #expect(BipartiteGraph(graph) == nil)
            let cycle = try #require(graph.findOddCycle())
            #expect(cycle.vertices == [0, 1, 4])
            #expect(cycle.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 4], [0, 4]])
            // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
            let k = cycle.vertices.count
            #expect(k == 3 && k % 2 == 1)
            #expect(Set(cycle.vertices).count == k)
            #expect(Set(cycle.edges).count == k)
            for i in 0 ..< k {
                let edge = graph.edges[cycle.edges[i]]
                #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
            }
            #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        }
    }
}
