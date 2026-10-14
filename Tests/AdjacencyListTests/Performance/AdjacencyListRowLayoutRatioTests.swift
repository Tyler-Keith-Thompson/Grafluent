// The stored rows that `AdjacencyList` and `UndirectedAdjacencyList` lend to algorithms
// (`_withOutIndexRows`, `_withIncidentIndexRows`) against packed arrays holding the same rows, on a
// directed G(10⁵, 10⁶) and an undirected G(10⁵, 5·10⁵). Each graph is built two ways: by its bulk
// initializer, `init(vertices:edges:)`, and by inserting the edges one at a time. Two kernels read
// every target and edge position: a walk over every row in vertex order, and a breadth-first
// search from vertex 0 that records each vertex's parent edge. The loops over the lent rows are the
// ones the library's algorithms run (a row's start and length from the row table, its positions at
// the same offset in the position table's row). The packed side reads offsets, targets and
// positions, as compressed sparse rows would. A bulk-built graph's rows are packed in vertex
// order, so both kernels are bounded at 1.3×. A graph built by insertion keeps the rows that grew
// out of place since the pool last packed. The walk in vertex order feels that and the search,
// whose order is random anyway, barely does, so only the search is bounded there, at 1.5×. The two
// sides are timed in alternating rounds, each keeping its fastest of fifteen, and the comparison
// is retried up to three times while it looks slow, so other work on the machine does not decide
// it. The timing runs only in an optimized build; a debug build checks that both sides agree.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("AdjacencyList row layout against packed arrays")
struct AdjacencyListRowLayoutRatioTests {
    @Test("AdjacencyList: lent out-rows walked and searched within 1.3× of packed arrays when bulk-built, searched within 1.5× when built by insertion", .timeLimit(.minutes(1)))
    func directed() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 7)
            let edges = (0 ..< 1_000_000).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)) }
            let bulk = AdjacencyList(vertices: 0 ..< n, edges: edges)
            var inserted = AdjacencyList<Int>(vertices: 0 ..< n)
            for edge in edges { inserted.insert(edge: edge) }
            #expect(bulk == inserted)
            #expect(Array(bulk.edges) == Array(inserted.edges))

            var offsets = [0], targets: [Int] = [], positions: [Int] = []
            for v in 0 ..< n {
                targets.append(contentsOf: bulk.successorIndices(ofIndex: v))
                positions.append(contentsOf: bulk.outEdges(ofIndex: v))
                offsets.append(targets.count)
            }

            func walkLent(_ graph: AdjacencyList<Int>) -> Int {
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
            func searchLent(_ graph: AdjacencyList<Int>) -> Int {
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
            // The two sides alternate, so a burst of other work slows both; each keeps its fastest round.
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
            let bulkSearch = ratio({ searchLent(bulk) }, searchPacked)
            let insertedSearch = ratio({ searchLent(inserted) }, searchPacked)
            #expect(bulkWalk < 1.3, "the walk over a bulk-built graph's rows took \(bulkWalk)× the packed arrays")
            #expect(bulkSearch < 1.3, "the search over a bulk-built graph's rows took \(bulkSearch)× the packed arrays")
            #expect(insertedSearch < 1.5, "the search over an inserted graph's rows took \(insertedSearch)× the packed arrays")
            #endif
        }.value
    }

    @Test("UndirectedAdjacencyList: lent incident rows walked and searched within 1.3× of packed arrays when bulk-built, searched within 1.5× when built by insertion", .timeLimit(.minutes(1)))
    func undirected() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 8)
            let edges = (0 ..< 500_000).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let bulk = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
            var inserted = UndirectedAdjacencyList<Int>(vertices: 0 ..< n)
            for edge in edges { inserted.insert(edge: edge) }
            #expect(bulk == inserted)
            #expect(Array(bulk.edges) == Array(inserted.edges))

            var offsets = [0], targets: [Int] = [], positions: [Int] = []
            for v in 0 ..< n {
                targets.append(contentsOf: bulk.neighborIndices(ofIndex: v))
                positions.append(contentsOf: bulk.incidentEdges(ofIndex: v))
                offsets.append(targets.count)
            }

            func walkLent(_ graph: UndirectedAdjacencyList<Int>) -> Int {
                graph._withIncidentIndexRows { targets, targetRows, edges, edgeRows in
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
            func searchLent(_ graph: UndirectedAdjacencyList<Int>) -> Int {
                graph._withIncidentIndexRows { targets, targetRows, edges, edgeRows in
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
            // The two sides alternate, so a burst of other work slows both; each keeps its fastest round.
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
            let bulkSearch = ratio({ searchLent(bulk) }, searchPacked)
            let insertedSearch = ratio({ searchLent(inserted) }, searchPacked)
            #expect(bulkWalk < 1.3, "the walk over a bulk-built graph's rows took \(bulkWalk)× the packed arrays")
            #expect(bulkSearch < 1.3, "the search over a bulk-built graph's rows took \(bulkSearch)× the packed arrays")
            #expect(insertedSearch < 1.5, "the search over an inserted graph's rows took \(insertedSearch)× the packed arrays")
            #endif
        }.value
    }
}
