// Named directed graphs with independently known properties.
//
// Graph definitions and expected values are mathematical facts, restated here from the test
// suites where they were found. Each fixture cites its origin. Expected values were re-derived
// for simple directed graphs (no parallel edges) wherever the original graph had parallel edges.
//
// The graph itself is written with `DirectedGraphBuilder`. The builder only collects the edges and
// vertices as written; the expected values beside it were computed by hand or taken from another
// library, never from code under test. GrafluentTestSupportTests checks that the two agree.

import GraphProtocols
import Testing

/// A directed graph given as data, with its expected vertex count, edge count and degrees.
public struct DirectedFixture<Vertex: Hashable & Sendable>: Sendable, CustomTestStringConvertible {
    public let name: String
    /// Where the graph and its expected values come from.
    public let source: String
    /// Vertices listed on their own, typically the isolated ones. DirectedEdge endpoints need not appear.
    public let vertices: [Vertex]
    /// Edges as written. May repeat an edge, which a simple directed graph collapses.
    public let edges: [DirectedEdge<Vertex>]
    /// Expected number of vertices.
    public let vertexCount: Int
    /// Expected number of edges, after repeated edges collapse.
    public let edgeCount: Int
    /// Expected outDegree(of: v) for every vertex.
    public let outDegree: [Vertex: Int]
    /// Expected inDegree(of: v) for every vertex.
    public let inDegree: [Vertex: Int]

    public init(
        _ name: String,
        source: String,
        vertexCount: Int,
        edgeCount: Int,
        outDegree: [Vertex: Int],
        inDegree: [Vertex: Int],
        @DirectedGraphBuilder<Vertex> graph: () -> DirectedGraphBuilder<Vertex>.Content
    ) {
        let content = graph()
        self.init(name, source: source, vertices: content.vertices, edges: content.edges, vertexCount: vertexCount, edgeCount: edgeCount, outDegree: outDegree, inDegree: inDegree)
    }

    public init(
        _ name: String,
        source: String,
        vertices: [Vertex],
        edges: [DirectedEdge<Vertex>],
        vertexCount: Int,
        edgeCount: Int,
        outDegree: [Vertex: Int],
        inDegree: [Vertex: Int]
    ) {
        self.name = name
        self.source = source
        self.vertices = vertices
        self.edges = edges
        self.vertexCount = vertexCount
        self.edgeCount = edgeCount
        self.outDegree = outDegree
        self.inDegree = inDegree
    }

    public var testDescription: String { name }

    /// The distinct edges.
    public var edgeSet: Set<DirectedEdge<Vertex>> { Set(edges) }

    /// The distinct vertices, including edge endpoints not listed in `vertices`.
    public var vertexSet: Set<Vertex> { Set(vertices).union(edges.flatMap { [$0.source, $0.target] }) }
}

/// The same degree for every vertex in `vertices`.
private func every<V: Hashable>(_ vertices: some Sequence<V>, _ degree: Int) -> [V: Int] {
    Dictionary(uniqueKeysWithValues: vertices.map { ($0, degree) })
}

/// Degrees listed by vertex, for fixtures whose vertices are 0..<n.
private func byVertex(_ degrees: [Int]) -> [Int: Int] {
    Dictionary(uniqueKeysWithValues: degrees.enumerated().map { ($0.offset, $0.element) })
}

extension DirectedFixture where Vertex == Int {
    public static let empty = DirectedFixture<Int>(
        "empty graph", source: "definition",
        vertexCount: 0, edgeCount: 0, outDegree: [:], inDegree: [:]
    ) {}

    public static let trivial = DirectedFixture<Int>(
        "trivial graph K₁", source: "definition",
        vertexCount: 1, edgeCount: 0, outDegree: [0: 0], inDegree: [0: 0]
    ) {
        0
    }

    public static let singleSelfLoop = DirectedFixture<Int>(
        "one vertex with a self-loop", source: "NetworkX test_function.py (density with self-loops)",
        vertexCount: 1, edgeCount: 1, outDegree: [0: 1], inDegree: [0: 1]
    ) {
        DirectedEdge(from: 0, to: 0)
    }

    public static let isolatedVertices = DirectedFixture<Int>(
        "10 isolated vertices", source: "JGraphT EmptyGraphGenerator test; Boost.Graph adj_list_loops.cpp",
        vertexCount: 10, edgeCount: 0, outDegree: every(0 ..< 10, 0), inDegree: every(0 ..< 10, 0)
    ) {
        for v in 0 ..< 10 { v }
    }

    public static let directedPath3 = DirectedFixture<Int>(
        "directed path 0→1→2", source: "NetworkX test_digraph.py",
        vertexCount: 3, edgeCount: 2,
        outDegree: [0: 1, 1: 1, 2: 0],
        inDegree: [0: 0, 1: 1, 2: 1]
    ) {
        DirectedEdge(from: 0, to: 1)
        DirectedEdge(from: 1, to: 2)
    }

    public static let completeDirected3 = DirectedFixture<Int>(
        "complete directed graph on 3 vertices", source: "NetworkX test_digraph.py; JGraphT g3",
        vertexCount: 3, edgeCount: 6, outDegree: every(0 ..< 3, 2), inDegree: every(0 ..< 3, 2)
    ) {
        DirectedEdge(from: 0, to: 1)
        DirectedEdge(from: 0, to: 2)
        DirectedEdge(from: 1, to: 0)
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 2, to: 0)
        DirectedEdge(from: 2, to: 1)
    }

    /// n(n − 1) = 90 edges.
    public static let completeDirected10 = DirectedFixture<Int>(
        "complete directed graph on 10 vertices", source: "JGraphT CompleteGraphGenerator test",
        vertexCount: 10, edgeCount: 90, outDegree: every(0 ..< 10, 9), inDegree: every(0 ..< 10, 9)
    ) {
        for u in 0 ..< 10 {
            for v in 0 ..< 10 where v != u {
                DirectedEdge(from: u, to: v)
            }
        }
    }

    /// The adjacency mapping `{0: [1, 2, 3], 1: [1, 2, 0], 4: []}`.
    public static let networkXFunctionGraph = DirectedFixture<Int>(
        "NetworkX test_function graph", source: "NetworkX test_function.py (TestFunction setup)",
        vertexCount: 5, edgeCount: 6,
        outDegree: [0: 3, 1: 3, 2: 0, 3: 0, 4: 0],
        inDegree: [0: 1, 1: 2, 2: 2, 3: 1, 4: 0]
    ) {
        DirectedEdge(from: 0, to: 1)
        DirectedEdge(from: 0, to: 2)
        DirectedEdge(from: 0, to: 3)
        DirectedEdge(from: 1, to: 1)
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 1, to: 0)
        4
    }

    /// Every edge goes from a higher number to a lower one, so this is acyclic.
    public static let house = DirectedFixture<Int>(
        "Boost.Graph house-and-lollipop DAG", source: "Boost.Graph test/test_graph.hpp, test_direction.hpp",
        vertexCount: 6, edgeCount: 7,
        outDegree: [0: 0, 1: 1, 2: 1, 3: 2, 4: 2, 5: 1],
        inDegree: [0: 2, 1: 2, 2: 1, 3: 1, 4: 1, 5: 0]
    ) {
        DirectedEdge(from: 5, to: 3)
        DirectedEdge(from: 3, to: 4)
        DirectedEdge(from: 3, to: 2)
        DirectedEdge(from: 4, to: 0)
        DirectedEdge(from: 4, to: 1)
        DirectedEdge(from: 2, to: 1)
        DirectedEdge(from: 1, to: 0)
    }

    /// Three strongly connected components: {0, 3, 6}, {2, 5, 8}, {1, 4, 7}.
    public static let scc9 = DirectedFixture<Int>(
        "petgraph SCC9", source: "petgraph tests/graph.rs (scc fixtures)",
        vertexCount: 9, edgeCount: 11,
        outDegree: [0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 2, 8: 2],
        inDegree: [0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 2, 6: 2, 7: 1, 8: 1]
    ) {
        DirectedEdge(from: 6, to: 0)
        DirectedEdge(from: 0, to: 3)
        DirectedEdge(from: 3, to: 6)
        DirectedEdge(from: 8, to: 6)
        DirectedEdge(from: 8, to: 2)
        DirectedEdge(from: 2, to: 5)
        DirectedEdge(from: 5, to: 8)
        DirectedEdge(from: 7, to: 5)
        DirectedEdge(from: 1, to: 7)
        DirectedEdge(from: 7, to: 4)
        DirectedEdge(from: 4, to: 1)
    }

    /// 2→3 and 5→5 are written twice and collapse, so the degrees differ from JGraphT's
    /// multigraph expectations; these were re-derived.
    public static let selfLoopsAndDuplicates = DirectedFixture<Int>(
        "self-loops and duplicate edges", source: "JGraphT IncomingOutgoingEdgesTest graph, re-derived without parallel edges",
        vertexCount: 5, edgeCount: 6,
        outDegree: [1: 1, 2: 2, 3: 0, 4: 1, 5: 2],
        inDegree: [1: 0, 2: 2, 3: 1, 4: 2, 5: 1]
    ) {
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 2, to: 4)
        DirectedEdge(from: 4, to: 4)
        DirectedEdge(from: 5, to: 5)
        DirectedEdge(from: 5, to: 2)
        DirectedEdge(from: 5, to: 5)
    }

    public static let directedCycle4 = DirectedFixture<Int>(
        "directed cycle 1→2→3→4→1", source: "JGraphT SimpleDirectedGraphTest g4",
        vertexCount: 4, edgeCount: 4, outDegree: every(1 ... 4, 1), inDegree: every(1 ... 4, 1)
    ) {
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 3, to: 4)
        DirectedEdge(from: 4, to: 1)
    }

    public static let triangleWithReciprocalEdge = DirectedFixture<Int>(
        "triangle with a reciprocal edge", source: "JGraphT DirectedGraphTest",
        vertexCount: 3, edgeCount: 4,
        outDegree: [1: 1, 2: 2, 3: 1],
        inDegree: [1: 2, 2: 1, 3: 1]
    ) {
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 2, to: 1)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 3, to: 1)
    }

    /// The directed path 0→…→5, plus the chord 1→3 written twice.
    public static let pathWithChord = DirectedFixture<Int>(
        "path with a duplicated chord", source: "NetworkX test_reportviews.py (degree views)",
        vertexCount: 6, edgeCount: 6,
        outDegree: [0: 1, 1: 2, 2: 1, 3: 1, 4: 1, 5: 0],
        inDegree: [0: 0, 1: 1, 2: 1, 3: 2, 4: 1, 5: 1]
    ) {
        for v in 0 ..< 5 { DirectedEdge(from: v, to: v + 1) }
        DirectedEdge(from: 1, to: 3)
        DirectedEdge(from: 1, to: 3)
    }

    /// The Petersen graph GP(5, 2), each edge as a pair of opposite edges: an outer 5-cycle
    /// 0…4, spokes i–(i + 5), and an inner pentagram on 5…9.
    public static let petersen = DirectedFixture<Int>(
        "Petersen graph (symmetric)", source: "definition; JGraphT GeneralizedPetersenGraphGenerator test (10 vertices, 15 edges, cubic)",
        vertexCount: 10, edgeCount: 30, outDegree: every(0 ..< 10, 3), inDegree: every(0 ..< 10, 3)
    ) {
        for i in 0 ..< 5 {
            let next = (i + 1) % 5
            let skip = 5 + (i + 2) % 5
            DirectedEdge(from: i, to: next)
            DirectedEdge(from: next, to: i)
            DirectedEdge(from: i, to: i + 5)
            DirectedEdge(from: i + 5, to: i)
            DirectedEdge(from: i + 5, to: skip)
            DirectedEdge(from: skip, to: i + 5)
        }
    }

    /// The 3-cube Q₃, each edge as a pair of opposite edges: vertices are 3-bit numbers, adjacent
    /// when they differ in one bit.
    public static let cube = DirectedFixture<Int>(
        "cube Q₃ (symmetric)", source: "definition; JGraphT GeneralizedPetersenGraphGenerator test (GP(4,1) = Q₃)",
        vertexCount: 8, edgeCount: 24, outDegree: every(0 ..< 8, 3), inDegree: every(0 ..< 8, 3)
    ) {
        for v in 0 ..< 8 {
            for bit in 0 ..< 3 {
                DirectedEdge(from: v, to: v ^ (1 << bit))
            }
        }
    }

    public static let directedPath10 = DirectedFixture<Int>(
        "directed path on 10 vertices", source: "JGraphT LinearGraphGenerator test",
        vertexCount: 10, edgeCount: 9,
        outDegree: every(0 ..< 9, 1).merging([9: 0]) { $1 },
        inDegree: every(1 ..< 10, 1).merging([0: 0]) { $1 }
    ) {
        for v in 0 ..< 9 { DirectedEdge(from: v, to: v + 1) }
    }

    public static let directedCycle10 = DirectedFixture<Int>(
        "directed cycle on 10 vertices", source: "JGraphT RingGraphGenerator test",
        vertexCount: 10, edgeCount: 10, outDegree: every(0 ..< 10, 1), inDegree: every(0 ..< 10, 1)
    ) {
        for v in 0 ..< 10 { DirectedEdge(from: v, to: (v + 1) % 10) }
    }

    /// Vertices A…F as 0…5: B→C, B→F, C→A, C→C, D→E, E→D, F→A.
    public static let boostExample = DirectedFixture<Int>(
        "Boost.Graph adjacency_matrix example", source: "Boost.Graph example/adjacency_matrix.cpp",
        vertexCount: 6, edgeCount: 7,
        outDegree: byVertex([0, 2, 2, 1, 1, 1]),
        inDegree: byVertex([2, 0, 2, 1, 1, 1])
    ) {
        0
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 1, to: 5)
        DirectedEdge(from: 2, to: 0)
        DirectedEdge(from: 2, to: 2)
        DirectedEdge(from: 3, to: 4)
        DirectedEdge(from: 4, to: 3)
        DirectedEdge(from: 5, to: 0)
    }

    /// The 24-vertex, 43-edge digraph Boost.Graph uses to check adjacency_matrix against
    /// adjacency_list. Vertex 7 has no predecessors and vertex 0 no successors.
    public static let boost24 = DirectedFixture<Int>(
        "Boost.Graph 24-vertex test digraph", source: "Boost.Graph test/adjacency_matrix_test.cpp",
        vertexCount: 24, edgeCount: 43,
        outDegree: byVertex([0, 1, 2, 2, 2, 1, 1, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1]),
        inDegree: byVertex([2, 2, 1, 1, 3, 2, 2, 0, 3, 1, 2, 2, 2, 2, 1, 3, 1, 2, 2, 3, 1, 1, 2, 2])
    ) {
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 2, to: 10)
        DirectedEdge(from: 2, to: 5)
        DirectedEdge(from: 3, to: 10)
        DirectedEdge(from: 3, to: 0)
        DirectedEdge(from: 4, to: 5)
        DirectedEdge(from: 4, to: 0)
        DirectedEdge(from: 5, to: 14)
        DirectedEdge(from: 6, to: 3)
        DirectedEdge(from: 7, to: 17)
        DirectedEdge(from: 7, to: 11)
        DirectedEdge(from: 8, to: 17)
        DirectedEdge(from: 8, to: 1)
        DirectedEdge(from: 9, to: 11)
        DirectedEdge(from: 9, to: 1)
        DirectedEdge(from: 10, to: 19)
        DirectedEdge(from: 10, to: 15)
        DirectedEdge(from: 10, to: 8)
        DirectedEdge(from: 11, to: 19)
        DirectedEdge(from: 11, to: 15)
        DirectedEdge(from: 11, to: 4)
        DirectedEdge(from: 12, to: 19)
        DirectedEdge(from: 12, to: 8)
        DirectedEdge(from: 12, to: 4)
        DirectedEdge(from: 13, to: 15)
        DirectedEdge(from: 13, to: 8)
        DirectedEdge(from: 13, to: 4)
        DirectedEdge(from: 14, to: 22)
        DirectedEdge(from: 14, to: 12)
        DirectedEdge(from: 15, to: 22)
        DirectedEdge(from: 15, to: 6)
        DirectedEdge(from: 16, to: 12)
        DirectedEdge(from: 16, to: 6)
        DirectedEdge(from: 17, to: 20)
        DirectedEdge(from: 18, to: 9)
        DirectedEdge(from: 19, to: 23)
        DirectedEdge(from: 19, to: 18)
        DirectedEdge(from: 20, to: 23)
        DirectedEdge(from: 20, to: 13)
        DirectedEdge(from: 21, to: 18)
        DirectedEdge(from: 21, to: 13)
        DirectedEdge(from: 22, to: 21)
        DirectedEdge(from: 23, to: 16)
    }

    /// Vertex 6 has only a self-loop; vertices 3 and 5 have no successors.
    public static let petgraphEdgesDirected = DirectedFixture<Int>(
        "petgraph test_edges_directed graph", source: "petgraph src/matrix_graph.rs (test_edges_directed)",
        vertexCount: 7, edgeCount: 9,
        outDegree: byVertex([4, 1, 2, 0, 1, 0, 1]),
        inDegree: byVertex([1, 1, 1, 3, 1, 1, 1])
    ) {
        DirectedEdge(from: 0, to: 5)
        DirectedEdge(from: 0, to: 2)
        DirectedEdge(from: 0, to: 3)
        DirectedEdge(from: 0, to: 1)
        DirectedEdge(from: 1, to: 3)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 2, to: 4)
        DirectedEdge(from: 4, to: 0)
        DirectedEdge(from: 6, to: 6)
    }

    public static let igraphReverseEdges = DirectedFixture<Int>(
        "igraph reverse_edges graph", source: "igraph tests/unit/igraph_reverse_edges.c (behaviour reference only; GPL)",
        vertexCount: 5, edgeCount: 5,
        outDegree: byVertex([1, 2, 1, 1, 0]),
        inDegree: byVertex([0, 2, 1, 1, 1])
    ) {
        DirectedEdge(from: 0, to: 1)
        DirectedEdge(from: 1, to: 2)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 3, to: 1)
        DirectedEdge(from: 1, to: 4)
    }

    /// JGraphT's CSV matrix fixture, renumbered from 1…5 to 0…4. Vertex 4 points at every vertex,
    /// itself included.
    public static let jgraphtMatrixCSV = DirectedFixture<Int>(
        "JGraphT CSV matrix graph", source: "JGraphT CSVExporterTest / CSVImporterTest, re-derived and renumbered from 0",
        vertexCount: 5, edgeCount: 10,
        outDegree: byVertex([2, 0, 2, 1, 5]),
        inDegree: byVertex([2, 2, 2, 2, 2])
    ) {
        DirectedEdge(from: 0, to: 1)
        DirectedEdge(from: 0, to: 2)
        DirectedEdge(from: 2, to: 0)
        DirectedEdge(from: 2, to: 3)
        DirectedEdge(from: 3, to: 4)
        DirectedEdge(from: 4, to: 0)
        DirectedEdge(from: 4, to: 1)
        DirectedEdge(from: 4, to: 2)
        DirectedEdge(from: 4, to: 3)
        DirectedEdge(from: 4, to: 4)
    }

    /// Every fixture with `Int` vertices.
    public static let all: [DirectedFixture<Int>] = [
        .empty, .trivial, .singleSelfLoop, .isolatedVertices, .directedPath3, .completeDirected3,
        .completeDirected10, .networkXFunctionGraph, .house, .scc9, .selfLoopsAndDuplicates,
        .directedCycle4, .triangleWithReciprocalEdge, .pathWithChord, .petersen, .cube,
        .directedPath10, .directedCycle10, .boostExample, .boost24, .petgraphEdgesDirected,
        .igraphReverseEdges, .jgraphtMatrixCSV,
    ]

    /// Fixtures with at least one edge.
    public static let nonempty: [DirectedFixture<Int>] = all.filter { !$0.edges.isEmpty }

    /// Fixtures whose vertices are exactly 0..<vertexCount, as index-based representations need.
    public static let zeroBased: [DirectedFixture<Int>] = all.filter { $0.vertexSet == Set(0 ..< $0.vertexCount) }
}

extension DirectedFixture where Vertex == String {
    /// Four connected vertices plus isolated G, J and K.
    public static let networkXABCD = DirectedFixture<String>(
        "NetworkX ABCD with isolated vertices", source: "NetworkX test_digraph_historical.py",
        vertexCount: 7, edgeCount: 5,
        outDegree: ["A": 2, "B": 2, "C": 1, "D": 0, "G": 0, "J": 0, "K": 0],
        inDegree: ["A": 0, "B": 1, "C": 2, "D": 2, "G": 0, "J": 0, "K": 0]
    ) {
        DirectedEdge(from: "A", to: "B")
        DirectedEdge(from: "A", to: "C")
        DirectedEdge(from: "B", to: "D")
        DirectedEdge(from: "B", to: "C")
        DirectedEdge(from: "C", to: "D")
        "G"
        "J"
        "K"
    }

    /// Acyclic; the original's edge weights are omitted.
    public static let petgraphDAG = DirectedFixture<String>(
        "petgraph 7-vertex DAG", source: "petgraph tests/graph.rs",
        vertexCount: 7, edgeCount: 11,
        outDegree: ["a": 2, "b": 2, "c": 1, "d": 3, "e": 1, "f": 2, "g": 0],
        inDegree: ["a": 0, "b": 2, "c": 1, "d": 1, "e": 4, "f": 1, "g": 2]
    ) {
        DirectedEdge(from: "a", to: "b")
        DirectedEdge(from: "a", to: "d")
        DirectedEdge(from: "d", to: "b")
        DirectedEdge(from: "b", to: "c")
        DirectedEdge(from: "b", to: "e")
        DirectedEdge(from: "c", to: "e")
        DirectedEdge(from: "d", to: "e")
        DirectedEdge(from: "d", to: "f")
        DirectedEdge(from: "f", to: "e")
        DirectedEdge(from: "f", to: "g")
        DirectedEdge(from: "e", to: "g")
    }

    public static let all: [DirectedFixture<String>] = [.networkXABCD, .petgraphDAG]
}
