/// A `String` that compares and hashes by its Unicode scalars (its UTF-8 bytes) rather than by
/// canonical equivalence as `String` does. Attribute names and IDs are compared this way throughout
/// the module: `"é"` precomposed and decomposed are two names, as they are in DOT, XML and JSON.
@usableFromInline internal struct _ScalarKey: Hashable {
    @usableFromInline let string: String

    @inlinable init(_ string: String) { self.string = string }

    @inlinable static func == (a: Self, b: Self) -> Bool { _sameScalars(a.string, b.string) }

    @inlinable func hash(into hasher: inout Hasher) {
        var s = string
        s.withUTF8 { hasher.combine(bytes: UnsafeRawBufferPointer($0)) }
    }
}

/// Whether `a` and `b` have the same Unicode scalars.
@inlinable func _sameScalars(_ a: String, _ b: String) -> Bool {
    var a = a, b = b
    return a.withUTF8 { x in
        b.withUTF8 { y in
            guard x.count == y.count else { return false }
            var k = 0
            while k < x.count {
                if x[k] != y[k] { return false }
                k &+= 1
            }
            return true
        }
    }
}

/// Whether `a` has the scalars of `ascii`, which is ASCII: `==` and the same UTF-8 length. A
/// string canonically equivalent to an ASCII one but different holds a scalar of two or more
/// bytes in place of one byte (U+212A for "K"), so it is longer.
@inline(__always)
@inlinable func _sameScalars(_ a: String, ascii: String) -> Bool {
    a.utf8.count == ascii.utf8.count && a == ascii
}

/// Whether every byte of `s` is ASCII.
@inlinable func _isASCII(_ s: String) -> Bool { s.utf8.allSatisfy { $0 < 0x80 } }
