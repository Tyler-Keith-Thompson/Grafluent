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
    /// Stop at the first articulation point, and after the first search tree.
    @usableFromInline static var stopAtArticulationPoint: Self { Self(rawValue: 8) }
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
    func run<Arcs: IteratorProtocol>(count n: Int, edgeCount m: Int, _ arcs: (Int) -> Arcs) -> _Biconnectivity where Arcs.Element == (Int, Int) {
        let wantBlocks = options.contains(.blocks)
        let wantBiEdge = options.contains(.biEdgeComponents)
        let stopAtBridge = options.contains(.stopAtBridge)
        let stopAtPoint = options.contains(.stopAtArticulationPoint)
        var result = _Biconnectivity(
            isArticulationPoint: [Bool](repeating: false, count: n),
            isBridge: [Bool](repeating: false, count: m),
            blockLabel: wantBlocks ? [Int](repeating: -1, count: m) : [],
            biEdgeLabel: wantBiEdge ? [Int](repeating: -1, count: n) : [])
        let unvisited = -1
        var disc = [Int](repeating: unvisited, count: n)
        var low = [Int](repeating: 0, count: n)
        var parentEdge = [Int](repeating: -1, count: n)
        var frames: [(v: Int, arcs: Arcs)] = []
        var edgeStack: [Int] = []
        var vertexStack: [Int] = []
        var time = 0

        search: for root in 0 ..< n where disc[root] == unvisited {
            if stopAtPoint && root > 0 { break }
            disc[root] = time
            low[root] = time
            time += 1
            var rootChildren = 0
            var treeSize = 1
            if wantBiEdge { vertexStack.append(root) }
            frames.append((root, arcs(root)))
            while !frames.isEmpty {
                let v = frames[frames.count - 1].v
                if let (w, e) = frames[frames.count - 1].arcs.next() {
                    if w == v || e == parentEdge[v] { continue }
                    if disc[w] == unvisited {
                        parentEdge[w] = e
                        disc[w] = time
                        low[w] = time
                        time += 1
                        treeSize += 1
                        if wantBlocks { edgeStack.append(e) }
                        if wantBiEdge { vertexStack.append(w) }
                        if v == root { rootChildren += 1 }
                        frames.append((w, arcs(w)))
                    } else if disc[w] < disc[v] {
                        if wantBlocks { edgeStack.append(e) }
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
                        while true {
                            let e = edgeStack.removeLast()
                            result.blockLabel[e] = label
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
/// first appearance, scanning the indices in order.
@inlinable
func _relabelByFirstAppearance(_ labels: inout [Int], count: Int) {
    var map = [Int](repeating: -1, count: count)
    var next = 0
    for i in labels.indices where labels[i] >= 0 {
        if map[labels[i]] < 0 {
            map[labels[i]] = next
            next += 1
        }
        labels[i] = map[labels[i]]
    }
}
