//
//  EliasFanoGraphTests.swift
//  Grafluent
//
//  `EliasFanoGraph` against `CompressedSparseRow`: the same vertices, edges and edge positions,
//  every query, the coding of a hand-worked row, the degenerate graphs, the collections, equality,
//  Codable, the checked spellings and traps, attached maps, and algorithms run on it.
//

import AdjacencyListModule
import CompressedSparseRowModule
import Connectivity
import EliasFanoGraphModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import ShortestPaths
import Testing
import Traversal

@Suite struct EliasFanoGraphTests {
    @Test("EF-1 a hand-worked row: 16 vertices, targets 1, 5, 9, 14 take 2 low bits each and the unary 1010101")
    func handWorkedRow() {
        let graph = EliasFanoGraph(vertexCount: 16, edges: [1, 5, 9, 14].map { DirectedEdge(from: 3, to: $0) })
        let expectedSuccessors = [1, 5, 9, 14]
        #expect(Array(graph.successors(of: 3)) == expectedSuccessors)
        #expect(graph.outDegree(of: 3) == 4)
        #expect(graph.outEdges(of: 3) == 0 ..< 4)
        // 4 targets × 2 low bits, and a unary section of 4 + (15 >> 2) + 1 = 8 bits: 16 bits for 4 edges.
        let expectedBitsPerEdge = 4.0
        #expect(graph.bitsPerEdge == expectedBitsPerEdge)
        let mirror = Mirror(reflecting: graph)
        let lower = mirror.descendant("lower") as? [UInt64]
        let upper = mirror.descendant("upper") as? [UInt64]
        let widths = mirror.descendant("widths") as? [UInt8]
        // Low bits 01, 01, 01, 10, least significant first: 0b10_01_01_01.
        #expect(lower == [0b10_01_01_01])
        #expect(upper == [0b1010101])
        #expect(widths?[3] == 2)
        #expect(graph.target(ofEdgeAt: 2) == 9)
        #expect(graph.source(ofEdgeAt: 3) == 3)
        #expect(graph.edgeIndex(of: DirectedEdge(from: 3, to: 14)) == 3)
        #expect(graph.edgeIndex(of: DirectedEdge(from: 3, to: 13)) == nil)
        #expect(graph.contains(edge: DirectedEdge(from: 3, to: 5)))
        #expect(!graph.contains(edge: DirectedEdge(from: 5, to: 3)))
    }

    @Test("EF-2 degenerate graphs: empty, no edges, one vertex with a self-loop, a complete graph (no low bits)")
    func degenerate() {
        let empty = EliasFanoGraph()
        #expect(empty.vertexCount == 0 && empty.edgeCount == 0)
        #expect(Array(empty.edges).isEmpty)
        #expect(empty == EliasFanoGraph(vertexCount: 0))
        let bare = EliasFanoGraph(vertexCount: 5)
        #expect(bare.edgeCount == 0 && bare.outDegree(of: 4) == 0)
        #expect(Array(bare.successors(of: 2)).isEmpty)
        #expect(bare.bitsPerEdge.isNaN)
        let loop = EliasFanoGraph(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(loop.edgeCount == 1)
        #expect(Array(loop.successors(of: 0)) == [0])
        #expect(loop.target(ofEdgeAt: 0) == 0)
        let n = 9
        let complete = EliasFanoGraph(vertexCount: n, edges: (0 ..< n).flatMap { u in (0 ..< n).map { DirectedEdge(from: u, to: $0) } })
        #expect(complete.edgeCount == n * n)
        for u in 0 ..< n { #expect(Array(complete.successors(of: u)) == Array(0 ..< n)) }
        // A full row has no low bits: 9 targets and a unary section of 9 + 8 + 1 bits.
        let expectedBitsPerEdge = 2.0
        #expect(complete.bitsPerEdge == expectedBitsPerEdge)
        #expect(Array(complete.edges.prefix(3)) == [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
    }

    @Test("EF-3 rows across word boundaries: a 300-vertex ring with chords agrees with the compressed sparse row in every query")
    func acrossWords() {
        let n = 300
        var edges: [DirectedEdge<Int>] = []
        for v in 0 ..< n {
            edges.append(DirectedEdge(from: v, to: (v + 1) % n))
            edges.append(DirectedEdge(from: v, to: (v * 7 + 13) % n))
            if v % 5 == 0 { edges.append(DirectedEdge(from: v, to: v)) }
        }
        let rows = CompressedSparseRow(vertexCount: n, edges: edges)
        let coded = EliasFanoGraph(rows)
        #expect(coded.edgeCount == rows.edgeCount)
        #expect(coded.offsets == rows.offsets)
        for v in 0 ..< n {
            #expect(Array(coded.successors(of: v)) == Array(rows.successors(of: v)))
            #expect(coded.outEdges(of: v) == rows.outEdges(of: v))
            var walked: [Int] = []
            coded._forEachSuccessorIndex(ofIndex: v) { walked.append($0) }
            #expect(walked == Array(rows.successors(of: v)))
        }
        for k in 0 ..< rows.edgeCount {
            #expect(coded.source(ofEdgeAt: k) == rows.source(ofEdgeAt: k))
            #expect(coded.target(ofEdgeAt: k) == rows.target(ofEdgeAt: k))
            #expect(coded.edges[k] == rows.edges[k])
        }
        #expect(Array(coded.edges) == Array(rows.edges))
        #expect(Array(coded.edges[100 ..< 250]) == Array(rows.edges[100 ..< 250]))
        #expect(coded.edges.firstIndex(of: DirectedEdge(from: 7, to: 8)) == rows.edges.firstIndex(of: DirectedEdge(from: 7, to: 8)))
        #expect(coded.edges.contains(DirectedEdge(from: 0, to: 0)))
        #expect(!coded.edges.contains(DirectedEdge(from: 1, to: 1)))
        #expect(CompressedSparseRow(coded) == rows)
        #expect(coded.transposed() == EliasFanoGraph(rows.transposed()))
        #expect(coded.bitsPerEdge < 16)
    }

    @Test("EF-4 equality, hashing, descriptions and Codable, interchangeable with the compressed sparse row's payload")
    func conformances() throws {
        let edges = [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 1)]
        let a = EliasFanoGraph(vertexCount: 3, edges: edges)
        let b = EliasFanoGraph(vertexCount: 3, edges: edges.reversed())
        let c = EliasFanoGraph(vertexCount: 4, edges: edges)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(a != c)
        // Two rows with the same low bits and different high parts: 5 vertices, one low bit each.
        let lowRow = EliasFanoGraph(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 2)])
        let highRow = EliasFanoGraph(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 4)])
        #expect(lowRow != highRow)
        #expect(lowRow.hashValue != highRow.hashValue)
        #expect(a.description == CompressedSparseRow(vertexCount: 3, edges: edges).description)
        #expect(a.debugDescription.hasPrefix("EliasFanoGraph(vertexCount: 3, edgeCount: 3, edges: "))
        let data = try JSONEncoder().encode(a)
        #expect(try JSONDecoder().decode(EliasFanoGraph.self, from: data) == a)
        #expect(try JSONDecoder().decode(CompressedSparseRow.self, from: data) == CompressedSparseRow(a))
        let rowsData = try JSONEncoder().encode(CompressedSparseRow(c))
        #expect(try JSONDecoder().decode(EliasFanoGraph.self, from: rowsData) == c)
        let corrupt = Data(#"{"offsets":[0,2,1],"targets":[0,1]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(EliasFanoGraph.self, from: corrupt) }
    }

    @Test("EF-5 the checked spellings throw for a vertex or an edge index out of range")
    func checked() throws {
        let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        #expect(try Array(graph.successors(checked: 0)) == [1, 2])
        #expect(try graph.outEdges(checked: 0) == 0 ..< 2)
        #expect(try graph.outDegree(checked: 1) == 0)
        #expect(try graph.vertexIndex(checked: 2) == 2)
        #expect(try graph.source(checkedEdgeAt: 1) == 0)
        #expect(try graph.target(checkedEdgeAt: 1) == 2)
        #expect(throws: VertexNotFound.self) { try graph.successors(checked: 3) }
        #expect(throws: VertexNotFound.self) { try graph.outEdges(checked: -1) }
        #expect(throws: VertexNotFound.self) { try graph.outDegree(checked: 3) }
        #expect(throws: VertexNotFound.self) { try graph.vertexIndex(checked: 3) }
        #expect(throws: EdgeNotFound.self) { try graph.source(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound.self) { try graph.target(checkedEdgeAt: -1) }
    }

    @Test("EF-6 the plain spellings trap out of range", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.successors(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.target(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = EliasFanoGraph(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 2)])
        }
        await #expect(processExitsWith: .failure) {
            let graph = EliasFanoGraph(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[1]
        }
    }

    @Test("EF-7 attached maps by position, carried by copies and bundled")
    func maps() throws {
        var graph = EliasFanoGraph(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        let weights = graph.addEdgeMap(default: 1.0)
        let names = graph.addVertexMap(default: "")
        graph[weights, ofEdgeAt: 1] = 2.5
        graph[names, of: 3] = "end"
        let copy = graph
        let values = graph.values(of: weights)
        let expected = 2.5
        #expect(values[1] == expected && values[0] == 1)
        #expect(copy[names, of: 3] == "end")
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 3] }
        let bundle = PropertyGraphBundle(graph, maps: weights, names)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<EliasFanoGraph, EdgeMap<Double>, VertexMap<String>>.self, from: data)
        #expect(back == bundle)
        #expect(back.graph[back.maps.0, ofEdgeAt: 1] == expected)
        let again = graph.addEdgeMap(values: values)
        #expect(graph[again, ofEdgeAt: 1] == expected)
    }

    @Test("EF-8 generations: built from a graph, current until that graph changes")
    func generations() {
        var list = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        let coded = EliasFanoGraph(list)
        #expect(coded.isCurrent(for: list))
        list.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(!coded.isCurrent(for: list))
        #expect(EliasFanoGraph(coded) == coded)
        #expect(EliasFanoGraph(coded).isCurrent(for: coded))
        #expect(!EliasFanoGraph().isCurrent(for: coded))
    }

    @Test("EF-9 algorithms on the coded graph agree with the compressed sparse row: BFS order, Dijkstra, strong components")
    func algorithms() {
        let n = 60
        var generator = SeededRandomNumberGenerator(seed: 9)
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< 240 { edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator))) }
        let rows = CompressedSparseRow(vertexCount: n, edges: edges)
        let coded = EliasFanoGraph(rows)
        #expect(Array(coded.lazy.breadthFirstSearch(from: 0)) == Array(rows.lazy.breadthFirstSearch(from: 0)))
        let rowsTree = rows.dijkstraShortestPaths(from: 0) { $0 % 7 + 1 }
        let codedTree = coded.dijkstraShortestPaths(from: 0) { $0 % 7 + 1 }
        for v in 0 ..< n { #expect(codedTree.distance(to: v) == rowsTree.distance(to: v)) }
        let rowsComponents = rows.stronglyConnectedComponents()
        let codedComponents = coded.stronglyConnectedComponents()
        #expect(codedComponents.count == rowsComponents.count)
        for u in 0 ..< n { for v in 0 ..< n {
            #expect((codedComponents.component(of: u) == codedComponents.component(of: v)) == (rowsComponents.component(of: u) == rowsComponents.component(of: v)))
        } }
    }

    @Test("EF-10 random graphs, dense and sparse: every query agrees with the compressed sparse row", .tags(.randomized))
    func randomAgainstRows() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 140), Gen.int(in: 0 ... 600), Gen.int(in: 0 ... 1_000_000)) { n, m, seed in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var edges: [DirectedEdge<Int>] = []
            if n > 0 { for _ in 0 ..< m { edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &draw), to: Int.random(in: 0 ..< n, using: &draw))) } }
            let rows = CompressedSparseRow(vertexCount: n, edges: edges)
            let coded = EliasFanoGraph(vertexCount: n, edges: edges)
            #expect(coded.offsets == rows.offsets, "n \(n) m \(m) seed \(seed)")
            #expect(coded == EliasFanoGraph(rows))
            #expect(CompressedSparseRow(coded) == rows)
            for v in 0 ..< n {
                #expect(Array(coded.successors(of: v)) == Array(rows.successors(of: v)), "row \(v), n \(n) m \(m) seed \(seed)")
                #expect(Array(coded.successorIndices(ofIndex: v)) == Array(rows.successorIndices(ofIndex: v)))
                #expect(coded.outDegree(of: v) == rows.outDegree(of: v))
            }
            for k in 0 ..< rows.edgeCount {
                #expect(coded.source(ofEdgeAt: k) == rows.source(ofEdgeAt: k))
                #expect(coded.target(ofEdgeAt: k) == rows.target(ofEdgeAt: k))
                #expect(coded.edgeIndex(of: rows.edges[k]) == k)
            }
            #expect(Array(coded.edges) == Array(rows.edges))
            if rows.edgeCount > 2 {
                let lower = Int.random(in: 0 ..< rows.edgeCount, using: &draw), upper = Int.random(in: lower ... rows.edgeCount, using: &draw)
                #expect(Array(coded.edges[lower ..< upper]) == Array(rows.edges[lower ..< upper]), "slice \(lower)..<\(upper) n \(n) m \(m) seed \(seed)")
            }
            for _ in 0 ..< 5 where n > 0 {
                let edge = DirectedEdge(from: Int.random(in: 0 ..< n, using: &draw), to: Int.random(in: 0 ..< n, using: &draw))
                #expect(coded.contains(edge: edge) == rows.contains(edge: edge))
            }
            #expect(coded.edgeCount == 0 || coded.bitsPerEdge <= 2 + Double(Int.bitWidth - n.leadingZeroBitCount))
        }
    }
}
