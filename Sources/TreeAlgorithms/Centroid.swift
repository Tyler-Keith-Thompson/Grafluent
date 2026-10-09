import Trees

extension Tree {
    /// The vertices whose removal leaves no component of more than n/2 vertices (Jordan's
    /// centroid; NetworkX `tree.centroid`), in `vertices` order: one, or two adjacent ones. Edge
    /// weights do not enter. O(n).
    @inlinable
    public func centroid() -> [Vertex] {
        let layout = _layout
        let n = layout.count
        // The largest component left by removing each vertex: its children's subtrees, and the
        // rest of the tree above it.
        var part = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            let size = layout.nodes[v].size
            part[v] = max(part[v], n - size)
            let p = layout.nodes[v].parent
            if p >= 0 { part[p] = max(part[p], size) }
        }
        return (0 ..< n).filter { 2 * part[$0] <= n }.map { layout.vertices[$0] }
    }

    /// The centroid decomposition: the rooted tree on the same vertices whose root is the
    /// centroid (the first in `vertices` order when there are two), whose root's children are
    /// the centroids, chosen the same way, of the components left when it is removed, and so on.
    /// Its edges are not the tree's: one (parent, child) per vertex but the root, in vertex
    /// order, so `children(of:)` is in vertex order. Height at most ⌊log₂ n⌋. O(n log n).
    @inlinable
    public func centroidDecomposition() -> RootedTree<Vertex> {
        let layout = _layout
        let n = layout.count
        var parents = [Int](repeating: -1, count: n)
        var removed = [Bool](repeating: false, count: n)
        var walkParent = [Int](repeating: -1, count: n)
        var size = [Int](repeating: 0, count: n)
        var component: [Int] = []
        // Jobs: a vertex of a component left, and the centroid it hangs from.
        var jobs: [(start: Int, parent: Int)] = [(layout.roots[0], -1)]
        while let (start, parent) = jobs.popLast() {
            // The component, breadth first, skipping removed vertices.
            component.removeAll(keepingCapacity: true)
            component.append(start)
            walkParent[start] = -1
            var head = 0
            while head < component.count {
                let x = component[head]
                head += 1
                for k in layout.rowOffsets[x] ..< layout.rowOffsets[x + 1] {
                    let y = layout.rowNeighbors[k]
                    if !removed[y], y != walkParent[x] {
                        walkParent[y] = x
                        component.append(y)
                    }
                }
            }
            let m = component.count
            for x in component { size[x] = 1 }
            for x in component.reversed() where walkParent[x] >= 0 { size[walkParent[x]] += size[x] }
            // The centroid with the least index: no part left of more than m/2 vertices.
            var centroid = -1
            for x in component where centroid < 0 || x < centroid {
                var largest = m - size[x]
                for k in layout.rowOffsets[x] ..< layout.rowOffsets[x + 1] {
                    let y = layout.rowNeighbors[k]
                    if !removed[y], y != walkParent[x] { largest = max(largest, size[y]) }
                }
                if 2 * largest <= m { centroid = x }
            }
            parents[centroid] = parent
            removed[centroid] = true
            for k in layout.rowOffsets[centroid] ..< layout.rowOffsets[centroid + 1] {
                let y = layout.rowNeighbors[k]
                if !removed[y] { jobs.append((y, centroid)) }
            }
        }
        return RootedTree(_layout: _TreeLayout.fromParents(vertices: layout.vertices, slots: layout.slots, dense: layout.dense, parents: parents)!)
    }
}
