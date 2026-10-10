import GraphProtocols

/// A minimum-cost flow (LEMON `NetworkSimplex`: `flow`, `totalCost`, `potential`): the result of
/// `minimumCostFlow(supply:capacity:cost:)` and `minimumCostMaximumFlow(from:to:capacity:cost:)`.
///
/// It keeps a copy of the graph to look positions up (copy-on-write, O(1) to make).
@frozen
public struct MinimumCostFlow<G: DirectedGraph, Capacity: BinaryInteger, Cost: SignedInteger> {
    @usableFromInline let _graph: G
    @usableFromInline let _positions: [G.Edges.Index]
    @usableFromInline let _vertices: _FlowVertices<G.Vertex>
    @usableFromInline let _flows: [Capacity]
    @usableFromInline let _potentials: [Int]
    /// The total cost, Σ flow × cost.
    public let cost: Cost
    /// The amount shipped: the sum of the positive supplies; for `minimumCostMaximumFlow`, the
    /// maximum flow value.
    public let value: Capacity

    @inlinable
    init(graph: G, vertices: _FlowVertices<G.Vertex>, flows: [Capacity], potentials: [Int], cost: Cost, value: Capacity) {
        _graph = graph
        _positions = graph.edgeIndexBound == nil ? Array(graph.edges.indices) : []
        _vertices = vertices
        _flows = flows
        _potentials = potentials
        self.cost = cost
        self.value = value
    }

    /// The flow on the edge at `position`. O(1) with edge indices, O(log m) without.
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity {
        _edgeFlow(_graph, _positions, _flows, position)
    }

    /// Every edge's flow, by edge position in `edges` order (LEMON `NetworkSimplex::flowMap`): a
    /// collection over the result's own storage, no copy made.
    @inlinable
    public var flowMap: FlowMap<G, Capacity> { FlowMap(graph: _graph, positions: _positions, flows: _flows) }

    /// The optimal dual: every edge with room left has reduced cost
    /// cost + potential(source) − potential(target) ≥ 0, and every edge carrying flow ≤ 0, the
    /// optimality certificate. Not unique.
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and its potential fits in `Cost`. A
    ///   potential is at most big M + n × the greatest |cost| in magnitude, where big M, the
    ///   network simplex's artificial cost, is (n + 1)(the greatest |cost| + 1): about
    ///   2(n + 1) times the greatest |cost|, so O(n × the greatest |cost|).
    @inlinable
    public func potential(of vertex: G.Vertex) -> Cost {
        let v = _graph._flowNumber(of: vertex, _vertices)
        guard let p = Cost(exactly: _potentials[v]) else { preconditionFailure("The potential does not fit in the cost type") }
        return p
    }
}

extension MinimumCostFlow: Equatable {
    /// Whether both have the same cost, value, flow on every edge and potentials (the solver is
    /// deterministic, so equal inputs give equal results). The graphs are not compared.
    @inlinable
    public static func == (lhs: MinimumCostFlow, rhs: MinimumCostFlow) -> Bool {
        lhs.cost == rhs.cost && lhs.value == rhs.value && lhs._flows == rhs._flows && lhs._potentials == rhs._potentials
    }
}

extension MinimumCostFlow: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Capacity: Sendable, Cost: Sendable {}

extension MinimumCostFlow: CustomStringConvertible {
    /// `cost 24; flow [4, 1, 4, 1]`.
    public var description: String {
        "cost \(cost); flow [\(_flows.map { "\($0)" }.joined(separator: ", "))]"
    }
}

/// Solves a minimum-cost flow in index space: per edge number its capacity and cost, per vertex
/// its supply, all already in `Int`. Returns the flows, potentials and total cost, or nil when
/// the supplies cannot be met. Self-loops carry their capacity when their cost is negative.
@inlinable
func _minimumCostFlow(_ edges: _FlowEdges, capacity: [Int], cost: [Int], supply: [Int]) -> (flows: [Int], potentials: [Int], cost: Int)? {
    let n = edges.vertexCount, m = edges.edgeCount
    var total = 0
    for b in supply {
        let (sum, overflow) = total.addingReportingOverflow(b)
        precondition(!overflow, "The supplies overflow")
        total = sum
    }
    guard total == 0 else { return nil }
    var flows = [Int](repeating: 0, count: m)
    var arcSource: [Int] = [], arcTarget: [Int] = [], arcCapacity: [Int] = [], arcCost: [Int] = [], arcEdge: [Int] = []
    arcSource.reserveCapacity(m)
    arcTarget.reserveCapacity(m)
    arcCapacity.reserveCapacity(m)
    arcCost.reserveCapacity(m)
    arcEdge.reserveCapacity(m)
    var greatest = 0
    for e in 0 ..< m {
        if edges.tail[e] == edges.head[e] {
            if cost[e] < 0 { flows[e] = capacity[e] }
            continue
        }
        arcSource.append(Int(edges.tail[e]))
        arcTarget.append(Int(edges.head[e]))
        arcCapacity.append(capacity[e])
        arcCost.append(cost[e])
        arcEdge.append(e)
        greatest = max(greatest, cost[e].magnitude > UInt(Int.max) ? Int.max : abs(cost[e]))
    }
    // Big M, with room for the potentials and reduced costs built from it.
    let (bigM, overflowM) = (greatest &+ 1).multipliedReportingOverflow(by: n &+ 1)
    // A comparison, not `bigM.multipliedReportingOverflow(by: 4)` with its product discarded:
    // Swift 6.4's optimizer drops that overflow flag here under -O.
    precondition(!overflowM && bigM <= Int.max / 4, "The costs are too large for the network simplex's artificial arcs")
    var potentials = [Int](repeating: 0, count: n)
    if n > 0 {
        let simplex = _NetworkSimplex(nodes: n, source: arcSource, target: arcTarget, capacity: arcCapacity, cost: arcCost, supply: supply, artificialCost: bigM)
        guard simplex.solve(supply: supply) else { return nil }
        for k in 0 ..< arcEdge.count { flows[arcEdge[k]] = simplex.flow(ofArc: k) }
        for v in 0 ..< n { potentials[v] = simplex.potential[v] }
    }
    // Σ capacity × |cost| fits (checked before solving), so neither the products nor the sum
    // overflow; the checked operators keep it that way.
    var totalCost = 0
    for e in 0 ..< m { totalCost += flows[e] * cost[e] }
    return (flows, potentials, totalCost)
}

extension DirectedGraph {
    // Minimum-cost flow. Integer capacities, supplies and costs, computed exactly in `Int`.

    /// A least-cost flow meeting every supply (positive: the vertex sends that much more than it
    /// receives; negative: a demand), within capacities (LEMON `NetworkSimplex`, OR-Tools
    /// `SimpleMinCostFlow`, NetworkX `min_cost_flow` with the opposite sign), or nil when there is
    /// none: the supplies do not sum to zero, or some set of vertices supplies more than its
    /// out-edges carry. Costs may be negative; negative cycles are saturated (capacities are
    /// finite). A self-loop carries its capacity when its cost is negative and nothing otherwise.
    /// Network simplex with block-search pivots and strongly feasible trees, LEMON's layout.
    /// `supply` is called once per vertex in `vertices` order, then, for each edge in position
    /// order, `capacity` and then `cost`, before any work. Which optimum is returned when several
    /// exist is unspecified, but the same input always gives the same result.
    ///
    /// Capacities may be of an unsigned type; supplies and costs are signed. Any capacity up to
    /// `Int.max` is fine (it is finite: only the solver's own artificial arcs are unbounded).
    ///
    /// - Precondition: every capacity is at least zero; capacities, supplies and costs fit in
    ///   `Int`; Σ capacity × |cost| fits in `Cost` (checked before solving; it bounds the total
    ///   cost, so a cost that could not be represented traps here rather than wrapping);
    ///   4(n + 1)(the greatest |cost| of a non-loop edge + 1) fits in `Int` (the solver's
    ///   artificial cost, with room for its potentials and reduced costs; computed in `Int` and
    ///   never reported); the positive supplies sum within `Int` and `Capacity`.
    @inlinable
    public func minimumCostFlow<S: SignedInteger, C: BinaryInteger, W: SignedInteger>(
        supply: (Vertex) -> S, capacity: (Edges.Index) -> C, cost: (Edges.Index) -> W
    ) -> MinimumCostFlow<Self, C, W>? {
        let (edges, vertices) = _flowEdges()
        let listed = _flowListed(vertices)
        var supplies: [Int] = []
        supplies.reserveCapacity(listed.count)
        var shipped = 0
        for v in listed {
            guard let b = Int(exactly: supply(v)) else { preconditionFailure("A supply does not fit in Int") }
            supplies.append(b)
            if b > 0 {
                let (sum, overflow) = shipped.addingReportingOverflow(b)
                precondition(!overflow, "The supplies overflow")
                shipped = sum
            }
        }
        let (capacities, costs) = _readCostedCapacities(edges, capacity, cost)
        guard let value = C(exactly: shipped) else { preconditionFailure("The positive supplies sum past the capacity type's range") }
        guard let solution = _minimumCostFlow(edges, capacity: capacities, cost: costs, supply: supplies) else { return nil }
        return MinimumCostFlow(graph: self, vertices: vertices, flows: solution.flows.map { C($0) }, potentials: solution.potentials, cost: W(solution.cost), value: value)
    }

    /// The least-cost flow among the maximum flows from `source` to `sink`, circulations
    /// included (NetworkX `max_flow_min_cost`, OR-Tools `SolveMaxFlowWithMinCost`): the maximum
    /// flow value by push–relabel's first phase, then `minimumCostFlow` with that supply at
    /// `source` and demand at `sink`. So a negative cycle away from every source–sink path is
    /// still saturated. For each edge in position order, `capacity` is called and then `cost`,
    /// once each, before any work.
    ///
    /// - Precondition: `source` and `sink` are distinct vertices, and the preconditions of
    ///   `minimumCostFlow(supply:capacity:cost:)` and `maximumFlow(from:to:capacity:)` hold.
    @inlinable
    public func minimumCostMaximumFlow<C: BinaryInteger, W: SignedInteger>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C, cost: (Edges.Index) -> W
    ) -> MinimumCostFlow<Self, C, W> {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let (capacities, costs) = _readCostedCapacities(edges, capacity, cost)
        // Self-loops get no arcs in the residual network, so their capacities never count.
        let value = _runMaximumFlow(edges, capacities, from: s, to: t, .preflow, wantsCut: false).value
        var supplies = [Int](repeating: 0, count: edges.vertexCount)
        supplies[s] = value
        supplies[t] = -value
        guard let solution = _minimumCostFlow(edges, capacity: capacities, cost: costs, supply: supplies) else {
            preconditionFailure("A maximum flow's value could not be shipped")
        }
        return MinimumCostFlow(graph: self, vertices: vertices, flows: solution.flows.map { C($0) }, potentials: solution.potentials, cost: W(solution.cost), value: C(value))
    }

    /// Each edge's capacity and cost in `Int`, read once per edge in position order, checking
    /// that capacities are nonnegative and Σ capacity × |cost| fits in `W`.
    @inlinable
    func _readCostedCapacities<C: BinaryInteger, W: SignedInteger>(
        _ edges: _FlowEdges, _ capacity: (Edges.Index) -> C, _ cost: (Edges.Index) -> W
    ) -> (capacities: [Int], costs: [Int]) {
        var capacities: [Int] = [], costs: [Int] = []
        capacities.reserveCapacity(edges.edgeCount)
        costs.reserveCapacity(edges.edgeCount)
        var bound = 0
        for position in self.edges.indices {
            let c = capacity(position)
            precondition(c >= 0, "A capacity is negative")
            guard let ci = Int(exactly: c) else { preconditionFailure("A capacity does not fit in Int") }
            guard let wi = Int(exactly: cost(position)) else { preconditionFailure("A cost does not fit in Int") }
            let (product, o1) = ci.multipliedReportingOverflow(by: wi.magnitude > UInt(Int.max) ? Int.max : abs(wi))
            let (sum, o2) = bound.addingReportingOverflow(product)
            precondition(!o1 && !o2 && W(exactly: sum) != nil, "Σ capacity × |cost| overflows the cost type")
            bound = sum
            capacities.append(ci)
            costs.append(wi)
        }
        return (capacities, costs)
    }
}
