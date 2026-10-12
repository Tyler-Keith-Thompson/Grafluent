// The `checked:` lookups for every conformer that has none of its own: the views (a transposed or
// complement view, a subgraph view, a product, an incidence graph view) and any other generic
// wrapper. Each checks `contains(_:)` once, then calls the trapping spelling, so the trapping
// spelling stays the fast path and is not touched.
//
// These are protocol-extension members, not requirements. A representation that declares its
// own `successors(checked:)` (one hash rather than this `contains` plus the lookup) is still the
// one called on that concrete type, because Swift prefers a member of the type over a member of a
// protocol extension. Generic code over `some DirectedGraph` calls these.

extension DirectedGraph {
    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `successors(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Successors {
        guard contains(vertex) else { throw VertexNotFound() }
        return successors(of: vertex)
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The cost
    /// of `contains(_:)` plus that of `outEdges(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> OutEdges {
        guard contains(vertex) else { throw VertexNotFound() }
        return outEdges(of: vertex)
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `outDegree(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return outDegree(of: vertex)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil` (when `vertex` is a vertex).
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertexIndex(of: vertex)
    }
}

extension BidirectionalDirectedGraph {
    /// `predecessors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `predecessors(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Predecessors {
        guard contains(vertex) else { throw VertexNotFound() }
        return predecessors(of: vertex)
    }

    /// `inEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The cost
    /// of `contains(_:)` plus that of `inEdges(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> InEdges {
        guard contains(vertex) else { throw VertexNotFound() }
        return inEdges(of: vertex)
    }

    /// `inDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The cost
    /// of `contains(_:)` plus that of `inDegree(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return inDegree(of: vertex)
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The cost
    /// of `contains(_:)` plus that of `degree(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return degree(of: vertex)
    }
}

extension Graph {
    /// `neighbors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `neighbors(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func neighbors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard contains(vertex) else { throw VertexNotFound() }
        return neighbors(of: vertex)
    }

    /// `incidentEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `incidentEdges(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func incidentEdges(checked vertex: Vertex) throws(VertexNotFound) -> IncidentEdges {
        guard contains(vertex) else { throw VertexNotFound() }
        return incidentEdges(of: vertex)
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The cost
    /// of `contains(_:)` plus that of `degree(of:)`.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return degree(of: vertex)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. The
    /// cost of `contains(_:)` plus that of `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil` (when `vertex` is a vertex).
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertexIndex(of: vertex)
    }
}
