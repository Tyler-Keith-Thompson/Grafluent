// The four checks (catalog §Checks, CV-189 – CV-212) against their definitions, written out here,
// with the elements given in order, reversed and twice. Graphs are `UndirectedAdjacencyList` built
// by inserting the row's vertices, then its edges in order, so rows are in position order (a
// self-loop twice); `multigraph` rows are `ReferencePseudograph`, whose rows are in position order
// too; `L …; R …` rows are `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by
// their index in `vertices` (bit i of a mask is the vertex at index i). Generated from cases.md by
// swiftgen.py, which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import Covering
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Checks: isVertexCover, isIndependentSet, isDominatingSet, isEdgeCover")
struct CoveringCheckTests {
    @Test("CV-189 empty set covers an edgeless graph: true")
    func cv189() {
        // V [0, 1]; E []; isVertexCover([])
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [] as [Int]
        #expect(graph.isVertexCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == true)
        #expect(graph.isVertexCover(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == true)
    }

    @Test("CV-190 one end covers: true")
    func cv190() {
        // V [0, 1]; E [0-1]; isVertexCover([1])
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [1] as [Int]
        #expect(graph.isVertexCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == true)
        #expect(graph.isVertexCover(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == true)
    }

    @Test("CV-191 loop needs its vertex: false")
    func cv191() {
        // V [0, 1]; E [0-0, 0-1]; isVertexCover([1])
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [1] as [Int]
        #expect(graph.isVertexCover(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == false)
        #expect(graph.isVertexCover(given + given) == false)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == false)
    }

    @Test("CV-192 loop covered: true")
    func cv192() {
        // V [0, 1]; E [0-0, 0-1]; isVertexCover([0])
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0] as [Int]
        #expect(graph.isVertexCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == true)
        #expect(graph.isVertexCover(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == true)
    }

    @Test("CV-193 repeats are fine: true")
    func cv193() {
        // P(3); isVertexCover([1, 1])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [1, 1] as [Int]
        #expect(graph.isVertexCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == true)
        #expect(graph.isVertexCover(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == true)
    }

    @Test("CV-194 C(4) alternate: true")
    func cv194() {
        // C(4); isVertexCover([0, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 2] as [Int]
        #expect(graph.isVertexCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == true)
        #expect(graph.isVertexCover(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == true)
    }

    @Test("CV-195 C(4) adjacent pair misses an edge: false")
    func cv195() {
        // C(4); isVertexCover([0, 1])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1] as [Int]
        #expect(graph.isVertexCover(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isVertexCover(given.reversed()) == false)
        #expect(graph.isVertexCover(given + given) == false)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) } == false)
    }

    @Test("CV-196 empty set: true")
    func cv196() {
        // K(3); isIndependentSet([])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [] as [Int]
        #expect(graph.isIndependentSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isIndependentSet(given.reversed()) == true)
        #expect(graph.isIndependentSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) } == true)
    }

    @Test("CV-197 adjacent: false")
    func cv197() {
        // K(3); isIndependentSet([0, 1])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 1] as [Int]
        #expect(graph.isIndependentSet(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isIndependentSet(given.reversed()) == false)
        #expect(graph.isIndependentSet(given + given) == false)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) } == false)
    }

    @Test("CV-198 looped vertex is not independent: false")
    func cv198() {
        // V [0, 1]; E [0-0, 0-1]; isIndependentSet([0])
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0] as [Int]
        #expect(graph.isIndependentSet(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isIndependentSet(given.reversed()) == false)
        #expect(graph.isIndependentSet(given + given) == false)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) } == false)
    }

    @Test("CV-199 other vertex: true")
    func cv199() {
        // V [0, 1]; E [0-0, 0-1]; isIndependentSet([1])
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [1] as [Int]
        #expect(graph.isIndependentSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isIndependentSet(given.reversed()) == true)
        #expect(graph.isIndependentSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) } == true)
    }

    @Test("CV-200 parallel edges: true")
    func cv200() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isIndependentSet([0, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 2] as [Int]
        #expect(graph.isIndependentSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isIndependentSet(given.reversed()) == true)
        #expect(graph.isIndependentSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) } == true)
    }

    @Test("CV-201 repeats are fine: true")
    func cv201() {
        // P(3); isIndependentSet([0, 0, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 0, 2] as [Int]
        #expect(graph.isIndependentSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isIndependentSet(given.reversed()) == true)
        #expect(graph.isIndependentSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect(ends.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) } == true)
    }

    @Test("CV-202 empty graph, empty set: true")
    func cv202() {
        // V []; E []; isDominatingSet([])
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [] as [Int]
        #expect(graph.isDominatingSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isDominatingSet(given.reversed()) == true)
        #expect(graph.isDominatingSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect((0 ..< n).allSatisfy { v in inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } } == true)
    }

    @Test("CV-203 isolated vertex must be in: false")
    func cv203() {
        // V [0, 1]; E []; isDominatingSet([0])
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0] as [Int]
        #expect(graph.isDominatingSet(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isDominatingSet(given.reversed()) == false)
        #expect(graph.isDominatingSet(given + given) == false)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect((0 ..< n).allSatisfy { v in inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } } == false)
    }

    @Test("CV-204 hub dominates: true")
    func cv204() {
        // star(4); isDominatingSet([0])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0] as [Int]
        #expect(graph.isDominatingSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isDominatingSet(given.reversed()) == true)
        #expect(graph.isDominatingSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect((0 ..< n).allSatisfy { v in inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } } == true)
    }

    @Test("CV-205 leaf does not: false")
    func cv205() {
        // star(4); isDominatingSet([1])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [1] as [Int]
        #expect(graph.isDominatingSet(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isDominatingSet(given.reversed()) == false)
        #expect(graph.isDominatingSet(given + given) == false)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect((0 ..< n).allSatisfy { v in inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } } == false)
    }

    @Test("CV-206 self-loop irrelevant: true")
    func cv206() {
        // V [0]; E [0-0]; isDominatingSet([0])
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0] as [Int]
        #expect(graph.isDominatingSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isDominatingSet(given.reversed()) == true)
        #expect(graph.isDominatingSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect((0 ..< n).allSatisfy { v in inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } } == true)
    }

    @Test("CV-207 Petersen {0,2,6}?: true")
    func cv207() {
        // nx(petersen_graph); isDominatingSet([0, 2, 6])
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0, 2, 6] as [Int]
        #expect(graph.isDominatingSet(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isDominatingSet(given.reversed()) == true)
        #expect(graph.isDominatingSet(given + given) == true)
        // The definition, checked here.
        let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })
        #expect((0 ..< n).allSatisfy { v in inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } } == true)
    }

    @Test("CV-208 empty graph: true")
    func cv208() {
        // V []; E []; isEdgeCover([])
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [] as [Int]
        #expect(graph.isEdgeCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isEdgeCover(given.reversed()) == true)
        #expect(graph.isEdgeCover(given + given) == true)
        // The definition, checked here.
        var covered = Set<Int>()
        for p in given {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect((covered.count == n) == true)
    }

    @Test("CV-209 one edge: true")
    func cv209() {
        // V [0, 1]; E [0-1]; isEdgeCover([0])
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0]
        #expect(graph.isEdgeCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isEdgeCover(given.reversed()) == true)
        #expect(graph.isEdgeCover(given + given) == true)
        // The definition, checked here.
        var covered = Set<Int>()
        for p in given {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect((covered.count == n) == true)
    }

    @Test("CV-210 P(3) one edge misses: false")
    func cv210() {
        // P(3); isEdgeCover([0])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0]
        #expect(graph.isEdgeCover(given) == false)
        // Order and repeats do not matter.
        #expect(graph.isEdgeCover(given.reversed()) == false)
        #expect(graph.isEdgeCover(given + given) == false)
        // The definition, checked here.
        var covered = Set<Int>()
        for p in given {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect((covered.count == n) == false)
    }

    @Test("CV-211 loop covers its vertex: true")
    func cv211() {
        // V [0]; E [0-0]; isEdgeCover([0])
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [0]
        #expect(graph.isEdgeCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isEdgeCover(given.reversed()) == true)
        #expect(graph.isEdgeCover(given + given) == true)
        // The definition, checked here.
        var covered = Set<Int>()
        for p in given {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect((covered.count == n) == true)
    }

    @Test("CV-212 parallel copy: true")
    func cv212() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; isEdgeCover([1, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let given = [1, 2]
        #expect(graph.isEdgeCover(given) == true)
        // Order and repeats do not matter.
        #expect(graph.isEdgeCover(given.reversed()) == true)
        #expect(graph.isEdgeCover(given + given) == true)
        // The definition, checked here.
        var covered = Set<Int>()
        for p in given {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect((covered.count == n) == true)
    }
}
