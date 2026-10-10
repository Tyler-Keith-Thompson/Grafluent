// `greedyColoring(strategy: .independentSet)` (catalog §Greedy.independentSet): colour k a maximal
// independent set of the uncoloured vertices, least available degree first, the lesser index on
// ties; exact; proper (checked here); at most Δ + 1 colours; a first-fit colouring; the strategy
// written out; at least `chromaticNumber()` colours. Graphs are `UndirectedAdjacencyList` built by
// inserting the row's vertices, then its edges in order, so rows are in position order (a self-loop
// twice); `multigraph` rows are `ReferencePseudograph`, whose rows are in position order too; `L …;
// R …` and the `Kb`, `crown` and `lcgb` rows are `BipartiteGraph(left:right:edges:)`. In-test
// oracles number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py,
// which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import ColoringModule
import GraphProtocols
import Testing

@Suite("greedyColoring(strategy: .independentSet)")
struct GreedyIndependentSetTests {
    @Test("CO-004 empty graph: colors []; 0 colors")
    func co004() {
        // V []; E []; greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-010 one vertex: colors [0]; 1 colors")
    func co010() {
        // V [0]; E []; greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-024 self-loops ignored; also in the degree that orders: colors [0, 1, 2, 0]; 3 colors")
    func co024() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2, 0])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-088 triangle: colors [0, 1, 2]; 3 colors")
    func co088() {
        // K(3); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-089 path P(5): colors [0, 1, 0, 1, 0]; 2 colors")
    func co089() {
        // P(5); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-090 cycle C(5): colors [0, 1, 0, 1, 2]; 3 colors")
    func co090() {
        // C(5); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-091 star(4): leaves first: colors [1, 0, 0, 0, 0]; 2 colors")
    func co091() {
        // star(4); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 0, 0, 0, 0])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-092 wheel(5): colors [2, 0, 1, 0, 1, 3]; 4 colors")
    func co092() {
        // wheel(5); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [2, 0, 1, 0, 1, 3])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-093 Petersen: colors [0, 1, 0, 1, 2, 1, 2, 2, 0, 0]; 3 colors")
    func co093() {
        // nx(petersen_graph); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 2, 1, 2, 2, 0, 0])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-094 grid(3,4): colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors")
    func co094() {
        // grid(3,4); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-095 crownx(4): colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors")
    func co095() {
        // crownx(4); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-096 nx(bull_graph): colors [0, 1, 2, 0, 0]; 3 colors")
    func co096() {
        // nx(bull_graph); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 2, 0, 0])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-097 nx(karate_club_graph)")
    func co097() {
        // nx(karate_club_graph); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 78)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-098 lcg(12,24,1): colors [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1]; 5 colors")
    func co098() {
        // lcg(12,24,1); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-099 lcg(20,50,7): colors [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0]; 4 colors")
    func co099() {
        // lcg(20,50,7); greedyColoring(strategy: .independentSet)
        let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 50)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .independentSet)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0])
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
        // Independent set written out: colour k is a maximal independent set of the uncoloured vertices,
        // built by taking the available vertex with the fewest available neighbours (the lesser index on
        // ties) and making it and its neighbours unavailable.
        var expected = [Int](repeating: -1, count: n)
        var k = 0
        while expected.contains(-1) {
            var available = Set((0 ..< n).filter { expected[$0] < 0 })
            while true {
                let left = available
                guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                expected[v] = k
                available.remove(v)
                for w in adjacent[v] { available.remove(w) }
            }
            k += 1
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }
}
