// Conversions between the walk types, as initializers (Swift's convention: `Array(set)`,
// `Int(exactly:)`). Upward ones cannot fail and share storage; a closed walk opens by repeating
// its start at the end. Downward ones check the stronger rules and return `nil` when they fail.

extension Walk {
    /// The trail as a walk. O(1).
    @inlinable
    public init(_ trail: Trail<Vertex, Edge>) {
        self.init(_uncheckedVertices: trail._vertices, edges: trail._edges)
    }

    /// The path as a walk. O(1).
    @inlinable
    public init(_ path: Path<Vertex, Edge>) {
        self.init(_uncheckedVertices: path._vertices, edges: path._edges)
    }

    /// The circuit as a closed walk, its start repeated at the end. O(n).
    @inlinable
    public init(_ circuit: Circuit<Vertex, Edge>) {
        self.init(_uncheckedVertices: circuit._vertices + [circuit._vertices[0]], edges: circuit._edges)
    }

    /// The cycle as a closed walk, its start repeated at the end. O(n).
    @inlinable
    public init(_ cycle: Cycle<Vertex, Edge>) {
        self.init(_uncheckedVertices: cycle._vertices + [cycle._vertices[0]], edges: cycle._edges)
    }

    /// This walk followed by `other` (JGraphT's `concat`).
    ///
    /// - Precondition: `target == other.source`.
    @inlinable
    public func appending(_ other: Walk) -> Walk {
        var result = self
        result.append(other)
        return result
    }

    /// Appends `other`, which starts where this walk ends.
    ///
    /// - Precondition: `target == other.source`.
    @inlinable
    public mutating func append(_ other: Walk) {
        precondition(target == other.source, "The walk appended must start where this one ends")
        _vertices.append(contentsOf: other._vertices.dropFirst())
        _edges.append(contentsOf: other._edges)
    }
}

extension Trail {
    /// The path as a trail: a path never repeats an edge. O(1).
    @inlinable
    public init(_ path: Path<Vertex, Edge>) {
        self.init(_uncheckedVertices: path._vertices, edges: path._edges)
    }

    /// The circuit as a closed trail, its start repeated at the end. O(n).
    @inlinable
    public init(_ circuit: Circuit<Vertex, Edge>) {
        self.init(_uncheckedVertices: circuit._vertices + [circuit._vertices[0]], edges: circuit._edges)
    }

    /// The cycle as a closed trail, its start repeated at the end. O(n).
    @inlinable
    public init(_ cycle: Cycle<Vertex, Edge>) {
        self.init(_uncheckedVertices: cycle._vertices + [cycle._vertices[0]], edges: cycle._edges)
    }

    /// The walk as a trail, or `nil` when it repeats an edge.
    @inlinable
    public init?(_ walk: Walk<Vertex, Edge>) {
        self.init(vertices: walk._vertices, edges: walk._edges)
    }
}

extension Path {
    /// The walk as a path, or `nil` when it repeats a vertex.
    @inlinable
    public init?(_ walk: Walk<Vertex, Edge>) {
        self.init(vertices: walk._vertices, edges: walk._edges)
    }

    /// The trail as a path, or `nil` when it repeats a vertex.
    @inlinable
    public init?(_ trail: Trail<Vertex, Edge>) {
        self.init(vertices: trail._vertices, edges: trail._edges)
    }
}

extension Circuit {
    /// The cycle as a circuit. O(1).
    @inlinable
    public init(_ cycle: Cycle<Vertex, Edge>) {
        self.init(_uncheckedVertices: cycle._vertices, edges: cycle._edges)
    }

    /// The closed walk as a circuit, its repeated end dropped; `nil` when it is not closed, is
    /// trivial, or repeats an edge.
    @inlinable
    public init?(_ walk: Walk<Vertex, Edge>) {
        guard !walk.isTrivial, walk.isClosed else { return nil }
        self.init(vertices: Array(walk._vertices.dropLast()), edges: walk._edges)
    }

    /// The closed trail as a circuit; `nil` when it is not closed or is trivial.
    @inlinable
    public init?(_ trail: Trail<Vertex, Edge>) {
        guard !trail.isTrivial, trail.isClosed else { return nil }
        self.init(vertices: Array(trail._vertices.dropLast()), edges: trail._edges)
    }
}

extension Cycle {
    /// The closed walk as a cycle, its repeated end dropped; `nil` when it is not closed, is
    /// trivial, or repeats a vertex (other than closing) or an edge.
    @inlinable
    public init?(_ walk: Walk<Vertex, Edge>) {
        guard !walk.isTrivial, walk.isClosed else { return nil }
        self.init(vertices: Array(walk._vertices.dropLast()), edges: walk._edges)
    }

    /// The closed trail as a cycle; `nil` when it is not closed, is trivial, or repeats a vertex.
    @inlinable
    public init?(_ trail: Trail<Vertex, Edge>) {
        guard !trail.isTrivial, trail.isClosed else { return nil }
        self.init(vertices: Array(trail._vertices.dropLast()), edges: trail._edges)
    }

    /// The circuit as a cycle, or `nil` when it repeats a vertex.
    @inlinable
    public init?(_ circuit: Circuit<Vertex, Edge>) {
        self.init(vertices: circuit._vertices, edges: circuit._edges)
    }
}
