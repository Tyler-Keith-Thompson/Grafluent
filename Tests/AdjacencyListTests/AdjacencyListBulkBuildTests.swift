// The bulk build from sorted edges (`init(_vertexCount:sortedEdges:_:)`, what the line graph, the
// condensation and the named graphs build through) fills the edge table in one pass of distinct
// pairs, without a lookup per edge. These check every edge lookup afterwards, and that mutation
// keeps working on the table it built, at sizes on both sides of the sorted fill (a table of at
// least 2¹⁴ buckets).

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList bulk build from sorted edges")
struct AdjacencyListBulkBuildTests {
    @Test("every edge is found at its position, and non-edges are not", arguments: [0, 1, 40, 30_000])
    func directedLookups(edgeCount: Int) {
        let n = 1_000
        var pairs = Set<[Int]>()
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15 &* UInt64(edgeCount + 1)
        while pairs.count < edgeCount {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let a = Int((state >> 33) % UInt64(n))
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let b = Int((state >> 33) % UInt64(n))
            if a != b { pairs.insert([a, b]) }
        }
        let edges = pairs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }.map { DirectedEdge(from: $0[0], to: $0[1]) }
        var graph = AdjacencyList<Int>(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
        #expect(graph.edgeCount == edges.count)
        for (k, edge) in edges.enumerated() {
            #expect(graph.contains(edge: edge))
            let position = graph.edges.index(graph.edges.startIndex, offsetBy: k)
            #expect(graph.edges[position] == edge)
        }
        var missing = 0
        for a in stride(from: 0, to: n, by: 37) {
            for b in stride(from: 0, to: n, by: 41) where !pairs.contains([a, b]) {
                #expect(!graph.contains(edge: DirectedEdge(from: a, to: b)))
                missing += 1
            }
        }
        #expect(missing > 0)

        // Mutation on the bulk-built table: a repeat is rejected, removals and insertions keep
        // every remaining edge reachable.
        if let first = edges.first {
            _ = graph.insert(edge: first)
            #expect(graph.edgeCount == edges.count)
        }
        var kept = Set(edges)
        for edge in edges.enumerated().filter({ $0.offset % 3 == 0 }).map(\.element) {
            #expect(graph.remove(edge: edge) != nil)
            kept.remove(edge)
        }
        let extra = DirectedEdge(from: n - 1, to: 0)
        if !kept.contains(extra) {
            _ = graph.insert(edge: extra)
            kept.insert(extra)
        }
        #expect(graph.edgeCount == kept.count)
        for edge in edges { #expect(graph.contains(edge: edge) == kept.contains(edge)) }
        #expect(graph.contains(edge: extra))
    }

    @Test("undirected: every edge is found, and non-edges are not", arguments: [0, 1, 40, 30_000])
    func undirectedLookups(edgeCount: Int) {
        let n = 1_000
        var pairs = Set<[Int]>()
        var state: UInt64 = 0xD1B5_4A32_D192_ED03 &* UInt64(edgeCount + 1)
        while pairs.count < edgeCount {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let a = Int((state >> 33) % UInt64(n))
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let b = Int((state >> 33) % UInt64(n))
            if a != b { pairs.insert([min(a, b), max(a, b)]) }
        }
        let edges = pairs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }.map { UndirectedEdge($0[0], $0[1]) }
        var graph = UndirectedAdjacencyList<Int>(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
        #expect(graph.edgeCount == edges.count)
        for edge in edges {
            #expect(graph.contains(edge: edge))
            #expect(graph.contains(edge: UndirectedEdge(edge.v, edge.u)))
        }
        for a in stride(from: 0, to: n, by: 37) {
            for b in stride(from: 0, to: n, by: 41) where a != b && !pairs.contains([min(a, b), max(a, b)]) {
                #expect(!graph.contains(edge: UndirectedEdge(a, b)))
            }
        }
        if let first = edges.first {
            _ = graph.insert(edge: UndirectedEdge(first.v, first.u))
            #expect(graph.edgeCount == edges.count)
            #expect(graph.remove(edge: first) != nil)
            #expect(!graph.contains(edge: first))
            #expect(graph.edgeCount == edges.count - 1)
            for edge in edges.dropFirst() { #expect(graph.contains(edge: edge)) }
        }
    }
}
