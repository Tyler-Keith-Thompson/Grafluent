// Attached maps and generations through the wrapper against a model, with shrinking
// (swift-property-based). A random sequence of vertex and edge insertions (some rejected, as a
// self-loop, a cycle or, through `insert(checked:)`, a missing endpoint), removals (by vertex, by
// pair, by position), resets, value writes and copies runs on a DirectedAcyclicGraph over each
// base, with three maps attached through the wrapper: an edge map whose value is each edge's
// insertion stamp, an Optional edge map of labels and a vertex map of ranks. The model keys the
// edges by stamp (their endpoints and labels) and the ranks by vertex, in Dictionaries. After every
// step the stamps at the live positions must be exactly the model's, each at an edge with the
// model's endpoints; every label and rank must be the model's, through the subscripts and
// `values(of:)`; the base must hold the same values; and the order must be a topological order.
// From the first structural mutation on, the generation read before a step must still be current
// exactly when the step changed no vertex or edge, and the graph's generation must be current for
// the base. On a failure, PropertyBased prints the smallest failing sequence. Each base's test
// writes out its own model.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

@Suite("DirectedAcyclicGraph attached maps and generations against a model", .tags(.randomized))
struct DirectedAcyclicGraphMapPropertyTests {
    @Test("AdjacencyList base: every value follows its edge or vertex, and the generation its mutations")
    func adjacencyList() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            var graph = DirectedAcyclicGraph<AdjacencyList<Int>>()
            let stamps = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            var ends: [Int: DirectedEdge<Int>] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var vertices = Set<Int>()
            var stamp = 0
            var mutated = false
            func liveStamps() -> [Int] { graph.edges.indices.map { graph[stamps, ofEdgeAt: $0] } }
            func forget(_ gone: some Sequence<Int>) {
                for s in gone {
                    ends[s] = nil
                    labelModel[s] = nil
                }
            }
            func inserted(_ position: Int, _ edge: DirectedEdge<Int>) {
                // AdjacencyList is simple: an existing edge keeps its stamp.
                guard ends.values.contains(edge) == false else {
                    #expect(ends[graph[stamps, ofEdgeAt: position]] == edge)
                    return
                }
                stamp += 1
                #expect(graph[stamps, ofEdgeAt: position] == -1 && graph[labels, ofEdgeAt: position] == nil)
                graph[stamps, ofEdgeAt: position] = stamp
                ends[stamp] = edge
                vertices.insert(edge.source)
                vertices.insert(edge.target)
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = DirectedEdge(from: a, to: b)
                let before = graph.generation
                let shape = (vertices, Set(ends.keys))
                switch operation {
                case 0:
                    if graph.insert(a).inserted {
                        #expect(graph[ranks, of: a] == 0.5)
                        vertices.insert(a)
                    }
                case 1, 2, 3:
                    if let position = try? graph.insert(edge: edge) { inserted(position, edge) }
                case 4:
                    if let position = try? graph.insert(checked: edge) { inserted(position, edge) }
                case 5:
                    let old = Set(liveStamps())
                    if graph.remove(edge: edge) != nil {
                        let gone = old.subtracting(liveStamps())
                        #expect(gone.count == 1 && gone.allSatisfy { ends[$0] == edge }, "step \(step)")
                        forget(gone)
                    }
                case 6:
                    if graph.edgeCount > 0 {
                        let p = Array(graph.edges.indices)[c % graph.edgeCount]
                        let s = graph[stamps, ofEdgeAt: p]
                        #expect(graph.remove(edgeAt: p) == ends[s])
                        forget([s])
                    }
                case 7:
                    if graph.remove(a) != nil {
                        vertices.remove(a)
                        rankModel[a] = nil
                        forget(ends.filter { $0.value.source == a || $0.value.target == a }.map(\.key))
                    }
                case 8, 9:
                    if graph.edgeCount > 0 {
                        let p = Array(graph.edges.indices)[c % graph.edgeCount]
                        let label: String? = operation == 8 ? "s\(c)" : nil
                        graph[labels, ofEdgeAt: p] = label
                        labelModel[graph[stamps, ofEdgeAt: p]] = label
                    }
                case 10:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 11:
                    if c < 20 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        vertices = []
                        rankModel = [:]
                    } else if c < 50 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                    } else {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    }
                default:
                    // A copy mutated in place of the graph leaves the graph's values alone.
                    var copy = graph
                    if let p = copy.edges.indices.first { copy[stamps, ofEdgeAt: p] = -99 }
                    if copy.contains(a) { copy[ranks, of: a] = -1 }
                    copy.remove(a)
                    _ = try? copy.insert(edge: edge)
                }

                let changed = shape != (vertices, Set(ends.keys))
                if changed { mutated = true }
                if mutated {
                    #expect(before.isCurrent(for: graph) == !changed, "step \(step): generation")
                    #expect(graph.generation.isCurrent(for: graph.base), "step \(step): the base's generation")
                }
                #expect(Set(graph.vertices) == vertices, "step \(step)")
                let live = liveStamps()
                #expect(live.count == ends.count && Set(live) == Set(ends.keys), "step \(step): stamps")
                let stampValues = graph.values(of: stamps), labelValues = graph.values(of: labels)
                for p in graph.edges.indices {
                    let s = graph[stamps, ofEdgeAt: p]
                    #expect(graph.edges[p] == ends[s], "step \(step): edge at \(p)")
                    #expect(stampValues[p] == s && graph.base[stamps, ofEdgeAt: p] == s, "step \(step): stamp at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s] && (try? graph[labels, checkedEdgeAt: p]) == labelModel[s], "step \(step): label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    let expected = rankModel[v] ?? 0.5
                    #expect(graph[ranks, of: v] == expected && graph.base[ranks, of: v] == expected, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexIndex(of: v)] == expected, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[graph.vertexIndex(of: v)] == expected && (try? graph[ranks, checked: v]) == expected, "step \(step): rank of \(v)")
                }
                let order = Array(graph.topologicalOrder)
                #expect(graph.edges.allSatisfy { order.firstIndex(of: $0.source)! < order.firstIndex(of: $0.target)! }, "step \(step): order")
                #expect(throws: EdgeNotFound.self) { try graph[stamps, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }

    @Test("DirectedPseudograph base: every value follows its edge copy or vertex, and the generation its mutations")
    func directedPseudograph() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
            let stamps = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            var ends: [Int: DirectedEdge<Int>] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var vertices = Set<Int>()
            var stamp = 0
            var mutated = false
            func liveStamps() -> [Int] { graph.edges.indices.map { graph[stamps, ofEdgeAt: $0] } }
            func forget(_ gone: some Sequence<Int>) {
                for s in gone {
                    ends[s] = nil
                    labelModel[s] = nil
                }
            }
            func inserted(_ position: Int, _ edge: DirectedEdge<Int>) {
                // Every insertion is a new copy, at the end.
                stamp += 1
                #expect(position == ends.count)
                #expect(graph[stamps, ofEdgeAt: position] == -1 && graph[labels, ofEdgeAt: position] == nil)
                graph[stamps, ofEdgeAt: position] = stamp
                ends[stamp] = edge
                vertices.insert(edge.source)
                vertices.insert(edge.target)
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = DirectedEdge(from: a, to: b)
                let before = graph.generation
                let shape = (vertices, Set(ends.keys))
                switch operation {
                case 0:
                    if graph.insert(a).inserted {
                        #expect(graph[ranks, of: a] == 0.5)
                        vertices.insert(a)
                    }
                case 1, 2, 3:
                    if let position = try? graph.insert(edge: edge) { inserted(position, edge) }
                case 4:
                    if let position = try? graph.insert(checked: edge) { inserted(position, edge) }
                case 5:
                    let old = Set(liveStamps())
                    if graph.remove(edge: edge) != nil {
                        let gone = old.subtracting(liveStamps())
                        // The newest copy goes.
                        #expect(gone == [ends.filter { $0.value == edge }.keys.max()!], "step \(step)")
                        forget(gone)
                    }
                case 6:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = graph[stamps, ofEdgeAt: p]
                        #expect(graph.remove(edgeAt: p) == ends[s])
                        forget([s])
                    }
                case 7:
                    if graph.remove(a) != nil {
                        vertices.remove(a)
                        rankModel[a] = nil
                        forget(ends.filter { $0.value.source == a || $0.value.target == a }.map(\.key))
                    }
                case 8, 9:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let label: String? = operation == 8 ? "s\(c)" : nil
                        graph[labels, ofEdgeAt: p] = label
                        labelModel[graph[stamps, ofEdgeAt: p]] = label
                    }
                case 10:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 11:
                    if c < 20 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        vertices = []
                        rankModel = [:]
                    } else if c < 50 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                    } else {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    }
                default:
                    var copy = graph
                    if copy.edgeCount > 0 { copy[stamps, ofEdgeAt: 0] = -99 }
                    if copy.contains(a) { copy[ranks, of: a] = -1 }
                    copy.remove(a)
                    _ = try? copy.insert(edge: edge)
                }

                let changed = shape != (vertices, Set(ends.keys))
                if changed { mutated = true }
                if mutated {
                    #expect(before.isCurrent(for: graph) == !changed, "step \(step): generation")
                    #expect(graph.generation.isCurrent(for: graph.base), "step \(step): the base's generation")
                }
                #expect(Set(graph.vertices) == vertices, "step \(step)")
                let live = liveStamps()
                #expect(live.count == ends.count && Set(live) == Set(ends.keys), "step \(step): stamps")
                let stampValues = graph.values(of: stamps), labelValues = graph.values(of: labels)
                for p in graph.edges.indices {
                    let s = graph[stamps, ofEdgeAt: p]
                    #expect(graph.edges[p] == ends[s], "step \(step): edge at \(p)")
                    #expect(stampValues[p] == s && graph.base[stamps, ofEdgeAt: p] == s, "step \(step): stamp at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s] && (try? graph[labels, checkedEdgeAt: p]) == labelModel[s], "step \(step): label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    let expected = rankModel[v] ?? 0.5
                    #expect(graph[ranks, of: v] == expected && graph.base[ranks, of: v] == expected, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexIndex(of: v)] == expected, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[graph.vertexIndex(of: v)] == expected && (try? graph[ranks, checked: v]) == expected, "step \(step): rank of \(v)")
                }
                let order = Array(graph.topologicalOrder)
                #expect(graph.edges.allSatisfy { order.firstIndex(of: $0.source)! < order.firstIndex(of: $0.target)! }, "step \(step): order")
                #expect(throws: EdgeNotFound.self) { try graph[stamps, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }

    @Test("StableDirectedGraph base: every value follows its edge copy or vertex, and the generation its mutations")
    func stableDirectedGraph() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>()
            let stamps = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            var ends: [Int: DirectedEdge<Int>] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var vertices = Set<Int>()
            var stamp = 0
            var mutated = false
            // Positions removed since the last reset: never handed out again, and they read as
            // no edge.
            var vacated = Set<Int>()
            func liveStamps() -> [Int] { graph.edges.indices.map { graph[stamps, ofEdgeAt: $0] } }
            func forget(_ gone: some Sequence<Int>) {
                for s in gone {
                    ends[s] = nil
                    labelModel[s] = nil
                }
            }
            func inserted(_ position: Int, _ edge: DirectedEdge<Int>) {
                stamp += 1
                #expect(!vacated.contains(position))
                #expect(graph[stamps, ofEdgeAt: position] == -1 && graph[labels, ofEdgeAt: position] == nil)
                graph[stamps, ofEdgeAt: position] = stamp
                ends[stamp] = edge
                vertices.insert(edge.source)
                vertices.insert(edge.target)
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = DirectedEdge(from: a, to: b)
                let before = graph.generation
                // Resetting the positions (clearing the edges of an edgeless graph whose bound is
                // not 0) is a structural change too.
                let shape = (vertices, Set(ends.keys), graph.edgePositionBound, graph.vertexPositionBound)
                let positions = Set(graph.edges.indices)
                switch operation {
                case 0:
                    if graph.insert(a).inserted {
                        #expect(graph[ranks, of: a] == 0.5)
                        vertices.insert(a)
                    }
                case 1, 2, 3:
                    if let position = try? graph.insert(edge: edge) { inserted(position, edge) }
                case 4:
                    if let position = try? graph.insert(checked: edge) { inserted(position, edge) }
                case 5:
                    let old = Set(liveStamps())
                    if graph.remove(edge: edge) != nil {
                        let gone = old.subtracting(liveStamps())
                        #expect(gone.count == 1 && gone.allSatisfy { ends[$0] == edge }, "step \(step)")
                        forget(gone)
                    }
                case 6:
                    if graph.edgeCount > 0 {
                        let p = Array(graph.edges.indices)[c % graph.edgeCount]
                        let s = graph[stamps, ofEdgeAt: p]
                        #expect(graph.remove(edgeAt: p) == ends[s])
                        forget([s])
                    }
                case 7:
                    if graph.remove(a) != nil {
                        vertices.remove(a)
                        rankModel[a] = nil
                        forget(ends.filter { $0.value.source == a || $0.value.target == a }.map(\.key))
                    }
                case 8, 9:
                    if graph.edgeCount > 0 {
                        let p = Array(graph.edges.indices)[c % graph.edgeCount]
                        let label: String? = operation == 8 ? "s\(c)" : nil
                        graph[labels, ofEdgeAt: p] = label
                        labelModel[graph[stamps, ofEdgeAt: p]] = label
                    }
                case 10:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 11:
                    if c < 20 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        vertices = []
                        rankModel = [:]
                        vacated = []
                    } else if c < 50 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        vacated = []
                    } else {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    }
                default:
                    var copy = graph
                    if let p = copy.edges.indices.first { copy[stamps, ofEdgeAt: p] = -99 }
                    if copy.contains(a) { copy[ranks, of: a] = -1 }
                    copy.remove(a)
                    _ = try? copy.insert(edge: edge)
                }
                if operation != 11 || c >= 50 { vacated.formUnion(positions.subtracting(graph.edges.indices)) }

                let changed = shape != (vertices, Set(ends.keys), graph.edgePositionBound, graph.vertexPositionBound)
                if changed { mutated = true }
                // The stable base starts a generation on every `removeAll`, an empty graph's too:
                // the safe direction.
                let resets = operation == 11 && c < 20
                if mutated && !(resets && !changed) {
                    #expect(before.isCurrent(for: graph) == !changed, "step \(step): generation")
                    #expect(graph.generation.isCurrent(for: graph.base), "step \(step): the base's generation")
                }
                #expect(Set(graph.vertices) == vertices, "step \(step)")
                let live = liveStamps()
                #expect(live.count == ends.count && Set(live) == Set(ends.keys), "step \(step): stamps")
                let stampValues = graph.values(of: stamps), labelValues = graph.values(of: labels)
                for p in graph.edges.indices {
                    let s = graph[stamps, ofEdgeAt: p]
                    #expect(graph.edges[p] == ends[s], "step \(step): edge at \(p)")
                    #expect(stampValues[p] == s && graph.base[stamps, ofEdgeAt: p] == s, "step \(step): stamp at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s] && (try? graph[labels, checkedEdgeAt: p]) == labelModel[s], "step \(step): label at \(p)")
                }
                for p in vacated where p < graph.edgePositionBound {
                    #expect(throws: EdgeNotFound.self, "step \(step): vacated \(p)") { try graph[stamps, checkedEdgeAt: p] }
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    let expected = rankModel[v] ?? 0.5
                    #expect(graph[ranks, of: v] == expected && graph.base[ranks, of: v] == expected, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexPosition(of: v)] == expected, "step \(step): rank at \(v)'s position")
                    #expect(rankValues[graph.vertexPosition(of: v)] == expected && (try? graph[ranks, checked: v]) == expected, "step \(step): rank of \(v)")
                }
                let order = Array(graph.topologicalOrder)
                #expect(graph.edges.allSatisfy { order.firstIndex(of: $0.source)! < order.firstIndex(of: $0.target)! }, "step \(step): order")
                #expect(throws: EdgeNotFound.self) { try graph[stamps, checkedEdgeAt: graph.edgePositionBound] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexPositionBound] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }
}
