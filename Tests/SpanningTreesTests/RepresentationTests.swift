// The same answers on every representation: UndirectedAdjacencyList (positions in insertion
// order), ReferencePseudograph (parallel edges and self-loops), AdjacencyList and AdjacencyMatrix
// read through `.undirected` (each arc an edge, the matrix weighed by cell and without edge
// indices), a conformer without vertex indices and one with vertex indices but no edge indices,
// and String vertices. Case IDs (ST-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

/// An undirected pseudograph with no vertex or edge indices, so the algorithms number the vertices
/// through a dictionary. A self-loop is listed twice at its vertex.
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

/// Vertex indices (the positions in `vertices`) but no edge indices, so edges are gathered by
/// walking `edges` rather than the rows.
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

@Suite("Representations")
struct RepresentationTests {
    @Test("ST-90 UndirectedAdjacencyList built from Wikipedia's graph: ST-04's answers")
    func undirectedAdjacencyList() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        // No edge repeats, so the positions are the written ones.
        #expect(graph.edges.map { [$0.u, $0.v] } == wiki.map { [$0.0, $0.1] })
        let canonical = [1, 5, 7, 0, 4, 9]
        let tree = graph.minimumSpanningTree { wiki[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 39)
        #expect(graph.kruskalMinimumSpanningTree { wiki[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { wiki[$0].2 }.edges) == Set(canonical))
        #expect(Set(graph.primMinimumSpanningTree { wiki[$0].2 }.edges) == Set(canonical))
        for root in 0 ..< 7 {
            let rooted = graph.primMinimumSpanningTree(from: root) { wiki[$0].2 }
            #expect(Set(rooted.edges) == Set(canonical), "from \(root)")
            #expect(rooted.weight == 39, "from \(root)")
        }
        #expect(graph.maximumSpanningTree { wiki[$0].2 }.edges == [6, 10, 3, 9, 2, 0])
        #expect(graph.minimumSpanningTree().edges == [0, 1, 2, 4, 7, 9])
    }

    @Test("ST-91 parallel edges and self-loops on ReferencePseudograph and AdjacencyList.undirected", .tags(.selfLoops))
    func parallelEdgesAndLoops() {
        // ST-27: 1–4 at positions 2 (weight 2) and 7 (weight 1).
        let boost: [(Int, Int, Int)] = [(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1)]
        let pseudograph = ReferencePseudograph(vertices: 0 ..< 5, edges: boost.map { UndirectedEdge($0.0, $0.1) })
        // As arcs, 1→4 and 4→1 are distinct, so the view has the same parallel pair.
        let arcs = AdjacencyList(vertices: 0 ..< 5, edges: boost.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(arcs.edgeCount == 8)
        #expect(pseudograph.minimumSpanningTree { boost[$0].2 }.edges == [0, 1, 5, 6])
        #expect(arcs.minimumSpanningTree { boost[$0].2 }.edges == [0, 1, 5, 6])
        #expect(arcs.kruskalMinimumSpanningTree { boost[$0].2 }.weight == 4)
        #expect(Set(arcs.boruvkaMinimumSpanningTree { boost[$0].2 }.edges) == [0, 1, 5, 6])
        #expect(arcs.primMinimumSpanningTree { boost[$0].2 }.weight == 4)
        #expect(!arcs.primMinimumSpanningTree { boost[$0].2 }.edges.contains(2))

        // ST-31: self-loops lighter than the one edge.
        let loops: [(Int, Int, Int)] = [(0, 0, -100), (0, 1, 5), (1, 1, -1)]
        let loopy = ReferencePseudograph(vertices: 0 ..< 2, edges: loops.map { UndirectedEdge($0.0, $0.1) })
        let loopArcs = AdjacencyList(vertices: 0 ..< 2, edges: loops.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let trees = [loopy.minimumSpanningTree { loops[$0].2 }, loopy.primMinimumSpanningTree { loops[$0].2 }, loopy.boruvkaMinimumSpanningTree { loops[$0].2 }]
        for tree in trees {
            #expect(tree.edges == [1])
            #expect(tree.weight == 5)
        }
        let viewTrees = [loopArcs.minimumSpanningTree { loops[$0].2 }, loopArcs.primMinimumSpanningTree { loops[$0].2 }, loopArcs.boruvkaMinimumSpanningTree { loops[$0].2 }]
        for tree in viewTrees {
            #expect(tree.edges == [1])
            #expect(tree.weight == 5)
        }
    }

    @Test("ST-92 a digraph through .undirected: opposite arcs are parallel edges and the lighter wins")
    func digraphThroughUndirected() {
        let arcs: [(Int, Int, Int)] = [(0, 1, 3), (1, 0, 1), (1, 2, 2)]
        let list = AdjacencyList(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = list.undirected
        let tree = graph.minimumSpanningTree { arcs[$0].2 }
        #expect(tree.edges == [1, 2])
        #expect(tree.weight == 3)
        #expect(graph.kruskalMinimumSpanningTree { arcs[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { arcs[$0].2 }.edges) == [1, 2])
        #expect(Set(graph.primMinimumSpanningTree { arcs[$0].2 }.edges) == [1, 2])
        #expect(Set(graph.primMinimumSpanningTree(from: 2) { arcs[$0].2 }.edges) == [1, 2])
        #expect(graph.maximumSpanningTree { arcs[$0].2 }.edges == [0, 2])

        // The same arcs in a matrix, weighed by cell.
        var cells = [[Int]](repeating: [Int](repeating: 0, count: 3), count: 3)
        for (u, v, w) in arcs { cells[u][v] = w }
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let matrixTree = matrix.minimumSpanningTree { cells[$0.source][$0.target] }
        #expect(matrixTree.edges.map { [$0.source, $0.target] } == [[1, 0], [1, 2]])
        #expect(matrixTree.weight == 3)
        #expect(Set(matrix.primMinimumSpanningTree { cells[$0.source][$0.target] }.edges.map { [$0.source, $0.target] }) == [[1, 0], [1, 2]])
        #expect(Set(matrix.boruvkaMinimumSpanningTree { cells[$0.source][$0.target] }.edges.map { [$0.source, $0.target] }) == [[1, 0], [1, 2]])
    }

    @Test("ST-93 a conformer without vertex indices gives the same canonical forests")
    func withoutVertexIndices() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let graph = PlainGraph(vertices: Array(0 ..< 7), edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == nil)
        let canonical = [1, 5, 7, 0, 4, 9]
        let tree = graph.minimumSpanningTree { wiki[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == 39)
        #expect(graph.kruskalMinimumSpanningTree { wiki[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { wiki[$0].2 }.edges) == Set(canonical))
        #expect(Set(graph.primMinimumSpanningTree { wiki[$0].2 }.edges) == Set(canonical))
        #expect(Set(graph.primMinimumSpanningTree(from: 4) { wiki[$0].2 }.edges) == Set(canonical))
        #expect(graph.maximumSpanningTree { wiki[$0].2 }.edges == [6, 10, 3, 9, 2, 0])
        #expect(graph.minimumSpanningTree().edges == [0, 1, 2, 4, 7, 9])

        let petgraph: [(String, String, Int)] = [
            ("A", "B", 7), ("A", "D", 5), ("D", "B", 9), ("B", "C", 8), ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6),
            ("F", "E", 8), ("F", "G", 11), ("E", "G", 9), ("H", "I", 1), ("H", "J", 3), ("I", "J", 1),
        ]
        let forest = PlainGraph(vertices: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"], edges: petgraph.map { UndirectedEdge($0.0, $0.1) })
        let forestTree = forest.minimumSpanningTree { petgraph[$0].2 }
        #expect(forestTree.edges == [11, 13, 1, 5, 7, 0, 4, 10])
        #expect(forestTree.weight == 41)
        #expect(Set(forest.boruvkaMinimumSpanningTree { petgraph[$0].2 }.edges) == [11, 13, 1, 5, 7, 0, 4, 10])
        #expect(forest.primMinimumSpanningTree { petgraph[$0].2 }.weight == 41)
        #expect(Set(forest.primMinimumSpanningTree(from: "J") { petgraph[$0].2 }.edges) == [11, 13])

        // Self-loops without indices: listed twice, never weighed.
        let loops: [(Int, Int, Int)] = [(0, 0, -100), (0, 1, 5), (1, 1, -1)]
        let loopy = PlainGraph(vertices: [0, 1], edges: loops.map { UndirectedEdge($0.0, $0.1) })
        var asked: [Int] = []
        let tree31 = loopy.primMinimumSpanningTree { position in
            asked.append(position)
            return loops[position].2
        }
        #expect(tree31.edges == [1])
        #expect(asked == [1])
    }

    @Test("ST-94 vertex indices without edge indices: the tie rule by edges order, through the fallback path")
    func withoutEdgeIndices() {
        // ST-34: equal weights, listed so that position order is not endpoint order.
        let ties: [(Int, Int, Int)] = [(0, 2, 1), (1, 2, 1), (0, 1, 1)]
        let graph = VertexIndexedGraph(vertices: [0, 1, 2], edges: ties.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.vertexIndexBound == 3)
        #expect(graph.edgeIndexBound == nil)
        let tree = graph.minimumSpanningTree { ties[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(graph.kruskalMinimumSpanningTree { ties[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { ties[$0].2 }.edges) == [0, 1])
        #expect(graph.maximumSpanningTree { ties[$0].2 }.edges == [0, 1])
        #expect(graph.minimumSpanningTree().edges == [0, 1])
        #expect(graph.primMinimumSpanningTree { ties[$0].2 }.weight == 2)

        // Vertices listed out of numeric order: the tie rule is by position, not by vertex index.
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let shuffled = VertexIndexedGraph(vertices: [6, 3, 0, 5, 1, 4, 2], edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [1, 5, 7, 0, 4, 9]
        #expect(shuffled.minimumSpanningTree { wiki[$0].2 }.edges == canonical)
        #expect(shuffled.kruskalMinimumSpanningTree { wiki[$0].2 }.weight == 39)
        #expect(Set(shuffled.boruvkaMinimumSpanningTree { wiki[$0].2 }.edges) == Set(canonical))
        #expect(Set(shuffled.primMinimumSpanningTree { wiki[$0].2 }.edges) == Set(canonical))
        #expect(Set(shuffled.primMinimumSpanningTree(from: 2) { wiki[$0].2 }.edges) == Set(canonical))
        #expect(shuffled.maximumSpanningTree { wiki[$0].2 }.edges == [6, 10, 3, 9, 2, 0])

        // AdjacencyMatrix has vertex indices but no edge indices; its positions are cells in
        // row-major order, which for Wikipedia's graph is the written order.
        var cells = [[Int]](repeating: [Int](repeating: 0, count: 7), count: 7)
        for (u, v, w) in wiki { cells[u][v] = w }
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: wiki.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(matrix.edgeIndexBound == nil)
        let matrixTree = matrix.minimumSpanningTree { cells[$0.source][$0.target] }
        #expect(matrixTree.edges.map { [$0.source, $0.target] } == [[0, 3], [2, 4], [3, 5], [0, 1], [1, 4], [4, 6]])
        #expect(matrixTree.weight == 39)
        #expect(matrix.kruskalMinimumSpanningTree { cells[$0.source][$0.target] } == matrixTree)
        #expect(Set(matrix.boruvkaMinimumSpanningTree { cells[$0.source][$0.target] }.edges) == Set(matrixTree.edges))
        #expect(Set(matrix.primMinimumSpanningTree { cells[$0.source][$0.target] }.edges) == Set(matrixTree.edges))
        #expect(matrix.maximumSpanningTree { cells[$0.source][$0.target] }.weight == 59)
    }

    @Test("ST-95 String vertices: petgraph's and JGraphT's graphs on UndirectedAdjacencyList and without indices")
    func stringVertices() {
        let prim: [(String, String, Int)] = [
            ("B", "A", 7), ("D", "A", 5), ("D", "B", 9), ("B", "C", 8), ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6),
            ("F", "E", 8), ("F", "G", 11), ("E", "G", 9),
        ]
        let kruskal: [(String, String, Int)] = [
            ("A", "B", 7), ("A", "D", 5), ("D", "B", 9), ("B", "C", 8), ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6),
            ("F", "E", 8), ("F", "G", 11), ("E", "G", 9), ("H", "I", 1), ("H", "J", 3), ("I", "J", 1),
        ]
        let jgrapht: [(String, String, Int)] = [
            ("A", "B", 5), ("A", "C", 10), ("B", "D", 15), ("C", "D", 20), ("E", "F", 20), ("E", "G", 15), ("G", "H", 10), ("F", "H", 5),
        ]
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        let cases: [([(String, String, Int)], [String], [Int], Int)] = [
            (prim, Array(letters.prefix(7)), [1, 5, 7, 0, 4, 10], 39),
            (kruskal, letters, [11, 13, 1, 5, 7, 0, 4, 10], 41),
            (jgrapht, Array(letters.prefix(8)), [0, 7, 1, 6, 2, 5], 60),
        ]
        for (edges, vertices, canonical, weight) in cases {
            let list = UndirectedAdjacencyList(vertices: vertices, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let plain = PlainGraph(vertices: vertices, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let listTree = list.minimumSpanningTree { edges[$0].2 }
            #expect(listTree.edges == canonical)
            #expect(listTree.weight == weight)
            #expect(Set(list.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == Set(canonical))
            #expect(Set(list.primMinimumSpanningTree { edges[$0].2 }.edges) == Set(canonical))
            #expect(list.primMinimumSpanningTree { edges[$0].2 }.weight == weight)
            let plainTree = plain.minimumSpanningTree { edges[$0].2 }
            #expect(plainTree.edges == canonical)
            #expect(plainTree.weight == weight)
            #expect(Set(plain.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == Set(canonical))
            #expect(plain.primMinimumSpanningTree { edges[$0].2 }.weight == weight)
        }
    }
}
