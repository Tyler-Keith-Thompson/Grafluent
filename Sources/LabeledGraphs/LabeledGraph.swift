import GraphProtocols
import OrderedCollections

/// A directed graph whose vertices are `Hashable` labels, stored over an index-based
/// representation whose vertices are `0..<n`.
///
/// `CompressedSparseRow` and `AdjacencyMatrix` lay out their storage by vertex number and take only
/// `Int` vertices. A `LabeledGraph` keeps an `OrderedSet<Label>` whose element `i` names base
/// vertex `i`. It conforms to `DirectedGraph` (and, over a bidirectional base,
/// `BidirectionalDirectedGraph`) with `Vertex == Label`, so algorithms take and return labels.
///
/// ## Hashing
///
/// A label-space member (`successors(of:)`, `outDegree(of:)`, `contains(_:)`,
/// `vertexIndex(of:)`) looks its label up once and then reads the base by index. The index-space
/// members (`successorIndices(ofIndex:)`, `outEdges(ofIndex:)`, the edge indices and
/// `_withSuccessorIndexRows`) are the base's own, with the base's types. An algorithm that runs in
/// index space, as Traversal, Connectivity and ShortestPaths do, hashes each input label once and
/// nothing per edge. Results map back through an array read.
///
/// ## Indices
///
/// Labels are numbered in the order they were added. The initializers that take labeled vertices
/// and edges number the given vertices first, then each new endpoint in order of first appearance.
/// `vertexIndex(of:)` and `vertex(atIndex:)` convert in both directions.
///
/// ## Edge positions
///
/// `Edges.Index` is `Base.Edges.Index`. For `CompressedSparseRow` it is an `Int` edge index in
/// row-major order of the vertex indices, and for `AdjacencyMatrix` a `(source, target)` cell.
/// Data kept beside the base by position stays valid through the labels.
///
/// ## Bases
///
/// `init(_:labels:)` labels any `DirectedGraph<Int>` whose vertices are `0..<vertexCount` in index
/// order. Construction from labels is available over `CompressedSparseRow` and `AdjacencyMatrix`,
/// and mutation over `AdjacencyMatrix`. Representations that already take `Hashable` vertices
/// (`AdjacencyList`, `DirectedPseudograph`, `StableDirectedGraph`) hash their vertices to slots, so
/// use those with the labels directly rather than wrapping them.
///
/// ## Missing labels
///
/// The label-space members trap on a label that is not a vertex, like an `Array` subscript.
/// `vertexIndex(checked:)`, `successors(checked:)` and the other `checked:` spellings throw
/// `VertexNotFound` instead, with the same single lookup.
///
/// The labels and the base are stored values with copy-on-write. `base` is read-only, so the two
/// stay in step.
@frozen
public struct LabeledGraph<Label: Hashable, Base> {
    /// Element `i` names base vertex `i`.
    @usableFromInline
    internal var _labels: OrderedSet<Label>

    /// The index-based graph. Its vertices are exactly `0..<_labels.count`, in index order.
    @usableFromInline
    internal var _base: Base

    /// Unchecked: `_labels.count` must be the base's vertex count, and the base's vertices must be
    /// `0..<count` in index order.
    @inlinable
    internal init(_labels: OrderedSet<Label>, _base: Base) {
        self._labels = _labels
        self._base = _base
    }

    /// The underlying index-based graph, in which vertex `i` is `vertex(atIndex: i)`. O(1).
    ///
    /// Read-only, because a vertex added to the base directly would have no label.
    @inlinable
    public var base: Base { _base }
}

extension LabeledGraph where Base: DirectedGraph<Int> {
    /// Labels `base`, giving base vertex `i` the label at offset `i` of `labels`.
    ///
    /// The base is stored, not copied.
    ///
    /// - Throws: `LabelingError` for the first requirement broken, checked in this order.
    ///   `base.vertexIndexBound` must not be `nil`. `base.vertices` must be exactly
    ///   `0..<base.vertexCount` in index order, with `base.vertexIndex(of: i) == i`. `labels` must
    ///   have `base.vertexCount` elements, and no label may repeat.
    /// - Complexity: O(n) expected. Each label is hashed once.
    @inlinable
    public init(_ base: Base, labels: some Sequence<Label>) throws(LabelingError) {
        guard let n = base.vertexIndexBound else { throw .baseNotDenselyIndexed }
        var expected = 0
        for v in base.vertices {
            guard v == expected, base.vertexIndex(of: v) == expected else { throw .baseVerticesNotInIndexOrder }
            expected += 1
        }
        guard expected == n else { throw .baseVerticesNotInIndexOrder }
        let given = Array(labels)
        guard given.count == n else { throw .labelCountMismatch(labelCount: given.count, vertexCount: n) }
        var set = OrderedSet<Label>(minimumCapacity: n)
        for (position, label) in given.enumerated() {
            guard set.append(label).inserted else { throw .duplicateLabel(position: position) }
        }
        self.init(_labels: set, _base: base)
    }
}

extension LabeledGraph: Sendable where Label: Sendable, Base: Sendable {}

// MARK: - Index conversions

extension LabeledGraph {
    /// The index of `label`, throwing instead of trapping when it is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `label` is not a vertex.
    @inlinable
    public func vertexIndex(checked label: Label) throws(VertexNotFound) -> Int {
        guard let index = _labels.firstIndex(of: label) else { throw VertexNotFound() }
        return index
    }

    /// The index of `label`, trapping when it is not a vertex. One hash.
    ///
    /// Never inlined. A hash costs far more than the call, and inlining it into generic algorithms
    /// with a label-space fallback branch (`_VertexIdentifiers.forEachSuccessor`) keeps their
    /// per-edge closures from being inlined.
    @inlinable
    @inline(never)
    internal func _index(of label: Label) -> Int {
        guard let index = _labels.firstIndex(of: label) else {
            preconditionFailure("\(label) is not a vertex of the graph")
        }
        return index
    }
}

// MARK: - Labeling edges

extension LabeledGraph {
    /// The labels in index order (the given vertices, then each new endpoint by first appearance)
    /// and the edges in index space. One hash per vertex and two per edge.
    @inlinable
    internal static func _numbered(
        vertices: some Sequence<Label>,
        edges: some Sequence<DirectedEdge<Label>>
    ) -> (labels: OrderedSet<Label>, edges: [DirectedEdge<Int>]) {
        var labels = OrderedSet(vertices)
        var numbered: [DirectedEdge<Int>] = []
        numbered.reserveCapacity(edges.underestimatedCount)
        for edge in edges {
            let source = labels.append(edge.source).index
            let target = labels.append(edge.target).index
            numbered.append(DirectedEdge(from: source, to: target))
        }
        return (labels, numbered)
    }

    /// The labels and the index-space edges of `graph`. When `graph` has vertex indices, its
    /// vertices are in index order, the edges come from `successorIndices(ofIndex:)`, and only the
    /// vertices are hashed. Otherwise each edge costs two hashes.
    @inlinable
    internal static func _numbered(_ graph: some DirectedGraph<Label>) -> (labels: OrderedSet<Label>, edges: [DirectedEdge<Int>]) {
        guard let n = graph.vertexIndexBound else {
            return _numbered(vertices: graph.vertices, edges: graph.edges)
        }
        // A conforming graph's vertices are distinct and number `vertexIndexBound`.
        let labels = OrderedSet(graph.vertices)
        var numbered: [DirectedEdge<Int>] = []
        numbered.reserveCapacity(graph.edgeCount)
        for v in 0 ..< n {
            for w in graph.successorIndices(ofIndex: v) { numbered.append(DirectedEdge(from: v, to: w)) }
        }
        return (labels, numbered)
    }
}
