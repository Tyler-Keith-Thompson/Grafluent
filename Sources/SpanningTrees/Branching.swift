import GraphProtocols
import Trees

/// A branching of a directed graph: edges with no two into the same vertex and no cycle, so a
/// forest of arborescences. A spanning arborescence is the branching with exactly one root that
/// reaches every vertex.
///
/// The edges are positions in the graph's `edges`, in position order. Equality compares the
/// edges and the weight, not which graph the branching came from. The branching never contains a
/// self-loop, and holds at most one of a set of parallel edges.
///
/// The branching holds no copy of the graph. Its positions stay valid until the graph is mutated.
@frozen
public struct Branching<G: DirectedGraph, Weight: Comparable & AdditiveArithmetic> {
    /// The branching's edges, as positions in the graph's `edges`, in position order.
    public let edges: [G.Edges.Index]

    /// The sum of the edge weights, added up in `edges` order; zero with no edges.
    public let weight: Weight

    @inlinable
    init(edges: [G.Edges.Index], weight: Weight) {
        self.edges = edges
        self.weight = weight
    }
}

extension Branching: Equatable {}
extension Branching: Hashable where Weight: Hashable {}
extension Branching: Sendable where G.Edges.Index: Sendable, Weight: Sendable {}

extension Arborescence {
    /// The spanning arborescence a branching is, over the graph it came from; nil unless the
    /// branching has `graph.vertexCount − 1` edges, so that one root reaches every vertex (and
    /// nil for a graph with no vertices).
    ///
    /// The result holds every vertex of `graph` in `vertices` order and the branching's edges in
    /// `branching.edges` order: the edge at position k is `graph.edges[branching.edges[k]]`.
    ///
    /// - Complexity: O(n) expected. Each vertex and edge end is hashed once, unless the vertices
    ///   are the `Int`s `0..<n` in order.
    /// - Precondition: `branching` is a branching of `graph` as it is now: its positions are
    ///   valid.
    @inlinable
    public init?<G: DirectedGraph, W>(_ branching: Branching<G, W>, in graph: G) where G.Vertex == Vertex {
        self.init(vertices: graph.vertices, edges: branching.edges.lazy.map { graph.edges[$0] })
    }
}

/// A directed graph's edges by rank (their offset in `edges`): each edge's source and target as
/// vertex numbers (vertex indices, or offsets in `vertices`), and its position.
@frozen
@usableFromInline
struct _RankedArcs<Position> {
    @usableFromInline var source: [Int]
    @usableFromInline var target: [Int]
    @usableFromInline var position: [Position]
    /// The number of vertex numbers.
    @usableFromInline let vertexCount: Int

    @inlinable
    init(source: [Int], target: [Int], position: [Position], vertexCount: Int) {
        self.source = source
        self.target = target
        self.position = position
        self.vertexCount = vertexCount
    }
}

extension DirectedGraph {
    /// Every edge by rank, its ends as vertex numbers. With vertex and edge indices the ends come
    /// from the index-space rows, each edge stored at its edge index, which by the edge-order law
    /// is its rank; with vertex indices only, from `sourceIndex(ofEdgeAt:)` and
    /// `targetIndex(ofEdgeAt:)` over `edges`; otherwise each end is looked up once in `numbers`.
    @inlinable
    func _rankedArcs(_ numbers: [Vertex: Int]?) -> _RankedArcs<Edges.Index> {
        let m = edgeCount
        let n = vertexIndexBound ?? numbers?.count ?? vertexCount
        var sources = [Int](repeating: 0, count: m)
        var targets = [Int](repeating: 0, count: m)
        var positions = [Edges.Index](repeating: edges.startIndex, count: m)
        if let numbers {
            for (rank, position) in edges.indices.enumerated() {
                sources[rank] = numbers[source(ofEdgeAt: position)]!
                targets[rank] = numbers[target(ofEdgeAt: position)]!
                positions[rank] = position
            }
        } else if edgeIndexBound != nil {
            for u in 0 ..< n {
                for (v, position) in zip(successorIndices(ofIndex: u), outEdges(ofIndex: u)) {
                    let rank = edgeIndex(of: position)
                    sources[rank] = u
                    targets[rank] = v
                    positions[rank] = position
                }
            }
        } else {
            for (rank, position) in edges.indices.enumerated() {
                sources[rank] = sourceIndex(ofEdgeAt: position)
                targets[rank] = targetIndex(ofEdgeAt: position)
                positions[rank] = position
            }
        }
        return _RankedArcs(source: sources, target: targets, position: positions, vertexCount: n)
    }
}
