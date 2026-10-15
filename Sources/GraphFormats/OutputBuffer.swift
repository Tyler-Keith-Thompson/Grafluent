/// The writers' output: bytes collected in a 64 KiB buffer and handed to the stream as a `String`
/// each time the buffer fills, so the stream sees one `write(_:)` per 64 KiB. A piece never ends
/// inside a scalar: a scalar cut by the boundary waits for the next piece.
@usableFromInline internal struct _OutputBuffer: ~Copyable {
    @usableFromInline static let capacity = 65_536

    @usableFromInline let base: UnsafeMutablePointer<UInt8>
    @usableFromInline var count = 0
    @usableFromInline let deliver: (String) -> Void

    @inlinable init(deliver: @escaping (String) -> Void) {
        base = .allocate(capacity: Self.capacity)
        self.deliver = deliver
    }

    @inlinable deinit { base.deallocate() }

    /// Hands every complete scalar in the buffer to the stream, keeping a cut scalar's bytes.
    @inlinable mutating func flush() {
        guard count > 0 else { return }
        // The start of the last scalar, at most three continuation bytes back.
        var lead = count - 1
        while lead > 0 && count - lead < 4 && base[lead] & 0xC0 == 0x80 { lead -= 1 }
        let first = base[lead]
        let width = first < 0x80 ? 1 : first >= 0xF0 ? 4 : first >= 0xE0 ? 3 : 2
        let end = lead + width <= count ? count : lead
        if end > 0 {
            deliver(String(decoding: UnsafeBufferPointer(start: base, count: end), as: UTF8.self))
        }
        let rest = count - end
        if rest > 0 { (base).update(from: base + end, count: rest) }
        count = rest
    }

    /// Makes room for `n` more bytes without a flush in between (`n` ≤ 64).
    @inline(__always)
    @inlinable mutating func reserve(_ n: Int) {
        if count &+ n > Self.capacity { flush() }
    }

    @inline(__always)
    @inlinable mutating func append(_ byte: UInt8) {
        if count == Self.capacity { flush() }
        base[count] = byte
        count &+= 1
    }

    @inline(__always)
    @inlinable mutating func append(_ bytes: UnsafeBufferPointer<UInt8>) {
        guard let source = bytes.baseAddress else { return }
        let remaining = bytes.count
        // A piece of 8 to 16 bytes, when 16 fit: two word copies (overlapping when shorter).
        if UInt(bitPattern: remaining &- 8) <= 8 && count &+ 16 <= Self.capacity {
            let from = UnsafeRawPointer(source), to = UnsafeMutableRawPointer(base + count)
            to.storeBytes(of: from.loadUnaligned(as: UInt64.self), as: UInt64.self)
            to.storeBytes(of: from.loadUnaligned(fromByteOffset: remaining &- 8, as: UInt64.self), toByteOffset: remaining &- 8, as: UInt64.self)
            count &+= remaining
            return
        }
        // A short piece that fits: a plain loop, cheaper than a call to memmove.
        if remaining <= 32 && count &+ remaining <= Self.capacity {
            var k = 0
            while k < remaining {
                base[count &+ k] = source[k]
                k &+= 1
            }
            count &+= remaining
            return
        }
        appendLong(source, remaining)
    }

    /// Appends the first `count` (at most 8) bytes of `word`, little-endian, with one store when 8
    /// bytes fit before the end of the buffer; `false`, with nothing appended, when they do not.
    @inline(__always)
    @inlinable mutating func appendWord(_ word: UInt64, count n: Int) -> Bool {
        guard count &+ 8 <= Self.capacity else { return false }
        UnsafeMutableRawPointer(base + count).storeBytes(of: word.littleEndian, as: UInt64.self)
        count &+= n
        return true
    }

    @inlinable mutating func appendLong(_ start: UnsafePointer<UInt8>, _ length: Int) {
        var source = start
        var remaining = length
        while remaining > 0 {
            if count == Self.capacity { flush() }
            let n = min(remaining, Self.capacity - count)
            (base + count).update(from: source, count: n)
            count += n
            source += n
            remaining -= n
        }
    }

    @inlinable mutating func append(_ string: String) {
        var string = string
        string.withUTF8 { append($0) }
    }

    @inlinable mutating func appendASCII(_ text: StaticString) {
        text.withUTF8Buffer { append($0) }
    }

    /// Appends `value` in decimal.
    @inlinable mutating func appendDecimal(_ value: Int) {
        reserve(20)
        if UInt(bitPattern: value) < 10 {
            base[count] = UInt8(truncatingIfNeeded: value) &+ 0x30
            count &+= 1
            return
        }
        var magnitude = value.magnitude
        // At most 20 digits, or 10 where `UInt` is 32 bits: `bound` stops at the greatest power
        // of ten the width holds.
        let maximumDigits = UInt.bitWidth == 64 ? 20 : 10
        var digits = 1
        var bound: UInt = 10
        while digits < maximumDigits && magnitude >= bound {
            digits &+= 1
            if digits == maximumDigits { break }
            bound &*= 10
        }
        if value < 0 {
            base[count] = UInt8(ascii: "-")
            count &+= 1
        }
        var k = count &+ digits
        count = k
        repeat {
            k &-= 1
            base[k] = UInt8(truncatingIfNeeded: magnitude % 10) &+ 0x30
            magnitude /= 10
        } while magnitude > 0
    }
}

/// Runs `body` with a buffer that delivers to `output`, then flushes what remains. Always inlined,
/// so that a writer's body (and the caller's closures it calls) can be inlined into the caller.
/// When `body` throws, what it appended since the last full buffer is dropped: a writer that
/// throws before its first append leaves `output` unchanged.
@inline(__always)
@inlinable func _withOutputBuffer<Failure: Error>(
    _ output: inout some TextOutputStream, _ body: (inout _OutputBuffer) throws(Failure) -> Void
) throws(Failure) {
    try withoutActuallyEscaping({ (piece: String) in output.write(piece) }) { deliver throws(Failure) in
        var buffer = _OutputBuffer(deliver: deliver)
        try body(&buffer)
        buffer.flush()
    }
}

/// Runs `body` with a buffer whose full pieces are held, then hands every piece to `output` in
/// order once `body` returns. When `body` throws, nothing reaches `output`. For the writers whose
/// checks run while they write; the others check first and stream (`_withOutputBuffer`).
@inline(__always)
@inlinable func _withHeldOutputBuffer(
    _ output: inout some TextOutputStream, _ body: (inout _OutputBuffer) throws(WriteError) -> Void
) throws(WriteError) {
    var pieces: [String] = []
    try withoutActuallyEscaping({ (piece: String) in pieces.append(piece) }) { deliver throws(WriteError) in
        var buffer = _OutputBuffer(deliver: deliver)
        try body(&buffer)
        buffer.flush()
    }
    for piece in pieces { output.write(piece) }
}

/// Where formatting code appends bytes: the output buffer, or an array being built.
@usableFromInline internal protocol _ByteSink: ~Copyable {
    /// Lets `body` write at most `maximum` (≤ 64) bytes in place, keeping the number it returns.
    mutating func appendInPlace(maximum: Int, _ body: (UnsafeMutablePointer<UInt8>) -> Int)
    mutating func append(_ byte: UInt8)
    mutating func append(_ bytes: UnsafeBufferPointer<UInt8>)
    mutating func appendASCII(_ text: StaticString)
    mutating func appendDecimal(_ value: Int)
}

extension _OutputBuffer: _ByteSink {
    @inline(__always)
    @inlinable mutating func appendInPlace(maximum: Int, _ body: (UnsafeMutablePointer<UInt8>) -> Int) {
        reserve(maximum)
        count &+= body(base + count)
    }
}

extension Array: _ByteSink where Element == UInt8 {
    @inlinable mutating func appendInPlace(maximum: Int, _ body: (UnsafeMutablePointer<UInt8>) -> Int) {
        let start = count
        append(contentsOf: repeatElement(0, count: maximum))
        let written = withUnsafeMutableBufferPointer { body($0.baseAddress! + start) }
        removeLast(maximum &- written)
    }

    @inlinable mutating func append(_ bytes: UnsafeBufferPointer<UInt8>) {
        append(contentsOf: bytes)
    }

    @inlinable mutating func appendASCII(_ text: StaticString) {
        text.withUTF8Buffer { append(contentsOf: $0) }
    }

    @inlinable mutating func appendDecimal(_ value: Int) {
        append(contentsOf: String(value).utf8)
    }
}
