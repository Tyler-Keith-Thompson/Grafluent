// Generations (GraphProtocols' `GraphGeneration`): every structural mutation of an AdjacencyMatrix
// starts a new one, and a call that changes nothing (an existing edge, an absent edge, a clear row)
// does not; attaching and writing maps and reserving capacity do not either. A copy is in the same
// generation until either is mutated; derived matrices are new graphs. See README.md.
// Two copies, under every interleaving of three steps, never share a generation in different
// states.

import AdjacencyMatrixModule
import BitCollections
import GraphProtocols
import Testing

@Suite("AdjacencyMatrix generations")
struct AdjacencyMatrixGenerationTests {
    @Test("Every structural mutation starts a generation; a call that changes nothing does not")
    func everyMutation() throws {
        var matrix = AdjacencyMatrix(vertexCount: 4)
        // Never mutated: no generation, current for nothing.
        #expect(!matrix.generation.isCurrent(for: matrix))
        matrix.appendVertex()
        var seen = matrix.generation
        #expect(seen.isCurrent(for: matrix))
        let other = AdjacencyMatrix(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 3, to: 4)])
        let steps: [(String, (inout AdjacencyMatrix) throws -> Void)] = [
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: DirectedEdge(from: 1, to: 2)) }),
            ("subscript true", { $0[2, 2] = true }),
            ("toggle", { $0[3, 0].toggle() }),
            ("subscript false", { $0[2, 2] = false }),
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 1, to: 2)) }),
            ("insertEdges(from:to:)", { _ = $0.insertEdges(from: 4, to: BitSet([0, 1, 2])) }),
            ("insertEdges(from:to:) inserting one", { _ = $0.insertEdges(from: 4, to: BitSet([0, 1, 2, 3])) }),
            ("removeEdges(from:)", { _ = $0.removeEdges(from: 4) }),
            ("insert(edge:) 4→3", { _ = $0.insert(edge: DirectedEdge(from: 4, to: 3)) }),
            ("removeEdges(to:)", { _ = $0.removeEdges(to: 3) }),
            ("insert(edge:) 2→4", { _ = $0.insert(edge: DirectedEdge(from: 2, to: 4)) }),
            ("removeEdges(incidentTo:)", { _ = $0.removeEdges(incidentTo: 4) }),
            ("formUnion", { $0.formUnion(other) }),
            ("formIntersection", { $0.formIntersection(other) }),
            ("formSymmetricDifference", { $0.formSymmetricDifference(other) }),
            ("subtract", { $0.subtract(other) }),
            ("appendVertex()", { _ = $0.appendVertex() }),
            ("insert(edge:) 5→5", { _ = $0.insert(edge: DirectedEdge(from: 5, to: 5)) }),
            ("removeAllEdges(keepingCapacity: true)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAllEdges()", { $0.removeAllEdges() }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("removeAll()", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&matrix)
            #expect(!seen.isCurrent(for: matrix), "\(name)")
            #expect(matrix.generation.isCurrent(for: matrix), "\(name)")
            seen = matrix.generation
        }

        // Calls that change nothing keep the generation.
        matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        _ = matrix.addEdgeMap(default: 0)
        seen = matrix.generation
        let unchanged: [(String, (inout AdjacencyMatrix) throws -> Void)] = [
            ("insert(edge:) of an edge", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("remove(edge:) of a non-edge", { _ = $0.remove(edge: DirectedEdge(from: 1, to: 0)) }),
            ("remove(edge:) out of range", { _ = $0.remove(edge: DirectedEdge(from: 9, to: 0)) }),
            ("subscript true on an edge", { $0[0, 1] = true }),
            ("subscript false on a non-edge", { $0[2, 2] = false }),
            ("insertEdges(from:to:) of edges", { _ = $0.insertEdges(from: 0, to: BitSet([1])) }),
            ("removeEdges(from:) of an empty row", { _ = $0.removeEdges(from: 2) }),
            ("removeEdges(to:) of an empty column", { _ = $0.removeEdges(to: 2) }),
            ("insert(checked:) throwing", { _ = try? $0.insert(checked: DirectedEdge(from: 0, to: 7)) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100) }),
            ("addEdgeMap", { _ = $0.addEdgeMap(default: "") }),
            ("addVertexMap and a write", { let m = $0.addVertexMap(default: 0); $0[m, of: 1] = 4 }),
            ("an edge map write", { let m = $0.addEdgeMap(default: 0); $0[m, ofEdgeAt: $0.edges.startIndex] = 4 }),
        ]
        for (name, step) in unchanged {
            try step(&matrix)
            #expect(seen.isCurrent(for: matrix), "\(name)")
        }
        // removeAllEdges(keepingCapacity: true) with no edge to remove.
        var empty = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 0)])
        empty.remove(edge: DirectedEdge(from: 0, to: 0))
        let emptySeen = empty.generation
        empty.removeAllEdges(keepingCapacity: true)
        #expect(emptySeen.isCurrent(for: empty))
    }

    @Test("A copy shares the generation until either is mutated; derived matrices are not current for the source")
    func copiesAndDerived() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        matrix.insert(edge: DirectedEdge(from: 1, to: 2))
        let seen = matrix.generation
        var copy = matrix
        #expect(seen.isCurrent(for: copy))
        copy.insert(edge: DirectedEdge(from: 2, to: 0))
        #expect(!seen.isCurrent(for: copy))
        #expect(seen.isCurrent(for: matrix))
        #expect(!copy.generation.isCurrent(for: matrix))
        matrix.insert(edge: DirectedEdge(from: 2, to: 1))
        #expect(!seen.isCurrent(for: matrix))
        #expect(!matrix.generation.isCurrent(for: copy))
        // Results of whole-matrix operations are other graphs.
        let current = matrix.generation
        #expect(!current.isCurrent(for: matrix.complement()))
        #expect(!current.isCurrent(for: matrix.transposed()))
        #expect(!current.isCurrent(for: matrix.union(copy)))
        #expect(current.isCurrent(for: matrix))
        // A matrix one mutation into its lineage (version 0) derives nothing current for it.
        var young = AdjacencyMatrix(vertexCount: 3)
        young.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(!young.generation.isCurrent(for: young.complement()))
        #expect(!young.generation.isCurrent(for: young.transposed()))
        // A decoded or rebuilt equal matrix is another graph.
        #expect(!current.isCurrent(for: AdjacencyMatrix(vertexCount: 3, edges: matrix.edges)))
    }

    @Test("AdjacencyMatrix: two copies never share a generation in different states, under every interleaving of three steps")
    func divergence() {
        // Two copies of one graph, each step applied to either: whenever two generations seen along
        // the way are current for each other, the states they were read from are the same. The
        // states are read into plain values, which hold none of the graph's storage, so the copies'
        // arrays are shared exactly as the steps leave them.
        func state(of graph: AdjacencyMatrix) -> String {
            return "\(graph.vertexCount) \(Array(graph.edges))"
        }
        func make() -> AdjacencyMatrix {
            var graph = AdjacencyMatrix(vertexCount: 4)
            for (s, t) in [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)] { graph.insert(edge: DirectedEdge(from: s, to: t)) }
            return graph
        }
        let steps: [(String, (inout AdjacencyMatrix) -> Void)] = [
            ("appendVertex()", { _ = $0.appendVertex() }),
            ("insert(checked:)", { _ = try? $0.insert(checked: DirectedEdge(from: 3, to: 1)) }),
            ("insert(checked:) of 0→1", { _ = try? $0.insert(checked: DirectedEdge(from: 0, to: 1)) }),
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 1, to: 2)) }),
            ("subscript toggle", { if $0.vertexCount > 2 { $0[2, 2].toggle() } }),
            ("removeEdges(from:)", { if $0.vertexCount > 0 { _ = $0.removeEdges(from: 0) } }),
            ("removeEdges(to:)", { if $0.vertexCount > 2 { _ = $0.removeEdges(to: 2) } }),
            ("insertEdges(from:to:)", { if $0.vertexCount > 3 { _ = $0.insertEdges(from: 3, to: BitSet([0, 3])) } }),
            ("formSymmetricDifference", { var other = AdjacencyMatrix(vertexCount: $0.vertexCount); if $0.vertexCount > 1 { other.insert(edge: DirectedEdge(from: 1, to: 0)) }; $0.formSymmetricDifference(other) }),
            ("removeAllEdges(keepingCapacity: true)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAllEdges()", { $0.removeAllEdges() }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 200) }),
            ("a map attached and written", { let w = $0.addEdgeMap(default: 0); if let p = $0.edges.indices.first { $0[w, ofEdgeAt: p] = 1 } })
        ]
        var violations: [String] = []
        let choices = 2 * steps.count
        for first in 0 ..< choices {
            for second in 0 ..< choices {
                for third in 0 ..< choices {
                    var a = make()
                    var b = a
                    var seen = [(a.generation, state(of: a), "start")]
                    var history = ""
                    for choice in [first, second, third] {
                        let (name, step) = steps[choice % steps.count]
                        if choice < steps.count { step(&a) } else { step(&b) }
                        history += (choice < steps.count ? " a." : " b.") + name
                        seen.append((a.generation, state(of: a), "a after" + history))
                        seen.append((b.generation, state(of: b), "b after" + history))
                    }
                    for i in seen.indices {
                        for j in seen.indices where j > i && seen[i].0.isCurrent(for: seen[j].0) && seen[i].1 != seen[j].1 {
                            violations.append("\(seen[i].2) and \(seen[j].2)")
                        }
                    }
                }
            }
        }
        #expect(violations.isEmpty, "\(violations.count) violations, among them \(violations.prefix(3))")
    }

    @Test("removeAll on an empty matrix still starts a generation of its own in each copy")
    func emptyRemoveAll() {
        var matrix = AdjacencyMatrix(vertexCount: 2)
        _ = matrix.insert(edge: DirectedEdge(from: 0, to: 1))
        matrix.removeAll()
        var first = matrix
        var second = first
        first.removeAll()
        second.removeAll(keepingCapacity: true)
        _ = first.appendVertex()
        #expect(!first.generation.isCurrent(for: second.generation) && !matrix.generation.isCurrent(for: first.generation))
        #expect(!matrix.generation.isCurrent(for: second.generation))
    }

}
