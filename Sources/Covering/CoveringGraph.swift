import GraphProtocols

/// The simple graph underlying an undirected graph, in index space, for the covering problems:
/// each vertex's distinct other neighbors in first-appearance row order (self-loops and parallel
/// copies dropped) as flat rows, and which vertices have a self-loop.
@frozen
@usableFromInline
struct _CoveringGraph: Sendable {
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbors: [Int]
    @usableFromInline var hasLoop: [Bool]

    @inlinable
    init(offsets: [Int], neighbors: [Int], hasLoop: [Bool]) {
        self.offsets = offsets
        self.neighbors = neighbors
        self.hasLoop = hasLoop
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    @inlinable
    func degree(_ v: Int) -> Int { offsets[v + 1] - offsets[v] }
}

/// Copies the rows once, dropping loops (recorded) and repeats with a stamp per vertex.
@frozen
@usableFromInline
struct _CopyCoveringGraph: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _CoveringGraph {
        var offsets = [Int](repeating: 0, count: n + 1)
        var neighbors: [Int] = []
        neighbors.reserveCapacity(2 * edgeCount)
        var hasLoop = [Bool](repeating: false, count: n)
        var stamp = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w == v {
                    hasLoop[v] = true
                    continue
                }
                if stamp[w] == v { continue }
                stamp[w] = v
                neighbors.append(w)
            }
            offsets[v + 1] = neighbors.count
        }
        return _CoveringGraph(offsets: offsets, neighbors: neighbors, hasLoop: hasLoop)
    }
}

extension Graph {
    @inlinable
    func _coveringGraph() -> _CoveringGraph { _runOnUndirectedRows(_CopyCoveringGraph()) }

    /// The vertices with these numbers (ascending numbers give `vertices` order).
    @inlinable
    func _coveringVertices(_ numbers: [Int], _ listed: [Vertex]?) -> [Vertex] {
        numbers.map { _vertex(number: $0, listed) }
    }

    /// The vertices whose flag is set, in `vertices` order.
    @inlinable
    func _coveringVertices(flagged: [Bool], _ listed: [Vertex]?) -> [Vertex] {
        var result: [Vertex] = []
        for v in flagged.indices where flagged[v] { result.append(_vertex(number: v, listed)) }
        return result
    }

    /// A membership flag per vertex number for `vertices` (repeats ignored).
    ///
    /// - Precondition: every element is a vertex of the graph.
    @inlinable
    func _coveringFlags(_ vertices: some Sequence<Vertex>, _ listed: [Vertex]?) -> [Bool] {
        var flags = [Bool](repeating: false, count: vertexCount)
        if let listed {
            var numbers: [Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            for v in vertices {
                guard let i = numbers[v] else { preconditionFailure("\(v) is not a vertex of the graph") }
                flags[i] = true
            }
        } else {
            for v in vertices {
                precondition(contains(v), "\(v) is not a vertex of the graph")
                flags[vertexIndex(of: v)] = true
            }
        }
        return flags
    }
}
