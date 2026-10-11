// Large inputs, each inside a Task with a one-minute limit, meant to finish within seconds in a
// debug build (the benchmarks take timings). Regular graphs give colour refinement one class, so
// these need the refinement after every assignment (api.md, Algorithms): random 3- and 10-regular
// graphs and a grid against relabelled copies (permuted vertices, shuffled edges), with a
// degree-preserving switch that changes the triangle count as a non-isomorphic partner; relabelled
// random graphs whose mapping count must equal their automorphism count; pattern counts in a random
// graph against counting formulas (triangles, paths, 4-cycles); Weisfeiler–Leman on 10⁵ edges.
// Every mapping returned is checked edge by edge. Random graphs come from RandomGraphs and the
// package's seeded generator. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs
import RandomGraphs
import Testing

@Suite("Isomorphism on large inputs")
struct IsomorphismStressTests {
    @Test("A random 3-regular graph on 1,000 vertices: a relabelled copy is isomorphic, with as many mappings as automorphisms; a switched copy with other triangles is not", .timeLimit(.minutes(1)))
    func randomCubic() async throws {
        try await Task {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 1000, degree: 3, using: &generator)
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 11)
            let permutation = Array(0 ..< 1000).shuffled(using: &rng)
            let pairs = graph.edges.map { [$0.u, $0.v] }
            let copy = UndirectedAdjacencyList(vertices: (0 ..< 1000).shuffled(using: &rng), edges: pairs.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[0]], permutation[$0[1]]) })
            #expect(graph.isIsomorphic(to: copy))
            let mapping = try #require(graph.isomorphism(to: copy))
            let images = Dictionary(uniqueKeysWithValues: graph.vertices.map { ($0, mapping.image(of: $0)) })
            #expect(Set(images.values).count == 1000)
            #expect(graph.edges.allSatisfy { copy.contains(edge: UndirectedEdge(images[$0.u]!, images[$0.v]!)) })
            #expect(Array(graph.isomorphisms(to: copy)).count == Array(graph.isomorphisms(to: graph)).count)
            // A switch: edges a–b and c–d become a–c and b–d, keeping every degree. Take the first
            // switch whose new edge a–c closes a triangle a–w–c (w a neighbour of a other than b,
            // c a neighbour of w) and that keeps the graph simple and changes the triangle count,
            // so the switched graph is certainly not isomorphic.
            let adjacency = (0 ..< 1000).map { Set(graph.neighbors(of: $0)) }
            func triangles(_ rows: [Set<Int>]) -> Int {
                var count = 0
                for u in 0 ..< rows.count { for v in rows[u] where v > u { count += rows[u].intersection(rows[v]).filter { $0 > v }.count } }
                return count
            }
            let before = triangles(adjacency)
            var switched: [Set<Int>]? = nil
            search: for a in 0 ..< 1000 {
                for b in adjacency[a].sorted() {
                    for w in adjacency[a].sorted() where w != b {
                        for c in adjacency[w].sorted() where c != a && c != b && !adjacency[a].contains(c) {
                            for d in adjacency[c].sorted() where ![a, b, w].contains(d) && !adjacency[b].contains(d) {
                                var rows = adjacency
                                rows[a].remove(b); rows[b].remove(a); rows[c].remove(d); rows[d].remove(c)
                                rows[a].insert(c); rows[c].insert(a); rows[b].insert(d); rows[d].insert(b)
                                if triangles(rows) != before {
                                    switched = rows
                                    break search
                                }
                            }
                        }
                    }
                }
            }
            let rows = try #require(switched)
            var other: [UndirectedEdge<Int>] = []
            for u in 0 ..< 1000 { for v in rows[u] where v > u { other.append(UndirectedEdge(u, v)) } }
            let switchedGraph = UndirectedAdjacencyList(vertices: 0 ..< 1000, edges: other)
            #expect(switchedGraph.edgeCount == 1500 && (0 ..< 1000).allSatisfy { switchedGraph.degree(of: $0) == 3 })
            #expect(!graph.isIsomorphic(to: switchedGraph))
            #expect(graph.isomorphism(to: switchedGraph) == nil)
        }.value
    }

    @Test("A random 10-regular graph on 1,000 vertices against a relabelled copy: a valid mapping", .timeLimit(.minutes(1)))
    func randomTenRegular() async throws {
        try await Task {
            var generator = Xoshiro256StarStar(seed: 2)
            let graph = Pseudograph<Int>.randomRegular(vertexCount: 1000, degree: 10, using: &generator)
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 12)
            let permutation = Array(0 ..< 1000).shuffled(using: &rng)
            let copy = Pseudograph(vertices: 0 ..< 1000, edges: graph.edges.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.v], permutation[$0.u]) })
            let mapping = try #require(graph.isomorphism(to: copy))
            let images = graph.vertices.map { mapping.image(of: $0) }
            #expect(Set(images).count == 1000)
            #expect(graph.edges.allSatisfy { copy.contains(edge: UndirectedEdge(images[$0.u], images[$0.v])) })
            #expect(graph.isIsomorphic(to: copy) && copy.isIsomorphic(to: graph))
        }.value
    }

    @Test("The 40 × 40 grid against a relabelled copy: exactly its 8 symmetries, each valid; the 40 × 40 torus against a relabelled copy", .timeLimit(.minutes(1)))
    func grid() async throws {
        try await Task {
            let side = 40
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    if j + 1 < side { edges.append(UndirectedEdge(i * side + j, i * side + j + 1)) }
                    if i + 1 < side { edges.append(UndirectedEdge(i * side + j, (i + 1) * side + j)) }
                }
            }
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 13)
            let n = side * side
            let permutation = Array(0 ..< n).shuffled(using: &rng)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            let copy = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.u], permutation[$0.v]) })
            let all = Array(graph.isomorphisms(to: copy))
            #expect(all.count == 8 && Set(all).count == 8)
            for mapping in all {
                #expect(Set(mapping.images).count == n)
                #expect(graph.edges.allSatisfy { copy.contains(edge: UndirectedEdge(mapping.image(of: $0.u), mapping.image(of: $0.v))) })
            }
            // The torus is vertex-transitive (4-regular, one class after refinement): 8 · 40² symmetries.
            var torus: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    torus.append(UndirectedEdge(i * side + j, i * side + (j + 1) % side))
                    torus.append(UndirectedEdge(i * side + j, ((i + 1) % side) * side + j))
                }
            }
            let ring = UndirectedAdjacencyList(vertices: 0 ..< n, edges: torus)
            let ringCopy = UndirectedAdjacencyList(vertices: 0 ..< n, edges: torus.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.u], permutation[$0.v]) })
            let mapping = try #require(ring.isomorphism(to: ringCopy))
            #expect(ring.edges.allSatisfy { ringCopy.contains(edge: UndirectedEdge(mapping.image(of: $0.u), mapping.image(of: $0.v))) })
        }.value
    }

    @Test("40 random graphs on 8 – 29 vertices against relabelled copies: as many mappings as automorphisms, every one valid", .timeLimit(.minutes(1)))
    func relabelledRandomGraphs() async {
        await Task {
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 14)
            for trial in 0 ..< 40 {
                let n = Int.random(in: 8 ... 29, using: &rng)
                var pairs = Set<[Int]>()
                for _ in 0 ..< Int.random(in: n ... 3 * n, using: &rng) {
                    let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                    if u != v { pairs.insert([min(u, v), max(u, v)]) }
                }
                let list = pairs.sorted { $0.lexicographicallyPrecedes($1) }
                let permutation = Array(0 ..< n).shuffled(using: &rng)
                let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: list.map { UndirectedEdge($0[0], $0[1]) })
                let copy = UndirectedAdjacencyList(vertices: 0 ..< n, edges: list.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[1]], permutation[$0[0]]) })
                let automorphisms = Array(graph.isomorphisms(to: graph))
                let mappings = Array(graph.isomorphisms(to: copy))
                #expect(mappings.count == automorphisms.count && Set(mappings).count == mappings.count, "trial \(trial): \(list)")
                #expect(mappings.contains { Array($0.images) == permutation }, "trial \(trial)")
                for mapping in mappings {
                    let images = Array(mapping.images)
                    #expect(Set(images).count == n && list.allSatisfy { copy.contains(edge: UndirectedEdge(images[$0[0]], images[$0[1]])) }, "trial \(trial)")
                }
            }
        }.value
    }

    @Test("Pattern counts in a random graph (200 vertices, 1,500 edges) against counting formulas: triangles, paths of length 2, 4-cycles", .timeLimit(.minutes(1)))
    func patternCounts() async {
        await Task {
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 15)
            let n = 200
            var pairs = Set<[Int]>()
            while pairs.count < 1500 {
                let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                if u != v { pairs.insert([min(u, v), max(u, v)]) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.shuffled(using: &rng).map { UndirectedEdge($0[0], $0[1]) })
            var rows = [Set<Int>](repeating: [], count: n)
            for p in pairs { rows[p[0]].insert(p[1]); rows[p[1]].insert(p[0]) }
            var triangles = 0
            for u in 0 ..< n { for v in rows[u] where v > u { triangles += rows[u].intersection(rows[v]).filter { $0 > v }.count } }
            let ordered = rows.map { $0.count * ($0.count - 1) }.reduce(0, +)
            // A 4-cycle is two vertices with two common neighbours, counted once from each diagonal.
            var squares = 0
            for u in 0 ..< n { for w in u + 1 ..< n { let c = rows[u].intersection(rows[w]).count; squares += c * (c - 1) / 2 } }
            squares /= 2
            let triangle = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            let path = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let square = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            #expect(triangles > 0 && squares > 0)
            #expect(Array(triangle.monomorphisms(to: graph)).count == 6 * triangles)
            #expect(Array(triangle.subgraphIsomorphisms(to: graph)).count == 6 * triangles)
            #expect(Array(path.monomorphisms(to: graph)).count == ordered)
            // An induced path of length 2 is one whose ends are not adjacent: every triangle holds 6.
            #expect(Array(path.subgraphIsomorphisms(to: graph)).count == ordered - 6 * triangles)
            let embeddings = Array(square.monomorphisms(to: graph))
            #expect(embeddings.count == 8 * squares && Set(embeddings).count == embeddings.count)
            #expect(embeddings.allSatisfy { m in square.edges.allSatisfy { rows[m.image(of: $0.u)].contains(m.image(of: $0.v)) } })
        }.value
    }

    @Test("A random digraph (500 vertices, 2,500 arcs) against a relabelled copy, and against its converse's copy", .timeLimit(.minutes(1)))
    func randomDigraph() async throws {
        try await Task {
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 16)
            let n = 500
            var arcs = Set<[Int]>()
            while arcs.count < 2500 {
                let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                if u != v { arcs.insert([u, v]) }
            }
            let list = arcs.sorted { $0.lexicographicallyPrecedes($1) }
            let permutation = Array(0 ..< n).shuffled(using: &rng)
            let graph = AdjacencyList(vertices: 0 ..< n, edges: list.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let copy = AdjacencyList(vertices: 0 ..< n, edges: list.shuffled(using: &rng).map { DirectedEdge(from: permutation[$0[0]], to: permutation[$0[1]]) })
            let mapping = try #require(graph.isomorphism(to: copy))
            #expect(Set(mapping.images).count == n)
            #expect(list.allSatisfy { copy.contains(edge: DirectedEdge(from: mapping.image(of: $0[0]), to: mapping.image(of: $0[1]))) })
            // The converse has the same degrees in reverse; it is isomorphic to the copy's converse.
            let converse = AdjacencyList(vertices: 0 ..< n, edges: list.map { DirectedEdge(from: $0[1], to: $0[0]) })
            let copyConverse = AdjacencyList(vertices: 0 ..< n, edges: list.map { DirectedEdge(from: permutation[$0[1]], to: permutation[$0[0]]) })
            #expect(converse.isIsomorphic(to: copyConverse))
        }.value
    }

    @Test("Weisfeiler–Leman on 20,000 vertices and 10⁵ edges: a relabelled copy hashes equal; moving one edge end changes the hash", .timeLimit(.minutes(1)))
    func weisfeilerLehmanLarge() async {
        await Task {
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 17)
            let n = 20_000
            var pairs: [[Int]] = []
            while pairs.count < 100_000 {
                let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                if u != v { pairs.append([u, v]) }
            }
            let permutation = Array(0 ..< n).shuffled(using: &rng)
            let graph = Pseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
            let copy = Pseudograph(vertices: 0 ..< n, edges: pairs.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[1]], permutation[$0[0]]) })
            let hash = graph.weisfeilerLehmanGraphHash()
            #expect(copy.weisfeilerLehmanGraphHash() == hash)
            // Move the first edge's second end to a vertex of another degree: the degree histogram
            // (round 1) changes.
            let degree = graph.degree(of: pairs[0][1])
            let other = (0 ..< n).first { $0 != pairs[0][0] && graph.degree(of: $0) != degree - 1 && graph.degree(of: $0) != degree }!
            let moved = Pseudograph(vertices: 0 ..< n, edges: [UndirectedEdge(pairs[0][0], other)] + pairs.dropFirst().map { UndirectedEdge($0[0], $0[1]) })
            #expect(moved.weisfeilerLehmanGraphHash() != hash)
            let hashes = graph.weisfeilerLehmanSubgraphHashes(), copyHashes = copy.weisfeilerLehmanSubgraphHashes()
            #expect((0 ..< n).allSatisfy { copyHashes.hashes(of: permutation[$0]) == hashes.hashes(of: $0) })
        }.value
    }
}
