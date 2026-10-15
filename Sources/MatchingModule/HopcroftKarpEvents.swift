import BipartiteGraphs
import GraphProtocols

/// What the Hopcroft–Karp algorithm reports, in order.
///
/// Each phase starts with a breadth-first search from the free left vertices, alternating
/// unmatched and matched edges, that finds the length of the shortest augmenting paths; it is
/// reported with that length. Then depth-first searches from each free left vertex, in left
/// order, find a maximal set of vertex-disjoint shortest augmenting paths, each reported as it is
/// found and applied: its edges, from the free left vertex to a free right vertex, alternate
/// between unmatched ones, which join the matching, and matched ones, which leave it. The
/// algorithm ends when a search finds no augmenting path.
@frozen
public enum HopcroftKarpEvent<Edge: Hashable>: Hashable {
    /// A phase starts; its augmenting paths have `length` edges.
    case phase(length: Int)
    /// An augmenting path, its edges in order from its free left end; the matching grows by one.
    case augmentingPath([Edge])
}

extension HopcroftKarpEvent: Sendable where Edge: Sendable {}

extension HopcroftKarpEvent: CustomStringConvertible {
    /// `phase(k)`, `augmentingPath([e, …])`, with `e` an edge's position.
    public var description: String {
        switch self {
        case .phase(let k): "phase(\(k))"
        case .augmentingPath(let edges): "augmentingPath(\(edges))"
        }
    }
}

/// The observer that records each phase's events.
@frozen
@usableFromInline
struct _HopcroftKarpRecorder<Edge: Hashable>: _HopcroftKarpObserver {
    /// Each slot's edge number, and each edge number's position.
    @usableFromInline let slotEdges: [Int]
    @usableFromInline let positions: [Edge]
    @usableFromInline var events: [HopcroftKarpEvent<Edge>] = []

    @inlinable
    init(slotEdges: [Int], positions: [Edge]) {
        self.slotEdges = slotEdges
        self.positions = positions
    }

    @inlinable
    mutating func layered(free: Int) {
        events.append(.phase(length: 2 * free - 1))
    }

    @inlinable
    mutating func augmenting(_ stack: [(vertex: Int, slot: Int)], mateSlot: [Int]) {
        var path: [Edge] = []
        path.reserveCapacity(2 * stack.count - 1)
        for (i, (v, slot)) in stack.enumerated() {
            if i > 0 { path.append(positions[slotEdges[mateSlot[v]]]) }
            path.append(positions[slotEdges[slot]])
        }
        events.append(.augmentingPath(path))
    }
}

/// The Hopcroft–Karp algorithm as a sequence of `HopcroftKarpEvent`s, one phase at a time:
/// pulling the first event of a phase runs that phase and keeps its events until they are
/// pulled.
///
/// It runs the engine of `maximumBipartiteMatching(bipartition:)`: the edges in an odd number of
/// augmenting paths are that call's matching. The sequence holds no copy of the graph; its
/// positions stay valid until the graph is mutated.
@frozen
public struct HopcroftKarpEvents<G: Graph>: Sequence {
    public typealias Element = HopcroftKarpEvent<G.Edges.Index>

    @usableFromInline let structure: _MatchingGraph
    @usableFromInline let left: [Int]
    @usableFromInline let positions: [G.Edges.Index]

    @inlinable
    init(graph: G, structure: _MatchingGraph, left: [Int], isLeft: [Bool]) {
        for v in 0 ..< structure.count {
            for slot in structure.offsets[v] ..< structure.offsets[v + 1] {
                precondition(isLeft[structure.targets[slot]] != isLeft[v], "An edge joins two vertices on one side: the bipartition is not this graph's")
            }
        }
        self.structure = structure
        self.left = left
        positions = Array(graph.edges.indices)
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(self) }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var run: _HopcroftKarpRun
        @usableFromInline var recorder: _HopcroftKarpRecorder<G.Edges.Index>
        @usableFromInline var cursor = 0
        @usableFromInline var done = false

        @inlinable
        init(_ base: HopcroftKarpEvents) {
            let n = base.structure.count
            run = _HopcroftKarpRun(offsets: base.structure.offsets, targets: base.structure.targets, left: base.left,
                                   mateSlot: [Int](repeating: -1, count: n), pairRight: [Int](repeating: -1, count: n))
            recorder = _HopcroftKarpRecorder(slotEdges: base.structure.edges, positions: base.positions)
        }

        @inlinable
        public mutating func next() -> HopcroftKarpEvent<G.Edges.Index>? {
            if cursor == recorder.events.count {
                recorder.events.removeAll(keepingCapacity: true)
                cursor = 0
                guard !done, run.phase(accept: { _ in true }, observer: &recorder) else {
                    done = true
                    return nil
                }
            }
            let event = recorder.events[cursor]
            cursor &+= 1
            return event
        }
    }
}

extension Graph {
    /// The Hopcroft–Karp algorithm on a bipartite graph as a sequence of events: each phase with
    /// the length of its augmenting paths, then each augmenting path. See `HopcroftKarpEvent` for
    /// the order. Left vertices are taken in `bipartition.left` order.
    ///
    /// The edges in an odd number of augmenting paths are
    /// `maximumBipartiteMatching(bipartition:)`'s matching.
    ///
    /// - Complexity: O(n + m) to make the sequence; O(m √n) to iterate every event.
    /// - Precondition: `bipartition` is this graph's (`bipartition()`): the same vertices, every
    ///   edge across.
    @inlinable
    public func hopcroftKarpEvents(bipartition: Bipartition<Self>) -> HopcroftKarpEvents<Self> {
        let structure = _matchingGraph()
        let n = structure.count
        precondition(bipartition.left.count + bipartition.right.count == n, "The bipartition is not this graph's")
        var isLeft = [Bool](repeating: false, count: n)
        var left: [Int] = []
        for v in 0 ..< n where bipartition.side(ofIndex: v) == .left {
            isLeft[v] = true
            left.append(v)
        }
        return HopcroftKarpEvents(graph: self, structure: structure, left: left, isLeft: isLeft)
    }
}

extension BipartiteGraph {
    /// The Hopcroft–Karp algorithm as a sequence of events, left vertices in `left` order. The
    /// edges in an odd number of augmenting paths are `maximumBipartiteMatching()`'s matching.
    ///
    /// - Complexity: O(n + m) to make the sequence; O(m √n) to iterate every event.
    @inlinable
    public func hopcroftKarpEvents() -> HopcroftKarpEvents<Self> {
        let structure = _matchingGraph()
        var isLeft = [Bool](repeating: false, count: structure.count)
        var leftNumbers: [Int] = []
        leftNumbers.reserveCapacity(left.count)
        for v in left {
            let i = vertexIndex(of: v)
            isLeft[i] = true
            leftNumbers.append(i)
        }
        return HopcroftKarpEvents(graph: self, structure: structure, left: leftNumbers, isLeft: isLeft)
    }
}
