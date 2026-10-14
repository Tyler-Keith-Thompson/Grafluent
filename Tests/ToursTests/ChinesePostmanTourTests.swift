// `chinesePostmanTour(weight:)` on `Graph` and `DirectedGraph`: hand-computed tours (the walk is
// Hierholzer's on the edges in position order, then the duplicated edges in position order, from
// the first vertex with an edge; directed rows are each vertex's out-edges in position order,
// then their copies), the duplicated edges and the weight; nil without edges or when the edges
// are not (strongly) connected; self-loops and parallel edges; every representation, and
// conformers without vertex or edge indices.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

/// A directed graph with no vertex or edge indices; rows in position order.
private struct UnindexedDirectedGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]

    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
}

/// An undirected graph with no vertex or edge indices; rows in position order, a self-loop twice.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("chinesePostmanTour")
struct ChinesePostmanTourTests {
    @Test("A path: both edges walked twice, there and back")
    func path() throws {
        let weights = [1, 2]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var asked: [Int] = []
        let tour = try #require(graph.chinesePostmanTour { position in
            asked.append(position)
            return weights[position]
        })
        #expect(asked == [0, 1])
        #expect(tour.walk.vertices == [0, 1, 2, 1, 0])
        #expect(tour.walk.edges == [0, 1, 1, 0])
        #expect(tour.duplicatedEdges == [0, 1])
        #expect(tour.weight == 6)
        #expect(tour.description == "weight 6; walk [0, 1, 2, 1, 0]; duplicated [0, 1]")
    }

    @Test("An Eulerian graph: its Eulerian circuit as a closed walk, nothing duplicated")
    func eulerian() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let tour = try #require(graph.chinesePostmanTour { _ in 5 })
        let circuit = try #require(graph.eulerianCircuit())
        #expect(tour.walk.vertices == circuit.vertices + [circuit.vertices[0]])
        #expect(tour.walk.edges == circuit.edges)
        #expect(tour.duplicatedEdges.isEmpty)
        #expect(tour.weight == 15)
    }

    @Test("A square with a heavy diagonal: the odd ends of the diagonal joined by the light side path")
    func squareWithDiagonal() throws {
        // 0-1 (1), 1-2 (1), 2-3 (2), 3-0 (2), 0-2 (5). Odd: 0 and 2, at distance 2 through 1.
        let weights = [1, 1, 2, 2, 5]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(0, 2)])
        let tour = try #require(graph.chinesePostmanTour { weights[$0] })
        #expect(tour.duplicatedEdges == [0, 1])
        #expect(tour.weight == 13)
        // Rows 0: e0 e3 e4 e5; 1: e0 e1 e5 e6; 2: e1 e2 e4 e6; 3: e2 e3 (e5, e6 the copies of e0, e1).
        #expect(tour.walk.vertices == [0, 1, 2, 3, 0, 2, 1, 0])
        #expect(tour.walk.edges == [0, 1, 2, 3, 4, 1, 0])
    }

    @Test("Equal shortest paths: the first one Dijkstra settles is kept, not replaced by a tie")
    func tiedPaths() throws {
        // A unit square 0-1-2-3 with the heavy diagonal 1-3 (5): the odd vertices 1 and 3 are
        // joined by 1-0-3 and 1-2-3, both of length 2; 0 is settled first and keeps 3's parent.
        let weights = [1, 1, 1, 1, 5]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(1, 3)])
        let tour = try #require(graph.chinesePostmanTour { weights[$0] })
        #expect(tour.weight == 11)
        #expect(tour.duplicatedEdges == [0, 3])
    }

    @Test("A star: every edge twice, whichever pairs the matching takes")
    func star() throws {
        let weights = [1, 2, 3]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let tour = try #require(graph.chinesePostmanTour { weights[$0] })
        #expect(tour.duplicatedEdges == [0, 1, 2])
        #expect(tour.weight == 12)
        #expect(tour.walk.vertices == [0, 1, 0, 2, 0, 3, 0])
        #expect(tour.walk.edges == [0, 0, 1, 1, 2, 2])
    }

    @Test("K4 with unit weights: two edges of a perfect matching duplicated, weight 8")
    func completeFour() throws {
        var ends: [UndirectedEdge<Int>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { ends.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: ends)
        let tour = try #require(graph.chinesePostmanTour { _ in 1 })
        #expect(tour.weight == 8)
        #expect(tour.duplicatedEdges.count == 2)
        let covered = tour.duplicatedEdges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] }
        #expect(covered.sorted() == [0, 1, 2, 3])
        #expect(tour.walk.length == 8 && tour.walk.isClosed)
    }

    @Test("Floating-point weights")
    func floatingPoint() throws {
        let weights = [0.5, 0.25]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let tour = try #require(graph.chinesePostmanTour { weights[$0] })
        #expect(tour.weight == 1.5)
        #expect(tour.duplicatedEdges == [0, 1])
    }

    @Test("Zero weights: every matching ties, each edge duplicated at most once")
    func zeroWeights() throws {
        // A star with four leaves and zero weights: every matching of the leaves costs 0, and each
        // leaf's edge is on exactly one matched path.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4)])
        let tour = try #require(graph.chinesePostmanTour { _ in 0 })
        #expect(tour.weight == 0)
        #expect(Set(tour.duplicatedEdges).count == tour.duplicatedEdges.count)
        #expect(tour.duplicatedEdges == [0, 1, 2, 3])
        #expect(tour.walk.length == 8)
    }

    @Test("No edges, or edges in two components: nil; isolated vertices are ignored")
    func noTour() throws {
        #expect(UndirectedAdjacencyList<Int>().chinesePostmanTour { _ in 1 } == nil)
        #expect(UndirectedAdjacencyList(vertices: 0 ..< 3, edges: []).chinesePostmanTour { _ in 1 } == nil)
        let split = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(split.chinesePostmanTour { _ in 1 } == nil)
        let isolated = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(1, 2)])
        let tour = try #require(isolated.chinesePostmanTour { _ in 4 })
        #expect(tour.walk.vertices == [1, 2, 1])
        #expect(tour.walk.edges == [0, 0])
        #expect(tour.weight == 8)
    }

    @Test("Self-loops are walked once, parallel edges each at least once, the lightest copy duplicated")
    func pseudograph() throws {
        let loop = Pseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        let alone = try #require(loop.chinesePostmanTour { _ in 3 })
        #expect(alone.walk.vertices == [0, 0])
        #expect(alone.walk.edges == [0])
        #expect(alone.duplicatedEdges.isEmpty)
        #expect(alone.weight == 3)
        // Three parallel edges 0-1 (5, 1, 2) and a loop at 1 (7): both ends odd, the copy at
        // position 1 duplicated.
        let weights = [5, 1, 2, 7]
        let graph = Pseudograph(vertices: [0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let tour = try #require(graph.chinesePostmanTour { weights[$0] })
        #expect(tour.duplicatedEdges == [1])
        #expect(tour.weight == 16)
        // Rows 0: e0 e1 e2 e4; 1: e0 e1 e2 e3 e3 e4 (e4 the copy of e1).
        #expect(tour.walk.vertices == [0, 1, 0, 1, 1, 0])
        #expect(tour.walk.edges == [0, 1, 2, 3, 1])
        var uses = [Int](repeating: 0, count: 4)
        for e in tour.walk.edges { uses[e] += 1 }
        #expect(uses == [1, 2, 1, 1])
        #expect(Walk(vertices: tour.walk.vertices, edges: tour.walk.edges, in: graph) != nil)
    }

    @Test("Directed: the cycle itself; an extra arc paid for by the cheapest way back")
    func directed() throws {
        let cycle = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let around = try #require(cycle.chinesePostmanTour { _ in 2 })
        #expect(around.walk.vertices == [0, 1, 2, 0])
        #expect(around.walk.edges == [0, 1, 2])
        #expect(around.duplicatedEdges.isEmpty)
        #expect(around.weight == 6)
        // 0→1 (1), 1→2 (1), 2→0 (1), 0→2 (4): 2 has one more in than out, sent back along 2→0.
        let weights = [1, 1, 1, 4]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        var asked: [Int] = []
        let tour = try #require(graph.chinesePostmanTour { position in
            asked.append(position)
            return weights[position]
        })
        #expect(asked == [0, 1, 2, 3])
        #expect(tour.walk.vertices == [0, 1, 2, 0, 2, 0])
        #expect(tour.walk.edges == [0, 1, 2, 3, 2])
        #expect(tour.duplicatedEdges == [2])
        #expect(tour.weight == 8)
    }

    @Test("Directed: an arc duplicated twice")
    func directedTwice() throws {
        // 1→0 three times (1 each), 0→1 once (2): 0 receives two more than it sends.
        let weights = [1, 1, 1, 2]
        let graph = DirectedPseudograph(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1)])
        let tour = try #require(graph.chinesePostmanTour { weights[$0] })
        #expect(tour.duplicatedEdges == [3, 3])
        #expect(tour.weight == 9)
        #expect(tour.walk.vertices == [0, 1, 0, 1, 0, 1, 0])
        #expect(tour.walk.edges == [3, 0, 3, 1, 3, 2])
    }

    @Test("Directed: nil without edges, when not strongly connected, or in two pieces")
    func directedNoTour() {
        #expect(AdjacencyList<Int>().chinesePostmanTour { _ in 1 } == nil)
        #expect(AdjacencyList(vertices: 0 ..< 2, edges: []).chinesePostmanTour { _ in 1 } == nil)
        #expect(AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)]).chinesePostmanTour { _ in 1 } == nil)
        let pieces = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        #expect(pieces.chinesePostmanTour { _ in 1 } == nil)
        let oneWay = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)])
        #expect(oneWay.chinesePostmanTour { _ in 1 } == nil)
    }

    @Test("Directed: a self-loop walked once, isolated vertices ignored")
    func directedLoop() throws {
        let graph = DirectedPseudograph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 2, to: 2)])
        let tour = try #require(graph.chinesePostmanTour { _ in 3 })
        #expect(tour.walk.vertices == [2, 2])
        #expect(tour.walk.edges == [0])
        #expect(tour.duplicatedEdges.isEmpty)
        #expect(tour.weight == 3)
    }

    @Test("Every representation gives the same tour")
    func representations() throws {
        // Undirected: the square with a diagonal.
        let weights = [1, 1, 2, 2, 5]
        let ends = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let expectedVertices = [0, 1, 2, 3, 0, 2, 1, 0], expectedEdges = [0, 1, 2, 3, 4, 1, 0]
        let pseudo = try #require(Pseudograph(vertices: 0 ..< 4, edges: ends.map { UndirectedEdge($0.0, $0.1) }).chinesePostmanTour { weights[$0] })
        #expect(pseudo.walk.vertices == expectedVertices && pseudo.walk.edges == expectedEdges && pseudo.weight == 13)
        let reference = try #require(ReferencePseudograph(vertices: 0 ..< 4, edges: ends.map { UndirectedEdge($0.0, $0.1) }).chinesePostmanTour { weights[$0] })
        #expect(reference.walk.vertices == expectedVertices && reference.walk.edges == expectedEdges && reference.weight == 13)
        let labels = ["a", "b", "c", "d"]
        let unindexed = UnindexedGraph(vertices: labels, edges: ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) })
        #expect(unindexed.vertexIndexBound == nil && unindexed.edgeIndexBound == nil)
        let named = try #require(unindexed.chinesePostmanTour { weights[$0] })
        #expect(named.walk.vertices == expectedVertices.map { labels[$0] } && named.walk.edges == expectedEdges && named.weight == 13)
        #expect(named.duplicatedEdges == [0, 1])
        // Directed: 0→1, 1→2, 2→0, 0→2 with weights 1, 1, 1, 4, edges already in row-major order
        // for the compressed sparse row: 0→1, 0→2, 1→2, 2→0.
        let arcs = [(0, 1), (0, 2), (1, 2), (2, 0)]
        let arcWeights = [1, 4, 1, 1]
        let expectedArcVertices = [0, 1, 2, 0, 2, 0], expectedArcs = [0, 2, 3, 1, 3]
        let list = try #require(AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).chinesePostmanTour { arcWeights[$0] })
        #expect(list.walk.vertices == expectedArcVertices && list.walk.edges == expectedArcs && list.duplicatedEdges == [3] && list.weight == 8)
        let csr = CompressedSparseRow(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let compressed = try #require(csr.chinesePostmanTour { arcWeights[$0] })
        #expect(compressed.walk.vertices == expectedArcVertices && compressed.walk.edges == expectedArcs && compressed.weight == 8)
        let multi = try #require(DirectedPseudograph(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).chinesePostmanTour { arcWeights[$0] })
        #expect(multi.walk.vertices == expectedArcVertices && multi.walk.edges == expectedArcs && multi.weight == 8)
        let referenceDirected = try #require(ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).chinesePostmanTour { arcWeights[$0] })
        #expect(referenceDirected.walk.vertices == expectedArcVertices && referenceDirected.walk.edges == expectedArcs && referenceDirected.weight == 8)
        let unindexedDirected = UnindexedDirectedGraph(vertices: labels.prefix(3).map { $0 }, edges: arcs.map { DirectedEdge(from: labels[$0.0], to: labels[$0.1]) })
        #expect(unindexedDirected.vertexIndexBound == nil && unindexedDirected.edgeIndexBound == nil)
        let namedDirected = try #require(unindexedDirected.chinesePostmanTour { arcWeights[$0] })
        #expect(namedDirected.walk.vertices == expectedArcVertices.map { labels[$0] } && namedDirected.walk.edges == expectedArcs && namedDirected.weight == 8)
        // The matrix numbers edges by cell, so weights are looked up by ends.
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let byEnds = { (edge: DirectedEdge<Int>) in arcWeights[arcs.firstIndex { $0.0 == edge.source && $0.1 == edge.target }!] }
        let fromMatrix = try #require(matrix.chinesePostmanTour { byEnds(matrix.edges[$0]) })
        #expect(fromMatrix.walk.vertices == expectedArcVertices && fromMatrix.weight == 8)
        #expect(fromMatrix.walk.edges.map { [matrix.edges[$0].source, matrix.edges[$0].target] } == expectedArcs.map { [arcs[$0].0, arcs[$0].1] })
        #expect(fromMatrix.duplicatedEdges.map { matrix.edges[$0] } == [DirectedEdge(from: 2, to: 0)])
    }
}
