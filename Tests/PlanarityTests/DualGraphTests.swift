// `PlanarEmbedding.dualGraph()`: hand-computed duals (the triangle, K4, a tree, the cube, a
// self-loop, parallel edges, two components, an isolated vertex, the empty graph), then, on random
// planar multigraphs with self-loops and parallel edges, the definition checked edge by edge
// (`rightFace` from each end) and the counts it implies (one dual vertex per face, one dual edge
// per edge, each dual vertex's degree its face's length); for connected graphs the dual of the
// dual has the graph's vertex and edge counts.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Planarity
import PropertyBased
import Testing

@Suite("PlanarEmbedding.dualGraph")
struct DualGraphTests {
    @Test("A triangle: two faces joined by three parallel edges")
    func triangle() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let embedding = try #require(graph.planarEmbedding())
        let dual = embedding.dualGraph()
        #expect(Array(dual.vertices) == [0, 1])
        #expect(dual.edgeCount == 3)
        #expect(dual.edges.allSatisfy { Set([$0.u, $0.v]) == [0, 1] })
        #expect(dual.edgeCount(between: 0, and: 1) == 3)
        // Each dual edge goes from the face right of the edge crossed from its lower end.
        for (k, e) in graph.edges.enumerated() {
            let low = Swift.min(e.u, e.v), high = Swift.max(e.u, e.v)
            #expect(dual.edges[k] == UndirectedEdge(embedding.rightFace(from: low, alongEdgeAt: k), embedding.rightFace(from: high, alongEdgeAt: k)))
            #expect(dual.edges[k].u == embedding.rightFace(from: low, alongEdgeAt: k))
        }
    }

    @Test("K4 is self-dual: four faces, each pair joined once")
    func completeFour() throws {
        var ends: [UndirectedEdge<Int>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { ends.append(UndirectedEdge(u, v)) } }
        let embedding = try #require(UndirectedAdjacencyList(vertices: 0 ..< 4, edges: ends).planarEmbedding())
        let dual = embedding.dualGraph()
        #expect(dual.vertexCount == 4 && dual.edgeCount == 6)
        for a in 0 ..< 4 { for b in a + 1 ..< 4 { #expect(dual.edgeCount(between: a, and: b) == 1) } }
        #expect(dual.edges.allSatisfy { $0.u != $0.v })
    }

    @Test("A tree: one face, every edge a self-loop on it")
    func tree() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(3, 4)])
        let dual = try #require(graph.planarEmbedding()).dualGraph()
        #expect(Array(dual.vertices) == [0])
        #expect(dual.edges.map { [$0.u, $0.v] } == Array(repeating: [0, 0], count: 4))
        #expect(dual.degree(of: 0) == 8)
    }

    @Test("The cube's dual is the octahedron: six faces of degree 4, twelve edges, no loops or parallel edges")
    func cube() throws {
        var ends: [UndirectedEdge<Int>] = []
        for v in 0 ..< 8 {
            for bit in [1, 2, 4] where v & bit == 0 { ends.append(UndirectedEdge(v, v | bit)) }
        }
        let dual = try #require(UndirectedAdjacencyList(vertices: 0 ..< 8, edges: ends).planarEmbedding()).dualGraph()
        #expect(dual.vertexCount == 6 && dual.edgeCount == 12)
        #expect(dual.vertices.allSatisfy { dual.degree(of: $0) == 4 })
        #expect(dual.edges.allSatisfy { $0.u != $0.v })
        #expect(Set(dual.edges.map { [Swift.min($0.u, $0.v), Swift.max($0.u, $0.v)] }).count == 12)
    }

    @Test("A self-loop and parallel edges: faces of length 1 and 2 in the dual")
    func multigraph() throws {
        // 0-1 twice and a loop at 1: faces the loop's inside (1), between the copies (2), outside.
        let graph = Pseudograph(vertices: [0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let embedding = try #require(graph.planarEmbedding())
        let dual = embedding.dualGraph()
        #expect(dual.vertexCount == embedding.faceCount && dual.vertexCount == 3)
        #expect(dual.edgeCount == 3)
        let lengths = embedding.faces.map(\.length)
        for f in 0 ..< 3 { #expect(dual.degree(of: f) == lengths[f]) }
        #expect(lengths.sorted() == [1, 2, 3])
        // The loop separates its inside from the face around it.
        let loop = dual.edges[2]
        #expect(loop.u != loop.v)
        #expect(lengths[loop.u] == 1 || lengths[loop.v] == 1)
    }

    @Test("Two components and an isolated vertex: the disjoint union of the duals; the empty graph's dual is empty")
    func disconnected() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0),
                                                                     UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        let embedding = try #require(graph.planarEmbedding())
        let dual = embedding.dualGraph()
        #expect(dual.vertexCount == 4 && dual.edgeCount == 6)
        // The first triangle's edges join its two faces, the second's the other two.
        let first = Set(dual.edges[0 ..< 3].flatMap { [$0.u, $0.v] }), second = Set(dual.edges[3 ..< 6].flatMap { [$0.u, $0.v] })
        #expect(first.count == 2 && second.count == 2 && first.isDisjoint(with: second))
        let empty = try #require(UndirectedAdjacencyList<Int>().planarEmbedding()).dualGraph()
        #expect(empty.vertexCount == 0 && empty.edgeCount == 0)
        let isolated = try #require(UndirectedAdjacencyList(vertices: 0 ..< 3, edges: []).planarEmbedding()).dualGraph()
        #expect(isolated.vertexCount == 0 && isolated.edgeCount == 0)
    }

    @Test("Vertices that are not their indices, and a graph without them: the same dual by edge order")
    func representations() throws {
        let labels = ["c", "a", "b", "d"]
        let ends = [("c", "a"), ("a", "b"), ("b", "c"), ("b", "d")]
        let graph = UndirectedAdjacencyList(vertices: labels, edges: ends.map { UndirectedEdge($0.0, $0.1) })
        let embedding = try #require(graph.planarEmbedding())
        let dual = embedding.dualGraph()
        #expect(dual.vertexCount == 2 && dual.edgeCount == 4)
        // The pendant edge b-d is a bridge: a loop on the outer face.
        #expect(dual.edges[3].u == dual.edges[3].v)
        for (k, e) in graph.edges.enumerated() {
            let low = graph.vertexIndex(of: e.u) < graph.vertexIndex(of: e.v) ? e.u : e.v
            let high = low == e.u ? e.v : e.u
            #expect(dual.edges[k] == UndirectedEdge(embedding.rightFace(from: low, alongEdgeAt: k), embedding.rightFace(from: high, alongEdgeAt: k)))
        }
        let reference = ReferencePseudograph(vertices: labels, edges: ends.map { UndirectedEdge($0.0, $0.1) })
        let referenceDual = try #require(reference.planarEmbedding()).dualGraph()
        #expect(referenceDual.edgeCount == 4 && referenceDual.vertexCount == 2)
    }

    @Test("Random planar multigraphs: the definition edge by edge, the counts, and the dual of the dual", .tags(.randomized))
    func random() async {
        let raw = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: raw, Gen.int(in: 1 ... 8)) { raw, n in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            guard let embedding = graph.planarEmbedding() else { return }
            let dual = embedding.dualGraph()
            let counts = dual.vertexCount == embedding.faceCount && dual.edgeCount == graph.edgeCount
            #expect(counts, "\(ends)")
            var definition = true
            for (k, e) in graph.edges.enumerated() {
                let (low, high) = e.u <= e.v ? (e.u, e.v) : (e.v, e.u)
                let left = embedding.rightFace(from: low, alongEdgeAt: k)
                // A self-loop's first end: the slot listed first in the clockwise order.
                let right = low == high ? embedding.rightFace(from: low, alongEdgeAt: k) : embedding.rightFace(from: high, alongEdgeAt: k)
                definition = definition && dual.edges[k].u == left && (low == high || dual.edges[k].v == right)
            }
            #expect(definition, "\(ends)")
            let lengths = embedding.faces.map(\.length)
            let degrees = (0 ..< dual.vertexCount).allSatisfy { dual.degree(of: $0) == lengths[$0] }
            #expect(degrees, "\(ends)")
            // Connected with an edge: the dual is connected and planar, and its dual has the graph's
            // vertex and edge counts (Euler's formula twice).
            var parent = Array(0 ..< n)
            func root(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (a, b) in ends { parent[root(a)] = root(b) }
            guard !ends.isEmpty, (0 ..< n).allSatisfy({ root($0) == root(0) }) else { return }
            guard let second = dual.planarEmbedding() else {
                Issue.record("the dual of \(ends) is not planar")
                return
            }
            let double = second.dualGraph()
            let same = double.vertexCount == n && double.edgeCount == graph.edgeCount
            #expect(same, "\(ends)")
        }
    }
}
