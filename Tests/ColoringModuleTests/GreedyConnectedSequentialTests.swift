// `greedyColoring(strategy: .connectedSequentialBreadthFirst)` and `.connectedSequentialDepthFirst`
// (catalog §Greedy.connectedSequential…): first fit in breadth-first or depth-first preorder,
// components by least vertex, each from its least vertex, neighbours in row order; exact; proper
// (checked here); at most Δ + 1 colours; a first-fit colouring; the search written out; at least
// `chromaticNumber()` colours. Graphs are `UndirectedAdjacencyList` built by inserting the row's
// vertices, then its edges in order, so rows are in position order (a self-loop twice); `multigraph`
// rows are `ReferencePseudograph`, whose rows are in position order too; `L …; R …` and the `Kb`,
// `crown` and `lcgb` rows are `BipartiteGraph(left:right:edges:)`. In-test oracles number vertices
// by their index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row
// with ref.py's model; see README.md.

import AdjacencyListModule
import ColoringModule
import GraphProtocols
import Testing

@Suite("greedyColoring(strategy: .connectedSequential…)")
struct GreedyConnectedSequentialTests {
    @Test("CO-005 empty graph: colors []; 0 colors")
    func co005() {
        // V []; E []; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-006 empty graph: colors []; 0 colors")
    func co006() {
        // V []; E []; greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-011 one vertex: colors [0]; 1 colors")
    func co011() {
        // V [0]; E []; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-012 one vertex: colors [0]; 1 colors")
    func co012() {
        // V [0]; E []; greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-025 self-loops ignored; also in the degree that orders: colors [0, 1, 2, 0]; 3 colors")
    func co025() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-100 path P(5): colors [0, 1, 0, 1, 0]; 2 colors")
    func co100() {
        // P(5); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-101 path P(5): colors [0, 1, 0, 1, 0]; 2 colors")
    func co101() {
        // P(5); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-102 cycle C(6): colors [0, 1, 0, 1, 0, 1]; 2 colors")
    func co102() {
        // C(6); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1])
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-103 cycle C(6): colors [0, 1, 0, 1, 0, 1]; 2 colors")
    func co103() {
        // C(6); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1])
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-104 star(4): colors [0, 1, 1, 1, 1]; 2 colors")
    func co104() {
        // star(4); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-105 star(4): colors [0, 1, 1, 1, 1]; 2 colors")
    func co105() {
        // star(4); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-106 Petersen: colors [0, 1, 0, 2, 1, 1, 0, 3, 3, 2]; 4 colors")
    func co106() {
        // nx(petersen_graph); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 2, 1, 1, 0, 3, 3, 2])
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-107 Petersen: colors [0, 1, 0, 1, 2, 1, 2, 2, 0, 0]; 3 colors")
    func co107() {
        // nx(petersen_graph); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-108 grid(3,4): colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors")
    func co108() {
        // grid(3,4); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-109 grid(3,4): colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors")
    func co109() {
        // grid(3,4); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-110 crownx(4): colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors")
    func co110() {
        // crownx(4); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-111 crownx(4): colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors")
    func co111() {
        // crownx(4); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-112 two components, least vertex roots each: colors [0, 0, 1, 0, 1, 1, 0]; 2 colors")
    func co112() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-4, 4-6, 1-2, 2-3, 3-5, 5-1]; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 1, 0, 1, 1, 0])
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-113 two components, least vertex roots each: colors [0, 0, 1, 0, 1, 1, 0]; 2 colors")
    func co113() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-4, 4-6, 1-2, 2-3, 3-5, 5-1]; greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 1, 0, 1, 1, 0])
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-114 component {5, 9}-style: root is the least vertex, not a set's first")
    func co114() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [9-5, 0-1, 1-2, 2-3, 3-4, 6-7, 7-8, 8-6]; greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-115 component {5, 9}-style: root is the least vertex, not a set's first")
    func co115() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [9-5, 0-1, 1-2, 2-3, 3-4, 6-7, 7-8, 8-6]; greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 0, 0, 1, 2, 1])
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-116 lcg(12,24,1): colors [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0]; 4 colors")
    func co116() {
        // lcg(12,24,1); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0])
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-117 lcg(12,24,1): colors [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0]; 4 colors")
    func co117() {
        // lcg(12,24,1); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0])
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-118 lcg(20,50,7): colors [0, 3, 0, 1, 1, 2, 0, 1, 1, 2, 2, 1, 1, 0, 3, 0, 2, 0, 0, 1]; 4 colors")
    func co118() {
        // lcg(20,50,7); greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 50)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialBreadthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 3, 0, 1, 1, 2, 0, 1, 1, 2, 2, 1, 1, 0, 3, 0, 2, 0, 0, 1])
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
        // Connected sequential breadth-first written out: each component from its least vertex, neighbours
        // in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            var queue = [root]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                order.append(v)
                for w in adjacent[v] where !seen[w] {
                    seen[w] = true
                    queue.append(w)
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }

    @Test("CO-119 lcg(20,50,7): colors [0, 0, 1, 1, 1, 2, 3, 1, 1, 0, 0, 0, 1, 0, 3, 3, 2, 0, 2, 1]; 4 colors")
    func co119() {
        // lcg(20,50,7); greedyColoring(strategy: .connectedSequentialDepthFirst)
        let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 50)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.greedyColoring(strategy: .connectedSequentialDepthFirst)
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 1, 1, 1, 2, 3, 1, 1, 0, 0, 0, 1, 0, 3, 3, 2, 0, 2, 1])
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
        // Connected sequential depth-first written out: each component from its least vertex, preorder,
        // neighbours in row order; then first fit.
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        for root in 0 ..< n where !seen[root] {
            seen[root] = true
            order.append(root)
            var stack = [(root, 0)]
            while let (v, k) = stack.last {
                if k == adjacent[v].count {
                    stack.removeLast()
                    continue
                }
                stack[stack.count - 1].1 += 1
                let w = adjacent[v][k]
                if !seen[w] {
                    seen[w] = true
                    order.append(w)
                    stack.append((w, 0))
                }
            }
        }
        var expected = [Int](repeating: -1, count: n)
        for v in order {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        // No colouring uses fewer than χ colours.
        #expect(coloring.colorCount >= graph.chromaticNumber())
    }
}
