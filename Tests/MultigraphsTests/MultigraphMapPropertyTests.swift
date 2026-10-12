// Attached maps against a model, with shrinking (swift-property-based): a random sequence of
// insertions, removals (by position, by pair, all copies of a pair, by vertex), clears and value
// writes runs on a graph with an edge map, an Optional edge map and a vertex map, and on a model
// that keys each value by its edge copy's insertion stamp or by its vertex (Dictionaries). The copy
// at a position is named without the maps: its pair's copies are listed oldest first by
// `edges(between:and:)` / `edges(from:to:)`, the model's live stamps of that pair sorted are the same
// copies in the same order, so the position's ordinal there picks the stamp. After every step, the
// value at every position and every vertex must be the model's, through the subscripts and
// `values(of:)`, and the position past the last must throw. The multigraphs run the same through
// their base's maps. On a failure, PropertyBased prints the smallest failing sequence. Each test
// writes its own model.

import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import Testing

@Suite("Multigraphs attached maps against a model", .tags(.randomized))
struct MultigraphMapPropertyTests {
    @Test("Pseudograph: every value follows its edge copy or vertex through random mutations")
    func pseudograph() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = Pseudograph<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            // Each live copy's endpoints by insertion stamp, and the values set; an absent value
            // is the default.
            var ends: [Int: UndirectedEdge<Int>] = [:]
            var weightModel: [Int: Int] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var stamp = 0
            // The stamp of the copy at `position`, read from the graph's classes alone.
            func identity(_ position: Int) -> Int {
                let e = graph.edges[position]
                let ordinal = Array(graph.edges(between: e.u, and: e.v)).firstIndex(of: position)!
                return ends.filter { $0.value == e }.keys.sorted()[ordinal]
            }
            func forget(_ stamps: [Int]) {
                for s in stamps {
                    ends[s] = nil
                    weightModel[s] = nil
                    labelModel[s] = nil
                }
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = UndirectedEdge(a, b)
                switch operation {
                case 0:
                    if graph.insert(a).inserted { rankModel[a] = nil }
                case 1, 2:
                    stamp += 1
                    #expect((graph.insert(edge: edge)) == ends.count)
                    ends[stamp] = edge
                case 3:
                    let newest = ends.filter { $0.value == edge }.keys.max()
                    #expect(graph.remove(edge: edge) != nil ? newest != nil : newest == nil)
                    if let newest { forget([newest]) }
                case 4:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph.remove(edgeAt: p)
                        forget([s])
                    }
                case 5:
                    if graph.remove(a) != nil {
                        rankModel[a] = nil
                        forget(ends.filter { ($0.value.u == a || $0.value.v == a) }.map(\.key))
                    }
                case 6, 7:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph[weights, ofEdgeAt: p] = c
                        weightModel[s] = c
                        graph[labels, ofEdgeAt: p] = operation == 6 ? "s\(c)" : nil
                        labelModel[s] = operation == 6 ? "s\(c)" : nil
                    }
                case 8:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 9:
                    #expect(graph.removeAllEdges(between: a, and: b) == ends.filter { $0.value == edge }.count)
                    forget(ends.filter { $0.value == edge }.map(\.key))
                default:
                    if c < 10 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        rankModel = [:]
                    } else if c < 30 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                    } else if c < 50 {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    } else {
                        // A copy mutated in place of the graph leaves the graph's values alone.
                        var copy = graph
                        if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                        copy.remove(a)
                        _ = copy.insert(edge: edge)
                    }
                }

                #expect(graph.edgeCount == ends.count, "step \(step)")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let s = identity(p)
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[s] ?? -1, "step \(step): weight at \(p)")
                    #expect(weightValues[p] == weightModel[s] ?? -1, "step \(step): values(of:) weight at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s], "step \(step): values(of:) label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    #expect(graph[ranks, of: v] == rankModel[v] ?? 0.5, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }

    @Test("DirectedPseudograph: every value follows its edge copy or vertex through random mutations")
    func directedPseudograph() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = DirectedPseudograph<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            // Each live copy's endpoints by insertion stamp, and the values set; an absent value
            // is the default.
            var ends: [Int: DirectedEdge<Int>] = [:]
            var weightModel: [Int: Int] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var stamp = 0
            // The stamp of the copy at `position`, read from the graph's classes alone.
            func identity(_ position: Int) -> Int {
                let e = graph.edges[position]
                let ordinal = Array(graph.edges(from: e.source, to: e.target)).firstIndex(of: position)!
                return ends.filter { $0.value == e }.keys.sorted()[ordinal]
            }
            func forget(_ stamps: [Int]) {
                for s in stamps {
                    ends[s] = nil
                    weightModel[s] = nil
                    labelModel[s] = nil
                }
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = DirectedEdge(from: a, to: b)
                switch operation {
                case 0:
                    if graph.insert(a).inserted { rankModel[a] = nil }
                case 1, 2:
                    stamp += 1
                    #expect((graph.insert(edge: edge)) == ends.count)
                    ends[stamp] = edge
                case 3:
                    let newest = ends.filter { $0.value == edge }.keys.max()
                    #expect(graph.remove(edge: edge) != nil ? newest != nil : newest == nil)
                    if let newest { forget([newest]) }
                case 4:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph.remove(edgeAt: p)
                        forget([s])
                    }
                case 5:
                    if graph.remove(a) != nil {
                        rankModel[a] = nil
                        forget(ends.filter { ($0.value.source == a || $0.value.target == a) }.map(\.key))
                    }
                case 6, 7:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph[weights, ofEdgeAt: p] = c
                        weightModel[s] = c
                        graph[labels, ofEdgeAt: p] = operation == 6 ? "s\(c)" : nil
                        labelModel[s] = operation == 6 ? "s\(c)" : nil
                    }
                case 8:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 9:
                    #expect(graph.removeAllEdges(from: a, to: b) == ends.filter { $0.value == edge }.count)
                    forget(ends.filter { $0.value == edge }.map(\.key))
                default:
                    if c < 10 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        rankModel = [:]
                    } else if c < 30 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                    } else if c < 50 {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    } else {
                        // A copy mutated in place of the graph leaves the graph's values alone.
                        var copy = graph
                        if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                        copy.remove(a)
                        _ = copy.insert(edge: edge)
                    }
                }

                #expect(graph.edgeCount == ends.count, "step \(step)")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let s = identity(p)
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[s] ?? -1, "step \(step): weight at \(p)")
                    #expect(weightValues[p] == weightModel[s] ?? -1, "step \(step): values(of:) weight at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s], "step \(step): values(of:) label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    #expect(graph[ranks, of: v] == rankModel[v] ?? 0.5, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }

    @Test("Multigraph: every value follows its edge copy or vertex through random mutations")
    func multigraph() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = Multigraph<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            // Each live copy's endpoints by insertion stamp, and the values set; an absent value
            // is the default.
            var ends: [Int: UndirectedEdge<Int>] = [:]
            var weightModel: [Int: Int] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var stamp = 0
            // The stamp of the copy at `position`, read from the graph's classes alone.
            func identity(_ position: Int) -> Int {
                let e = graph.edges[position]
                let ordinal = Array(graph.edges(between: e.u, and: e.v)).firstIndex(of: position)!
                return ends.filter { $0.value == e }.keys.sorted()[ordinal]
            }
            func forget(_ stamps: [Int]) {
                for s in stamps {
                    ends[s] = nil
                    weightModel[s] = nil
                    labelModel[s] = nil
                }
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = UndirectedEdge(a, b)
                switch operation {
                case 0:
                    if graph.insert(a).inserted { rankModel[a] = nil }
                case 1, 2:
                    if a == b {
                        // Rejected, and nothing changes.
                        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(edge: edge) }
                        break
                    }
                    stamp += 1
                    #expect((try? graph.insert(edge: edge)) == ends.count)
                    ends[stamp] = edge
                case 3:
                    let newest = ends.filter { $0.value == edge }.keys.max()
                    #expect(graph.remove(edge: edge) != nil ? newest != nil : newest == nil)
                    if let newest { forget([newest]) }
                case 4:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph.remove(edgeAt: p)
                        forget([s])
                    }
                case 5:
                    if graph.remove(a) != nil {
                        rankModel[a] = nil
                        forget(ends.filter { ($0.value.u == a || $0.value.v == a) }.map(\.key))
                    }
                case 6, 7:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph[weights, ofEdgeAt: p] = c
                        weightModel[s] = c
                        graph[labels, ofEdgeAt: p] = operation == 6 ? "s\(c)" : nil
                        labelModel[s] = operation == 6 ? "s\(c)" : nil
                    }
                case 8:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 9:
                    #expect(graph.removeAllEdges(between: a, and: b) == ends.filter { $0.value == edge }.count)
                    forget(ends.filter { $0.value == edge }.map(\.key))
                default:
                    if c < 10 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        rankModel = [:]
                    } else if c < 30 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                    } else if c < 50 {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    } else {
                        // A copy mutated in place of the graph leaves the graph's values alone.
                        var copy = graph
                        if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                        copy.remove(a)
                        _ = try? copy.insert(edge: edge)
                    }
                }

                #expect(graph.edgeCount == ends.count, "step \(step)")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let s = identity(p)
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[s] ?? -1, "step \(step): weight at \(p)")
                    #expect(weightValues[p] == weightModel[s] ?? -1, "step \(step): values(of:) weight at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s], "step \(step): values(of:) label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    #expect(graph[ranks, of: v] == rankModel[v] ?? 0.5, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }

    @Test("DirectedMultigraph: every value follows its edge copy or vertex through random mutations")
    func directedMultigraph() async {
        // (operation, a, b, c): a and b name vertices 0...5, c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = DirectedMultigraph<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            // Each live copy's endpoints by insertion stamp, and the values set; an absent value
            // is the default.
            var ends: [Int: DirectedEdge<Int>] = [:]
            var weightModel: [Int: Int] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            var stamp = 0
            // The stamp of the copy at `position`, read from the graph's classes alone.
            func identity(_ position: Int) -> Int {
                let e = graph.edges[position]
                let ordinal = Array(graph.edges(from: e.source, to: e.target)).firstIndex(of: position)!
                return ends.filter { $0.value == e }.keys.sorted()[ordinal]
            }
            func forget(_ stamps: [Int]) {
                for s in stamps {
                    ends[s] = nil
                    weightModel[s] = nil
                    labelModel[s] = nil
                }
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = DirectedEdge(from: a, to: b)
                switch operation {
                case 0:
                    if graph.insert(a).inserted { rankModel[a] = nil }
                case 1, 2:
                    if a == b {
                        // Rejected, and nothing changes.
                        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(edge: edge) }
                        break
                    }
                    stamp += 1
                    #expect((try? graph.insert(edge: edge)) == ends.count)
                    ends[stamp] = edge
                case 3:
                    let newest = ends.filter { $0.value == edge }.keys.max()
                    #expect(graph.remove(edge: edge) != nil ? newest != nil : newest == nil)
                    if let newest { forget([newest]) }
                case 4:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph.remove(edgeAt: p)
                        forget([s])
                    }
                case 5:
                    if graph.remove(a) != nil {
                        rankModel[a] = nil
                        forget(ends.filter { ($0.value.source == a || $0.value.target == a) }.map(\.key))
                    }
                case 6, 7:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let s = identity(p)
                        graph[weights, ofEdgeAt: p] = c
                        weightModel[s] = c
                        graph[labels, ofEdgeAt: p] = operation == 6 ? "s\(c)" : nil
                        labelModel[s] = operation == 6 ? "s\(c)" : nil
                    }
                case 8:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 9:
                    #expect(graph.removeAllEdges(from: a, to: b) == ends.filter { $0.value == edge }.count)
                    forget(ends.filter { $0.value == edge }.map(\.key))
                default:
                    if c < 10 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                        rankModel = [:]
                    } else if c < 30 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(ends.keys))
                    } else if c < 50 {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    } else {
                        // A copy mutated in place of the graph leaves the graph's values alone.
                        var copy = graph
                        if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                        copy.remove(a)
                        _ = try? copy.insert(edge: edge)
                    }
                }

                #expect(graph.edgeCount == ends.count, "step \(step)")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let s = identity(p)
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[s] ?? -1, "step \(step): weight at \(p)")
                    #expect(weightValues[p] == weightModel[s] ?? -1, "step \(step): values(of:) weight at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[s], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[s], "step \(step): values(of:) label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    #expect(graph[ranks, of: v] == rankModel[v] ?? 0.5, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[graph.vertexIndex(of: v)] == rankModel[v] ?? 0.5, "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 6] }
            }
        }
    }
}
