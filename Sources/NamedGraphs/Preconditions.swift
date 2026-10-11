// The size checks every family makes before it allocates. Products are guarded by division, not
// `multipliedReportingOverflow` with the product discarded, which Swift 6.4 folded to "no
// overflow" under -O in one module (Flows).

/// Traps unless `count` is not negative.
@inlinable
@inline(__always)
package func _checkCount(_ count: Int, _ name: StaticString = "vertexCount") {
    precondition(count >= 0, "\(name) \(count) is negative")
}

/// Whether `a · b` fits in `Int`, for `a, b ≥ 0`.
@inlinable
@inline(__always)
package func _productFits(_ a: Int, _ b: Int) -> Bool {
    a == 0 || b <= Int.max / a
}

/// The number of pairs u < v of `0..<n` (n(n − 1)/2), or nil when it overflows `Int`.
@inlinable
package func _unorderedPairCount(_ n: Int) -> Int? {
    guard n >= 2 else { return 0 }
    let (a, b) = n.isMultiple(of: 2) ? (n / 2, n - 1) : (n, (n - 1) / 2)
    return _productFits(a, b) ? a * b : nil
}

/// The number of pairs u ≠ v of `0..<n` (n(n − 1)), or nil when it overflows `Int`.
@inlinable
package func _orderedPairCount(_ n: Int) -> Int? {
    guard n >= 2 else { return 0 }
    return _productFits(n, n - 1) ? n * (n - 1) : nil
}
