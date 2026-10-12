import GraphProtocols
import Walks

/// Traps on a NaN or infinite weight. w − w is zero for every finite value of a floating-point
/// type (and for every integer), and NaN for NaN and ±∞, so one subtraction tests both without
/// knowing the type: ±∞ would turn sums into ∞ − ∞ = NaN (Held–Karp's table, 2-opt's gains).
@inlinable @inline(__always)
func _checkTourWeight<W: Comparable & AdditiveArithmetic>(_ w: W) {
    if !(w - w == .zero) { preconditionFailure(w == w ? "A weight is infinite" : "A weight is NaN") }
}

/// The simple graph a tour reads, as an n × n matrix: for each pair of distinct vertices the
/// lightest edge joining them (the earliest position on ties), its weight and its edge number
/// (−1 when no edge joins them). Self-loops are ignored.
@frozen
@usableFromInline
struct _TourMatrix<W: Comparable & AdditiveArithmetic> {
    @usableFromInline let n: Int
    @usableFromInline var weights: [W]
    @usableFromInline var edges: [Int]

    @inlinable
    init(n: Int, weights: [W], edges: [Int]) {
        self.n = n
        self.weights = weights
        self.edges = edges
    }

    /// The first pair (in row-major order) that no edge joins, or nil.
    @inlinable
    var missingPair: (Int, Int)? {
        for u in 0 ..< n {
            for v in u + 1 ..< n where edges[u * n + v] < 0 { return (u, v) }
        }
        return nil
    }
}

extension Graph {
    /// The matrix, reading `weight` once per non-loop edge in position order. A NaN or infinite
    /// weight traps (`_checkTourWeight`).
    @inlinable
    func _tourMatrix<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W, _ numbering: _TourNumbering<Vertex>) -> _TourMatrix<W> {
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        let (from, to) = _runOnUndirectedRows(_CopyEdgeEnds(), vertexNumbering: numbering.isIndexed ? nil : (numbering.listed, numbering.numbers))
        var weights = [W](repeating: .zero, count: n * n)
        var edges = [Int](repeating: -1, count: n * n)
        var e = 0
        for position in self.edges.indices {
            let u = from[e], v = to[e]
            if u != v {
                let w = weight(position)
                _checkTourWeight(w)
                let cell = u * n + v
                if edges[cell] < 0 || w < weights[cell] {
                    weights[cell] = w
                    edges[cell] = e
                    weights[v * n + u] = w
                    edges[v * n + u] = e
                }
            }
            e += 1
        }
        return _TourMatrix(n: n, weights: weights, edges: edges)
    }

    /// The matrix of a graph that must be complete: traps on a missing pair.
    @inlinable
    func _completeTourMatrix<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W, _ numbering: _TourNumbering<Vertex>) -> _TourMatrix<W> {
        let matrix = _tourMatrix(weight, numbering)
        if let (u, v) = matrix.missingPair {
            let names = _tourVertices([u, v], numbering)
            preconditionFailure("The graph is not complete (\(names[0]) and \(names[1]) are not adjacent)")
        }
        return matrix
    }

    /// The cycle through `order` over the matrix's edges.
    @inlinable
    func _tourCycle<W>(_ order: [Int], _ matrix: _TourMatrix<W>, _ numbering: _TourNumbering<Vertex>) -> Cycle<Vertex, Edges.Index> {
        let n = order.count
        var numbers = [Int](repeating: 0, count: n)
        for i in 0 ..< n { numbers[i] = matrix.edges[order[i] * matrix.n + order[i + 1 == n ? 0 : i + 1]] }
        return Cycle(_uncheckedVertices: _tourVertices(order, numbering), edges: _tourPositions(numbers))
    }
}

extension DirectedGraph {
    /// The vertices by number and each one's number, for a graph without vertex indices; empty
    /// for one with them (as `Graph._tourNumbering()`).
    @inlinable
    func _directedTourNumbering() -> _TourNumbering<Vertex> {
        guard let (listed, numbers) = _vertexNumbering() else { return _TourNumbering(listed: [], numbers: [:], isIndexed: true) }
        return _TourNumbering(listed: listed, numbers: numbers, isIndexed: false)
    }

    @inlinable
    func _tourVertices(_ numbers: some Sequence<Int>, _ numbering: _TourNumbering<Vertex>) -> [Vertex] {
        numbering.isIndexed ? numbers.map { vertex(atIndex: $0) } : numbers.map { numbering.listed[$0] }
    }

    /// The directed matrix: for each ordered pair (u, v) of distinct vertices the lightest arc
    /// u → v (the earliest position on ties), its weight and its edge number, the offset of its
    /// position in `edges` (−1 when there is none). `weight` is read once per non-loop edge in
    /// position order; a NaN or infinite weight traps.
    @inlinable
    func _directedTourMatrix<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W, _ numbering: _TourNumbering<Vertex>) -> _TourMatrix<W> {
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        var weights = [W](repeating: .zero, count: n * n)
        var edges = [Int](repeating: -1, count: n * n)
        var e = 0
        for position in self.edges.indices {
            let s = source(ofEdgeAt: position), t = target(ofEdgeAt: position)
            let u = numbering.isIndexed ? vertexIndex(of: s) : numbering.numbers[s]!
            let v = numbering.isIndexed ? vertexIndex(of: t) : numbering.numbers[t]!
            precondition(UInt(bitPattern: u) < UInt(bitPattern: n) && UInt(bitPattern: v) < UInt(bitPattern: n), "A vertex index is out of range")
            if u != v {
                let w = weight(position)
                _checkTourWeight(w)
                let cell = u * n + v
                if edges[cell] < 0 || w < weights[cell] {
                    weights[cell] = w
                    edges[cell] = e
                }
            }
            e += 1
        }
        return _TourMatrix(n: n, weights: weights, edges: edges)
    }

    /// The positions of edges given by their offsets in `edges` (as `Graph._tourPositions`).
    @inlinable
    func _tourEdgePositions(_ numbers: [Int]) -> [Edges.Index] {
        if Edges.Index.self == Int.self, let range = edges.indices as? Range<Int> {
            let base = range.lowerBound
            return numbers.map { unsafeBitCast(base &+ $0, to: Edges.Index.self) }
        }
        let all = Array(edges.indices)
        return numbers.map { all[$0] }
    }
}

/// The edge numbers of the closed tour through `order`, each from a vertex to the next.
@inlinable
func _tourArcNumbers<W>(_ order: [Int], _ matrix: _TourMatrix<W>) -> [Int] {
    let n = order.count
    return (0 ..< n).map { matrix.edges[order[$0] * matrix.n + order[$0 + 1 == n ? 0 : $0 + 1]] }
}
