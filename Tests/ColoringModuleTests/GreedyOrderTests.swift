// `greedyColoring(order:)` (catalog §Greedy.order): first fit in the given order (Boost
// `sequential_vertex_coloring`, NetworkX with a callable strategy); exact; proper (checked here); at
// most Δ + 1 colours; a first-fit colouring; first fit written out; the order as a lazy sequence.
// Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in
// order, so rows are in position order (a self-loop twice); `multigraph` rows are
// `ReferencePseudograph`, whose rows are in position order too; `L …; R …` and the `Kb`, `crown` and
// `lcgb` rows are `BipartiteGraph(left:right:edges:)`. In-test oracles number vertices by their
// index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with
// ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("greedyColoring(order:)")
struct GreedyOrderTests {
    @Test("CO-120 empty order on the empty graph: colors []; 0 colors")
    func co120() {
        // V []; E []; greedyColoring(order: [])
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 0)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-121 path in reverse: colors [0, 1, 0, 1, 0]; 2 colors")
    func co121() {
        // P(5); greedyColoring(order: [4, 3, 2, 1, 0])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [4, 3, 2, 1, 0] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-122 crown(4) interleaved: the classic n/2-colour trap: colors [0, 1, 2, 3, 0, 1, 2, 3]; 4 colors")
    func co122() throws {
        // crown(4); greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7])
        let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [0, 4, 1, 5, 2, 6, 3, 7] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2, 3, 0, 1, 2, 3])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-123 crown(4) sides first: 2 colours: colors [0, 0, 0, 0, 1, 1, 1, 1]; 2 colors")
    func co123() throws {
        // crown(4); greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7])
        let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 0, 0, 1, 1, 1, 1])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-124 labels: colors [2, 1, 0, 1]; 3 colors")
    func co124() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; greedyColoring(order: [c, b, a, d])
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = ["c", "b", "a", "d"] as [String]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [2, 1, 0, 1])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-125 Petersen, outer then inner: colors [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]; 3 colors")
    func co125() {
        // nx(petersen_graph); greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-126 Petersen, inner then outer: colors [1, 2, 0, 2, 0, 0, 0, 1, 1, 2]; 3 colors")
    func co126() {
        // nx(petersen_graph); greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4])
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [5, 6, 7, 8, 9, 0, 1, 2, 3, 4] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 2, 0, 2, 0, 0, 0, 1, 1, 2])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-127 self-loop ignored: colors [2, 0, 1, 0]; 3 colors")
    func co127() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(order: [3, 2, 1, 0])
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [3, 2, 1, 0] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [2, 0, 1, 0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }

    @Test("CO-128 parallel edges: colors [0, 1, 0]; 2 colors")
    func co128() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; greedyColoring(order: [2, 1, 0])
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let order = [2, 1, 0] as [Int]
        let coloring = graph.greedyColoring(order: order)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // At most Δ + 1 colours, Δ the greatest simple degree.
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        // First fit, checked here: a vertex of colour c has neighbours of every colour below c.
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(vertexList[v])") }
        // First fit in the given order, written out.
        let orderIndices = order.map { vertexList.firstIndex(of: $0)! }
        var expected = [Int](repeating: -1, count: n)
        for v in orderIndices {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // The order as any sequence: a lazy map of indices gives the same colouring.
        #expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)
    }
}
