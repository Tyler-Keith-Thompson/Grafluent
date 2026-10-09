import GraphProtocols
import Walks

/// Every simple cycle of a directed graph once, lazily: by least vertex (in `vertices` order),
/// and among the cycles with one least vertex in the order a depth-first search from it, taking
/// out-edges in `outEdges` order, meets them.
///
/// The sequence holds the graph (a value), so iterating again gives the same cycles, and changing
/// the original graph afterwards changes nothing. The first `next()` copies the graph's rows and
/// decomposes them, O(n + m). Unbounded, the time between consecutive cycles is O(n + m)
/// (Johnson), so c cycles take O((n + m)(c + 1)); with a bound k the whole enumeration takes
/// O((c + n)·k·d^k) for average degree d (Gupta–Suzumura).
@frozen
public struct DirectedSimpleCycles<G: DirectedGraph>: Sequence {
    public typealias Element = Cycle<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    /// The longest cycle, in edges, that the sequence includes.
    public let maxLength: Int

    @inlinable
    init(_ graph: G, maxLength: Int) {
        self.graph = graph
        self.maxLength = maxLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph, maxLength: maxLength)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline let maxLength: Int
        @usableFromInline var search: _SimpleCycleSearch?
        @usableFromInline var positions: [G.Edges.Index] = []
        @usableFromInline var listed: [G.Vertex]?

        @inlinable
        init(_ graph: G, maxLength: Int) {
            self.graph = graph
            self.maxLength = maxLength
        }

        @inlinable
        public mutating func next() -> Element? {
            if search == nil {
                let (rows, positions, listed) = graph._cycleRows()
                self.positions = positions
                self.listed = listed
                search = _SimpleCycleSearch(rows, maxLength: maxLength)
            }
            guard search!.next() else { return nil }
            return search!._withCycle { path, pathEdges, closing in
                var vertices: [G.Vertex] = [], edges: [G.Edges.Index] = []
                vertices.reserveCapacity(path.count)
                edges.reserveCapacity(path.count)
                for v in path { vertices.append(graph._vertex(number: v, listed)) }
                for e in pathEdges.dropFirst() { edges.append(positions[e]) }
                edges.append(positions[closing])
                return Cycle(_uncheckedVertices: vertices, edges: edges)
            }
        }
    }
}

/// Every simple cycle of an undirected graph once, lazily, each starting at its least vertex (in
/// `vertices` order) and leaving it through the lesser of its two edges there: by least vertex,
/// and among the cycles with one least vertex in the order a depth-first search from it, taking
/// edges in `incidentEdges` order, meets them in that orientation.
///
/// A self-loop is a cycle of length 1, and each pair of parallel edges one of length 2; a single
/// edge is no cycle. Otherwise as `DirectedSimpleCycles`.
@frozen
public struct UndirectedSimpleCycles<G: Graph>: Sequence {
    public typealias Element = Cycle<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    /// The longest cycle, in edges, that the sequence includes.
    public let maxLength: Int

    @inlinable
    init(_ graph: G, maxLength: Int) {
        self.graph = graph
        self.maxLength = maxLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph, maxLength: maxLength)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline let maxLength: Int
        @usableFromInline var search: _SimpleCycleSearch?
        @usableFromInline var positions: [G.Edges.Index] = []
        @usableFromInline var listed: [G.Vertex]?

        @inlinable
        init(_ graph: G, maxLength: Int) {
            self.graph = graph
            self.maxLength = maxLength
        }

        @inlinable
        public mutating func next() -> Element? {
            if search == nil {
                let (rows, positions) = graph._cycleRows()
                self.positions = positions
                listed = graph._listedVertices()
                search = _SimpleCycleSearch(rows, maxLength: maxLength)
            }
            guard search!.next() else { return nil }
            return search!._withCycle { path, pathEdges, closing in
                var vertices: [G.Vertex] = [], edges: [G.Edges.Index] = []
                vertices.reserveCapacity(path.count)
                edges.reserveCapacity(path.count)
                for v in path { vertices.append(graph._vertex(number: v, listed)) }
                for e in pathEdges.dropFirst() { edges.append(positions[e]) }
                edges.append(positions[closing])
                return Cycle(_uncheckedVertices: vertices, edges: edges)
            }
        }
    }
}

extension DirectedSimpleCycles: Sendable where G: Sendable {}
extension DirectedSimpleCycles.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}
extension UndirectedSimpleCycles: Sendable where G: Sendable {}
extension UndirectedSimpleCycles.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}

extension DirectedGraph {
    /// Every simple cycle (elementary circuit) of the graph once, lazily: no vertex and no edge
    /// twice, a self-loop a cycle of length 1, each copy of a parallel edge a different cycle.
    /// Each starts at its least vertex in `vertices` order; see `DirectedSimpleCycles` for the
    /// order.
    ///
    /// - Parameter maxLength: The longest cycle to include, in edges. A bound prunes the search
    ///   (Gupta–Suzumura); the result is the unbounded sequence filtered to it, in the same order.
    /// - Precondition: `maxLength >= 0`.
    @inlinable
    public func simpleCycles(maxLength: Int = .max) -> DirectedSimpleCycles<Self> {
        precondition(maxLength >= 0, "maxLength must be nonnegative")
        return DirectedSimpleCycles(self, maxLength: maxLength)
    }
}

extension Graph {
    /// Every simple cycle of the graph once, lazily: no vertex and no edge twice, so a self-loop
    /// is a cycle of length 1, each pair of parallel edges one of length 2, and a single edge
    /// none. Each starts at its least vertex in `vertices` order and leaves it through the lesser
    /// of its two edges there, so equal cycles have equal `vertices` and `edges`; see
    /// `UndirectedSimpleCycles` for the order.
    ///
    /// - Parameter maxLength: The longest cycle to include, in edges. A bound prunes the search
    ///   (Gupta–Suzumura); the result is the unbounded sequence filtered to it, in the same order.
    /// - Precondition: `maxLength >= 0`.
    @inlinable
    public func simpleCycles(maxLength: Int = .max) -> UndirectedSimpleCycles<Self> {
        precondition(maxLength >= 0, "maxLength must be nonnegative")
        return UndirectedSimpleCycles(self, maxLength: maxLength)
    }
}
