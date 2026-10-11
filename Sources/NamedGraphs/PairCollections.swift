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

/// Both arcs of every edge in `pairs` (each `(u, v)` with u < v, in lexicographic order), in
/// row-major order. A counting placement, not a sort: row v takes its smaller neighbors first, in
/// one pass over the pairs (which meets them ascending), then its larger ones in a second. O(n + m).
@usableFromInline
func _bothArcs(vertexCount n: Int, _ pairs: [DirectedEdge<Int>]) -> [DirectedEdge<Int>] {
    let m = pairs.count
    precondition(m <= Int.max / 2, "edge count overflows Int")
    var fill = [Int](repeating: 0, count: n + 1)
    for pair in pairs {
        fill[pair.source + 1] += 1
        fill[pair.target + 1] += 1
    }
    for v in 0 ..< n { fill[v + 1] += fill[v] }
    return [DirectedEdge<Int>](unsafeUninitializedCapacity: 2 * m) { arcs, initializedCount in
        for pair in pairs {
            arcs.initializeElement(at: fill[pair.target], to: DirectedEdge(from: pair.target, to: pair.source))
            fill[pair.target] += 1
        }
        for pair in pairs {
            arcs.initializeElement(at: fill[pair.source], to: DirectedEdge(from: pair.source, to: pair.target))
            fill[pair.source] += 1
        }
        initializedCount = 2 * m
    }
}

/// Every pair (u, v) with u and v in different parts and u < v, in lexicographic order: the edges
/// of a complete multipartite graph whose parts are consecutive ranges of `0..<n`, ending at
/// `ends` (empty parts dropped). A vertex's pairs start at the end of its own part. Computed as
/// read, so no edge list is allocated; `count` is stored.
@frozen
@usableFromInline
package struct _MultipartitePairs: Collection {
    /// The end of each non-empty part, ascending; the last is n.
    @usableFromInline let ends: [Int]
    @usableFromInline let n: Int
    @usableFromInline package let count: Int

    @inlinable
    package init(ends: [Int], count: Int) {
        self.ends = ends
        n = ends.last ?? 0
        self.count = count
    }

    /// The pair (u, v), with u in part `part`.
    @frozen
    @usableFromInline
    package struct Index: Comparable {
        @usableFromInline var u: Int
        @usableFromInline var v: Int
        @usableFromInline var part: Int

        @inlinable
        init(u: Int, v: Int, part: Int) {
            self.u = u
            self.v = v
            self.part = part
        }

        @inlinable
        package static func == (a: Index, b: Index) -> Bool { a.u == b.u && a.v == b.v }

        @inlinable
        package static func < (a: Index, b: Index) -> Bool { (a.u, a.v) < (b.u, b.v) }
    }

    @inlinable package var startIndex: Index { ends.count < 2 ? endIndex : Index(u: 0, v: ends[0], part: 0) }
    @inlinable package var endIndex: Index { Index(u: n, v: n, part: ends.count) }

    @inlinable
    package subscript(position: Index) -> DirectedEdge<Int> {
        DirectedEdge(from: position.u, to: position.v)
    }

    @inlinable
    package func index(after i: Index) -> Index {
        if i.v &+ 1 < n { return Index(u: i.u, v: i.v &+ 1, part: i.part) }
        let u = i.u &+ 1
        let part = u == ends[i.part] ? i.part &+ 1 : i.part
        // The last part's vertices have no larger neighbor in another part.
        guard part < ends.count &- 1 else { return endIndex }
        return Index(u: u, v: ends[part], part: part)
    }
}

extension _MultipartitePairs: Sendable {}
extension _MultipartitePairs.Index: Sendable {}
