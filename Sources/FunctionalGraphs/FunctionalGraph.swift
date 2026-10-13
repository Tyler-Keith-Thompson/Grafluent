import GraphProtocols

/// The graph of a function f on the vertices `0..<n`: every vertex `v` has exactly one out-edge,
/// `v → f(v)`, and a fixed point is a self-loop. Also called a successor graph (Laaksonen,
/// *Competitive Programmer's Handbook*, §16.3).
///
/// Following any vertex's edges eventually repeats, so each weakly connected component holds
/// exactly one cycle, with rooted trees hanging off its vertices (Flajolet and Odlyzko, "Random
/// mapping statistics", EUROCRYPT '89). `cycleDecomposition()` finds every cycle and tree in O(n);
/// `successor(of:steps:)` answers f^k(v) for any k.
///
/// For f given as a closure over a state space too large to store, use `floydCycleDetection` or
/// `brentCycleDetection`, which need only `Equatable` states and O(1) memory.
///
/// **Storage.** One `Int` per vertex, `f(v)`. The edge leaving `v` has position `v`, so edge
/// positions and edge indices are both the source. For `Hashable` vertex labels, use
/// `LabeledGraph<Label, FunctionalGraph>`; `LabeledGraph(FunctionalGraph(g)!, labels: g.vertices)`
/// gives a graph `g` its labels back.
///
/// The graph is immutable: build a new one to change f.
@frozen
public struct FunctionalGraph: Sendable {
    /// `_successors[v]` is f(v), each in `0..<_successors.count`.
    @usableFromInline
    internal var _successors: [Int]

    /// The attached vertex maps (`PropertyGraph`), one value per vertex.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// The attached edge maps, one value per edge, which is per source.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The generation: stamped once by every initializer, and never advanced.
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// Unchecked: every element must be in `0..<_successors.count`. Stamps a generation.
    @inlinable
    internal init(_unchecked successors: [Int]) {
        self._successors = successors
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
        _generation.stamp()
    }

    /// The generation of this graph, which never changes: the graph is immutable. A structure
    /// derived from this graph is current for it and its copies, and for no other graph.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }

    /// The graph of f, where `successors[v]` is f(v). O(n).
    ///
    /// - Precondition: every element is in `0..<n`, where n is the number of elements.
    @inlinable
    public init(successors: some Sequence<Int>) {
        let array = Array(successors)
        let n = array.count
        for (v, w) in array.enumerated() {
            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "successor \(w) of \(v) is not a vertex (0..<\(n))")
        }
        self.init(_unchecked: array)
    }

    /// The graph of `successor` on `0..<vertexCount`. O(n): calls `successor` once per vertex, in
    /// ascending order, and never when `vertexCount` is zero.
    ///
    /// - Precondition: `vertexCount >= 0`, and every result is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, successor: (Int) -> Int) {
        precondition(vertexCount >= 0, "negative vertex count \(vertexCount)")
        var array: [Int] = []
        array.reserveCapacity(vertexCount)
        for v in 0 ..< vertexCount {
            let w = successor(v)
            precondition(UInt(bitPattern: w) < UInt(bitPattern: vertexCount), "successor \(w) of \(v) is not a vertex (0..<\(vertexCount))")
            array.append(w)
        }
        self.init(_unchecked: array)
    }

    /// The functional graph of `graph`, or `nil` unless every vertex has out-degree exactly 1
    /// (parallel edges counted). Vertex `i` is the `i`th vertex of `graph.vertices`. O(n + m), and
    /// O(n) expected hashing when `graph` has no vertex indices.
    @inlinable
    public init?<G: DirectedGraph>(_ graph: G) {
        let n = graph.vertexCount
        var array = [Int](repeating: 0, count: n)
        if graph.vertexIndexBound != nil {
            // With vertex indices, `vertices` is in index order.
            for i in 0 ..< n {
                var row = graph.successorIndices(ofIndex: i).makeIterator()
                guard let w = row.next(), row.next() == nil else { return nil }
                array[i] = w
            }
        } else {
            var number: [G.Vertex: Int] = [:]
            number.reserveCapacity(n)
            for (i, v) in graph.vertices.enumerated() { number[v] = i }
            for (i, v) in graph.vertices.enumerated() {
                var row = graph.successors(of: v).makeIterator()
                guard let w = row.next(), row.next() == nil, let j = number[w] else { return nil }
                array[i] = j
            }
        }
        self.init(_unchecked: array)
    }

    @inlinable
    @inline(__always)
    internal func _check(_ vertex: Int) {
        precondition(UInt(bitPattern: vertex) < UInt(bitPattern: _successors.count), "\(vertex) is not a vertex of the graph")
    }

    /// f(v), the target of the one edge leaving `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func successor(of vertex: Int) -> Int {
        _check(vertex)
        return _successors.withUnsafeBufferPointer { $0[vertex] }
    }

    /// `successor(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func successor(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return successor(of: vertex)
    }

    /// `successor(of: vertex, steps: steps)`, throwing instead of trapping when `vertex` is not
    /// in `0..<vertexCount`. O(min(k, n)).
    ///
    /// - Precondition: `steps >= 0`: a negative count is a misuse, not a missing vertex, and
    ///   still traps.
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func successor(checked vertex: Int, steps: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return successor(of: vertex, steps: steps)
    }

    /// f^k(v): the vertex reached from `vertex` after `steps` edges. O(min(k, n)) time and O(1)
    /// memory. Up to n steps, it walks; beyond, it finds the tail and cycle of `vertex`'s walk by
    /// Brent's algorithm and walks the tail length plus the remaining steps modulo the cycle
    /// length, so `Int.max` steps cost O(n). For many queries, `cycleDecomposition()` answers
    /// each in O(log n).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`, and `steps >= 0`.
    @inlinable
    public func successor(of vertex: Int, steps: Int) -> Int {
        _check(vertex)
        precondition(steps >= 0, "negative step count \(steps)")
        return _successors.withUnsafeBufferPointer { f in
            var x = vertex
            if steps <= f.count {
                for _ in 0 ..< steps { x = f[x] }
                return x
            }
            // Brent's algorithm on the array: the cycle length, then the tail length.
            var power = 1, cycleLength = 1
            var tortoise = vertex, hare = f[vertex]
            while tortoise != hare {
                if power == cycleLength {
                    tortoise = hare
                    power &*= 2
                    cycleLength = 0
                }
                hare = f[hare]
                cycleLength &+= 1
            }
            tortoise = vertex
            hare = vertex
            for _ in 0 ..< cycleLength { hare = f[hare] }
            var tailLength = 0
            while tortoise != hare {
                tortoise = f[tortoise]
                hare = f[hare]
                tailLength &+= 1
            }
            // steps > n >= tailLength.
            for _ in 0 ..< (steps - tailLength) % cycleLength { tortoise = f[tortoise] }
            return tortoise
        }
    }
}
