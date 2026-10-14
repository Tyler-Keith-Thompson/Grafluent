import AdjacencyListModule
import GraphProtocols
import Multigraphs

// De Bruijn and Kautz graphs: words over an alphabet, with an arc from each word to the words it
// shifts into. A word is numbered by its rank in lexicographic order, and each row's targets
// differ only in their last letter, so they come out ascending.

/// m^n, or nil when it overflows `Int`.
@usableFromInline
func _power(_ m: Int, _ n: Int) -> Int? {
    var p = 1
    for _ in 0 ..< n {
        guard _productFits(p, m) else { return nil }
        p *= m
    }
    return p
}

/// The de Bruijn graph's vertex count and arcs in row-major order: word u (its digits base m)
/// → (u·m mod mⁿ) + a for each letter a. The constant words have a self-loop.
@usableFromInline
func _deBruijnArcs(_ m: Int, _ n: Int) -> (vertexCount: Int, arcs: [DirectedEdge<Int>]) {
    precondition(m >= 1, "alphabetSize \(m) < 1")
    precondition(n >= 1, "wordLength \(n) < 1")
    guard let count = _power(m, n), _productFits(count, m) else { preconditionFailure("count overflows Int") }
    var arcs: [DirectedEdge<Int>] = []
    arcs.reserveCapacity(count * m)
    // u·m mod mⁿ drops u's first letter: (u mod m^(n−1))·m.
    let tail = count / m
    for u in 0 ..< count {
        let base = (u % tail) * m
        for a in 0 ..< m { arcs.append(DirectedEdge(from: u, to: base + a)) }
    }
    return (count, arcs)
}

/// The Kautz graph's vertex count and arcs in row-major order. With q = s − 1, a word w₁…w_L is
/// numbered by its digits d₁ = w₁ and dᵢ = wᵢ, less 1 when wᵢ > wᵢ₋₁ (so dᵢ < q): rank
/// d₁·q^(L−1) + Σ dᵢ·q^(L−i), which orders the words lexicographically. Shifting drops d₁, turns
/// d₂ back into the letter w₂, and appends any digit in `0..<q`.
@usableFromInline
func _kautzArcs(_ s: Int, _ length: Int) -> (vertexCount: Int, arcs: [DirectedEdge<Int>]) {
    precondition(s >= 2, "alphabetSize \(s) < 2")
    precondition(length >= 1, "wordLength \(length) < 1")
    let q = s - 1
    guard let tailCount = _power(q, length - 1), _productFits(s, tailCount), _productFits(s * tailCount, q)
    else { preconditionFailure("count overflows Int") }
    let count = s * tailCount
    var arcs: [DirectedEdge<Int>] = []
    arcs.reserveCapacity(count * q)
    if length == 1 {
        // One-letter words: every other letter.
        for u in 0 ..< s { for v in 0 ..< s where v != u { arcs.append(DirectedEdge(from: u, to: v)) } }
        return (count, arcs)
    }
    let inner = tailCount / q
    for u in 0 ..< count {
        let first = u / tailCount, rest = u % tailCount
        let d2 = rest / inner
        let second = d2 >= first ? d2 + 1 : d2
        let base = second * tailCount + (rest % inner) * q
        for t in 0 ..< q { arcs.append(DirectedEdge(from: u, to: base + t)) }
    }
    return (count, arcs)
}

extension AdjacencyList where Vertex == Int {
    /// The de Bruijn graph B(m, n): a vertex for each word of length `wordLength` over
    /// `alphabetSize` letters, and an arc from each word to the m words its last n − 1 letters
    /// begin. Word a₁…aₙ is vertex Σ aᵢ·m^(n−i), so its successors are (u·m mod mⁿ) + a.
    /// mⁿ vertices, mⁿ⁺¹ arcs, in row-major order; each constant word has a self-loop, so the
    /// graph is built on the representations that allow them. Every vertex has in- and out-degree
    /// m. O(mⁿ⁺¹) expected.
    ///
    /// > Nicolaas G. de Bruijn. A combinatorial problem. *Proceedings of the Koninklijke
    /// > Nederlandse Akademie van Wetenschappen* 49, 758–764 (1946).
    ///
    /// - Precondition: `alphabetSize ≥ 1` and `wordLength ≥ 1`, and mⁿ⁺¹ fits in `Int`.
    @inlinable
    public static func deBruijn(alphabetSize m: Int, wordLength n: Int) -> AdjacencyList {
        let (count, arcs) = _deBruijnArcs(m, n)
        return _built(vertices: ContiguousArray(0 ..< count), sourceKeys: arcs.map(\.source), targetKeys: arcs.map(\.target),
                      reportingPositions: false, _ConstructionToken()).graph
    }
}

extension DirectedPseudograph where Vertex == Int {
    /// The de Bruijn graph B(m, n), numbered as `AdjacencyList.deBruijn(alphabetSize:wordLength:)`,
    /// with its arcs at positions `0..<mⁿ⁺¹` in row-major order. O(mⁿ⁺¹) expected.
    ///
    /// - Precondition: `alphabetSize ≥ 1` and `wordLength ≥ 1`, and mⁿ⁺¹ fits in `Int`.
    @inlinable
    public static func deBruijn(alphabetSize m: Int, wordLength n: Int) -> DirectedPseudograph {
        let (count, arcs) = _deBruijnArcs(m, n)
        return _built(vertices: ContiguousArray(0 ..< count), sourceKeys: arcs.map(\.source), targetKeys: arcs.map(\.target),
                      reportingPositions: false, _ConstructionToken()).graph
    }
}

extension _DirectedGraphConstruction {
    /// The Kautz graph K(s − 1, L − 1): a vertex for each word of length `wordLength` over
    /// `alphabetSize` letters in which no two consecutive letters are equal, and an arc from each
    /// word to the s − 1 words its last L − 1 letters begin. Vertices are numbered by the words in
    /// lexicographic order. s·(s − 1)^(L−1) vertices, each of in- and out-degree s − 1, with no
    /// self-loop; arcs in row-major order. With `wordLength: 1` it is the complete directed graph
    /// on s vertices. O(n·s).
    ///
    /// > William H. Kautz. Bounds on directed (d, k) graphs. *Theory of Cellular Logic Networks
    /// > and Machines*, AFCRL-68-0668 Final Report, 20–28 (1968).
    ///
    /// - Precondition: `alphabetSize ≥ 2` and `wordLength ≥ 1`, and the arc count fits in `Int`.
    @inlinable
    public static func kautz(alphabetSize s: Int, wordLength length: Int) -> Self {
        let (count, arcs) = _kautzArcs(s, length)
        return Self(_vertexCount: count, sortedEdges: arcs, _ConstructionToken())
    }
}
