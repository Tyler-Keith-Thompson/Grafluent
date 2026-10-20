// PackedCompressedSparseRow against a model of a vertex set and an edge set through random
// operation sequences: inserts, removals of vertices and edges, bulk removals, checked spellings
// and copies. After every operation each query agrees with the model, the dense indices stay dense,
// the lent rows are disjoint and in slot order, and attached maps keep their values through every
// rebalance. Case IDs (C-nn) refer to Tests/Catalogs/AdjacencyList/cases.md, whose conventions this
// type shares with AdjacencyList; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PackedCompressedSparseRowModule
import PropertyBased
import Testing

@Suite("PackedCompressedSparseRow against a model")
struct PackedCompressedSparseRowModelTests {
    @Test("Random operations on 0..<10: every query agrees with a set model, on a packed and on an inserted start")
    func randomOperations() async {
        let operations = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ..< 10), Gen.int(in: 0 ..< 10)).array(of: 0 ... 120)
        await propertyCheck(count: 400, input: operations, Gen.bool) { operations, packedStart in
            var graph = packedStart
                ? PackedCompressedSparseRow(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 3)])
                : PackedCompressedSparseRow<Int>()
            var vertices: Set<Int> = packedStart ? [0, 1, 2, 3, 4, 5] : []
            var edges: Set<DirectedEdge<Int>> = packedStart ? [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 3)] : []
            let weight = graph.addEdgeMap(default: -1)
            var weights: [DirectedEdge<Int>: Int] = [:]
            var snapshot: (PackedCompressedSparseRow<Int>, Set<Int>, Set<DirectedEdge<Int>>)?
            for (op, u, v) in operations {
                let edge = DirectedEdge(from: u, to: v)
                switch op {
                case 0:
                    #expect(graph.insert(u).inserted == vertices.insert(u).inserted, "insert(\(u))")
                case 1, 2, 3:
                    let result = graph.insert(edge: edge)
                    #expect(result.inserted == !edges.contains(edge) && result.memberAfterInsert == edge, "insert(edge: \(edge))")
                    if result.inserted {
                        let position = graph.edges(from: u, to: v)[0]
                        graph[weight, ofEdgeAt: position] = u * 10 + v
                        weights[edge] = u * 10 + v
                    }
                    edges.insert(edge)
                    vertices.formUnion([u, v])
                case 4:
                    #expect(graph.remove(u) == vertices.remove(u), "remove(\(u))")
                    edges = edges.filter { $0.source != u && $0.target != u }
                    weights = weights.filter { $0.key.source != u && $0.key.target != u }
                case 5, 6:
                    #expect(graph.remove(edge: edge) == edges.remove(edge), "remove(edge: \(edge))")
                    weights[edge] = nil
                case 7:
                    let result = try? graph.insert(checked: edge)
                    if vertices.contains(u), vertices.contains(v) {
                        #expect(result?.inserted == !edges.contains(edge), "insert(checked: \(edge))")
                        if result?.inserted == true {
                            graph[weight, ofEdgeAt: graph.edges(from: u, to: v)[0]] = u * 10 + v
                            weights[edge] = u * 10 + v
                        }
                        edges.insert(edge)
                    } else {
                        #expect(result == nil, "insert(checked: \(edge)) with a missing endpoint")
                    }
                default:
                    snapshot = (graph, vertices, edges)
                }
                verify(graph, vertices, edges)
                // Every weight written is still at its edge's position.
                for (e, w) in weights { #expect(graph[weight, ofEdgeAt: graph.edges(from: e.source, to: e.target)[0]] == w, "weight of \(e)") }
                for e in edges where weights[e] == nil { #expect(graph[weight, ofEdgeAt: graph.edges(from: e.source, to: e.target)[0]] == -1, "default of \(e)") }
            }
            if let (copy, vertices, edges) = snapshot { verify(copy, vertices, edges) }
        }
    }

    @Test("String vertices through a dictionary: the same model, with the slot table in play")
    func stringVertices() async {
        let names = ["ann", "bob", "cal", "dee", "eve", "fay", "gus"]
        let operations = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ..< 7), Gen.int(in: 0 ..< 7)).array(of: 0 ... 80)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = PackedCompressedSparseRow<String>()
            var vertices: Set<String> = []
            var edges: Set<DirectedEdge<String>> = []
            for (op, a, b) in operations {
                let u = names[a], v = names[b]
                let edge = DirectedEdge(from: u, to: v)
                switch op {
                case 0: #expect(graph.insert(u).inserted == vertices.insert(u).inserted)
                case 1, 2, 3:
                    #expect(graph.insert(edge: edge).inserted == !edges.contains(edge))
                    edges.insert(edge)
                    vertices.formUnion([u, v])
                case 4:
                    #expect(graph.remove(u) == vertices.remove(u))
                    edges = edges.filter { $0.source != u && $0.target != u }
                default:
                    #expect(graph.remove(edge: edge) == edges.remove(edge))
                }
                verify(graph, vertices, edges)
            }
        }
    }

    @Test("Bulk removals: removeAllEdges keeps the vertices, removeAll empties, with and without capacity")
    func bulkRemovals() {
        var graph = PackedCompressedSparseRow(vertices: 0 ..< 5, edges: (0 ..< 5).flatMap { u in (0 ..< 5).map { DirectedEdge(from: u, to: $0) } })
        for v in 5 ..< 9 { graph.insert(edge: DirectedEdge(from: v, to: v - 5)) }
        graph.removeAllEdges(keepingCapacity: true)
        verify(graph, Set(0 ..< 9), [])
        graph.insert(edge: DirectedEdge(from: 8, to: 0))
        verify(graph, Set(0 ..< 9), [DirectedEdge(from: 8, to: 0)])
        graph.removeAll()
        verify(graph, [], [])
        graph.insert(edge: DirectedEdge(from: 2, to: 2))
        verify(graph, [2], [DirectedEdge(from: 2, to: 2)])
        graph.removeAllEdges()
        verify(graph, [2], [])
        graph.reserveCapacity(vertexCount: 100, edgeCount: 1000)
        verify(graph, [2], [])
    }
}

/// Every query against the model, and the type's own laws.
func verify<V: Hashable>(_ graph: PackedCompressedSparseRow<V>, _ vertices: Set<V>, _ edges: Set<DirectedEdge<V>>) {
    #expect(graph.vertexCount == vertices.count && Set(graph.vertices) == vertices, "vertices \(Array(graph.vertices)), model \(vertices)")
    #expect(graph.edgeCount == edges.count && Set(graph.edges) == edges, "edges \(Array(graph.edges)), model \(edges)")
    #expect(graph == PackedCompressedSparseRow(vertices: vertices, edges: edges), "equal to a graph built from the model")
    #expect(graph.edgeIndexBound == edges.count && graph.vertexIndexBound == vertices.count)
    for v in vertices {
        #expect(graph.contains(v))
        let out = Set(graph.successors(of: v)), into = Set(graph.predecessors(of: v))
        #expect(out == Set(edges.filter { $0.source == v }.map(\.target)), "successors of \(v)")
        #expect(into == Set(edges.filter { $0.target == v }.map(\.source)), "predecessors of \(v)")
        #expect(graph.outDegree(of: v) == out.count && graph.inDegree(of: v) == into.count && graph.degree(of: v) == out.count + into.count)
        #expect(Set(graph.outEdges(of: v).map { graph.edges[$0] }) == edges.filter { $0.source == v }, "out-edges of \(v)")
        #expect(Set(graph.inEdges(of: v).map { graph.edges[$0] }) == edges.filter { $0.target == v }, "in-edges of \(v)")
        let i = graph.vertexIndex(of: v)
        #expect(graph.vertex(atIndex: i) == v && i < vertices.count)
        #expect(Set(graph.successorIndices(ofIndex: i).map { graph.vertex(atIndex: $0) }) == out)
        #expect(Set(graph.predecessorIndices(ofIndex: i).map { graph.vertex(atIndex: $0) }) == into)
        let checkedOut = (try? graph.successors(checked: v)).map { Set($0) }
        #expect(checkedOut == out && (try? graph.outDegree(checked: v)) == out.count)
    }
    for e in edges {
        #expect(graph.contains(edge: e))
        let positions = graph.edges(from: e.source, to: e.target)
        #expect(positions.count == 1 && graph.edges[positions[0]] == e && graph.source(ofEdgeAt: positions[0]) == e.source && graph.target(ofEdgeAt: positions[0]) == e.target)
        #expect(graph.edgeIndex(of: positions[0]) == positions[0] && positions[0] < edges.count)
        #expect(graph.sourceIndex(ofEdgeAt: positions[0]) == graph.vertexIndex(of: e.source))
    }
    // The lent rows: disjoint, in slot order, each row's positions beside its targets.
    let rows: Bool? = graph._withOutIndexRows { targets, targetRows, positions, positionRows in
        var ok = targetRows.count >= 3 * vertices.count && positionRows.count == targetRows.count
        var previousEnd = 0
        for slot in 0 ..< vertices.count {
            let start = targetRows[3 * slot], count = targetRows[3 * slot + 1], capacity = targetRows[3 * slot + 2]
            ok = ok && start >= previousEnd && count >= 0 && capacity >= count && start + capacity <= targets.count
            for k in 0 ..< count {
                let p = positions[start + k]
                ok = ok && graph.edges[p].source == graph.vertex(atIndex: slot) && graph.vertexIndex(of: graph.edges[p].target) == targets[start + k]
            }
            previousEnd = start + capacity
        }
        return ok
    }
    #expect(rows == true, "the lent rows are not packed in slot order")
}
