/// An undirected hypergraph: a finite set of vertices and a finite collection of hyperedges, each a
/// set of vertices of any size, the empty set included (Berge, *Hypergraphs*, 1989). Not a `Graph`,
/// and no shared parent with one: a hyperedge is not an edge. The `Hypergraphs` module's
/// `incidenceGraph` reads a hypergraph as its bipartite incidence graph (the Levi graph), which is
/// how the graph algorithms reach it.
///
/// **Hyperedges and their identity.** `hyperedges` lists every hyperedge once, a repeated one at
/// each of its positions, and a hyperedge's position is its identity, as an edge's is in `Graph`.
/// `incidentHyperedges(of:)` lists the positions of the hyperedges a vertex is a member of. A value
/// keyed by `Hyperedges.Index` (a weight) is the same from every member. Positions are valid until
/// the hypergraph is mutated.
///
/// **Vertex and hyperedge indices.** As for `Graph`: with `vertexIndexBound`, `vertexIndex(of:)`
/// maps the vertices one-to-one onto `0..<vertexIndexBound`, and `memberIndices(ofHyperedgeAt:)`
/// and `incidentHyperedges(ofIndex:)` read incidence in index space. With `hyperedgeIndexBound`,
/// `hyperedgeIndex(of:)` maps the positions one-to-one onto `0..<hyperedgeIndexBound`, so
/// per-hyperedge state lives in arrays. The algorithms in `Hypergraphs` need both bounds.
///
/// **Laws.** Every conformer satisfies:
/// - `vertexCount == vertices.count`, the vertices are distinct, and
///   `hyperedgeCount == hyperedges.count`.
/// - The members of a hyperedge are distinct vertices.
/// - A position `p` is in `incidentHyperedges(of: v)` exactly when `v` is a member of the
///   hyperedge at `p`, once, in `hyperedges` order. `degree(of: v)` is the length of that list and
///   `size(ofHyperedgeAt: p)` the number of members, so the degrees sum to the sizes.
/// - `contains(hyperedge:)` is true exactly when some hyperedge has those members, the empty set
///   included; it and `contains(_:)` never trap.
/// - With vertex indices, `vertices` is in index order, `memberIndices(ofHyperedgeAt:)` is the
///   members mapped through `vertexIndex(of:)` in the same order, and the `(ofIndex:)` reads equal
///   the vertex reads.
/// - With hyperedge indices, `hyperedgeIndexBound == hyperedgeCount`, and `hyperedges` is in index
///   order: the `k`th position has index `k`.
/// - The hash law: index-space members hash no vertex, and a vertex-space read looks its vertex up
///   once.
///
/// **Defaults.** As for `Graph`, members with default implementations are requirements, so a
/// representation's faster version is the one generic code calls, and a wrapper must forward
/// every one. The protocol has no mutation and does not refine `Sendable`.
public protocol Hypergraph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    /// The members of one hyperedge.
    associatedtype Members: Collection<Vertex>
    associatedtype Hyperedges: Collection<Members> where Hyperedges.Index: Hashable
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>

    /// Every vertex once, in an order the representation documents.
    var vertices: Vertices { get }

    /// Every hyperedge, as its members, at its position: a repeated hyperedge at each of its
    /// positions, an empty one as an empty collection.
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
    /// repeats; for an empty sequence, whether there is an empty hyperedge. Never traps: false when
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

    /// The incidence numbering the incidence-graph view uses as its edge positions: the
    /// incidences (a vertex in a hyperedge) numbered `0..<_incidenceCount` hyperedge by hyperedge,
    /// in index order, and within a hyperedge in `memberIndices` order. These four members read
    /// it. Defaults compute it from the other members: `_incidenceCount` in O(m), the others in
    /// O(m) and up per call. A representation that stores incidences (`UndirectedIncidenceList`)
    /// answers each in O(1).
    ///
    /// Not for use outside the library. Each requires both index bounds.
    var _incidenceCount: Int { get }

    /// The incidence numbers of the hyperedge whose index is `index`: a contiguous range.
    func _incidences(ofHyperedgeIndex index: Int) -> Range<Int>

    /// The incidence numbers of the vertex whose index is `index`, in `incidentHyperedges` order.
    func _incidences(ofIndex index: Int) -> ArraySlice<Int>

    /// The vertex index and hyperedge index of incidence `number`.
    func _incidence(_ number: Int) -> (vertexIndex: Int, hyperedgeIndex: Int)
}

extension Hypergraph {
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
        for v in wanted where !contains(v) { return false }
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

// MARK: - Incidence numbers, computed

extension Hypergraph {
    /// The position whose hyperedge index is `index`: `hyperedges` is in index order.
    @inlinable
    package func _hyperedgePosition(ofIndex index: Int) -> Hyperedges.Index {
        precondition(index >= 0 && index < hyperedgeCount, "Hyperedge index \(index) is out of range")
        return hyperedges.index(hyperedges.startIndex, offsetBy: index)
    }

    /// The first incidence number of each hyperedge, by index, and the total at the end.
    @inlinable
    package func _incidenceOffsets() -> [Int] {
        var offsets = [0]
        offsets.reserveCapacity(hyperedgeCount + 1)
        var total = 0
        for position in hyperedges.indices {
            total &+= size(ofHyperedgeAt: position)
            offsets.append(total)
        }
        return offsets
    }

    @inlinable
    public var _incidenceCount: Int {
        var total = 0
        for position in hyperedges.indices { total &+= size(ofHyperedgeAt: position) }
        return total
    }

    @inlinable
    public func _incidences(ofHyperedgeIndex index: Int) -> Range<Int> {
        let offsets = _incidenceOffsets()
        precondition(index >= 0 && index < offsets.count - 1, "Hyperedge index \(index) is out of range")
        return offsets[index] ..< offsets[index + 1]
    }

    @inlinable
    public func _incidences(ofIndex index: Int) -> ArraySlice<Int> {
        let offsets = _incidenceOffsets()
        var numbers: [Int] = []
        for position in incidentHyperedges(ofIndex: index) {
            var offset = 0
            for member in memberIndices(ofHyperedgeAt: position) {
                if member == index { break }
                offset &+= 1
            }
            numbers.append(offsets[hyperedgeIndex(of: position)] &+ offset)
        }
        return numbers[...]
    }

    @inlinable
    public func _incidence(_ number: Int) -> (vertexIndex: Int, hyperedgeIndex: Int) {
        var first = 0
        for (index, position) in hyperedges.indices.enumerated() {
            let size = size(ofHyperedgeAt: position)
            if number < first &+ size {
                var offset = number &- first
                for member in memberIndices(ofHyperedgeAt: position) {
                    if offset == 0 { return (member, index) }
                    offset &-= 1
                }
            }
            first &+= size
        }
        preconditionFailure("Incidence number \(number) is out of range")
    }
}
