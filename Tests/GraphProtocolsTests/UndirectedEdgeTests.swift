// UndirectedEdge: the unordered pair {u, v}. Equality and hashing ignore the order the endpoints
// were given in; the stored order is kept but is not part of the value. Case IDs (UG-Enn) refer to
// the catalog in README.md.

import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

/// A vertex type that is Hashable but not Sendable.
private final class UnsendableVertex: Hashable {
    let value: Int
    init(_ value: Int) { self.value = value }
    static func == (lhs: UnsendableVertex, rhs: UnsendableVertex) -> Bool { lhs.value == rhs.value }
    func hash(into hasher: inout Hasher) { hasher.combine(value) }
}

@Suite("UndirectedEdge")
struct UndirectedEdgeTests {
    @Test("UG-E01 equality and hashing are symmetric", .tags(.conformance))
    func symmetric() {
        #expect(UndirectedEdge(1, 2) == UndirectedEdge(2, 1))
        #expect(UndirectedEdge(2, 1) == UndirectedEdge(1, 2))
        #expect(UndirectedEdge(1, 2).hashValue == UndirectedEdge(2, 1).hashValue)
        #expect(UndirectedEdge("a", "b") == UndirectedEdge("b", "a"))
        #expect(UndirectedEdge("a", "b").hashValue == UndirectedEdge("b", "a").hashValue)
    }

    @Test("UG-E02 a Set holds an edge once, whichever way it is written")
    func setDeduplicates() {
        let edges: Set = [UndirectedEdge(1, 2), UndirectedEdge(2, 1), UndirectedEdge(1, 1)]
        #expect(edges.count == 2)
        #expect(edges.contains(UndirectedEdge(2, 1)))
        #expect(edges.contains(UndirectedEdge(1, 1)))
        var dictionary: [UndirectedEdge<Int>: String] = [:]
        dictionary[UndirectedEdge(1, 2)] = "first"
        dictionary[UndirectedEdge(2, 1)] = "second"
        #expect(dictionary == [UndirectedEdge(1, 2): "second"])
    }

    @Test("UG-E03 self-loops at different vertices are different values with different hashes", .tags(.selfLoops))
    func loopsDiffer() {
        #expect(UndirectedEdge(0, 0) != UndirectedEdge(1, 1))
        // Combining the two endpoint hashes with xor would send every self-loop to one hash.
        #expect(Set((0 ..< 100).map { UndirectedEdge($0, $0).hashValue }).count == 100)
        #expect(Set((0 ..< 100).map { UndirectedEdge($0, $0) }).count == 100)
    }

    @Test("UG-E04 edges with different endpoints differ")
    func nonEdgesDiffer() {
        #expect(UndirectedEdge(3, 3) != UndirectedEdge(3, 4))
        #expect(UndirectedEdge(3, 4) != UndirectedEdge(3, 3))
        #expect(UndirectedEdge(1, 2) != UndirectedEdge(1, 3))
        #expect(UndirectedEdge(1, 2) != UndirectedEdge(3, 1))
        #expect(UndirectedEdge(1, 1) != UndirectedEdge(1, 2))
    }

    @Test("UG-E05 isSelfLoop", .tags(.selfLoops))
    func isSelfLoop() {
        #expect(UndirectedEdge(2, 2).isSelfLoop)
        #expect(!UndirectedEdge(2, 3).isSelfLoop)
        #expect(!UndirectedEdge(3, 2).isSelfLoop)
        #expect(UndirectedEdge("a", "a").isSelfLoop)
    }

    @Test("UG-E06 oppositeVertex(to:) gives the other endpoint, or the vertex itself across a self-loop")
    func oppositeVertex() {
        #expect(UndirectedEdge(1, 2).oppositeVertex(to: 1) == 2)
        #expect(UndirectedEdge(1, 2).oppositeVertex(to: 2) == 1)
        #expect(UndirectedEdge(2, 1).oppositeVertex(to: 1) == 2)
        #expect(UndirectedEdge(5, 5).oppositeVertex(to: 5) == 5)
        #expect(UndirectedEdge("a", "b").oppositeVertex(to: "b") == "a")
    }

    @Test("UG-E06 oppositeVertex(to:) of a vertex that is not an endpoint traps", .tags(.precondition))
    func oppositeVertexOfNonEndpoint() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedEdge(1, 2).oppositeVertex(to: 3)
        }
    }

    @Test("UG-E07 Comparable orders by (min, max), so it agrees with ==")
    func comparable() {
        #expect(!(UndirectedEdge(1, 2) < UndirectedEdge(2, 1)))
        #expect(!(UndirectedEdge(2, 1) < UndirectedEdge(1, 2)))
        #expect([UndirectedEdge(2, 0), UndirectedEdge(1, 0), UndirectedEdge(0, 0)].sorted() == [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 2)])
        #expect(UndirectedEdge(0, 5) < UndirectedEdge(1, 1))
        #expect(UndirectedEdge(3, 1) < UndirectedEdge(1, 4))
        #expect(UndirectedEdge(2, 1) <= UndirectedEdge(1, 2))
        #expect(UndirectedEdge(2, 1) >= UndirectedEdge(1, 2))
        #expect([UndirectedEdge(4, 1), UndirectedEdge(2, 3), UndirectedEdge(1, 2)].min() == UndirectedEdge(1, 2))
    }

    @Test("UG-E08 the endpoints keep the order they were given in")
    func orientationKept() {
        let edge = UndirectedEdge(2, 1)
        #expect(edge.u == 2)
        #expect(edge.v == 1)
        var mutable = UndirectedEdge(0, 1)
        mutable.v = 7
        #expect(mutable.u == 0)
        #expect(mutable.v == 7)
        #expect(mutable == UndirectedEdge(7, 0))
    }

    @Test("UG-E09 description and debugDescription")
    func descriptions() {
        #expect("\(UndirectedEdge(1, 2))" == "1–2")
        #expect("\(UndirectedEdge(2, 1))" == "2–1")
        #expect(UndirectedEdge(1, 2).description == "1–2")
        #expect(String(reflecting: UndirectedEdge("a", "b")) == "\"a\"–\"b\"")
        #expect(UndirectedEdge("a", "b").description == "a–b")
    }

    @Test("UG-E10 Codable round trips keep the stored orientation", .tags(.conformance))
    func codable() throws {
        let edge = UndirectedEdge(2, 1)
        let decoded = try JSONDecoder().decode(UndirectedEdge<Int>.self, from: JSONEncoder().encode(edge))
        #expect(decoded == edge)
        #expect(decoded.u == 2)
        #expect(decoded.v == 1)
        let strings = [UndirectedEdge("b", "a"), UndirectedEdge("c", "c")]
        let decodedStrings = try JSONDecoder().decode([UndirectedEdge<String>].self, from: JSONEncoder().encode(strings))
        #expect(decodedStrings.map(\.u) == ["b", "c"])
        #expect(decodedStrings.map(\.v) == ["a", "c"])
    }

    @Test("UG-E11 conditional conformances: Sendable and BitwiseCopyable with Int vertices; Hashable with any vertex")
    func conditionalConformances() {
        func isSendable<T: Sendable>(_: T.Type) -> Bool { true }
        func isBitwiseCopyable<T: BitwiseCopyable>(_: T.Type) -> Bool { true }
        func isHashable<T: Hashable>(_: T.Type) -> Bool { true }
        #expect(isSendable(UndirectedEdge<Int>.self))
        #expect(isBitwiseCopyable(UndirectedEdge<Int>.self))
        #expect(isSendable(UndirectedEdge<String>.self))
        #expect(isHashable(UndirectedEdge<UnsendableVertex>.self))
        let a = UnsendableVertex(1)
        let b = UnsendableVertex(2)
        #expect(UndirectedEdge(a, b) == UndirectedEdge(b, a))
        #expect(Set([UndirectedEdge(a, b), UndirectedEdge(b, a)]).count == 1)
    }
}
