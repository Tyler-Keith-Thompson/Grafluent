    @Test("A hub of degree 11 beside vertices of degree 2 or 3, whose colour tables wrap around when an entry is removed: proper, 12 colours, edge by edge")
    func hubTables() {
        // Found by a random search with the tables' deletion broken at the wrap-around, which colours
        // this graph improperly.
        let pairs = [(0, 6), (0, 4), (0, 8), (0, 12), (0, 10), (0, 13), (1, 7), (0, 3), (0, 2), (0, 7), (7, 12), (0, 9), (0, 14), (2, 6), (7, 2), (5, 13), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 15, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 4, 5, 7, 6, 11, 8, 1, 9, 10, 1, 0, 0, 7])
        for v in 0 ..< 15 {
            let at = pairs.indices.filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(coloring.colorCount == 12)
    }
