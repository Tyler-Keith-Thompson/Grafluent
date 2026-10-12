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
        var magnitude = value.magnitude
        var digits = 1
        var bound: UInt = 10
        while digits < 20 && magnitude >= bound {
            digits &+= 1
            if digits == 20 { break }
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

/// Runs `body` with a buffer that delivers to `output`, then flushes what remains.
@inlinable func _withOutputBuffer(_ output: inout some TextOutputStream, _ body: (inout _OutputBuffer) -> Void) {
    withoutActuallyEscaping({ (piece: String) in output.write(piece) }) { deliver in
        var buffer = _OutputBuffer(deliver: deliver)
        body(&buffer)
        buffer.flush()
    }
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
