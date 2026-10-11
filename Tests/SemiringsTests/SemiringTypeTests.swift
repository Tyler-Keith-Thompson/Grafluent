// The four semirings' constants (catalog SR-001 – SR-007, and the other scalar families from
// SR-356): zero and one by value, their descriptions, zero worse than one by the
// natural order, and hashing; and the counting semiring, which is not selective, so only
// dagShortestDistances takes it (SR-324, SR-333).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: zero, one and the types")
struct SemiringTypeTests {
    @Test("SR-001 zero and one (TropicalSemiring<Int>)")
    func sr001() {
        // (.zero, .one) → (Int.max, 0)
        #expect(TropicalSemiring<Int>.zero.value == Int.max && TropicalSemiring<Int>.one.value == 0)
        #expect(TropicalSemiring<Int>.zero == TropicalSemiring<Int>(Int.max) && TropicalSemiring<Int>.one == TropicalSemiring<Int>(0))
        // CustomStringConvertible: the value.
        #expect(TropicalSemiring<Int>.zero.description == "9223372036854775807" && TropicalSemiring<Int>.one.description == "0")
        #expect("\(TropicalSemiring<Int>(0))" == "0")
        // zero is the worst element, one beats it.
        #expect(TropicalSemiring<Int>.one < TropicalSemiring<Int>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([TropicalSemiring<Int>.zero, TropicalSemiring<Int>(Int.max), TropicalSemiring<Int>.one]).count == 2)
    }

    @Test("SR-002 zero and one (TropicalSemiring<Double>)")
    func sr002() {
        // (.zero, .one) → (.infinity, 0.0)
        #expect(TropicalSemiring<Double>.zero.value == Double.infinity && TropicalSemiring<Double>.one.value == 0.0)
        #expect(TropicalSemiring<Double>.zero == TropicalSemiring<Double>(Double.infinity) && TropicalSemiring<Double>.one == TropicalSemiring<Double>(0.0))
        // CustomStringConvertible: the value.
        #expect(TropicalSemiring<Double>.zero.description == "inf" && TropicalSemiring<Double>.one.description == "0.0")
        #expect("\(TropicalSemiring<Double>(0.0))" == "0.0")
        // zero is the worst element, one beats it.
        #expect(TropicalSemiring<Double>.one < TropicalSemiring<Double>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([TropicalSemiring<Double>.zero, TropicalSemiring<Double>(Double.infinity), TropicalSemiring<Double>.one]).count == 2)
    }

    @Test("SR-003 zero and one (BottleneckSemiring<Int>)")
    func sr003() {
        // (.zero, .one) → (Int.min, Int.max)
        #expect(BottleneckSemiring<Int>.zero.value == Int.min && BottleneckSemiring<Int>.one.value == Int.max)
        #expect(BottleneckSemiring<Int>.zero == BottleneckSemiring<Int>(Int.min) && BottleneckSemiring<Int>.one == BottleneckSemiring<Int>(Int.max))
        // CustomStringConvertible: the value.
        #expect(BottleneckSemiring<Int>.zero.description == "-9223372036854775808" && BottleneckSemiring<Int>.one.description == "9223372036854775807")
        #expect("\(BottleneckSemiring<Int>(Int.max))" == "9223372036854775807")
        // zero is the worst element, one beats it.
        #expect(BottleneckSemiring<Int>.one < BottleneckSemiring<Int>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([BottleneckSemiring<Int>.zero, BottleneckSemiring<Int>(Int.min), BottleneckSemiring<Int>.one]).count == 2)
    }

    @Test("SR-004 zero and one (BottleneckSemiring<Double>)")
    func sr004() {
        // (.zero, .one) → (-.infinity, .infinity)
        #expect(BottleneckSemiring<Double>.zero.value == -Double.infinity && BottleneckSemiring<Double>.one.value == Double.infinity)
        #expect(BottleneckSemiring<Double>.zero == BottleneckSemiring<Double>(-Double.infinity) && BottleneckSemiring<Double>.one == BottleneckSemiring<Double>(Double.infinity))
        // CustomStringConvertible: the value.
        #expect(BottleneckSemiring<Double>.zero.description == "-inf" && BottleneckSemiring<Double>.one.description == "inf")
        #expect("\(BottleneckSemiring<Double>(Double.infinity))" == "inf")
        // zero is the worst element, one beats it.
        #expect(BottleneckSemiring<Double>.one < BottleneckSemiring<Double>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([BottleneckSemiring<Double>.zero, BottleneckSemiring<Double>(-Double.infinity), BottleneckSemiring<Double>.one]).count == 2)
    }

    @Test("SR-005 zero and one (BooleanSemiring)")
    func sr005() {
        // (.zero, .one) → (false, true)
        #expect(BooleanSemiring.zero.value == false && BooleanSemiring.one.value == true)
        #expect(BooleanSemiring.zero == BooleanSemiring(false) && BooleanSemiring.one == BooleanSemiring(true))
        // CustomStringConvertible: the value.
        #expect(BooleanSemiring.zero.description == "false" && BooleanSemiring.one.description == "true")
        #expect("\(BooleanSemiring(true))" == "true")
        // zero is the worst element, one beats it.
        #expect(BooleanSemiring.one < BooleanSemiring.zero)
        // Hashable: equal values hash alike.
        #expect(Set([BooleanSemiring.zero, BooleanSemiring(false), BooleanSemiring.one]).count == 2)
    }

    @Test("SR-006 zero and one (CountingSemiring<Int>)")
    func sr006() {
        // (.zero, .one) → (0, 1)
        #expect(CountingSemiring<Int>.zero.value == 0 && CountingSemiring<Int>.one.value == 1)
        #expect(CountingSemiring<Int>.zero == CountingSemiring<Int>(0) && CountingSemiring<Int>.one == CountingSemiring<Int>(1))
        // CustomStringConvertible: the value.
        #expect(CountingSemiring<Int>.zero.description == "0" && CountingSemiring<Int>.one.description == "1")
        #expect("\(CountingSemiring<Int>(1))" == "1")
        // Hashable: equal values hash alike.
        #expect(Set([CountingSemiring<Int>.zero, CountingSemiring<Int>(0), CountingSemiring<Int>.one]).count == 2)
    }

    @Test("SR-007 zero and one (CountingSemiring<Double>)")
    func sr007() {
        // (.zero, .one) → (0.0, 1.0)
        #expect(CountingSemiring<Double>.zero.value == 0.0 && CountingSemiring<Double>.one.value == 1.0)
        #expect(CountingSemiring<Double>.zero == CountingSemiring<Double>(0.0) && CountingSemiring<Double>.one == CountingSemiring<Double>(1.0))
        // CustomStringConvertible: the value.
        #expect(CountingSemiring<Double>.zero.description == "0.0" && CountingSemiring<Double>.one.description == "1.0")
        #expect("\(CountingSemiring<Double>(1.0))" == "1.0")
        // Hashable: equal values hash alike.
        #expect(Set([CountingSemiring<Double>.zero, CountingSemiring<Double>(0.0), CountingSemiring<Double>.one]).count == 2)
    }

    @Test("SR-324 Dijkstra needs a SelectiveSemiring (CountingSemiring<Int>)")
    func sr324() throws {
        // dijkstraShortestPaths(from: 0) → does not compile (CountingSemiring<Int> is not a SelectiveSemiring)
        // The call does not type-check: dijkstraShortestPaths takes S: SelectiveSemiring.
        #if false
        let rejected = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        _ = rejected.dijkstraShortestPaths(from: 0) { _ in CountingSemiring<Int>(1) }
        #endif
        func isSemiring(_ type: Any.Type) -> Bool { type is any Semiring.Type }
        func isSelective(_ type: Any.Type) -> Bool { type is any SelectiveSemiring.Type }
        func isComparable(_ type: Any.Type) -> Bool { type is any Comparable.Type }
        #expect(isSemiring(CountingSemiring<Int>.self))
        #expect(!isSelective(CountingSemiring<Int>.self) && !isComparable(CountingSemiring<Int>.self))
        // dagShortestDistances is the entry point that takes it.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let distances = try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring<Int>(1) })
        #expect([distances.distance(to: 0).value, distances.distance(to: 1).value] == [1, 1])
    }

    @Test("SR-333 Dijkstra needs a SelectiveSemiring (CountingSemiring<Double>)")
    func sr333() throws {
        // dijkstraShortestPaths(from: 0) → does not compile (CountingSemiring<Double> is not a SelectiveSemiring)
        // The call does not type-check: dijkstraShortestPaths takes S: SelectiveSemiring.
        #if false
        let rejected = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        _ = rejected.dijkstraShortestPaths(from: 0) { _ in CountingSemiring<Double>(1) }
        #endif
        func isSemiring(_ type: Any.Type) -> Bool { type is any Semiring.Type }
        func isSelective(_ type: Any.Type) -> Bool { type is any SelectiveSemiring.Type }
        func isComparable(_ type: Any.Type) -> Bool { type is any Comparable.Type }
        #expect(isSemiring(CountingSemiring<Double>.self))
        #expect(!isSelective(CountingSemiring<Double>.self) && !isComparable(CountingSemiring<Double>.self))
        // dagShortestDistances is the entry point that takes it.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let distances = try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring<Double>(1) })
        #expect([distances.distance(to: 0).value, distances.distance(to: 1).value] == [1, 1])
    }

    @Test("SR-356 zero and one (BottleneckSemiring<UInt>)")
    func sr356() {
        // (.zero, .one) → (0, UInt.max)
        #expect(BottleneckSemiring<UInt>.zero.value == 0 && BottleneckSemiring<UInt>.one.value == UInt.max)
        #expect(BottleneckSemiring<UInt>.zero == BottleneckSemiring<UInt>(0) && BottleneckSemiring<UInt>.one == BottleneckSemiring<UInt>(UInt.max))
        // CustomStringConvertible: the value.
        #expect(BottleneckSemiring<UInt>.zero.description == "0" && BottleneckSemiring<UInt>.one.description == "18446744073709551615")
        #expect("\(BottleneckSemiring<UInt>(UInt.max))" == "18446744073709551615")
        // zero is the worst element, one beats it.
        #expect(BottleneckSemiring<UInt>.one < BottleneckSemiring<UInt>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([BottleneckSemiring<UInt>.zero, BottleneckSemiring<UInt>(0), BottleneckSemiring<UInt>.one]).count == 2)
    }

    @Test("SR-357 zero and one (TropicalSemiring<UInt8>)")
    func sr357() {
        // (.zero, .one) → (UInt8.max, 0)
        #expect(TropicalSemiring<UInt8>.zero.value == UInt8.max && TropicalSemiring<UInt8>.one.value == 0)
        #expect(TropicalSemiring<UInt8>.zero == TropicalSemiring<UInt8>(UInt8.max) && TropicalSemiring<UInt8>.one == TropicalSemiring<UInt8>(0))
        // CustomStringConvertible: the value.
        #expect(TropicalSemiring<UInt8>.zero.description == "255" && TropicalSemiring<UInt8>.one.description == "0")
        #expect("\(TropicalSemiring<UInt8>(0))" == "0")
        // zero is the worst element, one beats it.
        #expect(TropicalSemiring<UInt8>.one < TropicalSemiring<UInt8>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([TropicalSemiring<UInt8>.zero, TropicalSemiring<UInt8>(UInt8.max), TropicalSemiring<UInt8>.one]).count == 2)
    }

    @Test("SR-358 zero and one (TropicalSemiring<Int8>)")
    func sr358() {
        // (.zero, .one) → (Int8.max, 0)
        #expect(TropicalSemiring<Int8>.zero.value == Int8.max && TropicalSemiring<Int8>.one.value == 0)
        #expect(TropicalSemiring<Int8>.zero == TropicalSemiring<Int8>(Int8.max) && TropicalSemiring<Int8>.one == TropicalSemiring<Int8>(0))
        // CustomStringConvertible: the value.
        #expect(TropicalSemiring<Int8>.zero.description == "127" && TropicalSemiring<Int8>.one.description == "0")
        #expect("\(TropicalSemiring<Int8>(0))" == "0")
        // zero is the worst element, one beats it.
        #expect(TropicalSemiring<Int8>.one < TropicalSemiring<Int8>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([TropicalSemiring<Int8>.zero, TropicalSemiring<Int8>(Int8.max), TropicalSemiring<Int8>.one]).count == 2)
    }

    @Test("SR-359 zero and one (TropicalSemiring<Float>)")
    func sr359() {
        // (.zero, .one) → (.infinity, 0.0)
        #expect(TropicalSemiring<Float>.zero.value == Float.infinity && TropicalSemiring<Float>.one.value == 0.0)
        #expect(TropicalSemiring<Float>.zero == TropicalSemiring<Float>(Float.infinity) && TropicalSemiring<Float>.one == TropicalSemiring<Float>(0.0))
        // CustomStringConvertible: the value.
        #expect(TropicalSemiring<Float>.zero.description == "inf" && TropicalSemiring<Float>.one.description == "0.0")
        #expect("\(TropicalSemiring<Float>(0.0))" == "0.0")
        // zero is the worst element, one beats it.
        #expect(TropicalSemiring<Float>.one < TropicalSemiring<Float>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([TropicalSemiring<Float>.zero, TropicalSemiring<Float>(Float.infinity), TropicalSemiring<Float>.one]).count == 2)
    }

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-360 zero and one (BottleneckSemiring<Float16>)")
    func sr360() {
        // (.zero, .one) → (-.infinity, .infinity)
        #expect(BottleneckSemiring<Float16>.zero.value == -Float16.infinity && BottleneckSemiring<Float16>.one.value == Float16.infinity)
        #expect(BottleneckSemiring<Float16>.zero == BottleneckSemiring<Float16>(-Float16.infinity) && BottleneckSemiring<Float16>.one == BottleneckSemiring<Float16>(Float16.infinity))
        // CustomStringConvertible: the value.
        #expect(BottleneckSemiring<Float16>.zero.description == "-inf" && BottleneckSemiring<Float16>.one.description == "inf")
        #expect("\(BottleneckSemiring<Float16>(Float16.infinity))" == "inf")
        // zero is the worst element, one beats it.
        #expect(BottleneckSemiring<Float16>.one < BottleneckSemiring<Float16>.zero)
        // Hashable: equal values hash alike.
        #expect(Set([BottleneckSemiring<Float16>.zero, BottleneckSemiring<Float16>(-Float16.infinity), BottleneckSemiring<Float16>.one]).count == 2)
    }
    #endif
}
