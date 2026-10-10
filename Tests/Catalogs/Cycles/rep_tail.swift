    @Test("CY-702 AdjacencyMatrix.undirected with cells u < v: K₄ with positions as cells, rows out-edges then in-edges")
    func adjacencyMatrixUndirected() throws {
        // Cells (0,1) < (0,2) < (0,3) < (1,2) < (1,3) < (2,3). Vertex 1's row is (1,2), (1,3), then
        // (0,1), so the order is not K(4)'s (CY-330); the canonical forms are, cell for cell.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.vertexIndexBound == 4 && graph.edgeIndexBound == nil)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2], [0, 1, 3], [0, 1, 3, 2], [0, 2, 3], [0, 2, 1, 3], [1, 2, 3]]
        let expectedCells: [[[Int]]] = [
            [[0, 1], [1, 2], [2, 3], [0, 3]], [[0, 1], [1, 2], [0, 2]], [[0, 1], [1, 3], [0, 3]],
            [[0, 1], [1, 3], [2, 3], [0, 2]], [[0, 2], [2, 3], [0, 3]], [[0, 2], [1, 2], [1, 3], [0, 3]],
            [[1, 2], [2, 3], [1, 3]],
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1, 2, 3])
        #expect(found.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [0, 3]])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3]])
        #expect(basis.map { $0.edges.map { [$0.source, $0.target] } } == [[[0, 1], [1, 2], [0, 2]], [[0, 1], [1, 3], [0, 3]], [[0, 2], [2, 3], [0, 3]]])
        #expect(graph.girth() == 3)
        #expect(!graph.isAcyclic)
    }

    @Test("CY-702 AdjacencyList.undirected, one arc per edge: K₄ with the arcs' positions, rows out-edges then in-edges")
    func adjacencyListUndirected() throws {
        // The same rows as the matrix's above, positions 0..<6 in written order.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        #expect(graph.edgeCount == 6)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2], [0, 1, 3], [0, 1, 3, 2], [0, 2, 3], [0, 2, 1, 3], [1, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 3, 5, 2], [0, 3, 1], [0, 4, 2], [0, 4, 5, 1], [1, 5, 2], [1, 3, 4, 2], [3, 5, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1, 2, 3])
        #expect(found.edges == [0, 3, 5, 2])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3]])
        #expect(basis.map(\.edges) == [[0, 3, 1], [0, 4, 2], [1, 5, 2]])
        #expect(graph.girth() == 3)
    }

    @Test("CY-703 conformers without indices and with vertex indices only: CY-119, CY-327 and CY-412 exactly")
    func conformersWithoutIndices() throws {
        // CY-119: 0-1 1-2 2-0 0-1 2-2.
        let pairs119: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let edges119 = pairs119.map { UndirectedEdge($0.0, $0.1) }
        let plain119 = PlainGraph(vertices: [0, 1, 2], edges: edges119)
        let indexed119 = VertexIndexedGraph(vertices: [0, 1, 2], edges: edges119)
        #expect(plain119.vertexIndexBound == nil && plain119.edgeIndexBound == nil)
        #expect(indexed119.vertexIndexBound == 3 && indexed119.edgeIndexBound == nil)
        let cycles119Vertices: [[Int]] = [[0, 1, 2], [0, 1], [0, 2, 1], [2]]
        let cycles119Edges: [[Int]] = [[0, 1, 2], [0, 3], [2, 1, 3], [4]]
        #expect(Array(plain119.simpleCycles()).map(\.vertices) == cycles119Vertices)
        #expect(Array(plain119.simpleCycles()).map(\.edges) == cycles119Edges)
        #expect(Array(indexed119.simpleCycles()).map(\.vertices) == cycles119Vertices)
        #expect(Array(indexed119.simpleCycles()).map(\.edges) == cycles119Edges)
        let basis119Vertices: [[Int]] = [[0, 1, 2], [0, 1], [2]]
        let basis119Edges: [[Int]] = [[0, 1, 2], [0, 3], [4]]
        #expect(plain119.cycleBasis().map(\.vertices) == basis119Vertices)
        #expect(plain119.cycleBasis().map(\.edges) == basis119Edges)
        #expect(indexed119.cycleBasis().map(\.vertices) == basis119Vertices)
        #expect(indexed119.cycleBasis().map(\.edges) == basis119Edges)
        let plainFound = try #require(plain119.findCycle())
        let indexedFound = try #require(indexed119.findCycle())
        #expect(plainFound.vertices == [0, 1, 2] && plainFound.edges == [0, 1, 2])
        #expect(indexedFound.vertices == [0, 1, 2] && indexedFound.edges == [0, 1, 2])
        #expect(plain119.girth() == 1 && indexed119.girth() == 1)
        #expect(!plain119.isAcyclic && !indexed119.isAcyclic)

        // CY-327 (igraph "Mickey3"): [0..6] 0-1 1-2 2-0 0-3 3-4 4-5 5-0 1-1 5-6 6-5 5-5 5-5.
        let pairs327: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 5), (5, 0), (1, 1), (5, 6), (6, 5), (5, 5), (5, 5)]
        let edges327 = pairs327.map { UndirectedEdge($0.0, $0.1) }
        let cycles327Vertices: [[Int]] = [[0, 1, 2], [0, 3, 4, 5], [1], [5, 6], [5], [5]]
        let cycles327Edges: [[Int]] = [[0, 1, 2], [3, 4, 5, 6], [7], [8, 9], [10], [11]]
        let plain327 = PlainGraph(vertices: Array(0 ... 6), edges: edges327)
        let indexed327 = VertexIndexedGraph(vertices: Array(0 ... 6), edges: edges327)
        #expect(Array(plain327.simpleCycles()).map(\.vertices) == cycles327Vertices)
        #expect(Array(plain327.simpleCycles()).map(\.edges) == cycles327Edges)
        #expect(Array(indexed327.simpleCycles()).map(\.vertices) == cycles327Vertices)
        #expect(Array(indexed327.simpleCycles()).map(\.edges) == cycles327Edges)
        // Here the basis is every simple cycle: no two share a non-tree edge.
        #expect(plain327.cycleBasis().map(\.edges) == cycles327Edges)
        #expect(indexed327.cycleBasis().map(\.edges) == cycles327Edges)

        // CY-412: C(0..3) 0-1 2-3, two doubled sides.
        let pairs412: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1), (2, 3)]
        let edges412 = pairs412.map { UndirectedEdge($0.0, $0.1) }
        let cycles412Vertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1], [0, 3, 2, 1], [0, 3, 2, 1], [2, 3]]
        let cycles412Edges: [[Int]] = [[0, 1, 2, 3], [0, 1, 5, 3], [0, 4], [3, 2, 1, 4], [3, 5, 1, 4], [2, 5]]
        let plain412 = PlainGraph(vertices: [0, 1, 2, 3], edges: edges412)
        #expect(Array(plain412.simpleCycles()).map(\.vertices) == cycles412Vertices)
        #expect(Array(plain412.simpleCycles()).map(\.edges) == cycles412Edges)
        #expect(plain412.cycleBasis().map(\.edges) == [[0, 1, 2, 3], [0, 4], [0, 1, 5, 3]])
        #expect(plain412.girth() == 2)
        let indexed412 = VertexIndexedGraph(vertices: [0, 1, 2, 3], edges: edges412)
        #expect(Array(indexed412.simpleCycles()).map(\.vertices) == cycles412Vertices)
        #expect(Array(indexed412.simpleCycles()).map(\.edges) == cycles412Edges)
        #expect(indexed412.cycleBasis().map(\.edges) == [[0, 1, 2, 3], [0, 4], [0, 1, 5, 3]])
        #expect(indexed412.girth() == 2)
    }

    @Test("CY-703 a digraph conformer without indices: CY-200 and CY-410 exactly")
    func digraphWithoutIndices() {
        // CY-200: 0>0 0>1 0>2 1>2 2>0 2>1 2>2.
        let pairs200: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let plain200 = PlainDigraph(vertices: [0, 1, 2], edges: pairs200.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(plain200.vertexIndexBound == nil && plain200.edgeIndexBound == nil)
        let cycles200 = Array(plain200.simpleCycles())
        #expect(cycles200.map(\.vertices) == [[0], [0, 1, 2], [0, 2], [1, 2], [2]])
        #expect(cycles200.map(\.edges) == [[0], [1, 3, 4], [2, 4], [3, 5], [6]])
        #expect(plain200.girth() == 1)
        // CY-410: 0>1 1>0 1>0 0>1, 2 × 2 antiparallel copies.
        let pairs410: [(Int, Int)] = [(0, 1), (1, 0), (1, 0), (0, 1)]
        let plain410 = PlainDigraph(vertices: [0, 1], edges: pairs410.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles410 = Array(plain410.simpleCycles())
        #expect(cycles410.map(\.vertices) == [[0, 1], [0, 1], [0, 1], [0, 1]])
        #expect(cycles410.map(\.edges) == [[0, 1], [0, 2], [3, 1], [3, 2]])
        #expect(plain410.girth() == 2)
    }

    @Test("CY-708 digraph.undirected: antiparallel arcs become a 2-cycle, rows out-edges then in-edges")
    func undirectedViewOfDigraph() throws {
        // D: 0>1 1>0 1>2 2>0. Vertex 1's row is 1, 2 (out) then 0 (in); the catalog's position-order
        // row gives the same order here.
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let digraph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0, 1, 2], [0, 1, 2]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2, 3], [1, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1])
        #expect(found.edges == [0, 1])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1], [0, 1, 2]])
        #expect(basis.map(\.edges) == [[0, 1], [0, 2, 3]])
        #expect(graph.girth() == 2)
        #expect(!graph.isAcyclic)
        // The digraph's own cycles: the digon and 0>1>2>0.
        let directed = Array(digraph.simpleCycles())
        #expect(directed.map(\.vertices) == [[0, 1], [0, 1, 2]])
        #expect(directed.map(\.edges) == [[0, 1], [0, 2, 3]])
        #expect(digraph.girth() == 2)
    }

    @Test("CY-423 CY-708 the .undirected view of D: 0>1 1>0 1>0: three 2-cycles, one per pair of arcs")
    func undirectedViewOfParallelArcs() throws {
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let cycles = Array(graph.simpleCycles())
        #expect(cycles.map(\.vertices) == [[0, 1], [0, 1], [0, 1]])
        #expect(cycles.map(\.edges) == [[0, 1], [0, 2], [1, 2]])
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1] && found.edges == [0, 1])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1], [0, 1]])
        #expect(basis.map(\.edges) == [[0, 1], [0, 2]])
        #expect(graph.girth() == 2)
    }

    @Test("CY-708 the .undirected view of CY-119 written as arcs: loops and parallel arcs keep their positions")
    func undirectedViewWithLoop() throws {
        // D: 0>1 1>2 2>0 0>1 2>2. The view lists the loop at 2 once as an out-edge, once as an in-edge.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let cycles = Array(graph.simpleCycles())
        #expect(cycles.map(\.vertices) == [[0, 1, 2], [0, 1], [0, 2, 1], [2]])
        #expect(cycles.map(\.edges) == [[0, 1, 2], [0, 3], [2, 1, 3], [4]])
        let found = try #require(graph.findCycle())
        #expect(found.vertices == [0, 1, 2] && found.edges == [0, 1, 2])
        let basis = graph.cycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1], [2]])
        #expect(basis.map(\.edges) == [[0, 1, 2], [0, 3], [4]])
        #expect(graph.girth() == 1)
    }

    @Test("CY-707 CY-858 g.directed reads every edge as two arcs: C₄ with a chord has 11 directed cycles and is not acyclic")
    func directedViewOfGraph() {
        // C(0..3) 0-2: 2 × 3 cycles of length ≥ 3 and 5 digons, one per edge.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = Array(graph.directed.simpleCycles())
        #expect(arcs.count == 11)
        #expect(arcs.filter { $0.length == 2 }.count == 5)
        #expect(arcs.filter { $0.length == 3 }.count == 4)
        #expect(arcs.filter { $0.length == 4 }.count == 2)
        // Every digon uses one edge's two arcs.
        #expect(arcs.filter { $0.length == 2 }.allSatisfy { $0.edges[0].position == $0.edges[1].position && $0.edges[0].reversed != $0.edges[1].reversed })
        #expect(graph.directed.girth() == 2)
        #expect(graph.girth() == 3)
    }

    @Test("CY-709 String and Collider vertices (every hash equal): the envelope (CY-319) relabelled, exactly")
    func stringAndColliderVertices() {
        // 0-1 0-3 0-4 1-2 1-3 2-3 2-4 3-4.
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 4), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3], [0, 1, 2, 3, 4], [0, 1, 2, 4], [0, 1, 2, 4, 3], [0, 1, 3], [0, 1, 3, 2, 4],
            [0, 1, 3, 4], [0, 3, 1, 2, 4], [0, 3, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4, 3], [3, 2, 4],
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 5, 1], [0, 3, 5, 7, 2], [0, 3, 6, 2], [0, 3, 6, 7, 1], [0, 4, 1], [0, 4, 5, 6, 2],
            [0, 4, 7, 2], [1, 4, 3, 6, 2], [1, 5, 6, 2], [1, 7, 2], [3, 5, 4], [3, 6, 7, 4], [5, 6, 7],
        ]
        let strings = ReferencePseudograph(edges: pairs.map { UndirectedEdge("v\($0.0)", "v\($0.1)") })
        let stringCycles = Array(strings.simpleCycles())
        #expect(stringCycles.map { $0.vertices.map { Int($0.dropFirst())! } } == expectedVertices)
        #expect(stringCycles.map(\.edges) == expectedEdges)
        #expect(strings.girth() == 3)
        #expect(strings.cycleBasis().count == 4)

        let colliderEdges = pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) }
        let colliders = ReferencePseudograph(edges: colliderEdges)
        let colliderCycles = Array(colliders.simpleCycles())
        #expect(colliderCycles.map { $0.vertices.map(\.value) } == expectedVertices)
        #expect(colliderCycles.map(\.edges) == expectedEdges)
        let list = UndirectedAdjacencyList(edges: colliderEdges)
        let listCycles = Array(list.simpleCycles())
        #expect(listCycles.map { $0.vertices.map(\.value) } == expectedVertices)
        #expect(listCycles.map(\.edges) == expectedEdges)
        #expect(list.findCycle()?.vertices.map(\.value) == [0, 1, 2, 3])
        #expect(list.findCycle()?.edges == [0, 3, 5, 1])
        #expect(list.cycleBasis().map { $0.vertices.map(\.value) } == [[0, 1, 3], [0, 1, 2, 3], [0, 1, 2, 4], [0, 3, 4]])
        #expect(list.cycleBasis().map(\.edges) == [[0, 4, 1], [0, 3, 5, 1], [0, 3, 6, 2], [1, 7, 2]])
        #expect(list.girth() == 3)
        #expect(!list.isAcyclic)
    }

    @Test("CY-710 UndirectedAdjacencyList after removals: rows out of position order, the order its own rows give, the same set as a pseudograph")
    func undirectedAdjacencyListAfterRemovals() throws {
        // K(0..5) and a triangle 5-6-7 with a loop at 7, then removals that move the last edge into
        // each hole and the last slot into a removed vertex's place, so rows leave position order.
        var pairs: [(Int, Int)] = []
        for u in 0 ..< 6 { for v in u + 1 ..< 6 { pairs.append((u, v)) } }
        pairs += [(5, 6), (6, 7), (7, 5), (7, 7)]
        var list = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        list.remove(edge: UndirectedEdge(0, 1))
        list.remove(edge: UndirectedEdge(3, 2))
        list.remove(1)
        list.insert(edge: UndirectedEdge(6, 0))
        list.insert(edge: UndirectedEdge(4, 4))
        let vertices = Array(list.vertices)
        let edges = Array(list.edges)
        let rows = vertices.map { Array(list.incidentEdges(of: $0)) }
        // Only meaningful if some row is out of position order.
        #expect(rows.contains { $0 != $0.sorted() })

        // Brute force over the list's own rows: every closed path from each start s through
        // vertices after s (in `vertices` order), in canonical orientation, sorted by api.md's key.
        let n = vertices.count
        var number: [Int: Int] = [:]
        for (i, v) in vertices.enumerated() { number[v] = i }
        var found: [[Int]: (key: [Int], vertices: [Int], edges: [Int])] = [:]
        for s in 0 ..< n {
            var pathVertices = [s]
            var pathEdges: [Int] = []
            func extend() {
                let v = pathVertices[pathVertices.count - 1]
                for e in rows[v] where !pathEdges.contains(e) {
                    let w = number[edges[e].oppositeVertex(to: vertices[v])]!
                    if w == s {
                        var cv = pathVertices
                        var ce = pathEdges + [e]
                        if ce.count >= 2 && ce[ce.count - 1] < ce[0] {
                            cv = [cv[0]] + cv[1...].reversed()
                            ce.reverse()
                        }
                        let key = [s] + zip(cv, ce).map { rows[$0.0].firstIndex(of: $0.1)! }
                        found[cv + [-1] + ce] = (key, cv, ce)
                    } else if w > s && !pathVertices.contains(w) {
                        pathVertices.append(w)
                        pathEdges.append(e)
                        extend()
                        pathVertices.removeLast()
                        pathEdges.removeLast()
                    }
                }
            }
            extend()
        }
        let expected = found.values.sorted { $0.key.lexicographicallyPrecedes($1.key) }
        #expect(!expected.isEmpty)
        let cycles = Array(list.simpleCycles())
        #expect(cycles.map(\.vertices) == expected.map { $0.vertices.map { vertices[$0] } })
        #expect(cycles.map(\.edges) == expected.map(\.edges))

        // The same set as a pseudograph holding the same vertices and edges with rows in position
        // order; only the order differs.
        let reference = ReferencePseudograph(vertices: vertices, edges: edges)
        let referenceCycles = Array(reference.simpleCycles())
        #expect(Set(cycles) == Set(referenceCycles))
        #expect(cycles.count == referenceCycles.count)
        #expect(list.girth() == reference.girth())
        #expect(list.isAcyclic == reference.isAcyclic)
        #expect(list.cycleBasis().count == reference.cycleBasis().count)
        let cycle = try #require(list.findCycle())
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: list) != nil)
        #expect(list.cycleBasis().allSatisfy { Cycle(vertices: $0.vertices, edges: $0.edges, in: list) != nil })
    }

    @Test("CY-710 AdjacencyList after removals: out-edge rows out of position order, the order its own rows give")
    func adjacencyListAfterRemovals() {
        // DKL(0..4) (every arc, loops included), then removals that repack rows and positions.
        var pairs: [(Int, Int)] = []
        for a in 0 ..< 5 { for b in 0 ..< 5 { pairs.append((a, b)) } }
        var list = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        list.remove(edge: DirectedEdge(from: 0, to: 1))
        list.remove(edge: DirectedEdge(from: 2, to: 2))
        list.remove(edge: DirectedEdge(from: 3, to: 0))
        list.remove(1)
        list.insert(edge: DirectedEdge(from: 4, to: 7))
        list.insert(edge: DirectedEdge(from: 7, to: 0))
        let vertices = Array(list.vertices)
        let edges = Array(list.edges)
        let rows = vertices.map { Array(list.outEdges(of: $0)) }
        #expect(rows.contains { $0 != $0.sorted() })

        // Brute force over the list's own rows, as above but directed: no orientation to choose.
        let n = vertices.count
        var number: [Int: Int] = [:]
        for (i, v) in vertices.enumerated() { number[v] = i }
        var found: [(key: [Int], vertices: [Int], edges: [Int])] = []
        for s in 0 ..< n {
            var pathVertices = [s]
            var pathEdges: [Int] = []
            func extend() {
                let v = pathVertices[pathVertices.count - 1]
                for e in rows[v] {
                    let w = number[edges[e].target]!
                    if w == s {
                        let ce = pathEdges + [e]
                        found.append(([s] + zip(pathVertices, ce).map { rows[$0.0].firstIndex(of: $0.1)! }, pathVertices, ce))
                    } else if w > s && !pathVertices.contains(w) {
                        pathVertices.append(w)
                        pathEdges.append(e)
                        extend()
                        pathVertices.removeLast()
                        pathEdges.removeLast()
                    }
                }
            }
            extend()
        }
        let expected = found.sorted { $0.key.lexicographicallyPrecedes($1.key) }
        #expect(!expected.isEmpty)
        let cycles = Array(list.simpleCycles())
        #expect(cycles.map(\.vertices) == expected.map { $0.vertices.map { vertices[$0] } })
        #expect(cycles.map(\.edges) == expected.map(\.edges))
        let reference = ReferenceDirectedMultigraph(vertices: vertices, edges: edges)
        #expect(Set(cycles) == Set(reference.simpleCycles()))
        #expect(list.girth() == reference.girth())
    }
}
