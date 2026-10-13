// Wrapper behavior, through the public API. The attached maps of a StableDirectedGraph base work
// through the wrapper. `remove(_:)` is a MutableDirectedGraph requirement, so generic code removes
// a vertex. Removing a vertex through the wrapper hashes it once to find it and then only as the
// base must. `insert(checked:)` throws a distinct error for each of its causes. See README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing
import Traversal

@Suite("DirectedAcyclicGraph review findings")
struct DirectedAcyclicGraphReviewTests {
    @Test("Edge and vertex maps attach, read, write and detach through DirectedAcyclicGraph<StableDirectedGraph>")
    func mapsThroughTheWrapper() throws {
        var graph = try #require(DirectedAcyclicGraph<StableDirectedGraph<String>>(edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"),
        ]))
        let weight = graph.addEdgeMap(of: Int.self)
        let label = graph.addVertexMap(of: String.self)
        graph[weight, ofEdgeAt: 0] = 5
        graph[weight, ofEdgeAt: 1] = 7
        graph[label, of: "a"] = "start"
        graph[label, ofVertexAt: 2] = "end"
        #expect(graph[weight, ofEdgeAt: 0] == 5 && graph[weight, ofEdgeAt: 1] == 7)
        #expect(graph[label, of: "a"] == "start" && graph[label, of: "c"] == "end" && graph[label, ofVertexAt: 1] == nil)
        // The base holds the same maps.
        #expect(graph.base[weight, ofEdgeAt: 1] == 7 && graph.base[label, of: "c"] == "end")
        // A non-vertex has no value: the checked read throws.
        #expect(throws: VertexNotFound.self) { try graph[label, checked: "z"] }
        #expect(try graph[label, checked: "a"] == "start" && graph[label, checkedVertexAt: 2] == "end")
        // A reordering keeps every position, so the values stay with their edges.
        #expect(try graph.insert(edge: DirectedEdge(from: "c", to: "d")) == 2)
        #expect(try graph.insert(edge: DirectedEdge(from: "x", to: "a")) == 3)
        #expect(Array(graph.topologicalOrder) == ["x", "a", "b", "c", "d"])
        graph[weight, ofEdgeAt: 3] = 1
        #expect(graph[weight, ofEdgeAt: 0] == 5 && graph[weight, ofEdgeAt: 3] == 1)
        // Removing through the wrapper removes the removed elements' values.
        _ = graph.remove(edgeAt: 0)
        #expect((try? graph[weight, checkedEdgeAt: 0]) == nil && graph[weight, ofEdgeAt: 1] == 7)
        _ = graph.remove("c")
        #expect((try? graph[label, checkedVertexAt: 2]) == nil && (try? graph[weight, checkedEdgeAt: 1]) == nil && graph[weight, ofEdgeAt: 3] == 1)
        #expect(throws: EdgeNotFound.self) { try graph[weight, checkedEdgeAt: 1] }
        // A snapshot by position, as algorithms read it, and a map with a default.
        let w = graph.values(of: weight)
        #expect(w[3] == 1 && graph.values(of: label)[0] == "start")
        let lengths = graph.addEdgeMap(default: 2.5)
        #expect(graph[lengths, ofEdgeAt: 3] == 2.5 && graph.values(of: lengths)[3] == 2.5)
        graph.removeEdgeMap(lengths)
        // A copy carries the maps, copy-on-write.
        var copy = graph
        copy[weight, ofEdgeAt: 3] = 100
        #expect(graph[weight, ofEdgeAt: 3] == 1 && copy[weight, ofEdgeAt: 3] == 100)
        // A weight closure over positions reads the map, as ShortestPaths' algorithms take it.
        let longest = try #require(graph.longestPath(weight: { graph[weight, ofEdgeAt: $0] ?? 0 }))
        #expect(longest.vertices == ["x", "a"] && longest.edges == [3])
        graph.removeEdgeMap(weight)
        graph.removeVertexMap(label)
        #expect(graph.base == copy.base)
    }

    @Test("remove(_:) is a MutableDirectedGraph requirement: generic code removes a vertex from any base")
    func removeIsARequirement() {
        func removeAll<G: MutableDirectedGraph<Int>>(_ vertices: [Int], from graph: inout G) -> [Int?] {
            vertices.map { graph.remove($0) }
        }
        var list = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1)])
        var pseudograph = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1)])
        var stable = StableDirectedGraph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(removeAll([1, 9, 3], from: &list) == [1, nil, 3])
        #expect(removeAll([1, 9, 3], from: &pseudograph) == [1, nil, 3])
        #expect(removeAll([1, 9, 3], from: &stable) == [1, nil, 3])
        #expect(Set(list.vertices) == [0, 2] && list.edgeCount == 0)
        #expect(Set(pseudograph.vertices) == [0, 2] && pseudograph.edgeCount == 0)
        #expect(Array(stable.vertices) == [0, 2] && stable.edgeCount == 0)
    }

    /// A vertex that counts how often it is hashed.
    final class Hashes: @unchecked Sendable {
        var count = 0
    }

    struct Counted: Hashable, @unchecked Sendable {
        let value: Int
        let hashes: Hashes

        static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.value == rhs.value }

        func hash(into hasher: inout Hasher) {
            hashes.count += 1
            hasher.combine(value)
        }
    }

    @Test("Removing a vertex through the wrapper hashes no more than removing it from the bare base, plus the wrapper's lookup on the stable base")
    func removalHashes() throws {
        // A dictionary removal also rehashes the entries it shifts back, so counts are compared
        // between two copies of one base, whose dictionaries are laid out alike.
        let hashes = Hashes()
        let vertices = (0 ..< 40).map { Counted(value: $0, hashes: hashes) }
        let edges = (0 ..< 39).map { DirectedEdge(from: vertices[$0], to: vertices[$0 + 1]) }
        // AdjacencyList: the wrapper's lookup replaces the base's own; the base then renames the
        // vertex moved into the hole and drops the removed one, as its remove(_:) does.
        let list = AdjacencyList(vertices: vertices, edges: edges)
        var bareList = list
        var wrappedList = try #require(DirectedAcyclicGraph(list))
        for v in [3, 17, 0, 36] {
            hashes.count = 0
            let bare = bareList.remove(vertices[v])
            let bareHashes = hashes.count
            hashes.count = 0
            let wrapped = wrappedList.remove(vertices[v])
            let wrappedHashes = hashes.count
            #expect(bare?.value == v && wrapped?.value == v)
            #expect(wrappedHashes == bareHashes, "AdjacencyList, vertex \(v): \(wrappedHashes) against \(bareHashes)")
        }
        let pseudograph = DirectedPseudograph(vertices: vertices, edges: edges)
        var barePseudograph = pseudograph
        var wrappedPseudograph = try #require(DirectedAcyclicGraph(pseudograph))
        for v in [3, 17, 0, 36] {
            hashes.count = 0
            _ = barePseudograph.remove(vertices[v])
            let bareHashes = hashes.count
            hashes.count = 0
            _ = wrappedPseudograph.remove(vertices[v])
            let wrappedHashes = hashes.count
            #expect(wrappedHashes == bareHashes, "DirectedPseudograph, vertex \(v): \(wrappedHashes) against \(bareHashes)")
        }
        // StableDirectedGraph finds and drops the vertex in one dictionary removal, which the
        // wrapper cannot share: it looks the key up first, to find the vertex's slot in the order.
        let stable = StableDirectedGraph(vertices: vertices, edges: edges)
        var bareStable = stable
        var wrappedStable = try #require(DirectedAcyclicGraph(stable))
        for v in [3, 17, 0, 36] {
            hashes.count = 0
            _ = bareStable.remove(vertices[v])
            let bareHashes = hashes.count
            hashes.count = 0
            _ = wrappedStable.remove(vertices[v])
            let wrappedHashes = hashes.count
            #expect(wrappedHashes == bareHashes + 1, "StableDirectedGraph, vertex \(v): \(wrappedHashes) against \(bareHashes)")
        }
        #expect(wrappedList.topologicalOrder.map(\.value) == (0 ..< 40).filter { ![3, 17, 0, 36].contains($0) })
        #expect(wrappedPseudograph.base == barePseudograph && wrappedStable.base == bareStable)
    }

    @Test("insert(checked:) throws a different error for a missing endpoint, a self-loop and a cycle, and changes nothing")
    func checkedInsertCauses() throws {
        var graph = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(edges: [DirectedEdge(from: 0, to: 1)]))
        let missing = DirectedEdge(from: 1, to: 2), loop = DirectedEdge(from: 1, to: 1), cycle = DirectedEdge(from: 1, to: 0)
        #expect(throws: AcyclicEdgeError.missingEndpoint) { try graph.insert(checked: missing) }
        #expect(throws: AcyclicEdgeError.missingEndpoint) { try graph.insert(checked: DirectedEdge(from: 2, to: 2)) }
        #expect(throws: AcyclicEdgeError.selfLoop) { try graph.insert(checked: loop) }
        #expect(throws: AcyclicEdgeError.cycle) { try graph.insert(checked: cycle) }
        #expect(Array(graph.vertices) == [0, 1] && Array(graph.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.topologicalOrder) == [0, 1])
        let path = try #require(graph.bidirectionalShortestPath(from: cycle.target, to: cycle.source))
        #expect(path.edges == [0])
    }
}
