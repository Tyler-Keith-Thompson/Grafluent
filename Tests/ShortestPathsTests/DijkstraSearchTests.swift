// Dijkstra's algorithm as an event sequence (`lazy.dijkstra`): a hand-traced directed graph on
// every representation, the trivial cases, self-loops, parallel edges, several sources, an
// undirected town, early stopping and value semantics, the preconditions, and property tests
// against `dijkstraShortestPaths` (the same settling order, distances and parent edges). Case IDs
// (SP-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing

/// A directed multigraph with no vertex indices, so the search numbers its vertices itself.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Dijkstra search events")
struct DijkstraSearchTests {
    @Test("SP-192 a hand-traced directed graph: every event in order, on every representation", .tags(.fixture, .selfLoops))
    func handTraced() {
        // 0→1 (4), 0→2 (1), 0→3 (9), 1→2 (0), 1→3 (5), 2→1 (2), 2→3 (4), 3→3 (5); 4 unreachable.
        let weights: [DirectedEdge<Int>: Int] = [
            DirectedEdge(from: 0, to: 1): 4, DirectedEdge(from: 0, to: 2): 1, DirectedEdge(from: 0, to: 3): 9,
            DirectedEdge(from: 1, to: 2): 0, DirectedEdge(from: 1, to: 3): 5, DirectedEdge(from: 2, to: 1): 2,
            DirectedEdge(from: 2, to: 3): 4, DirectedEdge(from: 3, to: 3): 5,
        ]
        let edges = weights.keys.sorted { ($0.source, $0.target) < ($1.source, $1.target) }
        typealias Event = DijkstraSearchEvent<Int, DirectedEdge<Int>, Int>
        let expected: [Event] = [
            .discover(0, distance: 0), .examine(0, distance: 0),
            .examineEdge(DirectedEdge(from: 0, to: 1), distance: 4), .edgeRelaxed(DirectedEdge(from: 0, to: 1), distance: 4), .discover(1, distance: 4),
            .examineEdge(DirectedEdge(from: 0, to: 2), distance: 1), .edgeRelaxed(DirectedEdge(from: 0, to: 2), distance: 1), .discover(2, distance: 1),
            .examineEdge(DirectedEdge(from: 0, to: 3), distance: 9), .edgeRelaxed(DirectedEdge(from: 0, to: 3), distance: 9), .discover(3, distance: 9),
            .finish(0, distance: 0),
            .examine(2, distance: 1),
            .examineEdge(DirectedEdge(from: 2, to: 1), distance: 3), .edgeRelaxed(DirectedEdge(from: 2, to: 1), distance: 3),
            .examineEdge(DirectedEdge(from: 2, to: 3), distance: 5), .edgeRelaxed(DirectedEdge(from: 2, to: 3), distance: 5),
            .finish(2, distance: 1),
            .examine(1, distance: 3),
            // 2 is settled: examined, nothing more.
            .examineEdge(DirectedEdge(from: 1, to: 2), distance: 3),
            .examineEdge(DirectedEdge(from: 1, to: 3), distance: 8), .edgeNotRelaxed(DirectedEdge(from: 1, to: 3), distance: 5),
            .finish(1, distance: 3),
            .examine(3, distance: 5),
            .examineEdge(DirectedEdge(from: 3, to: 3), distance: 10),
            .finish(3, distance: 5),
        ]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let search = g.lazy.dijkstra(from: 0) { weights[DirectedEdge(from: g.source(ofEdgeAt: $0), to: g.target(ofEdgeAt: $0))]! }
            let events: [Event] = search.map { event in
                switch event {
                case .discover(let v, let d): .discover(v, distance: d)
                case .examine(let v, let d): .examine(v, distance: d)
                case .examineEdge(let e, let d): .examineEdge(DirectedEdge(from: g.source(ofEdgeAt: e), to: g.target(ofEdgeAt: e)), distance: d)
                case .edgeRelaxed(let e, let d): .edgeRelaxed(DirectedEdge(from: g.source(ofEdgeAt: e), to: g.target(ofEdgeAt: e)), distance: d)
                case .edgeNotRelaxed(let e, let d): .edgeNotRelaxed(DirectedEdge(from: g.source(ofEdgeAt: e), to: g.target(ofEdgeAt: e)), distance: d)
                case .finish(let v, let d): .finish(v, distance: d)
                }
            }
            #expect(events == expected, "\(G.self)")
        }
        check(AdjacencyList(vertices: 0 ..< 5, edges: edges))
        check(CompressedSparseRow(vertexCount: 5, edges: edges))
        check(AdjacencyMatrix(vertexCount: 5, edges: edges))
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: edges))
        check(DirectedPseudograph(vertices: 0 ..< 5, edges: edges))
        check(UnindexedDigraph(vertices: Array(0 ..< 5), edges: edges))
        var stable = StableDirectedGraph(vertices: [99] + Array(0 ..< 5), edges: edges)
        stable.remove(99)
        check(stable)
    }

    @Test("SP-193 one vertex; a source alone; unreachable vertices are never reported; descriptions")
    func trivial() {
        let alone: [DijkstraSearchEvent<Int, Int, Int>] = [.discover(0, distance: 0), .examine(0, distance: 0), .finish(0, distance: 0)]
        let single = AdjacencyList(vertices: [0])
        #expect(Array(single.lazy.dijkstra(from: 0) { _ in 1 }) == alone)
        let apart = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 2)])
        #expect(Array(apart.lazy.dijkstra(from: 0) { _ in 1 }) == alone)
        let named = AdjacencyList(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let events = Array(named.lazy.dijkstra(from: "a") { _ in 2.5 })
        #expect(events.map(\.description) == [
            "discover(a, 0.0)", "examine(a, 0.0)", "examineEdge(0, 2.5)", "edgeRelaxed(0, 2.5)",
            "discover(b, 2.5)", "finish(a, 0.0)", "examine(b, 2.5)", "finish(b, 2.5)",
        ])
        #expect(events[6] == .examine("b", distance: 2.5))
        #expect(Set(events).count == 8)
    }

    @Test("SP-194 parallel edges and self-loops: the lighter copy relaxes, an equal one does not, a loop is examined only", .tags(.selfLoops))
    func parallelEdges() {
        var graph = DirectedPseudograph<Int>(vertices: 0 ..< 2)
        let loop = graph.insert(edge: DirectedEdge(from: 0, to: 0))
        let heavy = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let light = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let equal = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let weights = [loop: 0, heavy: 5, light: 2, equal: 2]
        let expected: [DijkstraSearchEvent<Int, Int, Int>] = [
            .discover(0, distance: 0), .examine(0, distance: 0),
            .examineEdge(loop, distance: 0),
            .examineEdge(heavy, distance: 5), .edgeRelaxed(heavy, distance: 5), .discover(1, distance: 5),
            .examineEdge(light, distance: 2), .edgeRelaxed(light, distance: 2),
            .examineEdge(equal, distance: 2), .edgeNotRelaxed(equal, distance: 2),
            .finish(0, distance: 0),
            .examine(1, distance: 2), .finish(1, distance: 2),
        ]
        #expect(Array(graph.lazy.dijkstra(from: 0) { weights[$0]! }) == expected)
    }

    @Test("SP-195 several sources: each discovered first at zero, in order, a repeat ignored")
    func severalSources() {
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = [3, 1, 1]
        let events = Array(graph.lazy.dijkstra(from: [3, 0, 3]) { weights[$0] })
        let first: [DijkstraSearchEvent<Int, Int, Int>] = [.discover(3, distance: 0), .discover(0, distance: 0)]
        #expect(Array(events.prefix(2)) == first)
        let settled = events.compactMap { event -> Int? in
            if case .examine(let v, _) = event { return v }
            return nil
        }
        #expect(settled.count == 4)
        #expect(Set(settled.prefix(2)) == [0, 3])
        #expect(graph.dijkstraShortestPaths(from: [3, 0]) { weights[$0] }.parentEdge(of: 1) == 1)
        #expect(Array(settled.suffix(2)) == [1, 2])
        // Equal priorities leave the queue in the order they entered it, as in dijkstraShortestPaths.
        #expect(settled.first == 3)
        #expect(events.contains(.edgeNotRelaxed(0, distance: 1)))
        let tree = graph.dijkstraShortestPaths(from: [3, 0]) { weights[$0] }
        #expect(events.contains(.examine(2, distance: tree.distance(to: 2)!)))
    }

    @Test("SP-196 an undirected town: distances from Home, arcs oriented away from the examined place, each street examined from both ends", .tags(.fixture))
    func undirectedTown() {
        let minutes: [UndirectedEdge<String>: Int] = [
            UndirectedEdge("Home", "Bakery"): 4, UndirectedEdge("Home", "Park"): 6, UndirectedEdge("Bakery", "Park"): 3,
            UndirectedEdge("Bakery", "School"): 7, UndirectedEdge("Park", "Library"): 5, UndirectedEdge("School", "Library"): 4,
            UndirectedEdge("School", "Café"): 6, UndirectedEdge("Library", "Café"): 3, UndirectedEdge("Library", "Station"): 8,
            UndirectedEdge("Café", "Station"): 5, UndirectedEdge("Park", "Market"): 6, UndirectedEdge("Market", "Station"): 4,
            UndirectedEdge("Library", "Market"): 7,
        ]
        let town = UndirectedAdjacencyList<String> {
            for street in minutes.keys { street }
        }
        let events = Array(town.lazy.dijkstra(from: "Home") { minutes[town.edges[$0]]! })
        var settled: [String: Int] = [:]
        var order: [Int] = []
        var examined: [Int: Int] = [:]
        var current = ""
        for event in events {
            switch event {
            case .examine(let v, let d):
                settled[v] = d
                order.append(d)
                current = v
            case .examineEdge(let arc, let d):
                examined[arc.position, default: 0] += 1
                // The arc leaves the place being examined.
                #expect(town.directedView.source(ofEdgeAt: arc) == current)
                #expect(d == settled[current]! + minutes[town.edges[arc.position]]!)
            default:
                break
            }
        }
        #expect(settled == ["Home": 0, "Bakery": 4, "Park": 6, "School": 11, "Library": 11, "Market": 12, "Café": 14, "Station": 16])
        #expect(order == order.sorted())
        #expect(examined.count == 13 && examined.values.allSatisfy { $0 == 2 })
        // Relaxed or not happens only from the first end: 13 streets, 13 decisions.
        let decisions = events.filter {
            switch $0 {
            case .edgeRelaxed, .edgeNotRelaxed: true
            default: false
            }
        }
        #expect(decisions.count == 13)
        let tree = town.dijkstraShortestPaths(from: "Home") { minutes[town.edges[$0]]! }
        #expect(settled.allSatisfy { tree.distance(to: $0.key) == $0.value })
    }

    @Test("SP-196 an undirected self-loop is examined from both of its ends, and nothing more", .tags(.selfLoops))
    func undirectedSelfLoop() {
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let events = Array(graph.lazy.dijkstra(from: 0) { [7, 1][$0] })
        let loopEvents = events.filter {
            switch $0 {
            case .examineEdge(let arc, _), .edgeRelaxed(let arc, _), .edgeNotRelaxed(let arc, _): arc.position == 0
            default: false
            }
        }
        #expect(loopEvents.count == graph.directedView.outEdges(of: 0).filter { $0.position == 0 }.count)
        #expect(loopEvents.allSatisfy { if case .examineEdge(_, 7) = $0 { true } else { false } })
        #expect(events.contains(.examine(1, distance: 1)))
    }

    @Test("SP-199 stopping early, iterating again, and a copy of the graph", .tags(.copyOnWrite))
    func valueSemantics() {
        var graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let search = graph.lazy.dijkstra(from: 0) { _ in 1 }
        let full = Array(search)
        #expect(full.count == 13)
        graph.insert(edge: DirectedEdge(from: 0, to: 2))
        #expect(Array(search) == full)
        var iterator = search.makeIterator()
        #expect(iterator.next() == .discover(0, distance: 0))
        #expect(iterator.next() == .examine(0, distance: 0))
        #expect(Array(search.prefix(2)) == Array(full.prefix(2)))
        #expect(graph.lazy.dijkstra(from: 0) { _ in 1 }.contains(.examineEdge(2, distance: 1)))
        var exhausted = search.makeIterator()
        while exhausted.next() != nil {}
        #expect(exhausted.next() == nil)
    }

    @Test("SP-197 a negative examined weight, a NaN weight, a missing source and no sources trap; a negative weight never examined does not", .tags(.precondition))
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            for _ in graph.lazy.dijkstra(from: 0, weight: { _ in -1 }) {}
        }
        await #expect(processExitsWith: .failure) {
            let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            for _ in graph.lazy.dijkstra(from: 0, weight: { _ in Double.nan }) {}
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2)
            _ = graph.lazy.dijkstra(from: 5) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2)
            _ = graph.lazy.dijkstra(from: [Int]()) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            for _ in graph.lazy.dijkstra(from: 0, weight: { _ in -1 }) {}
        }
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0)])
        let events = Array(graph.lazy.dijkstra(from: 0) { [1, -5][$0] })
        #expect(events.last == .finish(1, distance: 1))
    }

    @Test("SP-198 property, directed: the settling order, distances and parent edges of dijkstraShortestPaths", .tags(.randomized))
    func propertyDirected() async {
        // Up to 30 edges on vertices 0..<8 with weights 0...9; repeats and self-loops allowed.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 7)) { raw, source in
            let arcs = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String) where G.Edges.Index == Int {
                let events = Array(graph.lazy.dijkstra(from: source) { raw[$0].2 })
                let tree = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }
                var settled: [Int] = []
                var parentEdge: [Int: Int] = [:]
                var discovered = Set<Int>()
                var current = -1
                for event in events {
                    switch event {
                    case .discover(let v, let d):
                        #expect(discovered.insert(v).inserted, "\(name): \(v) discovered twice")
                        #expect(v == source ? d == 0 : d >= tree.distance(to: v)!, "\(name)")
                    case .examine(let v, let d):
                        #expect(tree.distance(to: v) == d, "\(name)")
                        #expect(discovered.contains(v))
                        settled.append(v)
                        current = v
                    case .examineEdge(let e, let d):
                        #expect(raw[e].0 == current && d == tree.distance(to: current)! + raw[e].2, "\(name)")
                    case .edgeRelaxed(let e, let d):
                        #expect(!settled.contains(raw[e].1) && d >= tree.distance(to: raw[e].1)!, "\(name)")
                        parentEdge[raw[e].1] = e
                    case .edgeNotRelaxed(let e, let d):
                        #expect(!settled.contains(raw[e].1) && d <= tree.distance(to: current)! + raw[e].2, "\(name)")
                    case .finish(let v, _):
                        #expect(v == current, "\(name)")
                    }
                }
                let reached = (0 ..< 8).filter { tree.distance(to: $0) != nil }
                let distances = settled.map { tree.distance(to: $0)! }
                #expect(Set(settled) == Set(reached) && settled.count == reached.count, "\(name)")
                #expect(distances == distances.sorted(), "\(name)")
                #expect(settled.first == source)
                for v in reached where v != source {
                    #expect(parentEdge[v] == tree.parentEdge(of: v), "\(name): \(v)")
                }
            }
            check(ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: arcs), "reference")
            check(DirectedPseudograph(vertices: 0 ..< 8, edges: arcs), "pseudograph")
        }
    }

    @Test("SP-198 property, undirected: the settling order, distances and parent edges of dijkstraShortestPaths", .tags(.randomized))
    func propertyUndirected() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 7)) { raw, source in
            let graph = ReferencePseudograph(vertices: 0 ..< 8, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let events = Array(graph.lazy.dijkstra(from: source) { raw[$0].2 })
            let tree = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }
            var settled: [Int] = []
            var parentArc: [Int: DirectedView<ReferencePseudograph<Int>>.Edges.Index] = [:]
            for event in events {
                switch event {
                case .examine(let v, let d):
                    #expect(tree.distance(to: v) == d)
                    settled.append(v)
                case .edgeRelaxed(let arc, _):
                    parentArc[graph.directedView.target(ofEdgeAt: arc)] = arc
                default:
                    break
                }
            }
            let reached = (0 ..< 8).filter { tree.distance(to: $0) != nil }
            let distances = settled.map { tree.distance(to: $0)! }
            #expect(Set(settled) == Set(reached) && settled.count == reached.count)
            #expect(distances == distances.sorted())
            for v in reached where v != source {
                #expect(parentArc[v] == tree.parentEdge(of: v), "\(v)")
            }
        }
    }
}
