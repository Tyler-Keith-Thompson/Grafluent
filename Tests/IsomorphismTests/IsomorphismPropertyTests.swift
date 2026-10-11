// Properties against a brute-force model written out in each test, with shrinking
// (swift-property-based). Random pseudographs and directed pseudographs (parallel edges and
// self-loops) on up to 6 vertices, with optional vertex and edge colours from two classes. The
// model tries every injection of the pattern's vertices into the target's and keeps those that
// satisfy api.md's definition (m(u, v) the multiset of edge colours between u and v; equal for an
// isomorphism and a subgraph isomorphism, contained for a monomorphism; vertex colours equal). Each
// problem's sequence must be that set exactly (so complete, with no mapping twice), the yes/no answer
// and the first mapping must agree with it, induced mappings must be monomorphisms, and colours
// must be kept. Weisfeiler–Leman partitions are checked against colour refinement written out, and
// relabelled copies must hash equal. See README.md.

import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs
import PropertyBased
import Testing

@Suite("Isomorphism properties against brute force, with shrinking", .tags(.randomized))
struct IsomorphismPropertyTests {
    @Test("Undirected: every problem's mappings are exactly the injections the definition accepts, with and without colours")
    func undirectedAgainstBruteForce() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1)).array(of: 0 ... 9)
        let shape = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 1_000_000))
        await propertyCheck(count: 400, input: edges, edges, shape) { targetRaw, patternRaw, shape in
            let (n, k, flags, seed) = shape
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let useVertexColors = flags & 1 != 0, useEdgeColors = flags & 2 != 0, relabel = flags & 4 != 0
            // The target on 0..<n; the pattern on k vertices, or for an isomorphism a relabelled copy
            // of the target (half of the time) so that positive answers are common.
            let target = n == 0 ? [] : targetRaw.map { [$0.0 % n, $0.1 % n, $0.2] }
            let targetColors = (0 ..< n).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let permutation = Array(0 ..< n).shuffled(using: &rng)
            let copy = target.map { [permutation[$0[0]], permutation[$0[1]], $0[2]] }.shuffled(using: &rng)
            var copyColors = targetColors
            for v in 0 ..< n { copyColors[permutation[v]] = targetColors[v] }
            let pattern = k == 0 ? [] : patternRaw.prefix(4).map { [$0.0 % k, $0.1 % k, $0.2] }
            let patternColors = (0 ..< k).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let context = "target \(target) \(targetColors), pattern \(pattern) \(patternColors), copy \(copy), flags \(flags)"
            // m(u, v): the sorted edge colours between u and v (0 for every edge without edge colours).
            func pairs(_ list: [[Int]]) -> [[Int]: [Int]] {
                var out: [[Int]: [Int]] = [:]
                for e in list {
                    let c = useEdgeColors ? e[2] : 0
                    out[[e[0], e[1]], default: []].append(c)
                    if e[0] != e[1] { out[[e[1], e[0]], default: []].append(c) }
                }
                return out.mapValues { $0.sorted() }
            }
            func contained(_ a: [Int], _ b: [Int]) -> Bool { a.allSatisfy { c in a.filter { $0 == c }.count <= b.filter { $0 == c }.count } }
            func model(_ p: [[Int]], _ pc: [Int], _ t: [[Int]], _ tc: [Int], _ problem: Int) -> Set<[Int]> {
                let pk = pc.count, tn = tc.count
                if problem == 0 && pk != tn { return [] }
                let mp = pairs(p), mt = pairs(t)
                var out = Set<[Int]>()
                var images: [Int] = []
                func extend() {
                    if images.count == pk {
                        let ok = (0 ..< pk).allSatisfy { u in
                            pc[u] == tc[images[u]] && (0 ..< pk).allSatisfy { v in
                                let a = mp[[u, v]] ?? [], b = mt[[images[u], images[v]]] ?? []
                                return problem == 2 ? contained(a, b) : a == b
                            }
                        }
                        if ok { out.insert(images) }
                        return
                    }
                    for x in 0 ..< tn where !images.contains(x) {
                        images.append(x)
                        extend()
                        images.removeLast()
                    }
                }
                extend()
                return out
            }
            let g = Pseudograph(vertices: 0 ..< n, edges: target.map { UndirectedEdge($0[0], $0[1]) })
            let h = Pseudograph(vertices: 0 ..< n, edges: copy.map { UndirectedEdge($0[0], $0[1]) })
            let p = Pseudograph(vertices: 0 ..< k, edges: pattern.map { UndirectedEdge($0[0], $0[1]) })
            let isoTarget = relabel ? copy : target.shuffled(using: &rng)
            let isoTargetColors = relabel ? copyColors : targetColors
            let isoGraph = relabel ? h : Pseudograph(vertices: 0 ..< n, edges: isoTarget.map { UndirectedEdge($0[0], $0[1]) })
            let gColor = { (v: Int) in targetColors[v] }, isoColor = { (v: Int) in isoTargetColors[v] }, pColor = { (v: Int) in patternColors[v] }
            let gEdge = { (e: Int) in useEdgeColors ? target[e][2] : 0 }, isoEdge = { (e: Int) in useEdgeColors ? isoTarget[e][2] : 0 }
            let pEdge = { (e: Int) in useEdgeColors ? pattern[e][2] : 0 }
            // Isomorphism: the target against a relabelled or reordered copy.
            let isomorphisms = Array(g.isomorphisms(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge).map { Array($0.images) })
            let expectedIsomorphisms = model(target, targetColors, isoTarget, isoTargetColors, 0)
            #expect(isomorphisms.count == expectedIsomorphisms.count && Set(isomorphisms) == expectedIsomorphisms, "isomorphisms: \(context)")
            #expect(!expectedIsomorphisms.isEmpty, "a copy is isomorphic: \(context)")
            #expect(g.isIsomorphic(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge) == !expectedIsomorphisms.isEmpty, "\(context)")
            let firstIsomorphism = g.isomorphism(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge).map { Array($0.images) }
            #expect(firstIsomorphism.map(expectedIsomorphisms.contains) ?? expectedIsomorphisms.isEmpty, "\(context)")
            // Without edge colours, the vertex-colour overload; without either, the plain one.
            if !useEdgeColors {
                #expect(Set(g.isomorphisms(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor).map { Array($0.images) }) == expectedIsomorphisms, "\(context)")
                if !useVertexColors {
                    #expect(Set(g.isomorphisms(to: isoGraph).map { Array($0.images) }) == expectedIsomorphisms, "\(context)")
                }
            }
            // The subgraph problems: the pattern into the target.
            let induced = Array(p.subgraphIsomorphisms(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) })
            let mono = Array(p.monomorphisms(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) })
            let expectedInduced = model(pattern, patternColors, target, targetColors, 1)
            let expectedMono = model(pattern, patternColors, target, targetColors, 2)
            #expect(induced.count == expectedInduced.count && Set(induced) == expectedInduced, "induced: \(context)")
            #expect(mono.count == expectedMono.count && Set(mono) == expectedMono, "mono: \(context)")
            #expect(Set(induced).isSubset(of: Set(mono)), "\(context)")
            #expect(p.isSubgraphIsomorphic(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge) == !expectedInduced.isEmpty, "\(context)")
            #expect(p.isMonomorphic(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge) == !expectedMono.isEmpty, "\(context)")
            let firstInduced = p.subgraphIsomorphism(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) }
            let firstMono = p.monomorphism(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) }
            #expect(firstInduced.map(expectedInduced.contains) ?? expectedInduced.isEmpty, "\(context)")
            #expect(firstMono.map(expectedMono.contains) ?? expectedMono.isEmpty, "\(context)")
            if !useEdgeColors && !useVertexColors {
                #expect(Set(p.subgraphIsomorphisms(to: g).map { Array($0.images) }) == expectedInduced, "\(context)")
                #expect(Set(p.monomorphisms(to: g).map { Array($0.images) }) == expectedMono, "\(context)")
            }
        }
    }

    @Test("Directed: every problem's mappings are exactly the injections the definition accepts, arc direction kept")
    func directedAgainstBruteForce() async {
        let arcs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1)).array(of: 0 ... 10)
        let shape = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 1_000_000))
        await propertyCheck(count: 400, input: arcs, arcs, shape) { targetRaw, patternRaw, shape in
            let (n, k, flags, seed) = shape
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let useVertexColors = flags & 1 != 0, useEdgeColors = flags & 2 != 0, relabel = flags & 4 != 0
            let target = n == 0 ? [] : targetRaw.map { [$0.0 % n, $0.1 % n, $0.2] }
            let targetColors = (0 ..< n).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let permutation = Array(0 ..< n).shuffled(using: &rng)
            let copy = target.map { [permutation[$0[0]], permutation[$0[1]], $0[2]] }.shuffled(using: &rng)
            var copyColors = targetColors
            for v in 0 ..< n { copyColors[permutation[v]] = targetColors[v] }
            let pattern = k == 0 ? [] : patternRaw.prefix(4).map { [$0.0 % k, $0.1 % k, $0.2] }
            let patternColors = (0 ..< k).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let context = "target \(target) \(targetColors), pattern \(pattern) \(patternColors), copy \(copy), flags \(flags)"
            // m(u, v): the sorted colours of the arcs from u to v.
            func pairs(_ list: [[Int]]) -> [[Int]: [Int]] {
                var out: [[Int]: [Int]] = [:]
                for e in list { out[[e[0], e[1]], default: []].append(useEdgeColors ? e[2] : 0) }
                return out.mapValues { $0.sorted() }
            }
            func contained(_ a: [Int], _ b: [Int]) -> Bool { a.allSatisfy { c in a.filter { $0 == c }.count <= b.filter { $0 == c }.count } }
            func model(_ p: [[Int]], _ pc: [Int], _ t: [[Int]], _ tc: [Int], _ problem: Int) -> Set<[Int]> {
                let pk = pc.count, tn = tc.count
                if problem == 0 && pk != tn { return [] }
                let mp = pairs(p), mt = pairs(t)
                var out = Set<[Int]>()
                var images: [Int] = []
                func extend() {
                    if images.count == pk {
                        let ok = (0 ..< pk).allSatisfy { u in
                            pc[u] == tc[images[u]] && (0 ..< pk).allSatisfy { v in
                                let a = mp[[u, v]] ?? [], b = mt[[images[u], images[v]]] ?? []
                                return problem == 2 ? contained(a, b) : a == b
                            }
                        }
                        if ok { out.insert(images) }
                        return
                    }
                    for x in 0 ..< tn where !images.contains(x) {
                        images.append(x)
                        extend()
                        images.removeLast()
                    }
                }
                extend()
                return out
            }
            let g = DirectedPseudograph(vertices: 0 ..< n, edges: target.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let p = DirectedPseudograph(vertices: 0 ..< k, edges: pattern.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let isoTarget = relabel ? copy : target.shuffled(using: &rng)
            let isoTargetColors = relabel ? copyColors : targetColors
            let isoGraph = DirectedPseudograph(vertices: 0 ..< n, edges: isoTarget.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let gColor = { (v: Int) in targetColors[v] }, isoColor = { (v: Int) in isoTargetColors[v] }, pColor = { (v: Int) in patternColors[v] }
            let gEdge = { (e: Int) in useEdgeColors ? target[e][2] : 0 }, isoEdge = { (e: Int) in useEdgeColors ? isoTarget[e][2] : 0 }
            let pEdge = { (e: Int) in useEdgeColors ? pattern[e][2] : 0 }
            let isomorphisms = Array(g.isomorphisms(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge).map { Array($0.images) })
            let expectedIsomorphisms = model(target, targetColors, isoTarget, isoTargetColors, 0)
            #expect(isomorphisms.count == expectedIsomorphisms.count && Set(isomorphisms) == expectedIsomorphisms, "isomorphisms: \(context)")
            #expect(!expectedIsomorphisms.isEmpty, "a copy is isomorphic: \(context)")
            #expect(g.isIsomorphic(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge), "\(context)")
            let firstIsomorphism = g.isomorphism(to: isoGraph, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge).map { Array($0.images) }
            #expect(firstIsomorphism.map(expectedIsomorphisms.contains) == true, "\(context)")
            // The converse graph is isomorphic to the copy's converse by the same mappings.
            let converse = DirectedPseudograph(vertices: 0 ..< n, edges: target.map { DirectedEdge(from: $0[1], to: $0[0]) })
            let isoConverse = DirectedPseudograph(vertices: 0 ..< n, edges: isoTarget.map { DirectedEdge(from: $0[1], to: $0[0]) })
            #expect(Set(converse.isomorphisms(to: isoConverse, vertexColor: gColor, otherVertexColor: isoColor, edgeColor: gEdge, otherEdgeColor: isoEdge).map { Array($0.images) }) == expectedIsomorphisms, "\(context)")
            let induced = Array(p.subgraphIsomorphisms(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) })
            let mono = Array(p.monomorphisms(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) })
            let expectedInduced = model(pattern, patternColors, target, targetColors, 1)
            let expectedMono = model(pattern, patternColors, target, targetColors, 2)
            #expect(induced.count == expectedInduced.count && Set(induced) == expectedInduced, "induced: \(context)")
            #expect(mono.count == expectedMono.count && Set(mono) == expectedMono, "mono: \(context)")
            #expect(p.isSubgraphIsomorphic(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge) == !expectedInduced.isEmpty, "\(context)")
            #expect(p.isMonomorphic(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge) == !expectedMono.isEmpty, "\(context)")
            let firstInduced = p.subgraphIsomorphism(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) }
            let firstMono = p.monomorphism(to: g, vertexColor: pColor, otherVertexColor: gColor, edgeColor: pEdge, otherEdgeColor: gEdge).map { Array($0.images) }
            #expect(firstInduced.map(expectedInduced.contains) ?? expectedInduced.isEmpty, "\(context)")
            #expect(firstMono.map(expectedMono.contains) ?? expectedMono.isEmpty, "\(context)")
            if !useEdgeColors && !useVertexColors {
                #expect(Set(p.subgraphIsomorphisms(to: g).map { Array($0.images) }) == expectedInduced, "\(context)")
                #expect(Set(p.monomorphisms(to: g).map { Array($0.images) }) == expectedMono, "\(context)")
                #expect(Set(g.isomorphisms(to: isoGraph).map { Array($0.images) }) == expectedIsomorphisms, "\(context)")
            }
        }
    }

    @Test("Weisfeiler–Leman: each round's partition is colour refinement's; relabelled copies hash equal, vertex by vertex")
    func weisfeilerLehmanAgainstRefinement() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 1)).array(of: 0 ... 14)
        let shape = zip(Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 1_000_000))
        await propertyCheck(count: 300, input: edges, shape) { raw, shape in
            let (n, k, flags, seed) = shape
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let directed = flags & 1 != 0, useVertexColors = flags & 2 != 0, useEdgeColors = flags & 4 != 0
            let list = raw.map { [$0.0 % n, $0.1 % n, useEdgeColors ? $0.2 : 0] }
            let colors = (0 ..< n).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let permutation = Array(0 ..< n).shuffled(using: &rng)
            let order = Array(list.indices).shuffled(using: &rng)
            let copy = order.map { [permutation[list[$0][0]], permutation[list[$0][1]], list[$0][2]] }
            var copyColors = colors
            for v in 0 ..< n { copyColors[permutation[v]] = colors[v] }
            let context = "\(directed ? "directed" : "undirected") \(list) \(colors), k \(k), π \(permutation)"
            // Colour refinement written out: round r's colour is (round r − 1's colour, the sorted
            // (edge colour, neighbour colour) pairs over the edge ends; out and in apart when
            // directed), numbered by first appearance; classes in vertex order.
            var rounds: [[Int]] = []
            var current = colors
            for _ in 0 ..< k {
                var signatures: [[Int]] = []
                for v in 0 ..< n {
                    var outs: [[Int]] = [], ins: [[Int]] = []
                    for e in list {
                        if e[0] == v { outs.append([e[2], current[e[1]]]) }
                        if e[1] == v && directed { ins.append([e[2], current[e[0]]]) }
                        if e[1] == v && !directed { outs.append([e[2], current[e[0]]]) }
                    }
                    outs.sort { $0.lexicographicallyPrecedes($1) }
                    ins.sort { $0.lexicographicallyPrecedes($1) }
                    signatures.append([current[v], -1] + outs.flatMap { $0 } + [-2] + ins.flatMap { $0 })
                }
                var names: [[Int]: Int] = [:]
                current = signatures.map { s in names[s] ?? { names[s] = names.count; return names.count - 1 }() }
                rounds.append(current)
            }
            func partition(_ colours: [Int]) -> [[Int]] {
                var classes: [Int: [Int]] = [:], first: [Int] = []
                for (v, c) in colours.enumerated() {
                    if classes[c] == nil { first.append(c) }
                    classes[c, default: []].append(v)
                }
                return first.map { classes[$0]! }
            }
            if directed {
                let g = DirectedPseudograph(vertices: 0 ..< n, edges: list.map { DirectedEdge(from: $0[0], to: $0[1]) })
                let h = DirectedPseudograph(vertices: 0 ..< n, edges: copy.map { DirectedEdge(from: $0[0], to: $0[1]) })
                let hashes = g.weisfeilerLehmanSubgraphHashes(iterations: k, vertexColor: { colors[$0] }, edgeColor: { list[$0][2] })
                let copyHashes = h.weisfeilerLehmanSubgraphHashes(iterations: k, vertexColor: { copyColors[$0] }, edgeColor: { copy[$0][2] })
                for r in 0 ..< k {
                    #expect(partition((0 ..< n).map { Array(hashes.hashes(of: $0))[r] }) == partition(rounds[r]), "round \(r + 1): \(context)")
                }
                #expect((0 ..< n).allSatisfy { copyHashes.hashes(of: permutation[$0]) == hashes.hashes(of: $0) }, "\(context)")
                #expect(g.weisfeilerLehmanGraphHash(iterations: k, vertexColor: { colors[$0] }, edgeColor: { list[$0][2] }) == h.weisfeilerLehmanGraphHash(iterations: k, vertexColor: { copyColors[$0] }, edgeColor: { copy[$0][2] }), "\(context)")
            } else {
                let g = Pseudograph(vertices: 0 ..< n, edges: list.map { UndirectedEdge($0[0], $0[1]) })
                let h = Pseudograph(vertices: 0 ..< n, edges: copy.map { UndirectedEdge($0[0], $0[1]) })
                let hashes = g.weisfeilerLehmanSubgraphHashes(iterations: k, vertexColor: { colors[$0] }, edgeColor: { list[$0][2] })
                let copyHashes = h.weisfeilerLehmanSubgraphHashes(iterations: k, vertexColor: { copyColors[$0] }, edgeColor: { copy[$0][2] })
                for r in 0 ..< k {
                    #expect(partition((0 ..< n).map { Array(hashes.hashes(of: $0))[r] }) == partition(rounds[r]), "round \(r + 1): \(context)")
                }
                #expect((0 ..< n).allSatisfy { copyHashes.hashes(of: permutation[$0]) == hashes.hashes(of: $0) }, "\(context)")
                #expect(g.weisfeilerLehmanGraphHash(iterations: k, vertexColor: { colors[$0] }, edgeColor: { list[$0][2] }) == h.weisfeilerLehmanGraphHash(iterations: k, vertexColor: { copyColors[$0] }, edgeColor: { copy[$0][2] }), "\(context)")
                if !useVertexColors && !useEdgeColors {
                    #expect(g.weisfeilerLehmanGraphHash(iterations: k) == h.weisfeilerLehmanGraphHash(iterations: k), "\(context)")
                }
            }
        }
    }
}
