import BitCollections
import GraphProtocols

/// The oriented incidence matrix of a directed hypergraph: entry (v, p) is −1 when `v` is a source
/// of column `p`, +1 when it is a target, and 0 otherwise. Gallo, Longo, Pallottino and Nguyen
/// (1993) define a directed hypergraph's matrix this way (aᵢⱼ = −1 for a tail node, 1 for a head
/// node); a directed graph's edge is the column with one source and one target, the matrix of
/// spectral graph theory (B·Bᵀ = L, Godsil–Royle §8.3) and NetworkX's
/// `incidence_matrix(oriented=True)`. It conforms to `DirectedHypergraph`, so the `Hypergraphs`
/// algorithms (B- and F-connection, components, the clique expansion) run on it unchanged; it is
/// not a `DirectedGraph`.
///
/// **Two bit planes.** The sources and the targets are each an `IncidenceMatrix`, as
/// SimpleDirectedHypergraphs.jl keeps two matrices, so a vertex can be on both sides of a column.
/// Its entry is then target − source = **0**, with both bits kept: `sources(ofHyperedgeAt:)`,
/// `targets(ofHyperedgeAt:)`, the stars and equality read the planes, so nothing is lost. A
/// directed self-loop is such a column, and its zero matches NetworkX's oriented loop column and
/// HyperGraphs.jl's `−1 + 1`. `reversed` swaps the planes (every entry negated) and `transposed()`
/// transposes each (the dual), both in O(1).
///
/// Storage is 4·n·m/8 bytes, so, as for `IncidenceMatrix`, this is for dense or small incidence;
/// `IncidenceList` is the sparse representation. Equality compares both planes cell for cell, with
/// equal shape, and column order counts.
@frozen
public struct OrientedIncidenceMatrix {
    /// The source plane: cell (v, p) set when `v` is a source of `p`.
    @usableFromInline internal var _sources: IncidenceMatrix
    /// The target plane.
    @usableFromInline internal var _targets: IncidenceMatrix
    /// The attached vertex maps (`addVertexMap(default:)`): dense, one value per row. The planes'
    /// own maps stay empty.
    @usableFromInline internal var _vertexMaps: _AttachedMaps
    /// The attached hyperedge maps (`addEdgeMap(default:)`): dense, one value per column.
    @usableFromInline internal var _edgeMaps: _AttachedMaps
    /// The generation, advanced by every structural mutation. The planes' stay unadvanced.
    @usableFromInline internal var _generation: _GenerationStamp

    /// The matrix with no vertices and no columns.
    @inlinable
    public init() {
        self.init(_sources: IncidenceMatrix(), _targets: IncidenceMatrix())
    }

    @inlinable
    internal init(_sources: IncidenceMatrix, _targets: IncidenceMatrix) {
        self._sources = _sources
        self._targets = _targets
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
    }
}

// MARK: - Construction

extension OrientedIncidenceMatrix {
    /// A matrix of `vertexCount` vertices and no columns.
    ///
    /// - Precondition: `vertexCount >= 0`.
    @inlinable
    public init(vertexCount: Int) {
        self.init(_sources: IncidenceMatrix(vertexCount: vertexCount), _targets: IncidenceMatrix(vertexCount: vertexCount))
    }

    /// A matrix of `vertexCount` vertices with one column per hyperedge, in order. Either side may
    /// be empty, and a vertex may be on both.
    ///
    /// - Precondition: `vertexCount >= 0`, and every vertex listed is in `0..<vertexCount`.
    /// - Complexity: O(n·⌈m/64⌉ + m·⌈n/64⌉ + p).
    @inlinable
    public init<S: Sequence, T: Sequence>(vertexCount: Int, hyperedges: some Sequence<(sources: S, targets: T)>)
        where S.Element == Int, T.Element == Int {
        var sources: [[Int]] = [], targets: [[Int]] = []
        for hyperedge in hyperedges {
            sources.append(Array(hyperedge.sources))
            targets.append(Array(hyperedge.targets))
        }
        self.init(_sources: IncidenceMatrix(vertexCount: vertexCount, hyperedges: sources), _targets: IncidenceMatrix(vertexCount: vertexCount, hyperedges: targets))
    }

    /// A matrix of `vertexCount` vertices with one column per edge, in order: −1 at its source,
    /// +1 at its target, and 0 for a self-loop (both bits set).
    ///
    /// - Precondition: every endpoint is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>) {
        self.init(vertexCount: vertexCount, hyperedges: edges.lazy.map { (sources: CollectionOfOne($0.source), targets: CollectionOfOne($0.target)) })
    }

    /// The oriented matrix of a directed hypergraph: rows by vertex index, a column per hyperedge
    /// in `hyperedges` order.
    ///
    /// - Precondition: `hypergraph.vertexIndexBound` is not `nil`.
    @inlinable
    public init(_ hypergraph: some DirectedHypergraph) {
        self.init(_copying: hypergraph)
    }

    @inlinable
    internal init(_copying hypergraph: some DirectedHypergraph) {
        if let same = hypergraph as? OrientedIncidenceMatrix {
            self = same
            return
        }
        guard let n = hypergraph.vertexIndexBound else {
            preconditionFailure("OrientedIncidenceMatrix(_:) needs a hypergraph with vertex indices")
        }
        let m = hypergraph.hyperedgeCount
        self.init(_sources: IncidenceMatrix(_vertexCount: n, hyperedgeCount: m), _targets: IncidenceMatrix(_vertexCount: n, hyperedgeCount: m))
        var p = 0
        for position in hypergraph.hyperedges.indices {
            for v in hypergraph.sourceIndices(ofHyperedgeAt: position) { _sources._setCell(v, p, to: true) }
            for v in hypergraph.targetIndices(ofHyperedgeAt: position) { _targets._setCell(v, p, to: true) }
            p += 1
        }
    }

    /// The oriented incidence matrix of a directed graph: rows by vertex index, a column per edge
    /// in `edges` order, −1 at the source and +1 at the target.
    ///
    /// - Precondition: `graph.vertexIndexBound` is not `nil`.
    @inlinable
    public init(_ graph: some DirectedGraph) {
        guard let n = graph.vertexIndexBound else {
            preconditionFailure("OrientedIncidenceMatrix(_:) needs a graph with vertex indices")
        }
        self.init(_sources: IncidenceMatrix(_vertexCount: n, hyperedgeCount: graph.edgeCount), _targets: IncidenceMatrix(_vertexCount: n, hyperedgeCount: graph.edgeCount))
        var p = 0
        for position in graph.edges.indices {
            _sources._setCell(graph.sourceIndex(ofEdgeAt: position), p, to: true)
            _targets._setCell(graph.targetIndex(ofEdgeAt: position), p, to: true)
            p += 1
        }
    }

    /// An oriented incidence matrix of an undirected graph: each edge oriented from `edges[p].u`
    /// to `edges[p].v` (NetworkX's `edgelist` tuple order), rows by vertex index.
    ///
    /// - Precondition: `graph.vertexIndexBound` is not `nil`.
    @inlinable
    public init(_ graph: some Graph) {
        guard let n = graph.vertexIndexBound else {
            preconditionFailure("OrientedIncidenceMatrix(_:) needs a graph with vertex indices")
        }
        self.init(_sources: IncidenceMatrix(_vertexCount: n, hyperedgeCount: graph.edgeCount), _targets: IncidenceMatrix(_vertexCount: n, hyperedgeCount: graph.edgeCount))
        var p = 0
        for position in graph.edges.indices {
            let (u, v) = graph.endpointIndices(ofEdgeAt: position)
            _sources._setCell(u, p, to: true)
            _targets._setCell(v, p, to: true)
            p += 1
        }
    }

    /// The one hypergraph conversion for a type that is both a directed graph and a directed
    /// hypergraph: read as a hypergraph.
    @inlinable
    public init<H: DirectedGraph & DirectedHypergraph>(_ hypergraph: H) {
        self.init(_copying: hypergraph)
    }
}

// MARK: - Reads

extension OrientedIncidenceMatrix {
    /// The number of vertices. O(1).
    @inlinable
    public var vertexCount: Int { _sources.vertexCount }

    /// The number of columns. O(1).
    @inlinable
    public var hyperedgeCount: Int { _sources.hyperedgeCount }

    /// The vertices: `0..<vertexCount`.
    @inlinable
    public var vertices: Range<Int> { _sources.vertices }

    /// Entry (`vertex`, `position`): target − source, so −1 for a source, +1 for a target, and 0
    /// for neither or both. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount` and `position` in `0..<hyperedgeCount`.
    @inlinable
    public subscript(vertex vertex: Int, hyperedge position: Int) -> Int {
        (_targets[vertex: vertex, hyperedge: position] ? 1 : 0) - (_sources[vertex: vertex, hyperedge: position] ? 1 : 0)
    }

    /// The sources of the column at `position`: the source plane's column. O(⌈n/64⌉).
    @inlinable
    public func sources(ofHyperedgeAt position: Int) -> BitSet { _sources.members(ofHyperedgeAt: position) }

    /// The targets of the column at `position`: the target plane's column. O(⌈n/64⌉).
    @inlinable
    public func targets(ofHyperedgeAt position: Int) -> BitSet { _targets.members(ofHyperedgeAt: position) }

    /// The number of sources of the column at `position`. O(1), cached.
    @inlinable
    public func sourceSize(ofHyperedgeAt position: Int) -> Int { _sources.size(ofHyperedgeAt: position) }

    /// The number of targets of the column at `position`. O(1), cached.
    @inlinable
    public func targetSize(ofHyperedgeAt position: Int) -> Int { _targets.size(ofHyperedgeAt: position) }

    /// The stored column of either plane, read in place: `IncidenceMatrix.MemberIndices`.
    public typealias MemberIndices = IncidenceMatrix.MemberIndices

    /// The stored row of either plane, read in place.
    public typealias IncidentHyperedgeIndices = IncidenceMatrix.MemberIndices

    /// The sources of the column at `position`, read in place without a copy.
    @inlinable
    public func sourceIndices(ofHyperedgeAt position: Int) -> MemberIndices { _sources.memberIndices(ofHyperedgeAt: position) }

    /// The targets of the column at `position`, read in place without a copy.
    @inlinable
    public func targetIndices(ofHyperedgeAt position: Int) -> MemberIndices { _targets.memberIndices(ofHyperedgeAt: position) }

    /// The columns with `index` among their sources, read in place without a copy.
    @inlinable
    public func outHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices { _sources.incidentHyperedgeIndices(ofIndex: index) }

    /// The columns with `index` among their targets, read in place without a copy.
    @inlinable
    public func inHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices { _targets.incidentHyperedgeIndices(ofIndex: index) }

    /// The set bits of one plane's column below `index`.
    @inlinable
    public func _memberRank(ofIndex index: Int, inHyperedgeAt position: Int, targets: Bool) -> Int {
        targets ? _targets._memberRank(ofIndex: index, inHyperedgeAt: position) : _sources._memberRank(ofIndex: index, inHyperedgeAt: position)
    }

    /// One plane's column member at offset `rank`.
    @inlinable
    public func _memberIndex(atRank rank: Int, inHyperedgeAt position: Int, targets: Bool) -> Int {
        targets ? _targets._memberIndex(atRank: rank, inHyperedgeAt: position) : _sources._memberIndex(atRank: rank, inHyperedgeAt: position)
    }

    /// Each vertex on either side of the column once: the two planes' words ORed.
    @inlinable
    public func _forEachMemberIndex(ofHyperedgeAt position: Int, _ body: (Int) -> Void) {
        _sources._checkHyperedge(position)
        let sources = _sources._columns, targets = _targets._columns
        let sourceStart = position &* sources.wordsPerRow, targetStart = position &* targets.wordsPerRow
        let used = _BitRows.wordsNeeded(sources.columnCount)
        sources.words.withUnsafeBufferPointer { sourceWords in
            targets.words.withUnsafeBufferPointer { targetWords in
                for k in 0 ..< used {
                    var word = sourceWords[sourceStart &+ k] | targetWords[targetStart &+ k]
                    while word != 0 {
                        body(k &* UInt.bitWidth &+ word.trailingZeroBitCount)
                        word &= word &- 1
                    }
                }
            }
        }
    }

    /// The columns with `vertex` among their sources: the source plane's row. O(⌈m/64⌉).
    @inlinable
    public func outHyperedges(of vertex: Int) -> BitSet { _sources.incidentHyperedges(of: vertex) }

    /// The columns with `vertex` among their targets: the target plane's row. O(⌈m/64⌉).
    @inlinable
    public func inHyperedges(of vertex: Int) -> BitSet { _targets.incidentHyperedges(of: vertex) }

    @inlinable
    public func outHyperedges(ofIndex index: Int) -> BitSet { outHyperedges(of: index) }

    @inlinable
    public func inHyperedges(ofIndex index: Int) -> BitSet { inHyperedges(of: index) }

    /// The number of columns with `vertex` among their sources. O(1), cached.
    @inlinable
    public func outDegree(of vertex: Int) -> Int { _sources.degree(of: vertex) }

    /// The number of columns with `vertex` among their targets. O(1), cached.
    @inlinable
    public func inDegree(of vertex: Int) -> Int { _targets.degree(of: vertex) }

    /// `outDegree + inDegree`: a vertex on both sides of a column counts it twice. O(1).
    @inlinable
    public func degree(of vertex: Int) -> Int { outDegree(of: vertex) &+ inDegree(of: vertex) }

    // The `checked:` lookups (README Principle 6): they throw `VertexNotFound` for a vertex that
    // is not in `0..<vertexCount`, where the trapping spellings above are the fast path; `try?`
    // gives an Optional.

    /// `outHyperedges(of:)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(⌈m/64⌉).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outHyperedges(checked vertex: Int) throws(VertexNotFound) -> BitSet {
        guard contains(vertex) else { throw VertexNotFound() }
        return outHyperedges(of: vertex)
    }

    /// `inHyperedges(of:)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(⌈m/64⌉).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func inHyperedges(checked vertex: Int) throws(VertexNotFound) -> BitSet {
        guard contains(vertex) else { throw VertexNotFound() }
        return inHyperedges(of: vertex)
    }

    /// `outDegree(of:)`, throwing instead of trapping when `vertex` is not in `0..<vertexCount`.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return outDegree(of: vertex)
    }

    /// `inDegree(of:)`, throwing instead of trapping when `vertex` is not in `0..<vertexCount`.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func inDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return inDegree(of: vertex)
    }

    /// `degree(of:)`, throwing instead of trapping when `vertex` is not in `0..<vertexCount`.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func degree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return degree(of: vertex)
    }

    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { outDegree(of: index) }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { inDegree(of: index) }

    /// Whether `vertex` is in `0..<vertexCount`. Never traps.
    @inlinable
    public func contains(_ vertex: Int) -> Bool { _sources.contains(vertex) }

    /// Whether some column has exactly these sources and these targets, ignoring order and
    /// repeats. False, without trapping, when a vertex is out of range.
    ///
    /// - Complexity: O(k + d·⌈n/64⌉) at one listed vertex's d columns; the empty pair scans the m
    ///   cached sizes.
    @inlinable
    public func contains(sources: some Sequence<Int>, targets: some Sequence<Int>) -> Bool {
        var wantedSources = BitSet(), wantedTargets = BitSet()
        for v in sources {
            guard contains(v) else { return false }
            wantedSources.insert(v)
        }
        for v in targets {
            guard contains(v) else { return false }
            wantedTargets.insert(v)
        }
        let candidates: BitSet
        if let first = wantedSources.first {
            candidates = _sources._rows.row(first)
        } else if let first = wantedTargets.first {
            candidates = _targets._rows.row(first)
        } else {
            for p in 0 ..< hyperedgeCount where _sources._sizes[p] == 0 && _targets._sizes[p] == 0 { return true }
            return false
        }
        for p in candidates where _sources._columns.row(p) == wantedSources && _targets._columns.row(p) == wantedTargets {
            return true
        }
        return false
    }

    /// `vertexCount`.
    @inlinable
    public var vertexIndexBound: Int? { vertexCount }

    @inlinable
    public func vertexIndex(of vertex: Int) -> Int { _sources.vertexIndex(of: vertex) }

    /// `vertex` itself, throwing instead of trapping when it is not in `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertexIndex(of: vertex)
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Int { _sources.vertex(atIndex: index) }

    /// `hyperedgeCount`.
    @inlinable
    public var hyperedgeIndexBound: Int? { hyperedgeCount }

    @inlinable
    public func hyperedgeIndex(of position: Int) -> Int { _sources.hyperedgeIndex(of: position) }

    /// Every column as its sources and targets, at its position.
    @frozen
    public struct Hyperedges: RandomAccessCollection, Sendable {
        @usableFromInline internal let _sources: IncidenceMatrix.Hyperedges
        @usableFromInline internal let _targets: IncidenceMatrix.Hyperedges

        @inlinable
        internal init(_sources: IncidenceMatrix.Hyperedges, _targets: IncidenceMatrix.Hyperedges) {
            self._sources = _sources
            self._targets = _targets
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _sources.endIndex }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }

        @inlinable
        public subscript(position: Int) -> (sources: BitSet, targets: BitSet) {
            (_sources[position], _targets[position])
        }
    }

    /// Every column, at its position. O(1).
    @inlinable
    public var hyperedges: Hyperedges { Hyperedges(_sources: _sources.hyperedges, _targets: _targets.hyperedges) }
}

extension OrientedIncidenceMatrix: DirectedHypergraph {}

// MARK: - Mutation

extension OrientedIncidenceMatrix {
    /// Appends a vertex in no column.
    ///
    /// - Returns: The new vertex, the old `vertexCount`.
    /// - Complexity: Amortized O(⌈m/64⌉).
    @inlinable
    @discardableResult
    public mutating func appendVertex() -> Int {
        _ = _sources._appendRow()
        let vertex = _targets._appendRow()
        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaults(count: 1) }
        _generation.advance()
        return vertex
    }

    /// Appends the column `sources` → `targets`. Either side may be empty, and a vertex may be on
    /// both (entry 0).
    ///
    /// - Returns: The new column's position.
    /// - Precondition: every vertex listed is in `0..<vertexCount`.
    /// - Complexity: Amortized O(n·⌈m/64⌉/m + ⌈n/64⌉ + k).
    @inlinable
    @discardableResult
    public mutating func insert(sources: some Sequence<Int>, targets: some Sequence<Int>) -> Int {
        _ = _sources._appendColumn(sources)
        let position = _targets._appendColumn(targets)
        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 1) }
        _generation.advance()
        return position
    }

    /// Appends the column of `edge`: −1 at its source and +1 at its target (0 for a self-loop).
    ///
    /// - Returns: The new column's position.
    /// - Precondition: both endpoints are in `0..<vertexCount`.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Int>) -> Int {
        insert(sources: CollectionOfOne(edge.source), targets: CollectionOfOne(edge.target))
    }

    /// Appends the column `sources` → `targets` if every vertex listed is in `0..<vertexCount`;
    /// otherwise throws and changes nothing.
    ///
    /// - Returns: The new column's position.
    /// - Throws: `VertexNotFound` when a vertex listed is not in `0..<vertexCount`.
    /// - Complexity: `insert(sources:targets:)`'s, plus one pass over the vertices to check them
    ///   first.
    @inlinable
    @discardableResult
    public mutating func insert(checked sources: some Sequence<Int>, targets: some Sequence<Int>) throws(VertexNotFound) -> Int {
        let sources = Array(sources), targets = Array(targets)
        for v in sources where !contains(v) { throw VertexNotFound() }
        for v in targets where !contains(v) { throw VertexNotFound() }
        return insert(sources: sources, targets: targets)
    }

    /// Appends the column of `edge` if both endpoints are in `0..<vertexCount`; otherwise throws
    /// and changes nothing.
    ///
    /// - Returns: The new column's position.
    /// - Throws: `VertexNotFound` when an endpoint is not in `0..<vertexCount`.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: DirectedEdge<Int>) throws(VertexNotFound) -> Int {
        guard contains(edge.source), contains(edge.target) else { throw VertexNotFound() }
        return insert(edge: edge)
    }

    /// Makes `vertex` a source of the column at `position`. O(1).
    ///
    /// - Returns: Whether it changed.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Int, intoSourcesOfHyperedgeAt position: Int) -> Bool {
        _sources._checkVertex(vertex)
        _sources._checkHyperedge(position)
        guard _sources._setCell(vertex, position, to: true) else { return false }
        _generation.advance()
        return true
    }

    /// Makes `vertex` a target of the column at `position`. O(1).
    ///
    /// - Returns: Whether it changed.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Int, intoTargetsOfHyperedgeAt position: Int) -> Bool {
        _targets._checkVertex(vertex)
        _targets._checkHyperedge(position)
        guard _targets._setCell(vertex, position, to: true) else { return false }
        _generation.advance()
        return true
    }

    /// Removes `vertex` from the sources of the column at `position`. O(1).
    ///
    /// - Returns: Whether it changed.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Int, fromSourcesOfHyperedgeAt position: Int) -> Bool {
        _sources._checkVertex(vertex)
        _sources._checkHyperedge(position)
        guard _sources._setCell(vertex, position, to: false) else { return false }
        _generation.advance()
        return true
    }

    /// Removes `vertex` from the targets of the column at `position`. O(1).
    ///
    /// - Returns: Whether it changed.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Int, fromTargetsOfHyperedgeAt position: Int) -> Bool {
        _targets._checkVertex(vertex)
        _targets._checkHyperedge(position)
        guard _targets._setCell(vertex, position, to: false) else { return false }
        _generation.advance()
        return true
    }

    /// Removes every vertex and column. Every attached map stays attached, empty.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _sources._removeAllCells(keepingCapacity: keepingCapacity)
        _targets._removeAllCells(keepingCapacity: keepingCapacity)
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _generation.advance()
    }

    /// Reserves storage for `vertexCount` vertices and `hyperedgeCount` columns, and room for
    /// their values in every attached map.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int) {
        _sources.reserveCapacity(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount)
        _targets.reserveCapacity(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount)
        if !_vertexMaps.isEmpty { _vertexMaps.reserveCapacity(vertexCount) }
        if !_edgeMaps.isEmpty { _edgeMaps.reserveCapacity(hyperedgeCount) }
    }

    /// The transpose of each plane, which is the dual (`IncidenceList.dual()`'s convention): column
    /// `v` of the result has sources `outHyperedges(of: v)` and targets `inHyperedges(of: v)`.
    /// O(1). A new hypergraph: it carries none of this matrix's attached maps.
    @inlinable
    public func transposed() -> OrientedIncidenceMatrix {
        OrientedIncidenceMatrix(_sources: _sources.transposed(), _targets: _targets.transposed())
    }

    /// Every column's sources and targets swapped, every entry negated (a vertex on both sides
    /// stays 0): Gallo et al.'s symmetric image. An involution. O(1): the planes swap. A new
    /// hypergraph: it carries none of this matrix's attached maps.
    @inlinable
    public var reversed: OrientedIncidenceMatrix {
        OrientedIncidenceMatrix(_sources: _targets, _targets: _sources)
    }
}

// MARK: - Equatable, Hashable, Sendable

extension OrientedIncidenceMatrix: Equatable {
    /// Equal when both planes are equal cell for cell, with equal shape: a vertex on both sides
    /// differs from one on neither, although both entries are 0.
    @inlinable
    public static func == (lhs: OrientedIncidenceMatrix, rhs: OrientedIncidenceMatrix) -> Bool {
        lhs._sources == rhs._sources && lhs._targets == rhs._targets
    }
}

extension OrientedIncidenceMatrix: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_sources)
        hasher.combine(_targets)
    }
}

extension OrientedIncidenceMatrix: Sendable {}

// MARK: - Codable

extension OrientedIncidenceMatrix: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertexCount
        case sources
        case targets
    }

    /// Encodes `{"vertexCount": n, "sources": [[v, …], …], "targets": [[v, …], …]}`: the shape,
    /// and each column's sides, by position, in ascending order. The encoding of a matrix is
    /// always the same.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(vertexCount, forKey: .vertexCount)
        try container.encode((0 ..< hyperedgeCount).map { Array(sources(ofHyperedgeAt: $0)) }, forKey: .sources)
        try container.encode((0 ..< hyperedgeCount).map { Array(targets(ofHyperedgeAt: $0)) }, forKey: .targets)
    }

    /// Decodes the form `encode(to:)` writes, throwing `DecodingError.dataCorrupted` for a negative
    /// vertex count, storage over `IncidenceMatrix.maximumDecodedWordCountKey`'s limit (two planes' words), a vertex
    /// out of range, a side not strictly ascending, or `sources` and `targets` of different
    /// lengths.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let n = try container.decode(Int.self, forKey: .vertexCount)
        let sources = try container.decode([[Int]].self, forKey: .sources)
        let targets = try container.decode([[Int]].self, forKey: .targets)
        guard sources.count == targets.count else {
            throw DecodingError.dataCorruptedError(forKey: .targets, in: container, debugDescription: "sources and targets have different lengths")
        }
        let maximum = decoder.userInfo[IncidenceMatrix.maximumDecodedWordCountKey] as? Int ?? IncidenceMatrix.defaultMaximumDecodedWordCount
        try IncidenceMatrix._checkDecodedShape(n, sources.count, planes: 2, maximum: maximum, key: .vertexCount, in: container)
        for column in sources { try IncidenceMatrix._checkDecodedColumn(column, vertexCount: n, key: .sources, in: container) }
        for column in targets { try IncidenceMatrix._checkDecodedColumn(column, vertexCount: n, key: .targets, in: container) }
        self.init(_sources: IncidenceMatrix(vertexCount: n, hyperedges: sources), _targets: IncidenceMatrix(vertexCount: n, hyperedges: targets))
    }
}

// MARK: - Description

extension OrientedIncidenceMatrix: CustomStringConvertible {
    /// The shape, then the rows as strings of `-` (−1), `0` and `+` (+1), column 0 leftmost, at
    /// most 16 rows of 64 columns: `3×2 [-0, +-, 0+]`. The empty matrix is `0×0 []`.
    public var description: String {
        _matrixDescription(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount) { v, p in
            let entry = (_targets._rows.bit(v, p) ? 1 : 0) - (_sources._rows.bit(v, p) ? 1 : 0)
            return entry < 0 ? "-" : entry > 0 ? "+" : "0"
        }
    }
}
