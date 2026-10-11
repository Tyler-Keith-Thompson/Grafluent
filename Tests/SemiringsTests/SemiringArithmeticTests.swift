// Arithmetic at the edges of the scalars (SR-208 – SR-217, the trap rows are in
// SemiringPreconditionTests.swift): Int.max is the tropical zero and absorbs (Boost's
// closed_plus), infinity absorbs, min of extremes never overflows, Double counts round.
// Generated from cases.md by swiftgen.py; see README.md.

import Semirings
import Testing

@Suite("Semirings: arithmetic at the edges")
struct SemiringArithmeticTests {
    @Test("SR-208 Int.max is zero: absorbing, never added (TropicalSemiring<Int>: a = Int.max, b = -5)")
    func sr208() {
        // a ⊗ b → Int.max
        let a = TropicalSemiring<Int>(Int.max)
        let b = TropicalSemiring<Int>(-5)
        #expect((a ⊗ b).value == Int.max)
        #expect(a.times(b).value == Int.max && b.times(a).value == Int.max)
    }

    @Test("SR-209 a finite sum reaching Int.max is zero (Boost's closed_plus) (TropicalSemiring<Int>: a = Int.max - 3, b = 3)")
    func sr209() {
        // a ⊗ b → Int.max
        let a = TropicalSemiring<Int>(Int.max - 3)
        let b = TropicalSemiring<Int>(3)
        #expect((a ⊗ b).value == Int.max)
        #expect(a.times(b).value == Int.max && b.times(a).value == Int.max)
    }

    @Test("SR-212 infinity absorbs (TropicalSemiring<Double>: a = .infinity, b = -1e308)")
    func sr212() {
        // a ⊗ b → .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(-1e308)
        #expect((a ⊗ b).value == Double.infinity)
        #expect(a.times(b).value == Double.infinity && b.times(a).value == Double.infinity)
    }

    @Test("SR-213 no overflow: min of extremes (BottleneckSemiring<Int>: a = Int.min, b = Int.max)")
    func sr213() {
        // a ⊗ b → Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        #expect((a ⊗ b).value == Int.min)
        #expect(a.times(b).value == Int.min && b.times(a).value == Int.min)
    }

    @Test("SR-216 the largest product that fits (CountingSemiring<Int>: a = 4294967296, b = 2147483647)")
    func sr216() {
        // a ⊗ b → 9223372032559808512
        let a = CountingSemiring<Int>(4294967296)
        let b = CountingSemiring<Int>(2147483647)
        #expect((a ⊗ b).value == 9223372032559808512)
        #expect(a.times(b).value == 9223372032559808512 && b.times(a).value == 9223372032559808512)
    }

    @Test("SR-217 Double counts round instead (CountingSemiring<Double>: a = 9007199254740992.0, b = 1.0)")
    func sr217() {
        // a ⊕ b → 9007199254740992.0
        let a = CountingSemiring<Double>(9007199254740992.0)
        let b = CountingSemiring<Double>(1.0)
        #expect((a ⊕ b).value == 9007199254740992.0)
        #expect(a.plus(b).value == 9007199254740992.0 && b.plus(a).value == 9007199254740992.0)
    }
}
