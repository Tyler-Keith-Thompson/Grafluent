/// A directed hypergraph: a finite set of vertices and a finite collection of hyperedges, each an
/// ordered pair of vertex sets, its sources (tail) and its targets (head). Gallo, Longo, Pallottino
/// and Nguyen, "Directed hypergraphs and applications", *Discrete Applied Mathematics*
/// 42(2–3):177–201, 1993, define a hyperarc as "an ordered pair … of (possibly empty) disjoint
/// subsets"; here either side may be empty and a vertex may be on both, the hypergraph form of a
/// self-loop (XGI's `DiHypergraph` allows both).
///
/// Not a `DirectedGraph`, and independent of `Hypergraph`, as `DirectedGraph` is of `Graph`. The
/// `Hypergraphs` module's `incidenceGraph` reads a directed hypergraph as a
/// `BidirectionalDirectedGraph`, sources → hyperedge → targets.
///
/// **Hyperedges and their identity.** As for `Hypergraph`: a hyperedge's position in `hyperedges`
/// is its identity. `outHyperedges(of: v)` lists the hyperedges with `v` among their sources,
/// Gallo's forward star FS(v), and `inHyperedges(of: v)` those with `v` among their targets, the
/// backward star BS(v). Both stars are requirements, so there is no bidirectional refinement.
///
/// **Laws.** Every conformer satisfies:
/// - `vertexCount == vertices.count`, the vertices are distinct, and
///   `hyperedgeCount == hyperedges.count`; each side of a hyperedge has distinct vertices.
/// - `p` is in `outHyperedges(of: v)` exactly when `v` is a source of `p`, and in
///   `inHyperedges(of: v)` exactly when `v` is a target of `p`; each list has `p` once, in
///   `hyperedges` order. `outDegree` and `inDegree` are their lengths, so they sum to the side
///   sizes, and `degree(of:)` is `outDegree + inDegree`: a vertex on both sides of a hyperedge
///   counts it twice.
/// - `contains(sources:targets:)` is true exactly when some hyperedge has those two sets, the
///   empty pair included, and never traps.
/// - The index laws of `Hypergraph`, side by side: `sourceIndices` and `targetIndices` are the
///   sides mapped through `vertexIndex(of:)`, the `(ofIndex:)` reads equal the vertex reads, and
///   with hyperedge indices `hyperedges` is in index order.
/// - The hash law: index-space members hash no vertex, and a vertex-space read looks its vertex up
///   once.
///
/// **Defaults.** As for `Hypergraph`. The protocol has no mutation and does not refine `Sendable`.
public protocol DirectedHypergraph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    /// One side of a hyperedge.
    associatedtype Members: Collection<Vertex>
    /// The hyperedges, one element per position. The element type is the representation's own (the
    /// library's are `(sources:, targets:)` pairs); generic code reads a hyperedge's sides through
    /// `sources(ofHyperedgeAt:)` and `targets(ofHyperedgeAt:)`, which is how `Members` is inferred.
    associatedtype Hyperedges: Collection where Hyperedges.Index: Hashable
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>
    associatedtype IncidentHyperedgeIndices: Sequence<Int> = LazyMapSequence<IncidentHyperedges, Int>

    /// Every vertex once, in an order the representation documents.
    var vertices: Vertices { get }

    /// Every hyperedge at its position.
    var hyperedges: Hyperedges { get }

    /// The positions of the hyperedges with `vertex` among their sources, Gallo's forward star
    /// FS(v), each once, in `hyperedges` order.
    ///
    /// - Precondition: `contains(vertex)`. A representation may trap or return an empty sequence
    ///   when this does not hold; generic code must rely on neither.
    func outHyperedges(of vertex: Vertex) -> IncidentHyperedges

    /// The positions of the hyperedges with `vertex` among their targets, the backward star BS(v),
    /// each once, in `hyperedges` order.
    ///
    /// - Precondition: `contains(vertex)`, as for `outHyperedges(of:)`.
    func inHyperedges(of vertex: Vertex) -> IncidentHyperedges

    /// The sources of the hyperedge at `position`, its tail.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func sources(ofHyperedgeAt position: Hyperedges.Index) -> Members

    /// The targets of the hyperedge at `position`, its head.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func targets(ofHyperedgeAt position: Hyperedges.Index) -> Members

    /// The number of sources of the hyperedge at `position` (XGI's `tail_size`). Default:
    /// `sources(ofHyperedgeAt: position).count`.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func sourceSize(ofHyperedgeAt position: Hyperedges.Index) -> Int

    /// The number of targets of the hyperedge at `position` (XGI's `head_size`). Default:
    /// `targets(ofHyperedgeAt: position).count`.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func targetSize(ofHyperedgeAt position: Hyperedges.Index) -> Int

    /// The number of hyperedges with `vertex` among their sources. Default: the length of
    /// `outHyperedges(of: vertex)`.
    func outDegree(of vertex: Vertex) -> Int

    /// The number of hyperedges with `vertex` among their targets. Default: the length of
    /// `inHyperedges(of: vertex)`.
    func inDegree(of vertex: Vertex) -> Int

    /// `outDegree(of:) + inDegree(of:)`. Default: that sum.
    func degree(of vertex: Vertex) -> Int

    /// The number of vertices. Default: `vertices.count`.
    var vertexCount: Int { get }

    /// The number of hyperedges. Default: `hyperedges.count`.
    var hyperedgeCount: Int { get }

    /// Whether `vertex` is a vertex. Never traps. Default: a scan of `vertices`.
    func contains(_ vertex: Vertex) -> Bool

    /// Whether some hyperedge has exactly these sources and these targets, ignoring order and
    /// repeats within each. Never traps: false when a vertex is not one. Default: two sets,
    /// compared with every hyperedge.
    func contains(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Bool

    /// The number of dense vertex indices, or `nil`. Default: `nil`.
    var vertexIndexBound: Int? { get }

    /// The index of `vertex`, in `0..<vertexIndexBound`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `contains(vertex)`.
    func vertexIndex(of vertex: Vertex) -> Int

    /// The vertex whose index is `index`.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    func vertex(atIndex index: Int) -> Vertex

    /// The number of dense hyperedge indices, or `nil`. Default: `nil`.
    var hyperedgeIndexBound: Int? { get }

    /// The index of the hyperedge at `position`, in `0..<hyperedgeIndexBound`.
    ///
    /// - Precondition: `hyperedgeIndexBound` is not `nil`, and `position` is a position in
    ///   `hyperedges`.
    func hyperedgeIndex(of position: Hyperedges.Index) -> Int

    /// The indices of `sources(ofHyperedgeAt: position)`, in the same order. Default: the sources
    /// mapped through `vertexIndex(of:)`.
    func sourceIndices(ofHyperedgeAt position: Hyperedges.Index) -> MemberIndices

    /// The indices of `targets(ofHyperedgeAt: position)`, in the same order. Default: the targets
    /// mapped through `vertexIndex(of:)`.
    func targetIndices(ofHyperedgeAt position: Hyperedges.Index) -> MemberIndices

    /// `outHyperedges(of: vertex(atIndex: index))`, without the lookup. Default: exactly that.
    func outHyperedges(ofIndex index: Int) -> IncidentHyperedges

    /// `inHyperedges(of: vertex(atIndex: index))`, without the lookup. Default: exactly that.
    func inHyperedges(ofIndex index: Int) -> IncidentHyperedges

    /// `outDegree(of: vertex(atIndex: index))`, without the lookup. Default: exactly that.
    func outDegree(ofIndex index: Int) -> Int

    /// `inDegree(of: vertex(atIndex: index))`, without the lookup. Default: exactly that.
    func inDegree(ofIndex index: Int) -> Int

    /// `outHyperedges(ofIndex: index)` mapped through `hyperedgeIndex(of:)`. Default: exactly that.
    ///
    /// - Precondition: both index bounds are non-nil, and `index` is in `0..<vertexIndexBound`.
    func outHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices

    /// `inHyperedges(ofIndex: index)` mapped through `hyperedgeIndex(of:)`. Default: exactly that.
    ///
    /// - Precondition: both index bounds are non-nil, and `index` is in `0..<vertexIndexBound`.
    func inHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices

    /// Calls `body` with each vertex index on either side of the hyperedge at `position`, at least
    /// once (a vertex on both sides may come twice). Default: `sourceIndices`, then
    /// `targetIndices`. `OrientedIncidenceMatrix` ORs the two planes' words, so each comes once.
    ///
    /// Not for use outside the library.
    func _forEachMemberIndex(ofHyperedgeAt position: Hyperedges.Index, _ body: (Int) -> Void)

    /// `Hypergraph._memberRank` for one side: the number of entries before `index` in
    /// `sourceIndices` (`targets: false`) or `targetIndices`. Default: a walk, O(k).
    /// `OrientedIncidenceMatrix` counts set bits, O(⌈n/64⌉).
    ///
    /// Not for use outside the library.
    func _memberRank(ofIndex index: Int, inHyperedgeAt position: Hyperedges.Index, targets: Bool) -> Int

    /// `Hypergraph._memberIndex(atRank:inHyperedgeAt:)` for one side. Default: a walk, O(k).
    ///
    /// Not for use outside the library.
    func _memberIndex(atRank rank: Int, inHyperedgeAt position: Hyperedges.Index, targets: Bool) -> Int
}

extension DirectedHypergraph {
    @inlinable
    public func sourceSize(ofHyperedgeAt position: Hyperedges.Index) -> Int {
        sources(ofHyperedgeAt: position).count
    }

    @inlinable
    public func targetSize(ofHyperedgeAt position: Hyperedges.Index) -> Int {
        targets(ofHyperedgeAt: position).count
    }

    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in outHyperedges(of: vertex) { count &+= 1 }
        return count
    }

    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in inHyperedges(of: vertex) { count &+= 1 }
        return count
    }

    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        outDegree(of: vertex) &+ inDegree(of: vertex)
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
    public func contains(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Bool {
        let wantedSources = Set(sources), wantedTargets = Set(targets)
        for position in hyperedges.indices
            where sourceSize(ofHyperedgeAt: position) == wantedSources.count && targetSize(ofHyperedgeAt: position) == wantedTargets.count {
            if self.sources(ofHyperedgeAt: position).allSatisfy({ wantedSources.contains($0) }),
               self.targets(ofHyperedgeAt: position).allSatisfy({ wantedTargets.contains($0) }) {
                return true
            }
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
    public func outHyperedges(ofIndex index: Int) -> IncidentHyperedges {
        outHyperedges(of: vertex(atIndex: index))
    }

    @inlinable
    public func inHyperedges(ofIndex index: Int) -> IncidentHyperedges {
        inHyperedges(of: vertex(atIndex: index))
    }

    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        outDegree(of: vertex(atIndex: index))
    }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int {
        inDegree(of: vertex(atIndex: index))
    }
}

extension DirectedHypergraph where MemberIndices == LazyMapSequence<Members, Int> {
    @inlinable
    public func sourceIndices(ofHyperedgeAt position: Hyperedges.Index) -> LazyMapSequence<Members, Int> {
        sources(ofHyperedgeAt: position).lazy.map { vertexIndex(of: $0) }
    }

    @inlinable
    public func targetIndices(ofHyperedgeAt position: Hyperedges.Index) -> LazyMapSequence<Members, Int> {
        targets(ofHyperedgeAt: position).lazy.map { vertexIndex(of: $0) }
    }
}

extension DirectedHypergraph where IncidentHyperedgeIndices == LazyMapSequence<IncidentHyperedges, Int> {
    @inlinable
    public func outHyperedgeIndices(ofIndex index: Int) -> LazyMapSequence<IncidentHyperedges, Int> {
        outHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) }
    }

    @inlinable
    public func inHyperedgeIndices(ofIndex index: Int) -> LazyMapSequence<IncidentHyperedges, Int> {
        inHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) }
    }
}

// MARK: - Incidence rows, computed

extension DirectedHypergraph {
    @inlinable
    public func _forEachMemberIndex(ofHyperedgeAt position: Hyperedges.Index, _ body: (Int) -> Void) {
        for i in sourceIndices(ofHyperedgeAt: position) { body(i) }
        for i in targetIndices(ofHyperedgeAt: position) { body(i) }
    }

    @inlinable
    public func _memberIndex(atRank rank: Int, inHyperedgeAt position: Hyperedges.Index, targets: Bool) -> Int {
        var remaining = rank
        for member in targets ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position) {
            if remaining == 0 { return member }
            remaining &-= 1
        }
        preconditionFailure("Rank \(rank) is out of range for that side of the hyperedge")
    }

    @inlinable
    public func _memberRank(ofIndex index: Int, inHyperedgeAt position: Hyperedges.Index, targets: Bool) -> Int {
        var rank = 0
        for member in targets ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position) {
            if member == index { return rank }
            rank &+= 1
        }
        preconditionFailure("Vertex index \(index) is not on that side of the hyperedge")
    }

}
