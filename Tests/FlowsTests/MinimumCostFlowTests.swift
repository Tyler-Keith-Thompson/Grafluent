// `minimumCostFlow(supply:capacity:cost:)` (catalog §MinimumCostFlow): the least cost exactly; the
// flow exactly where it is the only optimum; feasibility, the self-loop rule and optimality by the
// potentials' reduced costs (complementary slackness), checked here; nil rows have an infeasibility
// witness found here (unbalanced supplies, or a set supplying more than its out-edges carry); the
// closures' calls. Directed rows are `AdjacencyList`, or `DirectedPseudograph` when an edge repeats;
// undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each built by
// inserting the row's vertices, then its edges in order, so positions are the catalog's. In-test
// checks number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("minimumCostFlow(supply:capacity:cost:)")
struct MinimumCostFlowTests {
    @Test("FL-275 NetworkX docs example: cost 24: cost 24; flow [4, 1, 4, 1]")
    func fl275() throws {
        // V [a, b, c, d]; E [a→b 4 @3, a→c 10 @6, b→d 9 @1, c→d 5 @2]; supply [a: 5, d: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(String, String)] = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]
        let capacities: [Int] = [4, 10, 9, 5]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "b", "c", "d"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [3, 6, 1, 2]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [5, 0, 0, -5]
        var suppliesAsked: [String] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 24)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 5)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [4, 1, 4, 1] as [Int])
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

    @Test("FL-276 no vertices: cost 0; flow []")
    func fl276() throws {
        // V []; E []; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = []
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = []
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 0)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 0)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [] as [Int])
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

    @Test("FL-277 no supply, no edges: cost 0; flow []")
    func fl277() throws {
        // V [0, 1]; E []; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = []
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [0, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 0)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 0)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [] as [Int])
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

    @Test("FL-278 no supply, positive costs: nothing moves: cost 0; flow [0, 0]")
    func fl278() throws {
        // V [0, 1]; E [0→1 3 @1, 1→0 3 @1]; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [3, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [0, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 0)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 0)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0] as [Int])
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

    @Test("FL-279 no supply, a negative cycle: saturated to capacity 2: cost -6; flow [2, 2, 2]")
    func fl279() throws {
        // V [0, 1, 2]; E [0→1 2 @1, 1→2 3 @-5, 2→0 4 @1]; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let capacities: [Int] = [2, 3, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, -5, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [0, 0, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -6)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 0)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 2, 2] as [Int])
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

    @Test("FL-280 negative self-loop saturated: cost -5; flow [3, 1]")
    func fl280() throws {
        // V [0, 1]; E [0→0 3 @-2, 0→1 1 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let capacities: [Int] = [3, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-2, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, -1]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -5)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 1)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [3, 1] as [Int])
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

    @Test("FL-281 zero-cost self-loop carries nothing: cost 1; flow [0, 1]")
    func fl281() throws {
        // V [0, 1]; E [0→0 3 @0, 0→1 1 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let capacities: [Int] = [3, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [0, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, -1]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 1)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 1)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 1] as [Int])
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

    @Test("FL-282 one edge: cost 6; flow [3]")
    func fl282() throws {
        // V [0, 1]; E [0→1 5 @2]; supply [0: 3, 1: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [2]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [3, -3]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 6)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 3)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [3] as [Int])
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

    @Test("FL-283 supply over capacity: infeasible: nil")
    func fl283() {
        // V [0, 1]; E [0→1 1 @1]; supply [0: 2, 1: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [1]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [2, -2]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-284 unbalanced supplies: nil (NetworkX: total node demand is not zero): nil")
    func fl284() {
        // V [0, 1]; E [0→1 3 @1]; supply [0: 1, 1: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, -2]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-285 unbalanced, more supply: nil")
    func fl285() {
        // V [0, 1]; E [0→1 3 @1]; supply [0: 2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [2, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-286 no path to the demand: nil")
    func fl286() {
        // V [0, 1, 2]; E [0→1 3 @1]; supply [0: 1, 2: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, 0, -1]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-287 cheaper long way: cost 8; flow [0, 4, 4]")
    func fl287() throws {
        // V [0, 1, 2]; E [0→2 5 @5, 0→1 5 @1, 1→2 5 @1]; supply [0: 4, 2: -4]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
        let capacities: [Int] = [5, 5, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [5, 1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [4, 0, -4]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 8)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 4)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 4, 4] as [Int])
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

    @Test("FL-288 cheaper long way, capacity spills: cost 14; flow [2, 2, 2]")
    func fl288() throws {
        // V [0, 1, 2]; E [0→2 5 @5, 0→1 2 @1, 1→2 5 @1]; supply [0: 4, 2: -4]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
        let capacities: [Int] = [5, 2, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [5, 1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [4, 0, -4]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 14)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 4)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 2, 2] as [Int])
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

    @Test("FL-289 ties: two equal routes: cost 4; flow [2, 0, 2, 0] (one of several optima)")
    func fl289() throws {
        // V [0, 1, 2, 3]; E [0→1 2 @1, 0→2 2 @1, 1→3 2 @1, 2→3 2 @1]; supply [0: 2, 3: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [2, 2, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 1, 1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [2, 0, 0, -2]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 4)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 2)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        // One of several optima (catalog: [2, 0, 2, 0]): the flow itself is not pinned.
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

    @Test("FL-290 parallel edges, different costs: cost 4; flow [0, 2, 1]")
    func fl290() throws {
        // V [0, 1]; E [0→1 2 @3, 0→1 2 @1, 0→1 2 @2]; supply [0: 3, 1: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 1)]
        let capacities: [Int] = [2, 2, 2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [3, 1, 2]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [3, -3]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 4)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 3)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 2, 1] as [Int])
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

    @Test("FL-291 antiparallel edges: the back edge carries nothing: cost 4; flow [2, 0]")
    func fl291() throws {
        // V [0, 1]; E [0→1 5 @2, 1→0 5 @1]; supply [0: 2, 1: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [5, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [2, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [2, -2]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 4)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 2)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 0] as [Int])
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

    @Test("FL-292 negative cost on the route: cost -2; flow [2, 2, 0]")
    func fl292() throws {
        // V [0, 1, 2]; E [0→1 3 @-2, 1→2 3 @1, 0→2 3 @0]; supply [0: 2, 2: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [Int] = [3, 3, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-2, 1, 0]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [2, 0, -2]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -2)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 2)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 2, 0] as [Int])
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

    @Test("FL-293 negative cycle beside the route: cost -3; flow [1, 2, 2]")
    func fl293() throws {
        // V [0, 1, 2, 3]; E [0→3 1 @1, 1→2 2 @-3, 2→1 2 @1]; supply [0: 1, 3: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
        let capacities: [Int] = [1, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, -3, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, 0, 0, -1]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -3)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 1)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 2, 2] as [Int])
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

    @Test("FL-294 transshipment vertex: cost 15; flow [6, 3, 3, 0]")
    func fl294() throws {
        // V [p, w, c1, c2]; E [p→w 10 @1, w→c1 10 @1, w→c2 10 @2, p→c1 2 @5]; supply [p: 6, c1: -3, c2: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(String, String)] = [("p", "w"), ("w", "c1"), ("w", "c2"), ("p", "c1")]
        let capacities: [Int] = [10, 10, 10, 2]
        let graph = AdjacencyList<String>(vertices: ["p", "w", "c1", "c2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["p", "w", "c1", "c2"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 1, 2, 5]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [6, 0, -3, -3]
        var suppliesAsked: [String] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 15)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 6)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [6, 3, 3, 0] as [Int])
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

    @Test("FL-295 two supplies, two demands (transportation): cost 28; flow [3, 0, 2, 2]")
    func fl295() throws {
        // V [s1, s2, d1, d2]; E [s1→d1 9 @4, s1→d2 9 @6, s2→d1 9 @5, s2→d2 9 @3]; supply [s1: 3, s2: 4, d1: -5, d2: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(String, String)] = [("s1", "d1"), ("s1", "d2"), ("s2", "d1"), ("s2", "d2")]
        let capacities: [Int] = [9, 9, 9, 9]
        let graph = AdjacencyList<String>(vertices: ["s1", "s2", "d1", "d2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s1", "s2", "d1", "d2"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [4, 6, 5, 3]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [3, 4, -5, -2]
        var suppliesAsked: [String] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 28)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 7)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [3, 0, 2, 2] as [Int])
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

    @Test("FL-296 assignment 3×3 as flow: scipy linear_sum_assignment cost 5: cost 5; flow [0, 1, 0, 1, 0, 0, 0, 0, 1]")
    func fl296() throws {
        // V [r0, r1, r2, c0, c1, c2]; E [r0→c0 1 @4, r0→c1 1 @1, r0→c2 1 @3, r1→c0 1 @2, r1→c1 1 @0, r1→c2 1 @5, r2→c0 1 @3, r2→c1 1 @2, r2→c2 1 @2]; supply [r0: 1, r1: 1, r2: 1, c0: -1, c1: -1, c2: -1]; min…
        let pairs: [(String, String)] = [("r0", "c0"), ("r0", "c1"), ("r0", "c2"), ("r1", "c0"), ("r1", "c1"), ("r1", "c2"), ("r2", "c0"), ("r2", "c1"), ("r2", "c2")]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<String>(vertices: ["r0", "r1", "r2", "c0", "c1", "c2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["r0", "r1", "r2", "c0", "c1", "c2"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [4, 1, 3, 2, 0, 5, 3, 2, 2]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, 1, 1, -1, -1, -1]
        var suppliesAsked: [String] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 5)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 3)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 1, 0, 1, 0, 0, 0, 0, 1] as [Int])
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

    @Test("FL-297 infeasible behind a cut: nil")
    func fl297() {
        // V [0, 1, 2, 3]; E [0→1 5 @1, 0→2 5 @1, 1→3 1 @1, 2→3 1 @1]; supply [0: 3, 3: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [5, 5, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1, 1, 1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [3, 0, 0, -3]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-298 demand reached only against an edge: nil")
    func fl298() {
        // V [0, 1]; E [1→0 5 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(1, 0)]
        let capacities: [Int] = [5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, -1]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-299 zero-capacity edges: cost 2; flow [0, 1, 1]")
    func fl299() throws {
        // V [0, 1, 2]; E [0→1 0 @-9, 0→2 2 @1, 2→1 2 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let capacities: [Int] = [0, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-9, 1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [1, -1, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 2)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 1)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 1, 1] as [Int])
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

    @Test("FL-300 supply at a vertex with only a loop: cost -4; flow [4]")
    func fl300() throws {
        // V [0]; E [0→0 4 @-1]; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 0)]
        let capacities: [Int] = [4]
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -4)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 0)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [4] as [Int])
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

    @Test("FL-301 lcgcost(8,20,11,5,0,9)")
    func fl301() throws {
        // lcgcost(8,20,11,5,0,9); supply [0: 4, 7: -4]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 3), (6, 3), (4, 3), (0, 3), (0, 3), (0, 2), (6, 7), (2, 5), (2, 6), (4, 1), (3, 6), (6, 2), (0, 2), (1, 6), (3, 4), (3, 0), (6, 1), (4, 5), (5, 7), (6, 4)]
        let capacities: [Int] = [4, 4, 1, 5, 4, 4, 4, 3, 2, 1, 4, 3, 4, 5, 2, 3, 5, 4, 2, 1]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [8, 2, 7, 7, 7, 0, 1, 3, 8, 4, 2, 0, 0, 7, 5, 7, 4, 8, 7, 0]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [4, 0, 0, 0, 0, 0, 0, -4]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 38)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 4)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        // One of several optima (catalog: [0, 0, 0, 0, 0, 4, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0]): the flow itself is not pinned.
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

    @Test("FL-302 lcgcost(8,20,6,5,-4,9): negative costs")
    func fl302() throws {
        // lcgcost(8,20,6,5,-4,9); supply [0: 3, 5: -1, 7: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(7, 6), (4, 3), (2, 7), (2, 6), (3, 5), (7, 2), (5, 0), (1, 3), (0, 4), (0, 1), (7, 3), (3, 6), (2, 5), (0, 3), (6, 0), (5, 7), (2, 0), (5, 2), (1, 5), (7, 1)]
        let capacities: [Int] = [4, 2, 1, 1, 4, 3, 2, 3, 3, 5, 1, 3, 2, 5, 1, 1, 2, 4, 4, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-3, -2, -4, 2, -4, 5, 6, 0, -2, -1, 0, 0, 0, 7, 5, 2, 5, -2, 7, 3]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [3, 0, 0, 0, 0, -1, 0, -2]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -31)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 3)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 2, 1, 0, 4, 0, 0, 2, 2, 2, 0, 0, 2, 0, 0, 1, 1, 4, 0, 0] as [Int])
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

    @Test("FL-303 lcgcost(10,30,13,6,-5,5): a circulation")
    func fl303() throws {
        // lcgcost(10,30,13,6,-5,5); supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(2, 5), (8, 6), (0, 1), (3, 1), (7, 6), (0, 1), (2, 6), (3, 5), (2, 4), (4, 6), (1, 5), (0, 6), (8, 1), (5, 7), (7, 4), (9, 5), (0, 7), (0, 8), (9, 8), (1, 3), (5, 4), (3, 6), (8, 5), (9, 5), (4, 1), (5, 1), (0, 1), (3, 8), (8, 6), (1, 8)]
        let capacities: [Int] = [5, 4, 6, 5, 1, 1, 3, 3, 5, 6, 1, 5, 4, 1, 4, 6, 3, 6, 4, 4, 3, 6, 2, 5, 1, 1, 4, 5, 5, 3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [2, -2, 0, 2, -2, -5, -3, 0, -5, 4, -5, -2, -2, -1, 0, -5, 4, -1, -2, 5, 0, 1, -2, 0, -3, 0, 2, -2, 5, 4]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -9)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 0)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0] as [Int])
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

    @Test("FL-304 lcgcost(12,40,14,9,1,20)")
    func fl304() throws {
        // lcgcost(12,40,14,9,1,20); supply [0: 6, 1: 3, 10: -4, 11: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(4, 2), (9, 7), (7, 11), (3, 10), (9, 6), (0, 9), (6, 3), (2, 6), (0, 11), (10, 7), (1, 2), (11, 5), (5, 11), (11, 7), (4, 2), (5, 2), (6, 5), (0, 1), (3, 5), (4, 10), (6, 3), (7, 11), (10, 5), (8, 6), (8, 9), (4, 9), (11, 0), (2, 1), (7, 5), (1, 5), (0, 7), (0, 10), (0, 8), (6, 7), (2, 4), (1, 9), (11, 9), (4, 8), (7, 0), (9, 5)]
        let capacities: [Int] = [1, 4, 2, 1, 9, 2, 3, 1, 2, 5, 3, 5, 1, 6, 1, 9, 2, 7, 5, 6, 4, 7, 4, 5, 9, 7, 5, 9, 1, 7, 2, 9, 7, 5, 5, 3, 8, 7, 4, 2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [10, 14, 9, 10, 5, 19, 20, 15, 11, 8, 3, 8, 14, 9, 10, 4, 1, 8, 18, 4, 2, 16, 7, 13, 20, 19, 2, 9, 13, 20, 15, 12, 20, 10, 16, 1, 9, 20, 10, 14]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [6, 3, 0, 0, 0, 0, 0, 0, 0, 0, -4, -5]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 139)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 9)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 2, 2, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 3, 0, 0, 0, 0] as [Int])
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

    @Test("FL-305 lcgcost(6,8,15,2,1,3): more supply than the network carries: nil")
    func fl305() {
        // lcgcost(6,8,15,2,1,3); supply [0: 9, 5: -9]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(5, 3), (4, 1), (1, 0), (2, 1), (0, 5), (2, 1), (2, 1), (4, 5)]
        let capacities: [Int] = [2, 1, 2, 1, 2, 2, 2, 2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [2, 1, 1, 1, 3, 3, 1, 1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [9, 0, 0, 0, 0, -9]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        // No flow exists: each closure is still called at most once per edge, in order.
        #expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))
        #expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))
        #expect(result == nil)
        // Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more
        // than its out-edges carry (Gale's theorem).
        var witness = supplies.reduce(0) { $0 + Int($1) } != 0
        for mask in 1 ..< max(1 << n, 1) where !witness {
            var supplied = 0, carried = 0
            for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }
            for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }
            if supplied > carried { witness = true }
        }
        #expect(witness)
    }

    @Test("FL-488 Int.max capacities, a negative cycle: both arcs near Int.max (only the solver's own arcs are unbounded)")
    func fl488() throws {
        // V [0, 1]; E [0→1 9223372036854775807 @0, 1→0 9223372036854775807 @-1]; supply [0: 5, 1: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [0, -1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [5, -5]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -9223372036854775802)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 5)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [9223372036854775807, 9223372036854775802] as [Int])
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

    @Test("FL-489 Int.max capacities, the negative arc first")
    func fl489() throws {
        // V [0, 1]; E [0→1 9223372036854775807 @-1, 1→0 9223372036854775807 @0]; supply [0: 5, 1: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int] = [-1, 0]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int] = [5, -5]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == -9223372036854775807)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 5)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [9223372036854775807, 9223372036854775802] as [Int])
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

    @Test("FL-491 Int8 costs on 130 vertices: no bound on (n + 1) × the greatest cost: cost 1; flow [1]")
    func fl491() throws {
        // Int8 V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,…
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int8] = [1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let costs: [Int8] = [1]
        // Supplies by vertex index: positive sends, negative receives.
        let supplies: [Int8] = [1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        var suppliesAsked: [Int] = []
        var capacitiesAsked: [Int] = []
        var costsAsked: [Int] = []
        let result = graph.minimumCostFlow(supply: { vertex in
            suppliesAsked.append(vertex)
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, capacity: { position in
            capacitiesAsked.append(position)
            return capacities[position]
        }, cost: { position in
            costsAsked.append(position)
            return costs[position]
        })
        // `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order.
        #expect(suppliesAsked == vertexList)
        #expect(capacitiesAsked == Array(pairs.indices))
        #expect(costsAsked == Array(pairs.indices))
        let flowResult = try #require(result)
        #expect(flowResult.cost == 1)
        // The amount shipped: the sum of the positive supplies.
        #expect(flowResult.value == 1)
        let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
        #expect(flows == [1] as [Int8])
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
