import GraphProtocols
import OrderedCollections

/// A directed graph whose vertices are `Hashable` labels, stored over an index-based
/// representation whose vertices are `0..<n` (BGL's `labeled_graph` adaptor).
///
/// `CompressedSparseRow` and `AdjacencyMatrix` lay out their storage by vertex number, so they
/// take only `Int` vertices. A `LabeledGraph` keeps an `OrderedSet<Label>` whose element `i` names
/// base vertex `i`, and conforms to `DirectedGraph` (and, over a bidirectional base,
/// `BidirectionalDirectedGraph`) with `Vertex == Label`, so algorithms take and return labels.
///
/// **Hashing at the boundary only.** A label-space member (`successors(of:)`, `outDegree(of:)`,
/// `contains(_:)`, `vertexIndex(of:)`) looks its label up once and then reads the base by index.
/// Every index-space member (`successorIndices(ofIndex:)`, `outEdges(ofIndex:)`, the edge indices
/// and `_withSuccessorIndexRows`) is the base's own, with the base's own types, so an algorithm
/// that runs in index space, as Traversal, Connectivity and ShortestPaths do, hashes each input
/// label once and nothing per edge. Results map back through an array read.
///
/// **Indices.** The labels are numbered in the order they were added. The initializers that take
/// labeled vertices and edges list the given vertices first, then each new endpoint in order of
/// first appearance, as NetworkX's `convert_node_labels_to_integers(G, ordering="default")`
/// numbers `add_nodes_from` followed by `add_edges_from`. `vertexIndex(of:)` and
/// `vertex(atIndex:)` convert in both directions, like LEMON's `RangeIdMap` with its `InverseMap`.
///
/// **Positions are the base's.** `Edges.Index` is `Base.Edges.Index`: `Int` edge indices in
/// row-major order of the vertex indices for `CompressedSparseRow`, `(source, target)` cells for
/// `AdjacencyMatrix`. Data kept beside the base by position stays valid through the labels.
///
/// **Bases.** Any `DirectedGraph<Int>` whose vertices are `0..<vertexCount` in index order can be
/// labeled through `init(_:labels:)`. Construction from labels and mutation are offered for
/// `CompressedSparseRow` (immutable) and `AdjacencyMatrix` (vertices appended, edges inserted and
/// removed). Representations that already take `Hashable` vertices (`AdjacencyList`,
/// `DirectedPseudograph`, `StableDirectedGraph`) hash their `Int` vertices to slots, so labeling
/// them would hash twice at every boundary call; use them with the labels directly.
///
/// **Missing labels.** The label-space members trap on a label that is not a vertex, like an
/// `Array` subscript. `vertexIndex(safe:)`, `successors(safe:)` and the other `safe:` spellings
/// return `nil` instead, at the cost of the same single lookup.
///
/// Copy-on-write comes from the two stored values. `base` is read-only, so the labels and the base
/// cannot fall out of step.
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

    /// The underlying index-based graph: base vertex `i` is `vertex(atIndex: i)`. O(1). Read-only,
    /// as BGL's `labeled_graph::graph()` is in spirit: adding a base vertex here would leave it
    /// without a label.
    @inlinable
    public var base: Base { _base }
}

extension LabeledGraph where Base: DirectedGraph<Int> {
    /// Labels `base`: `labels` lists the label of base vertex `0`, then `1`, and so on. O(n)
    /// expected (each label hashed once, and the base's vertices read once). The base is stored,
    /// not copied.
    ///
    /// - Precondition: `base.vertexIndexBound` is not `nil`; `base.vertices` is exactly
    ///   `0..<base.vertexCount` in index order (so `base.vertexIndex(of: i) == i`); `labels` has
    ///   `base.vertexCount` elements; and no label repeats.
    @inlinable
    public init(_ base: Base, labels: some Sequence<Label>) {
        switch Self._validated(base, labels: labels) {
        case .success(let labels): self.init(_labels: labels, _base: base)
        case .failure(let failure): preconditionFailure(failure.message)
        }
    }

    /// Why a base and its labels cannot form a `LabeledGraph`: the preconditions of
    /// `init(_:labels:)`, checked in order, without trapping, for `init(_:labels:)` and decoding.
    @inlinable
    internal static func _validated(_ base: Base, labels: some Sequence<Label>) -> Result<OrderedSet<Label>, _LabelingFailure> {
        guard let n = base.vertexIndexBound else {
            return .failure(_LabelingFailure(inBase: true, "base is not densely indexed (vertexIndexBound is nil)"))
        }
        var expected = 0
        for v in base.vertices {
            guard v == expected, base.vertexIndex(of: v) == expected else {
                return .failure(_LabelingFailure(inBase: true, "base vertices are not 0..<vertexCount in index order"))
            }
            expected += 1
        }
        guard expected == n else {
            return .failure(_LabelingFailure(inBase: true, "base vertices are not 0..<vertexCount in index order"))
        }
        let given = Array(labels)
        guard given.count == n else {
            return .failure(_LabelingFailure(inBase: false, "\(given.count) labels for \(n) vertices"))
        }
        var set = OrderedSet<Label>(minimumCapacity: n)
        for label in given {
            guard set.append(label).inserted else {
                return .failure(_LabelingFailure(inBase: false, "duplicate label \(label)"))
            }
        }
        return .success(set)
    }
}

extension LabeledGraph: Sendable where Label: Sendable, Base: Sendable {}

/// A broken precondition of `LabeledGraph.init(_:labels:)`: its message, and whether the base
/// (rather than the labels) is at fault.
@usableFromInline
internal struct _LabelingFailure: Error {
    @usableFromInline let inBase: Bool
    @usableFromInline let message: String

    @inlinable
    init(inBase: Bool, _ message: String) {
        self.inBase = inBase
        self.message = message
    }
}

// MARK: - Index conversions

extension LabeledGraph {
    /// The index of `label`, or `nil` when it is not a vertex. One hash.
    @inlinable
    public func vertexIndex(safe label: Label) -> Int? {
        _labels.firstIndex(of: label)
    }

    /// The index of `label`, trapping when it is not a vertex. One hash.
    ///
    /// Never inlined: a hash costs far more than the call, and inlining it into generic
    /// algorithms that have a label-space fallback branch (`_VertexIdentifiers.forEachSuccessor`)
    /// made them too large to inline their per-edge closures, which cost 1.3× on CSR
    /// breadth-first search.
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

    /// The labels and the index-space edges of `graph`. With vertex indices, its vertices are in
    /// index order, so the edges come from `successorIndices(ofIndex:)` and only the vertices are
    /// hashed; otherwise two hashes per edge.
    @inlinable
    internal static func _numbered(_ graph: some DirectedGraph<Label>) -> (labels: OrderedSet<Label>, edges: [DirectedEdge<Int>]) {
        guard let n = graph.vertexIndexBound else {
            return _numbered(vertices: graph.vertices, edges: graph.edges)
        }
        let labels = OrderedSet(graph.vertices)
        precondition(labels.count == n, "The graph's vertices are not distinct")
        var numbered: [DirectedEdge<Int>] = []
        numbered.reserveCapacity(graph.edgeCount)
        for v in 0 ..< n {
            for w in graph.successorIndices(ofIndex: v) { numbered.append(DirectedEdge(from: v, to: w)) }
        }
        return (labels, numbered)
    }
}
