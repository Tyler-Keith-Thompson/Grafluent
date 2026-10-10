// `edgeColoring()` (catalog §EdgeColoring, and CO-253): Misra–Gries in position order as api.md
// documents it; exact colours by position; proper (checked here: the edges at each vertex differ);
// every colour used; classes ascending; Δ ≤ colours ≤ Δ + 1; and, on bipartite rows, König's Δ
// beside it. Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its
// edges in order, so rows are in position order (a self-loop twice); `multigraph` rows are
// `ReferencePseudograph`, whose rows are in position order too; `L …; R …` and the `Kb`, `crown` and
// `lcgb` rows are `BipartiteGraph(left:right:edges:)`. In-test oracles number vertices by their
// index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with
// ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GraphProtocols
import Testing

@Suite("edgeColoring()")
struct EdgeColoringTests {
    @Test("CO-195 empty graph: colors []; 0 colors")
    func co195() {
        // V []; E []; edgeColoring()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-196 one vertex: colors []; 0 colors")
    func co196() {
        // V [0]; E []; edgeColoring()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-197 one edge: colors [0]; 1 colors")
    func co197() {
        // V [0, 1]; E [0-1]; edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 1)
    }

    @Test("CO-198 path P(5): Delta 2: colors [0, 1, 0, 1]; 2 colors")
    func co198() {
        // P(5); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 0, 1])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 2)
    }

    @Test("CO-199 triangle: class 2, Delta + 1: colors [0, 1, 2]; 3 colors")
    func co199() {
        // K(3); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-200 K(4): class 1: colors [0, 1, 2, 3, 1, 0]; 4 colors")
    func co200() {
        // K(4); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 1, 0])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-201 K(5): class 2: colors [0, 1, 2, 3, 4, 1, 2, 3, 0, 4]; 5 colors")
    func co201() {
        // K(5); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 4, 1, 2, 3, 0, 4])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-202 cycle C(5): odd, 3: colors [0, 1, 0, 1, 2]; 3 colors")
    func co202() {
        // C(5); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 0, 1, 2])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-203 cycle C(6): colors [0, 1, 0, 1, 0, 1]; 2 colors")
    func co203() {
        // C(6); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 2)
    }

    @Test("CO-204 star(5): Delta: colors [0, 1, 2, 3, 4]; 5 colors")
    func co204() {
        // star(5); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 4])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 5)
    }

    @Test("CO-205 wheel(5): colors [0, 1, 2, 3, 4, 5, 0, 1, 0, 1]; 6 colors")
    func co205() {
        // wheel(5); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 4, 5, 0, 1, 0, 1])
        #expect(coloring.colorCount == 6)
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-206 Petersen: class 2, 4 colours: colors [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3]; 4 colors")
    func co206() {
        // nx(petersen_graph); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-207 grid(3,4): colors [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0]; 4 colors")
    func co207() {
        // grid(3,4); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 4)
    }

    @Test("CO-208 Kb(3,3): colors [0, 1, 2, 1, 2, 0, 2, 0, 1]; 3 colors")
    func co208() throws {
        // Kb(3,3); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 1, 2, 0, 2, 0, 1])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 3)
    }

    @Test("CO-209 nx(dodecahedral_graph)")
    func co209() {
        // nx(dodecahedral_graph); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 2, 1, 0, 1, 0, 1, 0])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-210 nx(karate_club_graph)")
    func co210() {
        // nx(karate_club_graph); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 78)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 14, 13, 16, 1, 2, 3, 4, 13, 6, 7, 0, 8, 2, 3, 4, 5, 6, 7, 3, 4, 5, 0, 1, 16, 0, 1, 2, 0, 1, 3, 0, 16, 0, 1, 3, 2, 2, 4, 5, 4, 6, 5, 7, 0, 1, 2, 6, 8, 1, 0, 2, 3, 0, 9, 10, 0, 11, 8, 12, 9, 13, 10, 15, 14])
        #expect(coloring.colorCount == 17)
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-211 edge order matters: C(4) listed 0-1, 2-3, 1-2, 3-0: colors [0, 0, 1, 1]; 2 colors")
    func co211() {
        // V [0, 1, 2, 3]; E [0-1, 2-3, 1-2, 3-0]; edgeColoring()
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 0, 1, 1])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 2)
    }

    @Test("CO-212 lcg(12,24,1): colors [0, 0, 1, 1, 2, 0, 4, 3, 1, 1, 3, 3, 1, 2, 4, 3, 0, 4, 2, 5, 0, 2, 6, 5]; 7 colors")
    func co212() {
        // lcg(12,24,1); edgeColoring()
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10), (1, 8), (2, 7), (7, 10), (9, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 0, 1, 1, 2, 0, 4, 3, 1, 1, 3, 3, 1, 2, 4, 3, 0, 4, 2, 5, 0, 2, 6, 5])
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-213 lcg(20,50,7)")
    func co213() {
        // lcg(20,50,7); edgeColoring()
        let pairs: [(Int, Int)] = [(18, 11), (5, 19), (19, 6), (12, 0), (9, 2), (16, 11), (16, 13), (14, 18), (13, 4), (0, 5), (13, 12), (12, 17), (10, 15), (13, 19), (9, 7), (5, 15), (8, 10), (0, 4), (6, 10), (12, 14), (17, 8), (14, 11), (8, 16), (6, 3), (3, 0), (12, 18), (1, 18), (10, 3), (8, 5), (10, 14), (12, 15), (16, 12), (17, 19), (18, 7), (5, 1), (17, 14), (8, 18), (15, 16), (5, 3), (16, 6), (5, 12), (15, 4), (1, 3), (8, 0), (5, 14), (2, 1), (10, 7), (7, 6), (18, 10), (5, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 50)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 3, 3, 1, 2, 1, 2, 2, 3, 0, 2, 2, 0, 3, 4, 2, 4, 3, 0, 5, 6, 2, 3, 4, 4, 5, 7, 5, 3, 7, 0, 6, 4, 6, 1, 5, 4, 6, 8])
        #expect(coloring.colorCount == 9)
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-214 lcg(30,90,3)")
    func co214() {
        // lcg(30,90,3); edgeColoring()
        let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19), (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (14, 11), (1, 20), (7, 25), (5, 21), (11, 7), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8), (2, 4), (25, 16), (3, 4), (26, 29), (6, 17), (11, 25), (23, 29), (15, 26), (6, 28), (6, 2), (16, 18), (21, 27), (0, 23), (18, 21), (6, 3), (18, 17), (25, 8), (22, 15), (23, 14), (21, 10), (13, 19), (20, 17), (6, 18), (12, 17), (11, 24), (23, 6), (22, 0), (15, 16), (6, 8), (19, 7), (7, 13), (26, 11), (11, 17), (24, 15), (14, 18), (9, 6), (23, 28), (6, 19), (26, 22), (20, 12), (10, 29), (2, 27), (14, 24), (28, 18), (2, 23), (27, 29), (20, 6), (27, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 90)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 6, 1, 1, 1, 4, 0, 2, 1, 2, 0, 0, 3, 1, 3, 0, 0, 3, 3, 8, 4, 5, 4, 2, 0, 2, 5, 8, 1, 4, 2, 4, 1, 4, 6, 6, 1, 7, 8, 1, 4, 0, 0, 6, 1, 2, 2, 5, 3, 3, 3, 12, 7, 1, 6, 2, 6, 4, 8, 4, 0, 3, 8, 5, 5, 0, 6, 8, 1, 5, 9, 9, 10, 7, 3, 2, 6, 10, 2, 11, 9, 2, 5, 2, 9, 8, 7, 6, 7, 0])
        #expect(coloring.colorCount == 13)
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
    }

    @Test("CO-253 lcgb(8,5,30,11): Delta + 1 on a bipartite graph (bipartiteEdgeColoring gives Delta, CO-228)")
    func co253() {
        // lcgb(8,5,30,11); edgeColoring()
        let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9), (3, 9), (5, 8), (3, 11), (1, 12), (4, 10), (1, 11), (6, 9), (1, 8), (2, 10), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let coloring = graph.edgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 0, 1, 0, 2, 1, 2, 3, 0, 4, 0, 4, 3, 1, 3, 3, 5, 2, 1, 1, 4, 4, 5, 3, 4, 6, 2, 7, 5, 5])
        #expect(coloring.colorCount == 8)
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
        // Vizing: Δ ≤ colours ≤ Δ + 1.
        #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
        // On a bipartite graph König's colouring has exactly Δ.
        #expect(graph.bipartiteEdgeColoring()?.colorCount == 7)
    }
}
