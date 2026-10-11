import GraphProtocols

extension FunctionalGraph: Equatable, Hashable {
    /// Whether f is the same function: the successor arrays are equal. O(n).
    @inlinable
    public static func == (lhs: FunctionalGraph, rhs: FunctionalGraph) -> Bool {
        lhs._successors == rhs._successors
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_successors)
    }
}

/// Encoded as the bare successor array, `[f(0), f(1), …]`.
extension FunctionalGraph: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_successors)
    }

    /// Decodes the successor array.
    ///
    /// - Throws: `DecodingError.dataCorrupted` when a successor is not in `0..<n`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let successors = try container.decode([Int].self)
        let n = successors.count
        for (v, w) in successors.enumerated() where UInt(bitPattern: w) >= UInt(bitPattern: n) {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "successor \(w) of \(v) is not a vertex (0..<\(n))"
            ))
        }
        self.init(_unchecked: successors)
    }
}

extension FunctionalGraph: CustomStringConvertible, CustomDebugStringConvertible {
    /// `FunctionalGraph([f(0), f(1), …])`.
    public var description: String { "FunctionalGraph(\(_successors))" }

    /// The same as `description`.
    public var debugDescription: String { description }
}
