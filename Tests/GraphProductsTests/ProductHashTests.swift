// The boundary law: a product computes its rows from the factors' index rows, so index-space reads
// hash no factor vertex, and a pair lookup costs one lookup in each factor (two hashes). Counted with
// a vertex type local to each test whose `hash(into:)` counts. A Swift Dictionary hashes a key once
// per lookup, so the counts are exact. See README.md.

import AdjacencyListModule
import GraphProducts
import GraphProtocols
import Testing
import Traversal

@Suite("GraphProducts hash law")
struct ProductHashTests {
    @Test("Undirected: index-space reads of all four products hash nothing; a pair lookup hashes twice")
    func undirectedIndexSpace() {
        final class Tally {
            var hashes = 0
        }
        struct Counted: Hashable {
            let name: String
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        // G: a path with a self-loop at its middle; H: a triangle with a pendant vertex.
        let g = UndirectedAdjacencyList<Counted>(
            vertices: ["a", "b", "c"].map { Counted(name: $0, tally: tally) },
            edges: [["a", "b"], ["b", "b"], ["b", "c"]].map { UndirectedEdge(Counted(name: $0[0], tally: tally), Counted(name: $0[1], tally: tally)) })
        let h = UndirectedAdjacencyList<Counted>(
            vertices: ["x", "y", "z", "w"].map { Counted(name: $0, tally: tally) },
            edges: [["x", "y"], ["y", "z"], ["z", "x"], ["z", "w"]].map { UndirectedEdge(Counted(name: $0[0], tally: tally), Counted(name: $0[1], tally: tally)) })
        let probe = Pair(Counted(name: "b", tally: tally), Counted(name: "z", tally: tally))

        let cartesian = cartesianProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 12 {
            _ = Array(cartesian.neighborIndices(ofIndex: i))
            _ = Array(cartesian.incidentEdges(ofIndex: i))
            _ = Array(cartesian.incidentEdgeIndices(ofIndex: i))
            _ = cartesian.vertex(atIndex: i)
        }
        for position in cartesian.edges.indices { _ = cartesian.edges[position]; _ = cartesian.edgeIndex(of: position) }
        _ = (cartesian.edgeCount, cartesian.vertexIndexBound, cartesian.edgeIndexBound, Array(cartesian.vertices))
        #expect(tally.hashes == 0)
        #expect(cartesian.vertexIndex(of: probe) == 6 && tally.hashes == 2)
        tally.hashes = 0
        #expect(cartesian.contains(probe) && tally.hashes == 2)
        tally.hashes = 0
        _ = Array(cartesian.neighbors(of: probe))
        #expect(tally.hashes == 2)

        let tensor = tensorProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 12 {
            _ = Array(tensor.neighborIndices(ofIndex: i))
            _ = Array(tensor.incidentEdges(ofIndex: i))
            _ = tensor.vertex(atIndex: i)
        }
        for position in tensor.edges.indices { _ = tensor.edges[position] }
        _ = (tensor.edgeCount, tensor.vertexIndexBound, tensor.edgeIndexBound, Array(tensor.vertices))
        #expect(tally.hashes == 0)
        #expect(tensor.vertexIndex(of: probe) == 6 && tally.hashes == 2)
        tally.hashes = 0
        _ = Array(tensor.incidentEdges(of: probe))
        #expect(tally.hashes == 2)

        let strong = strongProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 12 {
            _ = Array(strong.neighborIndices(ofIndex: i))
            _ = Array(strong.incidentEdges(ofIndex: i))
            _ = strong.vertex(atIndex: i)
        }
        for position in strong.edges.indices { _ = strong.edges[position] }
        _ = (strong.edgeCount, strong.vertexIndexBound, strong.edgeIndexBound, Array(strong.vertices))
        #expect(tally.hashes == 0)
        #expect(strong.vertexIndex(of: probe) == 6 && tally.hashes == 2)

        let lexicographic = lexicographicProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 12 {
            _ = Array(lexicographic.neighborIndices(ofIndex: i))
            _ = Array(lexicographic.incidentEdges(ofIndex: i))
            _ = lexicographic.vertex(atIndex: i)
        }
        for position in lexicographic.edges.indices { _ = lexicographic.edges[position] }
        _ = (lexicographic.edgeCount, lexicographic.vertexIndexBound, lexicographic.edgeIndexBound, Array(lexicographic.vertices))
        #expect(tally.hashes == 0)
        #expect(lexicographic.vertexIndex(of: probe) == 6 && tally.hashes == 2)
    }

    @Test("Directed: index-space reads of all four products hash nothing; a pair lookup hashes twice")
    func directedIndexSpace() {
        final class Tally {
            var hashes = 0
        }
        struct Counted: Hashable {
            let name: String
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        let g = AdjacencyList<Counted>(
            vertices: ["a", "b", "c"].map { Counted(name: $0, tally: tally) },
            edges: [["a", "b"], ["b", "b"], ["b", "c"], ["c", "a"]].map { DirectedEdge(from: Counted(name: $0[0], tally: tally), to: Counted(name: $0[1], tally: tally)) })
        let h = AdjacencyList<Counted>(
            vertices: ["x", "y"].map { Counted(name: $0, tally: tally) },
            edges: [["x", "y"], ["y", "x"], ["y", "y"]].map { DirectedEdge(from: Counted(name: $0[0], tally: tally), to: Counted(name: $0[1], tally: tally)) })
        let probe = Pair(Counted(name: "c", tally: tally), Counted(name: "y", tally: tally))

        let cartesian = cartesianProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 6 {
            _ = Array(cartesian.successorIndices(ofIndex: i))
            _ = Array(cartesian.outEdges(ofIndex: i))
            _ = Array(cartesian.predecessorIndices(ofIndex: i))
            _ = Array(cartesian.inEdges(ofIndex: i))
            _ = cartesian.vertex(atIndex: i)
        }
        for position in cartesian.edges.indices { _ = cartesian.edges[position]; _ = cartesian.edgeIndex(of: position) }
        _ = (cartesian.edgeCount, cartesian.vertexIndexBound, cartesian.edgeIndexBound, Array(cartesian.vertices))
        #expect(tally.hashes == 0)
        #expect(cartesian.vertexIndex(of: probe) == 5 && tally.hashes == 2)
        tally.hashes = 0
        _ = Array(cartesian.successors(of: probe))
        #expect(tally.hashes == 2)

        let tensor = tensorProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 6 {
            _ = Array(tensor.successorIndices(ofIndex: i))
            _ = Array(tensor.outEdges(ofIndex: i))
            _ = Array(tensor.predecessorIndices(ofIndex: i))
            _ = Array(tensor.inEdges(ofIndex: i))
        }
        for position in tensor.edges.indices { _ = tensor.edges[position]; _ = tensor.edgeIndex(of: position) }
        _ = (tensor.edgeCount, tensor.edgeIndexBound)
        #expect(tally.hashes == 0)

        let strong = strongProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 6 {
            _ = Array(strong.successorIndices(ofIndex: i))
            _ = Array(strong.outEdges(ofIndex: i))
            _ = Array(strong.predecessorIndices(ofIndex: i))
            _ = Array(strong.inEdges(ofIndex: i))
        }
        for position in strong.edges.indices { _ = strong.edges[position]; _ = strong.edgeIndex(of: position) }
        _ = (strong.edgeCount, strong.edgeIndexBound)
        #expect(tally.hashes == 0)

        let lexicographic = lexicographicProduct(g, h)
        tally.hashes = 0
        for i in 0 ..< 6 {
            _ = Array(lexicographic.successorIndices(ofIndex: i))
            _ = Array(lexicographic.outEdges(ofIndex: i))
            _ = Array(lexicographic.predecessorIndices(ofIndex: i))
            _ = Array(lexicographic.inEdges(ofIndex: i))
        }
        for position in lexicographic.edges.indices { _ = lexicographic.edges[position]; _ = lexicographic.edgeIndex(of: position) }
        _ = (lexicographic.edgeCount, lexicographic.edgeIndexBound)
        #expect(tally.hashes == 0)
        #expect(lexicographic.vertexIndex(of: probe) == 5 && tally.hashes == 2)
    }

    @Test("A search over a product hashes the same however many edges the factors have")
    func searchHashesAtInputsOnly() {
        final class Tally {
            var hashes = 0
        }
        struct Counted: Hashable {
            let name: String
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        let names = ["a", "b", "c", "d", "e", "f"]
        // A sparse factor (a path) and a dense one (complete) on the same vertices.
        let path = AdjacencyList<Counted>(
            vertices: names.map { Counted(name: $0, tally: tally) },
            edges: zip(names, names.dropFirst()).map { DirectedEdge(from: Counted(name: $0, tally: tally), to: Counted(name: $1, tally: tally)) })
        let complete = AdjacencyList<Counted>(
            vertices: names.map { Counted(name: $0, tally: tally) },
            edges: names.flatMap { u in names.filter { $0 != u }.map { DirectedEdge(from: Counted(name: u, tally: tally), to: Counted(name: $0, tally: tally)) } })
        let k2 = AdjacencyList<Counted>(
            vertices: ["x", "y"].map { Counted(name: $0, tally: tally) },
            edges: [DirectedEdge(from: Counted(name: "x", tally: tally), to: Counted(name: "y", tally: tally))])
        let source = Pair(Counted(name: "a", tally: tally), Counted(name: "x", tally: tally))
        let sparse = strongProduct(path, k2), dense = strongProduct(complete, k2)
        #expect(dense.edgeCount > 4 * sparse.edgeCount)
        tally.hashes = 0
        let sparseReached = Array(sparse.breadthFirstSearch(from: source)).count
        let sparseHashes = tally.hashes
        tally.hashes = 0
        let denseReached = Array(dense.breadthFirstSearch(from: source)).count
        let denseHashes = tally.hashes
        #expect(sparseReached > 0 && denseReached > 0)
        #expect(sparseHashes == denseHashes)
        #expect(sparseHashes <= 2 * 12)
    }
}
