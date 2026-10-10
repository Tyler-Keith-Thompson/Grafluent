// The protocol laws (`Graph` for `Pseudograph` and `Multigraph`, `BidirectionalDirectedGraph` for
// `DirectedPseudograph` and `DirectedMultigraph`) on graphs with copies and loops, fresh and after
// removals; the parallel classes (`edges(between:and:)` lists exactly the copies of the pair);
// the stored index rows read back through `_withIncidentIndexRows`; generic code; the drop-in
// check against `ReferencePseudograph` / `ReferenceDirectedMultigraph` built the same way (equal
// vertices, positions and rows); and the named fixtures' degree counts with every written edge
// kept. Every expectation is computed inside the test from the graph's own `edges` or from the
// fixture. See README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import Testing

@Suite("Multigraphs laws")
struct MultigraphLawTests {
    @Test("Pseudograph satisfies Graph's laws, fresh and after removals")
    func pseudographLaws() {
        var graphs: [(String, Pseudograph<Int>)] = []
        graphs.append(("empty", Pseudograph<Int>()))
        graphs.append(("isolated", Pseudograph<Int>(vertices: [4, 2, 0])))
        graphs.append(("copies and loops", Pseudograph<Int>(vertices: [9], edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 1),
            UndirectedEdge(1, 1), UndirectedEdge(2, 2), UndirectedEdge(3, 0), UndirectedEdge(0, 3),
        ])))
        var removed = graphs[2].1
        removed.remove(edgeAt: 0)
        removed.remove(edge: UndirectedEdge(1, 1))
        removed.remove(0)
        graphs.append(("after removals", removed))
        var mixed = Pseudograph<Int>(edges: (0 ..< 40).map { UndirectedEdge($0 % 5, ($0 * 3) % 7) })
        for p in [3, 0, 17, 5] { mixed.remove(edgeAt: p) }
        mixed.remove(4)
        mixed.removeAllEdges(between: 1, and: 3)
        mixed.insert(edge: UndirectedEdge(6, 6))
        graphs.append(("mixed", mixed))

        for (name, graph) in graphs {
            let vertices = Array(graph.vertices)
            let edges = Array(graph.edges)
            #expect(graph.vertexCount == vertices.count, "\(name)")
            #expect(Set(vertices).count == vertices.count, "\(name)")
            #expect(graph.edgeCount == edges.count, "\(name)")
            #expect(graph.vertexIndexBound == vertices.count, "\(name)")
            #expect(graph.edgeIndexBound == edges.count, "\(name)")
            for edge in edges { #expect(graph.contains(edge.u) && graph.contains(edge.v), "\(name)") }
            var ends = [Int](repeating: 0, count: edges.count)
            var degreeSum = 0
            for (i, v) in vertices.enumerated() {
                #expect(graph.vertexIndex(of: v) == i, "\(name)")
                #expect(graph.vertex(atIndex: i) == v, "\(name)")
                let incident = Array(graph.incidentEdges(of: v))
                let neighbors = Array(graph.neighbors(of: v))
                #expect(neighbors == incident.map { edges[$0].oppositeVertex(to: v) }, "\(name) \(v)")
                #expect(neighbors == incident.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }, "\(name) \(v)")
                #expect(graph.degree(of: v) == incident.count, "\(name) \(v)")
                // Each edge with an end at v, once per end: a loop twice.
                let expected = edges.indices.flatMap { p -> [Int] in
                    let e = edges[p]
                    return e.isSelfLoop && e.u == v ? [p, p] : (e.u == v || e.v == v ? [p] : [])
                }
                #expect(incident.sorted() == expected, "\(name) \(v)")
                #expect(Array(graph.incidentEdges(ofIndex: i)) == incident, "\(name) \(v)")
                #expect(Array(graph.incidentEdgeIndices(ofIndex: i)) == incident.map { graph.edgeIndex(of: $0) }, "\(name) \(v)")
                #expect(Array(graph.neighborIndices(ofIndex: i)) == neighbors.map { graph.vertexIndex(of: $0) }, "\(name) \(v)")
                for p in incident { ends[p] += 1 }
                degreeSum += graph.degree(of: v)
            }
            #expect(ends.allSatisfy { $0 == 2 }, "\(name)")
            #expect(degreeSum == 2 * graph.edgeCount, "\(name)")
            for p in edges.indices { #expect(graph.edgeIndex(of: p) == p, "\(name)") }
            // The parallel classes: every copy of a pair, nothing else, and the counts.
            let universe = vertices + [100]
            var classSizes = 0
            for (k, a) in universe.enumerated() {
                for b in universe[k...] {
                    let copies = Array(graph.edges(between: a, and: b))
                    let expected = edges.indices.filter { edges[$0] == UndirectedEdge(a, b) }
                    #expect(copies.sorted() == expected, "\(name) \(a)–\(b)")
                    #expect(Array(graph.edges(between: b, and: a)) == copies, "\(name) \(a)–\(b)")
                    #expect(graph.edges(between: a, and: b).count == expected.count, "\(name)")
                    #expect(graph.edges(between: a, and: b).isEmpty == expected.isEmpty, "\(name)")
                    #expect(graph.edgeCount(between: a, and: b) == expected.count, "\(name) \(a)–\(b)")
                    #expect(graph.edgeCount(between: b, and: a) == expected.count, "\(name)")
                    #expect(graph.contains(edge: UndirectedEdge(a, b)) == !expected.isEmpty, "\(name) \(a)–\(b)")
                    #expect(graph.contains(edge: UndirectedEdge(b, a)) == !expected.isEmpty, "\(name)")
                    classSizes += expected.count
                }
            }
            #expect(classSizes == edges.count, "\(name)")
            #expect(!graph.contains(100))
            // The stored rows, read back.
            let rows: [[Int]]? = graph._withIncidentIndexRows { neighbors, neighborRows, edgeStorage, edgeRows in
                var out: [[Int]] = []
                for i in 0 ..< vertices.count {
                    out.append(Array(neighbors[neighborRows[3 * i] ..< neighborRows[3 * i] + neighborRows[3 * i + 1]]))
                    out.append(Array(edgeStorage[edgeRows[3 * i] ..< edgeRows[3 * i] + edgeRows[3 * i + 1]]))
                }
                return out
            }
            #expect(rows != nil, "\(name)")
            if let rows {
                for i in vertices.indices {
                    #expect(rows[2 * i] == Array(graph.neighborIndices(ofIndex: i)), "\(name)")
                    #expect(rows[2 * i + 1] == Array(graph.incidentEdgeIndices(ofIndex: i)), "\(name)")
                }
            }
        }
    }

    @Test("Multigraph satisfies Graph's laws and forwards every requirement to its storage")
    func multigraphLaws() throws {
        var graph = try #require(Multigraph<Int>(vertices: [7], edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 3),
            UndirectedEdge(3, 2), UndirectedEdge(3, 0),
        ]))
        for step in 0 ..< 4 {
            let storage = Pseudograph(graph)
            let vertices = Array(graph.vertices)
            let edges = Array(graph.edges)
            #expect(vertices == Array(storage.vertices))
            #expect(edges.map { [$0.u, $0.v] } == storage.edges.map { [$0.u, $0.v] })
            #expect(graph.vertexCount == vertices.count && graph.edgeCount == edges.count)
            #expect(graph.vertexIndexBound == vertices.count && graph.edgeIndexBound == edges.count)
            #expect(edges.allSatisfy { !$0.isSelfLoop })
            var degreeSum = 0
            for (i, v) in vertices.enumerated() {
                #expect(graph.vertexIndex(of: v) == i && graph.vertex(atIndex: i) == v)
                let incident = Array(graph.incidentEdges(of: v))
                #expect(incident == Array(storage.incidentEdges(of: v)), "step \(step)")
                #expect(Array(graph.neighbors(of: v)) == incident.map { edges[$0].oppositeVertex(to: v) })
                #expect(Array(graph.neighbors(of: v)) == incident.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) })
                #expect(graph.degree(of: v) == incident.count)
                #expect(Array(graph.incidentEdges(ofIndex: i)) == incident)
                #expect(Array(graph.incidentEdgeIndices(ofIndex: i)) == incident)
                #expect(Array(graph.neighborIndices(ofIndex: i)) == Array(storage.neighborIndices(ofIndex: i)))
                degreeSum += incident.count
                for w in vertices {
                    #expect(Array(graph.edges(between: v, and: w)) == Array(storage.edges(between: v, and: w)))
                    #expect(graph.edgeCount(between: v, and: w) == edges.filter { $0 == UndirectedEdge(v, w) }.count)
                    #expect(graph.contains(edge: UndirectedEdge(v, w)) == edges.contains(UndirectedEdge(v, w)))
                }
            }
            #expect(degreeSum == 2 * edges.count)
            let forwarded: [Int]? = graph._withIncidentIndexRows { _, _, edgeStorage, edgeRows in
                (0 ..< vertices.count).flatMap { i in Array(edgeStorage[edgeRows[3 * i] ..< edgeRows[3 * i] + edgeRows[3 * i + 1]]) }
            }
            #expect(forwarded == vertices.indices.flatMap { Array(graph.incidentEdgeIndices(ofIndex: $0)) }, "step \(step)")
            switch step {
            case 0: graph.remove(edgeAt: 1)
            case 1: graph.remove(edge: UndirectedEdge(1, 0))
            default: graph.remove(graph.vertex(atIndex: 0))
            }
        }
    }

    @Test("DirectedPseudograph and DirectedMultigraph satisfy BidirectionalDirectedGraph's laws, fresh and after removals")
    func directedLaws() throws {
        var pseudographs: [(String, DirectedPseudograph<Int>)] = []
        pseudographs.append(("empty", DirectedPseudograph<Int>()))
        pseudographs.append(("isolated", DirectedPseudograph<Int>(vertices: [3, 1])))
        let built = DirectedPseudograph<Int>(vertices: [8], edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1),
            DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 0), DirectedEdge(from: 2, to: 0),
        ])
        pseudographs.append(("copies and loops", built))
        var removed = built
        removed.remove(edgeAt: 0)
        removed.remove(edge: DirectedEdge(from: 1, to: 1))
        removed.remove(0)
        pseudographs.append(("after removals", removed))
        var mixed = DirectedPseudograph<Int>(edges: (0 ..< 40).map { DirectedEdge(from: $0 % 6, to: ($0 * 5) % 7) })
        for p in [2, 0, 30, 9] { mixed.remove(edgeAt: p) }
        mixed.remove(5)
        mixed.removeAllEdges(from: 1, to: 5)
        pseudographs.append(("mixed", mixed))
        var multigraph = try #require(DirectedMultigraph<Int>(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0),
        ]))
        let freshMultigraph = multigraph
        multigraph.remove(edgeAt: 0)
        multigraph.remove(1)

        // The laws, written once for both types through the protocol.
        func check<G: BidirectionalDirectedGraph>(_ graph: G, _ name: String, copies: (Int, Int) -> [Int], count: (Int, Int) -> Int)
            where G.Vertex == Int, G.Edges.Index == Int
        {
            let vertices = Array(graph.vertices)
            let edges = Array(graph.edges)
            #expect(graph.vertexCount == vertices.count && Set(vertices).count == vertices.count, "\(name)")
            #expect(graph.edgeCount == edges.count, "\(name)")
            #expect(graph.vertexIndexBound == vertices.count && graph.edgeIndexBound == edges.count, "\(name)")
            var outSum = 0, inSum = 0
            for (i, v) in vertices.enumerated() {
                #expect(graph.vertexIndex(of: v) == i && graph.vertex(atIndex: i) == v, "\(name)")
                let out = Array(graph.outEdges(of: v))
                let into = Array(graph.inEdges(of: v))
                #expect(out.sorted() == edges.indices.filter { edges[$0].source == v }, "\(name) \(v)")
                #expect(into.sorted() == edges.indices.filter { edges[$0].target == v }, "\(name) \(v)")
                #expect(Array(graph.successors(of: v)) == out.map { edges[$0].target }, "\(name) \(v)")
                #expect(Array(graph.predecessors(of: v)) == into.map { edges[$0].source }, "\(name) \(v)")
                #expect(out.allSatisfy { graph.source(ofEdgeAt: $0) == v }, "\(name)")
                #expect(into.allSatisfy { graph.target(ofEdgeAt: $0) == v }, "\(name)")
                #expect(graph.outDegree(of: v) == out.count && graph.inDegree(of: v) == into.count, "\(name)")
                #expect(graph.degree(of: v) == out.count + into.count, "\(name)")
                #expect(Array(graph.outEdges(ofIndex: i)) == out && Array(graph.inEdges(ofIndex: i)) == into, "\(name)")
                #expect(Array(graph.successorIndices(ofIndex: i)) == graph.successors(of: v).map { graph.vertexIndex(of: $0) }, "\(name)")
                #expect(Array(graph.predecessorIndices(ofIndex: i)) == graph.predecessors(of: v).map { graph.vertexIndex(of: $0) }, "\(name)")
                outSum += out.count
                inSum += into.count
                for w in vertices + [100] {
                    let expected = edges.indices.filter { edges[$0] == DirectedEdge(from: v, to: w) }
                    #expect(copies(v, w).sorted() == expected, "\(name) \(v)→\(w)")
                    #expect(count(v, w) == expected.count, "\(name) \(v)→\(w)")
                    #expect(graph.contains(edge: DirectedEdge(from: v, to: w)) == !expected.isEmpty, "\(name) \(v)→\(w)")
                    #expect(copies(w, v).sorted() == edges.indices.filter { edges[$0] == DirectedEdge(from: w, to: v) }, "\(name)")
                }
            }
            #expect(outSum == edges.count && inSum == edges.count, "\(name)")
            for p in edges.indices {
                #expect(graph.edgeIndex(of: p) == p, "\(name)")
                #expect(graph.source(ofEdgeAt: p) == edges[p].source && graph.target(ofEdgeAt: p) == edges[p].target, "\(name)")
            }
            #expect(!graph.contains(100))
        }
        for (name, graph) in pseudographs {
            check(graph, name, copies: { Array(graph.edges(from: $0, to: $1)) }, count: { graph.edgeCount(from: $0, to: $1) })
        }
        for (name, graph) in [("multigraph", freshMultigraph), ("multigraph after removals", multigraph)] {
            check(graph, name, copies: { Array(graph.edges(from: $0, to: $1)) }, count: { graph.edgeCount(from: $0, to: $1) })
            #expect(graph.edges.allSatisfy { !$0.isSelfLoop })
        }
    }

    @Test("A freshly built Pseudograph is ReferencePseudograph built the same way: vertices, positions, rows")
    func dropInForReferencePseudograph() {
        var shapes: [([Int], [UndirectedEdge<Int>])] = [
            ([], []),
            ([3, 1], []),
            ([], [UndirectedEdge(0, 0)]),
            ([5], [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1), UndirectedEdge(2, 1), UndirectedEdge(1, 1), UndirectedEdge(0, 2)]),
        ]
        for fixture in UndirectedFixture<Int>.all { shapes.append((fixture.vertices, fixture.edges)) }
        for (vertices, edges) in shapes {
            let graph = Pseudograph<Int>(vertices: vertices, edges: edges)
            let reference = ReferencePseudograph(vertices: vertices, edges: edges)
            #expect(Array(graph.vertices) == reference.vertices)
            #expect(graph.edges.map { [$0.u, $0.v] } == reference.edges.map { [$0.u, $0.v] })
            for v in reference.vertices {
                #expect(Array(graph.incidentEdges(of: v)) == reference.incidentEdges(of: v), "\(v) of \(edges)")
                #expect(Array(graph.neighbors(of: v)) == reference.neighbors(of: v), "\(v) of \(edges)")
                #expect(graph.degree(of: v) == reference.degree(of: v))
                #expect(Array(graph.neighborIndices(ofIndex: graph.vertexIndex(of: v))) == Array(reference.neighborIndices(ofIndex: reference.vertexIndex(of: v))))
            }
            if let multigraph = Multigraph<Int>(vertices: vertices, edges: edges) {
                #expect(!edges.contains { $0.isSelfLoop })
                for v in reference.vertices { #expect(Array(multigraph.incidentEdges(of: v)) == reference.incidentEdges(of: v)) }
            } else {
                #expect(edges.contains { $0.isSelfLoop })
            }
        }
    }

    @Test("A freshly built DirectedPseudograph is ReferenceDirectedMultigraph built the same way")
    func dropInForReferenceDirectedMultigraph() {
        var shapes: [([Int], [DirectedEdge<Int>])] = [
            ([], []),
            ([2], [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)]),
            ([], [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 1)]),
        ]
        for fixture in DirectedFixture<Int>.all { shapes.append((fixture.vertices, fixture.edges)) }
        for (vertices, edges) in shapes {
            let graph = DirectedPseudograph<Int>(vertices: vertices, edges: edges)
            let reference = ReferenceDirectedMultigraph(vertices: vertices, edges: edges)
            #expect(Array(graph.vertices) == reference.vertices)
            #expect(graph.edges.map { [$0.source, $0.target] } == reference.edges.map { [$0.source, $0.target] })
            for v in reference.vertices {
                #expect(Array(graph.outEdges(of: v)) == reference.outEdges(of: v), "\(v) of \(edges)")
                #expect(Array(graph.inEdges(of: v)) == reference.inEdges(of: v), "\(v) of \(edges)")
                #expect(Array(graph.successors(of: v)) == reference.successors(of: v))
                #expect(Array(graph.predecessors(of: v)) == reference.predecessors(of: v))
                #expect(graph.degree(of: v) == reference.degree(of: v))
            }
        }
    }

    @Test("The named fixtures keep every written edge: pseudograph counts and degrees", arguments: UndirectedFixture<Int>.all)
    func undirectedFixtures(_ fixture: UndirectedFixture<Int>) {
        let graph = Pseudograph<Int>(vertices: fixture.vertices, edges: fixture.edges)
        #expect(graph.vertexCount == fixture.vertexCount)
        #expect(graph.edgeCount == fixture.pseudographEdgeCount)
        for (v, d) in fixture.pseudographDegree { #expect(graph.degree(of: v) == d, "\(v)") }
        // Collapsing the copies gives the simple values.
        let simple = UndirectedAdjacencyList(graph)
        #expect(simple.edgeCount == fixture.edgeCount)
        for (v, d) in fixture.degree { #expect(simple.degree(of: v) == d, "\(v)") }
    }

    @Test("The named directed fixtures with distinct arcs: counts and degrees", arguments: DirectedFixture<Int>.all.filter { Set($0.edges).count == $0.edges.count })
    func directedFixtures(_ fixture: DirectedFixture<Int>) {
        let graph = DirectedPseudograph<Int>(vertices: fixture.vertices, edges: fixture.edges)
        #expect(graph.vertexCount == fixture.vertexCount)
        #expect(graph.edgeCount == fixture.edgeCount)
        for (v, d) in fixture.outDegree { #expect(graph.outDegree(of: v) == d, "\(v)") }
        for (v, d) in fixture.inDegree { #expect(graph.inDegree(of: v) == d, "\(v)") }
    }

    @Test("Generic code sees the copies: counts, rows and contains(edge:) through Graph and DirectedGraph")
    func genericCode() throws {
        func summary<G: Graph>(_ graph: G) -> (edges: Int, degrees: [Int], loops: Int) where G.Vertex == Int {
            (graph.edgeCount, graph.vertices.map { graph.degree(of: $0) }, graph.edges.filter { $0.isSelfLoop }.count)
        }
        func arcs<G: BidirectionalDirectedGraph>(_ graph: G) -> (edges: Int, out: [Int], into: [Int]) where G.Vertex == Int {
            (graph.edgeCount, graph.vertices.map { graph.outDegree(of: $0) }, graph.vertices.map { graph.inDegree(of: $0) })
        }
        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let p = summary(pseudograph)
        #expect(p.edges == 3 && p.degrees == [2, 4] && p.loops == 1)
        let multigraph = try #require(Multigraph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2)]))
        let m = summary(multigraph)
        #expect(m.edges == 3 && m.degrees == [2, 3, 1] && m.loops == 0)
        let digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        let d = arcs(digraph)
        #expect(d.edges == 3 && d.out == [2, 1] && d.into == [0, 3])
        let directedMultigraph = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0)]))
        let dm = arcs(directedMultigraph)
        #expect(dm.edges == 2 && dm.out == [2, 0] && dm.into == [0, 2])
        // The views: each undirected edge two arcs; each arc an undirected edge.
        #expect(arcs(pseudograph.directed).edges == 6)
        #expect(summary(digraph.undirected).degrees == [2, 4])
        // contains(edge:) through the protocol answers as the type does.
        func has<G: Graph>(_ graph: G, _ edge: UndirectedEdge<Int>) -> Bool where G.Vertex == Int { graph.contains(edge: edge) }
        #expect(has(pseudograph, UndirectedEdge(1, 0)) && has(pseudograph, UndirectedEdge(1, 1)) && !has(pseudograph, UndirectedEdge(0, 0)))
        #expect(!has(pseudograph, UndirectedEdge(0, 7)) && !has(multigraph, UndirectedEdge(0, 2)))
    }
}
