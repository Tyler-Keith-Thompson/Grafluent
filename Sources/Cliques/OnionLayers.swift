import GraphProtocols

/// The onion decomposition's layers (Hébert-Dufresne, Grochow and Allard), by vertex number:
/// isolated vertices form layer 1; then each round takes the current core, raised to the least
/// remaining degree when that exceeds it, removes at once every remaining vertex of degree at most
/// the core, and makes them the next layer. The vertices a round leaves at degree exactly the
/// core are the next round's; when there are none, the least degree is found by a pointer over
/// lazy degree buckets that never moves back. O(n + m).
@inlinable
func _onionLayers(_ rows: _CompressedRows) -> [Int] {
    let n = rows.count
    guard n > 0 else { return [] }
    var degree = (0 ..< n).map { rows.degree($0) }
    let maxDegree = degree.max()!
    var layer = [Int](repeating: 0, count: n)
    var buckets = [[Int]](repeating: [], count: maxDegree + 1)
    var current: [Int] = [], next: [Int] = []
    var core = 1, number = 1, remaining = n
    for v in 0 ..< n where degree[v] == 0 {
        layer[v] = 1
        remaining -= 1
    }
    if remaining < n { number = 2 }
    for v in 0 ..< n where degree[v] > 0 {
        if degree[v] <= core { current.append(v) } else { buckets[degree[v]].append(v) }
    }
    var pointer = core + 1
    while remaining > 0 {
        if current.isEmpty {
            // No vertex is at or below the core: raise it to the least remaining degree.
            while true {
                while let v = buckets[pointer].last, layer[v] != 0 || degree[v] != pointer { buckets[pointer].removeLast() }
                if !buckets[pointer].isEmpty { break }
                pointer += 1
            }
            core = pointer
            for v in buckets[pointer] where layer[v] == 0 && degree[v] == pointer { current.append(v) }
            buckets[pointer].removeAll()
            pointer += 1
        }
        for v in current { layer[v] = number }
        remaining -= current.count
        for v in current {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[k]
                guard layer[w] == 0 else { continue }
                degree[w] -= 1
                if degree[w] == core {
                    next.append(w)
                } else if degree[w] > core {
                    buckets[degree[w]].append(w)
                }
            }
        }
        swap(&current, &next)
        next.removeAll(keepingCapacity: true)
        number += 1
    }
    return layer
}

/// The onion decomposition of an undirected graph's simple graph: each vertex's layer, a
/// refinement of the core decomposition in which every layer lies inside one k-shell. Layers are
/// numbered from 1; isolated vertices, when there are any, are layer 1 alone.
@frozen
public struct OnionLayers<G: Graph> {
    @usableFromInline let _graph: G
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _layers: [Int]
    @usableFromInline let _layerCount: Int

    @inlinable
    init(_ graph: G) {
        _graph = graph
        _numbers = graph._listedVertices().map { _vertexNumbers($0) }
        _layers = _onionLayers(graph._simpleRows())
        _layerCount = _layers.max() ?? 0
    }

    /// The layer of `vertex`. O(1) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func layer(of vertex: G.Vertex) -> Int { _layers[_graph._vertexNumber(of: vertex, _numbers, "The vertex is not in the graph")] }

    /// The layer of `vertex`, throwing instead of trapping when it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func layer(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return layer(of: vertex)
    }

    /// The layer of the vertex at `index` (its vertex index, or its position in `vertices` when
    /// the graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func layer(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < _layers.count, "Vertex index out of range")
        return _layers[index]
    }

    /// The number of layers, which is the greatest layer; 0 for the empty graph. O(1).
    @inlinable
    public var layerCount: Int { _layerCount }
}

extension OnionLayers: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// The onion decomposition of the simple graph underlying this one (self-loops ignored,
    /// parallel edges counted once). O(n + m).
    @inlinable
    public func onionLayers() -> OnionLayers<Self> { OnionLayers(self) }
}
