// Lazy views between the two kinds of graph: an undirected graph read as directed (each edge as
// two opposite arcs) and a bidirectional directed graph read as undirected (each arc as an edge).
// Both forward every requirement, so the base's own fast members are the ones called.

extension Graph {
    /// The graph as a directed graph with each edge as two opposite arcs, a self-loop included
    /// (NetworkX's directed view, LEMON's reading of a graph as a digraph). O(1); a value holding
    /// a copy of the graph.
    ///
    /// Arcs keep the edge's identity: the arc at `(position, reversed: false)` goes from
    /// `edges[position].u` to `.v`, and `reversed: true` the other way.
    @inlinable
    public var directed: DirectedView<Self> { DirectedView(base: self) }
}

extension BidirectionalDirectedGraph {
    /// The graph as an undirected graph with each arc as an edge, at the arc's own position, as
    /// JGraphT's `AsUndirectedGraph` reads a digraph. Two opposite arcs become two parallel edges
    /// (NetworkX's `to_undirected` would merge them into one, as converting to
    /// `UndirectedAdjacencyList` does), and a self-loop is a loop of degree 2. O(1); a value
    /// holding a copy of the graph.
    @inlinable
    public var undirected: UndirectedView<Self> { UndirectedView(base: self) }
}

// MARK: - DirectedView

/// An undirected graph read as a directed graph: each edge `{u, v}` is the two arcs `u→v` and
/// `v→u`, so `successors` and `predecessors` are both `neighbors`, and `edgeCount` is twice the
/// base's.
@frozen
public struct DirectedView<Base: Graph>: BidirectionalDirectedGraph {
    public typealias Vertex = Base.Vertex

    @usableFromInline let base: Base

    @inlinable
    init(base: Base) { self.base = base }

    /// The base's vertices.
    @inlinable
    public var vertices: Base.Vertices { base.vertices }

    /// Every edge of the base as two arcs, in the base's edge order: `u→v`, then `v→u`.
    @inlinable
    public var edges: Edges { Edges(base: base.edges) }

    /// The arcs of a `DirectedView`.
    @frozen
    public struct Edges: Collection {
        @usableFromInline let base: Base.Edges

        @inlinable
        init(base: Base.Edges) { self.base = base }

        /// An arc: an edge of the base, and whether the arc runs from its `v` to its `u`.
        @frozen
        public struct Index: Comparable, Hashable {
            /// The edge's position in the base.
            public let position: Base.Edges.Index
            /// Whether the arc goes from the edge's `v` to its `u`.
            public let reversed: Bool

            @inlinable
            public init(position: Base.Edges.Index, reversed: Bool) {
                self.position = position
                self.reversed = reversed
            }

            @inlinable
            public static func < (lhs: Index, rhs: Index) -> Bool {
                lhs.position < rhs.position || (lhs.position == rhs.position && !lhs.reversed && rhs.reversed)
            }
        }

        @inlinable public var startIndex: Index { Index(position: base.startIndex, reversed: false) }
        @inlinable public var endIndex: Index { Index(position: base.endIndex, reversed: false) }
        @inlinable public var count: Int { 2 * base.count }
        @inlinable public var isEmpty: Bool { base.isEmpty }

        @inlinable
        public func index(after i: Index) -> Index {
            i.reversed ? Index(position: base.index(after: i.position), reversed: false) : Index(position: i.position, reversed: true)
        }

        @inlinable
        public subscript(position: Index) -> DirectedEdge<Vertex> {
            let edge = base[position.position]
            return position.reversed ? DirectedEdge(from: edge.v, to: edge.u) : DirectedEdge(from: edge.u, to: edge.v)
        }
    }

    /// The arcs at a vertex, one per edge end, in the order of the base's `incidentEdges`: each
    /// arc leaving the vertex for `outEdges`, or entering it for `inEdges`. A self-loop's first
    /// end is its forward arc and its second the reversed one, so each arc is listed once.
    @frozen
    public struct Arcs: Sequence {
        @usableFromInline let edges: Base.Edges
        @usableFromInline let vertex: Vertex
        @usableFromInline let positions: Base.IncidentEdges
        /// Whether the arcs leave `vertex` (rather than enter it).
        @usableFromInline let leaving: Bool

        @inlinable
        init(base: Base, vertex: Vertex, positions: Base.IncidentEdges, leaving: Bool) {
            self.edges = base.edges
            self.vertex = vertex
            self.positions = positions
            self.leaving = leaving
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(edges: edges, vertex: vertex, positions: positions.makeIterator(), leaving: leaving)
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let edges: Base.Edges
            @usableFromInline let vertex: Vertex
            @usableFromInline var positions: Base.IncidentEdges.Iterator
            @usableFromInline let leaving: Bool
            /// The self-loops whose first end has been met: a vertex has few, so a scan beats
            /// hashing.
            @usableFromInline var loopsMet: [Base.Edges.Index] = []

            @inlinable
            init(edges: Base.Edges, vertex: Vertex, positions: Base.IncidentEdges.Iterator, leaving: Bool) {
                self.edges = edges
                self.vertex = vertex
                self.positions = positions
                self.leaving = leaving
            }

            @inlinable
            public mutating func next() -> Edges.Index? {
                guard let position = positions.next() else { return nil }
                let edge = edges[position]
                if edge.isSelfLoop {
                    if let k = loopsMet.firstIndex(of: position) {
                        loopsMet.remove(at: k)
                        return Edges.Index(position: position, reversed: true)
                    }
                    loopsMet.append(position)
                    return Edges.Index(position: position, reversed: false)
                }
                // Forward runs u→v: it leaves `vertex` when `vertex` is u.
                return Edges.Index(position: position, reversed: (edge.u == vertex) != leaving)
            }
        }
    }

    /// The base's `neighbors(of:)`.
    ///
    /// - Precondition: `vertex` is a vertex of the base.
    @inlinable
    public func successors(of vertex: Vertex) -> Base.Neighbors { base.neighbors(of: vertex) }

    /// The arc of each edge end at `vertex` that leaves it, in the order of `successors(of:)`.
    ///
    /// - Precondition: `vertex` is a vertex of the base.
    @inlinable
    public func outEdges(of vertex: Vertex) -> Arcs {
        Arcs(base: base, vertex: vertex, positions: base.incidentEdges(of: vertex), leaving: true)
    }

    /// The base's `neighbors(of:)`.
    ///
    /// - Precondition: `vertex` is a vertex of the base.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Base.Neighbors { base.neighbors(of: vertex) }

    /// The arc of each edge end at `vertex` that enters it, in the order of `predecessors(of:)`.
    ///
    /// - Precondition: `vertex` is a vertex of the base.
    @inlinable
    public func inEdges(of vertex: Vertex) -> Arcs {
        Arcs(base: base, vertex: vertex, positions: base.incidentEdges(of: vertex), leaving: false)
    }

    @inlinable
    public func source(ofEdgeAt position: Edges.Index) -> Vertex {
        let edge = base.edges[position.position]
        return position.reversed ? edge.v : edge.u
    }

    @inlinable
    public func target(ofEdgeAt position: Edges.Index) -> Vertex {
        let edge = base.edges[position.position]
        return position.reversed ? edge.u : edge.v
    }

    @inlinable public var vertexCount: Int { base.vertexCount }
    @inlinable public var edgeCount: Int { 2 * base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { base.contains(vertex) }

    /// Whether the base has the edge `{source, target}`.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        base.contains(edge: UndirectedEdge(edge.source, edge.target))
    }

    @inlinable public func outDegree(of vertex: Vertex) -> Int { base.degree(of: vertex) }
    @inlinable public func inDegree(of vertex: Vertex) -> Int { base.degree(of: vertex) }

    /// Twice the base's degree: every edge end is an arc out and an arc in.
    @inlinable public func degree(of vertex: Vertex) -> Int { 2 * base.degree(of: vertex) }

    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { base.vertex(atIndex: index) }

    /// The base's `neighborIndices(ofIndex:)`.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> Base.NeighborIndices { base.neighborIndices(ofIndex: index) }

    /// The base's `neighborIndices(ofIndex:)`.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> Base.NeighborIndices { base.neighborIndices(ofIndex: index) }
}

extension DirectedView: Sendable where Base: Sendable {}
extension DirectedView.Edges: Sendable where Base.Edges: Sendable {}
extension DirectedView.Edges.Index: Sendable where Base.Edges.Index: Sendable {}
extension DirectedView.Arcs: Sendable where Base.Edges: Sendable, Base.IncidentEdges: Sendable, Base.Vertex: Sendable {}
extension DirectedView.Arcs.Iterator: Sendable where Base.Edges: Sendable, Base.IncidentEdges.Iterator: Sendable, Base.Vertex: Sendable, Base.Edges.Index: Sendable {}

// MARK: - UndirectedView

/// A bidirectional directed graph read as an undirected graph: each arc `u→v` is the edge
/// `{u, v}` at the arc's position, so `neighbors` is `successors` then `predecessors`, and
/// `degree` is the base's. Two opposite arcs are two parallel edges.
@frozen
public struct UndirectedView<Base: BidirectionalDirectedGraph>: Graph {
    public typealias Vertex = Base.Vertex

    @usableFromInline let base: Base

    @inlinable
    init(base: Base) { self.base = base }

    /// The base's vertices.
    @inlinable
    public var vertices: Base.Vertices { base.vertices }

    /// The base's arcs as edges, in the base's order and at its positions.
    @inlinable
    public var edges: Edges { Edges(base: base.edges) }

    /// The edges of an `UndirectedView`: the base's arcs, at the base's positions.
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
        public subscript(position: Base.Edges.Index) -> UndirectedEdge<Vertex> {
            let arc = base[position]
            return UndirectedEdge(arc.source, arc.target)
        }
    }

    /// One sequence, then another (swift-algorithms' `chain`).
    @frozen
    public struct Chain<First: Sequence, Second: Sequence>: Sequence where First.Element == Second.Element {
        @usableFromInline let first: First
        @usableFromInline let second: Second

        @inlinable
        init(_ first: First, _ second: Second) {
            self.first = first
            self.second = second
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(first: first.makeIterator(), second: second.makeIterator())
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var first: First.Iterator
            @usableFromInline var second: Second.Iterator
            @usableFromInline var firstDone = false

            @inlinable
            init(first: First.Iterator, second: Second.Iterator) {
                self.first = first
                self.second = second
            }

            @inlinable
            public mutating func next() -> First.Element? {
                if !firstDone {
                    if let element = first.next() { return element }
                    firstDone = true
                }
                return second.next()
            }
        }
    }

    /// The base's successors, then its predecessors: a directed self-loop's vertex twice.
    ///
    /// - Precondition: `vertex` is a vertex of the base.
    @inlinable
    public func neighbors(of vertex: Vertex) -> Chain<Base.Successors, Base.Predecessors> {
        Chain(base.successors(of: vertex), base.predecessors(of: vertex))
    }

    /// The base's out-edges, then its in-edges, in the order of `neighbors(of:)`.
    ///
    /// - Precondition: `vertex` is a vertex of the base.
    @inlinable
    public func incidentEdges(of vertex: Vertex) -> Chain<Base.OutEdges, Base.InEdges> {
        Chain(base.outEdges(of: vertex), base.inEdges(of: vertex))
    }

    @inlinable
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Base.Edges.Index) -> Vertex {
        let source = base.source(ofEdgeAt: position)
        if vertex == source { return base.target(ofEdgeAt: position) }
        let target = base.target(ofEdgeAt: position)
        precondition(vertex == target, "\(vertex) is not an endpoint of the edge at \(position)")
        return source
    }

    @inlinable public var vertexCount: Int { base.vertexCount }
    @inlinable public var edgeCount: Int { base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { base.contains(vertex) }

    /// Whether the base has an arc between the endpoints, either way.
    @inlinable
    public func contains(edge: UndirectedEdge<Vertex>) -> Bool {
        base.contains(edge: DirectedEdge(from: edge.u, to: edge.v)) || base.contains(edge: DirectedEdge(from: edge.v, to: edge.u))
    }

    /// The base's `degree(of:)`, out-degree plus in-degree.
    @inlinable public func degree(of vertex: Vertex) -> Int { base.degree(of: vertex) }

    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { base.vertex(atIndex: index) }

    /// The base's successor indices, then its predecessor indices.
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> Chain<Base.SuccessorIndices, Base.PredecessorIndices> {
        Chain(base.successorIndices(ofIndex: index), base.predecessorIndices(ofIndex: index))
    }
}

extension UndirectedView: Sendable where Base: Sendable {}
extension UndirectedView.Edges: Sendable where Base.Edges: Sendable {}
extension UndirectedView.Chain: Sendable where First: Sendable, Second: Sendable {}
extension UndirectedView.Chain.Iterator: Sendable where First.Iterator: Sendable, Second.Iterator: Sendable {}
