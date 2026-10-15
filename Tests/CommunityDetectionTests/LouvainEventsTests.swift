// The Louvain method as an event sequence (`louvainEvents`): three triangles in a chain and a ring
// of twelve triangles traced against Tests/Catalogs/CommunityDetection/cases_events.py, the
// trivial cases, directed and weighted graphs, value semantics, the preconditions, and a property
// test replaying the events against `louvainPartitions` (each level's gains add up to its rise in
// modularity). Case IDs (CD-9nn) are listed in README.md.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Louvain events")
struct LouvainEventsTests {
    @Test("CD-900 three triangles in a chain: the moves, the level and the aggregation of the reference model", .tags(.fixture))
    func chain() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (4, 5), (3, 5), (5, 6), (6, 7), (7, 8), (6, 8)]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let events = Array(graph.louvainEvents())
        // Tests/Catalogs/CommunityDetection/cases_events.out, CD-900.
        let moves: [(Int, Int, Int, Double)] = [
            (0, 0, 1, 0.0743801652892562), (2, 2, 1, 0.13223140495867769), (3, 3, 4, 0.066115702479338845),
            (5, 5, 4, 0.11983471074380166), (6, 6, 8, 0.066115702479338845), (7, 7, 8, 0.14049586776859505),
        ]
        #expect(events.count == 8)
        for (k, (u, a, b, gain)) in moves.enumerated() {
            guard case .move(let v, let from, let to, let g) = events[k] else {
                Issue.record("event \(k) is \(events[k])")
                continue
            }
            #expect(v == u && from == a && to == b && abs(g - gain) <= 1e-12, "move \(k)")
        }
        let partitions = graph.louvainPartitions()
        guard case .levelFinished(let partition, let q) = events[6] else {
            Issue.record("event 6 is \(events[6])")
            return
        }
        #expect(partition == partitions[0] && partitions.count == 1)
        #expect(partition.map { Array($0) } == [[0, 1, 2], [3, 4, 5], [6, 7, 8]])
        #expect(abs(q - 0.48347107438016523) <= 1e-12 && abs(q - graph.modularity(of: partition)) <= 1e-12)
        #expect(events[7] == .aggregate(vertexCount: 3))
        #expect(events[7].description == "aggregate(3)")
        #expect(events[0].description.hasPrefix("move(0, 0 → 1, 0.07438"))
        // The same on an adjacency list.
        let list = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(list.louvainEvents()).count == 8)
    }

    @Test("CD-901 a ring of twelve triangles: two levels, the second pairing the triangles; the last partition is louvainCommunities'", .tags(.fixture))
    func ring() {
        var pairs: [(Int, Int)] = []
        for c in 0 ..< 12 {
            let b = 3 * c
            pairs += [(b, b + 1), (b + 1, b + 2), (b, b + 2), (b + 2, (b + 3) % 36)]
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 36, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let events = Array(graph.louvainEvents())
        #expect(events.count == 34)
        let finished = events.compactMap { event -> (Partition<DirectedView<UndirectedAdjacencyList<Int>>>, Double)? in
            if case .levelFinished(let p, let q) = event { (p, q) } else { nil }
        }
        #expect(finished.map(\.0) == graph.louvainPartitions())
        #expect(finished.last?.0 == graph.louvainCommunities())
        #expect(finished.count == 2 && abs(finished[0].1 - 2.0 / 3) <= 1e-12 && abs(finished[1].1 - 0.70833333333333337) <= 1e-12)
        let aggregates = events.compactMap { event -> Int? in if case .aggregate(let k) = event { k } else { nil } }
        #expect(aggregates == [12, 6])
        // The second level's moves: level vertex 0 joins 11, then 1 → 2, 3 → 4, …, 9 → 10.
        let second = events[events.firstIndex(of: .aggregate(vertexCount: 12))! + 1 ..< events.count - 2]
        let moved = second.compactMap { event -> [Int]? in if case .move(let v, let a, let b, _) = event { [v, a, b] } else { nil } }
        #expect(moved == [[0, 0, 11], [1, 1, 2], [3, 3, 4], [5, 5, 6], [7, 7, 8], [9, 9, 10]])
    }

    @Test("CD-902 no edges: one level of singletons at modularity 0; no vertices; directed and weighted graphs agree with louvainPartitions")
    func trivial() {
        let isolated = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [])
        let events = Array(isolated.louvainEvents())
        #expect(events == [.levelFinished(isolated.louvainCommunities(), modularity: 0)])
        #expect(events[0].description.hasPrefix("levelFinished("))
        #expect(Array(UndirectedAdjacencyList<Int>(vertices: []).louvainEvents()).count == 1)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3), (1, 1)]
        let directed = AdjacencyList(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let finished = directed.louvainEvents().compactMap { event -> Partition<AdjacencyList<Int>>? in
            if case .levelFinished(let p, _) = event { p } else { nil }
        }
        #expect(finished == directed.louvainPartitions())
        let weights: [Double] = [1, 2, 1, 3, 1, 2, 0.5, 4]
        let weighted = directed.louvainEvents(weight: { weights[$0] }, resolution: 0.8).compactMap { event -> Partition<AdjacencyList<Int>>? in
            if case .levelFinished(let p, _) = event { p } else { nil }
        }
        #expect(weighted == directed.louvainPartitions(weight: { weights[$0] }, resolution: 0.8))
        let undirected = ReferencePseudograph(vertices: 0 ..< 6, edges: arcs.map { UndirectedEdge($0.0, $0.1) })
        let undirectedWeighted = undirected.louvainEvents(weight: { Float(weights[$0]) }, threshold: 0.01).compactMap { event -> Partition<DirectedView<ReferencePseudograph<Int>>>? in
            if case .levelFinished(let p, _) = event { p } else { nil }
        }
        #expect(undirectedWeighted == undirected.louvainPartitions(weight: { Float(weights[$0]) }, threshold: 0.01))
    }

    @Test("CD-903 value semantics: a later insertion does not change the events; each iterator starts over; stopping early")
    func valueSemantics() {
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let events = graph.louvainEvents()
        _ = graph.insert(edge: UndirectedEdge(1, 2))
        let first = Array(events)
        #expect(Array(events) == first)
        guard case .levelFinished(let p, _)? = first.last(where: { if case .levelFinished = $0 { true } else { false } }) else {
            Issue.record("no level finished")
            return
        }
        #expect(p.map { Array($0) } == [[0, 1], [2, 3]])
        #expect(Array(events.prefix(1)) == Array(first.prefix(1)))
        var iterator = events.makeIterator()
        for _ in first { _ = iterator.next() }
        #expect(iterator.next() == nil)
    }

    @Test("CD-904 a negative resolution, a NaN threshold, a negative weight trap when the sequence is made")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.louvainEvents(resolution: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.louvainEvents(threshold: .nan)
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.louvainEvents(weight: { _ in -1.0 })
        }
    }

    @Test("CD-905 property: the finished levels are louvainPartitions'; each level's gains add up to its rise in modularity; moves leave and join existing communities", .tags(.randomized))
    func property() async {
        // Up to 40 edges on vertices 0..<12, weights 1...4; repeats and self-loops allowed.
        let edges = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 11), Gen.int(in: 1 ... 4)).array(of: 0 ... 40)
        await propertyCheck(count: 200, input: edges) { raw in
            let undirected = ReferencePseudograph(vertices: 0 ..< 12, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let directed = AdjacencyList(vertices: 0 ..< 12, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let w: (Int) -> Double = { Double(raw[$0].2) }
            func check<G: DirectedGraph>(_ events: LouvainEvents<G>, _ partitions: [Partition<G>], _ singletons: Double, _ name: String) {
                var finished: [Partition<G>] = []
                var previous = singletons
                var gains = 0.0
                var size = 12
                for event in events {
                    switch event {
                    case .move(let v, let a, let b, let gain):
                        #expect(v < size && a < size && b < size && a != b && gain > -1e-12, "\(name)")
                        gains += gain
                    case .levelFinished(let p, let q):
                        #expect(abs(previous + gains - q) <= 1e-9, "\(name): \(previous) + \(gains) ≠ \(q)")
                        finished.append(p)
                        previous = q
                        gains = 0
                    case .aggregate(let k):
                        #expect(k == finished.last?.count, "\(name)")
                        size = k
                    }
                }
                #expect(finished == partitions, "\(name)")
            }
            let identity = Array(0 ..< 12).map { [$0] }
            if !raw.isEmpty {
                check(undirected.louvainEvents(weight: w), undirected.louvainPartitions(weight: w), undirected.modularity(of: identity, weight: w), "undirected")
                check(directed.louvainEvents(weight: w), directed.louvainPartitions(weight: w), directed.modularity(of: identity, weight: w), "directed")
            }
            check(directed.louvainEvents(resolution: 1.5), directed.louvainPartitions(resolution: 1.5), raw.isEmpty ? 0 : directed.modularity(of: identity, resolution: 1.5), "directed, γ = 1.5")
        }
    }
}
