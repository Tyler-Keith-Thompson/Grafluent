import GraphProtocols

/// An immutable directed graph on the vertices `0..<vertexCount`, in compressed sparse row form:
/// `offsets` has `vertexCount + 1` entries, and the successors of `v` are
/// `targets[offsets[v] ..< offsets[v + 1]]`.
///
/// Rows are canonical: sorted ascending with no repeats, so parallel edges cannot be represented
/// and `contains(edge:)` is a binary search. Self-loops are kept. The graph is built once by its
/// initializers; there is no mutation, because inserting one edge would move O(m) others.
///
/// Every edge has an index in `0..<edgeCount`: its position in `targets`, which is its position in
/// row-major order. Because the rows are canonical, an edge's index depends only on the graph, never
/// on the order edges were given in, so an array of edge values indexed by it stays aligned. The
/// initializers and `transposed` can report where each edge went, to carry such values along.
@frozen
public struct CompressedSparseRow {
    @usableFromInline
    internal var _offsets: [Int]

    @usableFromInline
    internal var _targets: [Int]

    /// Unchecked: `_offsets` and `_targets` must already satisfy `init(offsets:targets:)`.
    @inlinable
    package init(_offsets: [Int], _targets: [Int]) {
        self._offsets = _offsets
        self._targets = _targets
    }

    /// Shared by every graph with no vertices, so creating one does not allocate.
    @usableFromInline
    internal static let _emptyOffsets: [Int] = [0]

    /// The graph with no vertices.
    @inlinable
    public init() {
        self.init(_offsets: Self._emptyOffsets, _targets: [])
    }

    /// A graph of `vertexCount` vertices and no edges.
    ///
    /// - Precondition: `vertexCount` is in `0 ..< Int.max`.
    @inlinable
    public init(vertexCount: Int) {
        Self._checkVertexCount(vertexCount)
        self.init(
            _offsets: vertexCount == 0 ? Self._emptyOffsets : [Int](repeating: 0, count: vertexCount + 1),
            _targets: []
        )
    }

    /// A graph of `vertexCount` vertices with the given edges, in any order. Repeated edges are
    /// stored once. O(n + m) for any input: two counting sorts, by target and then by source, or a
    /// single pass when the edges are already in row-major order without repeats. A sequence that
    /// is not a collection is copied first, since it must be read twice.
    ///
    /// - Precondition: `vertexCount` is in `0 ..< Int.max`, and every endpoint is in
    ///   `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>) {
        self.init(vertexCount: vertexCount, edges: Array(edges))
    }

    /// A graph of `vertexCount` vertices with the edges of a collection, which is read twice in
    /// place rather than copied.
    @inlinable
    public init(vertexCount: Int, edges: some Collection<DirectedEdge<Int>>) {
        var unused: [Int] = []
        self = Self._build(vertexCount: vertexCount, edges: edges, edgeIndices: &unused, recording: false)
    }

    /// A graph of `vertexCount` vertices with the edges of a collection, also reporting where each
    /// one went: `edgeIndices[i]` is the index in the graph of the `i`th input edge. Repeated edges
    /// get the same index, so the caller decides how to combine values given with them.
    @inlinable
    public init(vertexCount: Int, edges: some Collection<DirectedEdge<Int>>, edgeIndices: inout [Int]) {
        self = Self._build(vertexCount: vertexCount, edges: edges, edgeIndices: &edgeIndices, recording: true)
    }

    /// A graph from parallel arrays: edge `i` goes from `sources[i]` to `targets[i]`.
    ///
    /// - Precondition: the arrays have the same length, `vertexCount` is in `0 ..< Int.max`, and
    ///   every entry is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, sources: [Int], targets: [Int]) {
        precondition(sources.count == targets.count, "\(sources.count) sources but \(targets.count) targets")
        self.init(vertexCount: vertexCount, edges: _ParallelEdges(sources: sources, targets: targets))
    }

    @inlinable
    internal static func _checkVertexCount(_ vertexCount: Int) {
        precondition(vertexCount >= 0 && vertexCount < Int.max, "Invalid vertex count \(vertexCount)")
    }

    @inlinable
    internal static func _build(
        vertexCount n: Int,
        edges: some Collection<DirectedEdge<Int>>,
        edgeIndices: inout [Int],
        recording: Bool
    ) -> CompressedSparseRow {
        _checkVertexCount(n)
        let m = edges.count
        if n == 0 {
            precondition(m == 0, "A graph with no vertices has no edges")
            edgeIndices = []
            return CompressedSparseRow()
        }

        // Pass 1: check endpoints, count each row and column, and notice whether the input is
        // already in row-major order, and if so whether it also has no repeats (is canonical).
        var offsets = [Int](repeating: 0, count: n + 1)
        var columns = [Int](repeating: 0, count: n + 1)
        var isCanonical = true
        var isSorted = true
        offsets.withUnsafeMutableBufferPointer { offsets in
            columns.withUnsafeMutableBufferPointer { columns in
                var previousSource = -1
                var previousTarget = -1
                for edge in edges {
                    let source = edge.source
                    let target = edge.target
                    precondition(source >= 0 && source < n, "Edge source \(source) is out of range 0..<\(n)")
                    precondition(target >= 0 && target < n, "Edge target \(target) is out of range 0..<\(n)")
                    offsets[source &+ 1] &+= 1
                    columns[target &+ 1] &+= 1
                    if source < previousSource || (source == previousSource && target <= previousTarget) {
                        isCanonical = false
                        if source != previousSource || target != previousTarget { isSorted = false }
                    }
                    previousSource = source
                    previousTarget = target
                }
                for v in 0 ..< n {
                    offsets[v &+ 1] &+= offsets[v]
                    columns[v &+ 1] &+= columns[v]
                }
            }
        }

        if isCanonical {
            if recording { edgeIndices = Array(0 ..< m) }
            return CompressedSparseRow(_offsets: offsets, _targets: edges.map(\.target))
        }
        if isSorted {
            return _buildFromSortedWithRepeats(vertexCount: n, edges: edges, edgeIndices: &edgeIndices, recording: recording)
        }

        // Scratch: each edge's source, bucketed by target, then reused for the deduplicated index
        // of each slot; and each bucketed edge's input position.
        let scratch = UnsafeMutableBufferPointer<Int>.allocate(capacity: m)
        let inputPositions = UnsafeMutableBufferPointer<Int>.allocate(capacity: recording ? m : 0)
        defer {
            scratch.deallocate()
            inputPositions.deallocate()
        }
        if recording { edgeIndices = [Int](repeating: 0, count: m) }

        var kept = 0
        var targets = [Int](unsafeUninitializedCapacity: m) { targets, initializedCount in
            offsets.withUnsafeMutableBufferPointer { offsets in
                columns.withUnsafeMutableBufferPointer { columns in
                    edgeIndices.withUnsafeMutableBufferPointer { edgeIndices in
                        // Pass 2: bucket by target. `columns[t + 1]` is the cursor of bucket t,
                        // so afterwards it is the bucket's end and `columns[t]` its start.
                        var position = 0
                        for edge in edges {
                            let slot = columns[edge.target]
                            columns[edge.target] = slot &+ 1
                            scratch[slot] = edge.source
                            if recording { inputPositions[slot] = position }
                            position &+= 1
                        }

                        // Pass 3: deal the buckets into rows in ascending target order, so every
                        // row comes out ascending. `offsets[s]` is row s's cursor, then shifts back.
                        var start = 0
                        for target in 0 ..< n {
                            let end = columns[target]
                            for k in start ..< end {
                                let source = scratch[k]
                                let slot = offsets[source]
                                offsets[source] = slot &+ 1
                                targets.initializeElement(at: slot, to: target)
                                if recording { edgeIndices[inputPositions[k]] = slot }
                            }
                            start = end
                        }
                        var v = n
                        while v > 0 {
                            offsets[v] = offsets[v &- 1]
                            v &-= 1
                        }
                        offsets[0] = 0

                        // Pass 4: drop repeats, now adjacent within each row, in place.
                        var rowStart = 0
                        for v in 0 ..< n {
                            let rowEnd = offsets[v &+ 1]
                            var last = -1
                            for k in rowStart ..< rowEnd {
                                let target = targets[k]
                                if target != last {
                                    targets[kept] = target
                                    last = target
                                    kept &+= 1
                                }
                                scratch[k] = kept &- 1
                            }
                            offsets[v &+ 1] = kept
                            rowStart = rowEnd
                        }
                        if recording, kept < m {
                            for i in 0 ..< m { edgeIndices[i] = scratch[edgeIndices[i]] }
                        }
                    }
                }
            }
            initializedCount = kept
        }
        // The graph keeps its arrays forever, so drop the capacity the repeats took. (`Array(_:)` of
        // a slice would hand back the same oversized buffer, since every element is in the slice.)
        if kept < m {
            targets = targets.withUnsafeBufferPointer { kept in
                [Int](unsafeUninitializedCapacity: kept.count) { exact, initializedCount in
                    initializedCount = exact.initialize(fromContentsOf: kept)
                }
            }
        }
        return CompressedSparseRow(_offsets: offsets, _targets: targets)
    }

    /// Sorted input whose repeats are adjacent: one pass that skips them.
    @inlinable
    internal static func _buildFromSortedWithRepeats(
        vertexCount n: Int,
        edges: some Collection<DirectedEdge<Int>>,
        edgeIndices: inout [Int],
        recording: Bool
    ) -> CompressedSparseRow {
        let m = edges.count
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = []
        if recording { edgeIndices = [] }
        if recording { edgeIndices.reserveCapacity(m) }
        // Count the distinct edges first, so the targets are allocated exactly once.
        var distinct = 0
        var previous = DirectedEdge(from: -1, to: -1)
        for edge in edges where edge != previous {
            distinct &+= 1
            previous = edge
        }
        targets.reserveCapacity(distinct)
        previous = DirectedEdge(from: -1, to: -1)
        offsets.withUnsafeMutableBufferPointer { offsets in
            for edge in edges {
                if edge != previous {
                    targets.append(edge.target)
                    offsets[edge.source &+ 1] &+= 1
                    previous = edge
                }
                if recording { edgeIndices.append(targets.count &- 1) }
            }
            for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
        }
        return CompressedSparseRow(_offsets: offsets, _targets: targets)
    }

    /// Why a pair of arrays is not a valid compressed sparse row graph.
    public enum ValidationError: Error, Hashable, Sendable {
        /// `offsets` is empty; it needs `vertexCount + 1` entries.
        case emptyOffsets
        /// `offsets[0]` is not 0.
        case firstOffsetNotZero
        /// `offsets[vertex] > offsets[vertex + 1]`.
        case decreasingOffsets(vertex: Int)
        /// The last offset is not the number of targets.
        case lastOffsetMismatch(lastOffset: Int, targetCount: Int)
        /// `targets[edgeIndex]` is not in `0..<vertexCount`.
        case targetOutOfRange(edgeIndex: Int)
        /// A row is not in ascending order.
        case unsortedRow(vertex: Int)
        /// A row repeats a target.
        case duplicateEdge(vertex: Int)
    }

    /// A graph from its arrays, which must already be canonical. O(n + m); the arrays are stored,
    /// not copied. Only the first violation is reported, checking in the order listed below.
    ///
    /// - Throws: `ValidationError` if the arrays break any invariant: `offsets` has at least one
    ///   entry, starts at 0, never decreases, and ends at `targets.count`; every target is in
    ///   `0..<offsets.count - 1`; and every row is strictly ascending.
    @inlinable
    public init(offsets: [Int], targets: [Int]) throws(ValidationError) {
        guard let first = offsets.first else { throw .emptyOffsets }
        guard first == 0 else { throw .firstOffsetNotZero }
        let n = offsets.count - 1
        for v in 0 ..< n where offsets[v] > offsets[v + 1] {
            throw .decreasingOffsets(vertex: v)
        }
        guard offsets[n] == targets.count else {
            throw .lastOffsetMismatch(lastOffset: offsets[n], targetCount: targets.count)
        }
        for (k, target) in targets.enumerated() where target < 0 || target >= n {
            throw .targetOutOfRange(edgeIndex: k)
        }
        for v in 0 ..< n {
            var k = offsets[v] + 1
            while k < offsets[v + 1] {
                if targets[k - 1] == targets[k] { throw .duplicateEdge(vertex: v) }
                if targets[k - 1] > targets[k] { throw .unsortedRow(vertex: v) }
                k += 1
            }
        }
        self.init(_offsets: offsets, _targets: targets)
    }
}

/// Parallel source and target arrays, read as a collection of edges without copying.
@frozen
@usableFromInline
internal struct _ParallelEdges: RandomAccessCollection {
    @usableFromInline let sources: [Int]
    @usableFromInline let targets: [Int]

    @inlinable
    init(sources: [Int], targets: [Int]) {
        self.sources = sources
        self.targets = targets
    }

    @inlinable var startIndex: Int { 0 }
    @inlinable var endIndex: Int { sources.count }

    @inlinable
    subscript(position: Int) -> DirectedEdge<Int> {
        DirectedEdge(from: sources[position], to: targets[position])
    }
}

// MARK: - Queries

extension CompressedSparseRow {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _offsets.count - 1 }

    /// The number of edges.
    @inlinable
    public var edgeCount: Int { _targets.count }

    /// The vertices: `0..<vertexCount`.
    @inlinable
    public var vertices: Range<Int> { 0 ..< vertexCount }

    /// The row offsets: `vertexCount + 1` entries, starting at 0 and ending at `edgeCount`.
    @inlinable
    public var offsets: [Int] { _offsets }

    /// Every edge's target, row by row; each row is strictly ascending.
    @inlinable
    public var targets: [Int] { _targets }

    /// Calls `body` with the offsets and targets as buffers, for loops that must run without
    /// bounds checks or reference counting. The buffers are valid only during the call.
    @inlinable
    public func withUnsafeBufferPointers<Result, Failure: Error>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) throws(Failure) -> Result
    ) throws(Failure) -> Result {
        try _offsets.withUnsafeBufferPointer { (offsets) throws(Failure) -> Result in
            try _targets.withUnsafeBufferPointer { (targets) throws(Failure) -> Result in
                try body(offsets, targets)
            }
        }
    }

    /// Whether `vertex` is in `0..<vertexCount`.
    @inlinable
    public func contains(_ vertex: Int) -> Bool {
        vertex >= 0 && vertex < vertexCount
    }

    @inlinable
    @inline(__always)
    internal func _checkVertex(_ vertex: Int) {
        precondition(vertex >= 0 && vertex < vertexCount, "Vertex \(vertex) is out of range 0..<\(vertexCount)")
    }

    /// The vertices `vertex` has an edge to, ascending. The slice's indices are the edges' indices,
    /// not 0-based: `successors(of: v).first`, never `successors(of: v)[0]`.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func successors(of vertex: Int) -> ArraySlice<Int> {
        _checkVertex(vertex)
        return _targets[_offsets[vertex] ..< _offsets[vertex + 1]]
    }

    /// The number of edges leaving `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _offsets[vertex + 1] - _offsets[vertex]
    }

    /// The number of edges entering each vertex, indexed by vertex, in one O(n + m) pass over
    /// `targets`. (Rows hold only out-edges, so one vertex's in-degree costs as much as all.)
    @inlinable
    public var inDegrees: [Int] {
        var degrees = [Int](repeating: 0, count: vertexCount)
        degrees.withUnsafeMutableBufferPointer { degrees in
            _targets.withUnsafeBufferPointer { targets in
                for target in targets { degrees[target] &+= 1 }
            }
        }
        return degrees
    }

    /// The index of `edge`, or `nil` if it is not an edge (including when an endpoint is out of
    /// range). O(log d), a binary search of the source's row.
    @inlinable
    public func edgeIndex(of edge: DirectedEdge<Int>) -> Int? {
        guard contains(edge.source), contains(edge.target) else { return nil }
        var low = _offsets[edge.source]
        var high = _offsets[edge.source + 1]
        while low < high {
            let middle = low + (high - low) / 2
            let value = _targets[middle]
            if value == edge.target { return middle }
            if value < edge.target { low = middle + 1 } else { high = middle }
        }
        return nil
    }

    /// Whether `edge` is an edge. False when either endpoint is out of range. O(log d).
    @inlinable
    public func contains(edge: DirectedEdge<Int>) -> Bool {
        edgeIndex(of: edge) != nil
    }

    /// The source of the edge with index `edgeIndex`. O(log n), a binary search of `offsets`.
    ///
    /// - Precondition: `edgeIndex` is in `0..<edgeCount`.
    @inlinable
    public func source(ofEdgeAt edgeIndex: Int) -> Int {
        precondition(edgeIndex >= 0 && edgeIndex < edgeCount, "Edge index \(edgeIndex) is out of range 0..<\(edgeCount)")
        return _source(ofEdgeAt: edgeIndex)
    }

    /// The last vertex whose row starts at or before `edgeIndex`.
    @inlinable
    internal func _source(ofEdgeAt edgeIndex: Int) -> Int {
        var low = 0
        var high = vertexCount
        while low < high {
            let middle = low + (high - low + 1) / 2
            if _offsets[middle] <= edgeIndex { low = middle } else { high = middle - 1 }
        }
        return low
    }

    /// The target of the edge with index `edgeIndex`. O(1).
    ///
    /// - Precondition: `edgeIndex` is in `0..<edgeCount`.
    @inlinable
    public func target(ofEdgeAt edgeIndex: Int) -> Int {
        precondition(edgeIndex >= 0 && edgeIndex < edgeCount, "Edge index \(edgeIndex) is out of range 0..<\(edgeCount)")
        return _targets[edgeIndex]
    }

    /// The graph with every edge reversed (the compressed sparse column form of this one). Its rows
    /// come out canonical. O(n + m).
    @inlinable
    public func transposed() -> CompressedSparseRow {
        var unused: [Int] = []
        return _transposed(forwardEdgeIndices: &unused, recording: false)
    }

    /// The graph with every edge reversed, also reporting where each edge came from:
    /// `forwardEdgeIndices[k]` is the index in this graph of the transpose's edge `k`, so values
    /// indexed by this graph's edges can be read in the transpose's order.
    @inlinable
    public func transposed(forwardEdgeIndices: inout [Int]) -> CompressedSparseRow {
        _transposed(forwardEdgeIndices: &forwardEdgeIndices, recording: true)
    }

    @inlinable
    internal func _transposed(forwardEdgeIndices: inout [Int], recording: Bool) -> CompressedSparseRow {
        let n = vertexCount
        let m = edgeCount
        guard n > 0 else {
            forwardEdgeIndices = []
            return self
        }
        var offsets = [Int](repeating: 0, count: n + 1)
        if recording { forwardEdgeIndices = [Int](repeating: 0, count: m) }
        let targets = [Int](unsafeUninitializedCapacity: m) { targets, initializedCount in
            offsets.withUnsafeMutableBufferPointer { offsets in
                forwardEdgeIndices.withUnsafeMutableBufferPointer { forward in
                    _offsets.withUnsafeBufferPointer { sourceOffsets in
                        _targets.withUnsafeBufferPointer { sourceTargets in
                            // `offsets[t + 1]` counts row t, then is row t's cursor, then its end.
                            for target in sourceTargets { offsets[target &+ 1] &+= 1 }
                            var v = 0
                            while v < n {
                                offsets[v &+ 1] &+= offsets[v]
                                v &+= 1
                            }
                            // Shift right by one so `offsets[t + 1]` is row t's start, used as its cursor.
                            v = n
                            while v > 0 {
                                offsets[v] = offsets[v &- 1]
                                v &-= 1
                            }
                            // Sources are visited in ascending order, so every new row is filled
                            // in ascending order.
                            for source in 0 ..< n {
                                for k in sourceOffsets[source] ..< sourceOffsets[source &+ 1] {
                                    let target = sourceTargets[k]
                                    let slot = offsets[target &+ 1]
                                    offsets[target &+ 1] = slot &+ 1
                                    targets.initializeElement(at: slot, to: source)
                                    if recording { forward[slot] = k }
                                }
                            }
                        }
                    }
                }
            }
            initializedCount = m
        }
        return CompressedSparseRow(_offsets: offsets, _targets: targets)
    }
}

// MARK: - Edges

extension CompressedSparseRow {
    /// Every edge in row-major order; the position of an edge is its index.
    @inlinable
    public var edges: Edges { Edges(graph: self, bounds: 0 ..< edgeCount) }

    /// The edges of a graph, or a contiguous run of them. Positions are edge indices. Iterating is
    /// O(1) per edge, including over a slice, which is itself an `Edges`; subscripting a single
    /// position is O(log n), a search for its source, so prefer iteration to index loops.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let graph: CompressedSparseRow

        public let startIndex: Int
        public let endIndex: Int

        @inlinable
        init(graph: CompressedSparseRow, bounds: Range<Int>) {
            self.graph = graph
            self.startIndex = bounds.lowerBound
            self.endIndex = bounds.upperBound
        }

        public typealias Indices = Range<Int>
        public typealias SubSequence = Edges

        @inlinable public var indices: Range<Int> { startIndex ..< endIndex }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Int> {
            precondition(position >= startIndex && position < endIndex, "Index \(position) is out of bounds \(startIndex)..<\(endIndex)")
            return DirectedEdge(from: graph._source(ofEdgeAt: position), to: graph._targets[position])
        }

        @inlinable
        public subscript(bounds: Range<Int>) -> Edges {
            precondition(bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex, "Range \(bounds) is out of bounds \(startIndex)..<\(endIndex)")
            return Edges(graph: graph, bounds: bounds)
        }

        /// The position of `element` if it is in this run, found by binary search.
        @inlinable
        func _position(of element: DirectedEdge<Int>) -> Int? {
            guard let k = graph.edgeIndex(of: element), k >= startIndex, k < endIndex else { return nil }
            return k
        }

        @inlinable
        public func _customContainsEquatableElement(_ element: DirectedEdge<Int>) -> Bool? {
            _position(of: element) != nil
        }

        /// Edges are unique, so the first and last positions agree.
        @inlinable
        public func _customIndexOfEquatableElement(_ element: DirectedEdge<Int>) -> Int?? {
            .some(_position(of: element))
        }

        @inlinable
        public func _customLastIndexOfEquatableElement(_ element: DirectedEdge<Int>) -> Int?? {
            .some(_position(of: element))
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(graph: graph, bounds: startIndex ..< endIndex)
        }

        /// Walks the rows in order from one search for the first source, so each step is O(1)
        /// amortized.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let graph: CompressedSparseRow
            @usableFromInline var source: Int
            @usableFromInline var rowEnd: Int
            @usableFromInline var position: Int
            @usableFromInline let end: Int

            @inlinable
            init(graph: CompressedSparseRow, bounds: Range<Int>) {
                self.graph = graph
                self.position = bounds.lowerBound
                self.end = bounds.upperBound
                self.source = bounds.isEmpty ? 0 : graph._source(ofEdgeAt: bounds.lowerBound)
                self.rowEnd = bounds.isEmpty ? 0 : graph._offsets[source + 1]
            }

            @inlinable
            public mutating func next() -> DirectedEdge<Int>? {
                guard position < end else { return nil }
                while rowEnd <= position {
                    source &+= 1
                    rowEnd = graph._offsets[source &+ 1]
                }
                defer { position &+= 1 }
                return DirectedEdge(from: source, to: graph._targets[position])
            }
        }
    }
}

// MARK: - Conformances

extension CompressedSparseRow: Hashable {
    /// Equal when the vertex counts and the edges are equal: because rows are canonical, exactly
    /// when the arrays are equal.
    @inlinable
    public static func == (lhs: CompressedSparseRow, rhs: CompressedSparseRow) -> Bool {
        lhs._offsets == rhs._offsets && lhs._targets == rhs._targets
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_offsets)
        hasher.combine(_targets)
    }
}

extension CompressedSparseRow: Sendable {}
extension CompressedSparseRow.Edges: Sendable {}
extension CompressedSparseRow.Edges.Iterator: Sendable {}

extension CompressedSparseRow: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case offsets
        case targets
    }

    /// Encodes `{"offsets": [...], "targets": [...]}`. The vertex count is `offsets.count − 1`, so
    /// the payload is as large as the graph it describes.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(_offsets, forKey: .offsets)
        try container.encode(_targets, forKey: .targets)
    }

    /// Decodes and validates every invariant. Invalid arrays are a `DecodingError.dataCorrupted`
    /// whose coding path ends at the array at fault and whose underlying error is the
    /// `ValidationError`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let offsets = try container.decode([Int].self, forKey: .offsets)
        let targets = try container.decode([Int].self, forKey: .targets)
        do {
            try self.init(offsets: offsets, targets: targets)
        } catch {
            let key: _CodingKeys = switch error {
            case .emptyOffsets, .firstOffsetNotZero, .decreasingOffsets, .lastOffsetMismatch: .offsets
            case .targetOutOfRange, .unsortedRow, .duplicateEdge: .targets
            }
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: container.codingPath + [key],
                debugDescription: "Invalid compressed sparse row arrays: \(error)",
                underlyingError: error
            ))
        }
    }
}

extension CompressedSparseRow: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0→1, 1→2]`. The same form as
    /// every other representation, so equal graphs print alike.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 edges.
    public var debugDescription: String {
        "CompressedSparseRow(vertexCount: \(vertexCount), edgeCount: \(edgeCount), edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// Shows `offsets` and `targets`, the storage itself, so a debugger can browse it.
    public var customMirror: Mirror {
        Mirror(self, children: ["offsets": _offsets, "targets": _targets], displayStyle: .struct)
    }
}

// MARK: - DirectedGraph

extension CompressedSparseRow: DirectedGraph {
    /// The edge indices of the edges leaving `vertex`: `offsets[vertex] ..< offsets[vertex + 1]`,
    /// the indices of `successors(of: vertex)`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outEdges(of vertex: Int) -> Range<Int> {
        _checkVertex(vertex)
        return _offsets[vertex] ..< _offsets[vertex + 1]
    }

    /// The edges' positions are their own indices: slot `k` of `targets`.
    @inlinable
    public var edgeIndexBound: Int? { edgeCount }

    /// The position itself. O(1).
    @inlinable
    public func edgeIndex(of position: Int) -> Int { position }

    /// The vertices are their own indices.
    @inlinable
    public var vertexIndexBound: Int? { vertexCount }

    /// `vertex` itself.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return vertex
    }

    /// `index` itself.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func vertex(atIndex index: Int) -> Int {
        _checkVertex(index)
        return index
    }

    /// The successors themselves, since vertices are their own indices.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> ArraySlice<Int> { successors(of: index) }

    /// The offsets and targets themselves.
    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        withUnsafeBufferPointers { offsets, targets in body(offsets, targets) }
    }
}

extension CompressedSparseRow {
    /// The compressed sparse row form of any directed graph on the vertices
    /// `0..<graph.vertexCount`, with parallel edges collapsed. The edges are read in place.
    ///
    /// - Precondition: the vertices are exactly `0..<graph.vertexCount`. Other numberings are not
    ///   inferred or renumbered; use `init(vertexCount:edges:)`.
    @inlinable
    public init(_ graph: some DirectedGraph<Int>) {
        if let same = graph as? CompressedSparseRow {
            self = same
            return
        }
        let n = graph.vertexCount
        for v in graph.vertices {
            precondition(v >= 0 && v < n, "Vertex \(v) is not in 0..<\(n); the vertices must be exactly 0..<vertexCount")
        }
        self.init(vertexCount: n, edges: graph.edges)
    }
}
