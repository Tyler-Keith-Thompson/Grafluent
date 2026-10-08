// Equality and hashing, Codable, descriptions, value semantics, object lifetimes, a model test
// against Array, and exit tests for the preconditions. Case IDs (EL-Enn, EL-Dnn, EL-Nnn, EL-Wnn,
// EL-Pnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import EdgeListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("EdgeList equality and hashing", .tags(.conformance))
struct EdgeListEqualityTests {
    @Test("EL-E01 equality is element by element, in order")
    func elementwise() {
        let list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
        #expect(list == list)
        #expect(list == EdgeList([DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(list != EdgeList([DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)]))
        #expect(list != EdgeList([DirectedEdge(from: 0, to: 1)]))
        #expect(list != EdgeList())
    }

    @Test("EL-E02 multiplicity matters")
    func multiplicityMatters() {
        let once: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
        let twice: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]
        #expect(once != twice)
        #expect(Set(once) == Set(twice))
    }

    @Test("EL-E03 / EL-E05 every list of up to 3 edges on 2 vertices: list, graph and multiset classes, and hash consistency", .tags(.exhaustive))
    func exhaustiveTwoVertices() {
        let pairs = [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)]
        var lists: [EdgeList<Int>] = [EdgeList()]
        var frontier: [[DirectedEdge<Int>]] = [[]]
        for _ in 1 ... 3 {
            var next: [[DirectedEdge<Int>]] = []
            for prefix in frontier {
                for pair in pairs {
                    next.append(prefix + [pair])
                }
            }
            lists += next.map { EdgeList($0) }
            frontier = next
        }
        #expect(lists.count == 85)
        #expect(Set(lists).count == 85)
        #expect(Set(lists.map { AdjacencyList(edges: $0) }).count == 15)
        #expect(Set(lists.map { $0.sorted() }).count == 35)
        for a in lists {
            for b in lists {
                #expect((a == b) == a.elementsEqual(b))
                if a == b { #expect(a.hashValue == b.hashValue) }
            }
        }
    }

    @Test("EL-E04 every list of up to 2 edges on 3 vertices: 91 lists, 55 multisets, 46 edge sets", .tags(.exhaustive))
    func exhaustiveThreeVertices() {
        var pairs: [DirectedEdge<Int>] = []
        for u in 0 ..< 3 {
            for v in 0 ..< 3 { pairs.append(DirectedEdge(from: u, to: v)) }
        }
        var lists: [EdgeList<Int>] = [EdgeList()]
        for a in pairs { lists.append([a]) }
        for a in pairs {
            for b in pairs { lists.append([a, b]) }
        }
        #expect(lists.count == 91)
        #expect(Set(lists).count == 91)
        #expect(Set(lists.map { $0.sorted() }).count == 55)
        #expect(Set(lists.map { Set($0) }).count == 46)
    }

    @Test("EL-E05 equal lists built different ways hash alike")
    func hashAcrossConstructions() {
        let edges = DirectedFixture<Int>.house.edges
        let literal: EdgeList<Int> = [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ]
        var appended = EdgeList<Int>()
        for edge in edges { appended.append(edge) }
        var replaced = EdgeList([DirectedEdge(from: 9, to: 9)])
        replaced.replaceSubrange(0 ..< 1, with: edges)
        let fromSlice = EdgeList(EdgeList(edges + edges)[0 ..< 7])
        var mutated = EdgeList(edges.reversed())
        mutated.reverse()
        for list in [appended, replaced, fromSlice, mutated] {
            #expect(list == literal)
            #expect(list.hashValue == literal.hashValue)
        }
    }

    @Test("EL-E06 equal but distinct vertex instances compare equal")
    func equalInstances() {
        let a = EdgeList([DirectedEdge(from: HashableBox(1, label: "a"), to: HashableBox(2))])
        let b = EdgeList([DirectedEdge(from: HashableBox(1, label: "b"), to: HashableBox(2))])
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("EL-E07 order-free comparisons are spelled out")
    func orderFreeComparisons() {
        let list = EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges)
        let reversed = EdgeList(list.reversed())
        #expect(list != reversed)
        #expect(Set(list) == Set(reversed))
        #expect(list.sorted() == reversed.sorted())
        #expect(AdjacencyList(edges: list) == AdjacencyList(edges: reversed))
    }

    @Test("EL-E08 equality is not isomorphism")
    func notIsomorphism() {
        #expect(EdgeList([DirectedEdge(from: 0, to: 1)]) != EdgeList([DirectedEdge(from: 1, to: 0)]))
    }

    @Test("EL-E09 equal lists are interchangeable", .tags(.randomized))
    func substitutability() {
        var generator = SeededRandomNumberGenerator(seed: 9)
        for _ in 0 ..< 200 {
            var edges: [DirectedEdge<Int>] = []
            for _ in 0 ..< Int.random(in: 0 ... 6, using: &generator) {
                edges.append(DirectedEdge(from: Int.random(in: 0 ..< 3, using: &generator), to: Int.random(in: 0 ..< 3, using: &generator)))
            }
            let a = EdgeList(edges)
            var b = EdgeList<Int>()
            b.append(contentsOf: edges)
            #expect(a == b)
            #expect(a.first == b.first)
            #expect(a.vertices == b.vertices)
            #expect(a.description == b.description)
            #expect(a.transposed() == b.transposed())
        }
    }
}

@Suite("EdgeList Codable", .tags(.conformance))
struct EdgeListCodableTests {
    @Test("EL-D01 a JSON round trip keeps order and repeats", .tags(.fixture), arguments: DirectedFixture<Int>.all + DirectedFixture<Int>.realWorld)
    func jsonRoundTrip(_ fixture: DirectedFixture<Int>) throws {
        let list = EdgeList(fixture.edges)
        let decoded = try JSONDecoder().decode(EdgeList<Int>.self, from: JSONEncoder().encode(list))
        #expect(decoded == list)
    }

    @Test("EL-D01 / EL-D10 a property list round trip with String vertices, and Optional vertices")
    func otherRoundTrips() throws {
        let strings = EdgeList(DirectedFixture<String>.petgraphDAG.edges)
        #expect(try PropertyListDecoder().decode(EdgeList<String>.self, from: PropertyListEncoder().encode(strings)) == strings)
        let optionals = EdgeList<Int?>([DirectedEdge(from: nil, to: 1), DirectedEdge(from: 1, to: nil)])
        #expect(try JSONDecoder().decode(EdgeList<Int?>.self, from: JSONEncoder().encode(optionals)) == optionals)
    }

    @Test("EL-D02 / EL-D03 the encoded form is a flat array of endpoints")
    func encodedForm() throws {
        let path = EdgeList(DirectedFixture<Int>.directedPath3.edges)
        #expect(String(decoding: try JSONEncoder().encode(path), as: UTF8.self) == "[0,1,1,2]")
        #expect(String(decoding: try JSONEncoder().encode(EdgeList<Int>()), as: UTF8.self) == "[]")
        #expect(try JSONDecoder().decode(EdgeList<Int>.self, from: Data("[]".utf8)) == EdgeList())
        #expect(try JSONDecoder().decode(EdgeList<Int>.self, from: Data("[3,3,0,1,3,3]".utf8))
            == EdgeList([DirectedEdge(from: 3, to: 3), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 3, to: 3)]))
        let strings = EdgeList([DirectedEdge(from: "a", to: "b")])
        #expect(String(decoding: try JSONEncoder().encode(strings), as: UTF8.self) == #"["a","b"]"#)
    }

    @Test("EL-D04 isolated vertices do not survive a trip through the encoded form")
    func isolatedVerticesLost() throws {
        let abcd = DirectedFixture<String>.networkXABCD
        let graph = AdjacencyList(vertices: abcd.vertices, edges: abcd.edges)
        let decoded = try JSONDecoder().decode(EdgeList<String>.self, from: JSONEncoder().encode(EdgeList(graph.edges)))
        #expect(graph.vertexCount == 7)
        #expect(AdjacencyList(edges: decoded).vertexCount == 4)
    }

    @Test("EL-D05 / EL-D06 / EL-D08 corrupt payloads throw a DecodingError, never a partial list")
    func corrupt() {
        let payloads = [
            "[0, 1, 2]", "[0,1, 1,2, 2]", #"[0, "x"]"#, "null", "42", "{}", #"{"edges": [0, 1]}"#, "[[0, 1]]", "[0, null]", "[0.5, 1]",
        ]
        for json in payloads {
            #expect(throws: DecodingError.self, "\(json)") {
                try JSONDecoder().decode(EdgeList<Int>.self, from: Data(json.utf8))
            }
        }
    }

    @Test("EL-D05 an odd count is reported as corrupt data")
    func oddCount() throws {
        do {
            _ = try JSONDecoder().decode(EdgeList<Int>.self, from: Data("[0, 1, 2]".utf8))
            Issue.record("decoded")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("threw \(error), not dataCorrupted")
        }
    }

    @Test("EL-D07 negative and huge Int vertices are ordinary values")
    func extremeValues() throws {
        let decoded = try JSONDecoder().decode(EdgeList<Int>.self, from: Data("[-1, 9223372036854775807]".utf8))
        #expect(Array(decoded) == [DirectedEdge(from: -1, to: Int.max)])
    }

    @Test("EL-D09 the same list always encodes to the same bytes")
    func deterministic() throws {
        let edges = DirectedFixture<Int>.graph500Scale8.edges
        #expect(try JSONEncoder().encode(EdgeList(edges)) == JSONEncoder().encode(EdgeList(edges)))
        #expect(try JSONEncoder().encode(EdgeList(edges)) == JSONEncoder().encode(edges.flatMap { [$0.source, $0.target] }))
    }

    @Test("EL-D01 a list nested in another Codable value")
    func nested() throws {
        struct Document: Codable, Equatable {
            var name: String
            var lists: [EdgeList<Int>]
        }
        let document = Document(name: "d", lists: [EdgeList(DirectedFixture<Int>.house.edges), EdgeList()])
        #expect(try JSONDecoder().decode(Document.self, from: JSONEncoder().encode(document)) == document)
    }
}

@Suite("EdgeList descriptions", .tags(.conformance))
struct EdgeListDescriptionTests {
    @Test("EL-N01 / EL-N06 description lists the derived vertices and every edge, repeats included")
    func description() {
        let list = EdgeList(DirectedFixture<Int>.pathWithChord.edges)
        #expect(list.description == "[0, 1, 2, 3, 4, 5]; [0→1, 1→2, 2→3, 3→4, 4→5, 1→3, 1→3]")
        #expect("\(list)" == list.description)
        #expect(EdgeList<Int>().description == "[]; []")
    }

    @Test("EL-N02 description stops after 16 vertices and 16 edges")
    func truncated() {
        let list = EdgeList(DirectedFixture<Int>.completeDirected10.edges)
        let parts = list.description.components(separatedBy: "; ")
        #expect(parts[0] == "[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
        #expect(parts[1].hasPrefix("[0→1, 0→2, 0→3"))
        #expect(parts[1].hasSuffix(", …]"))
        #expect(parts[1].split(separator: ",").count == 17)
        let long = EdgeList((0 ..< 40).map { DirectedEdge(from: $0, to: $0 + 1) })
        #expect(long.description.components(separatedBy: "; ")[0].hasSuffix(", …]"))
    }

    @Test("EL-N03 String endpoints are quoted, as in an Array")
    func strings() {
        #expect(EdgeList([DirectedEdge(from: "a", to: "b")]).description == #"["a", "b"]; ["a"→"b"]"#)
    }

    @Test("EL-N04 debugDescription names the type and the counts")
    func debugDescription() {
        let list = EdgeList([DirectedEdge(from: "a", to: "b")])
        #expect(list.debugDescription == #"EdgeList<String>(vertexCount: 2, edgeCount: 1, vertices: ["a", "b"], edges: ["a"→"b"])"#)
        let long = EdgeList((0 ..< 40).map { DirectedEdge(from: $0, to: $0 + 1) })
        #expect(long.debugDescription.hasPrefix("EdgeList<Int>(vertexCount: 41, edgeCount: 40, vertices: ["))
        #expect(long.debugDescription.hasSuffix(", …])"))
    }

    @Test("EL-N05 the mirror is a collection of the edges")
    func mirror() {
        let list = EdgeList(DirectedFixture<Int>.pathWithChord.edges)
        let mirror = Mirror(reflecting: list)
        #expect(mirror.displayStyle == .collection)
        #expect(mirror.children.count == 7)
        #expect(mirror.children.map { $0.value as? DirectedEdge<Int> } == DirectedFixture<Int>.pathWithChord.edges)
    }

    @Test("EL-N07 equal lists print alike; a permutation prints differently")
    func printsAlike() {
        let a = EdgeList(DirectedFixture<Int>.house.edges)
        let b = EdgeList(Array(DirectedFixture<Int>.house.edges))
        #expect(a.description == b.description)
        #expect(EdgeList(a.reversed()).description != a.description)
    }
}

@Suite("EdgeList value semantics", .tags(.copyOnWrite))
struct EdgeListValueSemanticsTests {
    @Test("EL-W01 every mutation of a copy does what it does to an Array, and leaves the original unchanged")
    func everyMutation() {
        let edges = DirectedFixture<Int>.boost24.edges
        let original = EdgeList(edges)
        let loop = DirectedEdge(from: 99, to: 99)
        var copies = Array(repeating: original, count: 15)
        var arrays = Array(repeating: edges, count: 15)
        copies[0][0] = loop
        arrays[0][0] = loop
        copies[1].swapAt(0, 1)
        arrays[1].swapAt(0, 1)
        copies[2].sort()
        arrays[2].sort()
        copies[3].append(loop)
        arrays[3].append(loop)
        copies[4].insert(loop, at: 3)
        arrays[4].insert(loop, at: 3)
        copies[5].remove(at: 0)
        arrays[5].remove(at: 0)
        copies[6].remove(edge: edges[5])
        arrays[6].remove(at: 5)
        copies[7].removeAll { $0.source == 1 }
        arrays[7].removeAll { $0.source == 1 }
        copies[8].removeEdges(incidentTo: 4)
        arrays[8].removeAll { $0.source == 4 || $0.target == 4 }
        copies[9].replaceSubrange(2 ..< 5, with: [loop])
        arrays[9].replaceSubrange(2 ..< 5, with: [loop])
        copies[10].reverse()
        arrays[10].reverse()
        copies[11][3].target = 99
        arrays[11][3].target = 99
        copies[12][4 ..< 30].sort()
        arrays[12][4 ..< 30].sort()
        copies[13].transpose()
        arrays[13] = arrays[13].map { DirectedEdge(from: $0.target, to: $0.source) }
        copies[14].removeEdges(from: 10)
        arrays[14].removeAll { $0.source == 10 }
        #expect(Array(original) == edges)
        for k in copies.indices {
            #expect(Array(copies[k]) == arrays[k], "mutation \(k)")
            #expect(arrays[k] != edges, "mutation \(k) changes something")
        }
    }

    @Test("EL-W02 a slice taken before a mutation keeps the old edges")
    func sliceKeepsOldEdges() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        let slice = list[1 ..< 4]
        list.removeAll()
        #expect(Array(slice) == Array(DirectedFixture<Int>.house.edges[1 ..< 4]))
    }

    @Test("EL-W03 the list owns its edges")
    func ownsItsEdges() {
        var source = DirectedFixture<Int>.house.edges
        let list = EdgeList(source)
        source[0] = DirectedEdge(from: 0, to: 0)
        #expect(list[0] == DirectedEdge(from: 5, to: 3))
    }

    @Test("EL-W05 copies are independent across tasks")
    func acrossTasks() async {
        let list = EdgeList(DirectedFixture<Int>.petersen.edges)
        let changed = await Task.detached {
            var copy = list
            copy.removeAll { $0.source == 0 }
            return copy
        }.value
        #expect(list.count == 30)
        #expect(changed.count == 27)
    }

    @Test("EL-W06 random mutations agree with the same mutations on an Array", .tags(.randomized), arguments: [0, 1, 10, 200])
    func model(_ size: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(size) &+ 1)
        var model: [DirectedEdge<Int>] = []
        for _ in 0 ..< size {
            model.append(DirectedEdge(from: Int.random(in: 0 ..< 8, using: &generator), to: Int.random(in: 0 ..< 8, using: &generator)))
        }
        var list = EdgeList(model)
        for step in 0 ..< 2000 {
            let edge = DirectedEdge(from: Int.random(in: 0 ..< 8, using: &generator), to: Int.random(in: 0 ..< 8, using: &generator))
            let vertex = Int.random(in: 0 ..< 9, using: &generator)
            switch Int.random(in: 0 ..< 14, using: &generator) {
            case 0:
                list.append(edge)
                model.append(edge)
            case 1:
                let i = Int.random(in: 0 ... model.count, using: &generator)
                list.insert(edge, at: i)
                model.insert(edge, at: i)
            case 2 where !model.isEmpty:
                let i = Int.random(in: 0 ..< model.count, using: &generator)
                #expect(list.remove(at: i) == model.remove(at: i))
            case 3:
                let removed = list.remove(edge: edge)
                if let i = model.firstIndex(of: edge) {
                    #expect(removed == model.remove(at: i))
                } else {
                    #expect(removed == nil)
                }
            case 4:
                let before = model.count
                model.removeAll { $0.source == vertex || $0.target == vertex }
                #expect(list.removeEdges(incidentTo: vertex) == before - model.count)
            case 5 where !model.isEmpty:
                let i = Int.random(in: 0 ..< model.count, using: &generator)
                list[i] = edge
                model[i] = edge
            case 6 where model.count >= 2:
                let a = Int.random(in: 0 ..< model.count, using: &generator)
                let b = Int.random(in: a ... model.count, using: &generator)
                list.replaceSubrange(a ..< b, with: [edge, edge])
                model.replaceSubrange(a ..< b, with: [edge, edge])
            case 7:
                #expect(list.outDegree(of: vertex) == model.filter { $0.source == vertex }.count)
                #expect(list.inDegree(of: vertex) == model.filter { $0.target == vertex }.count)
                #expect(Array(list.successors(of: vertex)) == model.filter { $0.source == vertex }.map(\.target))
                #expect(Array(list.predecessors(of: vertex)) == model.filter { $0.target == vertex }.map(\.source))
                #expect(list.multiplicity(of: edge) == model.filter { $0 == edge }.count)
                #expect(list.contains(edge: edge) == model.contains(edge))
            case 8:
                let copy = list
                list.removeAll { $0.isSelfLoop }
                model.removeAll { $0.isSelfLoop }
                #expect(copy.count >= list.count)
            case 9 where model.count >= 2:
                // Mutations through a slice, including ones that narrow it.
                let a = Int.random(in: 0 ..< model.count, using: &generator)
                let b = Int.random(in: a ... model.count, using: &generator)
                switch Int.random(in: 0 ..< 7, using: &generator) {
                case 0:
                    list[a ..< b].sort()
                    model[a ..< b].sort()
                case 1 where b > a:
                    list[a ..< b].removeFirst()
                    model[a ..< b].removeFirst()
                case 2 where b > a:
                    list[a ..< b].removeLast()
                    model[a ..< b].removeLast()
                case 3:
                    list[a ..< b].append(edge)
                    model[a ..< b].append(edge)
                case 4:
                    list[a ..< b].removeAll { $0.source == vertex }
                    model[a ..< b].removeAll { $0.source == vertex }
                case 5:
                    list[a ..< b].reverse()
                    model[a ..< b].reverse()
                default:
                    _ = list[a ..< b].popFirst()
                    _ = model[a ..< b].popFirst()
                }
            case 10:
                list.transpose()
                model = model.map { DirectedEdge(from: $0.target, to: $0.source) }
            case 11:
                let before = model.count
                model.removeAll { $0.target == vertex }
                #expect(list.removeEdges(to: vertex) == before - model.count)
            case 12:
                let out = list.outDegrees
                for v in Set(model.flatMap { [$0.source, $0.target] }) {
                    #expect(out[v] == model.filter { $0.source == v }.count)
                }
            default:
                #expect(list.vertexCount == Set(model.flatMap { [$0.source, $0.target] }).count)
            }
            #expect(Array(list) == model, "step \(step)")
        }
    }
}

@Suite("EdgeList object lifetimes", .lifetimeChecked, .tags(.lifetime))
struct EdgeListLifetimeTests {
    @Test("EL-W04 removed edges release their vertices, and a destroyed list releases everything")
    func releases() {
        do {
            var list = EdgeList<LifetimeTracked<Int>>()
            for k in 0 ..< 10 {
                list.append(DirectedEdge(from: LifetimeTracked(k), to: LifetimeTracked(k + 100)))
            }
            #expect(LifetimeTracker.current!.instances == 20)
            list.remove(at: 0)
            #expect(LifetimeTracker.current!.instances == 18)
            list.removeAll { $0.source.payload < 5 }
            #expect(LifetimeTracker.current!.instances == 10)
            let target = list[0].target
            list.removeEdges(incidentTo: target)
            #expect(LifetimeTracker.current!.instances == 9)
            withExtendedLifetime(target) {}
            withExtendedLifetime(list) {}
        }
        #expect(LifetimeTracker.current!.instances == 0)
    }

    @Test("EL-W04 a copy keeps its vertices alive after the original drops them")
    func copyKeepsAlive() {
        do {
            var list = EdgeList([DirectedEdge(from: LifetimeTracked(1), to: LifetimeTracked(2))])
            let copy = list
            list.removeAll()
            #expect(LifetimeTracker.current!.instances == 2)
            withExtendedLifetime(copy) {}
        }
        #expect(LifetimeTracker.current!.instances == 0)
    }
}

@Suite("EdgeList preconditions", .tags(.precondition))
struct EdgeListPreconditionTests {
    @Test("EL-P01 subscripting out of range traps, reading and writing")
    func subscriptOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            _ = list[1]
        }
        await #expect(processExitsWith: .failure) {
            let list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            _ = list[-1]
        }
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            list[1] = DirectedEdge(from: 0, to: 0)
        }
    }

    @Test("EL-P02 / EL-P03 removing or inserting out of range traps")
    func removeInsertOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            list.remove(at: 1)
        }
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            list.insert(DirectedEdge(from: 0, to: 0), at: 2)
        }
    }

    @Test("EL-P04 removing from an empty or too-short list traps")
    func removeFromEmpty() async {
        await #expect(processExitsWith: .failure) {
            var list = EdgeList<Int>()
            list.removeFirst()
        }
        await #expect(processExitsWith: .failure) {
            var list = EdgeList<Int>()
            list.removeLast()
        }
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
            list.removeFirst(3)
        }
    }

    @Test("EL-P05 / EL-P06 swapping or replacing out of range traps")
    func swapReplaceOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            list.swapAt(0, 1)
        }
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            list.replaceSubrange(0 ..< 2, with: [])
        }
        await #expect(processExitsWith: .failure) {
            let list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            _ = list[0 ..< 2]
        }
    }

    @Test("EL-P07 a bare vertex in the builder traps, since an edge list cannot hold it")
    func builderVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = EdgeList<Int> {
                0
                DirectedEdge(from: 1, to: 2)
            }
        }
    }

    @Test("EL-P08 / EL-P10 the non-trapping counterparts really do not trap")
    func nonTrapping() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(list.remove(edge: DirectedEdge(from: 42, to: 42)) == nil)
        #expect(!list.contains(edge: DirectedEdge(from: 42, to: 42)))
        #expect(list.outDegree(of: 42) == 0)
        #expect(list.removeEdges(incidentTo: 42) == 0)
        var empty = EdgeList<Int>()
        #expect(empty.popLast() == nil)
    }

    @Test("EL-P11 parallel arrays of different lengths trap")
    func mismatchedParallelArrays() async {
        await #expect(processExitsWith: .failure) {
            _ = EdgeList(sources: [0, 1], targets: [1])
        }
        await #expect(processExitsWith: .failure) {
            _ = EdgeList(sources: [0], targets: [1, 2])
        }
    }

    @Test("EL-P12 an out-of-range slice traps when mutated in place, as when read")
    func sliceMutationOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1)]
            list[0 ..< 2].sort()
        }
    }
}
