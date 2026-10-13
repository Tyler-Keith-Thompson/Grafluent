import CompressedSparseRowModule

/// A square matrix of `Double`s in compressed sparse row form, storing exactly its nonzero
/// entries: the result of `adjacencyMatrix()`, `laplacianMatrix()` and the other graph matrices.
///
/// Row `i` holds the entries `values[offsets[i] ..< offsets[i + 1]]` in the columns
/// `columns[offsets[i] ..< offsets[i + 1]]`, ascending. No stored value is 0, so two matrices are
/// equal exactly when every entry is, and `nonzeroCount` counts the nonzero entries.
///
/// Not the representation `AdjacencyMatrix`, which is a graph stored as a bit matrix: this is a
/// numeric matrix of any graph, built by the methods of this module.
@frozen
public struct SparseMatrix: Hashable, Sendable {
    @usableFromInline var _offsets: [Int]
    @usableFromInline var _columns: [Int]
    @usableFromInline var _values: [Double]

    /// Unchecked: `offsets` starts at 0 and ends at `columns.count`, each row's columns ascend in
    /// `0..<rowCount`, and no value is 0.
    @inlinable
    init(_offsets: [Int], _columns: [Int], _values: [Double]) {
        self._offsets = _offsets
        self._columns = _columns
        self._values = _values
    }

    /// The number of rows, which is also the number of columns.
    @inlinable
    public var rowCount: Int { _offsets.count - 1 }

    /// Where each row starts in `columns` and `values`: `rowCount + 1` entries, the first 0 and the
    /// last `nonzeroCount`, as `CompressedSparseRow.offsets`.
    @inlinable
    public var offsets: [Int] { _offsets }

    /// The column of each stored entry, ascending within each row.
    @inlinable
    public var columns: [Int] { _columns }

    /// The value of each stored entry, aligned with `columns`; never 0.
    @inlinable
    public var values: [Double] { _values }

    /// The number of stored entries, which are exactly the nonzero ones.
    @inlinable
    public var nonzeroCount: Int { _columns.count }

    /// The entry in `row` and `column`: 0 when nothing is stored there. O(log k) for a row of k
    /// stored entries.
    ///
    /// - Precondition: `row` and `column` are in `0..<rowCount`.
    @inlinable
    public subscript(row: Int, column: Int) -> Double {
        let n = rowCount
        precondition(row >= 0 && row < n && column >= 0 && column < n, "SparseMatrix index out of range")
        var low = _offsets[row], high = _offsets[row + 1]
        while low < high {
            let middle = low + (high - low) / 2
            let c = _columns[middle]
            if c == column { return _values[middle] }
            if c < column { low = middle + 1 } else { high = middle }
        }
        return 0
    }

    /// The stored positions as a directed graph on `0..<rowCount`: an arc i → j for each stored
    /// entry (the sparsity pattern). O(1): it shares `offsets` and `columns`.
    @inlinable
    public var pattern: CompressedSparseRow { CompressedSparseRow(_offsets: _offsets, _targets: _columns) }

    /// The product of `matrix` and the column `vector`. O(rowCount + nonzeroCount).
    ///
    /// - Precondition: `vector.count == matrix.rowCount`.
    @inlinable
    public static func * (matrix: SparseMatrix, vector: [Double]) -> [Double] {
        let n = matrix.rowCount
        precondition(vector.count == n, "The vector's length is not the matrix's size")
        var result = [Double](repeating: 0, count: n)
        for i in 0 ..< n {
            var sum = 0.0
            for k in matrix._offsets[i] ..< matrix._offsets[i + 1] {
                sum += matrix._values[k] * vector[matrix._columns[k]]
            }
            result[i] = sum
        }
        return result
    }
}

extension SparseMatrix: CustomStringConvertible {
    /// The size and the stored entries row by row, as `(column: value)` pairs.
    public var description: String {
        var text = "SparseMatrix(\(rowCount)×\(rowCount), \(nonzeroCount) stored"
        for i in 0 ..< rowCount {
            let entries = (_offsets[i] ..< _offsets[i + 1]).map { "\(_columns[$0]): \(_values[$0])" }
            text += i == 0 ? ": " : "; "
            text += "[\(entries.joined(separator: ", "))]"
        }
        return text + ")"
    }
}
