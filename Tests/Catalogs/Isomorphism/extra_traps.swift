    @Test("image(of:) and preimage(of:) trap for a non-vertex on directed graphs too; image(checked:) throws")
    func directedAccessorsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let pattern = DirectedPseudograph<Int>(vertices: [4, 8], edges: [DirectedEdge(from: 4, to: 8)])
            let target = DirectedPseudograph<Int>(vertices: [1, 2, 3], edges: [DirectedEdge(from: 3, to: 1)])
            let mapping = pattern.subgraphIsomorphism(to: target)!
            _ = mapping.image(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let pattern = DirectedPseudograph<Int>(vertices: [4, 8], edges: [DirectedEdge(from: 4, to: 8)])
            let target = DirectedPseudograph<Int>(vertices: [1, 2, 3], edges: [DirectedEdge(from: 3, to: 1)])
            let mapping = pattern.subgraphIsomorphism(to: target)!
            _ = mapping.preimage(of: 4)
        }
        // Without the calls: the one mapping 4 ↦ 3, 8 ↦ 1, its accessors on vertices, and
        // VertexNotFound for a non-vertex through image(checked:).
        let pattern = DirectedPseudograph<Int>(vertices: [4, 8], edges: [DirectedEdge(from: 4, to: 8)])
        let target = DirectedPseudograph<Int>(vertices: [1, 2, 3], edges: [DirectedEdge(from: 3, to: 1)])
        guard let mapping = pattern.subgraphIsomorphism(to: target) else {
            Issue.record("no mapping")
            return
        }
        #expect(Array(mapping.images) == [3, 1])
        #expect(mapping.image(of: 4) == 3 && mapping.image(of: 8) == 1)
        #expect(throws: VertexNotFound.self) { try mapping.image(checked: 5) }
        #expect((try? mapping.image(checked: 8)) == 1)
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [8, nil, 4])
    }

    @Test("imageIndex(ofIndex:) traps outside the pattern's index range")
    func imageIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let pattern = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let target = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 2)])
            _ = pattern.monomorphism(to: target)!.imageIndex(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let pattern = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            let target = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 2)])
            _ = pattern.monomorphism(to: target)!.imageIndex(ofIndex: -1)
        }
        // Without the calls: both indices of the pattern answer, with target indices.
        let pattern = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 2)])
        guard let mapping = pattern.monomorphism(to: target) else {
            Issue.record("no mapping")
            return
        }
        #expect(Set([mapping.imageIndex(ofIndex: 0), mapping.imageIndex(ofIndex: 1)]) == [1, 2])
    }

    @Test("WeisfeilerLehmanSubgraphHashes: hashes(of:) traps for a non-vertex, hashes(ofIndex:) outside 0..<vertexCount")
    func subgraphHashesOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
            _ = graph.weisfeilerLehmanSubgraphHashes(iterations: 2).hashes(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
            _ = graph.weisfeilerLehmanSubgraphHashes(iterations: 2).hashes(ofIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.weisfeilerLehmanSubgraphHashes(iterations: 2).hashes(of: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.weisfeilerLehmanSubgraphHashes(iterations: 2).hashes(ofIndex: -1)
        }
        // Without the calls: every vertex and index answers with one hash per round.
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 2 })
        #expect((0 ..< 3).allSatisfy { hashes.hashes(ofIndex: $0).count == 2 })
        let digraph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1)])
        let directedHashes = digraph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect((0 ..< 3).allSatisfy { directedHashes.hashes(ofIndex: $0).count == 2 })
    }

    @Test("Negative iterations trap on directed graphs and with colours too")
    func negativeIterationsEverywhere() async {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.weisfeilerLehmanGraphHash(iterations: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.weisfeilerLehmanSubgraphHashes(iterations: -2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.weisfeilerLehmanGraphHash(iterations: -1, vertexColor: { $0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.weisfeilerLehmanSubgraphHashes(iterations: -1, vertexColor: { _ in 0 }, edgeColor: { $0 })
        }
        // Without the calls: iterations 0 answers.
        let digraph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(digraph.weisfeilerLehmanSubgraphHashes(iterations: 0).iterations == 0)
        let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        #expect(graph.weisfeilerLehmanGraphHash(iterations: 0, vertexColor: { $0 }) == graph.weisfeilerLehmanGraphHash(iterations: 0, vertexColor: { $0 }))
        #expect(graph.weisfeilerLehmanSubgraphHashes(iterations: 0, vertexColor: { _ in 0 }, edgeColor: { $0 }).iterations == 0)
    }

    @Test("Edit paths: a negative, NaN or infinite cost traps, as does a negative expansion limit")
    func editCosts() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.graphEditDistance(to: graph, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in -1 }, vertexInsertionCost: { _ in 1 },
                                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.graphEditDistance(to: graph, vertexSubstitutionCost: { _, _ in 0.0 }, vertexDeletionCost: { _ in 1.0 }, vertexInsertionCost: { _ in 1.0 },
                                        edgeSubstitutionCost: { _, _ in Double.nan }, edgeDeletionCost: { _ in 1.0 }, edgeInsertionCost: { _ in 1.0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.graphEditDistance(to: graph, vertexSubstitutionCost: { _, _ in 0.0 }, vertexDeletionCost: { _ in 1.0 }, vertexInsertionCost: { _ in Double.infinity },
                                        edgeSubstitutionCost: { _, _ in 0.0 }, edgeDeletionCost: { _ in 1.0 }, edgeInsertionCost: { _ in 1.0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.optimalEditPath(to: graph, expansionLimit: -1)
        }
        // Without the traps: zero costs and a zero limit are allowed.
        let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        #expect(graph.graphEditDistance(to: graph, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 0 }, vertexInsertionCost: { _ in 0 },
                                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 0 }, edgeInsertionCost: { _ in 0 }) == 0)
        #expect(graph.optimalEditPath(to: graph, expansionLimit: 0)?.cost == 0)
    }

    @Test("Edit paths: the accessors trap on a non-vertex, a non-edge or an index out of range")
    func editPathAccessors() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.optimalEditPath(to: graph)!.image(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.optimalEditPath(to: graph)!.preimage(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.optimalEditPath(to: graph)!.edgeImage(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.optimalEditPath(to: graph)!.edgePreimage(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.optimalEditPath(to: graph)!.imageIndex(ofIndex: 2)
        }
        // Without the calls: the identity path, read through the same accessors.
        let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        guard let path = graph.optimalEditPath(to: graph) else {
            Issue.record("no path")
            return
        }
        #expect(path.image(of: 0) == 0 && path.image(of: 1) == 1)
        #expect(path.preimage(of: 1) == 1)
        #expect(path.edgeImage(ofEdgeAt: 0) == 0 && path.edgePreimage(ofEdgeAt: 0) == 0)
        #expect(path.imageIndex(ofIndex: 1) == 1)
    }
