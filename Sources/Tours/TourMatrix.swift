import GraphProtocols
import Walks

/// Each edge's two ends by number (the end met first in the rows as `from`), read from the rows.
@frozen
@usableFromInline
struct _EdgeEnds: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> (from: [Int], to: [Int]) {
        var from = [Int](repeating: -1, count: m), to = [Int](repeating: 0, count: m)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let e = rows.edge(v, k)
                precondition(UInt(bitPattern: e) < UInt(bitPattern: m), "An edge index is out of range")
                if from[e] < 0 {
                    let w = rows.neighbor(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    from[e] = v
                    to[e] = w
                }
            }
        }
        return (from, to)
    }
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
    /// The matrix, reading `weight` once per non-loop edge in position order. A NaN weight traps.
    @inlinable
    func _tourMatrix<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W, _ numbering: _TourNumbering<Vertex>) -> _TourMatrix<W> {
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        let (from, to) = _runOnUndirectedRows(_EdgeEnds(), vertexNumbering: numbering.isIndexed ? nil : (numbering.listed, numbering.numbers))
        var weights = [W](repeating: .zero, count: n * n)
        var edges = [Int](repeating: -1, count: n * n)
        var e = 0
        for position in self.edges.indices {
            let u = from[e], v = to[e]
            if u != v {
                let w = weight(position)
                precondition(w == w, "A weight is NaN")
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
