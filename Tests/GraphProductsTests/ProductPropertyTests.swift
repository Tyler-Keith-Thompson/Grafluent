// Properties with shrinking (swift-property-based). Random factor pairs, pseudographs with parallel
// edges and self-loops, directed and undirected, build all four products, and each is compared with
// its definition written out edge by edge in index space (vertex (g, h) at g·|V(H)| + h):
//   □  (u, h)–(v, h) for every G-edge and H-vertex, then (g, c)–(g, d) for every G-vertex and H-edge;
//   ×  (a, c)–(b, d) for every G-edge and H-edge, and undirected also (a, d)–(b, c) when neither is
//      a self-loop;
//   ⊠  □'s edges, then ×'s;
//   ∘  (a, h)–(b, h′) for every G-edge and H-vertices h, h′ (h ≤ h′ over an undirected self-loop),
//      then □'s H-moves.
// The edge multisets, `edgeCount`, every row (a self-loop twice in an undirected row), each edge met
// once per end over all rows, `contains(edge:)` for every pair, the vertex numbering both ways and
// the edge-index law all must agree. Then Pair's laws. See README.md.

import Connectivity
import Foundation
import GrafluentTestSupport
import GraphProducts
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing
import Traversal

@Suite("GraphProducts properties against the definitions, with shrinking", .tags(.randomized))
struct ProductPropertyTests {
    @Test("Undirected products of random pseudographs agree with their definitions")
    func undirectedDefinitions() async {
        let factor = zip(Gen.int(in: 0 ... 4), zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 3)).array(of: 0 ... 5))
        await propertyCheck(count: 200, input: factor, factor) { gSpec, hSpec in
            let (nG, gPairs) = gSpec, (nH, hPairs) = hSpec
            let gEdges = nG == 0 ? [] : gPairs.map { [$0.0 % nG, $0.1 % nG] }
            let hEdges = nH == 0 ? [] : hPairs.map { [$0.0 % nH, $0.1 % nH] }
            let g = Pseudograph<Int>(vertices: 0 ..< nG, edges: gEdges.map { UndirectedEdge($0[0], $0[1]) })
            let h = Pseudograph<Int>(vertices: 0 ..< nH, edges: hEdges.map { UndirectedEdge($0[0], $0[1]) })
            // The definitions, as index pairs in `edges` order.
            var cartesian: [[Int]] = []
            for e in gEdges { for b in 0 ..< nH { cartesian.append([e[0] * nH + b, e[1] * nH + b]) } }
            var hMoves: [[Int]] = []
            for a in 0 ..< nG { for f in hEdges { hMoves.append([a * nH + f[0], a * nH + f[1]]) } }
            cartesian += hMoves
            var tensor: [[Int]] = []
            for e in gEdges {
                for f in hEdges {
                    tensor.append([e[0] * nH + f[0], e[1] * nH + f[1]])
                    if e[0] != e[1] && f[0] != f[1] { tensor.append([e[0] * nH + f[1], e[1] * nH + f[0]]) }
                }
            }
            var lexicographic: [[Int]] = []
            for e in gEdges {
                for b in 0 ..< nH { for b2 in 0 ..< nH where e[0] != e[1] || b <= b2 { lexicographic.append([e[0] * nH + b, e[1] * nH + b2]) } }
            }
            lexicographic += hMoves
            let context = "G \(nG) \(gEdges), H \(nH) \(hEdges)"
            func check<P: Graph>(_ product: P, _ expected: [[Int]], hasEdgeIndices: Bool, _ kind: String) where P.Vertex == Pair<Int, Int> {
                let n = nG * nH
                // Breadth-first layers and connected components walk each row in place
                // (`_forEachNeighborIndex`): the same entries, in the same order, as the row.
                if n > 0 {
                    var layer = [0], seen: Set = [0], layers: [[Int]] = []
                    while !layer.isEmpty {
                        layers.append(layer)
                        var next: [Int] = []
                        for u in layer { for w in product.neighborIndices(ofIndex: u) where seen.insert(w).inserted { next.append(w) } }
                        layer = next
                    }
                    #expect(product.directedView.breadthFirstLayers(from: product.vertex(atIndex: 0)) == layers.map { $0.map { product.vertex(atIndex: $0) } }, "\(kind): \(context)")
                }
                var label = [Int](repeating: -1, count: n), groups: [[Int]] = []
                for s in 0 ..< n where label[s] < 0 {
                    label[s] = groups.count
                    var group = [s], k = 0
                    while k < group.count {
                        for w in product.neighborIndices(ofIndex: group[k]) where label[w] < 0 {
                            label[w] = groups.count
                            group.append(w)
                        }
                        k += 1
                    }
                    groups.append(group.sorted())
                }
                #expect(product.connectedComponents().map { $0.map { product.vertexIndex(of: $0) } } == groups, "\(kind): \(context)")
                #expect(product.isConnected == (groups.count == 1), "\(kind): \(context)")
                let positions = Array(product.edges.indices)
                let ends = positions.map { [product.endpointIndices(ofEdgeAt: $0).u, product.endpointIndices(ofEdgeAt: $0).v] }
                #expect(ends == expected, "\(kind): \(context)")
                #expect(product.edges.map { [$0.u.first * nH + $0.u.second, $0.v.first * nH + $0.v.second] } == expected, "\(kind): \(context)")
                #expect(product.edgeCount == expected.count && product.edges.count == expected.count, "\(kind): \(context)")
                #expect(product.vertexIndexBound == n && product.vertexCount == n, "\(kind): \(context)")
                #expect(Set(positions).count == positions.count && positions == positions.sorted(), "\(kind): \(context)")
                #expect(Array(product.vertices) == (0 ..< n).map { Pair($0 / Swift.max(nH, 1), $0 % Swift.max(nH, 1)) }, "\(kind): \(context)")
                #expect(product.vertices.map { product.vertexIndex(of: $0) } == Array(0 ..< n), "\(kind): \(context)")
                #expect((0 ..< n).map { product.vertex(atIndex: $0) } == Array(product.vertices), "\(kind): \(context)")
                if hasEdgeIndices {
                    #expect(product.edgeIndexBound == expected.count, "\(kind): \(context)")
                    #expect(positions.map { product.edgeIndex(of: $0) } == Array(0 ..< expected.count), "\(kind): \(context)")
                } else {
                    #expect(product.edgeIndexBound == nil, "\(kind): \(context)")
                }
                var met = [Int](repeating: 0, count: positions.count)
                let offset = Dictionary(uniqueKeysWithValues: zip(positions, positions.indices))
                for i in 0 ..< n {
                    var want: [Int] = []
                    for e in expected {
                        if e[0] == i { want.append(e[1]) }
                        if e[1] == i { want.append(e[0]) }
                    }
                    let row = Array(product.incidentEdges(ofIndex: i))
                    let neighbors = Array(product.neighborIndices(ofIndex: i))
                    #expect(neighbors.sorted() == want.sorted(), "\(kind) row \(i): \(context)")
                    #expect(row.count == neighbors.count && product.degree(ofIndex: i) == want.count, "\(kind) row \(i): \(context)")
                    #expect(product.degree(of: product.vertex(atIndex: i)) == want.count, "\(kind) row \(i): \(context)")
                    #expect(Array(product.neighbors(of: product.vertex(atIndex: i))) == neighbors.map { product.vertex(atIndex: $0) }, "\(kind) row \(i): \(context)")
                    #expect(Array(product.incidentEdges(of: product.vertex(atIndex: i))) == row, "\(kind) row \(i): \(context)")
                    for (p, w) in zip(row, neighbors) {
                        let k = offset[p] ?? -1
                        #expect(k >= 0, "\(kind) row \(i): \(context)")
                        if k >= 0 {
                            met[k] += 1
                            // The entry's other end is its neighbor.
                            #expect(ends[k].sorted() == [i, w].sorted(), "\(kind) row \(i): \(context)")
                        }
                    }
                    for j in 0 ..< n {
                        let adjacent = expected.contains { ($0[0] == i && $0[1] == j) || ($0[0] == j && $0[1] == i) }
                        #expect(product.contains(edge: UndirectedEdge(product.vertex(atIndex: i), product.vertex(atIndex: j))) == adjacent, "\(kind) \(i)–\(j): \(context)")
                    }
                }
                // Every edge once per end; a self-loop twice in its one row.
                #expect(met.allSatisfy { $0 == 2 }, "\(kind): \(context)")
            }
            check(cartesianProductView(g, h), cartesian, hasEdgeIndices: true, "cartesian")
            check(tensorProductView(g, h), tensor, hasEdgeIndices: false, "tensor")
            check(strongProductView(g, h), cartesian + tensor, hasEdgeIndices: false, "strong")
            check(lexicographicProductView(g, h), lexicographic, hasEdgeIndices: false, "lexicographic")
            // The loop-free degree formulas, when neither factor has a self-loop.
            if gEdges.allSatisfy({ $0[0] != $0[1] }) && hEdges.allSatisfy({ $0[0] != $0[1] }) {
                for i in 0 ..< nG * nH {
                    let dG = g.degree(of: i / nH), dH = h.degree(of: i % nH)
                    #expect(cartesianProductView(g, h).degree(ofIndex: i) == dG + dH, "\(context)")
                    #expect(tensorProductView(g, h).degree(ofIndex: i) == dG * dH, "\(context)")
                    #expect(strongProductView(g, h).degree(ofIndex: i) == dG + dH + dG * dH, "\(context)")
                    #expect(lexicographicProductView(g, h).degree(ofIndex: i) == dG * nH + dH, "\(context)")
                }
            }
            // The undirected counts: × has 2·mG·mH − (ℓG·mH + ℓH·mG − ℓG·ℓH) edges.
            let lG = gEdges.filter { $0[0] == $0[1] }.count, lH = hEdges.filter { $0[0] == $0[1] }.count
            let mG = gEdges.count, mH = hEdges.count
            #expect(tensorProductView(g, h).edgeCount == 2 * mG * mH - (lG * mH + lH * mG - lG * lH), "\(context)")
            #expect(lexicographicProductView(g, h).edgeCount == (mG - lG) * nH * nH + lG * nH * (nH + 1) / 2 + nG * mH, "\(context)")
        }
    }

    @Test("Directed products of random pseudographs agree with their definitions")
    func directedDefinitions() async {
        let factor = zip(Gen.int(in: 0 ... 4), zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 3)).array(of: 0 ... 5))
        await propertyCheck(count: 200, input: factor, factor) { gSpec, hSpec in
            let (nG, gPairs) = gSpec, (nH, hPairs) = hSpec
            let gArcs = nG == 0 ? [] : gPairs.map { [$0.0 % nG, $0.1 % nG] }
            let hArcs = nH == 0 ? [] : hPairs.map { [$0.0 % nH, $0.1 % nH] }
            let g = DirectedPseudograph<Int>(vertices: 0 ..< nG, edges: gArcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let h = DirectedPseudograph<Int>(vertices: 0 ..< nH, edges: hArcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
            var cartesian: [[Int]] = []
            for e in gArcs { for b in 0 ..< nH { cartesian.append([e[0] * nH + b, e[1] * nH + b]) } }
            var hMoves: [[Int]] = []
            for a in 0 ..< nG { for f in hArcs { hMoves.append([a * nH + f[0], a * nH + f[1]]) } }
            cartesian += hMoves
            var tensor: [[Int]] = []
            for e in gArcs { for f in hArcs { tensor.append([e[0] * nH + f[0], e[1] * nH + f[1]]) } }
            var lexicographic: [[Int]] = []
            for e in gArcs { for b in 0 ..< nH { for b2 in 0 ..< nH { lexicographic.append([e[0] * nH + b, e[1] * nH + b2]) } } }
            lexicographic += hMoves
            let context = "G \(nG) \(gArcs), H \(nH) \(hArcs)"
            func check<P: BidirectionalDirectedGraph>(_ product: P, _ expected: [[Int]], _ kind: String) where P.Vertex == Pair<Int, Int> {
                let n = nG * nH
                // Breadth-first layers, weak components and ancestors walk each row in place
                // (`_forEachSuccessorIndex`, `_forEachPredecessorIndex`): the row's entries, in order.
                if n > 0 {
                    var layer = [0], seen: Set = [0], layers: [[Int]] = []
                    while !layer.isEmpty {
                        layers.append(layer)
                        var next: [Int] = []
                        for u in layer { for w in product.successorIndices(ofIndex: u) where seen.insert(w).inserted { next.append(w) } }
                        layer = next
                    }
                    #expect(product.breadthFirstLayers(from: product.vertex(atIndex: 0)) == layers.map { $0.map { product.vertex(atIndex: $0) } }, "\(kind): \(context)")
                    var stack = [0], reached: Set = [0]
                    while let u = stack.popLast() {
                        for w in product.predecessorIndices(ofIndex: u) where reached.insert(w).inserted { stack.append(w) }
                    }
                    reached.remove(0)
                    #expect(product.ancestors(of: product.vertex(atIndex: 0)) == Set(reached.map { product.vertex(atIndex: $0) }), "\(kind): \(context)")
                }
                var label = [Int](repeating: -1, count: n), groups: [[Int]] = []
                for s in 0 ..< n where label[s] < 0 {
                    label[s] = groups.count
                    var group = [s], k = 0
                    while k < group.count {
                        let u = group[k]
                        for w in Array(product.successorIndices(ofIndex: u)) + Array(product.predecessorIndices(ofIndex: u)) where label[w] < 0 {
                            label[w] = groups.count
                            group.append(w)
                        }
                        k += 1
                    }
                    groups.append(group.sorted())
                }
                #expect(product.weaklyConnectedComponents().map { $0.map { product.vertexIndex(of: $0) } } == groups, "\(kind): \(context)")
                let positions = Array(product.edges.indices)
                let ends = positions.map { [product.sourceIndex(ofEdgeAt: $0), product.targetIndex(ofEdgeAt: $0)] }
                #expect(ends == expected, "\(kind): \(context)")
                #expect(product.edges.map { [$0.source.first * nH + $0.source.second, $0.target.first * nH + $0.target.second] } == expected, "\(kind): \(context)")
                #expect(positions.map { [product.source(ofEdgeAt: $0), product.target(ofEdgeAt: $0)] } == Array(product.edges).map { [$0.source, $0.target] }, "\(kind): \(context)")
                #expect(product.edgeCount == expected.count && product.edges.count == expected.count, "\(kind): \(context)")
                #expect(Set(positions).count == positions.count && positions == positions.sorted(), "\(kind): \(context)")
                #expect(product.vertices.map { product.vertexIndex(of: $0) } == Array(0 ..< n), "\(kind): \(context)")
                // Pseudograph factors have dense edge indices, so every directed product has them.
                #expect(product.edgeIndexBound == expected.count, "\(kind): \(context)")
                #expect(positions.map { product.edgeIndex(of: $0) } == Array(0 ..< expected.count), "\(kind): \(context)")
                var out = [Int](repeating: 0, count: positions.count), into = out
                let offset = Dictionary(uniqueKeysWithValues: zip(positions, positions.indices))
                for i in 0 ..< n {
                    let succ = expected.filter { $0[0] == i }.map { $0[1] }
                    let pred = expected.filter { $0[1] == i }.map { $0[0] }
                    let v = product.vertex(atIndex: i)
                    #expect(Array(product.successorIndices(ofIndex: i)).sorted() == succ.sorted(), "\(kind) row \(i): \(context)")
                    #expect(Array(product.predecessorIndices(ofIndex: i)).sorted() == pred.sorted(), "\(kind) row \(i): \(context)")
                    #expect(Array(product.successors(of: v)) == product.successorIndices(ofIndex: i).map { product.vertex(atIndex: $0) }, "\(kind) row \(i): \(context)")
                    #expect(Array(product.predecessors(of: v)) == product.predecessorIndices(ofIndex: i).map { product.vertex(atIndex: $0) }, "\(kind) row \(i): \(context)")
                    #expect(product.outDegree(ofIndex: i) == succ.count && product.inDegree(ofIndex: i) == pred.count, "\(kind) row \(i): \(context)")
                    #expect(product.outDegree(of: v) == succ.count && product.inDegree(of: v) == pred.count && product.degree(of: v) == succ.count + pred.count, "\(kind) row \(i): \(context)")
                    #expect(Array(product.outEdges(of: v)) == Array(product.outEdges(ofIndex: i)) && Array(product.inEdges(of: v)) == Array(product.inEdges(ofIndex: i)), "\(kind) row \(i): \(context)")
                    for (p, w) in zip(product.outEdges(ofIndex: i), product.successorIndices(ofIndex: i)) {
                        let k = offset[p] ?? -1
                        #expect(k >= 0 && ends[Swift.max(k, 0)] == [i, w], "\(kind) row \(i): \(context)")
                        if k >= 0 { out[k] += 1 }
                    }
                    for (p, w) in zip(product.inEdges(ofIndex: i), product.predecessorIndices(ofIndex: i)) {
                        let k = offset[p] ?? -1
                        #expect(k >= 0 && ends[Swift.max(k, 0)] == [w, i], "\(kind) row \(i): \(context)")
                        if k >= 0 { into[k] += 1 }
                    }
                    for j in 0 ..< n {
                        let adjacent = expected.contains { $0 == [i, j] }
                        #expect(product.contains(edge: DirectedEdge(from: v, to: product.vertex(atIndex: j))) == adjacent, "\(kind) \(i)→\(j): \(context)")
                    }
                }
                // Each arc once in an out-row and once in an in-row.
                #expect(out.allSatisfy { $0 == 1 } && into.allSatisfy { $0 == 1 }, "\(kind): \(context)")
            }
            check(cartesianProductView(g, h), cartesian, "cartesian")
            check(tensorProductView(g, h), tensor, "tensor")
            check(strongProductView(g, h), cartesian + tensor, "strong")
            check(lexicographicProductView(g, h), lexicographic, "lexicographic")
            for i in 0 ..< nG * nH {
                let a = i / nH, b = i % nH
                #expect(cartesianProductView(g, h).outDegree(ofIndex: i) == g.outDegree(of: a) + h.outDegree(of: b), "\(context)")
                #expect(tensorProductView(g, h).inDegree(ofIndex: i) == g.inDegree(of: a) * h.inDegree(of: b), "\(context)")
                #expect(lexicographicProductView(g, h).outDegree(ofIndex: i) == g.outDegree(of: a) * nH + h.outDegree(of: b), "\(context)")
            }
        }
    }

    @Test("Pair: equality, hashing, lexicographic order, description and Codable")
    func pairLaws() async {
        let pairs = zip(Gen.int(in: -3 ... 3), Gen.int(in: -3 ... 3)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: pairs) { values in
            let built = values.map { Pair($0.0, $0.1) }
            #expect(built.map(\.first) == values.map(\.0) && built.map(\.second) == values.map(\.1))
            for (x, p) in zip(values, built) {
                for (y, q) in zip(values, built) {
                    #expect((p == q) == (x == y), "\(x) \(y)")
                    #expect((p < q) == (x < y), "\(x) \(y)")
                    if p == q { #expect(p.hashValue == q.hashValue, "\(x) \(y)") }
                }
                #expect(p.description == "(\(x.0), \(x.1))")
            }
            #expect(Set(built).count == Set(values.map { [$0.0, $0.1] }).count)
            #expect(built.sorted().map { [$0.first, $0.second] } == values.sorted { $0 < $1 }.map { [$0.0, $0.1] })
            let data = try? JSONEncoder().encode(built)
            let decoded = data.flatMap { try? JSONDecoder().decode([Pair<Int, Int>].self, from: $0) }
            #expect(decoded == built)
        }
        // Mutable parts, and nesting.
        var pair = Pair("g", 1)
        pair.first = "h"
        pair.second += 1
        #expect(pair == Pair("h", 2) && pair.description == "(h, 2)")
        let nested = Pair(Pair(1, 2), "x")
        #expect(nested.first.second == 2 && nested.description == "((1, 2), x)")
    }
}
