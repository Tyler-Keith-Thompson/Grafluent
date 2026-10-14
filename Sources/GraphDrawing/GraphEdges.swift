import GraphProtocols

/// An undirected graph's vertices and non-loop edges in index space, for the force-directed and
/// stress layouts: vertex numbers are `vertices` offsets, and edge `k` joins `us[k]` and `vs[k]`
/// with the value the caller's closure gave its position.
@frozen
@usableFromInline
struct _DrawingEdges<Vertex: Hashable> {
    @usableFromInline var vertices: ContiguousArray<Vertex>
    /// Each vertex's number when the graph has no vertex indices; nil when it has them.
    @usableFromInline var offsets: [Vertex: Int]?
    @usableFromInline var us: [Int]
    @usableFromInline var vs: [Int]
    @usableFromInline var values: [Double]

    @inlinable
    init(vertices: ContiguousArray<Vertex>, offsets: [Vertex: Int]?, us: [Int], vs: [Int], values: [Double]) {
        self.vertices = vertices
        self.offsets = offsets
        self.us = us
        self.vs = vs
        self.values = values
    }

    @inlinable
    var vertexCount: Int { vertices.count }

    /// A drawing of these vertices at `positions`.
    @inlinable
    func drawing(_ positions: [SIMD2<Double>]) -> Drawing<Vertex> {
        Drawing(_vertices: vertices, positions: positions, offsets: offsets)
    }
}

extension Graph {
    /// The vertices and the non-loop edges, each with `value(position)`; `value` is called once
    /// per edge, loops included, in `edges` order.
    @inlinable
    func _drawingEdges(_ value: (Edges.Index) -> Double) -> _DrawingEdges<Vertex> {
        let listed = ContiguousArray(vertices)
        var us: [Int] = [], vs: [Int] = [], values: [Double] = []
        let m = edgeCount
        us.reserveCapacity(m)
        vs.reserveCapacity(m)
        values.reserveCapacity(m)
        if let n = vertexIndexBound {
            for position in edges.indices {
                let x = value(position)
                let (u, v) = endpointIndices(ofEdgeAt: position)
                precondition(UInt(bitPattern: u) < UInt(bitPattern: n) && UInt(bitPattern: v) < UInt(bitPattern: n), "An endpoint index is out of range")
                guard u != v else { continue }
                us.append(u)
                vs.append(v)
                values.append(x)
            }
            return _DrawingEdges(vertices: listed, offsets: nil, us: us, vs: vs, values: values)
        }
        var offsets: [Vertex: Int] = [:]
        offsets.reserveCapacity(listed.count)
        for (i, v) in listed.enumerated() { offsets[v] = i }
        for position in edges.indices {
            let x = value(position)
            let edge = edges[position]
            let u = offsets[edge.u]!, v = offsets[edge.v]!
            guard u != v else { continue }
            us.append(u)
            vs.append(v)
            values.append(x)
        }
        return _DrawingEdges(vertices: listed, offsets: offsets, us: us, vs: vs, values: values)
    }
}

/// The positions of `vertices` in `drawing`, in order.
///
/// - Precondition: every vertex is in the drawing, at a finite position.
@inlinable
func _startPositions<Vertex: Hashable>(_ vertices: ContiguousArray<Vertex>, in drawing: Drawing<Vertex>) -> [SIMD2<Double>] {
    let positions =
        drawing._vertices == vertices
        ? drawing._positions
        : vertices.map { v in
            guard let i = drawing._offset(of: v) else { preconditionFailure("The initial drawing has no position for vertex \(v)") }
            return drawing._positions[i]
        }
    for p in positions { precondition(p.x.isFinite && p.y.isFinite, "Every initial position must be finite") }
    return positions
}

/// A graph's vertices in `vertices` order, with a lookup from a vertex to its offset: its vertex
/// index when the graph has vertex indices, one hash otherwise.
@frozen
@usableFromInline
struct _VertexOffsets<G: Graph> {
    @usableFromInline let graph: G
    @usableFromInline let vertices: ContiguousArray<G.Vertex>
    /// Each vertex's offset when the graph has no vertex indices; nil when it has them.
    @usableFromInline let offsets: [G.Vertex: Int]?

    @inlinable
    init(_ graph: G) {
        self.graph = graph
        vertices = ContiguousArray(graph.vertices)
        if graph.vertexIndexBound != nil {
            offsets = nil
        } else {
            var table: [G.Vertex: Int] = [:]
            table.reserveCapacity(vertices.count)
            for (i, v) in vertices.enumerated() { table[v] = i }
            offsets = table
        }
    }

    /// The offset of `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    func offset(of vertex: G.Vertex) -> Int {
        if let offsets {
            guard let i = offsets[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return i
        }
        precondition(graph.contains(vertex), "\(vertex) is not a vertex of the graph")
        return graph.vertexIndex(of: vertex)
    }

    /// A drawing of these vertices at `positions`.
    @inlinable
    func drawing(_ positions: [SIMD2<Double>]) -> Drawing<G.Vertex> {
        Drawing(_vertices: vertices, positions: positions, offsets: offsets)
    }
}
