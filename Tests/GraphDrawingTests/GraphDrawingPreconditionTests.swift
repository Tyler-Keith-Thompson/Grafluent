// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the call, so the trap is the call's and not the
// setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

@Suite("GraphDrawing preconditions", .tags(.precondition))
struct GraphDrawingPreconditionTests {
    @Test("DR-007 position(of:) on a missing vertex")
    func dr007() async {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); position(of: 4) → **trap**
        await #expect(processExitsWith: .failure) {
            let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
            let position = drawing.position(of: 4)
            _ = position
        }
        // Without the call: the same setup answers.
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        #expect(drawing.position(safe: 4) == nil && drawing.count == 2)
    }

    @Test("DR-010 vertices and positions of different lengths")
    func dr010() async {
        // Drawing(vertices: [5, 3], positions: [(0, 0)]); init → **trap**
        await #expect(processExitsWith: .failure) {
            _ = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0)])
        }
        // Without the call: the same setup answers.
        #expect(Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)]).count == 2)
    }

    @Test("DR-011 duplicate vertex")
    func dr011() async {
        // Drawing(vertices: [5, 5], positions: [(0, 0), (1, 1)]); init → **trap**
        await #expect(processExitsWith: .failure) {
            _ = Drawing(vertices: [5, 5], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)])
        }
        // Without the call: the same setup answers.
        #expect(Drawing(vertices: [5, 6], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)]).count == 2)
    }

    @Test("DR-031 negative radius")
    func dr031() async {
        // U: n=3;; circularLayout(radius: -1) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
            _ = graph.circularLayout(radius: -1)
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.circularLayout(radius: 0).positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 0.0), SIMD2(0.0, 0.0)])
        #expect(graph.circularLayout(center: SIMD2(0, 0)).count == 3)
    }

    @Test("DR-032 NaN centre")
    func dr032() async {
        // U: n=3;; circularLayout(center: (.nan, 0)) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
            _ = graph.circularLayout(center: SIMD2(.nan, 0))
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.circularLayout(radius: 0).positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 0.0), SIMD2(0.0, 0.0)])
        #expect(graph.circularLayout(center: SIMD2(0, 0)).count == 3)
    }

    @Test("DR-161 caller layers: negative layer")
    func dr161() async {
        // D: 0>1; sugiyamaLayout(layers: [-1, 0]) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.sugiyamaLayout(layers: { [-1, 0][$0] })
        }
        // Without the call: the same setup answers.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let layered = graph.sugiyamaLayout()
        #expect(layered.layer(of: 0) == 0 && layered.layer(of: 1) == 1 && layered.bends(ofEdgeAt: 0).isEmpty)
        #expect(graph.sugiyamaLayout(layers: { [0, 1][$0] }).drawing == layered.drawing)
    }

    @Test("DR-164 layer(of:) on a missing vertex")
    func dr164() async {
        // D: 0>1; sugiyamaLayout().layer(of: 9) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.sugiyamaLayout().layer(of: 9)
        }
        // Without the call: the same setup answers.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let layered = graph.sugiyamaLayout()
        #expect(layered.layer(of: 0) == 0 && layered.layer(of: 1) == 1 && layered.bends(ofEdgeAt: 0).isEmpty)
        #expect(graph.sugiyamaLayout(layers: { [0, 1][$0] }).drawing == layered.drawing)
    }

    @Test("DR-165 bends(ofEdgeAt:) on a missing edge")
    func dr165() async {
        // D: 0>1; sugiyamaLayout().bends(ofEdgeAt: 5) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.sugiyamaLayout().bends(ofEdgeAt: 5)
        }
        // Without the call: the same setup answers.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let layered = graph.sugiyamaLayout()
        #expect(layered.layer(of: 0) == 0 && layered.layer(of: 1) == 1 && layered.bends(ofEdgeAt: 0).isEmpty)
        #expect(graph.sugiyamaLayout(layers: { [0, 1][$0] }).drawing == layered.drawing)
    }

    @Test("DR-173 initial: drawing missing a vertex")
    func dr173() async {
        // U: P(0,1,2); fruchtermanReingoldLayout(initial: Drawing(vertices: [0, 1], …)) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.fruchtermanReingoldLayout(initial: Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)]))
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let start = Drawing(vertices: [0, 1, 2], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(graph.fruchtermanReingoldLayout(initial: start, iterations: 0) == start)
        var generator = Xoshiro256StarStar(seed: 1)
        #expect(graph.fruchtermanReingoldLayout(iterations: 0, barnesHutTheta: 0, using: &generator).count == 3)
    }

    @Test("DR-176 iterations: -1")
    func dr176() async {
        // U: P(0,1,2); fruchtermanReingoldLayout(iterations: -1, using: &g) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = graph.fruchtermanReingoldLayout(iterations: -1, using: &generator)
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let start = Drawing(vertices: [0, 1, 2], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(graph.fruchtermanReingoldLayout(initial: start, iterations: 0) == start)
        var generator = Xoshiro256StarStar(seed: 1)
        #expect(graph.fruchtermanReingoldLayout(iterations: 0, barnesHutTheta: 0, using: &generator).count == 3)
    }

    @Test("DR-189 Barnes–Hut θ < 0")
    func dr189() async {
        // U: P(0,1,2); fruchtermanReingoldLayout(barnesHutTheta: -1, using: &g) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = graph.fruchtermanReingoldLayout(barnesHutTheta: -1, using: &generator)
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let start = Drawing(vertices: [0, 1, 2], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(graph.fruchtermanReingoldLayout(initial: start, iterations: 0) == start)
        var generator = Xoshiro256StarStar(seed: 1)
        #expect(graph.fruchtermanReingoldLayout(iterations: 0, barnesHutTheta: 0, using: &generator).count == 3)
    }

    @Test("DR-205 edge length ≤ 0")
    func dr205() async {
        // U: 0-1; stressMajorizationLayout(edgeLength: { _ in 0 }) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.stressMajorizationLayout(edgeLength: { _ in 0 })
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(graph.stressMajorizationLayout(edgeLength: { _ in 0.5 }, tolerance: 0).count == 2)
    }

    @Test("DR-206 tolerance < 0")
    func dr206() async {
        // U: 0-1; stressMajorizationLayout(tolerance: -1) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.stressMajorizationLayout(tolerance: -1)
        }
        // Without the call: the same setup answers.
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(graph.stressMajorizationLayout(edgeLength: { _ in 0.5 }, tolerance: 0).count == 2)
    }

    @Test("setPosition(_:of:) on a missing vertex traps")
    func setPositionOnMissingVertex() async {
        await #expect(processExitsWith: .failure) {
            var drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
            drawing.setPosition(SIMD2(1.0, 1.0), of: 4)
        }
        // Without the call: a write to a vertex lands, and nothing else changes.
        var drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        drawing.setPosition(SIMD2(1.0, 1.0), of: 3)
        #expect(drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)] && Array(drawing.vertices) == [5, 3])
    }

    @Test("A drawing over String vertices traps on a missing one, read or written")
    func stringVertices() async {
        await #expect(processExitsWith: .failure) {
            let drawing = Drawing(vertices: ["a", "b"], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)])
            _ = drawing.position(of: "c")
        }
        await #expect(processExitsWith: .failure) {
            _ = Drawing(vertices: ["a", "b", "a"], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0)])
        }
        // Without the calls.
        let drawing = Drawing(vertices: ["a", "b"], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)])
        #expect(drawing.position(of: "b") == SIMD2(1.0, 0.0) && drawing.position(safe: "c") == nil)
    }

    @Test("circularLayout traps on an infinite centre and on a NaN in y")
    func circularNonFiniteCentre() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
            _ = graph.circularLayout(center: SIMD2(.infinity, 0))
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
            _ = graph.circularLayout(center: SIMD2(0, .nan))
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
            _ = graph.circularLayout(radius: -0.5)
        }
        // Without the calls: a finite centre and radius 0 put every vertex at the centre.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.circularLayout(radius: 0, center: SIMD2(2, 3)).positions == [SIMD2(2.0, 3.0), SIMD2(2.0, 3.0), SIMD2(2.0, 3.0)])
    }

    @Test("The Fruchterman–Reingold stepper has the function's preconditions")
    func fruchtermanReingoldStepper() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = FruchtermanReingoldLayout(graph, iterations: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = FruchtermanReingoldLayout(graph, barnesHutTheta: -0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = FruchtermanReingoldLayout(graph, initial: Drawing(vertices: [0, 2], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)]))
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.fruchtermanReingoldLayout(initial: graph.circularLayout(), iterations: -1)
        }
        // Without the calls: the same setups build.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var generator = Xoshiro256StarStar(seed: 1)
        let stepper = FruchtermanReingoldLayout(graph, iterations: 0, barnesHutTheta: 0.5, using: &generator)
        #expect(stepper.isFinished && stepper.drawing.count == 3)
        #expect(FruchtermanReingoldLayout(graph, initial: graph.circularLayout()).drawing == graph.circularLayout())
    }

    @Test("Stress majorization traps on a non-positive edge length anywhere, and its stepper does too")
    func stressPreconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.stressMajorizationLayout(edgeLength: { $0 == graph.edges.index(after: graph.edges.startIndex) ? -1 : 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = StressMajorizationLayout(graph, edgeLength: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = StressMajorizationLayout(graph, tolerance: -1)
        }
        // Without the calls: positive lengths lay out.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.stressMajorizationLayout(edgeLength: { _ in 3 }).count == 3)
        #expect(StressMajorizationLayout(graph, tolerance: 0).drawing == graph.circularLayout())
    }

    @Test("The layered drawing traps for a vertex or an edge position of another graph")
    func layeredLookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.sugiyamaLayout().layer(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.sugiyamaLayout().bends(ofEdgeAt: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = graph.sugiyamaLayout(layers: { $0 == 2 ? -3 : $0 })
        }
        // Without the calls: every vertex and position answers.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let layered = graph.sugiyamaLayout()
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2])
        #expect(layered.bends(ofEdgeAt: 1).isEmpty)
        #expect(graph.sugiyamaLayout(layers: { $0 }).drawing == layered.drawing)
    }

    @Test("Fruchterman–Reingold and stress majorization trap on a non-finite initial position")
    func nonFiniteInitial() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.fruchtermanReingoldLayout(initial: Drawing(vertices: 0 ..< 3, positions: [SIMD2(0, 0), SIMD2(.nan, 0), SIMD2(1, 1)]))
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = FruchtermanReingoldLayout(graph, initial: Drawing(vertices: 0 ..< 3, positions: [SIMD2(0, 0), SIMD2(0, .infinity), SIMD2(1, 1)]))
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.stressMajorizationLayout(initial: Drawing(vertices: [2, 1, 0], positions: [SIMD2(0, 0), SIMD2(-.infinity, 0), SIMD2(1, 1)]))
        }
        // Without the calls: finite starts, in or out of the graph's order, lay out.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.fruchtermanReingoldLayout(initial: Drawing(vertices: 0 ..< 3, positions: [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)])).count == 3)
        #expect(graph.stressMajorizationLayout(initial: Drawing(vertices: [2, 1, 0], positions: [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)])).count == 3)
    }
}
