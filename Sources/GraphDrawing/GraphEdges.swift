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
            guard let p = drawing.position(safe: v) else { preconditionFailure("The initial drawing has no position for vertex \(v)") }
            return p
        }
    for p in positions { precondition(p.x.isFinite && p.y.isFinite, "Every initial position must be finite") }
    return positions
}
