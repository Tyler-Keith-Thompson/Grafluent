// Attached maps and generations through a LabeledGraph over AdjacencyMatrix against a model, with
// shrinking (swift-property-based). A random sequence of label and edge insertions, removals (one
// edge, a row, a column, both, every edge, everything), value writes and copies runs on a graph with
// an edge map of weights, an Optional edge map of tags and a vertex map of ranks, all attached
// through the labeled graph. The model keys the weights and tags by labeled edge and the ranks by
// label, in Dictionaries. After every step the edges must be the model's, and every value must be
// the model's through the subscripts (by cell, by label, checked), `values(of:)` (by cell and by the
// label's index) and the base's own subscripts; the cell of a removed edge must throw and read the
// default. From the first structural mutation on, the generation read before a step must not be
// current after a step that changed a label or an edge, must stay current through value writes and
// copies, and must be the base's. On a failure, PropertyBased prints the smallest failing sequence.

import AdjacencyMatrixModule
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import PropertyBased
import Testing

@Suite("LabeledGraph attached maps and generations against a model", .tags(.randomized))
struct LabeledGraphMapPropertyTests {
    @Test("AdjacencyMatrix base: every value follows its edge or label, and the generation its mutations")
    func adjacencyMatrix() async {
        // (operation, a, b, c): a and b name the labels "a"..."f", c a position or a value.
        let operations = zip(Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            let names = ["a", "b", "c", "d", "e", "f"]
            var graph = LabeledGraph<String, AdjacencyMatrix>()
            let weights = graph.addEdgeMap(default: 0)
            let tags = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            var labels: [String] = []
            var weightModel: [DirectedEdge<String>: Int] = [:]
            var tagModel: [DirectedEdge<String>: String] = [:]
            var edges = Set<DirectedEdge<String>>()
            var rankModel: [String: Double] = [:]
            var mutated = false
            // The cells of removed edges that hold no edge now.
            var vacated = Set<AdjacencyMatrix.Edges.Index>()
            func drop(_ gone: [DirectedEdge<String>]) {
                for e in gone {
                    edges.remove(e)
                    weightModel[e] = nil
                    tagModel[e] = nil
                }
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let u = names[a], v = names[b]
                let edge = DirectedEdge(from: u, to: v)
                let before = graph.generation
                let shape = (labels, edges)
                let cells = Set(graph.edges.indices)
                // Whether the step only writes values or copies: then the generation must stay.
                var keeps = false
                switch operation {
                case 0:
                    if graph.insert(u).inserted {
                        #expect(graph[ranks, of: u] == 0.5)
                        labels.append(u)
                    }
                case 1, 2:
                    for w in [u, v] where !labels.contains(w) { labels.append(w) }
                    let inserted = graph.insert(edge: edge).inserted
                    #expect(inserted == !edges.contains(edge), "step \(step)")
                    edges.insert(edge)
                    #expect(graph[weights, ofEdgeAt: graph.edges.firstIndex(of: edge)!] == weightModel[edge] ?? 0)
                case 3:
                    if labels.contains(u) && labels.contains(v) {
                        _ = try? graph.insert(checked: edge)
                        edges.insert(edge)
                    } else {
                        #expect(throws: VertexNotFound.self) { try graph.insert(checked: edge) }
                    }
                case 4:
                    #expect((graph.remove(edge: edge) != nil) == edges.contains(edge), "step \(step)")
                    drop([edge])
                case 5:
                    if labels.contains(u) {
                        let gone = edges.filter { $0.source == u }
                        #expect(graph.removeEdges(from: u) == gone.count)
                        drop(Array(gone))
                    }
                case 6:
                    if labels.contains(u) {
                        let gone = edges.filter { $0.target == u }
                        #expect(graph.removeEdges(to: u) == gone.count)
                        drop(Array(gone))
                    }
                case 7:
                    if labels.contains(u) {
                        let gone = edges.filter { $0.source == u || $0.target == u }
                        #expect(graph.removeEdges(incidentTo: u) == gone.count)
                        drop(Array(gone))
                    }
                case 8:
                    keeps = true
                    if graph.edgeCount > 0 {
                        let p = Array(graph.edges.indices)[c % graph.edgeCount]
                        let e = graph.edges[p]
                        graph[weights, ofEdgeAt: p] = c
                        weightModel[e] = c
                        let tag: String? = c.isMultiple(of: 3) ? nil : "t\(c)"
                        graph[tags, ofEdgeAt: p] = tag
                        tagModel[e] = tag
                    }
                case 9:
                    keeps = true
                    if labels.contains(u) {
                        graph[ranks, of: u] = Double(c)
                        rankModel[u] = Double(c)
                    }
                case 10:
                    if c < 30 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        labels = []
                        rankModel = [:]
                    } else {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                    }
                    drop(Array(edges))
                default:
                    // A copy mutated in place of the graph leaves the graph's values alone.
                    keeps = true
                    var copy = graph
                    if let p = copy.edges.indices.first { copy[weights, ofEdgeAt: p] = -99 }
                    if copy.contains(u) { copy[ranks, of: u] = -1 }
                    copy.insert(edge: edge)
                    copy.removeEdges(incidentTo: u)
                }

                let changed = shape != (labels, edges)
                if changed { mutated = true }
                if mutated {
                    if changed { #expect(!before.isCurrent(for: graph), "step \(step): generation kept") }
                    if keeps { #expect(before.isCurrent(for: graph), "step \(step): generation started") }
                    #expect(graph.generation.isCurrent(for: graph.base), "step \(step): the base's generation")
                }
                #expect(Array(graph.vertices) == labels, "step \(step)")
                #expect(Set(graph.edges) == edges && graph.edgeCount == edges.count, "step \(step): edges")
                let weightValues = graph.values(of: weights), tagValues = graph.values(of: tags)
                for p in graph.edges.indices {
                    let e = graph.edges[p]
                    let weight = weightModel[e] ?? 0, tag = tagModel[e]
                    #expect(graph[weights, ofEdgeAt: p] == weight && graph.base[weights, ofEdgeAt: p] == weight, "step \(step): weight of \(e)")
                    #expect(weightValues[p] == weight && (try? graph[weights, checkedEdgeAt: p]) == weight, "step \(step): weight of \(e)")
                    #expect(graph[tags, ofEdgeAt: p] == tag && tagValues[p] == tag, "step \(step): tag of \(e)")
                }
                let n = graph.vertexCount
                vacated.formUnion(cells.subtracting(graph.edges.indices))
                vacated.subtract(graph.edges.indices)
                for cell in vacated where cell.source < n && cell.target < n {
                    #expect(throws: EdgeNotFound.self, "step \(step): cell \(cell)") { try graph[weights, checkedEdgeAt: cell] }
                    // A cell with no edge holds the default.
                    #expect(weightValues[cell] == 0 && tagValues[cell] == nil, "step \(step): cell \(cell)")
                }
                let rankValues = graph.values(of: ranks)
                for label in graph.vertices {
                    let expected = rankModel[label] ?? 0.5, index = graph.vertexIndex(of: label)
                    #expect(graph[ranks, of: label] == expected && graph.base[ranks, of: index] == expected, "step \(step): rank of \(label)")
                    #expect(graph[ranks, ofVertexAt: index] == expected && rankValues[index] == expected, "step \(step): rank of \(label)")
                    #expect((try? graph[ranks, checked: label]) == expected && (try? graph[ranks, checkedVertexAt: index]) == expected, "step \(step): rank of \(label)")
                }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: "z"] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: n] }
            }
        }
    }
}
