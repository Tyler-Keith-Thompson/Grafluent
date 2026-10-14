import GraphProtocols

// The icosahedral, Tutte, Chvátal and Hoffman–Singleton graphs, each built from its standard
// construction.

/// The icosahedron: apex 0, the upper pentagon 1 … 5, the lower pentagon 6 … 10, apex 11; upper
/// vertex 1 + t joins lower vertices 6 + t and 6 + (t + 1) mod 5.
@usableFromInline
let _icosahedralPairs: [DirectedEdge<Int>] = {
    var pairs: [DirectedEdge<Int>] = []
    for t in 0 ..< 5 {
        let next = (t + 1) % 5
        pairs.append(DirectedEdge(from: 0, to: 1 + t))
        pairs.append(DirectedEdge(from: 1 + t, to: 1 + next))
        pairs.append(DirectedEdge(from: 1 + t, to: 6 + t))
        pairs.append(DirectedEdge(from: 1 + t, to: 6 + next))
        pairs.append(DirectedEdge(from: 6 + t, to: 6 + next))
        pairs.append(DirectedEdge(from: 6 + t, to: 11))
    }
    return _sortedPairs(vertexCount: 12, pairs)
}()

/// Tutte's fragment: 15 vertices and 21 edges. Vertex 0 joins the centre, 13 joins vertex 6 of
/// the next fragment, and every other vertex has degree 3 inside it.
@usableFromInline
let _tutteFragment: [(Int, Int)] = [
    (0, 1), (0, 2), (1, 3), (1, 4), (2, 4), (2, 5), (3, 6), (3, 7), (4, 8), (5, 9), (5, 10),
    (6, 11), (7, 8), (7, 12), (8, 10), (9, 13), (9, 14), (10, 14), (11, 12), (11, 13), (12, 14),
]

/// The Tutte graph: centre 0 and three fragments on 1 + 15f ..< 16 + 15f, each joined to the
/// centre at its vertex 0 and to the next fragment from its vertex 13 to that one's vertex 6.
@usableFromInline
let _tuttePairs: [DirectedEdge<Int>] = {
    var pairs: [DirectedEdge<Int>] = []
    for f in 0 ..< 3 {
        let base = 1 + 15 * f, next = 1 + 15 * ((f + 1) % 3)
        pairs.append(DirectedEdge(from: 0, to: base))
        for (u, v) in _tutteFragment { pairs.append(DirectedEdge(from: base + u, to: base + v)) }
        pairs.append(DirectedEdge(from: base + 13, to: next + 6))
    }
    return _sortedPairs(vertexCount: 46, pairs)
}()

/// The Chvátal graph's 24 edges: the outer 5-cycle 0 … 4, the vertices
/// 5 … 9 each joined to two outer vertices, and 10 and 11.
@usableFromInline
let _chvatalPairs: [DirectedEdge<Int>] = [
    (0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7),
    (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11),
].map { DirectedEdge(from: $0.0, to: $0.1) }

/// The Hoffman–Singleton graph by Robertson's construction: pentagons P_h (vertex j at 5h + j,
/// joined to j ± 1) and pentagrams Q_i (vertex j at 25 + 5i + j, joined to j ± 2), and vertex j
/// of P_h joined to vertex h·i + j (mod 5) of Q_i.
@usableFromInline
let _hoffmanSingletonPairs: [DirectedEdge<Int>] = {
    var pairs: [DirectedEdge<Int>] = []
    for h in 0 ..< 5 {
        for j in 0 ..< 5 {
            pairs.append(DirectedEdge(from: 5 * h + j, to: 5 * h + (j + 1) % 5))
            pairs.append(DirectedEdge(from: 25 + 5 * h + j, to: 25 + 5 * h + (j + 2) % 5))
            for i in 0 ..< 5 { pairs.append(DirectedEdge(from: 5 * h + j, to: 25 + 5 * i + (h * i + j) % 5)) }
        }
    }
    return _sortedPairs(vertexCount: 50, pairs)
}()

extension _GraphConstruction {
    /// The icosahedral graph, the skeleton of the icosahedron: apex 0, the pentagon 1 … 5 below
    /// it, the pentagon 6 … 10, and apex 11, upper vertex 1 + t joined to lower vertices 6 + t and
    /// 6 + (t + 1) mod 5. 12 vertices, 30 edges, 5-regular and planar. O(1).
    @inlinable
    public static func icosahedral() -> Self {
        Self(_vertexCount: 12, sortedEdges: _icosahedralPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Tutte graph: three copies of Tutte's fragment around a centre vertex 0. 46 vertices,
    /// 69 edges, cubic, planar and 3-connected but not Hamiltonian. Fragment f is
    /// `1 + 15f ..< 16 + 15f`; its first vertex joins the centre and its fourteenth the next
    /// fragment. O(1).
    ///
    /// > William T. Tutte. On Hamiltonian circuits. *Journal of the London Mathematical Society*
    /// > s1-21(2), 98–101 (1946). doi:10.1112/jlms/s1-21.2.98
    @inlinable
    public static func tutte() -> Self {
        Self(_vertexCount: 46, sortedEdges: _tuttePairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Chvátal graph: 12 vertices, 24 edges, 4-regular, triangle-free, with chromatic number
    /// 4. The outer cycle is 0 – 1 – 2 – 3 – 4, each of 5 … 9 joins two outer vertices, and 10
    /// and 11 join four of 5 … 9 each. O(1).
    ///
    /// > Václav Chvátal. The smallest triangle-free 4-chromatic 4-regular graph. *Journal of
    /// > Combinatorial Theory* 9(1), 93–94 (1970). doi:10.1016/S0021-9800(70)80057-6
    @inlinable
    public static func chvatal() -> Self {
        Self(_vertexCount: 12, sortedEdges: _chvatalPairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Hoffman–Singleton graph by Robertson's construction: five pentagons P_h on
    /// `5h ..< 5h + 5` (vertex j joined to j ± 1) and five pentagrams Q_i on `25 + 5i ..< 30 + 5i`
    /// (vertex j joined to j ± 2), with vertex j of P_h joined to vertex h·i + j (mod 5) of Q_i.
    /// 50 vertices, 175 edges, 7-regular, the strongly regular (50, 7, 0, 1) Moore graph of girth
    /// 5. O(1).
    ///
    /// > Alan J. Hoffman and Robert R. Singleton. On Moore graphs with diameters 2 and 3. *IBM
    /// > Journal of Research and Development* 4(5), 497–504 (1960). doi:10.1147/rd.45.0497
    @inlinable
    public static func hoffmanSingleton() -> Self {
        Self(_vertexCount: 50, sortedEdges: _hoffmanSingletonPairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The icosahedral graph with both arcs of every edge. O(1).
    @inlinable
    public static func icosahedral() -> Self {
        Self(_vertexCount: 12, sortedEdges: _bothArcs(vertexCount: 12, _icosahedralPairs), _ConstructionToken())
    }

    /// The Tutte graph with both arcs of every edge. O(1).
    @inlinable
    public static func tutte() -> Self {
        Self(_vertexCount: 46, sortedEdges: _bothArcs(vertexCount: 46, _tuttePairs), _ConstructionToken())
    }

    /// The Chvátal graph with both arcs of every edge. O(1).
    @inlinable
    public static func chvatal() -> Self {
        Self(_vertexCount: 12, sortedEdges: _bothArcs(vertexCount: 12, _chvatalPairs), _ConstructionToken())
    }

    /// The Hoffman–Singleton graph with both arcs of every edge. O(1).
    @inlinable
    public static func hoffmanSingleton() -> Self {
        Self(_vertexCount: 50, sortedEdges: _bothArcs(vertexCount: 50, _hoffmanSingletonPairs), _ConstructionToken())
    }
}
