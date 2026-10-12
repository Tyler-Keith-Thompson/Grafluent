import GraphProtocols

/// A directed graph with no directed cycle, which keeps a topological order of its vertices
/// current as it changes (JGraphT's `DirectedAcyclicGraph`, petgraph's `acyclic::Acyclic`).
///
/// **A wrapper.** The graph is stored in `base`, any `MutableDirectedGraph`: `AdjacencyList`
/// (simple), `DirectedPseudograph` (parallel edges kept) or `StableDirectedGraph` (positions survive
/// removals). Every read member, index-space ones included, is the base's, with the base's own
/// types, so Traversal, Connectivity, ShortestPaths and the rest run on a DAG at the base's speed,
/// and vertex order, edge positions and parallel copies are the base's. The wrapper adds two
/// things: the rule that an edge closing a cycle is rejected, and the order.
///
/// **Rejection.** `insert(edge:)` throws `AcyclicEdgeError`, and changes nothing, when the edge
/// would close a cycle (`.cycle`) or is a self-loop (`.selfLoop`). The path that the edge u→v would
/// close is `bidirectionalShortestPath(from: v, to: u)` (Traversal), searched only when it is
/// asked for.
///
/// **The order.** `topologicalOrder` lists every vertex so that each edge goes from an earlier
/// vertex to a later one, and `topologicalPosition(of:)` gives a vertex's place. Bulk construction
/// orders by Kahn's algorithm. A vertex inserted alone is placed last; a new endpoint of an
/// inserted edge is placed first when it is the source and the target is already a vertex, and
/// last otherwise, so that the edge goes forward. Each later edge insertion maintains the order by
/// the dynamic topological sort of Pearce and Kelly:
///
/// > David J. Pearce and Paul H. J. Kelly. A Dynamic Topological Sort Algorithm for Directed
/// > Acyclic Graphs. *ACM Journal of Experimental Algorithmics* 11, article 1.7 (2006).
/// > doi:10.1145/1187436.1210590
///
/// An edge u→v with u already placed before v costs two array reads plus the base's insertion.
/// Otherwise a depth-first search forward from v visits only the vertices placed before u, and if
/// it meets u the edge is rejected. If not, a search backward from u visits only the vertices
/// placed after v, and the two visited sets, the backward one first, each in its old order, take
/// the places they held, sorted. No other vertex moves. That costs O(‖δ‖ + δ log δ): δ is the
/// number of vertices the two searches visit, ‖δ‖ the out-edges of the forward set plus the
/// in-edges of the backward set, all of which the searches read, and δ log δ the sorts (an
/// insertion sort up to 24). Both sets are defined by reachability and the old order, not by row
/// order, so the order after a sequence of operations depends only on that sequence. The
/// searches' scratch is kept in the value and reused, so an insertion allocates only while the
/// scratch grows.
///
/// **Slots.** The order is stored as an array of slots, and each vertex's label is its slot, so
/// Pearce–Kelly writes a moved vertex straight to its slot. Free slots before the first vertex
/// take the vertices placed first, and the array grows at the front by its own length when they
/// run out (amortized O(1)). Removing a vertex leaves a hole in its slot, O(1); holes at either
/// end are trimmed, and the slots are compacted once the holes outnumber the vertices (or the free
/// front slots exceed twice their number, plus 16), O(n) once per as many removals, so removal is
/// amortized O(1) for the order plus O(log n) for the count of holes below. While there is no
/// hole, `topologicalPosition(of:)` and the order's subscript are O(1); with holes, a Fenwick tree
/// over the slots counts the holes before a slot in O(log n), and finds the slot of a place in
/// O(log n). Pearce–Kelly reads labels only, so holes do not slow insertion. On a base that fills
/// a hole by moving its last vertex in, the moved vertex keeps its place.
///
/// **Equality** is the base's: the order is history and does not count.
@frozen
public struct DirectedAcyclicGraph<Base: MutableDirectedGraph> {
    /// The graph.
    @usableFromInline
    internal var _base: Base

    /// The keys (`Base`'s vertex keys) in topological order, by slot.
    @usableFromInline
    internal var _order: _TopologicalSlots

    /// Each key's label (its slot in `_order`) and the searches' visit marks, paged by key.
    @usableFromInline
    internal var _table: _KeyTable

    /// Scratch for Pearce–Kelly, kept between insertions: the search stack.
    @usableFromInline
    internal var _stack: ContiguousArray<Int>

    /// Scratch: the forward set, as (label, key).
    @usableFromInline
    internal var _forward: ContiguousArray<_Placed>

    /// Scratch: the backward set, as (label, key).
    @usableFromInline
    internal var _backward: ContiguousArray<_Placed>

    /// Scratch: the pooled labels of both sets, in increasing order.
    @usableFromInline
    internal var _labels: ContiguousArray<Int>

    /// The visit mark of the current forward search; the backward search uses `_stamp + 1`.
    @usableFromInline
    internal var _stamp: Int

    /// A graph whose order is `order`, every key at the slot of its place, as `table` labels them.
    @inlinable
    internal init(_base base: Base, order: ContiguousArray<Int>, table: _KeyTable) {
        _base = base
        _order = _TopologicalSlots(keys: order)
        _table = table
        _stack = []
        _forward = []
        _backward = []
        _labels = []
        _stamp = 2
    }

    /// The empty graph. O(1).
    @inlinable
    public init() {
        self.init(_base: Base(), order: [], table: _KeyTable())
    }
}

extension DirectedAcyclicGraph {
    /// The graph without the order: read-only, so the invariant holds. O(1).
    @inlinable
    public var base: Base { _base }
}

extension DirectedAcyclicGraph {
    /// The place of the vertex with key `key` in the order.
    @inlinable
    @inline(__always)
    internal func _position(ofKey key: Int) -> Int { _order.place(ofSlot: _table.label(key)) }

    /// The keys by place and each key's place: the slots and labels themselves while there is no
    /// hole, otherwise a compacted copy, O(n).
    @inlinable
    internal func _places() -> _Places {
        if _order.holes == 0 { return _Places(keys: _order.slots, start: _order.first, table: _table) }
        var keys = ContiguousArray<Int>()
        keys.reserveCapacity(_order.count)
        var table = _KeyTable()
        for key in _order.slots[_order.first...] where key >= 0 {
            keys.append(key)
        }
        // The keys are the base's vertex indices, in increasing order, so the page table grows
        // only at its end.
        for key in _base.vertices.indices { table.insert(key, label: 0) }
        for (place, key) in keys.enumerated() { table.setLabel(key, place) }
        return _Places(keys: keys, start: 0, table: table)
    }

    /// Moves every key down to the slot of its place, dropping the holes and the free front slots,
    /// and relabels. O(n).
    @inlinable
    internal mutating func _compact() {
        var write = 0
        var read = _order.first
        while read < _order.slots.count {
            let key = _order.slots[read]
            if key >= 0 {
                _order.slots[write] = key
                _table.setLabel(key, write)
                write &+= 1
            }
            read &+= 1
        }
        _order.slots.removeLast(_order.slots.count &- write)
        _order.first = 0
        _order.holes = 0
        _order.rank = []
    }

    /// Doubles the slots at the front, by at least 16, for vertices placed first; relabels. O(n).
    @inlinable
    @inline(never)
    internal mutating func _growFront() {
        let extra = Swift.max(_order.slots.count, 16)
        var grown = ContiguousArray<Int>()
        grown.reserveCapacity(extra &+ _order.slots.count)
        grown.append(contentsOf: repeatElement(-1, count: extra))
        grown.append(contentsOf: _order.slots)
        var slot = _order.first
        while slot < _order.slots.count {
            let key = _order.slots[slot]
            if key >= 0 { _table.setLabel(key, slot &+ extra) }
            slot &+= 1
        }
        _order.slots = grown
        _order.first &+= extra
        if _order.holes > 0 { _order.buildRank() } else { _order.rank = [] }
    }

    /// The keys in topological order, as one buffer: the slots themselves while there is no hole,
    /// otherwise a compacted copy. For ShortestPaths' `dagShortestPaths`, which relaxes in this
    /// order.
    @inlinable
    package func _withKeysInTopologicalOrder<Result>(_ body: (UnsafeBufferPointer<Int>) -> Result) -> Result {
        let places = _places()
        return places.keys.withUnsafeBufferPointer { body(UnsafeBufferPointer(rebasing: $0[places.start...])) }
    }
}

/// The order's slots: keys in topological order, -1 at a hole (a removed vertex's slot) and at
/// each free slot before `first`.
@frozen
@usableFromInline
internal struct _TopologicalSlots {
    /// The keys, by slot.
    @usableFromInline var slots: ContiguousArray<Int>
    /// The first slot that may hold a key; the slots before it are free.
    @usableFromInline var first: Int
    /// The holes among `first..<slots.count`.
    @usableFromInline var holes: Int
    /// A Fenwick tree over slots counting holes: entry `j - 1` holds the holes among slots
    /// `j - (j & -j) ..< j`. Empty until the first hole; from then on at least `slots.count`
    /// entries, marking every hole and nothing else.
    @usableFromInline var rank: ContiguousArray<Int>

    @inlinable
    init(keys: ContiguousArray<Int>) {
        slots = keys
        first = 0
        holes = 0
        rank = []
    }

    /// The number of keys.
    @inlinable
    var count: Int { slots.count &- first &- holes }

    /// The place of the key in `slot`: O(1) without holes, else O(log n).
    @inlinable
    @inline(__always)
    func place(ofSlot slot: Int) -> Int {
        holes == 0 ? slot &- first : slot &- first &- holesBefore(slot)
    }

    /// The holes among the slots before `slot`.
    @inlinable
    func holesBefore(_ slot: Int) -> Int {
        var j = Swift.min(slot, rank.count), sum = 0
        while j > 0 {
            sum &+= rank[j &- 1]
            j &= j &- 1
        }
        return sum
    }

    /// The slot of the key at `place`: O(1) without holes, else O(log n), by descending the tree
    /// for the slot after which `first + place` slots are not holes (the free front slots are not
    /// holes).
    @inlinable
    func slot(atPlace place: Int) -> Int {
        if holes == 0 { return first &+ place }
        var remaining = first &+ place &+ 1
        var position = 0
        var step = 1 &<< (Int.bitWidth &- 1 &- rank.count.leadingZeroBitCount)
        while step > 0 {
            let next = position &+ step
            if next <= rank.count {
                let open = step &- rank[next &- 1]
                if open < remaining {
                    position = next
                    remaining &-= open
                }
            }
            step &>>= 1
        }
        return position &+ remaining &- 1
    }

    /// Adds `delta` to the hole count of `slot`.
    @inlinable
    mutating func addHoles(_ delta: Int, at slot: Int) {
        var j = slot &+ 1
        while j <= rank.count {
            rank[j &- 1] &+= delta
            j &+= j & (0 &- j)
        }
    }

    /// Builds the tree over twice the slots (at least 64), in O(slots).
    @inlinable
    mutating func buildRank() {
        let size = Swift.max(slots.count &* 2, 64)
        rank = ContiguousArray(repeating: 0, count: size)
        var slot = first
        while slot < slots.count {
            if slots[slot] < 0 { rank[slot] = 1 }
            slot &+= 1
        }
        var j = 1
        while j <= size {
            let parent = j &+ (j & (0 &- j))
            if parent <= size { rank[parent &- 1] &+= rank[j &- 1] }
            j &+= 1
        }
    }

    /// Empties `slot`: trims it, and the holes it uncovers, at either end; otherwise leaves a hole.
    @inlinable
    mutating func remove(at slot: Int) {
        if slot == slots.count &- 1 {
            slots.removeLast()
            while slots.count > first, slots[slots.count &- 1] < 0 {
                addHoles(-1, at: slots.count &- 1)
                holes &-= 1
                slots.removeLast()
            }
        } else if slot == first {
            slots[slot] = -1
            first &+= 1
            while slots[first] < 0 {
                addHoles(-1, at: first)
                holes &-= 1
                first &+= 1
            }
        } else {
            slots[slot] = -1
            holes &+= 1
            if slot < rank.count { addHoles(1, at: slot) } else { buildRank() }
        }
        if first == slots.count {
            slots.removeAll(keepingCapacity: true)
            first = 0
        }
    }

    @inlinable
    mutating func removeAll(keepingCapacity: Bool) {
        slots.removeAll(keepingCapacity: keepingCapacity)
        first = 0
        holes = 0
        rank = []
    }
}

/// The keys by place, and each key's place.
@frozen
@usableFromInline
internal struct _Places {
    /// The keys: place `p` is `keys[start + p]`.
    @usableFromInline let keys: ContiguousArray<Int>
    @usableFromInline let start: Int
    /// Each key's label: its place plus `start`.
    @usableFromInline let table: _KeyTable

    @inlinable
    init(keys: ContiguousArray<Int>, start: Int, table: _KeyTable) {
        self.keys = keys
        self.start = start
        self.table = table
    }

    @inlinable
    @inline(__always)
    func key(atPlace place: Int) -> Int { keys[start &+ place] }

    @inlinable
    @inline(__always)
    func place(ofKey key: Int) -> Int { table.label(key) &- start }
}

/// A key with its label.
@frozen
@usableFromInline
internal struct _Placed {
    @usableFromInline var label: Int
    @usableFromInline var key: Int

    @inlinable
    init(label: Int, key: Int) {
        self.label = label
        self.key = key
    }
}

/// A map from vertex keys to labels (or, in a table used as a map, any `Int`) and visit marks,
/// paged as `_PositionNumbers` is: a page table from page `firstPage` on, indexed by
/// `(key >> _PositionPage.shift) - firstPage`, each entry the offset of the page's block in
/// `labels` and `marks` or -1, so a lookup is two array reads. The marks are a parallel array, so
/// the labels the fast path reads are 8 bytes a key. A block is freed, for reuse, once its last key
/// is removed, and freed entries at the front of the page table are dropped once they are half of
/// it (amortized O(1)). So on a `StableDirectedGraph`, whose keys are positions that are never
/// reused, memory follows the live vertices plus one word per 1024 positions from the first live
/// one, as the base's own page table does (the law in `MutableDirectedGraph`).
@frozen
@usableFromInline
internal struct _KeyTable {
    /// The page number of `pages[0]`.
    @usableFromInline var firstPage: Int
    @usableFromInline var pages: ContiguousArray<Int>
    /// How many entries at the front of `pages` are -1.
    @usableFromInline var front: Int
    @usableFromInline var labels: ContiguousArray<Int>
    /// The mark of the last search that visited each key, parallel to `labels`.
    @usableFromInline var marks: ContiguousArray<Int>
    /// Live keys in each block, by block.
    @usableFromInline var live: ContiguousArray<Int>
    /// Freed blocks.
    @usableFromInline var free: ContiguousArray<Int>
    /// Whether every page's block is the page itself, from page 0: then a key's entry is at the
    /// key, one array read. True for keys inserted from 0 up with no page freed for another's
    /// use, as on a dense base, or a stable base before it frees a page.
    @usableFromInline var flat: Bool

    @inlinable
    init() {
        firstPage = 0
        pages = []
        front = 0
        labels = []
        marks = []
        live = []
        free = []
        flat = true
    }

    /// The offset of `key`'s entry. The key must have been inserted.
    @inlinable
    @inline(__always)
    func slot(_ key: Int) -> Int {
        if flat { return key }
        return pages[(key &>> _PositionPage.shift) &- firstPage] &<< _PositionPage.shift | (key & _PositionPage.mask)
    }

    @inlinable
    @inline(__always)
    func label(_ key: Int) -> Int { labels[slot(key)] }

    @inlinable
    @inline(__always)
    mutating func setLabel(_ key: Int, _ label: Int) { labels[slot(key)] = label }

    /// Adds `key` with `label`. The key is at least every live key: a new vertex's key is
    /// `vertices.endIndex` (`MutableDirectedGraph`), and a table built from a graph takes its keys
    /// in increasing order. So its page is never before `firstPage`, nor before `front`.
    @inlinable
    mutating func insert(_ key: Int, label: Int) {
        let page = key &>> _PositionPage.shift
        if pages.isEmpty {
            firstPage = page
            front = 0
        }
        let k = page &- firstPage
        if k >= pages.count {
            pages.append(contentsOf: repeatElement(-1, count: k &- pages.count &+ 1))
        }
        var block = pages[k]
        if block < 0 {
            if let reused = free.popLast() {
                block = reused
            } else {
                block = live.count
                live.append(0)
                labels.append(contentsOf: repeatElement(0, count: _PositionPage.size))
                marks.append(contentsOf: repeatElement(0, count: _PositionPage.size))
            }
            pages[k] = block
            if block != page || firstPage != 0 { flat = false }
        }
        live[block] &+= 1
        let slot = block &<< _PositionPage.shift | (key & _PositionPage.mask)
        labels[slot] = label
        marks[slot] = 0
    }

    /// Removes `key`, freeing its block when it was the block's last, and dropping the freed
    /// entries at the front of the page table once they are half of it.
    @inlinable
    mutating func remove(_ key: Int) {
        let k = (key &>> _PositionPage.shift) &- firstPage
        let block = pages[k]
        live[block] &-= 1
        guard live[block] == 0 else { return }
        pages[k] = -1
        free.append(block)
        guard k == front else { return }
        while front < pages.count, pages[front] < 0 { front &+= 1 }
        if front == pages.count {
            pages.removeAll(keepingCapacity: true)
            front = 0
        } else if front &* 2 >= pages.count {
            pages.removeFirst(front)
            firstPage &+= front
            front = 0
            flat = false
        }
    }

    @inlinable
    mutating func removeAll(keepingCapacity: Bool) {
        firstPage = 0
        pages.removeAll(keepingCapacity: keepingCapacity)
        front = 0
        labels.removeAll(keepingCapacity: keepingCapacity)
        marks.removeAll(keepingCapacity: keepingCapacity)
        live.removeAll(keepingCapacity: keepingCapacity)
        free.removeAll(keepingCapacity: keepingCapacity)
        flat = true
    }
}

extension _Placed: Sendable {}
extension _KeyTable: Sendable {}
extension _TopologicalSlots: Sendable {}
extension _Places: Sendable {}
extension DirectedAcyclicGraph: Sendable where Base: Sendable {}
