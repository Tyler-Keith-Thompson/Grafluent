// Large shapes, each with a one-minute limit, meant to finish within seconds in a debug build; the
// benchmarks take timings. Every expected value is known by construction: a triangulated grid (each
// square split by a seeded diagonal, the four corner squares split through the corner, so no chord
// joins two outer vertices and the graph is 3-connected: its embedding is unique, 2(r − 1)(c − 1)
// triangles and one outer face), the same grid with an apex joined to its outer cycle (maximal
// planar, a Delaunay triangulation's shape), a seeded stacked triangulation, a plain grid, and each
// made non-planar by one edge between two vertices with no common face. Planar results are checked
// against the definitions (each rotation a permutation starting at the first incident edge, every
// position on two face sides, Euler's count); witnesses are checked to be subdivisions. See
// README.md.

import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("Planarity at scale")
struct PlanarityStressTests {
    @Test("A 120 × 120 triangulated grid: planar, unique embedding, triangles and one outer face", .timeLimit(.minutes(1)))
    func triangulatedGrid() throws {
        let r = 120, c = 120
        var rng = SeededRandomNumberGenerator(seed: 31)
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< r { for j in 0 ..< c {
            let v = i * c + j
            if j + 1 < c { edges.append(UndirectedEdge(v, v + 1)) }
            if i + 1 < r { edges.append(UndirectedEdge(v, v + c)) }
            if i + 1 < r && j + 1 < c {
                let corner = (i == 0 || i == r - 2) && (j == 0 || j == c - 2)
                // Through the corner for the corner squares: (0,0)–(1,1) and (0,c-1)–(1,c-2), and so on.
                let falling = corner ? (i == 0) == (j == 0) : Bool.random(using: &rng)
                edges.append(falling ? UndirectedEdge(v, v + c + 1) : UndirectedEdge(v + 1, v + c))
            }
        } }
        let graph = Pseudograph<Int>(vertices: 0 ..< r * c, edges: edges)
        #expect(graph.isPlanar)
        #expect(!graph.isOuterplanar)
        #expect(graph.findKuratowskiSubgraph() == nil)
        let embedding = try #require(graph.planarEmbedding())
        let n = r * c, m = edges.count
        #expect(embedding.faceCount == m - n + 2)
        let lengths = embedding.faces.map(\.length).sorted(by: >)
        #expect(lengths.first == 2 * (r - 1) + 2 * (c - 1) && lengths.dropFirst().allSatisfy { $0 == 3 } && lengths.count == 2 * (r - 1) * (c - 1) + 1)
        var sides = [Int](repeating: 0, count: m)
        for face in embedding.faces { for p in face.edges { sides[p] += 1 } }
        #expect(sides.allSatisfy { $0 == 2 })
        for v in stride(from: 0, to: n, by: 7) {
            let row = Array(embedding.clockwiseIncidentEdges(of: v)), incident = Array(graph.incidentEdges(of: v))
            #expect(row.sorted() == incident.sorted() && row.first == incident.first)
        }
    }

    @Test("A 100 × 100 triangulated grid plus an apex on its outer cycle: maximal planar; one more edge makes it non-planar", .timeLimit(.minutes(1)))
    func maximalPlanarGrid() throws {
        let r = 100, c = 100
        var rng = SeededRandomNumberGenerator(seed: 5)
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< r { for j in 0 ..< c {
            let v = i * c + j
            if j + 1 < c { edges.append(UndirectedEdge(v, v + 1)) }
            if i + 1 < r { edges.append(UndirectedEdge(v, v + c)) }
            if i + 1 < r && j + 1 < c { edges.append(Bool.random(using: &rng) ? UndirectedEdge(v, v + c + 1) : UndirectedEdge(v + 1, v + c)) }
        } }
        let apex = r * c
        for i in 0 ..< r { for j in 0 ..< c where i == 0 || j == 0 || i == r - 1 || j == c - 1 { edges.append(UndirectedEdge(apex, i * c + j)) } }
        let n = r * c + 1
        #expect(edges.count == 3 * n - 6)
        let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
        #expect(graph.isPlanar)
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.faceCount == 2 * n - 4 && embedding.faces.allSatisfy { $0.length == 3 })
        // Opposite corners of the grid have no common face.
        var near = edges
        near.append(UndirectedEdge(0, r * c - 1))
        let nonPlanar = Pseudograph<Int>(vertices: 0 ..< n, edges: near)
        #expect(!nonPlanar.isPlanar && nonPlanar.planarEmbedding() == nil)
    }

    @Test("A triangulated grid plus one edge between far interior vertices: not planar, with a valid witness", .timeLimit(.minutes(1)))
    func nearPlanarGrid() throws {
        let r = 30, c = 30
        var rng = SeededRandomNumberGenerator(seed: 8)
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< r { for j in 0 ..< c {
            let v = i * c + j
            if j + 1 < c { edges.append(UndirectedEdge(v, v + 1)) }
            if i + 1 < r { edges.append(UndirectedEdge(v, v + c)) }
            if i + 1 < r && j + 1 < c {
                let corner = (i == 0 || i == r - 2) && (j == 0 || j == c - 2)
                let falling = corner ? (i == 0) == (j == 0) : Bool.random(using: &rng)
                edges.append(falling ? UndirectedEdge(v, v + c + 1) : UndirectedEdge(v + 1, v + c))
            }
        } }
        let planar = Pseudograph<Int>(vertices: 0 ..< r * c, edges: edges)
        #expect(planar.isPlanar)
        // (3, 3) and (26, 26): interior, far apart, so on no common face of the unique embedding.
        edges.append(UndirectedEdge(3 * c + 3, 26 * c + 26))
        let graph = Pseudograph<Int>(vertices: 0 ..< r * c, edges: edges)
        #expect(!graph.isPlanar && !graph.isOuterplanar && graph.planarEmbedding() == nil)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.edges.contains(edges.count - 1))   // every witness needs the new edge
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        let branch = witness.branchVertices
        #expect(branch.count == (witness.kind == .k5 ? 5 : 6) && witness.paths.count == (witness.kind == .k5 ? 10 : 9))
        var inner = Set<Int>(), used: [Int] = []
        for path in witness.paths {
            #expect(branch.contains(path.vertices.first!) && branch.contains(path.vertices.last!))
            for v in path.vertices.dropFirst().dropLast() { #expect(!branch.contains(v) && inner.insert(v).inserted) }
            for (k, p) in path.edges.enumerated() { #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]])) }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
    }

    @Test("A stacked triangulation of 20 000 vertices: maximal planar; plus one edge, a witness through the new edge", .timeLimit(.minutes(1)))
    func stackedTriangulation() throws {
        // tri(n, s) from the catalog: each new vertex k goes into a face chosen by the LCG and is
        // joined to its three corners.
        let n = 20_000
        var state: UInt64 = 12
        var edges = [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)]
        var faces = [(0, 1, 2), (0, 1, 2)]
        for k in 3 ..< n {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let i = Int((state >> 33) % UInt64(faces.count))
            let (a, b, c) = faces[i]
            edges += [UndirectedEdge(a, k), UndirectedEdge(b, k), UndirectedEdge(c, k)]
            faces[i] = (a, b, k)
            faces += [(b, c, k), (a, c, k)]
        }
        let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
        #expect(edges.count == 3 * n - 6 && graph.isPlanar)
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.faceCount == 2 * n - 4 && embedding.faces.allSatisfy { $0.length == 3 })
        // The vertex placed last and vertex 0, unless adjacent, share no face; otherwise the next one.
        let far = (3 ..< n).reversed().first { v in !graph.neighbors(of: 0).contains(v) }!
        let nonPlanar = Pseudograph<Int>(vertices: 0 ..< n, edges: edges + [UndirectedEdge(0, far)])
        #expect(!nonPlanar.isPlanar)
        // The witness on the first 3,000 vertices (the induced triangulation is maximal planar too).
        let prefix = Array(edges.prefix(3 * 3_000 - 6))
        let besideZero = Set(prefix.filter { $0.u == 0 }.map(\.v))
        let small = Pseudograph<Int>(vertices: 0 ..< 3_000, edges: prefix + [UndirectedEdge(0, (3 ..< 3_000).reversed().first { !besideZero.contains($0) }!)])
        let witness = try #require(small.findKuratowskiSubgraph())
        #expect(witness.edges.contains(small.edgeCount - 1))
        #expect(witness.paths.map(\.edges).joined().sorted() == witness.edges)
        #expect(witness.branchVertices.count == (witness.kind == .k5 ? 5 : 6))
    }

    @Test("A 300 × 300 grid: planar, (r − 1)(c − 1) squares and one outer face; plus a far edge, not planar", .timeLimit(.minutes(1)))
    func grid() throws {
        let r = 300, c = 300
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< r { for j in 0 ..< c {
            let v = i * c + j
            if j + 1 < c { edges.append(UndirectedEdge(v, v + 1)) }
            if i + 1 < r { edges.append(UndirectedEdge(v, v + c)) }
        } }
        let graph = Pseudograph<Int>(vertices: 0 ..< r * c, edges: edges)
        #expect(graph.isPlanar)
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.faceCount == (r - 1) * (c - 1) + 1)
        let lengths = embedding.faces.map(\.length).sorted(by: >)
        #expect(lengths.first == 2 * (r - 1) + 2 * (c - 1) && lengths.dropFirst().allSatisfy { $0 == 4 })
        // Two interior vertices far apart: the grid is a subdivision of a 3-connected graph here.
        let nonPlanar = Pseudograph<Int>(vertices: 0 ..< r * c, edges: edges + [UndirectedEdge(10 * c + 10, 200 * c + 250)])
        #expect(!nonPlanar.isPlanar && nonPlanar.planarEmbedding() == nil)
    }
}
