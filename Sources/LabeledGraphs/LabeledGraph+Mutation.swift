import AdjacencyMatrixModule
import GraphProtocols
import OrderedCollections

// Over `AdjacencyMatrix`, vertices are appended and edges are inserted and removed. The matrix
// cannot remove a vertex, so neither can the labeled graph. `CompressedSparseRow` is immutable and
// is rebuilt through `init(_:)`.

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

    /// Inserts `edge`, first inserting each endpoint that is not a vertex. The source is inserted
    /// first, so a new source gets the lower index.
    ///
    /// - Returns: Whether the edge was new, and the edge with the labels stored in the graph. Those
    ///   are the existing labels, not the equal ones in `edge`.
    /// - Complexity: Two hashes, plus `insert(_:)` for each new endpoint; O(1) for the edge.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Label>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>) {
        let source = _insert(edge.source).index
        let target = _insert(edge.target).index
        let inserted = _base.insert(edge: DirectedEdge(from: source, to: target)).inserted
        return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))
    }

    /// Inserts `edge` only when both endpoints are already vertices, as `insert(edge:)` does.
    ///
    /// - Returns: As `insert(edge:)`.
    /// - Throws: `VertexNotFound` when an endpoint is not a vertex; then nothing changes.
    /// - Complexity: Two hashes; O(1) for the edge.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: DirectedEdge<Label>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>) {
        guard let source = _labels.firstIndex(of: edge.source),
              let target = _labels.firstIndex(of: edge.target)
        else { throw VertexNotFound() }
        let inserted = _base.insert(edge: DirectedEdge(from: source, to: target)).inserted
        return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))
    }

    /// Removes `edge`, keeping both endpoints.
    ///
    /// - Returns: The removed edge with the labels stored in the graph, or `nil` when it was not an
    ///   edge. An endpoint that is not a vertex also gives `nil`.
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

    /// Removes every edge leaving `label`, keeping the vertex.
    ///
    /// - Returns: The number of edges removed.
    /// - Precondition: `label` is a vertex.
    /// - Complexity: One hash, then O(n / 64) for the row.
    @inlinable
    @discardableResult
    public mutating func removeEdges(from label: Label) -> Int {
        _base.removeEdges(from: _index(of: label))
    }

    /// `removeEdges(from:)`, throwing instead of trapping when `label` is not a vertex.
    ///
    /// - Returns: The number of edges removed.
    /// - Throws: `VertexNotFound` when `label` is not a vertex; then nothing changes.
    @inlinable
    @discardableResult
    public mutating func removeEdges(checkedFrom label: Label) throws(VertexNotFound) -> Int {
        guard let index = _labels.firstIndex(of: label) else { throw VertexNotFound() }
        return _base.removeEdges(from: index)
    }

    /// Removes every edge entering `label`, keeping the vertex.
    ///
    /// - Returns: The number of edges removed.
    /// - Precondition: `label` is a vertex.
    /// - Complexity: One hash, then O(n) for the column.
    @inlinable
    @discardableResult
    public mutating func removeEdges(to label: Label) -> Int {
        _base.removeEdges(to: _index(of: label))
    }

    /// `removeEdges(to:)`, throwing instead of trapping when `label` is not a vertex.
    ///
    /// - Returns: The number of edges removed.
    /// - Throws: `VertexNotFound` when `label` is not a vertex; then nothing changes.
    @inlinable
    @discardableResult
    public mutating func removeEdges(checkedTo label: Label) throws(VertexNotFound) -> Int {
        guard let index = _labels.firstIndex(of: label) else { throw VertexNotFound() }
        return _base.removeEdges(to: index)
    }

    /// Removes every edge leaving or entering `label`, keeping the vertex.
    ///
    /// - Returns: The number of edges removed. A self-loop counts once.
    /// - Precondition: `label` is a vertex.
    /// - Complexity: One hash, then O(n) for the row and the column.
    @inlinable
    @discardableResult
    public mutating func removeEdges(incidentTo label: Label) -> Int {
        _base.removeEdges(incidentTo: _index(of: label))
    }

    /// `removeEdges(incidentTo:)`, throwing instead of trapping when `label` is not a vertex.
    ///
    /// - Returns: The number of edges removed.
    /// - Throws: `VertexNotFound` when `label` is not a vertex; then nothing changes.
    @inlinable
    @discardableResult
    public mutating func removeEdges(checkedIncidentTo label: Label) throws(VertexNotFound) -> Int {
        guard let index = _labels.firstIndex(of: label) else { throw VertexNotFound() }
        return _base.removeEdges(incidentTo: index)
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
    /// - Precondition: The matrix's storage fits (see `AdjacencyMatrix.reserveCapacity(vertexCount:)`).
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int) {
        _labels.reserveCapacity(vertexCount)
        _base.reserveCapacity(vertexCount: vertexCount)
    }
}
