// The weighted projections (catalog BP-173 – BP-197): `weightedProjectedGraph(onto:)`, the
// number of shared neighbours; `overlapWeightedProjectedGraph(onto:jaccard:)`, |N(u) ∩ N(v)| over the
// union's size or the lesser degree; `collaborationWeightedProjectedGraph(onto:)`, Σ 1/(d(w) − 1) over
// the shared neighbours in the earlier end's row order. The graph is `projectedGraph(onto:)`'s, at
// the same positions, and each weight is read through the attached map. ref.py checks every row
// against NetworkX 3.7's weighted projections. Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("Weighted projections")
struct WeightedProjectionTests {
    @Test("BP-173 K2,3 onto left: three shared neighbours: weightedProjectedGraph")
    func bp173() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; weightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.weightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [3] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-174 path a–x–b–y–c onto left: weightedProjectedGraph")
    func bp174() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; weightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.weightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == ["a", "b", "c"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1, 1] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-175 uneven degrees onto left: weightedProjectedGraph")
    func bp175() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; weightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.weightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1, 2] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [2, 1, 1] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-176 uneven degrees onto right: weightedProjectedGraph")
    func bp176() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; weightedProjectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.weightedProjectedGraph(onto: .right)
        #expect(Array(projection.graph.vertices) == [3, 4, 5, 6] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [2, 1, 1, 1, 1, 1] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .right).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-177 affiliation network onto people: weightedProjectedGraph")
    func bp177() throws {
        // left [p1, p2, p3, p4], right [e1, e2, e3], edges [p1–e1, p2–e1, p3–e1, p2–e2, p3–e2, p4–e3, p3–e3]; weightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["p1", "p2", "p3", "p4"] as [String], right: ["e1", "e2", "e3"] as [String], edges: [("p1", "e1"), ("p2", "e1"), ("p3", "e1"), ("p2", "e2"), ("p3", "e2"), ("p4", "e3"), ("p3", "e3")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.weightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == ["p1", "p2", "p3", "p4"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["p1", "p2"], ["p1", "p3"], ["p2", "p3"], ["p3", "p4"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1, 1, 2, 1] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-178 K2,3 onto left: three shared neighbours: overlapWeightedProjectedGraph")
    func bp178() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; overlapWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-179 path a–x–b–y–c onto left: overlapWeightedProjectedGraph")
    func bp179() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; overlapWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == ["a", "b", "c"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [0.5, 0.5] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-180 uneven degrees onto left: overlapWeightedProjectedGraph")
    func bp180() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; overlapWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1, 2] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [0.5, 0.25, 0.25] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-181 uneven degrees onto right: overlapWeightedProjectedGraph")
    func bp181() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; overlapWeightedProjectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .right)
        #expect(Array(projection.graph.vertices) == [3, 4, 5, 6] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .right).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-182 affiliation network onto people: overlapWeightedProjectedGraph")
    func bp182() throws {
        // left [p1, p2, p3, p4], right [e1, e2, e3], edges [p1–e1, p2–e1, p3–e1, p2–e2, p3–e2, p4–e3, p3–e3]; overlapWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["p1", "p2", "p3", "p4"] as [String], right: ["e1", "e2", "e3"] as [String], edges: [("p1", "e1"), ("p2", "e1"), ("p3", "e1"), ("p2", "e2"), ("p3", "e2"), ("p4", "e3"), ("p3", "e3")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == ["p1", "p2", "p3", "p4"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["p1", "p2"], ["p1", "p3"], ["p2", "p3"], ["p3", "p4"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [0.5, 0.3333333333333333, 0.6666666666666666, 0.3333333333333333] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-183 K2,3 onto left: three shared neighbours: overlapWeightedProjectedGraph")
    func bp183() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        #expect(Array(projection.graph.vertices) == [0, 1] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-184 path a–x–b–y–c onto left: overlapWeightedProjectedGraph")
    func bp184() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        #expect(Array(projection.graph.vertices) == ["a", "b", "c"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0, 1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-185 uneven degrees onto left: overlapWeightedProjectedGraph")
    func bp185() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        #expect(Array(projection.graph.vertices) == [0, 1, 2] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [0.6666666666666666, 0.5, 0.5] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-186 uneven degrees onto right: overlapWeightedProjectedGraph")
    func bp186() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; overlapWeightedProjectedGraph(onto: .right, jaccard: false)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .right, jaccard: false)
        #expect(Array(projection.graph.vertices) == [3, 4, 5, 6] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0, 0.5, 0.5, 0.5, 0.5, 0.5] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .right).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-187 affiliation network onto people: overlapWeightedProjectedGraph")
    func bp187() throws {
        // left [p1, p2, p3, p4], right [e1, e2, e3], edges [p1–e1, p2–e1, p3–e1, p2–e2, p3–e2, p4–e3, p3–e3]; overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        let graph = try #require(BipartiteGraph<String>(left: ["p1", "p2", "p3", "p4"] as [String], right: ["e1", "e2", "e3"] as [String], edges: [("p1", "e1"), ("p2", "e1"), ("p3", "e1"), ("p2", "e2"), ("p3", "e2"), ("p4", "e3"), ("p3", "e3")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        #expect(Array(projection.graph.vertices) == ["p1", "p2", "p3", "p4"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["p1", "p2"], ["p1", "p3"], ["p2", "p3"], ["p3", "p4"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0, 1.0, 1.0, 1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-188 K2,3 onto left: three shared neighbours: collaborationWeightedProjectedGraph")
    func bp188() throws {
        // left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; collaborationWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.collaborationWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [3.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-189 path a–x–b–y–c onto left: collaborationWeightedProjectedGraph")
    func bp189() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; collaborationWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.collaborationWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == ["a", "b", "c"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0, 1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-190 uneven degrees onto left: collaborationWeightedProjectedGraph")
    func bp190() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; collaborationWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.collaborationWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1, 2] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [2.0, 1.0, 1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-191 uneven degrees onto right: collaborationWeightedProjectedGraph")
    func bp191() throws {
        // left [0, 1, 2], right [3, 4, 5, 6], edges [0–3, 0–4, 0–5, 1–3, 1–4, 2–5, 2–6, 1–6]; collaborationWeightedProjectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (2, 6), (1, 6)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.collaborationWeightedProjectedGraph(onto: .right)
        #expect(Array(projection.graph.vertices) == [3, 4, 5, 6] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[3, 4], [3, 5], [3, 6], [4, 5], [4, 6], [5, 6]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0, 0.5, 0.5, 0.5, 0.5, 1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .right).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-192 affiliation network onto people: collaborationWeightedProjectedGraph")
    func bp192() throws {
        // left [p1, p2, p3, p4], right [e1, e2, e3], edges [p1–e1, p2–e1, p3–e1, p2–e2, p3–e2, p4–e3, p3–e3]; collaborationWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<String>(left: ["p1", "p2", "p3", "p4"] as [String], right: ["e1", "e2", "e3"] as [String], edges: [("p1", "e1"), ("p2", "e1"), ("p3", "e1"), ("p2", "e2"), ("p3", "e2"), ("p4", "e3"), ("p3", "e3")].map { UndirectedEdge<String>($0.0, $0.1) }))
        let projection = graph.collaborationWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == ["p1", "p2", "p3", "p4"] as [String])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [["p1", "p2"], ["p1", "p3"], ["p2", "p3"], ["p3", "p4"]] as [[String]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [0.5, 0.5, 1.5, 1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-193 star centre left, onto right: K4, each pair one shared neighbour: weightedProjectedGraph")
    func bp193() throws {
        // left [0], right [1, 2, 3, 4], edges [0–1, 0–2, 0–3, 0–4]; weightedProjectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1, 2, 3, 4] as [Int], edges: [(0, 1), (0, 2), (0, 3), (0, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.weightedProjectedGraph(onto: .right)
        #expect(Array(projection.graph.vertices) == [1, 2, 3, 4] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1, 1, 1, 1, 1, 1] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .right).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-194 star onto right: collaboration 1/3 per pair: collaborationWeightedProjectedGraph")
    func bp194() throws {
        // left [0], right [1, 2, 3, 4], edges [0–1, 0–2, 0–3, 0–4]; collaborationWeightedProjectedGraph(onto: .right)
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1, 2, 3, 4] as [Int], edges: [(0, 1), (0, 2), (0, 3), (0, 4)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.collaborationWeightedProjectedGraph(onto: .right)
        #expect(Array(projection.graph.vertices) == [1, 2, 3, 4] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.3333333333333333] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .right).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-195 edgeless: isolated vertices, no weights: weightedProjectedGraph")
    func bp195() throws {
        // left [0, 1], right [2]; weightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2] as [Int], edges: [UndirectedEdge<Int>]()))
        let projection = graph.weightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [0, 1] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [] as [Int])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-196 empty side: overlapWeightedProjectedGraph")
    func bp196() throws {
        // left [], right [0, 1]; overlapWeightedProjectedGraph(onto: .left)
        let graph = try #require(BipartiteGraph<Int>(left: [] as [Int], right: [0, 1] as [Int], edges: [UndirectedEdge<Int>]()))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left)
        #expect(Array(projection.graph.vertices) == [] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }

    @Test("BP-197 isolated left vertex kept: overlapWeightedProjectedGraph")
    func bp197() throws {
        // left [0, 1, 5], right [2], edges [0–2, 1–2]; overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 5] as [Int], right: [2] as [Int], edges: [(0, 2), (1, 2)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        let projection = graph.overlapWeightedProjectedGraph(onto: .left, jaccard: false)
        #expect(Array(projection.graph.vertices) == [0, 1, 5] as [Int])
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect(projection.graph.edges.indices.map { projection.graph[projection.weights, ofEdgeAt: $0] } == [1.0] as [Double])
        // The graph is projectedGraph(onto:)'s, edge for edge.
        #expect(projection.graph.edges.map { [$0.u, $0.v] } == graph.projectedGraph(onto: .left).edges.map { [$0.u, $0.v] })
    }
}
