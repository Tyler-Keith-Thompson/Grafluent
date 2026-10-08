// Cases added after the critical review: bugs that survived the first suite. Each one names what
// it guards against. Case IDs (UG-Rnn) continue the protocol catalog; see README.md.

import AdjacencyListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList review cases")
struct UndirectedAdjacencyListReviewTests {
    @Test("UG-R21 removeAllEdges forgets every edge: contains is false and reinserting works")
    func removeAllEdgesForgets() {
        for keepingCapacity in [false, true] {
            var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
            graph.removeAllEdges(keepingCapacity: keepingCapacity)
            #expect(graph.edgeCount == 0)
            #expect(graph.vertexCount == 3)
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)))
            #expect(!graph.contains(edge: UndirectedEdge(2, 2)))
            #expect(graph.degree(of: 2) == 0)
            #expect(graph.insert(edge: UndirectedEdge(1, 0)).inserted == true)
            #expect(graph.edgeCount == 1)
            #expect(Array(graph.neighbors(of: 0)) == [1])
            #expect(graph == UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)]))
        }
    }

    @Test("UG-R16 edgeless graphs with the same number of different vertices are not equal")
    func edgelessGraphsCompareVertices() {
        let a = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2])
        let b = UndirectedAdjacencyList<Int>(vertices: [0, 1, 3])
        #expect(a != b)
        // Built in another order, so the slot arrays differ and the slow path compares.
        let c = UndirectedAdjacencyList<Int>(vertices: [2, 0, 1])
        #expect(a == c)
        #expect(a.hashValue == c.hashValue)
    }

    @Test("UG-R16 different graphs hash differently: the vertex set and the edge set both count")
    func hashesSeeVerticesAndEdges() {
        let graphs = [
            UndirectedAdjacencyList<Int>(),
            UndirectedAdjacencyList(vertices: [0, 1, 2]),
            UndirectedAdjacencyList(vertices: [0, 1, 3]),
            UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]),
            UndirectedAdjacencyList(edges: [UndirectedEdge(0, 2)]),
            UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)]),
            UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 2)]),
            UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 0)]),
        ]
        // Equal hashes for unequal graphs are allowed, but all eight colliding would mean the
        // hash ignores what tells them apart.
        #expect(Set(graphs.map(\.hashValue)).count == graphs.count)
    }

    @Test("UG-R10 reinserting an edge in either orientation returns the stored edge and instances")
    func memberAfterInsert() {
        let zero = HashableBox(0, label: "stored")
        let one = HashableBox(1, label: "stored")
        var graph = UndirectedAdjacencyList<HashableBox>()
        graph.insert(edge: UndirectedEdge(zero, one))
        let same = graph.insert(edge: UndirectedEdge(HashableBox(0), HashableBox(1)))
        #expect(same.inserted == false)
        #expect(same.memberAfterInsert.u === zero)
        #expect(same.memberAfterInsert.v === one)
        let reversed = graph.insert(edge: UndirectedEdge(HashableBox(1), HashableBox(0)))
        #expect(reversed.inserted == false)
        #expect(reversed.memberAfterInsert.u === zero)
        #expect(reversed.memberAfterInsert.v === one)
        let vertex = graph.insert(HashableBox(1))
        #expect(vertex.inserted == false)
        #expect(vertex.memberAfterInsert === one)
        #expect(graph.remove(HashableBox(0)) === zero)
    }

    @Test("UG-R19 decoding keeps each edge's position and orientation")
    func codableKeepsOrientation() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(1, 0), UndirectedEdge(2, 1), UndirectedEdge(2, 2)])
        let decoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded.edges.map(\.u) == [1, 2, 2])
        #expect(decoded.edges.map(\.v) == [0, 1, 2])
        #expect(Array(decoded.vertices) == [1, 0, 2])
    }

    @Test("UG-R19 decoding rejects an edge given twice, in either orientation")
    func decodingRejectsRepeatedEdges() {
        for json in [#"{"vertices":[0,1],"edges":[0,1,0,1]}"#, #"{"vertices":[0,1],"edges":[0,1,1,0]}"#, #"{"vertices":[5],"edges":[0,0,0,0]}"#] {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: Data(json.utf8))
            }
        }
    }

    @Test("UG-R22 edge indices are the positions, and the incident ones run parallel to the neighbors")
    func edgeIndices() {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        graph.remove(edge: UndirectedEdge(0, 1))
        #expect(graph.edgeIndexBound == 3)
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0, 1, 2])
        for v in graph.vertices {
            let i = graph.vertexIndex(of: v)
            let indices = Array(graph.incidentEdgeIndices(ofIndex: i))
            #expect(indices == Array(graph.incidentEdges(of: v)))
            #expect(indices.count == Array(graph.neighborIndices(ofIndex: i)).count)
            for (e, w) in zip(indices, graph.neighborIndices(ofIndex: i)) {
                #expect(graph.oppositeVertex(to: v, acrossEdgeAt: e) == graph.vertex(atIndex: w))
            }
        }
    }

    @Test("UG-P02 random insertions and removals keep every law, against a set model", .tags(.randomized), arguments: 1 ... 12)
    func randomMutations(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 2_200)
        var graph = UndirectedAdjacencyList<Int>()
        var vertices: Set<Int> = []
        var edges: Set<UndirectedEdge<Int>> = []
        let n = 3 + seed % 6
        for _ in 0 ..< 150 {
            let a = Int.random(in: 0 ..< n, using: &generator), b = Int.random(in: 0 ..< n, using: &generator)
            switch Int.random(in: 0 ..< 12, using: &generator) {
            case 0 ..< 5:
                #expect(graph.insert(edge: UndirectedEdge(a, b)).inserted == !edges.contains(UndirectedEdge(a, b)))
                edges.insert(UndirectedEdge(a, b))
                vertices.formUnion([a, b])
            case 5 ..< 9:
                #expect((graph.remove(edge: UndirectedEdge(a, b)) != nil) == edges.contains(UndirectedEdge(a, b)))
                edges.remove(UndirectedEdge(a, b))
            case 9:
                #expect((graph.remove(a) != nil) == vertices.contains(a))
                vertices.remove(a)
                edges = edges.filter { $0.u != a && $0.v != a }
            case 10:
                graph.insert(a)
                vertices.insert(a)
            default:
                if Int.random(in: 0 ..< 8, using: &generator) == 0 {
                    graph.removeAllEdges()
                    edges = []
                }
            }
            #expect(Set(graph.vertices) == vertices)
            #expect(graph.vertexCount == vertices.count)
            #expect(graph.edgeCount == edges.count)
            #expect(Set(graph.edges) == edges)
            var degrees = 0
            for v in vertices {
                let incident = Array(graph.incidentEdges(of: v))
                let neighbors = Array(graph.neighbors(of: v))
                #expect(incident.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) } == neighbors)
                #expect(graph.degree(of: v) == neighbors.count)
                #expect(neighbors.map { graph.vertexIndex(of: $0) } == Array(graph.neighborIndices(ofIndex: graph.vertexIndex(of: v))))
                var ends: [UndirectedEdge<Int>: Int] = [:]
                for e in incident { ends[graph.edges[e], default: 0] += 1 }
                var expected: [UndirectedEdge<Int>: Int] = [:]
                for e in edges where e.u == v || e.v == v { expected[e] = e.isSelfLoop ? 2 : 1 }
                #expect(ends == expected)
                degrees += neighbors.count
            }
            #expect(degrees == 2 * edges.count)
            for a in 0 ..< n {
                for b in 0 ..< n { #expect(graph.contains(edge: UndirectedEdge(a, b)) == edges.contains(UndirectedEdge(a, b))) }
            }
            let rebuilt = UndirectedAdjacencyList(vertices: vertices.sorted(), edges: edges.sorted())
            #expect(graph == rebuilt)
            #expect(graph.hashValue == rebuilt.hashValue)
        }
    }
}
