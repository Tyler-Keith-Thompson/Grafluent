// Cases the catalog rows and the properties do not reach, each pinned to one behavior: rows past
// the builder's insertion-sort limit, near-miss equality and hashing, the views' membership and
// trapping reads, edge subscripts and incidence rows read through the protocols' defaults (on
// test-local conformers, with and without indices), the clique expansions' index tables, and
// hostile payloads. See README.md.

import AdjacencyListModule
import Connectivity
import Foundation
import GraphProtocols
import Hypergraphs
import Testing

@Suite("Hypergraphs edge cases")
struct HypergraphEdgeCaseTests {
    // MARK: - Construction

    @Test("A hyperedge of 40 members listed in descending index order, with repeats, is stored ascending once each")
    func longUnsortedHyperedge() {
        let names = (0 ..< 40).map { "v\($0)" }
        let members = names.reversed() + ["v3", "v17", "v39", "v0"]
        let undirected = UndirectedIncidenceList(vertices: names, hyperedges: [members, ["v1"]])
        #expect(Array(undirected.memberIndices(ofHyperedgeAt: 0)) == Array(0 ..< 40))
        #expect(Array(undirected.memberIndices(ofHyperedgeAt: 1)) == [1])
        #expect(undirected.size(ofHyperedgeAt: 0) == 40 && undirected.degree(of: "v3") == 1 && undirected.degree(of: "v1") == 2)
        let directed = IncidenceList(vertices: names, hyperedges: [(sources: members, targets: members.reversed()), (sources: ["v2"], targets: [])])
        #expect(Array(directed.sourceIndices(ofHyperedgeAt: 0)) == Array(0 ..< 40))
        #expect(Array(directed.targetIndices(ofHyperedgeAt: 0)) == Array(0 ..< 40))
        #expect(Array(directed.sourceIndices(ofHyperedgeAt: 1)) == [2] && directed.targetIndices(ofHyperedgeAt: 1).isEmpty)
    }

    @Test("Copying a conformer without vertex indices maps each member through the vertex list")
    func copyWithoutIndices() {
        // No index members: the copies must look every member up.
        struct Plain: Hypergraph {
            let names: [String]
            let rows: [[String]]
            var vertices: [String] { names }
            var hyperedges: [[String]] { rows }
            func incidentHyperedges(of vertex: String) -> [Int] { rows.indices.filter { rows[$0].contains(vertex) } }
        }
        struct PlainArcs: DirectedHypergraph {
            let names: [String]
            let arcs: [(sources: [String], targets: [String])]
            var vertices: [String] { names }
            var hyperedges: [(sources: [String], targets: [String])] { arcs }
            func sources(ofHyperedgeAt position: Int) -> [String] { arcs[position].sources }
            func targets(ofHyperedgeAt position: Int) -> [String] { arcs[position].targets }
            func outHyperedges(of vertex: String) -> [Int] { arcs.indices.filter { arcs[$0].sources.contains(vertex) } }
            func inHyperedges(of vertex: String) -> [Int] { arcs.indices.filter { arcs[$0].targets.contains(vertex) } }
        }
        let plain = Plain(names: ["c", "a", "b"], rows: [["b", "c"], [], ["a"]])
        let list = UndirectedIncidenceList(plain)
        #expect(Array(list.vertices) == ["c", "a", "b"])
        #expect(list.hyperedges.map { Array($0) } == [["c", "b"], [], ["a"]])
        let arcs = PlainArcs(names: ["c", "a", "b"], arcs: [(sources: ["b"], targets: ["a", "c"]), (sources: [], targets: ["b"])])
        let directed = IncidenceList(arcs)
        #expect(Array(directed.vertices) == ["c", "a", "b"])
        #expect(directed.hyperedges.map { [Array($0.sources), Array($0.targets)] } == [[["b"], ["c", "a"]], [[], ["b"]]])
    }

    // MARK: - Reads

    @Test("Inserting a vertex that is already there adds no row: the next index still traps")
    func reinsertAddsNoRow() async {
        await #expect(processExitsWith: .failure) {
            var hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"]])
            hypergraph.insert("a")
            _ = hypergraph.incidentHyperedges(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            var hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"]])
            hypergraph.insert("a")
            _ = hypergraph.degree(ofIndex: 2)
        }
        var hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"]])
        #expect(hypergraph.insert("a").inserted == false && hypergraph.vertexCount == 2)
        #expect(hypergraph.degree(ofIndex: 1) == 1)
    }

    @Test("hyperedgeIndex(of:) traps outside 0..<hyperedgeCount, both kinds")
    func hyperedgeIndexRange() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedIncidenceList<String>(hyperedges: [["a"], ["b"]]).hyperedgeIndex(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedIncidenceList<String>(hyperedges: [["a"], ["b"]]).hyperedgeIndex(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])]).hyperedgeIndex(of: 1)
        }
        #expect(UndirectedIncidenceList<String>(hyperedges: [["a"], ["b"]]).hyperedgeIndex(of: 1) == 1)
        #expect(IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])]).hyperedgeIndex(of: 0) == 0)
    }

    @Test("The in-side checked: reads answer the in-star, not the out-star")
    func inSideCheckedReads() throws {
        let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"]), (sources: ["a"], targets: ["c"]), (sources: ["b"], targets: ["a"])])
        #expect(try Array(hypergraph.inHyperedges(checked: "a")) == [2])
        #expect(try Array(hypergraph.outHyperedges(checked: "a")) == [0, 1])
        #expect(try hypergraph.inDegree(checked: "a") == 1 && hypergraph.outDegree(checked: "a") == 2)
        #expect(try hypergraph.degree(checked: "a") == 3)
        #expect(throws: VertexNotFound.self) { try hypergraph.inDegree(checked: "q") }
        #expect(throws: VertexNotFound.self) { try hypergraph.inHyperedges(checked: "q") }
        #expect(throws: VertexNotFound.self) { try hypergraph.degree(checked: "q") }
    }

    @Test("contains(sources:targets:) compares both sides, and the empty pair needs both sides empty")
    func directedContainsBothSides() {
        let hypergraph = IncidenceList<String>(vertices: ["a", "b", "c"], hyperedges: [(sources: [], targets: ["b"]), (sources: ["a"], targets: ["b"])])
        #expect(!hypergraph.contains(sources: [] as [String], targets: [] as [String]))
        #expect(hypergraph.contains(sources: [] as [String], targets: ["b"]))
        #expect(!hypergraph.contains(sources: ["a"], targets: ["c"]))
        #expect(!hypergraph.contains(sources: ["a"], targets: [] as [String]))
        #expect(hypergraph.contains(sources: ["a"], targets: ["b"]))
    }

    // MARK: - Equality and hashing

    @Test("Equality: same vertex order and sizes but other members; vertex sets of the same size")
    func equalityNearMisses() {
        let ab = UndirectedIncidenceList(vertices: ["a", "b", "c"], hyperedges: [["a", "b"]])
        let ac = UndirectedIncidenceList(vertices: ["a", "b", "c"], hyperedges: [["a", "c"]])
        #expect(ab != ac)
        #expect(UndirectedIncidenceList(vertices: ["a", "b"]) != UndirectedIncidenceList(vertices: ["c", "a"]))
        let toB = IncidenceList(vertices: ["a", "b", "c"], hyperedges: [(sources: ["a"], targets: ["b"])])
        let toC = IncidenceList(vertices: ["a", "b", "c"], hyperedges: [(sources: ["a"], targets: ["c"])])
        #expect(toB != toC)
        // The same members on each row once the sides are joined, split differently.
        let first = IncidenceList(vertices: ["a", "b", "c"], hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["a", "b"], targets: [])])
        let second = IncidenceList(vertices: ["a", "b", "c"], hyperedges: [(sources: ["a"], targets: ["b"]), (sources: ["a", "b"], targets: ["c"])])
        #expect(first != second)
    }

    @Test("Different hypergraphs of the same counts hash differently")
    func hashValuesSeparate() {
        let a = UndirectedIncidenceList(vertices: ["a"]), b = UndirectedIncidenceList(vertices: ["b"])
        #expect(a != b && a.hashValue != b.hashValue)
        let full = UndirectedIncidenceList(vertices: ["a"], hyperedges: [["a"]])
        let empty = UndirectedIncidenceList(vertices: ["a"], hyperedges: [[String]()])
        #expect(full != empty && full.hashValue != empty.hashValue)
        let forward = IncidenceList(vertices: ["a", "b"], hyperedges: [(sources: ["a"], targets: ["b"])])
        let backward = IncidenceList(vertices: ["a", "b"], hyperedges: [(sources: ["b"], targets: ["a"])])
        #expect(forward != backward && forward.hashValue != backward.hashValue)
        let noTarget = IncidenceList(vertices: ["a", "b"], hyperedges: [(sources: ["a"], targets: [String]())])
        #expect(forward != noTarget && forward.hashValue != noTarget.hashValue)
    }

    // MARK: - Codable

    @Test("Decoding throws for a negative member index and for a repeated vertex")
    func hostilePayloads() {
        let negative = Data(#"{"vertices":["a","b"],"hyperedges":[[-1,0]]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: negative) }
        let negativeSource = Data(#"{"vertices":["a","b"],"sources":[[-2]],"targets":[[]]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(IncidenceList<String>.self, from: negativeSource) }
        let repeated = Data(#"{"vertices":["a","a"],"sources":[],"targets":[]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(IncidenceList<String>.self, from: repeated) }
        let valid = Data(#"{"vertices":["a","b"],"sources":[[1]],"targets":[[0]]}"#.utf8)
        #expect((try? JSONDecoder().decode(IncidenceList<String>.self, from: valid)) == IncidenceList(vertices: ["a", "b"], hyperedges: [(sources: ["b"], targets: ["a"])]))
    }

    // MARK: - The views

    @Test("Undirected view: membership of vertices and edges, opposite ends, and its trapping reads")
    func undirectedViewMembership() async {
        let hypergraph = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], ["b", "c"], ["c"]])
        let view = hypergraph.incidenceGraphView
        let n = 3, m = 3
        #expect(!view.contains(-1) && !view.contains(n + m) && view.contains(0) && view.contains(n + m - 1))
        for q in view.edges.indices {
            let (i, h) = view.endpointIndices(ofEdgeAt: q)
            #expect(view.contains(edge: UndirectedEdge(i, h)) && view.contains(edge: UndirectedEdge(h, i)))
            #expect(view.oppositeVertex(to: i, acrossEdgeAt: q) == h && view.oppositeVertex(to: h, acrossEdgeAt: q) == i)
        }
        // Two hyperedges, two vertices, a vertex and a hyperedge it is not in, and out of range.
        #expect(!view.contains(edge: UndirectedEdge(n, n + 1)) && !view.contains(edge: UndirectedEdge(n + 1, n + 2)))
        #expect(!view.contains(edge: UndirectedEdge(0, 1)) && !view.contains(edge: UndirectedEdge(0, n + 2)))
        #expect(!view.contains(edge: UndirectedEdge(0, n + m)) && !view.contains(edge: UndirectedEdge(-1, n)))
        await #expect(processExitsWith: .failure) {
            _ = UndirectedIncidenceList<String>(hyperedges: [["a"]]).incidenceGraphView.vertexIndex(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedIncidenceList<String>(hyperedges: [["a"]]).incidenceGraphView.vertex(atIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedIncidenceList<String>(hyperedges: [["a"]]).incidenceGraphView.edgeIndex(of: 1)
        }
    }

    @Test("Directed view: membership of arcs both ways, and degree as out plus in")
    func directedViewMembership() {
        let hypergraph = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["a", "b"])])
        let view = hypergraph.incidenceGraphView
        let n = 3, m = 2
        #expect(!view.contains(-1) && !view.contains(n + m))
        for q in view.edges.indices {
            let source = view.source(ofEdgeAt: q), target = view.target(ofEdgeAt: q)
            #expect(view.contains(edge: DirectedEdge(from: source, to: target)))
        }
        #expect(!view.contains(edge: DirectedEdge(from: n, to: 0)) && !view.contains(edge: DirectedEdge(from: n + 1, to: 2)))
        #expect(!view.contains(edge: DirectedEdge(from: 1, to: n)) && !view.contains(edge: DirectedEdge(from: n, to: n + 1)))
        for x in view.vertices {
            #expect(view.degree(of: x) == view.outDegree(of: x) + view.inDegree(of: x))
        }
        #expect(view.degree(of: 1) == 3 && view.degree(of: n + 1) == 4)
    }

    @Test("Views over conformers without stored rows: edge subscripts, ends, components and bridges agree with the lists'")
    func viewsThroughTheDefaults() {
        struct Rows: Hypergraph {
            let names: [String]
            let rows: [[String]]
            var vertices: [String] { names }
            var hyperedges: [[String]] { rows }
            func incidentHyperedges(of vertex: String) -> [Int] { rows.indices.filter { rows[$0].contains(vertex) } }
            var vertexIndexBound: Int? { names.count }
            func vertexIndex(of vertex: String) -> Int { names.firstIndex(of: vertex)! }
            func vertex(atIndex index: Int) -> String { names[index] }
            var hyperedgeIndexBound: Int? { rows.count }
            func hyperedgeIndex(of position: Int) -> Int { position }
        }
        struct Arcs: DirectedHypergraph {
            let names: [String]
            let arcs: [(sources: [String], targets: [String])]
            var vertices: [String] { names }
            var hyperedges: [(sources: [String], targets: [String])] { arcs }
            func sources(ofHyperedgeAt position: Int) -> [String] { arcs[position].sources }
            func targets(ofHyperedgeAt position: Int) -> [String] { arcs[position].targets }
            func outHyperedges(of vertex: String) -> [Int] { arcs.indices.filter { arcs[$0].sources.contains(vertex) } }
            func inHyperedges(of vertex: String) -> [Int] { arcs.indices.filter { arcs[$0].targets.contains(vertex) } }
            var vertexIndexBound: Int? { names.count }
            func vertexIndex(of vertex: String) -> Int { names.firstIndex(of: vertex)! }
            func vertex(atIndex index: Int) -> String { names[index] }
            var hyperedgeIndexBound: Int? { arcs.count }
            func hyperedgeIndex(of position: Int) -> Int { position }
        }
        let names = ["a", "b", "c", "d", "e"]
        let rows = Rows(names: names, rows: [["a", "b", "c"], [], ["c", "d"], ["d", "e"], ["a", "c", "d", "e"]])
        let list = UndirectedIncidenceList(rows)
        let view = rows.incidenceGraphView, listView = list.incidenceGraphView
        #expect(view.edgeCount == 11 && Array(view.edges) == Array(listView.edges))
        for q in view.edges.indices {
            #expect(view.edges[q] == listView.edges[q])
            #expect(view.endpointIndices(ofEdgeAt: q) == listView.endpointIndices(ofEdgeAt: q))
        }
        #expect(view.connectedComponents().map { Array($0) } == listView.connectedComponents().map { Array($0) })
        #expect(view.bridges() == listView.bridges() && view.articulationPoints() == listView.articulationPoints())
        #expect(!rows.contains(hyperedge: ["a", "b", "c", "d"]) && !rows.contains(hyperedge: ["c", "d", "e"]))
        #expect(rows.contains(hyperedge: ["d", "c"]))

        let arcs = Arcs(names: names, arcs: [
            (sources: ["a"], targets: ["b", "c", "d"]), (sources: ["b", "c"], targets: []),
            (sources: [], targets: ["a", "e"]), (sources: ["d", "e"], targets: ["c", "d"]),
        ])
        let directed = IncidenceList(arcs)
        let arcView = arcs.incidenceGraphView, directedView = directed.incidenceGraphView
        #expect(arcView.edgeCount == 12 && Array(arcView.edges) == Array(directedView.edges))
        for q in arcView.edges.indices {
            #expect(arcView.edges[q] == directedView.edges[q])
            #expect(arcView.source(ofEdgeAt: q) == directedView.source(ofEdgeAt: q) && arcView.target(ofEdgeAt: q) == directedView.target(ofEdgeAt: q))
        }
        for p in arcs.arcs.indices {
            #expect(arcs.sourceSize(ofHyperedgeAt: p) == arcs.arcs[p].sources.count && arcs.targetSize(ofHyperedgeAt: p) == arcs.arcs[p].targets.count)
        }
        #expect(!arcs.contains(sources: ["a"], targets: ["b", "c", "e"]) && !arcs.contains(sources: ["d", "e"], targets: ["c", "a"]))
        #expect(!arcs.contains(sources: ["d", "e"], targets: ["c", "d", "a"]))
        #expect(arcs.contains(sources: ["e", "d"], targets: ["d", "c"]))
    }

    // MARK: - Clique expansions

    @Test("The clique expansions' vertex and edge tables: every vertex's index, edge membership, predecessors")
    func expansionTables() {
        let undirected = UndirectedIncidenceList<String>(hyperedges: [["a", "b", "c"], ["c", "d"], ["e"]])
        let expansion = undirected.cliqueExpansion()
        for (i, v) in ["a", "b", "c", "d", "e"].enumerated() { #expect(expansion.vertexIndex(of: v) == i) }
        for (u, v) in [("a", "b"), ("a", "c"), ("b", "c"), ("c", "d")] {
            #expect(expansion.contains(edge: UndirectedEdge(u, v)) && expansion.contains(edge: UndirectedEdge(v, u)))
        }
        #expect(!expansion.contains(edge: UndirectedEdge("a", "d")) && !expansion.contains(edge: UndirectedEdge("e", "e")))
        let directed = IncidenceList<String>(hyperedges: [(sources: ["a", "b"], targets: ["c"]), (sources: ["c"], targets: ["d", "a"])])
        let arcs = directed.cliqueExpansion()
        for (i, v) in ["a", "b", "c", "d"].enumerated() { #expect(arcs.vertexIndex(of: v) == i) }
        #expect(arcs.contains(edge: DirectedEdge(from: "a", to: "c")) && arcs.contains(edge: DirectedEdge(from: "c", to: "a")))
        #expect(!arcs.contains(edge: DirectedEdge(from: "d", to: "c")) && !arcs.contains(edge: DirectedEdge(from: "a", to: "b")))
        #expect(Set(arcs.predecessors(of: "c")) == ["a", "b"] && Set(arcs.predecessors(of: "a")) == ["c"])
        #expect(Set(arcs.successors(of: "c")) == ["a", "d"] && arcs.predecessors(of: "b").isEmpty)
    }
}
