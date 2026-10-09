// Cases added after the review: AdjacencyMatrix, the one representation with vertex indices but no
// edge indices (its edge positions are not Ints), agrees with AdjacencyList on every measure, and
// its diameter paths are paths of the matrix.

import AdjacencyListModule
import AdjacencyMatrixModule
import Distances
import GraphProtocols
import Testing
import Walks

@Suite("Distances review cases")
struct DistanceReviewTests {
    @Test("DI-1001 AdjacencyMatrix agrees with AdjacencyList, unweighted and weighted, and its diameter paths are its own", arguments: 1 ... 12)
    func matrixAgrees(seed: Int) throws {
        var state = UInt64(seed) &* 0x9E37_79B9_7F4A_7C15
        func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
        let n = 2 + next(9)
        var arcs: [DirectedEdge<Int>] = (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) }
        for _ in 0 ..< next(2 * n) { arcs.append(DirectedEdge(from: next(n), to: next(n))) }
        if seed % 3 == 0 { arcs.removeFirst() }  // not strongly connected
        let list = AdjacencyList(vertices: 0 ..< n, edges: arcs)
        let matrix = AdjacencyMatrix(vertexCount: n, edges: arcs)
        var weightOf: [DirectedEdge<Int>: Int] = [:]
        for arc in list.edges { weightOf[arc] = 1 + next(7) }
        let listWeight = { (e: Int) in weightOf[list.edges[e]]! }
        let matrixWeight = { (e: AdjacencyMatrix.Edges.Index) in weightOf[matrix.edges[e]]! }

        let a = list.eccentricities(), b = matrix.eccentricities()
        for v in 0 ..< n { #expect(a.eccentricity(of: v) == b.eccentricity(of: v), "seed \(seed), vertex \(v)") }
        #expect(a.radius == b.radius && a.diameter == b.diameter && a.center == b.center && a.periphery == b.periphery)
        let wa = list.eccentricities(weight: listWeight), wb = matrix.eccentricities(weight: matrixWeight)
        for v in 0 ..< n { #expect(wa.eccentricity(of: v) == wb.eccentricity(of: v), "seed \(seed), weighted vertex \(v)") }
        #expect(list.centroid() == matrix.centroid() && list.wienerIndex() == matrix.wienerIndex())
        #expect(list.wienerIndex(weight: listWeight) == matrix.wienerIndex(weight: matrixWeight))

        if let path = matrix.diameterPath() {
            #expect(Path(vertices: path.vertices, edges: path.edges, in: matrix) != nil, "seed \(seed): \(path)")
            #expect(path.length == a.diameter)
        } else {
            #expect(a.diameter == nil)
        }
        if let (path, distance) = matrix.diameterPath(weight: matrixWeight) {
            #expect(Path(vertices: path.vertices, edges: path.edges, in: matrix) != nil, "seed \(seed): \(path)")
            let length = path.edges.map(matrixWeight).reduce(0, +)
            #expect(distance == wa.diameter && length == distance)
        } else {
            #expect(wa.diameter == nil)
        }
        let undirected = matrix.undirected
        if let path = undirected.diameterPath() {
            #expect(Path(vertices: path.vertices, edges: path.edges, in: undirected) != nil, "seed \(seed): \(path)")
        }
    }

    @Test("DI-1002 a NaN weight traps on a directed graph too, even on an edge no search reaches")
    func directedNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            let w: [Double] = [1, .nan]
            _ = graph.eccentricities { w[$0] }
        }
        await #expect(processExitsWith: .failure) {
            // The search from 0 misses 2 and stops: only the up-front check sees edge 2→0.
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0)])
            let w: [Double] = [1, .nan]
            _ = graph.diameter { w[$0] }
        }
    }
}
