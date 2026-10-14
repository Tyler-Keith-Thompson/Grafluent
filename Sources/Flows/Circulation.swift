import GraphProtocols

/// A feasible flow within lower bounds and capacities that meets every supply, returned by
/// `feasibleCirculation(supply:lowerBound:capacity:)` and `feasibleCirculation(lowerBound:capacity:)`.
///
/// Every edge carries between its lower bound and its capacity, and at every vertex the flow out
/// less the flow in is its supply (zero for a circulation). It holds a copy-on-write copy of the
/// graph to look positions up.
@frozen
public struct Circulation<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: G
    /// Every edge position in `edges` order, for graphs without edge indices; empty with them.
    @usableFromInline let _positions: [G.Edges.Index]
    /// The flow on each edge, by edge number.
    @usableFromInline let _flows: [Capacity]

    @inlinable
    init(graph: G, flows: [Capacity]) {
        _graph = graph
        _positions = graph.edgeIndexBound == nil ? Array(graph.edges.indices) : []
        _flows = flows
    }

    /// The flow on the edge at `position`; on a self-loop, its lower bound.
    ///
    /// O(1) with edge indices, O(log m) without.
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity {
        _edgeFlow(_graph, _positions, _flows, position)
    }

    /// `flow(ofEdgeAt: position)`, throwing instead of trapping when `position` is not an edge
    /// position of the graph. O(1) with edge indices, O(log m) without.
    ///
    /// - Throws: `EdgeNotFound` when `position` is not a position in the graph's `edges`.
    @inlinable
    public func flow(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> Capacity {
        guard let e = _edgeNumberIfPresent(_graph, _positions, _flows.count, position) else { throw EdgeNotFound() }
        return _flows[e]
    }

    /// Every edge's flow, indexed by edge position in `edges` order. It shares the result's
    /// storage.
    @inlinable
    public var flowMap: FlowMap<G, Capacity> { FlowMap(graph: _graph, positions: _positions, flows: _flows) }
}

extension Circulation: Equatable {
    /// Whether both have the same flow on every edge. The graphs are not compared.
    @inlinable
    public static func == (lhs: Circulation, rhs: Circulation) -> Bool {
        lhs._flows == rhs._flows
    }
}

extension Circulation: Sendable where G: Sendable, G.Edges.Index: Sendable, Capacity: Sendable {}

extension Circulation: CustomStringConvertible {
    /// `flow [2, 0, 3]`: each edge's flow in `edges` order.
    public var description: String {
        "flow [\(_flows.map { "\($0)" }.joined(separator: ", "))]"
    }
}

/// The outcome of the reduction of a feasible flow with lower bounds to a maximum flow: each
/// edge's flow when feasible, or the barrier's marks (true: in the barrier) when not.
@frozen
@usableFromInline
struct _CirculationRun<C> {
    @usableFromInline let flows: [C]?
    @usableFromInline let barrier: [Bool]

    @inlinable
    init(flows: [C]?, barrier: [Bool]) {
        self.flows = flows
        self.barrier = barrier
    }
}

/// `a + b`, trapping with `message` on overflow.
@inlinable
func _checkedSum<C: AdditiveArithmetic>(_ a: C, _ b: C, _ message: @autoclosure () -> String) -> C {
    let (sum, overflow) = _addingReportingOverflow(a, b)
    precondition(!overflow, message())
    return sum
}

/// A flow with `lower[e] ≤ f(e) ≤ upper[e]` and out − in = supply at every vertex, by the
/// classical reduction: f = lower + g with 0 ≤ g ≤ upper − lower, each vertex's remaining
/// imbalance served from a super source or into a super sink, and a maximum flow from one to the
/// other by push–relabel. Feasible exactly when that flow saturates the super source. Otherwise
/// the source side of the canonical minimum cut, less the super source, is a barrier: a set S
/// whose supply exceeds the capacity out of S less the lower bounds into S.
///
/// `surplus[v]` and `deficit[v]` are the supply's positive and negative parts (both zero or one
/// zero), so unsigned types work.
@inlinable
func _feasibleCirculation<C: Comparable & AdditiveArithmetic>(
    _ edges: _FlowEdges, lower: [C], upper: [C], surplus: [C], deficit: [C]
) -> _CirculationRun<C> {
    let n = edges.vertexCount, m = edges.edgeCount
    // Each vertex's imbalance after the lower bounds: what it must still send (`excess`) or
    // still receive, kept as two nonnegative totals.
    var send = surplus, receive = deficit
    var room = [C](repeating: .zero, count: m)
    for e in 0 ..< m {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        if u == v { continue }
        room[e] = upper[e] - lower[e]
        // A negative lower bound is a flow the other way: it adds to the head's sending.
        if lower[e] >= .zero {
            receive[u] = _checkedSum(receive[u], lower[e], "The lower bounds at a vertex sum past the capacity type's range")
            send[v] = _checkedSum(send[v], lower[e], "The lower bounds at a vertex sum past the capacity type's range")
        } else {
            let back = C.zero - lower[e]
            send[u] = _checkedSum(send[u], back, "The lower bounds at a vertex sum past the capacity type's range")
            receive[v] = _checkedSum(receive[v], back, "The lower bounds at a vertex sum past the capacity type's range")
        }
    }
    let source = n, sink = n + 1
    var tail = edges.tail, head = edges.head
    var capacities = room
    var demanded = C.zero
    for v in 0 ..< n {
        if send[v] > receive[v] {
            tail.append(Int32(truncatingIfNeeded: source))
            head.append(Int32(truncatingIfNeeded: v))
            let c = send[v] - receive[v]
            capacities.append(c)
            demanded = _checkedSum(demanded, c, "The supplies sum past the capacity type's range")
        } else if receive[v] > send[v] {
            tail.append(Int32(truncatingIfNeeded: v))
            head.append(Int32(truncatingIfNeeded: sink))
            capacities.append(receive[v] - send[v])
        }
    }
    let network = _FlowEdges(vertexCount: n + 2, tail: tail, head: head, directed: true)
    let run = _runMaximumFlow(network, capacities, from: source, to: sink, .pushRelabel)
    guard run.value == demanded else {
        var barrier = [Bool](repeating: false, count: n)
        for v in 0 ..< n { barrier[v] = !run.inSink[v] }
        return _CirculationRun(flows: nil, barrier: barrier)
    }
    var flows = [C](repeating: .zero, count: m)
    for e in 0 ..< m { flows[e] = lower[e] + run.along[e] }
    return _CirculationRun(flows: flows, barrier: [])
}

extension DirectedGraph {
    // Feasible flows with lower bounds. `supply` is called once per vertex in `vertices` order,
    // then, for each edge in position order, `lowerBound` and then `capacity`, before any work.

    /// A flow that carries between each edge's lower bound and its capacity and in which every
    /// vertex sends out exactly its supply more than it receives; nil when there is none.
    ///
    /// A positive supply is how much more the vertex sends than it receives; a negative one is a
    /// demand. The supplies must sum to zero. Lower bounds may be negative (a flow against the
    /// edge, with a signed type). A self-loop carries its lower bound. When there is no such flow,
    /// `findCirculationBarrier(supply:lowerBound:capacity:)` gives a set of vertices that proves
    /// it.
    ///
    /// Computed by reduction to a maximum flow (push–relabel) from a super source serving each
    /// vertex's imbalance after the lower bounds. Which flow is returned when several exist is
    /// unspecified, but the same input always gives the same result.
    ///
    /// - Complexity: O(n² √m).
    ///
    /// - Precondition: every lower bound is at most its capacity; no value is NaN or infinite; the
    ///   supplies sum to zero; the lower bounds and supplies at a vertex sum without overflow, and
    ///   capacity − lower bound does not overflow.
    @inlinable
    public func feasibleCirculation<C: Comparable & AdditiveArithmetic>(
        supply: (Vertex) -> C, lowerBound: (Edges.Index) -> C, capacity: (Edges.Index) -> C
    ) -> Circulation<Self, C>? {
        let (edges, vertices) = _flowEdges()
        let run = _circulationRun(edges, vertices, supply, lowerBound, capacity)
        return run.flows.map { Circulation(graph: self, flows: $0) }
    }

    /// A circulation (out = in at every vertex) that carries between each edge's lower bound and
    /// its capacity; nil when there is none. See `feasibleCirculation(supply:lowerBound:capacity:)`.
    ///
    /// - Complexity: O(n² √m).
    ///
    /// - Precondition: as for `feasibleCirculation(supply:lowerBound:capacity:)`.
    @inlinable
    public func feasibleCirculation<C: Comparable & AdditiveArithmetic>(
        lowerBound: (Edges.Index) -> C, capacity: (Edges.Index) -> C
    ) -> Circulation<Self, C>? {
        feasibleCirculation(supply: { _ in .zero }, lowerBound: lowerBound, capacity: capacity)
    }

    /// A barrier that proves no feasible flow exists, or nil when one does.
    ///
    /// The barrier is a set S of vertices that must send more than it can: the supply of S
    /// exceeds the capacity of the edges leaving S less the lower bounds of the edges entering S.
    /// By Hoffman's circulation theorem (with supplies, Gale's) a flow exists exactly when no
    /// such set does. The barrier is the source side of the canonical minimum cut of the
    /// reduction, in `vertices` order; it is never empty.
    ///
    /// - Complexity: O(n² √m).
    ///
    /// - Precondition: as for `feasibleCirculation(supply:lowerBound:capacity:)`.
    @inlinable
    public func findCirculationBarrier<C: Comparable & AdditiveArithmetic>(
        supply: (Vertex) -> C, lowerBound: (Edges.Index) -> C, capacity: (Edges.Index) -> C
    ) -> [Vertex]? {
        let (edges, vertices) = _flowEdges()
        let run = _circulationRun(edges, vertices, supply, lowerBound, capacity)
        guard run.flows == nil else { return nil }
        let listed = _flowListed(vertices)
        return listed.indices.filter { run.barrier[$0] }.map { listed[$0] }
    }

    /// A barrier that proves no feasible circulation exists, or nil when one does. See
    /// `findCirculationBarrier(supply:lowerBound:capacity:)`; every supply is zero.
    ///
    /// - Complexity: O(n² √m).
    ///
    /// - Precondition: as for `feasibleCirculation(supply:lowerBound:capacity:)`.
    @inlinable
    public func findCirculationBarrier<C: Comparable & AdditiveArithmetic>(
        lowerBound: (Edges.Index) -> C, capacity: (Edges.Index) -> C
    ) -> [Vertex]? {
        findCirculationBarrier(supply: { _ in .zero }, lowerBound: lowerBound, capacity: capacity)
    }

    /// Reads the supplies, then each edge's lower bound and capacity, checks them, and runs the
    /// reduction.
    @inlinable
    func _circulationRun<C: Comparable & AdditiveArithmetic>(
        _ edges: _FlowEdges, _ vertices: _FlowVertices<Vertex>,
        _ supply: (Vertex) -> C, _ lowerBound: (Edges.Index) -> C, _ capacity: (Edges.Index) -> C
    ) -> _CirculationRun<C> {
        let n = edges.vertexCount, m = edges.edgeCount
        var surplus = [C](repeating: .zero, count: n), deficit = [C](repeating: .zero, count: n)
        var supplied = C.zero, demanded = C.zero
        for (v, vertex) in _flowListed(vertices).enumerated() {
            let b = supply(vertex)
            precondition(b == b, "A supply is NaN")
            precondition(b - b == .zero, "A supply is infinite")
            if b > .zero {
                surplus[v] = b
                supplied = _checkedSum(supplied, b, "The supplies sum past the capacity type's range")
            } else if b < .zero {
                deficit[v] = .zero - b
                demanded = _checkedSum(demanded, deficit[v], "The supplies sum past the capacity type's range")
            }
        }
        precondition(supplied == demanded, "The supplies do not sum to zero")
        var lower = [C](repeating: .zero, count: m), upper = [C](repeating: .zero, count: m)
        var e = 0
        for position in self.edges.indices {
            let l = lowerBound(position), u = capacity(position)
            precondition(l == l && u == u, "A lower bound or capacity is NaN")
            precondition(l - l == .zero && u - u == .zero, "A lower bound or capacity is infinite")
            precondition(l <= u, "A lower bound exceeds its capacity")
            lower[e] = l
            upper[e] = u
            e += 1
        }
        return _feasibleCirculation(edges, lower: lower, upper: upper, surplus: surplus, deficit: deficit)
    }
}
