import GraphProtocols
import Multigraphs

/// A vertex drawn with probability proportional to its count in `ends` plus `delta`: with
/// probability nδ / (nδ + |ends|) a uniform vertex of `0..<vertexCount` (only when δ > 0), else a
/// uniform entry of `ends`.
@inlinable
@inline(__always)
func _scaleFreeChoice<G: RandomNumberGenerator>(_ ends: [Int], _ vertexCount: Int, _ delta: Double, _ g: inout G) -> Int {
    if delta > 0 {
        let bias = Double(vertexCount) * delta
        if _uniform01(&g) < bias / (bias + Double(ends.count)) { return _below(vertexCount, &g) }
    }
    return ends[_below(ends.count, &g)]
}

extension DirectedPseudograph where Vertex == Int {
    /// The directed scale-free graph of Bollobás, Borgs, Chayes and Riordan, whose in- and
    /// out-degrees both follow power laws:
    ///
    /// > Béla Bollobás, Christian Borgs, Jennifer Chayes and Oliver Riordan. Directed scale-free
    /// > graphs. *Proceedings of the 14th ACM–SIAM Symposium on Discrete Algorithms* (SODA 2003),
    /// > 132–139.
    ///
    /// It starts from the directed cycle 0 → 1 → 2 → 0 and adds one arc per step until there are
    /// `vertexCount` vertices. With probability α the step adds a new vertex v → w; with
    /// probability β an arc v → w between existing vertices; otherwise (γ) an arc v → w to a new
    /// vertex w. An existing source is drawn with probability proportional to its out-degree plus
    /// `deltaOut`, an existing target to its in-degree plus `deltaIn`: with probability
    /// nδ/(nδ + m) a uniform vertex (new ones included), else the source (or target) of a uniform
    /// arc. New vertices take the next number. Self-loops and parallel arcs occur. The arcs are at
    /// positions `0..<m` in the order they were added, the cycle first.
    ///
    /// - Complexity: O(m) expected, with m ≈ (n − 3)/(α + γ) + 3 arcs.
    /// - Precondition: `vertexCount ≥ 3`; α, β and γ positive, summing to 1 within 10⁻⁹; and
    ///   `deltaIn`, `deltaOut` non-negative and finite.
    @inlinable
    public static func scaleFree(
        vertexCount n: Int, alpha: Double = 0.41, beta: Double = 0.54, gamma: Double = 0.05,
        deltaIn: Double = 0.2, deltaOut: Double = 0, using generator: inout some RandomNumberGenerator
    ) -> DirectedPseudograph {
        precondition(n >= 3, "vertexCount \(n) < 3, the starting cycle")
        precondition(alpha > 0 && beta > 0 && gamma > 0, "alpha, beta and gamma must be positive")
        precondition(abs(alpha + beta + gamma - 1) < 1e-9, "alpha + beta + gamma \(alpha + beta + gamma) is not 1")
        precondition(deltaIn >= 0 && deltaIn.isFinite, "deltaIn \(deltaIn) is negative or not finite")
        precondition(deltaOut >= 0 && deltaOut.isFinite, "deltaOut \(deltaOut) is negative or not finite")
        // Each vertex once per arc it is the source (or target) of: the cycle's vertices in order,
        // then each new arc's ends, so arc i ≥ 3 is sources[i] → targets[i].
        var sources = [0, 1, 2], targets = [0, 1, 2]
        var count = 3
        while count < n {
            let r = _uniform01(&generator)
            let v: Int, w: Int
            if r < alpha {
                v = count
                count += 1
                w = _scaleFreeChoice(targets, count, deltaIn, &generator)
            } else if r < alpha + beta {
                v = _scaleFreeChoice(sources, count, deltaOut, &generator)
                w = _scaleFreeChoice(targets, count, deltaIn, &generator)
            } else {
                v = _scaleFreeChoice(sources, count, deltaOut, &generator)
                w = count
                count += 1
            }
            sources.append(v)
            targets.append(w)
        }
        // The cycle's arcs, then the added ones, as inserting them in order would leave them.
        sources[0 ..< 3] = [0, 1, 2]
        targets[0 ..< 3] = [1, 2, 0]
        return _built(vertices: ContiguousArray(0 ..< n), sourceKeys: sources, targetKeys: targets, reportingPositions: false,
                      _ConstructionToken()).graph
    }

    /// `scaleFree(vertexCount:alpha:beta:gamma:deltaIn:deltaOut:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func scaleFree(
        vertexCount n: Int, alpha: Double = 0.41, beta: Double = 0.54, gamma: Double = 0.05,
        deltaIn: Double = 0.2, deltaOut: Double = 0
    ) -> DirectedPseudograph {
        var generator = SystemRandomNumberGenerator()
        return scaleFree(vertexCount: n, alpha: alpha, beta: beta, gamma: gamma, deltaIn: deltaIn, deltaOut: deltaOut, using: &generator)
    }
}
