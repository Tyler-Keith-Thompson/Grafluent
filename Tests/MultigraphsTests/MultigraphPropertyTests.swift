// Properties with shrinking (swift-property-based). Random operation sequences run on each of the
// four types against a model kept beside the graph: a vertex list in slot order, an edge list in
// position order (each edge in its stored orientation, with an insertion stamp), and each vertex's
// rows, updated by the documented rules alone: insertion appends at u, then at v; a removal moves
// the last edge into the hole and each row's last entry into its hole (an undirected loop's later
// end first); removing a vertex detaches its row from the last entry, then moves the last slot into
// its place; `remove(edge:)` takes the copy with the newest stamp; `edges(between:and:)` lists the
// copies by stamp. Every call's result and the whole state are compared after every step. Then the
// laws on random graphs after random removals, equality and hashing independent of orders, Codable
// round trips, the collapse to the simple lists (the first copy by position wins, in its
// orientation), and the drop-in check against the reference conformers. See README.md.

import AdjacencyListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import Testing

@Suite("Multigraphs properties against a model, with shrinking", .tags(.randomized))
struct MultigraphPropertyTests {
    @Test("Pseudograph: random operation sequences agree with the model after every step")
    func pseudographAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = Pseudograph<Int>()
            var vertices: [Int] = []
            var edges: [(u: Int, v: Int, stamp: Int)] = []
            var rows: [Int: [Int]] = [:]
            var stamp = 0
            // The documented removal of the edge at p.
            func detach(_ p: Int) {
                let e = edges[p]
                if e.u == e.v {
                    let hi = rows[e.u]!.lastIndex(of: p)!, lo = rows[e.u]!.firstIndex(of: p)!
                    for offset in [hi, lo] {
                        let last = rows[e.u]!.removeLast()
                        if offset < rows[e.u]!.count { rows[e.u]![offset] = last }
                    }
                } else {
                    for end in [e.u, e.v] {
                        let offset = rows[end]!.firstIndex(of: p)!
                        let last = rows[end]!.removeLast()
                        if offset < rows[end]!.count { rows[end]![offset] = last }
                    }
                }
                let lastPosition = edges.count - 1
                if p != lastPosition {
                    let moved = edges[lastPosition]
                    edges[p] = moved
                    for end in Set([moved.u, moved.v]) {
                        rows[end] = rows[end]!.map { $0 == lastPosition ? p : $0 }
                    }
                }
                edges.removeLast()
            }
            func copies(_ a: Int, _ b: Int) -> [Int] {
                edges.indices.filter { UndirectedEdge(edges[$0].u, edges[$0].v) == UndirectedEdge(a, b) }.sorted { edges[$0].stamp < edges[$1].stamp }
            }
            for (step, (kind, a, b, k)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0:
                    let result = graph.insert(a)
                    #expect(result.inserted == !vertices.contains(a) && result.memberAfterInsert == a, "\(context)")
                    if !vertices.contains(a) { vertices.append(a); rows[a] = [] }
                case 1, 2, 3, 4:
                    let p = graph.insert(edge: UndirectedEdge(a, b))
                    #expect(p == edges.count, "\(context)")
                    for x in [a, b] where !vertices.contains(x) { vertices.append(x); rows[x] = [] }
                    edges.append((a, b, stamp))
                    stamp += 1
                    rows[a]!.append(p)
                    rows[b]!.append(p)
                case 5, 6:
                    let removed = graph.remove(edge: UndirectedEdge(a, b))
                    if let newest = copies(a, b).last {
                        #expect(removed.map { [$0.u, $0.v] } == [edges[newest].u, edges[newest].v], "\(context)")
                        detach(newest)
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 7, 8:
                    if !edges.isEmpty {
                        let p = k % edges.count
                        let removed = graph.remove(edgeAt: p)
                        #expect([removed.u, removed.v] as [Int] == [edges[p].u, edges[p].v] as [Int], "\(context)")
                        detach(p)
                    }
                case 9:
                    let n = graph.removeAllEdges(between: a, and: b)
                    var count = 0
                    while let newest = copies(a, b).last { detach(newest); count += 1 }
                    #expect(n == count, "\(context)")
                case 10:
                    let removed = graph.remove(a)
                    if let slot = vertices.firstIndex(of: a) {
                        #expect(removed == a, "\(context)")
                        while let p = rows[a]!.last { detach(p) }
                        let last = vertices.removeLast()
                        if slot < vertices.count { vertices[slot] = last }
                        rows[a] = nil
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                default:
                    if k % 10 == 0 {
                        graph.removeAll(keepingCapacity: a == 0)
                        vertices = []; edges = []; rows = [:]
                    } else if k % 10 == 1 {
                        graph.removeAllEdges(keepingCapacity: a == 0)
                        edges = []
                        for v in vertices { rows[v] = [] }
                    }
                }

                // The whole state, after every step.
                #expect(Array(graph.vertices) == vertices, "\(context)")
                #expect(graph.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(context)")
                #expect(graph.vertexCount == vertices.count && graph.edgeCount == edges.count, "\(context)")
                for (i, v) in vertices.enumerated() {
                    let row = rows[v]!
                    #expect(Array(graph.incidentEdges(of: v)) == row, "\(v) at \(context)")
                    #expect(Array(graph.neighbors(of: v)) == row.map { UndirectedEdge(edges[$0].u, edges[$0].v).oppositeVertex(to: v) }, "\(v) at \(context)")
                    #expect(graph.degree(of: v) == row.count, "\(context)")
                    #expect(graph.vertexIndex(of: v) == i, "\(context)")
                    #expect(Array(graph.incidentEdgeIndices(ofIndex: i)) == row, "\(context)")
                    #expect(Array(graph.neighborIndices(ofIndex: i)) == graph.neighbors(of: v).map { vertices.firstIndex(of: $0)! }, "\(context)")
                }
                for x in 0 ... 6 {
                    #expect(graph.contains(x) == vertices.contains(x), "\(context)")
                    for y in x ... 6 {
                        let expected = copies(x, y)
                        #expect(Array(graph.edges(between: x, and: y)) == expected, "\(x)–\(y) at \(context)")
                        #expect(Array(graph.edges(between: y, and: x)) == expected, "\(context)")
                        #expect(graph.edgeCount(between: x, and: y) == expected.count, "\(context)")
                        #expect(graph.contains(edge: UndirectedEdge(y, x)) == !expected.isEmpty, "\(context)")
                    }
                }
                let rebuilt = Pseudograph<Int>(vertices: vertices.reversed(), edges: edges.reversed().map { UndirectedEdge($0.v, $0.u) })
                #expect(rebuilt == graph, "\(context)")
                #expect(rebuilt.hashValue == graph.hashValue, "\(context)")
            }

            // At the end: Codable and the conversion to the simple list.
            do {
                let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: JSONEncoder().encode(graph))
                #expect(decoded == graph)
                #expect(Array(decoded.vertices) == vertices)
                #expect(decoded.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] })
            } catch {
                Issue.record("round trip: \(error)")
            }
            var firsts: [[Int]] = []
            var seen: Set<UndirectedEdge<Int>> = []
            for e in edges where seen.insert(UndirectedEdge(e.u, e.v)).inserted { firsts.append([e.u, e.v]) }
            let simple = UndirectedAdjacencyList(graph)
            #expect(Array(simple.vertices) == vertices)
            #expect(simple.edges.map { [$0.u, $0.v] } == firsts)
        }
    }

    @Test("Multigraph: random operation sequences agree with the model after every step; loops are never inserted")
    func multigraphAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = Multigraph<Int>()
            var vertices: [Int] = []
            var edges: [(u: Int, v: Int, stamp: Int)] = []
            var rows: [Int: [Int]] = [:]
            var stamp = 0
            func detach(_ p: Int) {
                let e = edges[p]
                for end in [e.u, e.v] {
                    let offset = rows[end]!.firstIndex(of: p)!
                    let last = rows[end]!.removeLast()
                    if offset < rows[end]!.count { rows[end]![offset] = last }
                }
                let lastPosition = edges.count - 1
                if p != lastPosition {
                    let moved = edges[lastPosition]
                    edges[p] = moved
                    for end in [moved.u, moved.v] {
                        rows[end] = rows[end]!.map { $0 == lastPosition ? p : $0 }
                    }
                }
                edges.removeLast()
            }
            func copies(_ a: Int, _ b: Int) -> [Int] {
                edges.indices.filter { UndirectedEdge(edges[$0].u, edges[$0].v) == UndirectedEdge(a, b) }.sorted { edges[$0].stamp < edges[$1].stamp }
            }
            for (step, (kind, a, rawB, k)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let b = rawB == a ? (a + 1) % 6 : rawB
                switch kind {
                case 0:
                    let result = graph.insert(a)
                    #expect(result.inserted == !vertices.contains(a), "\(context)")
                    if !vertices.contains(a) { vertices.append(a); rows[a] = [] }
                case 1, 2, 3, 4:
                    let p = graph.insert(edge: UndirectedEdge(a, b))
                    #expect(p == edges.count, "\(context)")
                    for x in [a, b] where !vertices.contains(x) { vertices.append(x); rows[x] = [] }
                    edges.append((a, b, stamp))
                    stamp += 1
                    rows[a]!.append(p)
                    rows[b]!.append(p)
                case 5, 6:
                    let removed = graph.remove(edge: UndirectedEdge(b, a))
                    if let newest = copies(a, b).last {
                        #expect(removed.map { [$0.u, $0.v] } == [edges[newest].u, edges[newest].v], "\(context)")
                        detach(newest)
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 7, 8:
                    if !edges.isEmpty {
                        let p = k % edges.count
                        let removed = graph.remove(edgeAt: p)
                        #expect([removed.u, removed.v] as [Int] == [edges[p].u, edges[p].v] as [Int], "\(context)")
                        detach(p)
                    }
                case 9:
                    let n = graph.removeAllEdges(between: a, and: b)
                    var count = 0
                    while let newest = copies(a, b).last { detach(newest); count += 1 }
                    #expect(n == count, "\(context)")
                case 10:
                    let removed = graph.remove(a)
                    if let slot = vertices.firstIndex(of: a) {
                        #expect(removed == a, "\(context)")
                        while let p = rows[a]!.last { detach(p) }
                        let last = vertices.removeLast()
                        if slot < vertices.count { vertices[slot] = last }
                        rows[a] = nil
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                default:
                    if k % 10 == 0 {
                        graph.removeAll()
                        vertices = []; edges = []; rows = [:]
                    } else if k % 10 == 1 {
                        graph.removeAllEdges()
                        edges = []
                        for v in vertices { rows[v] = [] }
                    }
                }

                #expect(Array(graph.vertices) == vertices, "\(context)")
                #expect(graph.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] }, "\(context)")
                #expect(graph.edges.allSatisfy { !$0.isSelfLoop })
                for (i, v) in vertices.enumerated() {
                    let row = rows[v]!
                    #expect(Array(graph.incidentEdges(of: v)) == row, "\(v) at \(context)")
                    #expect(Array(graph.neighbors(of: v)) == row.map { UndirectedEdge(edges[$0].u, edges[$0].v).oppositeVertex(to: v) }, "\(context)")
                    #expect(graph.degree(of: v) == row.count && graph.vertexIndex(of: v) == i, "\(context)")
                }
                for x in 0 ... 6 {
                    for y in x ... 6 {
                        let expected = copies(x, y)
                        #expect(Array(graph.edges(between: x, and: y)) == expected, "\(x)–\(y) at \(context)")
                        #expect(graph.edgeCount(between: y, and: x) == expected.count, "\(context)")
                        #expect(graph.contains(edge: UndirectedEdge(x, y)) == !expected.isEmpty, "\(context)")
                    }
                }
                let rebuilt = Multigraph<Int>(vertices: vertices.shuffled(), edges: edges.shuffled().map { UndirectedEdge($0.v, $0.u) })
                #expect(rebuilt == graph, "\(context)")
                #expect(rebuilt?.hashValue == graph.hashValue, "\(context)")
                #expect(Pseudograph(graph) == Pseudograph<Int>(vertices: vertices, edges: edges.map { UndirectedEdge($0.u, $0.v) }), "\(context)")
            }
            do {
                let decoded = try JSONDecoder().decode(Multigraph<Int>.self, from: JSONEncoder().encode(graph))
                #expect(decoded == graph)
                #expect(decoded.edges.map { [$0.u, $0.v] } == edges.map { [$0.u, $0.v] })
            } catch {
                Issue.record("round trip: \(error)")
            }
        }
    }

    @Test("DirectedPseudograph: random operation sequences agree with the model after every step")
    func directedPseudographAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = DirectedPseudograph<Int>()
            var vertices: [Int] = []
            var edges: [(source: Int, target: Int, stamp: Int)] = []
            var outRows: [Int: [Int]] = [:]
            var inRows: [Int: [Int]] = [:]
            var stamp = 0
            func detach(_ p: Int) {
                let e = edges[p]
                do {
                    let offset = outRows[e.source]!.firstIndex(of: p)!
                    let last = outRows[e.source]!.removeLast()
                    if offset < outRows[e.source]!.count { outRows[e.source]![offset] = last }
                }
                do {
                    let offset = inRows[e.target]!.firstIndex(of: p)!
                    let last = inRows[e.target]!.removeLast()
                    if offset < inRows[e.target]!.count { inRows[e.target]![offset] = last }
                }
                let lastPosition = edges.count - 1
                if p != lastPosition {
                    let moved = edges[lastPosition]
                    edges[p] = moved
                    outRows[moved.source] = outRows[moved.source]!.map { $0 == lastPosition ? p : $0 }
                    inRows[moved.target] = inRows[moved.target]!.map { $0 == lastPosition ? p : $0 }
                }
                edges.removeLast()
            }
            func copies(_ a: Int, _ b: Int) -> [Int] {
                edges.indices.filter { edges[$0].source == a && edges[$0].target == b }.sorted { edges[$0].stamp < edges[$1].stamp }
            }
            for (step, (kind, a, b, k)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0:
                    let result = graph.insert(a)
                    #expect(result.inserted == !vertices.contains(a), "\(context)")
                    if !vertices.contains(a) { vertices.append(a); outRows[a] = []; inRows[a] = [] }
                case 1, 2, 3, 4:
                    let p = graph.insert(edge: DirectedEdge(from: a, to: b))
                    #expect(p == edges.count, "\(context)")
                    for x in [a, b] where !vertices.contains(x) { vertices.append(x); outRows[x] = []; inRows[x] = [] }
                    edges.append((a, b, stamp))
                    stamp += 1
                    outRows[a]!.append(p)
                    inRows[b]!.append(p)
                case 5, 6:
                    let removed = graph.remove(edge: DirectedEdge(from: a, to: b))
                    if let newest = copies(a, b).last {
                        #expect(removed == DirectedEdge(from: a, to: b), "\(context)")
                        detach(newest)
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 7, 8:
                    if !edges.isEmpty {
                        let p = k % edges.count
                        let removed = graph.remove(edgeAt: p)
                        #expect(removed == DirectedEdge(from: edges[p].source, to: edges[p].target), "\(context)")
                        detach(p)
                    }
                case 9:
                    let n = graph.removeAllEdges(from: a, to: b)
                    var count = 0
                    while let newest = copies(a, b).last { detach(newest); count += 1 }
                    #expect(n == count, "\(context)")
                case 10:
                    let removed = graph.remove(a)
                    if let slot = vertices.firstIndex(of: a) {
                        #expect(removed == a, "\(context)")
                        while let p = outRows[a]!.last { detach(p) }
                        while let p = inRows[a]!.last { detach(p) }
                        let last = vertices.removeLast()
                        if slot < vertices.count { vertices[slot] = last }
                        outRows[a] = nil
                        inRows[a] = nil
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                default:
                    if k % 10 == 0 {
                        graph.removeAll()
                        vertices = []; edges = []; outRows = [:]; inRows = [:]
                    } else if k % 10 == 1 {
                        graph.removeAllEdges()
                        edges = []
                        for v in vertices { outRows[v] = []; inRows[v] = [] }
                    }
                }

                #expect(Array(graph.vertices) == vertices, "\(context)")
                #expect(graph.edges.map { [$0.source, $0.target] } == edges.map { [$0.source, $0.target] }, "\(context)")
                #expect(graph.vertexCount == vertices.count && graph.edgeCount == edges.count, "\(context)")
                for (i, v) in vertices.enumerated() {
                    #expect(Array(graph.outEdges(of: v)) == outRows[v]!, "\(v) at \(context)")
                    #expect(Array(graph.inEdges(of: v)) == inRows[v]!, "\(v) at \(context)")
                    #expect(Array(graph.successors(of: v)) == outRows[v]!.map { edges[$0].target }, "\(context)")
                    #expect(Array(graph.predecessors(of: v)) == inRows[v]!.map { edges[$0].source }, "\(context)")
                    #expect(graph.outDegree(of: v) == outRows[v]!.count && graph.inDegree(of: v) == inRows[v]!.count, "\(context)")
                    #expect(graph.degree(of: v) == outRows[v]!.count + inRows[v]!.count, "\(context)")
                    #expect(graph.vertexIndex(of: v) == i, "\(context)")
                    #expect(Array(graph.outEdges(ofIndex: i)) == outRows[v]! && Array(graph.inEdges(ofIndex: i)) == inRows[v]!, "\(context)")
                    #expect(Array(graph.successorIndices(ofIndex: i)) == graph.successors(of: v).map { vertices.firstIndex(of: $0)! }, "\(context)")
                    #expect(Array(graph.predecessorIndices(ofIndex: i)) == graph.predecessors(of: v).map { vertices.firstIndex(of: $0)! }, "\(context)")
                }
                for x in 0 ... 6 {
                    for y in 0 ... 6 {
                        let expected = copies(x, y)
                        #expect(Array(graph.edges(from: x, to: y)) == expected, "\(x)→\(y) at \(context)")
                        #expect(graph.edgeCount(from: x, to: y) == expected.count, "\(context)")
                        #expect(graph.contains(edge: DirectedEdge(from: x, to: y)) == !expected.isEmpty, "\(context)")
                    }
                }
                let rebuilt = DirectedPseudograph<Int>(vertices: vertices.shuffled(), edges: edges.shuffled().map { DirectedEdge(from: $0.source, to: $0.target) })
                #expect(rebuilt == graph, "\(context)")
                #expect(rebuilt.hashValue == graph.hashValue, "\(context)")
            }
            do {
                let decoded = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: JSONEncoder().encode(graph))
                #expect(decoded == graph)
                #expect(Array(decoded.vertices) == vertices)
                #expect(decoded.edges.map { [$0.source, $0.target] } == edges.map { [$0.source, $0.target] })
            } catch {
                Issue.record("round trip: \(error)")
            }
            var firsts: [[Int]] = []
            var seen: Set<DirectedEdge<Int>> = []
            for e in edges where seen.insert(DirectedEdge(from: e.source, to: e.target)).inserted { firsts.append([e.source, e.target]) }
            let simple = AdjacencyList(graph)
            #expect(Array(simple.vertices) == vertices)
            #expect(simple.edges.map { [$0.source, $0.target] } == firsts)
        }
    }

    @Test("DirectedMultigraph: random operation sequences agree with the model after every step; loops are never inserted")
    func directedMultigraphAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = DirectedMultigraph<Int>()
            var vertices: [Int] = []
            var edges: [(source: Int, target: Int, stamp: Int)] = []
            var outRows: [Int: [Int]] = [:]
            var inRows: [Int: [Int]] = [:]
            var stamp = 0
            func detach(_ p: Int) {
                let e = edges[p]
                do {
                    let offset = outRows[e.source]!.firstIndex(of: p)!
                    let last = outRows[e.source]!.removeLast()
                    if offset < outRows[e.source]!.count { outRows[e.source]![offset] = last }
                }
                do {
                    let offset = inRows[e.target]!.firstIndex(of: p)!
                    let last = inRows[e.target]!.removeLast()
                    if offset < inRows[e.target]!.count { inRows[e.target]![offset] = last }
                }
                let lastPosition = edges.count - 1
                if p != lastPosition {
                    let moved = edges[lastPosition]
                    edges[p] = moved
                    outRows[moved.source] = outRows[moved.source]!.map { $0 == lastPosition ? p : $0 }
                    inRows[moved.target] = inRows[moved.target]!.map { $0 == lastPosition ? p : $0 }
                }
                edges.removeLast()
            }
            func copies(_ a: Int, _ b: Int) -> [Int] {
                edges.indices.filter { edges[$0].source == a && edges[$0].target == b }.sorted { edges[$0].stamp < edges[$1].stamp }
            }
            for (step, (kind, a, rawB, k)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let b = rawB == a ? (a + 1) % 6 : rawB
                switch kind {
                case 0:
                    let result = graph.insert(a)
                    #expect(result.inserted == !vertices.contains(a), "\(context)")
                    if !vertices.contains(a) { vertices.append(a); outRows[a] = []; inRows[a] = [] }
                case 1, 2, 3, 4:
                    let p = graph.insert(edge: DirectedEdge(from: a, to: b))
                    #expect(p == edges.count, "\(context)")
                    for x in [a, b] where !vertices.contains(x) { vertices.append(x); outRows[x] = []; inRows[x] = [] }
                    edges.append((a, b, stamp))
                    stamp += 1
                    outRows[a]!.append(p)
                    inRows[b]!.append(p)
                case 5, 6:
                    let removed = graph.remove(edge: DirectedEdge(from: a, to: b))
                    if let newest = copies(a, b).last {
                        #expect(removed == DirectedEdge(from: a, to: b), "\(context)")
                        detach(newest)
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 7, 8:
                    if !edges.isEmpty {
                        let p = k % edges.count
                        let removed = graph.remove(edgeAt: p)
                        #expect(removed == DirectedEdge(from: edges[p].source, to: edges[p].target), "\(context)")
                        detach(p)
                    }
                case 9:
                    let n = graph.removeAllEdges(from: a, to: b)
                    var count = 0
                    while let newest = copies(a, b).last { detach(newest); count += 1 }
                    #expect(n == count, "\(context)")
                case 10:
                    let removed = graph.remove(a)
                    if let slot = vertices.firstIndex(of: a) {
                        #expect(removed == a, "\(context)")
                        while let p = outRows[a]!.last { detach(p) }
                        while let p = inRows[a]!.last { detach(p) }
                        let last = vertices.removeLast()
                        if slot < vertices.count { vertices[slot] = last }
                        outRows[a] = nil
                        inRows[a] = nil
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                default:
                    if k % 10 == 0 {
                        graph.removeAll()
                        vertices = []; edges = []; outRows = [:]; inRows = [:]
                    } else if k % 10 == 1 {
                        graph.removeAllEdges()
                        edges = []
                        for v in vertices { outRows[v] = []; inRows[v] = [] }
                    }
                }

                #expect(Array(graph.vertices) == vertices, "\(context)")
                #expect(graph.edges.map { [$0.source, $0.target] } == edges.map { [$0.source, $0.target] }, "\(context)")
                #expect(graph.edges.allSatisfy { !$0.isSelfLoop })
                for v in vertices {
                    #expect(Array(graph.outEdges(of: v)) == outRows[v]!, "\(v) at \(context)")
                    #expect(Array(graph.inEdges(of: v)) == inRows[v]!, "\(v) at \(context)")
                    #expect(Array(graph.successors(of: v)) == outRows[v]!.map { edges[$0].target }, "\(context)")
                    #expect(Array(graph.predecessors(of: v)) == inRows[v]!.map { edges[$0].source }, "\(context)")
                }
                for x in 0 ... 6 {
                    for y in 0 ... 6 {
                        let expected = copies(x, y)
                        #expect(Array(graph.edges(from: x, to: y)) == expected, "\(x)→\(y) at \(context)")
                        #expect(graph.edgeCount(from: x, to: y) == expected.count, "\(context)")
                    }
                }
                let rebuilt = DirectedMultigraph<Int>(vertices: vertices.shuffled(), edges: edges.shuffled().map { DirectedEdge(from: $0.source, to: $0.target) })
                #expect(rebuilt == graph, "\(context)")
                #expect(rebuilt?.hashValue == graph.hashValue, "\(context)")
            }
            do {
                let decoded = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: JSONEncoder().encode(graph))
                #expect(decoded == graph)
                #expect(decoded.edges.map { [$0.source, $0.target] } == edges.map { [$0.source, $0.target] })
            } catch {
                Issue.record("round trip: \(error)")
            }
        }
    }

    @Test("The Graph laws hold on random pseudographs and multigraphs after random removals")
    func undirectedLawsOnRandomGraphs() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pseudograph = Pseudograph<Int>(vertices: [9], edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var multigraph = Multigraph<Int>(vertices: [9], edges: raw.filter { $0.0 != $0.1 }.map { UndirectedEdge($0.0, $0.1) })
            for _ in 0 ..< Int.random(in: 0 ... 4, using: &rng) {
                switch Int.random(in: 0 ... 2, using: &rng) {
                case 0:
                    if pseudograph.edgeCount > 0 { pseudograph.remove(edgeAt: Int.random(in: 0 ..< pseudograph.edgeCount, using: &rng)) }
                    if let m = multigraph, m.edgeCount > 0 { multigraph?.remove(edgeAt: Int.random(in: 0 ..< m.edgeCount, using: &rng)) }
                case 1:
                    let v = Int.random(in: 0 ... 9, using: &rng)
                    pseudograph.remove(v)
                    multigraph?.remove(v)
                default:
                    let (a, b) = (Int.random(in: 0 ... 7, using: &rng), Int.random(in: 0 ... 7, using: &rng))
                    pseudograph.remove(edge: UndirectedEdge(a, b))
                    multigraph?.removeAllEdges(between: a, and: b)
                }
            }
            #expect(multigraph != nil)
            let graphs: [(String, Pseudograph<Int>)] = [("pseudograph", pseudograph), ("multigraph", multigraph.map { Pseudograph($0) } ?? Pseudograph())]
            for (name, graph) in graphs {
                let vertices = Array(graph.vertices)
                let all = Array(graph.edges)
                var degreeSum = 0
                var ends = [Int](repeating: 0, count: all.count)
                for (i, v) in vertices.enumerated() {
                    let incident = Array(graph.incidentEdges(of: v))
                    #expect(Array(graph.neighbors(of: v)) == incident.map { all[$0].oppositeVertex(to: v) }, "\(name)")
                    #expect(incident.allSatisfy { all[$0].u == v || all[$0].v == v }, "\(name)")
                    #expect(incident.filter { all[$0].isSelfLoop }.count.isMultiple(of: 2), "\(name)")
                    #expect(graph.vertexIndex(of: v) == i && graph.vertex(atIndex: i) == v, "\(name)")
                    #expect(Array(graph.neighborIndices(ofIndex: i)) == graph.neighbors(of: v).map { graph.vertexIndex(of: $0) }, "\(name)")
                    for p in incident { ends[p] += 1 }
                    degreeSum += graph.degree(of: v)
                }
                #expect(ends.allSatisfy { $0 == 2 }, "\(name)")
                #expect(degreeSum == 2 * graph.edgeCount, "\(name)")
                var total = 0
                for (k, a) in vertices.enumerated() {
                    for b in vertices[k...] {
                        let copies = Array(graph.edges(between: a, and: b))
                        #expect(copies.sorted() == all.indices.filter { all[$0] == UndirectedEdge(a, b) }, "\(name) \(a)–\(b)")
                        #expect(graph.edgeCount(between: a, and: b) == copies.count, "\(name)")
                        total += copies.count
                    }
                }
                #expect(total == all.count, "\(name)")
            }
            if let multigraph {
                #expect(multigraph.edges.allSatisfy { !$0.isSelfLoop })
                #expect(Array(multigraph.vertices) == Array(Pseudograph(multigraph).vertices))
            }
        }
    }

    @Test("The BidirectionalDirectedGraph laws hold on random directed pseudographs after random removals")
    func directedLawsOnRandomGraphs() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var graph = DirectedPseudograph<Int>(edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            for _ in 0 ..< Int.random(in: 0 ... 4, using: &rng) {
                if Bool.random(using: &rng), graph.edgeCount > 0 {
                    graph.remove(edgeAt: Int.random(in: 0 ..< graph.edgeCount, using: &rng))
                } else {
                    graph.remove(Int.random(in: 0 ... 7, using: &rng))
                }
            }
            let vertices = Array(graph.vertices)
            let all = Array(graph.edges)
            var outSum = 0, inSum = 0
            for (i, v) in vertices.enumerated() {
                let out = Array(graph.outEdges(of: v)), into = Array(graph.inEdges(of: v))
                #expect(out.sorted() == all.indices.filter { all[$0].source == v })
                #expect(into.sorted() == all.indices.filter { all[$0].target == v })
                #expect(Array(graph.successors(of: v)) == out.map { all[$0].target })
                #expect(Array(graph.predecessors(of: v)) == into.map { all[$0].source })
                #expect(graph.degree(of: v) == out.count + into.count)
                #expect(Array(graph.successorIndices(ofIndex: i)) == graph.successors(of: v).map { graph.vertexIndex(of: $0) })
                #expect(Array(graph.predecessorIndices(ofIndex: i)) == graph.predecessors(of: v).map { graph.vertexIndex(of: $0) })
                outSum += out.count
                inSum += into.count
                for w in vertices {
                    #expect(Array(graph.edges(from: v, to: w)).sorted() == all.indices.filter { all[$0] == DirectedEdge(from: v, to: w) })
                }
            }
            #expect(outSum == all.count && inSum == all.count)
            for p in all.indices { #expect(graph.source(ofEdgeAt: p) == all[p].source && graph.target(ofEdgeAt: p) == all[p].target) }
        }
    }

    @Test("Equality and hashing ignore vertex order, edge order and (undirected) orientation, and see every copy")
    func equalityIgnoresOrders() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.bool).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let vertices = Array(0 ... 6)
            let undirected = raw.map { UndirectedEdge($0.0, $0.1) }
            let graph = Pseudograph<Int>(vertices: vertices, edges: undirected)
            let shuffled = Pseudograph<Int>(vertices: vertices.shuffled(using: &rng), edges: raw.shuffled(using: &rng).map { $0.2 ? UndirectedEdge($0.1, $0.0) : UndirectedEdge($0.0, $0.1) })
            #expect(graph == shuffled)
            #expect(graph.hashValue == shuffled.hashValue)
            var extra = shuffled
            extra.insert(edge: undirected.first ?? UndirectedEdge(0, 1))
            #expect(extra != graph)
            if !undirected.isEmpty {
                var fewer = shuffled
                fewer.remove(edgeAt: Int.random(in: 0 ..< fewer.edgeCount, using: &rng))
                #expect(fewer != graph)
                // Removing one copy and inserting it back, in the other orientation, restores equality.
                var back = graph
                let removed = back.remove(edgeAt: Int.random(in: 0 ..< back.edgeCount, using: &rng))
                back.insert(edge: UndirectedEdge(removed.v, removed.u))
                #expect(back == graph && back.hashValue == graph.hashValue)
            }
            let arcs = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            let digraph = DirectedPseudograph<Int>(vertices: vertices, edges: arcs)
            let digraphShuffled = DirectedPseudograph<Int>(vertices: vertices.shuffled(using: &rng), edges: arcs.shuffled(using: &rng))
            #expect(digraph == digraphShuffled && digraph.hashValue == digraphShuffled.hashValue)
            // Reversing every arc gives an equal graph exactly when the arc multiset is symmetric.
            let reversed = DirectedPseudograph<Int>(vertices: vertices, edges: arcs.map { DirectedEdge(from: $0.target, to: $0.source) })
            var counts: [DirectedEdge<Int>: Int] = [:]
            for arc in arcs { counts[arc, default: 0] += 1 }
            let symmetric = counts.allSatisfy { counts[DirectedEdge(from: $0.key.target, to: $0.key.source)] == $0.value }
            #expect((reversed == digraph) == symmetric)
            // Vertex sets matter.
            #expect(graph != Pseudograph<Int>(vertices: vertices + [7], edges: undirected))
            #expect(Multigraph<Int>(vertices: vertices, edges: undirected.filter { !$0.isSelfLoop }) == Multigraph<Int>(vertices: vertices.reversed(), edges: undirected.filter { !$0.isSelfLoop }.reversed()))
        }
    }

    @Test("Codable round trips keep vertices and positions; decoded rows are in position order (the reference conformer's)")
    func codableRoundTrips() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 25)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var graph = Pseudograph<Int>(edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var digraph = DirectedPseudograph<Int>(edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            for _ in 0 ..< 3 where graph.edgeCount > 0 {
                graph.remove(edgeAt: Int.random(in: 0 ..< graph.edgeCount, using: &rng))
                digraph.remove(edgeAt: Int.random(in: 0 ..< digraph.edgeCount, using: &rng))
            }
            if Bool.random(using: &rng) { graph.remove(Int.random(in: 0 ... 5, using: &rng)) }
            if Bool.random(using: &rng) { digraph.remove(Int.random(in: 0 ... 5, using: &rng)) }
            do {
                let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: JSONEncoder().encode(graph))
                #expect(decoded == graph)
                #expect(Array(decoded.vertices) == Array(graph.vertices))
                #expect(decoded.edges.map { [$0.u, $0.v] } == graph.edges.map { [$0.u, $0.v] })
                let reference = ReferencePseudograph(vertices: Array(graph.vertices), edges: Array(graph.edges))
                for v in decoded.vertices {
                    #expect(Array(decoded.incidentEdges(of: v)) == reference.incidentEdges(of: v))
                    // The same incidences as before, whatever the order.
                    #expect(Array(decoded.incidentEdges(of: v)).sorted() == Array(graph.incidentEdges(of: v)).sorted())
                }
                let directed = try PropertyListDecoder().decode(DirectedPseudograph<Int>.self, from: PropertyListEncoder().encode(digraph))
                #expect(directed == digraph)
                #expect(Array(directed.vertices) == Array(digraph.vertices))
                #expect(directed.edges.map { [$0.source, $0.target] } == digraph.edges.map { [$0.source, $0.target] })
                let directedReference = ReferenceDirectedMultigraph(vertices: Array(digraph.vertices), edges: Array(digraph.edges))
                for v in directed.vertices {
                    #expect(Array(directed.outEdges(of: v)) == directedReference.outEdges(of: v))
                    #expect(Array(directed.inEdges(of: v)) == directedReference.inEdges(of: v))
                }
                // The multigraphs accept exactly the loop-free payloads.
                let asMultigraph = try? JSONDecoder().decode(Multigraph<Int>.self, from: JSONEncoder().encode(graph))
                #expect((asMultigraph != nil) == !graph.edges.contains { $0.isSelfLoop })
                let asDirectedMultigraph = try? JSONDecoder().decode(DirectedMultigraph<Int>.self, from: JSONEncoder().encode(digraph))
                #expect((asDirectedMultigraph != nil) == !digraph.edges.contains { $0.isSelfLoop })
            } catch {
                Issue.record("round trip: \(error)")
            }
        }
    }

    @Test("Conversions to the simple lists keep each pair's first copy by position, in its orientation; simple graphs convert both ways")
    func collapseToSimpleLists() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 25)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var graph = Pseudograph<Int>(vertices: [8], edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var digraph = DirectedPseudograph<Int>(vertices: [8], edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            for _ in 0 ..< 3 where graph.edgeCount > 0 {
                graph.remove(edgeAt: Int.random(in: 0 ..< graph.edgeCount, using: &rng))
                digraph.remove(edgeAt: Int.random(in: 0 ..< digraph.edgeCount, using: &rng))
            }
            var firsts: [[Int]] = []
            var seen: Set<UndirectedEdge<Int>> = []
            for e in graph.edges where seen.insert(e).inserted { firsts.append([e.u, e.v]) }
            let simple = UndirectedAdjacencyList(graph)
            #expect(Array(simple.vertices) == Array(graph.vertices))
            #expect(simple.edges.map { [$0.u, $0.v] } == firsts)
            for v in graph.vertices { #expect(Set(simple.neighbors(of: v)) == Set(graph.neighbors(of: v))) }
            if let multigraph = Multigraph(graph) {
                #expect(UndirectedAdjacencyList(multigraph) == simple)
                #expect(Array(multigraph.vertices) == Array(graph.vertices))
            } else {
                #expect(graph.edges.contains { $0.isSelfLoop })
            }

            var arcFirsts: [[Int]] = []
            var arcSeen: Set<DirectedEdge<Int>> = []
            for e in digraph.edges where arcSeen.insert(e).inserted { arcFirsts.append([e.source, e.target]) }
            let list = AdjacencyList(digraph)
            #expect(Array(list.vertices) == Array(digraph.vertices))
            #expect(list.edges.map { [$0.source, $0.target] } == arcFirsts)

            // A simple graph converts to a pseudograph and back unchanged, positions included.
            let back = UndirectedAdjacencyList(Pseudograph(simple))
            #expect(back == simple)
            #expect(back.edges.map { [$0.u, $0.v] } == simple.edges.map { [$0.u, $0.v] })
            #expect(Array(back.vertices) == Array(simple.vertices))
            let directedBack = AdjacencyList(DirectedPseudograph(list))
            #expect(directedBack == list)
            #expect(directedBack.edges.map { [$0.source, $0.target] } == list.edges.map { [$0.source, $0.target] })
            // The pseudograph of a simple list has its positions; rows hold the same entries.
            let lifted = Pseudograph(simple)
            #expect(lifted.edges.map { [$0.u, $0.v] } == simple.edges.map { [$0.u, $0.v] })
            for v in simple.vertices {
                #expect(Array(lifted.incidentEdges(of: v)).sorted() == Array(simple.incidentEdges(of: v)).sorted())
                #expect(lifted.edges(between: v, and: v).count <= 1)
            }
        }
    }

    @Test("Built by init(vertices:edges:), the pseudographs are the reference conformers: vertices, positions, rows")
    func dropInForReferenceConformers() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 9).array(of: 0 ... 4)) { raw, listed in
            let undirected = raw.map { UndirectedEdge($0.0, $0.1) }
            let graph = Pseudograph<Int>(vertices: listed, edges: undirected)
            let reference = ReferencePseudograph(vertices: listed, edges: undirected)
            #expect(Array(graph.vertices) == reference.vertices)
            #expect(graph.edges.map { [$0.u, $0.v] } == reference.edges.map { [$0.u, $0.v] })
            for v in reference.vertices {
                #expect(Array(graph.incidentEdges(of: v)) == reference.incidentEdges(of: v))
                #expect(Array(graph.neighbors(of: v)) == reference.neighbors(of: v))
                #expect(Array(graph.neighborIndices(ofIndex: graph.vertexIndex(of: v))) == Array(reference.neighborIndices(ofIndex: reference.vertexIndex(of: v))))
            }
            let built = Pseudograph<Int>(reference)
            #expect(Array(built.vertices) == reference.vertices)
            for v in reference.vertices { #expect(Array(built.incidentEdges(of: v)) == reference.incidentEdges(of: v)) }

            let arcs = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            let digraph = DirectedPseudograph<Int>(vertices: listed, edges: arcs)
            let directedReference = ReferenceDirectedMultigraph(vertices: listed, edges: arcs)
            #expect(Array(digraph.vertices) == directedReference.vertices)
            #expect(digraph.edges.map { [$0.source, $0.target] } == directedReference.edges.map { [$0.source, $0.target] })
            for v in directedReference.vertices {
                #expect(Array(digraph.outEdges(of: v)) == directedReference.outEdges(of: v))
                #expect(Array(digraph.inEdges(of: v)) == directedReference.inEdges(of: v))
                #expect(Array(digraph.successors(of: v)) == directedReference.successors(of: v))
                #expect(Array(digraph.predecessors(of: v)) == directedReference.predecessors(of: v))
            }
            // Without loops, the multigraphs too.
            let loopless = undirected.filter { !$0.isSelfLoop }
            if let multigraph = Multigraph<Int>(vertices: listed, edges: loopless) {
                let looplessReference = ReferencePseudograph(vertices: listed, edges: loopless)
                for v in looplessReference.vertices { #expect(Array(multigraph.incidentEdges(of: v)) == looplessReference.incidentEdges(of: v)) }
            } else {
                Issue.record("a loop-free multigraph was not built")
            }
            #expect(Multigraph<Int>(vertices: listed, edges: undirected) == nil || !undirected.contains { $0.isSelfLoop })
            #expect(DirectedMultigraph<Int>(vertices: listed, edges: arcs) == nil || !arcs.contains { $0.isSelfLoop })
        }
    }
}
