import GraphProtocols
import Walks

extension DirectedGraph {
    /// The vertices in an order in which every edge goes from an earlier vertex to a later one:
    /// the reverse of a depth-first postorder of the whole graph, with roots in `vertices` order.
    /// `nil` when the graph has a cycle (a self-loop is one); `findCycle()` gives one.
    @inlinable
    public func topologicalSort() -> [Vertex]? {
        var search = IndexSpaceSearch(self)
        var order: [Vertex] = []
        let acyclic = search.depthFirst(from: nil) { step, ids in
            switch step {
            case .finish(let v): order.append(ids.vertex(v))
            case .backEdge: return .stop
            default: break
            }
            return .proceed
        }
        guard acyclic else { return nil }
        order.reverse()
        return order
    }

    /// The vertices in generations by Kahn's algorithm: the first generation has no in-edges, and
    /// each later one has in-edges only from earlier generations, so generation k holds the
    /// vertices whose longest incoming path has k edges (NetworkX's `topological_generations`).
    /// Within a generation, vertices are in the order they became ready. `nil` when the graph has a
    /// cycle.
    @inlinable
    public func topologicalGenerations() -> [[Vertex]]? {
        var ids = _VertexIdentifiers(self)
        var inDegree: [Int] = []
        var all: [Int] = []
        if ids.isIndexed { all = Array(0 ..< ids.count) } else { for v in vertices { all.append(ids.identifier(of: v)) } }
        _grow(&inDegree, to: ids.count, with: 0)
        for u in all {
            ids.forEachSuccessor(of: u) { inDegree[$0] += 1 }
        }
        var generation = all.filter { inDegree[$0] == 0 }
        var generations: [[Vertex]] = []
        var emitted = 0
        while !generation.isEmpty {
            generations.append(generation.map { ids.vertex($0) })
            emitted += generation.count
            var next: [Int] = []
            for u in generation {
                ids.forEachSuccessor(of: u) { w in
                    inDegree[w] -= 1
                    if inDegree[w] == 0 { next.append(w) }
                }
            }
            generation = next
        }
        return emitted == all.count ? generations : nil
    }

    /// The topological order that is smallest by `areInIncreasingOrder`: at each step, the least
    /// vertex all of whose in-edges come from vertices already placed (NetworkX's
    /// `lexicographical_topological_sort`). Vertices that compare equal are placed in the order they
    /// became ready. `nil` when the graph has a cycle.
    @inlinable
    public func lexicographicalTopologicalSort(by areInIncreasingOrder: (Vertex, Vertex) -> Bool) -> [Vertex]? {
        var ids = _VertexIdentifiers(self)
        var all: [Int] = []
        if ids.isIndexed { all = Array(0 ..< ids.count) } else { for v in vertices { all.append(ids.identifier(of: v)) } }
        var inDegree = [Int](repeating: 0, count: ids.count)
        for u in all {
            ids.forEachSuccessor(of: u) { inDegree[$0] += 1 }
        }
        // A binary min-heap of (vertex, arrival), so ties keep the order they became ready.
        var heap: [(id: Int, arrival: Int)] = []
        var arrivals = 0
        func precedes(_ a: (id: Int, arrival: Int), _ b: (id: Int, arrival: Int)) -> Bool {
            let x = ids.vertex(a.id)
            let y = ids.vertex(b.id)
            if areInIncreasingOrder(x, y) { return true }
            if areInIncreasingOrder(y, x) { return false }
            return a.arrival < b.arrival
        }
        func push(_ id: Int) {
            heap.append((id, arrivals))
            arrivals += 1
            var child = heap.count - 1
            while child > 0 {
                let parent = (child - 1) / 2
                guard precedes(heap[child], heap[parent]) else { break }
                heap.swapAt(child, parent)
                child = parent
            }
        }
        func pop() -> Int {
            let top = heap[0].id
            heap.swapAt(0, heap.count - 1)
            heap.removeLast()
            var parent = 0
            while true {
                let left = 2 * parent + 1
                let right = left + 1
                var least = parent
                if left < heap.count, precedes(heap[left], heap[least]) { least = left }
                if right < heap.count, precedes(heap[right], heap[least]) { least = right }
                if least == parent { break }
                heap.swapAt(parent, least)
                parent = least
            }
            return top
        }
        for u in all where inDegree[u] == 0 { push(u) }
        var order: [Vertex] = []
        while !heap.isEmpty {
            let u = pop()
            order.append(ids.vertex(u))
            var ready: [Int] = []
            ids.forEachSuccessor(of: u) { w in
                inDegree[w] -= 1
                if inDegree[w] == 0 { ready.append(w) }
            }
            for w in ready { push(w) }
        }
        return order.count == all.count ? order : nil
    }

    /// A cycle, its vertices in order from the target of the back edge that closes it, with the
    /// edges the search took, or `nil` when the graph is acyclic. It is the cycle closed by the
    /// first back edge of a depth-first search of the whole graph; a self-loop gives a cycle of one
    /// vertex and one edge.
    @inlinable
    public func findCycle() -> Cycle<Vertex, Edges.Index>? {
        _findCycle(from: nil)
    }

    /// A cycle reachable from `roots`, searched depth-first from each in turn, or `nil` when none
    /// is reachable.
    ///
    /// - Precondition: every root is a vertex.
    @inlinable
    public func findCycle(from roots: some Sequence<Vertex>) -> Cycle<Vertex, Edges.Index>? {
        var all: [Vertex] = []
        for root in roots {
            precondition(contains(root), "The source \(root) is not a vertex of the graph")
            all.append(root)
        }
        return _findCycle(from: all)
    }

    @inlinable
    func _findCycle(from roots: [Vertex]?) -> Cycle<Vertex, Edges.Index>? {
        var search = IndexSpaceSearch(self)
        let rootIDs = roots.map { $0.map { search.ids.identifier(of: $0) } }
        var closing: (source: Int, target: Int)?
        search.depthFirst(from: rootIDs) { step, _ in
            if case .backEdge(let u, let w) = step {
                closing = (u, w)
                return .stop
            }
            return .proceed
        }
        guard let (u, w) = closing else { return nil }
        // The tree path from w down to u, which the back edge u→w closes.
        var cycle: [Int] = [u]
        while cycle[cycle.count - 1] != w { cycle.append(search.parent[cycle[cycle.count - 1]]) }
        // The search took, from each vertex, the first out-edge to the next (an earlier one would
        // have reached it first), so picking the first edge of each step gives its edges.
        let ordered = Array(cycle.reversed())
        return Cycle(_uncheckedVertices: ordered.map { search.ids.vertex($0) }, edges: _stepEdges(ordered + [ordered[0]], search.ids))
    }

    /// Whether the graph has no cycle (a self-loop is a cycle). O(n + m).
    @inlinable
    public var isAcyclic: Bool { findCycle() == nil }
}

extension DirectedGraph where Vertex: Comparable {
    /// The topological order that is smallest by `<` (NetworkX's
    /// `lexicographical_topological_sort`). `nil` when the graph has a cycle.
    @inlinable
    public func lexicographicalTopologicalSort() -> [Vertex]? {
        lexicographicalTopologicalSort(by: <)
    }
}
