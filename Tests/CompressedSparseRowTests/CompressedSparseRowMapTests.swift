// Attached maps (GraphProtocols' `PropertyGraph`): a vertex map holds one value per vertex and an
// edge map one per edge index, every value the map's default until it is set. The graph is
// immutable, so nothing ever moves a value; the tests check defaults, writes by position and by
// vertex, the `checked` subscripts, `values(of:)` snapshots, copy-on-write between copies, handles
// that belong to another graph or were removed (traps, in child processes), that equality, hashing
// and coding ignore maps, and the generations: every initializer but `init()` stamps one, and
// `init(_:)` records the source's. The model test compares maps against dictionaries keyed by edge
// and vertex. See README.md.

import CompressedSparseRowModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("CompressedSparseRow attached maps")
struct CompressedSparseRowMapTests {
    @Test("A new map gives every vertex and edge its default; writes land at their position")
    func defaultsAndWrites() throws {
        // 0 → 1, 0 → 2, 1 → 2, 2 → 2: edge indices 0, 1, 2, 3.
        var graph = CompressedSparseRow(vertexCount: 4, edges: [
            DirectedEdge(from: 2, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1),
        ])
        let weights = graph.addEdgeMap(default: 1.5)
        let names = graph.addVertexMap(of: String.self)
        #expect(graph.edges.indices.map { graph[weights, ofEdgeAt: $0] } == [1.5, 1.5, 1.5, 1.5])
        #expect(graph.vertices.map { graph[names, of: $0] } == [nil, nil, nil, nil])

        graph[weights, ofEdgeAt: graph.edgeIndex(of: DirectedEdge(from: 1, to: 2))!] = 7
        graph[weights, ofEdgeAt: 0] = 2
        graph[names, of: 3] = "isolated"
        graph[names, ofVertexAt: 0] = "zero"
        #expect(graph.edges.indices.map { graph[weights, ofEdgeAt: $0] } == [2, 1.5, 7, 1.5])
        #expect(graph[names, of: 3] == "isolated" && graph[names, ofVertexAt: 3] == "isolated")
        #expect(graph[names, of: 0] == "zero" && graph[names, of: 1] == nil)
        graph[names, of: 0] = nil
        #expect(graph[names, of: 0] == nil)

        // The checked spellings agree in range and throw outside it.
        #expect(try graph[weights, checkedEdgeAt: 2] == 7)
        #expect(try graph[names, checkedVertexAt: 3] == "isolated")
        #expect(try graph[names, checked: 3] == "isolated")
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 4] }
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: -1] }
        #expect(throws: VertexNotFound.self) { try graph[names, checkedVertexAt: 4] }
        #expect(throws: VertexNotFound.self) { try graph[names, checked: -1] }

        // values(of:) reads the same values by position, and is a snapshot.
        let w = graph.values(of: weights)
        #expect(graph.edges.indices.map { w[$0] } == [2, 1.5, 7, 1.5])
        #expect(w.defaultValue == 1.5)
        let v = graph.values(of: names)
        #expect(v[3] == "isolated" && v.defaultValue == nil)
        graph[weights, ofEdgeAt: 1] = 9
        #expect(w[1] == 1.5 && graph.values(of: weights)[1] == 9)
    }

    @Test("Maps of a graph with no edges, and of the empty graph")
    func emptyGraphs() throws {
        var isolated = CompressedSparseRow(vertexCount: 3)
        let weights = isolated.addEdgeMap(default: 0)
        let colors = isolated.addVertexMap(default: -1)
        isolated[colors, of: 2] = 5
        #expect(isolated.vertices.map { isolated[colors, of: $0] } == [-1, -1, 5])
        #expect(throws: EdgeNotFound.self) { try isolated[weights, checkedEdgeAt: 0] }

        var empty = CompressedSparseRow()
        let none = empty.addVertexMap(default: 0)
        let noEdges = empty.addEdgeMap(default: 0)
        #expect(throws: VertexNotFound.self) { try empty[none, checked: 0] }
        #expect(throws: EdgeNotFound.self) { try empty[noEdges, checkedEdgeAt: 0] }
    }

    @Test("Several maps of different types are independent; removing one keeps the others", .tags(.copyOnWrite))
    func severalMaps() {
        var graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let a = graph.addEdgeMap(default: 0)
        let b = graph.addEdgeMap(default: "b")
        let c = graph.addEdgeMap(of: [Int].self)
        let d = graph.addVertexMap(default: false)
        graph[a, ofEdgeAt: 1] = 10
        graph[b, ofEdgeAt: 0] = "first"
        graph[c, ofEdgeAt: 1] = [1, 2]
        graph[d, of: 1] = true
        #expect(AnyHashable(a) != AnyHashable(b) && Set([a, a]).count == 1)
        // Removing the first map moves the others in the graph's table: their handles still find
        // them.
        graph.removeEdgeMap(a)
        #expect(graph[b, ofEdgeAt: 0] == "first" && graph[b, ofEdgeAt: 1] == "b")
        #expect(graph[c, ofEdgeAt: 1] == [1, 2] && graph[c, ofEdgeAt: 0] == nil)
        graph.removeVertexMap(d)
        let e = graph.addVertexMap(default: 3)
        #expect(graph.vertices.map { graph[e, of: $0] } == [3, 3, 3])
    }

    @Test("A copy shares the maps until either writes; the handle works on both", .tags(.copyOnWrite))
    func copiesAreIndependent() {
        var graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = graph.addEdgeMap(default: 0.0)
        let labels = graph.addVertexMap(default: "")
        graph[weights, ofEdgeAt: 0] = 1
        graph[labels, of: 0] = "a"
        var copy = graph
        let snapshot = graph.values(of: weights)
        copy[weights, ofEdgeAt: 0] = 5
        copy[labels, of: 0] = "b"
        #expect(graph[weights, ofEdgeAt: 0] == 1 && copy[weights, ofEdgeAt: 0] == 5)
        #expect(graph[labels, of: 0] == "a" && copy[labels, of: 0] == "b")
        graph[weights, ofEdgeAt: 1] = 2
        #expect(copy[weights, ofEdgeAt: 1] == 0 && snapshot[1] == 0)
        // A map added to the copy afterwards is the copy's alone.
        let extra = copy.addEdgeMap(default: 1)
        #expect(copy[extra, ofEdgeAt: 1] == 1)
        // Removing a map from one copy keeps it on the other.
        copy.removeEdgeMap(weights)
        #expect(graph[weights, ofEdgeAt: 0] == 1)
    }

    @Test("Equality, hashing and coding ignore maps; a decoded graph has none")
    func conformancesIgnoreMaps() throws {
        let plain = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0)])
        var mapped = plain
        let weights = mapped.addEdgeMap(default: 1)
        mapped[weights, ofEdgeAt: 1] = 4
        _ = mapped.addVertexMap(default: "x")
        #expect(mapped == plain && mapped.hashValue == plain.hashValue)
        #expect(mapped.description == plain.description && mapped.debugDescription == plain.debugDescription)
        // Sorted keys: a keyed container's order is otherwise not deterministic.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(mapped)
        #expect(encoded == (try encoder.encode(plain)))
        var decoded = try JSONDecoder().decode(CompressedSparseRow.self, from: encoded)
        #expect(decoded == plain)
        // Its own maps start fresh.
        let fresh = decoded.addEdgeMap(default: 2)
        #expect(decoded[fresh, ofEdgeAt: 1] == 2)
    }

    @Test("Generations: every initializer but init() stamps one; copies share it; attaching maps keeps it")
    func generations() throws {
        let empty = CompressedSparseRow()
        #expect(!empty.generation.isCurrent(for: empty))
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
        var edgeIndices: [Int] = []
        let built: [CompressedSparseRow] = [
            CompressedSparseRow(vertexCount: 0),
            CompressedSparseRow(vertexCount: 3),
            CompressedSparseRow(vertexCount: 0, edges: [] as [DirectedEdge<Int>]),
            CompressedSparseRow(vertexCount: 3, edges: edges),
            CompressedSparseRow(vertexCount: 3, edges: edges.reversed()),
            CompressedSparseRow(vertexCount: 3, edges: edges + edges),
            CompressedSparseRow(vertexCount: 3, edges: AnySequence(edges)),
            CompressedSparseRow(vertexCount: 3, edges: edges, edgeIndices: &edgeIndices),
            CompressedSparseRow(vertexCount: 3, sources: [0, 1], targets: [1, 2]),
            try CompressedSparseRow(offsets: [0, 1, 2, 2], targets: [1, 2]),
            CompressedSparseRow(_vertexCount: 3, sortedEdges: edges, _ConstructionToken()),
            try JSONDecoder().decode(CompressedSparseRow.self, from: JSONEncoder().encode(CompressedSparseRow(vertexCount: 3, edges: edges))),
            CompressedSparseRow(vertexCount: 3, edges: edges).transposed(),
            CompressedSparseRow(vertexCount: 0).transposed(),
        ]
        for (k, graph) in built.enumerated() {
            #expect(graph.generation.isCurrent(for: graph), "\(k)")
            for (j, other) in built.enumerated() where j != k {
                #expect(!graph.generation.isCurrent(for: other), "\(k) against \(j)")
            }
        }
        // The transpose is another graph, the transpose of a graph with no vertices included.
        let none = CompressedSparseRow(vertexCount: 0)
        #expect(!none.transposed().generation.isCurrent(for: none))
        #expect(!built[3].transposed().generation.isCurrent(for: built[3]))
        var graph = built[3]
        let before = graph.generation
        let copy = graph
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: 0] = 1
        graph.removeEdgeMap(weights)
        #expect(before.isCurrent(for: graph) && before.isCurrent(for: copy))
        #expect(graph == built[4] && !before.isCurrent(for: built[4]))
    }

    @Test("init(_:) records the source's generation: current until the source changes")
    func sourceGeneration() {
        var source = GenerationCountingGraph(vertexCount: 3)
        source.insert(DirectedEdge(from: 0, to: 1))
        let compressed = CompressedSparseRow(source)
        #expect(compressed.isCurrent(for: source))
        #expect(compressed.sourceGeneration.isCurrent(for: source))
        #expect(!compressed.isCurrent(for: compressed))
        #expect(!compressed.generation.isCurrent(for: source))
        let copy = source
        #expect(compressed.isCurrent(for: copy))
        source.insert(DirectedEdge(from: 1, to: 2))
        #expect(!compressed.isCurrent(for: source) && compressed.isCurrent(for: copy))
        #expect(CompressedSparseRow(source).isCurrent(for: source))

        // Built any other way, it has no source.
        let direct = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(!direct.isCurrent(for: source) && !direct.sourceGeneration.isCurrent(for: direct))
        // From a graph that does not track generations: never current.
        let untracked = CompressedSparseRow(UntrackedGraph())
        #expect(!untracked.isCurrent(for: UntrackedGraph()))
        // From another compressed graph: that graph, as it is, maps and all.
        var mapped = direct
        let weights = mapped.addEdgeMap(default: 3)
        let again = CompressedSparseRow(mapped)
        #expect(again.isCurrent(for: mapped) && again.isCurrent(for: direct))
        #expect(again[weights, ofEdgeAt: 0] == 3)
        #expect(!CompressedSparseRow(CompressedSparseRow()).isCurrent(for: CompressedSparseRow()))
        // Not part of equality.
        #expect(again == direct && CompressedSparseRow(source) == CompressedSparseRow(vertexCount: 3, edges: source.edgeList))
    }

    @Test("Reading or writing outside the graph traps, and a handle from another graph traps", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = graph.addEdgeMap(default: 0)
            _ = graph[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = graph.addEdgeMap(default: 0)
            graph[weights, ofEdgeAt: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2)
            let labels = graph.addVertexMap(default: 0)
            _ = graph[labels, of: 2]
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2)
            let labels = graph.addVertexMap(default: 0)
            graph[labels, ofVertexAt: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2)
            let labels = graph.addVertexMap(default: 0)
            graph[labels, of: 5] = 1
        }
        // Another graph, even one built from this one, has none of its maps.
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = graph.addEdgeMap(default: 0)
            _ = graph.transposed()[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2)
            let labels = graph.addVertexMap(default: 0)
            _ = CompressedSparseRow(vertexCount: 2).values(of: labels)
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2)
            let labels = graph.addVertexMap(default: 0)
            _ = try? CompressedSparseRow(vertexCount: 2)[labels, checked: 0]
        }
        // A removed map's handle traps, also on a copy made after the removal.
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let weights = graph.addEdgeMap(default: 0)
            graph.removeEdgeMap(weights)
            let copy = graph
            _ = copy[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = CompressedSparseRow(vertexCount: 2)
            let labels = graph.addVertexMap(default: 0)
            graph.removeVertexMap(labels)
            graph.removeVertexMap(labels)
        }
        // Without the faults: the same calls succeed.
        var graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        let weights = graph.addEdgeMap(default: 0)
        let labels = graph.addVertexMap(default: 0)
        graph[weights, ofEdgeAt: 0] = 1
        graph[labels, of: 1] = 2
        #expect(graph[weights, ofEdgeAt: 0] == 1 && graph[labels, ofVertexAt: 1] == 2)
    }

    @Test("Maps agree with dictionaries keyed by edge and vertex under random writes", .tags(.randomized))
    func modelOfMaps() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 20)
        let writes = zip(Gen.int(in: 0 ... 40), Gen.int(in: -5 ... 5)).array(of: 0 ... 30)
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 8), edges, writes) { n, raw, writes in
            let input = raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) }
            var graph = CompressedSparseRow(vertexCount: n, edges: input)
            let distinct = Array(Set(input))
            let weights = graph.addEdgeMap(default: 0)
            let labels = graph.addVertexMap(of: Int.self)
            var weightOf: [DirectedEdge<Int>: Int] = [:]
            var labelOf: [Int: Int] = [:]
            var copies: [(CompressedSparseRow, [DirectedEdge<Int>: Int], [Int: Int])] = []
            for (k, (target, value)) in writes.enumerated() {
                if k % 2 == 0, !distinct.isEmpty {
                    let edge = distinct[target % distinct.count]
                    graph[weights, ofEdgeAt: graph.edgeIndex(of: edge)!] = value
                    weightOf[edge] = value
                } else {
                    graph[labels, of: target % n] = value
                    labelOf[target % n] = value
                }
                if k % 7 == 0 { copies.append((graph, weightOf, labelOf)) }
            }
            copies.append((graph, weightOf, labelOf))
            // Every copy still reads the values it had when it was made.
            for (copy, weightOf, labelOf) in copies {
                let w = copy.values(of: weights)
                let l = copy.values(of: labels)
                for (k, edge) in copy.edges.enumerated() {
                    #expect(copy[weights, ofEdgeAt: k] == weightOf[edge, default: 0], "\(edge) in \(input)")
                    #expect(w[k] == weightOf[edge, default: 0])
                }
                for v in 0 ..< n {
                    #expect(copy[labels, of: v] == labelOf[v] && l[v] == labelOf[v])
                }
            }
        }
    }
}

/// A directed graph on `0..<vertexCount` that stamps a generation on every insertion, as the
/// mutable representations do.
private struct GenerationCountingGraph: DirectedGraph {
    let vertexCount: Int
    var edgeList: [DirectedEdge<Int>] = []
    var stamp = _GenerationStamp()

    init(vertexCount: Int) {
        self.vertexCount = vertexCount
    }

    mutating func insert(_ edge: DirectedEdge<Int>) {
        edgeList.append(edge)
        stamp.advance()
    }

    var generation: GraphGeneration { stamp.generation }
    var vertices: Range<Int> { 0 ..< vertexCount }
    var edges: [DirectedEdge<Int>] { edgeList }
    var edgeCount: Int { edgeList.count }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    func successors(of vertex: Int) -> [Int] { edgeList.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Int) -> [Int] { edgeList.indices.filter { edgeList[$0].source == vertex } }
    func source(ofEdgeAt position: Int) -> Int { edgeList[position].source }
    func target(ofEdgeAt position: Int) -> Int { edgeList[position].target }
}

/// A directed graph that does not track generations.
private struct UntrackedGraph: DirectedGraph {
    var vertices: Range<Int> { 0 ..< 2 }
    var edges: [DirectedEdge<Int>] { [DirectedEdge(from: 0, to: 1)] }
    var vertexCount: Int { 2 }
    var edgeCount: Int { 1 }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    func successors(of vertex: Int) -> [Int] { vertex == 0 ? [1] : [] }
    func outEdges(of vertex: Int) -> [Int] { vertex == 0 ? [0] : [] }
    func source(ofEdgeAt position: Int) -> Int { 0 }
    func target(ofEdgeAt position: Int) -> Int { 1 }
}
