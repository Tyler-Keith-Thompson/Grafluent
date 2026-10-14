import GraphProtocols

/// The k-components of an undirected graph (Moody and White's cohesive blocking): for each k ≥ 1,
/// the maximal sets of vertices whose induced subgraph is k-vertex-connected, that is, has more
/// than k vertices and stays connected after removing any k − 1 of them. The 1-components are the
/// connected components with an edge, the 2-components the blocks of three or more vertices; every
/// k-component lies inside a (k − 1)-component. Components at one level may share fewer than k
/// vertices.
///
/// Each component lists its vertices in `vertices` order; the components at a level are ordered
/// by their vertex lists, compared lexicographically by place in `vertices`.
@frozen
public struct KComponents<G: Graph> {
    /// Every component's vertices, level by level.
    @usableFromInline let _members: [G.Vertex]
    /// Component c is `_members[_componentOffsets[c] ..< _componentOffsets[c + 1]]`.
    @usableFromInline let _componentOffsets: [Int]
    /// The components of level k are `_levelOffsets[k - 1] ..< _levelOffsets[k]`.
    @usableFromInline let _levelOffsets: [Int]

    @inlinable
    init(members: [G.Vertex], componentOffsets: [Int], levelOffsets: [Int]) {
        _members = members
        _componentOffsets = componentOffsets
        _levelOffsets = levelOffsets
    }

    /// The greatest k with a k-component, or 0 when no edge joins two distinct vertices.
    @inlinable
    public var maximumK: Int { _levelOffsets.count - 1 }

    /// The k-components, each listing its vertices in `vertices` order; empty above `maximumK`.
    ///
    /// - Precondition: `k >= 1`.
    @inlinable
    public subscript(k: Int) -> [ArraySlice<G.Vertex>] {
        precondition(k >= 1, "k must be positive")
        guard k <= maximumK else { return [] }
        return (_levelOffsets[k - 1] ..< _levelOffsets[k]).map { c in
            _members[_componentOffsets[c] ..< _componentOffsets[c + 1]]
        }
    }
}

extension KComponents: Equatable where G.Vertex: Equatable {
    /// Whether both have the same components at every level, in the same order.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._levelOffsets == rhs._levelOffsets && lhs._componentOffsets == rhs._componentOffsets
            && lhs._members == rhs._members
    }
}

extension KComponents: Sendable where G.Vertex: Sendable {}

extension KComponents: CustomStringConvertible {
    public var description: String {
        let levels = (0 ..< maximumK).map { level in
            "\(level + 1): [" + self[level + 1].map { "[" + $0.map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
        }
        return "[" + levels.joined(separator: ", ") + "]"
    }
}

extension Graph {
    /// The k-components for every k (Moody and White's cohesive blocking): for each k, the maximal
    /// sets of vertices whose induced subgraph has more than k vertices and no vertex cut of fewer
    /// than k vertices. Parallel edges count once and self-loops not at all.
    ///
    /// Level 1 is the connected components with an edge and level 2 the blocks of three or more
    /// vertices. Each higher level refines each component of the level below: vertices of fewer
    /// than k neighbors are peeled off, and each piece left is either k-connected or split by a
    /// vertex cut X of fewer than k vertices into parts D, each searched again as D ∪ X. A cut is
    /// found by Even's method, unit-capacity flows on the split network between each of k
    /// vertices and every later one it is not adjacent to, each stopped after k augmenting paths.
    ///
    /// - Complexity: O(n + m) for levels 1 and 2; each refinement at level k makes at most k n
    ///   flows of O(k (n + m)) each.
    @inlinable
    public func kComponents() -> KComponents<Self> {
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: false, dropsLoops: true))
        var first: [[Int]] = []
        var second: [[Int]] = []
        do {
            let blocks = biconnectedComponents()
            let offsets = blocks._memberOffsets
            for b in 0 ..< offsets.count - 1 where offsets[b + 1] - offsets[b] > 2 {
                second.append(Array(blocks._memberNumbers[offsets[b] ..< offsets[b + 1]]))
            }
        }
        var cohesion = _VertexCohesion(rows)
        cohesion.connectedComponents(into: &first)
        let levels = cohesion.levels(first: first, second: second)
        let vertices = _DenseVertices(directedView)
        var members: [Vertex] = []
        var componentOffsets = [0], levelOffsets = [0]
        for level in levels {
            for component in level {
                for v in component { members.append(vertices.vertex(v)) }
                componentOffsets.append(members.count)
            }
            levelOffsets.append(componentOffsets.count - 1)
        }
        return KComponents(members: members, componentOffsets: componentOffsets, levelOffsets: levelOffsets)
    }
}

/// The index-space search behind `kComponents()`: simple rows (no loops, no repeated neighbors)
/// and scratch arrays stamped by tag, reused across every refinement.
@usableFromInline
struct _VertexCohesion {
    /// Simple rows: `targets[offsets[v] ..< offsets[v + 1]]` are v's distinct neighbors.
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]
    /// `mark[v] == tag` when v takes part in the current step.
    @usableFromInline var mark: [Int]
    @usableFromInline var tag = 0
    /// Each vertex's degree among the vertices taking part.
    @usableFromInline var degree: [Int]
    /// `seen[v] == epoch` when the current search has reached v.
    @usableFromInline var seen: [Int]
    @usableFromInline var epoch = 0
    /// Each vertex's number in the current split network.
    @usableFromInline var local: [Int]

    @usableFromInline
    init(_ rows: _CompressedRows) {
        let n = rows.count
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = []
        targets.reserveCapacity(rows.targets.count)
        var last = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                if last[w] != v {
                    last[w] = v
                    targets.append(w)
                }
            }
            offsets[v + 1] = targets.count
        }
        self.offsets = offsets
        self.targets = targets
        mark = [Int](repeating: 0, count: n)
        degree = [Int](repeating: 0, count: n)
        seen = [Int](repeating: 0, count: n)
        local = [Int](repeating: -1, count: n)
    }

    /// Appends the connected components with an edge, each ascending, in order of first vertex.
    @usableFromInline
    mutating func connectedComponents(into out: inout [[Int]]) {
        let n = offsets.count - 1
        epoch += 1
        var queue: [Int] = []
        for v in 0 ..< n where seen[v] != epoch && offsets[v + 1] > offsets[v] {
            seen[v] = epoch
            queue.removeAll(keepingCapacity: true)
            queue.append(v)
            var head = 0
            while head < queue.count {
                let x = queue[head]
                head += 1
                for slot in offsets[x] ..< offsets[x + 1] where seen[targets[slot]] != epoch {
                    seen[targets[slot]] = epoch
                    queue.append(targets[slot])
                }
            }
            out.append(queue.sorted())
        }
    }

    /// Every level, from the given first two: each level k ≥ 3 is the k-components found inside
    /// each component of level k − 1, until a level is empty.
    @usableFromInline
    mutating func levels(first: [[Int]], second: [[Int]]) -> [[[Int]]] {
        guard !first.isEmpty else { return [] }
        var levels = [first]
        var current = second
        var k = 2
        while !current.isEmpty {
            current.sort { $0.lexicographicallyPrecedes($1) }
            levels.append(current)
            k += 1
            var next: [[Int]] = []
            for component in current { maximalConnected(component, k: k, into: &next) }
            current = next
        }
        return levels
    }

    /// Appends the maximal k-connected sets inside `start`, each ascending.
    @usableFromInline
    mutating func maximalConnected(_ start: [Int], k: Int, into out: inout [[Int]]) {
        var stack = [start]
        var queue: [Int] = []
        var pieces: [[Int]] = []
        while let region = stack.popLast() {
            // Peel the vertices of fewer than k neighbors in the region, repeatedly.
            tag += 1
            for v in region { mark[v] = tag }
            queue.removeAll(keepingCapacity: true)
            for v in region {
                var d = 0
                for slot in offsets[v] ..< offsets[v + 1] where mark[targets[slot]] == tag { d += 1 }
                degree[v] = d
                if d < k { queue.append(v) }
            }
            for v in queue { mark[v] = 0 }
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for slot in offsets[v] ..< offsets[v + 1] {
                    let w = targets[slot]
                    guard mark[w] == tag else { continue }
                    degree[w] -= 1
                    if degree[w] < k {
                        mark[w] = 0
                        queue.append(w)
                    }
                }
            }
            // The pieces left, each either k-connected or split by a small cut.
            pieces.removeAll(keepingCapacity: true)
            components(of: region, into: &pieces)
            for piece in pieces {
                guard let cut = vertexCut(piece, below: k) else {
                    out.append(piece.sorted())
                    continue
                }
                tag += 1
                for v in piece { mark[v] = tag }
                for x in cut { mark[x] = 0 }
                var parts: [[Int]] = []
                components(of: piece, into: &parts)
                for part in parts { stack.append(part + cut) }
            }
        }
    }

    /// Appends the connected components among the vertices of `region` marked with `tag`.
    @usableFromInline
    mutating func components(of region: [Int], into out: inout [[Int]]) {
        epoch += 1
        for v in region where mark[v] == tag && seen[v] != epoch {
            seen[v] = epoch
            var component = [v]
            var head = 0
            while head < component.count {
                let x = component[head]
                head += 1
                for slot in offsets[x] ..< offsets[x + 1] {
                    let w = targets[slot]
                    if mark[w] == tag && seen[w] != epoch {
                        seen[w] = epoch
                        component.append(w)
                    }
                }
            }
            out.append(component)
        }
    }

    /// A vertex cut of fewer than k vertices in the subgraph induced by `piece` (connected, more
    /// than k vertices), or nil when it is k-connected. Even's method: when a cut X exists, the
    /// first vertex outside X is among the first k and X separates it from a later one, which it
    /// is not adjacent to.
    @usableFromInline
    mutating func vertexCut(_ piece: [Int], below k: Int) -> [Int]? {
        let c = piece.count
        for (i, v) in piece.enumerated() { local[v] = i }
        tag += 1
        for v in piece { mark[v] = tag }
        // The split network: v_in = 2i, v_out = 2i + 1; arc 2a and its reverse 2a + 1.
        var head: [Int] = [], capacity: [Int] = []
        for i in 0 ..< c {
            head.append(2 * i + 1)
            capacity.append(1)
            head.append(2 * i)
            capacity.append(0)
        }
        for (i, v) in piece.enumerated() {
            for slot in offsets[v] ..< offsets[v + 1] where mark[targets[slot]] == tag {
                head.append(2 * local[targets[slot]])
                capacity.append(c)
                head.append(2 * i + 1)
                capacity.append(0)
            }
        }
        let arcCount = head.count
        let nodeCount = 2 * c
        // Arcs by tail: arc a's tail is the head of its partner a ^ 1.
        var arcOffsets = [Int](repeating: 0, count: nodeCount + 1)
        for a in 0 ..< arcCount { arcOffsets[head[a ^ 1] + 1] += 1 }
        for x in 0 ..< nodeCount { arcOffsets[x + 1] += arcOffsets[x] }
        var fill = arcOffsets
        var arcs = [Int](repeating: 0, count: arcCount)
        for a in 0 ..< arcCount {
            let tail = head[a ^ 1]
            arcs[fill[tail]] = a
            fill[tail] += 1
        }
        var residual = capacity
        var reached = [Int](repeating: 0, count: nodeCount)
        var round = 0
        var parentArc = [Int](repeating: -1, count: nodeCount)
        var queue = [Int](repeating: 0, count: nodeCount)
        var adjacent = [Int](repeating: -1, count: c)
        for i in 0 ..< min(k, c) {
            let v = piece[i]
            for slot in offsets[v] ..< offsets[v + 1] where mark[targets[slot]] == tag { adjacent[local[targets[slot]]] = i }
            for j in (i + 1) ..< c where adjacent[j] != i {
                for a in 0 ..< arcCount { residual[a] = capacity[a] }
                let source = 2 * i + 1, sink = 2 * j
                var flow = 0
                while flow < k {
                    round += 1
                    reached[source] = round
                    queue[0] = source
                    var front = 0, back = 1
                    search: while front < back {
                        let x = queue[front]
                        front += 1
                        for slot in arcOffsets[x] ..< arcOffsets[x + 1] {
                            let a = arcs[slot]
                            let y = head[a]
                            guard residual[a] > 0, reached[y] != round else { continue }
                            reached[y] = round
                            parentArc[y] = a
                            if y == sink { break search }
                            queue[back] = y
                            back += 1
                        }
                    }
                    guard reached[sink] == round else { break }
                    var y = sink
                    while y != source {
                        let a = parentArc[y]
                        residual[a] -= 1
                        residual[a ^ 1] += 1
                        y = head[a ^ 1]
                    }
                    flow += 1
                }
                guard flow < k else { continue }
                // The last search failed: the cut is each vertex whose in-node it reached and
                // whose out-node it did not.
                var cut: [Int] = []
                for l in 0 ..< c where reached[2 * l] == round && reached[2 * l + 1] != round { cut.append(piece[l]) }
                return cut
            }
        }
        return nil
    }
}
