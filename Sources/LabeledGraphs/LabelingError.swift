/// The requirement of `LabeledGraph.init(_:labels:)` that a base and its labels break.
///
/// The requirements are checked in the order of the cases. Decoding reports the same failures as
/// `DecodingError.dataCorrupted`. Cases report positions rather than labels, because a label type
/// need not be `Sendable`.
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
