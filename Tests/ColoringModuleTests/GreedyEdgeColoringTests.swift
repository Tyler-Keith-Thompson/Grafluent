// `greedyEdgeColoring()`: rustworkx `graph_greedy_edge_color`, the largest-first colouring of the
// line graph. Each row's colours by position are rustworkx 0.18.1's on a `PyGraph(multigraph=True)`
// with the same edges in the same order; each test also checks properness by the definition (the
// edges at each vertex differ, a self-loop met once there, as `isEdgeColoring(_:)` meets it), every
// colour used, classes ascending, at most 2Δ − 1 colours (Δ counting edge ends), and the procedure
// written out: edges by the number of other edges they share an end with (a parallel copy at both
// ends, a self-loop once at its vertex), most first, ties by position, each taking the least colour
// of no coloured edge it shares an end with. Then `digraph.undirected` with an antiparallel pair,
// which `edgeColoring()` rejects; random multigraphs with loops against the procedure; and a
// graph with no edge indices whose positions are not 0..<m. See README.md.

import AdjacencyListModule
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

/// An undirected graph with no vertex or edge indices whose edge positions are 10 apart (0, 10,
/// 20, …), so a position is not an offset. Rows are in position order, a self-loop's twice.
private struct SpacedEdgesGraph: Graph {
    struct Edges: Collection {
        let list: [UndirectedEdge<Int>]
        var startIndex: Int { 0 }
        var endIndex: Int { 10 * list.count }
        func index(after i: Int) -> Int { i + 10 }
        subscript(position: Int) -> UndirectedEdge<Int> { list[position / 10] }
    }

    let vertices: [Int]
    let edges: Edges

    init(vertices: [Int], edges: [UndirectedEdge<Int>]) {
        self.vertices = vertices
        self.edges = Edges(list: edges)
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        edges.list.indices.flatMap { k in [edges.list[k].u, edges.list[k].v].filter { $0 == vertex }.map { _ in 10 * k } }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("greedyEdgeColoring()")
struct GreedyEdgeColoringTests {
    @Test("the empty graph: rustworkx's colours []")
    func theEmptyGraph() {
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 0, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("rustworkx's example, a triangle with a pendant: rustworkx's colours [2, 0, 1, 2]")
    func rustworkxExampleATriangleWithAPendant() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [2, 0, 1, 2])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("K4: rustworkx's colours [0, 1, 2, 2, 1, 0]")
    func k4() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 2, 1, 0])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("the cycle C5: rustworkx's colours [0, 1, 0, 1, 2]")
    func theCycleC5() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 0, 1, 2])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("Petersen (NetworkX's numbering): rustworkx's colours [0, 1, 2, 1, 2, 0, 2, 2, 1, 0, 0, 3, 0, 1, 3]")
    func petersenNetworkxNumbering() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 1, 2, 0, 2, 2, 1, 0, 0, 3, 0, 1, 3])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("the star K1,3: rustworkx's colours [0, 1, 2]")
    func theStarK13() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("three parallel copies of 0–1 and an edge 1–2 (multigraph): rustworkx's colours [0, 1, 3, 2]")
    func threeParallelCopiesOf01AndAnEdge12Multig() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (0, 1)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 3, 2])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("a self-loop and an edge at vertex 0: rustworkx's colours [0, 1]")
    func aSelfLoopAndAnEdgeAtVertex0() {
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("two self-loops and an edge at vertex 0: rustworkx's colours [0, 1, 2]")
    func twoSelfLoopsAndAnEdgeAtVertex0() {
        let pairs: [(Int, Int)] = [(0, 0), (0, 0), (0, 1)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("an isolated self-loop: rustworkx's colours [0]")
    func anIsolatedSelfLoop() {
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("an antiparallel pair 0–1, 1–0 and 1–2: rustworkx's colours [0, 1, 2]")
    func anAntiparallelPair0110And12() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("Shannon's triangle, every edge doubled: 6 colours, 3Δ/2: rustworkx's colours [0, 1, 2, 3, 4, 5]")
    func shannonTriangleEveryEdgeDoubled6Colours3() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (1, 2), (0, 2), (0, 2)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount, m = pairs.count
        let coloring = graph.greedyEdgeColoring()
        let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
        #expect(colors == [0, 1, 2, 3, 4, 5])
        // Proper: the edges at each vertex differ, a self-loop counted once.
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }.map { colors[$0] }
            #expect(Set(at).count == at.count, "at \(v): \(at)")
        }
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })
        // At most 2Δ − 1, Δ counting edge ends (a self-loop 2).
        let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
        #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1))
        // The procedure written out on the line graph: meets[e] lists, per shared end, the other edges.
        var meets = [[Int]](repeating: [], count: m)
        for v in 0 ..< n {
            let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
            for e in at { for f in at where f != e { meets[e].append(f) } }
        }
        let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
        var expected = [Int](repeating: -1, count: m)
        for e in order {
            var c = 0
            while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
            expected[e] = c
        }
        #expect(colors == expected)
    }

    @Test("digraph.undirected with an antiparallel pair (AdjacencyList, arcs 0→1, 1→0, 1→2): [0, 1, 2], where edgeColoring() traps")
    func antiparallelArcs() {
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)]).undirected
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 0], [1, 2]])
        let coloring = graph.greedyEdgeColoring()
        #expect(graph.edges.indices.map { coloring.color(ofEdgeAt: $0) } == [0, 1, 2])
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
    }

    @Test("A graph without edge indices whose positions are 0, 10, 20, …: greedyEdgeColoring(), edgeColoring() and bipartiteEdgeColoring() by position")
    func unindexedPositions() throws {
        // The path 0–1–2–3 and the chord 0–3: C4, bipartite.
        let graph = SpacedEdgesGraph(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(graph.edgeIndexBound == nil && graph.vertexIndexBound == nil)
        #expect(Array(graph.edges.indices) == [0, 10, 20, 30])
        // Every edge meets two others: position order, first fit [0, 1, 0, 1].
        let greedy = graph.greedyEdgeColoring()
        #expect([0, 10, 20, 30].map { greedy.color(ofEdgeAt: $0) } == [0, 1, 0, 1])
        #expect(greedy.colorClasses.map { Array($0) } == [[0, 20], [10, 30]])
        let misraGries = graph.edgeColoring()
        #expect(graph.isEdgeColoring { misraGries.color(ofEdgeAt: $0) })
        #expect(misraGries.colorClasses.flatMap { $0 }.sorted() == [0, 10, 20, 30])
        let koenig = try #require(graph.bipartiteEdgeColoring())
        #expect(koenig.colorCount == 2)
        #expect(graph.isEdgeColoring { koenig.color(ofEdgeAt: $0) })
        #expect(koenig.colorClasses.flatMap { $0 }.sorted() == [0, 10, 20, 30])
    }

    @Test("On random multigraphs with self-loops: the procedure written out, proper, at most 2Δ − 1", .tags(.randomized))
    func againstProcedure() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 8)) { raw, n in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let m = pairs.count
            let graph = ReferencePseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let coloring = graph.greedyEdgeColoring()
            let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
            var meets = [[Int]](repeating: [], count: m)
            for v in 0 ..< n {
                let at = (0 ..< m).filter { pairs[$0].0 == v || pairs[$0].1 == v }
                #expect(Set(at.map { colors[$0] }).count == at.count, "\(pairs)")
                for e in at { for f in at where f != e { meets[e].append(f) } }
            }
            #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) }, "\(pairs)")
            let degree = (0 ..< n).map { v in pairs.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }
            #expect(coloring.colorCount <= max(0, 2 * (degree.max() ?? 0) - 1), "\(pairs)")
            let order = (0 ..< m).sorted { (meets[$0].count, $1) > (meets[$1].count, $0) }
            var expected = [Int](repeating: -1, count: m)
            for e in order {
                var c = 0
                while meets[e].contains(where: { expected[$0] == c }) { c += 1 }
                expected[e] = c
            }
            #expect(colors == expected, "\(pairs)")
        }
    }
}
