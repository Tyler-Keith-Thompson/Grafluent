/// A forest of rooted trees on the vertices `0..<count` that can be linked and cut, with a cost on
/// each vertex, and minimum, addition and subtraction along the path from a vertex to its root.
///
/// The dynamic trees of Sleator and Tarjan, as link–cut trees: the forest is split into
/// preferred paths, each held in a splay tree ordered by depth, and the paths are joined by
/// path-parent pointers. Every operation is O(log count) amortized.
///
/// A vertex's cost belongs to the vertex, not to the edge to its parent, so path operations from
/// `v` cover `v` and its root and every vertex between them. To give edges costs, as Dinic's
/// algorithm with dynamic trees does, keep each edge's cost at its child and a cost at each root
/// that no path minimum should report.
///
/// Every operation is `mutating`, queries included, because each one restructures the splay trees.
/// Storage is one array of nodes, copied on write.
@frozen
public struct LinkCutTree<Cost: Comparable & AdditiveArithmetic> {
    /// A vertex's splay-tree node. `parent` is the splay-tree parent, or, at the root of a splay
    /// tree, the path-parent (the represented parent of the path's shallowest vertex), or -1.
    @frozen
    @usableFromInline
    struct _Node {
        @usableFromInline var left: Int
        @usableFromInline var right: Int
        @usableFromInline var parent: Int
        /// A vertex of least cost in this node's splay subtree.
        @usableFromInline var argmin: Int
        @usableFromInline var cost: Cost
        /// The least cost in this node's splay subtree.
        @usableFromInline var minimum: Cost
        /// An addition, then a subtraction, already made to this node but not yet to its
        /// children. Two amounts rather than one signed one, so unsigned costs work.
        @usableFromInline var pendingAddition: Cost
        @usableFromInline var pendingSubtraction: Cost
        /// Whether this node's children are still to be swapped, and their subtrees reversed.
        @usableFromInline var reversed: Bool

        @inlinable
        init(_ vertex: Int, cost: Cost) {
            left = -1
            right = -1
            parent = -1
            argmin = vertex
            self.cost = cost
            minimum = cost
            pendingAddition = .zero
            pendingSubtraction = .zero
            reversed = false
        }
    }

    @usableFromInline var _nodes: [_Node]

    /// Scratch for `_splay`: the splay-tree ancestors of a node, pushed down from the top.
    @usableFromInline var _stack: [Int]

    /// `count` trees of one vertex each, every vertex with cost `cost`. O(count).
    ///
    /// - Precondition: `count >= 0`.
    @inlinable
    public init(count: Int, cost: Cost) {
        precondition(count >= 0, "A link–cut tree cannot have a negative count")
        _nodes = (0 ..< count).map { _Node($0, cost: cost) }
        _stack = [Int](repeating: 0, count: count)
    }

    /// The number of vertices.
    @inlinable
    public var count: Int { _nodes.count }

    @inlinable
    @inline(__always)
    func _check(_ vertex: Int) {
        precondition(UInt(bitPattern: vertex) < UInt(bitPattern: _nodes.count), "Vertex out of range 0..<count")
    }

    /// Calls `body` with the node buffer and the scratch stack; one uniqueness check each.
    @inlinable
    @inline(__always)
    mutating func _withNodes<Result>(_ body: (UnsafeMutablePointer<_Node>, UnsafeMutablePointer<Int>) -> Result) -> Result {
        _nodes.withUnsafeMutableBufferPointer { nodes in
            _stack.withUnsafeMutableBufferPointer { stack in
                // Both have `count` elements; a dangling placeholder when that is zero, never read.
                body(nodes.baseAddress ?? UnsafeMutablePointer(bitPattern: MemoryLayout<_Node>.alignment)!,
                     stack.baseAddress ?? UnsafeMutablePointer(bitPattern: MemoryLayout<Int>.alignment)!)
            }
        }
    }

    // MARK: Queries

    /// The root of `vertex`'s tree.
    ///
    /// - Precondition: `vertex` is in `0..<count`.
    @inlinable
    public mutating func root(of vertex: Int) -> Int {
        _check(vertex)
        return _withNodes { nodes, stack in Self._findRoot(nodes, stack, vertex) }
    }

    /// `vertex`'s parent, or `nil` when it is a root.
    ///
    /// - Precondition: `vertex` is in `0..<count`.
    @inlinable
    public mutating func parent(of vertex: Int) -> Int? {
        _check(vertex)
        return _withNodes { nodes, stack in
            Self._access(nodes, stack, vertex)
            var x = nodes[vertex].left
            guard x >= 0 else { return nil }
            Self._push(nodes, x)
            while nodes[x].right >= 0 {
                x = nodes[x].right
                Self._push(nodes, x)
            }
            Self._splay(nodes, stack, x)
            return x
        }
    }

    /// Whether `u` and `v` are in the same tree.
    ///
    /// - Precondition: `u` and `v` are in `0..<count`.
    @inlinable
    public mutating func inSameTree(_ u: Int, _ v: Int) -> Bool {
        _check(u)
        _check(v)
        return _withNodes { nodes, stack in Self._findRoot(nodes, stack, u) == Self._findRoot(nodes, stack, v) }
    }

    /// `vertex`'s cost.
    ///
    /// - Precondition: `vertex` is in `0..<count`.
    @inlinable
    public mutating func cost(of vertex: Int) -> Cost {
        _check(vertex)
        return _withNodes { nodes, stack in
            Self._splay(nodes, stack, vertex)
            return nodes[vertex].cost
        }
    }

    /// A vertex of least cost on the path from `vertex` to its root, both included, and that
    /// cost. Which of several vertices of least cost is unspecified.
    ///
    /// - Precondition: `vertex` is in `0..<count`.
    @inlinable
    public mutating func pathMinimum(from vertex: Int) -> (vertex: Int, cost: Cost) {
        _check(vertex)
        return _withNodes { nodes, stack in
            Self._access(nodes, stack, vertex)
            return (nodes[vertex].argmin, nodes[vertex].minimum)
        }
    }

    // MARK: Changes

    /// Sets `vertex`'s cost to `cost`.
    ///
    /// - Precondition: `vertex` is in `0..<count`.
    @inlinable
    public mutating func setCost(of vertex: Int, to cost: Cost) {
        _check(vertex)
        _withNodes { nodes, stack in
            Self._splay(nodes, stack, vertex)
            nodes[vertex].cost = cost
            Self._pull(nodes, vertex)
        }
    }

    /// Adds `delta` to the cost of every vertex on the path from `vertex` to its root, both
    /// included.
    ///
    /// - Precondition: `vertex` is in `0..<count`; no cost on the path overflows.
    @inlinable
    public mutating func addCost(_ delta: Cost, toPathFrom vertex: Int) {
        _check(vertex)
        _withNodes { nodes, stack in
            Self._access(nodes, stack, vertex)
            Self._apply(nodes, vertex, delta, .zero)
        }
    }

    /// Subtracts `delta` from the cost of every vertex on the path from `vertex` to its root,
    /// both included.
    ///
    /// - Precondition: `vertex` is in `0..<count`; no cost on the path overflows, which for an
    ///   unsigned `Cost` means `delta` is at most the path's minimum.
    @inlinable
    public mutating func subtractCost(_ delta: Cost, fromPathFrom vertex: Int) {
        _check(vertex)
        _withNodes { nodes, stack in
            Self._access(nodes, stack, vertex)
            Self._apply(nodes, vertex, .zero, delta)
        }
    }

    /// Makes the root `child` a child of `parent`, joining their trees.
    ///
    /// - Precondition: `child` and `parent` are in `0..<count`; `child` is a root, and `parent`
    ///   is in another tree.
    @inlinable
    public mutating func link(_ child: Int, to parent: Int) {
        _check(child)
        _check(parent)
        _withNodes { nodes, stack in
            precondition(Self._findRoot(nodes, stack, parent) != child, "link(_:to:) would join a tree to itself")
            Self._access(nodes, stack, child)
            precondition(nodes[child].left < 0, "link(_:to:) needs a root as the child")
            // `child` is now alone in its splay tree's root path: its path-parent becomes `parent`.
            nodes[child].parent = parent
        }
    }

    /// Removes the edge from `vertex` to its parent, so `vertex` becomes the root of its own
    /// tree.
    ///
    /// - Precondition: `vertex` is in `0..<count` and is not a root.
    @inlinable
    public mutating func cut(_ vertex: Int) {
        _check(vertex)
        _withNodes { nodes, stack in
            Self._access(nodes, stack, vertex)
            let above = nodes[vertex].left
            precondition(above >= 0, "cut(_:) needs a vertex that has a parent")
            nodes[above].parent = -1
            nodes[vertex].left = -1
            Self._pull(nodes, vertex)
        }
    }

    /// Makes `vertex` the root of its tree, reversing the path from it to the old root.
    ///
    /// - Precondition: `vertex` is in `0..<count`.
    @inlinable
    public mutating func makeRoot(_ vertex: Int) {
        _check(vertex)
        _withNodes { nodes, stack in
            Self._access(nodes, stack, vertex)
            nodes[vertex].reversed.toggle()
        }
    }

    // MARK: Splay trees

    @inlinable
    @inline(__always)
    static func _isSplayRoot(_ nodes: UnsafeMutablePointer<_Node>, _ x: Int) -> Bool {
        let p = nodes[x].parent
        return p < 0 || (nodes[p].left != x && nodes[p].right != x)
    }

    /// Adds `addition`, then subtracts `subtraction`, from every cost in `x`'s splay subtree: now
    /// at `x`, later at its children.
    @inlinable
    @inline(__always)
    static func _apply(_ nodes: UnsafeMutablePointer<_Node>, _ x: Int, _ addition: Cost, _ subtraction: Cost) {
        nodes[x].cost = nodes[x].cost + addition - subtraction
        nodes[x].minimum = nodes[x].minimum + addition - subtraction
        nodes[x].pendingAddition += addition
        nodes[x].pendingSubtraction += subtraction
    }

    /// Hands `x`'s pending addition, subtraction and reversal down to its children.
    @inlinable
    @inline(__always)
    static func _push(_ nodes: UnsafeMutablePointer<_Node>, _ x: Int) {
        let addition = nodes[x].pendingAddition, subtraction = nodes[x].pendingSubtraction
        if addition != .zero || subtraction != .zero {
            if nodes[x].left >= 0 { _apply(nodes, nodes[x].left, addition, subtraction) }
            if nodes[x].right >= 0 { _apply(nodes, nodes[x].right, addition, subtraction) }
            nodes[x].pendingAddition = .zero
            nodes[x].pendingSubtraction = .zero
        }
        if nodes[x].reversed {
            let l = nodes[x].left, r = nodes[x].right
            nodes[x].left = r
            nodes[x].right = l
            if l >= 0 { nodes[l].reversed.toggle() }
            if r >= 0 { nodes[r].reversed.toggle() }
            nodes[x].reversed = false
        }
    }

    /// Recomputes `x`'s subtree minimum from its own cost and its children's.
    @inlinable
    @inline(__always)
    static func _pull(_ nodes: UnsafeMutablePointer<_Node>, _ x: Int) {
        var minimum = nodes[x].cost, argmin = x
        let l = nodes[x].left, r = nodes[x].right
        if l >= 0 && nodes[l].minimum < minimum {
            minimum = nodes[l].minimum
            argmin = nodes[l].argmin
        }
        if r >= 0 && nodes[r].minimum < minimum {
            minimum = nodes[r].minimum
            argmin = nodes[r].argmin
        }
        nodes[x].minimum = minimum
        nodes[x].argmin = argmin
    }

    /// Rotates `x` above its splay-tree parent. Both have been pushed.
    @inlinable
    @inline(__always)
    static func _rotate(_ nodes: UnsafeMutablePointer<_Node>, _ x: Int) {
        let y = nodes[x].parent, z = nodes[y].parent
        if !_isSplayRoot(nodes, y) {
            if nodes[z].left == y { nodes[z].left = x } else { nodes[z].right = x }
        }
        nodes[x].parent = z
        if nodes[y].left == x {
            let b = nodes[x].right
            nodes[y].left = b
            if b >= 0 { nodes[b].parent = y }
            nodes[x].right = y
        } else {
            let b = nodes[x].left
            nodes[y].right = b
            if b >= 0 { nodes[b].parent = y }
            nodes[x].left = y
        }
        nodes[y].parent = x
        _pull(nodes, y)
        _pull(nodes, x)
    }

    /// Splays `x` to the root of its splay tree, first pushing every pending change on the way
    /// down to it.
    @inlinable
    static func _splay(_ nodes: UnsafeMutablePointer<_Node>, _ stack: UnsafeMutablePointer<Int>, _ x: Int) {
        var top = 0
        var y = x
        stack[0] = y
        while !_isSplayRoot(nodes, y) {
            y = nodes[y].parent
            top &+= 1
            stack[top] = y
        }
        while top >= 0 {
            _push(nodes, stack[top])
            top &-= 1
        }
        while !_isSplayRoot(nodes, x) {
            let y = nodes[x].parent
            if !_isSplayRoot(nodes, y) {
                let z = nodes[y].parent
                _rotate(nodes, (nodes[z].left == y) == (nodes[y].left == x) ? y : x)
            }
            _rotate(nodes, x)
        }
    }

    /// Makes the path from the root to `x` preferred, ending at `x`, and splays `x` to the root
    /// of its splay tree, which then holds exactly that path.
    @inlinable
    static func _access(_ nodes: UnsafeMutablePointer<_Node>, _ stack: UnsafeMutablePointer<Int>, _ x: Int) {
        var below = -1
        var y = x
        while y >= 0 {
            _splay(nodes, stack, y)
            nodes[y].right = below
            _pull(nodes, y)
            below = y
            y = nodes[y].parent
        }
        _splay(nodes, stack, x)
    }

    @inlinable
    static func _findRoot(_ nodes: UnsafeMutablePointer<_Node>, _ stack: UnsafeMutablePointer<Int>, _ x: Int) -> Int {
        _access(nodes, stack, x)
        var r = x
        _push(nodes, r)
        while nodes[r].left >= 0 {
            r = nodes[r].left
            _push(nodes, r)
        }
        _splay(nodes, stack, r)
        return r
    }
}

extension LinkCutTree: Sendable where Cost: Sendable {}
extension LinkCutTree._Node: Sendable where Cost: Sendable {}
