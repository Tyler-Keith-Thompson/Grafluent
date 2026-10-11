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
    associatedtype Hyperedges: Collection where Hyperedges.Index: Hashable,
        Hyperedges.Element == (sources: Members, targets: Members)
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>

    /// Every vertex once, in an order the representation documents.
    var vertices: Vertices { get }

    /// Every hyperedge, as its sources and its targets, at its position.
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

    /// The sources of the hyperedge at `position`. Default: `hyperedges[position].sources`.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func sources(ofHyperedgeAt position: Hyperedges.Index) -> Members

    /// The targets of the hyperedge at `position`. Default: `hyperedges[position].targets`.
    ///
    /// - Precondition: `position` is a position in `hyperedges`.
    func targets(ofHyperedgeAt position: Hyperedges.Index) -> Members

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

    /// The incidence numbering the directed incidence-graph view uses as its edge positions: the
    /// source incidences (a vertex among a hyperedge's sources) numbered
    /// `0..<_sourceIncidenceCount` hyperedge by hyperedge, in index order, within a hyperedge in
    /// `sourceIndices` order; the target incidences likewise from 0. `targets: true` reads the
    /// target side. Defaults compute it from the other members, in O(m) and up per call; a
    /// representation that stores incidences (`IncidenceList`) answers each in O(1).
    ///
    /// Not for use outside the library. Each requires both index bounds.
    func _incidenceCount(targets: Bool) -> Int

    /// The incidence numbers of one side of the hyperedge whose index is `index`.
    func _incidences(ofHyperedgeIndex index: Int, targets: Bool) -> Range<Int>

    /// The incidence numbers of the vertex whose index is `index` on one side, in
    /// `outHyperedges` or `inHyperedges` order.
    func _incidences(ofIndex index: Int, targets: Bool) -> ArraySlice<Int>

    /// The vertex index and hyperedge index of incidence `number` on one side.
    func _incidence(_ number: Int, targets: Bool) -> (vertexIndex: Int, hyperedgeIndex: Int)
}

extension DirectedHypergraph {
    @inlinable
    public func sources(ofHyperedgeAt position: Hyperedges.Index) -> Members {
        hyperedges[position].sources
    }

    @inlinable
    public func targets(ofHyperedgeAt position: Hyperedges.Index) -> Members {
        hyperedges[position].targets
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
        for v in wantedSources.union(wantedTargets) where !contains(v) { return false }
        for hyperedge in hyperedges where hyperedge.sources.count == wantedSources.count && hyperedge.targets.count == wantedTargets.count {
            if hyperedge.sources.allSatisfy({ wantedSources.contains($0) }), hyperedge.targets.allSatisfy({ wantedTargets.contains($0) }) {
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

// MARK: - Incidence numbers, computed

extension DirectedHypergraph {
    /// The position whose hyperedge index is `index`: `hyperedges` is in index order.
    @inlinable
    package func _hyperedgePosition(ofIndex index: Int) -> Hyperedges.Index {
        precondition(index >= 0 && index < hyperedgeCount, "Hyperedge index \(index) is out of range")
        return hyperedges.index(hyperedges.startIndex, offsetBy: index)
    }

    @inlinable
    package func _sideCount(ofHyperedgeAt position: Hyperedges.Index, targets: Bool) -> Int {
        targets ? self.targets(ofHyperedgeAt: position).count : sources(ofHyperedgeAt: position).count
    }

    /// The first incidence number of one side of each hyperedge, by index, and the total at the end.
    @inlinable
    package func _incidenceOffsets(targets: Bool) -> [Int] {
        var offsets = [0]
        offsets.reserveCapacity(hyperedgeCount + 1)
        var total = 0
        for position in hyperedges.indices {
            total &+= _sideCount(ofHyperedgeAt: position, targets: targets)
            offsets.append(total)
        }
        return offsets
    }

    @inlinable
    public func _incidenceCount(targets: Bool) -> Int {
        _incidenceOffsets(targets: targets).last!
    }

    @inlinable
    public func _incidences(ofHyperedgeIndex index: Int, targets: Bool) -> Range<Int> {
        let offsets = _incidenceOffsets(targets: targets)
        precondition(index >= 0 && index < offsets.count - 1, "Hyperedge index \(index) is out of range")
        return offsets[index] ..< offsets[index + 1]
    }

    @inlinable
    public func _incidences(ofIndex index: Int, targets: Bool) -> ArraySlice<Int> {
        let offsets = _incidenceOffsets(targets: targets)
        var numbers: [Int] = []
        for position in targets ? inHyperedges(ofIndex: index) : outHyperedges(ofIndex: index) {
            var offset = 0
            for member in targets ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position) {
                if member == index { break }
                offset &+= 1
            }
            numbers.append(offsets[hyperedgeIndex(of: position)] &+ offset)
        }
        return numbers[...]
    }

    @inlinable
    public func _incidence(_ number: Int, targets: Bool) -> (vertexIndex: Int, hyperedgeIndex: Int) {
        var first = 0
        for (index, position) in hyperedges.indices.enumerated() {
            let size = _sideCount(ofHyperedgeAt: position, targets: targets)
            if number < first &+ size {
                var offset = number &- first
                for member in targets ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position) {
                    if offset == 0 { return (member, index) }
                    offset &-= 1
                }
            }
            first &+= size
        }
        preconditionFailure("Incidence number \(number) is out of range")
    }
}
