// Recognition on any `Graph` (catalog §Recognition, BP-001 – BP-084): `isBipartite`,
// `bipartition()` with its canonical sides (each component's least vertex left, each side in
// `vertices` order), `side(of:)` and `side(ofIndex:)`, `BipartiteGraph(graph)` agreeing with
// them, and `findOddCycle()`: the exact cycle api.md's breadth-first search returns, in Cycles'
// canonical form, and its validity (odd, simple, each edge joining consecutive vertices,
// `Cycle(vertices:edges:in:)` not nil). Undirected rows run on `ReferencePseudograph`, whose rows
// are in position order (a self-loop twice, consecutively; parallel edges kept), so vertex
// numbers and edge positions are the catalog's. `digraph` rows (BP-069 – BP-074) are an
// `AdjacencyList` read through `.undirected`: rows are successors, then predecessors. Generated
// from cases.md by swiftgen.py, which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Recognition: isBipartite, bipartition(), findOddCycle()")
struct RecognitionTests {
    @Test("BP-001 empty graph: left [], right []")
    func bp001() throws {
        // V []; E []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = []
        let right: [Int] = []
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-002 one vertex: left [0], right []")
    func bp002() throws {
        // V [0]; E []
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = []
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-003 two isolated vertices: left [0, 1], right []")
    func bp003() throws {
        // V [0, 1]; E []
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1]
        let right: [Int] = []
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-004 one edge: left [0], right [1]")
    func bp004() throws {
        // V [0, 1]; E [0–1]
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-005 one edge, written 1–0: left [0], right [1]")
    func bp005() throws {
        // V [0, 1]; E [1–0]
        let pairs: [(Int, Int)] = [(1, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-006 one edge, vertex order [1, 0]: left [1], right [0]")
    func bp006() throws {
        // V [1, 0]; E [0–1]
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: [1, 0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [1]
        let right: [Int] = [0]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-007 self-loop alone: odd cycle [0] via [0]")
    func bp007() throws {
        // V [0]; E [0–0]
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0])
        #expect(cycle.edges == [0])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 1 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-008 self-loop beside an edge: odd cycle [1] via [1]")
    func bp008() throws {
        // V [0, 1]; E [0–1, 1–1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [1])
        #expect(cycle.edges == [1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 1 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-009 self-loop on an isolated vertex of a bipartite graph: odd cycle [2] via [1]")
    func bp009() throws {
        // V [0, 1, 2]; E [0–1, 2–2]
        let pairs: [(Int, Int)] = [(0, 1), (2, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [2])
        #expect(cycle.edges == [1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 1 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-010 parallel pair: left [0], right [1]")
    func bp010() throws {
        // multigraph V [0, 1]; E [0–1, 0–1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-011 parallel pair, second copy written 1–0: left [0], right [1]")
    func bp011() throws {
        // multigraph V [0, 1]; E [0–1, 1–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-012 three parallel copies: left [0], right [1]")
    func bp012() throws {
        // multigraph V [0, 1]; E [0–1, 0–1, 0–1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-013 parallel pair inside a triangle: odd cycle [0, 1, 2] via [0, 2, 3]")
    func bp013() throws {
        // multigraph V [0, 1, 2]; E [0–1, 0–1, 1–2, 2–0]
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 2, 3])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-014 two self-loops on one vertex: odd cycle [0] via [0]")
    func bp014() throws {
        // multigraph V [0]; E [0–0, 0–0]
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = ReferencePseudograph(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0])
        #expect(cycle.edges == [0])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 1 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-015 path P3: left [0, 2], right [1]")
    func bp015() throws {
        // V [0, 1, 2]; E [0–1, 1–2]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-016 path P4: left [0, 2], right [1, 3]")
    func bp016() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2]
        let right: [Int] = [1, 3]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-017 path P7: left [0, 2, 4, 6], right [1, 3, 5]")
    func bp017() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4, 6]
        let right: [Int] = [1, 3, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-018 path P5 listed from the middle: left [2, 0, 4], right [1, 3]")
    func bp018() throws {
        // V [2, 0, 1, 3, 4]; E [0–1, 1–2, 2–3, 3–4]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: [2, 0, 1, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [2, 0, 4]
        let right: [Int] = [1, 3]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-019 triangle C3: odd cycle [0, 1, 2] via [0, 1, 2]")
    func bp019() throws {
        // V [0, 1, 2]; E [0–1, 1–2, 2–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-020 triangle written backwards: odd cycle [0, 1, 2] via [1, 0, 2]")
    func bp020() throws {
        // V [0, 1, 2]; E [2–1, 1–0, 0–2]
        let pairs: [(Int, Int)] = [(2, 1), (1, 0), (0, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [1, 0, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-021 square C4: left [0, 2], right [1, 3]")
    func bp021() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3, 3–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2]
        let right: [Int] = [1, 3]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-022 pentagon C5: odd cycle [0, 1, 2, 3, 4] via [0, 1, 2, 3, 4]")
    func bp022() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 1–2, 2–3, 3–4, 4–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4])
        #expect(cycle.edges == [0, 1, 2, 3, 4])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-023 hexagon C6: left [0, 2, 4], right [1, 3, 5]")
    func bp023() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4]
        let right: [Int] = [1, 3, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-024 heptagon C7: odd cycle [0, 1, 2, 3, 4, 5, 6] via [0, 1, 2, 3, 4, 5, 6]")
    func bp024() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6])
        #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 7 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-025 C9: odd cycle [0, 1, 2, 3, 4, 5, 6, 7, 8] via [0, 1, 2, 3, 4, 5, 6, 7, 8]")
    func bp025() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(cycle.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 9 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-026 C8: left [0, 2, 4, 6], right [1, 3, 5, 7]")
    func bp026() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4, 6]
        let right: [Int] = [1, 3, 5, 7]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-027 C5 with vertex order reversed: odd cycle [4, 3, 2, 1, 0] via [3, 2, 1, 0, 4]")
    func bp027() throws {
        // V [4, 3, 2, 1, 0]; E [0–1, 1–2, 2–3, 3–4, 4–0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(vertices: [4, 3, 2, 1, 0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [4, 3, 2, 1, 0])
        #expect(cycle.edges == [3, 2, 1, 0, 4])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-028 C5 with shuffled edge positions: odd cycle [0, 1, 2, 3, 4] via [1, 4, 3, 0, 2]")
    func bp028() throws {
        // V [0, 1, 2, 3, 4]; E [3–4, 0–1, 4–0, 2–3, 1–2]
        let pairs: [(Int, Int)] = [(3, 4), (0, 1), (4, 0), (2, 3), (1, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4])
        #expect(cycle.edges == [1, 4, 3, 0, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-029 K4: odd cycle [0, 1, 2] via [0, 3, 1]")
    func bp029() throws {
        // V [0, 1, 2, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 3, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-030 K5: odd cycle [0, 1, 2] via [0, 4, 1]")
    func bp030() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 4, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-031 star K1,4: left [0], right [1, 2, 3, 4]")
    func bp031() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1, 2, 3, 4]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-032 star with centre last: left [0, 1, 2, 3], right [4]")
    func bp032() throws {
        // V [0, 1, 2, 3, 4]; E [4–0, 4–1, 4–2, 4–3]
        let pairs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 2, 3]
        let right: [Int] = [4]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-033 K2,3: left [0, 1], right [2, 3, 4]")
    func bp033() throws {
        // V [0, 1, 2, 3, 4]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1]
        let right: [Int] = [2, 3, 4]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-034 K3,3: left [0, 1, 2], right [3, 4, 5]")
    func bp034() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5]
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 2]
        let right: [Int] = [3, 4, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-035 K3,3 plus one edge inside a side: odd cycle [0, 3, 1] via [0, 3, 9]")
    func bp035() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 0–1]
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (0, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 3, 1])
        #expect(cycle.edges == [0, 3, 9])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-036 K3,3 plus one edge inside the other side: odd cycle [0, 4, 5] via [1, 9, 2]")
    func bp036() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 4–5]
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 4, 5])
        #expect(cycle.edges == [1, 9, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-037 grid 3×3: left [0, 2, 4, 6, 8], right [1, 3, 5, 7]")
    func bp037() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8]
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4, 6, 8]
        let right: [Int] = [1, 3, 5, 7]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-038 grid 2×4: left [0, 2, 5, 7], right [1, 3, 4, 6]")
    func bp038() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 5–6, 6–7]
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 5, 7]
        let right: [Int] = [1, 3, 4, 6]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-039 grid 3×3 plus a diagonal: odd cycle [0, 1, 4] via [0, 3, 12]")
    func bp039() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8, 0–4]
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8), (0, 4)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 4])
        #expect(cycle.edges == [0, 3, 12])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-040 hypercube Q3: left [0, 3, 5, 6], right [1, 2, 4, 7]")
    func bp040() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 3, 5, 6]
        let right: [Int] = [1, 2, 4, 7]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-041 Petersen graph: odd cycle [0, 1, 2, 3, 4] via [0, 3, 5, 7, 1]")
    func bp041() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9]
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4])
        #expect(cycle.edges == [0, 3, 5, 7, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-042 wheel W5 (hub 0, rim C5): odd cycle [0, 1, 2] via [0, 5, 1]")
    func bp042() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 2–3, 3–4, 4–5, 5–1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 5, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-043 wheel W4 (hub 0, rim C4): odd cycle [0, 1, 2] via [0, 4, 1]")
    func bp043() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 2–3, 3–4, 4–1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 4, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-044 two triangles sharing a vertex (bowtie): odd cycle [0, 1, 2] via [0, 1, 2]")
    func bp044() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 1–2, 2–0, 2–3, 3–4, 4–2]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-045 triangle at the end of a path: odd cycle [3, 4, 5] via [3, 4, 5]")
    func bp045() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [3, 4, 5])
        #expect(cycle.edges == [3, 4, 5])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-046 C5 hanging off a long path: odd cycle [3, 4, 5, 6, 7] via [3, 4, 5, 6, 7]")
    func bp046() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [3, 4, 5, 6, 7])
        #expect(cycle.edges == [3, 4, 5, 6, 7])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-047 theta graph: paths of length 2, 2, 4 between 0 and 1: left [0, 1, 5], right [2, 3, 4, 6]")
    func bp047() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–2, 2–1, 0–3, 3–1, 0–4, 4–5, 5–6, 6–1]
        let pairs: [(Int, Int)] = [(0, 2), (2, 1), (0, 3), (3, 1), (0, 4), (4, 5), (5, 6), (6, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 5]
        let right: [Int] = [2, 3, 4, 6]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-048 theta graph: paths of length 1, 2, 3 (odd cycles): odd cycle [0, 1, 2] via [0, 2, 1]")
    func bp048() throws {
        // V [0, 1, 2, 3, 4]; E [0–1, 0–2, 2–1, 0–3, 3–4, 4–1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1), (0, 3), (3, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 2, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-049 C4 plus a chord: odd cycle [0, 1, 2] via [0, 1, 4]")
    func bp049() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3, 3–0, 0–2]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 4])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-050 C6 plus a long chord (two C4s): left [0, 2, 4], right [1, 3, 5]")
    func bp050() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4]
        let right: [Int] = [1, 3, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-051 C6 plus a short chord (two odd cycles): odd cycle [0, 1, 2] via [0, 1, 6]")
    func bp051() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–2]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 6])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-052 first conflict met is a C5 although a triangle exists: odd cycle [0, 1, 3, 4, 2] via [0, 2, 4, 3, 1]")
    func bp052() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 0–2, 1–3, 2–4, 3–4, 3–5, 5–6, 6–3]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (5, 6), (6, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 3, 4, 2])
        #expect(cycle.edges == [0, 2, 4, 3, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-053 disconnected: edge, isolated vertex, path: left [0, 1, 3, 5], right [2, 4]")
    func bp053() throws {
        // V [0, 1, 2, 3, 4, 5]; E [1–2, 3–4, 4–5]
        let pairs: [(Int, Int)] = [(1, 2), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 3, 5]
        let right: [Int] = [2, 4]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-054 disconnected: least vertex of a component is not its first endpoint: left [0, 1, 2, 5], right [3, 4]")
    func bp054() throws {
        // V [0, 1, 2, 3, 4, 5]; E [5–3, 3–1, 4–2]
        let pairs: [(Int, Int)] = [(5, 3), (3, 1), (4, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 2, 5]
        let right: [Int] = [3, 4]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-055 disconnected: bipartite component then triangle: odd cycle [2, 3, 4] via [1, 2, 3]")
    func bp055() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 2–3, 3–4, 4–2]
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4), (4, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [2, 3, 4])
        #expect(cycle.edges == [1, 2, 3])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-056 disconnected: triangle in the second component, first is C4: odd cycle [4, 5, 6] via [4, 5, 6]")
    func bp056() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–0, 4–5, 5–6, 6–4]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [4, 5, 6])
        #expect(cycle.edges == [4, 5, 6])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-057 disconnected: two triangles: odd cycle [0, 1, 2] via [0, 1, 2]")
    func bp057() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–0, 3–4, 4–5, 5–3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-058 isolated vertices around a C4: left [0, 1, 3, 4, 6], right [2, 5]")
    func bp058() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [1–2, 2–4, 4–5, 5–1]
        let pairs: [(Int, Int)] = [(1, 2), (2, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 3, 4, 6]
        let right: [Int] = [2, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-059 string vertices: a–x, b–x, b–y: left [a, b], right [x, y]")
    func bp059() throws {
        // V [a, b, x, y]; E [a–x, b–x, b–y]
        let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y")]
        let graph = ReferencePseudograph(vertices: ["a", "b", "x", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [String] = ["a", "b"]
        let right: [String] = ["x", "y"]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-060 string vertices: triangle a, b, c: odd cycle [c, b, a] via [1, 0, 2]")
    func bp060() throws {
        // V [c, b, a]; E [a–b, b–c, c–a]
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a")]
        let graph = ReferencePseudograph(vertices: ["c", "b", "a"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == ["c", "b", "a"])
        #expect(cycle.edges == [1, 0, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-061 tree (caterpillar): left [0, 2, 4, 6, 7], right [1, 3, 5]")
    func bp061() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 1–4, 2–5, 3–6, 3–7]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5), (3, 6), (3, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4, 6, 7]
        let right: [Int] = [1, 3, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-062 Möbius ladder M8 (not bipartite): odd cycle [0, 1, 2, 3, 7] via [0, 1, 2, 11, 7]")
    func bp062() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–0, 0–4, 1–5, 2–6, 3–7]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (0, 4), (1, 5), (2, 6), (3, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 7])
        #expect(cycle.edges == [0, 1, 2, 11, 7])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-063 Möbius ladder M6 = K3,3: left [0, 2, 4], right [1, 3, 5]")
    func bp063() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–3, 1–4, 2–5]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3), (1, 4), (2, 5)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2, 4]
        let right: [Int] = [1, 3, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-064 prism C3 × K2: odd cycle [0, 1, 2] via [0, 1, 2]")
    func bp064() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–0, 3–4, 4–5, 5–3, 0–3, 1–4, 2–5]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (0, 3), (1, 4), (2, 5)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-065 cube with one edge subdivided twice: left [0, 3, 5, 6, 9], right [1, 2, 4, 7, 8]")
    func bp065() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7, 0–8, 8–9, 9–1]
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 9), (9, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 3, 5, 6, 9]
        let right: [Int] = [1, 2, 4, 7, 8]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-066 cube with one edge subdivided once: odd cycle [0, 2, 3, 1, 8] via [0, 4, 2, 12, 11]")
    func bp066() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7, 0–8, 8–1]
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7), (0, 8), (8, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 2, 3, 1, 8])
        #expect(cycle.edges == [0, 4, 2, 12, 11])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-067 odd cycle deep in a BFS tree: odd cycle [5, 6, 7, 8, 9] via [5, 6, 7, 8, 9]")
    func bp067() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–9, 9–5]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 5)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [5, 6, 7, 8, 9])
        #expect(cycle.edges == [5, 6, 7, 8, 9])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-068 two odd cycles; the one met first is later in vertex order: odd cycle [0, 7, 6] via [0, 1, 2]")
    func bp068() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–7, 7–6, 6–0, 1–2, 2–3, 3–1, 0–1]
        let pairs: [(Int, Int)] = [(0, 7), (7, 6), (6, 0), (1, 2), (2, 3), (3, 1), (0, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 7, 6])
        #expect(cycle.edges == [0, 1, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-069 directed path 0→1→2: left [0, 2], right [1]")
    func bp069() throws {
        // digraph V [0, 1, 2]; E [0–1, 1–2]
        let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
        let digraph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-070 directed 2-cycle 0⇄1 (a parallel pair once undirected): left [0], right [1]")
    func bp070() throws {
        // digraph V [0, 1]; E [0–1, 1–0]
        let arcs: [(Int, Int)] = [(0, 1), (1, 0)]
        let digraph = AdjacencyList(vertices: [0, 1] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0]
        let right: [Int] = [1]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-071 directed triangle 0→1→2→0: odd cycle [0, 1, 2] via [0, 1, 2]")
    func bp071() throws {
        // digraph V [0, 1, 2]; E [0–1, 1–2, 2–0]
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let digraph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 1, 2])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-072 transitive triangle 0→1, 0→2, 1→2: odd cycle [0, 1, 2] via [0, 2, 1]")
    func bp072() throws {
        // digraph V [0, 1, 2]; E [0–1, 0–2, 1–2]
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let digraph = AdjacencyList(vertices: [0, 1, 2] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.edges == [0, 2, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-073 directed self-loop: odd cycle [1] via [1]")
    func bp073() throws {
        // digraph V [0, 1]; E [0–1, 1–1]
        let arcs: [(Int, Int)] = [(0, 1), (1, 1)]
        let digraph = AdjacencyList(vertices: [0, 1] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [1])
        #expect(cycle.edges == [1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 1 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-074 directed C4 with all arcs into 0 and 2: left [0, 2], right [1, 3]")
    func bp074() throws {
        // digraph V [0, 1, 2, 3]; E [1–0, 3–0, 1–2, 3–2]
        let arcs: [(Int, Int)] = [(1, 0), (3, 0), (1, 2), (3, 2)]
        let digraph = AdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = digraph.undirected
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 2]
        let right: [Int] = [1, 3]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-075 random bipartite #1 (seed 20261009): left [0, 3, 4, 5, 6], right [1, 2]")
    func bp075() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [3–1, 4–1, 6–1, 5–1, 6–2, 3–2, 5–2, 0–2, 0–1, 4–2]
        let pairs: [(Int, Int)] = [(3, 1), (4, 1), (6, 1), (5, 1), (6, 2), (3, 2), (5, 2), (0, 2), (0, 1), (4, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 3, 4, 5, 6]
        let right: [Int] = [1, 2]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-076 random G(n, m) #1 (seed 20261009): odd cycle [0, 3, 8, 1, 7] via [0, 3, 5, 6, 7]")
    func bp076() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–3, 6–7, 4–8, 3–8, 1–6, 1–8, 1–7, 0–7, 2–6, 2–4, 1–2]
        let pairs: [(Int, Int)] = [(0, 3), (6, 7), (4, 8), (3, 8), (1, 6), (1, 8), (1, 7), (0, 7), (2, 6), (2, 4), (1, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 3, 8, 1, 7])
        #expect(cycle.edges == [0, 3, 5, 6, 7])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-077 random bipartite #2 (seed 20261009): left [0, 1, 3, 4, 5, 6], right [2, 7]")
    func bp077() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–7, 3–7, 1–2, 4–7, 3–2, 4–2, 6–7, 5–2, 1–7, 6–2, 0–2]
        let pairs: [(Int, Int)] = [(0, 7), (3, 7), (1, 2), (4, 7), (3, 2), (4, 2), (6, 7), (5, 2), (1, 7), (6, 2), (0, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 3, 4, 5, 6]
        let right: [Int] = [2, 7]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-078 random G(n, m) #2 (seed 20261009): odd cycle [2, 4, 6] via [6, 2, 10]")
    func bp078() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 3–7, 4–6, 5–8, 1–6, 7–8, 2–4, 1–5, 2–8, 2–5, 2–6, 4–7]
        let pairs: [(Int, Int)] = [(0, 1), (3, 7), (4, 6), (5, 8), (1, 6), (7, 8), (2, 4), (1, 5), (2, 8), (2, 5), (2, 6), (4, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [2, 4, 6])
        #expect(cycle.edges == [6, 2, 10])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-079 random bipartite #3 (seed 20261009): left [0, 3, 4], right [1, 2, 5]")
    func bp079() throws {
        // V [0, 1, 2, 3, 4, 5]; E [3–2, 0–5, 0–1, 3–1]
        let pairs: [(Int, Int)] = [(3, 2), (0, 5), (0, 1), (3, 1)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 3, 4]
        let right: [Int] = [1, 2, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-080 random G(n, m) #3 (seed 20261009): odd cycle [0, 5, 4, 3, 2] via [1, 0, 2, 3, 5]")
    func bp080() throws {
        // V [0, 1, 2, 3, 4, 5]; E [4–5, 0–5, 3–4, 2–3, 1–5, 0–2]
        let pairs: [(Int, Int)] = [(4, 5), (0, 5), (3, 4), (2, 3), (1, 5), (0, 2)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 5, 4, 3, 2])
        #expect(cycle.edges == [1, 0, 2, 3, 5])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 5 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-081 random bipartite #4 (seed 20261009): left [0, 1, 4], right [2, 3, 5]")
    func bp081() throws {
        // V [0, 1, 2, 3, 4, 5]; E [2–1, 3–4, 5–1, 5–4]
        let pairs: [(Int, Int)] = [(2, 1), (3, 4), (5, 1), (5, 4)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 4]
        let right: [Int] = [2, 3, 5]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-082 random G(n, m) #4 (seed 20261009): odd cycle [1, 6, 7] via [1, 0, 5]")
    func bp082() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [6–7, 1–6, 0–7, 1–2, 1–5, 1–7, 3–7, 2–7]
        let pairs: [(Int, Int)] = [(6, 7), (1, 6), (0, 7), (1, 2), (1, 5), (1, 7), (3, 7), (2, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [1, 6, 7])
        #expect(cycle.edges == [1, 0, 5])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }

    @Test("BP-083 random bipartite #5 (seed 20261009): left [0, 1, 2, 3, 6, 7, 9], right [4, 5, 8]")
    func bp083() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [5–0, 4–2, 4–1, 5–1, 8–1, 5–3, 8–0, 8–6, 8–3, 4–9, 8–2, 5–2, 8–9]
        let pairs: [(Int, Int)] = [(5, 0), (4, 2), (4, 1), (5, 1), (8, 1), (5, 3), (8, 0), (8, 6), (8, 3), (4, 9), (8, 2), (5, 2), (8, 9)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        let left: [Int] = [0, 1, 2, 3, 6, 7, 9]
        let right: [Int] = [4, 5, 8]
        #expect(Array(bipartition.left) == left)
        #expect(Array(bipartition.right) == right)
        for v in left { #expect(bipartition.side(of: v) == .left) }
        for v in right { #expect(bipartition.side(of: v) == .right) }
        // side(ofIndex:) by vertex index (the position in `vertices`).
        for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }
        for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }
        let bipartite = try #require(BipartiteGraph(graph))
        #expect(Array(bipartite.left) == left)
        #expect(Array(bipartite.right) == right)
    }

    @Test("BP-084 random G(n, m) #5 (seed 20261009): odd cycle [0, 4, 1] via [0, 5, 1]")
    func bp084() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–4, 0–1, 2–6, 3–5, 6–7, 1–4, 3–7, 0–5, 1–2, 2–5, 1–7]
        let pairs: [(Int, Int)] = [(0, 4), (0, 1), (2, 6), (3, 5), (6, 7), (1, 4), (3, 7), (0, 5), (1, 2), (2, 5), (1, 7)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isBipartite)
        #expect(graph.bipartition() == nil)
        #expect(BipartiteGraph(graph) == nil)
        let cycle = try #require(graph.findOddCycle())
        #expect(cycle.vertices == [0, 4, 1])
        #expect(cycle.edges == [0, 5, 1])
        // Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.
        let k = cycle.vertices.count
        #expect(k == 3 && k % 2 == 1)
        #expect(Set(cycle.vertices).count == k)
        #expect(Set(cycle.edges).count == k)
        for i in 0 ..< k {
            let edge = graph.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
    }
}
