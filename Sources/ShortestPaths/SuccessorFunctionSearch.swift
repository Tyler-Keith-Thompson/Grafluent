// Weighted searches over a successor function, for state spaces that are not finite graphs (an
// unbounded grid, a puzzle's positions): the vertices are whatever the function reaches. Rust's
// `pathfinding` crate offers the same shape (`dijkstra`, `astar`); Traversal has the unweighted
// searches (`breadthFirstSearch(from:successors:)` and the others).

/// The heap entry of the closure searches: a state's number, its priority, and its distance when
/// it was queued (a stale entry has a larger distance than the state's best).
@frozen
@usableFromInline
struct _SearchEntry<W: Comparable> {
    @usableFromInline let state: Int
    @usableFromInline let priority: W
    @usableFromInline let distance: W

    @inlinable
    init(state: Int, priority: W, distance: W) {
        self.state = state
        self.priority = priority
        self.distance = distance
    }

    /// Lower priority first; on a tie, the farther state (closer to a goal under A*).
    @inlinable
    func precedes(_ other: _SearchEntry) -> Bool {
        priority < other.priority || (priority == other.priority && other.distance < distance)
    }
}

/// A binary min-heap of search entries, with no decrease-key: a better entry is pushed and the
/// stale one skipped when popped.
@frozen
@usableFromInline
struct _SearchHeap<W: Comparable> {
    @usableFromInline var entries: [_SearchEntry<W>] = []

    @inlinable
    init() {}

    @inlinable
    mutating func push(_ entry: _SearchEntry<W>) {
        entries.append(entry)
        var child = entries.count - 1
        while child > 0 {
            let up = (child - 1) / 2
            guard entry.precedes(entries[up]) else { break }
            entries[child] = entries[up]
            child = up
        }
        entries[child] = entry
    }

    @inlinable
    mutating func popMin() -> _SearchEntry<W>? {
        guard let last = entries.popLast() else { return nil }
        guard !entries.isEmpty else { return last }
        let first = entries[0]
        let count = entries.count
        var hole = 0
        while true {
            var child = 2 * hole + 1
            guard child < count else { break }
            if child + 1 < count, entries[child + 1].precedes(entries[child]) { child += 1 }
            guard entries[child].precedes(last) else { break }
            entries[hole] = entries[child]
            hole = child
        }
        entries[hole] = last
        return first
    }
}

/// Dijkstra's algorithm, or A* when `heuristic` is given, over a successor closure, with states
/// numbered in a dictionary as they are reached and a binary heap with lazy deletion: a state whose
/// distance improves is queued again, and the stale entry is skipped when it comes out. Under A*,
/// that reopens a state already expanded, so an admissible but inconsistent heuristic stays exact.
/// A step whose distance would pass `cutoff` is dropped before its state is numbered.
@inlinable
func _closureShortestPath<V: Hashable, W: Comparable & AdditiveArithmetic, S: Sequence<(V, W)>>(
    from start: V, cutoff: W?, successors: (V) -> S, heuristic: ((V) -> W)?, success: (V) -> Bool
) -> (path: [V], distance: W)? {
    precondition(cutoff.map { $0 == $0 } ?? true, "The cutoff is NaN")
    var number: [V: Int] = [start: 0]
    var states = [start]
    var distance = [W.zero]
    var parent = [-1]
    var heap = _SearchHeap<W>()
    var first = W.zero
    if let heuristic {
        first = heuristic(start)
        precondition(first == first, "An A* priority (distance plus heuristic estimate) is NaN")
    }
    heap.push(_SearchEntry(state: 0, priority: first, distance: .zero))
    while let entry = heap.popMin() {
        let u = entry.state
        // A stale entry: the state was queued again at a shorter distance.
        guard entry.distance == distance[u] else { continue }
        let state = states[u]
        // The goal is tested when it is settled, not when it is queued: with step costs that
        // depend on both ends, the first route to reach it need not be the shortest.
        if success(state) {
            var path: [V] = []
            var i = u
            while i >= 0 {
                path.append(states[i])
                i = parent[i]
            }
            path.reverse()
            return (path, entry.distance)
        }
        for (next, weight) in successors(state) {
            precondition(weight >= .zero, "Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford")
            let candidate = entry.distance + weight
            if let cutoff, cutoff < candidate { continue }
            let v: Int
            if let known = number[next] {
                guard candidate < distance[known] else { continue }
                v = known
                distance[v] = candidate
                parent[v] = u
            } else {
                v = states.count
                number[next] = v
                states.append(next)
                distance.append(candidate)
                parent.append(u)
            }
            var priority = candidate
            if let heuristic {
                priority = candidate + heuristic(next)
                // Covers a NaN estimate, and an infinite distance plus the opposite infinity: a NaN
                // priority would break the heap's order and end the search at a wrong state.
                precondition(priority == priority, "An A* priority (distance plus heuristic estimate) is NaN")
            }
            heap.push(_SearchEntry(state: v, priority: priority, distance: candidate))
        }
    }
    return nil
}

/// A shortest path from `start` to the nearest state satisfying `success`, by Dijkstra's algorithm
/// over a successor function (decision D19; the `pathfinding` crate's `dijkstra`), for state spaces
/// that are not stored graphs. `successors(v)` lists each state reachable in one step from `v` with
/// the step's cost, and is called once per expanded state; states need only be `Hashable`, and are
/// numbered in a dictionary as they are reached.
///
/// Returns the path's states from `start` to the goal, both included (`[start]` when `start`
/// satisfies `success`, without calling `successors`), and its cost; `nil` when the reachable space
/// is finite and holds no goal. On an infinite space with no reachable goal it does not return.
/// A goal is recognized when it is settled, so the distance is the shortest even when step costs
/// depend on both ends of the step. Among equal-cost paths, which one is returned is unspecified.
///
/// Inside an extension of `DirectedGraph`, the methods of the same name hide this function; call it
/// as `ShortestPaths.dijkstraShortestPath(from:cutoff:successors:success:)` there.
///
/// - Parameter cutoff: When given, states other than `start` are reached only at distance at most
///   `cutoff` (inclusive, as the stored-graph `dijkstraShortestPaths(from:cutoff:weight:)` and
///   NetworkX's `cutoff`), and `nil` is returned when no goal is that close. The search then ends
///   whenever finitely many states are within the cutoff, even on an infinite space. `start` is
///   always reached, at zero, and expanded, even under a negative cutoff.
/// - Precondition: every examined cost is at least `.zero` and not NaN (a cost is examined, and
///   checked, before the cutoff drops its step); `cutoff` is not NaN; every sum fits in `W`.
@inlinable
public func dijkstraShortestPath<V: Hashable, W: Comparable & AdditiveArithmetic, S: Sequence<(V, W)>>(
    from start: V, cutoff: W? = nil, successors: (V) -> S, success: (V) -> Bool
) -> (path: [V], distance: W)? {
    _closureShortestPath(from: start, cutoff: cutoff, successors: successors, heuristic: nil, success: success)
}

/// A shortest path from `start` to the nearest state satisfying `success`, by A* over a successor
/// function (decision D19; the `pathfinding` crate's `astar`), guided by `heuristic`, an estimate
/// of each state's cost to the nearest goal. Returns as `dijkstraShortestPath(from:cutoff:
/// successors:success:)` does, and calls `heuristic` once each time a state is queued.
///
/// With an admissible heuristic (never more than the true remaining cost, and so zero or less at a
/// goal) the path is a shortest one, even when the heuristic is not consistent, since a state whose
/// distance improves after it was expanded is expanded again. With a consistent one
/// (`h(u) <= cost(u, v) + h(v)`) no state is expanded twice. A heuristic of zero is Dijkstra's
/// algorithm.
///
/// - Parameter cutoff: As for `dijkstraShortestPath(from:cutoff:successors:success:)`: it bounds
///   the distance from `start`, not the distance plus the estimate (NetworkX's `astar_path` bounds
///   the sum), so the answer does not depend on the heuristic.
/// - Precondition: as for `dijkstraShortestPath(from:cutoff:successors:success:)`; no priority
///   (a distance plus its state's estimate) is NaN, so no estimate is NaN, and no estimate is an
///   infinity opposite to an infinite distance.
@inlinable
public func aStarShortestPath<V: Hashable, W: Comparable & AdditiveArithmetic, S: Sequence<(V, W)>>(
    from start: V, cutoff: W? = nil, successors: (V) -> S, heuristic: (V) -> W, success: (V) -> Bool
) -> (path: [V], distance: W)? {
    withoutActuallyEscaping(heuristic) { heuristic in
        _closureShortestPath(from: start, cutoff: cutoff, successors: successors, heuristic: heuristic, success: success)
    }
}
