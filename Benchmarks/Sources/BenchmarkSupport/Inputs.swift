import GraphProtocols

/// Deterministic benchmark inputs, so runs compare like with like.
public enum Inputs {
    /// `edgeCount` random edges on `vertexCount` vertices, possibly repeated, in random order.
    public static func randomEdges(vertexCount: Int, edgeCount: Int, seed: UInt = 1) -> [DirectedEdge<Int>] {
        var rng = SeededRandomNumberGenerator(seed: seed)
        return (0 ..< edgeCount).map { _ in
            DirectedEdge(from: Int.random(in: 0 ..< vertexCount, using: &rng), to: Int.random(in: 0 ..< vertexCount, using: &rng))
        }
    }

    /// The same edges, deduplicated and in row-major order.
    public static func sortedUnique(_ edges: [DirectedEdge<Int>]) -> [DirectedEdge<Int>] {
        Set(edges).sorted { ($0.source, $0.target) < ($1.source, $1.target) }
    }

    /// A star: vertex 0 points at each of `leaves` other vertices.
    public static func star(leaves: Int) -> [DirectedEdge<Int>] {
        (1 ... leaves).map { DirectedEdge(from: 0, to: $0) }
    }
}
