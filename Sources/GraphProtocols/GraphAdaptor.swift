/// A type that wraps a base graph and passes its positions through.
///
/// Views (a transposed view, a subgraph view, a directed or undirected view) and wrappers that add
/// rules (a multigraph, an acyclic graph) are adaptors. Every adaptor gets two things:
///
/// - Its `generation` is the base's, so a structure derived from the adaptor is current exactly
///   when one derived from the base would be, and a generation read from either is current for
///   both, although they may describe different graphs.
/// - When the base is a `PropertyGraph`, `values(of:)` and `[map, of: vertex]` read the base's
///   vertex maps. When the adaptor's edge positions are the base's
///   (`Edges.Index == Base.EdgePosition`), `[map, ofEdgeAt: position]` and `values(of:)` read the
///   base's edge maps too. A view whose positions are not the base's, such as a complement, has no
///   edge-map reads. These members are read-only. A `GraphDelegator` writes maps through members
///   of its own.
///
/// A view whose vertices are a subset of its base's should declare its own `[map, of: vertex]`
/// that traps on a vertex outside the view. The default reads the base's value.
///
/// Nothing else is forwarded. A view's graph members are its own, or the protocol defaults over
/// its own members. `GraphDelegator` forwards every read member to the base, and only a wrapper
/// that keeps the base's adjacency conforms to it. For a view such as a transposed one, the base's
/// members would describe the wrong graph.
public protocol GraphAdaptor<Base> {
    associatedtype Base
    /// The graph this one wraps.
    var base: Base { get }
}

/// A wrapper that owns its base, keeps the base's vertices, edges and positions, and adds only
/// rules.
///
/// Every read requirement of `Graph`, `DirectedGraph`, `BidirectionalDirectedGraph`,
/// `SparselyIndexedDirectedGraph` and `PropertyGraph` has a default that forwards to the base.
/// The defaults are `@inlinable` and use the base's own types, so algorithms run at the base's
/// speed and data kept by position stays valid through the wrapper. The wrapper implements every
/// mutation itself, since that is where its rules apply, along with its other members.
///
/// A conformer declares its associated types as the base's (`typealias Successors =
/// Base.Successors`, and so on) and its conformances (`DirectedGraph`, `PropertyGraph`, …), and
/// writes no forwarding bodies for reads. The defaults read the base through `base`, which is
/// read-only, because the base carries the wrapper's invariant. A `PropertyGraph` conformer also
/// writes the members that change its base: `addVertexMap(default:)`, `addEdgeMap(default:)`,
/// `removeVertexMap(_:)`, `removeEdgeMap(_:)` and the settable subscripts `[map, ofVertexAt:]`,
/// `[map, of:]` and `[map, ofEdgeAt:]`, each forwarding to its own stored base, so the base's
/// mutations keep the maps in step.
public protocol GraphDelegator<Base>: GraphAdaptor {}

// MARK: - Generation

extension GraphAdaptor where Self: DirectedGraph, Base: DirectedGraph {
    /// The base's generation.
    @inlinable
    public var generation: GraphGeneration { base.generation }
}

extension GraphAdaptor where Self: DirectedGraph, Base: Graph {
    /// The base's generation.
    @inlinable
    public var generation: GraphGeneration { base.generation }
}

extension GraphAdaptor where Self: Graph, Base: Graph {
    /// The base's generation.
    @inlinable
    public var generation: GraphGeneration { base.generation }
}

extension GraphAdaptor where Self: Graph, Base: DirectedGraph {
    /// The base's generation.
    @inlinable
    public var generation: GraphGeneration { base.generation }
}

// MARK: - Reading attached maps through an adaptor

extension GraphAdaptor where Base: PropertyGraph {
    /// The base's values of `map`, by the base's vertex positions. O(1).
    ///
    /// - Precondition: `map` is attached to the base.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Base, Value> {
        base.values(of: map)
    }

    /// The base's value of `vertex` in `map`. One hash.
    ///
    /// - Precondition: `map` is attached to the base and `vertex` is a vertex of the base.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, of vertex: Base.Vertex) -> Value {
        base[map, of: vertex]
    }

    /// The base's value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a
    /// vertex of the base.
    ///
    /// - Precondition: `map` is attached to the base.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, checked vertex: Base.Vertex) -> Value {
        get throws(VertexNotFound) { try base[map, checked: vertex] }
    }
}

extension GraphAdaptor where Base: PropertyGraph, Self: DirectedGraph, Edges.Index == Base.EdgePosition {
    /// The base's values of `map`, by edge position, which are the base's. O(1).
    ///
    /// - Precondition: `map` is attached to the base.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Base, Value> {
        base.values(of: map)
    }

    /// The base's value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to the base and an edge is at `position`.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Edges.Index) -> Value {
        base[map, ofEdgeAt: position]
    }

    /// The base's value of the edge at `position` in `map`, throwing instead of trapping when no
    /// edge is there.
    ///
    /// - Precondition: `map` is attached to the base.
    /// - Throws: `EdgeNotFound` when no edge is at `position`.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: Edges.Index) -> Value {
        get throws(EdgeNotFound) { try base[map, checkedEdgeAt: position] }
    }
}

extension GraphAdaptor where Base: PropertyGraph, Self: Graph, Edges.Index == Base.EdgePosition {
    /// The base's values of `map`, by edge position, which are the base's. O(1).
    ///
    /// - Precondition: `map` is attached to the base.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Base, Value> {
        base.values(of: map)
    }

    /// The base's value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to the base and an edge is at `position`.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Edges.Index) -> Value {
        base[map, ofEdgeAt: position]
    }

    /// The base's value of the edge at `position` in `map`, throwing instead of trapping when no
    /// edge is there.
    ///
    /// - Precondition: `map` is attached to the base.
    /// - Throws: `EdgeNotFound` when no edge is at `position`.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: Edges.Index) -> Value {
        get throws(EdgeNotFound) { try base[map, checkedEdgeAt: position] }
    }
}

// MARK: - Forwarding: DirectedGraph

// Each extension requires every associated type to be the base's, which makes it more specialized
// than the protocols' own defaults, so Swift picks its members as the witnesses. Where a protocol
// default is itself conditional (`SuccessorIndices == LazyMapSequence<…>`, `Successors:
// Collection`), neither would be more specialized than the other for a base that meets the
// condition, so a second extension with both constraints breaks the tie.

extension GraphDelegator
where Self: DirectedGraph, Base: DirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices {
    /// The base's vertices, in the base's order. O(1).
    @inlinable public var vertices: Vertices { base.vertices }
    /// The base's edges, at the base's positions. O(1).
    @inlinable public var edges: Edges { base.edges }
    @inlinable public func successors(of vertex: Vertex) -> Successors { base.successors(of: vertex) }
    @inlinable public func outEdges(of vertex: Vertex) -> OutEdges { base.outEdges(of: vertex) }
    @inlinable public func source(ofEdgeAt position: Edges.Index) -> Vertex { base.source(ofEdgeAt: position) }
    @inlinable public func target(ofEdgeAt position: Edges.Index) -> Vertex { base.target(ofEdgeAt: position) }
    @inlinable public var vertexCount: Int { base.vertexCount }
    @inlinable public var edgeCount: Int { base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { base.contains(vertex) }
    @inlinable public func contains(edge: DirectedEdge<Vertex>) -> Bool { base.contains(edge: edge) }
    @inlinable public func outDegree(of vertex: Vertex) -> Int { base.outDegree(of: vertex) }
    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { base.vertex(atIndex: index) }
    @inlinable public func successorIndices(ofIndex index: Int) -> SuccessorIndices { base.successorIndices(ofIndex: index) }
    @inlinable public func outEdges(ofIndex index: Int) -> OutEdges { base.outEdges(ofIndex: index) }
    @inlinable public func outDegree(ofIndex index: Int) -> Int { base.outDegree(ofIndex: index) }
    @inlinable public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) { base._forEachSuccessorIndex(ofIndex: index, body) }
    @inlinable public func sourceIndex(ofEdgeAt position: Edges.Index) -> Int { base.sourceIndex(ofEdgeAt: position) }
    @inlinable public func targetIndex(ofEdgeAt position: Edges.Index) -> Int { base.targetIndex(ofEdgeAt: position) }
    @inlinable public var edgeIndexBound: Int? { base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Edges.Index) -> Int { base.edgeIndex(of: position) }

    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        base._withSuccessorIndexRows(body)
    }

    @inlinable
    public func _withOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        base._withOutIndexRows(body)
    }
}

extension GraphDelegator
where Self: DirectedGraph, Base: DirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices,
    SuccessorIndices == LazyMapSequence<Successors, Int> {
    @inlinable public func successorIndices(ofIndex index: Int) -> SuccessorIndices { base.successorIndices(ofIndex: index) }
}

extension GraphDelegator
where Self: DirectedGraph, Base: DirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices, Successors: Collection {
    @inlinable public func outDegree(of vertex: Vertex) -> Int { base.outDegree(of: vertex) }
}

// MARK: - Forwarding: BidirectionalDirectedGraph

extension GraphDelegator
where Self: BidirectionalDirectedGraph, Base: BidirectionalDirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices,
    Edges == Base.Edges, Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices,
    Predecessors == Base.Predecessors, InEdges == Base.InEdges, PredecessorIndices == Base.PredecessorIndices {
    @inlinable public func predecessors(of vertex: Vertex) -> Predecessors { base.predecessors(of: vertex) }
    @inlinable public func inEdges(of vertex: Vertex) -> InEdges { base.inEdges(of: vertex) }
    @inlinable public func inDegree(of vertex: Vertex) -> Int { base.inDegree(of: vertex) }
    @inlinable public func degree(of vertex: Vertex) -> Int { base.degree(of: vertex) }
    @inlinable public func inDegree(ofIndex index: Int) -> Int { base.inDegree(ofIndex: index) }
    @inlinable public func predecessorIndices(ofIndex index: Int) -> PredecessorIndices { base.predecessorIndices(ofIndex: index) }
    @inlinable public func inEdges(ofIndex index: Int) -> InEdges { base.inEdges(ofIndex: index) }
    @inlinable public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) { base._forEachPredecessorIndex(ofIndex: index, body) }
}

extension GraphDelegator
where Self: BidirectionalDirectedGraph, Base: BidirectionalDirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices,
    Edges == Base.Edges, Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices,
    Predecessors == Base.Predecessors, InEdges == Base.InEdges, PredecessorIndices == Base.PredecessorIndices,
    PredecessorIndices == LazyMapSequence<Predecessors, Int> {
    @inlinable public func predecessorIndices(ofIndex index: Int) -> PredecessorIndices { base.predecessorIndices(ofIndex: index) }
}

extension GraphDelegator
where Self: BidirectionalDirectedGraph, Base: BidirectionalDirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices,
    Edges == Base.Edges, Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices,
    Predecessors == Base.Predecessors, InEdges == Base.InEdges, PredecessorIndices == Base.PredecessorIndices,
    Predecessors: Collection {
    @inlinable public func inDegree(of vertex: Vertex) -> Int { base.inDegree(of: vertex) }
}

// MARK: - Forwarding: SparselyIndexedDirectedGraph

extension GraphDelegator
where Self: SparselyIndexedDirectedGraph, Base: SparselyIndexedDirectedGraph, Vertex == Base.Vertex, Vertices == Base.Vertices,
    Edges == Base.Edges, Successors == Base.Successors, OutEdges == Base.OutEdges, SuccessorIndices == Base.SuccessorIndices,
    Predecessors == Base.Predecessors, InEdges == Base.InEdges, PredecessorIndices == Base.PredecessorIndices {
    @inlinable public var vertexPositionBound: Int { base.vertexPositionBound }
    @inlinable public var edgePositionBound: Int { base.edgePositionBound }
    @inlinable public func vertexPosition(of vertex: Vertex) -> Int { base.vertexPosition(of: vertex) }
    @inlinable public func vertex(atPosition position: Int) -> Vertex { base.vertex(atPosition: position) }
    @inlinable public func containsVertex(atPosition position: Int) -> Bool { base.containsVertex(atPosition: position) }
    @inlinable public func containsEdge(atPosition position: Int) -> Bool { base.containsEdge(atPosition: position) }
    @inlinable public func _numberedRows(outward: Bool, edges withEdges: Bool) -> _NumberedRows {
        base._numberedRows(outward: outward, edges: withEdges)
    }
}

// MARK: - Forwarding: Graph

extension GraphDelegator
where Self: Graph, Base: Graph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Neighbors == Base.Neighbors, IncidentEdges == Base.IncidentEdges, NeighborIndices == Base.NeighborIndices,
    IncidentEdgeIndices == Base.IncidentEdgeIndices {
    /// The base's vertices, in the base's order. O(1).
    @inlinable public var vertices: Vertices { base.vertices }
    /// The base's edges, at the base's positions. O(1).
    @inlinable public var edges: Edges { base.edges }
    @inlinable public func neighbors(of vertex: Vertex) -> Neighbors { base.neighbors(of: vertex) }
    @inlinable public func incidentEdges(of vertex: Vertex) -> IncidentEdges { base.incidentEdges(of: vertex) }
    @inlinable public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Edges.Index) -> Vertex {
        base.oppositeVertex(to: vertex, acrossEdgeAt: position)
    }
    @inlinable public var vertexCount: Int { base.vertexCount }
    @inlinable public var edgeCount: Int { base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { base.contains(vertex) }
    @inlinable public func contains(edge: UndirectedEdge<Vertex>) -> Bool { base.contains(edge: edge) }
    @inlinable public func degree(of vertex: Vertex) -> Int { base.degree(of: vertex) }
    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { base.vertex(atIndex: index) }
    @inlinable public func neighborIndices(ofIndex index: Int) -> NeighborIndices { base.neighborIndices(ofIndex: index) }
    @inlinable public var edgeIndexBound: Int? { base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Edges.Index) -> Int { base.edgeIndex(of: position) }
    @inlinable public func incidentEdgeIndices(ofIndex index: Int) -> IncidentEdgeIndices { base.incidentEdgeIndices(ofIndex: index) }
    @inlinable public func incidentEdges(ofIndex index: Int) -> IncidentEdges { base.incidentEdges(ofIndex: index) }
    @inlinable public func degree(ofIndex index: Int) -> Int { base.degree(ofIndex: index) }
    @inlinable public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) { base._forEachNeighborIndex(ofIndex: index, body) }
    @inlinable public func endpointIndices(ofEdgeAt position: Edges.Index) -> (u: Int, v: Int) { base.endpointIndices(ofEdgeAt: position) }

    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        base._withIncidentIndexRows(body)
    }

    /// The base's: the rows are the base's.
    @inlinable public static var _lendsIncidentRowsInConstantTime: Bool { Base._lendsIncidentRowsInConstantTime }
}

extension GraphDelegator
where Self: Graph, Base: Graph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Neighbors == Base.Neighbors, IncidentEdges == Base.IncidentEdges, NeighborIndices == Base.NeighborIndices,
    IncidentEdgeIndices == Base.IncidentEdgeIndices, NeighborIndices == LazyMapSequence<Neighbors, Int> {
    @inlinable public func neighborIndices(ofIndex index: Int) -> NeighborIndices { base.neighborIndices(ofIndex: index) }
}

extension GraphDelegator
where Self: Graph, Base: Graph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Neighbors == Base.Neighbors, IncidentEdges == Base.IncidentEdges, NeighborIndices == Base.NeighborIndices,
    IncidentEdgeIndices == Base.IncidentEdgeIndices, IncidentEdgeIndices == LazyMapSequence<IncidentEdges, Int> {
    @inlinable public func incidentEdgeIndices(ofIndex index: Int) -> IncidentEdgeIndices { base.incidentEdgeIndices(ofIndex: index) }
}

extension GraphDelegator
where Self: Graph, Base: Graph, Vertex == Base.Vertex, Vertices == Base.Vertices, Edges == Base.Edges,
    Neighbors == Base.Neighbors, IncidentEdges == Base.IncidentEdges, NeighborIndices == Base.NeighborIndices,
    IncidentEdgeIndices == Base.IncidentEdgeIndices, Neighbors: Collection {
    @inlinable public func degree(of vertex: Vertex) -> Int { base.degree(of: vertex) }
}

// MARK: - Forwarding: PropertyGraph

// The read members. The members that change the base (attaching, detaching and writing maps) are
// the conformer's own, over its stored base.

extension GraphDelegator where Self: PropertyGraph, Base: PropertyGraph, Vertex == Base.Vertex, EdgePosition == Base.EdgePosition {
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) { try base[map, checkedVertexAt: position] }
    }

    @inlinable
    public subscript<Value>(map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) { try base[map, checked: vertex] }
    }

    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: EdgePosition) -> Value {
        get throws(EdgeNotFound) { try base[map, checkedEdgeAt: position] }
    }

    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(base.values(of: map))
    }

    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(base.values(of: map))
    }

    @inlinable public static var _vertexMapLayout: _MapLayout { Base._vertexMapLayout }
    @inlinable public static var _edgeMapLayout: _MapLayout { Base._edgeMapLayout }
    @inlinable public static func _edgeMapOffset(of position: EdgePosition) -> Int { Base._edgeMapOffset(of: position) }
    @inlinable public var _vertexMapCount: Int { base._vertexMapCount }
    @inlinable public var _edgeMapCount: Int { base._edgeMapCount }
}

extension GraphDelegator
where Self: PropertyGraph, Base: PropertyGraph, Vertex == Base.Vertex, EdgePosition == Base.EdgePosition, EdgePosition == Int {
    @inlinable public static func _edgeMapOffset(of position: Int) -> Int { Base._edgeMapOffset(of: position) }
}

// A delegator whose edge positions are its base's meets both the adaptor's edge-map members and
// its own, and neither extension is more specialized than the other; these, with both sets of
// constraints, are the ones called.

extension GraphDelegator
where Self: PropertyGraph, Self: DirectedGraph, Base: PropertyGraph, Vertex == Base.Vertex, EdgePosition == Base.EdgePosition,
    Edges.Index == Base.EdgePosition {
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: EdgePosition) -> Value {
        get throws(EdgeNotFound) { try base[map, checkedEdgeAt: position] }
    }

    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(base.values(of: map))
    }
}

extension GraphDelegator
where Self: PropertyGraph, Self: Graph, Base: PropertyGraph, Vertex == Base.Vertex, EdgePosition == Base.EdgePosition,
    Edges.Index == Base.EdgePosition {
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: EdgePosition) -> Value {
        get throws(EdgeNotFound) { try base[map, checkedEdgeAt: position] }
    }

    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(base.values(of: map))
    }
}
