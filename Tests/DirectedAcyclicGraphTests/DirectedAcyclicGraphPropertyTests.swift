// Properties with shrinking (swift-property-based). Random operation sequences on each of the three
// bases run against a model written out beside the graph: the vertex set, the multiset of arcs (a set
// on AdjacencyList), and the order, maintained from the definitions. An edge u -> v is rejected exactly
// when it is a self-loop or v reaches u in the model; a rejected insert returns nil and changes nothing
// (equality, order, edges and positions all as before), and its witness, Traversal's
// `bidirectionalShortestPath(from: v, to: u)`, is a genuine path of the graph as short as the model's
// distance. An accepted backward edge moves B then F into their pooled places, where F is v and its
// descendants placed before u and B is u and its ancestors placed after v; nothing placed outside the
// endpoints' range moves. After every step the order must equal the model's, every edge must go
// forward, and the graph must be acyclic. Then random bulk builds against Kahn's algorithm, and Codable
// round trips. See README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Traversal
import Walks

@Suite("DirectedAcyclicGraph properties against a model, with shrinking", .tags(.randomized))
struct DirectedAcyclicGraphPropertyTests {
    @Test("Random mutation sequences on AdjacencyList agree with the model after every step")
    func mutationAgainstModelOnAdjacencyList() async {
        let operations = zip(Gen.int(in: 0 ... 13), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            var graph = DirectedAcyclicGraph<AdjacencyList<Int>>()
            var vertices = Set<Int>()
            var arcs: [DirectedEdge<Int>] = []
            var order: [Int] = []
            func descendants(of start: Int) -> Set<Int> {
                var seen = Set<Int>(), stack = [start]
                while let w = stack.popLast() {
                    for arc in arcs where arc.source == w && !seen.contains(arc.target) {
                        seen.insert(arc.target)
                        stack.append(arc.target)
                    }
                }
                return seen
            }
            func ancestors(of start: Int) -> Set<Int> {
                var seen = Set<Int>(), stack = [start]
                while let w = stack.popLast() {
                    for arc in arcs where arc.target == w && !seen.contains(arc.source) {
                        seen.insert(arc.source)
                        stack.append(arc.source)
                    }
                }
                return seen
            }
            func distance(from a: Int, to b: Int) -> Int? {
                var level = [a], seen: Set<Int> = [a], d = 0
                while !level.isEmpty {
                    if level.contains(b) { return d }
                    var next: [Int] = []
                    for w in level {
                        for arc in arcs where arc.source == w && !seen.contains(arc.target) {
                            seen.insert(arc.target)
                            next.append(arc.target)
                        }
                    }
                    level = next
                    d += 1
                }
                return nil
            }
            // Pearce-Kelly from the definitions: for an accepted u -> v with v placed before u, the
            // forward set F (v and its descendants placed before u) and the backward set B (u and its
            // ancestors placed after v), B then F, each by old place, take their pooled places.
            func accept(_ u: Int, _ v: Int) {
                let place = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
                if place[u]! > place[v]! {
                    let forward = descendants(of: v).union([v]).filter { place[$0]! < place[u]! }
                    let backward = ancestors(of: u).union([u]).filter { place[$0]! > place[v]! }
                    let moved = backward.sorted { place[$0]! < place[$1]! } + forward.sorted { place[$0]! < place[$1]! }
                    for (w, slot) in zip(moved, moved.map { place[$0]! }.sorted()) { order[slot] = w }
                }
                if !arcs.contains(DirectedEdge(from: u, to: v)) { arcs.append(DirectedEdge(from: u, to: v)) }
            }
            for (step, (kind, x, y)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let edge = DirectedEdge(from: x, to: y)
                let before = graph
                switch kind {
                case 0:
                    let result = graph.insert(x)
                    #expect(result.inserted == !vertices.contains(x) && result.memberAfterInsert == x, "\(context)")
                    if vertices.insert(x).inserted { order.append(x) }
                case 1, 2, 3, 4, 5, 6:
                    let safe = kind == 6
                    let result = safe ? graph.insert(safe: edge) : graph.insert(edge: edge)
                    if safe && !(vertices.contains(x) && vertices.contains(y)) {
                        #expect(result == nil, "\(context)")
                    } else if x == y || (vertices.contains(x) && vertices.contains(y) && distance(from: y, to: x) != nil) {
                        // Rejected: nil, and nothing changes, not even a missing endpoint.
                        #expect(result == nil, "\(context)")
                        #expect(graph == before && Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                        #expect(Array(graph.edges) == Array(before.edges) && Array(graph.edges.indices) == Array(before.edges.indices), "\(context)")
                        if x != y, let witness = graph.bidirectionalShortestPath(from: y, to: x) {
                            // The witness is genuine: a shortest path from the target to the source.
                            #expect(witness.source == y && witness.target == x && witness.length == distance(from: y, to: x), "\(context)")
                            #expect(witness.edges.indices.allSatisfy { graph.source(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0] && graph.target(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0 + 1] }, "\(context)")
                        } else if x != y {
                            Issue.record("no witness: \(context)")
                        }
                    } else {
                        for w in [x, y] where vertices.insert(w).inserted { order.append(w) }
                        if let position = result {
                            #expect(graph.source(ofEdgeAt: position) == x && graph.target(ofEdgeAt: position) == y, "\(context)")
                        } else {
                            Issue.record("rejected an acyclic edge: \(context)")
                        }
                        let oldPlaces = Dictionary(uniqueKeysWithValues: before.topologicalOrder.enumerated().map { ($1, $0) })
                        accept(x, y)
                        // Nothing placed outside [place(y), place(x)] moves.
                        if let px = oldPlaces[x], let py = oldPlaces[y] {
                            for (place, w) in before.topologicalOrder.enumerated() where place < min(px, py) || place > max(px, py) {
                                #expect(graph.topologicalPosition(of: w) == place, "\(context)")
                            }
                        }
                    }
                case 7, 8:
                    let removed = graph.remove(x)
                    #expect(removed == (vertices.contains(x) ? x : nil), "\(context)")
                    if vertices.remove(x) != nil {
                        order.removeAll { $0 == x }
                        arcs.removeAll { $0.source == x || $0.target == x }
                    }
                case 9, 10:
                    let removed = graph.remove(edge: edge)
                    #expect(removed == (arcs.contains(edge) ? edge : nil), "\(context)")
                    if let last = arcs.lastIndex(of: edge) { arcs.remove(at: last) }
                    #expect(Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                case 11:
                    // AdjacencyList has no remove(edgeAt:): every edge removed through remove(edge:).
                    if let first = graph.edges.first {
                        #expect(graph.remove(edge: first) == first, "\(context)")
                        arcs.removeAll { $0 == first }
                    }
                case 12:
                    graph.removeAllEdges(keepingCapacity: x.isMultiple(of: 2))
                    arcs.removeAll()
                default:
                    if x < 2 {
                        graph.removeAll(keepingCapacity: y.isMultiple(of: 2))
                        vertices.removeAll()
                        arcs.removeAll()
                        order.removeAll()
                    }
                }
                #expect(Set(graph.vertices) == vertices && graph.vertexCount == vertices.count, "\(context)")
                #expect(graph.edges.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) } == arcs.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) }, "\(context)")
                #expect(Array(graph.topologicalOrder) == order, "\(context)")
                // The laws: every edge goes forward, and the places agree with the order.
                #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) }, "\(context)")
                #expect(order.indices.allSatisfy { graph.topologicalPosition(of: order[$0]) == $0 && graph.topologicalPosition(safe: order[$0]) == $0 }, "\(context)")
                #expect(graph.isAcyclic, "\(context)")
            }
        }
    }

    @Test("Random mutation sequences on DirectedPseudograph agree with the model after every step")
    func mutationAgainstModelOnDirectedPseudograph() async {
        let operations = zip(Gen.int(in: 0 ... 13), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
            var vertices = Set<Int>()
            var arcs: [DirectedEdge<Int>] = []
            var order: [Int] = []
            func descendants(of start: Int) -> Set<Int> {
                var seen = Set<Int>(), stack = [start]
                while let w = stack.popLast() {
                    for arc in arcs where arc.source == w && !seen.contains(arc.target) {
                        seen.insert(arc.target)
                        stack.append(arc.target)
                    }
                }
                return seen
            }
            func ancestors(of start: Int) -> Set<Int> {
                var seen = Set<Int>(), stack = [start]
                while let w = stack.popLast() {
                    for arc in arcs where arc.target == w && !seen.contains(arc.source) {
                        seen.insert(arc.source)
                        stack.append(arc.source)
                    }
                }
                return seen
            }
            func distance(from a: Int, to b: Int) -> Int? {
                var level = [a], seen: Set<Int> = [a], d = 0
                while !level.isEmpty {
                    if level.contains(b) { return d }
                    var next: [Int] = []
                    for w in level {
                        for arc in arcs where arc.source == w && !seen.contains(arc.target) {
                            seen.insert(arc.target)
                            next.append(arc.target)
                        }
                    }
                    level = next
                    d += 1
                }
                return nil
            }
            // Pearce-Kelly from the definitions: for an accepted u -> v with v placed before u, the
            // forward set F (v and its descendants placed before u) and the backward set B (u and its
            // ancestors placed after v), B then F, each by old place, take their pooled places.
            func accept(_ u: Int, _ v: Int) {
                let place = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
                if place[u]! > place[v]! {
                    let forward = descendants(of: v).union([v]).filter { place[$0]! < place[u]! }
                    let backward = ancestors(of: u).union([u]).filter { place[$0]! > place[v]! }
                    let moved = backward.sorted { place[$0]! < place[$1]! } + forward.sorted { place[$0]! < place[$1]! }
                    for (w, slot) in zip(moved, moved.map { place[$0]! }.sorted()) { order[slot] = w }
                }
                arcs.append(DirectedEdge(from: u, to: v))
            }
            for (step, (kind, x, y)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let edge = DirectedEdge(from: x, to: y)
                let before = graph
                switch kind {
                case 0:
                    let result = graph.insert(x)
                    #expect(result.inserted == !vertices.contains(x) && result.memberAfterInsert == x, "\(context)")
                    if vertices.insert(x).inserted { order.append(x) }
                case 1, 2, 3, 4, 5, 6:
                    let safe = kind == 6
                    let result = safe ? graph.insert(safe: edge) : graph.insert(edge: edge)
                    if safe && !(vertices.contains(x) && vertices.contains(y)) {
                        #expect(result == nil, "\(context)")
                    } else if x == y || (vertices.contains(x) && vertices.contains(y) && distance(from: y, to: x) != nil) {
                        // Rejected: nil, and nothing changes, not even a missing endpoint.
                        #expect(result == nil, "\(context)")
                        #expect(graph == before && Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                        #expect(Array(graph.edges) == Array(before.edges) && Array(graph.edges.indices) == Array(before.edges.indices), "\(context)")
                        if x != y, let witness = graph.bidirectionalShortestPath(from: y, to: x) {
                            // The witness is genuine: a shortest path from the target to the source.
                            #expect(witness.source == y && witness.target == x && witness.length == distance(from: y, to: x), "\(context)")
                            #expect(witness.edges.indices.allSatisfy { graph.source(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0] && graph.target(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0 + 1] }, "\(context)")
                        } else if x != y {
                            Issue.record("no witness: \(context)")
                        }
                    } else {
                        for w in [x, y] where vertices.insert(w).inserted { order.append(w) }
                        if let position = result {
                            #expect(graph.source(ofEdgeAt: position) == x && graph.target(ofEdgeAt: position) == y, "\(context)")
                        } else {
                            Issue.record("rejected an acyclic edge: \(context)")
                        }
                        let oldPlaces = Dictionary(uniqueKeysWithValues: before.topologicalOrder.enumerated().map { ($1, $0) })
                        accept(x, y)
                        // Nothing placed outside [place(y), place(x)] moves.
                        if let px = oldPlaces[x], let py = oldPlaces[y] {
                            for (place, w) in before.topologicalOrder.enumerated() where place < min(px, py) || place > max(px, py) {
                                #expect(graph.topologicalPosition(of: w) == place, "\(context)")
                            }
                        }
                    }
                case 7, 8:
                    let removed = graph.remove(x)
                    #expect(removed == (vertices.contains(x) ? x : nil), "\(context)")
                    if vertices.remove(x) != nil {
                        order.removeAll { $0 == x }
                        arcs.removeAll { $0.source == x || $0.target == x }
                    }
                case 9, 10:
                    let removed = graph.remove(edge: edge)
                    #expect(removed == (arcs.contains(edge) ? edge : nil), "\(context)")
                    if let last = arcs.lastIndex(of: edge) { arcs.remove(at: last) }
                    #expect(Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                case 11:
                    let positions = Array(graph.edges.indices)
                    if !positions.isEmpty {
                        let position = positions[x % positions.count]
                        let expected = graph.edges[position]
                        #expect(graph.remove(edgeAt: position) == expected, "\(context)")
                        arcs.remove(at: arcs.firstIndex(of: expected)!)
                        #expect(Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                    }
                case 12:
                    graph.removeAllEdges(keepingCapacity: x.isMultiple(of: 2))
                    arcs.removeAll()
                default:
                    if x < 2 {
                        graph.removeAll(keepingCapacity: y.isMultiple(of: 2))
                        vertices.removeAll()
                        arcs.removeAll()
                        order.removeAll()
                    }
                }
                #expect(Set(graph.vertices) == vertices && graph.vertexCount == vertices.count, "\(context)")
                #expect(graph.edges.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) } == arcs.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) }, "\(context)")
                #expect(Array(graph.topologicalOrder) == order, "\(context)")
                // The laws: every edge goes forward, and the places agree with the order.
                #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) }, "\(context)")
                #expect(order.indices.allSatisfy { graph.topologicalPosition(of: order[$0]) == $0 && graph.topologicalPosition(safe: order[$0]) == $0 }, "\(context)")
                #expect(graph.isAcyclic, "\(context)")
            }
        }
    }

    @Test("Random mutation sequences on StableDirectedGraph agree with the model after every step")
    func mutationAgainstModelOnStableDirectedGraph() async {
        let operations = zip(Gen.int(in: 0 ... 13), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 60)
        await propertyCheck(count: 250, input: operations) { operations in
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>()
            var vertices = Set<Int>()
            var arcs: [DirectedEdge<Int>] = []
            var order: [Int] = []
            func descendants(of start: Int) -> Set<Int> {
                var seen = Set<Int>(), stack = [start]
                while let w = stack.popLast() {
                    for arc in arcs where arc.source == w && !seen.contains(arc.target) {
                        seen.insert(arc.target)
                        stack.append(arc.target)
                    }
                }
                return seen
            }
            func ancestors(of start: Int) -> Set<Int> {
                var seen = Set<Int>(), stack = [start]
                while let w = stack.popLast() {
                    for arc in arcs where arc.target == w && !seen.contains(arc.source) {
                        seen.insert(arc.source)
                        stack.append(arc.source)
                    }
                }
                return seen
            }
            func distance(from a: Int, to b: Int) -> Int? {
                var level = [a], seen: Set<Int> = [a], d = 0
                while !level.isEmpty {
                    if level.contains(b) { return d }
                    var next: [Int] = []
                    for w in level {
                        for arc in arcs where arc.source == w && !seen.contains(arc.target) {
                            seen.insert(arc.target)
                            next.append(arc.target)
                        }
                    }
                    level = next
                    d += 1
                }
                return nil
            }
            // Pearce-Kelly from the definitions: for an accepted u -> v with v placed before u, the
            // forward set F (v and its descendants placed before u) and the backward set B (u and its
            // ancestors placed after v), B then F, each by old place, take their pooled places.
            func accept(_ u: Int, _ v: Int) {
                let place = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
                if place[u]! > place[v]! {
                    let forward = descendants(of: v).union([v]).filter { place[$0]! < place[u]! }
                    let backward = ancestors(of: u).union([u]).filter { place[$0]! > place[v]! }
                    let moved = backward.sorted { place[$0]! < place[$1]! } + forward.sorted { place[$0]! < place[$1]! }
                    for (w, slot) in zip(moved, moved.map { place[$0]! }.sorted()) { order[slot] = w }
                }
                arcs.append(DirectedEdge(from: u, to: v))
            }
            for (step, (kind, x, y)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                let edge = DirectedEdge(from: x, to: y)
                let before = graph
                switch kind {
                case 0:
                    let result = graph.insert(x)
                    #expect(result.inserted == !vertices.contains(x) && result.memberAfterInsert == x, "\(context)")
                    if vertices.insert(x).inserted { order.append(x) }
                case 1, 2, 3, 4, 5, 6:
                    let safe = kind == 6
                    let result = safe ? graph.insert(safe: edge) : graph.insert(edge: edge)
                    if safe && !(vertices.contains(x) && vertices.contains(y)) {
                        #expect(result == nil, "\(context)")
                    } else if x == y || (vertices.contains(x) && vertices.contains(y) && distance(from: y, to: x) != nil) {
                        // Rejected: nil, and nothing changes, not even a missing endpoint.
                        #expect(result == nil, "\(context)")
                        #expect(graph == before && Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                        #expect(Array(graph.edges) == Array(before.edges) && Array(graph.edges.indices) == Array(before.edges.indices), "\(context)")
                        if x != y, let witness = graph.bidirectionalShortestPath(from: y, to: x) {
                            // The witness is genuine: a shortest path from the target to the source.
                            #expect(witness.source == y && witness.target == x && witness.length == distance(from: y, to: x), "\(context)")
                            #expect(witness.edges.indices.allSatisfy { graph.source(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0] && graph.target(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0 + 1] }, "\(context)")
                        } else if x != y {
                            Issue.record("no witness: \(context)")
                        }
                    } else {
                        for w in [x, y] where vertices.insert(w).inserted { order.append(w) }
                        if let position = result {
                            #expect(graph.source(ofEdgeAt: position) == x && graph.target(ofEdgeAt: position) == y, "\(context)")
                        } else {
                            Issue.record("rejected an acyclic edge: \(context)")
                        }
                        let oldPlaces = Dictionary(uniqueKeysWithValues: before.topologicalOrder.enumerated().map { ($1, $0) })
                        accept(x, y)
                        // Nothing placed outside [place(y), place(x)] moves.
                        if let px = oldPlaces[x], let py = oldPlaces[y] {
                            for (place, w) in before.topologicalOrder.enumerated() where place < min(px, py) || place > max(px, py) {
                                #expect(graph.topologicalPosition(of: w) == place, "\(context)")
                            }
                        }
                    }
                case 7, 8:
                    let removed = graph.remove(x)
                    #expect(removed == (vertices.contains(x) ? x : nil), "\(context)")
                    if vertices.remove(x) != nil {
                        order.removeAll { $0 == x }
                        arcs.removeAll { $0.source == x || $0.target == x }
                    }
                case 9, 10:
                    let removed = graph.remove(edge: edge)
                    #expect(removed == (arcs.contains(edge) ? edge : nil), "\(context)")
                    if let last = arcs.lastIndex(of: edge) { arcs.remove(at: last) }
                    #expect(Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                case 11:
                    let positions = Array(graph.edges.indices)
                    if !positions.isEmpty {
                        let position = positions[x % positions.count]
                        let expected = graph.edges[position]
                        #expect(graph.remove(edgeAt: position) == expected, "\(context)")
                        arcs.remove(at: arcs.firstIndex(of: expected)!)
                        #expect(Array(graph.topologicalOrder) == Array(before.topologicalOrder), "\(context)")
                    }
                case 12:
                    graph.removeAllEdges(keepingCapacity: x.isMultiple(of: 2))
                    arcs.removeAll()
                default:
                    if x < 2 {
                        graph.removeAll(keepingCapacity: y.isMultiple(of: 2))
                        vertices.removeAll()
                        arcs.removeAll()
                        order.removeAll()
                    }
                }
                #expect(Set(graph.vertices) == vertices && graph.vertexCount == vertices.count, "\(context)")
                #expect(graph.edges.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) } == arcs.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) }, "\(context)")
                #expect(Array(graph.topologicalOrder) == order, "\(context)")
                // The laws: every edge goes forward, and the places agree with the order.
                #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) }, "\(context)")
                #expect(order.indices.allSatisfy { graph.topologicalPosition(of: order[$0]) == $0 && graph.topologicalPosition(safe: order[$0]) == $0 }, "\(context)")
                #expect(graph.isAcyclic, "\(context)")
            }
        }
    }


    @Test("Random bulk builds: nil exactly when the edges have a cycle; otherwise Kahn's order, FIFO, roots in vertices order")
    func bulkBuildsAgainstKahn() async {
        let input = zip(Gen.int(in: 0 ... 7).array(of: 0 ... 6), zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14))
        await propertyCheck(count: 300, input: input) { listed, raw in
            let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            for collapse in [false, true] {
                // The base's vertices: listed first (a repeat once), then new endpoints in first-appearance order.
                var vertices: [Int] = []
                for v in listed + edges.flatMap({ [$0.source, $0.target] }) where !vertices.contains(v) { vertices.append(v) }
                var kept: [DirectedEdge<Int>] = []
                for e in edges where !(collapse && kept.contains(e)) { kept.append(e) }
                var indegree = Dictionary(uniqueKeysWithValues: vertices.map { v in (v, kept.filter { $0.target == v }.count) })
                var queue = vertices.filter { indegree[$0] == 0 }
                var next = 0
                while next < queue.count {
                    let v = queue[next]
                    next += 1
                    for e in kept where e.source == v {
                        indegree[e.target]! -= 1
                        if indegree[e.target] == 0 { queue.append(e.target) }
                    }
                }
                let expected: [Int]? = queue.count == vertices.count ? queue : nil
                if collapse {
                    let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: listed, edges: edges)
                    #expect(graph.map { Array($0.topologicalOrder) } == expected, "\(listed) \(raw)")
                    #expect(graph.map { Array($0.vertices) } == (expected == nil ? nil : vertices))
                    #expect(graph.map { Array($0.edges) } == (expected == nil ? nil : kept))
                } else {
                    let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: listed, edges: edges)
                    #expect(graph.map { Array($0.topologicalOrder) } == expected, "\(listed) \(raw)")
                    #expect(graph.map { Array($0.vertices) } == (expected == nil ? nil : vertices))
                    #expect(graph.map { Array($0.edges) } == (expected == nil ? nil : kept))
                    let stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: listed, edges: edges)
                    #expect(stable.map { Array($0.topologicalOrder) } == expected, "\(listed) \(raw)")
                    // The bulk order is Traversal's generations, flattened.
                    if let graph {
                        #expect(Array(graph.topologicalOrder) == graph.base.topologicalGenerations()!.flatMap { $0 })
                    } else {
                        #expect(graph == nil && DirectedPseudograph(vertices: listed, edges: edges).findCycle() != nil)
                    }
                }
            }
        }
    }

    @Test("Codable round trips of random histories keep the order and every position")
    func codableRoundTrips() async {
        let operations = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40)
        await propertyCheck(count: 200, input: operations) { operations in
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>()
            for (kind, x, y) in operations {
                switch kind {
                case 0, 1: _ = graph.insert(edge: DirectedEdge(from: x, to: y))
                case 2: _ = graph.remove(x)
                default: _ = graph.remove(edge: DirectedEdge(from: x, to: y))
                }
            }
            do {
                let again = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: try JSONEncoder().encode(graph))
                #expect(again == graph && Array(again.topologicalOrder) == Array(graph.topologicalOrder), "\(operations)")
                #expect(Array(again.edges.indices) == Array(graph.edges.indices) && Array(again.vertices) == Array(graph.vertices), "\(operations)")
                var dense = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
                for v in graph.topologicalOrder { dense.insert(v) }
                for e in graph.edges { _ = dense.insert(edge: e) }
                let denseAgain = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: try JSONEncoder().encode(dense))
                #expect(denseAgain == dense && Array(denseAgain.topologicalOrder) == Array(graph.topologicalOrder), "\(operations)")
            } catch {
                Issue.record("\(error) for \(operations)")
            }
        }
    }
}
