// Attached maps and generations through LabeledGraph (a GraphAdaptor of its base): maps attached to
// a CompressedSparseRow or AdjacencyMatrix base through the labels, read by label, by index, by
// position and through `values(of:)`, as the base holds them; Dijkstra fed by `values(of:)` against
// the same weights from an array; `Int` labels that are not the indices, so a label read can only
// go through the label lookup; and the generation, which is the base's. Each test is
// self-contained.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import LabeledGraphs
import ShortestPaths
import Testing

@Suite("LabeledGraph attached maps and generations")
struct LabeledGraphMapTests {
    @Test("CompressedSparseRow base: maps attached through the labels are the base's, by label and by index")
    func compressedSparseRow() throws {
        var graph = LabeledGraph<String, CompressedSparseRow>(edges: [
            DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "s", to: "b"),
            DirectedEdge(from: "a", to: "t"), DirectedEdge(from: "b", to: "t"),
        ])
        #expect(Array(graph.vertices) == ["s", "a", "b", "t"])
        let weights = graph.addEdgeMap(default: 1.0)
        let names = graph.addVertexMap(of: String.self)
        // Positions are CSR's edge indices, in row-major order of the vertex indices.
        let positions = Dictionary(uniqueKeysWithValues: graph.edges.indices.map { (graph.edges[$0], $0) })
        graph[weights, ofEdgeAt: positions[DirectedEdge(from: "s", to: "a")]!] = 5
        graph[weights, ofEdgeAt: positions[DirectedEdge(from: "b", to: "t")]!] = 0.5
        graph[names, of: "a"] = "left"
        graph[names, ofVertexAt: graph.vertexIndex(of: "b")] = "right"
        #expect(graph[names, of: "b"] == "right" && graph[names, of: "a"] == "left" && graph[names, of: "s"] == nil)
        #expect(graph.base[names, of: 1] == "left" && graph.base[names, ofVertexAt: 2] == "right")
        #expect(try graph[names, checked: "a"] == "left" && graph[names, checkedVertexAt: 2] == "right")
        #expect(throws: VertexNotFound.self) { try graph[names, checked: "z"] }
        #expect(throws: VertexNotFound.self) { try graph[names, checkedVertexAt: 4] }
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 4] }
        #expect(graph.base[weights, ofEdgeAt: positions[DirectedEdge(from: "s", to: "a")]!] == 5)

        // Map-fed Dijkstra equals the same weights read from an array beside the graph.
        let w = graph.values(of: weights)
        var array = [Double](repeating: 1, count: graph.edgeCount)
        array[positions[DirectedEdge(from: "s", to: "a")]!] = 5
        array[positions[DirectedEdge(from: "b", to: "t")]!] = 0.5
        let mapped = graph.dijkstraShortestPaths(from: "s", weight: { w[$0] })
        let arrayed = graph.dijkstraShortestPaths(from: "s", weight: { array[$0] })
        for label in graph.vertices { #expect(mapped.distance(to: label) == arrayed.distance(to: label)) }
        #expect(mapped.distance(to: "t") == 1.5 && mapped.distance(to: "a") == 5)
        #expect(graph.values(of: names)[graph.vertexIndex(of: "a")] == "left")

        // A copy carries the maps, copy-on-write.
        var copy = graph
        copy[names, of: "a"] = "copied"
        #expect(graph[names, of: "a"] == "left" && copy[names, of: "a"] == "copied")
        graph.removeEdgeMap(weights)
        graph.removeVertexMap(names)
        #expect(graph == copy)
    }

    @Test("AdjacencyMatrix base: values follow labels and cells through insertions and removals")
    func adjacencyMatrix() throws {
        var graph = LabeledGraph<String, AdjacencyMatrix>(vertices: ["x", "y"])
        let ranks = graph.addVertexMap(default: 0)
        let weights = graph.addEdgeMap(default: -1)
        graph[ranks, of: "y"] = 7
        graph.insert(edge: DirectedEdge(from: "y", to: "z"))
        #expect(graph[ranks, of: "z"] == 0 && graph[ranks, of: "y"] == 7)
        let cell = graph.edges.firstIndex(of: DirectedEdge(from: "y", to: "z"))!
        #expect(cell.source == 1 && cell.target == 2)
        #expect(graph[weights, ofEdgeAt: cell] == -1)
        graph[weights, ofEdgeAt: cell] = 3
        #expect(graph.values(of: weights)[cell] == 3 && graph.base.values(of: weights)[cell] == 3)
        // Removing the edge sets its cell back; inserting it again starts at the default.
        #expect(graph.remove(edge: DirectedEdge(from: "y", to: "z")) != nil)
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: cell] }
        graph.insert(edge: DirectedEdge(from: "y", to: "z"))
        #expect(graph[weights, ofEdgeAt: cell] == -1)
        graph[weights, ofEdgeAt: cell] = 4
        #expect(graph.removeEdges(incidentTo: "z") == 1 && graph.values(of: weights)[cell] == -1)
        // removeAll keeps the maps attached, emptied.
        graph.removeAll()
        graph.insert("q")
        #expect(graph[ranks, of: "q"] == 0)
    }

    @Test("Int labels that are not the indices: a label read goes through the label, not the base vertex")
    func intLabels() throws {
        var graph = LabeledGraph<Int, AdjacencyMatrix>(vertices: [30, 10, 20])
        let ranks = graph.addVertexMap(default: 0)
        graph[ranks, of: 20] = 2
        graph[ranks, of: 30] = 3
        #expect(graph.vertexIndex(of: 20) == 2)
        #expect(graph[ranks, of: 20] == 2 && graph[ranks, of: 30] == 3 && graph[ranks, of: 10] == 0)
        #expect(graph[ranks, ofVertexAt: 2] == 2 && graph[ranks, ofVertexAt: 0] == 3)
        #expect(graph.base[ranks, of: 2] == 2 && graph.base[ranks, of: 0] == 3)
        #expect(try graph[ranks, checked: 10] == 0)
        // 2 is a base vertex but not a label.
        #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 2] }
    }

    @Test("The generation is the base's: built graphs have one, label and edge changes start a new one, value writes do not")
    func generation() throws {
        let csr = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
        var copy = csr
        #expect(csr.generation.isCurrent(for: csr) && csr.generation.isCurrent(for: csr.base))
        let names = copy.addVertexMap(of: String.self)
        copy[names, of: "a"] = "first"
        #expect(csr.generation.isCurrent(for: copy))
        let other = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(!csr.generation.isCurrent(for: other))

        var matrix = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
        var seen = matrix.generation
        #expect(seen.isCurrent(for: matrix) && seen.isCurrent(for: matrix.base))
        let steps: [(String, (inout LabeledGraph<String, AdjacencyMatrix>) -> Void)] = [
            ("insert(_:)", { $0.insert("c") }),
            ("insert(edge:)", { $0.insert(edge: DirectedEdge(from: "b", to: "c")) }),
            ("insert(edge:) with a new endpoint", { $0.insert(edge: DirectedEdge(from: "c", to: "d")) }),
            ("remove(edge:)", { $0.remove(edge: DirectedEdge(from: "a", to: "b")) }),
            ("removeEdges(from:)", { $0.removeEdges(from: "b") }),
            ("removeAllEdges()", { $0.removeAllEdges() }),
            ("removeAll()", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            step(&matrix)
            #expect(!seen.isCurrent(for: matrix), "\(name) kept the generation")
            seen = matrix.generation
            #expect(seen.isCurrent(for: matrix) && seen.isCurrent(for: matrix.base), "\(name)")
        }
        matrix.insert(edge: DirectedEdge(from: "a", to: "b"))
        seen = matrix.generation
        let weights = matrix.addEdgeMap(default: 0)
        matrix[weights, ofEdgeAt: matrix.edges.startIndex] = 9
        matrix.insert("a")
        matrix.reserveCapacity(vertexCount: 64)
        #expect(seen.isCurrent(for: matrix))
    }
}
