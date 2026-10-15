import GraphProtocols

/// What the Bron–Kerbosch algorithm with pivoting reports, in order, as `maximalCliques()` runs
/// it.
///
/// Each call is entered with the vertex it adds to R, the clique being grown, and the contents of
/// R, of P, the candidates that extend R, and of X, the vertices that extend it but were already
/// tried. The outer calls take the vertices in `coreNumbers().degeneracyOrdering`, each v with
/// R = {v}, P its neighbors after it and X its neighbors before it (Eppstein, Löffler and
/// Strash). A call with P and X both empty reports R as a maximal clique. A call with candidates
/// chooses Tomita's pivot, the member of P ∪ X with the most neighbors in P (ties to the least
/// vertex index), and then calls itself on each candidate not adjacent to the pivot, in index
/// order, moving that candidate from P to X after the call. Every call ends with a backtrack.
/// Self-loops and parallel edges are ignored.
@frozen
public enum BronKerboschEvent<Vertex: Hashable>: Hashable {
    /// A call starts: `clique` is R, the enclosing call's R with `adding` (an outer call's R is
    /// that vertex alone, so R's size is the nesting depth); `candidates` is P and `excluded` is
    /// X. Each is in `vertices` order.
    case call(adding: Vertex, clique: [Vertex], candidates: [Vertex], excluded: [Vertex])
    /// The call's pivot.
    case pivot(Vertex)
    /// R is a maximal clique, in `vertices` order: an element of `maximalCliques()`.
    case maximalClique([Vertex])
    /// The current call returns.
    case backtrack
}

extension BronKerboschEvent: Sendable where Vertex: Sendable {}

extension BronKerboschEvent: CustomStringConvertible {
    /// `call(+v, R, P, X)`, `pivot(u)`, `maximalClique(R)`, `backtrack`.
    public var description: String {
        switch self {
        case .call(let v, let r, let p, let x): "call(+\(v), \(r), \(p), \(x))"
        case .pivot(let u): "pivot(\(u))"
        case .maximalClique(let r): "maximalClique(\(r))"
        case .backtrack: "backtrack"
        }
    }
}

/// The observer that records each call's events.
@frozen
@usableFromInline
struct _BronKerboschRecorder<G: Graph>: _BronKerboschObserver {
    @usableFromInline let graph: G
    /// Every vertex by number, read once, so each event's sets are array reads.
    @usableFromInline let vertices: [G.Vertex]
    @usableFromInline var events: [BronKerboschEvent<G.Vertex>] = []

    @inlinable
    init(graph: G, vertices: [G.Vertex]) {
        self.graph = graph
        self.vertices = vertices
    }

    @inlinable
    @inline(__always)
    func _vertex(_ number: Int) -> G.Vertex { vertices[number] }

    @inlinable
    mutating func enter(_ search: _MaximalCliqueSearch, at base: Int) {
        let frames = search.frames, pWords = search.pWords
        var clique = [search.clique[0]]
        for k in search.clique.indices.dropFirst() { clique.append(search.pVertices[search.clique[k]]) }
        clique.sort()
        // P and the part of X among P's vertices index `pVertices`; the rest of X indexes
        // `xVertices`. Both lists are sorted, so P comes out in order and X is merged.
        var candidates: [Int] = [], excluded: [Int] = []
        for k in 0 ..< pWords {
            var p = frames[base + k], x = frames[base + pWords + k]
            while p != 0 {
                candidates.append(search.pVertices[k << 6 | p.trailingZeroBitCount])
                p &= p &- 1
            }
            while x != 0 {
                excluded.append(search.pVertices[k << 6 | x.trailingZeroBitCount])
                x &= x &- 1
            }
        }
        for k in 0 ..< search.xWords {
            var x = frames[base + 2 * pWords + k]
            while x != 0 {
                excluded.append(search.xVertices[k << 6 | x.trailingZeroBitCount])
                x &= x &- 1
            }
        }
        excluded.sort()
        let added = search.clique.count == 1 ? search.clique[0] : search.pVertices[search.clique[search.clique.count - 1]]
        events.append(.call(adding: _vertex(added), clique: clique.map(_vertex), candidates: candidates.map(_vertex), excluded: excluded.map(_vertex)))
    }

    @inlinable
    mutating func enterAlone(_ search: _MaximalCliqueSearch, _ v: Int) {
        events.append(.call(adding: _vertex(v), clique: [_vertex(v)], candidates: [], excluded: search.xVertices.sorted().map(_vertex)))
    }

    @inlinable
    mutating func pivot(_ search: _MaximalCliqueSearch, _ member: Int) {
        let p = search.pVertices.count
        events.append(.pivot(_vertex(member < p ? search.pVertices[member] : search.xVertices[member - p])))
    }

    @inlinable
    mutating func report(_ clique: [Int]) {
        events.append(.maximalClique(clique.map(_vertex)))
    }

    @inlinable
    mutating func leave() {
        events.append(.backtrack)
    }
}

/// The Bron–Kerbosch algorithm with pivoting as a sequence of `BronKerboschEvent`s: the search of
/// `maximalCliques()`, one clique at a time. Pulling an event past the last one kept runs the
/// search to its next maximal clique and keeps the events on the way.
///
/// The `maximalClique` events, in order, are `maximalCliques()`. The sequence holds the graph, so
/// iterating again gives the same events.
@frozen
public struct BronKerboschEvents<G: Graph>: Sequence {
    public typealias Element = BronKerboschEvent<G.Vertex>

    @usableFromInline let graph: G

    @inlinable
    init(_ graph: G) {
        self.graph = graph
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(graph) }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var search: _MaximalCliqueSearch?
        /// Its vertex table is filled with the search, at the first pull.
        @usableFromInline var recorder: _BronKerboschRecorder<G>
        @usableFromInline var cursor = 0
        @usableFromInline var done = false

        @usableFromInline let graph: G

        @inlinable
        init(_ graph: G) {
            self.graph = graph
            recorder = _BronKerboschRecorder(graph: graph, vertices: [])
        }

        @inlinable
        public mutating func next() -> BronKerboschEvent<G.Vertex>? {
            if search == nil {
                search = _MaximalCliqueSearch(graph._simpleRows())
                let graph = graph
                recorder = _BronKerboschRecorder(graph: graph, vertices: graph._listedVertices() ?? (0 ..< graph.vertexCount).map { graph.vertex(atIndex: $0) })
            }
            if cursor == recorder.events.count {
                recorder.events.removeAll(keepingCapacity: true)
                cursor = 0
                guard !done else { return nil }
                if !search!.next(observer: &recorder) { done = true }
                guard !recorder.events.isEmpty else { return nil }
            }
            let event = recorder.events[cursor]
            cursor &+= 1
            return event
        }
    }
}

extension LazyGraphView {
    /// The Bron–Kerbosch algorithm with Tomita's pivot, as `maximalCliques()` runs it, as a sequence
    /// of events: each call entered with the vertex it adds to the clique and the contents of R,
    /// P and X, its pivot, each maximal clique, and each backtrack. See `BronKerboschEvent` for
    /// the order.
    ///
    /// - Complexity: O(n + m) before the first event; O(d·n·3^(d/3)) calls in all for degeneracy
    ///   d, each event O(|R| + |P| + |X|) more than the plain search's step.
    @inlinable
    public func bronKerbosch() -> BronKerboschEvents<Base> { BronKerboschEvents(base) }
}
