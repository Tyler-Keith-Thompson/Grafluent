import GraphProtocols
import NamedGraphs

/// The stochastic Kronecker graph's edges: on `base^k` vertices, the pair (u, v) has probability
/// ∏ᵢ initiator[uᵢ][vᵢ] over the base-`base` digits of u and v, and is drawn with one `uniform01`
/// per pair in row-major order, loops skipped; undirected, only the pairs with u < v are drawn.
@inlinable
func _kroneckerPairs<G: RandomNumberGenerator>(_ initiator: [[Double]], _ k: Int, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    let base = initiator.count
    precondition(base >= 1 && initiator.allSatisfy { $0.count == base }, "The initiator must be a square matrix with at least one row")
    for row in initiator {
        for p in row { precondition(p.isFinite && p >= 0 && p <= 1, "An initiator entry must be in 0...1, not \(p)") }
    }
    precondition(k >= 0, "iterations \(k) is negative")
    var n = 1
    for _ in 0 ..< k {
        precondition(_productFits(n, base), "vertex count overflows Int")
        n *= base
    }
    precondition(_productFits(n, n), "pair count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    for u in 0 ..< n {
        for v in (directed ? 0 : u + 1) ..< n where v != u {
            var p = 1.0
            var a = u, b = v
            for _ in 0 ..< k {
                p *= initiator[a % base][b % base]
                a /= base
                b /= base
            }
            if _uniform01(&g) < p { pairs.append(DirectedEdge(from: u, to: v)) }
        }
    }
    return pairs
}

extension _GraphConstruction {
    /// A stochastic Kronecker graph: the initiator matrix's k-th Kronecker power read as edge
    /// probabilities, which gives self-similar graphs with heavy-tailed degrees and shrinking
    /// diameters.
    ///
    /// > Jure Leskovec, Deepayan Chakrabarti, Jon Kleinberg, Christos Faloutsos and Zoubin
    /// > Ghahramani. Kronecker graphs: an approach to modeling networks. *Journal of Machine
    /// > Learning Research* 11 (2010).
    ///
    /// With an initiator of N rows the graph has Nᵏ vertices, and the pair (u, v) is an edge with
    /// probability ∏ᵢ initiator[uᵢ][vᵢ] over the base-N digits of u and v, drawn independently
    /// with one draw per pair with u < v in row-major order. A self-loop is never drawn. Pass a
    /// symmetric initiator for an undirected graph; an asymmetric one weighs the pair by the
    /// digits of its lower end against those of its higher end.
    ///
    /// - Complexity: O(N²ᵏ · k): every pair is drawn, so the graph is for a few thousand vertices.
    /// - Precondition: `initiator` is square with at least one row and entries in 0...1;
    ///   `iterations` at least zero; the number of pairs fits in `Int`.
    @inlinable
    public static func stochasticKronecker(initiator: [[Double]], iterations k: Int, using generator: inout some RandomNumberGenerator) -> Self {
        let pairs = _kroneckerPairs(initiator, k, directed: false, &generator)
        var n = 1
        for _ in 0 ..< k { n *= initiator.count }
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// `stochasticKronecker(initiator:iterations:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func stochasticKronecker(initiator: [[Double]], iterations k: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return stochasticKronecker(initiator: initiator, iterations: k, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// A stochastic Kronecker digraph: every ordered pair (u, v) with u ≠ v is an arc with
    /// probability ∏ᵢ initiator[uᵢ][vᵢ], drawn independently in row-major order, one draw per
    /// pair. A self-loop is never drawn.
    ///
    /// - Complexity: O(N²ᵏ · k).
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func stochasticKronecker(initiator: [[Double]], iterations k: Int, using generator: inout some RandomNumberGenerator) -> Self {
        let pairs = _kroneckerPairs(initiator, k, directed: true, &generator)
        var n = 1
        for _ in 0 ..< k { n *= initiator.count }
        return Self(_vertexCount: n, sortedEdges: pairs, _ConstructionToken())
    }

    /// `stochasticKronecker(initiator:iterations:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func stochasticKronecker(initiator: [[Double]], iterations k: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return stochasticKronecker(initiator: initiator, iterations: k, using: &generator)
    }
}
