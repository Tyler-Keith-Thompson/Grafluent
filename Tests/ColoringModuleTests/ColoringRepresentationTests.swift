// The catalog's rows again on other representations. Rows on `UndirectedAdjacencyList` run again on
// `ReferencePseudograph`; `BipartiteGraph` rows on an `UndirectedAdjacencyList` and a
// `ReferencePseudograph` with the same vertices and edges; every row on a file-private conformer
// with no vertex or edge indices; all with the catalog's values, since their rows are in position
// order too. Then on `AdjacencyList.undirected` with each edge an arc as written (rows with no arc
// twice), and on `AdjacencyMatrix.undirected` with the arcs at their row-major cells (rows on 0..<n
// with no arc twice). Through `.undirected` a row is successors, then predecessors, and matrix
// positions are cells, so the connected-sequential colourings (which follow rows) and the edge
// colourings (which follow positions) there were computed by swiftgen.py with ref.py's models on
// those rows and positions; the other vertex colourings depend only on vertex order and adjacency
// and are the catalog's. Matrix positions are compared as [source, target]. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
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

@Suite("Catalog rows on every representation")
struct ColoringRepresentationTests {
    @Test("CO-001 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co001() {
        // V []; E []; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-002 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co002() {
        // V []; E []; greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-003 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co003() {
        // V []; E []; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-004 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co004() {
        // V []; E []; greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-005 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co005() {
        // V []; E []; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-006 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co006() {
        // V []; E []; greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-007 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co007() {
        // V [0]; E []; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-008 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co008() {
        // V [0]; E []; greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-009 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co009() {
        // V [0]; E []; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-010 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co010() {
        // V [0]; E []; greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-011 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co011() {
        // V [0]; E []; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-012 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co012() {
        // V [0]; E []; greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-013 one vertex with a self-loop: loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co013() {
        // V [0]; E [0-0]; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-014 one vertex with a self-loop: loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co014() {
        // V [0]; E [0-0]; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-015 one vertex with a self-loop: loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co015() {
        // V [0]; E [0-0]; greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-016 two isolated vertices, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co016() {
        // V [0, 1]; E []; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 2).map { coloring.color(ofIndex: $0) } == [0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-017 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co017() {
        // V [0, 1]; E [0-1]; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 2).map { coloring.color(ofIndex: $0) } == [0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-018 parallel edges count once (degree 1 at 0), on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co018() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; greedyColoring(strategy: .largestFirst)
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-019 two isolated vertices, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co019() {
        // V [0, 1]; E []; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 2).map { coloring.color(ofIndex: $0) } == [0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-020 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co020() {
        // V [0, 1]; E [0-1]; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 2).map { coloring.color(ofIndex: $0) } == [0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-021 parallel edges count once (degree 1 at 0), on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co021() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; greedyColoring(strategy: .saturationLargestFirst)
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-022 self-loops ignored; also in the degree that orders, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co022() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [1, 2, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-023 self-loops ignored; also in the degree that orders, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co023() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [1, 2, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-024 self-loops ignored; also in the degree that orders, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co024() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-025 self-loops ignored; also in the degree that orders, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co025() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-026 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co026() {
        // K(3); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-027 K(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co027() {
        // K(5); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 4])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-028 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co028() {
        // P(5); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-029 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co029() {
        // C(5); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-030 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co030() {
        // C(6); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-031 star(4): hub first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co031() {
        // star(4); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-032 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co032() {
        // wheel(5); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-033 wheel(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co033() {
        // wheel(6); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-034 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co034() {
        // nx(petersen_graph); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-035 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co035() {
        // grid(3,4); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-036 Kb(2,3), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co036() {
        // Kb(2,3); greedyColoring(strategy: .largestFirst)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-037 crown(4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co037() {
        // crown(4); greedyColoring(strategy: .largestFirst)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-038 crownx(4): index order pairs the crown, 4 colours, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co038() {
        // crownx(4); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 2, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 2, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 1, 2, 2, 3, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 2, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 2, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-039 vertex order, not label order, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co039() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [0, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-040 ties: equal degrees keep vertex order, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co040() {
        // V [0, 1, 2, 3, 4, 5]; E [5-4, 3-2, 1-0, 0-5]; greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(5, 4), (3, 2), (1, 0), (0, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(5, 4), (3, 2), (1, 0), (0, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(5, 4), (3, 2), (1, 0), (0, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(5, 4), (3, 2), (1, 0), (0, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-041 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co041() {
        // nx(bull_graph); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [2, 0, 1, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-042 nx(house_x_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co042() {
        // nx(house_x_graph); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [2, 3, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-043 nx(krackhardt_kite_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co043() {
        // nx(krackhardt_kite_graph); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 18)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 3, 0, 3, 1, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 18)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 3, 0, 3, 1, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [2, 1, 3, 0, 3, 1, 2, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 3, 0, 3, 1, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 3, 0, 3, 1, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-044 nx(karate_club_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co044() {
        // nx(karate_club_graph); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 1, 1, 2, 4, 3, 1, 2, 1, 1, 4, 2, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 1, 1, 1, 1, 3, 2, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 1, 1, 2, 4, 3, 1, 2, 1, 1, 4, 2, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 1, 1, 1, 1, 3, 2, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 34).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 1, 1, 2, 4, 3, 1, 2, 1, 1, 4, 2, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 1, 1, 1, 1, 3, 2, 2, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 1, 1, 2, 4, 3, 1, 2, 1, 1, 4, 2, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 1, 1, 1, 1, 3, 2, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 1, 1, 2, 4, 3, 1, 2, 1, 1, 4, 2, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 1, 1, 1, 1, 3, 2, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-045 nx(florentine_families_graph): string vertices, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co045() {
        // nx(florentine_families_graph); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("Acciaiuoli", "Medici"), ("Medici", "Barbadori"), ("Medici", "Ridolfi"), ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"), ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"), ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"), ("Strozzi", "Bischeri"), ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"), ("Albizzi", "Ginori"), ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"), ("Bischeri", "Guadagni"), ("Guadagni", "Lamberteschi")]
            let graph = ReferencePseudograph<String>(vertices: ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 2, 1, 2, 1, 1, 0, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(String, String)] = [("Acciaiuoli", "Medici"), ("Medici", "Barbadori"), ("Medici", "Ridolfi"), ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"), ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"), ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"), ("Strozzi", "Bischeri"), ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"), ("Albizzi", "Ginori"), ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"), ("Bischeri", "Guadagni"), ("Guadagni", "Lamberteschi")]
            let graph = UnindexedGraph<String>(vertices: ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 2, 1, 2, 1, 1, 0, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 15).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 2, 0, 2, 1, 2, 1, 1, 0, 1, 0, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("Acciaiuoli", "Medici"), ("Medici", "Barbadori"), ("Medici", "Ridolfi"), ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"), ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"), ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"), ("Strozzi", "Bischeri"), ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"), ("Albizzi", "Ginori"), ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"), ("Bischeri", "Guadagni"), ("Guadagni", "Lamberteschi")]
            let graph = AdjacencyList<String>(vertices: ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 2, 1, 2, 1, 1, 0, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-046 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co046() {
        // lcg(12,24,1); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-047 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co047() {
        // lcg(20,50,7); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 0, 0, 2, 1, 1, 2, 0, 1, 1, 2, 3, 2, 0, 0, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 0, 0, 2, 1, 1, 2, 0, 1, 1, 2, 3, 2, 0, 0, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [2, 3, 0, 1, 0, 0, 2, 1, 1, 2, 0, 1, 1, 2, 3, 2, 0, 0, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 0, 0, 2, 1, 1, 2, 0, 1, 1, 2, 3, 2, 0, 0, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 0, 0, 2, 1, 1, 2, 0, 1, 1, 2, 3, 2, 0, 0, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-048 lcg(30,90,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co048() {
        // lcg(30,90,3); greedyColoring(strategy: .largestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 1, 2, 3, 0, 4, 2, 1, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 1, 2, 3, 0, 4, 2, 1, 1])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 30).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 1, 2, 3, 0, 4, 2, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 1, 2, 3, 0, 4, 2, 1, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyMatrix(vertexCount: 30, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .largestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 1, 2, 3, 0, 4, 2, 1, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-049 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co049() {
        // K(3); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [2, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-050 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co050() {
        // P(5); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-051 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co051() {
        // C(6); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-052 star(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co052() {
        // star(4); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [1, 0, 0, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-053 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co053() {
        // wheel(5); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 1, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 1, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [2, 3, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 1, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 1, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-054 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co054() {
        // nx(petersen_graph); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 0, 2, 1, 2, 1, 1, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 0, 2, 1, 2, 1, 1, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 2, 0, 2, 1, 2, 1, 1, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 0, 2, 1, 2, 1, 1, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 0, 2, 1, 2, 1, 1, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-055 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co055() {
        // grid(3,4); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-056 crown(4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co056() {
        // crown(4); greedyColoring(strategy: .smallestLast)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [1, 1, 1, 1, 0, 0, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-057 crownx(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co057() {
        // crownx(4); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-058 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co058() {
        // nx(bull_graph); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [2, 1, 0, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-059 nx(dodecahedral_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co059() {
        // nx(dodecahedral_graph); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 1, 2, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 1, 2, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [3, 2, 1, 2, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 1, 2, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 1, 2, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-060 nx(karate_club_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co060() {
        // nx(karate_club_graph); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 4, 1, 1, 0, 1, 3, 1, 0, 0, 0, 1, 2, 2, 2, 0, 2, 1, 2, 0, 2, 3, 2, 0, 1, 1, 1, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 4, 1, 1, 0, 1, 3, 1, 0, 0, 0, 1, 2, 2, 2, 0, 2, 1, 2, 0, 2, 3, 2, 0, 1, 1, 1, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 34).map { coloring.color(ofIndex: $0) } == [2, 3, 0, 4, 1, 1, 0, 1, 3, 1, 0, 0, 0, 1, 2, 2, 2, 0, 2, 1, 2, 0, 2, 3, 2, 0, 1, 1, 1, 2, 2, 3, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 4, 1, 1, 0, 1, 3, 1, 0, 0, 0, 1, 2, 2, 2, 0, 2, 1, 2, 0, 2, 3, 2, 0, 1, 1, 1, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 4, 1, 1, 0, 1, 3, 1, 0, 0, 0, 1, 2, 2, 2, 0, 2, 1, 2, 0, 2, 3, 2, 0, 1, 1, 1, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-061 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co061() {
        // lcg(12,24,1); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 3, 3, 1, 0, 1, 2, 1, 2, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 3, 3, 1, 0, 1, 2, 1, 2, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 3, 3, 1, 0, 1, 2, 1, 2, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 3, 3, 1, 0, 1, 2, 1, 2, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 3, 3, 1, 0, 1, 2, 1, 2, 1, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-062 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co062() {
        // lcg(20,50,7); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 1, 2, 3, 0, 0, 1, 3, 1, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0, 2])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 1, 2, 3, 0, 0, 1, 3, 1, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0, 2])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [4, 1, 2, 3, 0, 0, 1, 3, 1, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 1, 2, 3, 0, 0, 1, 3, 1, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0, 2])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 1, 2, 3, 0, 0, 1, 3, 1, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0, 2])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-063 lcg(30,90,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co063() {
        // lcg(30,90,3); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 2, 0, 2, 3, 1, 1, 2, 2, 2, 1, 3, 3, 2, 3, 0, 1, 0, 2, 0, 3, 0, 1, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 2, 0, 2, 3, 1, 1, 2, 2, 2, 1, 3, 3, 2, 3, 0, 1, 0, 2, 0, 3, 0, 1, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 30).map { coloring.color(ofIndex: $0) } == [1, 1, 1, 2, 0, 2, 3, 1, 1, 2, 2, 2, 1, 3, 3, 2, 3, 0, 1, 0, 2, 0, 3, 0, 1, 0, 0, 3, 4, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 2, 0, 2, 3, 1, 1, 2, 2, 2, 1, 3, 3, 2, 3, 0, 1, 0, 2, 0, 3, 0, 1, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyMatrix(vertexCount: 30, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 2, 0, 2, 3, 1, 1, 2, 2, 2, 1, 3, 3, 2, 3, 0, 1, 0, 2, 0, 3, 0, 1, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-064 planar: nx(icosahedral_graph), <= 6 colours, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co064() {
        // nx(icosahedral_graph); greedyColoring(strategy: .smallestLast)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 2, 1, 3, 2, 1, 2, 3, 0, 1, 0, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 2, 1, 3, 2, 1, 2, 3, 0, 1, 0, 0])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [4, 2, 1, 3, 2, 1, 2, 3, 0, 1, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .smallestLast)
            #expect(vertexList.map { coloring.color(of: $0) } == [4, 2, 1, 3, 2, 1, 2, 3, 0, 1, 0, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-065 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co065() {
        // K(3); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-066 K(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co066() {
        // K(5); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 4])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-067 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co067() {
        // P(5); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-068 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co068() {
        // C(5); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-069 cycle C(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co069() {
        // C(7); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-070 star(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co070() {
        // star(4); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-071 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co071() {
        // wheel(5); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-072 wheel(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co072() {
        // wheel(6); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-073 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co073() {
        // nx(petersen_graph); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-074 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co074() {
        // grid(3,4); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-075 crown(4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co075() {
        // crown(4); greedyColoring(strategy: .saturationLargestFirst)
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-076 crownx(5): DSatur is exact on bipartite graphs, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co076() {
        // crownx(5); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (2, 1), (2, 5), (2, 7), (2, 9), (4, 1), (4, 3), (4, 7), (4, 9), (6, 1), (6, 3), (6, 5), (6, 9), (8, 1), (8, 3), (8, 5), (8, 7)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (2, 1), (2, 5), (2, 7), (2, 9), (4, 1), (4, 3), (4, 7), (4, 9), (6, 1), (6, 3), (6, 5), (6, 9), (8, 1), (8, 3), (8, 5), (8, 7)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (2, 1), (2, 5), (2, 7), (2, 9), (4, 1), (4, 3), (4, 7), (4, 9), (6, 1), (6, 3), (6, 5), (6, 9), (8, 1), (8, 3), (8, 5), (8, 7)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (2, 1), (2, 5), (2, 7), (2, 9), (4, 1), (4, 3), (4, 7), (4, 9), (6, 1), (6, 3), (6, 5), (6, 9), (8, 1), (8, 3), (8, 5), (8, 7)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-077 vertex order, not label order, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co077() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [0, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-078 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co078() {
        // nx(bull_graph); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [2, 0, 1, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-079 nx(house_x_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co079() {
        // nx(house_x_graph); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [2, 3, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 3, 0, 1, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-080 nx(dodecahedral_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co080() {
        // nx(dodecahedral_graph); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-081 nx(chvatal_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co081() {
        // nx(chvatal_graph); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-082 nx(mycielski_graph,4): Groetzsch, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co082() {
        // nx(mycielski_graph,4); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 11).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyMatrix(vertexCount: 11, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-083 nx(karate_club_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co083() {
        // nx(karate_club_graph); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 34).map { coloring.color(ofIndex: $0) } == [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-084 two components: saturation 0 restarts at the greatest degree, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co084() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 1-2, 3-4, 3-5, 3-6]; greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [1, 0, 1, 0, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 1, 0, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-085 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co085() {
        // lcg(12,24,1); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-086 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co086() {
        // lcg(20,50,7); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-087 lcg(30,90,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co087() {
        // lcg(30,90,3); greedyColoring(strategy: .saturationLargestFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 30).map { coloring.color(ofIndex: $0) } == [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyMatrix(vertexCount: 30, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
            let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-088 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co088() {
        // K(3); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-089 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co089() {
        // P(5); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-090 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co090() {
        // C(5); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-091 star(4): leaves first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co091() {
        // star(4); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [1, 0, 0, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 0, 0, 0, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-092 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co092() {
        // wheel(5); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [2, 0, 1, 0, 1, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0, 1, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-093 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co093() {
        // nx(petersen_graph); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-094 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co094() {
        // grid(3,4); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-095 crownx(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co095() {
        // crownx(4); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-096 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co096() {
        // nx(bull_graph); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-097 nx(karate_club_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co097() {
        // nx(karate_club_graph); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 34).map { coloring.color(ofIndex: $0) } == [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-098 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co098() {
        // lcg(12,24,1); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-099 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co099() {
        // lcg(20,50,7); greedyColoring(strategy: .independentSet)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .independentSet)
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-100 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co100() {
        // P(5); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-101 path P(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co101() {
        // P(5); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-102 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co102() {
        // C(6); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-103 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co103() {
        // C(6); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-104 star(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co104() {
        // star(4); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-105 star(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co105() {
        // star(4); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-106 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co106() {
        // nx(petersen_graph); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 2, 1, 1, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 2, 1, 1, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 2, 1, 1, 0, 3, 3, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 2, 1, 1, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 2, 1, 1, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-107 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co107() {
        // nx(petersen_graph); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-108 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co108() {
        // grid(3,4); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-109 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co109() {
        // grid(3,4); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-110 crownx(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co110() {
        // crownx(4); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-111 crownx(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co111() {
        // crownx(4); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-112 two components, least vertex roots each, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co112() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-4, 4-6, 1-2, 2-3, 3-5, 5-1]; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-113 two components, least vertex roots each, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co113() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-4, 4-6, 1-2, 2-3, 3-5, 5-1]; greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 0, 1, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-114 component {5, 9}-style: root is the least vertex, not a set's first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co114() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [9-5, 0-1, 1-2, 2-3, 3-4, 6-7, 7-8, 8-6]; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-115 component {5, 9}-style: root is the least vertex, not a set's first, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co115() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [9-5, 0-1, 1-2, 2-3, 3-4, 6-7, 7-8, 8-6]; greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-116 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co116() {
        // lcg(12,24,1); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-117 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co117() {
        // lcg(12,24,1); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 0, 1, 1, 3, 2, 3, 0, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-118 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co118() {
        // lcg(20,50,7); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 3, 0, 1, 1, 2, 0, 1, 1, 2, 2, 1, 1, 0, 3, 0, 2, 0, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 3, 0, 1, 1, 2, 0, 1, 1, 2, 2, 1, 1, 0, 3, 0, 2, 0, 0, 1])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [0, 3, 0, 1, 1, 2, 0, 1, 1, 2, 2, 1, 1, 0, 3, 0, 2, 0, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 1, 3, 0, 2, 2, 4, 2, 2, 3, 0, 0, 1, 1, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 1, 0, 2, 2, 0, 1, 2, 2, 0, 0, 0, 1, 1, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-119 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co119() {
        // lcg(20,50,7); greedyColoring(strategy: .connectedSequentialDepthFirst)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1, 2, 3, 1, 1, 0, 0, 0, 1, 0, 3, 3, 2, 0, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1, 2, 3, 1, 1, 0, 0, 0, 1, 0, 3, 3, 2, 0, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 1, 1, 2, 3, 1, 1, 0, 0, 0, 1, 0, 3, 3, 2, 0, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 1, 1, 3, 3, 0, 0, 1, 4, 2, 3, 2, 0, 1, 2, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 1, 1, 2, 0, 1, 1, 0, 3, 1, 1, 0, 0, 0, 2, 2, 2, 1])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-120 empty order on the empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co120() {
        // V []; E []; greedyColoring(order: [])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(order: [] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(order: [] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(order: [] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.greedyColoring(order: [] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-121 path in reverse, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co121() {
        // P(5); greedyColoring(order: [4, 3, 2, 1, 0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(order: [4, 3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(order: [4, 3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(order: [4, 3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.greedyColoring(order: [4, 3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-122 crown(4) interleaved: the classic n/2-colour trap, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co122() {
        // crown(4); greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7])
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 0, 1, 2, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-123 crown(4) sides first: 2 colours, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co123() {
        // crown(4); greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7])
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-124 labels, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co124() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; greedyColoring(order: [c, b, a, d])
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(order: ["c", "b", "a", "d"] as [String])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(order: ["c", "b", "a", "d"] as [String])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [2, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.greedyColoring(order: ["c", "b", "a", "d"] as [String])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 1, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-125 Petersen, outer then inner, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co125() {
        // nx(petersen_graph); greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-126 Petersen, inner then outer, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co126() {
        // nx(petersen_graph); greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 2, 0, 0, 0, 1, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 2, 0, 0, 0, 1, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [1, 2, 0, 2, 0, 0, 0, 1, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 2, 0, 0, 0, 1, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [1, 2, 0, 2, 0, 0, 0, 1, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-127 self-loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co127() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(order: [3, 2, 1, 0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(order: [3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(order: [3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [2, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(order: [3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.greedyColoring(order: [3, 2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [2, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-128 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co128() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; greedyColoring(order: [2, 1, 0])
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(order: [2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(order: [2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.greedyColoring(order: [2, 1, 0] as [Int])
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-129 empty graph: 0, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co129() {
        // V []; E []; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 0)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 0)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 0)
        }
    }

    @Test("CO-130 one vertex: 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co130() {
        // V [0]; E []; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
    }

    @Test("CO-131 self-loop ignored: 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co131() {
        // V [0]; E [0-0]; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 1)
        }
    }

    @Test("CO-132 edgeless: 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co132() {
        // V [0, 1]; E []; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
    }

    @Test("CO-133 one edge: 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co133() {
        // V [0, 1]; E [0-1]; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-134 parallel edges: 2, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co134() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; chromaticNumber()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-135 K(1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co135() {
        // K(1); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            #expect(graph.chromaticNumber() == 1)
        }
    }

    @Test("CO-136 K(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co136() {
        // K(4); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-137 K(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co137() {
        // K(7); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 7)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 7)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 7)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 7)
        }
    }

    @Test("CO-138 path P(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co138() {
        // P(6); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-139 cycle C(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co139() {
        // C(4); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-140 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co140() {
        // C(5); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-141 cycle C(9), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co141() {
        // C(9); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 9)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-142 wheel(4): even rim, 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co142() {
        // wheel(4); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-143 wheel(5): odd rim, 4, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co143() {
        // wheel(5); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-144 wheel(8), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co144() {
        // wheel(8); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 16)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 16)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 16)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 1)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 16)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-145 Petersen: 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co145() {
        // nx(petersen_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-146 nx(mycielski_graph,3): C5, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co146() {
        // nx(mycielski_graph,3); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-147 nx(mycielski_graph,4): Groetzsch, triangle-free, 4, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co147() {
        // nx(mycielski_graph,4); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyMatrix(vertexCount: 11, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-148 nx(mycielski_graph,5): 23 vertices, triangle-free, 5, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co148() {
        // nx(mycielski_graph,5); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (0, 12), (0, 14), (0, 17), (0, 19), (1, 2), (1, 7), (1, 5), (1, 13), (1, 18), (1, 16), (1, 11), (2, 4), (2, 9), (2, 6), (2, 15), (2, 20), (2, 17), (2, 12), (3, 4), (3, 9), (3, 5), (3, 15), (3, 20), (3, 16), (3, 11), (4, 7), (4, 8), (4, 18), (4, 19), (4, 13), (4, 14), (5, 10), (5, 21), (5, 12), (5, 14), (6, 10), (6, 21), (6, 11), (6, 13), (7, 10), (7, 21), (7, 12), (7, 15), (8, 10), (8, 21), (8, 11), (8, 15), (9, 10), (9, 21), (9, 13), (9, 14), (10, 16), (10, 17), (10, 18), (10, 19), (10, 20), (11, 22), (12, 22), (13, 22), (14, 22), (15, 22), (16, 22), (17, 22), (18, 22), (19, 22), (20, 22), (21, 22)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 71)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (0, 12), (0, 14), (0, 17), (0, 19), (1, 2), (1, 7), (1, 5), (1, 13), (1, 18), (1, 16), (1, 11), (2, 4), (2, 9), (2, 6), (2, 15), (2, 20), (2, 17), (2, 12), (3, 4), (3, 9), (3, 5), (3, 15), (3, 20), (3, 16), (3, 11), (4, 7), (4, 8), (4, 18), (4, 19), (4, 13), (4, 14), (5, 10), (5, 21), (5, 12), (5, 14), (6, 10), (6, 21), (6, 11), (6, 13), (7, 10), (7, 21), (7, 12), (7, 15), (8, 10), (8, 21), (8, 11), (8, 15), (9, 10), (9, 21), (9, 13), (9, 14), (10, 16), (10, 17), (10, 18), (10, 19), (10, 20), (11, 22), (12, 22), (13, 22), (14, 22), (15, 22), (16, 22), (17, 22), (18, 22), (19, 22), (20, 22), (21, 22)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 71)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (0, 12), (0, 14), (0, 17), (0, 19), (1, 2), (1, 7), (1, 5), (1, 13), (1, 18), (1, 16), (1, 11), (2, 4), (2, 9), (2, 6), (2, 15), (2, 20), (2, 17), (2, 12), (3, 4), (3, 9), (3, 5), (3, 15), (3, 20), (3, 16), (3, 11), (4, 7), (4, 8), (4, 18), (4, 19), (4, 13), (4, 14), (5, 10), (5, 21), (5, 12), (5, 14), (6, 10), (6, 21), (6, 11), (6, 13), (7, 10), (7, 21), (7, 12), (7, 15), (8, 10), (8, 21), (8, 11), (8, 15), (9, 10), (9, 21), (9, 13), (9, 14), (10, 16), (10, 17), (10, 18), (10, 19), (10, 20), (11, 22), (12, 22), (13, 22), (14, 22), (15, 22), (16, 22), (17, 22), (18, 22), (19, 22), (20, 22), (21, 22)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 71)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (0, 12), (0, 14), (0, 17), (0, 19), (1, 2), (1, 7), (1, 5), (1, 13), (1, 18), (1, 16), (1, 11), (2, 4), (2, 9), (2, 6), (2, 15), (2, 20), (2, 17), (2, 12), (3, 4), (3, 9), (3, 5), (3, 15), (3, 20), (3, 16), (3, 11), (4, 7), (4, 8), (4, 18), (4, 19), (4, 13), (4, 14), (5, 10), (5, 21), (5, 12), (5, 14), (6, 10), (6, 21), (6, 11), (6, 13), (7, 10), (7, 21), (7, 12), (7, 15), (8, 10), (8, 21), (8, 11), (8, 15), (9, 10), (9, 21), (9, 13), (9, 14), (10, 16), (10, 17), (10, 18), (10, 19), (10, 20), (11, 22), (12, 22), (13, 22), (14, 22), (15, 22), (16, 22), (17, 22), (18, 22), (19, 22), (20, 22), (21, 22)]
            let graph = AdjacencyMatrix(vertexCount: 23, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 71)
            #expect(graph.chromaticNumber() == 5)
        }
    }

    @Test("CO-149 nx(chvatal_graph): 4, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co149() {
        // nx(chvatal_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-150 crown(5): 2, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co150() {
        // crown(5); chromaticNumber()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 7), (1, 8), (1, 9), (2, 5), (2, 6), (2, 8), (2, 9), (3, 5), (3, 6), (3, 7), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 7), (1, 8), (1, 9), (2, 5), (2, 6), (2, 8), (2, 9), (3, 5), (3, 6), (3, 7), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 7), (1, 8), (1, 9), (2, 5), (2, 6), (2, 8), (2, 9), (3, 5), (3, 6), (3, 7), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 7), (1, 8), (1, 9), (2, 5), (2, 6), (2, 8), (2, 9), (3, 5), (3, 6), (3, 7), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 7), (1, 8), (1, 9), (2, 5), (2, 6), (2, 8), (2, 9), (3, 5), (3, 6), (3, 7), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-151 crownx(6): 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co151() {
        // crownx(6); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (0, 11), (2, 1), (2, 5), (2, 7), (2, 9), (2, 11), (4, 1), (4, 3), (4, 7), (4, 9), (4, 11), (6, 1), (6, 3), (6, 5), (6, 9), (6, 11), (8, 1), (8, 3), (8, 5), (8, 7), (8, 11), (10, 1), (10, 3), (10, 5), (10, 7), (10, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (0, 11), (2, 1), (2, 5), (2, 7), (2, 9), (2, 11), (4, 1), (4, 3), (4, 7), (4, 9), (4, 11), (6, 1), (6, 3), (6, 5), (6, 9), (6, 11), (8, 1), (8, 3), (8, 5), (8, 7), (8, 11), (10, 1), (10, 3), (10, 5), (10, 7), (10, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (0, 11), (2, 1), (2, 5), (2, 7), (2, 9), (2, 11), (4, 1), (4, 3), (4, 7), (4, 9), (4, 11), (6, 1), (6, 3), (6, 5), (6, 9), (6, 11), (8, 1), (8, 3), (8, 5), (8, 7), (8, 11), (10, 1), (10, 3), (10, 5), (10, 7), (10, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (0, 11), (2, 1), (2, 5), (2, 7), (2, 9), (2, 11), (4, 1), (4, 3), (4, 7), (4, 9), (4, 11), (6, 1), (6, 3), (6, 5), (6, 9), (6, 11), (8, 1), (8, 3), (8, 5), (8, 7), (8, 11), (10, 1), (10, 3), (10, 5), (10, 7), (10, 9)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-152 queen(4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co152() {
        // queen(4); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 8), (0, 10), (0, 12), (0, 15), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 9), (1, 11), (1, 13), (2, 3), (2, 5), (2, 6), (2, 7), (2, 8), (2, 10), (2, 14), (3, 6), (3, 7), (3, 9), (3, 11), (3, 12), (3, 15), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 12), (4, 14), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 13), (5, 15), (6, 7), (6, 9), (6, 10), (6, 11), (6, 12), (6, 14), (7, 10), (7, 11), (7, 13), (7, 15), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (10, 11), (10, 13), (10, 14), (10, 15), (11, 14), (11, 15), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 76)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 8), (0, 10), (0, 12), (0, 15), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 9), (1, 11), (1, 13), (2, 3), (2, 5), (2, 6), (2, 7), (2, 8), (2, 10), (2, 14), (3, 6), (3, 7), (3, 9), (3, 11), (3, 12), (3, 15), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 12), (4, 14), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 13), (5, 15), (6, 7), (6, 9), (6, 10), (6, 11), (6, 12), (6, 14), (7, 10), (7, 11), (7, 13), (7, 15), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (10, 11), (10, 13), (10, 14), (10, 15), (11, 14), (11, 15), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 76)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 8), (0, 10), (0, 12), (0, 15), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 9), (1, 11), (1, 13), (2, 3), (2, 5), (2, 6), (2, 7), (2, 8), (2, 10), (2, 14), (3, 6), (3, 7), (3, 9), (3, 11), (3, 12), (3, 15), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 12), (4, 14), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 13), (5, 15), (6, 7), (6, 9), (6, 10), (6, 11), (6, 12), (6, 14), (7, 10), (7, 11), (7, 13), (7, 15), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (10, 11), (10, 13), (10, 14), (10, 15), (11, 14), (11, 15), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 76)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 8), (0, 10), (0, 12), (0, 15), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 9), (1, 11), (1, 13), (2, 3), (2, 5), (2, 6), (2, 7), (2, 8), (2, 10), (2, 14), (3, 6), (3, 7), (3, 9), (3, 11), (3, 12), (3, 15), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 12), (4, 14), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 13), (5, 15), (6, 7), (6, 9), (6, 10), (6, 11), (6, 12), (6, 14), (7, 10), (7, 11), (7, 13), (7, 15), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (10, 11), (10, 13), (10, 14), (10, 15), (11, 14), (11, 15), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 76)
            #expect(graph.chromaticNumber() == 5)
        }
    }

    @Test("CO-153 queen(5): 5, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co153() {
        // queen(5); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 160)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 160)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 160)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = AdjacencyMatrix(vertexCount: 25, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 160)
            #expect(graph.chromaticNumber() == 5)
        }
    }

    @Test("CO-154 queen(6): 7, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co154() {
        // queen(6); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 12), (0, 14), (0, 18), (0, 21), (0, 24), (0, 28), (0, 30), (0, 35), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 13), (1, 15), (1, 19), (1, 22), (1, 25), (1, 29), (1, 31), (2, 3), (2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 12), (2, 14), (2, 16), (2, 20), (2, 23), (2, 26), (2, 32), (3, 4), (3, 5), (3, 8), (3, 9), (3, 10), (3, 13), (3, 15), (3, 17), (3, 18), (3, 21), (3, 27), (3, 33), (4, 5), (4, 9), (4, 10), (4, 11), (4, 14), (4, 16), (4, 19), (4, 22), (4, 24), (4, 28), (4, 34), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (5, 25), (5, 29), (5, 30), (5, 35), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 18), (6, 20), (6, 24), (6, 27), (6, 30), (6, 34), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 19), (7, 21), (7, 25), (7, 28), (7, 31), (7, 35), (8, 9), (8, 10), (8, 11), (8, 13), (8, 14), (8, 15), (8, 18), (8, 20), (8, 22), (8, 26), (8, 29), (8, 32), (9, 10), (9, 11), (9, 14), (9, 15), (9, 16), (9, 19), (9, 21), (9, 23), (9, 24), (9, 27), (9, 33), (10, 11), (10, 15), (10, 16), (10, 17), (10, 20), (10, 22), (10, 25), (10, 28), (10, 30), (10, 34), (11, 16), (11, 17), (11, 21), (11, 23), (11, 26), (11, 29), (11, 31), (11, 35), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (12, 24), (12, 26), (12, 30), (12, 33), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (13, 20), (13, 25), (13, 27), (13, 31), (13, 34), (14, 15), (14, 16), (14, 17), (14, 19), (14, 20), (14, 21), (14, 24), (14, 26), (14, 28), (14, 32), (14, 35), (15, 16), (15, 17), (15, 20), (15, 21), (15, 22), (15, 25), (15, 27), (15, 29), (15, 30), (15, 33), (16, 17), (16, 21), (16, 22), (16, 23), (16, 26), (16, 28), (16, 31), (16, 34), (17, 22), (17, 23), (17, 27), (17, 29), (17, 32), (17, 35), (18, 19), (18, 20), (18, 21), (18, 22), (18, 23), (18, 24), (18, 25), (18, 30), (18, 32), (19, 20), (19, 21), (19, 22), (19, 23), (19, 24), (19, 25), (19, 26), (19, 31), (19, 33), (20, 21), (20, 22), (20, 23), (20, 25), (20, 26), (20, 27), (20, 30), (20, 32), (20, 34), (21, 22), (21, 23), (21, 26), (21, 27), (21, 28), (21, 31), (21, 33), (21, 35), (22, 23), (22, 27), (22, 28), (22, 29), (22, 32), (22, 34), (23, 28), (23, 29), (23, 33), (23, 35), (24, 25), (24, 26), (24, 27), (24, 28), (24, 29), (24, 30), (24, 31), (25, 26), (25, 27), (25, 28), (25, 29), (25, 30), (25, 31), (25, 32), (26, 27), (26, 28), (26, 29), (26, 31), (26, 32), (26, 33), (27, 28), (27, 29), (27, 32), (27, 33), (27, 34), (28, 29), (28, 33), (28, 34), (28, 35), (29, 34), (29, 35), (30, 31), (30, 32), (30, 33), (30, 34), (30, 35), (31, 32), (31, 33), (31, 34), (31, 35), (32, 33), (32, 34), (32, 35), (33, 34), (33, 35), (34, 35)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 290)
            #expect(graph.chromaticNumber() == 7)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 12), (0, 14), (0, 18), (0, 21), (0, 24), (0, 28), (0, 30), (0, 35), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 13), (1, 15), (1, 19), (1, 22), (1, 25), (1, 29), (1, 31), (2, 3), (2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 12), (2, 14), (2, 16), (2, 20), (2, 23), (2, 26), (2, 32), (3, 4), (3, 5), (3, 8), (3, 9), (3, 10), (3, 13), (3, 15), (3, 17), (3, 18), (3, 21), (3, 27), (3, 33), (4, 5), (4, 9), (4, 10), (4, 11), (4, 14), (4, 16), (4, 19), (4, 22), (4, 24), (4, 28), (4, 34), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (5, 25), (5, 29), (5, 30), (5, 35), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 18), (6, 20), (6, 24), (6, 27), (6, 30), (6, 34), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 19), (7, 21), (7, 25), (7, 28), (7, 31), (7, 35), (8, 9), (8, 10), (8, 11), (8, 13), (8, 14), (8, 15), (8, 18), (8, 20), (8, 22), (8, 26), (8, 29), (8, 32), (9, 10), (9, 11), (9, 14), (9, 15), (9, 16), (9, 19), (9, 21), (9, 23), (9, 24), (9, 27), (9, 33), (10, 11), (10, 15), (10, 16), (10, 17), (10, 20), (10, 22), (10, 25), (10, 28), (10, 30), (10, 34), (11, 16), (11, 17), (11, 21), (11, 23), (11, 26), (11, 29), (11, 31), (11, 35), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (12, 24), (12, 26), (12, 30), (12, 33), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (13, 20), (13, 25), (13, 27), (13, 31), (13, 34), (14, 15), (14, 16), (14, 17), (14, 19), (14, 20), (14, 21), (14, 24), (14, 26), (14, 28), (14, 32), (14, 35), (15, 16), (15, 17), (15, 20), (15, 21), (15, 22), (15, 25), (15, 27), (15, 29), (15, 30), (15, 33), (16, 17), (16, 21), (16, 22), (16, 23), (16, 26), (16, 28), (16, 31), (16, 34), (17, 22), (17, 23), (17, 27), (17, 29), (17, 32), (17, 35), (18, 19), (18, 20), (18, 21), (18, 22), (18, 23), (18, 24), (18, 25), (18, 30), (18, 32), (19, 20), (19, 21), (19, 22), (19, 23), (19, 24), (19, 25), (19, 26), (19, 31), (19, 33), (20, 21), (20, 22), (20, 23), (20, 25), (20, 26), (20, 27), (20, 30), (20, 32), (20, 34), (21, 22), (21, 23), (21, 26), (21, 27), (21, 28), (21, 31), (21, 33), (21, 35), (22, 23), (22, 27), (22, 28), (22, 29), (22, 32), (22, 34), (23, 28), (23, 29), (23, 33), (23, 35), (24, 25), (24, 26), (24, 27), (24, 28), (24, 29), (24, 30), (24, 31), (25, 26), (25, 27), (25, 28), (25, 29), (25, 30), (25, 31), (25, 32), (26, 27), (26, 28), (26, 29), (26, 31), (26, 32), (26, 33), (27, 28), (27, 29), (27, 32), (27, 33), (27, 34), (28, 29), (28, 33), (28, 34), (28, 35), (29, 34), (29, 35), (30, 31), (30, 32), (30, 33), (30, 34), (30, 35), (31, 32), (31, 33), (31, 34), (31, 35), (32, 33), (32, 34), (32, 35), (33, 34), (33, 35), (34, 35)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 290)
            #expect(graph.chromaticNumber() == 7)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 12), (0, 14), (0, 18), (0, 21), (0, 24), (0, 28), (0, 30), (0, 35), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 13), (1, 15), (1, 19), (1, 22), (1, 25), (1, 29), (1, 31), (2, 3), (2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 12), (2, 14), (2, 16), (2, 20), (2, 23), (2, 26), (2, 32), (3, 4), (3, 5), (3, 8), (3, 9), (3, 10), (3, 13), (3, 15), (3, 17), (3, 18), (3, 21), (3, 27), (3, 33), (4, 5), (4, 9), (4, 10), (4, 11), (4, 14), (4, 16), (4, 19), (4, 22), (4, 24), (4, 28), (4, 34), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (5, 25), (5, 29), (5, 30), (5, 35), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 18), (6, 20), (6, 24), (6, 27), (6, 30), (6, 34), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 19), (7, 21), (7, 25), (7, 28), (7, 31), (7, 35), (8, 9), (8, 10), (8, 11), (8, 13), (8, 14), (8, 15), (8, 18), (8, 20), (8, 22), (8, 26), (8, 29), (8, 32), (9, 10), (9, 11), (9, 14), (9, 15), (9, 16), (9, 19), (9, 21), (9, 23), (9, 24), (9, 27), (9, 33), (10, 11), (10, 15), (10, 16), (10, 17), (10, 20), (10, 22), (10, 25), (10, 28), (10, 30), (10, 34), (11, 16), (11, 17), (11, 21), (11, 23), (11, 26), (11, 29), (11, 31), (11, 35), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (12, 24), (12, 26), (12, 30), (12, 33), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (13, 20), (13, 25), (13, 27), (13, 31), (13, 34), (14, 15), (14, 16), (14, 17), (14, 19), (14, 20), (14, 21), (14, 24), (14, 26), (14, 28), (14, 32), (14, 35), (15, 16), (15, 17), (15, 20), (15, 21), (15, 22), (15, 25), (15, 27), (15, 29), (15, 30), (15, 33), (16, 17), (16, 21), (16, 22), (16, 23), (16, 26), (16, 28), (16, 31), (16, 34), (17, 22), (17, 23), (17, 27), (17, 29), (17, 32), (17, 35), (18, 19), (18, 20), (18, 21), (18, 22), (18, 23), (18, 24), (18, 25), (18, 30), (18, 32), (19, 20), (19, 21), (19, 22), (19, 23), (19, 24), (19, 25), (19, 26), (19, 31), (19, 33), (20, 21), (20, 22), (20, 23), (20, 25), (20, 26), (20, 27), (20, 30), (20, 32), (20, 34), (21, 22), (21, 23), (21, 26), (21, 27), (21, 28), (21, 31), (21, 33), (21, 35), (22, 23), (22, 27), (22, 28), (22, 29), (22, 32), (22, 34), (23, 28), (23, 29), (23, 33), (23, 35), (24, 25), (24, 26), (24, 27), (24, 28), (24, 29), (24, 30), (24, 31), (25, 26), (25, 27), (25, 28), (25, 29), (25, 30), (25, 31), (25, 32), (26, 27), (26, 28), (26, 29), (26, 31), (26, 32), (26, 33), (27, 28), (27, 29), (27, 32), (27, 33), (27, 34), (28, 29), (28, 33), (28, 34), (28, 35), (29, 34), (29, 35), (30, 31), (30, 32), (30, 33), (30, 34), (30, 35), (31, 32), (31, 33), (31, 34), (31, 35), (32, 33), (32, 34), (32, 35), (33, 34), (33, 35), (34, 35)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 290)
            #expect(graph.chromaticNumber() == 7)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 12), (0, 14), (0, 18), (0, 21), (0, 24), (0, 28), (0, 30), (0, 35), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 13), (1, 15), (1, 19), (1, 22), (1, 25), (1, 29), (1, 31), (2, 3), (2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 12), (2, 14), (2, 16), (2, 20), (2, 23), (2, 26), (2, 32), (3, 4), (3, 5), (3, 8), (3, 9), (3, 10), (3, 13), (3, 15), (3, 17), (3, 18), (3, 21), (3, 27), (3, 33), (4, 5), (4, 9), (4, 10), (4, 11), (4, 14), (4, 16), (4, 19), (4, 22), (4, 24), (4, 28), (4, 34), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (5, 25), (5, 29), (5, 30), (5, 35), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 18), (6, 20), (6, 24), (6, 27), (6, 30), (6, 34), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 19), (7, 21), (7, 25), (7, 28), (7, 31), (7, 35), (8, 9), (8, 10), (8, 11), (8, 13), (8, 14), (8, 15), (8, 18), (8, 20), (8, 22), (8, 26), (8, 29), (8, 32), (9, 10), (9, 11), (9, 14), (9, 15), (9, 16), (9, 19), (9, 21), (9, 23), (9, 24), (9, 27), (9, 33), (10, 11), (10, 15), (10, 16), (10, 17), (10, 20), (10, 22), (10, 25), (10, 28), (10, 30), (10, 34), (11, 16), (11, 17), (11, 21), (11, 23), (11, 26), (11, 29), (11, 31), (11, 35), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (12, 24), (12, 26), (12, 30), (12, 33), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (13, 20), (13, 25), (13, 27), (13, 31), (13, 34), (14, 15), (14, 16), (14, 17), (14, 19), (14, 20), (14, 21), (14, 24), (14, 26), (14, 28), (14, 32), (14, 35), (15, 16), (15, 17), (15, 20), (15, 21), (15, 22), (15, 25), (15, 27), (15, 29), (15, 30), (15, 33), (16, 17), (16, 21), (16, 22), (16, 23), (16, 26), (16, 28), (16, 31), (16, 34), (17, 22), (17, 23), (17, 27), (17, 29), (17, 32), (17, 35), (18, 19), (18, 20), (18, 21), (18, 22), (18, 23), (18, 24), (18, 25), (18, 30), (18, 32), (19, 20), (19, 21), (19, 22), (19, 23), (19, 24), (19, 25), (19, 26), (19, 31), (19, 33), (20, 21), (20, 22), (20, 23), (20, 25), (20, 26), (20, 27), (20, 30), (20, 32), (20, 34), (21, 22), (21, 23), (21, 26), (21, 27), (21, 28), (21, 31), (21, 33), (21, 35), (22, 23), (22, 27), (22, 28), (22, 29), (22, 32), (22, 34), (23, 28), (23, 29), (23, 33), (23, 35), (24, 25), (24, 26), (24, 27), (24, 28), (24, 29), (24, 30), (24, 31), (25, 26), (25, 27), (25, 28), (25, 29), (25, 30), (25, 31), (25, 32), (26, 27), (26, 28), (26, 29), (26, 31), (26, 32), (26, 33), (27, 28), (27, 29), (27, 32), (27, 33), (27, 34), (28, 29), (28, 33), (28, 34), (28, 35), (29, 34), (29, 35), (30, 31), (30, 32), (30, 33), (30, 34), (30, 35), (31, 32), (31, 33), (31, 34), (31, 35), (32, 33), (32, 34), (32, 35), (33, 34), (33, 35), (34, 35)]
            let graph = AdjacencyMatrix(vertexCount: 36, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 290)
            #expect(graph.chromaticNumber() == 7)
        }
    }

    @Test("CO-155 grid(4,4): 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co155() {
        // grid(4,4); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-156 nx(dodecahedral_graph): 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co156() {
        // nx(dodecahedral_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-157 nx(icosahedral_graph): 4, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co157() {
        // nx(icosahedral_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-158 nx(octahedral_graph): 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co158() {
        // nx(octahedral_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-159 nx(heawood_graph): 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co159() {
        // nx(heawood_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 21)
            #expect(graph.chromaticNumber() == 2)
        }
    }

    @Test("CO-160 nx(frucht_graph): 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co160() {
        // nx(frucht_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 18)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 18)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 18)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-161 nx(karate_club_graph): 5, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co161() {
        // nx(karate_club_graph); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 78)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 78)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            #expect(graph.chromaticNumber() == 5)
        }
    }

    @Test("CO-162 components: max over components, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co162() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0-1, 1-2, 2-0, 3-4, 5-6, 6-7, 7-8, 8-5, 5-7, 6-8]; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (5, 6), (6, 7), (7, 8), (8, 5), (5, 7), (6, 8)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (5, 6), (6, 7), (7, 8), (8, 5), (5, 7), (6, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (5, 6), (6, 7), (7, 8), (8, 5), (5, 7), (6, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (5, 6), (6, 7), (7, 8), (8, 5), (5, 7), (6, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-163 lcg(14,40,5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co163() {
        // lcg(14,40,5); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 40)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 40)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            #expect(graph.chromaticNumber() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            #expect(graph.chromaticNumber() == 4)
        }
    }

    @Test("CO-164 lcg(16,60,9), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co164() {
        // lcg(16,60,9); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 60)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 60)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 60)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 60)
            #expect(graph.chromaticNumber() == 5)
        }
    }

    @Test("CO-165 lcg(18,70,2), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co165() {
        // lcg(18,70,2); chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(10, 12), (0, 14), (11, 5), (0, 6), (9, 2), (17, 14), (10, 16), (12, 17), (14, 7), (14, 2), (8, 2), (13, 0), (17, 1), (9, 10), (9, 13), (17, 16), (6, 16), (15, 2), (10, 14), (2, 17), (1, 7), (0, 2), (0, 3), (15, 0), (14, 4), (6, 17), (17, 8), (14, 15), (15, 8), (0, 10), (1, 2), (6, 15), (8, 6), (3, 12), (0, 1), (0, 4), (17, 9), (7, 9), (3, 14), (12, 4), (1, 10), (4, 5), (12, 9), (7, 16), (6, 11), (6, 7), (6, 13), (8, 16), (15, 5), (13, 7), (0, 5), (1, 4), (4, 7), (0, 11), (11, 10), (6, 10), (4, 15), (12, 11), (13, 4), (9, 15), (3, 5), (2, 11), (8, 9), (11, 1), (10, 8), (8, 13), (6, 3), (13, 11), (8, 12), (14, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 70)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(10, 12), (0, 14), (11, 5), (0, 6), (9, 2), (17, 14), (10, 16), (12, 17), (14, 7), (14, 2), (8, 2), (13, 0), (17, 1), (9, 10), (9, 13), (17, 16), (6, 16), (15, 2), (10, 14), (2, 17), (1, 7), (0, 2), (0, 3), (15, 0), (14, 4), (6, 17), (17, 8), (14, 15), (15, 8), (0, 10), (1, 2), (6, 15), (8, 6), (3, 12), (0, 1), (0, 4), (17, 9), (7, 9), (3, 14), (12, 4), (1, 10), (4, 5), (12, 9), (7, 16), (6, 11), (6, 7), (6, 13), (8, 16), (15, 5), (13, 7), (0, 5), (1, 4), (4, 7), (0, 11), (11, 10), (6, 10), (4, 15), (12, 11), (13, 4), (9, 15), (3, 5), (2, 11), (8, 9), (11, 1), (10, 8), (8, 13), (6, 3), (13, 11), (8, 12), (14, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 70)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(10, 12), (0, 14), (11, 5), (0, 6), (9, 2), (17, 14), (10, 16), (12, 17), (14, 7), (14, 2), (8, 2), (13, 0), (17, 1), (9, 10), (9, 13), (17, 16), (6, 16), (15, 2), (10, 14), (2, 17), (1, 7), (0, 2), (0, 3), (15, 0), (14, 4), (6, 17), (17, 8), (14, 15), (15, 8), (0, 10), (1, 2), (6, 15), (8, 6), (3, 12), (0, 1), (0, 4), (17, 9), (7, 9), (3, 14), (12, 4), (1, 10), (4, 5), (12, 9), (7, 16), (6, 11), (6, 7), (6, 13), (8, 16), (15, 5), (13, 7), (0, 5), (1, 4), (4, 7), (0, 11), (11, 10), (6, 10), (4, 15), (12, 11), (13, 4), (9, 15), (3, 5), (2, 11), (8, 9), (11, 1), (10, 8), (8, 13), (6, 3), (13, 11), (8, 12), (14, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 70)
            #expect(graph.chromaticNumber() == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(10, 12), (0, 14), (11, 5), (0, 6), (9, 2), (17, 14), (10, 16), (12, 17), (14, 7), (14, 2), (8, 2), (13, 0), (17, 1), (9, 10), (9, 13), (17, 16), (6, 16), (15, 2), (10, 14), (2, 17), (1, 7), (0, 2), (0, 3), (15, 0), (14, 4), (6, 17), (17, 8), (14, 15), (15, 8), (0, 10), (1, 2), (6, 15), (8, 6), (3, 12), (0, 1), (0, 4), (17, 9), (7, 9), (3, 14), (12, 4), (1, 10), (4, 5), (12, 9), (7, 16), (6, 11), (6, 7), (6, 13), (8, 16), (15, 5), (13, 7), (0, 5), (1, 4), (4, 7), (0, 11), (11, 10), (6, 10), (4, 15), (12, 11), (13, 4), (9, 15), (3, 5), (2, 11), (8, 9), (11, 1), (10, 8), (8, 13), (6, 3), (13, 11), (8, 12), (14, 1)]
            let graph = AdjacencyMatrix(vertexCount: 18, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 70)
            #expect(graph.chromaticNumber() == 5)
        }
    }

    @Test("CO-166 odd cycle with a self-loop: 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co166() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-4, 4-0, 2-2]; chromaticNumber()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            #expect(graph.chromaticNumber() == 3)
        }
    }

    @Test("CO-167 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co167() {
        // V []; E []; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect((0 ..< 0).map { coloring.color(ofIndex: $0) } == [])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-168 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co168() {
        // V [0]; E []; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-169 self-loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co169() {
        // V [0]; E [0-0]; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 1).map { coloring.color(ofIndex: $0) } == [0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-170 two isolated, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co170() {
        // V [0, 1]; E []; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect((0 ..< 2).map { coloring.color(ofIndex: $0) } == [0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0])
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-171 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co171() {
        // V [0, 1]; E [0-1]; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 2).map { coloring.color(ofIndex: $0) } == [0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-172 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co172() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; lexicographicallyFirstMinimumColoring()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-173 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co173() {
        // K(3); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 3).map { coloring.color(ofIndex: $0) } == [0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-174 K(5): index order, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co174() {
        // K(5); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 4])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-175 path P(5): bipartition, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co175() {
        // P(5); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-176 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co176() {
        // C(5); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-177 cycle C(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co177() {
        // C(7); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-178 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co178() {
        // wheel(5); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-179 wheel(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co179() {
        // wheel(6); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-180 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co180() {
        // nx(petersen_graph); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 10).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-181 crownx(4): 2 colours, where first fit needs 4, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co181() {
        // crownx(4); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect((0 ..< 8).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-182 first fit not optimal, so the search decides, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co182() {
        // V [0, 1, 2, 3, 4, 5]; E [0-2, 2-3, 3-1, 1-4, 4-5, 5-0, 2-5]; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 6).map { coloring.color(ofIndex: $0) } == [0, 0, 1, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 1, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-183 P4 numbered 0-2-3-1 beside a triangle: each component its own chi, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co183() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-2, 2-3, 3-1, 4-5, 5-6, 6-4]; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 7).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 0, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-184 vertex order, not label order, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co184() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 1])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 1])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-185 nx(mycielski_graph,4): Groetzsch, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co185() {
        // nx(mycielski_graph,4); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 11).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyMatrix(vertexCount: 11, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-186 nx(chvatal_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co186() {
        // nx(chvatal_graph); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-187 queen(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co187() {
        // queen(5); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4, 2, 3, 4, 0, 1, 4, 0, 1, 2, 3, 1, 2, 3, 4, 0, 3, 4, 0, 1, 2])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4, 2, 3, 4, 0, 1, 4, 0, 1, 2, 3, 1, 2, 3, 4, 0, 3, 4, 0, 1, 2])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 25).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 4, 2, 3, 4, 0, 1, 4, 0, 1, 2, 3, 1, 2, 3, 4, 0, 3, 4, 0, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4, 2, 3, 4, 0, 1, 4, 0, 1, 2, 3, 1, 2, 3, 4, 0, 3, 4, 0, 1, 2])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = AdjacencyMatrix(vertexCount: 25, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 4, 2, 3, 4, 0, 1, 4, 0, 1, 2, 3, 1, 2, 3, 4, 0, 3, 4, 0, 1, 2])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-188 nx(dodecahedral_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co188() {
        // nx(dodecahedral_graph); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 20).map { coloring.color(ofIndex: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-189 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co189() {
        // nx(bull_graph); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 0, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-190 nx(house_x_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co190() {
        // nx(house_x_graph); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 5).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 3, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 3, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-191 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co191() {
        // lcg(12,24,1); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 12).map { coloring.color(ofIndex: $0) } == [0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-192 lcg(14,40,5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co192() {
        // lcg(14,40,5); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 2, 3, 3, 3, 0, 0, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 2, 3, 3, 3, 0, 0, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect((0 ..< 14).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 1, 2, 3, 3, 3, 0, 0, 0, 3, 3, 2])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 2, 3, 3, 3, 0, 0, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 1, 2, 3, 3, 3, 0, 0, 0, 3, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-193 lcg(16,60,9), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co193() {
        // lcg(16,60,9); lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 2, 0, 2, 1, 2, 3, 4, 4, 0, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 2, 0, 2, 1, 2, 3, 4, 4, 0, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect((0 ..< 16).map { coloring.color(ofIndex: $0) } == [0, 1, 1, 2, 0, 2, 1, 2, 3, 4, 4, 0, 3, 2, 1, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 2, 0, 2, 1, 2, 3, 4, 4, 0, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 1, 2, 0, 2, 1, 2, 3, 4, 4, 0, 3, 2, 1, 0])
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-194 self-loops ignored in a bigger graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co194() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; lexicographicallyFirstMinimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [0, 1, 2, 0])
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.lexicographicallyFirstMinimumColoring()
            #expect(vertexList.map { coloring.color(of: $0) } == [0, 1, 2, 0])
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }

    @Test("CO-195 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co195() {
        // V []; E []; edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-196 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co196() {
        // V [0]; E []; edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-197 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co197() {
        // V [0, 1]; E [0-1]; edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { Array($0) } == [[0]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { Array($0) } == [[0]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { Array($0) } == [[0]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-198 path P(5): Delta 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co198() {
        // P(5); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3]], [[1, 2], [3, 4]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-199 triangle: class 2, Delta + 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co199() {
        // K(3); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [2]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [2]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [2]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1]], [[0, 2]], [[1, 2]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-200 K(4): class 1, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co200() {
        // K(4); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5], [1, 4], [2], [3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5], [1, 4], [2], [3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5], [1, 4], [2], [3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3]], [[0, 2], [1, 3]], [[0, 3]], [[1, 2]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-201 K(5): class 2, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co201() {
        // K(5); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 1, 2, 3, 0, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 8], [1, 5], [2, 6], [3, 7], [4, 9]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 1, 2, 3, 0, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 8], [1, 5], [2, 6], [3, 7], [4, 9]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 1, 2, 3, 0, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 8], [1, 5], [2, 6], [3, 7], [4, 9]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 1, 2, 3, 0, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 4]], [[0, 2], [1, 3]], [[0, 3], [1, 4]], [[0, 4], [2, 3]], [[1, 2], [3, 4]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-202 cycle C(5): odd, 3, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co202() {
        // C(5); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3], [4]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3], [4]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3], [4]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3]], [[1, 2], [3, 4]], [[4, 0]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-203 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co203() {
        // C(6); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3, 5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3, 5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3, 5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5]], [[1, 2], [3, 4], [5, 0]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-204 star(5): Delta, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co204() {
        // star(5); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [2], [3], [4]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [2], [3], [4]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [2], [3], [4]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1]], [[0, 2]], [[0, 3]], [[0, 4]], [[0, 5]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-205 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co205() {
        // wheel(5); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 0, 1, 0, 1])
            #expect(coloring.colorCount == 6)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 6, 8], [1, 7, 9], [2], [3], [4], [5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 0, 1, 0, 1])
            #expect(coloring.colorCount == 6)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 6, 8], [1, 7, 9], [2], [3], [4], [5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 0, 1, 0, 1])
            #expect(coloring.colorCount == 6)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 6, 8], [1, 7, 9], [2], [3], [4], [5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 0, 1, 0, 1])
            #expect(coloring.colorCount == 6)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5]], [[0, 2], [3, 4], [5, 1]], [[0, 3]], [[0, 4]], [[0, 5]], [[1, 2]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-206 Petersen: class 2, 4 colours, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co206() {
        // nx(petersen_graph); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 4, 5, 9], [1, 3, 8, 10], [0, 6, 11, 13], [7, 12, 14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 4, 5, 9], [1, 3, 8, 10], [0, 6, 11, 13], [7, 12, 14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 4, 5, 9], [1, 3, 8, 10], [0, 6, 11, 13], [7, 12, 14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 5], [1, 6], [2, 3], [4, 9]], [[0, 4], [1, 2], [3, 8], [5, 7]], [[0, 1], [2, 7], [5, 8], [6, 9]], [[3, 4], [6, 8], [7, 9]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-207 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co207() {
        // grid(3,4); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 7, 11, 14, 16], [1, 2, 6, 9, 15], [3, 5, 8, 13], [10, 12]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 7, 11, 14, 16], [1, 2, 6, 9, 15], [3, 5, 8, 13], [10, 12]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 7, 11, 14, 16], [1, 2, 6, 9, 15], [3, 5, 8, 13], [10, 12]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5], [6, 7], [8, 9], [10, 11]], [[0, 4], [1, 2], [3, 7], [5, 6], [9, 10]], [[1, 5], [2, 6], [4, 8], [7, 11]], [[5, 9], [6, 10]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-208 Kb(3,3), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co208() {
        // Kb(3,3); edgeColoring()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 7], [1, 3, 8], [2, 4, 6]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 7], [1, 3, 8], [2, 4, 6]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 9)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 7], [1, 3, 8], [2, 4, 6]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 7], [1, 3, 8], [2, 4, 6]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 3], [1, 5], [2, 4]], [[0, 4], [1, 3], [2, 5]], [[0, 5], [1, 4], [2, 3]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-209 nx(dodecahedral_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co209() {
        // nx(dodecahedral_graph); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 2, 1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 9, 13, 16, 19, 22, 25, 27, 29], [1, 3, 7, 11, 14, 17, 20, 24, 26, 28], [2, 4, 6, 8, 10, 12, 15, 18, 21, 23]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 2, 1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 9, 13, 16, 19, 22, 25, 27, 29], [1, 3, 7, 11, 14, 17, 20, 24, 26, 28], [2, 4, 6, 8, 10, 12, 15, 18, 21, 23]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 2, 1, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 9, 13, 16, 19, 22, 25, 27, 29], [1, 3, 7, 11, 14, 17, 20, 24, 26, 28], [2, 4, 6, 8, 10, 12, 15, 18, 21, 23]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 3, 0, 2, 1, 2, 0, 1, 2, 0, 3, 1, 0, 1, 2, 0, 2, 3, 0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5], [6, 7], [8, 9], [10, 11], [12, 13], [14, 15], [16, 17], [18, 19]], [[0, 10], [1, 2], [3, 4], [5, 6], [7, 8], [9, 13], [11, 12], [15, 16], [17, 18]], [[0, 19], [1, 8], [2, 6], [4, 17], [5, 15], [7, 14], [11, 18], [12, 16]], [[3, 19], [9, 10], [13, 14]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-210 nx(karate_club_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co210() {
        // nx(karate_club_graph); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 78)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 14, 13, 16, 1, 2, 3, 4, 13, 6, 7, 0, 8, 2, 3, 4, 5, 6, 7, 3, 4, 5, 0, 1, 16, 0, 1, 2, 0, 1, 3, 0, 16, 0, 1, 3, 2, 2, 4, 5, 4, 6, 5, 7, 0, 1, 2, 6, 8, 1, 0, 2, 3, 0, 9, 10, 0, 11, 8, 12, 9, 13, 10, 15, 14])
            #expect(coloring.colorCount == 17)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 24, 35, 38, 41, 44, 46, 57, 63, 66, 69], [1, 17, 36, 39, 42, 47, 58, 62], [2, 18, 26, 40, 49, 50, 59, 64], [3, 19, 27, 32, 43, 48, 65], [4, 20, 28, 33, 51, 53], [5, 29, 34, 52, 55], [6, 22, 30, 54, 60], [7, 23, 31, 56], [8, 25, 61, 71], [9, 67, 73], [10, 68, 75], [11, 70], [12, 72], [15, 21, 74], [14, 77], [76], [13, 16, 37, 45]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 78)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 14, 13, 16, 1, 2, 3, 4, 13, 6, 7, 0, 8, 2, 3, 4, 5, 6, 7, 3, 4, 5, 0, 1, 16, 0, 1, 2, 0, 1, 3, 0, 16, 0, 1, 3, 2, 2, 4, 5, 4, 6, 5, 7, 0, 1, 2, 6, 8, 1, 0, 2, 3, 0, 9, 10, 0, 11, 8, 12, 9, 13, 10, 15, 14])
            #expect(coloring.colorCount == 17)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 24, 35, 38, 41, 44, 46, 57, 63, 66, 69], [1, 17, 36, 39, 42, 47, 58, 62], [2, 18, 26, 40, 49, 50, 59, 64], [3, 19, 27, 32, 43, 48, 65], [4, 20, 28, 33, 51, 53], [5, 29, 34, 52, 55], [6, 22, 30, 54, 60], [7, 23, 31, 56], [8, 25, 61, 71], [9, 67, 73], [10, 68, 75], [11, 70], [12, 72], [15, 21, 74], [14, 77], [76], [13, 16, 37, 45]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 14, 13, 16, 1, 2, 3, 4, 13, 6, 7, 0, 8, 2, 3, 4, 5, 6, 7, 3, 4, 5, 0, 1, 16, 0, 1, 2, 0, 1, 3, 0, 16, 0, 1, 3, 2, 2, 4, 5, 4, 6, 5, 7, 0, 1, 2, 6, 8, 1, 0, 2, 3, 0, 9, 10, 0, 11, 8, 12, 9, 13, 10, 15, 14])
            #expect(coloring.colorCount == 17)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 24, 35, 38, 41, 44, 46, 57, 63, 66, 69], [1, 17, 36, 39, 42, 47, 58, 62], [2, 18, 26, 40, 49, 50, 59, 64], [3, 19, 27, 32, 43, 48, 65], [4, 20, 28, 33, 51, 53], [5, 29, 34, 52, 55], [6, 22, 30, 54, 60], [7, 23, 31, 56], [8, 25, 61, 71], [9, 67, 73], [10, 68, 75], [11, 70], [12, 72], [15, 21, 74], [14, 77], [76], [13, 16, 37, 45]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 78)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 14, 13, 16, 1, 2, 3, 4, 13, 6, 7, 0, 8, 2, 3, 4, 5, 6, 7, 3, 4, 5, 0, 1, 16, 0, 1, 2, 0, 1, 3, 0, 16, 0, 1, 3, 2, 2, 4, 5, 4, 6, 5, 7, 0, 1, 2, 6, 8, 1, 0, 2, 3, 0, 9, 10, 0, 11, 8, 12, 9, 13, 10, 15, 14])
            #expect(coloring.colorCount == 17)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 6], [5, 10], [8, 30], [9, 33], [14, 32], [23, 25], [24, 27], [26, 29], [28, 31]], [[0, 2], [1, 3], [4, 10], [5, 16], [8, 32], [14, 33], [23, 27], [24, 25]], [[0, 3], [1, 7], [2, 8], [6, 16], [15, 33], [18, 32], [23, 29], [24, 31]], [[0, 4], [1, 13], [2, 9], [3, 7], [8, 33], [15, 32], [25, 31]], [[0, 5], [1, 17], [2, 13], [3, 12], [18, 33], [20, 32]], [[0, 6], [2, 27], [3, 13], [19, 33], [22, 32]], [[0, 7], [1, 21], [2, 28], [20, 33], [23, 32]], [[0, 8], [1, 30], [2, 32], [22, 33]], [[0, 10], [2, 7], [23, 33], [29, 32]], [[0, 11], [26, 33], [30, 32]], [[0, 12], [27, 33], [31, 32]], [[0, 13], [28, 33]], [[0, 17], [29, 33]], [[0, 31], [1, 19], [30, 33]], [[0, 21], [32, 33]], [[31, 33]], [[0, 19], [1, 2], [5, 6], [13, 33]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-211 edge order matters: C(4) listed 0-1, 2-3, 1-2, 3-0, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co211() {
        // V [0, 1, 2, 3]; E [0-1, 2-3, 1-2, 3-0]; edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1], [2, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1], [2, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2), (3, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1], [2, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3]], [[1, 2], [3, 0]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-212 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co212() {
        // lcg(12,24,1); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1, 2, 0, 4, 3, 1, 1, 3, 3, 1, 2, 4, 3, 0, 4, 2, 5, 0, 2, 6, 5])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 5, 16, 20], [2, 3, 8, 9, 12], [4, 13, 18, 21], [7, 10, 11, 15], [6, 14, 17], [19, 23], [22]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1, 2, 0, 4, 3, 1, 1, 3, 3, 1, 2, 4, 3, 0, 4, 2, 5, 0, 2, 6, 5])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 5, 16, 20], [2, 3, 8, 9, 12], [4, 13, 18, 21], [7, 10, 11, 15], [6, 14, 17], [19, 23], [22]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1, 2, 0, 4, 3, 1, 1, 3, 3, 1, 2, 4, 3, 0, 4, 2, 5, 0, 2, 6, 5])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 5, 16, 20], [2, 3, 8, 9, 12], [4, 13, 18, 21], [7, 10, 11, 15], [6, 14, 17], [19, 23], [22]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 1, 1, 3, 2, 0, 4, 0, 3, 2, 0, 2, 4, 0, 1, 3, 5, 4, 6, 5, 6])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 5], [2, 9], [3, 10], [6, 4], [7, 1]], [[0, 6], [1, 8], [2, 4], [7, 10]], [[0, 8], [2, 7], [4, 9], [6, 10]], [[0, 9], [2, 6], [4, 1], [8, 10]], [[2, 10], [6, 11], [9, 8]], [[9, 6], [10, 11]], [[9, 10], [11, 4]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-213 lcg(20,50,7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co213() {
        // lcg(20,50,7); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 50)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 3, 3, 1, 2, 1, 2, 2, 3, 0, 2, 2, 0, 3, 4, 2, 4, 3, 0, 5, 6, 2, 3, 4, 4, 5, 7, 5, 3, 7, 0, 6, 4, 6, 1, 5, 4, 6, 8])
            #expect(coloring.colorCount == 9)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 3, 4, 6, 20, 23, 29, 41], [2, 5, 7, 8, 9, 11, 14, 16, 45], [10, 15, 17, 18, 21, 22, 26, 32], [12, 13, 19, 24, 28, 33, 39], [25, 27, 34, 35, 43, 47], [30, 36, 38, 46], [31, 42, 44, 48], [37, 40], [49]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 50)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 3, 3, 1, 2, 1, 2, 2, 3, 0, 2, 2, 0, 3, 4, 2, 4, 3, 0, 5, 6, 2, 3, 4, 4, 5, 7, 5, 3, 7, 0, 6, 4, 6, 1, 5, 4, 6, 8])
            #expect(coloring.colorCount == 9)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 3, 4, 6, 20, 23, 29, 41], [2, 5, 7, 8, 9, 11, 14, 16, 45], [10, 15, 17, 18, 21, 22, 26, 32], [12, 13, 19, 24, 28, 33, 39], [25, 27, 34, 35, 43, 47], [30, 36, 38, 46], [31, 42, 44, 48], [37, 40], [49]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 3, 3, 1, 2, 1, 2, 2, 3, 0, 2, 2, 0, 3, 4, 2, 4, 3, 0, 5, 6, 2, 3, 4, 4, 5, 7, 5, 3, 7, 0, 6, 4, 6, 1, 5, 4, 6, 8])
            #expect(coloring.colorCount == 9)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 3, 4, 6, 20, 23, 29, 41], [2, 5, 7, 8, 9, 11, 14, 16, 45], [10, 15, 17, 18, 21, 22, 26, 32], [12, 13, 19, 24, 28, 33, 39], [25, 27, 34, 35, 43, 47], [30, 36, 38, 46], [31, 42, 44, 48], [37, 40], [49]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 50)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 2, 2, 3, 4, 0, 2, 5, 6, 7, 1, 0, 2, 3, 8, 5, 1, 0, 0, 3, 3, 1, 9, 4, 4, 1, 2, 3, 5, 1, 6, 0, 0, 3, 5, 0, 3, 2, 7, 8, 2, 4, 6, 4, 2, 6, 4])
            #expect(coloring.colorCount == 10)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 4], [1, 3], [5, 12], [6, 10], [8, 18], [9, 2], [13, 19], [14, 11], [15, 16]], [[0, 5], [1, 18], [6, 3], [8, 16], [10, 7], [12, 14], [13, 4]], [[2, 1], [3, 0], [5, 13], [7, 6], [12, 15], [16, 11], [17, 8], [18, 10]], [[5, 1], [8, 0], [9, 7], [10, 3], [12, 17], [14, 18], [16, 6]], [[5, 3], [10, 15], [12, 0], [17, 14], [18, 7], [19, 6]], [[5, 14], [8, 10], [12, 18], [15, 4]], [[5, 15], [13, 12], [17, 19], [18, 11]], [[5, 19], [16, 12]], [[8, 5], [16, 13]], [[10, 14]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-214 lcg(30,90,3), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co214() {
        // lcg(30,90,3); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 90)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 6, 1, 1, 1, 4, 0, 2, 1, 2, 0, 0, 3, 1, 3, 0, 0, 3, 3, 8, 4, 5, 4, 2, 0, 2, 5, 8, 1, 4, 2, 4, 1, 4, 6, 6, 1, 7, 8, 1, 4, 0, 0, 6, 1, 2, 2, 5, 3, 3, 3, 12, 7, 1, 6, 2, 6, 4, 8, 4, 0, 3, 8, 5, 5, 0, 6, 8, 1, 5, 9, 9, 10, 7, 3, 2, 6, 10, 2, 11, 9, 2, 5, 2, 9, 8, 7, 6, 7, 0])
            #expect(coloring.colorCount == 13)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 6, 10, 11, 15, 16, 24, 41, 42, 60, 65, 89], [2, 3, 4, 8, 13, 28, 32, 36, 39, 44, 53, 68], [7, 9, 23, 25, 30, 45, 46, 55, 75, 78, 81, 83], [12, 14, 17, 18, 48, 49, 50, 61, 74], [5, 20, 22, 29, 31, 33, 40, 57, 59], [21, 26, 47, 63, 64, 69, 82], [1, 34, 35, 43, 54, 56, 66, 76, 87], [37, 52, 73, 86, 88], [19, 27, 38, 58, 62, 67, 85], [70, 71, 80, 84], [72, 77], [79], [51]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 90)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 6, 1, 1, 1, 4, 0, 2, 1, 2, 0, 0, 3, 1, 3, 0, 0, 3, 3, 8, 4, 5, 4, 2, 0, 2, 5, 8, 1, 4, 2, 4, 1, 4, 6, 6, 1, 7, 8, 1, 4, 0, 0, 6, 1, 2, 2, 5, 3, 3, 3, 12, 7, 1, 6, 2, 6, 4, 8, 4, 0, 3, 8, 5, 5, 0, 6, 8, 1, 5, 9, 9, 10, 7, 3, 2, 6, 10, 2, 11, 9, 2, 5, 2, 9, 8, 7, 6, 7, 0])
            #expect(coloring.colorCount == 13)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 6, 10, 11, 15, 16, 24, 41, 42, 60, 65, 89], [2, 3, 4, 8, 13, 28, 32, 36, 39, 44, 53, 68], [7, 9, 23, 25, 30, 45, 46, 55, 75, 78, 81, 83], [12, 14, 17, 18, 48, 49, 50, 61, 74], [5, 20, 22, 29, 31, 33, 40, 57, 59], [21, 26, 47, 63, 64, 69, 82], [1, 34, 35, 43, 54, 56, 66, 76, 87], [37, 52, 73, 86, 88], [19, 27, 38, 58, 62, 67, 85], [70, 71, 80, 84], [72, 77], [79], [51]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 6, 1, 1, 1, 4, 0, 2, 1, 2, 0, 0, 3, 1, 3, 0, 0, 3, 3, 8, 4, 5, 4, 2, 0, 2, 5, 8, 1, 4, 2, 4, 1, 4, 6, 6, 1, 7, 8, 1, 4, 0, 0, 6, 1, 2, 2, 5, 3, 3, 3, 12, 7, 1, 6, 2, 6, 4, 8, 4, 0, 3, 8, 5, 5, 0, 6, 8, 1, 5, 9, 9, 10, 7, 3, 2, 6, 10, 2, 11, 9, 2, 5, 2, 9, 8, 7, 6, 7, 0])
            #expect(coloring.colorCount == 13)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 6, 10, 11, 15, 16, 24, 41, 42, 60, 65, 89], [2, 3, 4, 8, 13, 28, 32, 36, 39, 44, 53, 68], [7, 9, 23, 25, 30, 45, 46, 55, 75, 78, 81, 83], [12, 14, 17, 18, 48, 49, 50, 61, 74], [5, 20, 22, 29, 31, 33, 40, 57, 59], [21, 26, 47, 63, 64, 69, 82], [1, 34, 35, 43, 54, 56, 66, 76, 87], [37, 52, 73, 86, 88], [19, 27, 38, 58, 62, 67, 85], [70, 71, 80, 84], [72, 77], [79], [51]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
            let graph = AdjacencyMatrix(vertexCount: 30, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 90)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 0, 0, 1, 3, 3, 4, 6, 0, 2, 3, 4, 2, 0, 1, 10, 3, 5, 6, 0, 1, 2, 3, 0, 7, 1, 2, 1, 8, 4, 9, 2, 0, 1, 3, 9, 4, 2, 3, 5, 6, 7, 4, 0, 3, 1, 1, 2, 5, 4, 7, 6, 7, 8, 9, 10, 4, 11, 3, 1, 0, 2, 4, 7, 11, 8, 0, 3, 12, 6, 4, 1, 11, 5, 4, 0, 6, 2, 6, 0, 4, 5, 0, 8, 13, 7, 2, 5])
            #expect(coloring.colorCount == 14)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 16], [1, 20], [2, 4], [5, 18], [6, 3], [7, 9], [8, 17], [11, 19], [15, 13], [21, 10], [23, 28], [25, 24], [26, 22], [27, 29]], [[0, 17], [2, 23], [6, 8], [7, 13], [9, 19], [10, 29], [11, 24], [15, 26], [16, 18], [21, 3], [25, 5]], [[0, 23], [5, 19], [6, 2], [7, 25], [10, 16], [11, 17], [13, 12], [18, 15], [21, 27], [26, 9], [29, 14]], [[2, 27], [3, 0], [5, 21], [6, 18], [7, 26], [11, 25], [13, 19], [15, 16], [20, 17], [23, 29]], [[3, 4], [5, 28], [11, 7], [12, 17], [15, 8], [18, 19], [20, 6], [22, 0], [24, 23], [25, 16], [26, 29]], [[6, 19], [14, 11], [18, 17], [25, 9], [27, 5], [29, 15]], [[5, 16], [6, 28], [14, 18], [19, 1], [24, 15], [25, 27], [26, 11]], [[9, 6], [14, 24], [18, 21], [19, 7], [22, 15], [29, 13]], [[11, 6], [19, 8], [23, 14], [28, 18]], [[11, 16], [12, 6], [19, 15]], [[6, 17], [19, 24]], [[20, 12], [23, 6], [25, 8]], [[24, 6]], [[29, 9]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-217 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co217() throws {
        // V []; E []; bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { Array($0) } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [])
            #expect(coloring.colorCount == 0)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-218 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co218() throws {
        // V [0, 1]; E [0-1]; bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { Array($0) } == [[0]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { Array($0) } == [[0]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { Array($0) } == [[0]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0])
            #expect(coloring.colorCount == 1)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-219 path P(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co219() throws {
        // P(6); bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5]], [[1, 2], [3, 4]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-220 cycle C(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co220() throws {
        // C(6); bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3, 5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3, 5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 2, 4], [1, 3, 5]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 1])
            #expect(coloring.colorCount == 2)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5]], [[1, 2], [3, 4], [5, 0]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-221 Kb(3,3): Latin square, on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co221() throws {
        // Kb(3,3); bipartiteEdgeColoring()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[1, 5, 6], [2, 3, 7], [0, 4, 8]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 9)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[1, 5, 6], [2, 3, 7], [0, 4, 8]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 9)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[1, 5, 6], [2, 3, 7], [0, 4, 8]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[1, 5, 6], [2, 3, 7], [0, 4, 8]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 9)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 4], [1, 5], [2, 3]], [[0, 5], [1, 3], [2, 4]], [[0, 3], [1, 4], [2, 5]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-222 Kb(2,4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co222() throws {
        // Kb(2,4); bipartiteEdgeColoring()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 2, 3, 0, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[3, 4], [0, 5], [1, 6], [2, 7]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 2, 3, 0, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[3, 4], [0, 5], [1, 6], [2, 7]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 2, 3, 0, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[3, 4], [0, 5], [1, 6], [2, 7]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 2, 3, 0, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[3, 4], [0, 5], [1, 6], [2, 7]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 2, 3, 0, 0, 1, 2, 3])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 5], [1, 2]], [[0, 2], [1, 3]], [[0, 3], [1, 4]], [[0, 4], [1, 5]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-223 crown(4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co223() throws {
        // crown(4); bipartiteEdgeColoring()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 8, 9], [1, 5, 6, 10], [2, 3, 7, 11]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 8, 9], [1, 5, 6, 10], [2, 3, 7, 11]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 8, 9], [1, 5, 6, 10], [2, 3, 7, 11]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 8, 9], [1, 5, 6, 10], [2, 3, 7, 11]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 5], [1, 6], [2, 7], [3, 4]], [[0, 6], [1, 7], [2, 4], [3, 5]], [[0, 7], [1, 4], [2, 5], [3, 6]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-224 grid(3,4), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co224() throws {
        // grid(3,4); bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 17)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 7, 11, 14, 16], [1, 2, 6, 9, 15], [3, 5, 8, 13], [10, 12]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 17)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 7, 11, 14, 16], [1, 2, 6, 9, 15], [3, 5, 8, 13], [10, 12]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 4, 7, 11, 14, 16], [1, 2, 6, 9, 15], [3, 5, 8, 13], [10, 12]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 17)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 1], [2, 3], [4, 5], [6, 7], [8, 9], [10, 11]], [[0, 4], [1, 2], [3, 7], [5, 6], [9, 10]], [[1, 5], [2, 6], [4, 8], [7, 11]], [[5, 9], [6, 10]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-225 nx(heawood_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co225() throws {
        // nx(heawood_graph); bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 21)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 9, 12, 15, 18, 20], [1, 3, 7, 11, 14, 17, 19], [2, 4, 6, 8, 10, 13, 16]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 21)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 9, 12, 15, 18, 20], [1, 3, 7, 11, 14, 17, 19], [2, 4, 6, 8, 10, 13, 16]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 21)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 0])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 5, 9, 12, 15, 18, 20], [1, 3, 7, 11, 14, 17, 19], [2, 4, 6, 8, 10, 13, 16]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 21)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 1, 0, 1, 0, 0, 2, 1, 2, 0, 2, 2, 0, 1, 1, 0, 2, 1, 2, 0, 1])
            #expect(coloring.colorCount == 3)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 13], [1, 10], [2, 3], [4, 5], [6, 7], [8, 9], [11, 12]], [[0, 5], [1, 2], [3, 4], [6, 11], [7, 8], [9, 10], [12, 13]], [[0, 1], [2, 7], [3, 12], [4, 9], [5, 6], [8, 13], [10, 11]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-226 bipartite multigraph: parallel edges need different colours, on no indices")
    func co226() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2, 0-1]; bipartiteEdgeColoring()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 3, 2])
            #expect(coloring.colorCount == 4)
            #expect(coloring.colorClasses.map { Array($0) } == [[0], [1], [3], [2]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-227 lcgb(6,6,20,4), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co227() throws {
        // lcgb(6,6,20,4); bipartiteEdgeColoring()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(2, 10), (4, 11), (5, 11), (1, 11), (1, 8), (2, 8), (5, 7), (0, 7), (0, 10), (2, 7), (3, 10), (2, 11), (1, 6), (3, 8), (4, 8), (2, 9), (0, 9), (4, 6), (3, 6), (1, 7)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 9, 10, 12, 14, 16], [0, 1, 4, 7, 18], [3, 5, 6, 8, 17], [11, 13, 19], [15]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 10), (4, 11), (5, 11), (1, 11), (1, 8), (2, 8), (5, 7), (0, 7), (0, 10), (2, 7), (3, 10), (2, 11), (1, 6), (3, 8), (4, 8), (2, 9), (0, 9), (4, 6), (3, 6), (1, 7)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 9, 10, 12, 14, 16], [0, 1, 4, 7, 18], [3, 5, 6, 8, 17], [11, 13, 19], [15]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 10), (4, 11), (5, 11), (1, 11), (1, 8), (2, 8), (5, 7), (0, 7), (0, 10), (2, 7), (3, 10), (2, 11), (1, 6), (3, 8), (4, 8), (2, 9), (0, 9), (4, 6), (3, 6), (1, 7)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 9, 10, 12, 14, 16], [0, 1, 4, 7, 18], [3, 5, 6, 8, 17], [11, 13, 19], [15]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 10), (4, 11), (5, 11), (1, 11), (1, 8), (2, 8), (5, 7), (0, 7), (0, 10), (2, 7), (3, 10), (2, 11), (1, 6), (3, 8), (4, 8), (2, 9), (0, 9), (4, 6), (3, 6), (1, 7)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { Array($0) } == [[2, 9, 10, 12, 14, 16], [0, 1, 4, 7, 18], [3, 5, 6, 8, 17], [11, 13, 19], [15]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 10), (4, 11), (5, 11), (1, 11), (1, 8), (2, 8), (5, 7), (0, 7), (0, 10), (2, 7), (3, 10), (2, 11), (1, 6), (3, 8), (4, 8), (2, 9), (0, 9), (4, 6), (3, 6), (1, 7)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [3, 1, 2, 1, 2, 0, 3, 1, 2, 0, 3, 4, 2, 3, 0, 0, 1, 2, 0, 1])
            #expect(coloring.colorCount == 5)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[1, 8], [2, 9], [3, 10], [4, 6], [5, 7]], [[0, 9], [1, 6], [2, 7], [4, 8], [5, 11]], [[0, 10], [1, 7], [2, 8], [3, 6], [4, 11]], [[0, 7], [1, 11], [2, 10], [3, 8]], [[2, 11]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-228 lcgb(8,5,30,11), on UndirectedAdjacencyList, ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co228() throws {
        // lcgb(8,5,30,11); bipartiteEdgeColoring()
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 5, 3, 3, 1, 2, 1, 4, 0, 0, 0, 4, 4, 3, 6, 2, 2, 1, 3, 5, 3, 5, 4, 1, 5, 2, 1, 4, 0, 0])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[8, 9, 10, 28, 29], [4, 6, 17, 23, 26], [0, 5, 15, 16, 25], [2, 3, 13, 18, 20], [7, 11, 12, 22, 27], [1, 19, 21, 24], [14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 5, 3, 3, 1, 2, 1, 4, 0, 0, 0, 4, 4, 3, 6, 2, 2, 1, 3, 5, 3, 5, 4, 1, 5, 2, 1, 4, 0, 0])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[8, 9, 10, 28, 29], [4, 6, 17, 23, 26], [0, 5, 15, 16, 25], [2, 3, 13, 18, 20], [7, 11, 12, 22, 27], [1, 19, 21, 24], [14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 5, 3, 3, 1, 2, 1, 4, 0, 0, 0, 4, 4, 3, 6, 2, 2, 1, 3, 5, 3, 5, 4, 1, 5, 2, 1, 4, 0, 0])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[8, 9, 10, 28, 29], [4, 6, 17, 23, 26], [0, 5, 15, 16, 25], [2, 3, 13, 18, 20], [7, 11, 12, 22, 27], [1, 19, 21, 24], [14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [2, 5, 3, 3, 1, 2, 1, 4, 0, 0, 0, 4, 4, 3, 6, 2, 2, 1, 3, 5, 3, 5, 4, 1, 5, 2, 1, 4, 0, 0])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { Array($0) } == [[8, 9, 10, 28, 29], [4, 6, 17, 23, 26], [0, 5, 15, 16, 25], [2, 3, 13, 18, 20], [7, 11, 12, 22, 27], [1, 19, 21, 24], [14]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 13, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [3, 4, 2, 0, 4, 5, 1, 3, 2, 1, 0, 4, 5, 3, 4, 6, 0, 2, 5, 4, 1, 2, 3, 5, 0, 1, 2, 3, 0, 1])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 11], [2, 10], [3, 12], [6, 8], [7, 9]], [[1, 10], [2, 8], [4, 12], [6, 9], [7, 11]], [[0, 10], [1, 12], [4, 9], [5, 8], [6, 11]], [[0, 8], [1, 11], [3, 9], [5, 10], [6, 12]], [[0, 9], [1, 8], [2, 12], [3, 10], [4, 11]], [[1, 9], [3, 8], [4, 10], [5, 11]], [[3, 11]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-229 triangle: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co229() {
        // K(3); bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
    }

    @Test("CO-230 self-loop: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co230() {
        // V [0, 1]; E [0-1, 1-1]; bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
    }

    @Test("CO-231 Petersen: nil, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co231() {
        // nx(petersen_graph); bipartiteEdgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }
    }

    @Test("CO-232 empty colouring of the empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co232() {
        // V []; E []; isVertexColoring { [][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let given = [] as [Int]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let given = [] as [Int]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let given = [] as [Int]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let given = [] as [Int]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-233 one colour on an edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co233() {
        // V [0, 1]; E [0-1]; isVertexColoring { [0, 0][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
    }

    @Test("CO-234 two colours on an edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co234() {
        // V [0, 1]; E [0-1]; isVertexColoring { [0, 1][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let given = [0, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-235 self-loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co235() {
        // V [0]; E [0-0]; isVertexColoring { [0][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let given = [0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let given = [0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let given = [0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let given = [0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-236 self-loop ignored with a proper rest, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co236() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; isVertexColoring { [0, 1, 2, 0][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let given = [0, 1, 2, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let given = [0, 1, 2, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let given = [0, 1, 2, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let given = [0, 1, 2, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-237 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co237() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isVertexColoring { [0, 1, 0][$0] }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 0]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-238 triangle with a repeat, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co238() {
        // K(3); isVertexColoring { [0, 1, 1][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [0, 1, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == false)
        }
    }

    @Test("CO-239 colours need not be 0..<k or contiguous, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co239() {
        // P(3); isVertexColoring { [7, -2, 7][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [7, -2, 7]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [7, -2, 7]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [7, -2, 7]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let given = [7, -2, 7]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-240 Petersen, a greedy colouring, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co240() {
        // nx(petersen_graph); isVertexColoring { [0, 1, 0, 1, 2, 1, 0, 2, 2, 1][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let given = [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let given = [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let given = [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let given = [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]
            #expect(graph.isVertexColoring { given[vertexList.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-241 empty, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co241() {
        // V []; E []; isEdgeColoring { [][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let given = [] as [Int]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let given = [] as [Int]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let given = [] as [Int]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [] as [Int]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-242 path, alternating, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co242() {
        // P(4); isEdgeColoring { [0, 1, 0][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let given = [0, 1, 0]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let given = [0, 1, 0]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let given = [0, 1, 0]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [0, 1, 0]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-243 path, repeat at a shared end, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co243() {
        // P(4); isEdgeColoring { [0, 0, 1][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let given = [0, 0, 1]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let given = [0, 0, 1]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let given = [0, 0, 1]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [0, 0, 1]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == false)
        }
    }

    @Test("CO-244 parallel edges share both ends, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co244() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isEdgeColoring { [0, 0, 1][$0] }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let given = [0, 0, 1]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let given = [0, 0, 1]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [0, 0, 1]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == false)
        }
    }

    @Test("CO-245 parallel edges, distinct, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co245() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isEdgeColoring { [0, 1, 2][$0] }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let given = [0, 1, 2]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let given = [0, 1, 2]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [0, 1, 2]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-246 a self-loop meets the other edges at its vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co246() {
        // V [0, 1]; E [0-0, 0-1]; isEdgeColoring { [0, 0][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 2)
            let given = [0, 0]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 2)
            let given = [0, 0]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            let given = [0, 0]
            #expect(graph.isEdgeColoring { given[$0] } == false)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 2)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [0, 0]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == false)
        }
    }

    @Test("CO-247 a self-loop alone, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co247() {
        // V [0]; E [0-0]; isEdgeColoring { [0][$0] }
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let given = [0]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let given = [0]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let given = [0]
            #expect(graph.isEdgeColoring { given[$0] } == true)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            // The catalog's colours moved to the cells' row-major positions.
            let given = [0]
            let cells = Array(graph.edges.indices)
            #expect(graph.isEdgeColoring { given[cells.firstIndex(of: $0)!] } == true)
        }
    }

    @Test("CO-253 lcgb(8,5,30,11): Delta + 1 on a bipartite graph (bipartiteEdgeColoring gives Delta, CO-228), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co253() {
        // lcgb(8,5,30,11); edgeColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 0, 2, 1, 2, 3, 0, 4, 0, 4, 3, 1, 3, 3, 5, 2, 1, 1, 4, 4, 5, 3, 4, 6, 2, 7, 5, 5])
            #expect(coloring.colorCount == 8)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 3, 8, 10], [2, 5, 13, 18, 19], [4, 6, 17, 26], [7, 12, 14, 15, 23], [9, 11, 20, 21, 24], [16, 22, 28, 29], [25], [27]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 0, 2, 1, 2, 3, 0, 4, 0, 4, 3, 1, 3, 3, 5, 2, 1, 1, 4, 4, 5, 3, 4, 6, 2, 7, 5, 5])
            #expect(coloring.colorCount == 8)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 3, 8, 10], [2, 5, 13, 18, 19], [4, 6, 17, 26], [7, 12, 14, 15, 23], [9, 11, 20, 21, 24], [16, 22, 28, 29], [25], [27]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 0, 2, 1, 2, 3, 0, 4, 0, 4, 3, 1, 3, 3, 5, 2, 1, 1, 4, 4, 5, 3, 4, 6, 2, 7, 5, 5])
            #expect(coloring.colorCount == 8)
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 3, 8, 10], [2, 5, 13, 18, 19], [4, 6, 17, 26], [7, 12, 14, 15, 23], [9, 11, 20, 21, 24], [16, 22, 28, 29], [25], [27]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 13, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let coloring = graph.edgeColoring()
            #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2, 3, 1, 2, 3, 0, 4, 2, 0, 1, 3, 4, 1, 2, 0, 0, 4, 1, 2, 4, 5, 6, 6, 5, 4, 3, 3, 5])
            #expect(coloring.colorCount == 7)
            #expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == [[[0, 8], [1, 11], [2, 10], [3, 12], [4, 9]], [[0, 9], [1, 8], [2, 12], [3, 10], [4, 11]], [[0, 10], [1, 9], [2, 8], [3, 11], [4, 12]], [[0, 11], [1, 10], [3, 8], [6, 12], [7, 9]], [[1, 12], [3, 9], [4, 10], [5, 8], [6, 11]], [[5, 10], [6, 9], [7, 11]], [[5, 11], [6, 8]]])
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        }
    }

    @Test("CO-254 empty graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co254() {
        // V []; E []; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 0)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 0)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [])
        }
    }

    @Test("CO-255 one vertex, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co255() {
        // V [0]; E []; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
    }

    @Test("CO-256 self-loop ignored, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co256() {
        // V [0]; E [0-0]; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0])
        }
    }

    @Test("CO-257 two isolated, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co257() {
        // V [0, 1]; E []; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = []
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 0)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 1)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 0])
        }
    }

    @Test("CO-258 one edge, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co258() {
        // V [0, 1]; E [0-1]; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 1)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1])
        }
    }

    @Test("CO-259 parallel edges, on no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co259() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumColoring()
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0])
        }
    }

    @Test("CO-260 triangle, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co260() {
        // K(3); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 3)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2])
        }
    }

    @Test("CO-261 K(5): index order, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co261() {
        // K(5); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 3, 4])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 3, 4])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 3, 4])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 3, 4])
        }
    }

    @Test("CO-262 path P(5): bipartition, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co262() {
        // P(5); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 4)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0])
        }
    }

    @Test("CO-263 cycle C(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co263() {
        // C(5); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-264 cycle C(7), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co264() {
        // C(7); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-265 wheel(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co265() {
        // wheel(5); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 10)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-266 wheel(6), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co266() {
        // wheel(6); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1, 2, 1, 2])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1, 2, 1, 2])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1, 2, 1, 2])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1, 2, 1, 2])
        }
    }

    @Test("CO-267 Petersen, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co267() {
        // nx(petersen_graph); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 15)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-268 crownx(4): 2 colours, where first fit needs 4, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co268() {
        // crownx(4); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1])
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1])
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 12)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 2)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1])
        }
    }

    @Test("CO-269 first fit not optimal, so the search decides, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co269() {
        // V [0, 1, 2, 3, 4, 5]; E [0-2, 2-3, 3-1, 1-4, 4-5, 5-0, 2-5]; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 7)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-270 P4 numbered 0-2-3-1 beside a triangle: each component its own chi, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co270() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-2, 2-3, 3-1, 4-5, 5-6, 6-4]; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-271 vertex order, not label order, on ReferencePseudograph, no indices, AdjacencyList.undirected")
    func co271() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = ReferencePseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1])
        }
        do { // no indices
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1])
        }
        do { // AdjacencyList.undirected
            let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
            #expect(colors == [0, 1, 2, 1])
        }
    }

    @Test("CO-272 nx(mycielski_graph,4): Groetzsch, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co272() {
        // nx(mycielski_graph,4); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let graph = AdjacencyMatrix(vertexCount: 11, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 20)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-273 nx(chvatal_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co273() {
        // nx(chvatal_graph); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-274 queen(5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co274() {
        // queen(5); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
            let graph = AdjacencyMatrix(vertexCount: 25, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 160)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-275 nx(dodecahedral_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co275() {
        // nx(dodecahedral_graph); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
            let graph = AdjacencyMatrix(vertexCount: 20, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 30)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-276 nx(bull_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co276() {
        // nx(bull_graph); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 5)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-277 nx(house_x_graph), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co277() {
        // nx(house_x_graph); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 8)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-278 lcg(12,24,1), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co278() {
        // lcg(12,24,1); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 24)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-279 lcg(14,40,5), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co279() {
        // lcg(14,40,5); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
            let graph = AdjacencyMatrix(vertexCount: 14, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 40)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 4)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-280 lcg(16,60,9), on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co280() {
        // lcg(16,60,9); minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 60)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 5)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }

    @Test("CO-281 self-loops ignored in a bigger graph, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func co281() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; minimumColoring()
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let n = vertexList.count
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyList.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeCount == 6)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            let coloring = graph.minimumColoring()
            let colors = vertexList.map { coloring.color(of: $0) }
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
            // after the one below it.
            var high = -1
            for c in colors {
                #expect(c <= high + 1, "\(colors)")
                high = max(high, c)
            }
        }
    }
}
