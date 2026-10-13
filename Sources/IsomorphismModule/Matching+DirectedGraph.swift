import GraphProtocols

// The nine matching entry points on directed graphs (arc direction kept), each without colours,
// with vertex colours, and with vertex and arc colours; all run one engine (`_MatchingProblem`).

extension DirectedGraph {
    @inlinable
    func _matchings<Other: DirectedGraph>(to other: Other, _ kind: _MatchingKind, vertexColors: ([Int], [Int]), edgeColors: ([Int], [Int])) -> Isomorphisms<Self, Other> {
        let patternNumbers = _isomorphismNumbers(), targetNumbers = other._isomorphismNumbers()
        let pattern = _indexGraph(patternNumbers, vertexColors: vertexColors.0, edgeColors: edgeColors.0)
        let target = other._indexGraph(targetNumbers, vertexColors: vertexColors.1, edgeColors: edgeColors.1)
        return Isomorphisms(pattern: self, target: other, patternNumbers: patternNumbers, targetNumbers: targetNumbers, problem: _MatchingProblem(kind, pattern, target))
    }

    @inlinable
    func _vertexColorIDs<Other: DirectedGraph, VertexColor: Hashable>(_ other: Other, _ vertexColor: (Vertex) -> VertexColor, _ otherVertexColor: (Other.Vertex) -> VertexColor) -> ([Int], [Int]) {
        var table = _ColorTable<VertexColor>()
        let a = vertices.map { table.id(vertexColor($0)) }
        let b = other.vertices.map { table.id(otherVertexColor($0)) }
        return (a, b)
    }

    @inlinable
    func _edgeColorIDs<Other: DirectedGraph, EdgeColor: Hashable>(_ other: Other, _ edgeColor: (Edges.Index) -> EdgeColor, _ otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> ([Int], [Int]) {
        var table = _ColorTable<EdgeColor>()
        let a = edges.indices.map { table.id(edgeColor($0)) }
        let b = other.edges.indices.map { table.id(otherEdgeColor($0)) }
        return (a, b)
    }

    // MARK: isomorphism

    /// Every one of the isomorphisms from this graph onto `other`: bijections between the vertices that preserve the number of edges between every ordered pair of vertices (self-loops included), as a lazy sequence; the empty graph has one, the empty mapping.
    /// Each mapping reads from this graph to `other`: `images` lists the image of each vertex in
    /// `vertices` order. The order of the sequence is fixed for given inputs but not specified.
    ///
    /// Found by individualization–refinement. The first mapping comes from a search on both graphs at once, refined jointly after each assignment (most pairs are decided by the first refinement or a few assignments); when that search outgrows a small budget, the graphs are split into connected components and get canonical labelings by the engine of `automorphismGroup()` (with automorphism pruning), and the pair is isomorphic exactly when the certificates agree. The rest of the sequence is the first mapping composed with each automorphism of this graph, O(n) per mapping after the group is found. Set-up O((n + m) log n); the search is exponential in the worst case.
    ///
    /// A cancelled task ends the sequence (nil from `next()`; checked every few hundred search nodes), so `isIsomorphic(to:)` and `isomorphism(to:)` return false and nil. Wrap a call in a task with a deadline to bound it.
    @inlinable
    public func isomorphisms<Other: DirectedGraph>(to other: Other) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .isomorphism, vertexColors: ([], []), edgeColors: ([], []))
    }

    /// `isomorphisms(to:)` with vertex colours: a mapping also keeps each vertex's colour
    /// (`vertexColor` here, `otherVertexColor` in `other`; any `Hashable` class, not a proper
    /// colouring). Each closure is read once per vertex, at the call.
    @inlinable
    public func isomorphisms<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .isomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))
    }

    /// `isomorphisms(to:)` with vertex and arc colours: a mapping keeps vertex colours, and the
    /// arcs between two vertices must match as multisets of colours. For arc colours alone,
    /// pass a constant vertex colour. Each closure is read once per vertex or arc, at the call.
    @inlinable
    public func isomorphisms<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .isomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: _edgeColorIDs(other, edgeColor, otherEdgeColor))
    }

    /// The first of `isomorphisms(to:)`, or nil when there is none.
    @inlinable
    public func isomorphism<Other: DirectedGraph>(to other: Other) -> Isomorphism<Self, Other>? {
        isomorphisms(to: other)._first
    }

    /// The first of `isomorphisms(to:vertexColor:otherVertexColor:)`, or nil.
    @inlinable
    public func isomorphism<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Isomorphism<Self, Other>? {
        isomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor)._first
    }

    /// The first of `isomorphisms(to:vertexColor:otherVertexColor:edgeColor:otherEdgeColor:)`, or nil.
    @inlinable
    public func isomorphism<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Isomorphism<Self, Other>? {
        isomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor)._first
    }

    /// Whether `isomorphisms(to:)` is not empty.
    ///
    /// Families that remain hard (exponential for every individualization–refinement solver,
    /// this one included): Miyazaki graphs and other rigid graphs built from CFI gadgets, where
    /// refinement does not tell vertices apart and no automorphism prunes the search; and very large
    /// automorphism groups on dense graphs, where each search node costs a dense refinement.
    /// Strongly regular pairs, twisted CFI pairs and disjoint unions of equal components are
    /// handled by the automorphism pruning (milliseconds at a few hundred vertices).
    @inlinable
    public func isIsomorphic<Other: DirectedGraph>(to other: Other) -> Bool {
        isomorphism(to: other) != nil
    }

    /// Whether `isomorphisms(to:vertexColor:otherVertexColor:)` is not empty.
    @inlinable
    public func isIsomorphic<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Bool {
        isomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor) != nil
    }

    /// Whether `isomorphisms(to:vertexColor:otherVertexColor:edgeColor:otherEdgeColor:)` is not empty.
    @inlinable
    public func isIsomorphic<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Bool {
        isomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor) != nil
    }

    // MARK: subgraph isomorphism

    /// Every one of the subgraph isomorphisms from this graph (the pattern) into `other`: injections onto an induced subgraph, preserving the number of edges between every ordered pair of pattern vertices (self-loops included), as a lazy sequence; the empty graph has one, the empty mapping.
    /// Each mapping reads from this graph to `other`: `images` lists the image of each vertex in
    /// `vertices` order. The order of the sequence is fixed for given inputs but not specified.
    ///
    /// Found by VF2++ (Jüttner & Madarasi 2018). Set-up O(n + m); the search is exponential in the pattern's size in the worst case (the problem is NP-complete). A cancelled task ends the sequence (checked every 4,096 search steps).
    @inlinable
    public func subgraphIsomorphisms<Other: DirectedGraph>(to other: Other) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .subgraphIsomorphism, vertexColors: ([], []), edgeColors: ([], []))
    }

    /// `subgraphIsomorphisms(to:)` with vertex colours: a mapping also keeps each vertex's colour
    /// (`vertexColor` here, `otherVertexColor` in `other`; any `Hashable` class, not a proper
    /// colouring). Each closure is read once per vertex, at the call.
    @inlinable
    public func subgraphIsomorphisms<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .subgraphIsomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))
    }

    /// `subgraphIsomorphisms(to:)` with vertex and arc colours: a mapping keeps vertex colours, and the
    /// arcs between two vertices must match as multisets of colours. For arc colours alone,
    /// pass a constant vertex colour. Each closure is read once per vertex or arc, at the call.
    @inlinable
    public func subgraphIsomorphisms<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .subgraphIsomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: _edgeColorIDs(other, edgeColor, otherEdgeColor))
    }

    /// The first of `subgraphIsomorphisms(to:)`, or nil when there is none.
    @inlinable
    public func subgraphIsomorphism<Other: DirectedGraph>(to other: Other) -> Isomorphism<Self, Other>? {
        subgraphIsomorphisms(to: other)._first
    }

    /// The first of `subgraphIsomorphisms(to:vertexColor:otherVertexColor:)`, or nil.
    @inlinable
    public func subgraphIsomorphism<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Isomorphism<Self, Other>? {
        subgraphIsomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor)._first
    }

    /// The first of `subgraphIsomorphisms(to:vertexColor:otherVertexColor:edgeColor:otherEdgeColor:)`, or nil.
    @inlinable
    public func subgraphIsomorphism<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Isomorphism<Self, Other>? {
        subgraphIsomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor)._first
    }

    /// Whether `subgraphIsomorphisms(to:)` is not empty.
    @inlinable
    public func isSubgraphIsomorphic<Other: DirectedGraph>(to other: Other) -> Bool {
        subgraphIsomorphism(to: other) != nil
    }

    /// Whether `subgraphIsomorphisms(to:vertexColor:otherVertexColor:)` is not empty.
    @inlinable
    public func isSubgraphIsomorphic<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Bool {
        subgraphIsomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor) != nil
    }

    /// Whether `subgraphIsomorphisms(to:vertexColor:otherVertexColor:edgeColor:otherEdgeColor:)` is not empty.
    @inlinable
    public func isSubgraphIsomorphic<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Bool {
        subgraphIsomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor) != nil
    }

    // MARK: monomorphism

    /// Every one of the monomorphisms from this graph (the pattern) into `other`: injections onto a subgraph, not necessarily induced; between every ordered pair of pattern vertices the target has at least as many edges as the pattern (self-loops included), as a lazy sequence; the empty graph has one, the empty mapping.
    /// Each mapping reads from this graph to `other`: `images` lists the image of each vertex in
    /// `vertices` order. The order of the sequence is fixed for given inputs but not specified.
    ///
    /// Found by VF2++ (Jüttner & Madarasi 2018). Set-up O(n + m); the search is exponential in the pattern's size in the worst case (the problem is NP-complete). A cancelled task ends the sequence (checked every 4,096 search steps).
    @inlinable
    public func monomorphisms<Other: DirectedGraph>(to other: Other) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .monomorphism, vertexColors: ([], []), edgeColors: ([], []))
    }

    /// `monomorphisms(to:)` with vertex colours: a mapping also keeps each vertex's colour
    /// (`vertexColor` here, `otherVertexColor` in `other`; any `Hashable` class, not a proper
    /// colouring). Each closure is read once per vertex, at the call.
    @inlinable
    public func monomorphisms<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .monomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))
    }

    /// `monomorphisms(to:)` with vertex and arc colours: a mapping keeps vertex colours, and the
    /// arcs between two vertices must match as multisets of colours. For arc colours alone,
    /// pass a constant vertex colour. Each closure is read once per vertex or arc, at the call.
    @inlinable
    public func monomorphisms<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Isomorphisms<Self, Other> {
        _matchings(to: other, .monomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: _edgeColorIDs(other, edgeColor, otherEdgeColor))
    }

    /// The first of `monomorphisms(to:)`, or nil when there is none.
    @inlinable
    public func monomorphism<Other: DirectedGraph>(to other: Other) -> Isomorphism<Self, Other>? {
        monomorphisms(to: other)._first
    }

    /// The first of `monomorphisms(to:vertexColor:otherVertexColor:)`, or nil.
    @inlinable
    public func monomorphism<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Isomorphism<Self, Other>? {
        monomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor)._first
    }

    /// The first of `monomorphisms(to:vertexColor:otherVertexColor:edgeColor:otherEdgeColor:)`, or nil.
    @inlinable
    public func monomorphism<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Isomorphism<Self, Other>? {
        monomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor)._first
    }

    /// Whether `monomorphisms(to:)` is not empty.
    @inlinable
    public func isMonomorphic<Other: DirectedGraph>(to other: Other) -> Bool {
        monomorphism(to: other) != nil
    }

    /// Whether `monomorphisms(to:vertexColor:otherVertexColor:)` is not empty.
    @inlinable
    public func isMonomorphic<Other: DirectedGraph, VertexColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor) -> Bool {
        monomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor) != nil
    }

    /// Whether `monomorphisms(to:vertexColor:otherVertexColor:edgeColor:otherEdgeColor:)` is not empty.
    @inlinable
    public func isMonomorphic<Other: DirectedGraph, VertexColor: Hashable, EdgeColor: Hashable>(to other: Other, vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor) -> Bool {
        monomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor) != nil
    }

}
