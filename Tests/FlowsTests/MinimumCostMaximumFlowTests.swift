// `minimumCostMaximumFlow(from:to:capacity:cost:)` (catalog §MinimumCostMaximumFlow): the maximum
// flow value and the least cost among maximum flows, circulations included; the flow where unique;
// feasibility and the potentials' certificate, checked here. Directed rows are `AdjacencyList`, or
// `DirectedPseudograph` when an edge repeats; undirected rows `UndirectedAdjacencyList`, or
// `Pseudograph` with parallel edges; each built by inserting the row's vertices, then its edges in
// order, so positions are the catalog's. In-test checks number vertices by their index in
// `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's
// models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("minimumCostMaximumFlow(from:to:capacity:cost:)")
struct MinimumCostMaximumFlowTests {
    @Test("FL-308 one edge: value 3; cost 6; flow [3]")
    func fl308() {
        // V [0, 1]; E [0→1 3 @2]; minimumCostMaximumFlow(from: 0, to: 1, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [2]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 3)
        #expect(flowResult.cost == 6)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 1, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [3] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-309 no path: value 0, cost 0: value 0; cost 0; flow [0]")
    func fl309() {
        // V [0, 1, 2]; E [0→1 3 @2]; minimumCostMaximumFlow(from: 0, to: 2, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [2]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 0)
        #expect(flowResult.cost == 0)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 2, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-310 cheaper of two routes first: value 4; cost 16; flow [2, 2, 2, 2]")
    func fl310() {
        // V [0, 1, 2, 3]; E [0→1 2 @1, 0→2 2 @3, 1→3 2 @1, 2→3 2 @3]; minimumCostMaximumFlow(from: 0, to: 3, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [2, 2, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 3, 1, 3]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 4)
        #expect(flowResult.cost == 16)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 3, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 2, 2, 2] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-311 maximum before cheap: the dear edge is still used: value 6; cost 110; flow [1, 5, 5]")
    func fl311() {
        // V [0, 1, 2]; E [0→2 1 @100, 0→1 5 @1, 1→2 5 @1]; minimumCostMaximumFlow(from: 0, to: 2, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
        let capacities: [Int] = [1, 5, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [100, 1, 1]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 6)
        #expect(flowResult.cost == 110)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 2, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 5, 5] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-312 CLRS figure 26.1 with unit costs: value 23; cost 76; flow [12, 11, 12, 0, 11, 0, 19, 7, 4]")
    func fl312() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16 @1, s→v2 13 @1, v1→v3 12 @1, v2→v1 4 @1, v2→v4 14 @1, v3→v2 9 @1, v3→t 20 @1, v4→v3 7 @1, v4→t 4 @1]; minimumCostMaximumFlow(from: s, to: t, capacity:cost:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        let flowResult = graph.minimumCostMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 23)
        #expect(flowResult.cost == 76)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: "s", to: "t", capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-313 negative cycle off the path is saturated: NetworkX max_flow_min_cost too: value 1; cost -3; flow [1, 2, 2]")
    func fl313() {
        // V [0, 1, 2, 3]; E [0→3 1 @1, 1→2 2 @-1, 2→1 2 @-1]; minimumCostMaximumFlow(from: 0, to: 3, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
        let capacities: [Int] = [1, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, -1, -1]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 1)
        #expect(flowResult.cost == -3)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 3, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 2, 2] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-314 negative self-loop: value 2; cost -2; flow [2, 4]")
    func fl314() {
        // V [0, 1]; E [0→1 2 @1, 1→1 4 @-1]; minimumCostMaximumFlow(from: 0, to: 1, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let capacities: [Int] = [2, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, -1]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 2)
        #expect(flowResult.cost == -2)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 1, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 4] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-315 parallel edges: value 3; cost 7; flow [1, 2, 3]")
    func fl315() {
        // V [0, 1, 2]; E [0→1 2 @5, 0→1 2 @1, 1→2 3 @0]; minimumCostMaximumFlow(from: 0, to: 2, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let capacities: [Int] = [2, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [5, 1, 0]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 3)
        #expect(flowResult.cost == 7)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 2, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 2, 3] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-316 cancel along a reverse arc: value 2; cost 12; flow [1, 1, 0, 1, 1]")
    func fl316() {
        // V [0, 1, 2, 3]; E [0→1 1 @1, 0→2 1 @5, 1→2 1 @1, 1→3 1 @5, 2→3 1 @1]; minimumCostMaximumFlow(from: 0, to: 3, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 5, 1, 5, 1]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 2)
        #expect(flowResult.cost == 12)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 3, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 1, 0, 1, 1] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-317 lcgcost(8,24,21,5,0,9)")
    func fl317() {
        // lcgcost(8,24,21,5,0,9); minimumCostMaximumFlow(from: 0, to: 7, capacity:cost:)
        let pairs: [(Int, Int)] = [(3, 5), (1, 4), (7, 4), (4, 7), (4, 0), (6, 4), (0, 5), (7, 2), (7, 2), (1, 7), (2, 7), (5, 2), (5, 2), (3, 1), (5, 3), (7, 0), (0, 3), (0, 4), (1, 3), (3, 6), (4, 7), (1, 4), (3, 5), (3, 5)]
        let capacities: [Int] = [4, 2, 4, 5, 3, 3, 2, 3, 3, 2, 4, 2, 5, 2, 4, 4, 4, 4, 1, 4, 5, 3, 3, 5]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [6, 2, 0, 0, 7, 6, 1, 8, 8, 0, 1, 5, 9, 4, 8, 8, 7, 6, 6, 0, 4, 6, 8, 7]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 10)
        #expect(flowResult.cost == 90)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 7, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0, 0, 5, 0, 2, 2, 0, 0, 2, 2, 2, 0, 2, 0, 0, 4, 4, 0, 2, 1, 0, 0, 0] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-318 lcgcost(10,30,17,5,-3,9)")
    func fl318() {
        // lcgcost(10,30,17,5,-3,9); minimumCostMaximumFlow(from: 0, to: 9, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (5, 7), (0, 5), (6, 2), (1, 0), (8, 2), (2, 6), (0, 5), (0, 3), (0, 7), (4, 3), (0, 2), (7, 6), (9, 3), (8, 7), (5, 7), (7, 0), (1, 8), (9, 7), (3, 7), (6, 1), (0, 8), (9, 0), (4, 5), (2, 6), (5, 9), (5, 8), (8, 7), (8, 0), (1, 5)]
        let capacities: [Int] = [1, 3, 3, 5, 3, 5, 3, 5, 4, 4, 4, 5, 3, 1, 5, 1, 5, 5, 1, 3, 3, 4, 1, 4, 1, 3, 3, 4, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [7, 6, 7, 7, 5, 6, 0, 4, 7, -1, 0, -3, -1, -3, 1, 9, 3, 5, 2, 1, 5, 4, 7, 4, -1, 7, 7, 0, -3, 8]
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 9)!
        let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 3)
        #expect(flowResult.cost == 33)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 0, to: 9, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }

    @Test("FL-490 Int.max capacity against a negative arc: the value is Int.max, so the negative arc cannot be used")
    func fl490() {
        // V [1, 0]; E [0→1 3 @-2, 1→0 9223372036854775807 @0]; minimumCostMaximumFlow(from: 1, to: 0, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [3, 9223372036854775807]
        let graph = AdjacencyList<Int>(vertices: [1, 0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-2, 0]
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 0)!
        let flowResult = graph.minimumCostMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] }, cost: { costs[$0] })
        #expect(flowResult.value == 9223372036854775807)
        #expect(flowResult.cost == 0)
        // The value is the maximum flow value.
        #expect(flowResult.value == graph.maximumFlowValue(from: 1, to: 0, capacity: { capacities[$0] }))
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 9223372036854775807] as [Int])
        // The supplies of a flow of that value from the source to the sink.
        var supplies = [Int](repeating: 0, count: n)
        supplies[s] = flowResult.value
        supplies[t] = -flowResult.value
        // Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            balance[ends[k].0] += Int(flows[k])
            balance[ends[k].1] -= Int(flows[k])
        }
        #expect(balance == supplies.map { Int($0) })
        // The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.
        #expect(Int(flowResult.cost) == pairs.indices.reduce(0) { $0 + Int(flows[$1]) * Int(costs[$1]) })
        for k in pairs.indices where ends[k].0 == ends[k].1 {
            #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "self-loop \(k)")
        }
        // Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below
        // its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.
        let potentials = vertexList.map { Int(flowResult.potential(of: $0)) }
        for k in pairs.indices {
            let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]
            if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k): reduced cost \(reduced)") }
            if flows[k] > 0 { #expect(reduced <= 0, "edge \(k): reduced cost \(reduced)") }
        }
    }
}
