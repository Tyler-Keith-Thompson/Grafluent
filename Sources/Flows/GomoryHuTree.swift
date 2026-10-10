import GraphProtocols
import Trees

/// A Gomory–Hu cut tree (JGraphT `GusfieldGomoryHuCutTree`, LEMON `GomoryHu`): the result of
/// `gomoryHuTree(capacity:)`. Every pair's minimum cut value is the least capacity on its tree
/// path, and removing a tree edge splits the vertices into a minimum cut between its ends.
///
/// It keeps a copy of the graph (copy-on-write, O(1) to make) for the crossing edges of
/// `minimumCut(between:and:)`.
@frozen
public struct GomoryHuTree<G: Graph, Capacity: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: G
    /// The tree on the graph's vertices: the edge at position k joins the vertex with number
    /// k + 1 to its parent toward the first vertex.
    public let tree: Tree<G.Vertex>
    /// Each vertex number's parent number (the first vertex's is itself) and the capacity of its
    /// tree edge; `_depth` is its edge count to the first vertex.
    @usableFromInline let _parent: [Int]
    @usableFromInline let _capacity: [Capacity]
    @usableFromInline let _depth: [Int]
    @usableFromInline let _edges: _FlowEdges
    @usableFromInline let _graphCapacities: [Capacity]
    @usableFromInline let _vertices: _FlowVertices<G.Vertex>
    @usableFromInline let _listed: [G.Vertex]

    @inlinable
    init(graph: G, parent: [Int], capacity: [Capacity], edges: _FlowEdges, graphCapacities: [Capacity], vertices: _FlowVertices<G.Vertex>, listed: [G.Vertex]) {
        _graph = graph
        let n = parent.count
        tree = Tree(vertices: listed, edges: (1 ..< max(n, 1)).map { UndirectedEdge(listed[$0], listed[parent[$0]]) })!
        _parent = parent
        _capacity = capacity
        var depth = [Int](repeating: -1, count: n)
        if n > 0 { depth[0] = 0 }
        for v in 0 ..< n where depth[v] < 0 {
            var path: [Int] = []
            var x = v
            while depth[x] < 0 {
                path.append(x)
                x = parent[x]
            }
            var d = depth[x]
            for y in path.reversed() {
                d += 1
                depth[y] = d
            }
        }
        _depth = depth
        _edges = edges
        _graphCapacities = graphCapacities
        _vertices = vertices
        _listed = listed
    }

    /// The capacity of the tree edge at `position`: the minimum cut value between its ends.
    ///
    /// - Precondition: `position` is in `0 ..< tree.edgeCount`.
    @inlinable
    public func capacity(ofEdgeAt position: Int) -> Capacity {
        precondition(position >= 0 && position < _capacity.count - 1, "\(position) is not a tree edge position")
        return _capacity[position + 1]
    }

    /// The tree edges on the path from `u` to `v` by the vertex number each joins to its parent,
    /// in order from `u`.
    @inlinable
    func _path(_ u: Int, _ v: Int) -> [Int] {
        var a = u, b = v
        var fromU: [Int] = [], fromV: [Int] = []
        while _depth[a] > _depth[b] {
            fromU.append(a)
            a = _parent[a]
        }
        while _depth[b] > _depth[a] {
            fromV.append(b)
            b = _parent[b]
        }
        while a != b {
            fromU.append(a)
            a = _parent[a]
            fromV.append(b)
            b = _parent[b]
        }
        return fromU + fromV.reversed()
    }

    @inlinable
    func _number(_ vertex: G.Vertex) -> Int { _graph._flowNumber(of: vertex, _vertices) }

    /// The least capacity on the tree path, the minimum cut value between `u` and `v`. O(n).
    ///
    /// - Precondition: `u` and `v` are distinct vertices of the graph.
    @inlinable
    public func minimumCutValue(between u: G.Vertex, and v: G.Vertex) -> Capacity {
        let a = _number(u), b = _number(v)
        precondition(a != b, "A minimum cut needs two distinct vertices")
        let path = _path(a, b)
        var least = _capacity[path[0]]
        for x in path.dropFirst() where _capacity[x] < least { least = _capacity[x] }
        return least
    }

    /// The split at the least edge on the tree path (the one nearest `u` among equals), `u` on
    /// the source side, with the graph's crossing edges as arcs of `directed`, in position order.
    /// A minimum cut between `u` and `v`. O(n + m).
    ///
    /// - Precondition: `u` and `v` are distinct vertices of the graph.
    @inlinable
    public func minimumCut(between u: G.Vertex, and v: G.Vertex) -> Cut<DirectedView<G>, Capacity> {
        let a = _number(u), b = _number(v)
        precondition(a != b, "A minimum cut needs two distinct vertices")
        let path = _path(a, b)
        var chosen = path[0]
        for x in path.dropFirst() where _capacity[x] < _capacity[chosen] { chosen = x }
        // The subtree below the chosen edge, by children lists.
        let n = _parent.count
        var childStart = [Int](repeating: 0, count: n + 1)
        for x in 1 ..< n { childStart[_parent[x] + 1] += 1 }
        for x in 0 ..< n { childStart[x + 1] += childStart[x] }
        var fill = childStart
        var children = [Int](repeating: 0, count: max(n - 1, 0))
        for x in 1 ..< n {
            children[fill[_parent[x]]] = x
            fill[_parent[x]] += 1
        }
        var below = [Bool](repeating: false, count: n)
        below[chosen] = true
        var stack = [chosen]
        while let x = stack.popLast() {
            for k in childStart[x] ..< childStart[x + 1] {
                below[children[k]] = true
                stack.append(children[k])
            }
        }
        // The sink side is the part without u.
        let uBelow = below[a]
        let inSink = below.map { $0 != uBelow }
        return _graph._cut(_edges, _graphCapacities, _listed, inSink)
    }
}

extension GomoryHuTree: Equatable {
    /// Whether both have the same tree and capacities. The graphs are not compared.
    @inlinable
    public static func == (lhs: GomoryHuTree, rhs: GomoryHuTree) -> Bool {
        lhs.tree == rhs.tree && lhs._capacity.dropFirst() == rhs._capacity.dropFirst()
    }
}

extension GomoryHuTree: Sendable where G: Sendable, G.Vertex: Sendable, Capacity: Sendable {}

extension GomoryHuTree: CustomStringConvertible {
    /// `[1–0 5, 2–1 3]`: each tree edge, its child first, with its capacity.
    public var description: String {
        "[" + (1 ..< max(_parent.count, 1)).map { "\(_listed[$0])–\(_listed[_parent[$0]]) \(_capacity[$0])" }.joined(separator: ", ") + "]"
    }
}

extension Graph {
    /// A Gomory–Hu cut tree: every pair's minimum cut value is the least capacity on its tree
    /// path, and every tree edge splits the vertices into a minimum cut between its ends.
    /// Gusfield's algorithm with the canonical cut, vertices in order, rooted at the first: the
    /// same tree as NetworkX's `gomory_hu_tree`. Disconnected graphs get zero-capacity tree
    /// edges. nil for the empty graph. n − 1 maximum flows on one residual network, by
    /// push–relabel's first phase. `capacity` is called once per non-loop edge, in position
    /// order, before any work.
    ///
    /// The flows run in a wider type than `C` where needed (`Int` or `Int128` for fixed-width
    /// integers, `Double` for `Float`), so a vertex's capacity sum may pass `C`'s range.
    ///
    /// - Precondition: every capacity is at least zero, not NaN and finite, and every tree
    ///   capacity (a minimum cut value) fits in `C`.
    @inlinable
    public func gomoryHuTree<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> GomoryHuTree<Self, C>? {
        let (edges, vertices) = _flowEdges()
        let capacities = _readCapacities(edges, self.edges.indices, capacity)
        let n = edges.vertexCount
        guard n > 0 else { return nil }
        var parent = [Int](repeating: 0, count: n)
        var value = [C](repeating: .zero, count: n)
        if n > 1 { (parent, value) = _runWide(_Gusfield<C>(edges: edges), edges, capacities) }
        return GomoryHuTree(graph: self, parent: parent, capacity: value, edges: edges, graphCapacities: capacities, vertices: vertices, listed: _flowListed(vertices))
    }
}

/// Gusfield's algorithm with the canonical cut on wide capacities: each vertex number's parent
/// and its tree edge's capacity, narrowed back.
@frozen
@usableFromInline
struct _Gusfield<Capacity: Comparable & AdditiveArithmetic>: _WideCapacityAlgorithm {
    @usableFromInline let edges: _FlowEdges

    @inlinable
    init(edges: _FlowEdges) { self.edges = edges }

    @inlinable
    func run<K: Comparable & AdditiveArithmetic>(_ wide: [K], _ narrow: (K) -> Capacity) -> (parent: [Int], value: [Capacity]) {
        let n = edges.vertexCount
        var parent = [Int](repeating: 0, count: n)
        var value = [K](repeating: .zero, count: n)
        let network = _flowNetwork(edges, wide, reusable: true)
        let preflow = _Preflow(network)
        for s in 1 ..< n {
            if s > 1 { network.reset() }
            let t = parent[s]
            let flow = preflow.firstPhase(from: s, to: t)
            preflow.markSinkSide(t)
            let sinkSide = preflow.marks
            value[s] = flow
            for i in 1 ..< n where i != s && !sinkSide[i] && parent[i] == t { parent[i] = s }
            if t != 0 && !sinkSide[parent[t]] {
                parent[s] = parent[t]
                parent[t] = s
                value[s] = value[t]
                value[t] = flow
            }
        }
        return (parent, value.map(narrow))
    }
}
