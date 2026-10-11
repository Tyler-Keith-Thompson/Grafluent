/// An ordered pair: the vertex `(g, h)` of a graph product, with `g` a vertex of the first factor
/// and `h` one of the second (JGraphT's `Pair`, C++'s `std::pair`).
///
/// Comparable lexicographically, as tuples compare, and printed as `(g, h)`. A nested product's
/// vertices nest: `cartesianProduct(cartesianProduct(a, b), c)` has vertices
/// `Pair<Pair<A, B>, C>`. Code with its own `Pair` type can write `GraphProducts.Pair`.
@frozen
public struct Pair<First: Hashable, Second: Hashable>: Hashable {
    /// The vertex of the first factor.
    public var first: First
    /// The vertex of the second factor.
    public var second: Second

    @inlinable
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

extension Pair: Comparable where First: Comparable, Second: Comparable {
    @inlinable
    public static func < (lhs: Pair, rhs: Pair) -> Bool {
        lhs.first < rhs.first || (lhs.first == rhs.first && lhs.second < rhs.second)
    }
}

extension Pair: Sendable where First: Sendable, Second: Sendable {}
extension Pair: BitwiseCopyable where First: BitwiseCopyable, Second: BitwiseCopyable {}

extension Pair: Encodable where First: Encodable, Second: Encodable {
    /// Encodes the pair as a two-element unkeyed container, `[g, h]`.
    @inlinable
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(first)
        try container.encode(second)
    }
}

extension Pair: Decodable where First: Decodable, Second: Decodable {
    /// Decodes a two-element unkeyed container, `[g, h]`.
    @inlinable
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        first = try container.decode(First.self)
        second = try container.decode(Second.self)
    }
}

extension Pair: CustomStringConvertible {
    /// `(g, h)`.
    public var description: String { "(\(first), \(second))" }
}
