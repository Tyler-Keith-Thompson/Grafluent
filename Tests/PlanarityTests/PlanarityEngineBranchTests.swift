// Small graphs that reach particular branches of the two engines, each a small random graph where
// a bug in that branch changes the outcome: the left-right test's second-lowest return point when
// an edge returns as low as its parent edge, and when it returns higher than the parent edge's
// second-lowest return point so far; the Walkdown's short-circuit beside the root; and the
// Kuratowski isolation's x–y path past a second x-side attachment, minor C with the x–y path
// attached above both x and y, and minor E2. Each is checked against the definitions, not pinned to
// one witness. See README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("Planarity: engine branches on small graphs")
struct PlanarityEngineBranchTests {
    @Test("Left-right: an edge returns exactly as low as its parent edge, so the second-lowest return points merge")
    func equalLowpoints() throws {
        let pairs = [(1, 6), (8, 6), (5, 7), (3, 7), (0, 7), (7, 2), (1, 4), (5, 3), (3, 8), (0, 4), (1, 2), (7, 8), (5, 2)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isPlanar)
        #expect(graph.findKuratowskiSubgraph() == nil)
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.faceCount == pairs.count - 9 + 2)
        var sides = [Int](repeating: 0, count: pairs.count)
        for face in embedding.faces { for p in face.edges { sides[p] += 1 } }
        #expect(sides.allSatisfy { $0 == 2 })
    }

    @Test("Left-right: an edge returning above its parent edge's lowpoint keeps the lower second-lowest return point")
    func secondLowestReturnPointAbove() throws {
        // A planar graph where a later edge out of a vertex returns higher than the parent edge's
        // second-lowest return point so far. Raising that point to the later edge's return point
        // makes the parent edge look non-chordal, and the wrong nesting order then rejects the
        // graph. Found among 30 000 random graphs and reduced edge by edge.
        let pairs = [(0, 2), (0, 3), (0, 7), (1, 2), (1, 10), (1, 11), (1, 12), (2, 8), (2, 12), (3, 10), (4, 12), (5, 9),
                     (5, 12), (6, 7), (6, 9), (7, 8), (7, 11)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 13, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.isPlanar)
        #expect(graph.findKuratowskiSubgraph() == nil)
        let embedding = try #require(graph.planarEmbedding())
        #expect(embedding.faceCount == pairs.count - 13 + 2)
        var sides = [Int](repeating: 0, count: pairs.count)
        for face in embedding.faces { for p in face.edges { sides[p] += 1 } }
        #expect(sides.allSatisfy { $0 == 2 })
    }

    @Test("Kuratowski isolation: the x–y path keeps only what follows its last attachment on the x side")
    func xyPathAfterTheLastXAttachment() throws {
        // A non-planar graph whose x–y path search meets the x side twice: the detour walked before
        // the second attachment must be unmarked, or it stays in the witness, which then fails the
        // library's own check.
        let pairs = [(0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 6), (2, 3), (2, 5), (2, 6), (2, 7), (2, 8),
                     (3, 7), (3, 8), (4, 7), (5, 7), (6, 7), (7, 8), (7, 9)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isPlanar)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.paths.count == (witness.kind == .k5 ? 10 : 9) && witness.paths.map(\.edges).joined().sorted() == witness.edges)
        let alone = Pseudograph<Int>(vertices: 0 ..< 10, edges: witness.edges.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
        #expect(!alone.isPlanar)
        for drop in witness.edges {
            let rest = Pseudograph<Int>(vertices: 0 ..< 10, edges: witness.edges.filter { $0 != drop }.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
            #expect(rest.isPlanar, "without \(drop)")
        }
    }

    @Test("Kuratowski isolation: minor C with the x–y path attached above both x and y")
    func minorCHighOnTheYSide() throws {
        let pairs = [(8, 3), (7, 2), (3, 0), (7, 6), (6, 4), (5, 7), (4, 0), (3, 2), (6, 3), (8, 5), (5, 0), (1, 4), (8, 1)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isPlanar)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.kind == .k33)
        #expect(witness.paths.count == 9 && witness.paths.map(\.edges).joined().sorted() == witness.edges)
        for drop in witness.edges {
            let rest = Pseudograph<Int>(vertices: 0 ..< 9, edges: witness.edges.filter { $0 != drop }.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
            #expect(rest.isPlanar, "without \(drop)")
        }
    }

    @Test("Kuratowski isolation: minor E2, reduced to minor A at the future-pertinent vertex's ancestor")
    func minorE2() throws {
        let pairs = [(6, 5), (2, 0), (8, 4), (8, 3), (4, 9), (9, 2), (1, 5), (1, 7), (3, 9), (7, 4), (3, 6), (2, 8), (1, 2), (6, 4), (0, 3), (8, 6)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isPlanar)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.kind == .k33)
        #expect(witness.paths.count == 9 && witness.paths.map(\.edges).joined().sorted() == witness.edges)
        for drop in witness.edges {
            let rest = Pseudograph<Int>(vertices: 0 ..< 10, edges: witness.edges.filter { $0 != drop }.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
            #expect(rest.isPlanar, "without \(drop)")
        }
    }

    @Test("Walkdown: a stopping vertex beside the root on the other side keeps three vertices on the external face")
    func walkdownStoppingVertexBesideTheRoot() throws {
        // The smallest graph found whose Walkdown meets a stopping vertex that is already the
        // root's neighbour on the other side of the external face. Short-circuiting straight to it
        // would leave a two-vertex face whose links cannot be told apart, and the isolation would
        // then fail.
        let pairs = [(0, 10), (1, 9), (6, 10), (4, 9), (11, 4), (1, 7), (5, 8), (3, 5), (9, 7), (7, 10), (11, 5), (8, 7),
                     (2, 0), (4, 1), (11, 2), (8, 6), (3, 0), (2, 8)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(!graph.isPlanar)
        let witness = try #require(graph.findKuratowskiSubgraph())
        #expect(witness.kind == .k33)
        var degree = [Int: Int]()
        for p in witness.edges {
            degree[pairs[p].0, default: 0] += 1
            degree[pairs[p].1, default: 0] += 1
        }
        #expect(Set(degree.filter { $0.value == 3 }.keys) == Set(witness.branchVertices) && degree.values.allSatisfy { $0 == 2 || $0 == 3 })
        #expect(witness.paths.count == 9 && witness.paths.map(\.edges).joined().sorted() == witness.edges)
        for path in witness.paths {
            for (k, p) in path.edges.enumerated() {
                #expect(Set([pairs[p].0, pairs[p].1]) == Set([path.vertices[k], path.vertices[k + 1]]))
            }
        }
        // Minimal: without any one of its edges, the witness is planar.
        for drop in witness.edges {
            let rest = Pseudograph<Int>(vertices: 0 ..< 12, edges: witness.edges.filter { $0 != drop }.map { UndirectedEdge(pairs[$0].0, pairs[$0].1) })
            #expect(rest.isPlanar, "without \(drop)")
        }
    }
}
