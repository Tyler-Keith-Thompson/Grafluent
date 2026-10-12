// Attached maps under random mutation sequences (swift-property-based, with shrinking), against a
// model written out in the test: a dictionary from each vertex to its value and one from each
// hyperedge's position (its identity: hyperedges are only appended) to its value. Each sequence
// mixes insertions of vertices and hyperedges, checked insertions, writes by index, by vertex and
// by position, removeAll, and a copy taken midway whose values must not change after it. After
// every step every value is read through the subscripts, the checked subscripts and
// `values(of:)`, and the reads just past the ends must throw. See README.md.

import GraphProtocols
import Hypergraphs
import PropertyBased
import Testing

@Suite("Hypergraphs attached maps against a model, with shrinking", .tags(.randomized))
struct HypergraphMapPropertyTests {
    @Test("Undirected: maps agree with a dictionary model after every step")
    func undirectedAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 7).array(of: 0 ... 4)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: operations) { operations in
            var hypergraph = UndirectedIncidenceList<String>()
            let weights = hypergraph.addEdgeMap(default: -1)
            let labels = hypergraph.addVertexMap(of: String.self)
            var names: [String] = []
            var edgeModel: [Int: Int] = [:]
            var vertexModel: [String: String?] = [:]
            var snapshot: (UndirectedIncidenceList<String>, [Int: Int], [String: String?])?
            for (step, (kind, raw)) in operations.enumerated() {
                let members = raw.map { "v\($0)" }
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0:
                    let v = members.first ?? "v0"
                    hypergraph.insert(v)
                    if !names.contains(v) {
                        names.append(v)
                        vertexModel[v] = .some(nil)
                    }
                case 1, 2:
                    let position = hypergraph.insert(hyperedge: members)
                    for v in members where !names.contains(v) {
                        names.append(v)
                        vertexModel[v] = .some(nil)
                    }
                    edgeModel[position] = -1
                case 3:
                    if let position = try? hypergraph.insert(checked: members) { edgeModel[position] = -1 }
                case 4:
                    if !edgeModel.isEmpty {
                        let position = (raw.first ?? 0) % edgeModel.count
                        hypergraph[weights, ofEdgeAt: position] = raw.count
                        edgeModel[position] = raw.count
                    }
                case 5:
                    if let v = members.first, names.contains(v) {
                        hypergraph[labels, of: v] = "\(raw)"
                        vertexModel[v] = "\(raw)"
                    }
                case 6:
                    if !names.isEmpty {
                        let index = (raw.first ?? 0) % names.count
                        let value: String? = raw.count.isMultiple(of: 2) ? nil : "i\(raw.count)"
                        hypergraph[labels, ofVertexAt: index] = value
                        vertexModel[names[index]] = value
                    }
                case 7:
                    if snapshot == nil { snapshot = (hypergraph, edgeModel, vertexModel) }
                case 8:
                    hypergraph.reserveCapacity(vertexCount: names.count + 8, hyperedgeCount: edgeModel.count + 8, incidenceCount: 32)
                default:
                    if raw.count < 2 {
                        hypergraph.removeAll(keepingCapacity: raw.isEmpty)
                        names.removeAll()
                        edgeModel.removeAll()
                        vertexModel.removeAll()
                    }
                }
                let w = hypergraph.values(of: weights), l = hypergraph.values(of: labels)
                #expect(hypergraph.hyperedgeCount == edgeModel.count && Array(hypergraph.vertices) == names, "\(context)")
                for (position, value) in edgeModel {
                    #expect(hypergraph[weights, ofEdgeAt: position] == value, "\(context)")
                    #expect((try? hypergraph[weights, checkedEdgeAt: position]) == value, "\(context)")
                    #expect(w[position] == value, "\(context)")
                }
                for (index, v) in names.enumerated() {
                    #expect(hypergraph[labels, of: v] == vertexModel[v]!, "\(context)")
                    #expect(hypergraph[labels, ofVertexAt: index] == vertexModel[v]!, "\(context)")
                    #expect((try? hypergraph[labels, checked: v]) == vertexModel[v]!, "\(context)")
                    #expect((try? hypergraph[labels, checkedVertexAt: index]) == vertexModel[v]!, "\(context)")
                    #expect(l[index] == vertexModel[v]!, "\(context)")
                }
                #expect(throws: EdgeNotFound.self, "\(context)") { try hypergraph[weights, checkedEdgeAt: edgeModel.count] }
                #expect(throws: VertexNotFound.self, "\(context)") { try hypergraph[labels, checkedVertexAt: names.count] }
                #expect(throws: VertexNotFound.self, "\(context)") { try hypergraph[labels, checked: "absent"] }
                if let (copy, copyEdges, copyVertices) = snapshot {
                    #expect(copy.hyperedgeCount == copyEdges.count && copy.vertexCount == copyVertices.count, "\(context)")
                    for (position, value) in copyEdges { #expect(copy[weights, ofEdgeAt: position] == value, "copy, \(context)") }
                    for (v, value) in copyVertices { #expect(copy[labels, of: v] == value, "copy, \(context)") }
                }
            }
        }
    }

    @Test("Directed: maps agree with a dictionary model after every step")
    func directedAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 7).array(of: 0 ... 4)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: operations) { operations in
            var hypergraph = IncidenceList<String>()
            let weights = hypergraph.addEdgeMap(default: -1)
            let labels = hypergraph.addVertexMap(of: String.self)
            var names: [String] = []
            var edgeModel: [Int: Int] = [:]
            var vertexModel: [String: String?] = [:]
            var snapshot: (IncidenceList<String>, [Int: Int], [String: String?])?
            for (step, (kind, raw)) in operations.enumerated() {
                let all = raw.map { "v\($0)" }
                let sources = Array(all.prefix(all.count / 2)), targets = Array(all.dropFirst(all.count / 2))
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0:
                    let v = all.first ?? "v0"
                    hypergraph.insert(v)
                    if !names.contains(v) {
                        names.append(v)
                        vertexModel[v] = .some(nil)
                    }
                case 1, 2:
                    let position = hypergraph.insert(sources: sources, targets: targets)
                    for v in sources + targets where !names.contains(v) {
                        names.append(v)
                        vertexModel[v] = .some(nil)
                    }
                    edgeModel[position] = -1
                case 3:
                    if let position = try? hypergraph.insert(checked: sources, targets: targets) { edgeModel[position] = -1 }
                case 4:
                    if !edgeModel.isEmpty {
                        let position = (raw.first ?? 0) % edgeModel.count
                        hypergraph[weights, ofEdgeAt: position] = raw.count
                        edgeModel[position] = raw.count
                    }
                case 5:
                    if let v = all.first, names.contains(v) {
                        hypergraph[labels, of: v] = "\(raw)"
                        vertexModel[v] = "\(raw)"
                    }
                case 6:
                    if !names.isEmpty {
                        let index = (raw.first ?? 0) % names.count
                        let value: String? = raw.count.isMultiple(of: 2) ? nil : "i\(raw.count)"
                        hypergraph[labels, ofVertexAt: index] = value
                        vertexModel[names[index]] = value
                    }
                case 7:
                    if snapshot == nil { snapshot = (hypergraph, edgeModel, vertexModel) }
                case 8:
                    // The reversal keeps every position: the maps come with it.
                    hypergraph = hypergraph.reversed
                default:
                    if raw.count < 2 {
                        hypergraph.removeAll(keepingCapacity: raw.isEmpty)
                        names.removeAll()
                        edgeModel.removeAll()
                        vertexModel.removeAll()
                    }
                }
                let w = hypergraph.values(of: weights), l = hypergraph.values(of: labels)
                #expect(hypergraph.hyperedgeCount == edgeModel.count && Array(hypergraph.vertices) == names, "\(context)")
                for (position, value) in edgeModel {
                    #expect(hypergraph[weights, ofEdgeAt: position] == value, "\(context)")
                    #expect((try? hypergraph[weights, checkedEdgeAt: position]) == value, "\(context)")
                    #expect(w[position] == value, "\(context)")
                }
                for (index, v) in names.enumerated() {
                    #expect(hypergraph[labels, of: v] == vertexModel[v]!, "\(context)")
                    #expect(hypergraph[labels, ofVertexAt: index] == vertexModel[v]!, "\(context)")
                    #expect((try? hypergraph[labels, checked: v]) == vertexModel[v]!, "\(context)")
                    #expect((try? hypergraph[labels, checkedVertexAt: index]) == vertexModel[v]!, "\(context)")
                    #expect(l[index] == vertexModel[v]!, "\(context)")
                }
                #expect(throws: EdgeNotFound.self, "\(context)") { try hypergraph[weights, checkedEdgeAt: edgeModel.count] }
                #expect(throws: VertexNotFound.self, "\(context)") { try hypergraph[labels, checkedVertexAt: names.count] }
                #expect(throws: VertexNotFound.self, "\(context)") { try hypergraph[labels, checked: "absent"] }
                if let (copy, copyEdges, copyVertices) = snapshot {
                    #expect(copy.hyperedgeCount == copyEdges.count && copy.vertexCount == copyVertices.count, "\(context)")
                    for (position, value) in copyEdges { #expect(copy[weights, ofEdgeAt: position] == value, "copy, \(context)") }
                    for (v, value) in copyVertices { #expect(copy[labels, of: v] == value, "copy, \(context)") }
                }
            }
        }
    }
}
