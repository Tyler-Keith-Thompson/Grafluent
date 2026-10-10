import GraphProtocols
import Walks

// Index space for every entry point: vertex numbers are positions in `vertices` (the vertex
// indices when the graph has them), undirected edge numbers are offsets in `edges` (the edge
// indices when it has them), and a directed edge's number is its slot in the out-rows, which is
// its position in `edges` on a compressed sparse row.

/// The vertices by number and each one's number, for a graph without vertex indices; empty for
/// one with them.
@frozen
@usableFromInline
struct _TourNumbering<Vertex: Hashable> {
    @usableFromInline let listed: [Vertex]
    @usableFromInline let numbers: [Vertex: Int]
    @usableFromInline let isIndexed: Bool

    @inlinable
    init(listed: [Vertex], numbers: [Vertex: Int], isIndexed: Bool) {
        self.listed = listed
        self.numbers = numbers
        self.isIndexed = isIndexed
    }
}

extension Graph {
    @inlinable
    func _tourNumbering() -> _TourNumbering<Vertex> {
        guard let (listed, numbers) = _vertexNumbering() else { return _TourNumbering(listed: [], numbers: [:], isIndexed: true) }
        return _TourNumbering(listed: listed, numbers: numbers, isIndexed: false)
    }

    /// The number of `vertex`, trapping with `message` when it is not a vertex.
    @inlinable
    func _tourNumber(of vertex: Vertex, _ numbering: _TourNumbering<Vertex>, _ message: @autoclosure () -> String) -> Int {
        if numbering.isIndexed {
            precondition(contains(vertex), message())
            return vertexIndex(of: vertex)
        }
        guard let v = numbering.numbers[vertex] else { preconditionFailure(message()) }
        return v
    }

    @inlinable
    func _tourVertices(_ numbers: some Sequence<Int>, _ numbering: _TourNumbering<Vertex>) -> [Vertex] {
        numbering.isIndexed ? numbers.map { vertex(atIndex: $0) } : numbers.map { numbering.listed[$0] }
    }

    /// The positions of edges given by number: arithmetic when the positions are a range of
    /// integers, otherwise one walk of `edges.indices`.
    @inlinable
    func _tourPositions(_ numbers: [Int]) -> [Edges.Index] {
        if Edges.Index.self == Int.self, let range = edges.indices as? Range<Int> {
            let base = range.lowerBound
            return numbers.map { unsafeBitCast(base &+ $0, to: Edges.Index.self) }
        }
        let all = Array(edges.indices)
        return numbers.map { all[$0] }
    }
}

/// A directed graph's out-rows in index space, copied unless the representation lends its own
/// (compressed sparse row, where slot `k` is the edge at position `k`). `positions[k]` is slot
/// `k`'s edge position when copied with positions.
@frozen
@usableFromInline
struct _DirectedTourRows<G: DirectedGraph> {
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]
    @usableFromInline var positions: [G.Edges.Index]
    /// Whether the rows are the graph's own (`_withSuccessorIndexRows`), not copied.
    @usableFromInline let isLent: Bool
    @usableFromInline let count: Int
    @usableFromInline let listed: [G.Vertex]
    @usableFromInline let numbers: [G.Vertex: Int]
    @usableFromInline let isIndexed: Bool

    @inlinable
    init(offsets: [Int], targets: [Int], positions: [G.Edges.Index], isLent: Bool, count: Int, listed: [G.Vertex], numbers: [G.Vertex: Int], isIndexed: Bool) {
        self.offsets = offsets
        self.targets = targets
        self.positions = positions
        self.isLent = isLent
        self.count = count
        self.listed = listed
        self.numbers = numbers
        self.isIndexed = isIndexed
    }
}

extension DirectedGraph {
    /// The out-rows: the graph's own when it lends them, otherwise `successorIndices` (or
    /// `outEdges` through a numbering, without vertex indices) copied once, with each slot's
    /// position when `positions`.
    @inlinable
    func _directedTourRows(positions withPositions: Bool) -> _DirectedTourRows<Self> {
        if let n = vertexIndexBound {
            if Edges.Index.self == Int.self, _withSuccessorIndexRows({ _, _ in () }) != nil {
                return _DirectedTourRows(offsets: [], targets: [], positions: [], isLent: true, count: n, listed: [], numbers: [:], isIndexed: true)
            }
            var offsets = [Int](repeating: 0, count: n + 1)
            var targets: [Int] = []
            var positions: [Edges.Index] = []
            targets.reserveCapacity(edgeCount)
            if withPositions { positions.reserveCapacity(edgeCount) }
            for v in 0 ..< n {
                for w in successorIndices(ofIndex: v) {
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                    targets.append(w)
                }
                if withPositions {
                    for e in outEdges(ofIndex: v) { positions.append(e) }
                    precondition(positions.count == targets.count, "successorIndices and outEdges differ in length")
                }
                offsets[v + 1] = targets.count
            }
            return _DirectedTourRows(offsets: offsets, targets: targets, positions: positions, isLent: false, count: n, listed: [], numbers: [:], isIndexed: true)
        }
        let listed = Array(vertices)
        var numbers: [Vertex: Int] = [:]
        numbers.reserveCapacity(listed.count)
        for (i, v) in listed.enumerated() { numbers[v] = i }
        var offsets = [Int](repeating: 0, count: listed.count + 1)
        var targets: [Int] = []
        var positions: [Edges.Index] = []
        targets.reserveCapacity(edgeCount)
        for (i, v) in listed.enumerated() {
            for e in outEdges(of: v) {
                targets.append(numbers[target(ofEdgeAt: e)]!)
                if withPositions { positions.append(e) }
            }
            offsets[i + 1] = targets.count
        }
        return _DirectedTourRows(offsets: offsets, targets: targets, positions: positions, isLent: false, count: listed.count, listed: listed, numbers: numbers, isIndexed: false)
    }

    /// Calls `body` with the rows as buffers.
    @inlinable
    func _withTourRows<R>(_ rows: _DirectedTourRows<Self>, _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> R) -> R {
        if rows.isLent, let result = _withSuccessorIndexRows(body) { return result }
        return rows.offsets.withUnsafeBufferPointer { offsets in
            rows.targets.withUnsafeBufferPointer { targets in body(offsets, targets) }
        }
    }

    /// The number of `vertex`, trapping with `message` when it is not a vertex.
    @inlinable
    func _tourNumber(of vertex: Vertex, _ rows: _DirectedTourRows<Self>, _ message: @autoclosure () -> String) -> Int {
        if rows.isIndexed {
            precondition(contains(vertex), message())
            return vertexIndex(of: vertex)
        }
        guard let v = rows.numbers[vertex] else { preconditionFailure(message()) }
        return v
    }

    @inlinable
    func _tourVertices(_ numbers: some Sequence<Int>, _ rows: _DirectedTourRows<Self>) -> [Vertex] {
        rows.isIndexed ? numbers.map { vertex(atIndex: $0) } : numbers.map { rows.listed[$0] }
    }

    /// The positions of these slots.
    @inlinable
    func _tourPositions(_ slots: [Int], _ rows: _DirectedTourRows<Self>) -> [Edges.Index] {
        rows.isLent ? slots.map { unsafeBitCast($0, to: Edges.Index.self) } : slots.map { rows.positions[$0] }
    }
}
