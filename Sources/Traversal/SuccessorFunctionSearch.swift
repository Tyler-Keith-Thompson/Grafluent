import GraphProtocols

// Searches over a successor function, for state spaces that are not finite graphs (an unbounded
// grid, a puzzle's positions): the vertices are whatever the function reaches. The Rust
// `pathfinding` crate's `bfs`, `dfs`, `iddfs` and `topological_sort` take the same shape.

/// A successor function seen as a graph, for the searches. It is not a lawful `DirectedGraph` (it
/// has no vertex or edge collection, and contains everything), and only the searches here use it.
@usableFromInline
internal struct _SuccessorFunctionGraph<Vertex: Hashable, Successors: Sequence<Vertex>>: DirectedGraph {
    @usableFromInline let next: (Vertex) -> Successors

    @inlinable
    init(_ next: @escaping (Vertex) -> Successors) { self.next = next }

    @inlinable var vertices: [Vertex] { [] }
    @inlinable var edges: [DirectedEdge<Vertex>] { [] }
    @inlinable func successors(of vertex: Vertex) -> Successors { next(vertex) }
    @inlinable func outEdges(of vertex: Vertex) -> [Int] { [] }
    @inlinable func contains(_ vertex: Vertex) -> Bool { true }
}

/// A breadth-first search over `successors`, from `sources`. Lazy: on an infinite space, stop
/// iterating to stop the search. To prune, return fewer successors.
///
/// Inside an extension of `DirectedGraph`, the methods of the same name hide this function; call it
/// as `Traversal.breadthFirstSearch(from:successors:)` there.
@inlinable
public func breadthFirstSearch<Vertex: Hashable, Successors: Sequence<Vertex>>(
    from sources: some Sequence<Vertex>,
    depthLimit: Int? = nil,
    successors: @escaping (Vertex) -> Successors
) -> some Sequence<BreadthFirstSearchEvent<Vertex>> {
    _SuccessorFunctionGraph(successors).breadthFirstSearch(from: sources, depthLimit: depthLimit)
}

/// A depth-first search over `successors`, from each of `sources` in turn. Lazy: on an infinite
/// space, give a depth limit or stop iterating. To prune, return fewer successors.
@inlinable
public func depthFirstSearch<Vertex: Hashable, Successors: Sequence<Vertex>>(
    from sources: some Sequence<Vertex>,
    depthLimit: Int? = nil,
    successors: @escaping (Vertex) -> Successors
) -> some Sequence<DepthFirstSearchEvent<Vertex>> {
    _SuccessorFunctionGraph(successors).depthFirstSearch(from: sources, depthLimit: depthLimit)
}

/// The states reachable from `roots` in topological order: the reverse of a depth-first postorder
/// from each root in turn. `nil` when a cycle is reachable. `successors` is called once per state.
@inlinable
public func topologicalSort<Vertex: Hashable, Successors: Sequence<Vertex>>(
    from roots: some Sequence<Vertex>,
    successors: (Vertex) -> Successors
) -> [Vertex]? {
    withoutActuallyEscaping(successors) { successors in
        var order: [Vertex] = []
        for event in _SuccessorFunctionGraph(successors).depthFirstSearch(from: roots) {
            switch event {
            case .finish(let v): order.append(v)
            case .backEdge: return nil
            default: break
            }
        }
        order.reverse()
        return order
    }
}

/// A shortest path by edge count from `start` to the first state satisfying `isGoal`, by iterative
/// deepening (the `pathfinding` crate's `iddfs`): depth-first searches with a growing depth limit
/// that keep only the current path, so states need only be `Equatable`, and memory stays
/// proportional to the path. A path never revisits a state on itself. `nil` when no goal is
/// reachable and the space is finite; on an infinite space without a goal, it does not return.
///
/// Iterative deepening trades time for memory: with no record of visited states, every path is
/// enumerated again at each depth, which is exponential in the depth on graphs with many routes
/// between states (a grid). Use `breadthFirstSearch(from:successors:)` when states are `Hashable`
/// and memory allows.
@inlinable
public func iterativeDeepeningDepthFirstSearch<Vertex: Equatable, Successors: Sequence<Vertex>>(
    from start: Vertex,
    successors: (Vertex) -> Successors,
    until isGoal: (Vertex) -> Bool
) -> [Vertex]? {
    if isGoal(start) { return [start] }
    var limit = 1
    while true {
        // A depth-limited search with an explicit stack: the path, and each vertex's remaining
        // successors.
        var path = [start]
        var iterators = [successors(start).makeIterator()]
        var cutOff = false
        while let last = iterators.indices.last {
            guard let next = iterators[last].next() else {
                iterators.removeLast()
                path.removeLast()
                continue
            }
            if path.contains(next) { continue }
            if isGoal(next) { return path + [next] }
            if path.count == limit {
                cutOff = true
                continue
            }
            path.append(next)
            iterators.append(successors(next).makeIterator())
        }
        if !cutOff { return nil }
        limit += 1
    }
}
