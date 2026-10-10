// `minimumColoring()` (catalog §MinimumColoring, CO-254 – CO-281, the graphs of CO-167 – CO-194):
// proper (checked here), χ colours (ref.py's value, and `chromaticNumber()`), every colour used, the
// classes in `vertices` order, colours numbered by first appearance; the exact colours where they
// are forced (no edges; bipartite, the `bipartition()` sides; the only χ-colouring so numbered).
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

@Suite("minimumColoring()")
struct MinimumColoringTests {
    @Test("CO-254 empty graph: colors []; 0 colors")
    func co254() {
        // V []; E []; minimumColoring()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 0)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: no edges.
        #expect(colors == [])
    }

    @Test("CO-255 one vertex: colors [0]; 1 colors")
    func co255() {
        // V [0]; E []; minimumColoring()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 1)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: no edges.
        #expect(colors == [0])
    }

    @Test("CO-256 self-loop ignored: colors [0]; 1 colors")
    func co256() {
        // V [0]; E [0-0]; minimumColoring()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 1)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: no edges.
        #expect(colors == [0])
    }

    @Test("CO-257 two isolated: colors [0, 0]; 1 colors")
    func co257() {
        // V [0, 1]; E []; minimumColoring()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 1)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: no edges.
        #expect(colors == [0, 0])
    }

    @Test("CO-258 one edge: colors [0, 1]; 2 colors")
    func co258() throws {
        // V [0, 1]; E [0-1]; minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: bipartite, the sides.
        #expect(colors == [0, 1])
        // Bipartite: coloured by its bipartition() sides, left 0, right 1.
        let sides = try #require(graph.bipartition())
        #expect(sides.left.map { coloring.color(of: $0) }.allSatisfy { $0 == 0 })
        #expect(sides.right.map { coloring.color(of: $0) }.allSatisfy { $0 == 1 })
    }

    @Test("CO-259 parallel edges: colors [0, 1, 0]; 2 colors")
    func co259() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: bipartite, the sides.
        #expect(colors == [0, 1, 0])
        // Bipartite: coloured by its bipartition() sides, left 0, right 1.
        let sides = try #require(graph.bipartition())
        #expect(sides.left.map { coloring.color(of: $0) }.allSatisfy { $0 == 0 })
        #expect(sides.right.map { coloring.color(of: $0) }.allSatisfy { $0 == 1 })
    }

    @Test("CO-260 triangle: colors [0, 1, 2]; 3 colors")
    func co260() {
        // K(3); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: the only χ-colouring numbered by first appearance (exhaustive search).
        #expect(colors == [0, 1, 2])
    }

    @Test("CO-261 K(5): index order: colors [0, 1, 2, 3, 4]; 5 colors")
    func co261() {
        // K(5); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 5)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: the only χ-colouring numbered by first appearance (exhaustive search).
        #expect(colors == [0, 1, 2, 3, 4])
    }

    @Test("CO-262 path P(5): bipartition: colors [0, 1, 0, 1, 0]; 2 colors")
    func co262() throws {
        // P(5); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: bipartite, the sides.
        #expect(colors == [0, 1, 0, 1, 0])
        // Bipartite: coloured by its bipartition() sides, left 0, right 1.
        let sides = try #require(graph.bipartition())
        #expect(sides.left.map { coloring.color(of: $0) }.allSatisfy { $0 == 0 })
        #expect(sides.right.map { coloring.color(of: $0) }.allSatisfy { $0 == 1 })
    }

    @Test("CO-263 cycle C(5): 3 colors, proper, numbered by first appearance")
    func co263() {
        // C(5); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-264 cycle C(7): 3 colors, proper, numbered by first appearance")
    func co264() {
        // C(7); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-265 wheel(5): 4 colors, proper, numbered by first appearance")
    func co265() {
        // wheel(5); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 4 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-266 wheel(6): colors [0, 1, 2, 1, 2, 1, 2]; 3 colors")
    func co266() {
        // wheel(6); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: the only χ-colouring numbered by first appearance (exhaustive search).
        #expect(colors == [0, 1, 2, 1, 2, 1, 2])
    }

    @Test("CO-267 Petersen: 3 colors, proper, numbered by first appearance")
    func co267() {
        // nx(petersen_graph); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-268 crownx(4): 2 colours, where first fit needs 4: colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors")
    func co268() throws {
        // crownx(4); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (2, 1), (2, 5), (2, 7), (4, 1), (4, 3), (4, 7), (6, 1), (6, 3), (6, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 2)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: bipartite, the sides.
        #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1])
        // Bipartite: coloured by its bipartition() sides, left 0, right 1.
        let sides = try #require(graph.bipartition())
        #expect(sides.left.map { coloring.color(of: $0) }.allSatisfy { $0 == 0 })
        #expect(sides.right.map { coloring.color(of: $0) }.allSatisfy { $0 == 1 })
    }

    @Test("CO-269 first fit not optimal, so the search decides: 3 colors, proper, numbered by first appearance")
    func co269() {
        // V [0, 1, 2, 3, 4, 5]; E [0-2, 2-3, 3-1, 1-4, 4-5, 5-0, 2-5]; minimumColoring()
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-270 P4 numbered 0-2-3-1 beside a triangle: each component its own chi")
    func co270() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-2, 2-3, 3-1, 4-5, 5-6, 6-4]; minimumColoring()
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-271 vertex order, not label order: colors [0, 1, 2, 1]; 3 colors")
    func co271() {
        // V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c]; minimumColoring()
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // Forced, ref.py: the only χ-colouring numbered by first appearance (exhaustive search).
        #expect(colors == [0, 1, 2, 1])
    }

    @Test("CO-272 nx(mycielski_graph,4): Groetzsch: 4 colors, proper, numbered by first appearance")
    func co272() {
        // nx(mycielski_graph,4); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 4 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-273 nx(chvatal_graph): 4 colors, proper, numbered by first appearance")
    func co273() {
        // nx(chvatal_graph); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 4 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-274 queen(5): 5 colors, proper, numbered by first appearance")
    func co274() {
        // queen(5); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 160)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 5)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 5 in ref.py (= literature value (clique number 5)); the colours themselves depend on the search.
    }

    @Test("CO-275 nx(dodecahedral_graph): 3 colors, proper, numbered by first appearance")
    func co275() {
        // nx(dodecahedral_graph); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (certified: not bipartite, and the colouring has 3); the colours themselves depend on the search.
    }

    @Test("CO-276 nx(bull_graph): 3 colors, proper, numbered by first appearance")
    func co276() {
        // nx(bull_graph); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-277 nx(house_x_graph): 4 colors, proper, numbered by first appearance")
    func co277() {
        // nx(house_x_graph); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 4 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-278 lcg(12,24,1): 4 colors, proper, numbered by first appearance")
    func co278() {
        // lcg(12,24,1); minimumColoring()
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 4 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-279 lcg(14,40,5): 4 colors, proper, numbered by first appearance")
    func co279() {
        // lcg(14,40,5); minimumColoring()
        let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 40)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 4)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 4 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-280 lcg(16,60,9): 5 colors, proper, numbered by first appearance")
    func co280() {
        // lcg(16,60,9); minimumColoring()
        let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 60)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 5)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 5 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }

    @Test("CO-281 self-loops ignored in a bigger graph: 3 colors, proper, numbered by first appearance")
    func co281() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; minimumColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.minimumColoring()
        let colors = vertexList.map { coloring.color(of: $0) }
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        #expect(coloring.colorCount == 3)
        #expect(coloring.colorCount == graph.chromaticNumber())
        // Proper, checked here: the ends of every edge but a self-loop have different colours.
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b]) both \(colors[a])") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })
        // Numbered by first appearance: the first vertex has colour 0, and each colour first appears
        // after the one below it.
        var high = -1
        for c in colors {
            #expect(c <= high + 1, "\(colors)")
            high = max(high, c)
        }
        // χ = 3 in ref.py (= inclusion-exclusion count); the colours themselves depend on the search.
    }
}
