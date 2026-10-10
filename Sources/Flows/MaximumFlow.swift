import GraphProtocols

/// The maximum-flow algorithms behind the public entry points.
@usableFromInline
enum _MaximumFlowAlgorithm {
    /// Push–relabel's first phase only: the value and the canonical cut.
    case preflow
    /// Both phases: a maximum flow.
    case pushRelabel
    case edmondsKarp
    case dinic
}

/// A maximum flow in index space: its value, the sink side of the canonical cut by vertex
/// number, and each edge's flow (directed: along it; undirected: along and against its stored
/// direction, at most one nonzero).
@frozen
@usableFromInline
struct _MaximumFlowRun<C: Comparable & AdditiveArithmetic> {
    @usableFromInline let value: C
    @usableFromInline let inSink: [Bool]
    @usableFromInline let along: [C]
    @usableFromInline let against: [C]

    @inlinable
    init(value: C, inSink: [Bool], along: [C] = [], against: [C] = []) {
        self.value = value
        self.inSink = inSink
        self.along = along
        self.against = against
    }
}

/// The residual network of these edges: a directed edge's reverse arc starts at zero, an
/// undirected edge's at its capacity (one capacity both ways, `|f| ≤ c`).
@inlinable
func _residualNetwork<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C], reusable: Bool = false) -> _ResidualNetwork<C> {
    _ResidualNetwork(count: edges.vertexCount, tail: edges.tail, head: edges.head, forward: capacities, symmetric: !edges.directed, reusable: reusable)
}

/// Whether an undirected network's residuals could pass the capacity type: one residual pair
/// per edge reaches c + f, up to twice a capacity.
@inlinable
func _residualsMayOverflow<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C]) -> Bool {
    guard !edges.directed else { return false }
    var largest = C.zero
    for c in capacities where c > largest { largest = c }
    return _addingReportingOverflow(largest, largest).overflow
}

/// An undirected network as two independent arcs per edge (u → v and v → u, each of capacity
/// c with a reverse arc from zero), so no residual passes c. Its maximum flow value and every cut
/// value equal the single pair's, so the canonical cut is the same; pair 2e is the edge's stored
/// direction and 2e + 1 the other.
@inlinable
func _splitUndirectedNetwork<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C], reusable: Bool = false) -> _ResidualNetwork<C> {
    var tail: [Int32] = [], head: [Int32] = [], forward: [C] = []
    tail.reserveCapacity(2 * edges.edgeCount)
    head.reserveCapacity(2 * edges.edgeCount)
    forward.reserveCapacity(2 * edges.edgeCount)
    for e in 0 ..< edges.edgeCount {
        tail.append(edges.tail[e])
        head.append(edges.head[e])
        tail.append(edges.head[e])
        head.append(edges.tail[e])
        forward.append(capacities[e])
        forward.append(capacities[e])
    }
    return _ResidualNetwork(count: edges.vertexCount, tail: tail, head: head, forward: forward, symmetric: false, reusable: reusable)
}

/// The network the push–relabel and Dinic runs use: the single pair per edge, or two arcs per
/// undirected edge when the single pair's residuals could overflow.
@inlinable
func _flowNetwork<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C], reusable: Bool = false) -> _ResidualNetwork<C> {
    _residualsMayOverflow(edges, capacities) ? _splitUndirectedNetwork(edges, capacities, reusable: reusable) : _residualNetwork(edges, capacities, reusable: reusable)
}

/// Runs `algorithm` from `s` to `t` (vertex numbers, already checked distinct), after checking
/// that the capacities at the source sum without overflow.
@inlinable
func _runMaximumFlow<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C], from s: Int, to t: Int, _ algorithm: _MaximumFlowAlgorithm, wantsCut: Bool = true) -> _MaximumFlowRun<C> {
    let n = edges.vertexCount, m = edges.edgeCount
    let split = _residualsMayOverflow(edges, capacities)
    if split && algorithm == .edmondsKarp {
        let network = _residualNetwork(edges, capacities)
        network.checkRowSums([s])
        var bound = C.zero
        for a in network.first[s] ..< network.first[s + 1] { bound += network.residual[a] }
        let run = _edmondsKarpUndirected(network, capacities, from: s, to: t, bound: bound)
        return _MaximumFlowRun(value: run.value, inSink: run.inSink, along: run.along, against: run.against)
    }
    let network = split ? _splitUndirectedNetwork(edges, capacities) : _residualNetwork(edges, capacities)
    network.checkRowSums([s])
    let value: C
    var inSink: [Bool] = []
    switch algorithm {
    case .preflow, .pushRelabel:
        let preflow = _Preflow(network)
        value = preflow.firstPhase(from: s, to: t)
        guard wantsCut || algorithm == .pushRelabel else { return _MaximumFlowRun(value: value, inSink: []) }
        preflow.markSinkSide(t)
        inSink = Array(UnsafeBufferPointer(start: preflow.marks, count: n))
        if algorithm == .pushRelabel { preflow.secondPhase(from: s, to: t) }
    case .edmondsKarp, .dinic:
        value = algorithm == .edmondsKarp ? _edmondsKarp(network, from: s, to: t) : _dinic(network, from: s, to: t)
        inSink = [Bool](repeating: false, count: n)
        let queue = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
        defer { queue.deallocate() }
        _ = inSink.withUnsafeMutableBufferPointer { network.markSinkSide(t, $0.baseAddress!, queue) }
    }
    guard algorithm != .preflow else { return _MaximumFlowRun(value: value, inSink: inSink) }
    var along: [C] = [], against: [C] = []
    along.reserveCapacity(m)
    if edges.directed {
        for e in 0 ..< m { along.append(network.directedFlow(e)) }
    } else {
        against.reserveCapacity(m)
        for e in 0 ..< m {
            if split {
                let forward = network.directedFlow(2 * e), backward = network.directedFlow(2 * e + 1)
                along.append(forward >= backward ? forward - backward : .zero)
                against.append(forward >= backward ? .zero : backward - forward)
            } else {
                let (a, b) = network.undirectedFlow(e, capacity: capacities[e])
                along.append(a)
                against.append(b)
            }
        }
    }
    return _MaximumFlowRun(value: value, inSink: inSink, along: along, against: against)
}

extension DirectedGraph {
    // Maximum flow. `capacity` is called once per non-loop edge, in position order, before any
    // work; self-loops carry no flow and are never asked. Capacities are at least zero, not NaN,
    // finite, and the capacities of the edges out of `source` sum to a value that fits in `C`.

    /// A maximum flow from `source` to `sink`: highest-label push–relabel with the gap and global
    /// relabelling heuristics (Goldberg–Tarjan; Cherkassky–Goldberg), in two phases as LEMON's
    /// `Preflow` (NetworkX's default `preflow_push`, Boost `push_relabel_max_flow`). O(n² √m).
    /// Which maximum flow is returned is unspecified; `value` and `minimumCut` are not.
    ///
    /// - Precondition: `source` and `sink` are distinct vertices; every capacity is at least
    ///   zero, not NaN and finite; the capacities out of `source` sum without overflow.
    @inlinable
    public func maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Flow<Self, C> {
        _maximumFlow(from: source, to: sink, capacity: capacity, .pushRelabel)
    }

    /// A maximum flow by Edmonds–Karp: shortest augmenting paths by breadth-first search,
    /// residual arcs in edge-position order, stopping when the sink is discovered (the algorithm
    /// of Boost `edmonds_karp_max_flow` and NetworkX `edmonds_karp`). The flow is pinned by that
    /// procedure. O(n m²).
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func edmondsKarpMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Flow<Self, C> {
        _maximumFlow(from: source, to: sink, capacity: capacity, .edmondsKarp)
    }

    /// A maximum flow by Dinic's (Dinitz's) blocking flows with current-arc pointers (JGraphT
    /// `DinicMFImpl`, petgraph `dinics`, NetworkX `dinitz`). O(n² m); O(m √n) on unit networks
    /// (one in- or out-arc of capacity 1 per inner vertex), O(m min(√m, n^(2/3))) with unit
    /// capacities. `maximumFlow(from:to:capacity:)` (push–relabel) is the default because
    /// Dinic's phases can be many on long networks: on the DIMACS genrmf-long family (8 × 8 × 256)
    /// it took 223 ms here against push–relabel's 5 ms.
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func dinicMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Flow<Self, C> {
        _maximumFlow(from: source, to: sink, capacity: capacity, .dinic)
    }

    /// The maximum flow value from `source` to `sink`: push–relabel's first phase only (a
    /// maximum preflow; NetworkX `maximum_flow_value`, LEMON `Preflow::runMinCut`). O(n² √m).
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func maximumFlowValue<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> C {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        return _runMaximumFlow(edges, capacities, from: s, to: t, .preflow, wantsCut: false).value
    }

    /// The canonical minimum s–t cut: its sink side is every vertex that can still reach `sink`
    /// in the residual network of a maximum flow, the least sink side of any minimum cut
    /// (NetworkX `minimum_cut`, igraph `mincut`, OR-Tools `GetSinkSideMinCut`). Push–relabel's
    /// first phase suffices. O(n² √m).
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func minimumCut<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Cut<Self, C> {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        let run = _runMaximumFlow(edges, capacities, from: s, to: t, .preflow)
        return _cut(edges, capacities, _flowListed(vertices), run.inSink)
    }

    @inlinable
    func _maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C, _ algorithm: _MaximumFlowAlgorithm
    ) -> Flow<Self, C> {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        let run = _runMaximumFlow(edges, capacities, from: s, to: t, algorithm)
        let flows = run.along
        let cut = _cut(edges, capacities, _flowListed(vertices), run.inSink)
        return Flow(graph: self, flows: flows, source: source, sink: sink, value: run.value, minimumCut: cut)
    }
}

extension Graph {
    // The same maximum-flow and s–t cut entry points. Each edge carries up to its capacity in
    // either direction (one capacity shared by both: |f| ≤ c). Results are over `directed`, as
    // ShortestPaths' are: an edge's flow is on the arc of its direction, and a cut edge is the
    // arc from the source side to the sink side. `capacity` is called once per non-loop edge.

    /// A maximum flow from `source` to `sink` over `directed`, by push–relabel (see
    /// `DirectedGraph.maximumFlow(from:to:capacity:)`). Each edge is one residual pair with its
    /// capacity both ways.
    ///
    /// - Precondition: `source` and `sink` are distinct vertices; every capacity is at least
    ///   zero, not NaN and finite; the capacities at `source` sum without overflow. Capacities up
    ///   to the type's maximum are fine: when twice the greatest one would overflow, each edge is
    ///   carried as two arcs (Edmonds–Karp: as its flow both ways), so no residual passes a
    ///   capacity.
    @inlinable
    public func maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Flow<DirectedView<Self>, C> {
        _maximumFlow(from: source, to: sink, capacity: capacity, .pushRelabel)
    }

    /// A maximum flow over `directed` by Edmonds–Karp, with the rows in edge-position order: the
    /// flow is pinned by the procedure.
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func edmondsKarpMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Flow<DirectedView<Self>, C> {
        _maximumFlow(from: source, to: sink, capacity: capacity, .edmondsKarp)
    }

    /// A maximum flow over `directed` by Dinic's blocking flows.
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func dinicMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Flow<DirectedView<Self>, C> {
        _maximumFlow(from: source, to: sink, capacity: capacity, .dinic)
    }

    /// The maximum flow value: push–relabel's first phase only.
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func maximumFlowValue<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> C {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        return _runMaximumFlow(edges, capacities, from: s, to: t, .preflow, wantsCut: false).value
    }

    /// The canonical minimum s–t cut over `directed`: the least sink side, each crossing edge
    /// once as the arc leaving the source side.
    ///
    /// - Precondition: as for `maximumFlow(from:to:capacity:)`.
    @inlinable
    public func minimumCut<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C
    ) -> Cut<DirectedView<Self>, C> {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        let run = _runMaximumFlow(edges, capacities, from: s, to: t, .preflow)
        return _cut(edges, capacities, _flowListed(vertices), run.inSink)
    }

    @inlinable
    func _maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C, _ algorithm: _MaximumFlowAlgorithm
    ) -> Flow<DirectedView<Self>, C> {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: sink, vertices)
        precondition(s != t, "The source is the sink")
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        let run = _runMaximumFlow(edges, capacities, from: s, to: t, algorithm)
        var flows: [C] = []
        flows.reserveCapacity(2 * edges.edgeCount)
        for e in 0 ..< edges.edgeCount {
            flows.append(run.along[e])
            flows.append(run.against[e])
        }
        let cut = _cut(edges, capacities, _flowListed(vertices), run.inSink)
        return Flow(graph: directed, flows: flows, source: source, sink: sink, value: run.value, minimumCut: cut)
    }
}
