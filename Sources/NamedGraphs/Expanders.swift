import GraphProtocols

// Expander families on arithmetic: Margulis–Gabber–Galil on ℤₙ², the chordal cycle and the Paley
// graph on a prime field.

/// Whether `p` is prime, by trial division. O(√p).
@usableFromInline
package func _isPrime(_ p: Int) -> Bool {
    if p < 2 { return false }
    if p < 4 { return true }
    if p % 2 == 0 { return false }
    var d = 3
    while d <= p / d {
        if p % d == 0 { return false }
        d += 2
    }
    return true
}

/// The Margulis–Gabber–Galil graph's edges: (x, y) – (x + 2y, y), (x + 2y + 1, y), (x, y + 2x),
/// (x, y + 2x + 1) mod n, vertex (x, y) numbered x·n + y, as a simple graph: self-loops dropped and
/// repeats merged, sorted.
@usableFromInline
func _margulisGabberGalilPairs(_ n: Int) -> [DirectedEdge<Int>] {
    precondition(n >= 1, "a Margulis–Gabber–Galil graph needs a side of at least 1, not \(n)")
    precondition(_productFits(n, n) && _productFits(n * n, 4), "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(4 * n * n)
    for x in 0 ..< n {
        for y in 0 ..< n {
            let v = x * n + y
            for (a, b) in [((x + 2 * y) % n, y), ((x + 2 * y + 1) % n, y), (x, (y + 2 * x) % n), (x, (y + 2 * x + 1) % n)] {
                let w = a * n + b
                if w != v { pairs.append(DirectedEdge(from: v, to: w)) }
            }
        }
    }
    return _sortedPairs(vertexCount: n * n, pairs)
}

/// The chordal cycle graph's edges on the prime field: x – x + 1, x – x − 1, and x – x⁻¹ for x ≠ 0,
/// as a simple graph, sorted.
@usableFromInline
func _chordalCyclePairs(_ p: Int) -> [DirectedEdge<Int>] {
    precondition(_isPrime(p), "a chordal cycle graph needs a prime, not \(p)")
    precondition(_productFits(p, 3), "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(3 * p)
    for x in 0 ..< p {
        let next = (x + 1) % p
        if next != x { pairs.append(DirectedEdge(from: x, to: next)) }
        if x != 0 {
            // x⁻¹ by Fermat: x^(p − 2) mod p, by squaring.
            var base = x
            var exponent = p - 2
            var inverse = 1
            while exponent > 0 {
                if exponent & 1 == 1 { inverse = Int((UInt64(inverse) * UInt64(base)) % UInt64(p)) }
                base = Int((UInt64(base) * UInt64(base)) % UInt64(p))
                exponent >>= 1
            }
            if inverse != x { pairs.append(DirectedEdge(from: x, to: inverse)) }
        }
    }
    return _sortedPairs(vertexCount: p, pairs)
}

/// The nonzero squares of the prime field, as a membership table.
@usableFromInline
func _primeSquares(_ p: Int) -> [Bool] {
    var square = [Bool](repeating: false, count: p)
    for x in 1 ..< max(p, 1) { square[Int((UInt64(x) * UInt64(x)) % UInt64(p))] = true }
    return square
}

/// The Paley digraph's arcs on the prime field: x → y when y − x is a nonzero square, in row-major
/// order. For p ≡ 1 (mod 4) each arc has its reverse, for p ≡ 3 (mod 4) exactly one of each pair.
@usableFromInline
func _paleyArcs(_ p: Int) -> [DirectedEdge<Int>] {
    precondition(_isPrime(p), "a Paley graph needs a prime, not \(p)")
    precondition(_productFits(p, p), "edge count overflows Int")
    let square = _primeSquares(p)
    var arcs: [DirectedEdge<Int>] = []
    arcs.reserveCapacity(p * (p - 1) / 2)
    for x in 0 ..< p {
        for y in 0 ..< p where square[((y - x) % p + p) % p] {
            arcs.append(DirectedEdge(from: x, to: y))
        }
    }
    return arcs
}

extension _GraphConstruction {
    /// The Margulis–Gabber–Galil graph on `side²` vertices, vertex (x, y) of ℤ_side² numbered
    /// x·side + y, each joined to (x + 2y, y), (x + 2y + 1, y), (x, y + 2x) and (x, y + 2x + 1),
    /// mod `side`. An expander: every vertex has at most 8 neighbors and the family's spectral gap
    /// is bounded away from zero. Built as a simple graph, so a step that returns to its vertex is
    /// dropped and two steps that meet are one edge. Sorted. O(side²).
    ///
    /// - Precondition: `side ≥ 1`, with 4·side² fitting in `Int`.
    @inlinable
    public static func margulisGabberGalil(side n: Int) -> Self {
        Self(_vertexCount: n * n, sortedEdges: _margulisGabberGalilPairs(n).lazy.map(_undirected), _ConstructionToken())
    }

    /// The chordal cycle graph on the prime field ℤ_p: the cycle 0 – 1 – … – (p − 1) – 0 with a
    /// chord from each nonzero x to its inverse x⁻¹ mod p. An expander (Lubotzky). Built as a
    /// simple graph: a vertex that is its own inverse (1 and p − 1) has no chord. Sorted. O(p log p).
    ///
    /// - Precondition: `prime` is prime.
    @inlinable
    public static func chordalCycle(prime p: Int) -> Self {
        Self(_vertexCount: p, sortedEdges: _chordalCyclePairs(p).lazy.map(_undirected), _ConstructionToken())
    }

    /// The Paley graph on the prime field ℤ_p: x – y when y − x is a nonzero square mod p, which
    /// is symmetric exactly when p ≡ 1 (mod 4). (p − 1)/2-regular, self-complementary, a strongly
    /// regular expander. Sorted. O(p²).
    ///
    /// - Precondition: `prime` is prime and `prime % 4 == 1`.
    @inlinable
    public static func paley(prime p: Int) -> Self {
        let arcs = _paleyArcs(p)
        precondition(p % 4 == 1, "the Paley graph is undirected only for a prime ≡ 1 (mod 4), not \(p)")
        return Self(_vertexCount: p, sortedEdges: arcs.lazy.filter { $0.source < $0.target }.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The Margulis–Gabber–Galil graph with both arcs of every edge, in row-major order. O(side²).
    ///
    /// - Precondition: as for the undirected form, with twice the edge count fitting in `Int`.
    @inlinable
    public static func margulisGabberGalil(side n: Int) -> Self {
        Self(_vertexCount: n * n, sortedEdges: _bothArcs(vertexCount: n * n, _margulisGabberGalilPairs(n)), _ConstructionToken())
    }

    /// The chordal cycle graph with both arcs of every edge, in row-major order. O(p log p).
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func chordalCycle(prime p: Int) -> Self {
        Self(_vertexCount: p, sortedEdges: _bothArcs(vertexCount: p, _chordalCyclePairs(p)), _ConstructionToken())
    }

    /// The Paley digraph on the prime field ℤ_p: x → y when y − x is a nonzero square mod p. For
    /// p ≡ 1 (mod 4) it is the Paley graph with both arcs of every edge; for p ≡ 3 (mod 4) it is
    /// the Paley tournament, one arc between every two vertices. Row-major. O(p²).
    ///
    /// - Precondition: `prime` is prime.
    @inlinable
    public static func paley(prime p: Int) -> Self {
        Self(_vertexCount: p, sortedEdges: _paleyArcs(p), _ConstructionToken())
    }
}
