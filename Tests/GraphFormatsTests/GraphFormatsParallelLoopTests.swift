// Parallel self-loops and parallel edges survive every construction path into the multigraphs:
// 29 copies of a loop stay 29 edges (each counted twice in its vertex's degree), mixed with
// parallel non-loop edges in both orientations, through every reader (the line formats build in
// one step through `MutableGraph._built` / `MutableDirectedGraph._built`, the others insert one
// edge at a time) and through the public initializers. See README.md.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats parallel loops")
struct GraphFormatsParallelLoopTests {
    @Test("29 parallel loops and parallel edges in both orientations stay, in every reader and initializer")
    func parallelLoops() throws {
        // The pairs: 29 loops at 0, then 0–1 three times written both ways, 2 loops at 1, 1–2 twice.
        var pairs: [(Int, Int)] = Array(repeating: (0, 0), count: 29)
        pairs += [(0, 1), (1, 0), (0, 1), (1, 1), (1, 1), (1, 2), (2, 1)]
        let m = pairs.count
        let undirected = pairs.map { UndirectedEdge($0.0, $0.1) }
        let directed = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }

        func check(_ g: Pseudograph<Int>, _ how: String) {
            #expect(g.edgeCount == m, "\(how): \(g.edgeCount) edges")
            #expect(g.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] }, "\(how)")
            #expect(g.degree(of: 0) == 29 * 2 + 3, "\(how): degree of 0 is \(g.degree(of: 0))")
            #expect(g.degree(of: 1) == 3 + 2 * 2 + 2, "\(how): degree of 1 is \(g.degree(of: 1))")
            #expect(g.edges(between: 0, and: 0).count == 29, "\(how)")
            #expect(g.edges(between: 1, and: 0).count == 3, "\(how)")
            var copy = g
            #expect(copy.remove(edge: UndirectedEdge(0, 0)) != nil && copy.edgeCount == m - 1, "\(how)")
        }
        func check(_ g: DirectedPseudograph<Int>, _ how: String) {
            #expect(g.edgeCount == m, "\(how): \(g.edgeCount) edges")
            #expect(g.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] }, "\(how)")
            #expect(g.outDegree(of: 0) == 29 + 2 && g.inDegree(of: 0) == 29 + 1, "\(how)")
            #expect(g.edges(from: 0, to: 0).count == 29, "\(how)")
        }

        let edgeList = pairs.map { "\($0.0) \($0.1)" }.joined(separator: "\n")
        let adjacencyList = pairs.map { "\($0.0) \($0.1)" }.joined(separator: "\n")
        let symmetric = "%%MatrixMarket matrix coordinate pattern symmetric\n3 3 \(m)\n" + pairs.map { "\($0.0 + 1) \($0.1 + 1)\n" }.joined()
        let general = "%%MatrixMarket matrix coordinate pattern general\n3 3 \(m)\n" + pairs.map { "\($0.0 + 1) \($0.1 + 1)\n" }.joined()
        let dot = "graph { 0; 1; 2; " + pairs.map { "\($0.0) -- \($0.1)" }.joined(separator: "; ") + " }"
        let digraph = "digraph { 0; 1; 2; " + pairs.map { "\($0.0) -> \($0.1)" }.joined(separator: "; ") + " }"
        let nodeLink = "{\"nodes\": [{\"id\": 0}, {\"id\": 1}, {\"id\": 2}], \"edges\": ["
            + pairs.map { "{\"source\": \($0.0), \"target\": \($0.1)}" }.joined(separator: ", ") + "]}"

        check(Pseudograph<Int>(vertices: 0 ..< 3, edges: undirected), "init(vertices:edges:)")
        var oneAtATime = Pseudograph<Int>(vertices: 0 ..< 3)
        for e in undirected { oneAtATime.insert(edge: e) }
        check(oneAtATime, "insert(edge:)")
        check(try Pseudograph<Int>(edgeList: edgeList.utf8), "edge list")
        check(try Pseudograph<Int>(adjacencyList: adjacencyList.utf8), "adjacency list")
        check(try Pseudograph<Int>(matrixMarket: symmetric.utf8), "Matrix Market")
        check(try Pseudograph<Int>(dot: dot.utf8, vertex: { Int($0) }), "DOT")
        check(try Pseudograph<Int>(nodeLinkJSON: nodeLink.utf8), "node-link JSON")
        check(DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: directed), "directed init(vertices:edges:)")
        check(try DirectedPseudograph<Int>(edgeList: edgeList.utf8), "directed edge list")
        check(try DirectedPseudograph<Int>(matrixMarket: general.utf8), "directed Matrix Market")
        check(try DirectedPseudograph<Int>(dot: digraph.utf8, vertex: { Int($0) }), "directed DOT")
    }

    @Test("Loops on a later vertex, String vertices, and the bulk hook called directly keep every copy")
    func laterVertexLoops() throws {
        let text = "a b\nc c\n" + String(repeating: "c c\n", count: 28) + "b c\nc b\nc c\n"
        let g = try Pseudograph<String>(edgeList: text.utf8)
        #expect(g.edgeCount == 33)
        #expect(g.edges(between: "c", and: "c").count == 30)
        #expect(g.degree(of: "c") == 30 * 2 + 2)
        let d = try DirectedPseudograph<String>(edgeList: text.utf8)
        #expect(d.edges(from: "c", to: "c").count == 30)
        let built = Pseudograph<Int>._built(vertices: [7, 3], uKeys: Array(repeating: 1, count: 29) + [0, 1],
                                            vKeys: Array(repeating: 1, count: 29) + [1, 0], reportingPositions: true, _ConstructionToken())
        #expect(built.graph.edgeCount == 31 && built.positions == Array(0 ..< 31))
        #expect(built.graph.edges(between: 3, and: 3).count == 29 && built.graph.degree(of: 3) == 60)
        // Through the generic MutableGraph initializer, as a caller generic over the target reads.
        func read<G: MutableGraph>(_: G.Type, _ text: String) throws(ParseError) -> G where G.Vertex == Int { try G(edgeList: text.utf8) }
        let generic = try read(Pseudograph<Int>.self, "1 1\n1 1\n1 1\n")
        #expect(generic.edgeCount == 3)
    }
}
