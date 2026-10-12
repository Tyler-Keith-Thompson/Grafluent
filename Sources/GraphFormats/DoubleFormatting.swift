/// Doubles written as text: the shortest digits that round-trip (Giulietti's Schubfach, as Java's
/// `DoubleToDecimal` computes them; the same digits as Swift's `description` and Python's `repr`),
/// laid out by Python's `repr` rule or by SciPy's Matrix Market rule. Only public API: the table
/// is generated (`scripts/schubfach_table.py`), and the arithmetic is 64-bit multiplications.

/// The shortest round-trip decimal digits of a finite, nonzero `|x|`: `count` digits in `digits`,
/// with no leading or trailing zeros, and the decimal exponent of the first, so that
/// `|x| = d₀.d₁d₂… × 10^exponent`.
@usableFromInline internal struct _ShortestDigits {
    @inlinable
    init() {
    }

    /// Up to 17 digits, as ASCII.
    @usableFromInline var digits: (UInt64, UInt64, UInt64) = (0, 0, 0)
    @usableFromInline var count = 0
    @usableFromInline var exponent = 0

    @inline(__always)
    @inlinable func digit(_ k: Int) -> UInt8 {
        withUnsafeBytes(of: digits) { $0[k] }
    }
}

/// `floor(e × log10(2))`, for `|e|` ≤ 5,456,721.
@inline(__always)
@inlinable func _floorLog10Pow2(_ e: Int) -> Int { (e &* 661_971_961_083) >> 41 }

/// `floor(e × log10(2) − log10(4/3))`, for `|e|` ≤ 5,456,721.
@inline(__always)
@inlinable func _floorLog10ThreeQuartersPow2(_ e: Int) -> Int { (e &* 661_971_961_083 &- 274_743_187_321) >> 41 }

/// `floor(e × log2(10))`, for `|e|` ≤ 1,838,394.
@inline(__always)
@inlinable func _floorLog2Pow10(_ e: Int) -> Int { (e &* 913_124_641_741) >> 38 }

/// Schubfach's rounding of `cp × g / 2^127` to odd: the high bits, with a sticky low bit.
@inline(__always)
@inlinable func _roundToOdd(_ g1: UInt64, _ g0: UInt64, _ cp: UInt64) -> UInt64 {
    let x1 = g0.multipliedFullWidth(by: cp).high
    let y0 = g1 &* cp
    let y1 = g1.multipliedFullWidth(by: cp).high
    let z = (y0 >> 1) &+ x1
    let vbp = y1 &+ (z >> 63)
    return vbp | (((z & 0x7FFF_FFFF_FFFF_FFFF) &+ 0x7FFF_FFFF_FFFF_FFFF) >> 63)
}

/// The shortest decimal `f × 10^e` that rounds to the finite, positive `x` (Schubfach): `f` may
/// end in zeros. Java's `DoubleToDecimal.toDecimal` without its case for the two smallest
/// subnormals (`c < C_TINY`): the general path gives them the same digits, which the tests check
/// against `description` with the rest.
@inlinable func _schubfach(_ x: Double) -> (significand: UInt64, exponent: Int) {
    let bits = x.bitPattern
    let biased = Int(truncatingIfNeeded: (bits >> 52) & 0x7FF)
    let fraction = bits & ((1 << 52) &- 1)
    var q = -1074
    var c = fraction
    if biased != 0 {
        q = biased &- 1075
        c = (1 << 52) | fraction
        // An integer below 2⁵³: its own digits.
        if q < 0 && q > -53 {
            let f = c >> UInt64(-q)
            if f << UInt64(-q) == c { return (f, 0) }
        }
    }
    let odd = c & 1
    let cb = c << 2
    let cbr = cb &+ 2
    let cbl: UInt64
    let k: Int
    if c != 1 << 52 || q == -1074 {
        cbl = cb &- 2
        k = _floorLog10Pow2(q)
    } else {
        // The lower neighbour is half as far: a power of two.
        cbl = cb &- 1
        k = _floorLog10ThreeQuartersPow2(q)
    }
    let h = q &+ _floorLog2Pow10(-k) &+ 2
    let index = (k &+ 324) << 1
    let g1 = _schubfachTable[index], g0 = _schubfachTable[index &+ 1]
    let vb = _roundToOdd(g1, g0, cb << UInt64(h))
    let vbl = _roundToOdd(g1, g0, cbl << UInt64(h))
    let vbr = _roundToOdd(g1, g0, cbr << UInt64(h))
    let s = vb >> 2
    if s >= 100 {
        // One digit shorter, when a multiple of 10 is inside the rounding interval.
        let sp10 = 10 &* (s.multipliedFullWidth(by: 115_292_150_460_684_698 << 4).high)
        let tp10 = sp10 &+ 10
        let upin = vbl &+ odd <= sp10 << 2
        let wpin = (tp10 << 2) &+ odd <= vbr
        if upin != wpin { return (upin ? sp10 : tp10, k) }
    }
    let t = s &+ 1
    let uin = vbl &+ odd <= s << 2
    let win = (t << 2) &+ odd <= vbr
    if uin != win { return (uin ? s : t, k) }
    // Both in: the closer one, ties to even.
    let cmp = Int64(bitPattern: vb &- ((s &+ t) << 1))
    return (cmp < 0 || (cmp == 0 && s & 1 == 0) ? s : t, k)
}

/// "00", "01", …, "99": two digits per lookup.
@usableFromInline internal let _digitPairs: StaticString =
    "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899"

/// The shortest digits of a finite, nonzero `x` (its sign ignored), written two at a time.
@inlinable func _shortestDigits(_ x: Double) -> _ShortestDigits {
    var (f, e) = _schubfach(x.magnitude)
    while f % 10 == 0 {
        f /= 10
        e &+= 1
    }
    var count = 1
    var bound: UInt64 = 10
    while count < 19 && f >= bound {
        count &+= 1
        bound &*= 10
    }
    var result = _ShortestDigits()
    result.count = count
    result.exponent = e &+ count &- 1
    withUnsafeMutableBytes(of: &result.digits) { out in
        _digitPairs.withUTF8Buffer { pairs in
            var k = count
            while f >= 100 {
                let r = Int(truncatingIfNeeded: f % 100) &* 2
                f /= 100
                k &-= 2
                out[k] = pairs[r]
                out[k &+ 1] = pairs[r &+ 1]
            }
            if f >= 10 {
                let r = Int(truncatingIfNeeded: f) &* 2
                out[k &- 2] = pairs[r]
                out[k &- 1] = pairs[r &+ 1]
            } else {
                out[k &- 1] = UInt8(truncatingIfNeeded: f) &+ 0x30
            }
        }
    }
    return result
}

/// Appends `x` as Python's `repr` writes it: the shortest round-trip digits, positional when the
/// decimal exponent is in `-4 ..< 16` (with `.0` when integral), otherwise `d.ddde±XX` with at
/// least two exponent digits; `inf`, `-inf`, `nan`.
@inlinable func _appendPythonDouble<Sink: _ByteSink & ~Copyable>(_ x: Double, to sink: inout Sink) {
    if x.isNaN { return sink.appendASCII("nan") }
    if x.isInfinite { return sink.appendASCII(x < 0 ? "-inf" : "inf") }
    if x == 0 { return sink.appendASCII(x.sign == .minus ? "-0.0" : "0.0") }
    let d = _shortestDigits(x)
    let e = d.exponent, count = d.count
    // Laid out in a stack buffer (at most 25 bytes: sign, 17 digits, point, e±XXX), then appended once.
    var text: (UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0)
    let length = withUnsafeMutableBytes(of: &text) { out -> Int in
        withUnsafeBytes(of: d.digits) { digits -> Int in
            var n = 0
            if x.sign == .minus {
                out[0] = UInt8(ascii: "-")
                n = 1
            }
            if e < -4 || e >= 16 {
                out[n] = digits[0]
                n &+= 1
                if count > 1 {
                    out[n] = UInt8(ascii: ".")
                    n &+= 1
                    for k in 1 ..< count {
                        out[n] = digits[k]
                        n &+= 1
                    }
                }
                out[n] = UInt8(ascii: "e")
                out[n &+ 1] = e < 0 ? UInt8(ascii: "-") : UInt8(ascii: "+")
                n &+= 2
                let magnitude = Int(e.magnitude)
                if magnitude >= 100 {
                    out[n] = UInt8(truncatingIfNeeded: magnitude / 100) &+ 0x30
                    n &+= 1
                }
                out[n] = UInt8(truncatingIfNeeded: magnitude / 10 % 10) &+ 0x30
                out[n &+ 1] = UInt8(truncatingIfNeeded: magnitude % 10) &+ 0x30
                return n &+ 2
            }
            if e < 0 {
                out[n] = UInt8(ascii: "0")
                out[n &+ 1] = UInt8(ascii: ".")
                n &+= 2
                for _ in 0 ..< (-e &- 1) {
                    out[n] = UInt8(ascii: "0")
                    n &+= 1
                }
                for k in 0 ..< count {
                    out[n] = digits[k]
                    n &+= 1
                }
                return n
            }
            for k in 0 ... e {
                out[n] = k < count ? digits[k] : UInt8(ascii: "0")
                n &+= 1
            }
            out[n] = UInt8(ascii: ".")
            n &+= 1
            if count > e &+ 1 {
                for k in (e &+ 1) ..< count {
                    out[n] = digits[k]
                    n &+= 1
                }
            } else {
                out[n] = UInt8(ascii: "0")
                n &+= 1
            }
            return n
        }
    }
    withUnsafeBytes(of: text) { sink.append(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: UInt8.self), count: length)) }
}

/// Appends `x` as SciPy's `mmwrite` (fast_matrix_market) writes it: the shortest round-trip
/// digits as `d[.ddd]E<e>`, the exponent omitted when it is 0; `Infinity`, `-Infinity`, `NaN`;
/// `0` and `-0`.
@inlinable func _appendMatrixMarketDouble<Sink: _ByteSink & ~Copyable>(_ x: Double, to sink: inout Sink) {
    if x.isNaN { return sink.appendASCII("NaN") }
    if x.isInfinite { return sink.appendASCII(x < 0 ? "-Infinity" : "Infinity") }
    if x.sign == .minus { sink.append(UInt8(ascii: "-")) }
    if x == 0 { return sink.append(UInt8(ascii: "0")) }
    let d = _shortestDigits(x)
    sink.append(d.digit(0))
    if d.count > 1 {
        sink.append(UInt8(ascii: "."))
        for k in 1 ..< d.count { sink.append(d.digit(k)) }
    }
    if d.exponent != 0 {
        sink.append(UInt8(ascii: "E"))
        sink.appendDecimal(d.exponent)
    }
}
