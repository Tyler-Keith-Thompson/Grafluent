/// Doubles written as text: the shortest digits that round-trip (Giulietti's Schubfach; the same
/// digits as `description`), laid out in the form DOT, GraphML, node-link JSON and the edge list
/// write, or in the Matrix Market form. The table is generated (`scripts/schubfach_table.py`), and
/// the arithmetic is 64-bit multiplications.

/// The shortest round-trip decimal digits of a finite, nonzero `|x|`: `count` digits in `digits`,
/// with no leading or trailing zeros, and the decimal exponent of the first, so that
/// `|x| = d₀.d₁d₂… × 10^exponent`.
@usableFromInline internal struct _ShortestDigits {
    @inlinable
    init() {
    }

    /// Up to 17 digits, as ASCII, in 40 bytes (so that 24 can be copied from any of the first 17:
    /// the positional layout copies the fraction from just after the point, up to digit 16).
    @usableFromInline var digits: (UInt64, UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0, 0)
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
/// end in zeros. The two smallest subnormals take the general path too; the tests check their
/// digits against `description` with the rest.
@inline(__always)
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

/// The number of decimal digits of `v`, which is below 10⁹ (by comparisons, at most three).
/// `_shortestDigits` passes a significand below 10⁸ or one's digits above the last eight; a
/// significand is below 9.1 × 10¹⁶ (`c` < 2⁵³ times 2^q / 10^k < 10, or < 40/3 for a power of two
/// with `c` = 2⁵²), so those are below 10⁹.
@inline(__always)
@inlinable func _decimalDigitCount(_ v: UInt64) -> Int {
    if v < 10_000 {
        if v < 100 { return v < 10 ? 1 : 2 }
        return v < 1_000 ? 3 : 4
    }
    if v < 100_000_000 {
        if v < 1_000_000 { return v < 100_000 ? 5 : 6 }
        return v < 10_000_000 ? 7 : 8
    }
    return 9
}

/// Writes the last `count` decimal digits of `v`, zero-padded, to `out[0 ..< count]`, two at a time.
@inline(__always)
@inlinable func _writeDigits(_ v: UInt64, count: Int, to out: UnsafeMutablePointer<UInt8>, pairs: UnsafePointer<UInt8>) {
    var v = v
    var k = count
    while k >= 2 {
        let r = Int(truncatingIfNeeded: v % 100) &* 2
        v /= 100
        k &-= 2
        out[k] = pairs[r]
        out[k &+ 1] = pairs[r &+ 1]
    }
    if k == 1 { out[0] = UInt8(truncatingIfNeeded: v % 10) &+ 0x30 }
}

/// The shortest digits of a finite, nonzero `x` (its sign ignored): Schubfach's significand
/// written two digits at a time (its last eight digits as a fixed-width block), then its trailing
/// zeros dropped from the text.
@inline(__always)
@inlinable func _shortestDigits(_ x: Double) -> _ShortestDigits {
    let (f, e) = _schubfach(x.magnitude)
    var result = _ShortestDigits()
    var count = 0
    withUnsafeMutableBytes(of: &result.digits) { raw in
        let out = raw.baseAddress!.assumingMemoryBound(to: UInt8.self)
        _digitPairs.withUTF8Buffer { table in
            let pairs = table.baseAddress!
            let high = f / 100_000_000
            if high == 0 {
                count = _decimalDigitCount(f)
                _writeDigits(f, count: count, to: out, pairs: pairs)
            } else {
                let highCount = _decimalDigitCount(high)
                _writeDigits(high, count: highCount, to: out, pairs: pairs)
                _writeDigits(f &- high &* 100_000_000, count: 8, to: out + highCount, pairs: pairs)
                count = highCount &+ 8
            }
        }
        result.exponent = e &+ count &- 1
        while count > 1 && out[count &- 1] == UInt8(ascii: "0") { count &-= 1 }
    }
    result.count = count
    return result
}

/// Appends `x` as DOT, GraphML, node-link JSON and the edge list write it: the shortest round-trip
/// digits, positional when the decimal exponent is in `-4 ..< 16` (with `.0` when integral),
/// otherwise `d.ddde±XX` with at least two exponent digits; `inf`, `-inf`, `nan`.
@inlinable func _appendPythonDouble<Sink: _ByteSink & ~Copyable>(_ x: Double, to sink: inout Sink) {
    if x.isNaN { return sink.appendASCII("nan") }
    if x.isInfinite { return sink.appendASCII(x < 0 ? "-inf" : "inf") }
    if x == 0 { return sink.appendASCII(x.sign == .minus ? "-0.0" : "0.0") }
    let d = _shortestDigits(x)
    let negative = x.sign == .minus
    // Laid out in place: at most 26 bytes (sign, 17 digits, point, e±XXX), with the digits
    // copied 24 bytes at a time (the bytes past them are overwritten or not kept).
    sink.appendInPlace(maximum: 48) { out in
        withUnsafeBytes(of: d.digits) { raw in
            let digits = raw.baseAddress!
            @inline(__always) func copy24(from offset: Int, to target: UnsafeMutablePointer<UInt8>) {
                let to = UnsafeMutableRawPointer(target)
                to.storeBytes(of: digits.loadUnaligned(fromByteOffset: offset, as: UInt64.self), as: UInt64.self)
                to.storeBytes(of: digits.loadUnaligned(fromByteOffset: offset &+ 8, as: UInt64.self), toByteOffset: 8, as: UInt64.self)
                to.storeBytes(of: digits.loadUnaligned(fromByteOffset: offset &+ 16, as: UInt64.self), toByteOffset: 16, as: UInt64.self)
            }
            let first = digits.load(as: UInt8.self)
            let e = d.exponent, count = d.count
            var n = 0
            if negative {
                out[0] = UInt8(ascii: "-")
                n = 1
            }
            if e < -4 || e >= 16 {
                out[n] = first
                n &+= 1
                if count > 1 {
                    out[n] = UInt8(ascii: ".")
                    copy24(from: 1, to: out + (n &+ 1))
                    n &+= count
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
                copy24(from: 0, to: out + n)
                return n &+ count
            }
            if count > e &+ 1 {
                // Integer digits, the point, the fraction's.
                copy24(from: 0, to: out + n)
                out[n &+ e &+ 1] = UInt8(ascii: ".")
                copy24(from: e &+ 1, to: out + (n &+ e &+ 2))
                return n &+ count &+ 1
            }
            copy24(from: 0, to: out + n)
            var k = count
            while k <= e {
                out[n &+ k] = UInt8(ascii: "0")
                k &+= 1
            }
            out[n &+ e &+ 1] = UInt8(ascii: ".")
            out[n &+ e &+ 2] = UInt8(ascii: "0")
            return n &+ e &+ 3
        }
    }
}

/// Appends `x` as the Matrix Market writer writes it: the shortest round-trip digits as `d[.ddd]E<e>`, the exponent omitted when it is 0; `Infinity`, `-Infinity`, `NaN`;
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
