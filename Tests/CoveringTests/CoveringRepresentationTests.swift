// The graph rows of the catalog again on other representations. Rows on `UndirectedAdjacencyList`
// run again on `ReferencePseudograph`; `BipartiteGraph` rows on an `UndirectedAdjacencyList` and a
// `ReferencePseudograph` with the same vertices and edges; every row on a file-private conformer
// with no vertex or edge indices; all with the catalog's values, since their rows are in position
// order too. Then on `AdjacencyList.undirected` with each edge an arc as written, and on
// `AdjacencyMatrix.undirected` with the arcs at their row-major cells (rows on 0..<n with no arc
// twice). Every vertex-set result is the catalog's on every representation (they depend on the
// vertex order and the adjacency only, or, for `approximateMinimumVertexCover`, on the edge order,
// which `AdjacencyList` keeps). Through `.undirected` a row is successors, then predecessors, and
// matrix positions are cells: the edge covers there, and the vertex-cover approximation on the
// matrix, were computed by swiftgen.py with ref.py's models on those rows and positions. Matrix
// positions are compared as [source, target]. Matching rows run through `bipartition()`, the
// canonical sides. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import Covering
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Testing

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

@Suite("Catalog graph rows on every representation")
struct CoveringRepresentationTests {
    @Test("CV-001 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv001() {
        // V []; E []; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-002 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv002() {
        // V [0]; E []; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-003 one vertex with a self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv003() {
        // V [0]; E [0-0]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-004 two isolated vertices, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv004() {
        // V [0, 1]; E []; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-005 one edge: the lesser end, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv005() {
        // V [0, 1]; E [0-1]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-006 self-loop excludes its vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv006() {
        // V [0, 1]; E [0-0, 0-1]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let result = graph.maximumIndependentSet()
            #expect(result == [1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let result = graph.maximumIndependentSet()
            #expect(result == [1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let result = graph.maximumIndependentSet()
            #expect(result == [1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let result = graph.maximumIndependentSet()
            #expect(result == [1] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-007 parallel edges count once, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv007() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; maximumIndependentSet()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-008 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv008() {
        // K(3); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-009 K(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv009() {
        // K(5); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-010 path P(2), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv010() {
        // P(2); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.maximumIndependentSet()
            #expect(result == [0] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-011 path P(4): {0,2} beats {0,3}, {1,3}, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv011() {
        // P(4); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-012 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv012() {
        // P(5); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-013 path P(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv013() {
        // P(6); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-014 cycle C(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv014() {
        // C(4); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-015 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv015() {
        // C(5); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-016 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv016() {
        // C(6); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-017 cycle C(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv017() {
        // C(7); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-018 star(4): the leaves, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv018() {
        // star(4); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-019 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv019() {
        // wheel(5); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-020 wheel(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv020() {
        // wheel(6); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-021 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv021() {
        // nx(petersen_graph); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 8, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 8, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 8, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 8, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-022 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv022() {
        // grid(3,4); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 7, 8, 10] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 7, 8, 10] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 7, 8, 10] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 7, 8, 10] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-023 grid(5,5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv023() {
        // grid(5,5); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (15, 20), (16, 17), (16, 21), (17, 18), (17, 22), (18, 19), (18, 23), (19, 24), (20, 21), (21, 22), (22, 23), (23, 24)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (15, 20), (16, 17), (16, 21), (17, 18), (17, 22), (18, 19), (18, 23), (19, 24), (20, 21), (21, 22), (22, 23), (23, 24)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (15, 20), (16, 17), (16, 21), (17, 18), (17, 22), (18, 19), (18, 23), (19, 24), (20, 21), (21, 22), (22, 23), (23, 24)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (15, 20), (16, 17), (16, 21), (17, 18), (17, 22), (18, 19), (18, 23), (19, 24), (20, 21), (21, 22), (22, 23), (23, 24)]
            let graph = AdjacencyMatrix(vertexCount: 25, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-024 Kb(2,3) as BipartiteGraph, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv024() {
        // Kb(2,3); maximumIndependentSet()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [2, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-025 Kb(3,3), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv025() {
        // Kb(3,3); maximumIndependentSet()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 9)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-026 mixed components: triangle, path, looped pendant, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv026() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 7] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 7] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 7] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 7] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-027 vertex order, not label order, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func cv027() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == ["d", "c"] as [String])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == ["d", "c"] as [String])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.maximumIndependentSet()
            #expect(result == ["d", "c"] as [String])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-028 bipartite, interleaved vertex order, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv028() {
        // V [0, 1, 2, 3, 4, 5]; E [0-3, 3-1, 1-4, 4-2, 2-5]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (3, 1), (1, 4), (4, 2), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (3, 1), (1, 4), (4, 2), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (3, 1), (1, 4), (4, 2), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (3, 1), (1, 4), (4, 2), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-029 bipartite core: perfect matching, lattice choice, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv029() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-3, 3-0, 0-5, 4-5]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 5), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 5), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 5), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-030 odd cycle with pendant, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv030() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-3, 3-4, 4-0, 2-5]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-031 all vertices looped, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv031() {
        // V [0, 1, 2]; E [0-0, 1-1, 2-2, 0-1]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 1), (2, 2), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 1), (2, 2), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 1), (2, 2), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (1, 1), (2, 2), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.maximumIndependentSet()
            #expect(result == [] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-032 loop in a bipartite piece splits it, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv032() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-4, 2-2]; maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (2, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (2, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (2, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-033 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv033() {
        // nx(bull_graph); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 4] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-034 nx(house_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv034() {
        // nx(house_graph); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-035 nx(krackhardt_kite_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv035() {
        // nx(krackhardt_kite_graph); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 4, 7, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 4, 7, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 4, 7, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 4, 7, 9] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-036 nx(frucht_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv036() {
        // nx(frucht_graph); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 9, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 9, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 9, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 2, 5, 9, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-037 lcg(12,20,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv037() {
        // lcg(12,20,1); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 5, 8, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 5, 8, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 5, 8, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let result = graph.maximumIndependentSet()
            #expect(result == [1, 2, 3, 5, 8, 11] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-038 lcg(16,30,2), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv038() {
        // lcg(16,30,2); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 8, 11, 13, 14] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 8, 11, 13, 14] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 8, 11, 13, 14] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 3, 5, 8, 11, 13, 14] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-039 lcg(24,40,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv039() {
        // lcg(24,40,3); maximumIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 19), (11, 10), (12, 11), (7, 5), (17, 9), (19, 18), (8, 21), (22, 17), (3, 19), (7, 8), (5, 22), (11, 18), (5, 11), (13, 6), (23, 7), (17, 0), (9, 15), (12, 19), (7, 21), (12, 22), (12, 17), (5, 1), (13, 2), (5, 10), (10, 17), (23, 10), (8, 5), (19, 14), (1, 13), (11, 3), (11, 1), (23, 3), (12, 18), (11, 14), (21, 12), (2, 14), (12, 15), (21, 1), (21, 3), (12, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 19), (11, 10), (12, 11), (7, 5), (17, 9), (19, 18), (8, 21), (22, 17), (3, 19), (7, 8), (5, 22), (11, 18), (5, 11), (13, 6), (23, 7), (17, 0), (9, 15), (12, 19), (7, 21), (12, 22), (12, 17), (5, 1), (13, 2), (5, 10), (10, 17), (23, 10), (8, 5), (19, 14), (1, 13), (11, 3), (11, 1), (23, 3), (12, 18), (11, 14), (21, 12), (2, 14), (12, 15), (21, 1), (21, 3), (12, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 19), (11, 10), (12, 11), (7, 5), (17, 9), (19, 18), (8, 21), (22, 17), (3, 19), (7, 8), (5, 22), (11, 18), (5, 11), (13, 6), (23, 7), (17, 0), (9, 15), (12, 19), (7, 21), (12, 22), (12, 17), (5, 1), (13, 2), (5, 10), (10, 17), (23, 10), (8, 5), (19, 14), (1, 13), (11, 3), (11, 1), (23, 3), (12, 18), (11, 14), (21, 12), (2, 14), (12, 15), (21, 1), (21, 3), (12, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 19), (11, 10), (12, 11), (7, 5), (17, 9), (19, 18), (8, 21), (22, 17), (3, 19), (7, 8), (5, 22), (11, 18), (5, 11), (13, 6), (23, 7), (17, 0), (9, 15), (12, 19), (7, 21), (12, 22), (12, 17), (5, 1), (13, 2), (5, 10), (10, 17), (23, 10), (8, 5), (19, 14), (1, 13), (11, 3), (11, 1), (23, 3), (12, 18), (11, 14), (21, 12), (2, 14), (12, 15), (21, 1), (21, 3), (12, 0)]
            let graph = AdjacencyMatrix(vertexCount: 24, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let result = graph.maximumIndependentSet()
            #expect(result == [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-040 lcgb(6,7,15,4) as BipartiteGraph, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv040() {
        // lcgb(6,7,15,4); maximumIndependentSet()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [4, 6, 8, 9, 10, 11, 12] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [4, 6, 8, 9, 10, 11, 12] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [4, 6, 8, 9, 10, 11, 12] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [4, 6, 8, 9, 10, 11, 12] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = AdjacencyMatrix(vertexCount: 13, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.maximumIndependentSet()
            #expect(result == [4, 6, 8, 9, 10, 11, 12] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-041 lcgb(10,10,25,5), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv041() {
        // lcgb(10,10,25,5); maximumIndependentSet()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 25)
            let result = graph.maximumIndependentSet()
            #expect(result == [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 25)
            let result = graph.maximumIndependentSet()
            #expect(result == [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 25)
            let result = graph.maximumIndependentSet()
            #expect(result == [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 25)
            let result = graph.maximumIndependentSet()
            #expect(result == [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] as [Int])
            #expect(graph.isIndependentSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 25)
            let result = graph.maximumIndependentSet()
            #expect(result == [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] as [Int])
            #expect(graph.isIndependentSet(result))
        }
    }

    @Test("CV-042 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv042() {
        // V []; E []; independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.independenceNumber() == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.independenceNumber() == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.independenceNumber() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.independenceNumber() == 0)
        }
    }

    @Test("CV-043 one vertex with a self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv043() {
        // V [0]; E [0-0]; independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.independenceNumber() == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.independenceNumber() == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.independenceNumber() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.independenceNumber() == 0)
        }
    }

    @Test("CV-044 C(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv044() {
        // C(7); independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            #expect(graph.independenceNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            #expect(graph.independenceNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            #expect(graph.independenceNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            #expect(graph.independenceNumber() == 3)
        }
    }

    @Test("CV-045 Petersen: 4, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv045() {
        // nx(petersen_graph); independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 4)
        }
    }

    @Test("CV-046 K(6): 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv046() {
        // K(6); independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.independenceNumber() == 1)
        }
    }

    @Test("CV-047 grid(4,4): 8, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv047() {
        // grid(4,4); independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            #expect(graph.independenceNumber() == 8)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            #expect(graph.independenceNumber() == 8)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            #expect(graph.independenceNumber() == 8)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            #expect(graph.independenceNumber() == 8)
        }
    }

    @Test("CV-048 nx(dodecahedral_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv048() {
        // nx(dodecahedral_graph); independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            #expect(graph.independenceNumber() == 8)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            #expect(graph.independenceNumber() == 8)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.independenceNumber() == 8)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.independenceNumber() == 8)
        }
    }

    @Test("CV-049 lcg(20,45,6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv049() {
        // lcg(20,45,6); independenceNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 2), (13, 19), (4, 15), (6, 16), (14, 19), (15, 14), (10, 6), (15, 0), (3, 1), (3, 4), (17, 19), (5, 16), (11, 6), (12, 14), (8, 0), (17, 8), (0, 17), (14, 11), (3, 7), (0, 2), (15, 10), (7, 2), (6, 1), (6, 2), (16, 15), (19, 1), (14, 4), (10, 9), (8, 4), (17, 11), (0, 6), (5, 2), (13, 8), (8, 11), (7, 9), (1, 13), (16, 10), (13, 5), (17, 2), (10, 5), (19, 3), (9, 14), (9, 13), (5, 14), (17, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 45)
            #expect(graph.independenceNumber() == 8)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 2), (13, 19), (4, 15), (6, 16), (14, 19), (15, 14), (10, 6), (15, 0), (3, 1), (3, 4), (17, 19), (5, 16), (11, 6), (12, 14), (8, 0), (17, 8), (0, 17), (14, 11), (3, 7), (0, 2), (15, 10), (7, 2), (6, 1), (6, 2), (16, 15), (19, 1), (14, 4), (10, 9), (8, 4), (17, 11), (0, 6), (5, 2), (13, 8), (8, 11), (7, 9), (1, 13), (16, 10), (13, 5), (17, 2), (10, 5), (19, 3), (9, 14), (9, 13), (5, 14), (17, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 45)
            #expect(graph.independenceNumber() == 8)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 2), (13, 19), (4, 15), (6, 16), (14, 19), (15, 14), (10, 6), (15, 0), (3, 1), (3, 4), (17, 19), (5, 16), (11, 6), (12, 14), (8, 0), (17, 8), (0, 17), (14, 11), (3, 7), (0, 2), (15, 10), (7, 2), (6, 1), (6, 2), (16, 15), (19, 1), (14, 4), (10, 9), (8, 4), (17, 11), (0, 6), (5, 2), (13, 8), (8, 11), (7, 9), (1, 13), (16, 10), (13, 5), (17, 2), (10, 5), (19, 3), (9, 14), (9, 13), (5, 14), (17, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 45)
            #expect(graph.independenceNumber() == 8)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 2), (13, 19), (4, 15), (6, 16), (14, 19), (15, 14), (10, 6), (15, 0), (3, 1), (3, 4), (17, 19), (5, 16), (11, 6), (12, 14), (8, 0), (17, 8), (0, 17), (14, 11), (3, 7), (0, 2), (15, 10), (7, 2), (6, 1), (6, 2), (16, 15), (19, 1), (14, 4), (10, 9), (8, 4), (17, 11), (0, 6), (5, 2), (13, 8), (8, 11), (7, 9), (1, 13), (16, 10), (13, 5), (17, 2), (10, 5), (19, 3), (9, 14), (9, 13), (5, 14), (17, 5)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 45)
            #expect(graph.independenceNumber() == 8)
        }
    }

    @Test("CV-050 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv050() {
        // V []; E []; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-051 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv051() {
        // V [0]; E []; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-052 self-loop: its vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv052() {
        // V [0]; E [0-0]; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-053 one edge: the greater end, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv053() {
        // V [0, 1]; E [0-1]; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-054 loop and edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv054() {
        // V [0, 1]; E [0-0, 0-1]; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-055 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv055() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumVertexCover()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-056 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv056() {
        // K(3); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-057 K(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv057() {
        // K(4); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-058 P(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv058() {
        // P(4); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-059 C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv059() {
        // C(5); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-060 star(5): the hub, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv060() {
        // star(5); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-061 Petersen: 6, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv061() {
        // nx(petersen_graph); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-062 Kb(2,3): the left side, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv062() {
        // Kb(2,3); minimumVertexCover()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-063 Kb(3,2): the right side, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv063() {
        // Kb(3,2); minimumVertexCover()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (1, 4), (2, 3), (2, 4)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (1, 4), (2, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (1, 4), (2, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (1, 4), (2, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (1, 4), (2, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-064 L [0,1,2]; R [3,4,5]: lex vs Koenig, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv064() {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; minimumVertexCover()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumVertexCover()
            #expect(cover == [3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-065 BipartiteGraph with an isolated right vertex, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv065() {
        // L [0, 1]; R [2, 3, 4]; E [0-2, 1-2, 1-3]; minimumVertexCover()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (1, 3)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (1, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (1, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (1, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (1, 3)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == [2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-066 lcgb(8,6,18,7), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv066() {
        // lcgb(8,6,18,7); minimumVertexCover()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(6, 13), (1, 13), (0, 8), (3, 12), (3, 11), (0, 10), (5, 12), (5, 11), (4, 13), (0, 9), (6, 8), (5, 8), (0, 13), (6, 9), (5, 13), (1, 9), (4, 8), (4, 10)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 18)
            let cover = graph.minimumVertexCover()
            #expect(cover == [8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(6, 13), (1, 13), (0, 8), (3, 12), (3, 11), (0, 10), (5, 12), (5, 11), (4, 13), (0, 9), (6, 8), (5, 8), (0, 13), (6, 9), (5, 13), (1, 9), (4, 8), (4, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 18)
            let cover = graph.minimumVertexCover()
            #expect(cover == [8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(6, 13), (1, 13), (0, 8), (3, 12), (3, 11), (0, 10), (5, 12), (5, 11), (4, 13), (0, 9), (6, 8), (5, 8), (0, 13), (6, 9), (5, 13), (1, 9), (4, 8), (4, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 18)
            let cover = graph.minimumVertexCover()
            #expect(cover == [8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(6, 13), (1, 13), (0, 8), (3, 12), (3, 11), (0, 10), (5, 12), (5, 11), (4, 13), (0, 9), (6, 8), (5, 8), (0, 13), (6, 9), (5, 13), (1, 9), (4, 8), (4, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let cover = graph.minimumVertexCover()
            #expect(cover == [8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(6, 13), (1, 13), (0, 8), (3, 12), (3, 11), (0, 10), (5, 12), (5, 11), (4, 13), (0, 9), (6, 8), (5, 8), (0, 13), (6, 9), (5, 13), (1, 9), (4, 8), (4, 10)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let cover = graph.minimumVertexCover()
            #expect(cover == [8, 9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-067 grid(4,5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv067() {
        // grid(4,5); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 31)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 31)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 31)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 31)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-068 mixed components, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv068() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7]; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 4, 6] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 4, 6] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 4, 6] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let cover = graph.minimumVertexCover()
            #expect(cover == [1, 2, 4, 6] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-069 letters, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func cv069() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == ["a", "b"] as [String])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == ["a", "b"] as [String])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumVertexCover()
            #expect(cover == ["a", "b"] as [String])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-070 lcg(18,35,8), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv070() {
        // lcg(18,35,8); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(4, 6), (14, 7), (14, 5), (16, 5), (1, 11), (9, 1), (2, 7), (13, 14), (12, 5), (6, 0), (11, 15), (16, 4), (3, 10), (4, 7), (11, 9), (16, 15), (6, 16), (0, 12), (15, 13), (12, 15), (17, 0), (2, 5), (1, 17), (15, 10), (11, 6), (15, 3), (10, 4), (8, 14), (5, 1), (4, 11), (11, 7), (15, 9), (10, 9), (5, 4), (13, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 35)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1, 5, 6, 7, 10, 11, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(4, 6), (14, 7), (14, 5), (16, 5), (1, 11), (9, 1), (2, 7), (13, 14), (12, 5), (6, 0), (11, 15), (16, 4), (3, 10), (4, 7), (11, 9), (16, 15), (6, 16), (0, 12), (15, 13), (12, 15), (17, 0), (2, 5), (1, 17), (15, 10), (11, 6), (15, 3), (10, 4), (8, 14), (5, 1), (4, 11), (11, 7), (15, 9), (10, 9), (5, 4), (13, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 35)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1, 5, 6, 7, 10, 11, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(4, 6), (14, 7), (14, 5), (16, 5), (1, 11), (9, 1), (2, 7), (13, 14), (12, 5), (6, 0), (11, 15), (16, 4), (3, 10), (4, 7), (11, 9), (16, 15), (6, 16), (0, 12), (15, 13), (12, 15), (17, 0), (2, 5), (1, 17), (15, 10), (11, 6), (15, 3), (10, 4), (8, 14), (5, 1), (4, 11), (11, 7), (15, 9), (10, 9), (5, 4), (13, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 35)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1, 5, 6, 7, 10, 11, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(4, 6), (14, 7), (14, 5), (16, 5), (1, 11), (9, 1), (2, 7), (13, 14), (12, 5), (6, 0), (11, 15), (16, 4), (3, 10), (4, 7), (11, 9), (16, 15), (6, 16), (0, 12), (15, 13), (12, 15), (17, 0), (2, 5), (1, 17), (15, 10), (11, 6), (15, 3), (10, 4), (8, 14), (5, 1), (4, 11), (11, 7), (15, 9), (10, 9), (5, 4), (13, 5)]
            let graph = AdjacencyMatrix(vertexCount: 18, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 35)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 1, 5, 6, 7, 10, 11, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-071 wheel(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv071() {
        // wheel(7); minimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 14)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 2, 4, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 14)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 2, 4, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 14)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 2, 4, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 14)
            let cover = graph.minimumVertexCover()
            #expect(cover == [0, 2, 4, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-072 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv072() throws {
        // V []; E []; left [], right []; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-073 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv073() throws {
        // V [0, 1]; E [0-1]; left [0], right [1]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-074 P(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv074() throws {
        // P(4); left [0, 2], right [1, 3]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-075 P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv075() throws {
        // P(5); left [0, 2, 4], right [1, 3]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-076 C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv076() throws {
        // C(6); left [0, 2, 4], right [1, 3, 5]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-077 star(3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv077() throws {
        // star(3); left [0], right [1, 2, 3]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-078 Kb(2,3), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv078() throws {
        // Kb(2,3); left [0, 1], right [2, 3, 4]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-079 L [0,1,2]; R [3,4,5], on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv079() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; left [0, 1, 2], right [3, 4, 5]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-080 grid(3,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv080() throws {
        // grid(3,3); left [0, 2, 4, 6, 8], right [1, 3, 5, 7]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4, 6, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3, 5, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4, 6, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3, 5, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4, 6, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3, 5, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 4, 6, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 3, 5, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-081 grid(4,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv081() throws {
        // grid(4,4); left [0, 2, 5, 7, 8, 10, 13, 15], right [1, 3, 4, 6, 9, 11, 12, 14]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-082 tree, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv082() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 1-3, 1-4, 2-5, 2-6]; left [0, 3, 4, 5, 6], right [1, 2]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 3, 4, 5, 6] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 3, 4, 5, 6] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 3, 4, 5, 6] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 3, 4, 5, 6] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-083 two components, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv083() throws {
        // V [0, 1, 2, 3, 4, 5]; E [1-0, 1-2, 3-4, 5-4]; left [0, 2, 3, 5], right [1, 4]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(1, 0), (1, 2), (3, 4), (5, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 3, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 0), (1, 2), (3, 4), (5, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 3, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(1, 0), (1, 2), (3, 4), (5, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 3, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 0), (1, 2), (3, 4), (5, 4)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2, 3, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-084 parallel edges, on no indices")
    func cv084() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2]; left [0, 2], right [1]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-085 lcgb(6,7,15,4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv085() throws {
        // lcgb(6,7,15,4); left [0, 1, 2, 3, 4, 5], right [6, 7, 8, 9, 10, 11, 12]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = AdjacencyMatrix(vertexCount: 13, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-086 lcgb(9,5,20,9), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv086() throws {
        // lcgb(9,5,20,9); left [0, 1, 2, 3, 4, 5, 6, 7, 8], right [9, 10, 11, 12, 13]; minimumVertexCover(bipartition: g.bipartition()!)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(8, 10), (2, 9), (7, 11), (2, 11), (0, 10), (5, 9), (0, 11), (2, 13), (5, 12), (5, 13), (8, 9), (1, 13), (4, 11), (8, 12), (6, 11), (3, 11), (4, 12), (3, 13), (8, 13), (7, 10)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(8, 10), (2, 9), (7, 11), (2, 11), (0, 10), (5, 9), (0, 11), (2, 13), (5, 12), (5, 13), (8, 9), (1, 13), (4, 11), (8, 12), (6, 11), (3, 11), (4, 12), (3, 13), (8, 13), (7, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(8, 10), (2, 9), (7, 11), (2, 11), (0, 10), (5, 9), (0, 11), (2, 13), (5, 12), (5, 13), (8, 9), (1, 13), (4, 11), (8, 12), (6, 11), (3, 11), (4, 12), (3, 13), (8, 13), (7, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(8, 10), (2, 9), (7, 11), (2, 11), (0, 10), (5, 9), (0, 11), (2, 13), (5, 12), (5, 13), (8, 9), (1, 13), (4, 11), (8, 12), (6, 11), (3, 11), (4, 12), (3, 13), (8, 13), (7, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(8, 10), (2, 9), (7, 11), (2, 11), (0, 10), (5, 9), (0, 11), (2, 13), (5, 12), (5, 13), (8, 9), (1, 13), (4, 11), (8, 12), (6, 11), (3, 11), (4, 12), (3, 13), (8, 13), (7, 10)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            let cover = graph.minimumVertexCover(bipartition: sides)
            #expect(cover == [9, 10, 11, 12, 13] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-087 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv087() {
        // V []; E []; approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-088 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv088() {
        // V [0, 1]; E [0-1]; approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-089 self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv089() {
        // V [0]; E [0-0]; approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-090 loop and edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv090() {
        // V [0, 1]; E [0-0, 0-1]; approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-091 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv091() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; approximateMinimumVertexCover()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-092 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv092() {
        // K(3); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-093 P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv093() {
        // P(5); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-094 C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv094() {
        // C(6); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-095 star(4): hub first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv095() {
        // star(4); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-096 star(4) leaves first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv096() {
        // V [0, 1, 2, 3, 4]; E [1-0, 2-0, 3-0, 4-0]; approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(1, 0), (2, 0), (3, 0), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 0), (2, 0), (3, 0), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(1, 0), (2, 0), (3, 0), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 0), (2, 0), (3, 0), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-097 K(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv097() {
        // K(5); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-098 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv098() {
        // nx(petersen_graph); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-099 positions not in NetworkX order, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv099() {
        // V [0, 1, 2, 3]; E [2-3, 0-1, 1-2]; approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 3), (0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 3), (0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 3), (0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 3), (0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-100 lcg(16,30,2), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv100() {
        // lcg(16,30,2); approximateMinimumVertexCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [1, 2, 3, 6, 7, 8, 10, 11, 12, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [1, 2, 3, 6, 7, 8, 10, 11, 12, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [1, 2, 3, 6, 7, 8, 10, 11, 12, 15] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let cover = graph.approximateMinimumVertexCover()
            #expect(cover == [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 12] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-101 one edge, heavier first end, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv101() {
        // V [0, 1]; E [0-1]; w [3, 1]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [3, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [3, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [3, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [3, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-102 equal weights: lesser index, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv102() {
        // V [0, 1]; E [0-1]; w [2, 2]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [2, 2]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [2, 2]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [2, 2]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let weights: [Int] = [2, 2]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-103 star, heavy hub, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv103() {
        // star(4); w [10, 1, 1, 1, 1]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [1, 2, 3, 4] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-104 star, light hub, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv104() {
        // star(4); w [1, 5, 5, 5, 5]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [1, 5, 5, 5, 5]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [1, 5, 5, 5, 5]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [1, 5, 5, 5, 5]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [1, 5, 5, 5, 5]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-105 path, residual costs carry, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv105() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-3]; w [2, 3, 2, 3]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 3, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 3, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 3, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 3, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-106 zero weights, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv106() {
        // C(4); w [0, 1, 0, 1]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [0, 1, 0, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [0, 1, 0, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [0, 1, 0, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [0, 1, 0, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 2] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-107 triangle weighted, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv107() {
        // K(3); w [1, 2, 3]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 2, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-108 self-loop weighted, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv108() {
        // V [0, 1]; E [0-0, 0-1]; w [5, 1]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let weights: [Int] = [5, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let weights: [Int] = [5, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let weights: [Int] = [5, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let weights: [Int] = [5, 1]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-109 float weights, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv109() {
        // V [0, 1, 2]; E [0-1, 1-2]; w [0.5, 0.75, 0.25]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let weights: [Double] = [0.5, 0.75, 0.25]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let weights: [Double] = [0.5, 0.75, 0.25]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let weights: [Double] = [0.5, 0.75, 0.25]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let weights: [Double] = [0.5, 0.75, 0.25]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-110 lcgv(12,20,3,9), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv110() {
        // lcgv(12,20,3,9); w [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 5, 6, 7, 9, 11] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 5, 6, 7, 9, 11] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 5, 6, 7, 9, 11] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2, 5, 7, 9, 11] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-111 lcgv(20,40,5,5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv111() {
        // lcgv(20,40,5,5); w [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]; approximateMinimumVertexCover(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(12, 13), (14, 5), (15, 11), (19, 9), (10, 4), (15, 14), (8, 11), (13, 17), (8, 3), (2, 0), (8, 2), (1, 14), (10, 9), (15, 13), (5, 9), (0, 1), (14, 18), (14, 16), (8, 14), (12, 0), (7, 16), (11, 17), (1, 12), (1, 5), (11, 18), (12, 10), (15, 19), (11, 12), (8, 9), (18, 0), (7, 1), (7, 2), (2, 17), (8, 6), (17, 14), (6, 15), (1, 3), (7, 3), (15, 18), (13, 7)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 40)
            let weights: [Int] = [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(12, 13), (14, 5), (15, 11), (19, 9), (10, 4), (15, 14), (8, 11), (13, 17), (8, 3), (2, 0), (8, 2), (1, 14), (10, 9), (15, 13), (5, 9), (0, 1), (14, 18), (14, 16), (8, 14), (12, 0), (7, 16), (11, 17), (1, 12), (1, 5), (11, 18), (12, 10), (15, 19), (11, 12), (8, 9), (18, 0), (7, 1), (7, 2), (2, 17), (8, 6), (17, 14), (6, 15), (1, 3), (7, 3), (15, 18), (13, 7)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 40)
            let weights: [Int] = [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(12, 13), (14, 5), (15, 11), (19, 9), (10, 4), (15, 14), (8, 11), (13, 17), (8, 3), (2, 0), (8, 2), (1, 14), (10, 9), (15, 13), (5, 9), (0, 1), (14, 18), (14, 16), (8, 14), (12, 0), (7, 16), (11, 17), (1, 12), (1, 5), (11, 18), (12, 10), (15, 19), (11, 12), (8, 9), (18, 0), (7, 1), (7, 2), (2, 17), (8, 6), (17, 14), (6, 15), (1, 3), (7, 3), (15, 18), (13, 7)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let weights: [Int] = [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(12, 13), (14, 5), (15, 11), (19, 9), (10, 4), (15, 14), (8, 11), (13, 17), (8, 3), (2, 0), (8, 2), (1, 14), (10, 9), (15, 13), (5, 9), (0, 1), (14, 18), (14, 16), (8, 14), (12, 0), (7, 16), (11, 17), (1, 12), (1, 5), (11, 18), (12, 10), (15, 19), (11, 12), (8, 9), (18, 0), (7, 1), (7, 2), (2, 17), (8, 6), (17, 14), (6, 15), (1, 3), (7, 3), (15, 18), (13, 7)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let weights: [Int] = [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]
            let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
            #expect(cover == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16] as [Int])
            #expect(graph.isVertexCover(cover))
        }
    }

    @Test("CV-112 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv112() {
        // V []; E []; maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
    }

    @Test("CV-113 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv113() {
        // V [0]; E []; maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
    }

    @Test("CV-114 self-loop: empty, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv114() {
        // V [0]; E [0-0]; maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.maximalIndependentSet() == [] as [Int])
        }
    }

    @Test("CV-115 P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv115() {
        // P(5); maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
    }

    @Test("CV-116 star(3): hub first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv116() {
        // star(3); maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0] as [Int])
        }
    }

    @Test("CV-117 star(3), seeded with a leaf, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv117() {
        // star(3); maximalIndependentSet(containing: [1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet(containing: [1] as [Int]) == [1, 2, 3] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet(containing: [1] as [Int]) == [1, 2, 3] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet(containing: [1] as [Int]) == [1, 2, 3] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet(containing: [1] as [Int]) == [1, 2, 3] as [Int])
        }
    }

    @Test("CV-118 C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv118() {
        // C(6); maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet() == [0, 2, 4] as [Int])
        }
    }

    @Test("CV-119 C(6) seeded {1, 4}, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv119() {
        // C(6); maximalIndependentSet(containing: [1, 4])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 4] as [Int]) == [1, 4] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 4] as [Int]) == [1, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 4] as [Int]) == [1, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 4] as [Int]) == [1, 4] as [Int])
        }
    }

    @Test("CV-120 seeds adjacent: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv120() {
        // C(6); maximalIndependentSet(containing: [1, 2])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 2] as [Int]) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 2] as [Int]) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 2] as [Int]) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.maximalIndependentSet(containing: [1, 2] as [Int]) == nil)
        }
    }

    @Test("CV-121 seed with a self-loop: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv121() {
        // V [0, 1]; E [0-0, 0-1]; maximalIndependentSet(containing: [0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [0] as [Int]) == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [0] as [Int]) == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [0] as [Int]) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [0] as [Int]) == nil)
        }
    }

    @Test("CV-122 loop skipped, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv122() {
        // V [0, 1]; E [0-0, 0-1]; maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet() == [1] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet() == [1] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet() == [1] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet() == [1] as [Int])
        }
    }

    @Test("CV-123 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv123() {
        // nx(petersen_graph); maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(graph.maximalIndependentSet() == [0, 2, 6] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            #expect(graph.maximalIndependentSet() == [0, 2, 6] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.maximalIndependentSet() == [0, 2, 6] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.maximalIndependentSet() == [0, 2, 6] as [Int])
        }
    }

    @Test("CV-124 letters, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func cv124() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == ["d", "c"] as [String])
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == ["d", "c"] as [String])
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == ["d", "c"] as [String])
        }
    }

    @Test("CV-125 repeated seed, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv125() {
        // P(3); maximalIndependentSet(containing: [2, 2])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [2, 2] as [Int]) == [0, 2] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [2, 2] as [Int]) == [0, 2] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [2, 2] as [Int]) == [0, 2] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.maximalIndependentSet(containing: [2, 2] as [Int]) == [0, 2] as [Int])
        }
    }

    @Test("CV-126 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv126() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; maximalIndependentSet()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0, 2] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0, 2] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.maximalIndependentSet() == [0, 2] as [Int])
        }
    }

    @Test("CV-127 lcg(16,30,2), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv127() {
        // lcg(16,30,2); maximalIndependentSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet() == [0, 2, 3, 6, 9] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet() == [0, 2, 3, 6, 9] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet() == [0, 2, 3, 6, 9] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet() == [0, 2, 3, 6, 9] as [Int])
        }
    }

    @Test("CV-128 lcg(16,30,2) seeded, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv128() {
        // lcg(16,30,2); maximalIndependentSet(containing: [5, 9])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet(containing: [5, 9] as [Int]) == [0, 3, 5, 6, 7, 9] as [Int])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet(containing: [5, 9] as [Int]) == [0, 3, 5, 6, 7, 9] as [Int])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet(containing: [5, 9] as [Int]) == [0, 3, 5, 6, 7, 9] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.maximalIndependentSet(containing: [5, 9] as [Int]) == [0, 3, 5, 6, 7, 9] as [Int])
        }
    }

    @Test("CV-129 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv129() {
        // V []; E []; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-130 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv130() {
        // V [0]; E []; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-131 self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv131() {
        // V [0]; E [0-0]; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-132 two isolated, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv132() {
        // V [0, 1]; E []; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-133 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv133() {
        // V [0, 1]; E [0-1]; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-134 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv134() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumDominatingSet()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-135 P(3): the middle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv135() {
        // P(3); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let result = graph.minimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-136 P(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv136() {
        // P(4); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-137 P(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv137() {
        // P(7); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 5] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 5] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 5] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 5] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-138 C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv138() {
        // C(6); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-139 star(5): the hub, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv139() {
        // star(5); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-140 K(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv140() {
        // K(4); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.minimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-141 Petersen: 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv141() {
        // nx(petersen_graph); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-142 grid(3,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv142() {
        // grid(3,3); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 7] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 7] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 7] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 2, 7] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-143 grid(4,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv143() {
        // grid(4,4); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 7, 8, 14] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 7, 8, 14] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 7, 8, 14] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 7, 8, 14] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-144 mixed components, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv144() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7]; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 4, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 4, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 4, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let result = graph.minimumDominatingSet()
            #expect(result == [0, 4, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-145 letters, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func cv145() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == ["d", "c"] as [String])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == ["d", "c"] as [String])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.minimumDominatingSet()
            #expect(result == ["d", "c"] as [String])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-146 three branches, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv146() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 0-3, 1-4, 2-5, 3-6, 1-2, 2-3]; minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-147 lcg(14,20,10), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv147() {
        // lcg(14,20,10); minimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let result = graph.minimumDominatingSet()
            #expect(result == [1, 2, 3, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-148 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv148() {
        // V []; E []; approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-149 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv149() {
        // V [0]; E []; approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-150 self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv150() {
        // V [0]; E [0-0]; approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-151 P(3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv151() {
        // P(3); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-152 P(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv152() {
        // P(6); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-153 C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv153() {
        // C(6); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-154 star(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv154() {
        // star(4); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-155 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv155() {
        // nx(petersen_graph); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [0, 2, 6] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-156 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv156() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; approximateMinimumDominatingSet()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-157 grid(4,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv157() {
        // grid(4,4); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 5, 10, 11, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 5, 10, 11, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 5, 10, 11, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 5, 10, 11, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-158 letters, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func cv158() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == ["a", "c"] as [String])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == ["a", "c"] as [String])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == ["a", "c"] as [String])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-159 three branches, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv159() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 0-3, 1-4, 2-5, 3-6, 1-2, 2-3]; approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-160 lcg(14,20,10), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv160() {
        // lcg(14,20,10); approximateMinimumDominatingSet()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3, 5, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3, 5, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3, 5, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let result = graph.approximateMinimumDominatingSet()
            #expect(result == [1, 2, 3, 5, 12] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-161 star, heavy hub, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv161() {
        // star(4); w [10, 1, 1, 1, 1]; approximateMinimumDominatingSet(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [10, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [1, 2, 3, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-162 star, cheap hub, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv162() {
        // star(4); w [2, 1, 1, 1, 1]; approximateMinimumDominatingSet(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [2, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [2, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [2, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Int] = [2, 1, 1, 1, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-163 ratio tie: least index, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv163() {
        // V [0, 1, 2, 3]; E [0-1, 2-3, 1-2]; w [2, 4, 4, 2]; approximateMinimumDominatingSet(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 4, 4, 2]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 4, 4, 2]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 4, 4, 2]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [2, 4, 4, 2]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 3] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-164 zero weight vertex first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv164() {
        // P(4); w [1, 1, 0, 1]; approximateMinimumDominatingSet(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 1, 0, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 1, 0, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 1, 0, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let weights: [Int] = [1, 1, 0, 1]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-165 float weights, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv165() {
        // P(5); w [0.3, 0.9, 0.3, 0.9, 0.3]; approximateMinimumDominatingSet(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let weights: [Double] = [0.3, 0.9, 0.3, 0.9, 0.3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let weights: [Double] = [0.3, 0.9, 0.3, 0.9, 0.3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Double] = [0.3, 0.9, 0.3, 0.9, 0.3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let weights: [Double] = [0.3, 0.9, 0.3, 0.9, 0.3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [0, 2, 4] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-166 lcgv(12,20,3,9), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv166() {
        // lcgv(12,20,3,9); w [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]; approximateMinimumDominatingSet(weight:)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [2, 4, 9, 11] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [2, 4, 9, 11] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [2, 4, 9, 11] as [Int])
            #expect(graph.isDominatingSet(result))
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
            let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
            #expect(result == [2, 4, 9, 11] as [Int])
            #expect(graph.isDominatingSet(result))
        }
    }

    @Test("CV-167 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv167() {
        // V []; E []; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 0 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 0 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 0 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 0 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-168 isolated vertex: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv168() {
        // V [0]; E []; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
    }

    @Test("CV-169 self-loop covers its vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv169() {
        // V [0]; E [0-0]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 1 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 1 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 1 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 0]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 1 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-170 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv170() {
        // V [0, 1]; E [0-1]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-171 edge and isolated vertex: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv171() {
        // V [0, 1, 2]; E [0-1]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cover = graph.minimumEdgeCover()
            #expect(cover == nil)
        }
    }

    @Test("CV-172 loop and edge: the matched edge covers both, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv172() {
        // V [0, 1]; E [0-0, 0-1]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 2 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-173 uncovered vertex takes its first edge, a loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv173() {
        // V [0, 1, 2]; E [0-1, 2-2, 1-2]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (2, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (2, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 2]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-174 uncovered vertex takes its first edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv174() {
        // V [0, 1, 2]; E [0-1, 1-2, 2-2]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 2]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-175 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv175() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumEdgeCover()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-176 P(3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv176() {
        // P(3); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [1, 2]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-177 P(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv177() {
        // P(4); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 3]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-178 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv178() {
        // K(3); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [0, 2]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 3 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-179 star(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv179() {
        // star(4); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1, 2, 3])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1, 2, 3])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 1, 2, 3])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-180 C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv180() {
        // C(5); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2, 3])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2, 3])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 3], [4, 0]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-181 K(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv181() {
        // K(4); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 5])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 5])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 5])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 3]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 4 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-182 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv182() {
        // nx(petersen_graph); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 5, 9, 10, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 10 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 5, 9, 10, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 10 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 5, 9, 10, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 10 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 3], [4, 9], [5, 7], [6, 8]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 10 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-183 blossom, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv183() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-5]; minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 3, 5])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 3, 5])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [0, 3, 5])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 1], [2, 3], [4, 5]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-184 lcg(12,20,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv184() {
        // lcg(12,20,1); minimumEdgeCover()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [5, 9, 10, 11, 13, 16])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 12 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [5, 9, 10, 11, 13, 16])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 12 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let cover = graph.minimumEdgeCover()
            #expect(cover == [5, 9, 10, 11, 13, 16])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 12 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let cover = graph.minimumEdgeCover()
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 5], [2, 6], [3, 10], [7, 1], [9, 8], [11, 4]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 12 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-185 Kb(2,3), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv185() throws {
        // Kb(2,3); minimumEdgeCover(matching: g.maximumBipartiteMatching())
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 2], [0, 4], [1, 3]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 5 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-186 L [0,1,2]; R [3,4,5], on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv186() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; minimumEdgeCover(matching: g.maximumBipartiteMatching())
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 2, 4])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 3], [1, 4], [2, 5]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 6 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-187 isolated right vertex: nil, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv187() throws {
        // L [0]; R [1, 2]; E [0-1]; minimumEdgeCover(matching: g.maximumBipartiteMatching())
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == nil)
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 2] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == nil)
        }
    }

    @Test("CV-188 lcgb(6,7,15,4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv188() throws {
        // lcgb(6,7,15,4); minimumEdgeCover(matching: g.maximumBipartiteMatching())
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 1, 2, 3, 7, 11, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 13 - graph.maximumMatching().edges.count)
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 1, 2, 3, 7, 11, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 13 - graph.maximumMatching().edges.count)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 1, 2, 3, 7, 11, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 13 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover == [0, 1, 2, 3, 7, 11, 12])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 13 - graph.maximumMatching().edges.count)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
            let graph = AdjacencyMatrix(vertexCount: 13, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let sides = try #require(graph.bipartition())
            #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
            let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))
            #expect(cover?.map { [$0.source, $0.target] } == [[0, 9], [0, 12], [1, 8], [2, 11], [3, 6], [4, 7], [5, 10]])
            #expect(cover.map { graph.isEdgeCover($0) } == true)
            #expect(cover?.count == 13 - graph.maximumMatching().edges.count)
        }
    }

    @Test("CV-189 empty set covers an edgeless graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv189() {
        // V [0, 1]; E []; isVertexCover([])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.isVertexCover([] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.isVertexCover([] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isVertexCover([] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isVertexCover([] as [Int]) == true)
        }
    }

    @Test("CV-190 one end covers, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv190() {
        // V [0, 1]; E [0-1]; isVertexCover([1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isVertexCover([1] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.isVertexCover([1] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.isVertexCover([1] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.isVertexCover([1] as [Int]) == true)
        }
    }

    @Test("CV-191 loop needs its vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv191() {
        // V [0, 1]; E [0-0, 0-1]; isVertexCover([1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1] as [Int]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1] as [Int]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1] as [Int]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1] as [Int]) == false)
        }
    }

    @Test("CV-192 loop covered, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv192() {
        // V [0, 1]; E [0-0, 0-1]; isVertexCover([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([0] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([0] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([0] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([0] as [Int]) == true)
        }
    }

    @Test("CV-193 repeats are fine, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv193() {
        // P(3); isVertexCover([1, 1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1, 1] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1, 1] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1, 1] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isVertexCover([1, 1] as [Int]) == true)
        }
    }

    @Test("CV-194 C(4) alternate, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv194() {
        // C(4); isVertexCover([0, 2])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 2] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 2] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 2] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 2] as [Int]) == true)
        }
    }

    @Test("CV-195 C(4) adjacent pair misses an edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv195() {
        // C(4); isVertexCover([0, 1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 1] as [Int]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 1] as [Int]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 1] as [Int]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isVertexCover([0, 1] as [Int]) == false)
        }
    }

    @Test("CV-196 empty set, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv196() {
        // K(3); isIndependentSet([])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([] as [Int]) == true)
        }
    }

    @Test("CV-197 adjacent, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv197() {
        // K(3); isIndependentSet([0, 1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 1] as [Int]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 1] as [Int]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 1] as [Int]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 1] as [Int]) == false)
        }
    }

    @Test("CV-198 looped vertex is not independent, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv198() {
        // V [0, 1]; E [0-0, 0-1]; isIndependentSet([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0] as [Int]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0] as [Int]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0] as [Int]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0] as [Int]) == false)
        }
    }

    @Test("CV-199 other vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv199() {
        // V [0, 1]; E [0-0, 0-1]; isIndependentSet([1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([1] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([1] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([1] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([1] as [Int]) == true)
        }
    }

    @Test("CV-200 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv200() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isIndependentSet([0, 2])
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 2] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 2] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isIndependentSet([0, 2] as [Int]) == true)
        }
    }

    @Test("CV-201 repeats are fine, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv201() {
        // P(3); isIndependentSet([0, 0, 2])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0, 0, 2] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0, 0, 2] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0, 0, 2] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isIndependentSet([0, 0, 2] as [Int]) == true)
        }
    }

    @Test("CV-202 empty graph, empty set, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv202() {
        // V []; E []; isDominatingSet([])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([] as [Int]) == true)
        }
    }

    @Test("CV-203 isolated vertex must be in, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv203() {
        // V [0, 1]; E []; isDominatingSet([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([0] as [Int]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([0] as [Int]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([0] as [Int]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isDominatingSet([0] as [Int]) == false)
        }
    }

    @Test("CV-204 hub dominates, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv204() {
        // star(4); isDominatingSet([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
    }

    @Test("CV-205 leaf does not, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv205() {
        // star(4); isDominatingSet([1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([1] as [Int]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([1] as [Int]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([1] as [Int]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.isDominatingSet([1] as [Int]) == false)
        }
    }

    @Test("CV-206 self-loop irrelevant, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv206() {
        // V [0]; E [0-0]; isDominatingSet([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.isDominatingSet([0] as [Int]) == true)
        }
    }

    @Test("CV-207 Petersen {0,2,6}?, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv207() {
        // nx(petersen_graph); isDominatingSet([0, 2, 6])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(graph.isDominatingSet([0, 2, 6] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            #expect(graph.isDominatingSet([0, 2, 6] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.isDominatingSet([0, 2, 6] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.isDominatingSet([0, 2, 6] as [Int]) == true)
        }
    }

    @Test("CV-208 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv208() {
        // V []; E []; isEdgeCover([])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.isEdgeCover([] as [Int]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.isEdgeCover([] as [Int]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isEdgeCover([] as [Int]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.isEdgeCover([] as [AdjacencyMatrix.Edges.Index]) == true)
        }
    }

    @Test("CV-209 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv209() {
        // V [0, 1]; E [0-1]; isEdgeCover([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isEdgeCover([0]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.isEdgeCover([0]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.isEdgeCover([0]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeCover([cells[0]] as [AdjacencyMatrix.Edges.Index]) == true)
        }
    }

    @Test("CV-210 P(3) one edge misses, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv210() {
        // P(3); isEdgeCover([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.isEdgeCover([0]) == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.isEdgeCover([0]) == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.isEdgeCover([0]) == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeCover([cells[0]] as [AdjacencyMatrix.Edges.Index]) == false)
        }
    }

    @Test("CV-211 loop covers its vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv211() {
        // V [0]; E [0-0]; isEdgeCover([0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.isEdgeCover([0]) == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.isEdgeCover([0]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.isEdgeCover([0]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeCover([cells[0]] as [AdjacencyMatrix.Edges.Index]) == true)
        }
    }

    @Test("CV-212 parallel copy, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func cv212() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isEdgeCover([1, 2])
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.isEdgeCover([1, 2]) == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.isEdgeCover([1, 2]) == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeCover([cells[1], cells[2]] as [AdjacencyMatrix.Edges.Index]) == true)
        }
    }
}
