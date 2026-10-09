import GraphProtocols

/// A spanning forest of an undirected graph: one spanning tree per connected component, as edge
/// positions in the graph's `edges`, with the sum of their weights (JGraphT's `SpanningTree`,
/// whose `getEdges` and `getWeight` these are).
///
/// Equality compares the edges in order and the weight, not which graph the forest came from.
/// The canonical forests (`minimumSpanningTree(weight:)`, Kruskal, the maximum) come in a fixed
/// order, so equal answers are equal values; Prim's and Borůvka's orders differ, so compare their
/// edges as sets.
///
/// A forest of a graph with `n` vertices and `c` connected components has `n − c` edges. It never
/// contains a self-loop, and of a set of parallel edges at most one.
///
/// The forest does not hold a copy of the graph. Its positions are valid for as long as the
/// graph's positions are, that is, until the graph is mutated.
@frozen
public struct SpanningForest<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    /// The forest's edges, as positions in the graph's `edges`, in the order the algorithm added
    /// them (each algorithm documents its order).
    public let edges: [G.Edges.Index]

    /// The sum of the forest's edge weights, added up in `edges` order; zero with no edges.
    public let weight: Weight

    @inlinable
    init(edges: [G.Edges.Index], weight: Weight) {
        precondition(weight == weight, "A spanning forest's total weight is NaN (+∞ and −∞ both in the forest)")
        self.edges = edges
        self.weight = weight
    }
}

extension SpanningForest: Equatable {}
extension SpanningForest: Hashable where Weight: Hashable {}
extension SpanningForest: Sendable where G.Edges.Index: Sendable, Weight: Sendable {}

/// The graph's edges by rank (their offset in `edges`): endpoints as vertex identifiers, `u == -1`
/// for a self-loop, which is never weighed; positions; and each non-loop edge's (weight, rank),
/// in the order gathered.
@frozen
@usableFromInline
struct _RankedEdges<Position, W: Comparable & AdditiveArithmetic> {
    @usableFromInline var u: [Int]
    @usableFromInline var v: [Int]
    @usableFromInline var position: [Position]
    @usableFromInline var keyed: [(W, Int)]
    /// The number of vertex identifiers.
    @usableFromInline var vertexCount: Int

    @inlinable
    init(u: [Int], v: [Int], position: [Position], keyed: [(W, Int)], vertexCount: Int) {
        self.u = u
        self.v = v
        self.position = position
        self.keyed = keyed
        self.vertexCount = vertexCount
    }

    /// Moves the (weight, rank) pairs out, leaving them empty, so sorting them copies nothing.
    @inlinable
    mutating func takeKeyed() -> [(W, Int)] {
        var keyed: [(W, Int)] = []
        swap(&keyed, &self.keyed)
        return keyed
    }
}

extension Graph {
    /// Every edge by rank, each that is not a self-loop weighed once, between vertex identifiers:
    /// the graph's vertex indices when it has them, otherwise offsets in `vertices`. With vertex
    /// and edge indices the edges come from the index-space rows, each taken at its lower end
    /// and stored at its edge index, which by the edge-order law is its rank; the algorithm
    /// itself hashes nothing (a view's rows may: `UndirectedView` looks each row's vertex up in
    /// its base). Otherwise from `edges`, in order, looking each endpoint up once: by
    /// `vertexIndex(of:)` with vertex indices, else in a dictionary.
    @inlinable
    func _rankedEdges<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> _RankedEdges<Edges.Index, W> {
        let m = edgeCount
        guard m > 0 else { return _RankedEdges(u: [], v: [], position: [], keyed: [], vertexCount: vertexCount) }
        var us = [Int](repeating: -1, count: m)
        var vs = [Int](repeating: -1, count: m)
        var positions = [Edges.Index](repeating: edges.startIndex, count: m)
        var keyed: [(W, Int)] = []
        keyed.reserveCapacity(m)
        if let n = vertexIndexBound, edgeIndexBound != nil {
            for u in 0 ..< n {
                for (v, position) in zip(neighborIndices(ofIndex: u), incidentEdges(ofIndex: u)) where u < v {
                    let w = weight(position)
                    precondition(w == w, "An edge weight is NaN")
                    let rank = edgeIndex(of: position)
                    us[rank] = u
                    vs[rank] = v
                    positions[rank] = position
                    keyed.append((w, rank))
                }
            }
            return _RankedEdges(u: us, v: vs, position: positions, keyed: keyed, vertexCount: n)
        }
        let indexed = vertexIndexBound != nil
        let ids = indexed ? [:] : _numberedVertices()
        for (rank, position) in edges.indices.enumerated() {
            let edge = edges[position]
            let u = indexed ? vertexIndex(of: edge.u) : ids[edge.u]!
            let v = indexed ? vertexIndex(of: edge.v) : ids[edge.v]!
            if u == v { continue }
            let w = weight(position)
            precondition(w == w, "An edge weight is NaN")
            us[rank] = u
            vs[rank] = v
            positions[rank] = position
            keyed.append((w, rank))
        }
        return _RankedEdges(u: us, v: vs, position: positions, keyed: keyed, vertexCount: vertexIndexBound ?? ids.count)
    }

    /// Each vertex's offset in `vertices`, for a graph without vertex indices.
    @inlinable
    func _numberedVertices() -> [Vertex: Int] {
        var ids: [Vertex: Int] = [:]
        ids.reserveCapacity(vertexCount)
        for (i, v) in vertices.enumerated() { ids[v] = i }
        return ids
    }

    /// The forest of the edges `taken` as (weight, rank), its weight added up in that order.
    @inlinable
    static func _forest<W: Comparable & AdditiveArithmetic>(_ taken: [(W, Int)], _ positions: [Edges.Index]) -> SpanningForest<Self, W> {
        var total = W.zero
        var edges: [Edges.Index] = []
        edges.reserveCapacity(taken.count)
        for (w, rank) in taken {
            total += w
            edges.append(positions[rank])
        }
        return SpanningForest(edges: edges, weight: total)
    }
}
