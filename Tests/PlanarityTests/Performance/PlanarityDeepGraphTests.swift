// Graphs whose depth-first trees are 10⁵ or more vertices deep, which a recursive search would
// overflow the call stack on: a path, a ladder, a polygon fan, a K₃,₃ with every edge subdivided
// into a long path, and a K₅ hanging off the end of a long path. Every expected value is known by
// construction. See README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("Planarity on deep graphs")
struct PlanarityDeepGraphTests {
    @Test("A path of 200,000 vertices: planar and outerplanar, one face walking every edge twice", .timeLimit(.minutes(1)))
    func longPath() throws {
        let n = 200_000
        let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        #expect(graph.isPlanar)
        #expect(graph.isOuterplanar)
        #expect(graph.findKuratowskiSubgraph() == nil)
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.faceCount == 1)
        #expect(embedding.faces[0].length == 2 * (n - 1))
        #expect(embedding.rightFace(from: n / 2, alongEdgeAt: n / 2) == 0 && embedding.rightFace(from: n / 2 + 1, alongEdgeAt: n / 2) == 0)
        #expect(Array(embedding.clockwiseNeighbors(of: n / 2)) == [n / 2 - 1, n / 2 + 1])
    }

    @Test("A ladder of 100,000 rungs: planar and outerplanar, one square per pair of rungs and the outer face", .timeLimit(.minutes(1)))
    func longLadder() throws {
        let h = 100_000
        // Rails 0 ..< h and h ..< 2h, rung i joining i and h + i.
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< h - 1 {
            edges.append(UndirectedEdge(i, i + 1))
            edges.append(UndirectedEdge(h + i, h + i + 1))
        }
        for i in 0 ..< h { edges.append(UndirectedEdge(i, h + i)) }
        let graph = Pseudograph<Int>(vertices: 0 ..< 2 * h, edges: edges)
        #expect(graph.isPlanar)
        #expect(graph.isOuterplanar)
        #expect(graph.findKuratowskiSubgraph() == nil)
        let embedding = try #require(graph.planarEmbedding())
        // m − n + 2 = (3h − 2) − 2h + 2.
        #expect(embedding.faceCount == h)
        var sides = [Int](repeating: 0, count: edges.count)
        for face in embedding.faces { for p in face.edges { sides[p] += 1 } }
        #expect(sides.allSatisfy { $0 == 2 })
        // 2-connected: every face is a cycle.
        #expect(embedding.faces.allSatisfy { Set($0.vertices.dropLast()).count == $0.length })
    }

    @Test("A polygon fan on 100,000 vertices has exactly 2n − 3 edges and is outerplanar; one more edge is not", .timeLimit(.minutes(1)))
    func polygonFan() {
        let n = 100_000
        // A path 1 ..< n, each vertex joined to the hub 0: a triangulated polygon.
        var edges = (1 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
        edges += (1 ..< n).map { UndirectedEdge(0, $0) }
        #expect(edges.count == 2 * n - 3)
        let fan = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
        #expect(fan.isOuterplanar)
        #expect(fan.isPlanar)
        // A chord from vertex 1 to vertex 3 crosses no edge, but leaves vertex 2 inside a triangle.
        let chorded = Pseudograph<Int>(vertices: 0 ..< n, edges: edges + [UndirectedEdge(1, 3)])
        #expect(!chorded.isOuterplanar)
        #expect(chorded.isPlanar)
    }

    @Test("A K₃,₃ with every edge subdivided into a path of 20,001 edges: the witness is the whole graph", .timeLimit(.minutes(1)))
    func subdividedK33() throws {
        let length = 20_000
        // Branch vertices 0, 1, 2 on one side and 3, 4, 5 on the other; inner vertices from 6.
        var edges: [UndirectedEdge<Int>] = []
        var next = 6
        for a in 0 ..< 3 {
            for b in 3 ..< 6 {
                var previous = a
                for _ in 0 ..< length {
                    edges.append(UndirectedEdge(previous, next))
                    previous = next
                    next += 1
                }
                edges.append(UndirectedEdge(previous, b))
            }
        }
        let graph = Pseudograph<Int>(vertices: 0 ..< next, edges: edges)
        #expect(!graph.isPlanar)
        #expect(!graph.isOuterplanar)
        #expect(graph.planarEmbedding() == nil)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.kind == .k33)
        #expect(witness.edges == Array(0 ..< edges.count))
        #expect(witness.branchVertices == [0, 1, 2, 3, 4, 5])
        #expect(witness.paths.count == 9 && witness.paths.allSatisfy { $0.edges.count == length + 1 })
        #expect(witness.paths.map { [$0.vertices.first!, $0.vertices.last!] } == [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]])
    }

    @Test("A K₅ at the end of a path of 200,000 vertices: the witness is the K₅", .timeLimit(.minutes(1)))
    func k5AfterLongPath() throws {
        let n = 200_000
        var edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
        // The K₅ on the last five vertices: its four consecutive pairs are path edges n − 5 ... n − 2.
        let k5 = Array(n - 5 ..< n)
        var k5Positions = [n - 5, n - 4, n - 3, n - 2]
        for i in 0 ..< 5 {
            for j in stride(from: i + 2, to: 5, by: 1) {
                k5Positions.append(edges.count)
                edges.append(UndirectedEdge(k5[i], k5[j]))
            }
        }
        let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
        #expect(!graph.isPlanar)
        #expect(graph.planarEmbedding() == nil)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.kind == .k5)
        #expect(witness.edges == k5Positions.sorted())
        #expect(witness.branchVertices == k5)
        #expect(witness.paths.allSatisfy { $0.edges.count == 1 })
    }
}
