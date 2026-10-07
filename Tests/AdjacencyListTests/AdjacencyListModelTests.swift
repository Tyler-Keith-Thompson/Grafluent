// Model-based randomized tests. A long random sequence of operations is applied both to an
// AdjacencyList and to a deliberately naive model (out-neighbor sets in a Dictionary); after every
// step the return values and the complete observable state must agree. Modeled on Boost.Graph's
// test/graph.cpp (seeded random operations, checked after each one) and petgraph's quickcheck
// properties (P-01, P-03, P-06). Each seed is its own reproducible test case.
//
// Each test is self-contained, so the model is written out in each.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList against a reference model", .tags(.randomized))
struct AdjacencyListModelTests {
    @Test("P-01 / P-03 / P-06 random operations on Int vertices", .timeLimit(.minutes(1)), arguments: 0 ..< 100 as Range<UInt64>)
    func intVertices(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var graph = AdjacencyList<Int>()
        var model: [Int: Set<Int>] = [:]

        for step in 0 ..< 300 {
            let u = Int.random(in: 0 ..< 12, using: &rng)
            let v = Int.random(in: 0 ..< 12, using: &rng)
            let copy: AdjacencyList<Int>? = Bool.random(using: &rng) ? graph : nil
            let modelBefore = model

            // Weighted toward edge insertion so graphs grow dense, with rare clears so they also
            // pass through empty and isolated-only states.
            switch Int.random(in: 0 ..< 100, using: &rng) {
            case 0 ..< 10:
                let result = graph.insert(u)
                #expect(result.inserted == (model[u] == nil), "step \(step): insert(\(u))")
                #expect(result.memberAfterInsert == u)
                if model[u] == nil { model[u] = [] }
            case 10 ..< 20:
                let removed = graph.remove(u)
                #expect((removed != nil) == (model[u] != nil), "step \(step): remove(\(u))")
                if model.removeValue(forKey: u) != nil {
                    for w in model.keys { model[w]!.remove(u) }
                }
            case 20 ..< 65:
                let result = graph.insert(DirectedEdge(from: u, to: v))
                #expect(result.inserted == !(model[u]?.contains(v) ?? false), "step \(step): insert(\(u)→\(v))")
                if model[u] == nil { model[u] = [] }
                if model[v] == nil { model[v] = [] }
                model[u]!.insert(v)
            case 65 ..< 95:
                let removed = graph.remove(DirectedEdge(from: u, to: v))
                #expect((removed != nil) == (model[u]?.contains(v) ?? false), "step \(step): remove(\(u)→\(v))")
                model[u]?.remove(v)
            case 95 ..< 98:
                graph.removeAllEdges(keepingCapacity: Bool.random(using: &rng))
                for w in model.keys { model[w] = [] }
            default:
                graph.removeAll(keepingCapacity: Bool.random(using: &rng))
                model = [:]
            }

            // The graph agrees with the model.
            let modelEdges = Set(model.flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } })
            #expect(Set(graph.vertices) == Set(model.keys), "step \(step)")
            #expect(graph.vertexCount == model.count, "step \(step)")
            #expect(Set(graph.edges) == modelEdges, "step \(step)")
            #expect(graph.edgeCount == modelEdges.count, "step \(step)")
            #expect(graph.edges.count == modelEdges.count, "step \(step)")
            for w in model.keys {
                let modelIn = Set(model.compactMap { source, targets in targets.contains(w) ? source : nil })
                #expect(Set(graph.successors(of: w)) == model[w], "step \(step): successors(of: \(w))")
                #expect(Set(graph.predecessors(of: w)) == modelIn, "step \(step): predecessors(of: \(w))")
                #expect(graph.outDegree(of: w) == model[w]!.count, "step \(step): outDegree(of: \(w))")
                #expect(graph.inDegree(of: w) == modelIn.count, "step \(step): inDegree(of: \(w))")
            }
            // A copy taken before the step still matches the model as it was.
            if let copy {
                #expect(Set(copy.vertices) == Set(modelBefore.keys), "step \(step): copy changed")
                #expect(Set(copy.edges) == Set(modelBefore.flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } }), "step \(step): copy changed")
            }
        }
    }

    @Test("random operations with every vertex in one hash bucket", .timeLimit(.minutes(1)), arguments: 0 ..< 25 as Range<UInt64>)
    func collidingVertices(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var graph = AdjacencyList<Collider>()
        var model: [Collider: Set<Collider>] = [:]

        for step in 0 ..< 300 {
            let u = Collider(Int.random(in: 0 ..< 12, using: &rng), hash: 0)
            let v = Collider(Int.random(in: 0 ..< 12, using: &rng), hash: 0)

            switch Int.random(in: 0 ..< 100, using: &rng) {
            case 0 ..< 10:
                #expect(graph.insert(u).inserted == (model[u] == nil), "step \(step)")
                if model[u] == nil { model[u] = [] }
            case 10 ..< 20:
                #expect((graph.remove(u) != nil) == (model[u] != nil), "step \(step)")
                if model.removeValue(forKey: u) != nil {
                    for w in model.keys { model[w]!.remove(u) }
                }
            case 20 ..< 65:
                #expect(graph.insert(DirectedEdge(from: u, to: v)).inserted == !(model[u]?.contains(v) ?? false), "step \(step)")
                if model[u] == nil { model[u] = [] }
                if model[v] == nil { model[v] = [] }
                model[u]!.insert(v)
            case 65 ..< 95:
                #expect((graph.remove(DirectedEdge(from: u, to: v)) != nil) == (model[u]?.contains(v) ?? false), "step \(step)")
                model[u]?.remove(v)
            case 95 ..< 98:
                graph.removeAllEdges()
                for w in model.keys { model[w] = [] }
            default:
                graph.removeAll()
                model = [:]
            }

            let modelEdges = Set(model.flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } })
            #expect(Set(graph.vertices) == Set(model.keys), "step \(step)")
            #expect(Set(graph.edges) == modelEdges, "step \(step)")
            #expect(graph.edgeCount == modelEdges.count, "step \(step)")
            for w in model.keys {
                let modelIn = Set(model.compactMap { source, targets in targets.contains(w) ? source : nil })
                #expect(Set(graph.successors(of: w)) == model[w], "step \(step)")
                #expect(Set(graph.predecessors(of: w)) == modelIn, "step \(step)")
            }
        }
    }

    @Test("random operations on String vertices", .timeLimit(.minutes(1)), arguments: 0 ..< 25 as Range<UInt64>)
    func stringVertices(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var graph = AdjacencyList<String>()
        var model: [String: Set<String>] = [:]

        for step in 0 ..< 300 {
            let u = "v\(Int.random(in: 0 ..< 10, using: &rng))"
            let v = "v\(Int.random(in: 0 ..< 10, using: &rng))"

            switch Int.random(in: 0 ..< 100, using: &rng) {
            case 0 ..< 10:
                #expect(graph.insert(u).inserted == (model[u] == nil), "step \(step)")
                if model[u] == nil { model[u] = [] }
            case 10 ..< 20:
                #expect((graph.remove(u) != nil) == (model[u] != nil), "step \(step)")
                if model.removeValue(forKey: u) != nil {
                    for w in model.keys { model[w]!.remove(u) }
                }
            case 20 ..< 65:
                #expect(graph.insert(DirectedEdge(from: u, to: v)).inserted == !(model[u]?.contains(v) ?? false), "step \(step)")
                if model[u] == nil { model[u] = [] }
                if model[v] == nil { model[v] = [] }
                model[u]!.insert(v)
            case 65 ..< 95:
                #expect((graph.remove(DirectedEdge(from: u, to: v)) != nil) == (model[u]?.contains(v) ?? false), "step \(step)")
                model[u]?.remove(v)
            case 95 ..< 98:
                graph.removeAllEdges()
                for w in model.keys { model[w] = [] }
            default:
                graph.removeAll()
                model = [:]
            }

            let modelEdges = Set(model.flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } })
            #expect(Set(graph.vertices) == Set(model.keys), "step \(step)")
            #expect(Set(graph.edges) == modelEdges, "step \(step)")
            for w in model.keys {
                let modelIn = Set(model.compactMap { source, targets in targets.contains(w) ? source : nil })
                #expect(Set(graph.successors(of: w)) == model[w], "step \(step)")
                #expect(Set(graph.predecessors(of: w)) == modelIn, "step \(step)")
            }
        }
    }

    @Test("growth past many reallocations", .timeLimit(.minutes(1)), arguments: 0 ..< 5 as Range<UInt64>)
    func largeUniverse(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var graph = AdjacencyList<Int>()
        var model: [Int: Set<Int>] = [:]

        for step in 0 ..< 2_000 {
            let u = Int.random(in: 0 ..< 400, using: &rng)
            let v = Int.random(in: 0 ..< 400, using: &rng)
            switch Int.random(in: 0 ..< 10, using: &rng) {
            case 0:
                #expect((graph.remove(u) != nil) == (model[u] != nil), "step \(step)")
                if model.removeValue(forKey: u) != nil {
                    for w in model.keys { model[w]!.remove(u) }
                }
            case 1, 2:
                #expect((graph.remove(DirectedEdge(from: u, to: v)) != nil) == (model[u]?.contains(v) ?? false), "step \(step)")
                model[u]?.remove(v)
            default:
                #expect(graph.insert(DirectedEdge(from: u, to: v)).inserted == !(model[u]?.contains(v) ?? false), "step \(step)")
                if model[u] == nil { model[u] = [] }
                if model[v] == nil { model[v] = [] }
                model[u]!.insert(v)
            }
        }

        // Checked once at the end; the smaller tests check after every step.
        let modelEdges = Set(model.flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } })
        #expect(Set(graph.vertices) == Set(model.keys))
        #expect(Set(graph.edges) == modelEdges)
        #expect(graph.edgeCount == modelEdges.count)
        for w in model.keys {
            let modelIn = Set(model.compactMap { source, targets in targets.contains(w) ? source : nil })
            #expect(Set(graph.successors(of: w)) == model[w])
            #expect(Set(graph.predecessors(of: w)) == modelIn)
        }
    }
}
