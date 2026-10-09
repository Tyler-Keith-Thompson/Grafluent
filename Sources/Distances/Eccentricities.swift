import GraphProtocols

/// Every vertex's eccentricity, computed once (Boost's `all_eccentricities`), with the measures
/// that follow from them: the radius (the least), the diameter (the greatest), the center and
/// the periphery (the vertices that attain them). An eccentricity is `nil`, standing for
/// infinity, when some vertex is not reachable from the vertex; so the diameter is `nil` exactly
/// when the graph is not connected (or not strongly connected), and the radius when no vertex
/// reaches every vertex.
@frozen
public struct Eccentricities<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: G
    /// Without vertex indices: each vertex's position in `vertices`.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _listed: [G.Vertex]?
    @usableFromInline let _values: [Distance?]
    @usableFromInline let _radius: Distance?
    @usableFromInline let _diameter: Distance?

    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, values: [Distance?]) {
        _graph = graph
        _listed = listed
        if let listed {
            var numbers: [G.Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            _numbers = numbers
        } else {
            _numbers = nil
        }
        _values = values
        (_radius, _diameter) = _radiusAndDiameter(values)
    }

    @inlinable
    func _vertex(_ v: Int) -> G.Vertex { _listed?[v] ?? _graph.vertex(atIndex: v) }

    /// The greatest distance from `vertex` to another vertex; nil when some vertex is not
    /// reachable from it. O(1) after looking the vertex up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func eccentricity(of vertex: G.Vertex) -> Distance? {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return _values[v]
        }
        precondition(_graph.contains(vertex), "The vertex is not in the graph")
        return _values[_graph.vertexIndex(of: vertex)]
    }

    /// The eccentricity of the vertex at `index` (its vertex index, or its position in `vertices`
    /// when the graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func eccentricity(ofIndex index: Int) -> Distance? {
        precondition(index >= 0 && index < _values.count, "Vertex index out of range")
        return _values[index]
    }

    /// The least eccentricity; nil when every vertex has an unreachable one, or there is no vertex.
    @inlinable
    public var radius: Distance? { _radius }

    /// The greatest eccentricity; nil when some vertex has an unreachable one, or there is no
    /// vertex.
    @inlinable
    public var diameter: Distance? { _diameter }

    /// The vertices whose eccentricity is the radius (nil equal to nil), in `vertices` order. O(n).
    @inlinable
    public var center: [G.Vertex] { _matching(_values, _radius).map(_vertex) }

    /// The vertices whose eccentricity is the diameter (nil equal to nil), in `vertices` order.
    /// O(n).
    @inlinable
    public var periphery: [G.Vertex] { _matching(_values, _diameter).map(_vertex) }
}

extension Eccentricities: Sendable where G: Sendable, G.Vertex: Sendable, Distance: Sendable {}
