// Generations (GraphProtocols' `GraphGeneration`) on both representations: every structural
// mutation starts a new one, and a call that changes nothing does not (inserting a vertex already
// present, a checked insertion that throws, reserving capacity, attaching and writing maps). A
// copy is in the same generation until either is mutated; built and decoded hypergraphs have one,
// `init()` and `reversed` none until their first mutation. See README.md.
// Two copies, under every interleaving of three steps, never share a generation in different
// states.

import Foundation
import GraphProtocols
import Hypergraphs
import Testing

@Suite("Hypergraphs generations")
struct HypergraphGenerationTests {
    @Test("Undirected: every structural mutation starts a generation; a call that changes nothing does not")
    func undirectedMutations() {
        var hypergraph = UndirectedIncidenceList<Int>()
        #expect(!hypergraph.generation.isCurrent(for: hypergraph))
        hypergraph.insert(0)
        var seen = hypergraph.generation
        #expect(seen.isCurrent(for: hypergraph))
        let steps: [(String, (inout UndirectedIncidenceList<Int>) -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(hyperedge:)", { _ = $0.insert(hyperedge: [0, 2]) }),
            ("insert(hyperedge:) of present members", { _ = $0.insert(hyperedge: [0, 1]) }),
            ("insert(hyperedge:) empty", { _ = $0.insert(hyperedge: [] as [Int]) }),
            ("insert(checked:)", { _ = try? $0.insert(checked: [1, 2]) }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("insert(_:) after removeAll", { _ = $0.insert(5) }),
            ("removeAll()", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            step(&hypergraph)
            #expect(!seen.isCurrent(for: hypergraph), "\(name)")
            #expect(hypergraph.generation.isCurrent(for: hypergraph), "\(name)")
            seen = hypergraph.generation
        }
        hypergraph.insert(hyperedge: [5, 6])
        seen = hypergraph.generation
        let unchanged: [(String, (inout UndirectedIncidenceList<Int>) -> Void)] = [
            ("insert(_:) of a vertex", { _ = $0.insert(5) }),
            ("insert(checked:) that throws", { _ = try? $0.insert(checked: [5, 9]) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, hyperedgeCount: 100, incidenceCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0)
                $0[w, ofEdgeAt: 0] = 3
                let t = $0.addVertexMap(of: String.self)
                $0[t, of: 5] = "five"
                $0.removeEdgeMap(w)
                $0.removeVertexMap(t)
            }),
        ]
        for (name, step) in unchanged {
            step(&hypergraph)
            #expect(seen.isCurrent(for: hypergraph), "\(name)")
        }
    }

    @Test("Directed: every structural mutation starts a generation; a call that changes nothing does not")
    func directedMutations() {
        var hypergraph = IncidenceList<Int>()
        #expect(!hypergraph.generation.isCurrent(for: hypergraph))
        hypergraph.insert(0)
        var seen = hypergraph.generation
        #expect(seen.isCurrent(for: hypergraph))
        let steps: [(String, (inout IncidenceList<Int>) -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(sources:targets:)", { _ = $0.insert(sources: [0], targets: [2]) }),
            ("insert(sources:targets:) of present vertices", { _ = $0.insert(sources: [0], targets: [1]) }),
            ("insert(sources:targets:) empty", { _ = $0.insert(sources: [] as [Int], targets: [] as [Int]) }),
            ("insert(checked:targets:)", { _ = try? $0.insert(checked: [1], targets: [2]) }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("insert(_:) after removeAll", { _ = $0.insert(5) }),
            ("removeAll()", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            step(&hypergraph)
            #expect(!seen.isCurrent(for: hypergraph), "\(name)")
            #expect(hypergraph.generation.isCurrent(for: hypergraph), "\(name)")
            seen = hypergraph.generation
        }
        hypergraph.insert(sources: [5], targets: [6])
        seen = hypergraph.generation
        let unchanged: [(String, (inout IncidenceList<Int>) -> Void)] = [
            ("insert(_:) of a vertex", { _ = $0.insert(5) }),
            ("insert(checked:targets:) that throws", { _ = try? $0.insert(checked: [5], targets: [9]) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, hyperedgeCount: 100, sourceCount: 100, targetCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0)
                $0[w, ofEdgeAt: 0] = 3
                let t = $0.addVertexMap(of: String.self)
                $0[t, of: 5] = "five"
                $0.removeEdgeMap(w)
                $0.removeVertexMap(t)
            }),
        ]
        for (name, step) in unchanged {
            step(&hypergraph)
            #expect(seen.isCurrent(for: hypergraph), "\(name)")
        }
    }

    @Test("A copy shares the generation until either is mutated; built and decoded hypergraphs have one")
    func copiesAndConstruction() throws {
        var undirected = UndirectedIncidenceList(hyperedges: [[0, 1]])
        let built = undirected.generation
        #expect(built.isCurrent(for: undirected))
        var copy = undirected
        #expect(built.isCurrent(for: copy) && copy.generation.isCurrent(for: undirected))
        copy.insert(hyperedge: [1, 2])
        #expect(!built.isCurrent(for: copy) && built.isCurrent(for: undirected))
        undirected.insert(7)
        #expect(!built.isCurrent(for: undirected) && !undirected.generation.isCurrent(for: copy))
        for other in [UndirectedIncidenceList<Int>(vertices: [] as [Int]), UndirectedIncidenceList(vertices: [3]),
                      UndirectedIncidenceList(hyperedges: [] as [[Int]]), UndirectedIncidenceList(undirected.dual())] {
            #expect(other.generation.isCurrent(for: other))
        }
        let decoded = try JSONDecoder().decode(UndirectedIncidenceList<Int>.self, from: JSONEncoder().encode(copy))
        #expect(decoded.generation.isCurrent(for: decoded) && !decoded.generation.isCurrent(for: copy))
        #expect(decoded == copy)
        // The conversion of the same type is the hypergraph itself.
        #expect(UndirectedIncidenceList(copy).generation.isCurrent(for: copy))

        var directed = IncidenceList(hyperedges: [(sources: [0], targets: [1])])
        let builtDirected = directed.generation
        #expect(builtDirected.isCurrent(for: directed))
        let directedCopy = directed
        directed.insert(sources: [1], targets: [0])
        #expect(!builtDirected.isCurrent(for: directed) && builtDirected.isCurrent(for: directedCopy))
        for other in [IncidenceList<Int>(vertices: [] as [Int]), IncidenceList(vertices: [3]),
                      IncidenceList(hyperedges: [] as [(sources: [Int], targets: [Int])]), IncidenceList(directed.dual())] {
            #expect(other.generation.isCurrent(for: other))
        }
        let decodedDirected = try JSONDecoder().decode(IncidenceList<Int>.self, from: JSONEncoder().encode(directed))
        #expect(decodedDirected.generation.isCurrent(for: decodedDirected) && !decodedDirected.generation.isCurrent(for: directed))
        #expect(IncidenceList(directed).generation.isCurrent(for: directed))

        // The reversal is another hypergraph: no generation until it is mutated.
        var reversed = directed.reversed
        #expect(!reversed.generation.isCurrent(for: reversed) && !directed.generation.isCurrent(for: reversed))
        reversed.insert(9)
        #expect(reversed.generation.isCurrent(for: reversed) && !reversed.generation.isCurrent(for: directed))
        #expect(directed.generation.isCurrent(for: directed))
    }

    @Test("UndirectedIncidenceList: two copies never share a generation in different states, under every interleaving of three steps")
    func undirectedDivergence() {
        // Two copies of one graph, each step applied to either: whenever two generations seen along
        // the way are current for each other, the states they were read from are the same. The
        // states are read into plain values, which hold none of the graph's storage, so the copies'
        // arrays are shared exactly as the steps leave them.
        func state(of graph: UndirectedIncidenceList<Int>) -> String {
            return "\(Array(graph.vertices)) \(graph.hyperedges.map { "\($0)" })"
        }
        func make() -> UndirectedIncidenceList<Int> {
            var graph = UndirectedIncidenceList<Int>()
            _ = graph.insert(hyperedge: [0, 1, 2])
            _ = graph.insert(hyperedge: [2, 3])
            return graph
        }
        let steps: [(String, (inout UndirectedIncidenceList<Int>) -> Void)] = [
            ("insert(_:)", { _ = $0.insert(9) }),
            ("insert(_:) of a vertex", { _ = $0.insert(0) }),
            ("insert(hyperedge:)", { _ = $0.insert(hyperedge: [1, 4]) }),
            ("insert(hyperedge:) empty", { _ = $0.insert(hyperedge: [] as [Int]) }),
            ("insert(checked:)", { _ = try? $0.insert(checked: [0, 3]) }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("removeAll()", { $0.removeAll() }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 64, hyperedgeCount: 64, incidenceCount: 64) }),
            ("a map attached and written", { let w = $0.addEdgeMap(default: 0); if $0.hyperedgeCount > 0 { $0[w, ofEdgeAt: 0] = 1 } })
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

    @Test("IncidenceList: two copies never share a generation in different states, under every interleaving of three steps")
    func directedDivergence() {
        // Two copies of one graph, each step applied to either: whenever two generations seen along
        // the way are current for each other, the states they were read from are the same. The
        // states are read into plain values, which hold none of the graph's storage, so the copies'
        // arrays are shared exactly as the steps leave them.
        func state(of graph: IncidenceList<Int>) -> String {
            return "\(Array(graph.vertices)) \(graph.hyperedges.map { "\($0)" })"
        }
        func make() -> IncidenceList<Int> {
            var graph = IncidenceList<Int>()
            _ = graph.insert(sources: [0, 1], targets: [2])
            _ = graph.insert(sources: [2], targets: [3])
            return graph
        }
        let steps: [(String, (inout IncidenceList<Int>) -> Void)] = [
            ("insert(_:)", { _ = $0.insert(9) }),
            ("insert(_:) of a vertex", { _ = $0.insert(0) }),
            ("insert(sources:targets:)", { _ = $0.insert(sources: [1], targets: [4]) }),
            ("insert(sources:targets:) empty", { _ = $0.insert(sources: [] as [Int], targets: [] as [Int]) }),
            ("insert(checked:targets:)", { _ = try? $0.insert(checked: [0], targets: [3]) }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("removeAll()", { $0.removeAll() }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 64, hyperedgeCount: 64, sourceCount: 64, targetCount: 64) }),
            ("a map attached and written", { let w = $0.addEdgeMap(default: 0); if $0.hyperedgeCount > 0 { $0[w, ofEdgeAt: 0] = 1 } })
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
}
