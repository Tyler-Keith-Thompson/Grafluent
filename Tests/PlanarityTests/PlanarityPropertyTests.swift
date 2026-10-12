// Properties with shrinking (swift-property-based) against a brute-force model written inside each
// test: every rotation system of a small multigraph (each vertex's first edge end fixed, (d − 1)!
// orders per vertex), whose face orbits decide planarity by Euler's formula and outerplanarity by a
// face holding every vertex of its component. On larger random graphs: exactly one witness exists
// and meets the definitions; a chord drawn inside a face keeps the graph planar and adds one face;
// a Kuratowski subgraph is minimal (deleting any of its edges leaves a planar graph). The two
// engines are cross-checked against each other: Boyer–Myrvold on the graph plus an apex decides
// outerplanarity, reversed labels keep every answer, and `rightFace` agrees with the face walks.
// Graphs are `Pseudograph`s with loops and parallel edges, vertices listed in a seeded shuffled
// order. See README.md.

import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Planarity
import PropertyBased
import Testing

@Suite("Planarity properties against a brute-force model, with shrinking", .tags(.randomized))
struct PlanarityPropertyTests {
    @Test("isPlanar, planarEmbedding() and findKuratowskiSubgraph() agree with every rotation system, and isOuterplanar with a face through every vertex")
    func againstEveryRotationSystem() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 11)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = Pseudograph<Int>(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) on \(listed)"
            // The model: half-edges 2k (leaving edges[k].u) and 2k + 1, rows in position order.
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            var out = [[Int]](repeating: [], count: n)
            for (k, (a, b)) in ends.enumerated() { out[a].append(2 * k); out[b].append(2 * k + 1) }
            var count = 1
            for row in out { for f in stride(from: 1, to: max(row.count, 1), by: 1) { count = min(count * f, 1_000_000) } }
            guard count <= 40_000 else { return }
            // Components (union-find) and Euler's count.
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
            for (a, b) in ends { parent[find(a)] = find(b) }
            var vertexCount = [Int: Int](), edgeCount = [Int: Int]()
            for v in 0 ..< n { vertexCount[find(v), default: 0] += 1 }
            for (a, _) in ends { edgeCount[find(a), default: 0] += 1 }
            let euler = edgeCount.map { 2 - vertexCount[$0.key]! + $0.value }.reduce(0, +)
            // Enumerate: the first entry of each row fixed, the rest in every order (an odometer of
            // lexicographic successors of each sorted tail).
            func faceOrbits(_ rot: [[Int]]) -> [[Int]] {
                var slot = [Int](repeating: 0, count: 2 * ends.count), at = [Int](repeating: 0, count: 2 * ends.count)
                for (v, r) in rot.enumerated() { for (i, h) in r.enumerated() { slot[h] = i; at[h] = v } }
                var seen = Set<Int>(), faces: [[Int]] = []
                for r in rot { for h0 in r where !seen.contains(h0) {
                    var face: [Int] = [], h = h0
                    repeat { seen.insert(h); face.append(h); let t = h ^ 1; let w = at[t]; h = rot[w][(slot[t] + rot[w].count - 1) % rot[w].count] } while h != h0
                    faces.append(face)
                } }
                return faces
            }
            var tails = out.map { Array($0.dropFirst()).sorted() }
            var planarFound = false
            var outerplanarFound = [Int: Bool]()   // component root -> some planar rotation has a face through all its vertices
            enumeration: while true {
                let rot = out.indices.map { out[$0].isEmpty ? [] : [out[$0][0]] + tails[$0] }
                let faces = faceOrbits(rot)
                if faces.count == euler {
                    planarFound = true
                    for face in faces {
                        let tailsOfFace = Set(face.map { $0 & 1 == 0 ? ends[$0 >> 1].0 : ends[$0 >> 1].1 })
                        let root = find(ends[face[0] >> 1].0)
                        if tailsOfFace.count == vertexCount[root]! { outerplanarFound[root] = true }
                    }
                }
                // Next combination: advance the first row whose tail has a next permutation.
                var v = 0
                while v < n {
                    var t = tails[v]
                    if let i = (0 ..< max(t.count - 1, 0)).last(where: { t[$0] < t[$0 + 1] }) {
                        let j = (i + 1 ..< t.count).last { t[$0] > t[i] }!
                        t.swapAt(i, j)
                        t[(i + 1)...].reverse()
                        tails[v] = t
                        break
                    }
                    tails[v] = t.sorted()
                    v += 1
                }
                if v == n { break enumeration }
            }
            let outerplanar = planarFound && edgeCount.keys.allSatisfy { outerplanarFound[$0] == true }
            #expect(graph.isPlanar == planarFound, "\(context)")
            #expect(graph.isOuterplanar == outerplanar, "\(context)")
            if planarFound {
                guard let embedding = graph.planarEmbedding() else { Issue.record("no embedding: \(context)"); return }
                #expect(graph.findKuratowskiSubgraph() == nil, "\(context)")
                // The embedding's rotation, as half-edges, is one of the model's planar rotations.
                var used = Set<Int>()
                let rot = listed.map { v in
                    Array(embedding.clockwiseIncidentEdges(of: v)).map { k -> Int in
                        let h = ends[k].0 == index[v]! && !used.contains(2 * k) ? 2 * k : 2 * k + 1
                        used.insert(h)
                        return h
                    }
                }
                #expect(rot.enumerated().allSatisfy { $0.element.sorted() == out[$0.offset].sorted() && $0.element.first == out[$0.offset].first }, "\(context)")
                // A loop's two ends are interchangeable: either reading gives the same faces.
                #expect(faceOrbits(rot).count == euler && embedding.faceCount == euler, "\(context)")
                #expect(embedding.faces.map(\.length).reduce(0, +) == 2 * pairs.count, "\(context)")
            } else {
                #expect(graph.planarEmbedding() == nil, "\(context)")
                guard let witness = graph.findKuratowskiSubgraph() else { Issue.record("no witness: \(context)"); return }
                var degree = [Int: Int]()
                for k in witness.edges { degree[pairs[k].0, default: 0] += 1; degree[pairs[k].1, default: 0] += 1 }
                let branch = degree.filter { $0.value != 2 }
                #expect(Set(branch.keys) == Set(witness.branchVertices), "\(context)")
                #expect(witness.kind == .k5 ? branch.values.allSatisfy { $0 == 4 } && branch.count == 5 : branch.values.allSatisfy { $0 == 3 } && branch.count == 6, "\(context)")
                #expect(witness.edges.allSatisfy { pairs[$0].0 != pairs[$0].1 } && witness.paths.map(\.edges).joined().sorted() == witness.edges, "\(context)")
            }
        }
    }

    @Test("On larger graphs exactly one witness exists and meets the definitions; a chord in a face keeps planarity and adds a face")
    func witnessesAndChords() async {
        let edges = zip(Gen.int(in: 0 ... 29), Gen.int(in: 0 ... 29)).array(of: 0 ... 70)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 2 ... 30), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = Pseudograph<Int>(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) on \(listed)"
            if let embedding = graph.planarEmbedding() {
                #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil, "\(context)")
                // Every edge position twice across the faces; each face a closed walk along real edges.
                var count = [Int](repeating: 0, count: pairs.count)
                for face in embedding.faces {
                    #expect(face.vertices.first == face.vertices.last && face.edges.count == face.vertices.count - 1, "\(context)")
                    for (k, p) in face.edges.enumerated() {
                        count[p] += 1
                        #expect(Set([pairs[p].0, pairs[p].1]) == Set([face.vertices[k], face.vertices[k + 1]]), "\(context)")
                    }
                }
                #expect(count.allSatisfy { $0 == 2 }, "\(context)")
                // A chord between two vertices of one face (a face of length at least 4, its first and
                // third vertices) keeps the graph planar and adds exactly one face.
                if let face = embedding.faces.first(where: { $0.length >= 4 && $0.vertices[0] != $0.vertices[2] }) {
                    pairs.append((face.vertices[0], face.vertices[2]))
                    let chorded = Pseudograph<Int>(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
                    #expect(chorded.isPlanar, "chord \(face.vertices[0])–\(face.vertices[2]) in \(face.vertices): \(context)")
                    #expect(chorded.planarEmbedding()?.faceCount == embedding.faceCount + 1, "\(context)")
                }
            } else {
                #expect(!graph.isPlanar && !graph.isOuterplanar, "\(context)")
                guard let witness = graph.findKuratowskiSubgraph() else { Issue.record("no witness: \(context)"); return }
                // Minimal: the witness alone is not planar; without any one of its edges it is.
                let alone = Pseudograph<Int>(vertices: listed, edges: witness.edges.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
                #expect(!alone.isPlanar, "\(context)")
                for drop in witness.edges.indices {
                    let rest = Pseudograph<Int>(vertices: listed, edges: witness.edges.enumerated().filter { $0.offset != drop }.map { UndirectedEdge(pairs[$0.element].0, pairs[$0.element].1) })
                    #expect(rest.isPlanar, "without witness edge \(witness.edges[drop]): \(context)")
                }
                let branch = witness.branchVertices
                #expect(branch.count == (witness.kind == .k5 ? 5 : 6) && witness.paths.count == (witness.kind == .k5 ? 10 : 9), "\(context)")
                var inner = Set<Int>()
                for path in witness.paths {
                    #expect(branch.contains(path.vertices.first!) && branch.contains(path.vertices.last!), "\(context)")
                    for v in path.vertices.dropFirst().dropLast() { #expect(!branch.contains(v) && inner.insert(v).inserted, "\(context)") }
                    for (k, p) in path.edges.enumerated() { #expect(Set([pairs[p].0, pairs[p].1]) == Set([path.vertices[k], path.vertices[k + 1]]), "\(context)") }
                }
                #expect(witness.paths.map(\.edges).joined().sorted() == witness.edges, "\(context)")
            }
        }
    }

    @Test("Cross-checks: isOuterplanar is the apex graph's planarity by Boyer–Myrvold; reversed labels keep both answers; a second call gives the same results; rightFace names the face face(from:alongEdgeAt:) walks")
    func crossChecks() async {
        let edges = zip(Gen.int(in: 0 ... 13), Gen.int(in: 0 ... 13)).array(of: 0 ... 45)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 14)) { raw, n in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) on \(n) vertices"
            let planar = graph.isPlanar
            let witness = graph.findKuratowskiSubgraph()
            #expect(planar == (witness == nil), "left-right and Boyer–Myrvold disagree: \(context)")
            // Outerplanar exactly when the graph plus an apex joined to every vertex is planar,
            // asked of the other engine.
            let apex = Pseudograph<Int>(vertices: 0 ... n, edges: (pairs + (0 ..< n).map { ($0, n) }).map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.isOuterplanar == (apex.findKuratowskiSubgraph() == nil), "\(context)")
            // The same graph with labels and edge order reversed.
            let reversed = Pseudograph<Int>(vertices: 0 ..< n, edges: pairs.reversed().map { UndirectedEdge(n - 1 - $0.0, n - 1 - $0.1) })
            #expect(reversed.isPlanar == planar && (reversed.findKuratowskiSubgraph() == nil) == planar && reversed.isOuterplanar == graph.isOuterplanar, "\(context)")
            #expect(graph.findKuratowskiSubgraph() == witness, "\(context)")
            guard let embedding = graph.planarEmbedding() else {
                #expect(!planar, "\(context)")
                return
            }
            let again = graph.planarEmbedding()!
            #expect((0 ..< n).allSatisfy { Array(again.clockwiseIncidentEdges(of: $0)) == Array(embedding.clockwiseIncidentEdges(of: $0)) }, "\(context)")
            // Each half-edge's face, walked from it, is the face rightFace names, rotated to start there.
            for v in 0 ..< n {
                for p in Set(embedding.clockwiseIncidentEdges(of: v)) {
                    let walk = embedding.face(from: v, alongEdgeAt: p)
                    let face = embedding.faces[embedding.rightFace(from: v, alongEdgeAt: p)]
                    #expect(walk.vertices.first == v && walk.vertices.last == v && walk.edges.first == p, "\(context)")
                    let start = face.edges.indices.filter { face.edges[$0] == p && face.vertices[$0] == v }
                    #expect(start.contains { Array(face.edges[$0...] + face.edges[..<$0]) == walk.edges }, "\(context)")
                }
            }
        }
    }
}
