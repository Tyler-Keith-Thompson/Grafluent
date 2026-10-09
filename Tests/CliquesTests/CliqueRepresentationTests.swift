// The same answers on every representation. Every catalog test already runs on the
// `ReferencePseudograph` as the catalog writes it, and on `graph.directed.undirected`; this file
// runs each undirected catalog graph of §A – §E on `UndirectedAdjacencyList` (repeated edges
// inserted once, which leaves the simple graph and its row order unchanged), on
// `AdjacencyList.undirected` with each edge as one arc as written (rows: out-neighbours, then
// in-neighbours), and, for graphs on 0..<n, on `CompressedSparseRow` holding each edge as two arcs
// (read through a conformer private to this file, rows ascending) and on `AdjacencyMatrix.undirected`
// (successors, then predecessors, each ascending). It also runs a few graphs on conformers private to
// this file: without indices, with vertex indices only, with rows reversed, and with `Collider`
// vertices that all hash alike. Each test checks every entry point. Answers that do not depend on
// row order (the cliques as a set, ω, the maximum clique, core numbers, triangles, clustering) are the
// catalog's; the degeneracy ordering depends on row order (api.md: neighbours in row order), so it
// was computed with `ref.py`'s Batagelj–Zaversnik on the simple rows each representation stores,
// as were all literals here. Case IDs (CQ-nnn) name the catalog rows on each graph; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import Cliques
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

/// An undirected graph stored in a `CompressedSparseRow` that holds each edge `{u, v}` as the arcs
/// `u→v` and `v→u` (a loop as one arc). Each arc is an edge of this graph at the arc's position, so
/// every edge between distinct vertices appears twice (a parallel pair) and the simple graph is the
/// one given. A vertex's incidence row is its out-arcs, then the arcs into it from its successors,
/// both ascending by neighbour, so a loop's arc is listed twice.
private struct SymmetricCSRGraph: Graph {
    let csr: CompressedSparseRow

    init(vertexCount: Int, edges: [(Int, Int)]) {
        let arcs = edges.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] }
        self.csr = CompressedSparseRow(vertexCount: vertexCount, edges: arcs)
    }

    var vertices: Range<Int> { csr.vertices }
    var edges: [UndirectedEdge<Int>] { csr.edges.map { UndirectedEdge($0.source, $0.target) } }

    /// The position of the arc `from → to`.
    private func position(from: Int, to: Int) -> Int {
        let row = csr.offsets[from] ..< csr.offsets[from + 1]
        return row.first { csr.targets[$0] == to }!
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        Array(csr.outEdges(of: vertex)) + csr.successors(of: vertex).map { position(from: $0, to: vertex) }
    }
    func neighbors(of vertex: Int) -> [Int] { Array(csr.successors(of: vertex)) + Array(csr.successors(of: vertex)) }
    func contains(_ vertex: Int) -> Bool { csr.contains(vertex) }
    var vertexIndexBound: Int? { csr.vertexCount }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { csr.edgeCount }
    func edgeIndex(of position: Int) -> Int { position }
}

/// An undirected pseudograph with no vertex or edge indices, rows in position order (a self-loop
/// twice), so the algorithms number vertices through a dictionary.
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

/// Vertex indices (the positions in `vertices`) but no edge indices, rows in position order.
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

/// An undirected pseudograph whose incidence rows are reversed (the catalog's `~rev`): each row
/// is built in position order (a self-loop twice), then reversed. Vertex and edge indices are
/// positions.
private struct ReversedRowsPseudograph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>]) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { Array(inOrder.incidentEdges(of: $0).reversed()) }
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Cliques on every representation")
struct CliqueRepresentationTests {
    @Test("CQ-001, CQ-002 … CQ-061 on UndirectedAdjacencyList (repeats inserted once): U: []")
    func undirectedAdjacencyList01() {
        // U: []
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: [], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = []
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [])
        #expect(graph.cliqueNumber() == 0)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = []
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = []
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = []
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = []
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-011, CQ-012 … CQ-069 on UndirectedAdjacencyList (repeats inserted once): U: [0]")
    func undirectedAdjacencyList02() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-021, CQ-022 … CQ-064 on UndirectedAdjacencyList (repeats inserted once): U: [0] 0-0")
    func undirectedAdjacencyList03() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-031, CQ-032 … CQ-065 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1]")
    func undirectedAdjacencyList04() {
        // U: [0, 1]
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1])
        #expect(cores.kShell(0) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-041, CQ-042 … CQ-050 on UndirectedAdjacencyList (repeats inserted once): U: 0-1")
    func undirectedAdjacencyList05() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-051, CQ-052 … CQ-060 on UndirectedAdjacencyList (repeats inserted once): U: 0-1, 0-1, 1-0")
    func undirectedAdjacencyList06() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-101, CQ-301 … CQ-466 on UndirectedAdjacencyList (repeats inserted once): U: K(0..2), 2-3")
    func undirectedAdjacencyList07() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [3, 0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(1) == [3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.5833333333333334)
        #expect(values.averageClustering == 0.5833333333333334)
    }

    @Test("CQ-103 on UndirectedAdjacencyList (repeats inserted once): U: K(4)")
    func undirectedAdjacencyList08() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(3) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 4)
        #expect(values.triangleCount == 4)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-104, CQ-406 … CQ-410 on UndirectedAdjacencyList (repeats inserted once): U: K(5)")
    func undirectedAdjacencyList09() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 4])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [4, 4, 4, 4, 4]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(4) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [6, 6, 6, 6, 6]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 10)
        #expect(values.triangleCount == 10)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-105, CQ-426 … CQ-430 on UndirectedAdjacencyList (repeats inserted once): U: C(0..3)")
    func undirectedAdjacencyList10() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [0, 3], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-106, CQ-307 … CQ-309 on UndirectedAdjacencyList (repeats inserted once): U: C(0..4)")
    func undirectedAdjacencyList11() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-107, CQ-304 … CQ-306 on UndirectedAdjacencyList (repeats inserted once): U: P(0..4)")
    func undirectedAdjacencyList12() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [3, 4], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 4, 1, 3, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-108, CQ-310 … CQ-312 on UndirectedAdjacencyList (repeats inserted once): U: S(0;1..4)")
    func undirectedAdjacencyList13() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [0, 2], [0, 3], [0, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-109 on UndirectedAdjacencyList (repeats inserted once): U: S(4;0..3)")
    func undirectedAdjacencyList14() {
        // U: S(4;0..3)
        let pairs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
        let graph = UndirectedAdjacencyList(vertices: [4, 0, 1, 2, 3], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[4, 0], [4, 1], [4, 2], [4, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [4, 0])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [4, 0, 1, 2, 3])
        #expect(cores.kShell(1) == [4, 0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-110, CQ-411 … CQ-415 on UndirectedAdjacencyList (repeats inserted once): U: K(0..2), K(2..4)")
    func undirectedAdjacencyList15() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 3, 4, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-111, CQ-316 … CQ-420 on UndirectedAdjacencyList (repeats inserted once): U: K(0..2), 1-3, 2-3")
    func undirectedAdjacencyList16() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 2, 2, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 0.6666666666666666, 0.6666666666666666, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333333)
        #expect(values.averageClustering == 0.8333333333333333)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on UndirectedAdjacencyList (repeats inserted once): U: S(0;1..5), C(1..5)")
    func undirectedAdjacencyList17() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-113, CQ-209 … CQ-210 on UndirectedAdjacencyList (repeats inserted once): U: KB(0..2;3..5)")
    func undirectedAdjacencyList18() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList(vertices: [0, 3, 4, 5, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 3, 4, 5, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 3, 4, 5, 1, 2])
        #expect(cores.kShell(3) == [0, 3, 4, 5, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-114 on UndirectedAdjacencyList (repeats inserted once): U: moon(2)")
    func undirectedAdjacencyList19() {
        // U: moon(2)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-115 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1, 2] K(3..5)")
    func undirectedAdjacencyList20() {
        // U: [0, 1, 2] K(3..5)
        let pairs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1], [2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [3, 4, 5])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [3, 4, 5])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 0.5)
        #expect(values.averageClustering == 0.5)
    }

    @Test("CQ-116 on UndirectedAdjacencyList (repeats inserted once): U: [0] 0-0, 1-1, 1-2")
    func undirectedAdjacencyList21() {
        // U: [0] 0-0, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on UndirectedAdjacencyList (repeats inserted once): U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func undirectedAdjacencyList22() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-118 on UndirectedAdjacencyList (repeats inserted once): U: a-b, b-c, c-a, c-d, d-e, e-c")
    func undirectedAdjacencyList23() {
        // U: a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = UndirectedAdjacencyList(vertices: ["a", "b", "c", "d", "e"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[String]] = [["a", "b", "c"], ["c", "d", "e"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["a", "b", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["a", "b", "d", "e", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["a", "b", "c", "d", "e"])
        #expect(cores.kShell(2) == ["a", "b", "c", "d", "e"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-119 on UndirectedAdjacencyList (repeats inserted once): U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c")
    func undirectedAdjacencyList24() {
        // U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = UndirectedAdjacencyList(vertices: ["e", "d", "c", "b", "a"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[String]] = [["e", "d", "c"], ["c", "b", "a"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["e", "d", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["e", "d", "b", "a", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["e", "d", "c", "b", "a"])
        #expect(cores.kShell(2) == ["e", "d", "c", "b", "a"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-120, CQ-322 … CQ-435 on UndirectedAdjacencyList (repeats inserted once): U: nx(petersen)")
    func undirectedAdjacencyList25() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7],
            [5, 8], [6, 8], [6, 9], [7, 9]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on UndirectedAdjacencyList (repeats inserted once): U: nx(karate_club)")
    func undirectedAdjacencyList26() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30],
            [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            30, 7, 32, 33, 8, 1, 3, 13, 0, 2
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-122 on UndirectedAdjacencyList (repeats inserted once): U: K(0..3), K(3..6), 0-6")
    func undirectedAdjacencyList27() {
        // U: K(0..3), K(3..6), 0-6
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6),
            (5, 6), (0, 6)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 4, 5, 0, 3, 6]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [4, 3, 3, 7, 3, 3, 4]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6666666666666666, 1.0, 1.0, 0.4666666666666667, 1.0, 1.0, 0.6666666666666666]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 9)
        #expect(values.triangleCount == 9)
        #expect(graph.transitivity() == 0.6923076923076923)
        #expect(values.transitivity == 0.6923076923076923)
        #expect(graph.averageClustering() == 0.8285714285714285)
        #expect(values.averageClustering == 0.8285714285714285)
    }

    @Test("CQ-124 on UndirectedAdjacencyList (repeats inserted once): U: moon(4)")
    func undirectedAdjacencyList28() {
        // U: moon(4)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 3), (1, 4),
            (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6),
            (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11),
            (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10),
            (5, 11), (6, 9), (6, 10), (6, 11), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 3, 6, 9], [0, 3, 6, 10], [0, 3, 6, 11], [0, 3, 7, 9], [0, 3, 7, 10], [0, 3, 7, 11],
            [0, 3, 8, 9], [0, 3, 8, 10], [0, 3, 8, 11], [0, 4, 6, 9], [0, 4, 6, 10], [0, 4, 6, 11],
            [0, 4, 7, 9], [0, 4, 7, 10], [0, 4, 7, 11], [0, 4, 8, 9], [0, 4, 8, 10], [0, 4, 8, 11],
            [0, 5, 6, 9], [0, 5, 6, 10], [0, 5, 6, 11], [0, 5, 7, 9], [0, 5, 7, 10], [0, 5, 7, 11],
            [0, 5, 8, 9], [0, 5, 8, 10], [0, 5, 8, 11], [1, 3, 6, 9], [1, 3, 6, 10], [1, 3, 6, 11],
            [1, 3, 7, 9], [1, 3, 7, 10], [1, 3, 7, 11], [1, 3, 8, 9], [1, 3, 8, 10], [1, 3, 8, 11],
            [1, 4, 6, 9], [1, 4, 6, 10], [1, 4, 6, 11], [1, 4, 7, 9], [1, 4, 7, 10], [1, 4, 7, 11],
            [1, 4, 8, 9], [1, 4, 8, 10], [1, 4, 8, 11], [1, 5, 6, 9], [1, 5, 6, 10], [1, 5, 6, 11],
            [1, 5, 7, 9], [1, 5, 7, 10], [1, 5, 7, 11], [1, 5, 8, 9], [1, 5, 8, 10], [1, 5, 8, 11],
            [2, 3, 6, 9], [2, 3, 6, 10], [2, 3, 6, 11], [2, 3, 7, 9], [2, 3, 7, 10], [2, 3, 7, 11],
            [2, 3, 8, 9], [2, 3, 8, 10], [2, 3, 8, 11], [2, 4, 6, 9], [2, 4, 6, 10], [2, 4, 6, 11],
            [2, 4, 7, 9], [2, 4, 7, 10], [2, 4, 7, 11], [2, 4, 8, 9], [2, 4, 8, 10], [2, 4, 8, 11],
            [2, 5, 6, 9], [2, 5, 6, 10], [2, 5, 6, 11], [2, 5, 7, 9], [2, 5, 7, 10], [2, 5, 7, 11],
            [2, 5, 8, 9], [2, 5, 8, 10], [2, 5, 8, 11]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6, 9])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 9)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 108)
        #expect(values.triangleCount == 108)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.75)
        #expect(values.averageClustering == 0.75)
    }

    @Test("CQ-201, CQ-202 on UndirectedAdjacencyList (repeats inserted once): U: K(0..2), K(3..5)")
    func undirectedAdjacencyList29() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-203, CQ-204 on UndirectedAdjacencyList (repeats inserted once): U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)")
    func undirectedAdjacencyList30() {
        // U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[5, 4, 3], [2, 1, 0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [5, 4, 3])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [5, 4, 3, 2, 1, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [5, 4, 3, 2, 1, 0])
        #expect(cores.kShell(2) == [5, 4, 3, 2, 1, 0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-205, CQ-206 on UndirectedAdjacencyList (repeats inserted once): U: K(3..5), K(0..2)")
    func undirectedAdjacencyList31() {
        // U: K(3..5), K(0..2)
        let pairs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5), (0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: [3, 4, 5, 0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[3, 4, 5], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [3, 4, 5])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [3, 4, 5, 0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [3, 4, 5, 0, 1, 2])
        #expect(cores.kShell(2) == [3, 4, 5, 0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-207, CQ-208 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1, 2]")
    func undirectedAdjacencyList32() {
        // U: [0, 1, 2]
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1], [2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-215, CQ-216 on UndirectedAdjacencyList (repeats inserted once): U: C(0..4), K(5..8)")
    func undirectedAdjacencyList33() {
        // U: C(0..4), K(5..8)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)
        ]
        let graph = UndirectedAdjacencyList(vertices: [5, 6, 7, 8, 0, 1, 2, 3, 4], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4], [5, 6, 7, 8]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [5, 6, 7, 8])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [5, 6, 7, 8])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 4)
        #expect(values.triangleCount == 4)
        #expect(graph.transitivity() == 0.7058823529411765)
        #expect(values.transitivity == 0.7058823529411765)
        #expect(graph.averageClustering() == 0.4444444444444444)
        #expect(values.averageClustering == 0.4444444444444444)
    }

    @Test("CQ-217, CQ-218 on UndirectedAdjacencyList (repeats inserted once): U: moon(3)")
    func undirectedAdjacencyList34() {
        // U: moon(3)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
            (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 6), (3, 7), (3, 8), (4, 6),
            (4, 7), (4, 8), (5, 6), (5, 7), (5, 8)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 3, 6], [0, 3, 7], [0, 3, 8], [0, 4, 6], [0, 4, 7], [0, 4, 8], [0, 5, 6], [0, 5, 7],
            [0, 5, 8], [1, 3, 6], [1, 3, 7], [1, 3, 8], [1, 4, 6], [1, 4, 7], [1, 4, 8], [1, 5, 6],
            [1, 5, 7], [1, 5, 8], [2, 3, 6], [2, 3, 7], [2, 3, 8], [2, 4, 6], [2, 4, 7], [2, 4, 8],
            [2, 5, 6], [2, 5, 7], [2, 5, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [6, 6, 6, 6, 6, 6, 6, 6, 6]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 6)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(cores.kShell(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 27)
        #expect(values.triangleCount == 27)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6)
        #expect(values.averageClustering == 0.6)
    }

    @Test("CQ-219, CQ-220 on UndirectedAdjacencyList (repeats inserted once): U: P(0..3), 3-3, 3-3")
    func undirectedAdjacencyList35() {
        // U: P(0..3), 3-3, 3-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [2, 3], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on UndirectedAdjacencyList (repeats inserted once): U: K(4), 3-4, 4-5, 5-6, 6-4")
    func undirectedAdjacencyList36() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-325, CQ-326 … CQ-327 on UndirectedAdjacencyList (repeats inserted once): U: grid(3,4)")
    func undirectedAdjacencyList37() {
        // U: grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [2, 3], [3, 7], [4, 8], [8, 9], [7, 11], [10, 11], [1, 2], [1, 5], [4, 5],
            [2, 6], [6, 7], [5, 9], [9, 10], [6, 10], [5, 6]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 8, 11, 1, 4, 2, 7, 9, 10, 5, 6]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-328, CQ-329 … CQ-330 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1] 0-1, 0-1")
    func undirectedAdjacencyList38() {
        // U: [0, 1] 0-1, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-331, CQ-332 … CQ-333 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1] 0-1, 0-0, 1-1")
    func undirectedAdjacencyList39() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-441, CQ-442 … CQ-445 on UndirectedAdjacencyList (repeats inserted once): U: 0-1, 1-2, 2-0, 0-1, 1-1")
    func undirectedAdjacencyList40() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-446, CQ-447 … CQ-450 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1, 2, 3]")
    func undirectedAdjacencyList41() {
        // U: [0, 1, 2, 3]
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1], [2], [3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2, 3])
        #expect(cores.kShell(0) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-451, CQ-452 … CQ-455 on UndirectedAdjacencyList (repeats inserted once): U: P(0..2)")
    func undirectedAdjacencyList42() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 2, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2])
        #expect(cores.kShell(1) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-456, CQ-457 … CQ-460 on UndirectedAdjacencyList (repeats inserted once): U: [0, 1] 0-1, 2-3")
    func undirectedAdjacencyList43() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-001, CQ-002 … CQ-061 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: []")
    func adjacencyListUndirected01() {
        // U: []
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyList(vertices: [], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = []
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [])
        #expect(graph.cliqueNumber() == 0)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = []
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = []
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = []
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = []
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-011, CQ-012 … CQ-069 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0]")
    func adjacencyListUndirected02() {
        // U: [0]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyList(vertices: 0 ..< 1, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-021, CQ-022 … CQ-064 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0] 0-0")
    func adjacencyListUndirected03() {
        // U: [0] 0-0
        let arcs: [(Int, Int)] = [(0, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 1, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-031, CQ-032 … CQ-065 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1]")
    func adjacencyListUndirected04() {
        // U: [0, 1]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1])
        #expect(cores.kShell(0) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-041, CQ-042 … CQ-050 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: 0-1")
    func adjacencyListUndirected05() {
        // U: 0-1
        let arcs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-051, CQ-052 … CQ-060 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: 0-1, 0-1, 1-0")
    func adjacencyListUndirected06() {
        // U: 0-1, 0-1, 1-0
        let arcs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-101, CQ-301 … CQ-466 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(0..2), 2-3")
    func adjacencyListUndirected07() {
        // U: K(0..2), 2-3
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [3, 0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(1) == [3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.5833333333333334)
        #expect(values.averageClustering == 0.5833333333333334)
    }

    @Test("CQ-103 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(4)")
    func adjacencyListUndirected08() {
        // U: K(4)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(3) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 4)
        #expect(values.triangleCount == 4)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-104, CQ-406 … CQ-410 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(5)")
    func adjacencyListUndirected09() {
        // U: K(5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 4])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [4, 4, 4, 4, 4]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(4) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [6, 6, 6, 6, 6]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 10)
        #expect(values.triangleCount == 10)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-105, CQ-426 … CQ-430 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: C(0..3)")
    func adjacencyListUndirected10() {
        // U: C(0..3)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 3], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-106, CQ-307 … CQ-309 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: C(0..4)")
    func adjacencyListUndirected11() {
        // U: C(0..4)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-107, CQ-304 … CQ-306 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: P(0..4)")
    func adjacencyListUndirected12() {
        // U: P(0..4)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [3, 4], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 4, 1, 3, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-108, CQ-310 … CQ-312 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: S(0;1..4)")
    func adjacencyListUndirected13() {
        // U: S(0;1..4)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 2], [0, 3], [0, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-109 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: S(4;0..3)")
    func adjacencyListUndirected14() {
        // U: S(4;0..3)
        let arcs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
        let graph = AdjacencyList(vertices: [4, 0, 1, 2, 3], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[4, 0], [4, 1], [4, 2], [4, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [4, 0])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [4, 0, 1, 2, 3])
        #expect(cores.kShell(1) == [4, 0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-110, CQ-411 … CQ-415 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(0..2), K(2..4)")
    func adjacencyListUndirected15() {
        // U: K(0..2), K(2..4)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 3, 4, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-111, CQ-316 … CQ-420 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(0..2), 1-3, 2-3")
    func adjacencyListUndirected16() {
        // U: K(0..2), 1-3, 2-3
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 2, 2, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 0.6666666666666666, 0.6666666666666666, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333333)
        #expect(values.averageClustering == 0.8333333333333333)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: S(0;1..5), C(1..5)")
    func adjacencyListUndirected17() {
        // U: S(0;1..5), C(1..5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-113, CQ-209 … CQ-210 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: KB(0..2;3..5)")
    func adjacencyListUndirected18() {
        // U: KB(0..2;3..5)
        let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = AdjacencyList(vertices: [0, 3, 4, 5, 1, 2], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 3, 4, 5, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 3, 4, 5, 1, 2])
        #expect(cores.kShell(3) == [0, 3, 4, 5, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-114 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: moon(2)")
    func adjacencyListUndirected19() {
        // U: moon(2)
        let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-115 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1, 2] K(3..5)")
    func adjacencyListUndirected20() {
        // U: [0, 1, 2] K(3..5)
        let arcs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1], [2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [3, 4, 5])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [3, 4, 5])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 0.5)
        #expect(values.averageClustering == 0.5)
    }

    @Test("CQ-116 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0] 0-0, 1-1, 1-2")
    func adjacencyListUndirected21() {
        // U: [0] 0-0, 1-1, 1-2
        let arcs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func adjacencyListUndirected22() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-118 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: a-b, b-c, c-a, c-d, d-e, e-c")
    func adjacencyListUndirected23() {
        // U: a-b, b-c, c-a, c-d, d-e, e-c
        let arcs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = AdjacencyList(vertices: ["a", "b", "c", "d", "e"], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[String]] = [["a", "b", "c"], ["c", "d", "e"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["a", "b", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["a", "b", "d", "e", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["a", "b", "c", "d", "e"])
        #expect(cores.kShell(2) == ["a", "b", "c", "d", "e"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-119 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c")
    func adjacencyListUndirected24() {
        // U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c
        let arcs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = AdjacencyList(vertices: ["e", "d", "c", "b", "a"], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[String]] = [["e", "d", "c"], ["c", "b", "a"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["e", "d", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["e", "d", "b", "a", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["e", "d", "c", "b", "a"])
        #expect(cores.kShell(2) == ["e", "d", "c", "b", "a"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-120, CQ-322 … CQ-435 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: nx(petersen)")
    func adjacencyListUndirected25() {
        // U: nx(petersen)
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = AdjacencyList(vertices: 0 ..< 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7],
            [5, 8], [6, 8], [6, 9], [7, 9]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: nx(karate_club)")
    func adjacencyListUndirected26() {
        // U: nx(karate_club)
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = AdjacencyList(vertices: 0 ..< 34, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [0, 1, 2, 3, 7],
            [1, 30], [8, 30, 32, 33], [2, 8, 32], [13, 33], [0, 1, 2, 3, 13], [0, 2, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            7, 30, 32, 33, 3, 1, 8, 13, 0, 2
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-122 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(0..3), K(3..6), 0-6")
    func adjacencyListUndirected27() {
        // U: K(0..3), K(3..6), 0-6
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6),
            (5, 6), (0, 6)
        ]
        let graph = AdjacencyList(vertices: 0 ..< 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 4, 5, 0, 6, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [4, 3, 3, 7, 3, 3, 4]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6666666666666666, 1.0, 1.0, 0.4666666666666667, 1.0, 1.0, 0.6666666666666666]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 9)
        #expect(values.triangleCount == 9)
        #expect(graph.transitivity() == 0.6923076923076923)
        #expect(values.transitivity == 0.6923076923076923)
        #expect(graph.averageClustering() == 0.8285714285714285)
        #expect(values.averageClustering == 0.8285714285714285)
    }

    @Test("CQ-124 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: moon(4)")
    func adjacencyListUndirected28() {
        // U: moon(4)
        let arcs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 3), (1, 4),
            (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6),
            (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11),
            (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10),
            (5, 11), (6, 9), (6, 10), (6, 11), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11)
        ]
        let graph = AdjacencyList(vertices: 0 ..< 12, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 3, 6, 9], [0, 3, 6, 10], [0, 3, 6, 11], [0, 3, 7, 9], [0, 3, 7, 10], [0, 3, 7, 11],
            [0, 3, 8, 9], [0, 3, 8, 10], [0, 3, 8, 11], [0, 4, 6, 9], [0, 4, 6, 10], [0, 4, 6, 11],
            [0, 4, 7, 9], [0, 4, 7, 10], [0, 4, 7, 11], [0, 4, 8, 9], [0, 4, 8, 10], [0, 4, 8, 11],
            [0, 5, 6, 9], [0, 5, 6, 10], [0, 5, 6, 11], [0, 5, 7, 9], [0, 5, 7, 10], [0, 5, 7, 11],
            [0, 5, 8, 9], [0, 5, 8, 10], [0, 5, 8, 11], [1, 3, 6, 9], [1, 3, 6, 10], [1, 3, 6, 11],
            [1, 3, 7, 9], [1, 3, 7, 10], [1, 3, 7, 11], [1, 3, 8, 9], [1, 3, 8, 10], [1, 3, 8, 11],
            [1, 4, 6, 9], [1, 4, 6, 10], [1, 4, 6, 11], [1, 4, 7, 9], [1, 4, 7, 10], [1, 4, 7, 11],
            [1, 4, 8, 9], [1, 4, 8, 10], [1, 4, 8, 11], [1, 5, 6, 9], [1, 5, 6, 10], [1, 5, 6, 11],
            [1, 5, 7, 9], [1, 5, 7, 10], [1, 5, 7, 11], [1, 5, 8, 9], [1, 5, 8, 10], [1, 5, 8, 11],
            [2, 3, 6, 9], [2, 3, 6, 10], [2, 3, 6, 11], [2, 3, 7, 9], [2, 3, 7, 10], [2, 3, 7, 11],
            [2, 3, 8, 9], [2, 3, 8, 10], [2, 3, 8, 11], [2, 4, 6, 9], [2, 4, 6, 10], [2, 4, 6, 11],
            [2, 4, 7, 9], [2, 4, 7, 10], [2, 4, 7, 11], [2, 4, 8, 9], [2, 4, 8, 10], [2, 4, 8, 11],
            [2, 5, 6, 9], [2, 5, 6, 10], [2, 5, 6, 11], [2, 5, 7, 9], [2, 5, 7, 10], [2, 5, 7, 11],
            [2, 5, 8, 9], [2, 5, 8, 10], [2, 5, 8, 11]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6, 9])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 9)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 108)
        #expect(values.triangleCount == 108)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.75)
        #expect(values.averageClustering == 0.75)
    }

    @Test("CQ-201, CQ-202 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(0..2), K(3..5)")
    func adjacencyListUndirected29() {
        // U: K(0..2), K(3..5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-203, CQ-204 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)")
    func adjacencyListUndirected30() {
        // U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyList(vertices: [5, 4, 3, 2, 1, 0], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[5, 4, 3], [2, 1, 0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [5, 4, 3])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [5, 4, 3, 2, 1, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [5, 4, 3, 2, 1, 0])
        #expect(cores.kShell(2) == [5, 4, 3, 2, 1, 0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-205, CQ-206 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(3..5), K(0..2)")
    func adjacencyListUndirected31() {
        // U: K(3..5), K(0..2)
        let arcs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5), (0, 1), (0, 2), (1, 2)]
        let graph = AdjacencyList(vertices: [3, 4, 5, 0, 1, 2], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[3, 4, 5], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [3, 4, 5])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [3, 4, 5, 0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [3, 4, 5, 0, 1, 2])
        #expect(cores.kShell(2) == [3, 4, 5, 0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-207, CQ-208 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1, 2]")
    func adjacencyListUndirected32() {
        // U: [0, 1, 2]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1], [2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-215, CQ-216 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: C(0..4), K(5..8)")
    func adjacencyListUndirected33() {
        // U: C(0..4), K(5..8)
        let arcs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)
        ]
        let graph = AdjacencyList(vertices: [5, 6, 7, 8, 0, 1, 2, 3, 4], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4], [5, 6, 7, 8]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [5, 6, 7, 8])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [5, 6, 7, 8])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 4)
        #expect(values.triangleCount == 4)
        #expect(graph.transitivity() == 0.7058823529411765)
        #expect(values.transitivity == 0.7058823529411765)
        #expect(graph.averageClustering() == 0.4444444444444444)
        #expect(values.averageClustering == 0.4444444444444444)
    }

    @Test("CQ-217, CQ-218 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: moon(3)")
    func adjacencyListUndirected34() {
        // U: moon(3)
        let arcs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
            (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 6), (3, 7), (3, 8), (4, 6),
            (4, 7), (4, 8), (5, 6), (5, 7), (5, 8)
        ]
        let graph = AdjacencyList(vertices: 0 ..< 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 3, 6], [0, 3, 7], [0, 3, 8], [0, 4, 6], [0, 4, 7], [0, 4, 8], [0, 5, 6], [0, 5, 7],
            [0, 5, 8], [1, 3, 6], [1, 3, 7], [1, 3, 8], [1, 4, 6], [1, 4, 7], [1, 4, 8], [1, 5, 6],
            [1, 5, 7], [1, 5, 8], [2, 3, 6], [2, 3, 7], [2, 3, 8], [2, 4, 6], [2, 4, 7], [2, 4, 8],
            [2, 5, 6], [2, 5, 7], [2, 5, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [6, 6, 6, 6, 6, 6, 6, 6, 6]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 6)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(cores.kShell(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 27)
        #expect(values.triangleCount == 27)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6)
        #expect(values.averageClustering == 0.6)
    }

    @Test("CQ-219, CQ-220 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: P(0..3), 3-3, 3-3")
    func adjacencyListUndirected35() {
        // U: P(0..3), 3-3, 3-3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [2, 3], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: K(4), 3-4, 4-5, 5-6, 6-4")
    func adjacencyListUndirected36() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = AdjacencyList(vertices: 0 ..< 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-325, CQ-326 … CQ-327 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: grid(3,4)")
    func adjacencyListUndirected37() {
        // U: grid(3,4)
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = AdjacencyList(vertices: 0 ..< 12, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [2, 3], [3, 7], [4, 8], [8, 9], [7, 11], [10, 11], [1, 2], [1, 5], [4, 5],
            [6, 7], [2, 6], [5, 9], [9, 10], [6, 10], [5, 6]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 8, 11, 1, 4, 7, 2, 9, 10, 5, 6]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-328, CQ-329 … CQ-330 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1] 0-1, 0-1")
    func adjacencyListUndirected38() {
        // U: [0, 1] 0-1, 0-1
        let arcs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-331, CQ-332 … CQ-333 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1] 0-1, 0-0, 1-1")
    func adjacencyListUndirected39() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let arcs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-441, CQ-442 … CQ-445 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: 0-1, 1-2, 2-0, 0-1, 1-1")
    func adjacencyListUndirected40() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-446, CQ-447 … CQ-450 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1, 2, 3]")
    func adjacencyListUndirected41() {
        // U: [0, 1, 2, 3]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1], [2], [3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2, 3])
        #expect(cores.kShell(0) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-451, CQ-452 … CQ-455 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: P(0..2)")
    func adjacencyListUndirected42() {
        // U: P(0..2)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 2, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2])
        #expect(cores.kShell(1) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-456, CQ-457 … CQ-460 on AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours): U: [0, 1] 0-1, 2-3")
    func adjacencyListUndirected43() {
        // U: [0, 1] 0-1, 2-3
        let arcs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-001, CQ-002 … CQ-061 on CompressedSparseRow (each edge as two arcs; rows ascending): U: []")
    func compressedSparseRow01() {
        // U: []
        let pairs: [(Int, Int)] = []
        let graph = SymmetricCSRGraph(vertexCount: 0, edges: pairs)
        let expectedCliques: [[Int]] = []
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [])
        #expect(graph.cliqueNumber() == 0)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = []
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = []
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = []
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = []
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-011, CQ-012 … CQ-069 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0]")
    func compressedSparseRow02() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = SymmetricCSRGraph(vertexCount: 1, edges: pairs)
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-021, CQ-022 … CQ-064 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0] 0-0")
    func compressedSparseRow03() {
        // U: [0] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = SymmetricCSRGraph(vertexCount: 1, edges: pairs)
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-031, CQ-032 … CQ-065 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1]")
    func compressedSparseRow04() {
        // U: [0, 1]
        let pairs: [(Int, Int)] = []
        let graph = SymmetricCSRGraph(vertexCount: 2, edges: pairs)
        let expectedCliques: [[Int]] = [[0], [1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1])
        #expect(cores.kShell(0) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-041, CQ-042 … CQ-050 on CompressedSparseRow (each edge as two arcs; rows ascending): U: 0-1")
    func compressedSparseRow05() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = SymmetricCSRGraph(vertexCount: 2, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-051, CQ-052 … CQ-060 on CompressedSparseRow (each edge as two arcs; rows ascending): U: 0-1, 0-1, 1-0")
    func compressedSparseRow06() {
        // U: 0-1, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = SymmetricCSRGraph(vertexCount: 2, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-101, CQ-301 … CQ-466 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(0..2), 2-3")
    func compressedSparseRow07() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [3, 0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(1) == [3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.5833333333333334)
        #expect(values.averageClustering == 0.5833333333333334)
    }

    @Test("CQ-103 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(4)")
    func compressedSparseRow08() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(3) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 4)
        #expect(values.triangleCount == 4)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-104, CQ-406 … CQ-410 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(5)")
    func compressedSparseRow09() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = SymmetricCSRGraph(vertexCount: 5, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 4])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [4, 4, 4, 4, 4]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(4) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [6, 6, 6, 6, 6]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 10)
        #expect(values.triangleCount == 10)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-105, CQ-426 … CQ-430 on CompressedSparseRow (each edge as two arcs; rows ascending): U: C(0..3)")
    func compressedSparseRow10() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [0, 3], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-106, CQ-307 … CQ-309 on CompressedSparseRow (each edge as two arcs; rows ascending): U: C(0..4)")
    func compressedSparseRow11() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = SymmetricCSRGraph(vertexCount: 5, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-107, CQ-304 … CQ-306 on CompressedSparseRow (each edge as two arcs; rows ascending): U: P(0..4)")
    func compressedSparseRow12() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = SymmetricCSRGraph(vertexCount: 5, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [3, 4], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 4, 1, 3, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-108, CQ-310 … CQ-312 on CompressedSparseRow (each edge as two arcs; rows ascending): U: S(0;1..4)")
    func compressedSparseRow13() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = SymmetricCSRGraph(vertexCount: 5, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [0, 2], [0, 3], [0, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-110, CQ-411 … CQ-415 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(0..2), K(2..4)")
    func compressedSparseRow14() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = SymmetricCSRGraph(vertexCount: 5, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2], [2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 3, 4, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-111, CQ-316 … CQ-420 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(0..2), 1-3, 2-3")
    func compressedSparseRow15() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2], [1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 2, 2, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 0.6666666666666666, 0.6666666666666666, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333333)
        #expect(values.averageClustering == 0.8333333333333333)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on CompressedSparseRow (each edge as two arcs; rows ascending): U: S(0;1..5), C(1..5)")
    func compressedSparseRow16() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = SymmetricCSRGraph(vertexCount: 6, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-114 on CompressedSparseRow (each edge as two arcs; rows ascending): U: moon(2)")
    func compressedSparseRow17() {
        // U: moon(2)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = SymmetricCSRGraph(vertexCount: 6, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-115 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1, 2] K(3..5)")
    func compressedSparseRow18() {
        // U: [0, 1, 2] K(3..5)
        let pairs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5)]
        let graph = SymmetricCSRGraph(vertexCount: 6, edges: pairs)
        let expectedCliques: [[Int]] = [[0], [1], [2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [3, 4, 5])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [3, 4, 5])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 0.5)
        #expect(values.averageClustering == 0.5)
    }

    @Test("CQ-116 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0] 0-0, 1-1, 1-2")
    func compressedSparseRow19() {
        // U: [0] 0-0, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = SymmetricCSRGraph(vertexCount: 3, edges: pairs)
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on CompressedSparseRow (each edge as two arcs; rows ascending): U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func compressedSparseRow20() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = SymmetricCSRGraph(vertexCount: 3, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-120, CQ-322 … CQ-435 on CompressedSparseRow (each edge as two arcs; rows ascending): U: nx(petersen)")
    func compressedSparseRow21() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = SymmetricCSRGraph(vertexCount: 10, edges: pairs)
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7],
            [5, 8], [6, 8], [6, 9], [7, 9]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on CompressedSparseRow (each edge as two arcs; rows ascending): U: nx(karate_club)")
    func compressedSparseRow22() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = SymmetricCSRGraph(vertexCount: 34, edges: pairs)
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30],
            [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            30, 7, 32, 33, 8, 1, 3, 13, 0, 2
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-122 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(0..3), K(3..6), 0-6")
    func compressedSparseRow23() {
        // U: K(0..3), K(3..6), 0-6
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6),
            (5, 6), (0, 6)
        ]
        let graph = SymmetricCSRGraph(vertexCount: 7, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 4, 5, 0, 3, 6]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [4, 3, 3, 7, 3, 3, 4]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6666666666666666, 1.0, 1.0, 0.4666666666666667, 1.0, 1.0, 0.6666666666666666]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 9)
        #expect(values.triangleCount == 9)
        #expect(graph.transitivity() == 0.6923076923076923)
        #expect(values.transitivity == 0.6923076923076923)
        #expect(graph.averageClustering() == 0.8285714285714285)
        #expect(values.averageClustering == 0.8285714285714285)
    }

    @Test("CQ-124 on CompressedSparseRow (each edge as two arcs; rows ascending): U: moon(4)")
    func compressedSparseRow24() {
        // U: moon(4)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 3), (1, 4),
            (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6),
            (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11),
            (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10),
            (5, 11), (6, 9), (6, 10), (6, 11), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11)
        ]
        let graph = SymmetricCSRGraph(vertexCount: 12, edges: pairs)
        let expectedCliques: [[Int]] = [
            [0, 3, 6, 9], [0, 3, 6, 10], [0, 3, 6, 11], [0, 3, 7, 9], [0, 3, 7, 10], [0, 3, 7, 11],
            [0, 3, 8, 9], [0, 3, 8, 10], [0, 3, 8, 11], [0, 4, 6, 9], [0, 4, 6, 10], [0, 4, 6, 11],
            [0, 4, 7, 9], [0, 4, 7, 10], [0, 4, 7, 11], [0, 4, 8, 9], [0, 4, 8, 10], [0, 4, 8, 11],
            [0, 5, 6, 9], [0, 5, 6, 10], [0, 5, 6, 11], [0, 5, 7, 9], [0, 5, 7, 10], [0, 5, 7, 11],
            [0, 5, 8, 9], [0, 5, 8, 10], [0, 5, 8, 11], [1, 3, 6, 9], [1, 3, 6, 10], [1, 3, 6, 11],
            [1, 3, 7, 9], [1, 3, 7, 10], [1, 3, 7, 11], [1, 3, 8, 9], [1, 3, 8, 10], [1, 3, 8, 11],
            [1, 4, 6, 9], [1, 4, 6, 10], [1, 4, 6, 11], [1, 4, 7, 9], [1, 4, 7, 10], [1, 4, 7, 11],
            [1, 4, 8, 9], [1, 4, 8, 10], [1, 4, 8, 11], [1, 5, 6, 9], [1, 5, 6, 10], [1, 5, 6, 11],
            [1, 5, 7, 9], [1, 5, 7, 10], [1, 5, 7, 11], [1, 5, 8, 9], [1, 5, 8, 10], [1, 5, 8, 11],
            [2, 3, 6, 9], [2, 3, 6, 10], [2, 3, 6, 11], [2, 3, 7, 9], [2, 3, 7, 10], [2, 3, 7, 11],
            [2, 3, 8, 9], [2, 3, 8, 10], [2, 3, 8, 11], [2, 4, 6, 9], [2, 4, 6, 10], [2, 4, 6, 11],
            [2, 4, 7, 9], [2, 4, 7, 10], [2, 4, 7, 11], [2, 4, 8, 9], [2, 4, 8, 10], [2, 4, 8, 11],
            [2, 5, 6, 9], [2, 5, 6, 10], [2, 5, 6, 11], [2, 5, 7, 9], [2, 5, 7, 10], [2, 5, 7, 11],
            [2, 5, 8, 9], [2, 5, 8, 10], [2, 5, 8, 11]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6, 9])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 9)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 108)
        #expect(values.triangleCount == 108)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.75)
        #expect(values.averageClustering == 0.75)
    }

    @Test("CQ-201, CQ-202 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(0..2), K(3..5)")
    func compressedSparseRow25() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = SymmetricCSRGraph(vertexCount: 6, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-207, CQ-208 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1, 2]")
    func compressedSparseRow26() {
        // U: [0, 1, 2]
        let pairs: [(Int, Int)] = []
        let graph = SymmetricCSRGraph(vertexCount: 3, edges: pairs)
        let expectedCliques: [[Int]] = [[0], [1], [2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-217, CQ-218 on CompressedSparseRow (each edge as two arcs; rows ascending): U: moon(3)")
    func compressedSparseRow27() {
        // U: moon(3)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
            (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 6), (3, 7), (3, 8), (4, 6),
            (4, 7), (4, 8), (5, 6), (5, 7), (5, 8)
        ]
        let graph = SymmetricCSRGraph(vertexCount: 9, edges: pairs)
        let expectedCliques: [[Int]] = [
            [0, 3, 6], [0, 3, 7], [0, 3, 8], [0, 4, 6], [0, 4, 7], [0, 4, 8], [0, 5, 6], [0, 5, 7],
            [0, 5, 8], [1, 3, 6], [1, 3, 7], [1, 3, 8], [1, 4, 6], [1, 4, 7], [1, 4, 8], [1, 5, 6],
            [1, 5, 7], [1, 5, 8], [2, 3, 6], [2, 3, 7], [2, 3, 8], [2, 4, 6], [2, 4, 7], [2, 4, 8],
            [2, 5, 6], [2, 5, 7], [2, 5, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [6, 6, 6, 6, 6, 6, 6, 6, 6]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 6)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(cores.kShell(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 27)
        #expect(values.triangleCount == 27)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6)
        #expect(values.averageClustering == 0.6)
    }

    @Test("CQ-219, CQ-220 on CompressedSparseRow (each edge as two arcs; rows ascending): U: P(0..3), 3-3, 3-3")
    func compressedSparseRow28() {
        // U: P(0..3), 3-3, 3-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [2, 3], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on CompressedSparseRow (each edge as two arcs; rows ascending): U: K(4), 3-4, 4-5, 5-6, 6-4")
    func compressedSparseRow29() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = SymmetricCSRGraph(vertexCount: 7, edges: pairs)
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-325, CQ-326 … CQ-327 on CompressedSparseRow (each edge as two arcs; rows ascending): U: grid(3,4)")
    func compressedSparseRow30() {
        // U: grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = SymmetricCSRGraph(vertexCount: 12, edges: pairs)
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [2, 3], [3, 7], [4, 8], [8, 9], [7, 11], [10, 11], [1, 2], [1, 5], [4, 5],
            [2, 6], [6, 7], [5, 9], [9, 10], [6, 10], [5, 6]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 8, 11, 1, 4, 2, 7, 9, 10, 5, 6]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-328, CQ-329 … CQ-330 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1] 0-1, 0-1")
    func compressedSparseRow31() {
        // U: [0, 1] 0-1, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = SymmetricCSRGraph(vertexCount: 2, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-331, CQ-332 … CQ-333 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1] 0-1, 0-0, 1-1")
    func compressedSparseRow32() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = SymmetricCSRGraph(vertexCount: 2, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-441, CQ-442 … CQ-445 on CompressedSparseRow (each edge as two arcs; rows ascending): U: 0-1, 1-2, 2-0, 0-1, 1-1")
    func compressedSparseRow33() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = SymmetricCSRGraph(vertexCount: 3, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-446, CQ-447 … CQ-450 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1, 2, 3]")
    func compressedSparseRow34() {
        // U: [0, 1, 2, 3]
        let pairs: [(Int, Int)] = []
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[0], [1], [2], [3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2, 3])
        #expect(cores.kShell(0) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-451, CQ-452 … CQ-455 on CompressedSparseRow (each edge as two arcs; rows ascending): U: P(0..2)")
    func compressedSparseRow35() {
        // U: P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = SymmetricCSRGraph(vertexCount: 3, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 2, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2])
        #expect(cores.kShell(1) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-456, CQ-457 … CQ-460 on CompressedSparseRow (each edge as two arcs; rows ascending): U: [0, 1] 0-1, 2-3")
    func compressedSparseRow36() {
        // U: [0, 1] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = SymmetricCSRGraph(vertexCount: 4, edges: pairs)
        let expectedCliques: [[Int]] = [[0, 1], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-001, CQ-002 … CQ-061 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: []")
    func adjacencyMatrixUndirected01() {
        // U: []
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyMatrix(vertexCount: 0, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = []
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [])
        #expect(graph.cliqueNumber() == 0)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = []
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = []
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = []
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = []
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-011, CQ-012 … CQ-069 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0]")
    func adjacencyMatrixUndirected02() {
        // U: [0]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyMatrix(vertexCount: 1, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-021, CQ-022 … CQ-064 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0] 0-0")
    func adjacencyMatrixUndirected03() {
        // U: [0] 0-0
        let arcs: [(Int, Int)] = [(0, 0)]
        let graph = AdjacencyMatrix(vertexCount: 1, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-031, CQ-032 … CQ-065 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1]")
    func adjacencyMatrixUndirected04() {
        // U: [0, 1]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1])
        #expect(cores.kShell(0) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-041, CQ-042 … CQ-050 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: 0-1")
    func adjacencyMatrixUndirected05() {
        // U: 0-1
        let arcs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-051, CQ-052 … CQ-060 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: 0-1, 0-1, 1-0")
    func adjacencyMatrixUndirected06() {
        // U: 0-1, 0-1, 1-0
        let arcs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-101, CQ-301 … CQ-466 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(0..2), 2-3")
    func adjacencyMatrixUndirected07() {
        // U: K(0..2), 2-3
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [3, 0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(1) == [3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.5833333333333334)
        #expect(values.averageClustering == 0.5833333333333334)
    }

    @Test("CQ-103 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(4)")
    func adjacencyMatrixUndirected08() {
        // U: K(4)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(3) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 4)
        #expect(values.triangleCount == 4)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-104, CQ-406 … CQ-410 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(5)")
    func adjacencyMatrixUndirected09() {
        // U: K(5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 4])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [4, 4, 4, 4, 4]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(4) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [6, 6, 6, 6, 6]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 10)
        #expect(values.triangleCount == 10)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-105, CQ-426 … CQ-430 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: C(0..3)")
    func adjacencyMatrixUndirected10() {
        // U: C(0..3)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 3], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-106, CQ-307 … CQ-309 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: C(0..4)")
    func adjacencyMatrixUndirected11() {
        // U: C(0..4)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-107, CQ-304 … CQ-306 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: P(0..4)")
    func adjacencyMatrixUndirected12() {
        // U: P(0..4)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [3, 4], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 4, 1, 3, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-108, CQ-310 … CQ-312 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: S(0;1..4)")
    func adjacencyMatrixUndirected13() {
        // U: S(0;1..4)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [0, 2], [0, 3], [0, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(1) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-110, CQ-411 … CQ-415 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(0..2), K(2..4)")
    func adjacencyMatrixUndirected14() {
        // U: K(0..2), K(2..4)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 3, 4, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-111, CQ-316 … CQ-420 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(0..2), 1-3, 2-3")
    func adjacencyMatrixUndirected15() {
        // U: K(0..2), 1-3, 2-3
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 2, 2, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 0.6666666666666666, 0.6666666666666666, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333333)
        #expect(values.averageClustering == 0.8333333333333333)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: S(0;1..5), C(1..5)")
    func adjacencyMatrixUndirected16() {
        // U: S(0;1..5), C(1..5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-114 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: moon(2)")
    func adjacencyMatrixUndirected17() {
        // U: moon(2)
        let arcs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-115 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1, 2] K(3..5)")
    func adjacencyMatrixUndirected18() {
        // U: [0, 1, 2] K(3..5)
        let arcs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1], [2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [3, 4, 5])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [3, 4, 5])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 0.5)
        #expect(values.averageClustering == 0.5)
    }

    @Test("CQ-116 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0] 0-0, 1-1, 1-2")
    func adjacencyMatrixUndirected19() {
        // U: [0] 0-0, 1-1, 1-2
        let arcs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func adjacencyMatrixUndirected20() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-120, CQ-322 … CQ-435 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: nx(petersen)")
    func adjacencyMatrixUndirected21() {
        // U: nx(petersen)
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7],
            [5, 8], [6, 8], [6, 9], [7, 9]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: nx(karate_club)")
    func adjacencyMatrixUndirected22() {
        // U: nx(karate_club)
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = AdjacencyMatrix(vertexCount: 34, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [0, 1, 2, 3, 7],
            [1, 30], [8, 30, 32, 33], [2, 8, 32], [13, 33], [0, 1, 2, 3, 13], [0, 2, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            7, 30, 32, 33, 3, 1, 8, 13, 0, 2
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-122 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(0..3), K(3..6), 0-6")
    func adjacencyMatrixUndirected23() {
        // U: K(0..3), K(3..6), 0-6
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6),
            (5, 6), (0, 6)
        ]
        let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 4, 5, 0, 6, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5, 6])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [4, 3, 3, 7, 3, 3, 4]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6666666666666666, 1.0, 1.0, 0.4666666666666667, 1.0, 1.0, 0.6666666666666666]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 9)
        #expect(values.triangleCount == 9)
        #expect(graph.transitivity() == 0.6923076923076923)
        #expect(values.transitivity == 0.6923076923076923)
        #expect(graph.averageClustering() == 0.8285714285714285)
        #expect(values.averageClustering == 0.8285714285714285)
    }

    @Test("CQ-124 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: moon(4)")
    func adjacencyMatrixUndirected24() {
        // U: moon(4)
        let arcs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 3), (1, 4),
            (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6),
            (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11),
            (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10),
            (5, 11), (6, 9), (6, 10), (6, 11), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11)
        ]
        let graph = AdjacencyMatrix(vertexCount: 12, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 3, 6, 9], [0, 3, 6, 10], [0, 3, 6, 11], [0, 3, 7, 9], [0, 3, 7, 10], [0, 3, 7, 11],
            [0, 3, 8, 9], [0, 3, 8, 10], [0, 3, 8, 11], [0, 4, 6, 9], [0, 4, 6, 10], [0, 4, 6, 11],
            [0, 4, 7, 9], [0, 4, 7, 10], [0, 4, 7, 11], [0, 4, 8, 9], [0, 4, 8, 10], [0, 4, 8, 11],
            [0, 5, 6, 9], [0, 5, 6, 10], [0, 5, 6, 11], [0, 5, 7, 9], [0, 5, 7, 10], [0, 5, 7, 11],
            [0, 5, 8, 9], [0, 5, 8, 10], [0, 5, 8, 11], [1, 3, 6, 9], [1, 3, 6, 10], [1, 3, 6, 11],
            [1, 3, 7, 9], [1, 3, 7, 10], [1, 3, 7, 11], [1, 3, 8, 9], [1, 3, 8, 10], [1, 3, 8, 11],
            [1, 4, 6, 9], [1, 4, 6, 10], [1, 4, 6, 11], [1, 4, 7, 9], [1, 4, 7, 10], [1, 4, 7, 11],
            [1, 4, 8, 9], [1, 4, 8, 10], [1, 4, 8, 11], [1, 5, 6, 9], [1, 5, 6, 10], [1, 5, 6, 11],
            [1, 5, 7, 9], [1, 5, 7, 10], [1, 5, 7, 11], [1, 5, 8, 9], [1, 5, 8, 10], [1, 5, 8, 11],
            [2, 3, 6, 9], [2, 3, 6, 10], [2, 3, 6, 11], [2, 3, 7, 9], [2, 3, 7, 10], [2, 3, 7, 11],
            [2, 3, 8, 9], [2, 3, 8, 10], [2, 3, 8, 11], [2, 4, 6, 9], [2, 4, 6, 10], [2, 4, 6, 11],
            [2, 4, 7, 9], [2, 4, 7, 10], [2, 4, 7, 11], [2, 4, 8, 9], [2, 4, 8, 10], [2, 4, 8, 11],
            [2, 5, 6, 9], [2, 5, 6, 10], [2, 5, 6, 11], [2, 5, 7, 9], [2, 5, 7, 10], [2, 5, 7, 11],
            [2, 5, 8, 9], [2, 5, 8, 10], [2, 5, 8, 11]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6, 9])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 9)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(9) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 108)
        #expect(values.triangleCount == 108)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.75)
        #expect(values.averageClustering == 0.75)
    }

    @Test("CQ-201, CQ-202 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(0..2), K(3..5)")
    func adjacencyMatrixUndirected25() {
        // U: K(0..2), K(3..5)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-207, CQ-208 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1, 2]")
    func adjacencyMatrixUndirected26() {
        // U: [0, 1, 2]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1], [2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2])
        #expect(cores.kShell(0) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-217, CQ-218 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: moon(3)")
    func adjacencyMatrixUndirected27() {
        // U: moon(3)
        let arcs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
            (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 6), (3, 7), (3, 8), (4, 6),
            (4, 7), (4, 8), (5, 6), (5, 7), (5, 8)
        ]
        let graph = AdjacencyMatrix(vertexCount: 9, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 3, 6], [0, 3, 7], [0, 3, 8], [0, 4, 6], [0, 4, 7], [0, 4, 8], [0, 5, 6], [0, 5, 7],
            [0, 5, 8], [1, 3, 6], [1, 3, 7], [1, 3, 8], [1, 4, 6], [1, 4, 7], [1, 4, 8], [1, 5, 6],
            [1, 5, 7], [1, 5, 8], [2, 3, 6], [2, 3, 7], [2, 3, 8], [2, 4, 6], [2, 4, 7], [2, 4, 8],
            [2, 5, 6], [2, 5, 7], [2, 5, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3, 6])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [6, 6, 6, 6, 6, 6, 6, 6, 6]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 6)
        let expectedOrdering: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(cores.kShell(6) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 9]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 27)
        #expect(values.triangleCount == 27)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6)
        #expect(values.averageClustering == 0.6)
    }

    @Test("CQ-219, CQ-220 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: P(0..3), 3-3, 3-3")
    func adjacencyMatrixUndirected28() {
        // U: P(0..3), 3-3, 3-3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [2, 3], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 3, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: K(4), 3-4, 4-5, 5-6, 6-4")
    func adjacencyMatrixUndirected29() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-325, CQ-326 … CQ-327 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: grid(3,4)")
    func adjacencyMatrixUndirected30() {
        // U: grid(3,4)
        let arcs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = AdjacencyMatrix(vertexCount: 12, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [
            [0, 1], [0, 4], [2, 3], [3, 7], [4, 8], [8, 9], [7, 11], [10, 11], [1, 2], [1, 5], [4, 5],
            [6, 7], [2, 6], [5, 9], [9, 10], [6, 10], [5, 6]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 3, 8, 11, 1, 4, 7, 2, 9, 10, 5, 6]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(cores.kShell(2) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-328, CQ-329 … CQ-330 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1] 0-1, 0-1")
    func adjacencyMatrixUndirected31() {
        // U: [0, 1] 0-1, 0-1
        let arcs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-331, CQ-332 … CQ-333 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1] 0-1, 0-0, 1-1")
    func adjacencyMatrixUndirected32() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let arcs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1])
        #expect(cores.kShell(1) == [0, 1])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-441, CQ-442 … CQ-445 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: 0-1, 1-2, 2-0, 0-1, 1-1")
    func adjacencyMatrixUndirected33() {
        // U: 0-1, 1-2, 2-0, 0-1, 1-1
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (1, 1)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-446, CQ-447 … CQ-450 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1, 2, 3]")
    func adjacencyMatrixUndirected34() {
        // U: [0, 1, 2, 3]
        let arcs: [(Int, Int)] = []
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0], [1], [2], [3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0])
        #expect(graph.cliqueNumber() == 1)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 0, 0, 0]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 0)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(0) == [0, 1, 2, 3])
        #expect(cores.kShell(0) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-451, CQ-452 … CQ-455 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: P(0..2)")
    func adjacencyMatrixUndirected35() {
        // U: P(0..2)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 2, 1]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2])
        #expect(cores.kShell(1) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-456, CQ-457 … CQ-460 on AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending): U: [0, 1] 0-1, 2-3")
    func adjacencyMatrixUndirected36() {
        // U: [0, 1] 0-1, 2-3
        let arcs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let expectedCliques: [[Int]] = [[0, 1], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [1, 1, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [0, 1, 2, 3])
        #expect(cores.kShell(1) == [0, 1, 2, 3])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on a conformer without indices: U: nx(karate_club)")
    func plainGraph01() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = PlainGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30],
            [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            30, 7, 32, 33, 8, 1, 3, 13, 0, 2
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-119 on a conformer without indices: U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c")
    func plainGraph02() {
        // U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = PlainGraph(vertices: ["e", "d", "c", "b", "a"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[String]] = [["e", "d", "c"], ["c", "b", "a"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["e", "d", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["e", "d", "b", "a", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["e", "d", "c", "b", "a"])
        #expect(cores.kShell(2) == ["e", "d", "c", "b", "a"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-116 on a conformer without indices: U: [0] 0-0, 1-1, 1-2")
    func plainGraph03() {
        // U: [0] 0-0, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = PlainGraph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on a conformer without indices: U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func plainGraph04() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = PlainGraph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on a conformer without indices: U: S(0;1..5), C(1..5)")
    func plainGraph05() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = PlainGraph(vertices: [0, 1, 2, 3, 4, 5], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-113, CQ-209 … CQ-210 on a conformer without indices: U: KB(0..2;3..5)")
    func plainGraph06() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = PlainGraph(vertices: [0, 3, 4, 5, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 3, 4, 5, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 3, 4, 5, 1, 2])
        #expect(cores.kShell(3) == [0, 3, 4, 5, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on a conformer without indices: U: K(4), 3-4, 4-5, 5-6, 6-4")
    func plainGraph07() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = PlainGraph(vertices: [0, 1, 2, 3, 4, 5, 6], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on a conformer with vertex indices only: U: nx(karate_club)")
    func vertexIndexedGraph01() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = VertexIndexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30],
            [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            30, 7, 32, 33, 8, 1, 3, 13, 0, 2
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-119 on a conformer with vertex indices only: U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c")
    func vertexIndexedGraph02() {
        // U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = VertexIndexedGraph(vertices: ["e", "d", "c", "b", "a"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[String]] = [["e", "d", "c"], ["c", "b", "a"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["e", "d", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["e", "d", "b", "a", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["e", "d", "c", "b", "a"])
        #expect(cores.kShell(2) == ["e", "d", "c", "b", "a"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-116 on a conformer with vertex indices only: U: [0] 0-0, 1-1, 1-2")
    func vertexIndexedGraph03() {
        // U: [0] 0-0, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = VertexIndexedGraph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on a conformer with vertex indices only: U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func vertexIndexedGraph04() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = VertexIndexedGraph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on a conformer with vertex indices only: U: S(0;1..5), C(1..5)")
    func vertexIndexedGraph05() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = VertexIndexedGraph(vertices: [0, 1, 2, 3, 4, 5], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-113, CQ-209 … CQ-210 on a conformer with vertex indices only: U: KB(0..2;3..5)")
    func vertexIndexedGraph06() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = VertexIndexedGraph(vertices: [0, 3, 4, 5, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 3, 4, 5, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 3, 4, 5, 1, 2])
        #expect(cores.kShell(3) == [0, 3, 4, 5, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on a conformer with vertex indices only: U: K(4), 3-4, 4-5, 5-6, 6-4")
    func vertexIndexedGraph07() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = VertexIndexedGraph(vertices: [0, 1, 2, 3, 4, 5, 6], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-121, CQ-123 … CQ-465 on rows reversed (~rev): U: nx(karate_club)")
    func reversedRows01() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReversedRowsPseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [0, 1, 2, 3, 7],
            [1, 30], [8, 30, 32, 33], [13, 33], [2, 8, 32], [0, 1, 2, 3, 13], [0, 2, 8]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7])
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 4)
        let expectedOrdering: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 6, 5, 29, 27, 31, 23,
            7, 30, 33, 32, 3, 8, 1, 13, 2, 0
        ]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(4) == [0, 1, 2, 3, 7, 8, 13, 30, 32, 33])
        #expect(cores.kShell(1) == [11])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 45)
        #expect(values.triangleCount == 45)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(values.transitivity == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
        #expect(values.averageClustering == 0.5706384782076823)
    }

    @Test("CQ-119 on rows reversed (~rev): U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c")
    func reversedRows02() {
        // U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = ReversedRowsPseudograph(vertices: ["e", "d", "c", "b", "a"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[String]] = [["e", "d", "c"], ["c", "b", "a"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == ["e", "d", "c"])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [String] = ["e", "d", "b", "a", "c"]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == ["e", "d", "c", "b", "a"])
        #expect(cores.kShell(2) == ["e", "d", "c", "b", "a"])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 2, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 2)
        #expect(values.triangleCount == 2)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.8666666666666668)
        #expect(values.averageClustering == 0.8666666666666668)
    }

    @Test("CQ-116 on rows reversed (~rev): U: [0] 0-0, 1-1, 1-2")
    func reversedRows03() {
        // U: [0] 0-0, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = ReversedRowsPseudograph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [1, 2])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [0, 1, 1]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 1)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(1) == [1, 2])
        #expect(cores.kShell(0) == [0])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-117 on rows reversed (~rev): U: 0-1, 1-2, 2-0, 0-1, 2-2")
    func reversedRows04() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = ReversedRowsPseudograph(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 2)
        let expectedOrdering: [Int] = [0, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(2) == [0, 1, 2])
        #expect(cores.kShell(2) == [0, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 1)
        #expect(values.triangleCount == 1)
        #expect(graph.transitivity() == 1.0)
        #expect(values.transitivity == 1.0)
        #expect(graph.averageClustering() == 1.0)
        #expect(values.averageClustering == 1.0)
    }

    @Test("CQ-112, CQ-213 … CQ-425 on rows reversed (~rev): U: S(0;1..5), C(1..5)")
    func reversedRows05() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReversedRowsPseudograph(vertices: [0, 1, 2, 3, 4, 5], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2])
        #expect(graph.cliqueNumber() == 3)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [1, 2, 3, 4, 5, 0]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3, 4, 5])
        #expect(cores.kShell(3) == [0, 1, 2, 3, 4, 5])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [5, 2, 2, 2, 2, 2]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666,
            0.6666666666666666
        ]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.6)
        #expect(values.transitivity == 0.6)
        #expect(graph.averageClustering() == 0.6388888888888887)
        #expect(values.averageClustering == 0.6388888888888887)
    }

    @Test("CQ-113, CQ-209 … CQ-210 on rows reversed (~rev): U: KB(0..2;3..5)")
    func reversedRows06() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReversedRowsPseudograph(vertices: [0, 3, 4, 5, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 3])
        #expect(graph.cliqueNumber() == 2)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [0, 3, 4, 5, 1, 2]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 3, 4, 5, 1, 2])
        #expect(cores.kShell(3) == [0, 3, 4, 5, 1, 2])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [0, 0, 0, 0, 0, 0]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 0)
        #expect(values.triangleCount == 0)
        #expect(graph.transitivity() == 0.0)
        #expect(values.transitivity == 0.0)
        #expect(graph.averageClustering() == 0.0)
        #expect(values.averageClustering == 0.0)
    }

    @Test("CQ-313, CQ-314 … CQ-347 on rows reversed (~rev): U: K(4), 3-4, 4-5, 5-6, 6-4")
    func reversedRows07() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReversedRowsPseudograph(vertices: [0, 1, 2, 3, 4, 5, 6], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expectedCliques: [[Int]] = [[4, 5, 6], [3, 4], [0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3])
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(coresByIndex == expectedCores)
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracy == 3)
        let expectedOrdering: [Int] = [5, 6, 4, 1, 2, 0, 3]
        #expect(cores.degeneracyOrdering == expectedOrdering)
        #expect(cores.kCore(3) == [0, 1, 2, 3])
        #expect(cores.kShell(2) == [4, 5, 6])
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [3, 3, 3, 3, 1, 1, 1]
        let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }
        #expect(trianglesByIndex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [1.0, 1.0, 1.0, 0.5, 0.3333333333333333, 1.0, 1.0]
        let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }
        #expect(clusteringByIndex == expectedClustering)
        let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
        #expect(clusteringOneByOne == expectedClustering)
        #expect(graph.triangleCount() == 5)
        #expect(values.triangleCount == 5)
        #expect(graph.transitivity() == 0.75)
        #expect(values.transitivity == 0.75)
        #expect(graph.averageClustering() == 0.8333333333333334)
        #expect(values.averageClustering == 0.8333333333333334)
    }

    @Test("CQ-121, CQ-123 … CQ-465 with Collider vertices on UndirectedAdjacencyList: U: nx(karate_club)")
    func colliderVertices01() {
        // U: nx(karate_club), each vertex v as Collider(v, hash: v % 2)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let c = { (v: Int) in Collider(v, hash: v % 2) }
        let graph = UndirectedAdjacencyList(vertices: (0 ..< 34).map(c), edges: pairs.map { UndirectedEdge(c($0.0), c($0.1)) })
        let expectedCliques: [[Collider]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30],
            [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]
        ].map { $0.map(c) }
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3, 7].map(c))
        #expect(graph.cliqueNumber() == 5)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracyOrdering == [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            30, 7, 32, 33, 8, 1, 3, 13, 0, 2
        ].map(c))
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [
            18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4,
            3, 3, 13, 15
        ]
        let trianglesByVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(trianglesByVertex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [
            0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5,
            0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0,
            0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0,
            0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696,
            0.11029411764705882
        ]
        let clusteringByVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(clusteringByVertex == expectedClustering)
        #expect(graph.transitivity() == 0.2556818181818182)
        #expect(graph.averageClustering() == 0.5706384782076823)
    }

    @Test("CQ-122 with Collider vertices on UndirectedAdjacencyList: U: K(0..3), K(3..6), 0-6")
    func colliderVertices02() {
        // U: K(0..3), K(3..6), 0-6, each vertex v as Collider(v, hash: v % 2)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6),
            (5, 6), (0, 6)
        ]
        let c = { (v: Int) in Collider(v, hash: v % 2) }
        let graph = UndirectedAdjacencyList(vertices: (0 ..< 7).map(c), edges: pairs.map { UndirectedEdge(c($0.0), c($0.1)) })
        let expectedCliques: [[Collider]] = [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]].map { $0.map(c) }
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expectedCliques))
        #expect(cliques.count == expectedCliques.count)
        #expect(graph.maximumClique() == [0, 1, 2, 3].map(c))
        #expect(graph.cliqueNumber() == 4)
        let cores = graph.coreNumbers()
        let expectedCores: [Int] = [3, 3, 3, 3, 3, 3, 3]
        let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(coresByVertex == expectedCores)
        #expect(cores.degeneracyOrdering == [1, 2, 4, 5, 0, 3, 6].map(c))
        let values = graph.clusteringCoefficients()
        let expectedTriangles: [Int] = [4, 3, 3, 7, 3, 3, 4]
        let trianglesByVertex = graph.vertices.map { values.triangleCount(of: $0) }
        #expect(trianglesByVertex == expectedTriangles)
        let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
        #expect(trianglesOneByOne == expectedTriangles)
        let expectedClustering: [Double] = [0.6666666666666666, 1.0, 1.0, 0.4666666666666667, 1.0, 1.0, 0.6666666666666666]
        let clusteringByVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }
        #expect(clusteringByVertex == expectedClustering)
        #expect(graph.transitivity() == 0.6923076923076923)
        #expect(graph.averageClustering() == 0.8285714285714285)
    }
}
