// Modeled on swift-collections' MinimalSequence (Apache-2.0); independent implementation.

import Testing

/// What a `MinimalSequence` reports as its `underestimatedCount`.
public enum UnderestimatedCount: Hashable, Sendable, CustomTestStringConvertible {
    /// The exact count.
    case precise
    /// Half the count.
    case half
    /// A fixed value.
    case value(Int)

    public static let all: [UnderestimatedCount] = [.precise, .half, .value(0)]

    public var testDescription: String {
        switch self {
        case .precise: "precise"
        case .half: "half"
        case .value(let n): "value(\(n))"
        }
    }
}

/// A single-pass sequence: every iterator shares one cursor, so a consumer that iterates twice
/// sees no elements the second time. Use it to test initializers that take `some Sequence`.
public struct MinimalSequence<Element>: Sequence {
    fileprivate final class Cursor {
        let elements: [Element]
        var position = 0
        init(_ elements: [Element]) { self.elements = elements }
    }

    private let cursor: Cursor
    private let reportedCount: UnderestimatedCount

    public init(elements: some Sequence<Element>, underestimatedCount: UnderestimatedCount = .value(0)) {
        self.cursor = Cursor(Array(elements))
        self.reportedCount = underestimatedCount
    }

    public var underestimatedCount: Int {
        let count = cursor.elements.count - cursor.position
        switch reportedCount {
        case .precise: return count
        case .half: return count / 2
        case .value(let n):
            precondition(n <= count, "underestimatedCount must not exceed the number of elements")
            return n
        }
    }

    public struct Iterator: IteratorProtocol {
        fileprivate let cursor: Cursor

        public mutating func next() -> Element? {
            guard cursor.position < cursor.elements.count else { return nil }
            defer { cursor.position += 1 }
            return cursor.elements[cursor.position]
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(cursor: cursor)
    }
}
