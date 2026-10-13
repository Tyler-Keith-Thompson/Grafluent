import Trees

extension Tree where Vertex == Int {
    /// A uniformly random labeled tree on `0..<vertexCount`: a Prüfer sequence of n − 2 draws
    /// `below(n)`, decoded by `Tree(pruferSequence:)`, whose edge order it keeps (edge k joins the
    /// k-th leaf removed to the k-th code element). Prüfer's bijection between the n^(n − 2)
    /// sequences and the labeled trees makes the result uniform (Cayley's formula):
    ///
    /// > Heinz Prüfer. Neuer Beweis eines Satzes über Permutationen. *Archiv der Mathematik und
    /// > Physik* (3) 27, 142–144 (1918).
    ///
    /// One vertex makes no draws.
    ///
    /// - Complexity: O(n).
    /// - Precondition: `vertexCount ≥ 1`.
    @inlinable
    public static func random(vertexCount n: Int, using generator: inout some RandomNumberGenerator) -> Tree {
        precondition(n >= 1, "a Tree has at least one vertex")
        if n == 1 { return Tree(_vertexCount: 1, treeEnds: []) }
        var code: [Int] = []
        code.reserveCapacity(n - 2)
        for _ in 0 ..< n - 2 { code.append(_below(n, &generator)) }
        return Tree(pruferSequence: code)!
    }

    /// `random(vertexCount:using:)` with the system's random number generator.
    @inlinable
    public static func random(vertexCount n: Int) -> Tree {
        var generator = SystemRandomNumberGenerator()
        return random(vertexCount: n, using: &generator)
    }
}
