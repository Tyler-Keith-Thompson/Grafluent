import Trees

/// The heavy–light decomposition of a rooted tree or arborescence: each vertex's heavy child is
/// its child with the largest subtree (the first in `children(of:)` order on a tie), and the
/// heavy edges form paths. Vertices get positions in a preorder that takes the heavy child first,
/// so each heavy path and each subtree is an interval of positions, and any path between two
/// vertices is at most 2⌊log₂ n⌋ + 1 intervals (`segments(from:to:)`), for path and subtree
/// queries over a structure indexed by position.
@frozen
public struct HeavyLightDecomposition<Vertex: Hashable> {
    @usableFromInline let _layout: _TreeLayout<Vertex>
    /// The vertex numbers by position.
    @usableFromInline let _order: [Int]
    @usableFromInline let _position: [Int]
    @usableFromInline let _head: [Int]

    /// Decomposes a rooted tree. O(n).
    @inlinable
    public init(_ tree: RootedTree<Vertex>) {
        self.init(_layout: tree._layout)
    }

    /// Decomposes an arborescence. O(n).
    @inlinable
    public init(_ arborescence: Arborescence<Vertex>) {
        self.init(_layout: arborescence._layout)
    }

    @inlinable
    init(_layout layout: _TreeLayout<Vertex>) {
        _layout = layout
        let n = layout.count
        // Heavy children: the first child of greatest size, in row order without the parent edge.
        var heavy = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            var best = -1, bestSize = 0
            let parentEdge = layout.nodes[v].parentEdge
            for k in layout.rowOffsets[v] ..< layout.rowOffsets[v + 1] where layout.rowEdges[k] != parentEdge {
                let w = layout.rowNeighbors[k]
                if layout.nodes[w].size > bestSize {
                    best = w
                    bestSize = layout.nodes[w].size
                }
            }
            heavy[v] = best
        }
        var order: [Int] = []
        order.reserveCapacity(n)
        var position = [Int](repeating: 0, count: n)
        var head = [Int](repeating: 0, count: n)
        if n > 0 {
            let root = layout.roots[0]
            head[root] = root
            var stack = [root]
            while let v = stack.popLast() {
                position[v] = order.count
                order.append(v)
                // Light children in reverse row order, then the heavy child, so it comes next.
                let parentEdge = layout.nodes[v].parentEdge
                var k = layout.rowOffsets[v + 1] - 1
                while k >= layout.rowOffsets[v] {
                    let w = layout.rowNeighbors[k]
                    if layout.rowEdges[k] != parentEdge, w != heavy[v] {
                        head[w] = w
                        stack.append(w)
                    }
                    k -= 1
                }
                if heavy[v] >= 0 {
                    head[heavy[v]] = head[v]
                    stack.append(heavy[v])
                }
            }
        }
        _order = order
        _position = position
        _head = head
    }

    /// The child of `vertex` with the largest subtree, the first in `children(of:)` order on a
    /// tie; nil at a leaf. O(1).
    @inlinable
    public func heavyChild(of vertex: Vertex) -> Vertex? {
        heavyChild(ofIndex: _layout.number(of: vertex)).map { _layout.vertices[$0] }
    }

    /// The index of the heavy child of the vertex at `index`; nil at a leaf. O(1).
    @inlinable
    public func heavyChild(ofIndex index: Int) -> Int? {
        let next = _position[index] + 1
        guard next < _order.count, _head[_order[next]] == _head[index] else { return nil }
        return _order[next]
    }

    /// The top vertex of the heavy path through `vertex`. O(1).
    @inlinable
    public func head(of vertex: Vertex) -> Vertex { _layout.vertices[_head[_layout.number(of: vertex)]] }

    /// The index of the top vertex of the heavy path through the vertex at `index`. O(1).
    @inlinable
    public func head(ofIndex index: Int) -> Int { _head[index] }

    /// The position of `vertex`: its offset in this decomposition's `preorder` (heavy child
    /// first). O(1).
    @inlinable
    public func position(of vertex: Vertex) -> Int { _position[_layout.number(of: vertex)] }

    /// The position of the vertex at `index`. O(1).
    @inlinable
    public func position(ofIndex index: Int) -> Int { _position[index] }

    /// The index of the vertex at `position`. O(1).
    @inlinable
    public func vertexIndex(atPosition position: Int) -> Int { _order[position] }

    /// The vertices by position: a preorder taking each vertex's heavy child first, then its
    /// other children in `children(of:)` order. O(1).
    @inlinable
    public var preorder: Preorder { Preorder(_vertices: _layout.vertices, order: _order) }

    /// The positions of the subtree of `vertex`. O(1).
    @inlinable
    public func subtree(of vertex: Vertex) -> Range<Int> { subtree(ofIndex: _layout.number(of: vertex)) }

    /// The positions of the subtree of the vertex at `index`. O(1).
    @inlinable
    public func subtree(ofIndex index: Int) -> Range<Int> { _position[index] ..< _position[index] + _layout.nodes[index].size }

    /// The deepest common ancestor of `a` and `b`, a vertex counting as its own ancestor.
    /// O(log n).
    @inlinable
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex {
        _layout.vertices[lowestCommonAncestor(ofIndex: _layout.number(of: a), _layout.number(of: b))]
    }

    /// The deepest common ancestor of the vertices at indices `a` and `b`, as an index. O(log n).
    @inlinable
    public func lowestCommonAncestor(ofIndex a: Int, _ b: Int) -> Int {
        var x = a, y = b
        while _head[x] != _head[y] {
            if _layout.nodes[_head[x]].depth >= _layout.nodes[_head[y]].depth {
                x = _layout.nodes[_head[x]].parent
            } else {
                y = _layout.nodes[_head[y]].parent
            }
        }
        return _layout.nodes[x].depth <= _layout.nodes[y].depth ? x : y
    }

    /// The path from `source` to `target` as position intervals, in the order the path visits
    /// them: each inside one heavy path, visited from last to first where `isReversed` (going
    /// up). At most 2⌊log₂ n⌋ + 1 segments. Without the common ancestor (for values stored on
    /// edges, at their child's position) the ancestor's position is dropped, and a segment left
    /// empty by it. O(log n), one allocation.
    ///
    /// - Precondition: Both are vertices of the tree.
    @inlinable
    public func segments(from source: Vertex, to target: Vertex, includingCommonAncestor: Bool = true) -> [Segment] {
        segments(fromIndex: _layout.number(of: source), toIndex: _layout.number(of: target), includingCommonAncestor: includingCommonAncestor)
    }

    /// `segments(from:to:includingCommonAncestor:)` for the vertices at indices `source` and
    /// `target`.
    @inlinable
    public func segments(fromIndex source: Int, toIndex target: Int, includingCommonAncestor: Bool = true) -> [Segment] {
        // One buffer: the source side from the front, the target side from the back (so its
        // segments end up in walk order), then moved together.
        let capacity = 2 * (Int.bitWidth - max(_order.count, 1).leadingZeroBitCount) + 1
        return [Segment](unsafeUninitializedCapacity: capacity) { buffer, initialized in
            var x = source, y = target
            var front = 0, back = capacity
            while _head[x] != _head[y] {
                if _layout.nodes[_head[x]].depth >= _layout.nodes[_head[y]].depth {
                    let range = _position[_head[x]] ..< _position[x] + 1
                    (buffer.baseAddress! + front).initialize(to: Segment(positions: range, isReversed: range.count > 1))
                    front += 1
                    x = _layout.nodes[_head[x]].parent
                } else {
                    back -= 1
                    (buffer.baseAddress! + back).initialize(to: Segment(positions: _position[_head[y]] ..< _position[y] + 1, isReversed: false))
                    y = _layout.nodes[_head[y]].parent
                }
            }
            // On one heavy path: the shallower end is the common ancestor, the low end.
            let goingUp = _position[x] > _position[y]
            let low = min(_position[x], _position[y]), high = max(_position[x], _position[y])
            let shared = (includingCommonAncestor ? low : low + 1) ..< high + 1
            if !shared.isEmpty {
                (buffer.baseAddress! + front).initialize(to: Segment(positions: shared, isReversed: goingUp && shared.count > 1))
                front += 1
            }
            let tail = capacity - back
            if tail > 0 { (buffer.baseAddress! + front).moveInitialize(from: buffer.baseAddress! + back, count: tail) }
            initialized = front + tail
        }
    }
}

extension HeavyLightDecomposition {
    /// An interval of positions on one heavy path.
    @frozen
    public struct Segment: Hashable, Sendable {
        public var positions: Range<Int>
        /// Whether the path visits `positions` from the last to the first (it is going up). False
        /// for a one-position segment.
        public var isReversed: Bool

        @inlinable
        public init(positions: Range<Int>, isReversed: Bool) {
            self.positions = positions
            self.isReversed = isReversed
        }
    }

    /// The vertices by position.
    @frozen
    public struct Preorder: RandomAccessCollection {
        @usableFromInline let _vertices: ContiguousArray<Vertex>
        @usableFromInline let _order: [Int]

        @inlinable
        init(_vertices: ContiguousArray<Vertex>, order: [Int]) {
            self._vertices = _vertices
            _order = order
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _order.count }

        @inlinable
        public subscript(position: Int) -> Vertex { _vertices[_order[position]] }
    }
}

extension HeavyLightDecomposition: Sendable where Vertex: Sendable {}
extension HeavyLightDecomposition.Preorder: Sendable where Vertex: Sendable {}
