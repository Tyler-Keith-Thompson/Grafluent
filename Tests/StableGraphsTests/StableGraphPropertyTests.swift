// Properties with shrinking (swift-property-based). Random insert and remove sequences run against
// a model written out beside the graph: a list of (vertex, position) in insertion order, a list of
// (position, source, target) in insertion order, and the two end indices; `changeTarget` and
// `changeSource` re-point an edge in place, so rows stay filters of the edge list in position order. The model follows only
// api.md's rules: a new vertex or edge gets the current end index; a removal leaves a hole and moves
// nothing; removing a vertex removes its edges; `remove(edge:)` takes the newest copy; only
// `removeAll()` and `removeAllEdges()` reset an end index. Every result and the whole state are
// compared after every step: vertices, edges and every out- and in-row in insertion order,
// positions never reused, every position removed since the last reset rejected by
// `indices.contains` and `containsEdge(atPosition:)` / `containsVertex(atPosition:)`, the dense
// bounds nil exactly while holes exist, the position bounds the end indices. Then Codable round trips keeping
// the next fresh positions, equality and hashing ignoring positions, and algorithms on random
// graphs with holes against the compacted copy. See README.md.

import Connectivity
import Foundation
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Traversal

@Suite("StableGraphs properties against a model, with shrinking", .tags(.randomized))
struct StableGraphPropertyTests {
    @Test("Random operation sequences agree with the model after every step")
    func againstModel() async {
        let operations = zip(Gen.int(in: 0 ... 19), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = StableDirectedGraph<Int>()
            var vertices: [(vertex: Int, position: Int)] = []
            var edges: [(position: Int, source: Int, target: Int)] = []
            var vertexEnd = 0, edgeEnd = 0
            var staleEdges = Set<Int>(), staleVertices = Set<Int>()
            // Attached maps: every removal must clear the removed element's value.
            let labels = graph.addEdgeMap(of: Int.self), tags = graph.addVertexMap(of: Int.self)
            var edgeValues: [Int: Int] = [:], vertexValues: [Int: Int] = [:]
            for (step, (kind, a, b, k)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let isVertex = vertices.contains { $0.vertex == a }
                switch kind {
                case 0, 1:
                    let result = graph.insert(a)
                    #expect(result.inserted == !isVertex && result.memberAfterInsert == a, "\(context)")
                    if !isVertex { vertices.append((a, vertexEnd)); vertexEnd += 1 }
                case 2, 3, 4, 5:
                    let p = graph.insert(edge: DirectedEdge(from: a, to: b))
                    #expect(p == edgeEnd, "\(context)")
                    for x in [a, b] where !vertices.contains(where: { $0.vertex == x }) { vertices.append((x, vertexEnd)); vertexEnd += 1 }
                    edges.append((edgeEnd, a, b))
                    edgeEnd += 1
                case 6, 7:
                    let removed = graph.remove(edge: DirectedEdge(from: a, to: b))
                    if let newest = edges.lastIndex(where: { $0.source == a && $0.target == b }) {
                        #expect(removed == DirectedEdge(from: a, to: b), "\(context)")
                        staleEdges.insert(edges.remove(at: newest).position)
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 8, 9:
                    // A live position by its offset, or a stale one, which only indices.contains may see.
                    if !edges.isEmpty {
                        let offset = k % edges.count
                        let e = edges.remove(at: offset)
                        #expect(graph.remove(edgeAt: e.position) == DirectedEdge(from: e.source, to: e.target), "\(context)")
                        staleEdges.insert(e.position)
                    }
                case 10, 11:
                    let removed = graph.remove(a)
                    #expect(removed == (isVertex ? a : nil), "\(context)")
                    if let offset = vertices.firstIndex(where: { $0.vertex == a }) {
                        staleVertices.insert(vertices.remove(at: offset).position)
                        for e in edges where e.source == a || e.target == a { staleEdges.insert(e.position) }
                        edges.removeAll { $0.source == a || $0.target == a }
                    }
                case 12:
                    let count = edges.filter { $0.source == a && $0.target == b }.count
                    #expect(graph.removeAllEdges(from: a, to: b) == count, "\(context)")
                    for e in edges where e.source == a && e.target == b { staleEdges.insert(e.position) }
                    edges.removeAll { $0.source == a && $0.target == b }
                case 13:
                    #expect(graph.contains(edge: DirectedEdge(from: a, to: b)) == edges.contains { $0.source == a && $0.target == b }, "\(context)")
                    #expect(Array(graph.edges(from: a, to: b)) == edges.filter { $0.source == a && $0.target == b }.map(\.position), "\(context)")
                    #expect(graph.edgeCount(from: a, to: b) == edges.filter { $0.source == a && $0.target == b }.count, "\(context)")
                case 14:
                    if k % 8 == 0 {
                        graph.removeAllEdges()
                        edges = []
                        edgeEnd = 0
                        staleEdges = []
                    }
                case 16, 17:
                    // Re-point a live edge (by offset) at vertex b, if b is a vertex: the position
                    // and the unchanged end's row place stay, the new end's row stays in position order.
                    if !edges.isEmpty, vertices.contains(where: { $0.vertex == b }) {
                        let offset = k % edges.count
                        if kind == 16 {
                            graph.changeTarget(ofEdgeAt: edges[offset].position, to: b)
                            edges[offset].target = b
                        } else {
                            graph.changeSource(ofEdgeAt: edges[offset].position, to: b)
                            edges[offset].source = b
                        }
                    }
                case 18:
                    // The safe: spellings at any position, live or not, to any vertex or non-vertex.
                    let position = k % (edgeEnd + 2) - 1
                    let live = edges.firstIndex { $0.position == position }
                    let ok = live != nil && vertices.contains { $0.vertex == b }
                    if k % 2 == 0 {
                        let changed = graph.changeTarget(ofEdgeAt: position, safe: b)
                        #expect(changed == ok, "\(context)")
                        if ok, let live { edges[live].target = b }
                    } else {
                        let changed = graph.changeSource(ofEdgeAt: position, safe: b)
                        #expect(changed == ok, "\(context)")
                        if ok, let live { edges[live].source = b }
                    }
                case 19:
                    // Values for every live edge and vertex in the attached maps.
                    for e in edges { graph[map: labels, ofEdgeAt: e.position] = e.position &* 3; edgeValues[e.position] = e.position &* 3 }
                    for (vertex, position) in vertices { graph[map: tags, of: vertex] = -position; vertexValues[position] = -position }
                default:
                    if k % 16 == 0 {
                        graph.removeAll()
                        vertices = []
                        edges = []
                        vertexEnd = 0
                        edgeEnd = 0
                        staleEdges = []
                        staleVertices = []
                    }
                }
                // The maps hold values only at live positions: the removal cleared the rest.
                edgeValues = edgeValues.filter { p, _ in edges.contains { $0.position == p } }
                vertexValues = vertexValues.filter { p, _ in vertices.contains { $0.position == p } }
                #expect((0 ..< edgeEnd).filter { graph[map: labels, ofEdgeAt: $0] != nil } == edgeValues.keys.sorted(), "\(context)")
                #expect((0 ..< vertexEnd).filter { graph[map: tags, ofVertexAt: $0] != nil } == vertexValues.keys.sorted(), "\(context)")
                for (p, value) in edgeValues { #expect(graph[map: labels, ofEdgeAt: p] == value, "\(context)") }
                // The whole state.
                #expect(Array(graph.vertices) == vertices.map(\.vertex), "\(context)")
                #expect(Array(graph.vertices.indices) == vertices.map(\.position), "\(context)")
                #expect(graph.vertices.endIndex == vertexEnd && graph.edges.endIndex == edgeEnd, "\(context)")
                #expect(Array(graph.edges) == edges.map { DirectedEdge(from: $0.source, to: $0.target) }, "\(context)")
                #expect(Array(graph.edges.indices) == edges.map(\.position), "\(context)")
                #expect(graph.vertexCount == vertices.count && graph.edgeCount == edges.count, "\(context)")
                #expect(graph.vertexIndexBound == (vertices.count == vertexEnd ? vertexEnd : nil), "\(context)")
                #expect(graph.edgeIndexBound == (edges.count == edgeEnd ? edgeEnd : nil), "\(context)")
                for (vertex, position) in vertices {
                    let out = edges.filter { $0.source == vertex }, into = edges.filter { $0.target == vertex }
                    #expect(graph.vertices.firstIndex(of: vertex) == position && graph.vertices[position] == vertex, "\(context)")
                    #expect(Array(graph.outEdges(of: vertex)) == out.map(\.position), "\(context)")
                    #expect(Array(graph.inEdges(of: vertex)) == into.map(\.position), "\(context)")
                    #expect(Array(graph.successors(of: vertex)) == out.map(\.target), "\(context)")
                    #expect(Array(graph.predecessors(of: vertex)) == into.map(\.source), "\(context)")
                    #expect(graph.outDegree(of: vertex) == out.count && graph.inDegree(of: vertex) == into.count, "\(context)")
                    #expect(graph.degree(of: vertex) == out.count + into.count, "\(context)")
                    if graph.vertexIndexBound != nil {
                        #expect(graph.vertexIndex(of: vertex) == position && graph.vertex(atIndex: position) == vertex, "\(context)")
                    }
                }
                for e in edges {
                    #expect(graph.source(ofEdgeAt: e.position) == e.source && graph.target(ofEdgeAt: e.position) == e.target, "\(context)")
                    if graph.edgeIndexBound != nil { #expect(graph.edgeIndex(of: e.position) == e.position, "\(context)") }
                }
                for p in staleEdges { #expect(!graph.edges.indices.contains(p), "stale edge \(p), \(context)") }
                for p in staleVertices { #expect(!graph.vertices.indices.contains(p), "stale vertex \(p), \(context)") }
                for p in [-1, edgeEnd, edgeEnd + 1] { #expect(!graph.edges.indices.contains(p), "\(context)") }
                for p in [-1, vertexEnd] { #expect(!graph.vertices.indices.contains(p), "\(context)") }
                for v in 0 ... 5 { #expect(graph.contains(v) == vertices.contains { $0.vertex == v }, "\(context)") }
                // SparselyIndexedDirectedGraph: the bounds cover every live position, and liveness is exact.
                #expect(graph.vertexPositionBound == vertexEnd && graph.edgePositionBound == edgeEnd, "\(context)")
                for p in -1 ... vertexEnd + 1 {
                    #expect(graph.containsVertex(atPosition: p) == vertices.contains { $0.position == p }, "\(context)")
                }
                for p in -1 ... edgeEnd + 1 {
                    #expect(graph.containsEdge(atPosition: p) == edges.contains { $0.position == p }, "\(context)")
                }
                for (vertex, position) in vertices {
                    #expect(graph.vertexPosition(of: vertex) == position && graph.vertex(atPosition: position) == vertex, "\(context)")
                }
            }
        }
    }

    @Test("Codable round trips keep every position, both ends and the next fresh positions")
    func codableRoundTrip() async throws {
        let operations = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 40)
        await propertyCheck(count: 200, input: operations) { operations in
            var graph = StableDirectedGraph<Int>()
            for (kind, a, b) in operations {
                switch kind {
                case 0, 1: graph.insert(edge: DirectedEdge(from: a, to: b))
                case 2: graph.remove(a)
                default:
                    if let p = graph.edges.indices.first(where: { $0 % 7 == b }) { graph.remove(edgeAt: p) }
                }
            }
            guard var decoded = try? JSONDecoder().decode(StableDirectedGraph<Int>.self, from: JSONEncoder().encode(graph)) else {
                Issue.record("round trip failed for \(operations)")
                return
            }
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == Array(graph.vertices) && Array(decoded.vertices.indices) == Array(graph.vertices.indices))
            #expect(Array(decoded.edges) == Array(graph.edges) && Array(decoded.edges.indices) == Array(graph.edges.indices))
            #expect(decoded.vertices.endIndex == graph.vertices.endIndex && decoded.edges.endIndex == graph.edges.endIndex)
            #expect(decoded.vertexIndexBound == graph.vertexIndexBound && decoded.edgeIndexBound == graph.edgeIndexBound)
            for v in graph.vertices {
                #expect(Array(decoded.outEdges(of: v)) == Array(graph.outEdges(of: v)) && Array(decoded.inEdges(of: v)) == Array(graph.inEdges(of: v)))
            }
            var original = graph
            #expect(decoded.insert(edge: DirectedEdge(from: 9, to: 0)) == original.insert(edge: DirectedEdge(from: 9, to: 0)))
            #expect(Array(decoded.vertices.indices) == Array(original.vertices.indices))
            #expect(Array(decoded.inEdges(of: 0)) == Array(original.inEdges(of: 0)))
        }
    }

    @Test("Equality and hashing ignore positions, holes and orders, and see every copy")
    func equalityIgnoresPositions() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 20)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 0 ... 1_000)) { raw, seed in
            let wanted = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            // The same value reached with holes: extra vertices and copies inserted, then removed.
            var holed = StableDirectedGraph<Int>(vertices: [99])
            for (k, e) in wanted.enumerated() {
                holed.insert(edge: DirectedEdge(from: e.source, to: 98))
                holed.insert(edge: e)
                if (k + seed).isMultiple(of: 3) {
                    holed.insert(edge: e)
                    holed.remove(edge: e)
                }
            }
            holed.remove(99)
            holed.remove(98)
            let plain = StableDirectedGraph<Int>(vertices: Array(Set(wanted.flatMap { [$0.source, $0.target] })).sorted().reversed(), edges: wanted.reversed())
            #expect(holed == plain && holed.hashValue == plain.hashValue, "\(raw)")
            #expect(StableDirectedGraph<Int>(holed) == holed)
            if let first = wanted.first {
                var fewer = holed
                fewer.remove(edge: first)
                #expect(fewer != plain, "\(raw)")
                var more = plain
                more.insert(edge: first)
                #expect(more != holed, "\(raw)")
                if first.source != first.target {
                    var flipped = plain
                    flipped.remove(edge: first)
                    flipped.insert(edge: DirectedEdge(from: first.target, to: first.source))
                    #expect(flipped != holed, "\(raw)")
                }
            }
        }
    }

    @Test("Algorithms on random graphs with holes agree with the compacted copy")
    func algorithmsAgainstCompacted() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 40)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, mask in
            var graph = StableDirectedGraph<Int>(vertices: 0 ..< 10, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            for v in 0 ..< 10 where mask >> v & 1 == 1 { graph.remove(v) }
            for p in Array(graph.edges.indices) where (mask >> (10 + p % 10)) & 1 == 1 { graph.remove(edgeAt: p) }
            let compacted = DirectedPseudograph<Int>(graph)
            let positions = Array(graph.edges.indices)
            #expect(Array(compacted.edges) == Array(graph.edges), "\(raw) \(mask)")
            #expect(Array(graph.stronglyConnectedComponents().map { Array($0) }) == Array(compacted.stronglyConnectedComponents().map { Array($0) }), "\(raw) \(mask)")
            #expect(Array(graph.weaklyConnectedComponents().map { Array($0) }) == Array(compacted.weaklyConnectedComponents().map { Array($0) }), "\(raw) \(mask)")
            #expect(graph.topologicalSort() == compacted.topologicalSort(), "\(raw) \(mask)")
            #expect(Array(graph.depthFirstSearch()) == Array(compacted.depthFirstSearch()), "\(raw) \(mask)")
            for v in graph.vertices {
                #expect(Array(graph.breadthFirstSearch(from: v)) == Array(compacted.breadthFirstSearch(from: v)), "\(raw) \(mask)")
                #expect(Array(graph.outEdges(of: v)) == compacted.outEdges(of: v).map { positions[$0] }, "\(raw) \(mask)")
                #expect(Array(graph.inEdges(of: v)) == compacted.inEdges(of: v).map { positions[$0] }, "\(raw) \(mask)")
            }
        }
    }
}
