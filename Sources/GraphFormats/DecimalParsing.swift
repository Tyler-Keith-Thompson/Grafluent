/// Decimal numbers read from text: integers with overflow checks, and doubles by a grammar check
/// followed by a correctly rounded conversion (Eisel–Lemire, with the standard
/// library's `Double(_:)` for the rare inputs it cannot decide). No hexadecimal floats, no
/// `nan(…)` payloads, no Foundation.

// Why this parser exists: the standard library's only public way to read a double is
// `Double(_:)` on a `String` or `Substring`, so reading from a byte buffer would build a heap
// `String` for every number, and the readers spend most of their time on numbers. This one reads
// the bytes in place, correctly rounded, and leaves only the rare undecided inputs to
// `Double(_:)`. It uses public API only.

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
        // Saturates past 10⁹ (10⁸ where `Int` is 32 bits, so that ten times it still fits).
        if value < (Int.bitWidth == 64 ? 1_000_000_000 : 100_000_000) { value = value &* 10 &+ Int(text[i] &- 0x30) }
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
    return _fallbackDouble(parts, text.baseAddress!, start, end)
}

/// The double nearest to the decimal `parts` of `base[start..<end]`, by the standard library's
/// `Double(_:)`, for the inputs Eisel–Lemire cannot decide.
@inline(never)
@usableFromInline func _fallbackDouble(_ parts: _DecimalParts, _ base: UnsafePointer<UInt8>, _ start: Int, _ end: Int) -> Double {
    let overflow: Double = parts.negative ? -.infinity : .infinity
    if end &- start <= 700 {
        return Double(String(decoding: UnsafeBufferPointer(start: base + start, count: end &- start), as: UTF8.self)) ?? overflow
    }
    // `Double(_:)` refuses a long text (past 16 KiB on Apple platforms), and on Apple platforms
    // reads zeros past the 768th significant digit as if they were not zero. A long text is
    // passed as the same value to within rounding instead: `0.d₁…dₖ[1] × 10^e`, its significant
    // digits cut at 768 (a halfway point between doubles has at most 767) and trailing zeros
    // dropped, with a 1 standing for any nonzero digit cut.
    var digits: [UInt8] = []
    var place = parts.integerEnd &- parts.integerStart
    var sticky = false
    var k = parts.integerStart
    while k < parts.fractionEnd {
        if k == parts.integerEnd && parts.fractionStart > k {
            k = parts.fractionStart
            continue
        }
        let digit = base[k]
        k &+= 1
        if digits.isEmpty && digit == UInt8(ascii: "0") {
            place &-= 1
        } else if digits.count < 768 {
            digits.append(digit)
        } else if digit != UInt8(ascii: "0") {
            sticky = true
        }
    }
    while digits.last == UInt8(ascii: "0") { digits.removeLast() }
    if digits.isEmpty { return parts.negative ? -0.0 : 0.0 }
    if sticky { digits.append(UInt8(ascii: "1")) }
    let text = (parts.negative ? "-0." : "0.") + String(decoding: digits, as: UTF8.self) + "e\(place &+ parts.exponent)"
    return Double(text) ?? overflow
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

/// A number read in one scan: what `_lexicalValue` and the Matrix Market reader take a field's
/// text to be before falling back to words (`inf`, `nan`) or text.
@usableFromInline internal enum _ScannedNumber {
    /// `[+-]?[0-9]+` within `Int`.
    case integer(Int)
    /// Any other decimal (`_decimalParts`' grammar), correctly rounded; infinite past `Double`.
    case double(Double)
    /// Not a decimal.
    case none
}

/// The value of the eight ASCII digits at `base[i]`, read as one word (a SWAR conversion); `nil` when fewer than eight bytes are left or one is not a digit.
@inline(__always)
@inlinable func _eightDigits(_ base: UnsafePointer<UInt8>, _ i: Int, _ limit: Int) -> UInt64? {
    guard i &+ 8 <= limit else { return nil }
    let word = UnsafeRawPointer(base + i).loadUnaligned(as: UInt64.self).littleEndian
    // Every byte is 0x30 – 0x39: its high nibble is 3, and adding 6 does not carry into it.
    guard (word & 0xF0F0_F0F0_F0F0_F0F0) | (((word &+ 0x0606_0606_0606_0606) & 0xF0F0_F0F0_F0F0_F0F0) >> 4)
        == 0x3333_3333_3333_3333 else { return nil }
    var v = word &- 0x3030_3030_3030_3030
    v = v &* 10 &+ (v >> 8)
    v = ((v & 0x0000_00FF_0000_00FF) &* 0x000F_4240_0000_0064 &+ ((v >> 16) & 0x0000_00FF_0000_00FF) &* 0x0000_2710_0000_0001) >> 32
    return v & 0xFFFF_FFFF
}

/// Reads the longest prefix of `base[start..<limit]` that the decimal grammar allows as an integer
/// or a decimal, in one pass: the digits are accumulated while the grammar is checked (the first
/// 19 significant ones; the rest only counted), and the value comes from Eisel–Lemire, or
/// `_double`'s fallback for the rare input it cannot decide. Returns where the prefix ends.
@inline(__always)
@inlinable func _scanNumberPrefix(_ base: UnsafePointer<UInt8>, _ start: Int, _ limit: Int) -> (number: _ScannedNumber, end: Int) {
    var i = start
    guard i < limit else { return (.none, i) }
    var negative = false
    let first = base[i]
    if first == UInt8(ascii: "+") || first == UInt8(ascii: "-") {
        negative = first == UInt8(ascii: "-")
        i &+= 1
    }
    var w: UInt64 = 0
    var significant = 0, dropped = 0
    var integerDigits = 0, fractionDigits = 0
    while i < limit {
        if w != 0 && significant <= 11, let eight = _eightDigits(base, i, limit) {
            w = w &* 100_000_000 &+ eight
            significant &+= 8
            integerDigits &+= 8
            i &+= 8
            continue
        }
        let d = base[i] &- 0x30
        if d >= 10 { break }
        integerDigits &+= 1
        if significant < 19 {
            if w != 0 || d != 0 {
                w = w &* 10 &+ UInt64(d)
                significant &+= 1
            }
        } else {
            dropped &+= 1
        }
        i &+= 1
    }
    let afterInteger = i
    var exponent = 0
    var decimal = false
    if i < limit && base[i] == UInt8(ascii: ".") {
        decimal = true
        i &+= 1
        while i < limit {
            if w != 0 && significant <= 11, let eight = _eightDigits(base, i, limit) {
                w = w &* 100_000_000 &+ eight
                significant &+= 8
                fractionDigits &+= 8
                i &+= 8
                continue
            }
            let d = base[i] &- 0x30
            if d >= 10 { break }
            fractionDigits &+= 1
            if significant < 19 {
                if w != 0 || d != 0 {
                    w = w &* 10 &+ UInt64(d)
                    significant &+= 1
                }
            } else {
                dropped &+= 1
            }
            i &+= 1
        }
    }
    if integerDigits == 0 && fractionDigits == 0 { return (.none, start) }
    if i < limit && (base[i] | 0x20) == UInt8(ascii: "e") {
        var j = i &+ 1
        var exponentNegative = false
        if j < limit && (base[j] == UInt8(ascii: "+") || base[j] == UInt8(ascii: "-")) {
            exponentNegative = base[j] == UInt8(ascii: "-")
            j &+= 1
        }
        let digits = j
        var value = 0
        while j < limit {
            let d = base[j] &- 0x30
            if d >= 10 { break }
            if value < (Int.bitWidth == 64 ? 1_000_000_000 : 100_000_000) { value = value &* 10 &+ Int(d) }
            j &+= 1
        }
        if j > digits {
            exponent = exponentNegative ? -value : value
            decimal = true
            i = j
        }
    }
    if !decimal {
        // An integer: within a 64-bit Int when it has at most 18 significant digits; else (and
        // always where `Int` is 32 bits) when it fits.
        if dropped == 0 && ((Int.bitWidth == 64 && significant < 19) || w <= UInt64(Int.max) &+ (negative ? 1 : 0)) {
            if negative { return (.integer(w == UInt64(Int.max) &+ 1 ? Int.min : -Int(w)), afterInteger) }
            return (.integer(Int(w)), afterInteger)
        }
    }
    let sign: UInt64 = negative ? 1 << 63 : 0
    if w == 0 { return (.double(Double(bitPattern: sign)), i) }
    let q = exponent &- fractionDigits &+ dropped
    if let bits = _eiselLemire(q, w) {
        if dropped == 0 { return (.double(Double(bitPattern: bits | sign)), i) }
        if let upper = _eiselLemire(q, w &+ 1), upper == bits { return (.double(Double(bitPattern: bits | sign)), i) }
    }
    let text = UnsafeBufferPointer(start: base, count: i)
    guard let parts = _decimalParts(text, start, i) else { return (.none, start) }
    return (.double(_double(parts, text, start, i)), i)
}

/// Reads `text[start..<end]` as an integer or a decimal in one pass (`_scanNumberPrefix`, which
/// must read all of it).
@inlinable func _scanNumber(_ text: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> _ScannedNumber {
    guard let base = text.baseAddress, start < end else { return .none }
    let (number, stop) = _scanNumberPrefix(base, start, end)
    return stop == end ? number : .none
}
