// Attached maps (GraphProtocols' `PropertyGraph`): a vertex map and an edge map each hold one
// value per vertex, the edge leaving `v` at position `v`, every value the map's default until it
// is set. The graph is immutable, so nothing moves a value; the tests check defaults, writes, the
// `checked` subscripts, `values(of:)`, copy-on-write, traps (in child processes), that equality,
// hashing and coding ignore maps, and the generation, stamped once and never advanced. The model
// test compares maps against dictionaries keyed by edge and vertex. See README.md.

import Foundation
import FunctionalGraphs
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("FunctionalGraph attached maps")
struct FunctionalGraphMapTests {
    @Test("A new map gives every vertex and edge its default; writes land at their position")
    func defaultsAndWrites() throws {
        // 0 → 1 → 2 → 0, 3 → 3.
        var graph = FunctionalGraph(successors: [1, 2, 0, 3])
        let weights = graph.addEdgeMap(default: 0.5)
        let names = graph.addVertexMap(of: String.self)
        #expect(graph.edges.indices.map { graph[weights, ofEdgeAt: $0] } == [0.5, 0.5, 0.5, 0.5])
        #expect(graph.vertices.map { graph[names, of: $0] } == [nil, nil, nil, nil])
        // The edge 2 → 0 is the one leaving 2.
        graph[weights, ofEdgeAt: graph.edges.firstIndex(of: DirectedEdge(from: 2, to: 0))!] = 4
        graph[names, of: 3] = "fixed point"
        graph[names, ofVertexAt: 0] = "zero"
        #expect(graph.edges.indices.map { graph[weights, ofEdgeAt: $0] } == [0.5, 0.5, 4, 0.5])
        #expect(graph[names, ofVertexAt: 3] == "fixed point" && graph[names, of: 0] == "zero")
        #expect(try graph[weights, checkedEdgeAt: 2] == 4)
        #expect(try graph[names, checked: 3] == "fixed point")
        #expect(try graph[names, checkedVertexAt: 1] == nil)
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 4] }
        #expect(throws: VertexNotFound.self) { try graph[names, checkedVertexAt: -1] }
        #expect(throws: VertexNotFound.self) { try graph[names, checked: 4] }

        // values(of:) by position, as a snapshot; a weight closure reads it.
        let w = graph.values(of: weights)
        #expect(graph.vertices.map { w[graph.outEdges(of: $0).first!] } == [0.5, 0.5, 4, 0.5])
        #expect(w.defaultValue == 0.5 && graph.values(of: names)[3] == "fixed point")
        graph[weights, ofEdgeAt: 0] = 1
        #expect(w[0] == 0.5 && graph.values(of: weights)[0] == 1)

        // Removing a map keeps the others.
        let extra = graph.addVertexMap(default: 7)
        graph.removeVertexMap(names)
        #expect(graph[extra, of: 2] == 7)
        graph.removeEdgeMap(weights)
        let again = graph.addEdgeMap(default: 1)
        #expect(graph[again, ofEdgeAt: 2] == 1)
    }

    @Test("A copy shares the maps until either writes", .tags(.copyOnWrite))
    func copiesAreIndependent() {
        var graph = FunctionalGraph(successors: [1, 0])
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: 0] = 3
        var copy = graph
        copy[weights, ofEdgeAt: 0] = 5
        graph[weights, ofEdgeAt: 1] = 6
        #expect(graph[weights, ofEdgeAt: 0] == 3 && graph[weights, ofEdgeAt: 1] == 6)
        #expect(copy[weights, ofEdgeAt: 0] == 5 && copy[weights, ofEdgeAt: 1] == 0)
    }

    @Test("Equality, hashing and coding ignore maps and the generation")
    func conformancesIgnoreMaps() throws {
        let plain = FunctionalGraph(successors: [1, 1])
        var mapped = plain
        let labels = mapped.addVertexMap(default: "x")
        mapped[labels, of: 0] = "y"
        #expect(mapped == plain && mapped.hashValue == plain.hashValue && mapped.description == plain.description)
        // Sorted keys: a keyed container's order is otherwise not deterministic.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(mapped)
        #expect(encoded == (try encoder.encode(plain)))
        let decoded = try JSONDecoder().decode(FunctionalGraph.self, from: encoded)
        #expect(decoded == plain && !decoded.generation.isCurrent(for: plain))
    }

    @Test("Generations: every initializer stamps one; copies share it; maps keep it")
    func generations() throws {
        let rebuilt = FunctionalGraph(successors: [1, 1])
        let built: [FunctionalGraph] = [
            FunctionalGraph(successors: []),
            FunctionalGraph(successors: [1, 1]),
            FunctionalGraph(vertexCount: 2) { _ in 1 },
            FunctionalGraph(rebuilt)!,
            try JSONDecoder().decode(FunctionalGraph.self, from: JSONEncoder().encode(FunctionalGraph(successors: [0]))),
        ]
        for (k, graph) in built.enumerated() {
            #expect(graph.generation.isCurrent(for: graph), "\(k)")
            for (j, other) in built.enumerated() where j != k {
                #expect(!graph.generation.isCurrent(for: other), "\(k) against \(j)")
            }
        }
        var graph = built[1]
        let before = graph.generation
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: 1] = 2
        #expect(before.isCurrent(for: graph) && graph == built[2])
    }

    @Test("Reading or writing outside the graph traps, and a handle from another graph traps", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            var graph = FunctionalGraph(successors: [0, 0])
            let weights = graph.addEdgeMap(default: 0)
            _ = graph[weights, ofEdgeAt: 2]
        }
        await #expect(processExitsWith: .failure) {
            var graph = FunctionalGraph(successors: [0, 0])
            let weights = graph.addEdgeMap(default: 0)
            graph[weights, ofEdgeAt: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = FunctionalGraph(successors: [0, 0])
            let labels = graph.addVertexMap(default: 0)
            _ = graph[labels, ofVertexAt: 2]
        }
        await #expect(processExitsWith: .failure) {
            var graph = FunctionalGraph(successors: [0, 0])
            let labels = graph.addVertexMap(default: 0)
            graph[labels, of: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = FunctionalGraph(successors: [0, 0])
            let labels = graph.addVertexMap(default: 0)
            _ = FunctionalGraph(successors: [0, 0])[labels, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = FunctionalGraph(successors: [0, 0])
            let weights = graph.addEdgeMap(default: 0)
            graph.removeEdgeMap(weights)
            _ = graph.values(of: weights)
        }
        // Without the faults: the same calls succeed.
        var graph = FunctionalGraph(successors: [0, 0])
        let weights = graph.addEdgeMap(default: 0)
        let labels = graph.addVertexMap(default: 0)
        graph[weights, ofEdgeAt: 1] = 1
        graph[labels, of: 1] = 2
        #expect(graph[weights, ofEdgeAt: 1] == 1 && graph[labels, ofVertexAt: 1] == 2)
    }

    @Test("Maps agree with dictionaries keyed by edge and vertex under random writes", .tags(.randomized))
    func modelOfMaps() async {
        let successors = Gen.int(in: 0 ... 9).array(of: 1 ... 10)
        let writes = zip(Gen.int(in: 0 ... 40), Gen.int(in: -5 ... 5)).array(of: 0 ... 30)
        await propertyCheck(count: 200, input: successors, writes) { raw, writes in
            let n = raw.count
            var graph = FunctionalGraph(successors: raw.map { $0 % n })
            let weights = graph.addEdgeMap(default: 0)
            let labels = graph.addVertexMap(of: Int.self)
            var weightOf: [DirectedEdge<Int>: Int] = [:]
            var labelOf: [Int: Int] = [:]
            var copies: [(FunctionalGraph, [DirectedEdge<Int>: Int], [Int: Int])] = []
            for (k, (target, value)) in writes.enumerated() {
                let v = target % n
                if k % 2 == 0 {
                    graph[weights, ofEdgeAt: graph.outEdges(of: v).first!] = value
                    weightOf[DirectedEdge(from: v, to: graph.successor(of: v))] = value
                } else {
                    graph[labels, of: v] = value
                    labelOf[v] = value
                }
                if k % 5 == 0 { copies.append((graph, weightOf, labelOf)) }
            }
            copies.append((graph, weightOf, labelOf))
            for (copy, weightOf, labelOf) in copies {
                let w = copy.values(of: weights)
                for p in copy.edges.indices {
                    #expect(copy[weights, ofEdgeAt: p] == weightOf[copy.edges[p], default: 0] && w[p] == weightOf[copy.edges[p], default: 0])
                }
                for v in 0 ..< n { #expect(copy[labels, of: v] == labelOf[v]) }
            }
        }
    }
}
