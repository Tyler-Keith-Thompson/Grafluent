import GraphProtocols
import PriorityQueueModule
import Walks

/// Bidirectional Dijkstra in index space: a forward search from `source` over out-edges and a
/// backward one from `target` over in-edges, each step settling the next vertex of the side with
/// the smaller queue. Every edge either side examines that reaches a vertex the other side has
/// reached is a candidate meeting, of length forward label + weight + backward label; the best is
/// kept, the first among equals. The search stops when the two queues' smallest priorities add up
/// to at least the best candidate, which is then a shortest path's length.
@frozen
@usableFromInline
struct _BidirectionalDijkstra<G: DirectedGraph, W: Comparable & AdditiveArithmetic> {
    @usableFromInline let source: Int
    @usableFromInline let target: Int
    @usableFromInline let placeholder: G.Edges.Index

    @inlinable
    init(source: Int, target: Int, placeholder: G.Edges.Index) {
        self.source = source
        self.target = target
        self.placeholder = placeholder
    }

    /// The path's indices and edges, and its length; `nil` when `target` is not reachable.
    @usableFromInline
    typealias Output = (vertices: [Int], edges: [G.Edges.Index], distance: W)?

    @inlinable
    func run<Forward: IteratorProtocol, Backward: IteratorProtocol>(
        count n: Int, _ forward: (Int) -> Forward, _ backward: (Int) -> Backward, _ weight: (G.Edges.Index) -> W
    ) -> Output where Forward.Element == (Int, G.Edges.Index), Backward.Element == (Int, G.Edges.Index) {
        if source == target { return ([source], [], .zero) }
        // -2: not reached from that side; -1: the side's root.
        var forwardDistance = [W](repeating: .zero, count: n), backwardDistance = forwardDistance
        var forwardParent = [Int](repeating: -2, count: n), backwardParent = forwardParent
        // The edge each parent pointer crossed: from the parent forward, into it backward.
        var forwardEdge = [G.Edges.Index](repeating: placeholder, count: n), backwardEdge = forwardEdge
        var forwardQueue = IndexedPriorityQueue<W>(indexBound: n), backwardQueue = forwardQueue
        forwardParent[source] = -1
        backwardParent[target] = -1
        forwardQueue.insert(source, priority: .zero)
        backwardQueue.insert(target, priority: .zero)
        var best: W? = nil
        // The best meeting: the forward side's vertex, the edge, the backward side's vertex.
        var meetingTail = -1, meetingHead = -1
        var meetingEdge = placeholder
        while let forwardMin = forwardQueue.min, let backwardMin = backwardQueue.min {
            if let best, !(forwardMin.priority + backwardMin.priority < best) { break }
            if forwardQueue.count <= backwardQueue.count {
                let (u, du) = forwardQueue.removeMin()
                var out = forward(u)
                while let (v, e) = out.next() {
                    precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A successor index is out of range")
                    let w = weight(e)
                    precondition(w >= .zero, "Dijkstra's algorithm needs nonnegative weights (and no NaN); use Bellman–Ford")
                    let candidate = du + w
                    if forwardParent[v] == -2 || candidate < forwardDistance[v] {
                        forwardDistance[v] = candidate
                        forwardParent[v] = u
                        forwardEdge[v] = e
                        forwardQueue.insertOrDecreasePriority(of: v, to: candidate)
                    }
                    if backwardParent[v] != -2 {
                        let total = candidate + backwardDistance[v]
                        if best.map({ total < $0 }) ?? true {
                            best = total
                            (meetingTail, meetingEdge, meetingHead) = (u, e, v)
                        }
                    }
                }
            } else {
                let (x, dx) = backwardQueue.removeMin()
                var into = backward(x)
                while let (y, e) = into.next() {
                    precondition(UInt(bitPattern: y) < UInt(bitPattern: n), "A predecessor index is out of range")
                    let w = weight(e)
                    precondition(w >= .zero, "Dijkstra's algorithm needs nonnegative weights (and no NaN); use Bellman–Ford")
                    let candidate = dx + w
                    if backwardParent[y] == -2 || candidate < backwardDistance[y] {
                        backwardDistance[y] = candidate
                        backwardParent[y] = x
                        backwardEdge[y] = e
                        backwardQueue.insertOrDecreasePriority(of: y, to: candidate)
                    }
                    if forwardParent[y] != -2 {
                        let total = forwardDistance[y] + candidate
                        if best.map({ total < $0 }) ?? true {
                            best = total
                            (meetingTail, meetingEdge, meetingHead) = (y, e, x)
                        }
                    }
                }
            }
        }
        guard let best else { return nil }
        // Back from the meeting edge's tail to the source along forward parents, then on from its
        // head to the target along backward ones. The first best meeting found repeats no vertex:
        // a vertex on both halves met at the same length earlier.
        var vertices: [Int] = []
        var pathEdges: [G.Edges.Index] = []
        var v = meetingTail
        while v != -1 {
            vertices.append(v)
            if forwardParent[v] >= 0 { pathEdges.append(forwardEdge[v]) }
            v = forwardParent[v]
        }
        vertices.reverse()
        pathEdges.reverse()
        pathEdges.append(meetingEdge)
        v = meetingHead
        vertices.append(v)
        while backwardParent[v] != -1 {
            pathEdges.append(backwardEdge[v])
            v = backwardParent[v]
            vertices.append(v)
        }
        return (vertices, pathEdges, best)
    }
}

/// The in-edges of a graph without vertex indices, as (source index, edge position) pairs,
/// through a dictionary built once.
@frozen
@usableFromInline
struct _LookupInArcs<G: BidirectionalDirectedGraph>: IteratorProtocol {
    @usableFromInline let graph: G
    @usableFromInline let identifiers: [G.Vertex: Int]
    @usableFromInline var edges: G.InEdges.Iterator

    @inlinable
    init(graph: G, identifiers: [G.Vertex: Int], vertex: G.Vertex) {
        self.graph = graph
        self.identifiers = identifiers
        self.edges = graph.inEdges(of: vertex).makeIterator()
    }

    @inlinable
    mutating func next() -> (Int, G.Edges.Index)? {
        guard let e = edges.next() else { return nil }
        return (identifiers[graph.source(ofEdgeAt: e)]!, e)
    }
}

extension BidirectionalDirectedGraph {
    /// A shortest path from `source` to `target` by bidirectional Dijkstra, with the edges it takes
    /// (which tell parallel edges apart), and its length, or `nil` when `target` is not reachable.
    ///
    /// Searches forward from `source` over out-edges and backward from `target` over in-edges at
    /// once, and stops when no shorter path can be left; on most graphs the two searches together
    /// settle far fewer vertices than `dijkstraShortestPath(from:to:weight:)`. `weight` is called
    /// each time an edge is examined, from either side, and not kept.
    ///
    /// - Complexity: O((n + m) log n) in the worst case; O(n) to set up.
    /// - Precondition: `source` and `target` are vertices; every examined weight is at least
    ///   `.zero` and not NaN; every sum fits in `W`.
    @inlinable
    public func bidirectionalDijkstraShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> (path: Path<Vertex, Edges.Index>, distance: W)? {
        var ids = _numberedVertices()
        let search = _BidirectionalDijkstra<Self, W>(source: _index(of: source, ids), target: _index(of: target, ids), placeholder: edges.endIndex)
        let n = ids.count
        let result: _BidirectionalDijkstra<Self, W>.Output
        if ids.isIndexed {
            result = search.run(
                count: n, { zip(successorIndices(ofIndex: $0), outEdges(ofIndex: $0)).makeIterator() },
                { zip(predecessorIndices(ofIndex: $0), inEdges(ofIndex: $0)).makeIterator() }, weight)
        } else if let rows = ids.rows {
            let reverse = ids.numberedPredecessorRows()
            result = rows.offsets.withUnsafeBufferPointer { offsets in
                rows.neighbors.withUnsafeBufferPointer { targets in
                    rows.edges.withUnsafeBufferPointer { edges in
                        reverse.offsets.withUnsafeBufferPointer { reverseOffsets in
                            reverse.neighbors.withUnsafeBufferPointer { sources in
                                reverse.edges.withUnsafeBufferPointer { reverseEdges in
                                    search.run(
                                        count: n, { _NumberedArcs<Edges.Index>(row: $0, offsets: offsets, targets: targets, edges: edges) },
                                        { _NumberedArcs<Edges.Index>(row: $0, offsets: reverseOffsets, targets: sources, edges: reverseEdges) }, weight)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let identifiers = ids.identifiers, vertices = ids.vertices
            result = search.run(
                count: n, { _LookupArcs(graph: self, identifiers: identifiers, vertex: vertices[$0]) },
                { _LookupInArcs(graph: self, identifiers: identifiers, vertex: vertices[$0]) }, weight)
        }
        guard let result else { return nil }
        // Each step is an edge of the graph, and a shortest path found this way repeats no vertex.
        return (Path(_uncheckedVertices: result.vertices.map { ids.vertex($0) }, edges: result.edges), result.distance)
    }
}

extension Graph {
    /// `directedView.bidirectionalDijkstraShortestPath(from:to:weight:)`, weighing each arc by its
    /// edge: both searches walk every edge at each endpoint.
    @inlinable
    public func bidirectionalDijkstraShortestPath<W: Comparable & AdditiveArithmetic>(
        from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W
    ) -> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: W)? {
        directedView.bidirectionalDijkstraShortestPath(from: source, to: target) { weight($0.position) }
    }
}
