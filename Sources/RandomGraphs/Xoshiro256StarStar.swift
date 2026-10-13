/// The xoshiro256** 1.0 pseudorandom number generator, with 256 bits of state and period
/// 2^256 − 1.
///
/// > David Blackman and Sebastiano Vigna. Scrambled Linear Pseudorandom Number Generators.
/// > *ACM Transactions on Mathematical Software* 47(4), article 36 (2021). doi:10.1145/3460772
///
/// A copy replays the same stream, and two generators are equal when their states are equal. Not
/// for cryptography.
@frozen
public struct Xoshiro256StarStar: RandomNumberGenerator, Equatable, Hashable, Sendable {
    @usableFromInline var s0: UInt64
    @usableFromInline var s1: UInt64
    @usableFromInline var s2: UInt64
    @usableFromInline var s3: UInt64

    /// The generator whose state is the next four outputs of SplitMix64 started at `seed`. SplitMix64
    /// is Steele, Lea and Flood's generator ("Fast Splittable Pseudorandom Number Generators",
    /// OOPSLA 2014), whose outputs are never four zeros in a row, so every seed is valid.
    @inlinable
    public init(seed: UInt64) {
        var x = seed
        s0 = Self._splitMix64(&x)
        s1 = Self._splitMix64(&x)
        s2 = Self._splitMix64(&x)
        s3 = Self._splitMix64(&x)
    }

    /// The generator with exactly these four state words.
    ///
    /// - Precondition: The four words are not all zero.
    @inlinable
    public init(state: (UInt64, UInt64, UInt64, UInt64)) {
        precondition(state.0 | state.1 | state.2 | state.3 != 0, "the state must not be all zero")
        (s0, s1, s2, s3) = state
    }

    /// The next 64 bits: `rotl(s1 · 5, 7) · 9`, then the linear step. O(1).
    @inlinable
    @inline(__always)
    public mutating func next() -> UInt64 {
        let result = Self._rotateLeft(s1 &* 5, 7) &* 9
        let t = s1 << 17
        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3
        s2 ^= t
        s3 = Self._rotateLeft(s3, 45)
        return result
    }

    @inlinable
    @inline(__always)
    static func _rotateLeft(_ x: UInt64, _ k: UInt64) -> UInt64 {
        (x << k) | (x >> (64 - k))
    }

    @inlinable
    static func _splitMix64(_ x: inout UInt64) -> UInt64 {
        x &+= 0x9E37_79B9_7F4A_7C15
        var z = x
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension Xoshiro256StarStar: CustomStringConvertible {
    /// The four state words.
    public var description: String { "Xoshiro256StarStar(state: (\(s0), \(s1), \(s2), \(s3)))" }
}
