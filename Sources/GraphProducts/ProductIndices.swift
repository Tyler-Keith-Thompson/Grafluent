// The product numbering: vertex (g, h) at index(g)·|V(H)| + index(h), with its checks.

/// The two factors' vertex counts, checked: both factors need vertex indices, and the product's
/// count must fit in an `Int`. The guard is a comparison, not an overflow-reporting multiply.
@inlinable
func _factorCounts(_ first: Int?, _ second: Int?) -> (first: Int, second: Int) {
    guard let nG = first, let nH = second else {
        preconditionFailure("A factor has no vertex indices (vertexIndexBound is nil); a product needs them in phase 1")
    }
    precondition(nH == 0 || nG <= Int.max / nH, "The vertex count |V(G)|·|V(H)| = \(nG)·\(nH) overflows Int")
    return (nG, nH)
}

/// A factor's index of a part of a pair, checked against its bound.
@inlinable
@inline(__always)
func _checkedIndex(_ index: Int, bound: Int, _ part: some Any) -> Int {
    precondition(UInt(bitPattern: index) < UInt(bitPattern: bound), "\(part) is not a vertex of the factor")
    return index
}

/// A product vertex index, checked.
@inlinable
@inline(__always)
func _checkProductIndex(_ index: Int, count: Int) {
    precondition(UInt(bitPattern: index) < UInt(bitPattern: count), "Vertex index \(index) is out of range 0..<\(count)")
}
