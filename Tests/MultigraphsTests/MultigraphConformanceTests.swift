// Conformances and value behaviour beyond the catalog rows (api.md, Summary and Semantics):
// Codable through JSON and property lists after removals, corrupt payloads of every shape
// throwing (never trapping) on all four types, Hashable (orders ignored; copies, loops and
// vertices seen; colliding vertex hashes), `Sendable` across a `Task`, the mirror, the builders
// with control flow, the remaining initializers, `EdgesConnecting` as a collection and a value,
// copy-on-write on every mutation, and the capacity calls. See README.md.

import AdjacencyListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import Testing

@Suite("Multigraphs conformances: Codable, Hashable, Sendable, builders, value semantics", .tags(.conformance))
struct MultigraphConformanceTests {
    @Test("Round trips through JSON and property lists keep the value, vertex order and positions, on all four types")
    func roundTrips() throws {
        var pseudograph = Pseudograph<String>(vertices: ["z"], edges: [
            UndirectedEdge("a", "b"), UndirectedEdge("b", "a"), UndirectedEdge("b", "b"), UndirectedEdge("c", "a"), UndirectedEdge("a", "b"),
        ])
        pseudograph.remove(edgeAt: 1)
        pseudograph.remove("z")
        let p1 = try JSONDecoder().decode(Pseudograph<String>.self, from: JSONEncoder().encode(pseudograph))
        let p2 = try PropertyListDecoder().decode(Pseudograph<String>.self, from: PropertyListEncoder().encode(pseudograph))
        for decoded in [p1, p2] {
            #expect(decoded == pseudograph)
            #expect(Array(decoded.vertices) == Array(pseudograph.vertices))
            #expect(decoded.edges.map { [$0.u, $0.v] } == pseudograph.edges.map { [$0.u, $0.v] })
            // Rows are rebuilt in position order.
            let reference = ReferencePseudograph(vertices: Array(pseudograph.vertices), edges: Array(pseudograph.edges))
            for v in decoded.vertices { #expect(Array(decoded.incidentEdges(of: v)) == reference.incidentEdges(of: v)) }
        }

        var multigraph = try #require(Multigraph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(2, 1)]))
        multigraph.remove(edgeAt: 0)
        let m = try PropertyListDecoder().decode(Multigraph<Int>.self, from: PropertyListEncoder().encode(multigraph))
        #expect(m == multigraph)
        #expect(m.edges.map { [$0.u, $0.v] } == [[2, 1], [1, 0]])

        var digraph = DirectedPseudograph<Int>(edges: [
            DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 1),
        ])
        digraph.remove(edge: DirectedEdge(from: 3, to: 1))
        let d1 = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: JSONEncoder().encode(digraph))
        let d2 = try PropertyListDecoder().decode(DirectedPseudograph<Int>.self, from: PropertyListEncoder().encode(digraph))
        for decoded in [d1, d2] {
            #expect(decoded == digraph)
            #expect(Array(decoded.vertices) == [3, 1])
            #expect(decoded.edges.map { [$0.source, $0.target] } == [[3, 1], [1, 3], [1, 1]])
        }

        let directedMultigraph = try #require(DirectedMultigraph<Int>(vertices: [5], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        let dm = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: JSONEncoder().encode(directedMultigraph))
        #expect(dm == directedMultigraph)
        #expect(Array(dm.vertices) == [5, 0, 1])
        #expect(Array(dm.edges(from: 0, to: 1)) == [0, 1])

        // The same graph built the same way encodes to the same bytes.
        let sorted = JSONEncoder()
        sorted.outputFormatting = .sortedKeys
        let again = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(try sorted.encode(again) == sorted.encode(Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])))
        // A pseudograph without copies or loops round-trips through the simple lists' decoders.
        let simple = Pseudograph<Int>(vertices: [4], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let list = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(simple))
        #expect(Array(list.vertices) == [4, 0, 1, 2])
        #expect(list.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        // With copies, the simple list's decoder rejects it.
        let copiesPayload = try JSONEncoder().encode(directedMultigraph)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(AdjacencyList<Int>.self, from: copiesPayload) }
    }

    @Test("Malformed payloads throw on every type, and none traps")
    func malformedPayloads() {
        let payloads = [
            #"{"vertices":"x","edges":[]}"#,
            #"{"vertices":[0,1],"edges":"x"}"#,
            #"{"vertices":[0,1],"edges":[0.5,1]}"#,
            #"{"vertices":[0,1],"edges":[[0,1]]}"#,
            #"{"vertices":[0,1],"edges":[0,1,2]}"#,
            #"{"vertices":[0,1],"edges":[0,9223372036854775807]}"#,
            #"{"vertices":[0,1],"edges":[-9223372036854775808,0]}"#,
            #"{"vertices":[0,1],"edges":[0,-1]}"#,
            #"{"vertices":[0,1],"edges":[2,2]}"#,
            #"{"vertices":[1,1],"edges":[0,1]}"#,
            #"{"vertices":["a"],"edges":[]}"#,
            #"{"vertices":null,"edges":[]}"#,
            #"{"vertices":[0],"edges":null}"#,
            #"{"vertices":[],"edges":[0,0]}"#,
            #"[]"#,
            #"{}"#,
            #"7"#,
            #"{"vertices":[0,1],"edges":[0,1"#,
        ]
        for text in payloads {
            let data = Data(text.utf8)
            #expect(throws: (any Error).self, "\(text)") { try JSONDecoder().decode(Pseudograph<Int>.self, from: data) }
            #expect(throws: (any Error).self, "\(text)") { try JSONDecoder().decode(Multigraph<Int>.self, from: data) }
            #expect(throws: (any Error).self, "\(text)") { try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: data) }
            #expect(throws: (any Error).self, "\(text)") { try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: data) }
        }
        // Loops: only the multigraphs reject them, with dataCorrupted.
        for text in [#"{"vertices":[0,1],"edges":[0,1,1,1]}"#, #"{"vertices":[0],"edges":[0,0,0,0]}"#] {
            let data = Data(text.utf8)
            #expect((try? JSONDecoder().decode(Pseudograph<Int>.self, from: data)) != nil, "\(text)")
            #expect((try? JSONDecoder().decode(DirectedPseudograph<Int>.self, from: data)) != nil, "\(text)")
            #expect(throws: DecodingError.self, "\(text)") { try JSONDecoder().decode(Multigraph<Int>.self, from: data) }
            #expect(throws: DecodingError.self, "\(text)") { try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: data) }
        }
        // An endpoint out of range on every type is dataCorrupted, not a trap.
        for text in [#"{"vertices":[0,1],"edges":[0,2]}"#, #"{"vertices":[0,1],"edges":[-1,1]}"#] {
            let data = Data(text.utf8)
            for decode in [
                { _ = try JSONDecoder().decode(Pseudograph<Int>.self, from: data) },
                { _ = try JSONDecoder().decode(Multigraph<Int>.self, from: data) },
                { _ = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: data) },
                { _ = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: data) },
            ] as [() throws -> Void] {
                do {
                    try decode()
                    Issue.record("decoded \(text)")
                } catch DecodingError.dataCorrupted {
                    // Expected.
                } catch {
                    Issue.record("\(text): \(error), not dataCorrupted")
                }
            }
        }
    }

    @Test("Hashing: equal values hash alike whatever the orders; copies, loops, orientation (directed) and vertices are seen")
    func hashing() throws {
        let a = Pseudograph<Int>(vertices: [9, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(2, 2), UndirectedEdge(1, 2)])
        let b = Pseudograph<Int>(vertices: [2], edges: [UndirectedEdge(2, 1), UndirectedEdge(2, 2), UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(3, 9), UndirectedEdge(9, 9)])
        var c = b
        c.remove(edge: UndirectedEdge(9, 9))
        c.remove(edge: UndirectedEdge(3, 9))
        #expect(a == c)
        #expect(a.hashValue == c.hashValue)
        #expect(Set([a, c]).count == 1)
        // Twelve graphs on the same vertices with the same edge count, different multisets.
        let variants: [[UndirectedEdge<Int>]] = [
            [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 3)],
            [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(2, 3)],
            [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(2, 3)],
            [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(2, 3)],
            [UndirectedEdge(0, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 0)],
            [UndirectedEdge(1, 1), UndirectedEdge(0, 0), UndirectedEdge(0, 0)],
            [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)],
            [UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 2)],
            [UndirectedEdge(0, 3), UndirectedEdge(0, 3), UndirectedEdge(1, 2)],
            [UndirectedEdge(3, 3), UndirectedEdge(2, 2), UndirectedEdge(1, 1)],
            [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 3)],
            [UndirectedEdge(0, 2), UndirectedEdge(0, 2), UndirectedEdge(1, 3)],
        ]
        let graphs = variants.map { Pseudograph<Int>(vertices: 0 ..< 4, edges: $0) }
        // Same vertex and edge counts; the first two even have the same distinct edges. Only the
        // multisets tell them apart.
        for (i, g) in graphs.enumerated() {
            for (j, h) in graphs.enumerated() { #expect((g == h) == (i == j), "\(variants[i]) vs \(variants[j])") }
        }
        #expect(Set(graphs).count == variants.count)
        #expect(Set(graphs.map(\.hashValue)).count == variants.count)
        // Reversed orientations, shuffled vertices: the same values.
        let flipped = variants.map { Pseudograph<Int>(vertices: [3, 1, 2, 0], edges: $0.reversed().map { UndirectedEdge($0.v, $0.u) }) }
        #expect(Set(graphs + flipped).count == variants.count)
        for (g, f) in zip(graphs, flipped) { #expect(g.hashValue == f.hashValue) }
        // Directed: orientation and copies matter.
        let directed = [
            [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)],
            [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)],
            [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0)],
            [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1)],
        ].map { DirectedPseudograph<Int>(vertices: [0, 1], edges: $0) }
        #expect(Set(directed).count == 4)
        for (i, g) in directed.enumerated() {
            for (j, h) in directed.enumerated() { #expect((g == h) == (i == j)) }
        }
        let threeArcs = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(threeArcs != DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0)]))
        let multigraphs = try [
            [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)],
            [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1)],
        ].map { try #require(DirectedMultigraph<Int>(edges: $0)) }
        #expect(multigraphs[0] == multigraphs[1] && multigraphs[0].hashValue == multigraphs[1].hashValue)
        // Vertices whose hashes all collide still compare and hash by value.
        let colliding = Pseudograph<Collider>(edges: [UndirectedEdge(Collider(1), Collider(2)), UndirectedEdge(Collider(2), Collider(1)), UndirectedEdge(Collider(3), Collider(3))])
        #expect(colliding.vertexCount == 3)
        #expect(colliding.edgeCount(between: Collider(1), and: Collider(2)) == 2)
        #expect(colliding.edgeCount(between: Collider(1), and: Collider(3)) == 0)
        #expect(Array(colliding.edges(between: Collider(3), and: Collider(3))) == [2])
        let rebuilt = Pseudograph<Collider>(edges: [UndirectedEdge(Collider(3), Collider(3)), UndirectedEdge(Collider(1), Collider(2)), UndirectedEdge(Collider(1), Collider(2))])
        #expect(colliding == rebuilt && colliding.hashValue == rebuilt.hashValue)
        #expect(colliding != Pseudograph<Collider>(edges: [UndirectedEdge(Collider(1), Collider(2)), UndirectedEdge(Collider(3), Collider(3))]))
    }

    @Test("Sendable: the four types cross a Task when the vertex is Sendable")
    func sendable() async throws {
        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let multigraph = try #require(Multigraph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]))
        let digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 0)])
        let directedMultigraph = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 1)]))
        let counts = await Task { [pseudograph, multigraph, digraph, directedMultigraph] in
            [pseudograph.edgeCount(between: 0, and: 1), multigraph.degree(of: 1), digraph.degree(of: 0), directedMultigraph.inDegree(of: 1)]
        }.value
        #expect(counts == [2, 2, 2, 1])
        let edges = pseudograph.edges
        let neighbors = pseudograph.neighbors(of: 0)
        let viewed = await Task { [edges, neighbors] in (edges.count, Array(neighbors)) }.value
        #expect(viewed.0 == 2 && viewed.1 == [1, 1])
    }

    @Test("The mirror shows vertices and edges")
    func mirror() throws {
        let graph = Pseudograph<Int>(vertices: [5], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let labels = Mirror(reflecting: graph).children.map(\.label)
        #expect(labels == ["vertices", "edges"])
        let vertices = try #require(Mirror(reflecting: graph).children.first { $0.label == "vertices" }?.value as? [Int])
        #expect(vertices == [5, 0, 1])
        let edges = try #require(Mirror(reflecting: graph).children.first { $0.label == "edges" }?.value as? [UndirectedEdge<Int>])
        #expect(edges.count == 2)
        let directed = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        #expect(Mirror(reflecting: directed).children.map(\.label) == ["vertices", "edges"])
        let multigraph = try #require(Multigraph<String>(edges: [UndirectedEdge("a", "b")]))
        #expect(Mirror(reflecting: multigraph).children.map(\.label) == ["vertices", "edges"])
        #expect(Mirror(reflecting: DirectedPseudograph<Int>()).children.map(\.label) == ["vertices", "edges"])
    }

    @Test("The builders: vertices and edges as written, with control flow; the multigraphs' is nil on a loop")
    func builders() throws {
        let include = true
        let pseudograph = Pseudograph<Int> {
            7
            UndirectedEdge(0, 1)
            for _ in 0 ..< 2 { UndirectedEdge(1, 0) }
            if include { UndirectedEdge(2, 2) } else { 99 }
        }
        #expect(Array(pseudograph.vertices) == [7, 0, 1, 2])
        #expect(pseudograph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 0], [1, 0], [2, 2]])
        let multigraph = try #require(Multigraph<Int> {
            UndirectedEdge(0, 1)
            UndirectedEdge(0, 1)
            if !include { UndirectedEdge(3, 3) }
        })
        #expect(multigraph.edgeCount(between: 1, and: 0) == 2)
        #expect(Multigraph<Int> { UndirectedEdge(0, 1); UndirectedEdge(1, 1) } == nil)
        let digraph = DirectedPseudograph<Int> {
            4
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 1, to: 1)
        }
        #expect(Array(digraph.vertices) == [4, 0, 1])
        #expect(Array(digraph.edges(from: 0, to: 1)) == [0, 1])
        let directedMultigraph = try #require(DirectedMultigraph<Int> {
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 1, to: 0)
        })
        #expect(directedMultigraph.edgeCount == 2)
        #expect(DirectedMultigraph<Int> { DirectedEdge(from: 0, to: 0) } == nil)
    }

    @Test("init(), init(vertices:) and init(edges:) on all four types")
    func initializers() throws {
        #expect(Pseudograph<Int>().vertexCount == 0 && Multigraph<Int>().edgeCount == 0)
        #expect(DirectedPseudograph<Int>().vertexCount == 0 && DirectedMultigraph<Int>().edgeCount == 0)
        #expect(Array(Pseudograph<Int>(vertices: [2, 0, 2]).vertices) == [2, 0])
        #expect(Array(Multigraph<Int>(vertices: [2, 0, 2]).vertices) == [2, 0])
        #expect(Array(DirectedPseudograph<Int>(vertices: 0 ..< 3).vertices) == [0, 1, 2])
        #expect(Array(DirectedMultigraph<Int>(vertices: [1, 1]).vertices) == [1])
        let p = Pseudograph<Int>(edges: [UndirectedEdge(1, 0), UndirectedEdge(1, 0)])
        #expect(Array(p.vertices) == [1, 0] && p.edgeCount == 2)
        let m = try #require(Multigraph<Int>(edges: [UndirectedEdge(1, 0), UndirectedEdge(1, 0)]))
        #expect(m == Multigraph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        #expect(Multigraph<Int>(edges: [UndirectedEdge(1, 0), UndirectedEdge(4, 4)]) == nil)
        let d = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 2, to: 2)])
        #expect(Array(d.vertices) == [2] && d.edgeCount == 1)
        #expect(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 2, to: 2)]) == nil)
        #expect(DirectedMultigraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0)])?.edgeCount == 1)
        // Edges from any sequence.
        let lazy = Pseudograph<Int>(edges: (0 ..< 3).lazy.map { UndirectedEdge($0, 0) })
        #expect(lazy.edges.map { [$0.u, $0.v] } == [[0, 0], [1, 0], [2, 0]])
        // From graphs of other kinds: the reference conformers, keeping every copy.
        let reference = ReferencePseudograph(vertices: [9], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let converted = Pseudograph(reference)
        #expect(Array(converted.vertices) == [9, 0, 1])
        #expect(converted.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 1]])
        #expect(Multigraph(reference) == nil)
        let directedReference = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(DirectedPseudograph(directedReference).edgeCount(from: 0, to: 1) == 2)
        #expect(try #require(DirectedMultigraph(directedReference)).edgeCount == 2)
    }

    @Test("EdgesConnecting is a multi-pass collection with O(1) count, and a value unaffected by later changes")
    func edgesConnecting() {
        var graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 0), UndirectedEdge(0, 1)])
        let copies = graph.edges(between: 1, and: 0)
        #expect(copies.count == 3)
        #expect(!copies.isEmpty)
        #expect(copies.first == 0)
        #expect(Array(copies) == [0, 2, 3])
        #expect(Array(copies) == Array(copies))
        var walked: [Int] = []
        var i = copies.startIndex
        while i != copies.endIndex {
            walked.append(copies[i])
            i = copies.index(after: i)
        }
        #expect(walked == [0, 2, 3])
        #expect(copies.indices.map { copies[$0] } == [0, 2, 3])
        #expect(copies.startIndex < copies.endIndex)
        #expect(copies.distance(from: copies.startIndex, to: copies.endIndex) == 3)
        #expect(copies.contains(2) && !copies.contains(1))
        #expect(copies.map { graph.edges[$0] }.allSatisfy { $0 == UndirectedEdge(0, 1) })
        let empty = graph.edges(between: 0, and: 2)
        #expect(empty.isEmpty && empty.count == 0 && empty.startIndex == empty.endIndex && empty.first == nil)
        #expect(graph.edges(between: 7, and: 8).isEmpty)
        // A value: removing and inserting copies afterwards does not change it.
        graph.remove(edgeAt: 0)
        graph.insert(edge: UndirectedEdge(0, 1))
        graph.removeAllEdges(between: 2, and: 1)
        #expect(Array(copies) == [0, 2, 3])
        #expect(copies.count == 3)
        #expect(Array(graph.edges(between: 0, and: 1)) == [2, 0, 1])
        // Directed.
        var digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1)])
        let arcs = digraph.edges(from: 0, to: 1)
        digraph.removeAll()
        #expect(Array(arcs) == [0, 2])
        #expect(arcs.count == 2)
    }

    @Test("Copy-on-write: mutating a copy never changes the original, for every mutation", .tags(.copyOnWrite))
    func copyOnWrite() throws {
        let original = Pseudograph<Int>(vertices: [5], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        let vertices = original.vertices
        let edges = original.edges
        let neighbors = original.neighbors(of: 1)
        let incident = original.incidentEdges(of: 1)
        let copies = original.edges(between: 0, and: 1)
        let mutations: [(String, (inout Pseudograph<Int>) -> Void)] = [
            ("insert vertex", { $0.insert(9) }),
            ("insert edge", { $0.insert(edge: UndirectedEdge(0, 1)) }),
            ("insert loop", { $0.insert(edge: UndirectedEdge(5, 5)) }),
            ("remove vertex", { $0.remove(0) }),
            ("remove edge", { $0.remove(edge: UndirectedEdge(1, 0)) }),
            ("remove edge at", { $0.remove(edgeAt: 0) }),
            ("remove all copies", { $0.removeAllEdges(between: 0, and: 1) }),
            ("remove all edges", { $0.removeAllEdges() }),
            ("remove all edges keeping capacity", { $0.removeAllEdges(keepingCapacity: true) }),
            ("remove all", { $0.removeAll() }),
            ("remove all keeping capacity", { $0.removeAll(keepingCapacity: true) }),
            ("reserve", { $0.reserveCapacity(vertexCount: 100, edgeCount: 100) }),
        ]
        for (name, mutate) in mutations {
            var copy = original
            mutate(&copy)
            #expect(Array(original.vertices) == [5, 0, 1, 2], "\(name)")
            #expect(original.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 1], [1, 2]], "\(name)")
            #expect(Array(original.incidentEdges(of: 1)) == [0, 1, 2, 2, 3], "\(name)")
            #expect(Array(original.edges(between: 0, and: 1)) == [0, 1], "\(name)")
            #expect(original == Pseudograph<Int>(vertices: [5], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)]), "\(name)")
        }
        // Views taken before the mutations are values too.
        #expect(Array(vertices) == [5, 0, 1, 2])
        #expect(edges.count == 4 && edges[2] == UndirectedEdge(1, 1))
        #expect(Array(neighbors) == [0, 0, 1, 1, 2])
        #expect(Array(incident) == [0, 1, 2, 2, 3])
        #expect(Array(copies) == [0, 1])

        let directed = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        let directedMutations: [(DirectedPseudograph<Int>) -> DirectedPseudograph<Int>] = [
            { var g = $0; g.insert(edge: DirectedEdge(from: 1, to: 0)); return g },
            { var g = $0; g.remove(edge: DirectedEdge(from: 0, to: 1)); return g },
            { var g = $0; g.remove(edgeAt: 0); return g },
            { var g = $0; g.removeAllEdges(from: 0, to: 1); return g },
            { var g = $0; g.remove(1); return g },
            { var g = $0; g.removeAllEdges(); return g },
            { var g = $0; g.removeAll(); return g },
        ]
        for mutate in directedMutations {
            let changed = mutate(directed)
            #expect(changed != directed)
            #expect(directed.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 1], [1, 1]])
            #expect(Array(directed.outEdges(of: 0)) == [0, 1] && Array(directed.inEdges(of: 1)) == [0, 1, 2])
        }
        // The wrappers.
        let multigraph = try #require(Multigraph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        var multigraphCopy = multigraph
        multigraphCopy.remove(edge: UndirectedEdge(0, 1))
        multigraphCopy.insert(edge: UndirectedEdge(2, 3))
        #expect(multigraph.edgeCount == 2 && multigraph.vertexCount == 2)
        let directedMultigraph = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 1)]))
        var directedMultigraphCopy = directedMultigraph
        directedMultigraphCopy.removeAll()
        #expect(directedMultigraph.edgeCount == 1)
        // A no-op removal leaves both equal.
        var unchanged = original
        #expect(unchanged.remove(edge: UndirectedEdge(0, 2)) == nil)
        #expect(unchanged.remove(edge: UndirectedEdge(0, 99)) == nil)
        #expect(unchanged.removeAllEdges(between: 2, and: 2) == 0)
        #expect(unchanged.remove(99) == nil)
        #expect(unchanged == original)
        #expect(Array(unchanged.vertices) == Array(original.vertices))
        #expect(!unchanged.contains(99))
    }

    @Test("Capacity: reserveCapacity changes nothing visible; removeAll and removeAllEdges keep or drop vertices as named")
    func capacity() throws {
        var graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        graph.reserveCapacity(vertexCount: 1000, edgeCount: 1000)
        #expect(graph == Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        for k in 0 ..< 1000 { graph.insert(edge: UndirectedEdge(k % 7, k % 5)) }
        #expect(graph.edgeCount == 1002)
        graph.removeAllEdges(keepingCapacity: true)
        #expect(graph.vertexCount == 7 && graph.edgeCount == 0)
        #expect(graph.vertices.allSatisfy { graph.degree(of: $0) == 0 })
        #expect(graph.edges(between: 0, and: 1).isEmpty)
        #expect(graph.insert(edge: UndirectedEdge(0, 1)) == 0)
        graph.removeAll(keepingCapacity: true)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && !graph.contains(0))
        #expect(graph.insert(edge: UndirectedEdge(3, 3)) == 0)
        #expect(Array(graph.vertices) == [3])

        var multigraph = Multigraph<Int>()
        multigraph.reserveCapacity(vertexCount: 0, edgeCount: 0)
        multigraph.reserveCapacity(vertexCount: 10, edgeCount: 10)
        #expect(multigraph.insert(edge: UndirectedEdge(0, 1)) == 0)
        multigraph.removeAllEdges()
        #expect(multigraph.vertexCount == 2)
        multigraph.removeAll()
        #expect(multigraph.vertexCount == 0)

        var digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        digraph.reserveCapacity(vertexCount: 50, edgeCount: 50)
        digraph.removeAllEdges(keepingCapacity: true)
        #expect(digraph.vertexCount == 2 && digraph.edgeCount == 0)
        #expect(digraph.successors(of: 0).isEmpty && digraph.predecessors(of: 1).isEmpty)
        var directedMultigraph = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 1)]))
        directedMultigraph.removeAll(keepingCapacity: true)
        #expect(directedMultigraph.vertexCount == 0)
        #expect(directedMultigraph.insert(edge: DirectedEdge(from: 4, to: 5)) == 0)
    }
}
