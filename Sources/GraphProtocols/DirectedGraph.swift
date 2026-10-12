/// A directed graph: a finite set of vertices and a finite collection of directed edges between
/// them.
///
/// **Edges and their identity.** Edges may repeat (parallel edges) unless the representation says
/// otherwise. Each edge, every copy included, has a position in `edges`, and that position is the
/// edge's identity: `outEdges(of:)` lists the positions of the edges leaving a vertex, so an
/// algorithm can tell parallel edges apart and keep per-edge values (weights, capacities, flow)
/// keyed by `Edges.Index`. `source(ofEdgeAt:)` and `target(ofEdgeAt:)` read an edge's endpoints
/// without the cost of `edges[i]`. Positions are valid until the graph is mutated.
///
/// **Counting.** Every count and neighborhood counts each edge once, so a repeated edge counts once
/// per copy: `successors(of:)` lists a target once per edge to it, in the same order as
/// `outEdges(of:)`, and `outDegree(of:)` is the length of either. For a simple graph these are the
/// set definitions.
///
/// **Vertex indices.** A representation with dense vertex indices reports `vertexIndexBound`, and
/// then `vertexIndex(of:)` maps its vertices one-to-one onto `0..<vertexIndexBound`, so
/// algorithms can keep per-vertex state in arrays instead of dictionaries (Boost's `vertex_index`,
/// petgraph's `NodeCompactIndexable`). Indices are valid until the graph is mutated.
/// `successorIndices(ofIndex:)` gives adjacency directly in index space, and `outEdges(ofIndex:)`
/// the out-edges without looking the vertex up. A representation with dense edge indices also
/// reports `edgeIndexBound`, and then `edgeIndex(of:)` maps edge positions one-to-one onto
/// `0..<edgeIndexBound` (Boost's `edge_index`, petgraph's `EdgeIndexable`), so per-edge values
/// (weights, flow) can live in arrays.
///
/// **Laws.** Every conformer satisfies:
/// - `vertexCount == vertices.count`, the vertices are distinct, and every edge's endpoints are
///   vertices; `edgeCount == edges.count`.
/// - For every vertex `v`: `outEdges(of: v)` lists each position of an edge leaving `v` exactly
///   once; `source(ofEdgeAt: e) == v` and `target(ofEdgeAt: e) == edges[e].target` for each;
///   `successors(of: v)` is their targets in the same order; `outDegree(of: v)` is their count.
/// - The out-degrees sum to `edgeCount`. `contains(edge:)` is true exactly for the edges in
///   `edges`, and `contains` is false (and does not trap) for anything absent.
/// - Asking again gives the same answer.
/// - With vertex indices, `vertices` is in index order: `vertex(atIndex: i)` is the `i`th vertex,
///   so an algorithm that visits vertices in `vertices` order can walk `0..<vertexIndexBound`.
/// - With vertex indices, `successorIndices(ofIndex: vertexIndex(of: v))` is
///   `successors(of: v)` mapped through `vertexIndex(of:)`, in the same order, and
///   `outEdges(ofIndex: vertexIndex(of: v))` is `outEdges(of: v)`; for every position `e`,
///   `sourceIndex(ofEdgeAt: e)` and `targetIndex(ofEdgeAt: e)` are the indices of
///   `source(ofEdgeAt: e)` and `target(ofEdgeAt: e)`.
/// - With edge indices, `edgeIndexBound == edgeCount` and `edgeIndex(of:)` is one-to-one onto
///   `0..<edgeIndexBound`, and `edges` is in index order: the `k`th position of `edges` has
///   `edgeIndex` `k` (so `undirectedView`, which forwards both, keeps `Graph`'s law of the same name).
///
/// **Defaults.** Members with default implementations are requirements, not extension methods, so
/// a representation's faster version is the one generic code calls. A type that wraps another
/// graph generically (a view, a relabeling) must implement every requirement by forwarding to its
/// base: a default chosen for the wrapper would ignore the base's faster member.
///
/// The protocol has no mutation: mutation belongs to concrete types, and the refinement
/// `MutableDirectedGraph` (Boost's `MutableGraph`) gives wrappers the few hooks they need to
/// mutate a base generically. It does not refine
/// `Sendable`; representations are `Sendable` when their vertices are, and algorithms that cross
/// isolation ask for `DirectedGraph & Sendable`.
public protocol DirectedGraph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Edges: Collection<DirectedEdge<Vertex>> where Edges.Index: Hashable
    associatedtype Successors: Sequence<Vertex>
    associatedtype OutEdges: Sequence<Edges.Index>
    associatedtype SuccessorIndices: Sequence<Int> = LazyMapSequence<Successors, Int>

    /// Every vertex once, in an order the representation documents.
    var vertices: Vertices { get }

    /// Every edge, once per copy, in an order the representation documents.
    var edges: Edges { get }

    /// The target of every edge leaving `vertex`, once per edge, in the order of
    /// `outEdges(of: vertex)`.
    ///
    /// - Precondition: `contains(vertex)`. A representation may trap or return an empty sequence
    ///   when this does not hold; generic code must rely on neither.
    func successors(of vertex: Vertex) -> Successors

    /// The position in `edges` of every edge leaving `vertex`, each once.
    ///
    /// - Precondition: `contains(vertex)`, as for `successors(of:)`.
    func outEdges(of vertex: Vertex) -> OutEdges

    /// The source of the edge at `position` in `edges`. Default: `edges[position].source`.
    func source(ofEdgeAt position: Edges.Index) -> Vertex

    /// The target of the edge at `position` in `edges`. Default: `edges[position].target`.
    func target(ofEdgeAt position: Edges.Index) -> Vertex

    /// The number of vertices. Default: `vertices.count`.
    var vertexCount: Int { get }

    /// The number of edges, repeats included. Default: `edges.count`.
    var edgeCount: Int { get }

    /// Whether `vertex` is a vertex. Never traps. Default: a scan of `vertices`.
    func contains(_ vertex: Vertex) -> Bool

    /// Whether at least one copy of `edge` is an edge. Never traps; false when either endpoint is
    /// not a vertex. Default: a scan of `successors(of: edge.source)`.
    func contains(edge: DirectedEdge<Vertex>) -> Bool

    /// The number of edges leaving `vertex`, repeats included. Default: the length of
    /// `successors(of: vertex)`.
    ///
    /// - Precondition: `contains(vertex)`, as for `successors(of:)`.
    func outDegree(of vertex: Vertex) -> Int

    /// The number of dense vertex indices, `vertexCount`, or `nil` when the representation has
    /// none. Default: `nil`.
    var vertexIndexBound: Int? { get }

    /// The index of `vertex`, in `0..<vertexIndexBound`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `contains(vertex)`.
    func vertexIndex(of vertex: Vertex) -> Int

    /// The vertex whose index is `index`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func vertex(atIndex index: Int) -> Vertex

    /// The indices of `successors(of: vertex(atIndex: index))`, in the same order: adjacency in
    /// index space, so an algorithm keeping per-vertex state in arrays never maps a neighbor back
    /// to its index. Default: `successors` mapped through `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func successorIndices(ofIndex index: Int) -> SuccessorIndices

    /// `outEdges(of: vertex(atIndex: index))`, without the lookup a representation may need to
    /// find the vertex. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func outEdges(ofIndex index: Int) -> OutEdges

    /// `outDegree(of: vertex(atIndex: index))`, without the lookup a representation may need to
    /// find the vertex. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func outDegree(ofIndex index: Int) -> Int

    /// Calls `body` with each of `successorIndices(ofIndex: index)`, in order. Default: a loop
    /// over `successorIndices`. A view whose row is a filtering iterator (a subgraph, a product)
    /// runs its loops in place, which a walk over every row (union–find, breadth-first search)
    /// runs faster than through the iterator.
    ///
    /// Not for use outside the library.
    func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void)

    /// `vertexIndex(of: source(ofEdgeAt: position))`, for a representation or a view that knows
    /// the index without the lookup (a `LabeledGraph` reads its base's `Int` endpoint, where
    /// `vertexIndex(of:)` would hash the label). Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `position` is a position in `edges`.
    func sourceIndex(ofEdgeAt position: Edges.Index) -> Int

    /// `vertexIndex(of: target(ofEdgeAt: position))`, without the lookup where the representation
    /// can avoid it. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `position` is a position in `edges`.
    func targetIndex(ofEdgeAt position: Edges.Index) -> Int

    /// The number of dense edge indices, `edgeCount`, or `nil` when the representation has none.
    /// Default: `nil`.
    var edgeIndexBound: Int? { get }

    /// The index of the edge at `position`, in `0..<edgeIndexBound`.
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is a position in `edges`.
    func edgeIndex(of position: Edges.Index) -> Int

    /// For representations that store adjacency as flat rows in index space (compressed sparse
    /// row): calls `body` with the row offsets (`vertexIndexBound + 1` of them) and the targets,
    /// so that `successorIndices(ofIndex: v)` is `targets[offsets[v] ..< offsets[v + 1]]`, and
    /// returns its result. Only for a graph whose `Edges.Index` is `Int` and whose edge positions
    /// are `0 ..< edgeCount` in row order: slot `k` of `targets` is the edge at position `k` (and
    /// so with `edgeIndex` `k`), and algorithms hand slot `k` to a weight closure as position `k`.
    /// The buffers are valid only during the call. Default: `nil`, without calling `body`.
    ///
    /// Not for use outside the library: algorithms walk these rows with integer cursors, which
    /// avoids retaining the row storage once per visited vertex.
    func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result?

    /// For representations that store out-adjacency as rows in index space, each row in its own
    /// block of a shared pool (`AdjacencyList`): calls `body` with the target storage and its row
    /// table, and the edge-position storage and its row table, and returns its result. A row table
    /// holds three entries per vertex index `v`: the row's start in the storage, its length, and
    /// one more the algorithm ignores; so `successorIndices(ofIndex: v)` is
    /// `targets[targetRows[3v] ..< targetRows[3v] + targetRows[3v + 1]]`, and `outEdges(ofIndex: v)`
    /// likewise from `edges` and `edgeRows`. Only for a graph whose `Edges.Index` is `Int`. The
    /// buffers are valid only during the call. Default: `nil`, without calling `body`.
    ///
    /// Not for use outside the library, as `_withSuccessorIndexRows`; algorithms read the rows
    /// through `_withCheckedOutIndexRows(_:)`, which checks the tables' bounds once. A view that
    /// changes adjacency (a subgraph, a filter) must not forward it.
    func _withOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result?
}

/// A directed graph that also answers in-neighborhoods: Boost's `BidirectionalGraph`. Kept apart
/// from `DirectedGraph` because in-adjacency usually costs extra storage, and many algorithms only
/// go forward.
///
/// **Laws**, in addition to `DirectedGraph`'s: for every vertex `v`, `inEdges(of: v)` lists each
/// position of an edge entering `v` exactly once; `predecessors(of: v)` is their sources in the
/// same order; `inDegree(of: v)` is their count; `degree(of: v)` is `outDegree + inDegree`. With
/// vertex indices, `predecessorIndices` is `predecessors` mapped through `vertexIndex(of:)`, and
/// `inEdges(ofIndex: vertexIndex(of: v))` is `inEdges(of: v)`.
public protocol BidirectionalDirectedGraph<Vertex>: DirectedGraph {
    associatedtype Predecessors: Sequence<Vertex>
    associatedtype InEdges: Sequence<Edges.Index>
    associatedtype PredecessorIndices: Sequence<Int> = LazyMapSequence<Predecessors, Int>

    /// The source of every edge entering `vertex`, once per edge, in the order of
    /// `inEdges(of: vertex)`.
    ///
    /// - Precondition: `contains(vertex)`, as for `successors(of:)`.
    func predecessors(of vertex: Vertex) -> Predecessors

    /// The position in `edges` of every edge entering `vertex`, each once.
    ///
    /// - Precondition: `contains(vertex)`, as for `successors(of:)`.
    func inEdges(of vertex: Vertex) -> InEdges

    /// The number of edges entering `vertex`, repeats included. Default: the length of
    /// `predecessors(of: vertex)`.
    func inDegree(of vertex: Vertex) -> Int

    /// `outDegree(of:) + inDegree(of:)`; a self-loop counts twice. Default: that sum.
    func degree(of vertex: Vertex) -> Int

    /// `inDegree(of: vertex(atIndex: index))`, without the lookup a representation may need to
    /// find the vertex. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func inDegree(ofIndex index: Int) -> Int

    /// The indices of `predecessors(of: vertex(atIndex: index))`, in the same order. Default:
    /// `predecessors` mapped through `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func predecessorIndices(ofIndex index: Int) -> PredecessorIndices

    /// `inEdges(of: vertex(atIndex: index))`, without the lookup a representation may need to find
    /// the vertex. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func inEdges(ofIndex index: Int) -> InEdges

    /// Calls `body` with each of `predecessorIndices(ofIndex: index)`, in order. Default: a loop
    /// over `predecessorIndices`; as `_forEachSuccessorIndex(ofIndex:_:)`.
    ///
    /// Not for use outside the library.
    func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void)
}

extension DirectedGraph {
    @inlinable
    public func source(ofEdgeAt position: Edges.Index) -> Vertex {
        edges[position].source
    }

    @inlinable
    public func target(ofEdgeAt position: Edges.Index) -> Vertex {
        edges[position].target
    }

    @inlinable
    public var vertexCount: Int { vertices.count }

    @inlinable
    public var edgeCount: Int { edges.count }

    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        vertices.contains(vertex)
    }

    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        // The target is checked too, so a representation whose successors could name a
        // non-vertex still answers false.
        guard contains(edge.source), contains(edge.target) else { return false }
        return successors(of: edge.source).contains(edge.target)
    }

    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in successors(of: vertex) { count &+= 1 }
        return count
    }

    @inlinable
    public var vertexIndexBound: Int? { nil }

    @inlinable
    public func outEdges(ofIndex index: Int) -> OutEdges {
        outEdges(of: vertex(atIndex: index))
    }

    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        outDegree(of: vertex(atIndex: index))
    }

    @inlinable
    @inline(__always)
    public func _forEachSuccessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        for w in successorIndices(ofIndex: index) { body(w) }
    }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Edges.Index) -> Int {
        vertexIndex(of: source(ofEdgeAt: position))
    }

    @inlinable
    public func targetIndex(ofEdgeAt position: Edges.Index) -> Int {
        vertexIndex(of: target(ofEdgeAt: position))
    }

    @inlinable
    public var edgeIndexBound: Int? { nil }

    @inlinable
    public func edgeIndex(of position: Edges.Index) -> Int {
        preconditionFailure("\(Self.self) has no edge indices; check edgeIndexBound first")
    }

    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        nil
    }

    @inlinable
    public func _withOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        nil
    }

    /// `_withOutIndexRows(_:)`, with every row checked once to lie in bounds in both storages and
    /// the two rows of a vertex equally long, O(n), so `body` may read them unchecked. `nil`
    /// without vertex indices or stored rows.
    @inlinable
    @inline(__always)
    package func _withCheckedOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        guard let n = vertexIndexBound else { return nil }
        return _withOutIndexRows { targets, targetRows, edges, edgeRows in
            precondition(targetRows.count >= 3 * n && edgeRows.count >= 3 * n, "The row tables are shorter than vertexIndexBound")
            for v in 0 ..< n {
                let (ts, tl, es, el) = (targetRows[3 * v], targetRows[3 * v + 1], edgeRows[3 * v], edgeRows[3 * v + 1])
                precondition(tl == el && tl >= 0 && ts >= 0 && es >= 0 && ts + tl <= targets.count && es + el <= edges.count, "Row \(v) of the out-adjacency tables is out of bounds")
            }
            return body(targets, targetRows, edges, edgeRows)
        }
    }

    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int {
        preconditionFailure("\(Self.self) has no vertex indices; check vertexIndexBound first")
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        preconditionFailure("\(Self.self) has no vertex indices; check vertexIndexBound first")
    }
}

extension DirectedGraph where SuccessorIndices == LazyMapSequence<Successors, Int> {
    @inlinable
    public func successorIndices(ofIndex index: Int) -> LazyMapSequence<Successors, Int> {
        successors(of: vertex(atIndex: index)).lazy.map { vertexIndex(of: $0) }
    }
}

extension BidirectionalDirectedGraph where PredecessorIndices == LazyMapSequence<Predecessors, Int> {
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> LazyMapSequence<Predecessors, Int> {
        predecessors(of: vertex(atIndex: index)).lazy.map { vertexIndex(of: $0) }
    }
}

extension DirectedGraph where Successors: Collection {
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        successors(of: vertex).count
    }
}

extension BidirectionalDirectedGraph {
    @inlinable
    public func inEdges(ofIndex index: Int) -> InEdges {
        inEdges(of: vertex(atIndex: index))
    }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int {
        inDegree(of: vertex(atIndex: index))
    }

    @inlinable
    @inline(__always)
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        for w in predecessorIndices(ofIndex: index) { body(w) }
    }

    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in predecessors(of: vertex) { count &+= 1 }
        return count
    }

    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        outDegree(of: vertex) + inDegree(of: vertex)
    }
}

extension BidirectionalDirectedGraph where Predecessors: Collection {
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        predecessors(of: vertex).count
    }
}

/// A cursor over one row of `_withSuccessorIndexRows`: an iterator that holds no reference.
@frozen
@usableFromInline
package struct _RowCursor: IteratorProtocol {
    @usableFromInline var position: Int
    @usableFromInline let end: Int
    @usableFromInline let targets: UnsafePointer<Int>

    @inlinable
    @inline(__always)
    package init(row: Int, offsets: UnsafeBufferPointer<Int>, targets: UnsafeBufferPointer<Int>) {
        position = offsets[row]
        end = offsets[row + 1]
        // A placeholder when there are no edges at all; never read.
        self.targets = targets.baseAddress ?? UnsafePointer(bitPattern: MemoryLayout<Int>.alignment)!
    }

    @inlinable
    @inline(__always)
    package mutating func next() -> Int? {
        guard position < end else { return nil }
        defer { position += 1 }
        return targets[position]
    }
}

/// A cursor over the targets of one row of `_withOutIndexRows`: an iterator that holds no
/// reference. Unchecked: the tables are checked once by `_withCheckedOutIndexRows(_:)`.
@frozen
@usableFromInline
package struct _PooledRowCursor: IteratorProtocol {
    @usableFromInline var position: Int
    @usableFromInline let end: Int
    @usableFromInline let targets: UnsafePointer<Int>

    @inlinable
    @inline(__always)
    package init(row: Int, targets: UnsafeBufferPointer<Int>, targetRows: UnsafeBufferPointer<Int>) {
        position = targetRows[3 &* row]
        end = position &+ targetRows[3 &* row &+ 1]
        // A placeholder when there are no edges at all; never read.
        self.targets = targets.baseAddress ?? UnsafePointer(bitPattern: MemoryLayout<Int>.alignment)!
    }

    @inlinable
    @inline(__always)
    package mutating func next() -> Int? {
        guard position < end else { return nil }
        defer { position &+= 1 }
        return targets[position]
    }
}
