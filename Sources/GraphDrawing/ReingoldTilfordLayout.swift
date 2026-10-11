#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
#if canImport(math_h)
import math_h
#endif
import Trees

extension RootedTree {
    /// The tidy drawing of the tree: Reingold and Tilford's layered tree drawing as Walker
    /// refined it, in Buchheim, Jünger and Leipert's linear-time form.
    ///
    /// The root is at (0, 0) and a vertex at depth d has y = d. Children are placed left to right
    /// in `children(of:)` order, vertices at one depth at least 1 apart along each subtree's
    /// contour, and every parent centred over its first and last child. Where two subtrees had to
    /// be pushed apart, the smaller subtrees between them are spaced evenly (Walker's
    /// improvement), so a mirrored tree draws as the reflection of the drawing and isomorphic
    /// subtrees are drawn identically up to translation. Coordinates are multiples of a power of
    /// ½, exact in `Double`.
    ///
    /// - Reingold and Tilford, "Tidier drawings of trees", IEEE Transactions on Software
    ///   Engineering SE-7(2), 1981.
    /// - Walker, "A node-positioning algorithm for general trees", Software: Practice and
    ///   Experience 20(7), 1990.
    /// - Buchheim, Jünger and Leipert, "Improving Walker's algorithm to run in linear time",
    ///   Graph Drawing (GD 2002), LNCS 2528, 2002.
    ///
    /// O(n) time and memory, with no recursion.
    @inlinable
    public func reingoldTilfordLayout() -> Drawing<Vertex> {
        let layout = _layout
        return Drawing(_vertices: layout.vertices, positions: _walkerPositions(layout), offsets: layout.dense ? nil : layout.slots)
    }

    /// The tidy drawing bent into a disc (igraph's `layout_reingold_tilford_circular`): a vertex
    /// at (x, d) in `reingoldTilfordLayout()` goes to d · (cos φ, sin φ), with
    /// φ = 2π · (n − 1)/n · (x − x₀)/(x₁ − x₀) for the least and greatest x, x₀ and x₁ (no division
    /// when they are equal). The root is at the origin, and each depth on the circle of that
    /// radius.
    ///
    /// O(n) time and memory.
    @inlinable
    public func reingoldTilfordCircularLayout() -> Drawing<Vertex> {
        let layout = _layout
        return Drawing(_vertices: layout.vertices, positions: _polarPositions(_walkerPositions(layout)), offsets: layout.dense ? nil : layout.slots)
    }
}

/// Walker's positions of a rooted tree layout, by vertex number. The walks run on the vertices
/// renumbered in preorder, so that every subtree is a contiguous range and the walks read memory
/// almost in order; the positions are mapped back at the end.
@inlinable
func _walkerPositions<Vertex>(_ layout: _TreeLayout<Vertex>) -> [SIMD2<Double>] {
    let n = layout.count
    guard n > 0 else { return [] }
    let preorder = layout.preorder
    // rank[v]: v's preorder position.
    var rank = [Int](repeating: 0, count: n)
    for (i, v) in preorder.enumerated() { rank[v] = i }
    // Children rows in preorder numbering, each in `children(of:)` order.
    var childStart = [Int](repeating: 0, count: n + 1)
    var children = [Int](repeating: 0, count: n - 1)
    var parent = [Int](repeating: -1, count: n)
    var depth = [Int](repeating: 0, count: n)
    var fill = 0
    for i in 0 ..< n {
        let v = preorder[i]
        let node = layout.nodes[v]
        if node.parent >= 0 { parent[i] = rank[node.parent] }
        depth[i] = node.depth
        let hole = node.parentOffset
        let start = layout.rowOffsets[v], end = layout.rowOffsets[v + 1]
        for slot in start ..< end where slot - start != hole {
            children[fill] = rank[layout.rowNeighbors[slot]]
            fill += 1
        }
        childStart[i + 1] = fill
    }
    let walked = _walker(root: 0, parent: parent, depth: depth, childStart: childStart, children: children)
    var positions = [SIMD2<Double>](repeating: .zero, count: n)
    for i in 0 ..< n { positions[preorder[i]] = walked[i] }
    return positions
}

/// Buchheim, Jünger and Leipert's first and second walks over a tree given as child rows.
@usableFromInline
func _walker(root: Int, parent: [Int], depth: [Int], childStart: [Int], children: [Int]) -> [SIMD2<Double>] {
    let n = parent.count
    // Each vertex's offset among its siblings.
    var number = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        for (i, slot) in (childStart[v] ..< childStart[v + 1]).enumerated() { number[children[slot]] = i }
    }
    var prelim = [Double](repeating: 0, count: n)
    var mod = [Double](repeating: 0, count: n)
    var shift = [Double](repeating: 0, count: n)
    var change = [Double](repeating: 0, count: n)
    var thread = [Int](repeating: -1, count: n)
    var ancestor = Array(0 ..< n)
    // The default ancestor of each vertex's children while they are placed.
    var defaultAncestor = [Int](repeating: -1, count: n)

    @inline(__always) func leftSibling(_ v: Int) -> Int {
        let p = parent[v]
        return p < 0 || number[v] == 0 ? -1 : children[childStart[p] + number[v] - 1]
    }
    @inline(__always) func nextLeft(_ v: Int) -> Int {
        childStart[v] < childStart[v + 1] ? children[childStart[v]] : thread[v]
    }
    @inline(__always) func nextRight(_ v: Int) -> Int {
        childStart[v] < childStart[v + 1] ? children[childStart[v + 1] - 1] : thread[v]
    }

    // The first walk in postorder by an explicit stack: a vertex is finished once its last child
    // is, and then apportioned against its left siblings, as the recursive form does.
    var stack: [(vertex: Int, next: Int)] = [(root, childStart[root])]
    stack.reserveCapacity(64)
    while !stack.isEmpty {
        let top = stack.count - 1
        let v = stack[top].vertex, slot = stack[top].next
        if slot < childStart[v + 1] {
            stack[top].next = slot + 1
            let c = children[slot]
            if slot == childStart[v] { defaultAncestor[v] = c }
            stack.append((c, childStart[c]))
            continue
        }
        stack.removeLast()
        // Finish v.
        let w = leftSibling(v)
        if childStart[v] == childStart[v + 1] {
            prelim[v] = w >= 0 ? prelim[w] + 1 : 0
        } else {
            // Execute the shifts accumulated by the children's apportioning.
            var s = 0.0, c = 0.0
            var slot = childStart[v + 1] - 1
            while slot >= childStart[v] {
                let x = children[slot]
                prelim[x] += s
                mod[x] += s
                c += change[x]
                s += shift[x] + c
                slot -= 1
            }
            let mid = (prelim[children[childStart[v]]] + prelim[children[childStart[v + 1] - 1]]) / 2
            if w >= 0 {
                prelim[v] = prelim[w] + 1
                mod[v] = prelim[v] - mid
            } else {
                prelim[v] = mid
            }
        }
        // Apportion v against its left siblings' subtrees.
        let p = parent[v]
        guard p >= 0, w >= 0 else { continue }
        var vip = v, vop = v, vim = w
        var vom = children[childStart[p]]
        var sip = mod[vip], sop = mod[vop], sim = mod[vim], som = mod[vom]
        var defaultV = defaultAncestor[p]
        while nextRight(vim) >= 0 && nextLeft(vip) >= 0 {
            vim = nextRight(vim)
            vip = nextLeft(vip)
            vom = nextLeft(vom)
            vop = nextRight(vop)
            ancestor[vop] = v
            let gap = (prelim[vim] + sim) - (prelim[vip] + sip) + 1
            if gap > 0 {
                let a = parent[ancestor[vim]] == p ? ancestor[vim] : defaultV
                // Move the subtree of v right by `gap`, spreading it over the siblings between.
                let k = Double(number[v] - number[a])
                change[v] -= gap / k
                shift[v] += gap
                change[a] += gap / k
                prelim[v] += gap
                mod[v] += gap
                sip += gap
                sop += gap
            }
            sim += mod[vim]
            sip += mod[vip]
            som += mod[vom]
            sop += mod[vop]
        }
        if nextRight(vim) >= 0 && nextRight(vop) < 0 {
            thread[vop] = nextRight(vim)
            mod[vop] += sim - sop
        }
        if nextLeft(vip) >= 0 && nextLeft(vom) < 0 {
            thread[vom] = nextLeft(vip)
            mod[vom] += sip - som
            defaultV = v
        }
        defaultAncestor[p] = defaultV
    }

    // The second walk, in preorder (the numbering): x is prelim plus the ancestors' mods, the
    // root at 0.
    var offset = [Double](repeating: 0, count: n)
    var positions = [SIMD2<Double>](repeating: .zero, count: n)
    offset[root] = -prelim[root]
    for v in 0 ..< n {
        let p = parent[v]
        if p >= 0 { offset[v] = offset[p] + mod[p] }
        positions[v] = SIMD2(prelim[v] + offset[v], Double(depth[v]))
    }
    return positions
}

/// igraph's polar map of a tree drawing: x across 2π(n − 1)/n, depth as the radius.
@usableFromInline
func _polarPositions(_ positions: [SIMD2<Double>]) -> [SIMD2<Double>] {
    let n = positions.count
    guard n > 0 else { return [] }
    var low = positions[0].x, high = low
    for p in positions {
        low = Swift.min(low, p.x)
        high = Swift.max(high, p.x)
    }
    var ratio = 2 * Double.pi * (Double(n) - 1) / Double(n)
    if high > low { ratio /= high - low }
    return positions.map { p in
        let angle = (p.x - low) * ratio
        return SIMD2(p.y * cos(angle), p.y * sin(angle))
    }
}
