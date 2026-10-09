import GraphProtocols

extension Graph {
    /// The connected components (NetworkX's, Boost's and igraph's `connected_components`): in
    /// the order of their first vertex in `vertices`, each listing its vertices in `vertices`
    /// order. The same value as `directed.weaklyConnectedComponents()`, computed over each edge
    /// once. O(n + m α(n)).
    @inlinable
    public func connectedComponents() -> Components<DirectedView<Self>> {
        let (labels, count, _) = _runOnUndirectedRows(_UndirectedComponents())
        return Components(vertices: _DenseVertices(directed), labels: labels, count: count)
    }

    /// Whether the graph has exactly one connected component; false for the empty graph, as
    /// `isWeaklyConnected` (igraph, JGraphT; NetworkX raises). Stops once n − 1 joins succeed.
    @inlinable
    public var isConnected: Bool {
        let n = vertexCount
        guard n > 0 else { return false }
        return _runOnUndirectedRows(_UndirectedComponents(limit: n - 1)).joins == n - 1
    }

    /// The bridges: the edges whose removal adds a connected component (NetworkX's, JGraphT's,
    /// igraph's and petgraph's `bridges`), as positions in ascending order. A self-loop is never a
    /// bridge, and neither is any of two or more parallel edges. O(n + m).
    @inlinable
    public func bridges() -> [Edges.Index] {
        let search = _runOnUndirectedRows(_BiconnectivitySearch([]))
        let positions = Array(edges.indices)
        return search.isBridge.indices.filter { search.isBridge[$0] }.map { positions[$0] }
    }

    /// Whether the graph has a bridge (NetworkX's `has_bridges`). Stops at the first one found.
    @inlinable
    public var hasBridges: Bool {
        _runOnUndirectedRows(_BiconnectivitySearch(.stopAtBridge)).stoppedEarly
    }

    /// The articulation points: the vertices whose removal adds a connected component
    /// (NetworkX's, Boost's, igraph's and petgraph's `articulation_points`; cut vertices), in
    /// `vertices` order. Self-loops and parallel edges never make one. O(n + m).
    @inlinable
    public func articulationPoints() -> [Vertex] {
        let search = _runOnUndirectedRows(_BiconnectivitySearch([]))
        let numbering = _DenseVertices(directed)
        return search.isArticulationPoint.indices.filter { search.isArticulationPoint[$0] }.map { numbering.vertex($0) }
    }

    /// Whether the graph is biconnected (NetworkX's, JGraphT's and igraph's `is_biconnected`): at
    /// least two vertices, connected, and no articulation point. So K₂ is, and a graph with an
    /// isolated vertex is not. Stops at the first articulation point.
    @inlinable
    public var isBiconnected: Bool {
        let n = vertexCount
        guard n >= 2 else { return false }
        let search = _runOnUndirectedRows(_BiconnectivitySearch(.stopAtArticulationPoint))
        return !search.stoppedEarly && search.firstTreeSize == n
    }

    /// The bi-edge-connected (2-edge-connected) components (LEMON's `biEdgeConnectedComponents`,
    /// NetworkX's bridge components): the components left when every bridge is removed, ordered
    /// as `connectedComponents()`. An isolated vertex is one on its own. O(n + m).
    @inlinable
    public func biEdgeConnectedComponents() -> Components<DirectedView<Self>> {
        var search = _runOnUndirectedRows(_BiconnectivitySearch(.biEdgeComponents))
        _relabelByFirstAppearance(&search.biEdgeLabel, count: search.biEdgeCount)
        return Components(vertices: _DenseVertices(directed), labels: search.biEdgeLabel, count: search.biEdgeCount)
    }

    /// Whether the graph is bi-edge-connected (2-edge-connected; NetworkX's
    /// `is_k_edge_connected(G, 2)`): at least two vertices, connected, and no bridge. So a doubled
    /// edge is, and K₁ and K₂ are not. Stops at the first bridge.
    @inlinable
    public var isBiEdgeConnected: Bool {
        let n = vertexCount
        guard n >= 2 else { return false }
        let search = _runOnUndirectedRows(_BiconnectivitySearch(.stopAtBridge))
        return !search.stoppedEarly && search.firstTreeSize == n
    }

    /// The biconnected components, or blocks (Boost's, NetworkX's and igraph's
    /// `biconnected_components`): the maximal biconnected subgraphs, as sets of edges, which they
    /// partition (self-loops apart: a self-loop is in no block). Blocks are ordered by their
    /// smallest edge position, each listing its edges in ascending position. An isolated vertex,
    /// or one with only self-loops, is in no block. O(n + m).
    @inlinable
    public func biconnectedComponents() -> BiconnectedComponents<Self> {
        BiconnectedComponents(self)
    }

    /// The block–cut tree (JGraphT's `BlockCutpointGraph`): a node per block and per articulation
    /// point, and an edge between each block and each articulation point in it. A forest, one tree
    /// per connected component with an edge that is not a self-loop. O(n + m).
    @inlinable
    public func blockCutTree() -> BlockCutTree<Self> {
        BlockCutTree(biconnectedComponents())
    }
}

/// Labels per edge and the blocks of each vertex, from one search and one more pass over the rows.
@frozen
@usableFromInline
struct _Blocks: _UndirectedRowsAlgorithm {
    @inlinable init() {}

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, edgeCount m: Int, _ arcs: (Int) -> Arcs) -> (edgeLabel: [Int], blockCount: Int, vertexBlockOffsets: [Int], vertexBlocks: [Int], isArticulationPoint: [Bool]) where Arcs.Element == (Int, Int) {
        var search = _BiconnectivitySearch(.blocks).run(count: n, edgeCount: m, arcs)
        // Number blocks by their smallest edge.
        _relabelByFirstAppearance(&search.blockLabel, count: search.blockCount)
        var offsets = [0]
        offsets.reserveCapacity(n + 1)
        var blocks: [Int] = []
        var lastSeen = [Int](repeating: -1, count: search.blockCount)
        for v in 0 ..< n {
            let start = blocks.count
            var out = arcs(v)
            while let (w, e) = out.next() {
                guard w != v else { continue }
                let b = search.blockLabel[e]
                if lastSeen[b] != v {
                    lastSeen[b] = v
                    blocks.append(b)
                }
            }
            blocks[start...].sort()
            offsets.append(blocks.count)
        }
        return (search.blockLabel, search.blockCount, offsets, blocks, search.isArticulationPoint)
    }
}

/// The biconnected components (blocks) of an undirected graph: a collection of blocks, each the
/// positions of its edges in ascending order; blocks are ordered by their smallest edge position.
/// The blocks partition the edges that are not self-loops.
///
/// It keeps a copy of the graph (copy-on-write, so O(1) to make), so that per-vertex and per-edge
/// queries use the graph's own indices. As with `Components`, a slice keeps the indices of the
/// flat storage it is cut from: use `first`, iteration or `Array(_:)`.
@frozen
public struct BiconnectedComponents<G: Graph>: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ArraySlice<G.Edges.Index>
    public typealias Indices = Range<Int>

    @usableFromInline let _graph: G
    @usableFromInline let _vertices: _DenseVertices<DirectedView<G>>
    /// Without edge indices, each position's number.
    @usableFromInline let _edgeNumbers: [G.Edges.Index: Int]
    /// Each edge's block by number, −1 for a self-loop.
    @usableFromInline let _edgeLabel: [Int]
    @usableFromInline let _edges: [G.Edges.Index]
    @usableFromInline let _edgeOffsets: [Int]
    @usableFromInline let _members: [G.Vertex]
    @usableFromInline let _memberOffsets: [Int]
    /// Each vertex's blocks, ascending, by vertex number.
    @usableFromInline let _vertexBlocks: [Int]
    @usableFromInline let _vertexBlockOffsets: [Int]
    @usableFromInline let _isArticulationPoint: [Bool]

    @inlinable
    init(_ graph: G) {
        let found = graph._runOnUndirectedRows(_Blocks())
        let vertices = _DenseVertices(graph.directed)
        let positions = Array(graph.edges.indices)
        let count = found.blockCount
        // Edges grouped by block, ascending: a counting sort over edge numbers.
        var edgeOffsets = [Int](repeating: 0, count: count + 1)
        for label in found.edgeLabel where label >= 0 { edgeOffsets[label + 1] += 1 }
        for b in 0 ..< count { edgeOffsets[b + 1] += edgeOffsets[b] }
        var next = edgeOffsets
        var grouped = [G.Edges.Index](repeating: positions.first ?? graph.edges.startIndex, count: edgeOffsets[count])
        for (k, label) in found.edgeLabel.enumerated() where label >= 0 {
            grouped[next[label]] = positions[k]
            next[label] += 1
        }
        // Each block's vertices in vertex order: invert the per-vertex block lists.
        var memberOffsets = [Int](repeating: 0, count: count + 1)
        for b in found.vertexBlocks { memberOffsets[b + 1] += 1 }
        for b in 0 ..< count { memberOffsets[b + 1] += memberOffsets[b] }
        var place = memberOffsets
        // A block has vertices only when the graph does, so vertex 0 exists to fill with.
        var members = memberOffsets[count] == 0 ? [] : [G.Vertex](repeating: vertices.vertex(0), count: memberOffsets[count])
        if count > 0 {
            for v in 0 ..< vertices.count {
                for b in found.vertexBlocks[found.vertexBlockOffsets[v] ..< found.vertexBlockOffsets[v + 1]] {
                    members[place[b]] = vertices.vertex(v)
                    place[b] += 1
                }
            }
        }
        _graph = graph
        _vertices = vertices
        _edgeNumbers = graph.edgeIndexBound != nil ? [:] : graph._edgeNumbers()
        _edgeLabel = found.edgeLabel
        _edges = grouped
        _edgeOffsets = edgeOffsets
        _members = members
        _memberOffsets = memberOffsets
        _vertexBlocks = found.vertexBlocks
        _vertexBlockOffsets = found.vertexBlockOffsets
        _isArticulationPoint = found.isArticulationPoint
    }

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _edgeOffsets.count - 1 }

    /// The positions of the edges of the block at `position`, ascending.
    @inlinable
    public subscript(position: Int) -> ArraySlice<G.Edges.Index> {
        precondition(position >= 0 && position < endIndex, "Block position out of range")
        return _edges[_edgeOffsets[position] ..< _edgeOffsets[position + 1]]
    }

    /// The vertices of the block at `position`, in `vertices` order (NetworkX's
    /// `biconnected_components`).
    @inlinable
    public func vertices(ofComponentAt position: Int) -> ArraySlice<G.Vertex> {
        precondition(position >= 0 && position < endIndex, "Block position out of range")
        return _members[_memberOffsets[position] ..< _memberOffsets[position + 1]]
    }

    /// The block containing the edge at `position`, or `nil` for a self-loop, which is in none.
    ///
    /// - Precondition: `position` is an edge position of the graph.
    @inlinable
    public func component(ofEdgeAt position: G.Edges.Index) -> Int? {
        let number: Int
        if _graph.edgeIndexBound != nil {
            number = _graph.edgeIndex(of: position)
        } else {
            guard let found = _edgeNumbers[position] else { preconditionFailure("\(position) is not an edge position of the graph") }
            number = found
        }
        precondition(number >= 0 && number < _edgeLabel.count, "\(position) is not an edge position of the graph")
        let label = _edgeLabel[number]
        return label >= 0 ? label : nil
    }

    /// The blocks containing `vertex`, ascending (JGraphT's `getBlocks(vertex)`): two or more for
    /// an articulation point, one for any other vertex with an edge that is not a self-loop, none
    /// for the rest.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func components(containing vertex: G.Vertex) -> ArraySlice<Int> {
        let v = _vertices.number(of: vertex)
        precondition(v >= 0 && v + 1 < _vertexBlockOffsets.count, "\(vertex) is not a vertex of the graph")
        return _vertexBlocks[_vertexBlockOffsets[v] ..< _vertexBlockOffsets[v + 1]]
    }
}

extension BiconnectedComponents: Equatable {
    /// Whether both have the same blocks, with the same edges and vertices, in the same order.
    /// The graphs are not compared.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._edgeOffsets == rhs._edgeOffsets && lhs._edges == rhs._edges
            && lhs._memberOffsets == rhs._memberOffsets && lhs._members == rhs._members
    }
}

extension BiconnectedComponents: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}

extension BiconnectedComponents: CustomStringConvertible {
    public var description: String {
        "[" + map { "[" + $0.map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
    }
}

/// The block–cut tree of an undirected graph (Harary's block-cutpoint tree, JGraphT's
/// `BlockCutpointGraph`): a node per block and per articulation point, and an edge joining each
/// block to each articulation point it contains. Blocks are numbered as in `blocks`, articulation
/// points by their place in `articulationPoints` (`vertices` order). It is a forest: one tree per
/// connected component with an edge that is not a self-loop; isolated vertices are no node.
@frozen
public struct BlockCutTree<G: Graph> {
    /// A node of the tree.
    @frozen
    public enum Node: Hashable, Sendable {
        case block(Int)
        case articulationPoint(Int)
    }

    /// The blocks, as `biconnectedComponents()` gives them.
    public let blocks: BiconnectedComponents<G>
    /// The articulation points, in `vertices` order.
    public let articulationPoints: [G.Vertex]
    /// Each vertex's place in `articulationPoints`, or −1, by vertex number.
    @usableFromInline let _pointNumber: [Int]
    @usableFromInline let _blockPoints: [Int]
    @usableFromInline let _blockPointOffsets: [Int]

    @inlinable
    init(_ blocks: BiconnectedComponents<G>) {
        let n = blocks._vertices.count
        var pointNumber = [Int](repeating: -1, count: n)
        var points: [G.Vertex] = []
        for v in 0 ..< n where blocks._isArticulationPoint[v] {
            pointNumber[v] = points.count
            points.append(blocks._vertices.vertex(v))
        }
        // Each block's articulation points, ascending: its vertices are in vertex order.
        var offsets = [0]
        offsets.reserveCapacity(blocks.count + 1)
        var blockPoints: [Int] = []
        for b in blocks.indices {
            for vertex in blocks.vertices(ofComponentAt: b) {
                let p = pointNumber[blocks._vertices.number(of: vertex)]
                if p >= 0 { blockPoints.append(p) }
            }
            offsets.append(blockPoints.count)
        }
        self.blocks = blocks
        articulationPoints = points
        _pointNumber = pointNumber
        _blockPoints = blockPoints
        _blockPointOffsets = offsets
    }

    /// The articulation points in block `block`, as places in `articulationPoints`, ascending.
    @inlinable
    public func articulationPoints(ofBlock block: Int) -> ArraySlice<Int> {
        precondition(block >= 0 && block < blocks.count, "Block position out of range")
        return _blockPoints[_blockPointOffsets[block] ..< _blockPointOffsets[block + 1]]
    }

    /// The blocks containing the articulation point at place `point`, ascending.
    @inlinable
    public func blocks(ofArticulationPoint point: Int) -> ArraySlice<Int> {
        precondition(point >= 0 && point < articulationPoints.count, "Articulation point position out of range")
        return blocks.components(containing: articulationPoints[point])
    }

    /// The node standing for `vertex` (JGraphT's `getBlock`): its own node for an articulation
    /// point, its block for a vertex in exactly one, `nil` for a vertex in none.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func node(of vertex: G.Vertex) -> Node? {
        let v = blocks._vertices.number(of: vertex)
        if _pointNumber[v] >= 0 { return .articulationPoint(_pointNumber[v]) }
        return blocks.components(containing: vertex).first.map { .block($0) }
    }

    /// The number of tree edges: one per (block, articulation point in it).
    @inlinable
    public var edgeCount: Int { _blockPoints.count }
}

extension BlockCutTree: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.blocks == rhs.blocks && lhs._blockPoints == rhs._blockPoints && lhs._blockPointOffsets == rhs._blockPointOffsets
    }
}

extension BlockCutTree: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}
