/// One relation the refinement counts along, as flat rows: for a splitter cell S, vertex v gets the
/// sum of `weights[k]` (1 without weights) over the slots k with `targets[k] == v` in the rows of
/// S's vertices.
struct _RefinementRelation {
    let offsets: UnsafeMutablePointer<Int>
    let targets: UnsafeMutablePointer<Int>
    let weights: UnsafeMutablePointer<UInt64>?
}

/// The graph the refinement runs on, immutable and shared by copies of a search. For isomorphism
/// it is the disjoint union of the two graphs (G on `0..<half`, H on `half..<count`); for the
/// automorphism group and canonical labeling it is one graph (`half == count`, `balanced == false`).
/// One relation for an undirected graph, two for a directed one (arcs into the splitter, then arcs
/// out of it). Edge colours become 64-bit weights, so that a count is a sum over a multiset of
/// colours.
final class _RefinementGraph {
    let count: Int
    let half: Int
    let balanced: Bool
    let relations: [_RefinementRelation]
    private var allocations: [UnsafeMutableRawPointer] = []

    /// The disjoint union of `g` and `h` (equal vertex counts), each row of `h` shifted by `half`.
    convenience init(union g: _IndexGraph, _ h: _IndexGraph) {
        self.init(parts: [g, h], balanced: true)
    }

    /// One graph.
    convenience init(single g: _IndexGraph) {
        self.init(parts: [g], balanced: false)
    }

    private init(parts: [_IndexGraph], balanced: Bool) {
        let n = parts[0].count
        count = n * parts.count
        half = n
        self.balanced = balanced
        var allocations: [UnsafeMutableRawPointer] = []
        func relation(_ rows: [(offsets: [Int], targets: [Int], colors: [Int])]) -> _RefinementRelation {
            let m = rows.reduce(0) { $0 + $1.targets.count }
            let offsets = UnsafeMutablePointer<Int>.allocate(capacity: n * rows.count + 1)
            let targets = UnsafeMutablePointer<Int>.allocate(capacity: max(m, 1))
            allocations.append(UnsafeMutableRawPointer(offsets))
            allocations.append(UnsafeMutableRawPointer(targets))
            let colored = rows.contains { !$0.colors.isEmpty }
            let weights: UnsafeMutablePointer<UInt64>? = colored ? .allocate(capacity: max(m, 1)) : nil
            if let weights { allocations.append(UnsafeMutableRawPointer(weights)) }
            offsets[0] = 0
            var base = 0
            for (part, row) in rows.enumerated() {
                let shift = part * n
                for v in 0 ..< n { offsets[shift + v + 1] = base + row.offsets[v + 1] }
                for k in 0 ..< row.targets.count { targets[base + k] = row.targets[k] + shift }
                if let weights {
                    for k in 0 ..< row.colors.count { weights[base + k] = _colorWeight(row.colors[k]) }
                }
                base += row.targets.count
            }
            return _RefinementRelation(offsets: offsets, targets: targets, weights: weights)
        }
        var relations: [_RefinementRelation] = []
        if parts[0].isDirected {
            relations.append(relation(parts.map { ($0.inOffsets, $0.inTargets, $0.inColors) }))
        }
        relations.append(relation(parts.map { ($0.outOffsets, $0.outTargets, $0.outColors) }))
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
/// an undo trail (McKay 1981; McKay & Piperno 2014; sparse refinement, Junttila & Kaski 2007).
///
/// Cells are ranges of `elements`, named by their first position; `cellOf` maps a vertex to its
/// cell. Splitting a cell keeps the untouched part (or the first fragment) at the cell's start and
/// gives every other fragment a new cell, so only touched vertices move; each new cell's start is
/// pushed on the trail, and undoing merges the most recent cell into the cell just before it.
/// Splitters wait in a queue; when a cell that is not queued splits, every fragment but a largest
/// is queued (Hopcroft's rule, sound for counting refinement by McKay's lemma).
///
/// The cells longer than `unit` (2 in balanced mode, where a cell of two is a matched pair, else 1)
/// are kept in a list in position order, so that choosing a target cell does not scan the
/// singletons. Removing a cell from the list keeps its own links, and the trail undoes every change
/// in reverse order, so a removed cell goes back between the same neighbours (dancing links).
///
/// In balanced mode (isomorphism, on the union of G and H) every cell must hold as many vertices of
/// G as of H; a split that breaks this fails the refinement, which is the search's pruning.
/// Otherwise (one graph) the refinement is label-invariant: touched cells split in position order,
/// and `trace` hashes the cell structure each step produces (the search's node invariant).
final class _PartitionRefinement {
    let graph: _RefinementGraph
    let count: Int
    let unit: Int
    let invariant: Bool
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
    /// The list of cells longer than `unit`, by cell start; `count` is the head.
    let nextCell: UnsafeMutablePointer<Int>
    let previousCell: UnsafeMutablePointer<Int>
    let listed: UnsafeMutablePointer<Bool>
    var trailCount = 0
    var cellCount = 0
    var queueHead = 0
    var queueCount = 0
    /// A hash of the splits since it was last reset (single-graph mode only): updated at each
    /// event (a splitter taken from the queue, a cell split, an individualization, the end).
    var trace: UInt64 = 0
    /// When set, the value of `trace` after each event is appended to `recorded`.
    var recording = false
    var recorded: [UInt64] = []
    /// When set, the events are compared with `firstReference` (while `equalsFirst`) and
    /// `bestReference` (while `comparedToBest == 0`) as they happen, and the refinement stops
    /// (`refine()` returns false) once it can no longer equal the first and is not greater than the
    /// best (any more than the first, when `!canonical`).
    var checking = false
    var canonical = false
    var equalsFirst = false
    var comparedToBest = 0
    var firstReference: [UInt64] = []
    var bestReference: [UInt64] = []
    var eventIndex = 0
    var diverged = false

    init(_ graph: _RefinementGraph) {
        self.graph = graph
        let n = max(graph.count, 1)
        count = graph.count
        unit = graph.balanced ? 2 : 1
        invariant = !graph.balanced
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
        nextCell = .allocate(capacity: n + 1)
        previousCell = .allocate(capacity: n + 1)
        listed = .allocate(capacity: n)
        listed.initialize(repeating: false, count: n)
        nextCell[count] = count
        previousCell[count] = count
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
        nextCell.deallocate()
        previousCell.deallocate()
        listed.deallocate()
    }

    /// Whether every cell is a unit (a matched pair, or a single vertex).
    @inline(__always)
    var isDiscrete: Bool { nextCell[count] == count }

    @inline(__always)
    func mix(_ x: Int) {
        var z = (trace ^ UInt64(bitPattern: Int64(x))) &* 0x9E37_79B9_7F4A_7C15
        z ^= z >> 32
        trace = z
        if recording { recorded.append(z) }
        if checking { check(z) }
    }

    /// Compares event `eventIndex` with the references.
    private func check(_ z: UInt64) {
        let i = eventIndex
        eventIndex += 1
        if equalsFirst && (i >= firstReference.count || firstReference[i] != z) { equalsFirst = false }
        if comparedToBest == 0 {
            if i >= bestReference.count {
                comparedToBest = 1
            } else if bestReference[i] != z {
                comparedToBest = z < bestReference[i] ? -1 : 1
            }
        }
        if !equalsFirst && (!canonical || comparedToBest < 0) { diverged = true }
    }

    /// Sets up the comparison of the next refinement's events: `first` and `best` are the events of
    /// the reference nodes at the same depth (nil: none), `equalsFirst` and `comparedToBest` the
    /// parent's standing.
    func startChecking(first: [UInt64]?, best: [UInt64]?, equalsFirst: Bool, comparedToBest: Int, canonical: Bool) {
        checking = true
        self.canonical = canonical
        eventIndex = 0
        diverged = false
        self.equalsFirst = equalsFirst && first != nil
        firstReference = first ?? []
        self.comparedToBest = comparedToBest
        bestReference = best ?? []
        if comparedToBest == 0 && best == nil { self.comparedToBest = 1 }
        if !canonical { self.comparedToBest = -1 }
    }

    // MARK: the list of cells longer than `unit`

    @inline(__always)
    private func link(_ c: Int, after a: Int) {
        let b = nextCell[a]
        nextCell[c] = b
        previousCell[c] = a
        nextCell[a] = c
        previousCell[b] = c
        listed[c] = true
    }

    /// Takes `c` out of the list, keeping its own links for `relink`.
    @inline(__always)
    private func unlink(_ c: Int) {
        nextCell[previousCell[c]] = nextCell[c]
        previousCell[nextCell[c]] = previousCell[c]
        listed[c] = false
    }

    @inline(__always)
    private func relink(_ c: Int) {
        nextCell[previousCell[c]] = c
        previousCell[nextCell[c]] = c
        listed[c] = true
    }

    /// The list's part of one split: cell `x`, covering `x..<end`, gives `f..<end` to a new cell.
    @inline(__always)
    private func listSplit(_ x: Int, _ f: Int, _ end: Int) {
        if end - f > unit { link(f, after: x) }
        if f - x <= unit && listed[x] { unlink(x) }
    }

    /// The first smallest cell longer than `unit`, or -1 when the partition is discrete.
    func firstSmallestCell() -> Int {
        var best = -1, bestLength = Int.max
        var c = nextCell[count]
        while c != count {
            let length = cellLength[c]
            if length < bestLength {
                best = c
                bestLength = length
                if length == unit + 1 { break }
            }
            c = nextCell[c]
        }
        return best
    }

    /// The first largest cell longer than `unit`, or -1 when the partition is discrete.
    func firstLargestCell() -> Int {
        var best = -1, bestLength = 0
        var c = nextCell[count]
        while c != count {
            if cellLength[c] > bestLength {
                best = c
                bestLength = cellLength[c]
            }
            c = nextCell[c]
        }
        return best
    }

    // MARK: refinement

    /// The partition into colour classes (ids `0..<colorCount`, in id order), every cell queued.
    /// Returns false when a class is unbalanced. `colors` empty means one class.
    func start(colors: [Int]) -> Bool {
        let n = count
        trailCount = 0
        queueHead = 0
        queueCount = 0
        nextCell[n] = n
        previousCell[n] = n
        guard n > 0 else {
            cellCount = 0
            return true
        }
        for v in 0 ..< n { listed[v] = false }
        if colors.isEmpty {
            for v in 0 ..< n { elements[v] = v; position[v] = v; cellOf[v] = 0 }
            cellLength[0] = n
            sideCount[0] = graph.half < n ? graph.half : n
            cellCount = 1
            if n > unit { link(0, after: n) }
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
        var last = n
        for c in 0 ..< classes where starts[c + 1] > starts[c] {
            let s = starts[c], length = starts[c + 1] - s
            var side = 0
            for p in s ..< s + length where elements[p] < graph.half { side += 1 }
            cellLength[s] = length
            sideCount[s] = side
            cellCount += 1
            if length > unit {
                link(s, after: last)
                last = s
            }
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
        listSplit(c, s, end)
        trail[trailCount] = s
        trailCount += 1
        cellCount += 1
        enqueue(s)
    }

    /// Gives `u` (in a cell of length at least 2) a cell of its own at the cell's end, queued: the
    /// individualization on one graph.
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
        listSplit(c, s, s + 1)
        trail[trailCount] = s
        trailCount += 1
        cellCount += 1
        if invariant {
            mix(c)
            mix(length)
        }
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
            let merged = cellLength[previous] + length
            if merged > unit && !listed[previous] { relink(previous) }
            if listed[s] { unlink(s) }
            cellLength[previous] = merged
            sideCount[previous] += sideCount[s]
            cellCount -= 1
        }
    }

    /// Refines until no splitter is queued. Returns false, with the queue emptied, when a cell
    /// becomes unbalanced; the splits made stay on the trail for `undo(to:)`.
    func refine() -> Bool {
        let relations = graph.relations
        if diverged {
            abandonQueue()
            return false
        }
        while queueCount > 0 {
            let s = queue[queueHead]
            queueHead += 1
            if queueHead == count { queueHead = 0 }
            queueCount -= 1
            inQueue[s] = false
            let length = cellLength[s]
            if invariant {
                mix(s)
                mix(length)
            }
            // A copy: splitting may permute the splitter's own cell.
            splitter.update(from: elements + s, count: length)
            for relation in relations {
                let ok = relation.weights == nil
                    ? split(length, relation.offsets, relation.targets)
                    : split(length, relation.offsets, relation.targets, relation.weights!)
                if !ok || diverged {
                    abandonQueue()
                    return false
                }
            }
        }
        if invariant {
            mix(cellCount)
            if checking {
                // A sequence that stops early is less than one that goes on.
                if equalsFirst && eventIndex != firstReference.count { equalsFirst = false }
                if comparedToBest == 0 && eventIndex < bestReference.count { comparedToBest = -1 }
                if !equalsFirst && (!canonical || comparedToBest < 0) { diverged = true }
                if diverged { return false }
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
        if invariant && touched > 1 {
            // Position order, so that the splits do not depend on the vertex numbering.
            var region = UnsafeMutableBufferPointer(start: touchedCells, count: touched)
            region.sort()
        }
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
        if invariant {
            mix(c)
            mix(keptEnd - c)
            if marked == length { mix(Int(truncatingIfNeeded: low)) }
        }
        var keptSide = sideCount[c]
        var largest = c, largestLength = keptEnd - c
        var balanced = true
        var previous = c
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
            listSplit(previous, groupStart, end)
            previous = groupStart
            trail[trailCount] = groupStart
            trailCount += 1
            cellCount += 1
            if invariant {
                mix(groupLength)
                mix(Int(truncatingIfNeeded: key))
            }
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
