import GraphProtocols
import PriorityQueueModule

/// The shortest-path DAG from one source at a time, for the measures built on Brandes' searches
/// (load, percolation and group betweenness): the reached vertices in non-decreasing distance
/// (`order[0 ..< reached]`, the source first), each one's number of shortest paths (`sigma`, a path
/// being a sequence of slots, so parallel copies are distinct) and of DAG in-slots (`parents`), and
/// a test for whether slot v → w is a DAG step. Breadth-first without weights; with them, Dijkstra's
/// search where path lengths tie only when their sums are exactly equal and a step v → w is on the
/// DAG only when w settled after v, as `_betweenness` does.
@frozen
@usableFromInline
struct _ShortestPathDAG<W: Comparable & AdditiveArithmetic> {
    @usableFromInline let rows: _CompressedRows
    /// The weight of each slot, or nil for breadth-first search.
    @usableFromInline let weights: [W]?
    @usableFromInline var hops: [Int]
    @usableFromInline var distance: [W]
    /// Weighted: below `base` unreached, `base` in the heap, `base + 1 + r` settled r-th.
    @usableFromInline var stamp: [Int]
    @usableFromInline var base = 0
    @usableFromInline var sigma: [Double]
    @usableFromInline var parents: [Int]
    @usableFromInline var order: [Int]
    @usableFromInline var reached = 0
    @usableFromInline var heap: IndexedPriorityQueue<W>

    @inlinable
    init(_ rows: _CompressedRows, slotWeights: [W]?) {
        self.rows = rows
        weights = slotWeights
        let n = rows.count
        hops = [Int](repeating: -1, count: n)
        distance = [W](repeating: .zero, count: slotWeights == nil ? 0 : n)
        stamp = [Int](repeating: 0, count: n)
        sigma = [Double](repeating: 0, count: n)
        parents = [Int](repeating: 0, count: n)
        order = [Int](repeating: 0, count: n)
        heap = IndexedPriorityQueue(indexBound: slotWeights == nil ? 0 : n)
    }

    @inlinable
    var count: Int { rows.count }

    /// Runs the search from `s`.
    @inlinable
    mutating func search(from s: Int) {
        let n = rows.count
        for k in 0 ..< reached { hops[order[k]] = -1 }
        guard let weights else {
            hops[s] = 0
            sigma[s] = 1
            parents[s] = 0
            order[0] = s
            var head = 0, tail = 1
            while head < tail {
                let v = order[head]
                head += 1
                let next = hops[v] + 1, sv = sigma[v]
                for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                    let w = rows.targets[slot]
                    if hops[w] < 0 {
                        hops[w] = next
                        sigma[w] = 0
                        parents[w] = 0
                        order[tail] = w
                        tail += 1
                    }
                    if hops[w] == next {
                        sigma[w] += sv
                        parents[w] += 1
                    }
                }
            }
            reached = tail
            return
        }
        base += n + 1
        let base = self.base
        distance[s] = .zero
        stamp[s] = base
        hops[s] = 0
        sigma[s] = 1
        parents[s] = 0
        heap.insert(s, priority: .zero)
        var settled = 0
        while let (v, d) = heap.popMin() {
            order[settled] = v
            settled += 1
            stamp[v] = base + settled
            let sv = sigma[v]
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                let mark = stamp[w]
                if mark > base { continue }
                let candidate = d + weights[slot]
                if mark < base {
                    stamp[w] = base
                    hops[w] = 0
                    distance[w] = candidate
                    sigma[w] = sv
                    parents[w] = 1
                    heap.insert(w, priority: candidate)
                } else if candidate < distance[w] {
                    distance[w] = candidate
                    sigma[w] = sv
                    parents[w] = 1
                    heap.decreasePriority(of: w, to: candidate)
                } else if candidate == distance[w] {
                    sigma[w] += sv
                    parents[w] += 1
                }
            }
        }
        reached = settled
    }

    /// Whether `slot`, from `v` (reached), is a step of the DAG.
    @inlinable
    func isStep(from v: Int, _ slot: Int) -> Bool {
        let w = rows.targets[slot]
        guard let weights else { return hops[w] == hops[v] + 1 }
        return stamp[w] > stamp[v] && stamp[w] > base && distance[w] == distance[v] + weights[slot]
    }

    /// Whether `v` was reached by the last search.
    @inlinable
    func isReached(_ v: Int) -> Bool { weights == nil ? hops[v] >= 0 : stamp[v] > base }
}

extension _ShortestPathDAG where W == Int {
    /// Breadth-first searches.
    @inlinable
    init(_ rows: _CompressedRows) {
        self.init(rows, slotWeights: nil)
    }
}
