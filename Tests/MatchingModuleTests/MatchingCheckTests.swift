// `isMatching`, `isMaximalMatching` and `isPerfectMatching` (catalog §Checks, MA-035 – MA-051) on
// the row's positions, against the definitions written out here, in the given order and reversed.
// Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in
// order, so rows are in position order; `multigraph` rows are `ReferencePseudograph`, whose rows are
// in position order too (a self-loop twice, parallel edges kept); `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Generated from cases.md by swiftgen.py, which re-evaluates
// each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("isMatching, isMaximalMatching, isPerfectMatching")
struct MatchingCheckTests {
    @Test("MA-035 empty set on the empty graph: true / true / true")
    func ma035() {
        // V []; E []; isMatching / isMaximalMatching / isPerfectMatching([])
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let candidate: [Int] = []
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }

    @Test("MA-036 empty set on one edge (a matching, not maximal): true / false / false")
    func ma036() {
        // V [0, 1]; E [0-1]; isMatching / isMaximalMatching / isPerfectMatching([])
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let candidate: [Int] = []
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-037 one edge: true / true / true")
    func ma037() {
        // V [0, 1]; E [0-1]; isMatching / isMaximalMatching / isPerfectMatching([0])
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let candidate: [Int] = [0]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }

    @Test("MA-038 P4 middle edge: true / true / false")
    func ma038() {
        // P(4); isMatching / isMaximalMatching / isPerfectMatching([1])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let candidate: [Int] = [1]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-039 P4 outer edges: true / true / true")
    func ma039() {
        // P(4); isMatching / isMaximalMatching / isPerfectMatching([0, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let candidate: [Int] = [0, 2]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }

    @Test("MA-040 P4 adjacent edges: false / false / false")
    func ma040() {
        // P(4); isMatching / isMaximalMatching / isPerfectMatching([0, 1])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let candidate: [Int] = [0, 1]
        #expect(graph.isMatching(candidate) == false)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == false && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == false)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-041 P4 all edges: false / false / false")
    func ma041() {
        // P(4); isMatching / isMaximalMatching / isPerfectMatching([0, 1, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let candidate: [Int] = [0, 1, 2]
        #expect(graph.isMatching(candidate) == false)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == false && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == false)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-042 self-loop alone (a self-loop is never in a matching (NetworkX agrees)): false / false / false")
    func ma042() {
        // V [0]; E [0-0]; isMatching / isMaximalMatching / isPerfectMatching([0])
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let candidate: [Int] = [0]
        #expect(graph.isMatching(candidate) == false)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == false && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == false)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-043 self-loop with an edge: false / false / false")
    func ma043() {
        // V [0, 1, 2]; E [0-0, 1-2]; isMatching / isMaximalMatching / isPerfectMatching([0, 1])
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let candidate: [Int] = [0, 1]
        #expect(graph.isMatching(candidate) == false)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == false && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == false)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-044 loop graph, loops ignored for maximality (vertex 0 has only a loop; the matching is still maximal)")
    func ma044() {
        // V [0, 1, 2]; E [0-0, 1-2]; isMatching / isMaximalMatching / isPerfectMatching([1])
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let candidate: [Int] = [1]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-045 repeated position (the same edge twice shares its endpoints): false / false / false")
    func ma045() {
        // V [0, 1]; E [0-1]; isMatching / isMaximalMatching / isPerfectMatching([0, 0])
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let candidate: [Int] = [0, 0]
        #expect(graph.isMatching(candidate) == false)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == false && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == false)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-046 parallel copies both listed: false / false / false")
    func ma046() {
        // multigraph V [0, 1]; E [0-1, 1-0]; isMatching / isMaximalMatching / isPerfectMatching([0, 1])
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let candidate: [Int] = [0, 1]
        #expect(graph.isMatching(candidate) == false)
        #expect(graph.isMaximalMatching(candidate) == false)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == false && isMaximal == false && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == false)
        #expect(graph.isMaximalMatching(candidate.reversed()) == false)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-047 one parallel copy: true / true / true")
    func ma047() {
        // multigraph V [0, 1]; E [0-1, 1-0]; isMatching / isMaximalMatching / isPerfectMatching([1])
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let candidate: [Int] = [1]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }

    @Test("MA-048 K4 perfect: true / true / true")
    func ma048() {
        // K(4); isMatching / isMaximalMatching / isPerfectMatching([0, 5])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let candidate: [Int] = [0, 5]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }

    @Test("MA-049 NetworkX valid_not_path (positions of 0–3, 2–5, 1–4): true / true / true")
    func ma049() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 0-3, 0-4, 1-2, 1-4, 2-5, 3-4, 4-5]; isMatching / isMaximalMatching / isPerfectMatching([1, 4, 5])
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 4), (1, 2), (1, 4), (2, 5), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let candidate: [Int] = [1, 4, 5]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }

    @Test("MA-050 isolated vertex blocks perfection: true / true / false")
    func ma050() {
        // V [0, 1, 2]; E [0-1]; isMatching / isMaximalMatching / isPerfectMatching([0])
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let candidate: [Int] = [0]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == false)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == false)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == false)
    }

    @Test("MA-051 unordered position list: true / true / true")
    func ma051() {
        // K(4); isMatching / isMaximalMatching / isPerfectMatching([5, 0])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let candidate: [Int] = [5, 0]
        #expect(graph.isMatching(candidate) == true)
        #expect(graph.isMaximalMatching(candidate) == true)
        #expect(graph.isPerfectMatching(candidate) == true)
        // The definitions, checked here.
        var ends: [Int] = []
        for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }
        let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count
        let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }
        let isPerfect = isMatching && ends.count == graph.vertexCount
        #expect(isMatching == true && isMaximal == true && isPerfect == true)
        // Order does not matter: the same positions reversed.
        #expect(graph.isMatching(candidate.reversed()) == true)
        #expect(graph.isMaximalMatching(candidate.reversed()) == true)
        #expect(graph.isPerfectMatching(candidate.reversed()) == true)
    }
}
