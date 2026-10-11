/// A position in the plane for each vertex, in a fixed vertex order: what every layout in this
/// module returns, and what a caller passes as a starting drawing.
///
/// A drawing is coordinates and nothing else. It holds no sizes, shapes, labels or styles;
/// rendering is the caller's. A layout lists its graph's vertices in `vertices` order, and its
/// units are its own: separation 1 for tree and layered drawings, the optimal distance for
/// Fruchterman–Reingold, edge lengths for stress majorization. `rescaled(scale:center:)` maps any
/// drawing to a common frame.
///
/// The drawing is a random-access collection of `(vertex, position)` pairs in order, indexed by
/// offset. Look a vertex up with `position(of:)` (traps when absent) or `position(safe:)` (`nil`),
/// and move it with `setPosition(_:of:)`; `positions` is the whole column, for loops in index
/// space. Lookup is the offset itself when the vertices are the `Int`s `0..<n` in order, and one
/// hash otherwise.
///
/// Two drawings are equal when they list the same vertices with the same positions in the same
/// order.
@frozen
public struct Drawing<Vertex: Hashable> {
    @usableFromInline var _vertices: ContiguousArray<Vertex>
    @usableFromInline var _positions: [SIMD2<Double>]
    /// Each vertex's offset; empty when `_dense`.
    @usableFromInline var _offsets: [Vertex: Int]
    /// Whether the vertices are the `Int`s `0..<n` in order, so a vertex is its own offset.
    @usableFromInline var _dense: Bool

    /// The empty drawing.
    @inlinable
    public init() {
        _vertices = []
        _positions = []
        _offsets = [:]
        _dense = true
    }

    /// A drawing that puts `vertices[i]` at `positions[i]`.
    ///
    /// - Precondition: the two sequences have the same length, and no vertex is repeated.
    @inlinable
    public init(vertices: some Sequence<Vertex>, positions: some Sequence<SIMD2<Double>>) {
        let listed = ContiguousArray(vertices)
        let points = Array(positions)
        precondition(listed.count == points.count, "A drawing needs one position per vertex: \(listed.count) vertices, \(points.count) positions")
        self.init(_vertices: listed, positions: points)
    }

    /// The drawing of distinct `vertices` at `positions` (equal lengths), with `offsets` when the
    /// caller already has the table.
    @inlinable
    init(_vertices vertices: ContiguousArray<Vertex>, positions: [SIMD2<Double>], offsets: [Vertex: Int]? = nil) {
        _vertices = vertices
        _positions = positions
        if Self._isDense(vertices) {
            _offsets = [:]
            _dense = true
        } else if let offsets, offsets.count == vertices.count {
            _offsets = offsets
            _dense = false
        } else {
            var table: [Vertex: Int] = [:]
            table.reserveCapacity(vertices.count)
            for (i, v) in vertices.enumerated() {
                precondition(table.updateValue(i, forKey: v) == nil, "A vertex appears twice in a drawing: \(v)")
            }
            _offsets = table
            _dense = false
        }
    }

    /// Whether the vertices are the `Int`s `0..<n` in order.
    @inlinable
    static func _isDense(_ vertices: ContiguousArray<Vertex>) -> Bool {
        guard Vertex.self == Int.self else { return false }
        for (i, v) in vertices.enumerated() where unsafeBitCast(v, to: Int.self) != i { return false }
        return true
    }

    /// The vertices, in the drawing's order.
    @inlinable
    public var vertices: ContiguousArray<Vertex> { _vertices }

    /// The positions, parallel to `vertices`: `positions[i]` is the position of `vertices[i]`.
    ///
    /// - Precondition (set): the count stays `vertices.count`.
    @inlinable
    public var positions: [SIMD2<Double>] {
        get { _positions }
        set {
            precondition(newValue.count == _vertices.count, "A drawing needs one position per vertex")
            _positions = newValue
        }
        _modify {
            yield &_positions
            precondition(_positions.count == _vertices.count, "A drawing needs one position per vertex")
        }
    }

    /// The offset of `vertex` in `vertices`, or `nil` when it is not drawn.
    @inlinable
    func _offset(of vertex: Vertex) -> Int? {
        if _dense {
            guard Vertex.self == Int.self else { return nil }
            let i = unsafeBitCast(vertex, to: Int.self)
            return UInt(bitPattern: i) < UInt(bitPattern: _vertices.count) ? i : nil
        }
        return _offsets[vertex]
    }

    /// The position of `vertex`.
    ///
    /// - Precondition: `vertex` is in the drawing.
    @inlinable
    public func position(of vertex: Vertex) -> SIMD2<Double> {
        guard let i = _offset(of: vertex) else { preconditionFailure("The vertex is not in the drawing: \(vertex)") }
        return _positions[i]
    }

    /// The position of `vertex`, or `nil` when it is not in the drawing.
    @inlinable
    public func position(safe vertex: Vertex) -> SIMD2<Double>? {
        _offset(of: vertex).map { _positions[$0] }
    }

    /// Moves `vertex` to `position`.
    ///
    /// - Precondition: `vertex` is in the drawing.
    @inlinable
    public mutating func setPosition(_ position: SIMD2<Double>, of vertex: Vertex) {
        guard let i = _offset(of: vertex) else { preconditionFailure("The vertex is not in the drawing: \(vertex)") }
        _positions[i] = position
    }

    /// The least and greatest coordinates on each axis, or `nil` for an empty drawing.
    @inlinable
    public var boundingBox: (min: SIMD2<Double>, max: SIMD2<Double>)? {
        guard var low = _positions.first else { return nil }
        var high = low
        for p in _positions {
            low = pointwiseMin(low, p)
            high = pointwiseMax(high, p)
        }
        return (low, high)
    }

    /// The drawing centred on `center` and scaled so that its largest absolute coordinate,
    /// measured from the mean position over both axes, is `scale` (NetworkX's `rescale_layout`,
    /// then a translation). The aspect ratio is kept; a drawing whose points all coincide goes to
    /// `center`.
    @inlinable
    public func rescaled(scale: Double = 1, center: SIMD2<Double> = .zero) -> Drawing {
        var copy = self
        copy.rescale(scale: scale, center: center)
        return copy
    }

    /// Rescales in place; see `rescaled(scale:center:)`.
    @inlinable
    public mutating func rescale(scale: Double = 1, center: SIMD2<Double> = .zero) {
        let n = _positions.count
        guard n > 0 else { return }
        var sum = SIMD2<Double>.zero
        for p in _positions { sum += p }
        let mean = sum / Double(n)
        var limit = 0.0
        for p in _positions {
            let q = p - mean
            limit = Swift.max(limit, Swift.max(Swift.abs(q.x), Swift.abs(q.y)))
        }
        for i in 0 ..< n {
            _positions[i] = limit > 0 ? (_positions[i] - mean) * scale / limit + center : center
        }
    }
}

extension Drawing: RandomAccessCollection {
    public typealias Element = (vertex: Vertex, position: SIMD2<Double>)
    public typealias Index = Int
    public typealias Indices = Range<Int>

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _vertices.count }

    /// The vertex at `offset` and its position.
    @inlinable
    public subscript(offset: Int) -> (vertex: Vertex, position: SIMD2<Double>) {
        (_vertices[offset], _positions[offset])
    }
}

extension Drawing: Equatable {
    @inlinable
    public static func == (lhs: Drawing, rhs: Drawing) -> Bool {
        lhs._vertices == rhs._vertices && lhs._positions == rhs._positions
    }
}

extension Drawing: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_vertices.count)
        for v in _vertices { hasher.combine(v) }
        for p in _positions { hasher.combine(p) }
    }
}

extension Drawing: Sendable where Vertex: Sendable {}

extension Drawing: CustomStringConvertible {
    public var description: String {
        "Drawing([" + zip(_vertices, _positions).map { "\($0.0): (\($0.1.x), \($0.1.y))" }.joined(separator: ", ") + "])"
    }
}
