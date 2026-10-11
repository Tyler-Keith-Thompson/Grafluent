import GraphProtocols
import OrderedCollections

// Every index-space requirement is the base's, with the base's types: in particular
// `SuccessorIndices` and `PredecessorIndices`, whose protocol defaults would map each neighbor
// label back through `vertexIndex(of:)`, one hash per edge.

extension LabeledGraph: DirectedGraph where Base: DirectedGraph<Int> {
    public typealias Vertex = Label
    public typealias Vertices = OrderedSet<Label>
    public typealias Successors = LazyMapSequence<Base.SuccessorIndices, Label>
    public typealias OutEdges = Base.OutEdges
    public typealias SuccessorIndices = Base.SuccessorIndices

    /// The labels in index order: `vertices[i]` names base vertex `i`. O(1).
    @inlinable
    public var vertices: OrderedSet<Label> { _labels }

    /// The base's edges with their endpoints labeled, in the base's order and at its positions.
    /// O(1); reading an edge is the base's read plus two array reads, with no hashing.
    @inlinable
    public var edges: Edges { Edges(base: _base.edges, labels: _labels) }

    /// The edges of a `LabeledGraph`: the base's edges, at the base's positions, with labels for
    /// endpoints.
    @frozen
    public struct Edges: Collection {
        public typealias Index = Base.Edges.Index
        public typealias Element = DirectedEdge<Label>
        public typealias Indices = Base.Edges.Indices

        @usableFromInline let base: Base.Edges
        @usableFromInline let labels: OrderedSet<Label>

        @inlinable
        init(base: Base.Edges, labels: OrderedSet<Label>) {
            self.base = base
            self.labels = labels
        }

        @inlinable public var startIndex: Index { base.startIndex }
        @inlinable public var endIndex: Index { base.endIndex }
        @inlinable public var count: Int { base.count }
        @inlinable public var isEmpty: Bool { base.isEmpty }
        @inlinable public func index(after i: Index) -> Index { base.index(after: i) }

        /// The base's positions, of the base's type: `Range<Int>` for `CompressedSparseRow`.
        @inlinable public var indices: Base.Edges.Indices { base.indices }

        /// The edge at `position`, labeled. The base's subscript plus two array reads.
        ///
        /// - Precondition: `position` is a valid position, not `endIndex` (the base checks).
        @inlinable
        public subscript(position: Index) -> DirectedEdge<Label> {
            let edge = base[position]
            return DirectedEdge(from: labels[edge.source], to: labels[edge.target])
        }

        /// Two hashes, then the base's own membership test (a binary search for
        /// `CompressedSparseRow`, a bit for `AdjacencyMatrix`).
        @inlinable
        public func _customContainsEquatableElement(_ element: DirectedEdge<Label>) -> Bool? {
            guard let source = labels.firstIndex(of: element.source),
                  let target = labels.firstIndex(of: element.target)
            else { return false }
            return base.contains(DirectedEdge(from: source, to: target))
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(base: base.makeIterator(), labels: labels)
        }

        /// The base's iterator, labeling each edge.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var base: Base.Edges.Iterator
            @usableFromInline let labels: OrderedSet<Label>

            @inlinable
            init(base: Base.Edges.Iterator, labels: OrderedSet<Label>) {
                self.base = base
                self.labels = labels
            }

            @inlinable
            public mutating func next() -> DirectedEdge<Label>? {
                guard let edge = base.next() else { return nil }
                return DirectedEdge(from: labels[edge.source], to: labels[edge.target])
            }
        }
    }

    /// The labels of `label`'s successors, in the base's row order (ascending index for both
    /// `CompressedSparseRow` and `AdjacencyMatrix`). One hash, then a lazy map of the base's row
    /// through an array read.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func successors(of label: Label) -> Successors {
        _successors(ofIndex: _index(of: label))
    }

    @inlinable
    internal func _successors(ofIndex index: Int) -> Successors {
        let labels = _labels
        return _base.successorIndices(ofIndex: index).lazy.map { labels[$0] }
    }

    /// The base's out-edge positions of `label`. One hash.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func outEdges(of label: Label) -> Base.OutEdges {
        _base.outEdges(ofIndex: _index(of: label))
    }

    /// The base's out-degree of `label`. One hash, then the base's (O(1) for both
    /// `CompressedSparseRow` and `AdjacencyMatrix`).
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func outDegree(of label: Label) -> Int {
        _base.outDegree(of: _index(of: label))
    }

    /// The label of the edge's source: the base's `source(ofEdgeAt:)` (O(log n) for
    /// `CompressedSparseRow`, O(1) for `AdjacencyMatrix`) and an array read, with no hashing.
    ///
    /// - Precondition: `position` is the position of an edge (the base checks).
    @inlinable
    @inline(__always)
    public func source(ofEdgeAt position: Base.Edges.Index) -> Label {
        _labels[_base.source(ofEdgeAt: position)]
    }

    /// The label of the edge's target: the base's `target(ofEdgeAt:)` and an array read, with no
    /// hashing.
    ///
    /// - Precondition: `position` is the position of an edge (the base checks).
    @inlinable
    @inline(__always)
    public func target(ofEdgeAt position: Base.Edges.Index) -> Label {
        _labels[_base.target(ofEdgeAt: position)]
    }

    /// The number of labels, which is the base's vertex count. O(1).
    @inlinable
    @inline(__always)
    public var vertexCount: Int { _labels.count }

    /// The base's edge count.
    @inlinable
    @inline(__always)
    public var edgeCount: Int { _base.edgeCount }

    /// Whether `label` is a vertex. One hash; never traps.
    @inlinable
    public func contains(_ label: Label) -> Bool {
        _labels.contains(label)
    }

    /// Whether `edge` is an edge: two hashes, then the base's `contains(edge:)` (O(log d) for
    /// `CompressedSparseRow`, O(1) for `AdjacencyMatrix`). False, without trapping, when either
    /// endpoint is not a vertex.
    @inlinable
    public func contains(edge: DirectedEdge<Label>) -> Bool {
        guard let source = _labels.firstIndex(of: edge.source),
              let target = _labels.firstIndex(of: edge.target)
        else { return false }
        return _base.contains(edge: DirectedEdge(from: source, to: target))
    }

    /// The base's bound, which is `vertexCount`: never `nil`, so index-space algorithms keep their
    /// state in arrays.
    @inlinable
    @inline(__always)
    public var vertexIndexBound: Int? { _base.vertexIndexBound }

    /// The index of `label`, the base vertex it names. One hash.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    @inline(__always)
    public func vertexIndex(of label: Label) -> Int {
        _index(of: label)
    }

    /// The label of base vertex `index`. O(1), an array read.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    @inline(__always)
    public func vertex(atIndex index: Int) -> Label {
        precondition(index >= 0 && index < _labels.count, "index \(index) out of range 0..<\(_labels.count)")
        return _labels[index]
    }

    /// The base's `successorIndices(ofIndex:)`, of the base's own type. No hashing.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    @inline(__always)
    public func successorIndices(ofIndex index: Int) -> Base.SuccessorIndices {
        _base.successorIndices(ofIndex: index)
    }

    /// The base's `outEdges(ofIndex:)`. No hashing.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    @inline(__always)
    public func outEdges(ofIndex index: Int) -> Base.OutEdges {
        _base.outEdges(ofIndex: index)
    }

    /// The base's edge index bound: `edgeCount` for `CompressedSparseRow`, `nil` for
    /// `AdjacencyMatrix`.
    @inlinable
    @inline(__always)
    public var edgeIndexBound: Int? { _base.edgeIndexBound }

    /// The base's `edgeIndex(of:)`.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil` (the base traps otherwise), and `position` is
    ///   a position in `edges`.
    @inlinable
    @inline(__always)
    public func edgeIndex(of position: Base.Edges.Index) -> Int {
        _base.edgeIndex(of: position)
    }

    /// The base's rows (`CompressedSparseRow`'s offsets and targets), valid here because a label's
    /// index is its base vertex and the positions are the base's.
    @inlinable
    @inline(__always)
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        _base._withSuccessorIndexRows(body)
    }
}

extension LabeledGraph where Base: DirectedGraph<Int> {
    /// `successors(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func successors(safe label: Label) -> Successors? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _successors(ofIndex: index)
    }

    /// `outEdges(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func outEdges(safe label: Label) -> Base.OutEdges? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _base.outEdges(ofIndex: index)
    }

    /// `outDegree(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func outDegree(safe label: Label) -> Int? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _base.outDegree(of: index)
    }
}

extension LabeledGraph.Edges: BidirectionalCollection where Base: DirectedGraph<Int>, Base.Edges: BidirectionalCollection {
    @inlinable
    public func index(before i: Index) -> Index { base.index(before: i) }
}

extension LabeledGraph.Edges: RandomAccessCollection where Base: DirectedGraph<Int>, Base.Edges: RandomAccessCollection {
    @inlinable
    public func index(_ i: Index, offsetBy distance: Int) -> Index { base.index(i, offsetBy: distance) }

    @inlinable
    public func distance(from start: Index, to end: Index) -> Int { base.distance(from: start, to: end) }
}

extension LabeledGraph.Edges: Sendable where Label: Sendable, Base.Edges: Sendable {}
extension LabeledGraph.Edges.Iterator: Sendable where Label: Sendable, Base.Edges.Iterator: Sendable {}

// MARK: - BidirectionalDirectedGraph

extension LabeledGraph: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph<Int> {
    public typealias Predecessors = LazyMapSequence<Base.PredecessorIndices, Label>
    public typealias InEdges = Base.InEdges
    public typealias PredecessorIndices = Base.PredecessorIndices

    /// The labels of `label`'s predecessors, in the base's column order (ascending index for
    /// `AdjacencyMatrix`). One hash, then a lazy map of the base's row.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func predecessors(of label: Label) -> Predecessors {
        _predecessors(ofIndex: _index(of: label))
    }

    @inlinable
    internal func _predecessors(ofIndex index: Int) -> Predecessors {
        let labels = _labels
        return _base.predecessorIndices(ofIndex: index).lazy.map { labels[$0] }
    }

    /// The base's in-edge positions of `label`. One hash.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func inEdges(of label: Label) -> Base.InEdges {
        _base.inEdges(ofIndex: _index(of: label))
    }

    /// The base's in-degree of `label`. One hash.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func inDegree(of label: Label) -> Int {
        _base.inDegree(of: _index(of: label))
    }

    /// The base's degree of `label`, a self-loop counted twice. One hash.
    ///
    /// - Precondition: `label` is a vertex.
    @inlinable
    public func degree(of label: Label) -> Int {
        _base.degree(of: _index(of: label))
    }

    /// The base's `predecessorIndices(ofIndex:)`, of the base's own type. No hashing.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    @inline(__always)
    public func predecessorIndices(ofIndex index: Int) -> Base.PredecessorIndices {
        _base.predecessorIndices(ofIndex: index)
    }

    /// The base's `inEdges(ofIndex:)`. No hashing.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    @inline(__always)
    public func inEdges(ofIndex index: Int) -> Base.InEdges {
        _base.inEdges(ofIndex: index)
    }
}

extension LabeledGraph where Base: BidirectionalDirectedGraph<Int> {
    /// `predecessors(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func predecessors(safe label: Label) -> Predecessors? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _predecessors(ofIndex: index)
    }

    /// `inEdges(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func inEdges(safe label: Label) -> Base.InEdges? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _base.inEdges(ofIndex: index)
    }

    /// `inDegree(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func inDegree(safe label: Label) -> Int? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _base.inDegree(of: index)
    }

    /// `degree(of:)`, or `nil` when `label` is not a vertex. One hash.
    @inlinable
    public func degree(safe label: Label) -> Int? {
        guard let index = _labels.firstIndex(of: label) else { return nil }
        return _base.degree(of: index)
    }
}
