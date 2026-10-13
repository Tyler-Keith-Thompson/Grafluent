import GraphProtocols

/// Copies an undirected graph's rows in index space: every edge end (a loop twice), with the
/// weight of its edge when `weights` (by edge number) is given; a weight-0 edge is left out.
@frozen
@usableFromInline
struct _CopyWeightedRows: _UndirectedRowsAlgorithm {
    @usableFromInline let weights: [Double]?

    @inlinable
    init(weights: [Double]?) { self.weights = weights }

    @inlinable
    var readsEdges: Bool { weights != nil }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _WeightedAdjacency {
        precondition(n <= Int(Int32.max), "More vertices than the spectral engines index (2³¹ − 1)")
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int32] = []
        targets.reserveCapacity(2 * edgeCount)
        var slotWeights: [Double] = []
        var bound = 0.0
        var negative = false
        var loop = false
        if let weights {
            slotWeights.reserveCapacity(2 * edgeCount)
            for v in 0 ..< n {
                var sum = 0.0
                for k in 0 ..< rows.count(v) {
                    let w = rows.neighbor(v, k), e = rows.edge(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                    let weight = weights[e]
                    if weight == 0 { continue }
                    targets.append(Int32(truncatingIfNeeded: w))
                    slotWeights.append(weight)
                    sum += abs(weight)
                    if weight < 0 { negative = true }
                    if w == v { loop = true }
                }
                precondition(sum.isFinite, "A sum of weights overflows Double")
                bound = max(bound, sum)
                offsets[v + 1] = targets.count
            }
        } else {
            for v in 0 ..< n {
                for k in 0 ..< rows.count(v) {
                    let w = rows.neighbor(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    targets.append(Int32(truncatingIfNeeded: w))
                    if w == v { loop = true }
                }
                bound = max(bound, Double(targets.count - offsets[v]))
                offsets[v + 1] = targets.count
            }
        }
        return _WeightedAdjacency(offsets: offsets, columns: targets, values: weights == nil ? nil : slotWeights, gershgorinBound: bound, hasNegativeEntry: negative, hasLoop: loop)
    }
}

/// Each edge's weight as a `Double`, read once in position order: finite, and nonnegative unless
/// `allowsNegative`.
@inlinable
func _spectralWeights<Positions: Sequence, W: BinaryInteger>(_ positions: Positions, count: Int, _ weight: (Positions.Element) -> W, allowsNegative: Bool) -> [Double] {
    var weights: [Double] = []
    weights.reserveCapacity(count)
    for position in positions {
        let w = weight(position)
        precondition(allowsNegative || w >= 0, "A weight is negative")
        weights.append(Double(w))
    }
    return weights
}

/// Each edge's weight as a `Double`, read once in position order: finite, and nonnegative unless
/// `allowsNegative`.
@inlinable
func _spectralWeights<Positions: Sequence, W: BinaryFloatingPoint>(_ positions: Positions, count: Int, _ weight: (Positions.Element) -> W, allowsNegative: Bool) -> [Double] {
    var weights: [Double] = []
    weights.reserveCapacity(count)
    for position in positions {
        let w = weight(position)
        precondition(w.isFinite, "A weight is not finite")
        precondition(allowsNegative || w >= 0, "A weight is negative")
        weights.append(Double(w))
    }
    return weights
}

/// Traps on an iteration limit below 1; nil (the method's default limit) passes.
@inlinable
func _checkMaxIterations(_ maxIterations: Int?) {
    if let maxIterations { precondition(maxIterations >= 1, "maxIterations must be at least 1") }
}

extension Graph {
    /// The weighted adjacency in index space: vertices numbered by vertex index, or by position in
    /// `numbering.listed` for a graph without vertex indices.
    @inlinable
    func _spectralAdjacency(_ weights: [Double]?, numbering: (listed: [Vertex], numbers: [Vertex: Int])?) -> _WeightedAdjacency {
        _runOnUndirectedRows(_CopyWeightedRows(weights: weights), vertexNumbering: numbering)
    }

    @inlinable
    func _spectralWeights<W: BinaryInteger>(_ weight: (Edges.Index) -> W, allowsNegative: Bool = false) -> [Double] {
        SpectralGraphTheory._spectralWeights(edges.indices, count: edgeCount, weight, allowsNegative: allowsNegative)
    }

    @inlinable
    func _spectralWeights<W: BinaryFloatingPoint>(_ weight: (Edges.Index) -> W, allowsNegative: Bool = false) -> [Double] {
        SpectralGraphTheory._spectralWeights(edges.indices, count: edgeCount, weight, allowsNegative: allowsNegative)
    }

    /// For the exact spanning-tree count, read once per position in position order: each edge's
    /// number plus one (0 for a weight-0 edge, which the rows then leave out), its weight as a
    /// `Double`, and its residues modulo the three count primes (3 per edge).
    @inlinable
    func _exactSpanningTreeWeights<W: BinaryInteger>(_ weight: (Edges.Index) -> W) -> (numbers: [Double], weights: [Double], residues: [UInt64]) {
        var numbers: [Double] = [], weights: [Double] = [], residues: [UInt64] = []
        numbers.reserveCapacity(edgeCount)
        weights.reserveCapacity(edgeCount)
        residues.reserveCapacity(3 * edgeCount)
        let (p1, p2, p3) = _countPrimes
        for position in edges.indices {
            let w = weight(position)
            precondition(w >= 0, "A weight is negative")
            numbers.append(w == 0 ? 0 : Double(numbers.count + 1))
            weights.append(Double(w))
            residues.append(_residue(w, modulo: p1))
            residues.append(_residue(w, modulo: p2))
            residues.append(_residue(w, modulo: p3))
        }
        return (numbers, weights, residues)
    }

    /// The number of `vertex`: its vertex index, or its position in `vertices`.
    @inlinable
    func _spectralNumber(of vertex: Vertex, _ numbering: (listed: [Vertex], numbers: [Vertex: Int])?) -> Int {
        _vertexNumber(of: vertex, numbering?.numbers, "The vertex is not in the graph")
    }
}

extension DirectedGraph {
    /// The weighted adjacency in index space (A[u][v] = Σ w over arcs u → v): vertices numbered
    /// by vertex index, or by position in `vertices`.
    @inlinable
    func _spectralAdjacency(_ weights: [Double]?) -> _MergedRows {
        let readsEdges = weights != nil
        var offsets: [Int] = [0]
        var targets: [Int32] = []
        var slotWeights: [Double] = []
        targets.reserveCapacity(edgeCount)
        if readsEdges { slotWeights.reserveCapacity(edgeCount) }
        let n: Int
        if let bound = vertexIndexBound {
            n = bound
            precondition(n <= Int(Int32.max), "More vertices than the spectral engines index (2³¹ − 1)")
            offsets.reserveCapacity(n + 1)
            if Edges.Index.self == Int.self, let rows = _withSuccessorIndexRows({ offsets, targets in (Array(offsets), Array(targets)) }) {
                // Slot k is the edge with position and index k.
                precondition(rows.0.count == n + 1, "The row offsets do not match vertexIndexBound")
                let narrowed = rows.1.map { w in
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                    return Int32(truncatingIfNeeded: w)
                }
                return _MergedRows(count: n, slotOffsets: rows.0, targets: narrowed, weights: weights, symmetric: false)
            }
            if !readsEdges {
                for v in 0 ..< n {
                    for w in successorIndices(ofIndex: v) {
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        targets.append(Int32(truncatingIfNeeded: w))
                    }
                    offsets.append(targets.count)
                }
            } else {
                let indexed = edgeIndexBound != nil
                let numbers = indexed ? [:] : _edgeNumbers()
                for v in 0 ..< n {
                    var successors = successorIndices(ofIndex: v).makeIterator()
                    for position in outEdges(ofIndex: v) {
                        guard let w = successors.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        targets.append(Int32(truncatingIfNeeded: w))
                        slotWeights.append(weights![indexed ? edgeIndex(of: position) : numbers[position]!])
                    }
                    precondition(successors.next() == nil, "successorIndices and outEdges differ in length")
                    offsets.append(targets.count)
                }
            }
        } else {
            let listed = Array(vertices)
            n = listed.count
            precondition(n <= Int(Int32.max), "More vertices than the spectral engines index (2³¹ − 1)")
            let vertexNumbers = _vertexNumbers(listed)
            let indexed = edgeIndexBound != nil
            let numbers = !readsEdges || indexed ? [:] : _edgeNumbers()
            for v in listed {
                for position in outEdges(of: v) {
                    targets.append(Int32(truncatingIfNeeded: vertexNumbers[target(ofEdgeAt: position)]!))
                    if readsEdges { slotWeights.append(weights![indexed ? edgeIndex(of: position) : numbers[position]!]) }
                }
                offsets.append(targets.count)
            }
        }
        return _MergedRows(count: n, slotOffsets: offsets, targets: targets, weights: readsEdges ? slotWeights : nil, symmetric: false)
    }

    @inlinable
    func _spectralWeights<W: BinaryInteger>(_ weight: (Edges.Index) -> W, allowsNegative: Bool = false) -> [Double] {
        SpectralGraphTheory._spectralWeights(edges.indices, count: edgeCount, weight, allowsNegative: allowsNegative)
    }

    @inlinable
    func _spectralWeights<W: BinaryFloatingPoint>(_ weight: (Edges.Index) -> W, allowsNegative: Bool = false) -> [Double] {
        SpectralGraphTheory._spectralWeights(edges.indices, count: edgeCount, weight, allowsNegative: allowsNegative)
    }
}
