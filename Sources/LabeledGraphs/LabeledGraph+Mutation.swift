import AdjacencyMatrixModule
import GraphProtocols
import OrderedCollections

// Mutation over `AdjacencyMatrix`: vertices are appended (the matrix cannot remove one), edges are
// inserted and removed. `CompressedSparseRow` is immutable; rebuild it through `init(_:)`.
//
// Vertex removal is not offered, because no base here supports it. A future base that removes a
// vertex by swap-remove (index n − 1 moving into the hole) must keep the labels in step in the same
// mutation, with `_labels.swapAt(i, n - 1)` and `_labels.removeLast()`, O(1) expected. LEMON's
// `RangeIdMap` (lemon/maps.h) does the same on erase, moving the largest id into the hole ("the ids
// can change when deleting an item"). BGL's `labeled_graph` instead erases from the middle of its
// label vector, shifting every later label.

extension LabeledGraph where Base == AdjacencyMatrix {
    /// Inserts `label` as a new vertex with the next index, unless it is already a vertex.
    ///
    /// - Returns: Whether it was inserted, and the label stored in the graph (the existing one,
    ///   which is equal to `label`, when it was not).
    /// - Complexity: O(1) expected for the label, plus the matrix's `appendVertex()`, amortized
    ///   O(n / 64).
    @inlinable
    @discardableResult
    public mutating func insert(_ label: Label) -> (inserted: Bool, memberAfterInsert: Label) {
        let (inserted, index) = _insert(label)
        return (inserted, _labels[index])
    }

    /// The index of `label`, appending it and a base vertex when it is new.
    @inlinable
    internal mutating func _insert(_ label: Label) -> (inserted: Bool, index: Int) {
        let (inserted, index) = _labels.append(label)
        if inserted { _base.appendVertex() }
        return (inserted, index)
    }

    /// Inserts `edge`, first inserting each endpoint that is not yet a vertex, source first (so a
    /// new source gets the lower index), as NetworkX's `add_edge` does.
    ///
    /// - Returns: Whether the edge was new, and the edge as stored, with the graph's labels.
    /// - Complexity: Two hashes, plus `insert(_:)` for each new endpoint; O(1) for the edge.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Label>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>) {
        let source = _insert(edge.source).index
        let target = _insert(edge.target).index
        let inserted = _base.insert(edge: DirectedEdge(from: source, to: target)).inserted
        return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))
    }

    /// Inserts `edge` only when both endpoints are already vertices; otherwise returns `nil` and
    /// changes nothing.
    ///
    /// - Complexity: Two hashes; O(1) for the edge.
    @inlinable
    @discardableResult
    public mutating func insert(safe edge: DirectedEdge<Label>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>)? {
        guard let source = _labels.firstIndex(of: edge.source),
              let target = _labels.firstIndex(of: edge.target)
        else { return nil }
        let inserted = _base.insert(edge: DirectedEdge(from: source, to: target)).inserted
        return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))
    }

    /// Removes `edge`, keeping both endpoints.
    ///
    /// - Returns: The removed edge, with the graph's labels, or `nil` when it was not an edge,
    ///   including when an endpoint is not a vertex (the matrix's `remove(edge:)` contract).
    /// - Complexity: Two hashes; O(1) for the edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Label>) -> DirectedEdge<Label>? {
        guard let source = _labels.firstIndex(of: edge.source),
              let target = _labels.firstIndex(of: edge.target),
              _base.remove(edge: DirectedEdge(from: source, to: target)) != nil
        else { return nil }
        return DirectedEdge(from: _labels[source], to: _labels[target])
    }

    /// Removes every edge, keeping every label and its index.
    ///
    /// - Parameter keepingCapacity: When false, the matrix releases its spare row capacity.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        _base.removeAllEdges(keepingCapacity: keepingCapacity)
    }

    /// Removes every label, vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _labels.removeAll(keepingCapacity: keepingCapacity)
        _base.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves storage for at least `vertexCount` labels and matrix vertices.
    ///
    /// - Precondition: the matrix's storage fits (see `AdjacencyMatrix.reserveCapacity(vertexCount:)`).
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int) {
        _labels.reserveCapacity(vertexCount)
        _base.reserveCapacity(vertexCount: vertexCount)
    }
}
