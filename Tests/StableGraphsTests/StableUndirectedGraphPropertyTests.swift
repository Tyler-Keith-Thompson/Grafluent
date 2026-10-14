// StableUndirectedGraph against a model, with shrinking (swift-property-based). Random insert and
// remove sequences run against a model written out beside the graph: a list of (vertex, position)
// in insertion order, a list of (position, u, v) in insertion order, and the two end indices. The
// model follows only the documented rules: a new vertex or edge gets the current end index, in its
// orientation; a removal leaves a hole and moves nothing; removing a vertex removes its edges;
// `remove(edge:)` takes the newest copy in either orientation; only `removeAll()` and
// `removeAllEdges()` reset an end index; a vertex's edges are in position order, a self-loop twice.
// After every step the whole state is compared, and the attached maps' values with it. See
// README.md.

import GraphProtocols
import PropertyBased
import StableGraphs
import Testing

@Suite("StableUndirectedGraph against a model, with shrinking", .tags(.randomized))
struct StableUndirectedGraphPropertyTests {
    @Test("Random operation sequences agree with the model after every step")
    func againstModel() async {
        let operations = zip(Gen.int(in: 0 ... 15), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = StableUndirectedGraph<Int>()
            var vertices: [(vertex: Int, position: Int)] = []
            var edges: [(position: Int, u: Int, v: Int)] = []
            var vertexEnd = 0, edgeEnd = 0
            var staleEdges = Set<Int>(), staleVertices = Set<Int>()
            let labels = graph.addEdgeMap(of: Int.self), tags = graph.addVertexMap(of: Int.self)
            var edgeValues: [Int: Int] = [:], vertexValues: [Int: Int] = [:]
            for (step, (kind, a, b, k)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let isVertex = vertices.contains { $0.vertex == a }
                switch kind {
                case 0:
                    let result = graph.insert(a)
                    #expect(result.inserted == !isVertex && result.memberAfterInsert == a, "\(context)")
                    if !isVertex { vertices.append((a, vertexEnd)); vertexEnd += 1 }
                case 1, 2, 3, 4:
                    let p = graph.insert(edge: UndirectedEdge(a, b))
                    #expect(p == edgeEnd, "\(context)")
                    for x in [a, b] where !vertices.contains(where: { $0.vertex == x }) { vertices.append((x, vertexEnd)); vertexEnd += 1 }
                    edges.append((edgeEnd, a, b))
                    edgeEnd += 1
                case 5, 6:
                    let removed = graph.remove(edge: UndirectedEdge(a, b))
                    if let newest = edges.lastIndex(where: { ($0.u == a && $0.v == b) || ($0.u == b && $0.v == a) }) {
                        let e = edges.remove(at: newest)
                        #expect(removed?.u == e.u && removed?.v == e.v, "\(context)")
                        staleEdges.insert(e.position)
                        edgeValues[e.position] = nil
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 7:
                    if !edges.isEmpty {
                        let e = edges.remove(at: k % edges.count)
                        let removed = graph.remove(edgeAt: e.position)
                        #expect(removed.u == e.u && removed.v == e.v, "\(context)")
                        staleEdges.insert(e.position)
                        edgeValues[e.position] = nil
                    }
                case 8, 9:
                    #expect(graph.remove(a) == (isVertex ? a : nil), "\(context)")
                    if let offset = vertices.firstIndex(where: { $0.vertex == a }) {
                        let position = vertices.remove(at: offset).position
                        staleVertices.insert(position)
                        vertexValues[position] = nil
                        for e in edges where e.u == a || e.v == a {
                            staleEdges.insert(e.position)
                            edgeValues[e.position] = nil
                        }
                        edges.removeAll { $0.u == a || $0.v == a }
                    }
                case 10:
                    let matching = edges.filter { ($0.u == a && $0.v == b) || ($0.u == b && $0.v == a) }
                    #expect(graph.removeAllEdges(between: a, and: b) == matching.count, "\(context)")
                    for e in matching {
                        staleEdges.insert(e.position)
                        edgeValues[e.position] = nil
                    }
                    edges.removeAll { ($0.u == a && $0.v == b) || ($0.u == b && $0.v == a) }
                case 11:
                    // Remove the edges whose position is a multiple of b + 2.
                    let chosen = edges.filter { $0.position % (b + 2) == 0 }
                    #expect(graph.removeAllEdges(where: { $0 % (b + 2) == 0 }) == chosen.count, "\(context)")
                    for e in chosen {
                        staleEdges.insert(e.position)
                        edgeValues[e.position] = nil
                    }
                    edges.removeAll { $0.position % (b + 2) == 0 }
                case 12:
                    if !edges.isEmpty {
                        let e = edges[k % edges.count]
                        graph[labels, ofEdgeAt: e.position] = k
                        edgeValues[e.position] = k
                    }
                    if let x = vertices.first(where: { $0.vertex == a }) {
                        graph[tags, of: a] = k
                        vertexValues[x.position] = k
                    }
                case 13:
                    if k % 5 == 0 {
                        graph.removeAllEdges(keepingCapacity: k % 2 == 0)
                        edges = []
                        edgeEnd = 0
                        staleEdges = []
                        edgeValues = [:]
                    }
                case 14:
                    if k % 7 == 0 {
                        graph.removeAll(keepingCapacity: k % 2 == 0)
                        vertices = []
                        edges = []
                        vertexEnd = 0
                        edgeEnd = 0
                        staleEdges = []
                        staleVertices = []
                        edgeValues = [:]
                        vertexValues = [:]
                    }
                default:
                    // A copy mutated on its own never changes the graph.
                    var copy = graph
                    copy.insert(edge: UndirectedEdge(a, b))
                    if !edges.isEmpty { copy[labels, ofEdgeAt: edges[0].position] = -1 }
                }
                // The whole state.
                #expect(Array(graph.vertices) == vertices.map(\.vertex), "\(context)")
                #expect(Array(graph.vertices.indices) == vertices.map(\.position), "\(context)")
                #expect(graph.vertices.endIndex == vertexEnd && graph.edges.endIndex == edgeEnd, "\(context)")
                #expect(Array(graph.edges.indices) == edges.map(\.position), "\(context)")
                #expect(graph.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(context)")
                #expect(graph.vertexIndexBound == (vertices.count == vertexEnd ? vertexEnd : nil), "\(context)")
                #expect(graph.edgeIndexBound == (edges.count == edgeEnd ? edgeEnd : nil), "\(context)")
                for x in vertices {
                    // Each edge end at the vertex, in position order: a self-loop twice.
                    var incident: [Int] = [], neighbors: [Int] = []
                    for e in edges {
                        if e.u == x.vertex { incident.append(e.position); neighbors.append(e.v) }
                        if e.v == x.vertex { incident.append(e.position); neighbors.append(e.u) }
                    }
                    #expect(Array(graph.incidentEdges(of: x.vertex)) == incident, "\(context) at \(x.vertex)")
                    #expect(Array(graph.neighbors(of: x.vertex)) == neighbors, "\(context) at \(x.vertex)")
                    #expect(graph.degree(of: x.vertex) == incident.count, "\(context)")
                    if graph.vertexIndexBound != nil {
                        #expect(Array(graph.neighborIndices(ofIndex: x.position)) == neighbors.map { n in vertices.first { $0.vertex == n }!.position }, "\(context)")
                    }
                    #expect(graph[tags, ofVertexAt: x.position] == vertexValues[x.position], "\(context)")
                }
                for e in edges { #expect(graph[labels, ofEdgeAt: e.position] == edgeValues[e.position], "\(context)") }
                for p in staleEdges {
                    #expect(!graph.edges.indices.contains(p), "\(context)")
                    #expect(throws: EdgeNotFound.self) { try graph[labels, checkedEdgeAt: p] }
                }
                for p in staleVertices {
                    #expect(!graph.vertices.indices.contains(p), "\(context)")
                    #expect(throws: VertexNotFound.self) { try graph[tags, checkedVertexAt: p] }
                }
                for x in 0 ... 5 {
                    for y in x ... 5 {
                        let copies = edges.filter { ($0.u == x && $0.v == y) || ($0.u == y && $0.v == x) }.map(\.position)
                        #expect(Array(graph.edges(between: x, and: y)) == copies, "\(context)")
                        #expect(graph.contains(edge: UndirectedEdge(y, x)) == !copies.isEmpty, "\(context)")
                    }
                }
            }
        }
    }
}
