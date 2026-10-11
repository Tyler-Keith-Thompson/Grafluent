/// One relation the refinement counts along, as flat rows: for a splitter cell S, vertex v gets the
/// sum of `weights[k]` (1 without weights) over the slots k with `targets[k] == v` in the rows of
/// S's vertices.
struct _RefinementRelation {
    let offsets: UnsafeMutablePointer<Int>
    let targets: UnsafeMutablePointer<Int>
    let weights: UnsafeMutablePointer<UInt64>?
}

/// The graph the refinement runs on, immutable and shared by copies of a search: for isomorphism,
/// the disjoint union of the two graphs (G on `0..<half`, H on `half..<count`); one relation for
/// an undirected graph, two for a directed one (arcs into the splitter, then arcs out of it).
///
/// Phase 2 (automorphism group, canonical labeling) runs the same engine on one graph:
/// `half == count` and `balanced == false`.
final class _RefinementGraph {
    let count: Int
    let half: Int
    let balanced: Bool
    let relations: [_RefinementRelation]
    private var allocations: [UnsafeMutableRawPointer] = []

    /// The disjoint union of `g` and `h` (equal vertex counts), each row of `h` shifted by `half`.
    /// Edge colours become 64-bit weights, so that a count is a sum over a multiset of colours.
    init(union g: _IndexGraph, _ h: _IndexGraph) {
        let n = g.count
        count = 2 * n
        half = n
        balanced = true
        var relations: [_RefinementRelation] = []
        var allocations: [UnsafeMutableRawPointer] = []
        func relation(_ go: [Int], _ gt: [Int], _ gc: [Int], _ ho: [Int], _ ht: [Int], _ hc: [Int]) -> _RefinementRelation {
            let m = gt.count + ht.count
            let offsets = UnsafeMutablePointer<Int>.allocate(capacity: 2 * n + 1)
            let targets = UnsafeMutablePointer<Int>.allocate(capacity: max(m, 1))
            allocations.append(UnsafeMutableRawPointer(offsets))
            allocations.append(UnsafeMutableRawPointer(targets))
            for v in 0 ... n { offsets[v] = go[v] }
            for v in stride(from: 1, through: n, by: 1) { offsets[n + v] = gt.count + ho[v] }
            for k in 0 ..< gt.count { targets[k] = gt[k] }
            for k in 0 ..< ht.count { targets[gt.count + k] = ht[k] + n }
            var weights: UnsafeMutablePointer<UInt64>? = nil
            if !gc.isEmpty || !hc.isEmpty {
                let w = UnsafeMutablePointer<UInt64>.allocate(capacity: max(m, 1))
                allocations.append(UnsafeMutableRawPointer(w))
                for k in 0 ..< gc.count { w[k] = _colorWeight(gc[k]) }
                for k in 0 ..< hc.count { w[gt.count + k] = _colorWeight(hc[k]) }
                weights = w
            }
            return _RefinementRelation(offsets: offsets, targets: targets, weights: weights)
        }
        if g.isDirected {
            relations.append(relation(g.inOffsets, g.inTargets, g.inColors, h.inOffsets, h.inTargets, h.inColors))
            relations.append(relation(g.outOffsets, g.outTargets, g.outColors, h.outOffsets, h.outTargets, h.outColors))
        } else {
            relations.append(relation(g.outOffsets, g.outTargets, g.outColors, h.outOffsets, h.outTargets, h.outColors))
        }
        self.relations = relations
        self.allocations = allocations
    }

    deinit {
        for pointer in allocations { pointer.deallocate() }
    }
}

/// A nonzero 64-bit weight for an edge colour id (SplitMix64's finalizer).
@inline(__always)
func _colorWeight(_ id: Int) -> UInt64 {
    var z = UInt64(bitPattern: Int64(id)) &+ 0x9E37_79B9_7F4A_7C15
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return (z ^ (z >> 31)) | 1
}

/// An ordered partition of `0..<count` refined to the coarsest equitable partition below it, with
/// an undo trail (McKay 1981; McKay & Piperno 2014; bliss's sparse refinement, Junttila & Kaski
/// 2007).
///
/// Cells are ranges of `elements`, named by their first position; `cellOf` maps a vertex to its
/// cell. Splitting a cell keeps the untouched part (or the first fragment) at the cell's start and
/// gives every other fragment a new cell, so only touched vertices move; each new cell's start is
/// pushed on the trail, and undoing merges the most recent cell into the cell just before it.
/// Splitters wait in a queue; when a cell that is not queued splits, every fragment but a largest
/// is queued (Hopcroft's rule, sound for counting refinement by McKay's lemma).
///
/// In balanced mode (isomorphism, on the union of G and H) every cell must hold as many vertices
/// of G as of H; a split that breaks this fails the refinement, which is the search's pruning.
final class _PartitionRefinement {
    let graph: _RefinementGraph
    let count: Int
    let elements: UnsafeMutablePointer<Int>
    let position: UnsafeMutablePointer<Int>
    let cellOf: UnsafeMutablePointer<Int>
    /// By cell start.
    let cellLength: UnsafeMutablePointer<Int>
    /// By cell start: the number of G vertices in the cell.
    let sideCount: UnsafeMutablePointer<Int>
    /// By cell start: how many of its vertices the current splitter touched (moved to its end).
    let markCount: UnsafeMutablePointer<Int>
    let inQueue: UnsafeMutablePointer<Bool>
    let queue: UnsafeMutablePointer<Int>
    let touchedCells: UnsafeMutablePointer<Int>
    let splitter: UnsafeMutablePointer<Int>
    let counts: UnsafeMutablePointer<UInt64>
    /// The starts of the cells created, in order; at most `count - 1` at a time.
    let trail: UnsafeMutablePointer<Int>
    var trailCount = 0
    var cellCount = 0
    var queueHead = 0
    var queueCount = 0

    init(_ graph: _RefinementGraph) {
        self.graph = graph
        let n = max(graph.count, 1)
        count = graph.count
        elements = .allocate(capacity: n)
        position = .allocate(capacity: n)
        cellOf = .allocate(capacity: n)
        cellLength = .allocate(capacity: n)
        sideCount = .allocate(capacity: n)
        markCount = .allocate(capacity: n)
        markCount.initialize(repeating: 0, count: n)
        inQueue = .allocate(capacity: n)
        inQueue.initialize(repeating: false, count: n)
        queue = .allocate(capacity: n)
        touchedCells = .allocate(capacity: n)
        splitter = .allocate(capacity: n)
        counts = .allocate(capacity: n)
        trail = .allocate(capacity: n)
    }

    /// A copy with the same partition, trail and queue, sharing the graph.
    convenience init(copying other: _PartitionRefinement) {
        self.init(other.graph)
        let n = count
        elements.update(from: other.elements, count: n)
        position.update(from: other.position, count: n)
        cellOf.update(from: other.cellOf, count: n)
        cellLength.update(from: other.cellLength, count: n)
        sideCount.update(from: other.sideCount, count: n)
        inQueue.update(from: other.inQueue, count: n)
        queue.update(from: other.queue, count: n)
        trail.update(from: other.trail, count: n)
        trailCount = other.trailCount
        cellCount = other.cellCount
        queueHead = other.queueHead
        queueCount = other.queueCount
    }

    deinit {
        elements.deallocate()
        position.deallocate()
        cellOf.deallocate()
        cellLength.deallocate()
        sideCount.deallocate()
        markCount.deallocate()
        inQueue.deallocate()
        queue.deallocate()
        touchedCells.deallocate()
        splitter.deallocate()
        counts.deallocate()
        trail.deallocate()
    }

    /// The partition into colour classes (ids `0..<colorCount`, in id order), every cell queued.
    /// Returns false when a class is unbalanced. `colors` empty means one class.
    func start(colors: [Int]) -> Bool {
        let n = count
        trailCount = 0
        queueHead = 0
        queueCount = 0
        guard n > 0 else {
            cellCount = 0
            return true
        }
        if colors.isEmpty {
            for v in 0 ..< n { elements[v] = v; position[v] = v; cellOf[v] = 0 }
            cellLength[0] = n
            sideCount[0] = graph.half < n ? graph.half : n
            cellCount = 1
            enqueue(0)
            return !graph.balanced || 2 * sideCount[0] == n
        }
        let classes = (colors.max() ?? 0) + 1
        var starts = [Int](repeating: 0, count: classes + 1)
        for c in colors { starts[c + 1] += 1 }
        for c in 0 ..< classes { starts[c + 1] += starts[c] }
        var fill = starts
        for v in 0 ..< n {
            let p = fill[colors[v]]
            fill[colors[v]] += 1
            elements[p] = v
            position[v] = p
            cellOf[v] = starts[colors[v]]
        }
        cellCount = 0
        var ok = true
        for c in 0 ..< classes where starts[c + 1] > starts[c] {
            let s = starts[c], length = starts[c + 1] - s
            var side = 0
            for p in s ..< s + length where elements[p] < graph.half { side += 1 }
            cellLength[s] = length
            sideCount[s] = side
            cellCount += 1
            if graph.balanced && 2 * side != length { ok = false }
            enqueue(s)
        }
        if !ok { abandonQueue() }
        return ok
    }

    @inline(__always)
    func enqueue(_ cell: Int) {
        if inQueue[cell] { return }
        inQueue[cell] = true
        var slot = queueHead + queueCount
        if slot >= count { slot -= count }
        queue[slot] = cell
        queueCount += 1
    }

    func abandonQueue() {
        while queueCount > 0 {
            inQueue[queue[queueHead]] = false
            queueHead += 1
            if queueHead == count { queueHead = 0 }
            queueCount -= 1
        }
        queueHead = 0
    }

    /// Gives `u` and `x` (in one cell of length at least 3) a cell of their own, queued; the
    /// partition before must be equitable. In balanced mode `u` is in G and `x` in H.
    func individualize(_ u: Int, _ x: Int) {
        let c = cellOf[u]
        let length = cellLength[c]
        let end = c + length
        moveVertex(u, to: end - 2)
        moveVertex(x, to: end - 1)
        let s = end - 2
        cellOf[u] = s
        cellOf[x] = s
        cellLength[s] = 2
        let side = (u < graph.half ? 1 : 0) + (x < graph.half ? 1 : 0)
        sideCount[s] = side
        cellLength[c] = length - 2
        sideCount[c] -= side
        trail[trailCount] = s
        trailCount += 1
        cellCount += 1
        enqueue(s)
    }

    /// Gives `u` (in a cell of length at least 2) a cell of its own, queued. Phase 2's
    /// individualization on a single graph.
    func individualize(_ u: Int) {
        let c = cellOf[u]
        let length = cellLength[c]
        let s = c + length - 1
        moveVertex(u, to: s)
        cellOf[u] = s
        cellLength[s] = 1
        let side = u < graph.half ? 1 : 0
        sideCount[s] = side
        cellLength[c] = length - 1
        sideCount[c] -= side
        trail[trailCount] = s
        trailCount += 1
        cellCount += 1
        enqueue(s)
    }

    @inline(__always)
    func moveVertex(_ v: Int, to q: Int) {
        let p = position[v]
        if p == q { return }
        let other = elements[q]
        elements[q] = v
        position[v] = q
        elements[p] = other
        position[other] = p
    }

    /// Undoes every split after the trail had `mark` entries.
    func undo(to mark: Int) {
        while trailCount > mark {
            trailCount -= 1
            let s = trail[trailCount]
            let previous = cellOf[elements[s - 1]]
            let length = cellLength[s]
            for p in s ..< s + length { cellOf[elements[p]] = previous }
            cellLength[previous] += length
            sideCount[previous] += sideCount[s]
            cellCount -= 1
        }
    }

    /// Refines until no splitter is queued. Returns false, with the queue emptied, when a cell
    /// becomes unbalanced; the splits made stay on the trail for `undo(to:)`.
    func refine() -> Bool {
        let relations = graph.relations
        while queueCount > 0 {
            let s = queue[queueHead]
            queueHead += 1
            if queueHead == count { queueHead = 0 }
            queueCount -= 1
            inQueue[s] = false
            let length = cellLength[s]
            // A copy: splitting may permute the splitter's own cell.
            splitter.update(from: elements + s, count: length)
            for relation in relations {
                let ok = relation.weights == nil
                    ? split(length, relation.offsets, relation.targets)
                    : split(length, relation.offsets, relation.targets, relation.weights!)
                if !ok {
                    abandonQueue()
                    return false
                }
            }
        }
        return true
    }

    /// Counts the edges from the splitter (the first `length` entries of `splitter`) with weight 1,
    /// then splits the touched cells.
    private func split(_ length: Int, _ offsets: UnsafeMutablePointer<Int>, _ targets: UnsafeMutablePointer<Int>) -> Bool {
        var touched = 0
        for i in 0 ..< length {
            let w = splitter[i]
            var k = offsets[w]
            let end = offsets[w + 1]
            while k < end {
                let v = targets[k]
                k += 1
                let c = cellOf[v]
                let cellEnd = c + cellLength[c]
                if cellEnd - c == 1 { continue }
                let marked = markCount[c]
                let p = position[v]
                let boundary = cellEnd - marked
                if p < boundary {
                    let q = boundary - 1
                    let other = elements[q]
                    elements[q] = v
                    position[v] = q
                    elements[p] = other
                    position[other] = p
                    if marked == 0 {
                        touchedCells[touched] = c
                        touched += 1
                    }
                    markCount[c] = marked + 1
                    counts[v] = 1
                } else {
                    counts[v] &+= 1
                }
            }
        }
        return splitTouched(touched)
    }

    /// As `split(_:_:_:)`, with a weight per slot.
    private func split(_ length: Int, _ offsets: UnsafeMutablePointer<Int>, _ targets: UnsafeMutablePointer<Int>, _ weights: UnsafeMutablePointer<UInt64>) -> Bool {
        var touched = 0
        for i in 0 ..< length {
            let w = splitter[i]
            var k = offsets[w]
            let end = offsets[w + 1]
            while k < end {
                let v = targets[k]
                let weight = weights[k]
                k += 1
                let c = cellOf[v]
                let cellEnd = c + cellLength[c]
                if cellEnd - c == 1 { continue }
                let marked = markCount[c]
                let p = position[v]
                let boundary = cellEnd - marked
                if p < boundary {
                    let q = boundary - 1
                    let other = elements[q]
                    elements[q] = v
                    position[v] = q
                    elements[p] = other
                    position[other] = p
                    if marked == 0 {
                        touchedCells[touched] = c
                        touched += 1
                    }
                    markCount[c] = marked + 1
                    counts[v] = weight
                } else {
                    counts[v] &+= weight
                }
            }
        }
        return splitTouched(touched)
    }

    private func splitTouched(_ touched: Int) -> Bool {
        var ok = true
        for t in 0 ..< touched {
            let c = touchedCells[t]
            let marked = markCount[c]
            markCount[c] = 0
            if ok && !splitCell(c, marked) { ok = false }
        }
        return ok
    }

    /// Splits cell `c`, whose last `marked` vertices were touched, by their counts: the untouched
    /// part first (keeping `c`), then the touched vertices in increasing count.
    private func splitCell(_ c: Int, _ marked: Int) -> Bool {
        let length = cellLength[c]
        let end = c + length
        let first = end - marked
        var low = counts[elements[first]], high = low
        for p in first + 1 ..< end {
            let x = counts[elements[p]]
            if x < low { low = x } else if x > high { high = x }
        }
        if marked == length && low == high { return true }
        if low != high { sortByCount(first, end) }
        let half = graph.half
        let wasQueued = inQueue[c]
        // The part that keeps the name c: the untouched vertices, or the first count group.
        var keptEnd = first
        if marked == length {
            keptEnd = first + 1
            while keptEnd < end && counts[elements[keptEnd]] == low { keptEnd += 1 }
        }
        var keptSide = sideCount[c]
        var largest = c, largestLength = keptEnd - c
        var balanced = true
        var groupStart = keptEnd
        while groupStart < end {
            let key = counts[elements[groupStart]]
            var groupEnd = groupStart + 1
            while groupEnd < end && counts[elements[groupEnd]] == key { groupEnd += 1 }
            var side = 0
            for p in groupStart ..< groupEnd {
                let v = elements[p]
                cellOf[v] = groupStart
                if v < half { side += 1 }
            }
            let groupLength = groupEnd - groupStart
            cellLength[groupStart] = groupLength
            sideCount[groupStart] = side
            keptSide -= side
            trail[trailCount] = groupStart
            trailCount += 1
            cellCount += 1
            if 2 * side != groupLength { balanced = false }
            if wasQueued {
                enqueue(groupStart)
            } else if groupLength > largestLength {
                largest = groupStart
                largestLength = groupLength
            }
            groupStart = groupEnd
        }
        cellLength[c] = keptEnd - c
        sideCount[c] = keptSide
        if 2 * keptSide != keptEnd - c { balanced = false }
        if !wasQueued {
            var s = c
            while s < end {
                if s != largest { enqueue(s) }
                s += cellLength[s]
            }
        }
        return balanced || !graph.balanced
    }

    /// Sorts `elements[from..<to]` by count and updates their positions.
    private func sortByCount(_ from: Int, _ to: Int) {
        let counts = self.counts
        let span = to - from
        if span <= 16 {
            var i = from + 1
            while i < to {
                let v = elements[i]
                let key = counts[v]
                var j = i
                while j > from && counts[elements[j - 1]] > key {
                    elements[j] = elements[j - 1]
                    j -= 1
                }
                elements[j] = v
                i += 1
            }
        } else {
            var region = UnsafeMutableBufferPointer(start: elements + from, count: span)
            region.sort { counts[$0] < counts[$1] }
        }
        for p in from ..< to { position[elements[p]] = p }
    }
}
