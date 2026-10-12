import GraphProtocols

extension BidirectionalDirectedGraph {
    /// The graph with every edge reversed, as a lazy view (NetworkX's `reverse_view`, Boost's
    /// `reverse_graph`). O(1); the view holds a copy of the graph and copies no edge.
    ///
    /// The view keeps the graph's vertices, vertex indices, edge positions and edge indices; the
    /// edge at position `p` runs from the graph's target of `p` to its source. Its out-rows are the
    /// graph's in-rows. To materialize it, pass it to a representation's initializer
    /// (`AdjacencyList(g.reverseView)`), or use the representation's own `transposed()`.
    @inlinable
    public var reverseView: ReverseView<Self> { ReverseView(base: self) }
}

extension ReverseView {
    /// The base: reversing twice gives back the graph itself, with no view around it. O(1).
    @inlinable
    public var reverseView: Base { base }
}

/// A bidirectional directed graph with every edge reversed: the converse (or transpose) of its
/// base. Made by `reverseView`.
///
/// Every member forwards to the base with the two directions swapped, so `successors` is the base's
/// `predecessors`, `outEdges(ofIndex:)` the base's `inEdges(ofIndex:)`, and the base's own fast
/// members are the ones called. Positions and edge indices are the base's, so a weight keyed by the
/// base's positions applies to the view unchanged.
@frozen
public struct ReverseView<Base: BidirectionalDirectedGraph>: BidirectionalDirectedGraph {
    public typealias Vertex = Base.Vertex

    /// The graph the view reverses.
    public let base: Base

    @inlinable
    init(base: Base) { self.base = base }

    /// The base's vertices, in the base's order.
    @inlinable
    public var vertices: Base.Vertices { base.vertices }

    /// The base's edges, each reversed, at the base's positions.
    @inlinable
    public var edges: Edges { Edges(base: base.edges) }

    /// The edges of a `ReverseView`: the base's, each reversed, at the base's positions.
    @frozen
    public struct Edges: Collection {
        @usableFromInline let base: Base.Edges

        @inlinable
        init(base: Base.Edges) { self.base = base }

        @inlinable public var startIndex: Base.Edges.Index { base.startIndex }
        @inlinable public var endIndex: Base.Edges.Index { base.endIndex }
        @inlinable public var count: Int { base.count }
        @inlinable public var isEmpty: Bool { base.isEmpty }
        @inlinable public func index(after i: Base.Edges.Index) -> Base.Edges.Index { base.index(after: i) }

        @inlinable
        public subscript(position: Base.Edges.Index) -> DirectedEdge<Vertex> {
            let edge = base[position]
            return DirectedEdge(from: edge.target, to: edge.source)
        }
    }

    /// The base's `predecessors(of:)`.
    @inlinable
    public func successors(of vertex: Vertex) -> Base.Predecessors { base.predecessors(of: vertex) }

    /// The base's `inEdges(of:)`.
    @inlinable
    public func outEdges(of vertex: Vertex) -> Base.InEdges { base.inEdges(of: vertex) }

    /// The base's `successors(of:)`.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Base.Successors { base.successors(of: vertex) }

    /// The base's `outEdges(of:)`.
    @inlinable
    public func inEdges(of vertex: Vertex) -> Base.OutEdges { base.outEdges(of: vertex) }

    /// The base's target of the edge.
    @inlinable
    public func source(ofEdgeAt position: Base.Edges.Index) -> Vertex { base.target(ofEdgeAt: position) }

    /// The base's source of the edge.
    @inlinable
    public func target(ofEdgeAt position: Base.Edges.Index) -> Vertex { base.source(ofEdgeAt: position) }

    @inlinable public var vertexCount: Int { base.vertexCount }
    @inlinable public var edgeCount: Int { base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { base.contains(vertex) }

    /// Whether the base has the edge the other way.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        base.contains(edge: DirectedEdge(from: edge.target, to: edge.source))
    }

    @inlinable public func outDegree(of vertex: Vertex) -> Int { base.inDegree(of: vertex) }
    @inlinable public func inDegree(of vertex: Vertex) -> Int { base.outDegree(of: vertex) }
    @inlinable public func degree(of vertex: Vertex) -> Int { base.degree(of: vertex) }

    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { base.vertex(atIndex: index) }

    /// The base's `predecessorIndices(ofIndex:)`.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> Base.PredecessorIndices { base.predecessorIndices(ofIndex: index) }

    /// The base's `successorIndices(ofIndex:)`.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> Base.SuccessorIndices { base.successorIndices(ofIndex: index) }

    /// The base's `_forEachPredecessorIndex(ofIndex:_:)`.
    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        base._forEachPredecessorIndex(ofIndex: index, body)
    }

    /// The base's `_forEachSuccessorIndex(ofIndex:_:)`.
    @inlinable
    @inline(__always)
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        base._forEachSuccessorIndex(ofIndex: index, body)
    }

    @inlinable public func outEdges(ofIndex index: Int) -> Base.InEdges { base.inEdges(ofIndex: index) }
    @inlinable public func inEdges(ofIndex index: Int) -> Base.OutEdges { base.outEdges(ofIndex: index) }
    @inlinable public func outDegree(ofIndex index: Int) -> Int { base.inDegree(ofIndex: index) }
    @inlinable public func inDegree(ofIndex index: Int) -> Int { base.outDegree(ofIndex: index) }
    @inlinable public func sourceIndex(ofEdgeAt position: Base.Edges.Index) -> Int { base.targetIndex(ofEdgeAt: position) }
    @inlinable public func targetIndex(ofEdgeAt position: Base.Edges.Index) -> Int { base.sourceIndex(ofEdgeAt: position) }

    @inlinable public var edgeIndexBound: Int? { base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Base.Edges.Index) -> Int { base.edgeIndex(of: position) }

    /// `nil`: the base's flat rows are its out-rows, not the view's.
    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        nil
    }
}

extension ReverseView: Sendable where Base: Sendable {}
extension ReverseView.Edges: Sendable where Base.Edges: Sendable {}

extension ReverseView.Edges: BidirectionalCollection where Base.Edges: BidirectionalCollection {
    @inlinable public func index(before i: Base.Edges.Index) -> Base.Edges.Index { base.index(before: i) }
}

extension ReverseView.Edges: RandomAccessCollection where Base.Edges: RandomAccessCollection {
    @inlinable public func index(_ i: Base.Edges.Index, offsetBy distance: Int) -> Base.Edges.Index { base.index(i, offsetBy: distance) }
    @inlinable public func distance(from start: Base.Edges.Index, to end: Base.Edges.Index) -> Int { base.distance(from: start, to: end) }
}
