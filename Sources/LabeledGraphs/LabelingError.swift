/// Why a base and its labels cannot form a `LabeledGraph`: the requirements of
/// `LabeledGraph.init(_:labels:)`, checked in the order of the cases. Decoding reports the same
/// failures as `DecodingError.dataCorrupted`.
///
/// No case carries a label: an `Error` must be `Sendable` and a label type needn't be, and the
/// caller already holds the labels. `CompressedSparseRow.ValidationError` reports its arrays the
/// same way, by position.
public enum LabelingError: Error, Hashable, Sendable {
    /// The base's `vertexIndexBound` is `nil`: its vertex indices have holes.
    case baseNotDenselyIndexed
    /// The base's vertices are not `0..<vertexCount` in index order.
    case baseVerticesNotInIndexOrder
    /// The number of labels is not the base's vertex count.
    case labelCountMismatch(labelCount: Int, vertexCount: Int)
    /// The label at this offset in `labels` repeats an earlier one.
    case duplicateLabel(position: Int)
}
