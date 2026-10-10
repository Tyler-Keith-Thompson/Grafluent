import GraphProtocols
import Walks

// Edge- and vertex-disjoint paths (NetworkX `edge_disjoint_paths`, `node_disjoint_paths`; igraph
// `edge_disjoint_paths`, `vertex_disjoint_paths`, which return the counts): Menger's witnesses,
// read off a unit maximum flow by path decomposition.

/// A unit flow's arcs, decomposed into paths from `s` to `t`: `arcs[x]` lists the arcs that
/// carry flow out of x, as (head, edge number, against the stored orientation). Each walk from `s`
/// follows unused arcs; arriving at a vertex already on the walk closes a cycle, which is dropped
/// (its arcs used up), so every path is simple. Returns each path's vertex numbers and its arcs.
@inlinable
func _decomposeUnitFlow(_ arcs: [[(head: Int, edge: Int, against: Bool)]], from s: Int, to t: Int, count: Int) -> [(vertices: [Int], arcs: [(edge: Int, against: Bool)])] {
    let n = arcs.count
    var nextArc = [Int](repeating: 0, count: n)
    var onWalk = [Int](repeating: -1, count: n)
    var paths: [(vertices: [Int], arcs: [(edge: Int, against: Bool)])] = []
    paths.reserveCapacity(count)
    for _ in 0 ..< count {
        var vertices = [s]
        var used: [(edge: Int, against: Bool)] = []
        onWalk[s] = 0
        while vertices.last! != t {
            let x = vertices.last!
            precondition(nextArc[x] < arcs[x].count, "A unit flow lost its conservation")
            let arc = arcs[x][nextArc[x]]
            nextArc[x] += 1
            let k = onWalk[arc.head]
            if k >= 0 {
                // A cycle back to the walk: drop it.
                for y in vertices[(k + 1)...] { onWalk[y] = -1 }
                vertices.removeSubrange((k + 1)...)
                used.removeSubrange(k...)
                continue
            }
            onWalk[arc.head] = vertices.count
            vertices.append(arc.head)
            used.append((arc.edge, arc.against))
        }
        for y in vertices { onWalk[y] = -1 }
        paths.append((vertices, used))
    }
    return paths
}

/// The split network for vertex-disjoint paths with the edge s → t removed (as
/// `_splitNetwork`), and per pair the edge it stands for and whether it runs against the edge's
/// stored orientation (−1 for the split arcs).
@inlinable
func _splitNetworkWithEdges(_ edges: _FlowEdges, _ s: Int, _ t: Int) -> (network: _ResidualNetwork<Int>, edge: [Int], against: [Bool]) {
    let n = edges.vertexCount
    var tail: [Int32] = [], head: [Int32] = [], capacity: [Int] = [], edge: [Int] = [], against: [Bool] = []
    for v in 0 ..< n {
        tail.append(Int32(truncatingIfNeeded: 2 * v))
        head.append(Int32(truncatingIfNeeded: 2 * v + 1))
        capacity.append(1)
        edge.append(-1)
        against.append(false)
    }
    for e in 0 ..< edges.edgeCount where !edges.isLoop(e) {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        tail.append(Int32(truncatingIfNeeded: 2 * u + 1))
        head.append(Int32(truncatingIfNeeded: 2 * v))
        capacity.append(u == s && v == t ? 0 : n)
        edge.append(e)
        against.append(false)
        if !edges.directed {
            tail.append(Int32(truncatingIfNeeded: 2 * v + 1))
            head.append(Int32(truncatingIfNeeded: 2 * u))
            capacity.append(v == s && u == t ? 0 : n)
            edge.append(e)
            against.append(true)
        }
    }
    return (_ResidualNetwork(count: 2 * n, tail: tail, head: head, forward: capacity, symmetric: false), edge, against)
}

/// The edge-disjoint paths by edge number: a unit flow by Dinic, decomposed.
@inlinable
func _edgeDisjointPaths(_ edges: _FlowEdges, _ s: Int, _ t: Int) -> [(vertices: [Int], arcs: [(edge: Int, against: Bool)])] {
    let n = edges.vertexCount
    let network = _unitNetwork(edges)
    let value = _dinic(network, from: s, to: t)
    var arcs = [[(head: Int, edge: Int, against: Bool)]](repeating: [], count: n)
    for e in 0 ..< edges.edgeCount where !edges.isLoop(e) {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        if edges.directed {
            if network.directedFlow(e) > 0 { arcs[u].append((v, e, false)) }
        } else {
            let (along, back) = network.undirectedFlow(e, capacity: 1)
            if along > 0 { arcs[u].append((v, e, false)) }
            if back > 0 { arcs[v].append((u, e, true)) }
        }
    }
    return _decomposeUnitFlow(arcs, from: s, to: t, count: value)
}

/// The internally vertex-disjoint paths by edge number: a unit flow on the split network (the
/// edges s → t removed), decomposed, then the first edge s → t in position order as one more path
/// when there is one.
@inlinable
func _vertexDisjointPaths(_ edges: _FlowEdges, _ s: Int, _ t: Int) -> [(vertices: [Int], arcs: [(edge: Int, against: Bool)])] {
    let n = edges.vertexCount
    let (network, edge, against) = _splitNetworkWithEdges(edges, s, t)
    let value = _dinic(network, from: 2 * s + 1, to: 2 * t)
    var arcs = [[(head: Int, edge: Int, against: Bool)]](repeating: [], count: n)
    for p in n ..< edge.count where network.directedFlow(p) > 0 {
        let e = edge[p]
        let (u, v) = against[p] ? (Int(edges.head[e]), Int(edges.tail[e])) : (Int(edges.tail[e]), Int(edges.head[e]))
        arcs[u].append((v, e, against[p]))
    }
    var paths = _decomposeUnitFlow(arcs, from: s, to: t, count: value)
    for e in 0 ..< edges.edgeCount {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        if u == s && v == t {
            paths.append(([s, t], [(e, false)]))
            break
        }
        if !edges.directed && u == t && v == s {
            paths.append(([s, t], [(e, true)]))
            break
        }
    }
    return paths
}

extension DirectedGraph {
    /// A largest set of edge-disjoint paths from `source` to `target` (NetworkX
    /// `edge_disjoint_paths`; igraph `edge_disjoint_paths` gives their number): as many as
    /// `edgeConnectivity(from:to:)`, each a simple path, no edge position in two of them.
    /// Parallel edges are distinct edges; self-loops are never used. A unit maximum flow by Dinic,
    /// decomposed into paths (flow cycles dropped). Which paths are returned is not specified, but
    /// the same input always gives the same paths. O(m min(√m, n^(2/3))).
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func edgeDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, Edges.Index>] {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _directedPaths(_edgeDisjointPaths(edges, s, t), vertices)
    }

    /// A largest set of internally vertex-disjoint paths from `source` to `target` (NetworkX
    /// `node_disjoint_paths`; igraph `vertex_disjoint_paths` gives their number): as many as
    /// `vertexConnectivity(from:to:)`, each a simple path, no vertex but the two ends in two of
    /// them. An edge from `source` to `target` is one such path, whatever its multiplicity (the
    /// first in position order, listed last). A unit flow on the split network (each other vertex
    /// an arc of capacity 1), decomposed. Which paths are returned is not specified, but the same
    /// input always gives the same paths. O(m √n).
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func vertexDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, Edges.Index>] {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _directedPaths(_vertexDisjointPaths(edges, s, t), vertices)
    }

    @inlinable
    func _directedPaths(_ paths: [(vertices: [Int], arcs: [(edge: Int, against: Bool)])], _ vertices: _FlowVertices<Vertex>) -> [Path<Vertex, Edges.Index>] {
        let listed = _flowListed(vertices)
        let positions = Array(self.edges.indices)
        return paths.map { path in
            Path(_uncheckedVertices: path.vertices.map { listed[$0] }, edges: path.arcs.map { positions[$0.edge] })
        }
    }
}

extension Graph {
    /// A largest set of edge-disjoint paths between `source` and `target`, over `directed` (each
    /// edge an arc in the direction the path uses it): as many as `edgeConnectivity(from:to:)`, no
    /// edge in two of them. See `DirectedGraph.edgeDisjointPaths(from:to:)`.
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func edgeDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, DirectedView<Self>.Edges.Index>] {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _undirectedPaths(_edgeDisjointPaths(edges, s, t), vertices)
    }

    /// A largest set of internally vertex-disjoint paths between `source` and `target`, over
    /// `directed`: as many as `vertexConnectivity(from:to:)`; an edge between them is one path.
    /// See `DirectedGraph.vertexDisjointPaths(from:to:)`.
    ///
    /// - Precondition: `source` and `target` are distinct vertices.
    @inlinable
    public func vertexDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, DirectedView<Self>.Edges.Index>] {
        let (edges, vertices) = _flowEdges()
        let s = _flowNumber(of: source, vertices), t = _flowNumber(of: target, vertices)
        precondition(s != t, "The source is the target")
        return _undirectedPaths(_vertexDisjointPaths(edges, s, t), vertices)
    }

    @inlinable
    func _undirectedPaths(_ paths: [(vertices: [Int], arcs: [(edge: Int, against: Bool)])], _ vertices: _FlowVertices<Vertex>) -> [Path<Vertex, DirectedView<Self>.Edges.Index>] {
        let listed = _flowListed(vertices)
        let positions = Array(self.edges.indices)
        return paths.map { path in
            Path(_uncheckedVertices: path.vertices.map { listed[$0] }, edges: path.arcs.map { DirectedView<Self>.Edges.Index(position: positions[$0.edge], reversed: $0.against) })
        }
    }
}
