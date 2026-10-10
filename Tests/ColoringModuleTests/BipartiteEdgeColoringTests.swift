// `bipartiteEdgeColoring()` (catalog §BipartiteEdgeColoring): König's alternating-path recolouring
// in position order; exact colours by position; proper (checked here), parallel edges included;
// exactly Δ colours; nil exactly when the graph has an odd cycle. Graphs are
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

@Suite("bipartiteEdgeColoring()")
struct BipartiteEdgeColoringTests {
    @Test("CO-217 empty graph: colors []; 0 colors")
    func co217() throws {
        // V []; E []; bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [])
        #expect(coloring.colorCount == 0)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-218 one edge: colors [0]; 1 colors")
    func co218() throws {
        // V [0, 1]; E [0-1]; bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0])
        #expect(coloring.colorCount == 1)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-219 path P(6): colors [0, 1, 0, 1, 0]; 2 colors")
    func co219() throws {
        // P(6); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 0, 1, 0])
        #expect(coloring.colorCount == 2)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-220 cycle C(6): colors [0, 1, 0, 1, 0, 1]; 2 colors")
    func co220() throws {
        // C(6); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1])
        #expect(coloring.colorCount == 2)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-221 Kb(3,3): Latin square: colors [2, 0, 1, 1, 2, 0, 0, 1, 2]; 3 colors")
    func co221() throws {
        // Kb(3,3); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [2, 0, 1, 1, 2, 0, 0, 1, 2])
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-222 Kb(2,4): colors [1, 2, 3, 0, 0, 1, 2, 3]; 4 colors")
    func co222() throws {
        // Kb(2,4); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [1, 2, 3, 0, 0, 1, 2, 3])
        #expect(coloring.colorCount == 4)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-223 crown(4): colors [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2]; 3 colors")
    func co223() throws {
        // crown(4); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (1, 4), (1, 6), (1, 7), (2, 4), (2, 5), (2, 7), (3, 4), (3, 5), (3, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2])
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-224 grid(3,4): colors [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0]; 4 colors")
    func co224() throws {
        // grid(3,4); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0])
        #expect(coloring.colorCount == 4)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-225 nx(heawood_graph): colors [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 0]; 3 colors")
    func co225() throws {
        // nx(heawood_graph); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 21)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 0])
        #expect(coloring.colorCount == 3)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-226 bipartite multigraph: parallel edges need different colours: colors [0, 1, 3, 2]; 4 colors")
    func co226() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2, 0-1]; bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (0, 1)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 3, 2])
        #expect(coloring.colorCount == 4)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-227 lcgb(6,6,20,4): colors [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3]; 5 colors")
    func co227() throws {
        // lcgb(6,6,20,4); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(2, 10), (4, 11), (5, 11), (1, 11), (1, 8), (2, 8), (5, 7), (0, 7), (0, 10), (2, 7), (3, 10), (2, 11), (1, 6), (3, 8), (4, 8), (2, 9), (0, 9), (4, 6), (3, 6), (1, 7)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3])
        #expect(coloring.colorCount == 5)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-228 lcgb(8,5,30,11)")
    func co228() throws {
        // lcgb(8,5,30,11); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], right: [8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = try #require(graph.bipartiteEdgeColoring())
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [2, 5, 3, 3, 1, 2, 1, 4, 0, 0, 0, 4, 4, 3, 6, 2, 2, 1, 3, 5, 3, 5, 4, 1, 5, 2, 1, 4, 0, 0])
        #expect(coloring.colorCount == 7)
        // Proper, checked here: the edges at each vertex have different colours.
        for v in 0 ..< n {
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(vertexList[v]): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        // Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // Δ counts edge ends (parallel edges each).
        let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
        // König: exactly Δ colours.
        #expect(coloring.colorCount == maxDegree)
        #expect(graph.bipartition() != nil)
    }

    @Test("CO-229 triangle: nil")
    func co229() {
        // K(3); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.bipartiteEdgeColoring() == nil)
        // Not bipartite: an odd cycle (a self-loop is one of length 1).
        #expect(graph.bipartition() == nil)
        #expect(graph.findOddCycle() != nil)
    }

    @Test("CO-230 self-loop: nil")
    func co230() {
        // V [0, 1]; E [0-1, 1-1]; bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.bipartiteEdgeColoring() == nil)
        // Not bipartite: an odd cycle (a self-loop is one of length 1).
        #expect(graph.bipartition() == nil)
        #expect(graph.findOddCycle() != nil)
    }

    @Test("CO-231 Petersen: nil")
    func co231() {
        // nx(petersen_graph); bipartiteEdgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.bipartiteEdgeColoring() == nil)
        // Not bipartite: an odd cycle (a self-loop is one of length 1).
        #expect(graph.bipartition() == nil)
        #expect(graph.findOddCycle() != nil)
    }
}
