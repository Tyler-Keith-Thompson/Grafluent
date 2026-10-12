/// A `String` that compares and hashes by its Unicode scalars (its UTF-8 bytes), as NetworkX
/// compares Python strings, rather than by canonical equivalence as `String` does. Attribute names
/// and IDs are compared this way throughout the module: `"é"` precomposed and decomposed are two
/// names, as they are two names to Graphviz, NetworkX and an XML parser.
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
@inline(__always)
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
