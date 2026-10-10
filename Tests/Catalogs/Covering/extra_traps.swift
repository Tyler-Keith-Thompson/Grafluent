    @Test("isIndependentSet with a non-vertex traps")
    func independentSetNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isIndependentSet([0, 9])
        }
    }

    @Test("isDominatingSet with a non-vertex traps")
    func dominatingSetNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isDominatingSet([1, 9])
        }
    }

    @Test("isEdgeCover with a negative position traps")
    func edgeCoverNegativePosition() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.isEdgeCover([0, -1])
        }
    }

    @Test("maximalIndependentSet(containing:) with a non-vertex after a valid seed traps")
    func seedNonVertexAfterValid() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.maximalIndependentSet(containing: [0, 9])
        }
    }

    @Test("approximateMinimumDominatingSet(weight:) with a NaN Double weight traps")
    func dominatingNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [1.0, Double.nan]
            _ = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        }
    }

    @Test("approximateMinimumDominatingSet(weight:) with a negative Double weight traps")
    func dominatingNegativeDoubleWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [1.0, -0.5]
            _ = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        }
    }

    @Test("approximateMinimumVertexCover(weight:) with a negative Double weight traps")
    func vertexCoverNegativeDoubleWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let weights = [1.0, -0.5]
            _ = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        }
    }

    @Test("approximateMinimumVertexCover(weight:) with a negative weight on a vertex no edge reaches traps (every weight is read)")
    func vertexCoverNegativeWeightIsolated() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
            let weights = [1, 1, -3]
            _ = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        }
    }

    @Test("minimumVertexCover(bipartition:) with sides of another graph that put an edge inside a side traps")
    func bipartitionEdgeInsideSide() async {
        await #expect(processExitsWith: .failure) {
            // P4 0–1–2–3; the sides of 0–2, 1–3 are left [0, 1], right [2, 3], so 0–1 is inside the left side.
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let other = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3)])
            _ = graph.minimumVertexCover(bipartition: other.bipartition()!)
        }
    }
