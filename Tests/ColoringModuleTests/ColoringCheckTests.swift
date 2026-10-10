// `isColoring(_:)` and `isEdgeColoring(_:)` (catalog §Checks) against their definitions, written out
// here; the closure called once per vertex, or once per edge. Graphs are `UndirectedAdjacencyList`
// built by inserting the row's vertices, then its edges in order, so rows are in position order (a
// self-loop twice); `multigraph` rows are `ReferencePseudograph`, whose rows are in position order
// too; `L …; R …` and the `Kb`, `crown` and `lcgb` rows are `BipartiteGraph(left:right:edges:)`.
// In-test oracles number vertices by their index in `vertices`. Generated from cases.md by
// swiftgen.py, which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Checks: isColoring, isEdgeColoring")
struct ColoringCheckTests {
    @Test("CO-232 empty colouring of the empty graph: true")
    func co232() {
        // V []; E []; isColoring { [][$0] }
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [] as [Int]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-233 one colour on an edge: false")
    func co233() {
        // V [0, 1]; E [0-1]; isColoring { [0, 0][$0] }
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 0]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == false)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-234 two colours on an edge: true")
    func co234() {
        // V [0, 1]; E [0-1]; isColoring { [0, 1][$0] }
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-235 self-loop ignored: true")
    func co235() {
        // V [0]; E [0-0]; isColoring { [0][$0] }
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-236 self-loop ignored with a proper rest: true")
    func co236() {
        // V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2]; isColoring { [0, 1, 2, 0][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1, 2, 0]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-237 parallel edges: true")
    func co237() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isColoring { [0, 1, 0][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1, 0]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-238 triangle with a repeat: false")
    func co238() {
        // K(3); isColoring { [0, 1, 1][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1, 1]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == false)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-239 colours need not be 0..<k or contiguous: true")
    func co239() {
        // P(3); isColoring { [7, -2, 7][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [7, -2, 7]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-240 Petersen, a greedy colouring: true")
    func co240() {
        // nx(petersen_graph); isColoring { [0, 1, 0, 1, 2, 1, 0, 2, 2, 1][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]
        // The definition, written out: no edge but a self-loop has ends of one colour.
        let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }
        #expect(proper == true)
        var calls = 0
        let result = graph.isColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }
        #expect(result == proper)
        #expect(calls == n)
    }

    @Test("CO-241 empty: true")
    func co241() {
        // V []; E []; isEdgeColoring { [][$0] }
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [] as [Int]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == true)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }

    @Test("CO-242 path, alternating: true")
    func co242() {
        // P(4); isEdgeColoring { [0, 1, 0][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1, 0]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == true)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }

    @Test("CO-243 path, repeat at a shared end: false")
    func co243() {
        // P(4); isEdgeColoring { [0, 0, 1][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 0, 1]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == false)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }

    @Test("CO-244 parallel edges share both ends: false")
    func co244() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isEdgeColoring { [0, 0, 1][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 0, 1]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == false)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }

    @Test("CO-245 parallel edges, distinct: true")
    func co245() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isEdgeColoring { [0, 1, 2][$0] }
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1, 2]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == true)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }

    @Test("CO-246 a self-loop meets the other edges at its vertex: false")
    func co246() {
        // V [0, 1]; E [0-0, 0-1]; isEdgeColoring { [0, 0][$0] }
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 0]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == false)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }

    @Test("CO-247 a self-loop alone: true")
    func co247() {
        // V [0]; E [0-0]; isEdgeColoring { [0][$0] }
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0]
        // The definition, written out: the edges at each vertex (a self-loop once) have different colours.
        let proper = (0 ..< n).allSatisfy { v in
            let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }
            return Set(at).count == at.count
        }
        #expect(proper == true)
        var calls = 0
        let result = graph.isEdgeColoring { calls += 1; return given[$0] }
        #expect(result == proper)
        #expect(calls == graph.edgeCount)
    }
}
