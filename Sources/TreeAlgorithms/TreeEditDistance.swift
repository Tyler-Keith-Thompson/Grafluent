import Trees

extension OrderedTree {
    /// The tree edit distance to `other` at the given costs: the least total cost of deleting
    /// vertices of this tree, inserting vertices of `other` and substituting one for the other
    /// that turns this tree into `other`. Deleting a vertex makes its children children of its
    /// parent, in its place in the order; inserting is the reverse. Equivalently, the least cost
    /// of a mapping between the trees that keeps ancestry and sibling order, with unmapped
    /// vertices deleted or inserted.
    ///
    /// Zhang and Shasha's dynamic program over the keyroots of both trees.
    ///
    /// - Zhang and Shasha, "Simple fast algorithms for the editing distance between trees and
    ///   related problems", SIAM Journal on Computing 18(6), 1989.
    ///
    /// `deletionCost` and `insertionCost` are called once per vertex, and `substitutionCost` once
    /// per pair of vertices, during the call.
    ///
    /// - Parameters:
    ///   - other: The tree to reach.
    ///   - substitutionCost: The cost of substituting a vertex of this tree by one of `other`.
    ///   - deletionCost: The cost of deleting a vertex of this tree.
    ///   - insertionCost: The cost of inserting a vertex of `other`.
    /// - Returns: The distance.
    /// - Precondition: Every cost is not negative, and the sum of all deletion and insertion
    ///   costs fits in `Cost`.
    /// - Complexity: O(n · n′ · min(h, l) · min(h′, l′)) time for heights h, h′ and leaf counts
    ///   l, l′, and O(n · n′) memory.
    @inlinable
    public func treeEditDistance<Other: Hashable, Cost: AdditiveArithmetic & Comparable>(
        to other: OrderedTree<Other>,
        substitutionCost: (Vertex, Other) -> Cost, deletionCost: (Vertex) -> Cost, insertionCost: (Other) -> Cost
    ) -> Cost {
        let a = _ZhangShashaTree(_layout), b = _ZhangShashaTree(other._layout)
        let n = a.vertex.count, m = b.vertex.count
        let deletion = ContiguousArray(a.vertex.map { deletionCost(_layout.vertices[$0]) })
        let insertion = ContiguousArray(b.vertex.map { insertionCost(other._layout.vertices[$0]) })
        let stride = m + 1
        // treeDistance[i · m + j]: the distance between the subtrees at postorder i and j.
        var treeDistance = ContiguousArray(repeating: Cost.zero, count: n * m)
        // forestDistance[x · stride + y]: the distance between the forests of the first x and y
        // vertices (in postorder) of the two current keyroots' subtrees.
        var forestDistance = ContiguousArray(repeating: Cost.zero, count: (n + 1) * stride)
        a.leftmost.withUnsafeBufferPointer { la in
            b.leftmost.withUnsafeBufferPointer { lb in
                deletion.withUnsafeBufferPointer { deletion in
                    insertion.withUnsafeBufferPointer { insertion in
                        treeDistance.withUnsafeMutableBufferPointer { td in
                            forestDistance.withUnsafeMutableBufferPointer { fd in
                                for i in a.keyroots {
                                    let li = la[i], rows = i - li + 1
                                    for j in b.keyroots {
                                        let lj = lb[j], columns = j - lj + 1
                                        fd[0] = .zero
                                        for x in 1 ... rows { fd[x * stride] = fd[(x - 1) * stride] + deletion[li + x - 1] }
                                        for y in 1 ... columns { fd[y] = fd[y - 1] + insertion[lj + y - 1] }
                                        for x in 1 ... rows {
                                            let p = li + x - 1, row = x * stride, above = row - stride
                                            let wholeA = la[p] == li
                                            let del = deletion[p]
                                            for y in 1 ... columns {
                                                let q = lj + y - 1
                                                var best = fd[above + y] + del
                                                let inserted = fd[row + y - 1] + insertion[q]
                                                if inserted < best { best = inserted }
                                                if wholeA && lb[q] == lj {
                                                    let substituted = fd[above + y - 1]
                                                        + substitutionCost(_layout.vertices[a.vertex[p]], other._layout.vertices[b.vertex[q]])
                                                    if substituted < best { best = substituted }
                                                    td[p * m + q] = best
                                                } else {
                                                    let matched = fd[(la[p] - li) * stride + lb[q] - lj] + td[p * m + q]
                                                    if matched < best { best = matched }
                                                }
                                                fd[row + y] = best
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return treeDistance[n * m - 1]
    }

    /// The tree edit distance to `other` at unit costs: the fewest vertex deletions and
    /// insertions that turn this tree's shape into `other`'s, substitution being free. Zero
    /// exactly when the two have the same shape as ordered trees.
    ///
    /// - Complexity: As `treeEditDistance(to:substitutionCost:deletionCost:insertionCost:)`.
    @inlinable
    public func treeEditDistance<Other: Hashable>(to other: OrderedTree<Other>) -> Int {
        treeEditDistance(to: other, substitutionCost: { _, _ in 0 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 })
    }
}

/// A tree in postorder for Zhang and Shasha: each postorder position's vertex number, the
/// position of its leftmost leaf (its subtree is the interval from there to it), and the keyroots
/// (the root and every vertex that is not its parent's first child) in increasing order.
@frozen
@usableFromInline
struct _ZhangShashaTree {
    @usableFromInline var vertex: ContiguousArray<Int>
    @usableFromInline var leftmost: ContiguousArray<Int>
    @usableFromInline var keyroots: ContiguousArray<Int>

    @inlinable
    init<Vertex>(_ layout: _TreeLayout<Vertex>) {
        let n = layout.count
        var vertex = ContiguousArray(repeating: 0, count: n)
        var leftmost = ContiguousArray(repeating: 0, count: n)
        var position = ContiguousArray(repeating: 0, count: n)
        for v in 0 ..< n {
            // post(v) = pre(v) + size(v) − 1 − depth(v), as `RootedTree.postorder`.
            let node = layout.nodes[v]
            let p = node.preorderPosition + node.size - 1 - node.depth
            vertex[p] = v
            leftmost[p] = p - node.size + 1
            position[v] = p
        }
        var keyroots = ContiguousArray<Int>()
        for p in 0 ..< n {
            let parent = layout.nodes[vertex[p]].parent
            if parent < 0 || leftmost[position[parent]] != leftmost[p] { keyroots.append(p) }
        }
        self.vertex = vertex
        self.leftmost = leftmost
        self.keyroots = keyroots
    }
}
