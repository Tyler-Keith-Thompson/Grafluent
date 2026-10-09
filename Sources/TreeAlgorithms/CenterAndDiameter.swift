import Trees
import Walks

extension _TreeLayout {
    /// Each edge's weight by position, checked as it is read: at least `.zero` and not NaN.
    @inlinable
    func _weights<W: Comparable & AdditiveArithmetic>(_ weight: (Int) -> W) -> [W] {
        var weights: [W] = []
        weights.reserveCapacity(edgeCount)
        for e in 0 ..< edgeCount {
            let w = weight(e)
            precondition(w >= .zero && w == w, "Edge weights must be at least zero and not NaN")
            weights.append(w)
        }
        return weights
    }

    /// Every vertex's eccentricity, in one rerooting pass: in reverse preorder the two longest
    /// chains down from each vertex (and the child the longest goes through), in preorder the
    /// longest leaving its subtree through its parent.
    @inlinable
    func _eccentricities<W: Comparable & AdditiveArithmetic>(_ weights: [W]) -> [W] {
        let n = count
        guard n > 0 else { return [] }
        var down1 = [W](repeating: .zero, count: n), down2 = [W](repeating: .zero, count: n)
        var through = [Int](repeating: -1, count: n)
        for i in stride(from: n - 1, through: 1, by: -1) {
            let v = preorder[i]
            let p = nodes[v].parent
            let chain = down1[v] + weights[nodes[v].parentEdge]
            if through[p] < 0 || chain > down1[p] {
                down2[p] = down1[p]
                down1[p] = chain
                through[p] = v
            } else if chain > down2[p] {
                down2[p] = chain
            }
        }
        var up = [W](repeating: .zero, count: n)
        var eccentricity = [W](repeating: .zero, count: n)
        eccentricity[preorder[0]] = down1[preorder[0]]
        for i in 1 ..< n {
            let v = preorder[i]
            let p = nodes[v].parent
            let sideways = through[p] == v ? down2[p] : down1[p]
            up[v] = weights[nodes[v].parentEdge] + max(up[p], sideways)
            eccentricity[v] = max(down1[v], up[v])
        }
        return eccentricity
    }

    @inlinable
    func _center<W: Comparable & AdditiveArithmetic>(_ weights: [W]) -> [Vertex] {
        let eccentricity = _eccentricities(weights)
        guard let least = eccentricity.min() else { return [] }
        return (0 ..< count).filter { eccentricity[$0] == least }.map { vertices[$0] }
    }

    /// The path between the first vertex of greatest eccentricity and the first vertex farthest
    /// from it, by vertex index, and its length.
    @inlinable
    func _diameterPath<W: Comparable & AdditiveArithmetic>(_ weights: [W]) -> (path: Path<Vertex, Int>, distance: W) {
        let eccentricity = _eccentricities(weights)
        let greatest = eccentricity.max()!
        let u = eccentricity.firstIndex(of: greatest)!
        // Distances from u, by one walk over the rows.
        var distance = [W](repeating: .zero, count: count)
        var seen = [Bool](repeating: false, count: count)
        seen[u] = true
        var stack = [u]
        while let x = stack.popLast() {
            for k in rowOffsets[x] ..< rowOffsets[x + 1] {
                let y = rowNeighbors[k]
                if !seen[y] {
                    seen[y] = true
                    distance[y] = distance[x] + weights[rowEdges[k]]
                    stack.append(y)
                }
            }
        }
        // The first farthest by this walk's own sums: with floating point they can differ from the
        // eccentricities' in the last digit, so neither is looked up in the other.
        var v = u
        for x in 0 ..< count where distance[x] > distance[v] { v = x }
        let (vs, es) = path(u, v)!
        return (Path(_uncheckedVertices: vs.map { vertices[$0] }, edges: es), distance[v])
    }
}

extension Tree {
    /// The vertices of least eccentricity, in `vertices` order: one, or two adjacent ones
    /// (NetworkX `tree.center`, JGraphT's `TreeMeasurer`). O(n).
    @inlinable
    public func center() -> [Vertex] {
        _layout._center([Int](repeating: 1, count: edgeCount))
    }

    /// The vertices of least eccentricity by weighted distance, in `vertices` order: one or two
    /// adjacent vertices for positive weights, any number with zero weights. `weight` is called
    /// once per edge, in position order. O(n).
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN, and the sums fit in `W`.
    @inlinable
    public func center<W: Comparable & AdditiveArithmetic>(weight: (Int) -> W) -> [Vertex] {
        _layout._center(_layout._weights(weight))
    }

    /// The greatest number of edges between two vertices; 0 for one vertex. O(n).
    @inlinable
    public func diameter() -> Int {
        _layout._eccentricities([Int](repeating: 1, count: edgeCount)).max()!
    }

    /// The greatest weighted distance between two vertices. O(n).
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN, and the sums fit in `W`.
    @inlinable
    public func diameter<W: Comparable & AdditiveArithmetic>(weight: (Int) -> W) -> W {
        _layout._eccentricities(_layout._weights(weight)).max()!
    }

    /// A longest path, as igraph's `get_diameter` returns one, with ties broken by vertex index:
    /// from the first vertex in `vertices` order of greatest eccentricity to the first vertex
    /// farthest from it, so the lexicographically least such pair. The trivial path at the first
    /// vertex for one vertex. O(n).
    @inlinable
    public func diameterPath() -> Path<Vertex, Int> {
        _layout._diameterPath([Int](repeating: 1, count: edgeCount)).path
    }

    /// A longest path by weighted distance, chosen as `diameterPath()` chooses, and its weight
    /// summed along the path (with floating point, it can differ from `diameter(weight:)` in the
    /// last digit, the sums being taken in another order). O(n).
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN, and the sums fit in `W`.
    @inlinable
    public func diameterPath<W: Comparable & AdditiveArithmetic>(weight: (Int) -> W) -> (path: Path<Vertex, Int>, distance: W) {
        _layout._diameterPath(_layout._weights(weight))
    }
}
