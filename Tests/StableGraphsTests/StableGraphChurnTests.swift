// Churn across many pages: storage is paged (1024 positions a page) and a page whose positions
// are all dead is freed, so these runs hand out tens of thousands of positions while few stay live.
// Each is checked against a model of the live elements: every live position keeps its element and
// its place in every row, every dead one reads as removed (also inside freed pages), algorithms
// agree with the compacted copy, a copy taken before a mutation never changes (copy-on-write by
// page), Codable round-trips keep every position, and the maps keep exactly the live positions'
// values. The memory bound itself is measured in StableGraphsBenchmarks. See README.md.

import Connectivity
import Foundation
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

@Suite("StableGraphs churn across pages")
struct StableGraphChurnTests {
    @Test("Random churn over 3·10⁴ positions agrees with a model of the live elements", .tags(.randomized))
    func churnAgainstModel() async {
        let seeds = Gen.int(in: 0 ... 1_000_000).array(of: 1 ... 1)
        await propertyCheck(count: 6, input: seeds) { seeds in
            var state = UInt64(seeds[0]) &* 2_862_933_555_777_941_757 &+ 3_037_000_493
            func next(_ bound: Int) -> Int {
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return Int(truncatingIfNeeded: state >> 33) % bound
            }
            var graph = StableDirectedGraph<Int>()
            var live: [Int: (source: Int, target: Int)] = [:]
            var liveVertices: [Int: Int] = [:]   // vertex -> position
            var nextVertex = 0
            let labels = graph.addEdgeMap(of: Int.self)
            for _ in 0 ..< 40 {
                liveVertices[nextVertex] = graph.vertices.endIndex
                graph.insert(nextVertex)
                nextVertex += 1
            }
            for step in 0 ..< 30_000 {
                let vertices = liveVertices.keys.sorted()
                switch next(10) {
                case 0 ... 4:
                    let s = vertices[next(vertices.count)], t = vertices[next(vertices.count)]
                    let p = graph.insert(edge: DirectedEdge(from: s, to: t))
                    live[p] = (s, t)
                    graph[map: labels, ofEdgeAt: p] = p
                case 5, 6:
                    // The oldest live edge, so whole pages die.
                    if let p = graph.edges.indices.first {
                        _ = graph.remove(edgeAt: p)
                        live[p] = nil
                    }
                case 7:
                    // A new vertex in, the oldest out.
                    liveVertices[nextVertex] = graph.vertices.endIndex
                    graph.insert(nextVertex)
                    nextVertex += 1
                    let oldest = graph.vertices.first!
                    _ = graph.remove(oldest)
                    liveVertices[oldest] = nil
                    for (p, e) in live where e.source == oldest || e.target == oldest { live[p] = nil }
                case 8:
                    if let p = graph.edges.indices.last {
                        let v = vertices[next(vertices.count)]
                        graph.changeTarget(ofEdgeAt: p, to: v)
                        live[p]!.target = v
                    }
                default:
                    if let p = graph.edges.indices.last {
                        let v = vertices[next(vertices.count)]
                        let changed = graph.changeSource(ofEdgeAt: p, safe: v)
                        #expect(changed)
                        live[p]!.source = v
                    }
                }
                if step % 3_000 == 2_999 {
                    let positions = live.keys.sorted()
                    #expect(Array(graph.edges.indices) == positions)
                    #expect(graph.edges.map { [$0.source, $0.target] } == positions.map { [live[$0]!.source, live[$0]!.target] })
                    #expect(graph.edgeCount == live.count && graph.vertexCount == liveVertices.count)
                    #expect(Array(graph.vertices.indices) == liveVertices.values.sorted())
                    for (v, position) in liveVertices {
                        #expect(Array(graph.outEdges(of: v)) == positions.filter { live[$0]!.source == v })
                        #expect(Array(graph.inEdges(of: v)) == positions.filter { live[$0]!.target == v })
                        #expect(graph.vertexPosition(of: v) == position)
                    }
                    // Dead positions, in freed pages and in live ones, read as removed.
                    for p in stride(from: 0, to: graph.edges.endIndex, by: 97) {
                        #expect(graph.containsEdge(atPosition: p) == (live[p] != nil))
                        #expect(graph.edges.indices.contains(p) == (live[p] != nil))
                    }
                    for p in stride(from: 0, to: graph.vertices.endIndex, by: 13) {
                        #expect(graph.containsVertex(atPosition: p) == liveVertices.values.contains(p))
                    }
                    // Algorithms see the live graph: the same as the compacted copy.
                    let compacted = DirectedPseudograph<Int>(graph)
                    #expect(graph.weaklyConnectedComponents().count == compacted.weaklyConnectedComponents().count)
                    #expect(graph.stronglyConnectedComponents().count == compacted.stronglyConnectedComponents().count)
                    // The labels of removed edges went with them; the live ones stay.
                    #expect((0 ..< graph.edges.endIndex).filter { graph[map: labels, ofEdgeAt: $0] != nil } == positions)
                    #expect(positions.allSatisfy { graph[map: labels, ofEdgeAt: $0] == $0 })
                    // A round trip keeps every position and the next fresh one.
                    let decoded = try? JSONDecoder().decode(StableDirectedGraph<Int>.self, from: JSONEncoder().encode(graph))
                    #expect(decoded.map { Array($0.edges.indices) } == positions)
                    #expect(decoded.map { Array($0.vertices.indices) } == liveVertices.values.sorted())
                    #expect(decoded?.edges.endIndex == graph.edges.endIndex && decoded?.vertices.endIndex == graph.vertices.endIndex)
                    #expect(decoded == graph)
                    if let decoded {
                        for p in stride(from: 0, to: graph.vertices.endIndex, by: 7) {
                            #expect(decoded.containsVertex(atPosition: p) == graph.containsVertex(atPosition: p))
                        }
                        #expect(decoded.weaklyConnectedComponents().count == graph.weaklyConnectedComponents().count)
                    }
                }
            }
            #expect(graph.edges.endIndex > 10_000)
        }
    }

    @Test("A copy taken before mutations keeps every page it shares")
    func copyOnWriteByPage() {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 5_000, edges: (0 ..< 20_000).map { DirectedEdge(from: $0 % 5_000, to: ($0 &* 7 + 1) % 5_000) })
        let snapshot = graph
        let edges = Array(snapshot.edges), positions = Array(snapshot.edges.indices)
        let rows = (0 ..< 5_000).map { (Array(snapshot.outEdges(of: $0)), Array(snapshot.inEdges(of: $0))) }
        // Mutations touching a few pages each.
        graph.remove(edgeAt: 3)
        graph.changeTarget(ofEdgeAt: 10_001, to: 4_999)
        graph.changeSource(ofEdgeAt: 19_999, to: 0)
        _ = graph.remove(2_500)
        graph.insert(edge: DirectedEdge(from: 1, to: 9_999))
        _ = graph.removeAllEdges { $0 % 1_000 == 0 }
        for p in 0 ..< 3_000 where graph.edges.indices.contains(p) { graph.remove(edgeAt: p) }
        #expect(Array(snapshot.edges) == edges && Array(snapshot.edges.indices) == positions)
        #expect((0 ..< 5_000).allSatisfy { Array(snapshot.outEdges(of: $0)) == rows[$0].0 && Array(snapshot.inEdges(of: $0)) == rows[$0].1 })
        #expect(snapshot.vertexIndexBound == 5_000 && snapshot.edgeIndexBound == 20_000)
        #expect(snapshot.target(ofEdgeAt: 10_001) == edges[10_001].target && snapshot.contains(2_500))
        #expect(graph.target(ofEdgeAt: 10_001) == 4_999 && !graph.contains(2_500))
        // And the other way round: mutating the copy leaves the graph.
        var copy = graph
        let before = Array(graph.edges)
        copy.removeAll()
        #expect(Array(graph.edges) == before && copy.vertexCount == 0)
    }

    @Test("Attached maps across pages: copy-on-write, several maps, and handles valid on copies")
    func mapsAcrossPages() {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 50_000)
        let names = graph.addVertexMap(of: String.self), weights = graph.addVertexMap(of: Double.self)
        for v in stride(from: 0, to: 50_000, by: 7) { graph[map: names, of: v] = "v\(v)" }
        graph[map: weights, of: 14] = 1.5
        let copy = graph
        for v in stride(from: 0, to: 40_000, by: 7) { _ = graph.remove(v) }
        #expect((0 ..< 50_000).filter { graph[map: names, ofVertexAt: $0] != nil } == Array(stride(from: 40_005, to: 50_000, by: 7)))
        #expect(graph[map: weights, of: 14] == nil && copy[map: weights, of: 14] == 1.5)
        #expect(copy[map: names, of: 0] == "v0" && copy[map: names, of: 49_994] == "v49994")
        #expect((0 ..< 50_000).filter { copy[map: names, ofVertexAt: $0] != nil }.count == 7_143)
        graph[map: names, of: 40_005] = "x"
        #expect(graph[map: names, of: 40_005] == "x" && copy[map: names, of: 40_005] == "v40005")
        graph[map: names, of: 40_005] = nil
        #expect(graph[map: names, of: 40_005] == nil && graph[map: names, of: -1] == nil && graph[map: names, ofVertexAt: Int.max] == nil)
        // A handle stays valid on copies; removing the map from one copy leaves the other's.
        var other = copy
        other.removeVertexMap(names)
        #expect(copy[map: names, of: 7] == "v7" && other[map: weights, of: 14] == 1.5)
        let another = graph.addVertexMap(of: String.self)
        #expect(names == names && names != another && Set([names, another, names]).count == 2)
        #expect(graph[map: another, of: 40_012] == nil)
    }

    @Test("removeAllEdges(keepingCapacity:) keeps vertex holes and freed pages, both ways")
    func removeAllEdgesKeepsHoles() {
        for keepingCapacity in [true, false] {
            var graph = StableDirectedGraph<Int>(vertices: 0 ..< 3_000, edges: (0 ..< 3_000).map { DirectedEdge(from: $0, to: ($0 + 1) % 3_000) })
            for v in 0 ..< 2_100 where v % 3 != 0 || v < 1_100 { _ = graph.remove(v) }
            let live = Array(graph.vertices.indices)
            graph.removeAllEdges(keepingCapacity: keepingCapacity)
            #expect(Array(graph.vertices.indices) == live && graph.edgeCount == 0 && graph.edges.endIndex == 0)
            #expect((0 ..< 3_000).allSatisfy { graph.containsVertex(atPosition: $0) == live.contains($0) })
            #expect(graph.weaklyConnectedComponents().count == live.count && graph.vertexIndexBound == nil)
            #expect(graph.insert(edge: DirectedEdge(from: 2_999, to: 1_200)) == 0)
            #expect(Array(graph.successors(of: 2_999)) == [1_200] && graph.stronglyConnectedComponents().count == live.count)
        }
    }

    @Test("A freed page between live ones: equality, Codable, numbering and stepping across it")
    func freedPageInTheMiddle() throws {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 3_000, edges: (0 ..< 3_000).map { DirectedEdge(from: $0, to: (3 * $0 + 1) % 3_000) })
        for v in 1_024 ..< 2_048 { _ = graph.remove(v) }
        // Vertex page 1 is wholly dead; edge pages lose the edges at those vertices.
        let compacted = StableDirectedGraph<Int>(DirectedPseudograph<Int>(graph))
        #expect(graph == compacted && graph.hashValue == compacted.hashValue)
        #expect(graph.vertices.index(after: 1_023) == 2_048 && graph.vertices.index(before: 2_048) == 1_023)
        #expect(graph.weaklyConnectedComponents().count == compacted.weaklyConnectedComponents().count)
        let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph && Array(decoded.vertices.indices) == Array(graph.vertices.indices))
        #expect(Array(decoded.edges.indices) == Array(graph.edges.indices))
        #expect((1_000 ..< 2_100).allSatisfy { decoded.containsVertex(atPosition: $0) == graph.containsVertex(atPosition: $0) })
        #expect(decoded.weaklyConnectedComponents().count == compacted.weaklyConnectedComponents().count)
    }

    @Test("Every page freed: stepping, liveness and the next positions")
    func everyPageFreed() throws {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 2_048, edges: (0 ..< 2_048).map { DirectedEdge(from: $0, to: $0) })
        for p in 0 ..< 2_048 { graph.remove(edgeAt: p) }
        #expect(graph.edges.index(after: 5) == 2_048 && graph.edges.isEmpty && !graph.containsEdge(atPosition: 2_047))
        for v in 0 ..< 2_048 { _ = graph.remove(v) }
        #expect(graph.vertices.index(after: 5) == 2_048 && graph.vertices.isEmpty && !graph.containsVertex(atPosition: 2_047))
        #expect(graph.insert(edge: DirectedEdge(from: 7, to: 8)) == 2_048)
        #expect(Array(graph.vertices.indices) == [2_048, 2_049] && graph.edges.index(before: graph.edges.endIndex) == 2_048)
        // A payload whose positions start past freed pages decodes with the holes dead.
        let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph && Array(decoded.vertices.indices) == [2_048, 2_049])
        #expect(!decoded.containsVertex(atPosition: 2_047) && decoded.weaklyConnectedComponents().count == 1)
    }
}