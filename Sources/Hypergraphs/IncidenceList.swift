import GraphProtocols
import OrderedCollections

/// A directed hypergraph stored as an incidence list: each hyperedge's sources and targets, and
/// each vertex's out- and in-hyperedges (Gallo's forward and backward stars), as two planes of
/// `UndirectedIncidenceList`'s storage. Unprefixed, as `AdjacencyList` is the directed one of its
/// pair. (`OrientedIncidenceMatrix` is the matrix form; `IncidenceMatrix` is undirected, because
/// "oriented incidence matrix" is the established name.)
///
/// The vertices are any `Hashable` values, kept in an `OrderedSet` whose element `i` is vertex
/// index `i`: the listed vertices first, then each new hyperedge's sources, then its targets, by
/// first appearance. A hyperedge is an ordered pair of vertex sets. Either side may be empty, and
/// a vertex may be on both (a self-loop's hypergraph form; Gallo et al. require disjoint sides,
/// XGI's `DiHypergraph` does not). Repeated hyperedges are kept at their own positions. Each side
/// is stored in vertex-index order.
///
/// The source plane holds every hyperedge's sources and every vertex's out-hyperedges, the target
/// plane the targets and the in-hyperedges, so both stars are stored rows and `reversed` swaps the
/// planes in O(1). Every vertex-space read hashes its vertex once; index-space reads and the
/// `Hypergraphs` algorithms hash none. Hyperedges can be appended but not removed. Equality
/// ignores the order of the vertices and of the hyperedges.
@frozen
public struct IncidenceList<Vertex: Hashable> {
    /// The vertices; element `i` is vertex index `i`.
    @usableFromInline
    internal var _vertices: OrderedSet<Vertex>

    /// Hyperedge `p`'s sources; vertex `i`'s out-hyperedges.
    @usableFromInline
    internal var _sources: _IncidencePlane

    /// Hyperedge `p`'s targets; vertex `i`'s in-hyperedges.
    @usableFromInline
    internal var _targets: _IncidencePlane

    /// The hypergraph with no vertices and no hyperedges.
    @inlinable
    public init() {
        _vertices = []
        _sources = _IncidencePlane()
        _targets = _IncidencePlane()
    }

    @inlinable
    internal init(_uncheckedVertices vertices: OrderedSet<Vertex>, sources: _IncidencePlane, targets: _IncidencePlane) {
        _vertices = vertices
        _sources = sources
        _targets = targets
    }
}

// MARK: - Construction

extension IncidenceList {
    /// A hypergraph with the given vertices and no hyperedges. A repeated vertex is inserted once.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for v in vertices { insert(v) }
    }

    /// A hypergraph with the given hyperedges, in order, whose vertices are their sources and
    /// targets by first appearance (each hyperedge's sources before its targets).
    ///
    /// - Complexity: O(n + p log k) expected, p the number of incidences on both sides.
    @inlinable
    public init<S: Sequence, T: Sequence>(hyperedges: some Sequence<(sources: S, targets: T)>)
        where S.Element == Vertex, T.Element == Vertex {
        self.init(vertices: [] as [Vertex], hyperedges: hyperedges)
    }

    /// A hypergraph with the given vertices, then the hyperedges in order; vertices missing from
    /// `vertices` are inserted by first appearance, sources before targets. Built in one pass: the
    /// vertex rows are laid out at their exact sizes.
    ///
    /// - Complexity: O(n + p log k) expected: one hash per listed vertex and per side member.
    @inlinable
    public init<S: Sequence, T: Sequence>(vertices: some Sequence<Vertex>, hyperedges: some Sequence<(sources: S, targets: T)>)
        where S.Element == Vertex, T.Element == Vertex {
        var indexer = _VertexIndexer<Vertex>()
        for v in vertices { _ = indexer.index(of: v) }
        var sourceRows = _SortedRowsBuilder(rowCapacity: hyperedges.underestimatedCount)
        var targetRows = _SortedRowsBuilder(rowCapacity: hyperedges.underestimatedCount)
        for hyperedge in hyperedges {
            for v in hyperedge.sources { sourceRows.append(indexer.index(of: v)) }
            sourceRows.endRow()
            for v in hyperedge.targets { targetRows.append(indexer.index(of: v)) }
            targetRows.endRow()
        }
        let set = indexer.vertices()
        self.init(_uncheckedVertices: set,
                  sources: _IncidencePlane(vertexCount: set.count, offsets: sourceRows.offsets, members: sourceRows.finish().members),
                  targets: _IncidencePlane(vertexCount: set.count, offsets: targetRows.offsets, members: targetRows.finish().members))
    }

    /// A copy of any directed hypergraph: its vertices in order and its hyperedges at their
    /// positions. Converting an `IncidenceList` returns it unchanged.
    ///
    /// - Complexity: O(n + p log k), with no vertex hashed per member when `hypergraph` has vertex
    ///   indices.
    @inlinable
    public init(_ hypergraph: some DirectedHypergraph<Vertex>) {
        self.init(_copying: hypergraph)
    }

    @inlinable
    internal init(_copying hypergraph: some DirectedHypergraph<Vertex>) {
        if let same = hypergraph as? IncidenceList {
            self = same
            return
        }
        // The vertices are distinct (the protocol's law).
        let set = OrderedSet(uncheckedUniqueElements: hypergraph.vertices)
        let indexed = hypergraph.vertexIndexBound == set.count
        var sourceRows = _SortedRowsBuilder(rowCapacity: hypergraph.hyperedgeCount)
        var targetRows = _SortedRowsBuilder(rowCapacity: hypergraph.hyperedgeCount)
        for position in hypergraph.hyperedges.indices {
            if indexed {
                for i in hypergraph.sourceIndices(ofHyperedgeAt: position) { sourceRows.append(i) }
                for i in hypergraph.targetIndices(ofHyperedgeAt: position) { targetRows.append(i) }
            } else {
                for v in hypergraph.sources(ofHyperedgeAt: position) {
                    guard let i = set.firstIndex(of: v) else { preconditionFailure("A vertex of hyperedge \(position) is not a vertex") }
                    sourceRows.append(i)
                }
                for v in hypergraph.targets(ofHyperedgeAt: position) {
                    guard let i = set.firstIndex(of: v) else { preconditionFailure("A vertex of hyperedge \(position) is not a vertex") }
                    targetRows.append(i)
                }
            }
            sourceRows.endRow()
            targetRows.endRow()
        }
        self.init(_uncheckedVertices: set,
                  sources: _IncidencePlane(vertexCount: set.count, offsets: sourceRows.offsets, members: sourceRows.finish().members),
                  targets: _IncidencePlane(vertexCount: set.count, offsets: targetRows.offsets, members: targetRows.finish().members))
    }

    /// The directed graph as a directed hypergraph: its vertices in order, and each edge, in
    /// `edges` order, as the hyperedge with one source and one target (a self-loop has its vertex
    /// on both sides). On such a hypergraph B- and F-connection are reachability.
    ///
    /// - Complexity: O(n + m) expected.
    @inlinable
    public init(_ graph: some DirectedGraph<Vertex>) {
        self.init(vertices: graph.vertices, hyperedges: graph.edges.lazy.map { (sources: CollectionOfOne($0.source), targets: CollectionOfOne($0.target)) })
    }

    /// The one hypergraph conversion for a type that is both a directed graph and a directed
    /// hypergraph: read as a hypergraph.
    @inlinable
    public init<H: DirectedHypergraph & DirectedGraph>(_ hypergraph: H) where H.Vertex == Vertex {
        self.init(_copying: hypergraph)
    }
}

// MARK: - Mutation

extension IncidenceList {
    /// Inserts `vertex` if it is not a vertex yet, at the next index.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the hypergraph equal to it.
    /// - Complexity: O(1) expected, amortized.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        let (inserted, index) = _vertices.append(vertex)
        if inserted {
            _sources.appendVertex()
            _targets.appendVertex()
        }
        return (inserted, _vertices[index])
    }

    @inlinable
    internal mutating func _appendIndex(of vertex: Vertex) -> Int {
        let (inserted, index) = _vertices.append(vertex)
        if inserted {
            _sources.appendVertex()
            _targets.appendVertex()
        }
        return index
    }

    /// Appends the hyperedge `sources` → `targets`, inserting the vertices that are not vertices
    /// yet, sources first, by first appearance. A vertex listed twice on one side is stored once
    /// there; either side may be empty, and a vertex may be on both.
    ///
    /// - Returns: The new hyperedge's position, the old `hyperedgeCount`.
    /// - Complexity: O(k log k) expected, amortized, k the larger side.
    @inlinable
    @discardableResult
    public mutating func insert(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Int {
        var sourceRow: [Int] = []
        for v in sources { sourceRow.append(_appendIndex(of: v)) }
        var targetRow: [Int] = []
        for v in targets { targetRow.append(_appendIndex(of: v)) }
        _sortUnique(&sourceRow)
        _sortUnique(&targetRow)
        let position = _sources.hyperedgeCount
        _sources.appendHyperedge(sourceRow)
        _targets.appendHyperedge(targetRow)
        return position
    }

    /// Appends the hyperedge `sources` → `targets` if every one is already a vertex; otherwise
    /// throws and changes nothing.
    ///
    /// - Returns: The new hyperedge's position, the old `hyperedgeCount`.
    /// - Throws: `VertexNotFound` when one is not a vertex.
    /// - Complexity: O(k log k) expected, one hash per vertex listed.
    @inlinable
    @discardableResult
    public mutating func insert(checked sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) throws(VertexNotFound) -> Int {
        var sourceRow: [Int] = []
        for v in sources {
            guard let index = _vertices.firstIndex(of: v) else { throw VertexNotFound() }
            sourceRow.append(index)
        }
        var targetRow: [Int] = []
        for v in targets {
            guard let index = _vertices.firstIndex(of: v) else { throw VertexNotFound() }
            targetRow.append(index)
        }
        _sortUnique(&sourceRow)
        _sortUnique(&targetRow)
        let position = _sources.hyperedgeCount
        _sources.appendHyperedge(sourceRow)
        _targets.appendHyperedge(targetRow)
        return position
    }

    /// Removes every vertex and hyperedge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _sources.removeAll(keepingCapacity: keepingCapacity)
        _targets.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves storage for `vertexCount` vertices, `hyperedgeCount` hyperedges, and
    /// `sourceCount` and `targetCount` incidences on each side in all.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, sourceCount: Int, targetCount: Int) {
        _vertices.reserveCapacity(vertexCount)
        _sources.reserveCapacity(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount, incidenceCount: sourceCount)
        _targets.reserveCapacity(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount, incidenceCount: targetCount)
    }

    /// Every hyperedge with its sources and targets swapped: Gallo et al.'s symmetric image. An
    /// involution. O(1): the planes are swapped.
    @inlinable
    public var reversed: IncidenceList {
        IncidenceList(_uncheckedVertices: _vertices, sources: _targets, targets: _sources)
    }
}

// MARK: - Views of the storage

extension IncidenceList {
    /// One side of a hyperedge, in vertex-index order. See `UndirectedIncidenceList.Members`.
    public typealias Members = UndirectedIncidenceList<Vertex>.Members


    /// Every hyperedge, as its sources and targets, at positions `0..<hyperedgeCount`.
    @frozen
    public struct Hyperedges: RandomAccessCollection {
        @usableFromInline internal let _sources: _IncidencePlane
        @usableFromInline internal let _targets: _IncidencePlane
        @usableFromInline internal let _vertices: [Vertex]

        @inlinable
        internal init(_sources: _IncidencePlane, _targets: _IncidencePlane, _vertices: [Vertex]) {
            self._sources = _sources
            self._targets = _targets
            self._vertices = _vertices
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _sources.hyperedgeCount }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }
        @inlinable public subscript(position: Int) -> (sources: Members, targets: Members) {
            (Members(_indices: _sources.memberIndices(of: position), _vertices: _vertices),
             Members(_indices: _targets.memberIndices(of: position), _vertices: _vertices))
        }
    }
}

// MARK: - Reads

extension IncidenceList {
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
    public var hyperedges: Hyperedges { Hyperedges(_sources: _sources, _targets: _targets, _vertices: _vertices.elements) }

    /// The number of vertices. O(1).
    @inlinable
    public var vertexCount: Int { _vertices.count }

    /// The number of hyperedges. O(1).
    @inlinable
    public var hyperedgeCount: Int { _sources.hyperedgeCount }

    /// The sources of the hyperedge at `position`, in vertex-index order. O(1), no hashing.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func sources(ofHyperedgeAt position: Int) -> Members {
        Members(_indices: _sources.memberIndices(of: position), _vertices: _vertices.elements)
    }

    /// The targets of the hyperedge at `position`, in vertex-index order. O(1), no hashing.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func targets(ofHyperedgeAt position: Int) -> Members {
        Members(_indices: _targets.memberIndices(of: position), _vertices: _vertices.elements)
    }

    /// The vertex indices of the sources of the hyperedge at `position`, ascending. O(1).
    @inlinable
    public func sourceIndices(ofHyperedgeAt position: Int) -> ArraySlice<Int> {
        _sources.memberIndices(of: position)
    }

    /// The vertex indices of the targets of the hyperedge at `position`, ascending. O(1).
    @inlinable
    public func targetIndices(ofHyperedgeAt position: Int) -> ArraySlice<Int> {
        _targets.memberIndices(of: position)
    }

    /// The positions of the hyperedges with `vertex` among their sources, ascending: FS(v). O(1)
    /// expected.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func outHyperedges(of vertex: Vertex) -> ArraySlice<Int> {
        outHyperedges(ofIndex: _index(of: vertex))
    }

    /// The positions of the hyperedges with `vertex` among their targets, ascending: BS(v). O(1)
    /// expected.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func inHyperedges(of vertex: Vertex) -> ArraySlice<Int> {
        inHyperedges(ofIndex: _index(of: vertex))
    }

    /// `outHyperedges(of: vertex(atIndex: index))`. O(1), no hashing.
    @inlinable
    public func outHyperedges(ofIndex index: Int) -> ArraySlice<Int> {
        _sources.hyperedgeRow(index)
    }

    /// `inHyperedges(of: vertex(atIndex: index))`. O(1), no hashing.
    @inlinable
    public func inHyperedges(ofIndex index: Int) -> ArraySlice<Int> {
        _targets.hyperedgeRow(index)
    }

    /// `outHyperedges(of:)`, throwing instead of trapping when `vertex` is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outHyperedges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let index = _vertices.firstIndex(of: vertex) else { throw VertexNotFound() }
        return outHyperedges(ofIndex: index)
    }

    /// `inHyperedges(of:)`, throwing instead of trapping when `vertex` is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inHyperedges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let index = _vertices.firstIndex(of: vertex) else { throw VertexNotFound() }
        return inHyperedges(ofIndex: index)
    }

    /// The number of hyperedges with `vertex` among their sources. O(1) expected.
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int { _sources.degree(_index(of: vertex)) }

    /// The number of hyperedges with `vertex` among their targets. O(1) expected.
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int { _targets.degree(_index(of: vertex)) }

    /// `outDegree + inDegree`: a vertex on both sides of a hyperedge counts it twice. O(1)
    /// expected, one hash.
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        let index = _index(of: vertex)
        return _sources.degree(index) &+ _targets.degree(index)
    }

    /// `outDegree(of:)`, throwing instead of trapping when `vertex` is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let index = _vertices.firstIndex(of: vertex) else { throw VertexNotFound() }
        return _sources.degree(index)
    }

    /// `inDegree(of:)`, throwing instead of trapping when `vertex` is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let index = _vertices.firstIndex(of: vertex) else { throw VertexNotFound() }
        return _targets.degree(index)
    }

    /// `degree(of:)`, throwing instead of trapping when `vertex` is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let index = _vertices.firstIndex(of: vertex) else { throw VertexNotFound() }
        return _sources.degree(index) &+ _targets.degree(index)
    }

    /// The out-degree of the vertex at `index`. O(1).
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { _sources.degree(index) }

    /// The in-degree of the vertex at `index`. O(1).
    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { _targets.degree(index) }

    /// Whether `vertex` is a vertex. O(1) expected.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool { _vertices.contains(vertex) }

    /// Whether some hyperedge has exactly these sources and these targets, ignoring order and
    /// repeats within each. False, without trapping, when one is not a vertex.
    ///
    /// - Complexity: O(k log k) expected (one hash per vertex listed) plus O(d · k): the rows at
    ///   one listed vertex's d hyperedges are compared. The empty pair scans the m hyperedges.
    @inlinable
    public func contains(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Bool {
        var wantedSources: [Int] = []
        for v in sources {
            guard let index = _vertices.firstIndex(of: v) else { return false }
            wantedSources.append(index)
        }
        var wantedTargets: [Int] = []
        for v in targets {
            guard let index = _vertices.firstIndex(of: v) else { return false }
            wantedTargets.append(index)
        }
        _sortUnique(&wantedSources)
        _sortUnique(&wantedTargets)
        let candidates: ArraySlice<Int>
        if let first = wantedSources.first {
            candidates = outHyperedges(ofIndex: first)
        } else if let first = wantedTargets.first {
            candidates = inHyperedges(ofIndex: first)
        } else {
            for p in 0 ..< _sources.hyperedgeCount where _sources.size(of: p) == 0 && _targets.size(of: p) == 0 { return true }
            return false
        }
        for p in candidates where _sources.memberIndices(of: p).elementsEqual(wantedSources) && _targets.memberIndices(of: p).elementsEqual(wantedTargets) {
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
    public func vertexIndex(of vertex: Vertex) -> Int { _index(of: vertex) }

    /// The index of `vertex`, throwing instead of trapping when it is not a vertex. One hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let index = _vertices.firstIndex(of: vertex) else { throw VertexNotFound() }
        return index
    }

    /// The vertex at `index`. O(1).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        _vertices[index]
    }

    /// `hyperedgeCount`: the positions are the indices.
    @inlinable
    public var hyperedgeIndexBound: Int? { _sources.hyperedgeCount }

    /// `position` itself.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func hyperedgeIndex(of position: Int) -> Int {
        _sources.checkHyperedge(position)
        return position
    }

    /// The number of sources of the hyperedge at `position`. O(1).
    @inlinable
    public func sourceSize(ofHyperedgeAt position: Int) -> Int { _sources.size(of: position) }

    /// The number of targets of the hyperedge at `position`. O(1).
    @inlinable
    public func targetSize(ofHyperedgeAt position: Int) -> Int { _targets.size(of: position) }

    /// `outHyperedges(ofIndex:)`: the positions are the indices. O(1), no hashing.
    @inlinable
    public func outHyperedgeIndices(ofIndex index: Int) -> ArraySlice<Int> { _sources.hyperedgeRow(index) }

    /// `inHyperedges(ofIndex:)`: the positions are the indices. O(1), no hashing.
    @inlinable
    public func inHyperedgeIndices(ofIndex index: Int) -> ArraySlice<Int> { _targets.hyperedgeRow(index) }

    /// The stored sides, run through directly.
    @inlinable
    public func _forEachMemberIndex(ofHyperedgeAt position: Int, _ body: (Int) -> Void) {
        let sourceRange = _sources.range(of: position), targetRange = _targets.range(of: position)
        _sources.members.withUnsafeBufferPointer { members in
            for q in sourceRange { body(members[q]) }
        }
        _targets.members.withUnsafeBufferPointer { members in
            for q in targetRange { body(members[q]) }
        }
    }
}

extension IncidenceList: DirectedHypergraph {}

// MARK: - Equatable, Hashable

extension IncidenceList: Equatable {
    /// Equal when the vertex sets are equal and the hyperedges are equal as a multiset of
    /// (source set, target set) pairs, whatever the vertex order and the hyperedge order.
    ///
    /// - Complexity: O(n) expected to match the vertices (none hashed when both list them in the
    ///   same order), then O(p log m) index comparisons.
    @inlinable
    public static func == (lhs: IncidenceList, rhs: IncidenceList) -> Bool {
        let n = lhs._vertices.count
        guard n == rhs._vertices.count, lhs._sources.hyperedgeCount == rhs._sources.hyperedgeCount,
              lhs._sources.incidenceCount == rhs._sources.incidenceCount,
              lhs._targets.incidenceCount == rhs._targets.incidenceCount
        else { return false }
        // Each hyperedge as one row: its sources, a separator −1, its targets.
        func rows(_ list: IncidenceList, _ map: (Int) -> Int) -> [[Int]] {
            (0 ..< list._sources.hyperedgeCount).map { p in
                list._sources.memberIndices(of: p).map(map).sorted() + [-1] + list._targets.memberIndices(of: p).map(map).sorted()
            }
        }
        if lhs._vertices.elements == rhs._vertices.elements {
            if lhs._sources.memberOffsets == rhs._sources.memberOffsets, lhs._sources.members == rhs._sources.members,
               lhs._targets.memberOffsets == rhs._targets.memberOffsets, lhs._targets.members == rhs._targets.members {
                return true
            }
            return _sameRowMultiset(rows(lhs) { $0 }, rows(rhs) { $0 })
        }
        var toLeft = [Int](repeating: 0, count: n)
        for (i, v) in rhs._vertices.enumerated() {
            guard let j = lhs._vertices.firstIndex(of: v) else { return false }
            toLeft[i] = j
        }
        return _sameRowMultiset(rows(lhs) { $0 }, rows(rhs) { toLeft[$0] })
    }
}

extension IncidenceList: Hashable {
    /// A hash that ignores the vertex order and the hyperedge order: the counts, the sum of the
    /// vertices' hash values, and the sum over the hyperedges of a hash of their sides' order-free
    /// member hashes. Each vertex is hashed once. O(n + p).
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_vertices.count)
        hasher.combine(_sources.hyperedgeCount)
        var vertexHashes: [UInt] = []
        vertexHashes.reserveCapacity(_vertices.count)
        var vertexSum: UInt = 0
        for v in _vertices {
            let h = _mixHash(v.hashValue)
            vertexHashes.append(h)
            vertexSum &+= h
        }
        var hyperedgeSum: UInt = 0
        for p in 0 ..< _sources.hyperedgeCount {
            var sourceSum: UInt = 0, targetSum: UInt = 0
            for i in _sources.memberIndices(of: p) { sourceSum &+= vertexHashes[i] }
            for i in _targets.memberIndices(of: p) { targetSum &+= vertexHashes[i] }
            hyperedgeSum &+= _mixHash(Int(bitPattern: _mixHash(Int(bitPattern: sourceSum &+ UInt(bitPattern: _sources.size(of: p)))) &+ targetSum))
        }
        hasher.combine(vertexSum)
        hasher.combine(hyperedgeSum)
    }
}

// MARK: - Sendable

extension IncidenceList: Sendable where Vertex: Sendable {}
extension IncidenceList.Hyperedges: Sendable where Vertex: Sendable {}

// MARK: - Codable

extension IncidenceList: Codable where Vertex: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertices
        case sources
        case targets
    }

    /// Encodes `{"vertices": [v₀, …], "sources": [[i, …], …], "targets": [[i, …], …]}`: the
    /// vertices in index order, and each hyperedge's sides, by position, as ascending vertex
    /// indices. A round trip keeps the vertex order and the positions.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        try container.encode(_sources.rows(), forKey: .sources)
        try container.encode(_targets.rows(), forKey: .targets)
    }

    /// Decodes the form `encode(to:)` writes, throwing `DecodingError.dataCorrupted` for a repeated
    /// vertex, an index out of range, a side whose indices are not strictly ascending, or `sources`
    /// and `targets` of different lengths.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let vertexList = try container.decode([Vertex].self, forKey: .vertices)
        let set = OrderedSet(vertexList)
        guard set.count == vertexList.count else {
            throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
        }
        let sourceRows = try container.decode([[Int]].self, forKey: .sources)
        let targetRows = try container.decode([[Int]].self, forKey: .targets)
        guard sourceRows.count == targetRows.count else {
            throw DecodingError.dataCorruptedError(forKey: .targets, in: container, debugDescription: "sources and targets have different lengths")
        }
        func plane(_ rows: [[Int]], _ key: _CodingKeys) throws -> _IncidencePlane {
            var offsets: ContiguousArray<Int> = [0]
            var flat = ContiguousArray<Int>()
            for row in rows {
                var previous = -1
                for i in row {
                    guard i < set.count else {
                        throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Vertex index \(i) is out of range 0..<\(set.count)")
                    }
                    guard i > previous else {
                        throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "A side is not strictly ascending")
                    }
                    previous = i
                    flat.append(i)
                }
                offsets.append(flat.count)
            }
            return _IncidencePlane(vertexCount: set.count, offsets: offsets, members: flat)
        }
        let sources = try plane(sourceRows, .sources), targets = try plane(targetRows, .targets)
        self.init(_uncheckedVertices: set, sources: sources, targets: targets)
    }
}

// MARK: - Descriptions

extension IncidenceList: CustomStringConvertible, CustomDebugStringConvertible {
    internal var _hyperedgesDescription: String {
        GraphDescription.list(hyperedges, count: hyperedgeCount) { hyperedge in
            "{" + hyperedge.sources.map { GraphDescription.vertex($0) }.joined(separator: ", ") + "}→{"
                + hyperedge.targets.map { GraphDescription.vertex($0) }.joined(separator: ", ") + "}"
        }
    }

    /// The vertices and the hyperedges, at most 16 of each: `["a", "b", "c"]; [{"a", "b"}→{"c"}, {}→{}]`.
    public var description: String {
        GraphDescription.list(_vertices, count: _vertices.count) { GraphDescription.vertex($0) } + "; " + _hyperedgesDescription
    }

    /// The type, the counts, then the same lists:
    /// `IncidenceList<String>(vertexCount: 3, hyperedgeCount: 2, vertices: […], hyperedges: […])`.
    public var debugDescription: String {
        "IncidenceList<\(Vertex.self)>(vertexCount: \(vertexCount), hyperedgeCount: \(hyperedgeCount), vertices: "
            + GraphDescription.list(_vertices, count: _vertices.count) { GraphDescription.vertex($0) }
            + ", hyperedges: " + _hyperedgesDescription + ")"
    }
}
