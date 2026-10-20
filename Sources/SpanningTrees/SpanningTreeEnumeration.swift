import DisjointSetModule
import GraphProtocols

/// A partition of the spanning forests of a graph, in Sörensen and Janssens's scheme: those that
/// contain every edge of `included` and none of `excluded`, with the lightest of them (its ranks in
/// (weight, rank) order and its weight) and the number of the partition, which breaks ties.
@frozen
@usableFromInline
struct _ForestPartition<W: Comparable> {
    @usableFromInline var included: [Int]
    @usableFromInline var excluded: [Int]
    @usableFromInline var tree: [Int]
    @usableFromInline var weight: W
    @usableFromInline var number: Int

    @inlinable
    init(included: [Int], excluded: [Int], tree: [Int], weight: W, number: Int) {
        self.included = included
        self.excluded = excluded
        self.tree = tree
        self.weight = weight
        self.number = number
    }
}

/// The spanning forests of a graph in nondecreasing weight: a binary heap of partitions by (weight,
/// number), the lightest popped and split along its forest's free edges.
@frozen
@usableFromInline
struct _SpanningForestEnumeration<Position, W: Comparable & AdditiveArithmetic> {
    @usableFromInline let edges: _RankedEdges<Position, W>
    /// The non-loop edges as (weight, rank) in nondecreasing (weight, rank) order.
    @usableFromInline let sorted: [(W, Int)]
    /// The index in `sorted` of each rank, −1 for a loop.
    @usableFromInline let slot: [Int]
    /// The size of a spanning forest: n − c.
    @usableFromInline var size: Int
    @usableFromInline var heap: [_ForestPartition<W>]
    @usableFromInline var numbered: Int
    /// Marks per computation: `stamp[rank] == round` for an excluded or included edge.
    @usableFromInline var included: [Int]
    @usableFromInline var excluded: [Int]
    @usableFromInline var round: Int

    @inlinable
    init(edges: _RankedEdges<Position, W>, sorted: [(W, Int)]) {
        self.edges = edges
        self.sorted = sorted
        var slot = [Int](repeating: -1, count: edges.u.count)
        for (k, (_, rank)) in sorted.enumerated() { slot[rank] = k }
        self.slot = slot
        included = [Int](repeating: 0, count: edges.u.count)
        excluded = [Int](repeating: 0, count: edges.u.count)
        round = 0
        heap = []
        numbered = 0
        size = 0
        // The first partition is unconstrained: its forest is the minimum one, of size n − c.
        let first = kruskal(including: [], excluding: [])
        size = first.tree.count
        push(_ForestPartition(included: [], excluded: [], tree: first.tree, weight: first.weight, number: 0))
        numbered = 1
    }

    /// Kruskal under the constraints: the included edges first, then every other edge not excluded
    /// in sorted order. The tree is given as indices into `sorted`, ascending.
    @inlinable
    mutating func kruskal(including: [Int], excluding: [Int]) -> (tree: [Int], weight: W) {
        round += 1
        for rank in including { included[rank] = round }
        for rank in excluding { excluded[rank] = round }
        var sets = DisjointSet(count: edges.vertexCount)
        var tree: [Int] = []
        var weight = W.zero
        for rank in including {
            _ = sets.union(edges.u[rank], edges.v[rank])
            tree.append(slot[rank])
            weight += sorted[slot[rank]].0
        }
        for (k, (w, rank)) in sorted.enumerated() where included[rank] != round && excluded[rank] != round {
            if sets.union(edges.u[rank], edges.v[rank]) {
                tree.append(k)
                weight += w
            }
        }
        // The included edges are a prefix of the tree in sorted order: a child includes its
        // parent's free tree edges before the one it excludes, and every edge the child takes
        // instead comes after that excluded edge, so the tree is already sorted.
        return (tree, weight)
    }

    @inlinable
    func precedes(_ a: _ForestPartition<W>, _ b: _ForestPartition<W>) -> Bool {
        a.weight < b.weight || (!(b.weight < a.weight) && a.number < b.number)
    }

    @inlinable
    mutating func push(_ partition: _ForestPartition<W>) {
        heap.append(partition)
        var child = heap.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard precedes(heap[child], heap[parent]) else { break }
            heap.swapAt(child, parent)
            child = parent
        }
    }

    @inlinable
    mutating func pop() -> _ForestPartition<W>? {
        guard !heap.isEmpty else { return nil }
        let top = heap[0]
        let last = heap.removeLast()
        if !heap.isEmpty {
            heap[0] = last
            var parent = 0
            while true {
                let left = 2 * parent + 1, right = left + 1
                var least = parent
                if left < heap.count, precedes(heap[left], heap[least]) { least = left }
                if right < heap.count, precedes(heap[right], heap[least]) { least = right }
                if least == parent { break }
                heap.swapAt(parent, least)
                parent = least
            }
        }
        return top
    }

    /// The next forest's ranks (in sorted order) and weight, splitting its partition along the
    /// forest's edges that were not included: the k-th child includes the first k − 1 of them and
    /// excludes the k-th, when a spanning forest remains.
    @inlinable
    mutating func next() -> (ranks: [Int], weight: W)? {
        guard let partition = pop() else { return nil }
        var included = partition.included
        for k in partition.tree {
            let rank = sorted[k].1
            if partition.included.contains(rank) { continue }
            var excluded = partition.excluded
            excluded.append(rank)
            let child = kruskal(including: included, excluding: excluded)
            if child.tree.count == size {
                push(_ForestPartition(included: included, excluded: excluded, tree: child.tree, weight: child.weight, number: numbered))
                numbered += 1
            }
            included.append(rank)
        }
        return (partition.tree.map { sorted[$0].1 }, partition.weight)
    }
}

/// The spanning forests of a graph in nondecreasing weight, as `spanningForests(weight:)` lists
/// them.
@frozen
public struct SpanningForests<G: Graph, Weight: Comparable & AdditiveArithmetic>: Sequence {
    @usableFromInline let _edges: _RankedEdges<G.Edges.Index, Weight>
    @usableFromInline let _sorted: [(Weight, Int)]

    @inlinable
    init(edges: _RankedEdges<G.Edges.Index, Weight>, sorted: [(Weight, Int)]) {
        _edges = edges
        _sorted = sorted
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(_SpanningForestEnumeration(edges: _edges, sorted: _sorted))
    }

    /// Lists the forests of a `SpanningForests`, lightest first.
    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline var _enumeration: _SpanningForestEnumeration<G.Edges.Index, Weight>

        @inlinable
        init(_ enumeration: _SpanningForestEnumeration<G.Edges.Index, Weight>) {
            _enumeration = enumeration
        }

        /// The next lightest spanning forest, or `nil` when every one has been listed.
        @inlinable
        public mutating func next() -> SpanningForest<G, Weight>? {
            guard let (ranks, weight) = _enumeration.next() else { return nil }
            return SpanningForest(edges: ranks.map { _enumeration.edges.position[$0] }, weight: weight)
        }
    }
}

extension Graph {
    /// Every spanning forest of the graph, in nondecreasing weight: one spanning tree per connected
    /// component, the lightest first, so `prefix(k)` is the k lightest. Each forest lists its edges
    /// by nondecreasing (weight, position), and the first is `minimumSpanningTree(weight:)`.
    /// Forests of equal weight come in an order that is deterministic but unspecified. Self-loops
    /// are never in a forest; parallel edges give distinct forests.
    ///
    /// The sequence is lazy. It keeps a heap of partitions of the forests still to list, each with
    /// its lightest forest (Sörensen and Janssens): listing a forest splits its partition along the
    /// forest's free edges, one Kruskal run per split.
    ///
    /// - Parameter weight: Each edge's weight, called once per edge that is not a self-loop.
    /// - Complexity: O(m log m) to start; O(n · m · α(n)) per forest listed, and O(n · m) memory
    ///   per forest still pending.
    /// - Precondition: no weight is NaN, and no forest's weight overflows.
    @inlinable
    public func spanningForests<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> SpanningForests<Self, W> {
        var ranked = _rankedEdges(weight)
        var keyed = ranked.takeKeyed()
        keyed.sort { $0.0 < $1.0 || (!($1.0 < $0.0) && $0.1 < $1.1) }
        return SpanningForests(edges: ranked, sorted: keyed)
    }

    /// Every spanning forest of the unweighted graph, every edge weighing 1: the weight of each is
    /// its number of edges, and the order among them is deterministic but unspecified.
    ///
    /// - Complexity: as for `spanningForests(weight:)`.
    @inlinable
    public func spanningForests() -> SpanningForests<Self, Int> {
        spanningForests { _ in 1 }
    }
}
