// The collection conformances: RandomAccessCollection laws and slicing, MutableCollection and
// sorting, RangeReplaceableCollection mutation. Case IDs (EL-Lnn, EL-Snn, EL-Rnn) refer to the
// catalog; see README.md.

import EdgeListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("EdgeList as a RandomAccessCollection")
struct EdgeListRandomAccessTests {
    @Test("EL-L01 / EL-L03 / EL-L04 / EL-L05 indices, stepping, multi-pass iteration and subscripts", .tags(.fixture, .conformance), arguments: DirectedFixture<Int>.all)
    func laws(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let m = fixture.edges.count
        #expect(list.startIndex == 0)
        #expect(list.endIndex == m)
        #expect(list.indices == 0 ..< m)
        #expect(list.underestimatedCount == m)
        // Multi-pass: two iterations give the same edges.
        var first: [DirectedEdge<Int>] = []
        for edge in list { first.append(edge) }
        var second: [DirectedEdge<Int>] = []
        for edge in list { second.append(edge) }
        #expect(first == fixture.edges)
        #expect(second == fixture.edges)
        #expect(list.first == fixture.edges.first)
        #expect(list.last == fixture.edges.last)
        var i = list.startIndex
        var visited = 0
        while i != list.endIndex {
            #expect(list[i] == fixture.edges[visited])
            #expect(list.index(before: list.index(after: i)) == i)
            i = list.index(after: i)
            visited += 1
        }
        #expect(visited == m)
        var backward: [DirectedEdge<Int>] = []
        var j = list.endIndex
        while j != list.startIndex {
            j = list.index(before: j)
            backward.append(list[j])
        }
        #expect(backward == fixture.edges.reversed())
    }

    @Test("EL-L02 offsets and distances are integer arithmetic, with limits")
    func offsets() {
        let list = EdgeList(DirectedFixture<Int>.boost24.edges)
        #expect(list.count == 43)
        #expect(list.index(0, offsetBy: 43) == list.endIndex)
        #expect(list.index(43, offsetBy: -43) == 0)
        #expect(list.index(5, offsetBy: 40, limitedBy: 43) == nil)
        #expect(list.index(5, offsetBy: 38, limitedBy: 43) == 43)
        #expect(list.index(10, offsetBy: -3, limitedBy: 0) == 7)
        #expect(list.distance(from: 3, to: 40) == 37)
        #expect(list.distance(from: 40, to: 3) == -37)
    }

    @Test("EL-L06 / EL-L08 a slice shares the list's indices; a list made from it starts at 0")
    func slicing() {
        let list = EdgeList(DirectedFixture<Int>.house.edges)
        let slice = list[2 ..< 5]
        #expect(slice.startIndex == 2)
        #expect(slice.endIndex == 5)
        #expect(Array(slice) == Array(Array(list)[2 ..< 5]))
        for k in slice.indices {
            #expect(slice[k] == list[k])
        }
        let copy = EdgeList(slice)
        #expect(copy.startIndex == 0)
        #expect(Array(copy) == [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 1)])
    }

    @Test("EL-L07 / EL-L09 every slice, empty ones included, matches an array's", .tags(.exhaustive), arguments: [DirectedFixture<Int>.jgraphtSparseDirected, .boostWebGraph, .house, .empty])
    func everySlice(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let m = fixture.edges.count
        for a in 0 ... m {
            for b in a ... m {
                let slice = list[a ..< b]
                #expect(Array(slice) == Array(fixture.edges[a ..< b]), "\(a)..<\(b)")
                #expect(slice.count == b - a)
                #expect(slice.indices == a ..< b)
            }
        }
    }

    @Test("EL-L10 reversed() reverses order and keeps each edge's direction")
    func reversedOrder() {
        let list = EdgeList(DirectedFixture<Int>.directedPath3.edges)
        #expect(Array(list.reversed()) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)])
    }

    @Test("EL-L11 / EL-L12 first and last index of a parallel edge, and of a missing one")
    func firstAndLastIndex() {
        let list = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(list.firstIndex(of: DirectedEdge(from: 2, to: 4)) == 5)
        #expect(list.lastIndex(of: DirectedEdge(from: 2, to: 4)) == 7)
        #expect(list.firstIndex(of: DirectedEdge(from: 4, to: 2)) == nil)
        #expect(list.firstIndex { $0.source == 99 } == nil)
    }

    @Test("EL-L13 the edges are contiguous storage")
    func contiguousStorage() {
        let list = EdgeList(DirectedFixture<Int>.boost24.edges)
        let copied = list.withContiguousStorageIfAvailable { Array($0) }
        #expect(copied == DirectedFixture<Int>.boost24.edges)
    }

    @Test("EL-L14 a list can be sent to a task and read there")
    func sendable() async {
        let list = EdgeList(DirectedFixture<Int>.petersen.edges)
        let count = await Task.detached { list.count + list.vertexCount }.value
        #expect(count == 40)
    }

    @Test("EL-L15 elementsEqual and starts(with:)")
    func sequenceAlgorithms() {
        let list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(list.elementsEqual(DirectedFixture<Int>.house.edges))
        #expect(list.starts(with: DirectedFixture<Int>.house.edges.prefix(3)))
        #expect(!list.starts(with: [DirectedEdge(from: 0, to: 0)]))
    }

    @Test("EL-L16 a copy's mutation leaves the original's positions and edges alone")
    func indicesStableAcrossCopies() {
        let list = EdgeList(DirectedFixture<Int>.house.edges)
        var copy = list
        copy.remove(at: 0)
        copy.insert(DirectedEdge(from: 9, to: 9), at: 3)
        for k in list.indices {
            #expect(list[k] == DirectedFixture<Int>.house.edges[k])
        }
    }
}

@Suite("EdgeList as a MutableCollection")
struct EdgeListMutableCollectionTests {
    @Test("EL-S01 assigning through the subscript replaces one edge")
    func assign() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        list[0] = DirectedEdge(from: 0, to: 5)
        #expect(list.count == 7)
        #expect(list[0] == DirectedEdge(from: 0, to: 5))
        #expect(Array(list.dropFirst()) == Array(DirectedFixture<Int>.house.edges.dropFirst()))
    }

    @Test("EL-S02 an endpoint can be changed in place")
    func mutateInPlace() {
        var list = EdgeList(DirectedFixture<Int>.directedPath3.edges)
        list[1].target = 0
        #expect(Array(list) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(list.vertices == [0, 1])
    }

    @Test("EL-S03 swapAt exchanges two edges; swapping one with itself does nothing")
    func swap() {
        let a = DirectedEdge(from: 0, to: 1)
        let b = DirectedEdge(from: 1, to: 2)
        let c = DirectedEdge(from: 2, to: 3)
        var list: EdgeList<Int> = [a, b, c]
        list.swapAt(0, 2)
        #expect(Array(list) == [c, b, a])
        list.swapAt(1, 1)
        #expect(Array(list) == [c, b, a])
    }

    @Test("EL-S04 / EL-S05 sorting, and its stability")
    func sorting() {
        var list = EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges)
        var bySource = list
        list.sort()
        #expect(Array(list) == [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 5, to: 0), DirectedEdge(from: 5, to: 2),
        ])
        // Equal sources keep input order: 4→1 stays before 4→0.
        bySource.sort { $0.source < $1.source }
        #expect(Array(bySource) == [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 1),
            DirectedEdge(from: 4, to: 0), DirectedEdge(from: 5, to: 0), DirectedEdge(from: 5, to: 2),
        ])
    }

    @Test("EL-S06 sorting real data keeps every copy, adjacent")
    func sortingDuplicates() {
        var list = EdgeList(DirectedFixture<Int>.gap4.edges)
        list.sort()
        #expect(list.count == 256)
        #expect(list.prefix(27).allSatisfy { $0 == DirectedEdge(from: 0, to: 0) })
        #expect(list[27] != DirectedEdge(from: 0, to: 0))
        #expect(list.last == DirectedEdge(from: 13, to: 13))
    }

    @Test("EL-S07 reverse() in place equals reversed()")
    func reverseInPlace() {
        var list = EdgeList(DirectedFixture<Int>.boost24.edges)
        let expected = Array(list.reversed())
        list.reverse()
        #expect(Array(list) == expected)
    }

    @Test("EL-S08 partition puts every match after the pivot and loses nothing", .tags(.selfLoops))
    func partition() {
        var list = EdgeList(DirectedFixture<Int>.petgraphCsr1.edges)
        let pivot = list.partition { $0.isSelfLoop }
        #expect(pivot == 3)
        #expect(list[..<pivot].allSatisfy { !$0.isSelfLoop })
        #expect(list[pivot...].allSatisfy { $0.isSelfLoop })
        #expect(Set(list) == Set(DirectedFixture<Int>.petgraphCsr1.edges))
    }

    @Test("EL-S09 shuffling keeps the edges; equal seeds shuffle alike", .tags(.randomized))
    func shuffle() {
        var first = EdgeList(DirectedFixture<Int>.boost24.edges)
        var second = first
        var g1 = SeededRandomNumberGenerator(seed: 42)
        var g2 = SeededRandomNumberGenerator(seed: 42)
        first.shuffle(using: &g1)
        second.shuffle(using: &g2)
        #expect(first == second)
        #expect(first.sorted()
            == DirectedFixture<Int>.boost24.edges.sorted())
    }

    @Test("EL-S10 sorting a copy leaves the original", .tags(.copyOnWrite))
    func sortCopy() {
        let list = EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges)
        var copy = list
        copy.sort()
        #expect(Array(list) == DirectedFixture<Int>.boostCsrUnsorted.edges)
        #expect(copy != list)
    }

    @Test("EL-S11 edges of Comparable vertices sort lexicographically, by source and then target")
    func comparable() {
        #expect(DirectedEdge(from: 0, to: 9) < DirectedEdge(from: 1, to: 0))
        #expect(DirectedEdge(from: 1, to: 0) < DirectedEdge(from: 1, to: 2))
        #expect(!(DirectedEdge(from: 1, to: 2) < DirectedEdge(from: 1, to: 2)))
        var list = EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges)
        list.sort()
        #expect(Array(list) == DirectedFixture<Int>.boostCsrUnsorted.edges.sorted { ($0.source, $0.target) < ($1.source, $1.target) })
        #expect(EdgeList(DirectedFixture<String>.petgraphDAG.edges).sorted() == DirectedFixture<String>.petgraphDAG.edges.sorted { ($0.source, $0.target) < ($1.source, $1.target) })
    }

    @Test("EL-S13 slice mutations match an Array's: sort, swap, reverse, narrowing, removal and insertion")
    func sliceMutationsMatchArray() {
        let edges = DirectedFixture<Int>.boost24.edges
        var generatorA = SeededRandomNumberGenerator(seed: 13)
        var generatorB = SeededRandomNumberGenerator(seed: 13)
        var list = EdgeList(edges)
        var array = edges
        list[5 ..< 20].sort()
        array[5 ..< 20].sort()
        #expect(Array(list) == array)
        list[0 ..< 10].reverse()
        array[0 ..< 10].reverse()
        #expect(Array(list) == array)
        list[30...].swapAt(31, 40)
        array[30...].swapAt(31, 40)
        #expect(Array(list) == array)
        list[2 ..< 8].removeFirst()
        array[2 ..< 8].removeFirst()
        #expect(Array(list) == array)
        list[2 ..< 8].removeLast(2)
        array[2 ..< 8].removeLast(2)
        #expect(Array(list) == array)
        _ = list[10 ..< 15].popFirst()
        _ = array[10 ..< 15].popFirst()
        #expect(Array(list) == array)
        list[3 ..< 6].append(DirectedEdge(from: 99, to: 99))
        array[3 ..< 6].append(DirectedEdge(from: 99, to: 99))
        #expect(Array(list) == array)
        list[0 ..< 20].removeAll { $0.isSelfLoop || $0.source == 2 }
        array[0 ..< 20].removeAll { $0.isSelfLoop || $0.source == 2 }
        #expect(Array(list) == array)
        list[4 ..< 4].insert(DirectedEdge(from: 77, to: 77), at: 4)
        array[4 ..< 4].insert(DirectedEdge(from: 77, to: 77), at: 4)
        #expect(Array(list) == array)
        list[1 ..< 9][3].target = 55
        array[1 ..< 9][3].target = 55
        #expect(Array(list) == array)
        list[...].shuffle(using: &generatorA)
        array[...].shuffle(using: &generatorB)
        #expect(Array(list) == array)
    }

    @Test("EL-S12 mutating a slice in place writes back to the list")
    func sliceWriteBack() {
        let a = DirectedEdge(from: 0, to: 1)
        let b = DirectedEdge(from: 1, to: 2)
        let c = DirectedEdge(from: 2, to: 3)
        var list: EdgeList<Int> = [a, b, c]
        list[0 ..< 2].swapAt(0, 1)
        #expect(Array(list) == [b, a, c])
        list[1...].reverse()
        #expect(Array(list) == [b, c, a])
    }
}

@Suite("EdgeList as a RangeReplaceableCollection")
struct EdgeListRangeReplaceableTests {
    @Test("EL-R01 appending one at a time or all at once")
    func append() {
        var oneByOne = EdgeList<Int>()
        for edge in DirectedFixture<Int>.directedCycle10.edges { oneByOne.append(edge) }
        var allAtOnce = EdgeList<Int>()
        allAtOnce.append(contentsOf: DirectedFixture<Int>.directedCycle10.edges)
        #expect(oneByOne == EdgeList(DirectedFixture<Int>.directedCycle10.edges))
        #expect(allAtOnce == oneByOne)
    }

    @Test("EL-R02 appending an edge already present adds a parallel copy")
    func appendDuplicate() {
        var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
        list.append(DirectedEdge(from: 0, to: 1))
        #expect(list.count == 2)
        #expect(list.multiplicity(of: DirectedEdge(from: 0, to: 1)) == 2)
    }

    @Test("EL-R03 / EL-R04 inserting at the start, middle and end")
    func insert() {
        let a = DirectedEdge(from: 0, to: 1)
        let b = DirectedEdge(from: 1, to: 2)
        let c = DirectedEdge(from: 2, to: 3)
        var list: EdgeList<Int> = [a, c]
        list.insert(b, at: 1)
        #expect(Array(list) == [a, b, c])
        list.insert(c, at: 0)
        list.insert(a, at: list.endIndex)
        #expect(Array(list) == [c, a, b, c, a])
        list.insert(contentsOf: [b, b], at: 2)
        #expect(Array(list) == [c, a, b, b, b, c, a])
    }

    @Test("EL-R05 remove(at:) returns the removed edge")
    func removeAt() {
        var list = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(list.remove(at: 4) == DirectedEdge(from: 4, to: 4))
        #expect(Array(list) == [
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4),
            DirectedEdge(from: 5, to: 5), DirectedEdge(from: 5, to: 2), DirectedEdge(from: 5, to: 5),
        ])
    }

    @Test("EL-R06 removing from either end")
    func removeEnds() {
        var list = EdgeList(DirectedFixture<Int>.directedPath10.edges)
        #expect(list.removeFirst() == DirectedEdge(from: 0, to: 1))
        list.removeFirst(2)
        #expect(list.first == DirectedEdge(from: 3, to: 4))
        #expect(list.removeLast() == DirectedEdge(from: 8, to: 9))
        list.removeLast(2)
        #expect(Array(list) == [DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 5, to: 6)])
        #expect(list.popLast() == DirectedEdge(from: 5, to: 6))
        #expect(list.popLast() == DirectedEdge(from: 4, to: 5))
        #expect(list.popLast() == DirectedEdge(from: 3, to: 4))
        #expect(list.popLast() == nil)
    }

    @Test("EL-R07 replacing a range with fewer, as many, and more edges")
    func replaceSubrange() {
        let house = DirectedFixture<Int>.house.edges
        let extra = (0 ..< 5).map { DirectedEdge(from: 10 + $0, to: 20 + $0) }
        var shorter = EdgeList(house)
        shorter.replaceSubrange(1 ..< 3, with: [])
        #expect(Array(shorter) == [house[0]] + Array(house[3...]))
        var same = EdgeList(house)
        same.replaceSubrange(1 ..< 3, with: extra.prefix(2))
        #expect(Array(same) == [house[0]] + Array(extra.prefix(2)) + Array(house[3...]))
        var longer = EdgeList(house)
        longer.replaceSubrange(1 ..< 3, with: extra)
        #expect(Array(longer) == [house[0]] + extra + Array(house[3...]))
        var removed = EdgeList(house)
        removed.removeSubrange(2 ..< 6)
        #expect(Array(removed) == Array(house[..<2]) + Array(house[6...]))
    }

    @Test("EL-R08 removing everything gives the empty list, whether or not capacity is kept", arguments: [false, true])
    func removeAll(_ keepingCapacity: Bool) {
        var list = EdgeList(DirectedFixture<Int>.boost24.edges)
        list.removeAll(keepingCapacity: keepingCapacity)
        #expect(list == EdgeList())
        #expect(list.vertices == [])
    }

    @Test("EL-R09 removeAll(where:) removes every match")
    func removeAllWhere() {
        var loops = EdgeList(DirectedFixture<Int>.petgraphCsr1.edges)
        loops.removeAll { $0.isSelfLoop }
        #expect(Array(loops) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0)])
        var sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        sparse.removeAll { $0 == DirectedEdge(from: 2, to: 4) }
        #expect(sparse.count == 10)
    }

    @Test("EL-R10 remove(edge:) removes the first copy only, and returns it")
    func removeEdgeFirstCopy() {
        // NetworkX removes the last-added parallel edge, rustworkx the newest, Boost every copy.
        var list = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(list.remove(edge: DirectedEdge(from: 2, to: 3)) == DirectedEdge(from: 2, to: 3))
        #expect(Array(list) == [
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 4),
            DirectedEdge(from: 5, to: 5), DirectedEdge(from: 5, to: 2), DirectedEdge(from: 5, to: 5),
        ])
        #expect(list.remove(edge: DirectedEdge(from: 5, to: 5)) == DirectedEdge(from: 5, to: 5))
        #expect(list[4] == DirectedEdge(from: 5, to: 2))
        #expect(list[5] == DirectedEdge(from: 5, to: 5))
    }

    @Test("EL-R10 remove(edge:) returns the list's own instance")
    func removeEdgeReturnsStoredInstance() {
        let stored = HashableBox(1, label: "stored")
        let probe = HashableBox(1, label: "probe")
        let target = HashableBox(2)
        var list = EdgeList([DirectedEdge(from: stored, to: target)])
        let removed = list.remove(edge: DirectedEdge(from: probe, to: target))
        #expect(removed?.source === stored)
        #expect(list.isEmpty)
    }

    @Test("EL-R11 removing an absent edge returns nil and changes nothing")
    func removeAbsent() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(list.remove(edge: DirectedEdge(from: 0, to: 5)) == nil)
        #expect(list.remove(edge: DirectedEdge(from: 42, to: 43)) == nil)
        #expect(Array(list) == DirectedFixture<Int>.house.edges)
        var empty = EdgeList<Int>()
        #expect(empty.remove(edge: DirectedEdge(from: 0, to: 0)) == nil)
    }

    @Test("EL-R12 removing every copy of an edge")
    func removeAllCopies() {
        var list = EdgeList(DirectedFixture<Int>.gap4.edges)
        list.removeAll { $0 == DirectedEdge(from: 0, to: 0) }
        #expect(list.count == 229)
        #expect(list.multiplicity(of: DirectedEdge(from: 0, to: 0)) == 0)
    }

    @Test("EL-R13 removeEdges(incidentTo:) removes every edge at a vertex, a self-loop once, and counts them")
    func removeIncident() {
        // gap4: vertex 0 has 153 out-entries and 27 in-entries, all 27 of them self-loops.
        var list = EdgeList(DirectedFixture<Int>.gap4.edges)
        #expect(list.removeEdges(incidentTo: 0) == 153)
        #expect(list.count == 103)
        #expect(!list.contains(0))
        #expect(list.allSatisfy { $0.source != 0 && $0.target != 0 })
    }

    @Test("EL-R14 removeEdges(incidentTo:) keeps the rest in order and renames nothing")
    func removeIncidentKeepsOrder() {
        var list: EdgeList<Int> = [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 0),
        ]
        #expect(list.removeEdges(incidentTo: 1) == 2)
        #expect(Array(list) == [DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
    }

    @Test("EL-R19 removeEdges(from:) and removeEdges(to:) remove one direction only")
    func removeOneDirection() {
        var out = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(out.removeEdges(from: 5) == 3)
        #expect(Array(out) == [
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 4),
        ])
        var into = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(into.removeEdges(to: 2) == 2)
        #expect(Array(into) == [
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 4),
            DirectedEdge(from: 5, to: 5), DirectedEdge(from: 5, to: 5),
        ])
        #expect(into.removeEdges(from: 42) == 0)
        #expect(into.removeEdges(to: 42) == 0)
    }

    @Test("EL-R20 capacity grows with reservation and is kept by removeAll(keepingCapacity: true)")
    func capacity() {
        var list = EdgeList<Int>()
        list.reserveCapacity(1000)
        #expect(list.capacity >= 1000)
        list.append(contentsOf: DirectedFixture<Int>.boost24.edges)
        list.removeAll(keepingCapacity: true)
        #expect(list.capacity >= 1000)
        list.removeAll()
        #expect(list.capacity < 1000)
    }

    @Test("EL-R15 removeEdges(incidentTo:) at a vertex that is not there removes nothing")
    func removeIncidentAbsent() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(list.removeEdges(incidentTo: 42) == 0)
        #expect(Array(list) == DirectedFixture<Int>.house.edges)
    }

    @Test("EL-R16 mutating while iterating iterates the original value")
    func mutateWhileIterating() {
        var list = EdgeList(DirectedFixture<Int>.directedPath3.edges)
        for edge in list {
            list.append(DirectedEdge(from: edge.target, to: edge.source))
        }
        #expect(Array(list) == [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1),
        ])
    }

    @Test("EL-R17 + and += with lists and arrays")
    func plus() {
        let path = EdgeList(DirectedFixture<Int>.directedPath3.edges)
        let doubled = path + path
        #expect(doubled.count == 4)
        #expect(doubled.multiplicity(of: DirectedEdge(from: 0, to: 1)) == 2)
        #expect(doubled.multiplicity(of: DirectedEdge(from: 1, to: 2)) == 2)
        var grown = path
        grown += [DirectedEdge(from: 2, to: 0)]
        #expect(Array(grown) == DirectedFixture<Int>.directedPath3.edges + [DirectedEdge(from: 2, to: 0)])
        let fromArray: EdgeList<Int> = path + [DirectedEdge(from: 9, to: 9)]
        #expect(fromArray.last == DirectedEdge(from: 9, to: 9))
    }

    @Test("EL-R18 after a removal, later positions hold the edges that followed; after an append, every position is unchanged")
    func positionsAfterMutation() {
        let house = DirectedFixture<Int>.house.edges
        var list = EdgeList(house)
        list.remove(at: 2)
        for j in 2 ..< list.count {
            #expect(list[j] == house[j + 1])
        }
        var appended = EdgeList(house)
        appended.append(DirectedEdge(from: 9, to: 9))
        for j in house.indices {
            #expect(appended[j] == house[j])
        }
    }
}
