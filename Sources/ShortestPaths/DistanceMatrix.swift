import GraphProtocols
import Walks

/// All-pairs distances, from Floyd–Warshall: for each ordered pair of vertices, the distance of a
/// best path and the last edge on it, so `path(from:to:)` walks back from the target.
///
/// A matrix holds a copy of the graph, as `ShortestPathTree` does. O(n²) space: n² distances and
/// n² edge positions.
@frozen
public struct DistanceMatrix<G: DirectedGraph, Distance> {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    @usableFromInline let _count: Int
    /// Row-major; meaningful only where a path exists.
    @usableFromInline let _distance: [Distance]
    /// Row-major: the last edge of a best path from the row to the column; `_placeholder` on the
    /// diagonal and where no path exists.
    @usableFromInline let _lastEdge: [G.Edges.Index]
    @usableFromInline let _placeholder: G.Edges.Index

    @inlinable
    init(ids: _VertexIdentifiers<G>, count: Int, distance: [Distance], lastEdge: [G.Edges.Index], placeholder: G.Edges.Index) {
        _ids = ids
        _count = count
        _distance = distance
        _lastEdge = lastEdge
        _placeholder = placeholder
    }

    @inlinable
    func _index(of vertex: G.Vertex) -> Int {
        _ids.graph._index(of: vertex, _ids)
    }

    /// The distance of a best path from `source` to `target`, or `nil` when no path joins them. A
    /// vertex's distance to itself is the empty path's: zero, or `.one` over a semiring.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func distance(from source: G.Vertex, to target: G.Vertex) -> Distance? {
        let i = _index(of: source), j = _index(of: target)
        return distance(fromIndex: i, toIndex: j)
    }

    /// The distance between the vertices with indices `sourceIndex` and `targetIndex`, as
    /// `distance(from:to:)`. With vertex indices these are the graph's; otherwise positions in
    /// `vertices`.
    ///
    /// - Precondition: both indices are in `0..<vertexCount`.
    @inlinable
    public func distance(fromIndex sourceIndex: Int, toIndex targetIndex: Int) -> Distance? {
        precondition(sourceIndex >= 0 && sourceIndex < _count, "Index \(sourceIndex) is out of range 0..<\(_count)")
        precondition(targetIndex >= 0 && targetIndex < _count, "Index \(targetIndex) is out of range 0..<\(_count)")
        let k = sourceIndex * _count + targetIndex
        guard sourceIndex == targetIndex || _lastEdge[k] != _placeholder else { return nil }
        return _distance[k]
    }

    /// Whether a path joins `source` to `target`: always for a vertex and itself. As
    /// `distance(from:to:) != nil`, without reading the distance.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func hasPath(from source: G.Vertex, to target: G.Vertex) -> Bool {
        _hasPath(_index(of: source), _index(of: target))
    }

    @inlinable
    func _hasPath(_ i: Int, _ j: Int) -> Bool {
        i == j || _lastEdge[i * _count + j] != _placeholder
    }

    /// A best path from `source` to `target`, both included, with the edges it takes (which tell
    /// parallel edges apart): the trivial path `[source]` when they are equal, `nil` when no path
    /// joins them. O(length) edge lookups.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph.
    @inlinable
    public func path(from source: G.Vertex, to target: G.Vertex) -> Path<G.Vertex, G.Edges.Index>? {
        _path(_index(of: source), _index(of: target))
    }

    @inlinable
    func _path(_ i: Int, _ target: Int) -> Path<G.Vertex, G.Edges.Index>? {
        var j = target
        let row = i * _count
        guard i == j || _lastEdge[row + j] != _placeholder else { return nil }
        var vertices = [_ids.vertex(j)]
        var edges: [G.Edges.Index] = []
        while j != i {
            precondition(edges.count < _count, "A Floyd–Warshall path does not end")
            let e = _lastEdge[row + j]
            edges.append(e)
            j = _index(of: _ids.graph.source(ofEdgeAt: e))
            vertices.append(_ids.vertex(j))
        }
        vertices.reverse()
        edges.reverse()
        // Only strict improvements are kept, so a best path never repeats a vertex.
        return Path(_uncheckedVertices: vertices, edges: edges)
    }
}

// MARK: - checked: lookups

// `VertexNotFound` for a vertex that is not in the graph; `try?` gives an Optional. A nil the
// trapping spelling returns (no path) is still nil.

extension DistanceMatrix {
    /// `distance(from: source, to: target)`, throwing instead of trapping when either is not a
    /// vertex of the graph: nil still means no path joins them.
    ///
    /// - Throws: `VertexNotFound` when `source` or `target` is not a vertex of the graph.
    @inlinable
    public func distance(checkedFrom source: G.Vertex, to target: G.Vertex) throws(VertexNotFound) -> Distance? {
        let i = try _ids.graph._checkedIndex(of: source, _ids), j = try _ids.graph._checkedIndex(of: target, _ids)
        return distance(fromIndex: i, toIndex: j)
    }

    /// `hasPath(from: source, to: target)`, throwing instead of trapping when either is not a
    /// vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `source` or `target` is not a vertex of the graph.
    @inlinable
    public func hasPath(checkedFrom source: G.Vertex, to target: G.Vertex) throws(VertexNotFound) -> Bool {
        let i = try _ids.graph._checkedIndex(of: source, _ids), j = try _ids.graph._checkedIndex(of: target, _ids)
        return _hasPath(i, j)
    }

    /// `path(from: source, to: target)`, throwing instead of trapping when either is not a vertex
    /// of the graph: nil still means no path joins them. O(length) edge lookups.
    ///
    /// - Throws: `VertexNotFound` when `source` or `target` is not a vertex of the graph.
    @inlinable
    public func path(checkedFrom source: G.Vertex, to target: G.Vertex) throws(VertexNotFound) -> Path<G.Vertex, G.Edges.Index>? {
        let i = try _ids.graph._checkedIndex(of: source, _ids), j = try _ids.graph._checkedIndex(of: target, _ids)
        return _path(i, j)
    }
}

extension DistanceMatrix: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Distance: Sendable {}
