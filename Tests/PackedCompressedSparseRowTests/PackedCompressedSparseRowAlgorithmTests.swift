// Algorithms on PackedCompressedSparseRow agree with the same algorithms on AdjacencyList and
// CompressedSparseRow built from the same edges, before and after mutations: breadth-first search
// and its layers, Dijkstra with an attached weight map, strongly connected components, and the
// index-space row hook that those algorithms read.

import AdjacencyListModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import PackedCompressedSparseRowModule
import ShortestPaths
import Testing
import Traversal

@Suite("PackedCompressedSparseRow under the algorithms")
struct PackedCompressedSparseRowAlgorithmTests {
    @Test("Breadth-first layers, Dijkstra and strong components agree with AdjacencyList after a mixed workload")
    func agreesWithAdjacencyList() {
        var rng = SeededRandomNumberGenerator(seed: 21)
        let n = 400
        var packed = PackedCompressedSparseRow<Int>(vertices: 0 ..< n)
        var list = AdjacencyList<Int>(vertices: 0 ..< n)
        var weights: [DirectedEdge<Int>: Int] = [:]
        for _ in 0 ..< 4000 {
            let edge = DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng))
            if Int.random(in: 0 ..< 4, using: &rng) == 0 {
                packed.remove(edge: edge)
                list.remove(edge: edge)
                weights[edge] = nil
            } else {
                packed.insert(edge: edge)
                list.insert(edge: edge)
                if weights[edge] == nil { weights[edge] = Int.random(in: 1 ... 20, using: &rng) }
            }
        }
        #expect(packed == PackedCompressedSparseRow(list) && Set(packed.edges) == Set(list.edges))
        let packedLayers = packed.breadthFirstLayers(from: 0), listLayers = list.breadthFirstLayers(from: 0)
        #expect(packedLayers.map { Set($0) } == listLayers.map { Set($0) })
        let packedTree = packed.dijkstraShortestPaths(from: 0) { weights[packed.edges[$0]]! }
        let listTree = list.dijkstraShortestPaths(from: 0) { weights[list.edges[$0]]! }
        #expect((0 ..< n).map { packedTree.distance(to: $0) } == (0 ..< n).map { listTree.distance(to: $0) })
        let packedComponents = packed.stronglyConnectedComponents().map { Set($0) }
        let listComponents = list.stronglyConnectedComponents().map { Set($0) }
        #expect(Set(packedComponents) == Set(listComponents))
        let csr = CompressedSparseRow(packed)
        #expect(csr.vertexCount == n && Set(csr.edges) == Set(packed.edges))
        #expect(csr.breadthFirstLayers(from: 0).map { Set($0) } == packedLayers.map { Set($0) })
    }

    @Test("The lent rows are the ones the queries answer with, on a bulk-built and on an inserted graph")
    func lentRows() {
        let edges = (0 ..< 60).map { DirectedEdge(from: $0 % 12, to: ($0 * 5) % 12) }
        let bulk = PackedCompressedSparseRow(vertices: 0 ..< 12, edges: edges)
        var inserted = PackedCompressedSparseRow<Int>(vertices: 0 ..< 12)
        for edge in edges { inserted.insert(edge: edge) }
        for graph in [bulk, inserted] {
            let agree: Bool = graph._withOutIndexRows { targets, targetRows, positions, positionRows in
                (0 ..< 12).allSatisfy { v in
                    let start = targetRows[3 * v], count = targetRows[3 * v + 1]
                    let ps = positionRows[3 * v], pc = positionRows[3 * v + 1]
                    return start == ps && count == pc
                        && Array(targets[start ..< start + count]) == Array(graph.successorIndices(ofIndex: v))
                        && Array(positions[start ..< start + count]) == Array(graph.outEdges(ofIndex: v))
                }
            } ?? false
            #expect(agree)
        }
        #expect(bulk == inserted)
    }

    @Test("Attached vertex and edge maps read through the index space, and values(of:) snapshots them")
    func mapsAndValues() {
        var graph = PackedCompressedSparseRow(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weight = graph.addEdgeMap(default: 1.0)
        let label = graph.addVertexMap(default: "")
        let colour = graph.addEdgeMap(of: String.self)
        graph[weight, ofEdgeAt: 1] = 2.5
        graph[label, of: 2] = "two"
        graph[colour, ofEdgeAt: 0] = "red"
        for v in 5 ..< 60 { graph.insert(edge: DirectedEdge(from: v - 1, to: v)) }
        #expect(graph[weight, ofEdgeAt: 1] == 2.5 && graph[label, of: 2] == "two" && graph[colour, ofEdgeAt: 0] == "red" && graph[colour, ofEdgeAt: 5] == nil)
        let snapshot = graph.values(of: weight)
        #expect(snapshot[1] == 2.5 && snapshot[0] == 1.0)
        let tree = graph.dijkstraShortestPaths(from: 0) { snapshot[$0] }
        #expect(tree.distance(to: 2) == 3.5)
        graph.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 2)) && graph[weight, ofEdgeAt: graph.edges(from: 1, to: 2)[0]] == 2.5)
        #expect((try? graph[weight, checkedEdgeAt: 1_000]) == nil && (try? graph[label, checked: 99]) == nil)
        graph.removeEdgeMap(weight)
        graph.removeVertexMap(label)
    }
}
