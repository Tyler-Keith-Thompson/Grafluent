import GraphProtocols
import OrderedCollections

/// An undirected hypergraph stored as an incidence list: a row per hyperedge of its members and a
/// row per vertex of its memberships. The undirected counterpart of `IncidenceList`, named as
/// `UndirectedAdjacencyList` is. (`IncidenceMatrix`, the bit-matrix representation, is the
/// undirected one of its pair, because "oriented incidence matrix" is the established name of the
/// other.)
///
/// The vertices are any `Hashable` values, kept in an `OrderedSet` whose element `i` is vertex
/// index `i`: the vertices listed first, then new members by first appearance, as `LabeledGraph`
/// assigns them. A hyperedge is a set of vertices of any size, the empty set included; repeated
/// hyperedges are kept, each at its own position `0..<hyperedgeCount`, and a member listed twice
/// is stored once. Members are stored in vertex-index order.
///
/// Storage is compressed sparse rows: the members of every hyperedge in one array, and for every
/// vertex its incidence numbers and, beside them, its hyperedge positions, in rows of shared
/// pools. So `memberIndices` and `incidentHyperedges(ofIndex:)` are stored `ArraySlice<Int>` rows
/// read without hashing, and the
/// hypergraph makes a constant number of allocations however many vertices it has. Every
/// vertex-space read hashes its vertex once; index-space reads and the `Hypergraphs` algorithms
/// hash none.
///
/// Hyperedges can be appended but not removed (removal, and with it a decision on positions, is
/// left for later). Equality ignores the order of the vertices and of the hyperedges.
@frozen
public struct UndirectedIncidenceList<Vertex: Hashable> {
    /// The vertices; element `i` is vertex index `i`.
    @usableFromInline
    internal var _vertices: OrderedSet<Vertex>

    /// The hyperedges and their transpose.
    @usableFromInline
    internal var _plane: _IncidencePlane

    /// The hypergraph with no vertices and no hyperedges.
    @inlinable
    public init() {
        _vertices = []
        _plane = _IncidencePlane()
    }

    /// The hypergraph with `vertices`, already distinct, and the plane over their indices.
    @inlinable
    internal init(_uncheckedVertices vertices: OrderedSet<Vertex>, plane: _IncidencePlane) {
        _vertices = vertices
        _plane = plane
    }
}

// MARK: - Construction

extension UndirectedIncidenceList {
    /// A hypergraph with the given vertices and no hyperedges. A repeated vertex is inserted once.
    ///
    /// - Complexity: O(n) expected.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init(vertices: vertices, hyperedges: [] as [[Vertex]])
    }

    /// A hypergraph with the given hyperedges, in order, whose vertices are their members by first
    /// appearance. A member listed twice in one hyperedge is stored once.
    ///
    /// - Complexity: O(n + p log k) expected, p the number of incidences and k the largest size.
    @inlinable
    public init(hyperedges: some Sequence<some Sequence<Vertex>>) {
        self.init(vertices: [] as [Vertex], hyperedges: hyperedges)
    }

    /// A hypergraph with the given vertices, then the hyperedges in order. Members missing from
    /// `vertices` are inserted by first appearance, after the listed ones. Built in one pass: the
    /// vertex rows are laid out at their exact sizes.
    ///
    /// - Complexity: O(n + p log k) expected: one hash per listed vertex and per member, O(k) per
    ///   hyperedge already in vertex-index order and O(k log k) otherwise.
    @inlinable
    public init(vertices: some Sequence<Vertex>, hyperedges: some Sequence<some Sequence<Vertex>>) {
        var indexer = _VertexIndexer<Vertex>()
        for v in vertices { _ = indexer.index(of: v) }
        var rows = _SortedRowsBuilder(rowCapacity: hyperedges.underestimatedCount)
        for hyperedge in hyperedges {
            for v in hyperedge { rows.append(indexer.index(of: v)) }
            rows.endRow()
        }
        let set = indexer.vertices()
        let (offsets, members) = rows.finish()
        self.init(_uncheckedVertices: set, plane: _IncidencePlane(vertexCount: set.count, offsets: offsets, members: members))
    }

    /// A copy of any hypergraph: its vertices in order, isolated ones included, and its
    /// hyperedges at their positions, in order. Converting an `UndirectedIncidenceList` returns it
    /// unchanged.
    ///
    /// - Complexity: O(n + p log k), with no vertex hashed per member when `hypergraph` has vertex
    ///   indices; one hash per member otherwise.
    @inlinable
    public init(_ hypergraph: some Hypergraph<Vertex>) {
        if let same = hypergraph as? UndirectedIncidenceList {
            self = same
            return
        }
        // The vertices are distinct (the protocol's law).
        let set = OrderedSet(uncheckedUniqueElements: hypergraph.vertices)
        var rows = _SortedRowsBuilder(rowCapacity: hypergraph.hyperedgeCount)
        let indexed = hypergraph.vertexIndexBound == set.count
        for position in hypergraph.hyperedges.indices {
            if indexed {
                for i in hypergraph.memberIndices(ofHyperedgeAt: position) { rows.append(i) }
            } else {
                for v in hypergraph.members(ofHyperedgeAt: position) {
                    guard let i = set.firstIndex(of: v) else { preconditionFailure("A member of hyperedge \(position) is not a vertex") }
                    rows.append(i)
                }
            }
            rows.endRow()
        }
        let (offsets, members) = rows.finish()
        self.init(_uncheckedVertices: set, plane: _IncidencePlane(vertexCount: set.count, offsets: offsets, members: members))
    }
}

// MARK: - Mutation

extension UndirectedIncidenceList {
    /// Inserts `vertex` if it is not a vertex yet, at the next index.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the hypergraph equal to it.
    /// - Complexity: O(1) expected, amortized.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        let (inserted, index) = _vertices.append(vertex)
        if inserted { _plane.appendVertex() }
        return (inserted, _vertices[index])
    }

    /// Appends a hyperedge with `members`, inserting the members that are not vertices yet, by
    /// first appearance (XGI's `add_edge`). A member listed twice is stored once; an empty
    /// sequence appends an empty hyperedge.
    ///
    /// - Returns: The new hyperedge's position, the old `hyperedgeCount`.
    /// - Complexity: O(k log k) expected, amortized; O(k) when the members come in vertex-index
    ///   order.
    @inlinable
    @discardableResult
    public mutating func insert(hyperedge members: some Sequence<Vertex>) -> Int {
        var row: [Int] = []
        for v in members {
            let (inserted, index) = _vertices.append(v)
            if inserted { _plane.appendVertex() }
            row.append(index)
        }
        _sortUnique(&row)
        let position = _plane.hyperedgeCount
        _plane.appendHyperedge(row)
        return position
    }

    /// Appends a hyperedge with `members` if every member is already a vertex; otherwise changes
    /// nothing.
    ///
    /// - Returns: The new hyperedge's position, or `nil` when a member is not a vertex.
    /// - Complexity: O(k log k) expected, one hash per member.
    @inlinable
    @discardableResult
    public mutating func insert(safe members: some Sequence<Vertex>) -> Int? {
        var row: [Int] = []
        for v in members {
            guard let index = _vertices.firstIndex(of: v) else { return nil }
            row.append(index)
        }
        _sortUnique(&row)
        let position = _plane.hyperedgeCount
        _plane.appendHyperedge(row)
        return position
    }

    /// Removes every vertex and hyperedge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _plane.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves storage for `vertexCount` vertices, `hyperedgeCount` hyperedges and
    /// `incidenceCount` memberships in all.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, incidenceCount: Int) {
        _vertices.reserveCapacity(vertexCount)
        _plane.reserveCapacity(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount, incidenceCount: incidenceCount)
    }
}

// MARK: - Views of the storage

extension UndirectedIncidenceList {
    /// The members of one hyperedge, in vertex-index order: its stored row of vertex indices read
    /// through the vertices, so no vertex is hashed. Random access, O(1) per element.
    @frozen
    public struct Members: RandomAccessCollection {
        @usableFromInline internal let _indices: ArraySlice<Int>
        @usableFromInline internal let _vertices: [Vertex]

        @inlinable
        internal init(_indices: ArraySlice<Int>, _vertices: [Vertex]) {
            self._indices = _indices
            self._vertices = _vertices
        }

        @inlinable public var startIndex: Int { _indices.startIndex }
        @inlinable public var endIndex: Int { _indices.endIndex }
        @inlinable public var count: Int { _indices.count }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }
        @inlinable public subscript(position: Int) -> Vertex { _vertices[_indices[position]] }
    }

    /// Every hyperedge, as its `Members`, at positions `0..<hyperedgeCount`.
    @frozen
    public struct Hyperedges: RandomAccessCollection {
        @usableFromInline internal let _plane: _IncidencePlane
        @usableFromInline internal let _vertices: [Vertex]

        @inlinable
        internal init(_plane: _IncidencePlane, _vertices: [Vertex]) {
            self._plane = _plane
            self._vertices = _vertices
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _plane.hyperedgeCount }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }
        @inlinable public subscript(position: Int) -> Members {
            Members(_indices: _plane.memberIndices(of: position), _vertices: _vertices)
        }
    }
}

// MARK: - Reads

extension UndirectedIncidenceList {
    /// The index of `vertex`, trapping with a message when it is not a vertex. One hash.
    @inlinable
    internal func _index(of vertex: Vertex) -> Int {
        guard let index = _vertices.firstIndex(of: vertex) else {
            preconditionFailure("\(vertex) is not a vertex of the hypergraph")
        }
        return index
    }

    /// The vertices, in index order. O(1).
    @inlinable
    public var vertices: OrderedSet<Vertex> { _vertices }

    /// Every hyperedge at its position. O(1).
    @inlinable
    public var hyperedges: Hyperedges { Hyperedges(_plane: _plane, _vertices: _vertices.elements) }

    /// The number of vertices. O(1).
    @inlinable
    public var vertexCount: Int { _vertices.count }

    /// The number of hyperedges, repeated and empty ones included. O(1).
    @inlinable
    public var hyperedgeCount: Int { _plane.hyperedgeCount }

    /// The members of the hyperedge at `position`, in vertex-index order. O(1), no hashing.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func members(ofHyperedgeAt position: Int) -> Members {
        Members(_indices: _plane.memberIndices(of: position), _vertices: _vertices.elements)
    }

    /// The vertex indices of the hyperedge at `position`, ascending: its stored row. O(1).
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func memberIndices(ofHyperedgeAt position: Int) -> ArraySlice<Int> {
        _plane.memberIndices(of: position)
    }

    /// The number of members of the hyperedge at `position`. O(1).
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func size(ofHyperedgeAt position: Int) -> Int {
        _plane.size(of: position)
    }

    /// The positions of the hyperedges `vertex` is a member of, ascending. O(1) expected: one
    /// hash, then the stored row.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func incidentHyperedges(of vertex: Vertex) -> ArraySlice<Int> {
        incidentHyperedges(ofIndex: _index(of: vertex))
    }

    /// The positions of the hyperedges the vertex at `index` is a member of, ascending. O(1), no
    /// hashing.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func incidentHyperedges(ofIndex index: Int) -> ArraySlice<Int> {
        _plane.hyperedgeRow(index)
    }

    /// `incidentHyperedges(of:)`, or `nil` when `vertex` is not a vertex. One hash.
    @inlinable
    public func incidentHyperedges(safe vertex: Vertex) -> ArraySlice<Int>? {
        guard let index = _vertices.firstIndex(of: vertex) else { return nil }
        return incidentHyperedges(ofIndex: index)
    }

    /// The number of hyperedges `vertex` is a member of. O(1) expected.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        _plane.degree(_index(of: vertex))
    }

    /// The number of hyperedges the vertex at `index` is a member of. O(1).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        _plane.degree(index)
    }

    /// `degree(of:)`, or `nil` when `vertex` is not a vertex. One hash.
    @inlinable
    public func degree(safe vertex: Vertex) -> Int? {
        guard let index = _vertices.firstIndex(of: vertex) else { return nil }
        return _plane.degree(index)
    }

    /// Whether `vertex` is a vertex. O(1) expected.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _vertices.contains(vertex)
    }

    /// Whether some hyperedge has exactly the members of `members`, ignoring their order and
    /// repeats; for an empty sequence, whether there is an empty hyperedge. False, without
    /// trapping, when a member is not a vertex.
    ///
    /// - Complexity: O(k log k) expected (one hash per member) plus O(d · k): the rows at the first
    ///   member's d hyperedges are compared. The empty set scans the m hyperedges.
    @inlinable
    public func contains(hyperedge members: some Sequence<Vertex>) -> Bool {
        var wanted: [Int] = []
        for v in members {
            guard let index = _vertices.firstIndex(of: v) else { return false }
            wanted.append(index)
        }
        _sortUnique(&wanted)
        guard let first = wanted.first else {
            for p in 0 ..< _plane.hyperedgeCount where _plane.size(of: p) == 0 { return true }
            return false
        }
        for p in _plane.hyperedgeRow(first) where _plane.memberIndices(of: p).elementsEqual(wanted) {
            return true
        }
        return false
    }

    /// `vertexCount`: the indices are always dense.
    @inlinable
    public var vertexIndexBound: Int? { _vertices.count }

    /// The index of `vertex`. O(1) expected.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int {
        _index(of: vertex)
    }

    /// The index of `vertex`, or `nil` when it is not a vertex. One hash.
    @inlinable
    public func vertexIndex(safe vertex: Vertex) -> Int? {
        _vertices.firstIndex(of: vertex)
    }

    /// The vertex at `index`. O(1).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        precondition(index >= 0 && index < _vertices.count, "Vertex index \(index) is out of range 0..<\(_vertices.count)")
        return _vertices[index]
    }

    /// `hyperedgeCount`: the positions are the indices.
    @inlinable
    public var hyperedgeIndexBound: Int? { _plane.hyperedgeCount }

    /// `position` itself.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func hyperedgeIndex(of position: Int) -> Int {
        _plane.checkHyperedge(position)
        return position
    }

    /// `incidentHyperedges(ofIndex:)`: the positions are the indices. O(1), no hashing.
    @inlinable
    public func incidentHyperedgeIndices(ofIndex index: Int) -> ArraySlice<Int> {
        _plane.hyperedgeRow(index)
    }

    /// The stored members, run through directly.
    @inlinable
    public func _forEachMemberIndex(ofHyperedgeAt position: Int, _ body: (Int) -> Void) {
        let range = _plane.range(of: position)
        _plane.members.withUnsafeBufferPointer { members in
            for q in range { body(members[q]) }
        }
    }

    /// The storage, lent. O(1).
    @inlinable
    public func _withIncidenceRows<Result>(
        _ body: (
            _ memberOffsets: UnsafeBufferPointer<Int>, _ members: UnsafeBufferPointer<Int>,
            _ incidences: UnsafeBufferPointer<Int>, _ incidenceRows: UnsafeBufferPointer<Int>,
            _ hyperedges: UnsafeBufferPointer<Int>, _ hyperedgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result {
        _plane.withIncidenceRows(body)
    }
}

extension UndirectedIncidenceList: Hypergraph {}

// MARK: - Equatable, Hashable

extension UndirectedIncidenceList: Equatable {
    /// Equal when the vertex sets are equal and the hyperedges are equal as a multiset of member
    /// sets, whatever the vertex order and the hyperedge order (the representations' rule).
    ///
    /// - Complexity: O(n) expected to match the vertices (one hash each, none when both list
    ///   them in the same order), then O(p log m) index comparisons to match the hyperedges.
    @inlinable
    public static func == (lhs: UndirectedIncidenceList, rhs: UndirectedIncidenceList) -> Bool {
        let n = lhs._vertices.count
        guard n == rhs._vertices.count, lhs._plane.hyperedgeCount == rhs._plane.hyperedgeCount,
              lhs._plane.incidenceCount == rhs._plane.incidenceCount
        else { return false }
        if lhs._vertices.elements == rhs._vertices.elements {
            if lhs._plane.memberOffsets == rhs._plane.memberOffsets, lhs._plane.members == rhs._plane.members { return true }
            return _sameRowMultiset(lhs._plane.rows(), rhs._plane.rows())
        }
        var toLeft = [Int](repeating: 0, count: n)
        for (i, v) in rhs._vertices.enumerated() {
            guard let j = lhs._vertices.firstIndex(of: v) else { return false }
            toLeft[i] = j
        }
        let mapped = rhs._plane.rows().map { row in row.map { toLeft[$0] }.sorted() }
        return _sameRowMultiset(lhs._plane.rows(), mapped)
    }
}

/// A 64-bit mix (splitmix64's finalizer), so sums of hash values stay well spread.
@inlinable
@inline(__always)
package func _mixHash(_ value: Int) -> UInt {
    var z = UInt64(UInt(bitPattern: value)) &+ 0x9E37_79B9_7F4A_7C15
    z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
    return UInt(truncatingIfNeeded: z ^ (z &>> 31))
}

extension UndirectedIncidenceList: Hashable {
    /// A hash that ignores the vertex order and the hyperedge order, so equal hypergraphs hash
    /// alike: the counts, the sum of the vertices' hash values, and the sum over the hyperedges of
    /// an order-free hash of their members' hash values. Each vertex is hashed once. O(n + p).
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_vertices.count)
        hasher.combine(_plane.hyperedgeCount)
        var vertexHashes: [UInt] = []
        vertexHashes.reserveCapacity(_vertices.count)
        var vertexSum: UInt = 0
        for v in _vertices {
            let h = _mixHash(v.hashValue)
            vertexHashes.append(h)
            vertexSum &+= h
        }
        var hyperedgeSum: UInt = 0
        for p in 0 ..< _plane.hyperedgeCount {
            var memberSum: UInt = 0
            for i in _plane.memberIndices(of: p) { memberSum &+= vertexHashes[i] }
            hyperedgeSum &+= _mixHash(Int(bitPattern: memberSum &+ UInt(bitPattern: _plane.size(of: p))))
        }
        hasher.combine(vertexSum)
        hasher.combine(hyperedgeSum)
    }
}

// MARK: - Sendable

extension UndirectedIncidenceList: Sendable where Vertex: Sendable {}
extension UndirectedIncidenceList.Members: Sendable where Vertex: Sendable {}
extension UndirectedIncidenceList.Hyperedges: Sendable where Vertex: Sendable {}

// MARK: - Codable

extension UndirectedIncidenceList: Codable where Vertex: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertices
        case hyperedges
    }

    /// Encodes `{"vertices": [v₀, v₁, …], "hyperedges": [[i, …], …]}`: the vertices in index
    /// order, and each hyperedge, by position, as its ascending vertex indices. A round trip keeps
    /// the vertex order and the positions.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        try container.encode(_plane.rows(), forKey: .hyperedges)
    }

    /// Decodes the form `encode(to:)` writes, throwing `DecodingError.dataCorrupted` for a repeated
    /// vertex, a member index out of range, or a hyperedge whose indices are not strictly
    /// ascending (which covers a repeated member: the encoder never writes one).
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let vertexList = try container.decode([Vertex].self, forKey: .vertices)
        let set = OrderedSet(vertexList)
        guard set.count == vertexList.count else {
            throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
        }
        let rows = try container.decode([[Int]].self, forKey: .hyperedges)
        var offsets: ContiguousArray<Int> = [0]
        var flat = ContiguousArray<Int>()
        for row in rows {
            var previous = -1
            for i in row {
                guard i >= 0, i < set.count else {
                    throw DecodingError.dataCorruptedError(forKey: .hyperedges, in: container, debugDescription: "Member index \(i) is out of range 0..<\(set.count)")
                }
                guard i > previous else {
                    throw DecodingError.dataCorruptedError(forKey: .hyperedges, in: container, debugDescription: "Members are not strictly ascending")
                }
                previous = i
                flat.append(i)
            }
            offsets.append(flat.count)
        }
        self.init(_uncheckedVertices: set, plane: _IncidencePlane(vertexCount: set.count, offsets: offsets, members: flat))
    }
}

// MARK: - Descriptions

extension UndirectedIncidenceList: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices and the hyperedges, at most 16 of each, each vertex as `String(reflecting:)`
    /// writes it: `["a", "b", "c"]; [{"a", "b"}, {}, {"b", "c"}]`.
    public var description: String {
        GraphDescription.list(_vertices, count: _vertices.count) { GraphDescription.vertex($0) }
            + "; "
            + GraphDescription.list(hyperedges, count: hyperedgeCount) { members in
                "{" + members.map { GraphDescription.vertex($0) }.joined(separator: ", ") + "}"
            }
    }

    /// The type, the counts, then the same lists:
    /// `UndirectedIncidenceList<String>(vertexCount: 3, hyperedgeCount: 3, vertices: […], hyperedges: […])`.
    public var debugDescription: String {
        "UndirectedIncidenceList<\(Vertex.self)>(vertexCount: \(vertexCount), hyperedgeCount: \(hyperedgeCount), vertices: "
            + GraphDescription.list(_vertices, count: _vertices.count) { GraphDescription.vertex($0) }
            + ", hyperedges: "
            + GraphDescription.list(hyperedges, count: hyperedgeCount) { members in
                "{" + members.map { GraphDescription.vertex($0) }.joined(separator: ", ") + "}"
            }
            + ")"
    }
}
