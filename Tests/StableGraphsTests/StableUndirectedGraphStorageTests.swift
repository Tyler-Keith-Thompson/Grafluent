// StableUndirectedGraph's storage and its fast paths: the bulk initializers build the same graph as
// one insertion per edge, rows and positions included, and the two stay alike under the same
// removals (both stable graphs); a decoded graph's rebuilt rows survive removals; the numbered
// incidence rows (`SparselyIndexedGraph`) against a model of the numbering, with vertex holes,
// with edge holes only, and through a test-local conformer that leaves `_numberedIncidenceRows` to
// GraphProtocols' default; the algorithms on those rows against the compacted copy; and the
// `SparselyIndexedGraph` laws. See README.md.

import Connectivity
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

/// A conformer outside the package: public members only, `_numberedIncidenceRows` from the default.
private struct Forwarding: SparselyIndexedGraph {
    let base: StableUndirectedGraph<Int>
    var vertices: StableUndirectedGraph<Int>.Vertices { base.vertices }
    var edges: StableUndirectedGraph<Int>.Edges { base.edges }
    var vertexCount: Int { base.vertexCount }
    var edgeCount: Int { base.edgeCount }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
    func neighbors(of vertex: Int) -> StableUndirectedGraph<Int>.Neighbors { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> StableUndirectedGraph<Int>.IncidentEdges { base.incidentEdges(of: vertex) }
    func degree(of vertex: Int) -> Int { base.degree(of: vertex) }
    var vertexPositionBound: Int { base.vertexPositionBound }
    var edgePositionBound: Int { base.edgePositionBound }
    func vertexPosition(of vertex: Int) -> Int { base.vertexPosition(of: vertex) }
    func vertex(atPosition position: Int) -> Int { base.vertex(atPosition: position) }
    func containsVertex(atPosition position: Int) -> Bool { base.containsVertex(atPosition: position) }
    func containsEdge(atPosition position: Int) -> Bool { base.containsEdge(atPosition: position) }
}

@Suite("StableUndirectedGraph storage and numbered rows")
struct StableUndirectedGraphStorageTests {
    @Test("The bulk initializers build what one insertion per edge builds, and the two stay alike under removals", .tags(.randomized))
    func bulkBuildAgainstInsertions() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 40)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 0 ... 4)) { triples, listed in
            let pairs = triples.map { UndirectedEdge($0.0, $0.1) }
            var bulk = StableUndirectedGraph(vertices: (0 ..< listed).map { 7 - $0 }, edges: pairs)
            var stepwise = StableUndirectedGraph(vertices: (0 ..< listed).map { 7 - $0 })
            for edge in pairs { stepwise.insert(edge: edge) }
            var directedBulk = StableDirectedGraph(vertices: (0 ..< listed).map { 7 - $0 }, edges: triples.map { DirectedEdge(from: $0.0, to: $0.1) })
            var directedStepwise = StableDirectedGraph(vertices: (0 ..< listed).map { 7 - $0 })
            for t in triples { directedStepwise.insert(edge: DirectedEdge(from: t.0, to: t.1)) }
            // Then the same removals on both, chosen by the third component.
            for (step, t) in triples.enumerated() {
                let context = "step \(step) of \(triples), \(listed) listed"
                #expect(Array(bulk.vertices.indices) == Array(stepwise.vertices.indices) && Array(bulk.vertices) == Array(stepwise.vertices), "\(context)")
                #expect(Array(bulk.edges.indices) == Array(stepwise.edges.indices), "\(context)")
                #expect(bulk.edges.map { [$0.u, $0.v] } == stepwise.edges.map { [$0.u, $0.v] }, "\(context)")
                for v in bulk.vertices {
                    #expect(Array(bulk.incidentEdges(of: v)) == Array(stepwise.incidentEdges(of: v)), "\(context) at \(v)")
                    #expect(Array(bulk.neighbors(of: v)) == Array(stepwise.neighbors(of: v)), "\(context) at \(v)")
                    #expect(Array(directedBulk.outEdges(of: v)) == Array(directedStepwise.outEdges(of: v)), "\(context) at \(v)")
                    #expect(Array(directedBulk.inEdges(of: v)) == Array(directedStepwise.inEdges(of: v)), "\(context) at \(v)")
                }
                switch t.2 % 3 {
                case 0:
                    let live = Array(bulk.edges.indices)
                    if !live.isEmpty {
                        let p = live[t.2 % live.count]
                        #expect(bulk.remove(edgeAt: p) == stepwise.remove(edgeAt: p))
                        #expect(directedBulk.remove(edgeAt: p) == directedStepwise.remove(edgeAt: p))
                    }
                case 1:
                    #expect(bulk.remove(t.0) == stepwise.remove(t.0))
                    #expect(directedBulk.remove(t.0) == directedStepwise.remove(t.0))
                default:
                    #expect(bulk.removeAllEdges(between: t.0, and: t.1) == stepwise.removeAllEdges(between: t.0, and: t.1))
                    #expect(directedBulk.removeAllEdges(from: t.0, to: t.1) == directedStepwise.removeAllEdges(from: t.0, to: t.1))
                }
            }
        }
    }

    @Test("A decoded graph's rebuilt rows take further removals like the original's", .tags(.randomized))
    func decodedThenRemoved() throws {
        var rng = SeededRandomNumberGenerator(seed: 44)
        for _ in 0 ..< 20 {
            var graph = StableUndirectedGraph<Int>(vertices: 0 ..< 12)
            for _ in 0 ..< 40 { graph.insert(edge: UndirectedEdge(Int.random(in: 0 ..< 12, using: &rng), Int.random(in: 0 ..< 12, using: &rng))) }
            for _ in 0 ..< 10 { graph.remove(edgeAt: Array(graph.edges.indices).randomElement(using: &rng)!) }
            graph.remove(Int.random(in: 0 ..< 12, using: &rng))
            var decoded = try JSONDecoder().decode(StableUndirectedGraph<Int>.self, from: JSONEncoder().encode(graph))
            for _ in 0 ..< 15 {
                if Bool.random(using: &rng), let p = Array(graph.edges.indices).randomElement(using: &rng) {
                    #expect(graph.remove(edgeAt: p) == decoded.remove(edgeAt: p))
                } else {
                    let v = Int.random(in: 0 ..< 12, using: &rng)
                    #expect(graph.remove(v) == decoded.remove(v))
                }
                #expect(Array(decoded.edges.indices) == Array(graph.edges.indices))
                for v in graph.vertices { #expect(Array(decoded.incidentEdges(of: v)) == Array(graph.incidentEdges(of: v))) }
            }
            #expect(decoded.insert(edge: UndirectedEdge(0, 1)) == graph.insert(edge: UndirectedEdge(0, 1)))
        }
    }

    @Test("_numberedIncidenceRows numbers vertices in vertices order and edges in edges order, rows in incidentEdges order, with vertex holes, edge holes, both, and none", arguments: 0 ..< 4)
    func numberedRows(holes: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(45 + holes))
        var graph = StableUndirectedGraph<Int>(vertices: 0 ..< 9)
        for _ in 0 ..< 30 { graph.insert(edge: UndirectedEdge(Int.random(in: 0 ..< 9, using: &rng), Int.random(in: 0 ..< 9, using: &rng))) }
        if holes & 1 != 0 { graph.remove(3) }
        if holes & 2 != 0 { for _ in 0 ..< 5 { graph.remove(edgeAt: Array(graph.edges.indices).randomElement(using: &rng)!) } }
        let vertexNumbers = Dictionary(uniqueKeysWithValues: Array(graph.vertices).enumerated().map { ($1, $0) })
        let edgeNumbers = Dictionary(uniqueKeysWithValues: Array(graph.edges.indices).enumerated().map { ($1, $0) })
        var neighbors: [Int] = [], edges: [Int] = [], offsets = [0]
        for v in graph.vertices {
            for p in graph.incidentEdges(of: v) {
                neighbors.append(vertexNumbers[graph.oppositeVertex(to: v, acrossEdgeAt: p)]!)
                edges.append(edgeNumbers[p]!)
            }
            offsets.append(neighbors.count)
        }
        for rows in [graph._numberedIncidenceRows(), Forwarding(base: graph)._numberedIncidenceRows()] {
            #expect(rows.offsets == offsets)
            #expect(rows.neighbors == neighbors)
            #expect(rows.edges == edges)
            for (position, v) in zip(graph.vertices.indices, graph.vertices) { #expect(rows.numbers[position] == vertexNumbers[v]) }
        }
        // The lent rows exist exactly when there are no holes.
        #expect((graph._withIncidentIndexRows { _, _, _, _ in () } != nil) == (holes == 0))
    }

    @Test("Algorithms on the numbered rows agree with the compacted copy, and the default rows give the same answers", arguments: 0 ..< 6)
    func algorithmsOnNumberedRows(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(46 + seed))
        let n = 12 + seed * 3
        var graph = StableUndirectedGraph<Int>(vertices: 0 ..< n)
        for _ in 0 ..< n * 2 { graph.insert(edge: UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
        // Edge holes only on even seeds, vertex holes too on odd ones.
        for p in Array(graph.edges.indices) where Int.random(in: 0 ..< 4, using: &rng) == 0 { graph.remove(edgeAt: p) }
        if seed % 2 == 1 { for v in 0 ..< n where Int.random(in: 0 ..< 4, using: &rng) == 0 { graph.remove(v) } }
        #expect((graph.vertexIndexBound == nil) == (seed % 2 == 1))
        let compacted = Pseudograph(graph)
        let positions = Array(graph.edges.indices)
        let wrapped = Forwarding(base: graph)
        for candidate in [graph.connectedComponents().map { Array($0) }, wrapped.connectedComponents().map { Array($0) }] {
            #expect(candidate == compacted.connectedComponents().map { Array($0) })
        }
        #expect(graph.bridges() == compacted.bridges().map { positions[$0] })
        #expect(wrapped.bridges() == compacted.bridges().map { positions[$0] })
        #expect(graph.articulationPoints() == compacted.articulationPoints())
        #expect(wrapped.articulationPoints() == compacted.articulationPoints())
        #expect(graph.biconnectedComponents().map { Set($0) } == compacted.biconnectedComponents().map { Set($0.map { positions[$0] }) })
        #expect(graph.isConnected == compacted.isConnected)
    }

    @Test("SparselyIndexedGraph's laws: the bounds are the end indices, positions and liveness agree with the collections")
    func sparseLaws() {
        var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(2, 3)])
        graph.remove(1)
        graph.insert(edge: UndirectedEdge(3, 0))
        #expect(graph.vertexPositionBound == graph.vertices.endIndex && graph.edgePositionBound == graph.edges.endIndex)
        for p in -1 ... graph.vertexPositionBound + 1 {
            #expect(graph.containsVertex(atPosition: p) == graph.vertices.indices.contains(p))
        }
        for p in -1 ... graph.edgePositionBound + 1 {
            #expect(graph.containsEdge(atPosition: p) == graph.edges.indices.contains(p))
        }
        for v in graph.vertices {
            #expect(graph.vertex(atPosition: graph.vertexPosition(of: v)) == v)
            #expect(graph.vertices[graph.vertexPosition(of: v)] == v)
        }
        // Without holes the bounds are the dense indices.
        let dense = StableUndirectedGraph(edges: [UndirectedEdge(0, 1)])
        #expect(dense.vertexPositionBound == dense.vertexIndexBound && dense.edgePositionBound == dense.edgeIndexBound)
    }
}
