import GraphProtocols

/// What one biconnectivity search records, and when it may stop early.
@frozen
@usableFromInline
struct _BiconnectivityOptions: OptionSet {
    @usableFromInline let rawValue: Int
    @inlinable init(rawValue: Int) { self.rawValue = rawValue }

    /// A block label per edge (keeps an edge stack).
    @usableFromInline static var blocks: Self { Self(rawValue: 1) }
    /// A 2-edge-connected component label per vertex (keeps a vertex stack).
    @usableFromInline static var biEdgeComponents: Self { Self(rawValue: 2) }
    /// Stop at the first bridge.
    @usableFromInline static var stopAtBridge: Self { Self(rawValue: 4) }
    /// Stop at the first articulation point.
    @usableFromInline static var stopAtArticulationPoint: Self { Self(rawValue: 8) }
    /// Search from the first vertex only: enough to tell whether the graph is connected.
    @usableFromInline static var firstTreeOnly: Self { Self(rawValue: 16) }
}

/// The result of a search: per vertex, whether it is an articulation point and its 2-edge-
/// connected label; per edge, whether it is a bridge and its block label (−1 for a self-loop or
/// when not asked); the label counts; how many vertices the first tree reached; and whether the
/// search stopped early.
@frozen
@usableFromInline
struct _Biconnectivity {
    @usableFromInline var isArticulationPoint: [Bool]
    @usableFromInline var isBridge: [Bool]
    @usableFromInline var blockLabel: [Int]
    @usableFromInline var blockCount = 0
    /// With blocks: each (block, vertex) membership, once, as the search pops each block (its
    /// parent vertex and the child of each tree edge in it): n − c + blocks pairs in all.
    @usableFromInline var memberBlock: [Int] = []
    @usableFromInline var memberVertex: [Int] = []
    @usableFromInline var biEdgeLabel: [Int]
    @usableFromInline var biEdgeCount = 0
    @usableFromInline var firstTreeSize = 0
    @usableFromInline var stoppedEarly = false

    @inlinable
    init(isArticulationPoint: [Bool], isBridge: [Bool], blockLabel: [Int], biEdgeLabel: [Int]) {
        self.isArticulationPoint = isArticulationPoint
        self.isBridge = isBridge
        self.blockLabel = blockLabel
        self.biEdgeLabel = biEdgeLabel
    }
}

/// Hopcroft–Tarjan, iteratively: one depth-first search with an explicit frame stack computes
/// discovery times and low points, and from them bridges, articulation points, blocks and
/// 2-edge-connected components.
///
/// It skips the parent *edge*, not the parent vertex: a parallel copy of the tree edge into `v`
/// is a back edge to the parent, so the tree edge is not a bridge and the copy joins its block.
/// A back edge is pushed once, from its lower end; a self-loop is never pushed, so it is in no
/// block and never a bridge.
@frozen
@usableFromInline
struct _BiconnectivitySearch: _UndirectedRowsAlgorithm {
    @usableFromInline let options: _BiconnectivityOptions

    @inlinable
    init(_ options: _BiconnectivityOptions) { self.options = options }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> _Biconnectivity {
        let wantBlocks = options.contains(.blocks)
        let wantBiEdge = options.contains(.biEdgeComponents)
        let stopAtBridge = options.contains(.stopAtBridge)
        let stopAtPoint = options.contains(.stopAtArticulationPoint)
        let firstTreeOnly = options.contains(.firstTreeOnly)
        var result = _Biconnectivity(
            isArticulationPoint: [Bool](repeating: false, count: n),
            isBridge: [Bool](repeating: false, count: m),
            blockLabel: wantBlocks ? [Int](repeating: -1, count: m) : [],
            biEdgeLabel: wantBiEdge ? [Int](repeating: -1, count: n) : [])
        let unvisited = -1
        var disc = [Int](repeating: unvisited, count: n)
        var low = [Int](repeating: 0, count: n)
        var parentEdge = [Int](repeating: -1, count: n)
        // Each frame: the vertex and the offset in its row of the next edge end to scan.
        var frames: [(v: Int, next: Int)] = []
        var edgeStack: [Int] = []
        // Beside each stacked edge: the child it leads to for a tree edge, −1 for a back edge.
        var childStack: [Int] = []
        var vertexStack: [Int] = []
        var time = 0

        search: for root in 0 ..< n where disc[root] == unvisited {
            if firstTreeOnly && root > 0 { break }
            disc[root] = time
            low[root] = time
            time += 1
            var rootChildren = 0
            var treeSize = 1
            if wantBiEdge { vertexStack.append(root) }
            frames.append((root, 0))
            while let (v, k) = frames.last {
                if k < rows.count(v) {
                    frames[frames.count - 1].next = k + 1
                    let w = rows.neighbor(v, k)
                    let e = rows.edge(v, k)
                    // The rows are unchecked buffers: a conformer breaking the index laws traps
                    // here instead of corrupting memory.
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n) && UInt(bitPattern: e) < UInt(bitPattern: m), "A neighbor or edge index is out of range")
                    if w == v || e == parentEdge[v] { continue }
                    if disc[w] == unvisited {
                        parentEdge[w] = e
                        disc[w] = time
                        low[w] = time
                        time += 1
                        treeSize += 1
                        if wantBlocks {
                            edgeStack.append(e)
                            childStack.append(w)
                        }
                        if wantBiEdge { vertexStack.append(w) }
                        if v == root { rootChildren += 1 }
                        frames.append((w, 0))
                    } else if disc[w] < disc[v] {
                        if wantBlocks {
                            edgeStack.append(e)
                            childStack.append(-1)
                        }
                        if disc[w] < low[v] { low[v] = disc[w] }
                    }
                    continue
                }
                frames.removeLast()
                guard let p = frames.last?.v else { break }
                if low[v] < low[p] { low[p] = low[v] }
                if low[v] > disc[p] {
                    result.isBridge[parentEdge[v]] = true
                    if stopAtBridge {
                        result.stoppedEarly = true
                        break search
                    }
                    if wantBiEdge {
                        let label = result.biEdgeCount
                        result.biEdgeCount += 1
                        while true {
                            let x = vertexStack.removeLast()
                            result.biEdgeLabel[x] = label
                            if x == v { break }
                        }
                    }
                }
                if low[v] >= disc[p] {
                    if p != root {
                        result.isArticulationPoint[p] = true
                        if stopAtPoint {
                            result.stoppedEarly = true
                            break search
                        }
                    }
                    if wantBlocks {
                        let label = result.blockCount
                        result.blockCount += 1
                        result.memberBlock.append(label)
                        result.memberVertex.append(p)
                        while true {
                            let e = edgeStack.removeLast()
                            let child = childStack.removeLast()
                            result.blockLabel[e] = label
                            if child >= 0 {
                                result.memberBlock.append(label)
                                result.memberVertex.append(child)
                            }
                            if e == parentEdge[v] { break }
                        }
                    }
                }
            }
            if rootChildren >= 2 {
                result.isArticulationPoint[root] = true
                if stopAtPoint {
                    result.stoppedEarly = true
                    break search
                }
            }
            if wantBiEdge {
                let label = result.biEdgeCount
                result.biEdgeCount += 1
                for x in vertexStack { result.biEdgeLabel[x] = label }
                vertexStack.removeAll(keepingCapacity: true)
            }
            if root == 0 { result.firstTreeSize = treeSize }
        }
        return result
    }
}

/// Relabels `labels` (values in `0..<count`, −1 for none) so that labels are numbered in order of
/// first appearance, scanning the indices in order. Returns the map from old labels to new.
@inlinable
@discardableResult
func _relabelByFirstAppearance(_ labels: inout [Int], count: Int) -> [Int] {
    var map = [Int](repeating: -1, count: count)
    var next = 0
    for i in labels.indices where labels[i] >= 0 {
        if map[labels[i]] < 0 {
            map[labels[i]] = next
            next += 1
        }
        labels[i] = map[labels[i]]
    }
    return map
}

/// A stable counting sort of `items` by `key`, keys in `0..<keyCount`: the items in key order
/// (input order within a key), and the offsets where each key's items start (`keyCount + 1`).
@inlinable
func _countingSort(_ items: [Int], by key: [Int], keyCount: Int) -> (items: [Int], offsets: [Int]) {
    var offsets = [Int](repeating: 0, count: keyCount + 1)
    var sorted = [Int](repeating: 0, count: items.count)
    offsets.withUnsafeMutableBufferPointer { offsets in
        key.withUnsafeBufferPointer { key in
            items.withUnsafeBufferPointer { items in
                sorted.withUnsafeMutableBufferPointer { sorted in
                    for i in items { offsets[key[i] + 1] += 1 }
                    for c in 0 ..< keyCount { offsets[c + 1] += offsets[c] }
                    var next = Array(offsets)
                    next.withUnsafeMutableBufferPointer { next in
                        for i in items {
                            sorted[next[key[i]]] = i
                            next[key[i]] += 1
                        }
                    }
                }
            }
        }
    }
    return (sorted, offsets)
}
