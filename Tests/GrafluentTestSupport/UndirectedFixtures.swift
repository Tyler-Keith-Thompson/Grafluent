// Named undirected graphs with independently known properties.
//
// Graph definitions and expected values are mathematical facts, restated here from the test
// suites and generators where they were found. Each fixture cites its origin. Degrees count edge
// ends, so a self-loop adds 2 to its vertex's degree (NetworkX, JGraphT, Boost agree on the
// number). Expected values are given twice: for a simple graph, where repeated edges collapse
// (`edgeCount`, `degree`), and for a pseudograph, which keeps every edge as written
// (`pseudographEdgeCount`, `pseudographDegree`, NetworkX `MultiGraph`). They differ only where an
// edge is written twice.
//
// The graph itself is written with `GraphBuilder`. The builder only collects the edges and
// vertices as written; the expected values beside it were computed by hand or with NetworkX,
// never from code under test. GrafluentTestSupportTests checks that the two agree.

import GraphProtocols
import Testing

/// An undirected graph given as data, with its expected vertex count, edge counts and degrees.
public struct UndirectedFixture<Vertex: Hashable & Sendable>: Sendable, CustomTestStringConvertible {
    public let name: String
    /// Where the graph and its expected values come from.
    public let source: String
    /// Vertices listed on their own, typically the isolated ones. Edge endpoints need not appear.
    public let vertices: [Vertex]
    /// Edges as written. May repeat an edge (in either orientation), which a simple graph collapses.
    public let edges: [UndirectedEdge<Vertex>]
    /// Expected number of vertices.
    public let vertexCount: Int
    /// Expected number of edges after repeated edges collapse; a self-loop counts once.
    public let edgeCount: Int
    /// Expected degree(of: v) for every vertex after repeated edges collapse; a self-loop counts 2.
    public let degree: [Vertex: Int]
    /// Expected number of edges with every written edge kept.
    public let pseudographEdgeCount: Int
    /// Expected degree(of: v) for every vertex with every written edge kept.
    public let pseudographDegree: [Vertex: Int]

    /// A fixture whose written edges are all distinct, so the simple and pseudograph values agree.
    public init(
        _ name: String,
        source: String,
        vertexCount: Int,
        edgeCount: Int,
        degree: [Vertex: Int],
        @GraphBuilder<Vertex> graph: () -> GraphBuilder<Vertex>.Content
    ) {
        let content = graph()
        self.init(
            name, source: source, vertices: content.vertices, edges: content.edges, vertexCount: vertexCount,
            edgeCount: edgeCount, degree: degree, pseudographEdgeCount: edgeCount, pseudographDegree: degree
        )
    }

    /// A fixture that writes some edge more than once.
    public init(
        _ name: String,
        source: String,
        vertexCount: Int,
        edgeCount: Int,
        degree: [Vertex: Int],
        pseudographEdgeCount: Int,
        pseudographDegree: [Vertex: Int],
        @GraphBuilder<Vertex> graph: () -> GraphBuilder<Vertex>.Content
    ) {
        let content = graph()
        self.init(
            name, source: source, vertices: content.vertices, edges: content.edges, vertexCount: vertexCount,
            edgeCount: edgeCount, degree: degree, pseudographEdgeCount: pseudographEdgeCount, pseudographDegree: pseudographDegree
        )
    }

    public init(
        _ name: String,
        source: String,
        vertices: [Vertex],
        edges: [UndirectedEdge<Vertex>],
        vertexCount: Int,
        edgeCount: Int,
        degree: [Vertex: Int],
        pseudographEdgeCount: Int,
        pseudographDegree: [Vertex: Int]
    ) {
        self.name = name
        self.source = source
        self.vertices = vertices
        self.edges = edges
        self.vertexCount = vertexCount
        self.edgeCount = edgeCount
        self.degree = degree
        self.pseudographEdgeCount = pseudographEdgeCount
        self.pseudographDegree = pseudographDegree
    }

    public var testDescription: String { name }

    /// The distinct edges (`UndirectedEdge` equality ignores orientation).
    public var edgeSet: Set<UndirectedEdge<Vertex>> { Set(edges) }

    /// The distinct vertices, including edge endpoints not listed in `vertices`.
    public var vertexSet: Set<Vertex> { Set(vertices).union(edges.flatMap { [$0.u, $0.v] }) }
}

/// The same degree for every vertex in `vertices`.
private func every<V: Hashable>(_ vertices: some Sequence<V>, _ degree: Int) -> [V: Int] {
    Dictionary(uniqueKeysWithValues: vertices.map { ($0, degree) })
}

/// Degrees listed by vertex, for fixtures whose vertices are 0..<n.
private func byVertex(_ degrees: [Int]) -> [Int: Int] {
    Dictionary(uniqueKeysWithValues: degrees.enumerated().map { ($0.offset, $0.element) })
}

extension UndirectedFixture where Vertex == Int {
    public static let empty = UndirectedFixture<Int>(
        "empty graph", source: "definition",
        vertexCount: 0, edgeCount: 0, degree: [:]
    ) {}

    public static let trivial = UndirectedFixture<Int>(
        "trivial graph K₁", source: "definition",
        vertexCount: 1, edgeCount: 0, degree: [0: 0]
    ) {
        0
    }

    public static let singleSelfLoop = UndirectedFixture<Int>(
        "one vertex with a self-loop", source: "NetworkX test_graph.py test_selfloop_degree",
        vertexCount: 1, edgeCount: 1, degree: [0: 2]
    ) {
        UndirectedEdge(0, 0)
    }

    public static let isolatedVertices = UndirectedFixture<Int>(
        "10 isolated vertices", source: "definition",
        vertexCount: 10, edgeCount: 0, degree: every(0 ..< 10, 0)
    ) {
        for v in 0 ..< 10 { v }
    }

    public static let k3 = UndirectedFixture<Int>(
        "complete graph K₃", source: "NetworkX test_graph.py BaseGraphTester (K3)",
        vertexCount: 3, edgeCount: 3, degree: every(0 ..< 3, 2)
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(0, 2)
        UndirectedEdge(1, 2)
    }

    public static let k3WithLoop = UndirectedFixture<Int>(
        "K₃ with a self-loop at 0", source: "NetworkX test_graph.py test_selfloops",
        vertexCount: 3, edgeCount: 4, degree: [0: 4, 1: 2, 2: 2]
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(0, 2)
        UndirectedEdge(1, 2)
        UndirectedEdge(0, 0)
    }

    public static let loopAndPath = UndirectedFixture<Int>(
        "a self-loop on the end of a path", source: "NetworkX Graph([(0, 0), (0, 1), (1, 2)])",
        vertexCount: 3, edgeCount: 3, degree: [0: 3, 1: 2, 2: 1]
    ) {
        UndirectedEdge(0, 0)
        UndirectedEdge(0, 1)
        UndirectedEdge(1, 2)
    }

    /// a, b, c, d are 0, 1, 2, 3. a–c and a–b are each written twice (once reversed).
    public static let petgraphUndirected = UndirectedFixture<Int>(
        "petgraph undirected with repeats and a loop", source: "petgraph tests/graph.rs undirected; NetworkX Graph and MultiGraph degrees",
        vertexCount: 4, edgeCount: 5, degree: [0: 5, 1: 2, 2: 2, 3: 1],
        pseudographEdgeCount: 7, pseudographDegree: [0: 7, 1: 3, 2: 3, 3: 1]
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(0, 2)
        UndirectedEdge(2, 0)
        UndirectedEdge(0, 0)
        UndirectedEdge(1, 2)
        UndirectedEdge(1, 0)
        UndirectedEdge(0, 3)
    }

    public static let components7 = UndirectedFixture<Int>(
        "four components on seven vertices", source: "NetworkX connected_components",
        vertexCount: 7, edgeCount: 3, degree: byVertex([1, 2, 1, 1, 1, 0, 0])
    ) {
        for v in 0 ..< 7 { v }
        UndirectedEdge(0, 1)
        UndirectedEdge(1, 2)
        UndirectedEdge(3, 4)
    }

    public static let path4 = UndirectedFixture<Int>(
        "path P₄", source: "NetworkX path_graph(4)",
        vertexCount: 4, edgeCount: 3, degree: byVertex([1, 2, 2, 1])
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(1, 2)
        UndirectedEdge(2, 3)
    }

    public static let cycle5 = UndirectedFixture<Int>(
        "cycle C₅", source: "NetworkX cycle_graph(5)",
        vertexCount: 5, edgeCount: 5, degree: every(0 ..< 5, 2)
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(1, 2)
        UndirectedEdge(2, 3)
        UndirectedEdge(3, 4)
        UndirectedEdge(0, 4)
    }

    public static let k4 = UndirectedFixture<Int>(
        "complete graph K₄", source: "NetworkX complete_graph(4)",
        vertexCount: 4, edgeCount: 6, degree: every(0 ..< 4, 3)
    ) {
        for u in 0 ..< 4 {
            for v in u + 1 ..< 4 { UndirectedEdge(u, v) }
        }
    }

    public static let house = UndirectedFixture<Int>(
        "house graph", source: "NetworkX generators/small.py house_graph",
        vertexCount: 5, edgeCount: 6, degree: byVertex([2, 2, 3, 3, 2])
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(0, 2)
        UndirectedEdge(1, 3)
        UndirectedEdge(2, 3)
        UndirectedEdge(2, 4)
        UndirectedEdge(3, 4)
    }

    public static let petersen = UndirectedFixture<Int>(
        "Petersen graph", source: "NetworkX generators/small.py petersen_graph",
        vertexCount: 10, edgeCount: 15, degree: every(0 ..< 10, 3)
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(0, 4)
        UndirectedEdge(0, 5)
        UndirectedEdge(1, 2)
        UndirectedEdge(1, 6)
        UndirectedEdge(2, 3)
        UndirectedEdge(2, 7)
        UndirectedEdge(3, 4)
        UndirectedEdge(3, 8)
        UndirectedEdge(4, 9)
        UndirectedEdge(5, 7)
        UndirectedEdge(5, 8)
        UndirectedEdge(6, 8)
        UndirectedEdge(6, 9)
        UndirectedEdge(7, 9)
    }

    /// The 3-cube Q₃, its vertices (bit tuples) numbered in sorted order.
    public static let cube = UndirectedFixture<Int>(
        "cube graph Q₃", source: "NetworkX hypercube_graph(3), labels sorted",
        vertexCount: 8, edgeCount: 12, degree: every(0 ..< 8, 3)
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(0, 2)
        UndirectedEdge(0, 4)
        UndirectedEdge(1, 3)
        UndirectedEdge(1, 5)
        UndirectedEdge(2, 3)
        UndirectedEdge(2, 6)
        UndirectedEdge(3, 7)
        UndirectedEdge(4, 5)
        UndirectedEdge(4, 6)
        UndirectedEdge(5, 7)
        UndirectedEdge(6, 7)
    }

    public static let karate = UndirectedFixture<Int>(
        "Zachary's karate club", source: "NetworkX generators/social.py karate_club_graph",
        vertexCount: 34, edgeCount: 78,
        degree: byVertex([
            16, 9, 10, 6, 3, 4, 4, 4, 5, 2, 3, 1, 2, 5, 2, 2, 2, 2, 2, 3, 2, 2, 2, 5, 3, 3, 2, 4, 3, 4, 4, 6, 12, 17,
        ])
    ) {
        for v in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 17, 19, 21, 31] { UndirectedEdge(0, v) }
        for v in [2, 3, 7, 13, 17, 19, 21, 30] { UndirectedEdge(1, v) }
        for v in [3, 7, 8, 9, 13, 27, 28, 32] { UndirectedEdge(2, v) }
        for v in [7, 12, 13] { UndirectedEdge(3, v) }
        for v in [6, 10] { UndirectedEdge(4, v) }
        for v in [6, 10, 16] { UndirectedEdge(5, v) }
        UndirectedEdge(6, 16)
        for v in [30, 32, 33] { UndirectedEdge(8, v) }
        UndirectedEdge(9, 33)
        UndirectedEdge(13, 33)
        for v in [32, 33] { UndirectedEdge(14, v) }
        for v in [32, 33] { UndirectedEdge(15, v) }
        for v in [32, 33] { UndirectedEdge(18, v) }
        UndirectedEdge(19, 33)
        for v in [32, 33] { UndirectedEdge(20, v) }
        for v in [32, 33] { UndirectedEdge(22, v) }
        for v in [25, 27, 29, 32, 33] { UndirectedEdge(23, v) }
        for v in [25, 27, 31] { UndirectedEdge(24, v) }
        UndirectedEdge(25, 31)
        for v in [29, 33] { UndirectedEdge(26, v) }
        UndirectedEdge(27, 33)
        for v in [31, 33] { UndirectedEdge(28, v) }
        for v in [32, 33] { UndirectedEdge(29, v) }
        for v in [32, 33] { UndirectedEdge(30, v) }
        for v in [32, 33] { UndirectedEdge(31, v) }
        UndirectedEdge(32, 33)
    }

    /// 1–2 is written twice: a simple graph has the path 0–1–2, a pseudograph a doubled edge.
    public static let parallelPath = UndirectedFixture<Int>(
        "path with a doubled edge", source: "NetworkX MultiGraph([(0, 1), (1, 2), (1, 2)])",
        vertexCount: 3, edgeCount: 2, degree: byVertex([1, 2, 1]),
        pseudographEdgeCount: 3, pseudographDegree: byVertex([1, 3, 2])
    ) {
        UndirectedEdge(0, 1)
        UndirectedEdge(1, 2)
        UndirectedEdge(1, 2)
    }

    /// Every fixture above.
    public static let all: [UndirectedFixture<Int>] = [
        .empty, .trivial, .singleSelfLoop, .isolatedVertices, .k3, .k3WithLoop, .loopAndPath,
        .petgraphUndirected, .components7, .path4, .cycle5, .k4, .house, .petersen, .cube, .karate,
        .parallelPath,
    ]

    /// Fixtures with at least one edge.
    public static let nonempty: [UndirectedFixture<Int>] = all.filter { !$0.edges.isEmpty }
}

extension UndirectedFixture where Vertex == String {
    /// Four connected vertices plus isolated G, J and K.
    public static let networkXABCD = UndirectedFixture<String>(
        "NetworkX ABCD with isolated vertices", source: "NetworkX classes/tests/historical_tests.py test_iterators",
        vertexCount: 7, edgeCount: 5,
        degree: ["A": 2, "B": 3, "C": 3, "D": 2, "G": 0, "J": 0, "K": 0]
    ) {
        UndirectedEdge("A", "B")
        UndirectedEdge("A", "C")
        UndirectedEdge("B", "D")
        UndirectedEdge("C", "B")
        UndirectedEdge("C", "D")
        "G"
        "J"
        "K"
    }

    /// A self-loop at K.
    public static let networkXIJK = UndirectedFixture<String>(
        "NetworkX IJK with a self-loop", source: "NetworkX classes/tests/historical_tests.py test_add_edges_from2",
        vertexCount: 3, edgeCount: 3,
        degree: ["I": 1, "J": 2, "K": 3]
    ) {
        UndirectedEdge("I", "J")
        UndirectedEdge("K", "K")
        UndirectedEdge("J", "K")
    }

    /// The Int fixture of the same name, with petgraph's own vertex names.
    public static let petgraphUndirected = UndirectedFixture<String>(
        "petgraph undirected with repeats and a loop, named", source: "petgraph tests/graph.rs undirected",
        vertexCount: 4, edgeCount: 5, degree: ["a": 5, "b": 2, "c": 2, "d": 1],
        pseudographEdgeCount: 7, pseudographDegree: ["a": 7, "b": 3, "c": 3, "d": 1]
    ) {
        UndirectedEdge("a", "b")
        UndirectedEdge("a", "c")
        UndirectedEdge("c", "a")
        UndirectedEdge("a", "a")
        UndirectedEdge("b", "c")
        UndirectedEdge("b", "a")
        UndirectedEdge("a", "d")
    }

    public static let all: [UndirectedFixture<String>] = [.networkXABCD, .networkXIJK, .petgraphUndirected]
}
