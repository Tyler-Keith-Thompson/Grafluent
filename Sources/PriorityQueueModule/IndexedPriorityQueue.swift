/// A min-priority queue of the indices `0..<indexBound`, each queued at most once with a
/// priority: a 4-ary heap with a position array (Boost's `d_ary_heap_indirect`, LEMON's
/// `QuadHeap`, Sedgewick's `IndexMinPQ`). `insert`, `popMin()`, `decreasePriority(of:to:)`,
/// `updatePriority(of:to:)` and `remove(_:)` are O(log count); `min`, `contains(_:)` and
/// `priority(of:)` are O(1).
///
/// Indices with equal priorities leave in an unspecified order. `min` changes only when a
/// strictly smaller priority arrives, or when the minimum leaves or its priority increases. To
/// break ties a particular way, put the rule in `Priority`, for example `(distance, index)`.
///
/// Priorities must not be NaN. Not a `Sequence`, as swift-collections' `Heap` is not:
/// `unordered` lists the contents. Storage is two arrays, copied on write.
///
/// Use it when items are dense indices whose priorities must be lowered in place (Dijkstra, Prim,
/// A*). `Heap` has no way to find or change a queued element, so it can only stand in by pushing
/// duplicates and skipping stale ones: in Dijkstra that costs 1.1–1.4× (the gap narrows as graphs
/// grow, and with few distinct weights), and about 2.6× when every item is decreased once. For pushes and pops alone, `Heap` is the
/// better structure: it stores bare elements, and sorts 10⁶ `Int`s in about 0.7× the time.
///
/// An index that has left the queue is indistinguishable from one never queued. Dijkstra needs
/// nothing more, since a settled vertex is never relaxed again; Prim must keep its own set of tree
/// vertices, or `insertOrDecreasePriority(of:to:)` would queue them again.
@frozen
public struct IndexedPriorityQueue<Priority: Comparable> {
    public typealias Element = (index: Int, priority: Priority)

    /// The queued pairs in heap order: each slot's priority is at most its children's, the
    /// children of slot `h` being `4h + 1 ... 4h + 4`.
    @usableFromInline var _heap: [Element]

    /// For each index, its slot in `_heap`, or -1 when it is not queued.
    @usableFromInline var _slots: [Int]

    /// An empty queue for the indices `0..<indexBound`. O(indexBound).
    ///
    /// - Precondition: `indexBound >= 0`.
    @inlinable
    public init(indexBound: Int) {
        precondition(indexBound >= 0, "An index bound cannot be negative")
        _heap = []
        _slots = [Int](repeating: -1, count: indexBound)
    }

    /// The indices the queue can hold are `0..<indexBound`.
    @inlinable
    public var indexBound: Int { _slots.count }

    /// The number of queued indices.
    @inlinable
    public var count: Int { _heap.count }

    /// Whether no index is queued.
    @inlinable
    public var isEmpty: Bool { _heap.isEmpty }

    /// The queued pairs, in an unspecified order. O(1).
    @inlinable
    public var unordered: [Element] { _heap }

    /// Reserves room for `minimumCapacity` queued indices.
    ///
    /// - Precondition: `minimumCapacity >= 0`.
    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "A capacity cannot be negative")
        _heap.reserveCapacity(minimumCapacity)
    }

    @inlinable
    @inline(__always)
    func _check(_ index: Int) {
        precondition(UInt(bitPattern: index) < UInt(bitPattern: _slots.count), "Index out of range 0..<indexBound")
    }

    @inlinable
    @inline(__always)
    func _checkPriority(_ priority: Priority) {
        // Only NaN is unequal to itself, among the standard library's types; a `Priority` whose
        // `==` is not reflexive traps here too.
        precondition(priority == priority, "A priority cannot be NaN")
    }

    /// Whether `index` is queued.
    ///
    /// - Precondition: `index` is in `0..<indexBound`.
    @inlinable
    public func contains(_ index: Int) -> Bool {
        _check(index)
        return _slots[index] >= 0
    }

    /// `index`'s priority, or `nil` if it is not queued.
    ///
    /// - Precondition: `index` is in `0..<indexBound`.
    @inlinable
    public func priority(of index: Int) -> Priority? {
        _check(index)
        let slot = _slots[index]
        return slot < 0 ? nil : _heap[slot].priority
    }

    /// The pair with the lowest priority, or `nil` when the queue is empty. O(1).
    @inlinable
    public var min: Element? { _heap.first }

    /// Queues `index` with `priority`. O(log count).
    ///
    /// - Precondition: `index` is in `0..<indexBound` and not queued; `priority` is not NaN.
    @inlinable
    public mutating func insert(_ index: Int, priority: Priority) {
        _check(index)
        _checkPriority(priority)
        _heap.append((index, priority))
        _withBuffers { heap, slots in
            precondition(slots[index] < 0, "The index is already queued")
            Self._siftUp(heap, slots, heap.count &- 1, (index, priority))
        }
    }

    /// Removes and returns the pair with the lowest priority, or `nil` when the queue is empty.
    /// O(log count).
    @inlinable
    public mutating func popMin() -> Element? {
        guard let last = _heap.popLast() else { return nil }
        return _withBuffers { heap, slots in
            slots[last.index] = -1
            guard !heap.isEmpty else { return last }
            let top = heap[0]
            slots[top.index] = -1
            Self._siftDown(heap, slots, 0, last)
            return top
        }
    }

    /// Removes and returns the pair with the lowest priority. O(log count).
    ///
    /// - Precondition: the queue is not empty.
    @inlinable
    @discardableResult
    public mutating func removeMin() -> Element {
        guard let top = popMin() else { preconditionFailure("removeMin() on an empty queue") }
        return top
    }

    /// Lowers the priority of a queued index to `priority`; an equal priority changes nothing.
    /// O(log count).
    ///
    /// - Precondition: `index` is queued, `priority` is at most its priority, and not NaN.
    @inlinable
    public mutating func decreasePriority(of index: Int, to priority: Priority) {
        _check(index)
        _checkPriority(priority)
        _withBuffers { heap, slots in
            let slot = slots[index]
            precondition(slot >= 0, "The index is not queued")
            precondition(!(heap[slot].priority < priority), "decreasePriority(of:to:) cannot raise a priority; use updatePriority(of:to:)")
            Self._siftUp(heap, slots, slot, (index, priority))
        }
    }

    /// Queues `index` with `priority`, or lowers its priority to `priority` if it is queued with
    /// a larger one; otherwise changes nothing. Returns whether the queue changed. O(log count).
    /// One call for a relaxation step (Boost's `push_or_update`, LEMON's `set` restricted to
    /// decreases).
    ///
    /// - Precondition: `index` is in `0..<indexBound`; `priority` is not NaN.
    @inlinable
    @discardableResult
    public mutating func insertOrDecreasePriority(of index: Int, to priority: Priority) -> Bool {
        _check(index)
        _checkPriority(priority)
        if _slots[index] < 0 {
            _heap.append((index, priority))
            _withBuffers { heap, slots in Self._siftUp(heap, slots, heap.count &- 1, (index, priority)) }
            return true
        }
        return _withBuffers { heap, slots in
            let slot = slots[index]
            guard priority < heap[slot].priority else { return false }
            Self._siftUp(heap, slots, slot, (index, priority))
            return true
        }
    }

    /// Sets the priority of a queued index, up or down, and returns the old one. O(log count).
    /// (Unlike Boost's `update`, which only decreases.)
    ///
    /// - Precondition: `index` is queued; `priority` is not NaN.
    @inlinable
    @discardableResult
    public mutating func updatePriority(of index: Int, to priority: Priority) -> Priority {
        _check(index)
        _checkPriority(priority)
        return _withBuffers { heap, slots in
            let slot = slots[index]
            precondition(slot >= 0, "The index is not queued")
            let old = heap[slot].priority
            if priority < old {
                Self._siftUp(heap, slots, slot, (index, priority))
            } else {
                Self._siftDown(heap, slots, slot, (index, priority))
            }
            return old
        }
    }

    /// Dequeues `index` and returns its priority, or `nil` if it was not queued. O(log count).
    ///
    /// - Precondition: `index` is in `0..<indexBound`.
    @inlinable
    @discardableResult
    public mutating func remove(_ index: Int) -> Priority? {
        _check(index)
        let slot = _slots[index]
        guard slot >= 0 else { return nil }
        let last = _heap.removeLast()
        return _withBuffers { heap, slots in
            slots[index] = -1
            guard slot < heap.count else { return last.priority }
            let old = heap[slot].priority
            // The last pair fills the hole, and moves whichever way it must.
            if last.priority < old {
                Self._siftUp(heap, slots, slot, last)
            } else {
                Self._siftDown(heap, slots, slot, last)
            }
            return old
        }
    }

    /// Dequeues every index, O(count). The result behaves as a fresh queue with the same bound;
    /// only the reserved capacity may differ.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        for entry in _heap { _slots[entry.index] = -1 }
        _heap.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Calls `body` with both arrays' buffers: one uniqueness check each per operation, and no
    /// bounds checks inside.
    @inlinable
    @inline(__always)
    mutating func _withBuffers<Result>(_ body: (UnsafeMutableBufferPointer<Element>, UnsafeMutableBufferPointer<Int>) -> Result) -> Result {
        _heap.withUnsafeMutableBufferPointer { heap in
            _slots.withUnsafeMutableBufferPointer { slots in body(heap, slots) }
        }
    }

    /// Moves `entry` up from `hole` to where its parent's priority is not larger.
    @inlinable
    @inline(__always)
    static func _siftUp(_ heap: UnsafeMutableBufferPointer<Element>, _ slots: UnsafeMutableBufferPointer<Int>, _ hole: Int, _ entry: Element) {
        var h = hole
        while h > 0 {
            let parent = (h &- 1) >> 2
            let above = heap[parent]
            guard entry.priority < above.priority else { break }
            heap[h] = above
            slots[above.index] = h
            h = parent
        }
        heap[h] = entry
        slots[entry.index] = h
    }

    /// Moves `entry` down from `hole` to where no child's priority is smaller.
    @inlinable
    @inline(__always)
    static func _siftDown(_ heap: UnsafeMutableBufferPointer<Element>, _ slots: UnsafeMutableBufferPointer<Int>, _ hole: Int, _ entry: Element) {
        let n = heap.count
        var h = hole
        while true {
            let first = h &* 4 &+ 1
            if first >= n { break }
            var best = first
            var smallest = heap[first]
            var c = first &+ 1
            let end = Swift.min(first &+ 4, n)
            while c < end {
                let child = heap[c]
                if child.priority < smallest.priority {
                    best = c
                    smallest = child
                }
                c &+= 1
            }
            guard smallest.priority < entry.priority else { break }
            heap[h] = smallest
            slots[smallest.index] = h
            h = best
        }
        heap[h] = entry
        slots[entry.index] = h
    }
}

extension IndexedPriorityQueue: Sendable where Priority: Sendable {}

extension IndexedPriorityQueue: CustomStringConvertible, CustomDebugStringConvertible {
    /// The queued pairs by priority, then index, at most 16: `[4: 0.5, 1: 2.0, 7: 2.0]`. Equal
    /// contents print alike, however they were reached. O(count log count), since it sorts.
    public var description: String {
        let sorted = _heap.sorted { $0.priority < $1.priority || (!($1.priority < $0.priority) && $0.index < $1.index) }
        var parts = sorted.prefix(16).map { "\($0.index): \($0.priority)" }
        if sorted.count > 16 { parts.append("…") }
        return "[" + parts.joined(separator: ", ") + "]"
    }

    /// The type, the bound, and the pairs as `description` lists them.
    public var debugDescription: String {
        "IndexedPriorityQueue<\(Priority.self)>(indexBound: \(indexBound), \(description))"
    }
}
