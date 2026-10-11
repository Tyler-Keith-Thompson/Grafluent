// The sentinels the catalog leaves out: the unsigned scalars (the bottleneck zero is 0, and
// UInt.max is the tropical zero and absorbs) and the signed tropical −∞ (Int.min), which absorbs
// every finite value but not the zero. Hand-written; they pin planted bugs the catalog rows
// missed (scripts/mutants/Semirings.py).

import Semirings
import Testing

@Suite("Semirings: the unsigned and −∞ sentinels")
struct SemiringSentinelTests {
    @Test("The unsigned bottleneck zero is 0: the identity of ⊕ and the annihilator of ⊗")
    func unsignedBottleneckZero() {
        let zero = BottleneckSemiring<UInt>.zero
        #expect(zero.value == 0)
        #expect(BottleneckSemiring<UInt8>.zero.value == 0 && BottleneckSemiring<UInt8>.one.value == UInt8.max)
        for a: UInt in [0, 1, 7, UInt.max] {
            let x = BottleneckSemiring(a)
            #expect(x.plus(zero) == x && zero.plus(x) == x, "identity: \(a)")
            #expect(x.times(zero) == zero && zero.times(x) == zero, "annihilator: \(a)")
            #expect(!(zero < x) && (x == zero || x < zero), "zero is the worst: \(a)")
        }
    }

    @Test("UInt.max is the unsigned tropical zero: it absorbs instead of overflowing")
    func unsignedTropicalZero() {
        let zero = TropicalSemiring<UInt>.zero
        #expect(zero.value == UInt.max && TropicalSemiring<UInt>.one.value == 0)
        for a: UInt in [0, 1, 7, UInt.max - 1, UInt.max] {
            let x = TropicalSemiring(a)
            #expect(x.times(zero) == zero && zero.times(x) == zero, "annihilator: \(a)")
            let product = x ⊗ zero
            #expect(product.value == UInt.max, "operator: \(a)")
        }
        #expect(TropicalSemiring<UInt8>(250).times(TropicalSemiring(UInt8.max)).value == UInt8.max)
        #expect(TropicalSemiring<UInt>(3).times(TropicalSemiring(4)).value == 7)
    }

    @Test("Int.min is the tropical −∞: it absorbs every finite value, including negative ones")
    func negativeInfinityAbsorbs() {
        let minus = TropicalSemiring(Int.min)
        for a in [-5, -1, 0, 1, 5, Int.max - 1] {
            let x = TropicalSemiring(a)
            #expect(minus.times(x).value == Int.min && x.times(minus).value == Int.min, "−∞ ⊗ \(a)")
        }
        #expect(minus.times(minus).value == Int.min)
        #expect(TropicalSemiring<Int8>(Int8.min).times(TropicalSemiring(-3)).value == Int8.min)
        #expect(TropicalSemiring<Int8>(4).times(TropicalSemiring(Int8.min)).value == Int8.min)
    }

    @Test("The tropical zero absorbs first: Int.max ⊗ Int.min is the zero")
    func zeroAbsorbsBeforeNegativeInfinity() {
        let zero = TropicalSemiring<Int>.zero, minus = TropicalSemiring(Int.min)
        #expect(zero.times(minus) == zero && minus.times(zero) == zero)
        let product = minus ⊗ zero
        #expect(product.value == Int.max)
        #expect(TropicalSemiring<Int16>(Int16.max).times(TropicalSemiring(Int16.min)).value == Int16.max)
    }
}
