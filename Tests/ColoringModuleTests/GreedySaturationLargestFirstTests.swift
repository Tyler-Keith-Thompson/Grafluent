// `greedyColoring(strategy: .saturationLargestFirst)` (catalog §Greedy.saturationLargestFirst):
// DSatur with NetworkX's tie rule (saturation, then simple degree in the whole graph, then the
// lesser index), NetworkX's colours; exact; proper (checked here); at most Δ + 1 colours; a
// first-fit colouring; the strategy written out; at least `chromaticNumber()` colours. Graphs are
// `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in order, so rows
// are in position order (a self-loop twice); `multigraph` rows are `ReferencePseudograph`, whose
// rows are in position order too; `L …; R …` and the `Kb`, `crown` and `lcgb` rows are
// `BipartiteGraph(left:right:edges:)`. In-test oracles number vertices by their index in `vertices`.
// Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's model; see
// README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("greedyColoring(strategy: .saturationLargestFirst)")
struct GreedySaturationLargestFirstTests {
    @Test("CO-003 empty graph: colors []; 0 colors")
    func co003() {
        // V []; E []; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-009 one vertex: colors [0]; 1 colors")
    func co009() {
        // V [0]; E []; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 1)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-014 one vertex with a self-loop: loop ignored: colors [0]; 1 colors")
    func co014() {
        // V [0]; E [0-0]; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 1)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-019 two isolated vertices: colors [0, 0]; 1 colors")
    func co019() {
        // V [0, 1]; E []; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 1)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-020 one edge: colors [0, 1]; 2 colors")
    func co020() {
        // V [0, 1]; E [0-1]; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-021 parallel edges count once (degree 1 at 0): colors [1, 0, 1]; 2 colors")
    func co021() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-023 self-loops ignored; also in the degree that orders: colors [1, 2, 0, 1]; 3 colors")
    func co023() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 2, 0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-065 triangle: colors [0, 1, 2]; 3 colors")
    func co065() {
        // K(3); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-066 K(5): colors [0, 1, 2, 3, 4]; 5 colors")
    func co066() {
        // K(5); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2, 3, 4])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 5)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-067 path P(5): colors [1, 0, 1, 0, 1]; 2 colors")
    func co067() {
        // P(5); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 0, 1, 0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-068 cycle C(5): colors [0, 1, 0, 1, 2]; 3 colors")
    func co068() {
        // C(5); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-069 cycle C(7): colors [0, 1, 0, 1, 0, 1, 2]; 3 colors")
    func co069() {
        // C(7); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-070 star(4): colors [0, 1, 1, 1, 1]; 2 colors")
    func co070() {
        // star(4); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 1, 1, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-071 wheel(5): colors [0, 1, 2, 1, 2, 3]; 4 colors")
    func co071() {
        // wheel(5); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2, 1, 2, 3])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-072 wheel(6): colors [0, 1, 2, 1, 2, 1, 2]; 3 colors")
    func co072() {
        // wheel(6); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2, 1, 2, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-073 Petersen: colors [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]; 3 colors")
    func co073() {
        // nx(petersen_graph); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-074 grid(3,4): colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors")
    func co074() {
        // grid(3,4); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-075 crown(4): colors [0, 0, 0, 0, 1, 1, 1, 1]; 2 colors")
    func co075() throws {
        // crown(4); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-076 crownx(5): DSatur is exact on bipartite graphs: colors [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]; 2 colors")
    func co076() {
        // crownx(5); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (2, 1), (2, 5), (2, 7), (2, 9), (4, 1), (4, 3), (4, 7), (4, 9), (6, 1), (6, 3), (6, 5), (6, 9), (8, 1), (8, 3), (8, 5), (8, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-077 vertex order, not label order: colors [0, 2, 1, 2]; 3 colors")
    func co077() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 2, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-078 nx(bull_graph): colors [2, 0, 1, 1, 0]; 3 colors")
    func co078() {
        // nx(bull_graph); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [2, 0, 1, 1, 0])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-079 nx(house_x_graph): colors [2, 3, 0, 1, 2]; 4 colors")
    func co079() {
        // nx(house_x_graph); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [2, 3, 0, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-080 nx(dodecahedral_graph): colors [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2]; 3 colors")
    func co080() {
        // nx(dodecahedral_graph); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-081 nx(chvatal_graph): colors [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3]; 4 colors")
    func co081() {
        // nx(chvatal_graph); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-082 nx(mycielski_graph,4): Groetzsch: colors [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0]; 4 colors")
    func co082() {
        // nx(mycielski_graph,4); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-083 nx(karate_club_graph)")
    func co083() {
        // nx(karate_club_graph); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 78)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0])
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 5)
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-084 two components: saturation 0 restarts at the greatest degree: colors [1, 0, 1, 0, 1, 1, 1]; 2 colors")
    func co084() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 1-2, 3-4, 3-5, 3-6]; greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 0, 1, 0, 1, 1, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-085 lcg(12,24,1): colors [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2]; 4 colors")
    func co085() {
        // lcg(12,24,1); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-086 lcg(20,50,7): colors [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1]; 4 colors")
    func co086() {
        // lcg(20,50,7); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 50)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-087 lcg(30,90,3)")
    func co087() {
        // lcg(30,90,3); greedyColoring(strategy: .saturationLargestFirst)
        let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 90)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3])
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
        // DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour
        // colours, then the greatest simple degree, then the lesser index, takes the least colour free.
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }
}
