import BipartiteGraphs
import GraphProtocols

/// A cost matrix as the assignment engine reads it: one row at a time (`select`), each column's
/// cost or nil when the pair is forbidden. Rows never outnumber columns.
@usableFromInline
protocol _AssignmentCosts {
    associatedtype Cost: SignedNumeric & Comparable
    var rowCount: Int { get }
    var columnCount: Int { get }
    mutating func select(_ row: Int)
    func cost(_ column: Int) -> Cost?
}

/// Shortest augmenting paths with potentials, as scipy's `rectangular_lsap.cpp` (Crouse 2016) in
/// operation order: rows in order; per row, Dijkstra-like scans of the remaining columns, which
/// start in reverse order and are swap-removed as they are reached; among equal path costs the scan
/// keeps the first, except that an unassigned column replaces an equal assigned one. Returns the
/// column of each row, or nil when some row cannot be assigned.
@inlinable
func _shortestAugmentingPath<C: _AssignmentCosts>(_ costs: inout C) -> [Int]? {
    typealias W = C.Cost
    let nr = costs.rowCount, nc = costs.columnCount
    var u = [W](repeating: .zero, count: nr)
    var v = [W](repeating: .zero, count: nc)
    var shortest = [W](repeating: .zero, count: nc)
    var reached = [Bool](repeating: false, count: nc)
    var path = [Int](repeating: -1, count: nc)
    var col4row = [Int](repeating: -1, count: nr)
    var row4col = [Int](repeating: -1, count: nc)
    var remaining = [Int](repeating: 0, count: nc)
    var rowScanned = [Bool](repeating: false, count: nr)
    var columnScanned = [Bool](repeating: false, count: nc)
    for current in 0 ..< nr {
        var minimum = W.zero
        for k in 0 ..< nc { remaining[k] = nc - k - 1 }
        var count = nc
        for k in 0 ..< nr { rowScanned[k] = false }
        for k in 0 ..< nc {
            columnScanned[k] = false
            reached[k] = false
        }
        var i = current
        var sink = -1
        while sink == -1 {
            var index = -1
            var lowest = W.zero
            var lowestReached = false
            rowScanned[i] = true
            costs.select(i)
            for k in 0 ..< count {
                let j = remaining[k]
                if let c = costs.cost(j) {
                    let r = minimum + c - u[i] - v[j]
                    if !reached[j] || r < shortest[j] {
                        path[j] = i
                        shortest[j] = r
                        reached[j] = true
                    }
                }
                let less: Bool, equal: Bool
                if !lowestReached {
                    less = reached[j]
                    equal = !reached[j]
                } else {
                    less = reached[j] && shortest[j] < lowest
                    equal = reached[j] && shortest[j] == lowest
                }
                if index == -1 || less || (equal && row4col[j] == -1) {
                    lowest = shortest[j]
                    lowestReached = reached[j]
                    index = k
                }
            }
            guard lowestReached else { return nil }
            minimum = lowest
            let j = remaining[index]
            if row4col[j] == -1 { sink = j } else { i = row4col[j] }
            columnScanned[j] = true
            count -= 1
            remaining[index] = remaining[count]
        }
        u[current] += minimum
        for r in 0 ..< nr where rowScanned[r] && r != current {
            u[r] += minimum - shortest[col4row[r]]
        }
        for c in 0 ..< nc where columnScanned[c] {
            v[c] -= minimum - shortest[c]
        }
        var j = sink
        while true {
            let r = path[j]
            row4col[j] = r
            let previous = col4row[r]
            col4row[r] = j
            j = previous
            if r == current { break }
        }
    }
    return col4row
}

/// A dense matrix read once, already transposed and negated: values and an allowed flag per cell.
@frozen
@usableFromInline
struct _DenseCosts<Cost: SignedNumeric & Comparable>: _AssignmentCosts {
    @usableFromInline let rowCount: Int
    @usableFromInline let columnCount: Int
    @usableFromInline let values: [Cost]
    @usableFromInline let allowed: [Bool]
    @usableFromInline var start = 0

    @inlinable
    init(rowCount: Int, columnCount: Int, values: [Cost], allowed: [Bool]) {
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.values = values
        self.allowed = allowed
    }

    @inlinable
    mutating func select(_ row: Int) { start = row * columnCount }

    @inlinable
    func cost(_ column: Int) -> Cost? { allowed[start + column] ? values[start + column] : nil }
}

/// The result of `linearSumAssignment`: scipy's `(row_ind, col_ind)`, by ascending row.
@frozen
public struct LinearSumAssignment<Cost: Comparable & AdditiveArithmetic>: Equatable {
    /// The assigned rows, ascending.
    public let rows: [Int]
    /// The column assigned to each of `rows`.
    public let columns: [Int]
    /// The sum of the assigned costs in `rows` order.
    public let cost: Cost

    @inlinable
    init(rows: [Int], columns: [Int], cost: Cost) {
        self.rows = rows
        self.columns = columns
        self.cost = cost
    }
}

extension LinearSumAssignment: Hashable where Cost: Hashable {}
extension LinearSumAssignment: Sendable where Cost: Sendable {}

/// The assignment problem on a `rowCount` × `columnCount` cost matrix (scipy
/// `linear_sum_assignment`, the same assignment): min(rowCount, columnCount) pairs, no row or
/// column twice, least total cost (greatest with `maximize`). `cost(row, column)` is nil for a
/// forbidden pair. nil when no assignment avoids the forbidden pairs. A matrix with more rows than
/// columns is solved transposed, as scipy does. O(r² c) time, r ≤ c the dimensions, and O(r c)
/// memory: `cost` is called once per cell, into a matrix, as scipy takes one. Integer costs are
/// exact (scipy converts to `Double`).
///
/// - Precondition: both counts are at least zero; no cost is NaN or infinite.
@inlinable
public func linearSumAssignment<W: SignedNumeric & Comparable>(rowCount: Int, columnCount: Int, maximize: Bool = false, cost: (_ row: Int, _ column: Int) -> W?) -> LinearSumAssignment<W>? {
    precondition(rowCount >= 0 && columnCount >= 0, "The counts must be at least zero")
    guard rowCount > 0, columnCount > 0 else { return LinearSumAssignment(rows: [], columns: [], cost: .zero) }
    let transposed = columnCount < rowCount
    let nr = transposed ? columnCount : rowCount, nc = transposed ? rowCount : columnCount
    return withoutActuallyEscaping(cost) { cost in
        // Read once per cell, transposed and negated, as scipy builds its matrix.
        let cells = nr * nc
        var values = [W](repeating: .zero, count: cells)
        var allowed = [Bool](repeating: false, count: cells)
        for i in 0 ..< nr {
            for j in 0 ..< nc {
                guard let x = transposed ? cost(j, i) : cost(i, j) else { continue }
                precondition(x == x, "A cost is NaN")
                values[i * nc + j] = maximize ? -x : x
                allowed[i * nc + j] = true
            }
        }
        var dense = _DenseCosts(rowCount: nr, columnCount: nc, values: values, allowed: allowed)
        let solved = _shortestAugmentingPath(&dense)
        guard let col4row = solved else { return nil }
        var rows: [Int] = [], columns: [Int] = []
        if transposed {
            // Rows of the transposed problem are columns: read back sorted by original row.
            let order = col4row.indices.sorted { col4row[$0] < col4row[$1] }
            rows = order.map { col4row[$0] }
            columns = order
        } else {
            rows = Array(0 ..< rowCount)
            columns = col4row
        }
        var total = W.zero
        for (r, c) in zip(rows, columns) { total += cost(r, c)! }
        return LinearSumAssignment(rows: rows, columns: columns, cost: total)
    }
}

/// The biadjacency matrix of a bipartite graph without building it: each row vertex keeps its
/// columns with the lightest copy's weight and edge number (earliest on ties), scattered into one
/// scratch row when selected.
@frozen
@usableFromInline
struct _GraphCosts<Cost: SignedNumeric & Comparable>: _AssignmentCosts {
    @usableFromInline let rowCount: Int
    @usableFromInline let columnCount: Int
    @usableFromInline let offsets: [Int]
    @usableFromInline let columns: [Int]
    @usableFromInline let weights: [Cost]
    @usableFromInline let edges: [Int]
    @usableFromInline var scratch: [Cost]
    @usableFromInline var stamp: [Int]
    @usableFromInline var row = -1

    @inlinable
    init(rowCount: Int, columnCount: Int, offsets: [Int], columns: [Int], weights: [Cost], edges: [Int]) {
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.offsets = offsets
        self.columns = columns
        self.weights = weights
        self.edges = edges
        scratch = [Cost](repeating: .zero, count: columnCount)
        stamp = [Int](repeating: -1, count: columnCount)
    }

    @inlinable
    mutating func select(_ row: Int) {
        self.row = row
        for k in offsets[row] ..< offsets[row + 1] {
            stamp[columns[k]] = row
            scratch[columns[k]] = weights[k]
        }
    }

    @inlinable
    func cost(_ column: Int) -> Cost? { stamp[column] == row ? scratch[column] : nil }
}

/// The least-weight matching covering the smaller side, or nil: rows `rowSide`, columns the others
/// by their order in `columnSide`, each pair's lightest copy (earliest on ties).
@inlinable
func _fullMatching<W: SignedNumeric & Comparable>(_ structure: _MatchingGraph, rowSide: [Int], columnSide: [Int], weights: [W]) -> [Int]? {
    let n = structure.count
    var columnNumber = [Int](repeating: -1, count: n)
    for (k, v) in columnSide.enumerated() { columnNumber[v] = k }
    var offsets = [0], columns: [Int] = [], costs: [W] = [], edges: [Int] = []
    var seen = [Int](repeating: -1, count: columnSide.count)
    for v in rowSide {
        let start = columns.count
        for slot in structure.offsets[v] ..< structure.offsets[v + 1] {
            let c = columnNumber[structure.targets[slot]]
            precondition(c >= 0, "An edge joins two vertices on one side: the bipartition is not this graph's")
            let e = structure.edges[slot], w = weights[e]
            if seen[c] >= start, columns[seen[c]] == c {
                let k = seen[c]
                if w < costs[k] || (w == costs[k] && e < edges[k]) {
                    costs[k] = w
                    edges[k] = e
                }
            } else {
                seen[c] = columns.count
                columns.append(c)
                costs.append(w)
                edges.append(e)
            }
        }
        offsets.append(columns.count)
    }
    // A row with no edge cannot be assigned.
    for r in rowSide.indices where offsets[r] == offsets[r + 1] { return nil }
    var provider = _GraphCosts(rowCount: rowSide.count, columnCount: columnSide.count, offsets: offsets, columns: columns, weights: costs, edges: edges)
    guard rowSide.count > 0, columnSide.count > 0 else { return [Int](repeating: -1, count: n) }
    guard let col4row = _shortestAugmentingPath(&provider) else { return nil }
    var mateEdge = [Int](repeating: -1, count: n)
    for (r, c) in col4row.enumerated() {
        var e = -1
        for k in offsets[r] ..< offsets[r + 1] where columns[k] == c { e = edges[k] }
        mateEdge[rowSide[r]] = e
        mateEdge[columnSide[c]] = e
    }
    return mateEdge
}

extension Graph {
    @inlinable
    func _minimumWeightFullMatching<W: SignedNumeric & Comparable>(left: [Int], right: [Int], structure: _MatchingGraph, weight: (Edges.Index) -> W) -> Matching<Self, W>? {
        let weights = _matchingWeights(structure, weight, { $0 == $0 }, "A weight is NaN")
        // A tall matrix is solved transposed, as scipy does.
        let mateEdge = left.count <= right.count
            ? _fullMatching(structure, rowSide: left, columnSide: right, weights: weights)
            : _fullMatching(structure, rowSide: right, columnSide: left, weights: weights)
        guard let mateEdge else { return nil }
        return Matching(self, listed: _listedVertices(), structure: structure, mateEdge: mateEdge, weights: weights)
    }

    /// A least-weight matching covering the smaller side of a bipartite graph, or nil when none
    /// exists (NetworkX `minimum_weight_full_matching`): scipy's assignment on the biadjacency
    /// matrix, rows `bipartition.left`, columns `bipartition.right` in these orders (NetworkX's
    /// columns follow set iteration, so its matching can differ among equal-weight ones), missing
    /// edges forbidden, each pair's lightest copy (NetworkX keeps the last copy on a multigraph). The matrix is never built: memory O(n + m). An empty
    /// side gives the empty matching. `weight` is called once per edge, in position order.
    /// O(s² t), s ≤ t the side sizes.
    ///
    /// - Precondition: `bipartition` is this graph's; no weight is NaN or infinite.
    @inlinable
    public func minimumWeightFullMatching<W: SignedNumeric & Comparable>(bipartition: Bipartition<Self>, weight: (Edges.Index) -> W) -> Matching<Self, W>? {
        let structure = _matchingGraph()
        let n = structure.count
        precondition(bipartition.left.count + bipartition.right.count == n, "The bipartition is not this graph's")
        var left: [Int] = [], right: [Int] = []
        for v in 0 ..< n {
            if bipartition.side(ofIndex: v) == .left { left.append(v) } else { right.append(v) }
        }
        return _minimumWeightFullMatching(left: left, right: right, structure: structure, weight: weight)
    }
}

extension BipartiteGraph {
    /// A least-weight matching covering the smaller side, or nil when none exists: as `Graph`'s, rows
    /// `left`, columns `right`, in their orders.
    ///
    /// - Precondition: no weight is NaN or infinite.
    @inlinable
    public func minimumWeightFullMatching<W: SignedNumeric & Comparable>(weight: (Int) -> W) -> Matching<Self, W>? {
        let structure = _matchingGraph()
        let leftNumbers = left.map { vertexIndex(of: $0) }
        let rightNumbers = right.map { vertexIndex(of: $0) }
        return _minimumWeightFullMatching(left: leftNumbers, right: rightNumbers, structure: structure, weight: weight)
    }
}
