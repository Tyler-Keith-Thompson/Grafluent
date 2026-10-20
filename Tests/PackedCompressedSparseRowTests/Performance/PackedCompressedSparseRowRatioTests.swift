// The rows PackedCompressedSparseRow lends to algorithms (`_withOutIndexRows`) against packed
// arrays holding the same rows, on a directed G(10⁵, 10⁶) built two ways: by the bulk initializer
// and by inserting the edges one at a time. Two kernels read every target and edge position: a walk
// over every row in vertex order, and a breadth-first search from vertex 0 that records each
// vertex's parent edge. The packed side reads offsets, targets and positions as compressed sparse
// rows would. The rows of a graph built by insertion stay in vertex order with spare cells between
// them, so both kernels are bounded at 1.4× however the graph was built, where AdjacencyList
// bounds only the search of an inserted graph (at 1.5×). The two sides are timed in alternating
// rounds, each keeping its fastest of fifteen, and the comparison is retried up to three times
// while it looks slow. The timing runs only in an optimized build; a debug build checks that both
// sides agree, on a smaller instance.

import GrafluentTestSupport
import GraphProtocols
import PackedCompressedSparseRowModule
import Testing

@Suite("PackedCompressedSparseRow row layout against packed arrays")
struct PackedCompressedSparseRowRatioTests {
    @Test("Lent out-rows walked and searched within 1.4× of packed arrays, bulk-built or built by insertion", .timeLimit(.minutes(1)))
    func directed() async {
        await Task {
            #if DEBUG
            let n = 2_000, m = 20_000
            #else
            let n = 100_000, m = 1_000_000
            #endif
            var rng = SeededRandomNumberGenerator(seed: 7)
            let edges = (0 ..< m).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)) }
            let bulk = PackedCompressedSparseRow(vertices: 0 ..< n, edges: edges)
            var inserted = PackedCompressedSparseRow<Int>(vertices: 0 ..< n)
            for edge in edges { inserted.insert(edge: edge) }
            #expect(bulk == inserted)
            #expect(Array(bulk.edges) == Array(inserted.edges))

            var offsets = [0], targets: [Int] = [], positions: [Int] = []
            for v in 0 ..< n {
                targets.append(contentsOf: bulk.successorIndices(ofIndex: v))
                positions.append(contentsOf: bulk.outEdges(ofIndex: v))
                offsets.append(targets.count)
            }

            func walkLent(_ graph: PackedCompressedSparseRow<Int>) -> Int {
                graph._withOutIndexRows { targets, targetRows, edges, edgeRows in
                    var sum = 0
                    for v in 0 ..< n {
                        let start = targetRows[3 &* v], end = start &+ targetRows[3 &* v &+ 1], shift = edgeRows[3 &* v] &- start
                        var k = start
                        while k < end {
                            sum &+= targets[k] &* 31 &+ edges[k &+ shift]
                            k &+= 1
                        }
                    }
                    return sum
                }!
            }
            func walkPacked() -> Int {
                offsets.withUnsafeBufferPointer { offsets in
                    targets.withUnsafeBufferPointer { targets in
                        positions.withUnsafeBufferPointer { positions in
                            var sum = 0
                            for v in 0 ..< n {
                                var k = offsets[v]
                                let end = offsets[v &+ 1]
                                while k < end {
                                    sum &+= targets[k] &* 31 &+ positions[k]
                                    k &+= 1
                                }
                            }
                            return sum
                        }
                    }
                }
            }
            func searchLent(_ graph: PackedCompressedSparseRow<Int>) -> Int {
                graph._withOutIndexRows { targets, targetRows, edges, edgeRows in
                    var parent = [Int](repeating: -1, count: n)
                    var queue = [Int](repeating: 0, count: n)
                    return parent.withUnsafeMutableBufferPointer { parent in
                        queue.withUnsafeMutableBufferPointer { queue in
                            var head = 0, tail = 1
                            parent[0] = Int.max
                            while head < tail {
                                let v = queue[head]
                                head &+= 1
                                let start = targetRows[3 &* v], end = start &+ targetRows[3 &* v &+ 1], shift = edgeRows[3 &* v] &- start
                                var k = start
                                while k < end {
                                    let w = targets[k]
                                    if parent[w] < 0 {
                                        parent[w] = edges[k &+ shift]
                                        queue[tail] = w
                                        tail &+= 1
                                    }
                                    k &+= 1
                                }
                            }
                            var sum = 0
                            for v in 0 ..< n { sum &+= parent[v] }
                            return sum
                        }
                    }
                }!
            }
            func searchPacked() -> Int {
                offsets.withUnsafeBufferPointer { offsets in
                    targets.withUnsafeBufferPointer { targets in
                        positions.withUnsafeBufferPointer { positions in
                            var parent = [Int](repeating: -1, count: n)
                            var queue = [Int](repeating: 0, count: n)
                            return parent.withUnsafeMutableBufferPointer { parent in
                                queue.withUnsafeMutableBufferPointer { queue in
                                    var head = 0, tail = 1
                                    parent[0] = Int.max
                                    while head < tail {
                                        let v = queue[head]
                                        head &+= 1
                                        var k = offsets[v]
                                        let end = offsets[v &+ 1]
                                        while k < end {
                                            let w = targets[k]
                                            if parent[w] < 0 {
                                                parent[w] = positions[k]
                                                queue[tail] = w
                                                tail &+= 1
                                            }
                                            k &+= 1
                                        }
                                    }
                                    var sum = 0
                                    for v in 0 ..< n { sum &+= parent[v] }
                                    return sum
                                }
                            }
                        }
                    }
                }
            }
            #expect(walkLent(bulk) == walkPacked())
            #expect(walkLent(inserted) == walkPacked())
            #expect(searchLent(bulk) == searchPacked())
            #expect(searchLent(inserted) == searchPacked())

            #if !DEBUG
            func ratio(_ library: () -> Int, _ baseline: () -> Int) -> Double {
                let clock = ContinuousClock()
                var result = Double.infinity
                var sink = 0
                for _ in 0 ..< 3 where result > 1.1 {
                    var a = Duration.seconds(1_000), b = Duration.seconds(1_000)
                    for _ in 0 ..< 15 {
                        a = min(a, clock.measure { sink &+= library() })
                        b = min(b, clock.measure { sink &+= baseline() })
                    }
                    result = min(result, a / b)
                }
                #expect(sink != 1)
                return result
            }
            let bulkWalk = ratio({ walkLent(bulk) }, walkPacked)
            let insertedWalk = ratio({ walkLent(inserted) }, walkPacked)
            let bulkSearch = ratio({ searchLent(bulk) }, searchPacked)
            let insertedSearch = ratio({ searchLent(inserted) }, searchPacked)
            #expect(bulkWalk < 1.4, "the walk over a bulk-built graph's rows took \(bulkWalk)× the packed arrays")
            #expect(insertedWalk < 1.4, "the walk over an inserted graph's rows took \(insertedWalk)× the packed arrays")
            #expect(bulkSearch < 1.4, "the search over a bulk-built graph's rows took \(bulkSearch)× the packed arrays")
            #expect(insertedSearch < 1.4, "the search over an inserted graph's rows took \(insertedSearch)× the packed arrays")
            #endif
        }.value
    }
}
