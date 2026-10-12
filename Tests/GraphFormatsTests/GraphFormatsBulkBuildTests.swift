// The line formats (Matrix Market, edge list, adjacency list) collect a whole file and build the
// graph in one step. These check, on seeded random files with repeated pairs, self-loops and
// aliased IDs (`01` and `1` are one Int vertex), that the result is the graph inserting the same
// vertices and edges in file order builds: the same vertices, the same edge at each position, each
// vertex's rows in the same order; that a simple target keeps an edge's first orientation and
// reports a repeated pair's attributes on its first position; and that the graph still mutates
// correctly afterwards. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("GraphFormats bulk construction")
struct GraphFormatsBulkBuildTests {
    @Test("Each line reader builds the graph insertion would, in every representation", arguments: 0 ..< 60 as Range<UInt>)
    func matchesInsertion(seed: UInt) throws {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let n = Int.random(in: 1 ... 12, using: &rng)
        let m = Int.random(in: 0 ... 50, using: &rng)
        var pairs: [(Int, Int)] = []
        var order: [Int] = []
        var lines: [String] = []
        for _ in 0 ..< m {
            let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
            pairs.append((u, v))
            for w in [u, v] where !order.contains(w) { order.append(w) }
            // An alias with a leading zero reads as the same Int vertex.
            let su = Bool.random(using: &rng) ? "0\(u)" : "\(u)", sv = Bool.random(using: &rng) ? "+\(v)" : "\(v)"
            lines.append("\(su)\t\(sv) \(u * 100 + v)")
        }
        let edgeList = lines.joined(separator: "\n")
        let matrixMarket = "%%MatrixMarket matrix coordinate integer general\n\(n) \(n) \(m)\n"
            + pairs.map { "\($0.0 + 1) \($0.1 + 1) \($0.0 * 100 + $0.1)\n" }.joined()
        let symmetric = "%%MatrixMarket matrix coordinate integer symmetric\n\(n) \(n) \(m)\n"
            + pairs.map { "\($0.0 + 1) \($0.1 + 1) \($0.0 * 100 + $0.1)\n" }.joined()
        let directedEdges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let undirectedEdges = pairs.map { UndirectedEdge($0.0, $0.1) }

        func rows<G: BidirectionalDirectedGraph>(_ g: G) -> [String] where G.Vertex == Int {
            var offsets: [G.Edges.Index: Int] = [:]
            for (k, p) in g.edges.indices.enumerated() { offsets[p] = k }
            var out = ["vertices \(Array(g.vertices))", "edges \(g.edges.map { "\($0.source)>\($0.target)" })"]
            for v in g.vertices {
                out.append("\(v): \(Array(g.successors(of: v))) \(Array(g.predecessors(of: v))) "
                    + "\(g.outEdges(of: v).map { offsets[$0]! }) \(g.inEdges(of: v).map { offsets[$0]! })")
            }
            return out
        }
        func rows<G: Graph>(_ g: G) -> [String] where G.Vertex == Int {
            var offsets: [G.Edges.Index: Int] = [:]
            for (k, p) in g.edges.indices.enumerated() { offsets[p] = k }
            var out = ["vertices \(Array(g.vertices))", "edges \(g.edges.map { "\($0.u)-\($0.v)" })"]
            for v in g.vertices { out.append("\(v): \(Array(g.neighbors(of: v))) \(g.incidentEdges(of: v).map { offsets[$0]! })") }
            return out
        }
        // After the build: removing an edge and a vertex works as on the inserted graph.
        func mutated<G: MutableDirectedGraph>(_ g: G) -> G where G.Vertex == Int {
            var g = g
            if let edge = directedEdges.last { _ = g.remove(edge: edge) }
            _ = g.remove(order.first ?? 0)
            return g
        }
        func mutated<G: MutableGraph>(_ g: G) -> G where G.Vertex == Int {
            var g = g
            if let edge = undirectedEdges.last { _ = g.remove(edge: UndirectedEdge(edge.v, edge.u)) }
            _ = g.remove(order.first ?? 0)
            return g
        }

        // The edge list and the adjacency list (one edge per line), into every representation.
        let adjacencyList = pairs.map { "\($0.0) \($0.1)" }.joined(separator: "\n")
        let a1 = try AdjacencyList<Int>(edgeList: edgeList.utf8, columns: ["w"])
        let a2 = AdjacencyList<Int>(vertices: order, edges: directedEdges)
        #expect(rows(a1) == rows(a2))
        #expect(rows(mutated(a1)) == rows(mutated(a2)))
        #expect(rows(try AdjacencyList<Int>(adjacencyList: adjacencyList.utf8)) == rows(a2))
        let d1 = try DirectedPseudograph<Int>(edgeList: edgeList.utf8, columns: ["w"])
        let d2 = DirectedPseudograph<Int>(vertices: order, edges: directedEdges)
        #expect(rows(d1) == rows(d2))
        #expect(rows(mutated(d1)) == rows(mutated(d2)))
        let s1 = try StableDirectedGraph<Int>(edgeList: edgeList.utf8, columns: ["w"])
        let s2 = StableDirectedGraph<Int>(vertices: order, edges: directedEdges)
        #expect(rows(s1) == rows(s2))
        #expect(rows(mutated(s1)) == rows(mutated(s2)))
        let u1 = try UndirectedAdjacencyList<Int>(edgeList: edgeList.utf8, columns: ["w"])
        let u2 = UndirectedAdjacencyList<Int>(vertices: order, edges: undirectedEdges)
        #expect(rows(u1) == rows(u2))
        #expect(rows(mutated(u1)) == rows(mutated(u2)))
        #expect(rows(try UndirectedAdjacencyList<Int>(adjacencyList: adjacencyList.utf8)) == rows(u2))
        let p1 = try Pseudograph<Int>(edgeList: edgeList.utf8, columns: ["w"])
        let p2 = Pseudograph<Int>(vertices: order, edges: undirectedEdges)
        #expect(rows(p1) == rows(p2))
        #expect(rows(mutated(p1)) == rows(mutated(p2)))

        // Matrix Market: the vertices 0..<n in order, then the entries.
        #expect(rows(try AdjacencyList<Int>(matrixMarket: matrixMarket.utf8)) == rows(AdjacencyList<Int>(vertices: 0 ..< n, edges: directedEdges)))
        #expect(rows(try DirectedPseudograph<Int>(matrixMarket: matrixMarket.utf8))
            == rows(DirectedPseudograph<Int>(vertices: 0 ..< n, edges: directedEdges)))
        #expect(rows(try Pseudograph<Int>(matrixMarket: symmetric.utf8)) == rows(Pseudograph<Int>(vertices: 0 ..< n, edges: undirectedEdges)))
        #expect(try UndirectedAdjacencyList<String>(matrixMarket: symmetric.utf8, vertex: { "v\($0)" }).vertices.map { $0 }
            == (0 ..< n).map { "v\($0)" })

        // Attributes: every edge's value reaches its position; a simple target's repeated pair
        // reports again on its first position, so the last value wins there.
        var simpleValues: [Int: Int] = [:], multiValues: [Int: Int] = [:]
        let simple = try AdjacencyList<Int>(edgeList: edgeList.utf8, columns: ["w"], edgeAttribute: { p, _, value in
            if case .integer(let w) = value { simpleValues[p] = w }
        })
        let multi = try DirectedPseudograph<Int>(edgeList: edgeList.utf8, columns: ["w"], edgeAttribute: { p, _, value in
            if case .integer(let w) = value { multiValues[p] = w }
        })
        #expect(multiValues == Dictionary(uniqueKeysWithValues: pairs.enumerated().map { ($0, $1.0 * 100 + $1.1) }))
        for p in simple.edges.indices {
            let edge = simple.edges[p]
            #expect(simpleValues[p] == edge.source * 100 + edge.target)
        }
        #expect(multi.edgeCount == m && simpleValues.count == simple.edgeCount)
    }

    @Test("Two IDs that map to one vertex are that vertex, in the bulk build too")
    func aliasesThroughTheClosure() throws {
        let graph = try DirectedPseudograph<String>(edgeList: "a A\nB b\nA c\n".utf8, vertex: { $0.lowercased() })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.edges.map { $0 } == [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "b", to: "b"), DirectedEdge(from: "a", to: "c")])
        let matrix = try Pseudograph<String>(matrixMarket: "%%MatrixMarket matrix coordinate pattern symmetric\n4 4 2\n2 1\n4 3\n".utf8,
                                             vertex: { $0 < 2 ? "low" : "high" })
        #expect(Array(matrix.vertices) == ["low", "high"])
        #expect(matrix.edges.map { [$0.u, $0.v] } == [["low", "low"], ["high", "high"]])
    }
}
