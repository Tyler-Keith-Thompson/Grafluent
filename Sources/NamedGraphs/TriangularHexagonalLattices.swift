import GraphProtocols

// Triangular and hexagonal lattices, sized by their triangles and hexagons. A node is a
// coordinate pair (i, j), column i and row j; the few corner nodes the shapes leave out are
// skipped in the numbering.

/// The triangular lattice of m rows and n columns of triangles: N = ⌈n/2⌉ + 1 nodes in a row
/// (one fewer in each odd row when n is odd), numbered row by row, bottom row first. Row j has the
/// edges (i, j) – (i + 1, j), (i, j) – (i, j + 1), and (i + 1, j) – (i, j + 1) for even j or
/// (i, j) – (i + 1, j + 1) for odd j.
@usableFromInline
func _triangularLatticePairs(_ m: Int, _ n: Int) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    _checkCount(m, "rowCount")
    _checkCount(n, "columnCount")
    guard m > 0, n > 0 else { return (0, []) }
    let columns = (n + 1) / 2
    // At most (m + 1)(N + 1) nodes and three edges per node.
    precondition(columns < Int.max && _productFits(m + 1, columns + 1) && (m + 1) * (columns + 1) <= Int.max / 3,
                 "count overflows Int")
    let short = !n.isMultiple(of: 2)
    func width(_ j: Int) -> Int { short && !j.isMultiple(of: 2) ? columns : columns + 1 }
    var start = [Int](repeating: 0, count: m + 2)
    for j in 0 ... m { start[j + 1] = start[j] + width(j) }
    let count = start[m + 1]
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(3 * count)
    for j in 0 ... m {
        let here = start[j], w = width(j)
        for i in 0 ..< w - 1 { pairs.append(DirectedEdge(from: here + i, to: here + i + 1)) }
        guard j < m else { continue }
        let above = start[j + 1], wa = width(j + 1)
        for i in 0 ..< Swift.min(w, wa) { pairs.append(DirectedEdge(from: here + i, to: above + i)) }
        for i in 0 ..< columns {
            if j.isMultiple(of: 2) {
                pairs.append(DirectedEdge(from: here + i + 1, to: above + i))
            } else {
                pairs.append(DirectedEdge(from: here + i, to: above + i + 1))
            }
        }
    }
    return (count, _sortedPairs(vertexCount: count, pairs))
}

/// The hexagonal lattice of m rows and n columns of hexagons: columns 0 … n of 2m + 2 nodes,
/// numbered column by column, less node (0, 2m + 1) and the end of column n that has one edge
/// ((n, 0) for even n, (n, 2m + 1) for odd n). Column i has the edges (i, j) – (i, j + 1), and
/// (i, j) – (i + 1, j) where i and j have the same parity.
@usableFromInline
func _hexagonalLatticePairs(_ m: Int, _ n: Int) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    _checkCount(m, "rowCount")
    _checkCount(n, "columnCount")
    guard m > 0, n > 0 else { return (0, []) }
    precondition(m <= Int.max / 2 - 1 && n < Int.max, "count overflows Int")
    let rows = 2 * m + 2
    precondition(_productFits(n + 1, rows) && (n + 1) * rows <= Int.max / 2, "count overflows Int")
    // The first and one-past-last row of column i.
    func low(_ i: Int) -> Int { i == n && n.isMultiple(of: 2) ? 1 : 0 }
    func high(_ i: Int) -> Int { i == 0 || (i == n && !n.isMultiple(of: 2)) ? rows - 1 : rows }
    var start = [Int](repeating: 0, count: n + 2)
    for i in 0 ... n { start[i + 1] = start[i] + high(i) - low(i) }
    let count = start[n + 1]
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(2 * count)
    for i in 0 ... n {
        let first = low(i), last = high(i)
        let here = start[i] - first
        for j in first ..< last - 1 { pairs.append(DirectedEdge(from: here + j, to: here + j + 1)) }
        guard i < n else { continue }
        let next = start[i + 1] - low(i + 1)
        var j = i.isMultiple(of: 2) ? 0 : 1
        while j < rows {
            if j >= first, j < last, j >= low(i + 1), j < high(i + 1) {
                pairs.append(DirectedEdge(from: here + j, to: next + j))
            }
            j += 2
        }
    }
    return (count, _sortedPairs(vertexCount: count, pairs))
}

extension _GraphConstruction {
    /// The triangular lattice with `rowCount` rows and `columnCount` columns of triangles, counting
    /// those that point up and those that point down. The nodes form m + 1 rows of ⌈n/2⌉ + 1,
    /// numbered row by row from the bottom, each odd row shifted half a step to the right; when n
    /// is odd, each odd row has one node fewer. Each node joins its neighbors in its row, the one
    /// above it, and one diagonal neighbor above. Either count 0 gives the null graph. Sorted.
    /// O(n·m).
    ///
    /// - Precondition: both counts are non-negative, and the vertex count fits in `Int`.
    @inlinable
    public static func triangularLattice(rowCount m: Int, columnCount n: Int) -> Self {
        let (count, pairs) = _triangularLatticePairs(m, n)
        return Self(_vertexCount: count, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The hexagonal (honeycomb) lattice with `rowCount` rows and `columnCount` columns of
    /// hexagons. The nodes form n + 1 columns of 2m + 2, numbered column by column from the bottom
    /// of column 0, without the two corner nodes that would have a single edge: the top of column
    /// 0 and one end of column n. (n + 1)(2m + 2) − 2 vertices, every degree 2 or 3. Either count
    /// 0 gives the null graph. Sorted. O(n·m).
    ///
    /// - Precondition: both counts are non-negative, and the vertex count fits in `Int`.
    @inlinable
    public static func hexagonalLattice(rowCount m: Int, columnCount n: Int) -> Self {
        let (count, pairs) = _hexagonalLatticePairs(m, n)
        return Self(_vertexCount: count, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The triangular lattice with both arcs of every edge, in row-major order; numbering as the
    /// undirected `triangularLattice(rowCount:columnCount:)`. O(n·m).
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func triangularLattice(rowCount m: Int, columnCount n: Int) -> Self {
        let (count, pairs) = _triangularLatticePairs(m, n)
        return Self(_vertexCount: count, sortedEdges: _bothArcs(vertexCount: count, pairs), _ConstructionToken())
    }

    /// The hexagonal lattice with both arcs of every edge, in row-major order; numbering as the
    /// undirected `hexagonalLattice(rowCount:columnCount:)`. O(n·m).
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func hexagonalLattice(rowCount m: Int, columnCount n: Int) -> Self {
        let (count, pairs) = _hexagonalLatticePairs(m, n)
        return Self(_vertexCount: count, sortedEdges: _bothArcs(vertexCount: count, pairs), _ConstructionToken())
    }
}
