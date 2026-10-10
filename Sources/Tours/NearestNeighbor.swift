import GraphProtocols
import Walks

/// The nearest-neighbour order from `start`: repeatedly the nearest unvisited vertex, the first
/// in vertex order on ties. O(n²).
@inlinable
func _nearestNeighborOrder<W>(_ matrix: _TourMatrix<W>, from start: Int) -> [Int] {
    let n = matrix.n
    var order = [Int](repeating: 0, count: n)
    // The unvisited vertices in vertex order, compacted as each one leaves, so ties stay first.
    var unvisited = [Int](repeating: 0, count: n - 1)
    for v in 0 ..< n where v != start { unvisited[v < start ? v : v - 1] = v }
    order[0] = start
    matrix.weights.withUnsafeBufferPointer { d in
        unvisited.withUnsafeMutableBufferPointer { unvisited in
            order.withUnsafeMutableBufferPointer { order in
                var current = start, left = n - 1
                for step in 1 ..< n {
                    let row = current * n
                    var best = 0
                    var nearest = d[row + unvisited[0]]
                    for k in 1 ..< left {
                        let w = d[row + unvisited[k]]
                        if w < nearest {
                            nearest = w
                            best = k
                        }
                    }
                    current = unvisited[best]
                    order[step] = current
                    left -= 1
                    for k in best ..< left { unvisited[k] = unvisited[k + 1] }
                }
            }
        }
    }
    return order
}

extension Graph {
    @inlinable
    func _nearestNeighborTour<W: Comparable & AdditiveArithmetic>(from start: Vertex?, _ weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        let s = start.map { _tourNumber(of: $0, numbering, "\($0) is not a vertex of the graph") } ?? 0
        let matrix = _completeTourMatrix(weight, numbering)
        return _tourCycle(_nearestNeighborOrder(matrix, from: s), matrix, numbering)
    }

    /// The nearest-neighbour tour from the first vertex (NetworkX `greedy_tsp`, JGraphT
    /// `NearestNeighborHeuristicTSP(first)`, whose default starts at a random vertex): repeatedly
    /// the nearest unvisited vertex, the first in `vertices` order on ties, then back to the
    /// start. LEMON's `NearestNeighborTsp` shares the name only: it starts from the lightest edge
    /// and grows the path at both ends, a different procedure and tour.
    ///
    /// Tours read the simple graph: self-loops are ignored, and each pair of vertices is joined by
    /// its lightest edge (the earliest position on ties), which is the edge the returned `Cycle`
    /// uses, so `cycle.weight(weight)` is the tour's length. nil below three vertices, before any
    /// other check. `weight` is called once per non-loop edge, in position order, before any work.
    /// No approximation guarantee in general; within ½(⌈log₂ n⌉ + 1) of the shortest tour when
    /// the weights satisfy the triangle inequality (Rosenkrantz, Stearns and Lewis, "An analysis
    /// of several heuristics for the traveling salesman problem", SIAM Journal on Computing 6,
    /// 1977).
    ///
    /// - Precondition: the graph is complete (every pair of distinct vertices joined); no weight
    ///   is NaN or infinite.
    /// - Complexity: O(n²) after O(n + m) to read the edges and weights.
    @inlinable
    public func nearestNeighborTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        _nearestNeighborTour(from: nil, weight)
    }

    /// The nearest-neighbour tour from `start` (NetworkX `greedy_tsp(G, source=)`, JGraphT
    /// `NearestNeighborHeuristicTSP(first)`), listed from `start`; as `nearestNeighborTour(weight:)`.
    ///
    /// - Precondition: the graph is complete; `start` is a vertex of the graph; no weight is NaN
    ///   or infinite.
    /// - Complexity: O(n²) after O(n + m).
    @inlinable
    public func nearestNeighborTour<W: Comparable & AdditiveArithmetic>(from start: Vertex, weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        _nearestNeighborTour(from: start, weight)
    }
}
