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
