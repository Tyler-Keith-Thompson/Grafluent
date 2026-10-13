#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
// A swift.org toolchain reading a newer macOS SDK (the fuzz build) gets a Darwin without libm's
// functions; the SDK's math module has them.
#if canImport(math_h)
import math_h
#endif
import GraphProtocols

extension Graph {
    /// The vertices evenly spaced on a circle, in `vertices` order counterclockwise from the
    /// positive x axis: vertex `i` of `n` at `center + radius · (cos 2πi/n, sin 2πi/n)`. A single
    /// vertex is at `center`. Edges are not read. A directed graph is drawn through
    /// `undirectedView`.
    ///
    /// O(n) time.
    ///
    /// - Precondition: `radius` is finite and not negative, and `center` is finite.
    @inlinable
    public func circularLayout(radius: Double = 1, center: SIMD2<Double> = .zero) -> Drawing<Vertex> {
        precondition(radius.isFinite && radius >= 0, "The radius must be finite and not negative")
        precondition(center.x.isFinite && center.y.isFinite, "The centre must be finite")
        let listed = ContiguousArray(vertices)
        return Drawing(_vertices: listed, positions: _circlePositions(listed.count, radius: radius, center: center))
    }
}

/// `n` points evenly spaced on a circle, the first on the positive x axis; one point at `center`.
@usableFromInline
func _circlePositions(_ n: Int, radius: Double, center: SIMD2<Double>) -> [SIMD2<Double>] {
    if n == 1 { return [center] }
    var positions: [SIMD2<Double>] = []
    positions.reserveCapacity(n)
    let step = 2 * Double.pi / Double(n)
    for i in 0 ..< n {
        let angle = step * Double(i)
        positions.append(center + radius * SIMD2(cos(angle), sin(angle)))
    }
    return positions
}
