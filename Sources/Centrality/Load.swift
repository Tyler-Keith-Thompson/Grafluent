import GraphProtocols

/// Load (Goh, Kahng and Kim 2001; Newman's betweenness for a packet that splits evenly at each
/// branch): from each source, every other vertex sends one unit back along the shortest-path DAG,
/// each vertex passing what reaches it in equal shares to its DAG in-slots; a vertex's score is what
/// passes through it as neither source nor target, summed over ordered pairs.
@inlinable
func _load<W>(_ dag: inout _ShortestPathDAG<W>) -> [Double] {
    let n = dag.count
    var result = [Double](repeating: 0, count: n)
    var passed = [Double](repeating: 0, count: n)
    for s in 0 ..< n {
        dag.search(from: s)
        var k = dag.reached - 1
        while k > 0 {
            let v = dag.order[k]
            var through = 0.0
            for slot in dag.rows.offsets[v] ..< dag.rows.offsets[v + 1] where dag.isStep(from: v, slot) {
                let w = dag.rows.targets[slot]
                through += (1 + passed[w]) / Double(dag.parents[w])
            }
            passed[v] = through
            result[v] += through
            k -= 1
        }
    }
    return result
}

/// Percolation centrality (Piraveenan, Prokopenko and Hossain 2013): Brandes' dependencies, each
/// source's weighted by x_s / (Σx − x_v) at the vertex v it is credited to (0 when that is 0/0).
@inlinable
func _percolation<W>(_ dag: inout _ShortestPathDAG<W>, states: [Double]) -> [Double] {
    let n = dag.count
    var result = [Double](repeating: 0, count: n)
    var delta = [Double](repeating: 0, count: n)
    var total = 0.0
    for x in states { total += x }
    for s in 0 ..< n {
        dag.search(from: s)
        var k = dag.reached - 1
        while k > 0 {
            let v = dag.order[k]
            let sv = dag.sigma[v]
            var dependency = 0.0
            for slot in dag.rows.offsets[v] ..< dag.rows.offsets[v + 1] where dag.isStep(from: v, slot) {
                let w = dag.rows.targets[slot]
                dependency += sv / dag.sigma[w] * (1 + delta[w])
            }
            delta[v] = dependency
            let others = total - states[v]
            if others > 0 { result[v] += dependency * states[s] / others }
            k -= 1
        }
    }
    return result
}

/// Scales by 1 / ((n − 1)(n − 2)) when `normalized` and n > 2.
@inlinable
func _scaleByPairs(_ scores: inout [Double], normalized: Bool) {
    let n = Double(scores.count)
    guard normalized, scores.count > 2 else { return }
    let scale = 1 / ((n - 1) * (n - 2))
    for v in scores.indices { scores[v] *= scale }
}

/// Scales by 1 / (n − 2) when n > 2.
@inlinable
func _scaleByOthers(_ scores: inout [Double]) {
    guard scores.count > 2 else { return }
    let scale = 1 / Double(scores.count - 2)
    for v in scores.indices { scores[v] *= scale }
}

/// The states by vertex number, each checked to be in [0, 1].
@inlinable
func _percolationStates<V>(_ vertices: some Sequence<V>, _ state: (V) -> Double) -> [Double] {
    vertices.map { v in
        let x = state(v)
        precondition(x >= 0 && x <= 1, "A percolation state must be in 0 ... 1")
        return x
    }
}

extension Graph {
    /// The vertices in vertex-number order: by index, or as listed.
    @inlinable
    func _verticesInNumberOrder() -> [Vertex] {
        vertexIndexBound != nil ? (0 ..< vertexCount).map { vertex(atIndex: $0) } : Array(vertices)
    }

    /// Load centrality (Goh, Kahng and Kim 2001; Brandes 2008): from every source s, each vertex
    /// t ≠ s sends one unit to s along shortest paths, a vertex splitting what reaches it equally
    /// among its shortest-path predecessors (each parallel copy one); a vertex's load is what
    /// passes through it as neither end, summed over ordered pairs (s, t). It differs from
    /// betweenness, which splits in proportion to the number of shortest paths. `normalized`
    /// divides by (n − 1)(n − 2); there is no scaling when n ≤ 2, and an unnormalized sum counts
    /// both orders of each pair. Self-loops never matter. O(nm).
    @inlinable
    public func loadCentrality(normalized: Bool = true) -> CentralityScores<DirectedView<Self>> {
        var dag = _ShortestPathDAG(_centralityRows(readsEdges: false))
        var scores = _load(&dag)
        _scaleByPairs(&scores, normalized: normalized)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Weighted load centrality: shortest by weight, lengths tying only when their sums are exactly
    /// equal. `weight` is called once per edge, in position order. O(n · m log n).
    ///
    /// - Precondition: every weight is greater than zero (and not NaN).
    @inlinable
    public func loadCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, normalized: Bool = true) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var dag = _ShortestPathDAG(rows, slotWeights: rows.slotWeights(weights))
        var scores = _load(&dag)
        _scaleByPairs(&scores, normalized: normalized)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Percolation centrality (Piraveenan, Prokopenko and Hossain 2013): betweenness weighted by
    /// how percolated each path's source is, PC(v) = 1/(n − 2) Σ over ordered pairs s ≠ v ≠ t of
    /// σ_st(v)/σ_st · x_s / (Σ_u x_u − x_v), where x is each vertex's percolation state (a term
    /// whose denominator is 0 is 0). With every state equal and positive it is the normalized
    /// `betweennessCentrality()`. No scaling when n ≤ 2. Self-loops never matter. O(nm).
    ///
    /// - Parameter state: each vertex's percolation state x_v, in [0, 1]; called once per vertex,
    ///   in vertex-number order.
    /// - Precondition: every state is in 0 ... 1.
    @inlinable
    public func percolationCentrality(state: (Vertex) -> Double) -> CentralityScores<DirectedView<Self>> {
        let states = _percolationStates(_verticesInNumberOrder(), state)
        var dag = _ShortestPathDAG(_centralityRows(readsEdges: false))
        var scores = _percolation(&dag, states: states)
        _scaleByOthers(&scores)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }

    /// Weighted percolation centrality: shortest by weight, lengths tying only when their sums are
    /// exactly equal. `weight` is called once per edge, in position order. O(n · m log n).
    ///
    /// - Precondition: every state is in 0 ... 1; every weight is greater than zero (and not NaN).
    @inlinable
    public func percolationCentrality<W: Comparable & AdditiveArithmetic>(state: (Vertex) -> Double, weight: (Edges.Index) -> W) -> CentralityScores<DirectedView<Self>> {
        let states = _percolationStates(_verticesInNumberOrder(), state)
        let rows = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var dag = _ShortestPathDAG(rows, slotWeights: rows.slotWeights(weights))
        var scores = _percolation(&dag, states: states)
        _scaleByOthers(&scores)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: scores)
    }
}

extension DirectedGraph {
    /// The vertices in vertex-number order: by index, or as listed.
    @inlinable
    func _verticesInNumberOrder() -> [Vertex] {
        vertexIndexBound != nil ? (0 ..< vertexCount).map { vertex(atIndex: $0) } : Array(vertices)
    }

    /// Load centrality over directed shortest paths, as on `Graph`. O(nm).
    @inlinable
    public func loadCentrality(normalized: Bool = true) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: false)
        var dag = _ShortestPathDAG(rows)
        var scores = _load(&dag)
        _scaleByPairs(&scores, normalized: normalized)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted load centrality over directed shortest paths. O(n · m log n).
    ///
    /// - Precondition: every weight is greater than zero (and not NaN).
    @inlinable
    public func loadCentrality<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W, normalized: Bool = true) -> CentralityScores<Self> {
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var dag = _ShortestPathDAG(rows, slotWeights: rows.slotWeights(weights))
        var scores = _load(&dag)
        _scaleByPairs(&scores, normalized: normalized)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Percolation centrality over directed shortest paths, as on `Graph`. O(nm).
    ///
    /// - Precondition: every state is in 0 ... 1.
    @inlinable
    public func percolationCentrality(state: (Vertex) -> Double) -> CentralityScores<Self> {
        let states = _percolationStates(_verticesInNumberOrder(), state)
        let (rows, numbers) = _centralityRows(readsEdges: false)
        var dag = _ShortestPathDAG(rows)
        var scores = _percolation(&dag, states: states)
        _scaleByOthers(&scores)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }

    /// Weighted percolation centrality over directed shortest paths. O(n · m log n).
    ///
    /// - Precondition: every state is in 0 ... 1; every weight is greater than zero (and not NaN).
    @inlinable
    public func percolationCentrality<W: Comparable & AdditiveArithmetic>(state: (Vertex) -> Double, weight: (Edges.Index) -> W) -> CentralityScores<Self> {
        let states = _percolationStates(_verticesInNumberOrder(), state)
        let (rows, numbers) = _centralityRows(readsEdges: true)
        let weights = _edgeWeights(weight, valid: { $0 > .zero }, message: "Edge weights must be greater than zero")
        var dag = _ShortestPathDAG(rows, slotWeights: rows.slotWeights(weights))
        var scores = _percolation(&dag, states: states)
        _scaleByOthers(&scores)
        return CentralityScores(self, numbers: numbers, scores: scores)
    }
}
