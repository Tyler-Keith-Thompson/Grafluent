import GraphProtocols

/// Pearson's correlation of the pairs (x[v], y[w]), one per slot of row v with target w. Nil
/// with no pairs, or when every pair has the same x or the same y. Two passes: the means, then
/// the centred sums, so equal values give exactly zero variance. Clamped to [−1, 1].
@inlinable
func _pearson(_ rows: _CompressedRows, _ x: [Double], _ y: [Double]) -> Double? {
    let n = rows.count
    let m = rows.targets.count
    guard m > 0 else { return nil }
    return rows.offsets.withUnsafeBufferPointer { offsets in
        rows.targets.withUnsafeBufferPointer { targets in
            x.withUnsafeBufferPointer { x in
                y.withUnsafeBufferPointer { y -> Double? in
                    var sumX = 0.0, sumY = 0.0
                    var leastX = Double.infinity, greatestX = -Double.infinity
                    var leastY = Double.infinity, greatestY = -Double.infinity
                    for v in 0 ..< n {
                        let count = offsets[v + 1] - offsets[v]
                        guard count > 0 else { continue }
                        let value = x[v]
                        sumX += Double(count) * value
                        if value < leastX { leastX = value }
                        if value > greatestX { greatestX = value }
                    }
                    for k in 0 ..< m {
                        let value = y[targets[k]]
                        sumY += value
                        if value < leastY { leastY = value }
                        if value > greatestY { greatestY = value }
                    }
                    guard leastX < greatestX, leastY < greatestY else { return nil }
                    let meanX = sumX / Double(m), meanY = sumY / Double(m)
                    var cross = 0.0, squaresX = 0.0, squaresY = 0.0
                    for v in 0 ..< n {
                        let start = offsets[v], end = offsets[v + 1]
                        guard start < end else { continue }
                        var row = 0.0, rowSquares = 0.0
                        for k in start ..< end {
                            let dy = y[targets[k]] - meanY
                            row += dy
                            rowSquares += dy * dy
                        }
                        let dx = x[v] - meanX
                        cross += dx * row
                        squaresX += Double(end - start) * dx * dx
                        squaresY += rowSquares
                    }
                    let r = cross / (squaresX.squareRoot() * squaresY.squareRoot())
                    return min(1, max(-1, r))
                }
            }
        }
    }
}

/// Newman's assortativity coefficient for classes: (Σ e_cc − Σ a_c b_c) / (1 − Σ a_c b_c) over
/// the pairs (class[v], class[w]), one per slot of row v with target w; a_c and b_c the
/// fractions of pairs whose first and second member is in class c. Nil with no pairs, or when
/// every pair is within one class.
@inlinable
func _classAssortativity(_ rows: _CompressedRows, _ classes: [Int], count k: Int) -> Double? {
    let n = rows.count
    let m = rows.targets.count
    guard m > 0 else { return nil }
    var first = [Int](repeating: 0, count: k), second = [Int](repeating: 0, count: k)
    var same = 0
    for v in 0 ..< n {
        let c = classes[v]
        first[c] += rows.degree(v)
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
            let d = classes[rows.targets[slot]]
            second[d] += 1
            if c == d { same += 1 }
        }
    }
    var products = 0.0
    for c in 0 ..< k {
        if first[c] == m && second[c] == m { return nil }
        products += Double(first[c]) * Double(second[c])
    }
    let total = Double(m)
    return (total * Double(same) - products) / (total * total - products)
}

/// Each vertex's class number, in order of first appearance.
@inlinable
func _classNumbers<C: Hashable>(_ values: [C]) -> (classes: [Int], count: Int) {
    var numbers: [C: Int] = [:]
    var classes: [Int] = []
    classes.reserveCapacity(values.count)
    for value in values {
        if let c = numbers[value] {
            classes.append(c)
        } else {
            let c = numbers.count
            numbers[value] = c
            classes.append(c)
        }
    }
    return (classes, numbers.count)
}

extension Graph {
    /// Newman's degree assortativity coefficient: Pearson's correlation of the degrees at the two
    /// ends of an edge, each edge read in both directions (a self-loop twice, as its degree
    /// counts it). Parallel copies each count. Nil without edges or when every edge end has the
    /// same degree (a regular graph). O(n + m).
    @inlinable
    public func degreeAssortativityCoefficient() -> Double? {
        _runOnUndirectedRows(_IncidenceRowsAlgorithm(_DegreePearson(source: .out, target: .out, symmetric: true)))
    }

    /// The degree assortativity coefficient over weighted degrees: each vertex's degree is the
    /// sum of its edges' weights (a self-loop's twice). Each edge still counts once each way.
    /// `weight` is called once per edge, in position order. O(n + m).
    ///
    /// - Parameter weight: The weight of the edge at a position.
    /// - Returns: The coefficient in [−1, 1]; nil without edges or when every edge end has the
    ///   same weighted degree.
    /// - Precondition: Every weight is finite.
    @inlinable
    public func degreeAssortativityCoefficient<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Double? {
        let rows = _assortativityRows(readsEdges: true)
        let degrees = _rowDegrees(rows, _finiteWeights(weight))
        return _pearson(rows, degrees, degrees)
    }

    /// Newman's attribute assortativity coefficient for categorical classes: (Σ e_cc − Σ a_c²) /
    /// (1 − Σ a_c²), e_cd the fraction of edge ends joining class c to class d (each edge read in
    /// both directions, a self-loop twice). 1 when every edge stays within its class.
    /// `attribute` is called once per vertex, in `vertices` order. O(n + m) expected.
    ///
    /// - Parameter attribute: The class of a vertex.
    /// - Returns: The coefficient, at most 1; nil without edges or when every edge joins
    ///   vertices of one single class.
    @inlinable
    public func attributeAssortativityCoefficient<C: Hashable>(attribute: (Vertex) -> C) -> Double? {
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: false, dropsLoops: false), vertexNumbering: numbering)
        let (classes, count) = _classNumbers(_vertexValues(numbering?.listed, attribute))
        return _classAssortativity(rows, classes, count: count)
    }

    /// Newman's numeric assortativity coefficient: Pearson's correlation of the values at the
    /// two ends of an edge, each edge read in both directions (a self-loop twice).
    /// `attribute` is called once per vertex, in `vertices` order. O(n + m).
    ///
    /// - Parameter attribute: The value of a vertex.
    /// - Returns: The coefficient in [−1, 1]; nil without edges or when every edge end has the
    ///   same value.
    /// - Precondition: Every value is finite.
    @inlinable
    public func numericAssortativityCoefficient<W: BinaryFloatingPoint>(attribute: (Vertex) -> W) -> Double? {
        let numbering = _vertexNumbering()
        let values = _vertexValues(numbering?.listed) { (v: Vertex) -> Double in
            let value = Double(attribute(v))
            precondition(value.isFinite, "Vertex values must be finite")
            return value
        }
        return _runOnUndirectedRows(_IncidenceRowsAlgorithm(_ValuePearson(values, symmetric: true)), vertexNumbering: numbering)
    }
}

extension DirectedGraph {
    /// Newman's degree assortativity coefficient for directed graphs: Pearson's correlation,
    /// over the arcs, of the `source` degree of each arc's tail with the `target` degree of its
    /// head. A self-loop is one arc; parallel arcs each count. O(n + m).
    ///
    /// - Parameters:
    ///   - source: The degree read at each arc's tail; out-degree by default.
    ///   - target: The degree read at each arc's head; in-degree by default.
    /// - Returns: The coefficient in [−1, 1]; nil without arcs or when every tail, or every
    ///   head, has the same degree.
    @inlinable
    public func degreeAssortativityCoefficient(source: DegreeType = .out, target: DegreeType = .in) -> Double? {
        _runOnArcRows(_DegreePearson(source: source, target: target, symmetric: false)).output
    }

    /// The directed degree assortativity coefficient over weighted degrees: each degree is the
    /// sum of the weights of the arcs it counts. Each arc still counts once. `weight` is called
    /// once per edge, in position order. O(n + m).
    ///
    /// - Parameters:
    ///   - source: The weighted degree read at each arc's tail; out by default.
    ///   - target: The weighted degree read at each arc's head; in by default.
    ///   - weight: The weight of the edge at a position.
    /// - Returns: The coefficient in [−1, 1]; nil without arcs or when every tail, or every
    ///   head, has the same weighted degree.
    /// - Precondition: Every weight is finite.
    @inlinable
    public func degreeAssortativityCoefficient<W: BinaryFloatingPoint>(source: DegreeType = .out, target: DegreeType = .in, weight: (Edges.Index) -> W) -> Double? {
        let rows = _compressedRows(readsEdges: true, dropsLoops: false).rows
        let degrees = _arcDegrees(rows, _finiteWeights(weight))
        return _pearson(rows, _degrees(source, degrees), _degrees(target, degrees))
    }

    /// Newman's attribute assortativity coefficient for categorical classes, over the arcs:
    /// (Σ e_cc − Σ a_c b_c) / (1 − Σ a_c b_c), e_cd the fraction of arcs from class c to class
    /// d, a_c and b_c the fractions of arcs leaving and entering class c. `attribute` is called
    /// once per vertex, in `vertices` order. O(n + m) expected.
    ///
    /// - Parameter attribute: The class of a vertex.
    /// - Returns: The coefficient, at most 1; nil without arcs or when every arc joins vertices
    ///   of one single class.
    @inlinable
    public func attributeAssortativityCoefficient<C: Hashable>(attribute: (Vertex) -> C) -> Double? {
        let copied = _compressedRows(readsEdges: false, dropsLoops: false)
        let (classes, count) = _classNumbers(_vertexValues(copied.numbering?.listed, attribute))
        return _classAssortativity(copied.rows, classes, count: count)
    }

    /// Newman's numeric assortativity coefficient over the arcs: Pearson's correlation of the
    /// value at each arc's tail with the value at its head. `attribute` is called once per
    /// vertex, in `vertices` order. O(n + m).
    ///
    /// - Parameter attribute: The value of a vertex.
    /// - Returns: The coefficient in [−1, 1]; nil without arcs or when every tail, or every
    ///   head, has the same value.
    /// - Precondition: Every value is finite.
    @inlinable
    public func numericAssortativityCoefficient<W: BinaryFloatingPoint>(attribute: (Vertex) -> W) -> Double? {
        let values = _vertexValues(_listedVertices()) { (v: Vertex) -> Double in
            let value = Double(attribute(v))
            precondition(value.isFinite, "Vertex values must be finite")
            return value
        }
        return _runOnArcRows(_ValuePearson(values, symmetric: false)).output
    }
}
