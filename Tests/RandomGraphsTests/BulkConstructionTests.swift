// Every conformer of the bulk construction the generators use: a graph built by a generator equals
// the same graph built edge by edge through the public initializers and `insert(edge:)`, with its
// edges in the same order, and the two stay equal through a random script of insertions and
// removals of edges and vertices. Each test is self-contained. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import StableGraphs
import Testing

@Suite("Bulk construction against edge-by-edge construction, through a random script", .tags(.randomized))
struct BulkConstructionTests {

    @Test("AdjacencyList<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func adjacencyList() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = AdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = AdjacencyList<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.source, $0.target] } == Array(built.edges).map { [$0.source, $0.target] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    bulk.insert(edge: DirectedEdge(from: u, to: v))
                    built.insert(edge: DirectedEdge(from: u, to: v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("DirectedPseudograph<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func directedPseudograph() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = DirectedPseudograph<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = DirectedPseudograph<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.source, $0.target] } == Array(built.edges).map { [$0.source, $0.target] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    bulk.insert(edge: DirectedEdge(from: u, to: v))
                    built.insert(edge: DirectedEdge(from: u, to: v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("DirectedMultigraph<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func directedMultigraph() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = DirectedMultigraph<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = DirectedMultigraph<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { try built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.source, $0.target] } == Array(built.edges).map { [$0.source, $0.target] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    if u == v { continue }
                    try bulk.insert(edge: DirectedEdge(from: u, to: v))
                    try built.insert(edge: DirectedEdge(from: u, to: v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("StableDirectedGraph<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func stableDirectedGraph() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = StableDirectedGraph<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = StableDirectedGraph<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.source, $0.target] } == Array(built.edges).map { [$0.source, $0.target] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    bulk.insert(edge: DirectedEdge(from: u, to: v))
                    built.insert(edge: DirectedEdge(from: u, to: v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("UndirectedAdjacencyList<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func undirectedAdjacencyList() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = UndirectedAdjacencyList<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.u, $0.v] } == Array(built.edges).map { [$0.u, $0.v] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    bulk.insert(edge: UndirectedEdge(u, v))
                    built.insert(edge: UndirectedEdge(u, v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("Pseudograph<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func pseudograph() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = Pseudograph<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = Pseudograph<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.u, $0.v] } == Array(built.edges).map { [$0.u, $0.v] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    bulk.insert(edge: UndirectedEdge(u, v))
                    built.insert(edge: UndirectedEdge(u, v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("Multigraph<Int>: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func multigraph() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = Multigraph<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = Multigraph<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { try built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.u, $0.v] } == Array(built.edges).map { [$0.u, $0.v] }, "seed \(seed)")
            var next = n
            for step in 0 ..< 80 {
                switch generator.next() % 5 {
                case 0, 1:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    if u == v { continue }
                    try bulk.insert(edge: UndirectedEdge(u, v))
                    try built.insert(edge: UndirectedEdge(u, v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                case 3:
                    let vertices = bulk.vertices.sorted()
                    guard !vertices.isEmpty else { continue }
                    let w = vertices[Int(generator.next() % UInt64(vertices.count))]
                    #expect(bulk.remove(w) == built.remove(w), "seed \(seed) step \(step)")
                default:
                    built.insert(next)
                    bulk.insert(next)
                    next += 1
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("AdjacencyMatrix: a generated G(n, p) equals its edge-by-edge build, edges in the same order, through a random script")
    func adjacencyMatrix() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            var bulk = AdjacencyMatrix.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var built = AdjacencyMatrix(vertexCount: n)
            for e in Array(bulk.edges) { built.insert(edge: e) }
            #expect(bulk == built && Array(bulk.edges).map { [$0.source, $0.target] } == Array(built.edges).map { [$0.source, $0.target] }, "seed \(seed)")
            for step in 0 ..< 80 {
                switch generator.next() % 4 {
                case 0, 1:
                    let vertices = Array(0 ..< bulk.vertexCount)
                    guard !vertices.isEmpty else { continue }
                    let u = vertices[Int(generator.next() % UInt64(vertices.count))]
                    let v = vertices[Int(generator.next() % UInt64(vertices.count))]
                    bulk.insert(edge: DirectedEdge(from: u, to: v))
                    built.insert(edge: DirectedEdge(from: u, to: v))
                case 2:
                    let edges = Array(bulk.edges)
                    guard !edges.isEmpty else { continue }
                    let e = edges[Int(generator.next() % UInt64(edges.count))]
                    #expect(bulk.remove(edge: e) != nil && built.remove(edge: e) != nil, "seed \(seed) step \(step)")
                default:
                    built.appendVertex()
                    bulk.appendVertex()
                }
                #expect(bulk == built && bulk.edgeCount == built.edgeCount, "seed \(seed) step \(step)")
            }
        }
    }

    @Test("CompressedSparseRow: a generated G(n, p) equals the graph built from the same edges one at a time, edges in the same order")
    func compressedSparseRow() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 24), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let bulk = CompressedSparseRow.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var list = AdjacencyList<Int>(vertices: 0 ..< n)
            for e in Array(bulk.edges) { list.insert(edge: e) }
            let built = CompressedSparseRow(vertexCount: n, edges: Array(list.edges))
            #expect(bulk == built && Array(bulk.edges).map { [$0.source, $0.target] } == Array(built.edges).map { [$0.source, $0.target] }, "seed \(seed)")
        }
    }
}
