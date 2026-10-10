import GraphProtocols

/// A proper colouring of a graph's vertices by the colours `0..<colorCount`, each of which is
/// used: the result of `greedyColoring(strategy:)`, `greedyColoring(order:)` and
/// `minimumColoring()` (JGraphT `VertexColoringAlgorithm.Coloring`, Graphs.jl `Coloring`).
///
/// It keeps a copy of the graph to look vertices up (copy-on-write, so O(1) to make; while the
/// result is alive, the next mutation of the original copies the whole graph), as `Bipartition`
/// does. A colour class's slice keeps the indices of the flat storage it is cut from: use `first`,
/// iteration or `Array(_:)`, not `[0]`.
@frozen
public struct Coloring<G: Graph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// The colour of each vertex, by vertex number.
    @usableFromInline let _colors: [Int]
    /// Every vertex, colour by colour; colour `c` is `_members[_offsets[c] ..< _offsets[c + 1]]`.
    @usableFromInline let _members: [G.Vertex]
    @usableFromInline let _offsets: [Int]

    /// The colouring given by a colour per vertex number, every colour in `0..<k` used.
    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, numbers: [G.Vertex: Int]? = nil, colors: [Int]) {
        let n = colors.count
        var k = 0
        for c in colors where c >= k { k = c + 1 }
        var offsets = [Int](repeating: 0, count: k + 1)
        for c in colors { offsets[c + 1] += 1 }
        for c in 0 ..< k { offsets[c + 1] += offsets[c] }
        var fill = offsets
        var order = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            order[fill[colors[v]]] = v
            fill[colors[v]] += 1
        }
        _graph = graph
        if let numbers {
            _numbers = numbers
        } else if let listed {
            var numbers: [G.Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            _numbers = numbers
        } else {
            _numbers = nil
        }
        _colors = colors
        _members = order.map { listed?[$0] ?? graph.vertex(atIndex: $0) }
        _offsets = offsets
    }

    /// The number of colours: χ for `minimumColoring()`, 0 for the empty graph.
    @inlinable
    public var colorCount: Int { _offsets.count - 1 }

    /// The colour of `vertex`, in `0..<colorCount`. O(1) after the graph's `vertexIndex(of:)` (one
    /// hash for a graph without vertex indices).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func color(of vertex: G.Vertex) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return _colors[v]
        }
        precondition(_graph.contains(vertex), "\(vertex) is not a vertex of the graph")
        return _colors[_graph.vertexIndex(of: vertex)]
    }

    /// The colour of the vertex at `index`: its vertex index, or its position in `vertices` when
    /// the graph has no vertex indices.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func color(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < _colors.count, "Vertex index \(index) out of range")
        return _colors[index]
    }

    /// The vertices of each colour, by colour, each in `vertices` order (JGraphT
    /// `getColorClasses`): slices of one flat array. Each is an independent set.
    @inlinable
    public var colorClasses: [ArraySlice<G.Vertex>] {
        (0 ..< colorCount).map { _members[_offsets[$0] ..< _offsets[$0 + 1]] }
    }
}

extension Coloring: Equatable {
    /// Whether every vertex has the same colour in both: the colour vectors are equal, so two
    /// colourings with the same classes under different colour numbers are not. The graphs are not
    /// compared.
    @inlinable
    public static func == (lhs: Coloring, rhs: Coloring) -> Bool { lhs._colors == rhs._colors }
}

extension Coloring: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Coloring: CustomStringConvertible {
    /// `[[a, c], [b]]`: the colour classes, by colour.
    public var description: String {
        "[" + colorClasses.map { "[" + $0.map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
    }
}

/// How `greedyColoring(strategy:)` orders the vertices. Each vertex in turn takes the least colour
/// none of its already coloured neighbours has (first fit). Degrees are simple degrees (distinct
/// other neighbours, self-loops left out); ties go to the lesser vertex index. NetworkX
/// `greedy_color(G, strategy)`, rustworkx `ColoringStrategy`, igraph `vertex_coloring_greedy`.
@frozen
public enum ColoringStrategy: Hashable, Sendable, CaseIterable {
    /// Degree descending, the lesser index first on ties: Welsh–Powell, which colours class by
    /// class in this order and gives the same colouring as first fit. NetworkX `largest_first`
    /// (the same colouring), JGraphT `LargestDegreeFirstColoring`. O(n + m).
    case largestFirst
    /// Matula–Beck: repeatedly remove a vertex of least degree in what is left (the least index
    /// on ties), then colour in the reverse of that removal order. At most degeneracy + 1 colours,
    /// so at most 6 on a planar graph. NetworkX `smallest_last`, whose ties follow set order
    /// instead. O((n + m) log n).
    case smallestLast
    /// DSatur (Brélaz 1979): first a vertex of greatest degree, then repeatedly the uncoloured
    /// vertex with the most distinct colours among its neighbours, ties to the greatest degree in
    /// the whole graph, then to the lesser index. NetworkX `saturation_largest_first` (`DSATUR`),
    /// the same colouring. Exact on bipartite graphs. O((n + m) log n).
    case saturationLargestFirst
    /// Colour classes one at a time: class k is a maximal independent set of the vertices not yet
    /// coloured, built by repeatedly taking the one with the fewest neighbours among those still
    /// available (the least index on ties) and making it and its neighbours unavailable. NetworkX
    /// `independent_set`, whose ties follow set order instead. O(χ (n + m) log n) for χ classes.
    case independentSet
    /// Components by least vertex, each in breadth-first order from its least vertex, neighbours
    /// in `incidentEdges` order. NetworkX `connected_sequential_bfs`, which starts each component
    /// at an arbitrary vertex instead. O(n + m).
    case connectedSequentialBreadthFirst
    /// The same in depth-first preorder. NetworkX `connected_sequential_dfs`. O(n + m).
    case connectedSequentialDepthFirst
}
