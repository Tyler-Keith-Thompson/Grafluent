import GraphProtocols

/// A graph's edges in index space, by edge number (the edge's offset in `edges`, its edge index
/// when it has one): each edge's ends by vertex number (`vertices` order). An undirected edge's
/// `tail` is its stored `u`. Self-loops are kept, so edge numbers stay dense.
@frozen
@usableFromInline
struct _FlowEdges {
    @usableFromInline let vertexCount: Int
    @usableFromInline var tail: [Int32]
    @usableFromInline var head: [Int32]
    @usableFromInline let directed: Bool

    @inlinable
    init(vertexCount: Int, tail: [Int32], head: [Int32], directed: Bool) {
        self.vertexCount = vertexCount
        self.tail = tail
        self.head = head
        self.directed = directed
    }

    @inlinable
    var edgeCount: Int { tail.count }

    @inlinable
    func isLoop(_ e: Int) -> Bool { tail[e] == head[e] }
}

/// Vertex numbers for a graph: its vertex indices, or positions in `vertices` with a lookup
/// table when it has none.
@frozen
@usableFromInline
struct _FlowVertices<Vertex: Hashable> {
    /// The vertices by number when the graph has no vertex indices; nil when it has them.
    @usableFromInline let listed: [Vertex]?
    @usableFromInline let numbers: [Vertex: Int]

    @inlinable
    init(listed: [Vertex]?) {
        self.listed = listed
        var numbers: [Vertex: Int] = [:]
        if let listed {
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
        }
        self.numbers = numbers
    }
}

extension DirectedGraph {
    /// Each edge's ends by number, read from the rows in index space (no hashing with vertex
    /// indices), and the vertex numbering.
    @inlinable
    func _flowEdges() -> (edges: _FlowEdges, vertices: _FlowVertices<Vertex>) {
        let m = edgeCount
        precondition(m < Int(Int32.max) / 2, "Flows need fewer than 2³⁰ edges")
        var tail = [Int32](repeating: -1, count: m)
        var head = [Int32](repeating: -1, count: m)
        if let n = vertexIndexBound {
            precondition(n < Int(Int32.max), "Flows need fewer than 2³¹ vertices")
            let vertices = _FlowVertices<Vertex>(listed: nil)
            if Edges.Index.self == Int.self, _withSuccessorIndexRows({ offsets, targets in
                precondition(offsets.count == n + 1 && targets.count == m, "The rows do not match the edges")
                for v in 0 ..< n {
                    for slot in offsets[v] ..< offsets[v + 1] {
                        let w = targets[slot]
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        tail[slot] = Int32(truncatingIfNeeded: v)
                        head[slot] = Int32(truncatingIfNeeded: w)
                    }
                }
                return true
            }) == true {
                return (_FlowEdges(vertexCount: n, tail: tail, head: head, directed: true), vertices)
            }
            let indexed = edgeIndexBound != nil
            let numbers = indexed ? [:] : _flowEdgeNumbers()
            tail.withUnsafeMutableBufferPointer { tail in
                head.withUnsafeMutableBufferPointer { head in
                    for v in 0 ..< n {
                        var successors = successorIndices(ofIndex: v).makeIterator()
                        for position in outEdges(ofIndex: v) {
                            guard let w = successors.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                            let e = indexed ? edgeIndex(of: position) : numbers[position]!
                            precondition(UInt(bitPattern: e) < UInt(bitPattern: m) && tail[e] < 0, "An edge is listed twice in the rows")
                            tail[e] = Int32(truncatingIfNeeded: v)
                            head[e] = Int32(truncatingIfNeeded: w)
                        }
                        precondition(successors.next() == nil, "successorIndices and outEdges differ in length")
                    }
                }
            }
            return (_FlowEdges(vertexCount: n, tail: tail, head: head, directed: true), vertices)
        }
        let vertices = _FlowVertices(listed: Array(self.vertices))
        let listed = vertices.listed!
        precondition(listed.count < Int(Int32.max), "Flows need fewer than 2³¹ vertices")
        let indexed = edgeIndexBound != nil
        let numbers = indexed ? [:] : _flowEdgeNumbers()
        for (v, vertex) in listed.enumerated() {
            for position in outEdges(of: vertex) {
                let e = indexed ? edgeIndex(of: position) : numbers[position]!
                tail[e] = Int32(truncatingIfNeeded: v)
                head[e] = Int32(truncatingIfNeeded: vertices.numbers[target(ofEdgeAt: position)]!)
            }
        }
        return (_FlowEdges(vertexCount: listed.count, tail: tail, head: head, directed: true), vertices)
    }

    /// Each edge position's offset in `edges`.
    @inlinable
    func _flowEdgeNumbers() -> [Edges.Index: Int] {
        var numbers: [Edges.Index: Int] = [:]
        numbers.reserveCapacity(edgeCount)
        for (k, position) in edges.indices.enumerated() { numbers[position] = k }
        return numbers
    }

    /// The number of `vertex`, trapping when it is not a vertex.
    @inlinable
    func _flowNumber(of vertex: Vertex, _ vertices: _FlowVertices<Vertex>) -> Int {
        if vertices.listed != nil {
            guard let v = vertices.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return v
        }
        precondition(contains(vertex), "\(vertex) is not a vertex of the graph")
        return vertexIndex(of: vertex)
    }

    /// Every vertex by number.
    @inlinable
    func _flowListed(_ vertices: _FlowVertices<Vertex>) -> [Vertex] {
        vertices.listed ?? (0 ..< vertexIndexBound!).map { vertex(atIndex: $0) }
    }
}

/// Each undirected edge's two ends by number, the end met first in the rows first.
@frozen
@usableFromInline
struct _CopyFlowEnds: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> (tail: [Int32], head: [Int32]) {
        var tail = [Int32](repeating: -1, count: m), head = [Int32](repeating: -1, count: m)
        var ends = [UInt8](repeating: 0, count: m)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k), e = rows.edge(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n) && UInt(bitPattern: e) < UInt(bitPattern: m), "A neighbor or edge index is out of range")
                if tail[e] < 0 {
                    tail[e] = Int32(truncatingIfNeeded: v)
                    head[e] = Int32(truncatingIfNeeded: w)
                }
                ends[e] &+= 1
            }
        }
        precondition(ends.allSatisfy { $0 == 2 }, "An edge does not have exactly two ends in the incidence rows")
        return (tail, head)
    }
}

extension Graph {
    /// Each edge's ends by number, its stored `u` first, and the vertex numbering.
    @inlinable
    func _flowEdges() -> (edges: _FlowEdges, vertices: _FlowVertices<Vertex>) {
        let m = edgeCount
        precondition(m < Int(Int32.max) / 2, "Flows need fewer than 2³⁰ edges")
        let numbering = _vertexNumbering()
        let n = vertexIndexBound ?? numbering!.listed.count
        precondition(n < Int(Int32.max), "Flows need fewer than 2³¹ vertices")
        var (tail, head) = _runOnUndirectedRows(_CopyFlowEnds(), vertexNumbering: numbering)
        let listed = numbering?.listed
        // Orient each edge as stored: the rows give its ends, not which one is `u`.
        var e = 0
        for position in edges.indices {
            if tail[e] != head[e] && edges[position].u != _vertex(number: Int(tail[e]), listed) {
                swap(&tail[e], &head[e])
            }
            e += 1
        }
        var vertices = _FlowVertices<Vertex>(listed: nil)
        if let numbering { vertices = _FlowVertices(listed: numbering.listed) }
        return (_FlowEdges(vertexCount: n, tail: tail, head: head, directed: false), vertices)
    }

    /// The number of `vertex`, trapping when it is not a vertex.
    @inlinable
    func _flowNumber(of vertex: Vertex, _ vertices: _FlowVertices<Vertex>) -> Int {
        if vertices.listed != nil {
            guard let v = vertices.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return v
        }
        precondition(contains(vertex), "\(vertex) is not a vertex of the graph")
        return vertexIndex(of: vertex)
    }

    /// Every vertex by number.
    @inlinable
    func _flowListed(_ vertices: _FlowVertices<Vertex>) -> [Vertex] {
        vertices.listed ?? (0 ..< vertexIndexBound!).map { vertex(atIndex: $0) }
    }
}

/// Reads one capacity per non-loop edge, in position order, checking each: at least zero, not
/// NaN, finite (`c - c == 0` holds for every finite value and fails for infinities and NaN, and
/// never overflows). Loops get zero.
@inlinable
func _readCapacities<C: Comparable & AdditiveArithmetic, Positions: Collection>(
    _ edges: _FlowEdges, _ positions: Positions, _ capacity: (Positions.Element) -> C
) -> [C] {
    var capacities = [C](repeating: .zero, count: edges.edgeCount)
    var e = 0
    for position in positions {
        if edges.tail[e] != edges.head[e] {
            let c = capacity(position)
            precondition(c == c, "A capacity is NaN")
            precondition(c >= .zero, "A capacity is negative")
            precondition(c - c == .zero, "A capacity is infinite")
            capacities[e] = c
        }
        e += 1
    }
    return capacities
}

/// `a + b`, and whether it overflowed: integers through `addingReportingOverflow`, floating
/// point by the result being infinite.
@inlinable
func _addingReportingOverflow<C: AdditiveArithmetic>(_ a: C, _ b: C) -> (partialValue: C, overflow: Bool) {
    if let x = a as? any FixedWidthInteger {
        return _fixedWidthAdd(x, b)
    }
    let sum = a + b
    return (sum, sum - sum != .zero)
}

@inlinable
func _fixedWidthAdd<T: FixedWidthInteger, C>(_ x: T, _ b: C) -> (partialValue: C, overflow: Bool) {
    let (sum, overflow) = x.addingReportingOverflow(b as! T)
    return (sum as! C, overflow)
}

extension _FlowEdges: Sendable {}
extension _FlowVertices: Sendable where Vertex: Sendable {}
