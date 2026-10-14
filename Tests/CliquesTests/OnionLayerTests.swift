// The onion decomposition (Hébert-Dufresne, Grochow and Allard), k-crusts and k-coronas, on the
// simple graph. Hand-computed graphs, representations, the checked spelling, exits, and property
// tests: onion layers against NetworkX's round-by-round algorithm replayed on sets, crusts and
// coronas against their definitions over peeled core numbers.

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("Onion layers, k-crusts and k-coronas")
struct OnionLayerTests {
    @Test("CQ-920 A path with an isolated vertex: the isolated vertex is layer 1, the path's ends 2, its middle 3")
    func pathWithIsolated() {
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let onion = graph.onionLayers()
        #expect((0 ..< 5).map { onion.layer(of: $0) } == [2, 3, 3, 2, 1])
        #expect((0 ..< 5).map { onion.layer(ofIndex: $0) } == [2, 3, 3, 2, 1])
        #expect(onion.layerCount == 3)
    }

    @Test("CQ-921 A triangle with a pendant: no isolated vertex, so the pendant is layer 1 and the triangle, once the core rises to 2, layer 2")
    func trianglePendant() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let onion = graph.onionLayers()
        #expect((0 ..< 4).map { onion.layer(of: $0) } == [2, 2, 2, 1])
        #expect(onion.layerCount == 2)
    }

    @Test("CQ-922 K₄ is one layer; a star's leaves are layer 1 and its centre layer 2")
    func completeAndStar() {
        let k4 = ReferencePseudograph(edges: [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)].map { UndirectedEdge($0.0, $0.1) })
        let onion = k4.onionLayers()
        #expect((0 ..< 4).map { onion.layer(of: $0) } == [1, 1, 1, 1])
        let star = ReferencePseudograph(edges: [(0, 1), (0, 2), (0, 3)].map { UndirectedEdge($0.0, $0.1) })
        let layers = star.onionLayers()
        #expect((0 ..< 4).map { layers.layer(of: $0) } == [2, 1, 1, 1])
        #expect(layers.layerCount == 2)
    }

    @Test("CQ-923 Layers count rounds: a chain of triangles hanging off K₄ peels one or two vertices a round before K₄ goes at once")
    func shellRounds() {
        // A K₄ on 0…3 with a path of triangles hanging off 3: 3-4-5, 4-5-6, 5-6-7.
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (4, 5), (4, 6), (5, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let onion = graph.onionLayers()
        // Degrees 3,3,3,5,3,4,3,2: round 1 (core 1) takes nothing at degree 1, so the core rises
        // to 2 and takes 7; then 6 drops to 2 (layer 2), then 4 and 5 (layer 3), then K₄ (core 3).
        #expect((0 ..< 8).map { onion.layer(of: $0) } == [4, 4, 4, 4, 3, 3, 2, 1])
        #expect(onion.layerCount == 4)
    }

    @Test("CQ-924 Loops and parallel edges are ignored; the empty graph has no layers")
    func loopsParallelsEmpty() {
        let graph = Pseudograph(vertices: 0 ..< 3, edges: [(0, 1), (0, 1), (1, 1), (1, 2), (2, 2)].map { UndirectedEdge($0.0, $0.1) })
        let onion = graph.onionLayers()
        #expect((0 ..< 3).map { onion.layer(of: $0) } == [1, 2, 1])
        let loopOnly = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        #expect(loopOnly.onionLayers().layer(of: 0) == 1)
        let empty = ReferencePseudograph<Int>(edges: [])
        #expect(empty.onionLayers().layerCount == 0)
    }

    @Test("CQ-925 String vertices listed in reverse: layers by vertex, not by name")
    func unindexed() {
        let graph = UndirectedAdjacencyList(vertices: ["d", "c", "b", "a", "z"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d")])
        let onion = graph.onionLayers()
        #expect(["a", "b", "c", "d", "z"].map { onion.layer(of: $0) } == [2, 3, 3, 2, 1])
    }

    @Test("CQ-926 layer(checked:) throws VertexNotFound for a non-vertex; layer(of:) and layer(ofIndex:) trap")
    func checkedAndTraps() async throws {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let onion = graph.onionLayers()
        #expect(throws: VertexNotFound.self) { try onion.layer(checked: 7) }
        #expect(try onion.layer(checked: 1) == 1)
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).onionLayers().layer(of: 7)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).onionLayers().layer(ofIndex: 2)
        }
    }

    @Test("CQ-927 kCrust and kCorona on a triangle with a pendant and an isolated vertex, and on the diamond")
    func crustAndCorona() {
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let cores = graph.coreNumbers()
        #expect(cores.kCrust(0) == [4])
        #expect(cores.kCrust(1) == [3, 4])
        #expect(cores.kCrust(2) == [0, 1, 2, 3, 4])
        #expect(cores.kCrust(cores.degeneracy - 1) == [3, 4])
        #expect(cores.kCorona(0) == [4])
        #expect(cores.kCorona(1) == [3])
        #expect(cores.kCorona(2) == [0, 1, 2])
        #expect(cores.kCorona(3) == [])
        // The diamond: all of core 2, but 0 and 1 have three neighbours in the 2-core.
        let diamond = ReferencePseudograph(edges: [(0, 1), (0, 2), (1, 2), (0, 3), (1, 3)].map { UndirectedEdge($0.0, $0.1) })
        #expect(diamond.coreNumbers().kCorona(2) == [2, 3])
        #expect(diamond.coreNumbers().kCrust(1) == [])
        // A parallel copy and a loop add no neighbour.
        let doubled = Pseudograph(vertices: 0 ..< 3, edges: [(0, 1), (0, 1), (1, 2), (2, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(doubled.coreNumbers().kCorona(1) == [0, 2])
    }

    @Test("CQ-928 kCrust and kCorona trap on a negative k")
    func crustTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).coreNumbers().kCrust(-1)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).coreNumbers().kCorona(-1)
        }
    }

    @Test("CQ-929 Onion layers are NetworkX's rounds replayed on sets; crusts and coronas follow their definitions", .tags(.randomized))
    func againstReplay() async {
        // A local function rather than the closure given to propertyCheck: in a closure, Swift 6.3
        // numbers a closure inside a #expect argument like the next closure written after it, and
        // the `layer(of:)` map below has the type of the `coreNumber(of:)` map after it. Function
        // bodies number their closures correctly.
        @Sendable func check(_ n: Int, _ raw: [(Int, Int)]) {
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var adjacent = [Set<Int>](repeating: [], count: n)
            for (a, b) in pairs where a != b {
                adjacent[a].insert(b)
                adjacent[b].insert(a)
            }
            var expected = [Int](repeating: 0, count: n)
            var remaining = Set(0 ..< n)
            var layer = 1, core = 1
            let isolated = (0 ..< n).filter { adjacent[$0].isEmpty }
            if !isolated.isEmpty {
                for v in isolated {
                    expected[v] = 1
                    remaining.remove(v)
                }
                layer = 2
            }
            while !remaining.isEmpty {
                let degree = { (v: Int) in adjacent[v].intersection(remaining).count }
                core = max(core, remaining.map(degree).min()!)
                let taken = remaining.filter { degree($0) <= core }
                for v in taken { expected[v] = layer }
                remaining.subtract(taken)
                layer += 1
            }
            let onion = graph.onionLayers()
            #expect((0 ..< n).map { onion.layer(of: $0) } == expected, "\(pairs)")
            #expect(onion.layerCount == (expected.max() ?? 0))
            let cores = graph.coreNumbers()
            let coreNumber: [Int] = (0 ..< n).map { cores.coreNumber(of: $0) }
            for k in 0 ... cores.degeneracy + 1 {
                let crust: [Int] = (0 ..< n).filter { coreNumber[$0] <= k }
                #expect(cores.kCrust(k) == crust)
                var corona: [Int] = []
                for v in 0 ..< n where coreNumber[v] == k {
                    let inCore = adjacent[v].filter { coreNumber[$0] >= k }.count
                    if inCore == k { corona.append(v) }
                }
                #expect(cores.kCorona(k) == corona)
            }
        }
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: Gen.int(in: 1 ... 10), edges) { n, raw in check(n, raw) }
    }
}
