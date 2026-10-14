import GraphProtocols

// LCF notation and the cubic graphs it names: the cycle 0 … n − 1, then the chords in the order the
// notation lists them.

/// The edges of the LCF graph, sorted, each once: the n-cycle, and for i in 0 ..< k·r (k shifts,
/// r repeats) the chord (i mod n) – (i + shifts[i mod k]) mod n.
@usableFromInline
func _lcfPairs(_ n: Int, _ shifts: [Int], _ r: Int) -> [DirectedEdge<Int>] {
    precondition(n >= 3, "an LCF graph needs a cycle of at least 3 vertices, not \(n)")
    _checkCount(r, "repeatCount")
    precondition(_productFits(shifts.count, r) && shifts.count * r <= Int.max - n, "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(n + shifts.count * r)
    for i in 0 ..< n { pairs.append(DirectedEdge(from: i, to: (i + 1) % n)) }
    for i in 0 ..< shifts.count * r {
        let shift = shifts[i % shifts.count]
        let u = i % n, v = ((u + shift % n) % n + n) % n
        precondition(v != u, "shift \(shift) is a multiple of vertexCount \(n): a self-loop")
        pairs.append(DirectedEdge(from: u, to: v))
    }
    return _sortedPairs(vertexCount: n, pairs)
}

/// The edges of the LCF graph [shifts]^r on n vertices, cached per named graph.
@usableFromInline
let _heawoodPairs = _lcfPairs(14, [5, -5], 7)
@usableFromInline
let _moebiusKantorPairs = _lcfPairs(16, [5, -5], 8)
@usableFromInline
let _pappusPairs = _lcfPairs(18, [5, 7, -7, 7, -7, -5], 3)
@usableFromInline
let _desarguesPairs = _lcfPairs(20, [5, -5, 9, -9], 5)
@usableFromInline
let _dodecahedralPairs = _lcfPairs(20, [10, 7, 4, -4, -7, 10, -4, 7, -7, 4], 2)
@usableFromInline
let _fruchtPairs = _lcfPairs(12, [-5, -2, -4, 2, 5, -2, 2, 5, -2, -5, 4, 2], 1)

extension _GraphConstruction {
    /// The graph in LCF notation [s₁, …, s_k]^r on `vertexCount` vertices: the cycle
    /// 0 – 1 – … – (n − 1) – 0, and for i in 0 ..< k·r the chord from vertex i mod n to
    /// (i + s_{i mod k}) mod n. Shifts are taken mod n and may be negative. A chord that repeats an
    /// edge adds nothing, so a cubic Hamiltonian graph is written with r·k = n and each chord
    /// listed from both ends. Sorted. O(n + k·r).
    ///
    /// > Harold S. M. Coxeter, Roberto Frucht and David L. Powers. *Zero-Symmetric Graphs:
    /// > Trivalent Graphical Regular Representations of Groups*. Academic Press (1981).
    ///
    /// - Precondition: `vertexCount ≥ 3`, `repeatCount ≥ 0`, and no shift is a multiple of
    ///   `vertexCount` (a self-loop).
    @inlinable
    public static func lcf(vertexCount n: Int, shifts: [Int], repeatCount r: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _lcfPairs(n, shifts, r).lazy.map(_undirected), _ConstructionToken())
    }

    /// The Heawood graph, [5, −5]⁷ on 14 vertices: the incidence graph of the Fano plane, cubic,
    /// of girth 6. O(1).
    @inlinable
    public static func heawood() -> Self {
        Self(_vertexCount: 14, sortedEdges: _heawoodPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Möbius–Kantor graph, [5, −5]⁸ on 16 vertices: the generalized Petersen graph GP(8, 3),
    /// cubic, of girth 6. O(1).
    @inlinable
    public static func moebiusKantor() -> Self {
        Self(_vertexCount: 16, sortedEdges: _moebiusKantorPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Pappus graph, [5, 7, −7, 7, −7, −5]³ on 18 vertices: cubic, of girth 6. O(1).
    @inlinable
    public static func pappus() -> Self {
        Self(_vertexCount: 18, sortedEdges: _pappusPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Desargues graph, [5, −5, 9, −9]⁵ on 20 vertices: the generalized Petersen graph
    /// GP(10, 3), cubic, of girth 6. O(1).
    @inlinable
    public static func desargues() -> Self {
        Self(_vertexCount: 20, sortedEdges: _desarguesPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The dodecahedral graph, the skeleton of the dodecahedron, [10, 7, 4, −4, −7, 10, −4, 7, −7,
    /// 4]² on 20 vertices: cubic, planar, of girth 5. The other Platonic solids are
    /// `complete(vertexCount: 4)` (tetrahedron), `hypercube(dimension: 3)` (cube),
    /// `turan(vertexCount: 6, partCount: 3)` (octahedron) and `icosahedral()`. O(1).
    @inlinable
    public static func dodecahedral() -> Self {
        Self(_vertexCount: 20, sortedEdges: _dodecahedralPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Frucht graph, [−5, −2, −4, 2, 5, −2, 2, 5, −2, −5, 4, 2] on 12 vertices: cubic, with no
    /// automorphism but the identity. O(1).
    ///
    /// > Roberto Frucht. Herstellung von Graphen mit vorgegebener abstrakter Gruppe. *Compositio
    /// > Mathematica* 6, 239–250 (1939).
    @inlinable
    public static func frucht() -> Self {
        Self(_vertexCount: 12, sortedEdges: _fruchtPairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The LCF graph with both arcs of every edge, in row-major order. O(n + k·r).
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func lcf(vertexCount n: Int, shifts: [Int], repeatCount r: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _bothArcs(vertexCount: n, _lcfPairs(n, shifts, r)), _ConstructionToken())
    }

    /// The Heawood graph with both arcs of every edge. O(1).
    @inlinable
    public static func heawood() -> Self {
        Self(_vertexCount: 14, sortedEdges: _bothArcs(vertexCount: 14, _heawoodPairs), _ConstructionToken())
    }

    /// The Möbius–Kantor graph with both arcs of every edge. O(1).
    @inlinable
    public static func moebiusKantor() -> Self {
        Self(_vertexCount: 16, sortedEdges: _bothArcs(vertexCount: 16, _moebiusKantorPairs), _ConstructionToken())
    }

    /// The Pappus graph with both arcs of every edge. O(1).
    @inlinable
    public static func pappus() -> Self {
        Self(_vertexCount: 18, sortedEdges: _bothArcs(vertexCount: 18, _pappusPairs), _ConstructionToken())
    }

    /// The Desargues graph with both arcs of every edge. O(1).
    @inlinable
    public static func desargues() -> Self {
        Self(_vertexCount: 20, sortedEdges: _bothArcs(vertexCount: 20, _desarguesPairs), _ConstructionToken())
    }

    /// The dodecahedral graph with both arcs of every edge. O(1).
    @inlinable
    public static func dodecahedral() -> Self {
        Self(_vertexCount: 20, sortedEdges: _bothArcs(vertexCount: 20, _dodecahedralPairs), _ConstructionToken())
    }

    /// The Frucht graph with both arcs of every edge. O(1).
    @inlinable
    public static func frucht() -> Self {
        Self(_vertexCount: 12, sortedEdges: _bothArcs(vertexCount: 12, _fruchtPairs), _ConstructionToken())
    }
}
