#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
#if canImport(math_h)
import math_h
#endif
import GraphProtocols

extension Graph {
    /// The vertices on concentric circles, one per shell: shell k of s (from 0) on the circle of
    /// radius (k + 1) · `radius` / s about `center`, or k · `radius` / s when the first shell holds
    /// a single vertex (which then sits at the centre). The j-th vertex of a shell of size c is at
    /// angle 2πj/c + (k + 1) · `rotation`, counterclockwise from the positive x axis, so each shell
    /// starts `rotation` further round than the one inside it. A graph of one vertex has it at
    /// `center`. Edges are not read. A directed graph is drawn through `undirectedView`.
    ///
    /// - Parameters:
    ///   - shells: the vertices of each shell, innermost first; nil (the default) puts every
    ///     vertex, in `vertices` order, on one circle of radius `radius`.
    ///   - rotation: the angle between the starts of consecutive shells; nil (the default) is
    ///     π / s.
    ///   - radius: the outermost radius when the first shell has more than one vertex.
    ///   - center: the centre of the circles.
    /// - Returns: the drawing, in `vertices` order.
    ///
    /// O(n) time, and O(n) hashing for a graph without vertex indices.
    ///
    /// - Precondition: every vertex of the graph is in exactly one shell, and every vertex of a
    ///   shell is a vertex of the graph; `rotation` is finite; `radius` is finite and not
    ///   negative; `center` is finite.
    @inlinable
    public func shellLayout(shells: [[Vertex]]? = nil, rotation: Double? = nil, radius: Double = 1, center: SIMD2<Double> = .zero) -> Drawing<Vertex> {
        precondition(radius.isFinite && radius >= 0, "The radius must be finite and not negative")
        precondition(center.x.isFinite && center.y.isFinite, "The centre must be finite")
        if let rotation { precondition(rotation.isFinite, "The rotation must be finite") }
        let offsets = _VertexOffsets(self)
        let n = offsets.vertices.count
        var positions = [SIMD2<Double>](repeating: center, count: n)
        guard let shells else {
            if n > 1 {
                let first = rotation ?? Double.pi
                let step = 2 * Double.pi / Double(n)
                for i in 0 ..< n {
                    let angle = Double(i) * step + first
                    positions[i] = center + radius * SIMD2(cos(angle), sin(angle))
                }
            }
            return offsets.drawing(positions)
        }
        var placed = [Bool](repeating: false, count: n)
        var count = 0
        let bump = radius / Double(Swift.max(shells.count, 1))
        let turn = rotation ?? Double.pi / Double(Swift.max(shells.count, 1))
        var r = shells.first?.count == 1 ? 0 : bump
        var first = turn
        for shell in shells {
            let step = 2 * Double.pi / Double(Swift.max(shell.count, 1))
            for (j, v) in shell.enumerated() {
                let i = offsets.offset(of: v)
                precondition(!placed[i], "\(v) is in more than one shell")
                placed[i] = true
                count += 1
                let angle = Double(j) * step + first
                if n > 1 { positions[i] = center + r * SIMD2(cos(angle), sin(angle)) }
            }
            r += bump
            first += turn
        }
        precondition(count == n, "Every vertex must be in a shell")
        return offsets.drawing(positions)
    }

    /// The vertices along a spiral from the origin, in `vertices` order.
    ///
    /// By default vertex i is at i · (cos ri, sin ri), r the `resolution`: equal angles between
    /// consecutive vertices, at growing distances. With `equidistant`, consecutive vertices are an
    /// arc of length about 1 apart along the Archimedean spiral ρ = θ/2: θ starts at r + 2/r, and for each vertex in
    /// turn ρ = θ / 2, θ grows by 1/ρ, and the vertex is at ρ · (cos θ, sin θ). A graph of one
    /// vertex has it at the origin. The drawing is not rescaled (`rescaled(scale:center:)` maps it to a common
    /// frame). Edges are not read. A directed graph is drawn through `undirectedView`.
    ///
    /// - Parameters:
    ///   - resolution: the angle step, or the spiral's starting angle with `equidistant`; smaller
    ///     values draw a tighter spiral.
    ///   - equidistant: whether consecutive vertices are equally far apart.
    /// - Returns: the drawing, in `vertices` order.
    ///
    /// O(n) time.
    ///
    /// - Precondition: `resolution` is finite, and positive when `equidistant`.
    @inlinable
    public func spiralLayout(resolution: Double = 0.35, equidistant: Bool = false) -> Drawing<Vertex> {
        precondition(resolution.isFinite && (!equidistant || resolution > 0), equidistant ? "The resolution must be positive and finite" : "The resolution must be finite")
        let offsets = _VertexOffsets(self)
        return offsets.drawing(_spiralPositions(offsets.vertices.count, resolution: resolution, equidistant: equidistant))
    }

    /// The vertices at independent uniform points of [0, 1)², drawn from `generator`: x then y for
    /// each vertex in `vertices` order, each the top 53 bits of one `next()`, 2n draws in all.
    /// Edges are not read. A directed graph is drawn through `undirectedView`.
    ///
    /// - Returns: the drawing, in `vertices` order.
    ///
    /// O(n) time.
    @inlinable
    public func randomLayout(using generator: inout some RandomNumberGenerator) -> Drawing<Vertex> {
        let offsets = _VertexOffsets(self)
        var positions: [SIMD2<Double>] = []
        positions.reserveCapacity(offsets.vertices.count)
        for _ in 0 ..< offsets.vertices.count {
            let x = Double(generator.next() >> 11) * 0x1p-53
            let y = Double(generator.next() >> 11) * 0x1p-53
            positions.append(SIMD2(x, y))
        }
        return offsets.drawing(positions)
    }

    /// The random drawing from the system's random number generator; see
    /// `randomLayout(using:)`.
    @inlinable
    public func randomLayout() -> Drawing<Vertex> {
        var generator = SystemRandomNumberGenerator()
        return randomLayout(using: &generator)
    }
}

/// `n` points along the spiral of `Graph.spiralLayout(resolution:equidistant:)`.
@usableFromInline
func _spiralPositions(_ n: Int, resolution: Double, equidistant: Bool) -> [SIMD2<Double>] {
    var positions: [SIMD2<Double>] = []
    positions.reserveCapacity(n)
    if n == 1 { return [.zero] }
    if equidistant {
        var theta = resolution
        theta += 1 / (0.5 * theta)
        for _ in 0 ..< n {
            let rho = 0.5 * theta
            theta += 1 / rho
            positions.append(SIMD2(cos(theta) * rho, sin(theta) * rho))
        }
    } else {
        for i in 0 ..< n {
            let distance = Double(i), angle = resolution * distance
            positions.append(SIMD2(distance * cos(angle), distance * sin(angle)))
        }
    }
    return positions
}
