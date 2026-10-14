// Truss numbers and k-trusses (Cohen; Wang–Cheng), on the simple graph: parallel edges share
// their simple edge's number and a self-loop has none. Hand-computed graphs, every
// representation the module's other suites use, the checked spelling, exits, and a property test
// against peeling by definition (repeatedly delete edges in fewer than k − 2 triangles).

import AdjacencyListModule
import AdjacencyMatrixModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

/// An undirected pseudograph without vertex or edge indices, rows in position order, so the
/// decomposition numbers vertices and edges through dictionaries.
private struct UnindexedPseudograph: Graph {
    let vertices: [String]
    let edges: [UndirectedEdge<String>]

    func incidentEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].u == vertex || edges[$0].v == vertex }.flatMap { edges[$0].u == edges[$0].v ? [$0, $0] : [$0] } }
    func neighbors(of vertex: String) -> [String] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Truss numbers and k-trusses")
struct TrussTests {
    @Test("CQ-910 K₄: every edge has truss number 4; kTruss(4) is every edge, kTruss(5) none")
    func completeGraph() {
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let trusses = graph.trussNumbers()
        #expect(graph.edges.indices.map { trusses.trussNumber(ofEdgeAt: $0) } == [4, 4, 4, 4, 4, 4])
        #expect(trusses.kTruss(4) == Array(0 ..< 6))
        #expect(trusses.kTruss(5) == [])
        #expect(trusses.kTruss(0) == Array(0 ..< 6))
    }

    @Test("CQ-911 A triangle with a pendant edge: the triangle's edges are 3, the pendant 2")
    func trianglePendant() {
        let pairs = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let trusses = graph.trussNumbers()
        #expect(graph.edges.indices.map { trusses.trussNumber(ofEdgeAt: $0) } == [3, 3, 3, 2])
        #expect(trusses.kTruss(2) == [0, 1, 2, 3])
        #expect(trusses.kTruss(3) == [0, 1, 2])
        #expect(trusses.kTruss(4) == [])
    }

    @Test("CQ-912 The diamond: the shared edge is in two triangles, but the 4-truss is empty, so every edge is 3")
    func diamond() {
        let pairs = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let trusses = graph.trussNumbers()
        #expect(graph.edges.indices.map { trusses.trussNumber(ofEdgeAt: $0) } == [3, 3, 3, 3, 3])
        #expect(trusses.kTruss(4) == [])
    }

    @Test("CQ-913 K₅ and K₄ joined by an edge, a 4-cycle, and a triangle on a K₄ edge: 5, 4, 2, 2, then 3, 3 and the copy's 4")
    func mixed() {
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append((u, v)) } }
        for u in 5 ..< 9 { for v in u + 1 ..< 9 { pairs.append((u, v)) } }
        pairs += [(4, 5), (9, 10), (10, 11), (11, 12), (12, 9)]
        // Vertex 13 closes one triangle on K₄'s edge 6–8, which is given again as a parallel copy.
        pairs += [(8, 13), (13, 6), (8, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let trusses = graph.trussNumbers()
        let numbers = graph.edges.indices.map { trusses.trussNumber(ofEdgeAt: $0) }
        #expect(numbers == Array(repeating: 5, count: 10) + Array(repeating: 4, count: 6) + [2, 2, 2, 2, 2] + [3, 3, 4])
        #expect(trusses.kTruss(5) == Array(0 ..< 10))
        #expect(trusses.kTruss(4) == Array(0 ..< 16) + [23])
    }

    @Test("CQ-914 Self-loops have no truss number and are in no k-truss; parallel copies share their simple edge's number")
    func loopsAndParallels() {
        let pairs = [(0, 1), (1, 2), (0, 2), (0, 1), (2, 2), (1, 2), (2, 3), (3, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let trusses = graph.trussNumbers()
        #expect(graph.edges.indices.map { trusses.trussNumber(ofEdgeAt: $0) } == [3, 3, 3, 3, nil, 3, 2, nil])
        #expect(trusses.kTruss(0) == [0, 1, 2, 3, 5, 6])
        #expect(trusses.kTruss(3) == [0, 1, 2, 3, 5])
        let pseudograph = Pseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let viaPseudograph = pseudograph.trussNumbers()
        #expect(pseudograph.edges.indices.map { viaPseudograph.trussNumber(ofEdgeAt: $0) } == [3, 3, 3, 3, nil, 3, 2, nil])
    }

    @Test("CQ-915 The empty graph, one vertex, and an edgeless graph have no edges in any truss")
    func degenerate() {
        let empty = ReferencePseudograph<Int>(edges: [])
        #expect(empty.trussNumbers().kTruss(0) == [])
        let one = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        #expect(one.trussNumbers().trussNumber(ofEdgeAt: 0) == nil)
        #expect(one.trussNumbers().kTruss(2) == [])
        let edgeless = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge<Int>]())
        #expect(edgeless.trussNumbers().kTruss(0) == [])
    }

    @Test("CQ-916 Every representation: UndirectedAdjacencyList, Pseudograph, AdjacencyList and AdjacencyMatrix through undirectedView, and a graph without indices")
    func representations() {
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (3, 5)]
        let expected: [Int] = [4, 4, 4, 4, 4, 4, 3, 3, 3]
        let list = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let listTrusses = list.trussNumbers()
        for p in list.edges.indices {
            let e = list.edges[p]
            let k = pairs.firstIndex { UndirectedEdge($0.0, $0.1) == e }!
            #expect(listTrusses.trussNumber(ofEdgeAt: p) == expected[k])
        }
        let pseudograph = Pseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let pseudoTrusses = pseudograph.trussNumbers()
        #expect(pseudograph.edges.indices.map { pseudoTrusses.trussNumber(ofEdgeAt: $0) } == expected)
        let directed = AdjacencyList(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        let directedTrusses = directed.trussNumbers()
        for p in directed.edges.indices {
            let e = directed.edges[p]
            let k = pairs.firstIndex { UndirectedEdge($0.0, $0.1) == UndirectedEdge(e.u, e.v) }!
            #expect(directedTrusses.trussNumber(ofEdgeAt: p) == expected[k])
        }
        #expect(directedTrusses.kTruss(4).count == 6)
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        let matrixTrusses = matrix.trussNumbers()
        #expect(matrixTrusses.kTruss(4).count == 6)
        #expect(matrixTrusses.kTruss(3).count == 9)
        for p in matrix.edges.indices {
            let e = matrix.edges[p]
            let k = pairs.firstIndex { UndirectedEdge($0.0, $0.1) == UndirectedEdge(e.u, e.v) }!
            #expect(matrixTrusses.trussNumber(ofEdgeAt: p) == expected[k])
        }
        let names = ["a", "b", "c", "d", "e", "f"]
        let plain = UnindexedPseudograph(vertices: names.reversed(), edges: pairs.map { UndirectedEdge(names[$0.0], names[$0.1]) })
        let plainTrusses = plain.trussNumbers()
        #expect(plain.edges.indices.map { plainTrusses.trussNumber(ofEdgeAt: $0) } == expected)
        #expect(plainTrusses.kTruss(4) == Array(0 ..< 6))
    }

    @Test("CQ-917 trussNumber(checkedEdgeAt:) throws EdgeNotFound for a position outside the graph and answers otherwise")
    func checked() throws {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 2)])
        let trusses = graph.trussNumbers()
        #expect(throws: EdgeNotFound.self) { try trusses.trussNumber(checkedEdgeAt: 4) }
        #expect(throws: EdgeNotFound.self) { try trusses.trussNumber(checkedEdgeAt: -1) }
        #expect(try trusses.trussNumber(checkedEdgeAt: 1) == 3)
        #expect(try trusses.trussNumber(checkedEdgeAt: 3) == nil)
        let plain = UnindexedPseudograph(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(throws: EdgeNotFound.self) { try plain.trussNumbers().trussNumber(checkedEdgeAt: 1) }
        #expect(try plain.trussNumbers().trussNumber(checkedEdgeAt: 0) == 2)
    }

    @Test("CQ-918 trussNumber(ofEdgeAt:) traps on a position outside the graph, kTruss on a negative k")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.trussNumbers().trussNumber(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.trussNumbers().kTruss(-1)
        }
    }

    @Test("CQ-919 Truss numbers are peeling by definition: an edge's number is the largest k for which it survives deleting edges in fewer than k − 2 triangles", .tags(.randomized))
    func againstPeeling() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 36)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 9), edges) { n, raw in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var simple = Set<[Int]>()
            for (a, b) in pairs where a != b { simple.insert([min(a, b), max(a, b)]) }
            var truss: [[Int]: Int] = [:]
            for e in simple { truss[e] = 2 }
            var k = 3
            while true {
                var alive = simple
                var changed = true
                while changed {
                    changed = false
                    for e in alive {
                        let triangles = (0 ..< n).filter { w in alive.contains([min(e[0], w), max(e[0], w)]) && alive.contains([min(e[1], w), max(e[1], w)]) }.count
                        if triangles < k - 2 {
                            alive.remove(e)
                            changed = true
                        }
                    }
                }
                if alive.isEmpty { break }
                for e in alive { truss[e] = k }
                k += 1
            }
            let trusses = graph.trussNumbers()
            for (p, (a, b)) in pairs.enumerated() {
                let expected = a == b ? nil : truss[[min(a, b), max(a, b)]]
                #expect(trusses.trussNumber(ofEdgeAt: p) == expected, "\(pairs) edge \(p)")
            }
            for k in 0 ... k {
                let expected = pairs.indices.filter { pairs[$0].0 != pairs[$0].1 && truss[[min(pairs[$0].0, pairs[$0].1), max(pairs[$0].0, pairs[$0].1)]]! >= k }
                #expect(trusses.kTruss(k) == expected, "k = \(k)")
            }
        }
    }
}
