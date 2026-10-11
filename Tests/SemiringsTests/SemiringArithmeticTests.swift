// Arithmetic at the edges of the scalars (SR-208 – SR-217, and the other widths from SR-413;
// the trap rows are in SemiringPreconditionTests.swift): Int.max is the tropical zero and
// absorbs (Boost's closed_plus), infinity absorbs, min of extremes never overflows, Double counts
// round, and unsigned 0 is the bottleneck zero.
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

    @Test("SR-413 a finite sum reaching Int8.max is zero (TropicalSemiring<Int8>: a = Int8.max - 7, b = 7)")
    func sr413() {
        // a ⊗ b → Int8.max
        let a = TropicalSemiring<Int8>(Int8.max - 7)
        let b = TropicalSemiring<Int8>(7)
        #expect((a ⊗ b).value == Int8.max)
        #expect(a.times(b).value == Int8.max && b.times(a).value == Int8.max)
    }

    @Test("SR-415 Int8.min absorbs (−∞) (TropicalSemiring<Int8>: a = Int8.min, b = -1)")
    func sr415() {
        // a ⊗ b → Int8.min
        let a = TropicalSemiring<Int8>(Int8.min)
        let b = TropicalSemiring<Int8>(-1)
        #expect((a ⊗ b).value == Int8.min)
        #expect(a.times(b).value == Int8.min && b.times(a).value == Int8.min)
    }

    @Test("SR-416 Int16.max absorbs before Int16.min (TropicalSemiring<Int16>: a = Int16.min, b = Int16.max)")
    func sr416() {
        // a ⊗ b → Int16.max
        let a = TropicalSemiring<Int16>(Int16.min)
        let b = TropicalSemiring<Int16>(Int16.max)
        #expect((a ⊗ b).value == Int16.max)
        #expect(a.times(b).value == Int16.max && b.times(a).value == Int16.max)
    }

    @Test("SR-419 a finite sum reaching UInt8.max is zero (TropicalSemiring<UInt8>: a = 200, b = 55)")
    func sr419() {
        // a ⊗ b → UInt8.max
        let a = TropicalSemiring<UInt8>(200)
        let b = TropicalSemiring<UInt8>(55)
        #expect((a ⊗ b).value == UInt8.max)
        #expect(a.times(b).value == UInt8.max && b.times(a).value == UInt8.max)
    }

    @Test("SR-421 UInt16.max absorbs (TropicalSemiring<UInt16>: a = UInt16.max, b = 1)")
    func sr421() {
        // a ⊗ b → UInt16.max
        let a = TropicalSemiring<UInt16>(UInt16.max)
        let b = TropicalSemiring<UInt16>(1)
        #expect((a ⊗ b).value == UInt16.max)
        #expect(a.times(b).value == UInt16.max && b.times(a).value == UInt16.max)
    }

    @Test("SR-422 a finite sum reaching UInt32.max is zero (TropicalSemiring<UInt32>: a = UInt32.max - 1, b = 1)")
    func sr422() {
        // a ⊗ b → UInt32.max
        let a = TropicalSemiring<UInt32>(UInt32.max - 1)
        let b = TropicalSemiring<UInt32>(1)
        #expect((a ⊗ b).value == UInt32.max)
        #expect(a.times(b).value == UInt32.max && b.times(a).value == UInt32.max)
    }

    @Test("SR-424 0 is one, not −∞: it does not absorb (TropicalSemiring<UInt>: a = 0, b = 9)")
    func sr424() {
        // a ⊗ b → 9
        let a = TropicalSemiring<UInt>(0)
        let b = TropicalSemiring<UInt>(9)
        #expect((a ⊗ b).value == 9)
        #expect(a.times(b).value == 9 && b.times(a).value == 9)
    }

    @Test("SR-425 0 is zero: it annihilates (BottleneckSemiring<UInt>: a = 0, b = 9)")
    func sr425() {
        // a ⊗ b → 0
        let a = BottleneckSemiring<UInt>(0)
        let b = BottleneckSemiring<UInt>(9)
        #expect((a ⊗ b).value == 0)
        #expect(a.times(b).value == 0 && b.times(a).value == 0)
    }

    @Test("SR-426 0 is zero: ⊕'s identity (BottleneckSemiring<UInt>: a = 0, b = 9)")
    func sr426() {
        // a ⊕ b → 9
        let a = BottleneckSemiring<UInt>(0)
        let b = BottleneckSemiring<UInt>(9)
        #expect((a ⊕ b).value == 9)
        #expect(a.plus(b).value == 9 && b.plus(a).value == 9)
    }

    @Test("SR-427 a sum rounding past Float's range is zero (TropicalSemiring<Float>: a = 1.7014118346046923e+38, b = 1.7014118346046923e+38)")
    func sr427() {
        // a ⊗ b → .infinity
        let a = TropicalSemiring<Float>(1.7014118346046923e+38)
        let b = TropicalSemiring<Float>(1.7014118346046923e+38)
        #expect((a ⊗ b).value == Float.infinity)
        #expect(a.times(b).value == Float.infinity && b.times(a).value == Float.infinity)
    }

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-428 a sum rounding past Float16's range is zero (TropicalSemiring<Float16>: a = 32768.0, b = 32768.0)")
    func sr428() {
        // a ⊗ b → .infinity
        let a = TropicalSemiring<Float16>(32768.0)
        let b = TropicalSemiring<Float16>(32768.0)
        #expect((a ⊗ b).value == Float16.infinity)
        #expect(a.times(b).value == Float16.infinity && b.times(a).value == Float16.infinity)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-429 -.infinity is zero: it annihilates (BottleneckSemiring<Float16>: a = -.infinity, b = 65504.0)")
    func sr429() {
        // a ⊗ b → -.infinity
        let a = BottleneckSemiring<Float16>(-Float16.infinity)
        let b = BottleneckSemiring<Float16>(65504.0)
        #expect((a ⊗ b).value == -Float16.infinity)
        #expect(a.times(b).value == -Float16.infinity && b.times(a).value == -Float16.infinity)
    }
    #endif
}
