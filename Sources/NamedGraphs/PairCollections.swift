import GraphProtocols

// The edge lists of the Θ(n²) families, computed as they are read, so no edge array is allocated.
// Each lists pairs as `DirectedEdge<Int>` in row-major order; the undirected factories map them to
// `UndirectedEdge` lazily. Iteration runs a dedicated iterator (no division per element); the
// position subscript, which the bulk initializers do not use, computes the pair arithmetically.

/// Every pair (u, v) with u < v in `0..<n`, in lexicographic order: the edges of Kₙ.
@frozen
@usableFromInline
package struct _AscendingPairs: RandomAccessCollection {
    @usableFromInline let n: Int

    @inlinable
    package init(_ n: Int) { self.n = n }

    @inlinable package var startIndex: Int { 0 }
    @inlinable package var endIndex: Int { n < 2 ? 0 : (n.isMultiple(of: 2) ? (n / 2) * (n - 1) : n * ((n - 1) / 2)) }

    /// The first position of row `u`: u(2n − u − 1)/2.
    @inlinable
    func rowStart(_ u: Int) -> Int {
        let a = u, b = 2 * n - u - 1
        return a.isMultiple(of: 2) ? (a / 2) * b : a * (b / 2)
    }

    @inlinable
    package subscript(position: Int) -> DirectedEdge<Int> {
        precondition(position >= 0 && position < endIndex, "Position out of range")
        // The row from the quadratic's root, then corrected for rounding.
        let m = Double(2 * n - 1)
        var u = Int(((m - (m * m - 8 * Double(position)).squareRoot()) / 2).rounded(.down))
        u = Swift.max(0, Swift.min(u, n - 2))
        while u > 0, rowStart(u) > position { u -= 1 }
        while u < n - 2, rowStart(u + 1) <= position { u += 1 }
        return DirectedEdge(from: u, to: u + 1 + position - rowStart(u))
    }

    @frozen
    @usableFromInline
    package struct Iterator: IteratorProtocol {
        @usableFromInline var u: Int
        @usableFromInline var v: Int
        @usableFromInline let n: Int

        @inlinable
        package init(n: Int) {
            u = 0
            v = 1
            self.n = n
        }

        @inlinable
        @inline(__always)
        package mutating func next() -> DirectedEdge<Int>? {
            if v >= n {
                guard u &+ 2 < n else { return nil }
                u &+= 1
                v = u &+ 1
            }
            defer { v &+= 1 }
            return DirectedEdge(from: u, to: v)
        }
    }

    @inlinable
    package func makeIterator() -> Iterator { Iterator(n: n) }
}

/// Every pair (u, v) with u ≠ v in `0..<n`, in row-major order: the arcs of the complete digraph.
@frozen
@usableFromInline
package struct _DistinctPairs: RandomAccessCollection {
    @usableFromInline let n: Int

    @inlinable
    package init(_ n: Int) { self.n = n }

    @inlinable package var startIndex: Int { 0 }
    @inlinable package var endIndex: Int { n < 2 ? 0 : n * (n - 1) }

    @inlinable
    package subscript(position: Int) -> DirectedEdge<Int> {
        precondition(position >= 0 && position < endIndex, "Position out of range")
        let u = position / (n - 1), r = position % (n - 1)
        return DirectedEdge(from: u, to: r < u ? r : r + 1)
    }

    @frozen
    @usableFromInline
    package struct Iterator: IteratorProtocol {
        @usableFromInline var u: Int
        @usableFromInline var v: Int
        @usableFromInline let n: Int

        @inlinable
        package init(n: Int) {
            u = 0
            v = 1
            self.n = n < 2 ? 0 : n
        }

        @inlinable
        @inline(__always)
        package mutating func next() -> DirectedEdge<Int>? {
            if v >= n {
                guard u &+ 1 < n else { return nil }
                u &+= 1
                v = 0
            }
            if v == u { v &+= 1 }
            if v >= n {
                // u = n − 1 ended its row at v = u.
                return nil
            }
            defer { v &+= 1 }
            return DirectedEdge(from: u, to: v)
        }
    }

    @inlinable
    package func makeIterator() -> Iterator { Iterator(n: n) }
}

/// Every pair (u, v) with u in `0..<a` and v in `a..<a + b`, in lexicographic order: the edges of
/// K_{a,b}, left end first.
@frozen
@usableFromInline
package struct _CrossPairs: RandomAccessCollection {
    @usableFromInline let a: Int
    @usableFromInline let b: Int

    @inlinable
    package init(_ a: Int, _ b: Int) {
        self.a = a
        self.b = b
    }

    @inlinable package var startIndex: Int { 0 }
    @inlinable package var endIndex: Int { a * b }

    @inlinable
    package subscript(position: Int) -> DirectedEdge<Int> {
        precondition(position >= 0 && position < endIndex, "Position out of range")
        return DirectedEdge(from: position / b, to: a + position % b)
    }

    @frozen
    @usableFromInline
    package struct Iterator: IteratorProtocol {
        @usableFromInline var u: Int
        @usableFromInline var v: Int
        @usableFromInline let a: Int
        @usableFromInline let end: Int

        @inlinable
        package init(a: Int, b: Int) {
            u = 0
            v = a
            self.a = b == 0 ? 0 : a
            end = a + b
        }

        @inlinable
        @inline(__always)
        package mutating func next() -> DirectedEdge<Int>? {
            if v >= end {
                u &+= 1
                v = a
            }
            guard u < a else { return nil }
            defer { v &+= 1 }
            return DirectedEdge(from: u, to: v)
        }
    }

    @inlinable
    package func makeIterator() -> Iterator { Iterator(a: a, b: b) }
}

extension _AscendingPairs: Sendable {}
extension _DistinctPairs: Sendable {}
extension _CrossPairs: Sendable {}

/// Undirected edges from pairs given smaller end first.
@inlinable
@inline(__always)
package func _undirected(_ pair: DirectedEdge<Int>) -> UndirectedEdge<Int> {
    UndirectedEdge(pair.source, pair.target)
}
