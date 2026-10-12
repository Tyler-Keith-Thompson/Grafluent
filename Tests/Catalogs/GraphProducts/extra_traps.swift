    @Test("A second factor without vertex indices traps, for all four products")
    func secondFactorWithHoles() async {
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"])
            var h = StableDirectedGraph<String>(vertices: ["x", "removed"])
            _ = h.remove("removed")
            _ = cartesianProductView(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"])
            var h = StableDirectedGraph<String>(vertices: ["x", "removed"])
            _ = h.remove("removed")
            _ = tensorProductView(g, h)
        }
        await #expect(processExitsWith: .failure) {
            var g = StableDirectedGraph<String>(vertices: ["a", "removed"])
            _ = g.remove("removed")
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = strongProductView(g, h)
        }
        await #expect(processExitsWith: .failure) {
            var g = StableDirectedGraph<String>(vertices: ["a", "removed"])
            _ = g.remove("removed")
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = lexicographicProductView(g, h)
        }
        // Without the removals: all four accepted.
        let g = StableDirectedGraph<String>(vertices: ["a"])
        let h = AdjacencyList<String>(vertices: ["x"])
        #expect(cartesianProductView(g, h).vertexIndexBound == 1 && tensorProductView(h, g).vertexIndexBound == 1)
        #expect(strongProductView(g, h).vertexIndexBound == 1 && lexicographicProductView(g, h).vertexIndexBound == 1)
    }

    @Test("Vertex count overflow traps for every kind, in either order")
    func overflowEveryKind() async {
        await #expect(processExitsWith: .failure) {
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = tensorProductView(Huge(count: 3), Huge(count: Int.max / 2))
        }
        await #expect(processExitsWith: .failure) {
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = strongProductView(Huge(count: Int.max / 2), Huge(count: 3))
        }
        await #expect(processExitsWith: .failure) {
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = lexicographicProductView(Huge(count: 1 << 40), Huge(count: 1 << 40))
        }
        // At the boundary: Int.max / 2 · 2 fits, and an empty factor never overflows.
        struct Huge: Graph {
            let count: Int
            var vertices: Range<Int> { 0 ..< count }
            var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
            func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
            func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
            var vertexIndexBound: Int? { count }
            func vertexIndex(of vertex: Int) -> Int { vertex }
            func vertex(atIndex index: Int) -> Int { index }
        }
        #expect(tensorProductView(Huge(count: 2), Huge(count: Int.max / 2)).vertexIndexBound == Int.max - 1)
        #expect(strongProductView(Huge(count: 0), Huge(count: Int.max)).vertexIndexBound == 0)
        #expect(lexicographicProductView(Huge(count: Int.max), Huge(count: 0)).vertexIndexBound == 0)
    }

    @Test("Index-space reads trap outside 0..<vertexIndexBound")
    func indicesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = cartesianProductView(g, h).vertex(atIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = tensorProductView(g, h).vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = strongProductView(g, h).vertex(atIndex: 2)
        }
        // Without the calls: the last index answers.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
        #expect(cartesianProductView(g, h).vertex(atIndex: 1) == Pair("b", "x"))
        #expect(tensorProductView(g, h).vertex(atIndex: 0) == Pair("a", "x"))
    }

    @Test("Label-space reads of a pair that is not a vertex trap, directed and undirected")
    func rowsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = Array(cartesianProductView(g, h).successors(of: Pair("q", "x")))
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = Array(lexicographicProductView(g, h).predecessors(of: Pair("a", "q")))
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = Array(strongProductView(g, h).neighbors(of: Pair("a", "q")))
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = tensorProductView(g, h).degree(of: Pair("q", "x"))
        }
        // Without the calls: contains(_:) and contains(edge:) answer false without trapping.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
        let product = strongProductView(g, h)
        #expect(!product.contains(Pair("a", "q")) && !product.contains(edge: UndirectedEdge(Pair("a", "x"), Pair("q", "x"))))
        #expect(Array(product.neighbors(of: Pair("a", "x"))) == [Pair("b", "x")])
    }

    @Test("edgeIndex(of:) traps on an undirected tensor, strong or lexicographic product")
    func noEdgeIndices() async {
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let product = tensorProductView(g, g)
            _ = product.edgeIndex(of: product.edges.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let product = strongProductView(g, g)
            _ = product.edgeIndex(of: product.edges.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let product = lexicographicProductView(g, g)
            _ = product.edgeIndex(of: product.edges.startIndex)
        }
        // Without the calls: the bounds say so, and the Cartesian product has them.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(tensorProductView(g, g).edgeIndexBound == nil && strongProductView(g, g).edgeIndexBound == nil)
        #expect(lexicographicProductView(g, g).edgeIndexBound == nil)
        let cartesian = cartesianProductView(g, g)
        #expect(cartesian.edgeIndexBound == 4 && cartesian.edgeIndex(of: cartesian.edges.startIndex) == 0)
    }
