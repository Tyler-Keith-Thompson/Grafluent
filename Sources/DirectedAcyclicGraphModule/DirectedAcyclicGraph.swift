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
/// **Rejection.** `insert(edge:)` returns `nil`, and changes nothing, when the edge would close a
/// cycle; a self-loop is one. The path that the edge u→v would close is
/// `bidirectionalShortestPath(from: v, to: u)` (Traversal), searched only when it is asked for.
///
/// **The order.** `topologicalOrder` lists every vertex so that each edge goes from an earlier
/// vertex to a later one, and `topologicalPosition(of:)` gives a vertex's place in O(1). Bulk
/// construction orders by Kahn's algorithm. Each later insertion maintains the order by the
/// dynamic topological sort of Pearce and Kelly:
///
/// > David J. Pearce and Paul H. J. Kelly. A Dynamic Topological Sort Algorithm for Directed
/// > Acyclic Graphs. *ACM Journal of Experimental Algorithmics* 11, article 1.7 (2006).
/// > doi:10.1145/1187436.1210590
///
/// An edge u→v with u already placed before v costs two array reads plus the base's insertion.
/// Otherwise a depth-first search forward from v visits only the vertices placed before u, and if
/// it meets u the edge is rejected. If not, a search backward from u visits only the vertices
/// placed after v, and the two visited sets, the backward one first, each in its old order, take
/// the places they held, sorted. No other vertex moves. That costs O(‖δ‖ + δ log δ), where δ is
/// the number of vertices the two searches visit and ‖δ‖ adds their edges. Both sets are defined
/// by reachability and the old order, not by row order, so the order after a sequence of
/// operations depends only on that sequence. The searches' scratch is kept in the value and
/// reused, so an insertion allocates only while the scratch grows.
///
/// **Labels.** Each vertex carries an integer label, increasing along the order, which is its
/// place while no vertex has been removed. Removals cannot create a cycle, so they keep the order:
/// removing a vertex closes its gap in the order with one `Array.remove(at:)` (a memmove,
/// O(n − place)) and leaves the other labels alone, so labels after it are one more than their
/// places until the labels are renumbered, once as many vertices have been removed as remain
/// (amortized O(1) per removal). `topologicalPosition(of:)` reads the label and is O(1) where the
/// label is the place, and a binary search over the order, O(log n), behind a removed vertex.
/// On a base that fills a hole by moving its last vertex in, the moved vertex keeps its place.
///
/// **Equality** is the base's: the order is history and does not count.
@frozen
public struct DirectedAcyclicGraph<Base: MutableDirectedGraph> {
    /// The graph.
    @usableFromInline
    internal var _base: Base

    /// The keys (`Base`'s vertex keys) in topological order.
    @usableFromInline
    internal var _order: ContiguousArray<Int>

    /// Each key's label, increasing along `_order`, and the searches' visit marks, paged by key.
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

    /// Scratch: the places in `_order` of the pooled labels.
    @usableFromInline
    internal var _places: ContiguousArray<Int>

    /// The label of the next vertex appended to the order: one more than the last label, and
    /// equal to `_order.count` exactly while every label is its place.
    @usableFromInline
    internal var _nextLabel: Int

    /// The visit mark of the current forward search; the backward search uses `_stamp + 1`.
    @usableFromInline
    internal var _stamp: Int

    @inlinable
    internal init(_base base: Base, order: ContiguousArray<Int>, table: _KeyTable) {
        _base = base
        _order = order
        _table = table
        _stack = []
        _forward = []
        _backward = []
        _labels = []
        _places = []
        _nextLabel = order.count
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
    internal func _position(ofKey key: Int) -> Int { _table.position(of: key, in: _order) }

    /// A table from keys to places: `_table` itself while every label is its place, otherwise a
    /// fresh one, O(n).
    @inlinable
    internal func _placeTable() -> _KeyTable {
        if _nextLabel == _order.count { return _table }
        var places = _KeyTable()
        for (place, key) in _order.enumerated() { places.insert(key, label: place) }
        return places
    }

    /// Renumbers the labels to the places. O(n).
    @inlinable
    internal mutating func _renumber() {
        for (place, key) in _order.enumerated() { _table.setLabel(key, place) }
        _nextLabel = _order.count
    }
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
/// paged as `_PositionNumbers` is: a page table indexed by `key >> _PositionPage.shift`, each entry
/// the offset of the page's block in `labels` and `marks` or -1, so a lookup is two array reads.
/// The marks are a parallel array, so the labels the fast path reads are 8 bytes a key. A block is freed, for reuse, once its last key is removed, so on a
/// `StableDirectedGraph`, whose keys are positions that are never reused, memory follows the live
/// vertices plus one table word per 1024 positions handed out.
@frozen
@usableFromInline
internal struct _KeyTable {
    @usableFromInline var pages: ContiguousArray<Int>
    @usableFromInline var labels: ContiguousArray<Int>
    /// The mark of the last search that visited each key, parallel to `labels`.
    @usableFromInline var marks: ContiguousArray<Int>
    /// Live keys in each block, by block.
    @usableFromInline var live: ContiguousArray<Int>
    /// Freed blocks.
    @usableFromInline var free: ContiguousArray<Int>

    @inlinable
    init() {
        pages = []
        labels = []
        marks = []
        live = []
        free = []
    }

    /// The offset of `key`'s entry. The key must have been inserted.
    @inlinable
    @inline(__always)
    func slot(_ key: Int) -> Int {
        pages[key &>> _PositionPage.shift] &<< _PositionPage.shift | (key & _PositionPage.mask)
    }

    @inlinable
    @inline(__always)
    func label(_ key: Int) -> Int { labels[slot(key)] }

    @inlinable
    @inline(__always)
    mutating func setLabel(_ key: Int, _ label: Int) { labels[slot(key)] = label }

    /// The place in `order` of `key`, whose labels increase along `order`: O(1) when the label is
    /// the place (no vertex before it removed since the last renumbering), else a binary search.
    @inlinable
    func position(of key: Int, in order: ContiguousArray<Int>) -> Int {
        position(ofLabel: label(key), key: key, in: order)
    }

    /// The place in `order` of the key `key` with label `label`.
    @inlinable
    func position(ofLabel label: Int, key: Int, in order: ContiguousArray<Int>) -> Int {
        if label < order.count, order[label] == key { return label }
        var low = 0, high = order.count
        while low < high {
            let middle = (low &+ high) &>> 1
            if self.label(order[middle]) < label { low = middle &+ 1 } else { high = middle }
        }
        return low
    }

    /// Adds `key` with `label`.
    @inlinable
    mutating func insert(_ key: Int, label: Int) {
        let page = key &>> _PositionPage.shift
        if page >= pages.count {
            pages.append(contentsOf: repeatElement(-1, count: page &- pages.count &+ 1))
        }
        var block = pages[page]
        if block < 0 {
            if let reused = free.popLast() {
                block = reused
            } else {
                block = live.count
                live.append(0)
                labels.append(contentsOf: repeatElement(0, count: _PositionPage.size))
                marks.append(contentsOf: repeatElement(0, count: _PositionPage.size))
            }
            pages[page] = block
        }
        live[block] &+= 1
        let slot = block &<< _PositionPage.shift | (key & _PositionPage.mask)
        labels[slot] = label
        marks[slot] = 0
    }

    /// Removes `key`, freeing its block when it was the block's last.
    @inlinable
    mutating func remove(_ key: Int) {
        let page = key &>> _PositionPage.shift
        let block = pages[page]
        live[block] &-= 1
        if live[block] == 0 {
            pages[page] = -1
            free.append(block)
        }
    }

    @inlinable
    mutating func removeAll(keepingCapacity: Bool) {
        pages.removeAll(keepingCapacity: keepingCapacity)
        labels.removeAll(keepingCapacity: keepingCapacity)
        marks.removeAll(keepingCapacity: keepingCapacity)
        live.removeAll(keepingCapacity: keepingCapacity)
        free.removeAll(keepingCapacity: keepingCapacity)
    }
}

extension _Placed: Sendable {}
extension _KeyTable: Sendable {}
extension DirectedAcyclicGraph: Sendable where Base: Sendable {}
