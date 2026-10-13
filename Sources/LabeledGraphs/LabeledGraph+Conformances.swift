import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import OrderedCollections

// MARK: - Equatable

extension LabeledGraph: Equatable where Base: DirectedGraph<Int> & Equatable {
    /// Equal when the label sets are equal and the labeled edge sets are equal, whatever index
    /// each graph gave each label.
    ///
    /// When the labels are equal in order, this is `lhs.base == rhs.base`. Otherwise the label sets
    /// are compared with n hashes, the right graph's indices are mapped into the left's, and each
    /// mapped edge is looked up with the left base's `contains(edge:)`. That is O(m log d) for
    /// `CompressedSparseRow` and O(m) for `AdjacencyMatrix`. A base that allows parallel edges is
    /// compared by edge multiplicity through a dictionary.
    @inlinable
    public static func == (lhs: LabeledGraph, rhs: LabeledGraph) -> Bool {
        if lhs._labels == rhs._labels { return lhs._base == rhs._base }
        let n = lhs._labels.count
        guard n == rhs._labels.count, lhs._base.edgeCount == rhs._base.edgeCount else { return false }
        // `toLeft[i]` is the left index of the right graph's label `i`.
        var toLeft = [Int](repeating: 0, count: n)
        for (i, label) in rhs._labels.enumerated() {
            guard let j = lhs._labels.firstIndex(of: label) else { return false }
            toLeft[i] = j
        }
        if Base.self == CompressedSparseRow.self || Base.self == AdjacencyMatrix.self {
            // Edge sets: equal counts and containment one way suffice.
            for edge in rhs._base.edges where !lhs._base.contains(edge: DirectedEdge(from: toLeft[edge.source], to: toLeft[edge.target])) {
                return false
            }
            return true
        }
        var multiplicity: [DirectedEdge<Int>: Int] = [:]
        for edge in lhs._base.edges { multiplicity[edge, default: 0] += 1 }
        for edge in rhs._base.edges {
            let mapped = DirectedEdge(from: toLeft[edge.source], to: toLeft[edge.target])
            guard let count = multiplicity[mapped], count > 0 else { return false }
            multiplicity[mapped] = count - 1
        }
        return true
    }
}

// MARK: - Hashable

extension LabeledGraph: Hashable where Base: DirectedGraph<Int> & Hashable {
    /// Hashes the label set and the labeled edges independently of the index assignment, so graphs
    /// equal under `==` hash alike.
    ///
    /// The hash combines the counts, the sum of the labels' hash values, and the sum over the edges
    /// of a hash of the two endpoints' hash values. Each parallel edge counts separately.
    ///
    /// - Complexity: O(n + m). Each label is hashed once.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_labels.count)
        hasher.combine(_base.edgeCount)
        var labelHashes: [Int] = []
        labelHashes.reserveCapacity(_labels.count)
        var labelSum: UInt = 0
        for label in _labels {
            let h = label.hashValue
            labelHashes.append(h)
            labelSum &+= UInt(bitPattern: h)
        }
        var edgeSum: UInt = 0
        for edge in _base.edges {
            var edgeHasher = Hasher()
            edgeHasher.combine(labelHashes[edge.source])
            edgeHasher.combine(labelHashes[edge.target])
            edgeSum &+= UInt(bitPattern: edgeHasher.finalize())
        }
        hasher.combine(labelSum)
        hasher.combine(edgeSum)
    }
}

// MARK: - Codable

extension LabeledGraph: Codable where Label: Codable, Base: DirectedGraph<Int> & Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case labels
        case base
    }

    /// Encodes `{"labels": [...], "base": ...}`, with the labels in index order and the base in its
    /// own form.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(_labels.elements, forKey: .labels)
        try container.encode(_base, forKey: .base)
    }

    /// Decodes and checks the requirements of `init(_:labels:)`.
    ///
    /// - Throws: `DecodingError.dataCorrupted` at `labels` for a count mismatch or a repeated
    ///   label, and at `base` for vertices that are not `0..<vertexCount` in index order.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let labels = try container.decode([Label].self, forKey: .labels)
        let base = try container.decode(Base.self, forKey: .base)
        do throws(LabelingError) {
            self = try Self(base, labels: labels)
        } catch {
            let (key, message): (_CodingKeys, String) = switch error {
            case .baseNotDenselyIndexed: (.base, "base is not densely indexed (vertexIndexBound is nil)")
            case .baseVerticesNotInIndexOrder: (.base, "base vertices are not 0..<vertexCount in index order")
            case .labelCountMismatch(let labelCount, let vertexCount): (.labels, "\(labelCount) labels for \(vertexCount) vertices")
            case .duplicateLabel(let position): (.labels, "duplicate label \(labels[position])")
            }
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: message)
        }
    }
}

// MARK: - Descriptions

extension LabeledGraph: CustomStringConvertible, CustomDebugStringConvertible where Base: DirectedGraph<Int> {
    /// The labels and the labeled edges, at most 16 of each, as in `["a", "b"]; ["a"→"b"]`. A
    /// labeled graph prints like an `AdjacencyList` of the same vertices and edges in the same
    /// order.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 labeled edges.
    public var debugDescription: String {
        "LabeledGraph<\(Label.self), \(Base.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }
}
