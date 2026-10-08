/// An edge of an undirected graph: the unordered pair {u, v}. `UndirectedEdge(1, 2)` and
/// `UndirectedEdge(2, 1)` are equal and hash alike.
///
/// `u` and `v` keep the order they were given in. That order is not part of the value, as a
/// `Set`'s iteration order is not: equal edges may list their endpoints in different orders. Code
/// that needs the endpoint across from a vertex uses `oppositeVertex(to:)`.
///
/// An edge whose endpoints are equal is a self-loop.
@frozen
public struct UndirectedEdge<Vertex: Hashable>: Hashable {
    /// One endpoint, the first given.
    public var u: Vertex

    /// The other endpoint, the second given.
    public var v: Vertex

    @inlinable
    public init(_ u: Vertex, _ v: Vertex) {
        self.u = u
        self.v = v
    }

    /// Whether the edge is a self-loop, from a vertex to itself.
    @inlinable
    public var isSelfLoop: Bool { u == v }

    /// The endpoint across the edge from `vertex`: `v` for `u`, `u` for `v`, and `vertex` itself
    /// for a self-loop (JGraphT's `getOppositeVertex`).
    ///
    /// - Precondition: `vertex` is `u` or `v`.
    @inlinable
    public func oppositeVertex(to vertex: Vertex) -> Vertex {
        if vertex == u { return v }
        precondition(vertex == v, "\(vertex) is not an endpoint of \(self)")
        return u
    }

    /// Whether both edges join the same two vertices, in either order.
    @inlinable
    public static func == (lhs: UndirectedEdge, rhs: UndirectedEdge) -> Bool {
        (lhs.u == rhs.u && lhs.v == rhs.v) || (lhs.u == rhs.v && lhs.v == rhs.u)
    }

    /// Hashes the two endpoints without their order: each endpoint is hashed on its own, and the
    /// smaller hash is combined first.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        let a = u.hashValue, b = v.hashValue
        hasher.combine(min(a, b))
        hasher.combine(max(a, b))
    }
}

extension UndirectedEdge: Sendable where Vertex: Sendable {}

extension UndirectedEdge: Comparable where Vertex: Comparable {
    /// Lexicographic on the endpoints in ascending order, (min(u, v), max(u, v)), so it agrees
    /// with `==`: neither of `{1, 2}` and `{2, 1}` comes first.
    @inlinable
    public static func < (lhs: UndirectedEdge, rhs: UndirectedEdge) -> Bool {
        let l = lhs.u < lhs.v ? (lhs.u, lhs.v) : (lhs.v, lhs.u)
        let r = rhs.u < rhs.v ? (rhs.u, rhs.v) : (rhs.v, rhs.u)
        return l.0 < r.0 || (l.0 == r.0 && l.1 < r.1)
    }
}

extension UndirectedEdge: BitwiseCopyable where Vertex: BitwiseCopyable {}

extension UndirectedEdge: Encodable where Vertex: Encodable {}

extension UndirectedEdge: Decodable where Vertex: Decodable {}

extension UndirectedEdge: CustomStringConvertible, CustomDebugStringConvertible {
    /// `u–v`.
    public var description: String { "\(u)–\(v)" }

    /// `u–v` with each endpoint written as `Array` writes its elements, so `String` endpoints are
    /// quoted: `"a"–"b"`.
    public var debugDescription: String { GraphDescription.edge(self) }
}
