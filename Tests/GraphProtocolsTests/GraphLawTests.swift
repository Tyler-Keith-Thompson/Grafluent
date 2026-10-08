// The Graph laws on every conformer: UndirectedAdjacencyList with Int and String vertices (simple,
// with self-loops), and the pseudograph test conformer (ReferencePseudograph.swift), where
// parallel edges count once per copy and a self-loop twice; and seeded random graphs observed
// identically through both. Case IDs (UG-Lnn, UG-Pnn) refer to the catalog in README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Graph laws on every conformer")
struct GraphLawTests {
    @Test("UG-L01 – L12, L15 – L23 the laws on an undirected adjacency list", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func adjacencyListLaws(_ fixture: UndirectedFixture<Int>) {
        func check<G: Graph>(_ g: G, absent: G.Vertex) {
            let vertices = Array(g.vertices)
            let edges = Array(g.edges)
            let vertexSet = Set(vertices)
            // L01, L02: counts, and vertices are distinct.
            #expect(g.vertexCount == vertices.count)
            #expect(vertexSet.count == g.vertexCount)
            #expect(g.edgeCount == edges.count)
            // L03: every vertex is contained, and every endpoint is a vertex.
            for v in vertices { #expect(g.contains(v)) }
            for e in edges {
                #expect(vertexSet.contains(e.u))
                #expect(vertexSet.contains(e.v))
            }
            var degreeSum = 0
            var positionCounts: [G.Edges.Index: Int] = [:]
            for v in vertices {
                let neighbors = Array(g.neighbors(of: v))
                let incident = Array(g.incidentEdges(of: v))
                // L04: the neighbors are the far ends of the edge ends at v; a loop gives v twice.
                var fromNeighbors: [G.Vertex: Int] = [:]
                for w in neighbors { fromNeighbors[w, default: 0] += 1 }
                var fromEdges: [G.Vertex: Int] = [:]
                for e in edges {
                    if e.u == v && e.v == v {
                        fromEdges[v, default: 0] += 2
                    } else if e.u == v {
                        fromEdges[e.v, default: 0] += 1
                    } else if e.v == v {
                        fromEdges[e.u, default: 0] += 1
                    }
                }
                #expect(fromNeighbors == fromEdges)
                // L05: the degree is the length of either list.
                #expect(g.degree(of: v) == neighbors.count)
                #expect(g.degree(of: v) == incident.count)
                // L11: a self-loop puts v twice among its neighbors and its position twice among its incident edges.
                let loopCount = edges.filter { $0.u == v && $0.v == v }.count
                #expect(neighbors.filter { $0 == v }.count == 2 * loopCount)
                for e in incident where g.edges[e].isSelfLoop {
                    #expect(incident.filter { $0 == e }.count == 2)
                }
                // L12: a simple graph repeats only v, and only through its self-loop.
                for (w, count) in fromNeighbors {
                    #expect(count == (w == v ? 2 : 1))
                }
                // L15: asking again gives the same sequences.
                #expect(Array(g.neighbors(of: v)) == neighbors)
                #expect(Array(g.incidentEdges(of: v)) == incident)
                // L16: every incident edge has v as an endpoint, and the opposite vertices are the neighbors, in order.
                for e in incident {
                    #expect(g.edges[e].u == v || g.edges[e].v == v)
                    #expect(g.oppositeVertex(to: v, acrossEdgeAt: e) == g.edges[e].oppositeVertex(to: v))
                    // L18: across and back.
                    #expect(g.oppositeVertex(to: g.oppositeVertex(to: v, acrossEdgeAt: e), acrossEdgeAt: e) == v)
                    positionCounts[e, default: 0] += 1
                }
                #expect(incident.map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == neighbors)
                degreeSum += g.degree(of: v)
            }
            // L06: handshake.
            #expect(degreeSum == 2 * g.edgeCount)
            // L17: every position is listed exactly twice over all vertices, and nothing else is.
            #expect(Set(positionCounts.keys) == Set(g.edges.indices))
            #expect(positionCounts.values.allSatisfy { $0 == 2 })
            // L07: contains(edge:) agrees with edges and with neighbors, in both orientations.
            let edgeSet = Set(edges)
            for u in vertices {
                let neighbors = Array(g.neighbors(of: u))
                for v in vertices {
                    #expect(g.contains(edge: UndirectedEdge(u, v)) == g.contains(edge: UndirectedEdge(v, u)))
                    #expect(g.contains(edge: UndirectedEdge(u, v)) == edgeSet.contains(UndirectedEdge(u, v)))
                    #expect(g.contains(edge: UndirectedEdge(u, v)) == neighbors.contains(v))
                }
            }
            // L08, L09: absent vertices are not contained, and asking does not trap.
            #expect(!g.contains(absent))
            #expect(!g.contains(edge: UndirectedEdge(absent, absent)))
            for v in vertices {
                #expect(!g.contains(edge: UndirectedEdge(v, absent)))
                #expect(!g.contains(edge: UndirectedEdge(absent, v)))
            }
            // L10: symmetry.
            for u in vertices {
                let fromU = Array(g.neighbors(of: u))
                for v in vertices where v != u {
                    #expect(fromU.filter { $0 == v }.count == Array(g.neighbors(of: v)).filter { $0 == u }.count)
                }
            }
            // L12: no repeated edges.
            #expect(edgeSet.count == g.edgeCount)
            // L19, L20, L21: vertex indices.
            #expect(g.vertexIndexBound == g.vertexCount)
            if let n = g.vertexIndexBound {
                var indices = Set<Int>()
                for v in vertices {
                    let i = g.vertexIndex(of: v)
                    #expect((0 ..< n).contains(i))
                    #expect(g.vertex(atIndex: i) == v)
                    indices.insert(i)
                    #expect(Array(g.neighborIndices(ofIndex: i)) == g.neighbors(of: v).map { g.vertexIndex(of: $0) })
                }
                #expect(indices == Set(0 ..< n))
                #expect(g.vertices.map { g.vertexIndex(of: $0) } == Array(0 ..< n))
            }
            // L22: vertices and edges are the same when asked again.
            #expect(Array(g.vertices) == vertices)
            #expect(Array(g.edges) == edges)
            // L23: the stored orientation is stable, not merely equal as an unordered pair.
            for e in g.edges.indices {
                #expect(g.edges[e].u == g.edges[e].u)
                #expect(g.edges[e].v == g.edges[e].v)
            }
            #expect(zip(Array(g.edges), edges).allSatisfy { $0.u == $1.u && $0.v == $1.v })
        }
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges), absent: -1)
    }

    @Test("UG-L01 – L12, L15 – L22 the laws with String vertices", .tags(.fixture), arguments: UndirectedFixture<String>.all)
    func adjacencyListLawsWithStrings(_ fixture: UndirectedFixture<String>) {
        func check<G: Graph>(_ g: G, absent: G.Vertex) {
            let vertices = Array(g.vertices)
            let edges = Array(g.edges)
            #expect(g.vertexCount == vertices.count)
            #expect(Set(vertices).count == g.vertexCount)
            #expect(g.edgeCount == edges.count)
            #expect(Set(edges).count == g.edgeCount)
            var degreeSum = 0
            var positionCounts: [G.Edges.Index: Int] = [:]
            for v in vertices {
                #expect(g.contains(v))
                let neighbors = Array(g.neighbors(of: v))
                let incident = Array(g.incidentEdges(of: v))
                var fromNeighbors: [G.Vertex: Int] = [:]
                for w in neighbors { fromNeighbors[w, default: 0] += 1 }
                var fromEdges: [G.Vertex: Int] = [:]
                for e in edges {
                    if e.u == v && e.v == v {
                        fromEdges[v, default: 0] += 2
                    } else if e.u == v {
                        fromEdges[e.v, default: 0] += 1
                    } else if e.v == v {
                        fromEdges[e.u, default: 0] += 1
                    }
                }
                #expect(fromNeighbors == fromEdges)
                #expect(g.degree(of: v) == neighbors.count)
                #expect(g.degree(of: v) == incident.count)
                #expect(incident.map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == neighbors)
                #expect(Array(g.neighbors(of: v)) == neighbors)
                for e in incident { positionCounts[e, default: 0] += 1 }
                for w in vertices {
                    #expect(g.contains(edge: UndirectedEdge(v, w)) == neighbors.contains(w))
                    #expect(g.contains(edge: UndirectedEdge(w, v)) == neighbors.contains(w))
                    if w != v {
                        #expect(neighbors.filter { $0 == w }.count == Array(g.neighbors(of: w)).filter { $0 == v }.count)
                    }
                }
                degreeSum += neighbors.count
                if let n = g.vertexIndexBound {
                    #expect((0 ..< n).contains(g.vertexIndex(of: v)))
                    #expect(g.vertex(atIndex: g.vertexIndex(of: v)) == v)
                    #expect(Array(g.neighborIndices(ofIndex: g.vertexIndex(of: v))) == neighbors.map { g.vertexIndex(of: $0) })
                }
            }
            #expect(degreeSum == 2 * g.edgeCount)
            #expect(Set(positionCounts.keys) == Set(g.edges.indices))
            #expect(positionCounts.values.allSatisfy { $0 == 2 })
            #expect(!g.contains(absent))
            #expect(!g.contains(edge: UndirectedEdge(absent, absent)))
            for v in vertices { #expect(!g.contains(edge: UndirectedEdge(v, absent))) }
            #expect(Array(g.vertices) == vertices)
            #expect(Array(g.edges) == edges)
        }
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges), absent: "∅")
    }

    @Test("UG-L01 – L11, L15 – L23 the laws on a pseudograph, with every written edge kept", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func pseudographLaws(_ fixture: UndirectedFixture<Int>) {
        func check<G: Graph>(_ g: G, absent: G.Vertex) {
            let vertices = Array(g.vertices)
            let edges = Array(g.edges)
            #expect(g.vertexCount == vertices.count)
            #expect(Set(vertices).count == g.vertexCount)
            // L02: each written edge once, each copy once, a loop once.
            #expect(g.edgeCount == edges.count)
            for e in edges {
                #expect(g.contains(e.u))
                #expect(g.contains(e.v))
            }
            var degreeSum = 0
            var positionCounts: [G.Edges.Index: Int] = [:]
            for v in vertices {
                let neighbors = Array(g.neighbors(of: v))
                let incident = Array(g.incidentEdges(of: v))
                // L04, exactly, for this conformer: in edge order, a loop's vertex twice in a row.
                var expected: [G.Vertex] = []
                for e in edges {
                    if e.u == v && e.v == v {
                        expected += [v, v]
                    } else if e.u == v {
                        expected.append(e.v)
                    } else if e.v == v {
                        expected.append(e.u)
                    }
                }
                #expect(neighbors == expected)
                #expect(g.degree(of: v) == neighbors.count)
                #expect(g.degree(of: v) == incident.count)
                // L11: once per end, so a loop copy twice.
                let loopCount = edges.filter { $0.u == v && $0.v == v }.count
                #expect(neighbors.filter { $0 == v }.count == 2 * loopCount)
                #expect(Array(g.neighbors(of: v)) == neighbors)
                #expect(Array(g.incidentEdges(of: v)) == incident)
                for e in incident {
                    #expect(g.edges[e].u == v || g.edges[e].v == v)
                    #expect(g.oppositeVertex(to: g.oppositeVertex(to: v, acrossEdgeAt: e), acrossEdgeAt: e) == v)
                    positionCounts[e, default: 0] += 1
                }
                #expect(incident.map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == neighbors)
                degreeSum += g.degree(of: v)
            }
            #expect(degreeSum == 2 * g.edgeCount)
            // L17: each copy of a parallel edge is its own position, listed at both its ends.
            #expect(Set(positionCounts.keys) == Set(g.edges.indices))
            #expect(positionCounts.values.allSatisfy { $0 == 2 })
            // L07: at least one copy.
            for u in vertices {
                for v in vertices {
                    let edge = UndirectedEdge(u, v)
                    #expect(g.contains(edge: edge) == g.contains(edge: UndirectedEdge(v, u)))
                    #expect(g.contains(edge: edge) == edges.contains(edge))
                    #expect(g.contains(edge: edge) == Array(g.neighbors(of: u)).contains(v))
                }
            }
            // L08, L09.
            #expect(!g.contains(absent))
            #expect(!g.contains(edge: UndirectedEdge(absent, absent)))
            for v in vertices { #expect(!g.contains(edge: UndirectedEdge(absent, v))) }
            // L10: a neighbor once per edge between them, from either side.
            for u in vertices {
                for v in vertices where v != u {
                    #expect(Array(g.neighbors(of: u)).filter { $0 == v }.count == Array(g.neighbors(of: v)).filter { $0 == u }.count)
                }
            }
            // L19 – L21.
            if let n = g.vertexIndexBound {
                #expect(n == g.vertexCount)
                #expect(g.vertices.map { g.vertexIndex(of: $0) } == Array(0 ..< n))
                for v in vertices {
                    #expect(g.vertex(atIndex: g.vertexIndex(of: v)) == v)
                    #expect(Array(g.neighborIndices(ofIndex: g.vertexIndex(of: v))) == g.neighbors(of: v).map { g.vertexIndex(of: $0) })
                }
            }
            // L22, L23.
            #expect(Array(g.vertices) == vertices)
            #expect(zip(Array(g.edges), edges).allSatisfy { $0.u == $1.u && $0.v == $1.v })
        }
        let g = ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)
        check(g, absent: -1)
        #expect(g.edgeCount == fixture.pseudographEdgeCount)
    }

    @Test("UG-L04, L05, L11 the laws on a pseudograph with String vertices", .tags(.fixture), arguments: UndirectedFixture<String>.all)
    func pseudographLawsWithStrings(_ fixture: UndirectedFixture<String>) {
        func check<G: Graph>(_ g: G, absent: G.Vertex) {
            let edges = Array(g.edges)
            var degreeSum = 0
            for v in g.vertices {
                var expected: [G.Vertex] = []
                for e in edges {
                    if e.u == v && e.v == v {
                        expected += [v, v]
                    } else if e.u == v {
                        expected.append(e.v)
                    } else if e.v == v {
                        expected.append(e.u)
                    }
                }
                #expect(Array(g.neighbors(of: v)) == expected)
                #expect(g.degree(of: v) == expected.count)
                #expect(g.incidentEdges(of: v).map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == expected)
                degreeSum += g.degree(of: v)
            }
            #expect(degreeSum == 2 * g.edgeCount)
            #expect(!g.contains(absent))
            #expect(!g.contains(edge: UndirectedEdge(absent, absent)))
        }
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges), absent: "∅")
    }

    @Test("UG-L13 generic code reads the same values as the concrete members", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func genericAgreesWithConcrete(_ fixture: UndirectedFixture<Int>) {
        func answers<G: Graph<Int>>(_ g: G) -> [Int] where G.Edges.Index == Int {
            var result = [g.vertexCount, g.edgeCount]
            for v in fixture.vertexSet.sorted() {
                result.append(g.contains(v) ? 1 : 0)
                result.append(g.degree(of: v))
                for w in fixture.vertexSet.sorted() { result.append(g.contains(edge: UndirectedEdge(v, w)) ? 1 : 0) }
            }
            for e in g.edges.indices {
                result.append(g.oppositeVertex(to: g.edges[e].u, acrossEdgeAt: e))
                result.append(g.oppositeVertex(to: g.edges[e].v, acrossEdgeAt: e))
            }
            return result
        }
        let list = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var concrete = [list.vertexCount, list.edgeCount]
        for v in fixture.vertexSet.sorted() {
            concrete.append(list.contains(v) ? 1 : 0)
            concrete.append(list.degree(of: v))
            for w in fixture.vertexSet.sorted() { concrete.append(list.contains(edge: UndirectedEdge(v, w)) ? 1 : 0) }
        }
        for e in list.edges.indices {
            concrete.append(list.oppositeVertex(to: list.edges[e].u, acrossEdgeAt: e))
            concrete.append(list.oppositeVertex(to: list.edges[e].v, acrossEdgeAt: e))
        }
        #expect(answers(list) == concrete)
        let pseudograph = ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)
        var pseudographConcrete = [pseudograph.vertexCount, pseudograph.edgeCount]
        for v in fixture.vertexSet.sorted() {
            pseudographConcrete.append(pseudograph.contains(v) ? 1 : 0)
            pseudographConcrete.append(pseudograph.degree(of: v))
            for w in fixture.vertexSet.sorted() { pseudographConcrete.append(pseudograph.contains(edge: UndirectedEdge(v, w)) ? 1 : 0) }
        }
        for e in pseudograph.edges.indices {
            pseudographConcrete.append(pseudograph.oppositeVertex(to: pseudograph.edges[e].u, acrossEdgeAt: e))
            pseudographConcrete.append(pseudograph.oppositeVertex(to: pseudograph.edges[e].v, acrossEdgeAt: e))
        }
        #expect(answers(pseudograph) == pseudographConcrete)
    }

    @Test("UG-L14 generic counts and degrees are the fixture's", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func genericAgreesWithFixture(_ fixture: UndirectedFixture<Int>) {
        func counts<G: Graph<Int>>(_ g: G) -> (vertices: Int, edges: Int, degree: [Int: Int]) {
            var degree: [Int: Int] = [:]
            for v in g.vertices { degree[v] = g.degree(of: v) }
            return (g.vertexCount, g.edgeCount, degree)
        }
        let simple = counts(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        #expect(simple.vertices == fixture.vertexCount)
        #expect(simple.edges == fixture.edgeCount)
        #expect(simple.degree == fixture.degree)
        let kept = counts(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        #expect(kept.vertices == fixture.vertexCount)
        #expect(kept.edges == fixture.pseudographEdgeCount)
        #expect(kept.degree == fixture.pseudographDegree)
    }

    @Test("UG-L14 generic counts and degrees with String vertices", .tags(.fixture), arguments: UndirectedFixture<String>.all)
    func genericAgreesWithStringFixture(_ fixture: UndirectedFixture<String>) {
        func counts<G: Graph<String>>(_ g: G) -> (vertices: Int, edges: Int, degree: [String: Int]) {
            var degree: [String: Int] = [:]
            for v in g.vertices { degree[v] = g.degree(of: v) }
            return (g.vertexCount, g.edgeCount, degree)
        }
        let simple = counts(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        #expect(simple.vertices == fixture.vertexCount)
        #expect(simple.edges == fixture.edgeCount)
        #expect(simple.degree == fixture.degree)
        let kept = counts(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        #expect(kept.edges == fixture.pseudographEdgeCount)
        #expect(kept.degree == fixture.pseudographDegree)
    }

    @Test("UG-L04, L11 parallel edges and a loop through the protocol, as petgraph lists them")
    func repeatedEdges() {
        func check(_ g: some Graph<Int>, neighbors: [Int: [Int]], degree: [Int: Int]) {
            for (v, expected) in neighbors { #expect(Array(g.neighbors(of: v)) == expected, "neighbors(of: \(v))") }
            for (v, d) in degree { #expect(g.degree(of: v) == d, "degree(of: \(v))") }
        }
        // petgraph tests/graph.rs: neighbors(b) == [a, c, a]; a's loop adds a twice to a's own list.
        let petgraph = ReferencePseudograph(edges: UndirectedFixture<Int>.petgraphUndirected.edges)
        #expect(petgraph.edgeCount == 7)
        check(petgraph, neighbors: [1: [0, 2, 0], 0: [1, 2, 2, 0, 0, 1, 3]], degree: [0: 7, 1: 3, 2: 3, 3: 1])
        // The two copies of 1–2 are two positions, listed at both ends.
        let doubled = ReferencePseudograph(edges: UndirectedFixture<Int>.parallelPath.edges)
        #expect(Array(doubled.incidentEdges(of: 1)) == [0, 1, 2])
        #expect(Array(doubled.incidentEdges(of: 2)) == [1, 2])
        // The loop is one position, listed twice.
        #expect(Array(petgraph.incidentEdges(of: 0)) == [0, 1, 2, 3, 3, 5, 6])
    }

    @Test("UG-P01 the laws on seeded random graphs, the same through every conformer", .tags(.randomized), arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func randomGraphs(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 30, using: &generator)
        var edges: [UndirectedEdge<Int>] = []
        for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &generator) {
            edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)))
        }
        // Everything a generic algorithm can observe, as plain values.
        func observe<G: Graph<Int>>(_ g: G) -> [[Int]] {
            var rows: [[Int]] = [[g.vertexCount, g.edgeCount]]
            var degreeSum = 0
            for v in 0 ..< n {
                rows.append(Array(g.neighbors(of: v)).sorted())
                rows.append([g.degree(of: v), g.incidentEdges(of: v).map { g.oppositeVertex(to: v, acrossEdgeAt: $0) }.count])
                rows.append((0 ..< n).map { g.contains(edge: UndirectedEdge(v, $0)) ? 1 : 0 })
                degreeSum += g.degree(of: v)
            }
            rows.append([degreeSum - 2 * g.edgeCount])
            return rows
        }
        // Set collapses repeats in either orientation.
        let distinct = Array(Set(edges))
        let expected = observe(ReferencePseudograph(vertices: 0 ..< n, edges: distinct))
        #expect(observe(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)) == expected)
        #expect(observe(UndirectedAdjacencyList(ReferencePseudograph(vertices: 0 ..< n, edges: edges))) == expected)
        #expect(expected.last == [0])
    }
}
