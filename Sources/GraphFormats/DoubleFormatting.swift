/// Doubles written as text: the shortest digits that round-trip (the standard library's, which are
/// also Python's), laid out by Python's `repr` rule or by SciPy's Matrix Market rule.

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

/// The standard library's shortest round-trip formatting (what `description` uses), into a
/// buffer, without making a `String`: the runtime entry point `Double.description` itself calls.
/// Returns the number of bytes written.
@usableFromInline
@_silgen_name("swift_float64ToString")
internal func _float64ToString(_ buffer: UnsafeMutablePointer<UInt8>, _ length: UInt, _ value: Double, _ debug: Bool) -> UInt64

/// Room for what `_float64ToString` prints.
@usableFromInline internal struct _Capture {
    @inlinable
    init() {
    }

    @usableFromInline var bytes: (UInt64, UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0, 0)
    @usableFromInline var count = 0
}

/// The shortest digits of a finite, nonzero `x` (its sign ignored).
@inlinable func _shortestDigits(_ x: Double) -> _ShortestDigits {
    var capture = _Capture()
    let magnitude = x.magnitude
    capture.count = withUnsafeMutableBytes(of: &capture.bytes) { storage in
        Int(_float64ToString(storage.baseAddress!.assumingMemoryBound(to: UInt8.self), UInt(storage.count), magnitude, false))
    }
    var result = _ShortestDigits()
    withUnsafeBytes(of: capture.bytes) { text in
        let n = capture.count
        // The forms printed: `123.45`, `0.001`, `1e-05`, `1.5e+300`.
        var i = 0
        var pointSeen = false
        var digitsBeforePoint = 0
        var leadingZeros = 0  // zeros after the point before the first nonzero digit
        var started = false
        withUnsafeMutableBytes(of: &result.digits) { out in
            while i < n {
                let c = text[i]
                if c == UInt8(ascii: ".") {
                    pointSeen = true
                } else if _isDigit(c) {
                    if !pointSeen { digitsBeforePoint += 1 }
                    if !started && c == UInt8(ascii: "0") {
                        if pointSeen { leadingZeros += 1 }
                    } else {
                        started = true
                        if result.count < out.count {
                            out[result.count] = c
                            result.count += 1
                        }
                    }
                } else {
                    break
                }
                i += 1
            }
        }
        var exponent = 0
        if i < n && (text[i] == UInt8(ascii: "e") || text[i] == UInt8(ascii: "E")) {
            i += 1
            var negative = false
            if text[i] == UInt8(ascii: "-") { negative = true; i += 1 } else if text[i] == UInt8(ascii: "+") { i += 1 }
            while i < n {
                exponent = exponent * 10 + Int(text[i] &- 0x30)
                i += 1
            }
            if negative { exponent = -exponent }
        }
        // Leading integer zeros only occur as the single `0` of `0.001`.
        let integerDigits = (digitsBeforePoint == 1 && text[0] == UInt8(ascii: "0")) ? 0 : digitsBeforePoint
        result.exponent = integerDigits > 0 ? exponent + integerDigits - 1 : exponent - leadingZeros - 1
    }
    // Trailing zeros (`100.0`, `1.0`).
    while result.count > 1 && result.digit(result.count - 1) == UInt8(ascii: "0") { result.count -= 1 }
    return result
}

/// Appends `x` as Python's `repr` writes it: the shortest round-trip digits, positional when the
/// decimal exponent is in `-4 ..< 16` (with `.0` when integral), otherwise `d.ddde±XX` with at
/// least two exponent digits; `inf`, `-inf`, `nan`.
@inlinable func _appendPythonDouble<Sink: _ByteSink & ~Copyable>(_ x: Double, to sink: inout Sink) {
    if x.isNaN { return sink.appendASCII("nan") }
    if x.isInfinite { return sink.appendASCII(x < 0 ? "-inf" : "inf") }
    if x.sign == .minus { sink.append(UInt8(ascii: "-")) }
    if x == 0 { return sink.appendASCII("0.0") }
    // Below 2⁵³ the standard library lays the digits out as Python does (positional for decimal
    // exponents -4 ..< 16, `1e-05` below); only 2⁵³ ..< 10¹⁶, which it writes with an exponent,
    // needs the digits rearranged.
    if x.magnitude < 9.0e15 {
        var capture = _Capture()
        let magnitude = x.magnitude
        capture.count = withUnsafeMutableBytes(of: &capture.bytes) { storage in
            Int(_float64ToString(storage.baseAddress!.assumingMemoryBound(to: UInt8.self), UInt(storage.count), magnitude, false))
        }
        let count = capture.count
        withUnsafeBytes(of: capture.bytes) { text in
            sink.append(UnsafeBufferPointer(start: text.baseAddress!.assumingMemoryBound(to: UInt8.self), count: count))
        }
        return
    }
    let d = _shortestDigits(x)
    let e = d.exponent
    if e < -4 || e >= 16 {
        sink.append(d.digit(0))
        if d.count > 1 {
            sink.append(UInt8(ascii: "."))
            for k in 1 ..< d.count { sink.append(d.digit(k)) }
        }
        sink.append(UInt8(ascii: "e"))
        sink.append(e < 0 ? UInt8(ascii: "-") : UInt8(ascii: "+"))
        let magnitude = e.magnitude
        if magnitude < 10 { sink.append(UInt8(ascii: "0")) }
        sink.appendDecimal(Int(magnitude))
    } else if e < 0 {
        sink.appendASCII("0.")
        for _ in 0 ..< (-e - 1) { sink.append(UInt8(ascii: "0")) }
        for k in 0 ..< d.count { sink.append(d.digit(k)) }
    } else {
        for k in 0 ... e { sink.append(k < d.count ? d.digit(k) : UInt8(ascii: "0")) }
        sink.append(UInt8(ascii: "."))
        if d.count > e + 1 {
            for k in (e + 1) ..< d.count { sink.append(d.digit(k)) }
        } else {
            sink.append(UInt8(ascii: "0"))
        }
    }
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
