import Cycles
import GraphProtocols

extension DirectedGraph {
    /// A layered drawing by the Sugiyama framework: every vertex on a horizontal layer, edges
    /// pointing down, long edges bent through every layer they cross, few crossings.
    ///
    /// 1. Cycles are broken by reversing the edges of `feedbackArcSet()` (Eades, Lin and Smyth)
    ///    other than self-loops; a DAG reverses nothing. Self-loops are left out of the drawing.
    /// 2. Layers minimize the total edge span Σ (layer(target) − layer(source)) with every edge
    ///    spanning at least one layer, parallel edges counted each (Gansner et al.'s network
    ///    simplex, solved through its dual min-cost flow as OGDF's `OptimalRanking`); each weakly
    ///    connected component starts at layer 0. Where several layerings are optimal, which one is
    ///    chosen is not specified.
    /// 3. An edge spanning k > 1 layers gets a bend point on each of the k − 1 between.
    /// 4. Crossings are reduced by barycenter sweeps: each layer starts with its vertices in
    ///    `vertices` order, then its bend points by edge position; a sweep sorts layers 1 … L−1 by
    ///    the mean position of each node's neighbours in the layer above, then layers L−2 … 0 by
    ///    those below, stably, a node with no such neighbour keeping its position. The order with
    ///    the fewest crossings seen is kept. Sweeps stop at no crossings, when a sweep changes
    ///    nothing, or after `maxIterations` (igraph's default, 100).
    /// 5. x coordinates are Brandes and Köpf's: four vertical alignments to median neighbours,
    ///    avoiding type-1 conflicts, each compacted by longest path over its blocks at separation
    ///    1, aligned to the narrowest, and averaged by the mean of the two median candidates.
    ///    Then the least x is 0, and y is the layer.
    ///
    /// Layered drawing as a framework: Sugiyama, Tagawa and Toda, "Methods for visual
    /// understanding of hierarchical system structures", IEEE Transactions on Systems, Man, and
    /// Cybernetics 11(2), 1981. Layering: Gansner, Koutsofios, North and Vo, "A technique for
    /// drawing directed graphs", IEEE Transactions on Software Engineering 19(3), 1993.
    /// Coordinates: Brandes and Köpf, "Fast and simple horizontal coordinate assignment", Graph
    /// Drawing (GD 2001), LNCS 2265, 2002. The compaction is longest path rather than the paper's
    /// class shifts, which Brandes, Walter and Zink show can violate the separation ("Erratum:
    /// Fast and simple horizontal coordinate assignment", arXiv:2008.01252, 2020).
    ///
    /// O((n + m) log n) for cycle removal. Network simplex has no polynomial bound and is
    /// superlinear in practice: on random DAGs with m = 2n it takes about 60 ms at n = 10⁴ and
    /// 0.65 s at 4 · 10⁴, growing about as n^1.5 to n^1.7 (release build). O(maxIterations ·
    /// (N + M) log N) for crossing reduction over N vertices and bend points and M segments;
    /// O(N + M) for coordinates.
    ///
    /// - Precondition: `maxIterations ≥ 0`.
    @inlinable
    public func sugiyamaLayout(maxIterations: Int = 100) -> LayeredDrawing<Self> {
        precondition(maxIterations >= 0, "The number of iterations must not be negative")
        return _sugiyamaLayout(layers: nil, maxIterations: maxIterations)
    }

    /// A layered drawing with the caller's layers (igraph's `layers=`): steps 3 to 5 of
    /// `sugiyamaLayout(maxIterations:)` on layer `layers(v)` for each vertex, and y = `layers(v)`.
    /// An edge pointing to a lower layer is reversed (and listed in `reversedEdges`); an edge
    /// within one layer gets no segment and no bends. Layers that no vertex is on are skipped: a
    /// long edge gets a bend on each non-empty layer it crosses, so time and memory do not depend
    /// on how large the layer numbers are (igraph puts a bend on every layer between).
    ///
    /// - Precondition: every layer is at least 0; `maxIterations ≥ 0`.
    @inlinable
    public func sugiyamaLayout(layers: (Vertex) -> Int, maxIterations: Int = 100) -> LayeredDrawing<Self> {
        precondition(maxIterations >= 0, "The number of iterations must not be negative")
        var given: [Int] = []
        given.reserveCapacity(vertexCount)
        for v in vertices {
            let l = layers(v)
            precondition(l >= 0, "A layer must not be negative")
            given.append(l)
        }
        return _sugiyamaLayout(layers: given, maxIterations: maxIterations)
    }

    @inlinable
    func _sugiyamaLayout(layers: [Int]?, maxIterations: Int) -> LayeredDrawing<Self> {
        let arcs = _arcsInPositionOrder()
        let result = _layeredDrawing(vertexCount: arcs.vertexCount, sources: arcs.sources, targets: arcs.targets, layers: layers, maxIterations: maxIterations)
        let drawing = Drawing(_vertices: ContiguousArray(vertices), positions: result.positions)
        return LayeredDrawing(
            drawing: drawing, layers: result.layer, layerCount: result.layerCount, positions: arcs.positions, bendStart: result.bendStart,
            bends: result.bends, reversedEdges: result.reversed.map { arcs.positions[$0] }, crossingCount: result.crossings)
    }
}

/// A layered drawing of a directed graph (`DirectedGraph.sugiyamaLayout(…)`): a position per
/// vertex with y its layer, a layer per vertex, and bend points for every edge that crosses
/// layers. Vertices and bend points in one layer are at least 1 apart; edges point down once the
/// reversed ones are turned.
@frozen
public struct LayeredDrawing<G: DirectedGraph> {
    @usableFromInline let _drawing: Drawing<G.Vertex>
    @usableFromInline let _layers: [Int]
    @usableFromInline let _layerCount: Int
    /// Every edge position, ascending: edge number k is `_positions[k]`.
    @usableFromInline let _positions: [G.Edges.Index]
    @usableFromInline let _bendStart: [Int]
    @usableFromInline let _bends: [SIMD2<Double>]
    @usableFromInline let _reversedEdges: [G.Edges.Index]
    @usableFromInline let _crossingCount: Int

    @inlinable
    init(
        drawing: Drawing<G.Vertex>, layers: [Int], layerCount: Int, positions: [G.Edges.Index], bendStart: [Int], bends: [SIMD2<Double>],
        reversedEdges: [G.Edges.Index], crossingCount: Int
    ) {
        _drawing = drawing
        _layers = layers
        _layerCount = layerCount
        _positions = positions
        _bendStart = bendStart
        _bends = bends
        _reversedEdges = reversedEdges
        _crossingCount = crossingCount
    }

    /// The vertices' positions, in the graph's `vertices` order: y is the layer, x is at least 0,
    /// and the least x is 0.
    @inlinable
    public var drawing: Drawing<G.Vertex> { _drawing }

    /// The layer of `vertex`, from 0 at the top.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func layer(of vertex: G.Vertex) -> Int {
        guard let i = _drawing._offset(of: vertex) else { preconditionFailure("The vertex is not in the layered drawing: \(vertex)") }
        return _layers[i]
    }

    /// The layer of `vertex`, throwing instead of trapping when it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func layer(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        guard let i = _drawing._offset(of: vertex) else { throw VertexNotFound() }
        return _layers[i]
    }

    /// The number of layers: one more than the greatest layer, 0 for an empty graph.
    @inlinable
    public var layerCount: Int { _layerCount }

    /// The bend points of the edge at `position`, from its source to its target (bottom to top
    /// for a reversed edge): one per layer strictly between its ends (with caller layers, per
    /// layer that has a vertex), empty for an edge between adjacent layers, within one layer, or a
    /// self-loop.
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public func bends(ofEdgeAt position: G.Edges.Index) -> ArraySlice<SIMD2<Double>> {
        var lo = 0, hi = _positions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if _positions[mid] < position { lo = mid + 1 } else { hi = mid }
        }
        precondition(lo < _positions.count && _positions[lo] == position, "The position is not an edge of the layered drawing's graph")
        return _bends[_bendStart[lo] ..< _bendStart[lo + 1]]
    }

    /// The bend points of the edge at `position`, throwing instead of trapping when `position`
    /// is not a position in the graph's `edges`. O(log m), as `bends(ofEdgeAt:)`.
    ///
    /// - Throws: `EdgeNotFound` when `position` is not a position in the graph's `edges`.
    @inlinable
    public func bends(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> ArraySlice<SIMD2<Double>> {
        var lo = 0, hi = _positions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if _positions[mid] < position { lo = mid + 1 } else { hi = mid }
        }
        guard lo < _positions.count && _positions[lo] == position else { throw EdgeNotFound() }
        return _bends[_bendStart[lo] ..< _bendStart[lo + 1]]
    }

    /// The edges drawn against their direction, by position: `feedbackArcSet()` without its
    /// self-loops, or with caller layers the edges that point to a lower layer.
    @inlinable
    public var reversedEdges: [G.Edges.Index] { _reversedEdges }

    /// The number of pairs of segments between adjacent layers (edges cut at their bend points)
    /// whose ends are in opposite orders. Segments that share an end do not cross.
    @inlinable
    public var crossingCount: Int { _crossingCount }
}

extension LayeredDrawing: Sendable where G.Vertex: Sendable, G.Edges.Index: Sendable {}
