import GraphProtocols

/// The renumbering of an ego graph: the vertices within `radius` steps of `center` over `first`
/// and `second` rows, kept in base index order. Both arrays are empty when every vertex is kept,
/// as `_renumbering` gives them. O(n + the rows walked).
@inlinable
func _egoRenumbering<A: Sequence<Int>, B: Sequence<Int>>(
    count n: Int, center: Int, radius: Int, first: (Int) -> A, second: ((Int) -> B)?
) -> (old: [Int], new: [Int], count: Int) {
    precondition(radius >= 0, "The radius must not be negative")
    var new = [Int](repeating: -1, count: n)
    // The queue grows with the vertices found, so a small ego graph of a large graph costs no
    // O(n) queue on top of the renumbering array.
    var queue = [center]
    new[center] = 0
    var head = 0, tail = 1, depth = 0
    while depth < radius && head < tail {
        let end = tail
        while head < end {
            let v = queue[head]
            head &+= 1
            for w in first(v) where new[w] < 0 {
                new[w] = 0
                queue.append(w)
                tail &+= 1
            }
            if let second {
                for w in second(v) where new[w] < 0 {
                    new[w] = 0
                    queue.append(w)
                    tail &+= 1
                }
            }
        }
        depth &+= 1
    }
    if tail == n { return ([], [], n) }
    var old = [Int]()
    old.reserveCapacity(tail)
    for b in 0 ..< n where new[b] >= 0 {
        new[b] = old.count
        old.append(b)
    }
    return (old, new, tail)
}

/// The vertex count of a base that a subgraph view reads in index space.
@inlinable
func _viewBound(_ bound: Int?) -> Int {
    guard let n = bound else {
        preconditionFailure("The base has no vertex indices (vertexIndexBound is nil); a subgraph view needs them")
    }
    return n
}

extension DirectedGraph {
    /// The ego graph of `center`: the subgraph induced on the vertices that a directed path of at
    /// most `radius` arcs reaches from `center`, `center` included, as a lazy view. It is the
    /// `inducedSubgraphView(on:)` of those vertices, numbered and positioned as there.
    ///
    /// - Parameters:
    ///   - center: The vertex the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps `center` alone.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search stopped after `radius` layers,
    ///   with one hash for `center`.
    /// - Precondition: `center` is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of center: Vertex, radius: Int = 1) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: _requiredVertexIndex(of: center, "\(center) is not a vertex of the graph"), radius: radius)
    }

    /// `egoGraphView(of:radius:)`, throwing instead of trapping when `center` is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `center` is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: try vertexIndex(checked: center), radius: radius)
    }

    @inlinable
    func _egoGraphView(count n: Int, center: Int, radius: Int) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, center: center, radius: radius, first: { successorIndices(ofIndex: $0) },
            second: nil as ((Int) -> EmptyCollection<Int>)?)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
}

extension BidirectionalDirectedGraph {
    /// The ego graph of `center`, with distances measured along arcs in either direction when
    /// `undirected` is true, as on the underlying undirected graph. The view is the induced
    /// subgraph of this directed graph on those vertices, as `egoGraphView(of:radius:)` gives it.
    ///
    /// - Parameters:
    ///   - center: The vertex the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps `center` alone.
    ///   - undirected: Whether a step may follow an arc backwards.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), with one hash for `center`.
    /// - Precondition: `center` is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of center: Vertex, radius: Int = 1, undirected: Bool) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: _requiredVertexIndex(of: center, "\(center) is not a vertex of the graph"), radius: radius, undirected: undirected)
    }

    /// `egoGraphView(of:radius:undirected:)`, throwing instead of trapping when `center` is not a
    /// vertex.
    ///
    /// - Throws: `VertexNotFound` when `center` is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1, undirected: Bool) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: try vertexIndex(checked: center), radius: radius, undirected: undirected)
    }

    @inlinable
    func _egoGraphView(count n: Int, center: Int, radius: Int, undirected: Bool) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, center: center, radius: radius, first: { successorIndices(ofIndex: $0) },
            second: undirected ? { predecessorIndices(ofIndex: $0) } : nil)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
}

extension Graph {
    /// The ego graph of `center`: the subgraph induced on the vertices within distance `radius`
    /// of `center`, `center` included, as a lazy view. It is the `inducedSubgraphView(on:)` of
    /// those vertices, numbered and positioned as there.
    ///
    /// - Parameters:
    ///   - center: The vertex the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps `center` alone.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search stopped after `radius` layers,
    ///   with one hash for `center`.
    /// - Precondition: `center` is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of center: Vertex, radius: Int = 1) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: _requiredVertexIndex(of: center, "\(center) is not a vertex of the graph"), radius: radius)
    }

    /// `egoGraphView(of:radius:)`, throwing instead of trapping when `center` is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `center` is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: try vertexIndex(checked: center), radius: radius)
    }

    @inlinable
    func _egoGraphView(count n: Int, center: Int, radius: Int) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, center: center, radius: radius, first: { neighborIndices(ofIndex: $0) },
            second: nil as ((Int) -> EmptyCollection<Int>)?)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
}
