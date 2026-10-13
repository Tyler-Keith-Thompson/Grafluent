#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
// A swift.org toolchain reading a newer macOS SDK (the fuzz build) gets a Darwin without libm's
// functions; the SDK's math module has them.
#if canImport(math_h)
import math_h
#endif

// Every procedure draws only through these two functions, so its output depends on the
// generator's `next()` sequence alone. The catalog's reference model reads the same bits, and its
// rows check outputs draw for draw. `Int.random(in:using:)` and `Double.random(in:using:)` are not
// used because the standard library does not promise their algorithms.

/// A double in [0, 1) from the top 53 bits of one draw.
@inlinable
@inline(__always)
func _uniform01<G: RandomNumberGenerator>(_ g: inout G) -> Double {
    Double(g.next() >> 11) * 0x1p-53
}

/// An `Int` in `0..<n` by rejection on the top k bits of each draw, where k is the bit length of n
/// (not of n − 1, so `_below(1)` still draws). At most two draws expected.
///
/// - Precondition: `n ≥ 1` (not checked).
@inlinable
@inline(__always)
func _below<G: RandomNumberGenerator>(_ n: Int, _ g: inout G) -> Int {
    // 64 − k, where k = 64 − n.leadingZeroBitCount.
    let shift = UInt64(truncatingIfNeeded: n.leadingZeroBitCount)
    while true {
        let r = Int(truncatingIfNeeded: g.next() >> shift)
        if r < n { return r }
    }
}

/// The natural logarithm. It is the one platform-dependent function in the procedures; G(n, p),
/// the block model and the random DAG use it to compute skips.
@inlinable
@inline(__always)
func _log(_ x: Double) -> Double {
    log(x)
}

/// Traps unless `p` is in 0...1 (so not NaN).
@inlinable
@inline(__always)
func _checkProbability(_ p: Double, _ name: StaticString) {
    precondition(p >= 0 && p <= 1, "\(name) \(p) is not in 0...1")
}
