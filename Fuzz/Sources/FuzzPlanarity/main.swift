// Planarity on random multigraphs (loops and parallel edges, vertices listed in a random order):
// the left-right test (`isPlanar`, `planarEmbedding()`) and Boyer–Myrvold
// (`findKuratowskiSubgraph()`) agree. An embedding is checked against the definitions: each
// clockwise order a permutation of the incident edges starting at the first, the neighbours
// across them, faces traced here from the rotation (the slot before the twin) equal to `faces`
// and to `face(from:alongEdgeAt:)` and `rightFace(from:alongEdgeAt:)` from every half-edge, and
// Euler's count per component with an edge; `dualGraph()` joins, for each edge, the traced faces
// on its two sides. A witness is a subdivision of its kind made of the
// graph's edges (ascending, no loop, one copy of a pair), its paths use every edge once between
// branch vertices, and it is minimal: without any one edge it is planar. `isOuterplanar` is
// Boyer–Myrvold's answer on the graph plus an apex. A second call returns the same results.

import FuzzSupport
import GraphProtocols
import Multigraphs
import Planarity

@main
enum FuzzPlanarity {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 12)
        // Vertex labels: a permutation of 0..<n drawn from the input, listed in that order.
        var listed = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { listed.swapAt(i, input.int(below: i + 1)) }
        var pairs: [(Int, Int)] = []
        while !input.isEmpty, pairs.count < 40 {
            let a = input.int(below: n), b = input.int(below: n)
            pairs.append((a, b))
        }
        let graph = Pseudograph<Int>(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let planar = graph.isPlanar
        let embedding = graph.planarEmbedding()
        let witness = graph.findKuratowskiSubgraph()
        check(planar == (embedding != nil), "isPlanar \(planar) but planarEmbedding() \(embedding == nil ? "nil" : "found"): \(pairs)")
        check(planar == (witness == nil), "isPlanar \(planar) but findKuratowskiSubgraph() \(witness == nil ? "nil" : "found"): \(pairs)")
        let apex = Pseudograph<Int>(vertices: 0 ... n, edges: (pairs + (0 ..< n).map { ($0, n) }).map { UndirectedEdge($0.0, $0.1) })
        check(graph.isOuterplanar == (apex.findKuratowskiSubgraph() == nil), "isOuterplanar disagrees with the apex graph: \(pairs)")
        if let embedding {
            checkEmbedding(graph, embedding, pairs, listed)
            let again = graph.planarEmbedding()!
            for v in listed {
                check(Array(again.clockwiseIncidentEdges(of: v)) == Array(embedding.clockwiseIncidentEdges(of: v)), "embedding not deterministic: \(pairs)")
            }
        }
        if let witness {
            checkWitness(witness, pairs, listed)
            check(graph.findKuratowskiSubgraph() == witness, "witness not deterministic: \(pairs)")
        }
    }

    static func checkEmbedding(_ graph: Pseudograph<Int>, _ embedding: PlanarEmbedding<Pseudograph<Int>>, _ pairs: [(Int, Int)], _ listed: [Int]) {
        // The rotation, and each position's two slots (vertex, index in its row).
        var rotation: [Int: [Int]] = [:]
        var slots = [[(v: Int, i: Int)]](repeating: [], count: pairs.count)
        for v in listed {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            check(row.sorted() == incident.sorted() && row.first == incident.first, "rotation of \(v) \(row) is not incidentEdges \(incident) from its first: \(pairs)")
            let across = Array(embedding.clockwiseNeighbors(of: v))
            check(across.count == row.count, "clockwiseNeighbors count at \(v): \(pairs)")
            for (i, p) in row.enumerated() {
                let (a, b) = pairs[p]
                check(across[i] == (a == v ? b : a), "clockwiseNeighbors at \(v): \(pairs)")
                slots[p].append((v, i))
            }
            rotation[v] = row
        }
        check(slots.allSatisfy { $0.count == 2 }, "some position not embedded twice: \(pairs)")
        // Faces: the orbits of "the slot before the twin", met in vertex and row order.
        var faceOf: [Int: [Int]] = rotation.mapValues { [Int](repeating: -1, count: $0.count) }
        var traced: [(vertices: [Int], edges: [Int])] = []
        for v in listed {
            for i in rotation[v]!.indices where faceOf[v]![i] == -1 {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (v, i)
                repeat {
                    faceOf[x]![y] = traced.count
                    vertices.append(x)
                    let p = rotation[x]![y]
                    edges.append(p)
                    let twin = slots[p][0].v == x && slots[p][0].i == y ? slots[p][1] : slots[p][0]
                    let length = rotation[twin.v]!.count
                    (x, y) = (twin.v, (twin.i + length - 1) % length)
                } while (x, y) != (v, i)
                traced.append((vertices + [v], edges))
            }
        }
        check(embedding.faceCount == traced.count, "faceCount \(embedding.faceCount), traced \(traced.count): \(pairs)")
        for (k, face) in embedding.faces.enumerated() where k < traced.count {
            check(face.vertices == traced[k].vertices && face.edges == traced[k].edges, "face \(k) differs from the traced orbit: \(pairs)")
        }
        // Euler's formula per component with an edge: f = m − n′ + 2c.
        var parent = Dictionary(uniqueKeysWithValues: listed.map { ($0, $0) })
        func find(_ x: Int) -> Int { var x = x; while parent[x]! != x { x = parent[x]! }; return x }
        for (a, b) in pairs { parent[find(a)] = find(b) }
        let withEdges = Set(pairs.flatMap { [$0.0, $0.1] })
        let components = Set(withEdges.map(find)).count
        check(traced.count == pairs.count - withEdges.count + 2 * components, "Euler's formula fails: \(pairs)")
        // The dual graph: a vertex per traced face, edge p from the face of its first slot (in
        // vertex and row order) to the face of the other.
        let dual = embedding.dualGraph()
        check(Array(dual.vertices) == Array(0 ..< traced.count) && dual.edgeCount == pairs.count, "dualGraph counts: \(pairs)")
        for p in pairs.indices where p < dual.edgeCount {
            let a = slots[p][0], b = slots[p][1]
            let edge = dual.edges[p]
            check(edge.u == faceOf[a.v]![a.i] && edge.v == faceOf[b.v]![b.i], "dualGraph edge \(p) is \(edge): \(pairs)")
        }
        // Every half-edge: face(from:alongEdgeAt:) is its orbit, rightFace its position.
        for v in listed {
            let row = rotation[v]!
            for (i, p) in row.enumerated() where row.firstIndex(of: p) == i {
                let walk = embedding.face(from: v, alongEdgeAt: p)
                let f = faceOf[v]![i]
                check(embedding.rightFace(from: v, alongEdgeAt: p) == f, "rightFace from \(v) along \(p): \(pairs)")
                check(walk.vertices.first == v && walk.vertices.last == v && walk.edges.first == p, "face(from: \(v), alongEdgeAt: \(p)) does not start there: \(pairs)")
                check(walk.edges.count == traced[f].edges.count && Set(walk.edges) == Set(traced[f].edges), "face(from: \(v), alongEdgeAt: \(p)) is not its orbit: \(pairs)")
            }
        }
    }

    static func checkWitness(_ witness: KuratowskiSubgraph<Pseudograph<Int>>, _ pairs: [(Int, Int)], _ listed: [Int]) {
        check(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count, "witness edges not ascending: \(pairs)")
        var degree: [Int: Int] = [:]
        var seenPairs = Set<[Int]>()
        for p in witness.edges {
            let (a, b) = pairs[p]
            check(a != b, "a loop in the witness: \(pairs)")
            check(seenPairs.insert([min(a, b), max(a, b)]).inserted, "two copies of a pair in the witness: \(pairs)")
            degree[a, default: 0] += 1
            degree[b, default: 0] += 1
        }
        let isK5 = witness.kind == .k5
        let branch = degree.filter { $0.value != 2 }
        check(branch.count == (isK5 ? 5 : 6) && branch.values.allSatisfy { $0 == (isK5 ? 4 : 3) }, "branch degrees wrong for \(witness.kind): \(pairs)")
        check(Set(branch.keys) == Set(witness.branchVertices) && witness.branchVertices.count == branch.count, "branchVertices: \(pairs)")
        let position = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
        if isK5 {
            check(witness.branchVertices.map { position[$0]! } == witness.branchVertices.map { position[$0]! }.sorted(), "K5 branch vertices out of order: \(pairs)")
        }
        // The paths: one per joined pair, between branch vertices, internally disjoint, every edge once.
        let b = witness.branchVertices
        var expected: [[Int]] = []
        if isK5 {
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { expected.append([b[i], b[j]]) } }
        } else {
            for i in 0 ..< 3 { for j in 3 ..< 6 { expected.append([b[i], b[j]]) } }
        }
        check(witness.paths.map { [$0.vertices.first!, $0.vertices.last!] } == expected, "paths do not join the branch pairs in order: \(pairs)")
        var inner = Set<Int>()
        for path in witness.paths {
            for v in path.vertices.dropFirst().dropLast() { check(degree[v] == 2 && inner.insert(v).inserted, "paths not internally disjoint: \(pairs)") }
            for (k, p) in path.edges.enumerated() {
                check(Set([pairs[p].0, pairs[p].1]) == Set([path.vertices[k], path.vertices[k + 1]]), "path edge does not join its vertices: \(pairs)")
            }
        }
        check(witness.paths.map(\.edges).joined().sorted() == witness.edges, "paths do not use every witness edge once: \(pairs)")
        // Minimal: without any one edge, the witness is planar.
        for drop in witness.edges {
            let rest = Pseudograph<Int>(vertices: listed, edges: witness.edges.filter { $0 != drop }.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
            check(rest.isPlanar, "witness not minimal without \(drop): \(pairs)")
        }
    }
}
