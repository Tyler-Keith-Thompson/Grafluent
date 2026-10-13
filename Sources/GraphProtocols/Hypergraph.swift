/// An undirected hypergraph: a finite set of vertices and a finite collection of hyperedges, each a
/// set of vertices of any size, the empty set included (Berge, *Hypergraphs*, 1989).
///
/// A hypergraph is not a `Graph` and shares no parent protocol with one, because a hyperedge is
/// not an edge. The `Hypergraphs` module's `incidenceGraphView` reads a hypergraph as its
/// bipartite incidence graph (the Levi graph), which is how the graph algorithms reach it.
///
/// `hyperedges` lists every hyperedge once, a repeated one at each of its positions. A hyperedge's
/// position is its identity, as an edge's is in `Graph`. `incidentHyperedges(of:)` lists the
/// positions of the hyperedges a vertex is a member of, so a value keyed by `Hyperedges.Index`,
/// such as a weight, is the same from every member. Positions are valid until the hypergraph is
/// mutated.
///
/// With `vertexIndexBound`, `vertexIndex(of:)` maps the vertices one-to-one onto
/// `0..<vertexIndexBound`, and `memberIndices(ofHyperedgeAt:)` and `incidentHyperedges(ofIndex:)`
/// read incidence in index space. With `hyperedgeIndexBound`, `hyperedgeIndex(of:)` maps the
/// positions one-to-one onto `0..<hyperedgeIndexBound`, so per-hyperedge state lives in arrays.
/// The algorithms in `Hypergraphs` need both bounds.
///
/// Every conformer satisfies these laws:
/// - `vertexCount == vertices.count`, the vertices are distinct, and
///   `hyperedgeCount == hyperedges.count`.
/// - The members of a hyperedge are distinct vertices.
/// - A position `p` is in `incidentHyperedges(of: v)` exactly when `v` is a member of the
///   hyperedge at `p`, once, in `hyperedges` order. `degree(of: v)` is the length of that list and
///   `size(ofHyperedgeAt: p)` is the number of members, so the degrees sum to the sizes.
/// - `contains(hyperedge:)` is true exactly when some hyperedge has those members, the empty set
///   included. It and `contains(_:)` never trap.
/// - With vertex indices, `vertices` is in index order, `memberIndices(ofHyperedgeAt:)` is the
///   members mapped through `vertexIndex(of:)` in the same order, and the `(ofIndex:)` reads equal
///   the vertex reads.
/// - With hyperedge indices, `hyperedgeIndexBound == hyperedgeCount`, and `hyperedges` is in index
///   order: the `k`th position has index `k`.
/// - Index-space members hash no vertex, and a vertex-space read looks its vertex up once.
///
/// Members with default implementations are still requirements. Generic code calls a
/// representation's own version when it has one, and a wrapper must forward every one. The
/// protocol has no mutating members and does not refine `Sendable`.
public protocol Hypergraph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    /// The members of one hyperedge.
    associatedtype Members: Collection<Vertex>
    associatedtype Hyperedges: Collection<Members> where Hyperedges.Index: Hashable
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>
    associatedtype IncidentHyperedgeIndices: Sequence<Int> = LazyMapSequence<IncidentHyperedges, Int>

    /// Every vertex once, in an order the representation documents.
    var vertices: Vertices { get }

    /// Every hyperedge, as its members, at its position. A repeated hyperedge appears at each of
    /// its positions, and an empty one as an empty collection.
    var hyperedges: Hyperedges { get }

    /// The positions of the hyperedges `vertex` is a member of, each once, in `hyperedges` order.
    ///
    /// - Precondition: `contains(vertex)`. A representation may trap or return an empty sequence
    ///   when this does not hold; generic code must rely on neither.
    func incidentHyperedges(of vertex: Vertex) -> IncidentHyperedges

    /// The members of the hyperedge at `position`. Default: `hyperedges[position]`.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func members(ofHyperedgeAt position: Hyperedges.Index) -> Members

    /// The number of members of the hyperedge at `position`, Berge's |e|. Default:
    /// `members(ofHyperedgeAt: position).count`.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func size(ofHyperedgeAt position: Hyperedges.Index) -> Int

    /// The number of hyperedges `vertex` is a member of. Default: the length of
    /// `incidentHyperedges(of: vertex)`.
    ///
    /// - Precondition: `contains(vertex)`, as for `incidentHyperedges(of:)`.
    func degree(of vertex: Vertex) -> Int

    /// The number of vertices. Default: `vertices.count`.
    var vertexCount: Int { get }

    /// The number of hyperedges, repeats and empty ones included. Default: `hyperedges.count`.
    var hyperedgeCount: Int { get }

    /// Whether `vertex` is a vertex. Never traps. Default: a scan of `vertices`.
    func contains(_ vertex: Vertex) -> Bool

    /// Whether some hyperedge has exactly the members of `members`, ignoring their order and
    /// repeats. For an empty sequence, whether there is an empty hyperedge. Never traps; false when
    /// a member is not a vertex. Default: a set of the members, compared with every hyperedge.
    func contains(hyperedge members: some Sequence<Vertex>) -> Bool

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

    /// The number of dense hyperedge indices, `hyperedgeCount`, or `nil` when the representation
    /// has none. Default: `nil`.
    var hyperedgeIndexBound: Int? { get }

    /// The index of the hyperedge at `position`, in `0..<hyperedgeIndexBound`.
    ///
    /// - Precondition: `hyperedgeIndexBound` is not `nil`, and `position` is a position in
    ///   `hyperedges`.
    func hyperedgeIndex(of position: Hyperedges.Index) -> Int

    /// The indices of `members(ofHyperedgeAt: position)`, in the same order. Default: the members
    /// mapped through `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `position` is a position in
    ///   `hyperedges`.
    func memberIndices(ofHyperedgeAt position: Hyperedges.Index) -> MemberIndices

    /// `incidentHyperedges(of: vertex(atIndex: index))`, without the lookup a representation may
    /// need to find the vertex. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func incidentHyperedges(ofIndex index: Int) -> IncidentHyperedges

    /// `degree(of: vertex(atIndex: index))`, without the lookup. Default: exactly that.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func degree(ofIndex index: Int) -> Int

    /// The indices of the hyperedges that the vertex at `index` is a member of:
    /// `incidentHyperedges(ofIndex: index)` mapped through `hyperedgeIndex(of:)`. Default: exactly
    /// that.
    ///
    /// - Precondition: both index bounds are non-nil, and `index` is in `0..<vertexIndexBound`.
    func incidentHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices

    /// Calls `body` with each of `memberIndices(ofHyperedgeAt: position)`, in order. Default: a
    /// loop over `memberIndices(ofHyperedgeAt:)`. `IncidenceMatrix` scans the column's words in
    /// place, which is faster for algorithms that visit every hyperedge.
    ///
    /// Not for use outside the library.
    func _forEachMemberIndex(ofHyperedgeAt position: Hyperedges.Index, _ body: (Int) -> Void)

    /// The number of members before `index` in `memberIndices(ofHyperedgeAt: position)`, which is
    /// the member's place in the hyperedge. Default: a walk of `memberIndices`, O(k).
    /// `IncidenceMatrix` counts the column's set bits below `index`, O(⌈n/64⌉). The
    /// incidence-graph view numbers a vertex's incidences with it.
    ///
    /// - Precondition: `index` is a member of the hyperedge.
    ///
    /// Not for use outside the library.
    func _memberRank(ofIndex index: Int, inHyperedgeAt position: Hyperedges.Index) -> Int

    /// The member index at offset `rank` of `memberIndices(ofHyperedgeAt: position)`, the inverse
    /// of `_memberRank`. Default: a walk, O(k). `IncidenceMatrix` skips whole words by popcount,
    /// O(⌈n/64⌉). The incidence-graph view's `edges[q]` reads it.
    ///
    /// Not for use outside the library.
    func _memberIndex(atRank rank: Int, inHyperedgeAt position: Hyperedges.Index) -> Int

    /// Calls `body` with the incidences as flat rows, valid only during the call. The
    /// incidence-graph views number their edges this way.
    ///
    /// Incidence `q` is the `q`th member, counting hyperedge by hyperedge in index order and within
    /// a hyperedge in `memberIndices` order. Hyperedge `h`'s incidences are
    /// `memberOffsets[h] ..< memberOffsets[h + 1]` (`m + 1` offsets), and `members[q]` is
    /// incidence `q`'s vertex index. Vertex `i`'s row in `incidences` lists its incidence numbers
    /// in ascending order, and its row in `hyperedges` lists the hyperedge indices beside them.
    /// Each row table has three entries per vertex (start, length, unused), as in
    /// `Graph._withIncidentIndexRows`.
    ///
    /// Default: the rows written out for the call, O(n + m + p) plus the cost of reading every
    /// `memberIndices` once. `UndirectedIncidenceList` lends its storage.
    ///
    /// Not for use outside the library. Requires both index bounds.
    func _withIncidenceRows<Result>(
        _ body: (
            _ memberOffsets: UnsafeBufferPointer<Int>, _ members: UnsafeBufferPointer<Int>,
            _ incidences: UnsafeBufferPointer<Int>, _ incidenceRows: UnsafeBufferPointer<Int>,
            _ hyperedges: UnsafeBufferPointer<Int>, _ hyperedgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result

    /// The hypergraph's current generation. Every structural mutation replaces it. A structure
    /// derived from the hypergraph stores the generation and calls
    /// `GraphGeneration.isCurrent(for:)` before relying on it again. Default:
    /// `GraphGeneration.untracked`, which is current for no hypergraph. A wrapper reports its
    /// base's generation.
    var generation: GraphGeneration { get }
}

extension Hypergraph {
    /// `GraphGeneration.untracked`, for a conformer that does not track its mutations.
    @inlinable
    public var generation: GraphGeneration { .untracked }

    @inlinable
    public func members(ofHyperedgeAt position: Hyperedges.Index) -> Members {
        hyperedges[position]
    }

    @inlinable
    public func size(ofHyperedgeAt position: Hyperedges.Index) -> Int {
        members(ofHyperedgeAt: position).count
    }

    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in incidentHyperedges(of: vertex) { count &+= 1 }
        return count
    }

    @inlinable
    public var vertexCount: Int { vertices.count }

    @inlinable
    public var hyperedgeCount: Int { hyperedges.count }

    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        vertices.contains(vertex)
    }

    @inlinable
    public func contains(hyperedge members: some Sequence<Vertex>) -> Bool {
        let wanted = Set(members)
        for hyperedge in hyperedges where hyperedge.count == wanted.count {
            if hyperedge.allSatisfy({ wanted.contains($0) }) { return true }
        }
        return false
    }

    @inlinable
    public var vertexIndexBound: Int? { nil }

    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int {
        preconditionFailure("\(Self.self) has no vertex indices; check vertexIndexBound first")
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        preconditionFailure("\(Self.self) has no vertex indices; check vertexIndexBound first")
    }

    @inlinable
    public var hyperedgeIndexBound: Int? { nil }

    @inlinable
    public func hyperedgeIndex(of position: Hyperedges.Index) -> Int {
        preconditionFailure("\(Self.self) has no hyperedge indices; check hyperedgeIndexBound first")
    }

    @inlinable
    public func incidentHyperedges(ofIndex index: Int) -> IncidentHyperedges {
        incidentHyperedges(of: vertex(atIndex: index))
    }

    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        degree(of: vertex(atIndex: index))
    }
}

extension Hypergraph where MemberIndices == LazyMapSequence<Members, Int> {
    @inlinable
    public func memberIndices(ofHyperedgeAt position: Hyperedges.Index) -> LazyMapSequence<Members, Int> {
        members(ofHyperedgeAt: position).lazy.map { vertexIndex(of: $0) }
    }
}

extension Hypergraph where IncidentHyperedgeIndices == LazyMapSequence<IncidentHyperedges, Int> {
    @inlinable
    public func incidentHyperedgeIndices(ofIndex index: Int) -> LazyMapSequence<IncidentHyperedges, Int> {
        incidentHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) }
    }
}

// MARK: - Incidence rows, computed

extension Hypergraph {
    @inlinable
    public func _forEachMemberIndex(ofHyperedgeAt position: Hyperedges.Index, _ body: (Int) -> Void) {
        for i in memberIndices(ofHyperedgeAt: position) { body(i) }
    }

    @inlinable
    public func _memberIndex(atRank rank: Int, inHyperedgeAt position: Hyperedges.Index) -> Int {
        var remaining = rank
        for member in memberIndices(ofHyperedgeAt: position) {
            if remaining == 0 { return member }
            remaining &-= 1
        }
        preconditionFailure("Rank \(rank) is out of range for the hyperedge")
    }

    @inlinable
    public func _memberRank(ofIndex index: Int, inHyperedgeAt position: Hyperedges.Index) -> Int {
        var rank = 0
        for member in memberIndices(ofHyperedgeAt: position) {
            if member == index { return rank }
            rank &+= 1
        }
        preconditionFailure("Vertex index \(index) is not a member of the hyperedge")
    }

    @inlinable
    public func _withIncidenceRows<Result>(
        _ body: (
            _ memberOffsets: UnsafeBufferPointer<Int>, _ members: UnsafeBufferPointer<Int>,
            _ incidences: UnsafeBufferPointer<Int>, _ incidenceRows: UnsafeBufferPointer<Int>,
            _ hyperedges: UnsafeBufferPointer<Int>, _ hyperedgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result {
        guard let n = vertexIndexBound, hyperedgeIndexBound != nil else {
            preconditionFailure("\(Self.self) has no vertex or hyperedge indices")
        }
        var memberOffsets: [Int] = [0]
        memberOffsets.reserveCapacity(hyperedgeCount &+ 1)
        var members: [Int] = []
        for position in hyperedges.indices {
            for i in memberIndices(ofHyperedgeAt: position) { members.append(i) }
            memberOffsets.append(members.count)
        }
        return _withTransposedIncidenceRows(vertexCount: n, memberOffsets: memberOffsets, members: members, body)
    }
}

/// Calls `body` with `members` (flat rows at `memberOffsets`) and its transpose: for each of the
/// `n` vertex indices, its incidence numbers ascending and the row numbers beside them, under one
/// row table of (start, length, unused) per vertex, laid out by a counting pass. O(n + m + p).
@inlinable
package func _withTransposedIncidenceRows<Result>(
    vertexCount n: Int, memberOffsets: [Int], members: [Int],
    _ body: (
        _ memberOffsets: UnsafeBufferPointer<Int>, _ members: UnsafeBufferPointer<Int>,
        _ incidences: UnsafeBufferPointer<Int>, _ incidenceRows: UnsafeBufferPointer<Int>,
        _ hyperedges: UnsafeBufferPointer<Int>, _ hyperedgeRows: UnsafeBufferPointer<Int>
    ) -> Result
) -> Result {
    let p = members.count, m = memberOffsets.count &- 1
    var rows = [Int](repeating: 0, count: 3 &* n)
    var incidences = [Int](repeating: 0, count: p)
    var rowHyperedges = [Int](repeating: 0, count: p)
    memberOffsets.withUnsafeBufferPointer { offsets in
        members.withUnsafeBufferPointer { members in
            rows.withUnsafeMutableBufferPointer { rows in
                for q in 0 ..< p {
                    let i = members[q]
                    precondition(i >= 0 && i < n, "Member index \(i) is out of range 0..<\(n)")
                    rows[3 &* i &+ 1] &+= 1
                }
                var start = 0
                for i in 0 ..< n {
                    rows[3 &* i] = start
                    start &+= rows[3 &* i &+ 1]
                    rows[3 &* i &+ 1] = 0
                }
                incidences.withUnsafeMutableBufferPointer { incidences in
                    rowHyperedges.withUnsafeMutableBufferPointer { rowHyperedges in
                        for h in 0 ..< m {
                            for q in offsets[h] ..< offsets[h &+ 1] {
                                let i = members[q]
                                let slot = rows[3 &* i] &+ rows[3 &* i &+ 1]
                                rows[3 &* i &+ 1] &+= 1
                                incidences[slot] = q
                                rowHyperedges[slot] = h
                            }
                        }
                    }
                }
            }
        }
    }
    return memberOffsets.withUnsafeBufferPointer { offsets in
        members.withUnsafeBufferPointer { members in
            incidences.withUnsafeBufferPointer { incidences in
                rowHyperedges.withUnsafeBufferPointer { rowHyperedges in
                    rows.withUnsafeBufferPointer { rows in
                        body(offsets, members, incidences, rows, rowHyperedges, rows)
                    }
                }
            }
        }
    }
}
