import GraphProtocols

/// The core decomposition of an undirected graph (Batagelj–Zaversnik; NetworkX `core_number`,
/// igraph `coreness`, JGraphT `Coreness`), over its simple graph: a vertex's core number
/// is the largest k such that it lies in a subgraph where every vertex has at least k neighbors.
@frozen
public struct CoreNumbers<G: Graph> {
    @usableFromInline let _graph: G
    @usableFromInline let _listed: [G.Vertex]?
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _core: [Int]
    @usableFromInline let _order: [Int]
    @usableFromInline let _degeneracy: Int

    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, core: [Int], order: [Int]) {
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
        _core = core
        _order = order
        _degeneracy = core.max() ?? 0
    }

    @inlinable
    func _index(of vertex: G.Vertex) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return v
        }
        precondition(_graph.contains(vertex), "The vertex is not in the graph")
        return _graph.vertexIndex(of: vertex)
    }

    /// The core number of `vertex`. O(1) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func coreNumber(of vertex: G.Vertex) -> Int { _core[_index(of: vertex)] }

    /// The core number of the vertex at `index` (its vertex index, or its position in `vertices`
    /// when the graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func coreNumber(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < _core.count, "Vertex index out of range")
        return _core[index]
    }

    /// The greatest core number; 0 for the empty graph. O(1).
    @inlinable
    public var degeneracy: Int { _degeneracy }

    /// Every vertex once, in Batagelj–Zaversnik's removal order: each has at most `degeneracy`
    /// neighbors after it, and core numbers never decrease along it. O(n).
    @inlinable
    public var degeneracyOrdering: [G.Vertex] { _order.map { _graph._vertex(number: $0, _listed) } }

    /// The vertices of the k-core (core number at least k), in `vertices` order. O(n).
    ///
    /// - Precondition: `k >= 0`.
    @inlinable
    public func kCore(_ k: Int) -> [G.Vertex] {
        precondition(k >= 0, "k must be nonnegative")
        return _core.indices.filter { _core[$0] >= k }.map { _graph._vertex(number: $0, _listed) }
    }

    /// The vertices of core number exactly k, in `vertices` order. O(n).
    ///
    /// - Precondition: `k >= 0`.
    @inlinable
    public func kShell(_ k: Int) -> [G.Vertex] {
        precondition(k >= 0, "k must be nonnegative")
        return _core.indices.filter { _core[$0] == k }.map { _graph._vertex(number: $0, _listed) }
    }
}

extension CoreNumbers: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// The core decomposition of the simple graph underlying this one (self-loops ignored,
    /// parallel edges counted once), by Batagelj–Zaversnik's bucket algorithm. O(n + m).
    @inlinable
    public func coreNumbers() -> CoreNumbers<Self> {
        let (core, order) = _cores(_simpleRows())
        return CoreNumbers(self, listed: _listedVertices(), core: core, order: order)
    }
}
