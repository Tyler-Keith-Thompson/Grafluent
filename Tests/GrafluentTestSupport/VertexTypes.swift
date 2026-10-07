// Vertex types that stress a container's use of Hashable.
// The idea of a forced-collision key comes from swift-collections' Collider (Apache-2.0);
// this is an independent implementation.

/// A key whose hash is chosen by the test, so any number of distinct keys can be forced
/// into the same hash bucket.
public struct Collider: Hashable, Sendable, CustomStringConvertible {
    public var value: Int
    public var hashValueOverride: Int

    public init(_ value: Int, hash: Int = 0) {
        self.value = value
        self.hashValueOverride = hash
    }

    public static func == (lhs: Collider, rhs: Collider) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValueOverride)
    }

    public var description: String { "Collider(\(value), hash: \(hashValueOverride))" }
}

/// A reference-type key. Two boxes are equal when their values are equal, but they are
/// different objects, so `===` reveals which instance a container stored.
public final class HashableBox: Hashable, Sendable, CustomStringConvertible {
    public let value: Int
    public let label: String

    public init(_ value: Int, label: String = "") {
        self.value = value
        self.label = label
    }

    public static func == (lhs: HashableBox, rhs: HashableBox) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public var description: String { label.isEmpty ? "Box(\(value))" : "Box(\(value), \(label))" }
}
