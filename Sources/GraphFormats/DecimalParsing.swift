/// Decimal numbers read from text: integers with overflow checks, and doubles by a grammar check
/// followed by a correctly rounded conversion (Eisel–Lemire, as in fast_float, with the standard
/// library's `Double(_:)` for the rare inputs it cannot decide). No hexadecimal floats, no
/// `nan(…)` payloads, no Foundation.

/// Whether `byte` is an ASCII digit.
@inline(__always)
@inlinable func _isDigit(_ byte: UInt8) -> Bool { byte &- 0x30 < 10 }

/// The result of reading an integer: its value, or that its grammar is wrong, or that it is outside
/// `Int`.
@usableFromInline internal enum _IntegerParse: Equatable {
    case value(Int)
    case malformed
    case outOfRange
}

/// Reads `text[start..<end]` as `[+-]?[0-9]+` (`signed`) or `[0-9]+`.
@inlinable func _parseInteger(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, signed: Bool) -> _IntegerParse {
    var i = start
    var negative = false
    if signed && i < end && (text[i] == UInt8(ascii: "+") || text[i] == UInt8(ascii: "-")) {
        negative = text[i] == UInt8(ascii: "-")
        i &+= 1
    }
    guard i < end else { return .malformed }
    var magnitude: UInt64 = 0
    var overflow = false
    while i < end {
        let d = text[i] &- 0x30
        guard d < 10 else { return .malformed }
        if !overflow {
            let (m, o1) = magnitude.multipliedReportingOverflow(by: 10)
            let (s, o2) = m.addingReportingOverflow(UInt64(d))
            if o1 || o2 { overflow = true } else { magnitude = s }
        }
        i &+= 1
    }
    if overflow { return .outOfRange }
    if negative {
        if magnitude > UInt64(Int.max) &+ 1 { return .outOfRange }
        return .value(magnitude == UInt64(Int.max) &+ 1 ? Int.min : -Int(magnitude))
    }
    if magnitude > UInt64(Int.max) { return .outOfRange }
    return .value(Int(magnitude))
}

/// The parts of a decimal number already checked against a grammar: where its integer and fraction
/// digits are, its sign, and its explicit exponent (saturated far outside `Double`'s range).
@usableFromInline internal struct _DecimalParts {
    @inlinable
    init() {
    }

    @usableFromInline var negative = false
    @usableFromInline var integerStart = 0, integerEnd = 0
    @usableFromInline var fractionStart = 0, fractionEnd = 0
    @usableFromInline var exponent = 0
}

/// Reads `text[start..<end]` as `[+-]?([0-9]+\.[0-9]*|\.[0-9]+|[0-9]+)([eE][+-]?[0-9]+)?`, the
/// decimal grammar of XML Schema, Matrix Market and the edge list, or returns `nil`.
@inlinable func _decimalParts(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> _DecimalParts? {
    var parts = _DecimalParts()
    var i = start
    if i < end && (text[i] == UInt8(ascii: "+") || text[i] == UInt8(ascii: "-")) {
        parts.negative = text[i] == UInt8(ascii: "-")
        i &+= 1
    }
    parts.integerStart = i
    while i < end && _isDigit(text[i]) { i &+= 1 }
    parts.integerEnd = i
    parts.fractionStart = i
    parts.fractionEnd = i
    if i < end && text[i] == UInt8(ascii: ".") {
        i &+= 1
        parts.fractionStart = i
        while i < end && _isDigit(text[i]) { i &+= 1 }
        parts.fractionEnd = i
    }
    if parts.integerEnd == parts.integerStart && parts.fractionEnd == parts.fractionStart { return nil }
    if i < end && (text[i] == UInt8(ascii: "e") || text[i] == UInt8(ascii: "E")) {
        i &+= 1
        guard let e = _exponent(text, &i, end) else { return nil }
        parts.exponent = e
    }
    return i == end ? parts : nil
}

/// Reads `[+-]?[0-9]+` at `i`, saturating at ±10⁹, and advances `i` past it; `nil` without digits.
@inlinable func _exponent(_ text: UnsafeBufferPointer<UInt8>, _ i: inout Int, _ end: Int) -> Int? {
    var negative = false
    if i < end && (text[i] == UInt8(ascii: "+") || text[i] == UInt8(ascii: "-")) {
        negative = text[i] == UInt8(ascii: "-")
        i &+= 1
    }
    let digits = i
    var value = 0
    while i < end && _isDigit(text[i]) {
        if value < 1_000_000_000 { value = value &* 10 &+ Int(text[i] &- 0x30) }
        i &+= 1
    }
    guard i > digits else { return nil }
    return negative ? -value : value
}

/// The double nearest to the decimal `parts` of `text[start..<end]`, correctly rounded; infinite
/// when it overflows.
@inlinable func _double(_ parts: _DecimalParts, _ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> Double {
    // The first 19 significant digits, and how many more there are.
    var w: UInt64 = 0
    var significant = 0
    var dropped = 0
    var leading = true
    // The digits of both parts in order, skipping the point between them.
    let point = parts.fractionStart > parts.integerEnd ? parts.integerEnd : -1
    var k = parts.integerStart
    while k < parts.fractionEnd {
        if k == point {
            k &+= 1
            continue
        }
        let d = text[k] &- 0x30
        k &+= 1
        if leading && d == 0 { continue }
        leading = false
        if significant < 19 {
            w = w &* 10 &+ UInt64(d)
            significant &+= 1
        } else {
            dropped &+= 1
        }
    }
    let fractionDigits = parts.fractionEnd &- parts.fractionStart
    // Saturated: the exponent is at most ±10⁹ and the digit counts are bounded by the input size.
    let q = parts.exponent &- fractionDigits &+ dropped
    let sign: UInt64 = parts.negative ? 1 << 63 : 0
    if w == 0 { return Double(bitPattern: sign) }
    if let bits = _eiselLemire(q, w) {
        if dropped == 0 { return Double(bitPattern: bits | sign) }
        // Digits were dropped: the value lies in [w, w + 1) × 10^q; decided when both ends agree.
        if let upper = _eiselLemire(q, w &+ 1), upper == bits { return Double(bitPattern: bits | sign) }
    }
    let string = String(decoding: UnsafeBufferPointer(rebasing: text[start ..< end]), as: UTF8.self)
    return Double(string) ?? (parts.negative ? -.infinity : .infinity)
}

/// `w × 10^q` as the bits of a positive double, correctly rounded, or `nil` when the
/// approximation cannot decide (never for `w` exact, by Mushtak and Lemire's proof; kept for the
/// truncated case's second call). `w` is not zero.
@inlinable func _eiselLemire(_ q: Int, _ w: UInt64) -> UInt64? {
    if q < -342 { return 0 }
    if q > 308 { return 0x7FF << 52 }
    let lz = w.leadingZeroBitCount
    let shifted = w << UInt64(lz)
    let index = 2 &* (q &+ 342)
    var (high, low) = shifted.multipliedFullWidth(by: _powersOfFive[index])
    let precisionMask: UInt64 = 0x1FF  // 64 − (52 + 3) low bits of the high word
    if high & precisionMask == precisionMask {
        let (secondHigh, _) = shifted.multipliedFullWidth(by: _powersOfFive[index &+ 1])
        let (sum, carry) = low.addingReportingOverflow(secondHigh)
        low = sum
        if carry { high &+= 1 }
    }
    let upperBit = Int(high >> 63)
    let shift = UInt64(upperBit &+ 9)
    var mantissa = high >> shift
    var power2 = (((152_170 &+ 65_536) &* q) >> 16) &+ 63 &+ upperBit &- lz &+ 1023
    if power2 <= 0 {
        if -power2 &+ 1 >= 64 { return 0 }
        mantissa >>= UInt64(-power2 &+ 1)
        mantissa &+= mantissa & 1
        mantissa >>= 1
        power2 = mantissa < (1 << 52) ? 0 : 1
        return mantissa | (UInt64(power2) << 52)
    }
    if low <= 1 && q >= -4 && q <= 23 && mantissa & 3 == 1 {
        if mantissa << shift == high { mantissa &= ~1 }
    }
    mantissa &+= mantissa & 1
    mantissa >>= 1
    if mantissa >= (2 << 52) {
        mantissa = 1 << 52
        power2 &+= 1
    }
    mantissa &= ~(1 << 52)
    if power2 >= 0x7FF { return 0x7FF << 52 }
    return mantissa | (UInt64(power2) << 52)
}
