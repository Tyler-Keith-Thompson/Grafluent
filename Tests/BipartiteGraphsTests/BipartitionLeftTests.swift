// `bipartition(left:)`: the caller's left side, every other vertex right, each side in `vertices`
// order; nil when an edge (a self-loop included) has both ends on one side or `left` names a
// non-vertex. Read on an indexed graph and on one without indices, and checked against
// `bipartition()` given its own left side and against `BipartiteGraph(_:left:)`.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import GraphProtocols
import Testing

/// An undirected graph with no vertex or edge indices.
private struct UnindexedGraph: Graph {
    let vertices: [String]
    let edges: [UndirectedEdge<String>]
    func incidentEdges(of vertex: String) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: String) -> [String] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("bipartition(left:)")
struct BipartitionLeftTests {
    @Test("Two stars whose centres come mid-list: the caller's sides, not the canonical ones")
    func callerSides() throws {
        let vertices = ["j1", "j2", "w1", "w2", "j3", "j4"]
        let edges = [("w1", "j1"), ("w1", "j2"), ("w2", "j3"), ("w2", "j4")].map { UndirectedEdge($0.0, $0.1) }
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let canonical = try #require(indexed.bipartition())
        #expect(Array(canonical.left) == ["j1", "j2", "w2"])
        let sides = try #require(indexed.bipartition(left: ["w1", "w2"]))
        #expect(Array(sides.left) == ["w1", "w2"])
        #expect(Array(sides.right) == ["j1", "j2", "j3", "j4"])
        #expect(sides.side(of: "w2") == .left)
        #expect(sides.side(of: "j3") == .right)
        #expect(sides.side(ofIndex: indexed.vertexIndex(of: "w1")) == .left)
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(plain.vertexIndexBound == nil)
        let unindexed = try #require(plain.bipartition(left: ["w2", "w1"]))
        #expect(Array(unindexed.left) == ["w1", "w2"])
        #expect(Array(unindexed.right) == ["j1", "j2", "j3", "j4"])
        #expect(unindexed.side(of: "j1") == .right)
        #expect(unindexed.side(ofIndex: 3) == .left)
        // The jobs on the left instead.
        let flipped = try #require(indexed.bipartition(left: ["j1", "j2", "j3", "j4"]))
        #expect(Array(flipped.left) == ["j1", "j2", "j3", "j4"])
        #expect(Array(flipped.right) == ["w1", "w2"])
    }

    @Test("nil when an edge has both ends on one side, on either side, with or without indices")
    func edgeInsideASide() {
        // The path a-b-c.
        let vertices = ["a", "b", "c"]
        let edges = [("a", "b"), ("b", "c")].map { UndirectedEdge($0.0, $0.1) }
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(indexed.bipartition(left: ["a", "b"]) == nil)
        #expect(indexed.bipartition(left: ["a"]) == nil)
        #expect(indexed.bipartition(left: [] as [String]) == nil)
        #expect(indexed.bipartition(left: ["a", "b", "c"]) == nil)
        #expect(plain.bipartition(left: ["a", "b"]) == nil)
        #expect(plain.bipartition(left: ["a"]) == nil)
        #expect(indexed.bipartition(left: ["b"]) != nil)
        #expect(indexed.bipartition(left: ["a", "c"]) != nil)
        #expect(plain.bipartition(left: ["b"]) != nil)
    }

    @Test("nil for a self-loop whichever side its vertex is on")
    func selfLoop() {
        let vertices = ["a", "b"]
        let edges = [UndirectedEdge("a", "b"), UndirectedEdge("b", "b")]
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(indexed.bipartition(left: ["a"]) == nil)
        #expect(indexed.bipartition(left: ["b"]) == nil)
        #expect(plain.bipartition(left: ["a"]) == nil)
        #expect(plain.bipartition(left: ["b"]) == nil)
    }

    @Test("An isolated vertex goes on whichever side the caller puts it")
    func isolatedVertex() throws {
        // The edge a-b and the isolated z.
        let vertices = ["a", "b", "z"]
        let edges = [UndirectedEdge("a", "b")]
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        let zLeft = try #require(indexed.bipartition(left: ["a", "z"]))
        #expect(Array(zLeft.left) == ["a", "z"])
        #expect(Array(zLeft.right) == ["b"])
        let zRight = try #require(indexed.bipartition(left: ["a"]))
        #expect(Array(zRight.left) == ["a"])
        #expect(Array(zRight.right) == ["b", "z"])
        #expect(zRight.side(of: "z") == .right)
        let plainLeft = try #require(plain.bipartition(left: ["z", "b"]))
        #expect(Array(plainLeft.left) == ["b", "z"])
        #expect(Array(plainLeft.right) == ["a"])
        // A graph of isolated vertices takes any split, the empty one included.
        let empty = UndirectedAdjacencyList(vertices: ["p", "q"], edges: [])
        let allRight = try #require(empty.bipartition(left: [] as [String]))
        #expect(allRight.left.isEmpty)
        #expect(Array(allRight.right) == ["p", "q"])
        let allLeft = try #require(empty.bipartition(left: ["q", "p"]))
        #expect(Array(allLeft.left) == ["p", "q"])
        #expect(allLeft.right.isEmpty)
        // The graph with no vertices.
        let none = UndirectedAdjacencyList<String>(vertices: [], edges: [])
        let nothing = try #require(none.bipartition(left: [] as [String]))
        #expect(nothing.left.isEmpty && nothing.right.isEmpty)
    }

    @Test("nil when left names a non-vertex; repeats in left are one vertex")
    func nonVertexAndRepeats() throws {
        let vertices = ["a", "b"]
        let edges = [UndirectedEdge("a", "b")]
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        #expect(indexed.bipartition(left: ["a", "q"]) == nil)
        #expect(indexed.bipartition(left: ["q"]) == nil)
        #expect(plain.bipartition(left: ["q", "a"]) == nil)
        let repeated = try #require(indexed.bipartition(left: ["a", "a", "a"]))
        #expect(Array(repeated.left) == ["a"])
        #expect(Array(repeated.right) == ["b"])
        let plainRepeated = try #require(plain.bipartition(left: ["b", "b"]))
        #expect(Array(plainRepeated.left) == ["b"])
        #expect(Array(plainRepeated.right) == ["a"])
    }

    @Test("Given bipartition()'s own left side, the same bipartition, on several representations")
    func parityWithBipartition() throws {
        // A 6-cycle with a pendant path, a 4-cycle listed out of order, and an isolated vertex.
        let vertices = ["c0", "c1", "c2", "c3", "c4", "c5", "p1", "p2", "s0", "s1", "s2", "s3", "x"]
        let pairs = [
            ("c0", "c1"), ("c1", "c2"), ("c2", "c3"), ("c3", "c4"), ("c4", "c5"), ("c5", "c0"),
            ("c3", "p1"), ("p1", "p2"),
            ("s2", "s1"), ("s1", "s0"), ("s0", "s3"), ("s3", "s2"),
        ]
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        let indexed = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let canonical = try #require(indexed.bipartition())
        #expect(indexed.bipartition(left: canonical.left) == canonical)
        let complement = try #require(indexed.bipartition(left: canonical.right))
        #expect(Array(complement.left) == Array(canonical.right))
        #expect(Array(complement.right) == Array(canonical.left))
        let plain = UnindexedGraph(vertices: vertices, edges: edges)
        let plainCanonical = try #require(plain.bipartition())
        #expect(plain.bipartition(left: plainCanonical.left) == plainCanonical)
        // Through `AdjacencyMatrix.undirectedView`, vertices 0..<n.
        let arcs = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6)]
        let matrix = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        let matrixCanonical = try #require(matrix.bipartition())
        #expect(matrix.bipartition(left: matrixCanonical.left) == matrixCanonical)
        #expect(matrix.bipartition(left: [0, 1]) == nil)
        // Through `AdjacencyList.undirectedView`, a vertex reached from both directions.
        let list = AdjacencyList(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 2)]).undirectedView
        let listCanonical = try #require(list.bipartition())
        #expect(list.bipartition(left: listCanonical.left) == listCanonical)
        let swapped = try #require(list.bipartition(left: [1, 2]))
        #expect(Array(swapped.left) == [1, 2])
        #expect(Array(swapped.right) == [0, 3])
    }

    @Test("Agrees with BipartiteGraph(_:left:) on which sides it accepts and what they are")
    func agreesWithBipartiteGraphInitializer() {
        let vertices = ["a", "b", "c", "d"]
        let edges = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "a")].map { UndirectedEdge($0.0, $0.1) }
        let graph = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        let lefts: [[String]] = [[], ["a"], ["a", "c"], ["b", "d"], ["a", "b"], ["a", "c", "c"], ["a", "q"], vertices]
        for left in lefts {
            let bipartition = graph.bipartition(left: left)
            let bipartite = BipartiteGraph<String>(graph, left: left)
            #expect((bipartition == nil) == (bipartite == nil), "left \(left)")
            if let bipartition, let bipartite {
                #expect(Set(bipartition.left) == Set(bipartite.left), "left \(left)")
                #expect(Set(bipartition.right) == Set(bipartite.right), "left \(left)")
            }
        }
    }
}
