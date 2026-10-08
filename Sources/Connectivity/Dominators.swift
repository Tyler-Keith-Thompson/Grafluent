import GraphProtocols

/// What the Lengauer–Tarjan engine computes, over vertex numbers and depth-first preorder
/// numbers ("dfn") of the vertices reachable from the root.
@frozen
@usableFromInline
package struct _Dominators {
    /// The dfn of each vertex number, or -1 when unreachable.
    @usableFromInline var dfn: [Int]
    /// The vertex number at each dfn.
    @usableFromInline var vertexAt: [Int]
    /// The immediate dominator of each dfn, as a dfn; -1 for the root.
    @usableFromInline var idom: [Int]
    /// The predecessors of each dfn, as dfns, once per edge: `predecessors[predecessorOffsets[d] ..< predecessorOffsets[d + 1]]`.
    @usableFromInline var predecessorOffsets: [Int]
    @usableFromInline var predecessors: [Int]

    @inlinable
    package init(dfn: [Int], vertexAt: [Int], idom: [Int], predecessorOffsets: [Int], predecessors: [Int]) {
        self.dfn = dfn
        self.vertexAt = vertexAt
        self.idom = idom
        self.predecessorOffsets = predecessorOffsets
        self.predecessors = predecessors
    }
}

/// Lengauer and Tarjan's dominator algorithm, the simple version (path compression without
/// balancing, O(E log V)), with an iterative depth-first search and an iterative `COMPRESS`.
/// Predecessors are collected during the search, so only successors are needed.
@inlinable
@inline(__always)
package func _lengauerTarjan<Neighbors: IteratorProtocol<Int>>(
    count n: Int,
    root: Int,
    _ neighbors: (Int) -> Neighbors
) -> _Dominators {
    // Depth-first search from the root: preorder numbers, tree parents, and every edge between
    // reachable vertices as a (source dfn, target dfn) pair.
    var dfn = [Int](repeating: -1, count: n)
    var vertexAt: [Int] = []
    var parent: [Int] = []
    var edgeSources: [Int] = []
    var edgeTargets: [Int] = []
    var path: [Int] = []
    var iterators: [Neighbors] = []
    dfn[root] = 0
    vertexAt.append(root)
    parent.append(-1)
    path.append(0)
    iterators.append(neighbors(root))
    while let d = path.last {
        guard let w = iterators[iterators.count - 1].next() else {
            path.removeLast()
            iterators.removeLast()
            continue
        }
        if dfn[w] < 0 {
            dfn[w] = vertexAt.count
            vertexAt.append(w)
            parent.append(d)
            path.append(dfn[w])
            iterators.append(neighbors(w))
        }
        edgeSources.append(d)
        edgeTargets.append(dfn[w])
    }
    let reached = vertexAt.count
    // Predecessors by target, in edge order.
    var predecessorOffsets = [Int](repeating: 0, count: reached + 1)
    for t in edgeTargets { predecessorOffsets[t + 1] += 1 }
    for d in 0 ..< reached { predecessorOffsets[d + 1] += predecessorOffsets[d] }
    var next = predecessorOffsets
    var predecessors = [Int](repeating: 0, count: edgeSources.count)
    for (s, t) in zip(edgeSources, edgeTargets) {
        predecessors[next[t]] = s
        next[t] += 1
    }
    edgeSources = []
    edgeTargets = []

    // Everything below is in dfn space, over one workspace of five rows.
    var idom = [Int](repeating: -1, count: reached)
    var workspace = [Int](repeating: -1, count: 5 * reached)
    var compressPath: [Int] = []
    idom.withUnsafeMutableBufferPointer { idom in
        workspace.withUnsafeMutableBufferPointer { workspace in
            predecessors.withUnsafeBufferPointer { predecessors in
                parent.withUnsafeBufferPointer { parent in
                    let base = workspace.baseAddress!
                    let semi = base
                    let label = base + reached
                    let ancestor = base + 2 * reached
                    let bucketHead = base + 3 * reached
                    let bucketNext = base + 4 * reached
                    for v in 0 ..< reached {
                        semi[v] = v
                        label[v] = v
                    }

                    /// The vertex of least semidominator on the forest path from `v` up to its
                    /// root (excluded), after COMPRESS(v) done iteratively: collect the path, then
                    /// update it from the top down.
                    @inline(__always)
                    func eval(_ v: Int, _ compressPath: inout [Int]) -> Int {
                        if ancestor[v] < 0 { return v }
                        var x = v
                        while ancestor[ancestor[x]] >= 0 {
                            compressPath.append(x)
                            x = ancestor[x]
                        }
                        while let y = compressPath.popLast() {
                            let a = ancestor[y]
                            if semi[label[a]] < semi[label[y]] { label[y] = label[a] }
                            ancestor[y] = ancestor[a]
                        }
                        return label[v]
                    }

                    var w = reached - 1
                    while w > 0 {
                        var k = predecessorOffsets[w]
                        let end = predecessorOffsets[w + 1]
                        while k < end {
                            let u = eval(predecessors[k], &compressPath)
                            if semi[u] < semi[w] { semi[w] = semi[u] }
                            k += 1
                        }
                        bucketNext[w] = bucketHead[semi[w]]
                        bucketHead[semi[w]] = w
                        let pw = parent[w]
                        ancestor[w] = pw
                        var v = bucketHead[pw]
                        while v >= 0 {
                            let u = eval(v, &compressPath)
                            idom[v] = semi[u] < semi[v] ? u : pw
                            v = bucketNext[v]
                        }
                        bucketHead[pw] = -1
                        w -= 1
                    }
                    if reached > 1 {
                        for w in 1 ..< reached where idom[w] != semi[w] { idom[w] = idom[idom[w]] }
                    }
                }
            }
        }
    }
    return _Dominators(dfn: dfn, vertexAt: vertexAt, idom: idom, predecessorOffsets: predecessorOffsets, predecessors: predecessors)
}

/// The dominator tree of the vertices reachable from a root: `a` dominates `b` when every path
/// from the root to `b` passes through `a`. Each reachable vertex but the root has an immediate
/// dominator, its closest strict dominator, which is its parent in the tree.
///
/// Like `Components`, it keeps a copy of the graph to look vertices up through its vertex
/// indices, with the same cost: while it is alive, the next mutation of the original copies the
/// graph. Every query traps when its vertex is not a vertex of that graph.
@frozen
public struct DominatorTree<Graph: DirectedGraph> {
    @usableFromInline let _vertices: _DenseVertices<Graph>
    @usableFromInline let _root: Int
    /// The immediate dominator of each vertex number; -1 for the root and unreachable vertices.
    @usableFromInline let _idom: [Int]
    /// Entry and exit times of a depth-first walk of the tree, for O(1) `dominates`; -1 when
    /// unreachable.
    @usableFromInline let _enter: [Int]
    @usableFromInline let _exit: [Int]
    /// The children of each vertex number, in `vertices` order.
    @usableFromInline let _childOffsets: [Int]
    @usableFromInline let _children: [Graph.Vertex]

    @inlinable
    init(vertices: _DenseVertices<Graph>, root: Int, _ result: _Dominators) {
        let n = vertices.count
        var idom = [Int](repeating: -1, count: n)
        var offsets = [Int](repeating: 0, count: n + 1)
        var children = [Int](repeating: 0, count: max(result.vertexAt.count - 1, 0))
        var enter = [Int](repeating: -1, count: n)
        var exit = [Int](repeating: -1, count: n)
        idom.withUnsafeMutableBufferPointer { idom in
            offsets.withUnsafeMutableBufferPointer { offsets in
                children.withUnsafeMutableBufferPointer { children in
                    enter.withUnsafeMutableBufferPointer { enter in
                        exit.withUnsafeMutableBufferPointer { exit in
                            result.vertexAt.withUnsafeBufferPointer { vertexAt in
                                result.idom.withUnsafeBufferPointer { dominator in
                                    for d in 1 ..< max(vertexAt.count, 1) {
                                        idom[vertexAt[d]] = vertexAt[dominator[d]]
                                    }
                                }
                            }
                            // Children grouped by parent, each group in increasing vertex number:
                            // count into the next slot, sum to starts, place advancing the starts
                            // to ends, and shift the ends up a slot.
                            for v in 0 ..< n where idom[v] >= 0 { offsets[idom[v] + 1] += 1 }
                            for v in 0 ..< n { offsets[v + 1] += offsets[v] }
                            for v in 0 ..< n where idom[v] >= 0 {
                                children[offsets[idom[v]]] = v
                                offsets[idom[v]] += 1
                            }
                            var v = n
                            while v > 0 {
                                offsets[v] = offsets[v - 1]
                                v -= 1
                            }
                            offsets[0] = 0
                            // Entry and exit times of a walk of the tree, iteratively: while a
                            // vertex is open, `exit` holds where its parent's children resume.
                            var clock = 0
                            var current = root
                            enter[root] = clock
                            clock += 1
                            var cursor = offsets[root]
                            exit[root] = -1
                            while current >= 0 {
                                if cursor < offsets[current + 1] {
                                    let c = children[cursor]
                                    // Save where to resume `current`, then descend.
                                    exit[c] = cursor + 1
                                    enter[c] = clock
                                    clock += 1
                                    current = c
                                    cursor = offsets[c]
                                } else {
                                    let resume = exit[current]
                                    exit[current] = clock
                                    clock += 1
                                    if current == root { break }
                                    // Back to the parent, at the child after `current`.
                                    current = idom[current]
                                    cursor = resume
                                }
                            }
                        }
                    }
                }
            }
        }
        _vertices = vertices
        _root = root
        _idom = idom
        _enter = enter
        _exit = exit
        _childOffsets = offsets
        _children = children.map { vertices.vertex($0) }
    }

    @inlinable
    func _number(_ vertex: Graph.Vertex) -> Int {
        let v = _vertices.number(of: vertex)
        precondition(v >= 0 && v < _idom.count, "\(vertex) is not a vertex of the graph")
        return v
    }

    /// The root the tree was computed from.
    @inlinable
    public var root: Graph.Vertex { _vertices.vertex(_root) }

    /// The closest strict dominator of `vertex`: its parent in the tree. `nil` for the root and
    /// for vertices the root does not reach.
    @inlinable
    public func immediateDominator(of vertex: Graph.Vertex) -> Graph.Vertex? {
        let d = _idom[_number(vertex)]
        return d < 0 ? nil : _vertices.vertex(d)
    }

    /// The dominators of `vertex`: `vertex` itself, its immediate dominator, and so on up to the
    /// root. `nil` when the root does not reach `vertex`.
    @inlinable
    public func dominators(of vertex: Graph.Vertex) -> [Graph.Vertex]? {
        var v = _number(vertex)
        guard _enter[v] >= 0 else { return nil }
        var result: [Graph.Vertex] = [vertex]
        while _idom[v] >= 0 {
            v = _idom[v]
            result.append(_vertices.vertex(v))
        }
        return result
    }

    /// `dominators(of:)` without `vertex` itself. `nil` when the root does not reach `vertex`.
    @inlinable
    public func strictDominators(of vertex: Graph.Vertex) -> [Graph.Vertex]? {
        dominators(of: vertex).map { Array($0.dropFirst()) }
    }

    /// The vertices whose immediate dominator is `vertex`, in `vertices` order. Empty for a leaf
    /// and for a vertex the root does not reach. The slice keeps the indices of the flat storage
    /// it is cut from, as a `Components` element does.
    @inlinable
    public func children(of vertex: Graph.Vertex) -> ArraySlice<Graph.Vertex> {
        let v = _number(vertex)
        return _children[_childOffsets[v] ..< _childOffsets[v + 1]]
    }

    /// Whether `a` is an ancestor of `b` in this tree, or `b` itself: for a dominator tree, every
    /// path from the root to `b` passes through `a`; for a post-dominator tree, every path from
    /// `b` to the exit does. False when `b` is not in the tree (the root does not reach it, or it
    /// does not reach the exit), where LLVM's `DominatorTree::dominates`, whose name this is,
    /// answers true. O(1).
    @inlinable
    public func dominates(_ a: Graph.Vertex, _ b: Graph.Vertex) -> Bool {
        let u = _number(a)
        let v = _number(b)
        guard _enter[u] >= 0, _enter[v] >= 0 else { return false }
        return _enter[u] <= _enter[v] && _exit[v] <= _exit[u]
    }
}

extension DominatorTree: Sendable where Graph: Sendable, Graph.Vertex: Sendable {}

/// The dominance frontier of each vertex reachable from a root: the vertices `y` such that the
/// vertex dominates a predecessor of `y` but does not strictly dominate `y` (Cytron et al.), where
/// SSA construction places φ-functions.
@frozen
public struct DominanceFrontiers<Graph: DirectedGraph> {
    @usableFromInline let _vertices: _DenseVertices<Graph>
    @usableFromInline let _reachable: [Bool]
    @usableFromInline let _offsets: [Int]
    @usableFromInline let _members: [Graph.Vertex]

    /// Cooper, Harvey and Kennedy's runner: for every reachable `y` and every predecessor `p`,
    /// walk from `p` up the dominator tree to `idom(y)`, adding `y` to each frontier on the way.
    /// For the root, whose idom is none, the walk includes the root.
    @inlinable
    init(vertices: _DenseVertices<Graph>, _ result: _Dominators) {
        let n = vertices.count
        var runners: [Int] = []
        var members: [Int] = []
        var mark = [Int](repeating: -1, count: result.vertexAt.count)
        for y in 0 ..< n {
            let dy = result.dfn[y]
            guard dy >= 0 else { continue }
            let stop = result.idom[dy]
            for p in result.predecessors[result.predecessorOffsets[dy] ..< result.predecessorOffsets[dy + 1]] {
                var runner = p
                while runner != stop, mark[runner] != dy {
                    mark[runner] = dy
                    runners.append(result.vertexAt[runner])
                    members.append(y)
                    runner = result.idom[runner]
                }
            }
        }
        // Group by runner; within a group, y is increasing because the outer loop is.
        var offsets = [Int](repeating: 0, count: n + 1)
        for r in runners { offsets[r + 1] += 1 }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] }
        var next = offsets
        var grouped = [Int](repeating: 0, count: members.count)
        for (r, y) in zip(runners, members) {
            grouped[next[r]] = y
            next[r] += 1
        }
        _vertices = vertices
        _reachable = result.dfn.map { $0 >= 0 }
        _offsets = offsets
        _members = grouped.map { vertices.vertex($0) }
    }

    /// The dominance frontier of `vertex`, in `vertices` order; `nil` when the root does not reach
    /// `vertex`. The slice keeps the indices of the flat storage it is cut from.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public subscript(vertex: Graph.Vertex) -> ArraySlice<Graph.Vertex>? {
        let v = _vertices.number(of: vertex)
        precondition(v >= 0 && v < _reachable.count, "\(vertex) is not a vertex of the graph")
        guard _reachable[v] else { return nil }
        return _members[_offsets[v] ..< _offsets[v + 1]]
    }
}

extension DominanceFrontiers: Sendable where Graph: Sendable, Graph.Vertex: Sendable {}

extension DirectedGraph {
    @inlinable
    @inline(__always)
    func _dominators(_ vertices: _DenseVertices<Self>, root: Vertex) -> (root: Int, result: _Dominators) {
        precondition(contains(root), "The root \(root) is not a vertex of the graph")
        let r = vertices.number(of: root)
        if vertices.isIndexed {
            let n = vertices.count
            if let result = _withSuccessorIndexRows({ offsets, targets in
                _lengauerTarjan(count: n, root: r) { _RowCursor(row: $0, offsets: offsets, targets: targets) }
            }) {
                return (r, result)
            }
            return (r, _lengauerTarjan(count: n, root: r) { successorIndices(ofIndex: $0).makeIterator() })
        }
        return (r, _lengauerTarjan(count: vertices.count, root: r) { u in
            successors(of: vertices.vertices[u]).lazy.map { vertices.numbers[$0]! }.makeIterator()
        })
    }

    /// The dominator tree of the vertices reachable from `root`, by Lengauer and Tarjan's
    /// algorithm (iterative, O(E log V)). Needs only successors.
    ///
    /// - Precondition: `root` is a vertex.
    @inlinable
    public func dominatorTree(root: Vertex) -> DominatorTree<Self> {
        let vertices = _DenseVertices(self)
        let (r, result) = _dominators(vertices, root: root)
        return DominatorTree(vertices: vertices, root: r, result)
    }

    /// The dominance frontiers of the vertices reachable from `root` (NetworkX's
    /// `dominance_frontiers`). Computes the dominators again rather than taking a
    /// `DominatorTree`, which does not keep the predecessors the frontiers need.
    ///
    /// - Precondition: `root` is a vertex.
    @inlinable
    public func dominanceFrontiers(root: Vertex) -> DominanceFrontiers<Self> {
        let vertices = _DenseVertices(self)
        return DominanceFrontiers(vertices: vertices, _dominators(vertices, root: root).result)
    }
}

extension BidirectionalDirectedGraph {
    /// The post-dominator tree for `exit`: the dominator tree of the graph with every edge
    /// reversed, so `a` post-dominates `b` when every path from `b` to `exit` passes through `a`
    /// (LLVM's `PostDominatorTree`). Vertices that cannot reach `exit` have no post-dominators.
    /// For a `CompressedSparseRow`, use the dominator tree of `transposed()`.
    ///
    /// - Precondition: `exit` is a vertex.
    @inlinable
    public func postDominatorTree(exit: Vertex) -> DominatorTree<Self> {
        precondition(contains(exit), "The exit \(exit) is not a vertex of the graph")
        let vertices = _DenseVertices(self)
        let x = vertices.number(of: exit)
        let result = vertices.isIndexed
            ? _lengauerTarjan(count: vertices.count, root: x) { predecessorIndices(ofIndex: $0).makeIterator() }
            : _lengauerTarjan(count: vertices.count, root: x) { u in
                predecessors(of: vertices.vertices[u]).lazy.map { vertices.numbers[$0]! }.makeIterator()
            }
        return DominatorTree(vertices: vertices, root: x, result)
    }
}
