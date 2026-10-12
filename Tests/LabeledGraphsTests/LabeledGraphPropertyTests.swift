// Properties with shrinking (swift-property-based). Random operation sequences on the matrix base
// run against a model written out beside the graph: the labels in insertion order (a new label
// takes the next index; `insert(edge:)` inserts a missing source, then a missing target) and the
// set of labeled arcs. After every step every result and the whole state are compared: labels and
// their indices both ways, every row by label and by index in ascending index order, the edges in
// row-major order of their indices, membership, and the base's arcs as the labeled arcs through
// the indices. Then random builds of both bases against the first-appearance rule, equality against
// the model's rule (equal label sets and equal arc sets, whatever the index assignment), and
// Codable round trips. See README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import PropertyBased
import Testing
import Traversal

@Suite("LabeledGraphs properties against a model, with shrinking", .tags(.randomized))
struct LabeledGraphPropertyTests {
    @Test("Random mutation sequences on the matrix base agree with the model after every step")
    func mutationAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 15), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = LabeledGraph<String, AdjacencyMatrix>()
            var labels: [String] = []
            var arcs = Set<[String]>()
            for (step, (kind, x, y)) in operations.enumerated() {
                let a = "l\(x)", b = "l\(y)"
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0, 1:
                    let result = graph.insert(a)
                    #expect(result.inserted == !labels.contains(a) && result.memberAfterInsert == a, "\(context)")
                    if !labels.contains(a) { labels.append(a) }
                case 2, 3, 4, 5, 6:
                    let result = graph.insert(edge: DirectedEdge(from: a, to: b))
                    #expect(result.inserted == !arcs.contains([a, b]) && result.memberAfterInsert == DirectedEdge(from: a, to: b), "\(context)")
                    for l in [a, b] where !labels.contains(l) { labels.append(l) }
                    arcs.insert([a, b])
                case 7, 8:
                    let before = graph
                    let result = try? graph.insert(checked: DirectedEdge(from: a, to: b))
                    if labels.contains(a) && labels.contains(b) {
                        #expect(result?.inserted == !arcs.contains([a, b]) && result?.memberAfterInsert == DirectedEdge(from: a, to: b), "\(context)")
                        arcs.insert([a, b])
                    } else {
                        // `VertexNotFound`, the only error it throws, and nothing changes.
                        #expect(result == nil && graph == before && graph.base == before.base, "\(context)")
                    }
                case 9, 10, 11, 12:
                    let removed = graph.remove(edge: DirectedEdge(from: a, to: b))
                    #expect(removed == (arcs.contains([a, b]) ? DirectedEdge(from: a, to: b) : nil), "\(context)")
                    arcs.remove([a, b])
                case 13:
                    graph.removeAllEdges(keepingCapacity: x.isMultiple(of: 2))
                    arcs.removeAll()
                case 14:
                    if x < 2 {
                        graph.removeAll(keepingCapacity: y.isMultiple(of: 2))
                        labels.removeAll()
                        arcs.removeAll()
                    }
                default:
                    graph.reserveCapacity(vertexCount: x * 3)
                }
                // The whole state.
                let index = Dictionary(uniqueKeysWithValues: labels.enumerated().map { ($1, $0) })
                let sortedArcs = arcs.sorted { (index[$0[0]]!, index[$0[1]]!) < (index[$1[0]]!, index[$1[1]]!) }
                #expect(Array(graph.vertices) == labels, "\(context)")
                #expect(graph.vertexCount == labels.count && graph.edgeCount == arcs.count && graph.vertexIndexBound == labels.count, "\(context)")
                #expect(graph.edges.map { [$0.source, $0.target] } == sortedArcs, "\(context)")
                #expect(graph.edges.indices.map { [$0.source, $0.target] } == sortedArcs.map { [index[$0[0]]!, index[$0[1]]!] }, "\(context)")
                #expect(graph.base.vertexCount == labels.count, "\(context)")
                #expect(graph.base.edges.map { [labels[$0.source], labels[$0.target]] } == sortedArcs, "\(context)")
                for (i, l) in labels.enumerated() {
                    let successors = labels.filter { arcs.contains([l, $0]) }
                    let predecessors = labels.filter { arcs.contains([$0, l]) }
                    #expect(graph.vertexIndex(of: l) == i && (try? graph.vertexIndex(checked: l)) == i && graph.vertex(atIndex: i) == l, "\(context)")
                    #expect(Array(graph.successors(of: l)) == successors && Array(graph.predecessors(of: l)) == predecessors, "\(context)")
                    #expect(Array(graph.successorIndices(ofIndex: i)) == successors.map { index[$0]! }, "\(context)")
                    #expect(Array(graph.predecessorIndices(ofIndex: i)) == predecessors.map { index[$0]! }, "\(context)")
                    #expect(graph.outEdges(of: l).map { graph.target(ofEdgeAt: $0) } == successors, "\(context)")
                    #expect(graph.inEdges(of: l).map { graph.source(ofEdgeAt: $0) } == predecessors, "\(context)")
                    #expect(graph.outDegree(of: l) == successors.count && graph.inDegree(of: l) == predecessors.count, "\(context)")
                    #expect(graph.degree(of: l) == successors.count + predecessors.count, "\(context)")
                }
                for x in 0 ... 7 {
                    let l = "l\(x)"
                    #expect(graph.contains(l) == labels.contains(l), "\(context)")
                    for y in 0 ... 7 {
                        #expect(graph.contains(edge: DirectedEdge(from: l, to: "l\(y)")) == arcs.contains([l, "l\(y)"]), "\(context)")
                    }
                }
                #expect((try? graph.successors(checked: "absent")) == nil && (try? graph.vertexIndex(checked: "absent")) == nil, "\(context)")
            }
            // Equal to its rebuilds, in the same order and in reverse.
            let edges = arcs.map { DirectedEdge(from: $0[0], to: $0[1]) }
            #expect(graph == LabeledGraph<String, AdjacencyMatrix>(vertices: labels, edges: edges), "\(operations)")
            #expect(graph == LabeledGraph<String, AdjacencyMatrix>(vertices: labels.reversed(), edges: edges), "\(operations)")
        }
    }

    @Test("Builds of both bases: listed labels first, then new endpoints in first-appearance order; parallel edges once")
    func buildsAgainstModel() async {
        let input = zip(Gen.int(in: 0 ... 9).array(of: 0 ... 8), zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 25))
        await propertyCheck(count: 300, input: input) { vertices, raw in
            let listed = vertices.map { "v\($0)" }
            let edges = raw.map { DirectedEdge(from: "v\($0.0)", to: "v\($0.1)") }
            var labels: [String] = []
            for l in listed + edges.flatMap({ [$0.source, $0.target] }) where !labels.contains(l) { labels.append(l) }
            let index = Dictionary(uniqueKeysWithValues: labels.enumerated().map { ($1, $0) })
            let arcs = Set(edges.map { [index[$0.source]!, index[$0.target]!] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            let labeledArcs = arcs.map { [labels[$0[0]], labels[$0[1]]] }
            let csr = LabeledGraph<String, CompressedSparseRow>(vertices: listed, edges: edges)
            let matrix = LabeledGraph<String, AdjacencyMatrix>(vertices: listed, edges: edges)
            #expect(Array(csr.vertices) == labels && Array(matrix.vertices) == labels, "\(vertices) \(raw)")
            #expect(csr.edges.map { [$0.source, $0.target] } == labeledArcs && matrix.edges.map { [$0.source, $0.target] } == labeledArcs, "\(vertices) \(raw)")
            #expect(Array(csr.edges.indices) == Array(0 ..< arcs.count), "\(vertices) \(raw)")
            #expect(matrix.edges.indices.map { [$0.source, $0.target] } == arcs, "\(vertices) \(raw)")
            #expect(csr.base.edges.map { [$0.source, $0.target] } == arcs && csr.base.vertexCount == labels.count, "\(vertices) \(raw)")
            #expect(csr.edgeIndexBound == arcs.count && matrix.edgeIndexBound == nil, "\(vertices) \(raw)")
            for (i, l) in labels.enumerated() {
                let successors = arcs.filter { $0[0] == i }.map { $0[1] }
                #expect(Array(csr.successorIndices(ofIndex: i)) == successors && Array(matrix.successorIndices(ofIndex: i)) == successors, "\(vertices) \(raw)")
                #expect(Array(csr.successors(of: l)) == successors.map { labels[$0] }, "\(vertices) \(raw)")
                #expect(csr.outEdges(of: l).map { csr.target(ofEdgeAt: $0) } == successors.map { labels[$0] }, "\(vertices) \(raw)")
            }
            // init(_ graph:) and init(_:labels:) give the same graph.
            #expect(LabeledGraph<String, CompressedSparseRow>(matrix) == csr && LabeledGraph<String, AdjacencyMatrix>(csr) == matrix, "\(vertices) \(raw)")
            let relabeledCSR = try LabeledGraph(csr.base, labels: labels), relabeledMatrix = try LabeledGraph(matrix.base, labels: labels)
            #expect(relabeledCSR == csr && relabeledMatrix == matrix, "\(vertices) \(raw)")
            // topologicalSort is the base's through the labels.
            #expect(csr.topologicalSort() == csr.base.topologicalSort()?.map { labels[$0] }, "\(vertices) \(raw)")
        }
    }

    @Test("Equality is equal label sets and equal labeled arc sets, whatever the index assignment")
    func equalityAgainstModel() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, edges, Gen.int(in: 0 ... 1_000)) { first, second, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let lhsEdges = first.map { DirectedEdge(from: "v\($0.0)", to: "v\($0.1)") }
            let rhsEdges = second.map { DirectedEdge(from: "v\($0.0)", to: "v\($0.1)") }
            let extra = seed % 3 == 0 ? ["v9"] : []
            let lhsLabels = Set(lhsEdges.flatMap { [$0.source, $0.target] } + extra)
            let rhsLabels = Set(rhsEdges.flatMap { [$0.source, $0.target] })
            let expected = lhsLabels == rhsLabels && Set(lhsEdges) == Set(rhsEdges)
            let lhs = LabeledGraph<String, CompressedSparseRow>(vertices: lhsLabels.sorted().shuffled(using: &rng), edges: lhsEdges)
            let rhs = LabeledGraph<String, CompressedSparseRow>(vertices: rhsLabels.sorted().shuffled(using: &rng), edges: rhsEdges.shuffled(using: &rng))
            #expect((lhs == rhs) == expected && (rhs == lhs) == expected, "\(first) \(second) \(seed)")
            let lhsMatrix = LabeledGraph<String, AdjacencyMatrix>(vertices: lhsLabels.sorted().reversed(), edges: lhsEdges)
            let rhsMatrix = LabeledGraph<String, AdjacencyMatrix>(vertices: rhsLabels.sorted(), edges: rhsEdges.reversed())
            #expect((lhsMatrix == rhsMatrix) == expected, "\(first) \(second) \(seed)")
            // A graph equals every relabeling of itself in another index order.
            let reordered = LabeledGraph<String, CompressedSparseRow>(vertices: Array(lhs.vertices).shuffled(using: &rng), edges: Array(lhs.edges))
            #expect(reordered == lhs && lhs == reordered, "\(first) \(seed)")
        }
    }

    @Test("Codable round trips keep the labels, their indices and the base")
    func codableRoundTrip() async throws {
        let input = zip(Gen.int(in: 0 ... 9).array(of: 0 ... 6), zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 20))
        await propertyCheck(count: 200, input: input) { vertices, raw in
            let listed = vertices.map { "v\($0)" }
            let edges = raw.map { DirectedEdge(from: "v\($0.0)", to: "v\($0.1)") }
            let csr = LabeledGraph<String, CompressedSparseRow>(vertices: listed, edges: edges)
            let matrix = LabeledGraph<String, AdjacencyMatrix>(vertices: listed, edges: edges)
            guard let decodedCSR = try? JSONDecoder().decode(LabeledGraph<String, CompressedSparseRow>.self, from: JSONEncoder().encode(csr)),
                  let decodedMatrix = try? JSONDecoder().decode(LabeledGraph<String, AdjacencyMatrix>.self, from: JSONEncoder().encode(matrix))
            else {
                Issue.record("round trip failed for \(vertices) \(raw)")
                return
            }
            #expect(decodedCSR == csr && Array(decodedCSR.vertices) == Array(csr.vertices) && decodedCSR.base == csr.base, "\(vertices) \(raw)")
            #expect(decodedMatrix == matrix && Array(decodedMatrix.vertices) == Array(matrix.vertices) && decodedMatrix.base == matrix.base, "\(vertices) \(raw)")
        }
    }
}
