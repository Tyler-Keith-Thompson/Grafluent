import GraphProtocols
import Walks

/// A graph's adjacency in index space, copied into flat arrays the search owns: slot `offsets[v]
/// ..< offsets[v + 1]` of `targets` and `edges` is vertex `v`'s row, in `outEdges` (directed) or
/// `incidentEdges` (undirected) order. Vertex numbers are in `vertices` order. An undirected edge
/// number is the edge's offset in `edges` (its index when the graph has edge indices), so numbers
/// order like positions; a directed edge's number is its slot.
@frozen
@usableFromInline
struct _CycleRows: Sendable {
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]
    @usableFromInline var edges: [Int]
    @usableFromInline let undirected: Bool

    @inlinable
    init(offsets: [Int], targets: [Int], edges: [Int], undirected: Bool) {
        self.offsets = offsets
        self.targets = targets
        self.edges = edges
        self.undirected = undirected
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    /// The vertex each slot leaves.
    @inlinable
    func slotSources() -> [Int] {
        var sources = [Int](repeating: 0, count: targets.count)
        for v in 0 ..< count {
            for slot in offsets[v] ..< offsets[v + 1] { sources[slot] = v }
        }
        return sources
    }

    /// Whether each vertex has a self-loop.
    @inlinable
    func loops() -> [Bool] {
        var loops = [Bool](repeating: false, count: count)
        for v in 0 ..< count {
            for slot in offsets[v] ..< offsets[v + 1] where targets[slot] == v { loops[v] = true }
        }
        return loops
    }
}

/// Copies an undirected graph's rows, whole.
@frozen
@usableFromInline
struct _CopyIncidenceRows: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _CycleRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = []
        var edges: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        edges.reserveCapacity(2 * edgeCount)
        // Every edge has two ends in the rows (a loop both in one row).
        var ends = [UInt8](repeating: 0, count: edgeCount)
        for v in 0 ..< n {
            let d = rows.count(v)
            for k in 0 ..< d {
                let w = rows.neighbor(v, k), e = rows.edge(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n) && UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "A neighbor or edge index is out of range")
                targets.append(w)
                edges.append(e)
                ends[e] &+= 1
            }
            offsets[v + 1] = targets.count
        }
        precondition(ends.allSatisfy { $0 == 2 }, "An edge does not have exactly two ends in the incidence rows")
        return _CycleRows(offsets: offsets, targets: targets, edges: edges, undirected: true)
    }
}

extension Graph {
    /// The rows, the numbering of the vertices, and each edge number's position.
    @inlinable
    func _cycleRows() -> (rows: _CycleRows, positions: [Edges.Index]) {
        (_runOnUndirectedRows(_CopyIncidenceRows()), Array(edges.indices))
    }

    /// The positions of these edge numbers (offsets in `edges`), in the same order: one walk of
    /// `edges.indices` up to the largest, so a collection without random access costs O(m), not
    /// O(m) per edge.
    @inlinable
    func _positions(ofEdgeNumbers numbers: [Int]) -> [Edges.Index] {
        let order = numbers.indices.sorted { numbers[$0] < numbers[$1] }
        var result = [Edges.Index?](repeating: nil, count: numbers.count)
        var index = edges.startIndex, offset = 0
        for k in order {
            while offset < numbers[k] {
                edges.formIndex(after: &index)
                offset += 1
            }
            result[k] = index
        }
        return result.map { $0! }
    }

    /// The cycle with these vertex and edge numbers, already canonical.
    @inlinable
    func _cycle(_ vertexNumbers: [Int], _ edgeNumbers: [Int], _ listed: [Vertex]?, _ positions: [Edges.Index]?) -> Cycle<Vertex, Edges.Index> {
        Cycle(
            _uncheckedVertices: vertexNumbers.map { _vertex(number: $0, listed) },
            edges: positions.map { p in edgeNumbers.map { p[$0] } } ?? _positions(ofEdgeNumbers: edgeNumbers)
        )
    }
}

extension DirectedGraph {
    /// The rows (edge numbers are slots), each slot's position, and the vertices by number when
    /// the graph has no vertex indices.
    @inlinable
    func _cycleRows(withPositions: Bool = true) -> (rows: _CycleRows, positions: [Edges.Index], listed: [Vertex]?) {
        var offsets: [Int] = [0]
        var targets: [Int] = []
        var positions: [Edges.Index] = []
        targets.reserveCapacity(edgeCount)
        positions.reserveCapacity(edgeCount)
        let listed: [Vertex]?
        if let n = vertexIndexBound {
            listed = nil
            offsets.reserveCapacity(n + 1)
            for v in 0 ..< n {
                for w in successorIndices(ofIndex: v) { targets.append(w) }
                var count = 0
                for e in outEdges(ofIndex: v) {
                    if withPositions { positions.append(e) }
                    count += 1
                }
                precondition(targets.count == offsets[v] + count, "successorIndices and outEdges differ in length")
                offsets.append(targets.count)
            }
            for w in targets { precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range") }
        } else {
            let all = Array(vertices)
            listed = all
            var numbers: [Vertex: Int] = [:]
            numbers.reserveCapacity(all.count)
            for (i, v) in all.enumerated() { numbers[v] = i }
            offsets.reserveCapacity(all.count + 1)
            for v in all {
                for e in outEdges(of: v) {
                    targets.append(numbers[target(ofEdgeAt: e)]!)
                    if withPositions { positions.append(e) }
                }
                offsets.append(targets.count)
            }
        }
        return (_CycleRows(offsets: offsets, targets: targets, edges: Array(0 ..< targets.count), undirected: false), positions, listed)
    }

}

/// Rotates a closed sequence of vertex numbers (edge `i` joining vertex `i` and vertex `i + 1`) to
/// start at its least vertex and, when `undirected`, to leave it through the lesser of its two
/// edges there.
@inlinable
func _canonicalCycle(_ vertices: [Int], _ edges: [Int], undirected: Bool) -> (vertices: [Int], edges: [Int]) {
    let n = vertices.count
    var r = 0
    for i in 1 ..< max(n, 1) where vertices[i] < vertices[r] { r = i }
    var vs = [Int](), es = [Int]()
    vs.reserveCapacity(n)
    es.reserveCapacity(n)
    for i in 0 ..< n {
        let j = r + i < n ? r + i : r + i - n
        vs.append(vertices[j])
        es.append(edges[j])
    }
    guard undirected, n >= 2, es[n - 1] < es[0] else { return (vs, es) }
    // The other orientation: v₀, vₙ₋₁, …, v₁ over eₙ₋₁, eₙ₋₂, …, e₀.
    var rv = [vs[0]], re = [Int]()
    rv.reserveCapacity(n)
    re.reserveCapacity(n)
    for i in stride(from: n - 1, through: 1, by: -1) { rv.append(vs[i]) }
    for i in stride(from: n - 1, through: 0, by: -1) { re.append(es[i]) }
    return (rv, re)
}
