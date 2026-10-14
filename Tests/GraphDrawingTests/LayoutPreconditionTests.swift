// Preconditions of the shell, spiral, bipartite, spectral, scaling and ForceAtlas2 layouts: each
// trapping call runs in a child process (exit test); the same setup then answers in this process
// with a valid argument, so the trap is the argument's.

import GrafluentTestSupport
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

@Suite("Layout preconditions", .tags(.precondition))
struct LayoutPreconditionTests {
    @Test("shellLayout: a vertex in two shells, a vertex in none, a vertex not in the graph")
    func shellPartition() async {
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(shells: [[0, 1], [1, 2]])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(shells: [[0, 1]])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(shells: [[0, 1, 2, 3]])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(shells: [])
        }
        // A repeated vertex with the count still n.
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(shells: [[0, 0], [1]])
        }
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(shells: [[0, 1], [2]]).count == 3)
    }

    @Test("shellLayout: negative or infinite radius, infinite rotation, infinite centre")
    func shellParameters() async {
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(radius: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(radius: .infinity)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(rotation: .nan)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(center: SIMD2(.infinity, 0))
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(center: SIMD2(0, .nan))
        }
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).shellLayout(rotation: 0, radius: 0).positions == [.zero, .zero, .zero])
    }

    @Test("spiralLayout: a non-finite resolution; zero with equidistant")
    func spiral() async {
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).spiralLayout(resolution: .infinity)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).spiralLayout(resolution: 0, equidistant: true)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).spiralLayout(resolution: -0.1, equidistant: true)
        }
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).spiralLayout(resolution: 0).positions == [SIMD2(0, 0), SIMD2(1, 0), SIMD2(2, 0)])
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).spiralLayout(resolution: 0.1, equidistant: true).count == 3)
    }

    @Test("bipartiteLayout: a repeated left vertex, a vertex not in the graph, a bad aspect ratio")
    func bipartite() async {
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).bipartiteLayout(left: [0, 0])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).bipartiteLayout(left: [3])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).bipartiteLayout(left: [0], aspectRatio: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).bipartiteLayout(left: [0], aspectRatio: .infinity)
        }
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).bipartiteLayout(left: [0, 2], aspectRatio: 1).count == 3)
    }

    @Test("spectralLayout and multidimensionalScalingLayout: bad weights, lengths and limits")
    func eigen() async {
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).spectralLayout(weight: { _ in -1 })
        }
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).spectralLayout(weight: { _ in .infinity })
        }
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).spectralLayout(maxIterations: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).multidimensionalScalingLayout(edgeLength: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).multidimensionalScalingLayout(edgeLength: { _ in .nan })
        }
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).multidimensionalScalingLayout(maxIterations: 0)
        }
        // A weight of 0 is no edge; a loop's weight is never read into the matrix.
        #expect((try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).spectralLayout(weight: { _ in 0 }, maxIterations: 1000))?.count == 3)
        #expect((try? Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).multidimensionalScalingLayout(edgeLength: { _ in 0.5 }, maxIterations: 1000))?.count == 3)
    }

    @Test("forceAtlas2Layout: bad parameters and weights, an initial drawing missing a vertex or not finite")
    func forceAtlas2() async {
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(iterations: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(scalingRatio: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(scalingRatio: .infinity)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(gravity: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(gravity: .nan)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(jitterTolerance: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(barnesHutTheta: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(weight: { _ in -1 })
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(initial: Drawing(vertices: [0, 1], positions: [.zero, .zero]))
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(initial: Drawing(vertices: [0, 1], positions: [.zero, SIMD2(.nan, 0)]))
        }
        var generator = Xoshiro256StarStar(seed: 1)
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(
            iterations: 0, gravity: 0, jitterTolerance: 0, barnesHutTheta: 0, weight: { _ in 0 }, using: &generator).count == 3)
    }
}

@Suite("bfsLayout preconditions", .tags(.precondition))
struct BFSLayoutPreconditionTests {
    @Test("bfsLayout: a start not in the graph, a vertex not reachable")
    func bfs() async {
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]).bfsLayout(start: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).bfsLayout(start: 0)
        }
        #expect(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1)]).bfsLayout(start: 0).count == 3)
    }
}
