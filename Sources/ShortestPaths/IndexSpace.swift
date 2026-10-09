import GraphProtocols

/// The out-edges of a vertex in index space, as (target index, edge position) pairs: what every
/// engine in this module walks. Three sources, chosen once per run by `_runInIndexSpace`.
@usableFromInline
protocol _IndexSpaceAlgorithm {
    associatedtype G: DirectedGraph
    associatedtype W
    associatedtype Output

    /// Runs over `count` vertex indices; `arcs(u)` lists the out-edges of index `u`, and `weight`
    /// weighs an edge. The closures are parameters, not stored, so they inline into the loop.
    func run<Arcs: IteratorProtocol>(count: Int, _ arcs: (Int) -> Arcs, _ weight: (G.Edges.Index) -> W) -> Output where Arcs.Element == (Int, G.Edges.Index)
}

/// A row of `_withSuccessorIndexRows`, where slot `k` is the edge at position `k`.
@frozen
@usableFromInline
struct _RowArcs<Index>: IteratorProtocol {
    @usableFromInline var position: Int
    @usableFromInline let end: Int
    @usableFromInline let targets: UnsafePointer<Int>

    @inlinable
    @inline(__always)
    init(row: Int, offsets: UnsafeBufferPointer<Int>, targets: UnsafeBufferPointer<Int>) {
        position = offsets[row]
        end = offsets[row + 1]
        // A placeholder when there are no edges at all; never read.
        self.targets = targets.baseAddress ?? UnsafePointer(bitPattern: MemoryLayout<Int>.alignment)!
    }

    @inlinable
    @inline(__always)
    mutating func next() -> (Int, Index)? {
        guard position < end else { return nil }
        defer { position += 1 }
        // `Index` is `Int` here: checked once, in `_runInIndexSpace`.
        return (targets[position], unsafeBitCast(position, to: Index.self))
    }
}

/// The out-edges of a graph without vertex indices, through a dictionary built once.
@frozen
@usableFromInline
struct _LookupArcs<G: DirectedGraph>: IteratorProtocol {
    @usableFromInline let graph: G
    @usableFromInline let identifiers: [G.Vertex: Int]
    @usableFromInline var edges: G.OutEdges.Iterator

    @inlinable
    init(graph: G, identifiers: [G.Vertex: Int], vertex: G.Vertex) {
        self.graph = graph
        self.identifiers = identifiers
        self.edges = graph.outEdges(of: vertex).makeIterator()
    }

    @inlinable
    mutating func next() -> (Int, G.Edges.Index)? {
        guard let e = edges.next() else { return nil }
        return (identifiers[graph.target(ofEdgeAt: e)]!, e)
    }
}

extension DirectedGraph {
    /// The vertices numbered in `vertices` order: their indices when the graph has them (law
    /// L27), otherwise numbers handed out here, all at once, so engines only read the mapping.
    @inlinable
    func _numberedVertices() -> _VertexIdentifiers<Self> {
        var ids = _VertexIdentifiers(self)
        if !ids.isIndexed {
            for v in vertices { _ = ids.identifier(of: v) }
        }
        return ids
    }

    /// Runs `algorithm` over the cheapest out-edge source the graph offers: its rows (compressed
    /// sparse row), its index-space rows, or a lookup per edge.
    @inlinable
    @inline(__always)
    func _runInIndexSpace<A: _IndexSpaceAlgorithm>(_ algorithm: A, _ ids: _VertexIdentifiers<Self>, weight: (Edges.Index) -> A.W) -> A.Output where A.G == Self {
        let n = ids.count
        if ids.isIndexed {
            if Edges.Index.self == Int.self, let output = _withSuccessorIndexRows({ offsets, targets in
                algorithm.run(count: n, { _RowArcs<Edges.Index>(row: $0, offsets: offsets, targets: targets) }, weight)
            }) {
                return output
            }
            return algorithm.run(count: n, { zip(successorIndices(ofIndex: $0), outEdges(ofIndex: $0)).makeIterator() }, weight)
        }
        let identifiers = ids.identifiers, vertices = ids.vertices
        return algorithm.run(count: n, { _LookupArcs(graph: self, identifiers: identifiers, vertex: vertices[$0]) }, weight)
    }

    /// The index of `vertex`, trapping when it is not a vertex.
    @inlinable
    func _index(of vertex: Vertex, _ ids: _VertexIdentifiers<Self>) -> Int {
        if ids.isIndexed {
            precondition(contains(vertex), "\(vertex) is not a vertex of the graph")
            return vertexIndex(of: vertex)
        }
        guard let id = ids.identifiers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return id
    }
}
