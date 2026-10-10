// Conventions the catalog rows do not isolate: equality of the four results on their values,
// `Sendable`, descriptions, each result's own copy of the graph, generic code over `some
// DirectedGraph` and `some Graph`, string and hash-colliding vertices, other capacity types
// (Int32, UInt16, Float), an undirected graph against its `directed` view (each edge two arcs of
// the same capacity: the same value, the same cut sides, the same global cut value and
// connectivity), self-loops never asked for a capacity even when the closure would trap,
// `minimumCostMaximumFlow` with zero costs, the Gomory–Hu tree's symmetric lookups, `flowMap`, the
// signed flow of an undirected edge, cut sides indexed from zero, and unsigned minimum-cost
// capacities. Expected values are catalog rows or worked out in each test's comments. See
// README.md.

import AdjacencyListModule
import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Flows results and conventions", .tags(.conformance))
struct FlowsConformanceTests {
    @Test("Flow, Cut, MinimumCostFlow and GomoryHuTree compare equal on equal inputs and differ when a capacity differs")
    func equality() {
        // CLRS figure 26.1 (FL-086): value 23.
        let clrs = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"], edges: [
            DirectedEdge(from: "s", to: "v1"), DirectedEdge(from: "s", to: "v2"), DirectedEdge(from: "v1", to: "v3"),
            DirectedEdge(from: "v2", to: "v1"), DirectedEdge(from: "v2", to: "v4"), DirectedEdge(from: "v3", to: "v2"),
            DirectedEdge(from: "v3", to: "t"), DirectedEdge(from: "v4", to: "v3"), DirectedEdge(from: "v4", to: "t"),
        ])
        let capacities = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let other = [16, 13, 12, 4, 14, 9, 20, 7, 5]
        let first = clrs.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
        let again = clrs.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
        let changed = clrs.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { other[$0] })
        #expect(first == again)
        #expect(first != changed)
        #expect(first.minimumCut == clrs.minimumCut(from: "s", to: "t", capacity: { capacities[$0] }))
        #expect(first.minimumCut != changed.minimumCut)
        // The same graph's other direction: another source and sink, so another flow.
        #expect(first != clrs.edmondsKarpMaximumFlow(from: "s", to: "v3", capacity: { capacities[$0] }))
        // Two cuts of the same value 2 on the path 0→1→2: capacities 2, 3 cut the first edge, 3, 2 the
        // second, so their sides and edges differ.
        let twoEdges = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let firstEdgeCut = twoEdges.minimumCut(from: 0, to: 2, capacity: { [2, 3][$0] })
        let secondEdgeCut = twoEdges.minimumCut(from: 0, to: 2, capacity: { [3, 2][$0] })
        #expect(firstEdgeCut.value == secondEdgeCut.value && firstEdgeCut != secondEdgeCut)

        // FL-275, NetworkX's min-cost example: cost 24.
        let network = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "b", to: "d"), DirectedEdge(from: "c", to: "d"),
        ])
        let mcfCapacities = [4, 10, 9, 5], costs = [3, 6, 1, 2]
        let supply: [String: Int] = ["a": 5, "d": -5]
        let cheapest = network.minimumCostFlow(supply: { supply[$0] ?? 0 }, capacity: { mcfCapacities[$0] }, cost: { costs[$0] })
        let cheapestAgain = network.minimumCostFlow(supply: { supply[$0] ?? 0 }, capacity: { mcfCapacities[$0] }, cost: { costs[$0] })
        #expect(cheapest != nil && cheapest == cheapestAgain)
        #expect(cheapest?.cost == 24)
        let dearer = network.minimumCostFlow(supply: { supply[$0] ?? 0 }, capacity: { mcfCapacities[$0] }, cost: { $0 == 0 ? 4 : costs[$0] })
        #expect(dearer != nil && cheapest != dearer)

        // FL-262, a path with capacities 3, 1, 2.
        let path = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let pathCapacities = [3, 1, 2]
        let tree = path.gomoryHuTree(capacity: { pathCapacities[$0] })
        #expect(tree != nil && tree == path.gomoryHuTree(capacity: { pathCapacities[$0] }))
        #expect(tree != path.gomoryHuTree(capacity: { pathCapacities[$0] + 1 }))
    }

    @Test("The results are Sendable when their graphs, vertices, positions and values are")
    func sendable() {
        func requireSendable<T: Sendable>(_: T) {}
        let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let flow = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 })
        requireSendable(flow)
        requireSendable(flow.minimumCut)
        requireSendable(graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 1 }, cost: { _ in 1 }))
        let undirected = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        requireSendable(undirected.maximumFlow(from: 0, to: 1, capacity: { _ in 5 }))
        requireSendable(undirected.gomoryHuTree(capacity: { _ in 5 }))
        #expect(flow.value == 5)
    }

    @Test("Every result has a nonempty description")
    func descriptions() {
        let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let flow = graph.maximumFlow(from: 0, to: 1, capacity: { _ in 5 })
        #expect(!flow.description.isEmpty)
        #expect(!flow.minimumCut.description.isEmpty)
        let cheapest = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 1 }, cost: { _ in 1 })
        #expect(cheapest.map { !$0.description.isEmpty } == true)
        let undirected = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let tree = undirected.gomoryHuTree(capacity: { _ in 5 })
        #expect(tree.map { !$0.description.isEmpty } == true)
    }

    @Test("A result keeps its own copy of the graph: later mutations change nothing it reports")
    func ownCopy() {
        // 0→1 (3), 1→2 (2): value 2, cut at 1→2 (FL-036's shape).
        var graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let capacities = [3, 2]
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        let cut = graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] })
        let cheapest = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { _ in 1 })
        _ = graph.insert(edge: DirectedEdge(from: 0, to: 2))
        _ = graph.insert(3)
        #expect(flow.value == 2)
        #expect([0, 1].map { flow.flow(ofEdgeAt: $0) } == [2, 2])
        #expect(Array(flow.minimumCut.sourceSide) == [0, 1] && Array(flow.minimumCut.sinkSide) == [2])
        #expect(cut.edges == [1] && Array(cut.sinkSide) == [2])
        #expect(cheapest.cost == 4 && [0, 1].map { cheapest.flow(ofEdgeAt: $0) } == [2, 2])

        var undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let tree = undirected.gomoryHuTree(capacity: { capacities[$0] })!
        _ = undirected.insert(edge: UndirectedEdge(0, 2))
        #expect(tree.minimumCutValue(between: 0, and: 2) == 2)
        #expect(tree.minimumCut(between: 0, and: 2).edges.map(\.position) == [1])
    }

    @Test("Generic code over some DirectedGraph and some Graph sees the same results as concrete code")
    func genericCode() {
        func directedValue(_ graph: some DirectedGraph<Int>, _ capacity: [Int]) -> Int {
            graph.maximumFlowValue(from: 0, to: 3, capacity: { capacity[graph.edgeIndex(of: $0)] })
        }
        func undirectedLambda(_ graph: some Graph<Int>) -> Int { graph.edgeConnectivity() }
        // FL-106's diamond: value 2.
        let diamond = AdjacencyList<Int>(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
        ])
        #expect(directedValue(diamond, [1, 1, 1, 1]) == 2)
        #expect(directedValue(diamond, [1, 1, 1, 1]) == diamond.maximumFlowValue(from: 0, to: 3, capacity: { _ in 1 }))
        // C(5): λ = 2 (FL-361).
        let cycle = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        #expect(undirectedLambda(cycle) == 2)
        #expect(undirectedLambda(cycle) == cycle.edgeConnectivity())
    }

    @Test("String vertices and hash-colliding vertices give the catalog's results (FL-086 and FL-240)")
    func vertexTypes() {
        // CLRS figure 26.1 on Collider vertices whose hashes all collide: value 23, sink side {v3, t}.
        let vertices = (0 ..< 6).map { Collider($0, hash: 7) }
        let pairs = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
        let capacities = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let colliding = AdjacencyList<Collider>(vertices: vertices, edges: pairs.map { DirectedEdge(from: vertices[$0.0], to: vertices[$0.1]) })
        let flow = colliding.maximumFlow(from: vertices[0], to: vertices[5], capacity: { capacities[$0] })
        #expect(flow.value == 23)
        #expect(Array(flow.minimumCut.sinkSide) == [vertices[3], vertices[5]])
        #expect(flow.minimumCut.edges == [2, 7, 8])
        // The Stoer–Wagner paper's graph with String vertices: value 4, sink side {3, 4, 7, 8} (FL-240).
        let swPairs = [("1", "2"), ("1", "5"), ("2", "3"), ("2", "5"), ("2", "6"), ("3", "4"), ("3", "7"), ("4", "7"), ("4", "8"), ("5", "6"), ("6", "7"), ("7", "8")]
        let swCapacities = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        let paper = UndirectedAdjacencyList<String>(vertices: (1 ... 8).map { String($0) }, edges: swPairs.map { UndirectedEdge($0.0, $0.1) })
        let cut = paper.minimumCut(capacity: { swCapacities[$0] })
        #expect(cut?.value == 4)
        #expect(cut.map { Array($0.sinkSide) } == ["3", "4", "7", "8"])
    }

    @Test("Other capacity types: Int32, UInt16 and Float give the Int results (FL-086, FL-146 scaled)")
    func capacityTypes() {
        let clrs = AdjacencyList<Int>(vertices: 0 ..< 6, edges: [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let capacities = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let asInt = clrs.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] })
        let asInt32 = clrs.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { Int32(capacities[$0]) })
        let asUInt16 = clrs.maximumFlow(from: 0, to: 5, capacity: { UInt16(capacities[$0]) })
        let asFloat = clrs.dinicMaximumFlow(from: 0, to: 5, capacity: { Float(capacities[$0]) })
        #expect(asInt32.value == 23 && asUInt16.value == 23 && asFloat.value == 23)
        #expect((0 ..< 9).map { Int(asInt32.flow(ofEdgeAt: $0)) } == (0 ..< 9).map { asInt.flow(ofEdgeAt: $0) })
        #expect(Array(asUInt16.minimumCut.sinkSide) == Array(asInt.minimumCut.sinkSide))
        #expect(asFloat.minimumCut.edges == asInt.minimumCut.edges)
        // FL-146 in Float: dyadic capacities, exact; value 1.125.
        let dyadic = AdjacencyList<Int>(vertices: 0 ..< 4, edges: [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let fractions: [Float] = [0.5, 0.75, 0.25, 1.0, 0.125]
        #expect(dyadic.maximumFlowValue(from: 0, to: 3, capacity: { fractions[$0] }) == 1.125)
    }

    @Test("An undirected graph and its directed view (each edge two arcs of its capacity): the same value and cut sides, the same global cut value, the same connectivity")
    func undirectedAgainstDirectedView() {
        // The Wikipedia Gomory–Hu graph (FL-194, FL-242).
        let pairs = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        for s in 0 ..< 6 {
            for t in 0 ..< 6 where t != s {
                let undirected = graph.minimumCut(from: s, to: t, capacity: { capacities[$0] })
                let directed = view.minimumCut(from: s, to: t, capacity: { capacities[$0.position] })
                #expect(undirected.value == directed.value, "\(s) → \(t)")
                #expect(Array(undirected.sourceSide) == Array(directed.sourceSide), "\(s) → \(t)")
                #expect(undirected.edges == directed.edges, "\(s) → \(t)")
                #expect(graph.edgeConnectivity(from: s, to: t) == view.edgeConnectivity(from: s, to: t), "\(s) → \(t)")
                #expect(graph.vertexConnectivity(from: s, to: t) == view.vertexConnectivity(from: s, to: t), "\(s) → \(t)")
            }
        }
        #expect(graph.minimumCut(capacity: { capacities[$0] })?.value == 6)
        #expect(view.minimumCut(capacity: { capacities[$0.position] })?.value == 6)
        #expect(graph.edgeConnectivity() == view.edgeConnectivity())
        #expect(graph.vertexConnectivity() == view.vertexConnectivity())
    }

    @Test("Self-loops are never asked for a capacity by any maximum-flow, cut or Gomory–Hu entry point")
    func loopsNeverAsked() {
        // FL-061's graph: loops 0→0 and 1→1 beside 0→1 (4). The closure records what it is asked and
        // answers −1 (a negative capacity, which would trap) for a loop.
        let graph = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        var asked: [Int] = []
        let capacity: (Int) -> Int = { position in
            asked.append(position)
            return position == 1 ? 4 : -1
        }
        #expect(graph.maximumFlowValue(from: 0, to: 1, capacity: capacity) == 4)
        #expect(graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: capacity).flow(ofEdgeAt: 0) == 0)
        #expect(graph.dinicMaximumFlow(from: 0, to: 1, capacity: capacity).flow(ofEdgeAt: 2) == 0)
        #expect(graph.maximumFlow(from: 0, to: 1, capacity: capacity).value == 4)
        #expect(graph.minimumCut(from: 0, to: 1, capacity: capacity).edges == [1])
        #expect(graph.minimumCut(capacity: capacity)?.value == 0)
        let undirected = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(undirected.maximumFlowValue(from: 0, to: 1, capacity: capacity) == 4)
        #expect(undirected.minimumCut(capacity: capacity)?.value == 4)
        #expect(undirected.gomoryHuTree(capacity: capacity)?.capacity(ofEdgeAt: 0) == 4)
        #expect(!asked.isEmpty && asked.allSatisfy { $0 == 1 })
    }

    @Test("minimumCostMaximumFlow with zero costs: the maximum flow value at cost 0; the value is always maximumFlowValue's")
    func minimumCostMaximumFlowZeroCosts() {
        // FL-096's Ford–Fulkerson network: value 2000.
        let graph = AdjacencyList<String>(vertices: ["s", "a", "b", "t"], edges: [
            DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "s", to: "b"), DirectedEdge(from: "a", to: "b"),
            DirectedEdge(from: "a", to: "t"), DirectedEdge(from: "b", to: "t"),
        ])
        let capacities = [1000, 1000, 1, 1000, 1000]
        let free = graph.minimumCostMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }, cost: { _ in 0 })
        #expect(free.value == 2000 && free.cost == 0)
        #expect(free.value == graph.maximumFlowValue(from: "s", to: "t", capacity: { capacities[$0] }))
        // With the cross edge a→b at cost −5: every maximum flow saturates s→b and b→t, so a→b
        // carries nothing however cheap it is (the maximum comes first); cost 4 · 1000.
        let costs = [1, 1, -5, 1, 1]
        let priced = graph.minimumCostMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(priced.value == 2000)
        #expect(priced.flow(ofEdgeAt: 2) == 0)
        #expect(priced.cost == 4000)
    }

    @Test("A Gomory–Hu tree's lookups: minimumCutValue(between:and:) is symmetric; minimumCut(between:and:) has u on its source side and the s–t minimum cut's value")
    func gomoryHuSymmetry() {
        // The Stoer–Wagner paper graph (FL-268).
        let pairs = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: 1 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.gomoryHuTree(capacity: { capacities[$0] })!
        for u in 1 ... 8 {
            for v in 1 ... 8 where v != u {
                #expect(tree.minimumCutValue(between: u, and: v) == tree.minimumCutValue(between: v, and: u))
                let forward = tree.minimumCut(between: u, and: v), backward = tree.minimumCut(between: v, and: u)
                #expect(forward.value == backward.value)
                #expect(forward.sourceSide.contains(u) && forward.sinkSide.contains(v))
                #expect(forward.value == graph.minimumCut(from: u, to: v, capacity: { capacities[$0] }).value)
            }
        }
    }

    @Test("A flow on DirectedPseudograph keeps parallel edges apart: each copy its own flow and its own cut entry (FL-066)")
    func parallelEdgesApart() {
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [(0, 1), (0, 1), (1, 2), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let capacities = [2, 3, 1, 9]
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        #expect((0 ..< 4).map { flow.flow(ofEdgeAt: $0) } == [2, 3, 1, 4])
        #expect(flow.minimumCut.edges == [0, 1])
        #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
    }

    @Test("flowMap: every edge's flow by edge position, in edges order, the same as flow(ofEdgeAt:), for a maximum flow (FL-066's network) and a minimum-cost flow (FL-275)")
    func flowMaps() {
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [(0, 1), (0, 1), (1, 2), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let capacities = [2, 3, 1, 9]
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
        let map = flow.flowMap
        #expect(Array(map) == [2, 3, 1, 4])
        #expect(Array(map.indices) == Array(graph.edges.indices))
        #expect(map.count == 4 && map[1] == 3 && map[3] == flow.flow(ofEdgeAt: 3))
        // FL-275: a→b 4 @3, a→c 10 @6, b→d 9 @1, c→d 5 @2; 5 from a to d at cost 24.
        let costGraph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")].map { DirectedEdge(from: $0.0, to: $0.1) })
        let costCapacities = [4, 10, 9, 5], costs = [3, 6, 1, 2]
        let supplies = ["a": 5, "d": -5]
        let cheapest = costGraph.minimumCostFlow(supply: { supplies[$0] ?? 0 }, capacity: { costCapacities[$0] }, cost: { costs[$0] })
        #expect(cheapest.map { Array($0.flowMap) } == [4, 1, 4, 1])
    }

    @Test("An undirected flow's signed flow(ofEdgeAt:) by the undirected edge's position: positive along its stored order, negative against it, the forward arc's flow less the reversed arc's (FL-164: 5 from 1 to 0 over the edge 0–1 is −5)")
    func signedUndirectedFlow() {
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let flow = graph.maximumFlow(from: 1, to: 0, capacity: { _ in 5 })
        #expect(flow.flow(ofEdgeAt: 0) == -5)
        #expect(flow.flow(ofEdgeAt: .init(position: 0, reversed: false)) == 0)
        #expect(flow.flow(ofEdgeAt: .init(position: 0, reversed: true)) == 5)
        #expect(Array(flow.flowMap) == [0, 5])
        // A path 0–1–2 used from 0: both edges along their stored order.
        let path = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
        let along = path.dinicMaximumFlow(from: 0, to: 2, capacity: { _ in 3 })
        #expect(along.flow(ofEdgeAt: 0) == 3 && along.flow(ofEdgeAt: 1) == -3)
    }

    @Test("A cut's sides are arrays from index zero: on the path 0→1→2→3 of capacity 2 (FL-031) the sink side is [3], the source side [0, 1, 2]")
    func cutSidesFromZero() {
        let graph = AdjacencyList<Int>(vertices: 0 ..< 4, edges: [(0, 1), (1, 2), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let cut = graph.minimumCut(from: 0, to: 3, capacity: { _ in 2 })
        #expect(cut.sinkSide.startIndex == 0 && cut.sinkSide[0] == 3)
        #expect(cut.sourceSide == [0, 1, 2] && cut.sourceSide[2] == 2)
    }

    @Test("minimumCostFlow and minimumCostMaximumFlow take unsigned capacities, with signed supplies and costs: FL-275 in UInt8 capacities costs 24 with the flow [4, 1, 4, 1]; one edge of capacity 3 at cost 2 in UInt carries 3 at cost 6 (FL-308)")
    func unsignedMinimumCostCapacities() {
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")].map { DirectedEdge(from: $0.0, to: $0.1) })
        let capacities: [UInt8] = [4, 10, 9, 5]
        let costs: [Int] = [3, 6, 1, 2]
        let supplies: [String: Int8] = ["a": 5, "d": -5]
        let result = graph.minimumCostFlow(supply: { supplies[$0] ?? 0 }, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(result?.cost == 24)
        #expect(result?.value == 5)
        #expect(result.map { Array($0.flowMap) } == [4, 1, 4, 1] as [UInt8])
        let edge = AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let maximum = edge.minimumCostMaximumFlow(from: 0, to: 1, capacity: { _ in UInt(3) }, cost: { _ in 2 })
        #expect(maximum.value == 3 && maximum.cost == 6 && maximum.flow(ofEdgeAt: 0) == 3)
    }

    @Test("Flow equality compares the per-edge flows: two diamonds with the same value 1 and the same cut but the flow on different routes differ")
    func flowEqualityReadsFlows() {
        // 0→1, 0→2, 1→3, 2→3; the unit route through 1 or through 2, the other closed (capacity 0).
        let graph = AdjacencyList<Int>(vertices: 0 ..< 4, edges: [(0, 1), (0, 2), (1, 3), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let throughOne = [1, 1, 1, 0], throughTwo = [1, 1, 0, 1]
        let first = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { throughOne[$0] })
        let second = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { throughTwo[$0] })
        #expect(first.value == 1 && second.value == 1)
        #expect(first.minimumCut == second.minimumCut)
        #expect(Array(first.flowMap) == [1, 0, 1, 0] && Array(second.flowMap) == [0, 1, 0, 1])
        #expect(first != second)
    }

    @Test("MinimumCostFlow equality compares the potentials: the path 0→1→2 at costs 1, 2 and at 2, 1 ships the same flow at the same cost 3, with other potentials")
    func minimumCostEqualityReadsPotentials() {
        let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let supplies = [1, 0, -1]
        let oneTwo = [1, 2], twoOne = [2, 1]
        let first = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { _ in 1 }, cost: { oneTwo[$0] })!
        let second = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { _ in 1 }, cost: { twoOne[$0] })!
        #expect(first.cost == 3 && second.cost == 3 && first.value == second.value)
        #expect(Array(first.flowMap) == [1, 1] && Array(second.flowMap) == [1, 1])
        // Equal flow, cost and value: only the potentials can tell them apart. Each solve leaves
        // both edges in its spanning tree at reduced cost zero, so potential(1) − potential(0) is
        // the first edge's cost, 1 against 2.
        let firstGap = first.potential(of: 0) - first.potential(of: 1)
        let secondGap = second.potential(of: 0) - second.potential(of: 1)
        #expect(firstGap != secondGap)
        #expect(first != second)
    }

    @Test("Float global minimum cut sums in Double: vertex 1's capacities 2²⁴ + 1 + 1 + 1 would round to 2²⁴ in Float and beat vertex 2's 2²⁴ + 2, the true minimum")
    func floatGlobalCutSumsExactly() {
        // 0 is a hub; 1 joins it by 2²⁴ and has three unit edges to 3, 4, 5, which join the hub by
        // 2²⁵ each; 2 joins the hub by 2²⁴ + 2. The least cut is 2 alone, 16777218, against 1 alone,
        // 16777219. In Float, 2²⁴ + 1 is 2²⁴ (ties to even), so summing there would pick 1.
        let pairs: [(Int, Int)] = [(0, 1), (1, 3), (1, 4), (1, 5), (0, 2), (0, 3), (0, 4), (0, 5)]
        let capacities: [Float] = [16_777_216, 1, 1, 1, 16_777_218, 33_554_432, 33_554_432, 33_554_432]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cut = graph.minimumCut(capacity: { capacities[$0] })
        #expect(cut?.value == 16_777_218)
        #expect(cut?.sinkSide == [2])
    }
}

